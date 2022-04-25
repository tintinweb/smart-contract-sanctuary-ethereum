/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    event log(string values);

    event ImplementationUpgraded(address indexed implementation, string name_, string symbol_, uint8 decimals_, uint256 totalSupply_);

    function implementation() external view returns (address);

    function setImplementation(address newImplementation) external;

}

contract UnstructuredStorageProxy is IProxy {


    bytes32 internal constant IMPLEMENTATION_SLOT = keccak256("DEMO.20220415.implemntation-slot");

    function implementation() public view override returns (address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

    function setImplementation(address newImplementation) public override {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }


    function upgradeTo(address newImplementation, string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) public {
        setImplementation(newImplementation);
        (bool success, bytes memory returndata) = implementation().delegatecall(
            abi.encodeWithSelector(this.initialize.selector, name_, symbol_, decimals_, totalSupply_)
        );
        require(success, string(returndata));

        emit ImplementationUpgraded(implementation(), name_, symbol_, decimals_, totalSupply_);
    }

    function initialize(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) external pure {
        revert("CANNOT_CALL_INITIALIZE");
    }

    fallback() external payable {
        address _implementation = implementation();
        require(_implementation != address(0x0), "MISSING_IMPLEMENTATION");
        emit log("in proxy fallback");
        assembly {
            let ptr := mload(0x40)

        // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())

        // (2) forward call to logic contract
            let result := delegatecall(gas(), _implementation, ptr, calldatasize(), 0, 0)
            let size := returndatasize()

        // (3) retrieve return data
            returndatacopy(ptr, 0, size)

        // (4) forward return data back to caller
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }
}