/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract BadMechSuit3 {
    
    address public impl;

    constructor() {
        impl = address(new SuitLogic());
        (bool result ,) = impl.delegatecall(
            abi.encodeWithSignature("initialize()")
        );
        require(result);
    }

    /// @dev You can safely assume this fallback function works safely!
    fallback() external {
        address _impl = impl;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(0, 0, size)

            switch result
            case 0 { revert(0, size) }
            default { return(0, size) }
        }
    }

}

contract SuitLogic {

    bytes32 private DO_NOT_USE;
    uint32 private fuel;

    function initialize() external {
        fuel = 100;
    }

    function shootFire() external pure returns (bytes32) {
        return keccak256("FWOOOOOSH");
    }

    function explode() external payable {
        if (msg.value > fuel * 100 ether) {
            selfdestruct(payable(msg.sender));
        }
    }

}