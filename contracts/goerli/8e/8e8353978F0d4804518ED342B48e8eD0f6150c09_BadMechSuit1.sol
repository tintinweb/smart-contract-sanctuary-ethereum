/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract BadMechSuit1 {
    
    address constant ADMIN = 0xda5db8cd87955F8A552D4fd0Ce1DB9E168e10632;
    address private impl;

    constructor() {
        impl = address(new SuitLogicV0());
    }

    /// @dev You can assume this fallback function works safely!
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

    function upgradeTo(address _impl) public {
        require(msg.sender == ADMIN);
        impl = _impl;
    }

}

contract SuitLogicV0 {

    bytes32 private DO_NOT_USE;
    int32 private fuel;
    
    constructor() {
        fuel = type(int32).max;
    }

    function consumeFuel() external {
        fuel -= 10;
    }

    function throwFists() external view returns (bytes32) {
        require(fuel >= 0);
        return keccak256("WHAMM!");
    }

}