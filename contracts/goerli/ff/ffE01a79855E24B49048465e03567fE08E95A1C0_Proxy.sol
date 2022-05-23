// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;


/**
 * @title Proxy // This is the user's wallet
 * @notice Basic proxy that delegates all calls to a fixed implementing contract.
 */
contract Proxy {

    /* This is the keccak-256 hash of "chainless.scw.proxy.implementation" subtracted by 1, and is validated in the constructor */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x509eec92e0cfa2f1ef3e421b58e60bf4c4940e3260fc771142ea68e0bfb3e134;

    event Received(uint indexed value, address indexed sender, bytes data);

    constructor(address _implementation) {
         assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("chainless.scw.proxy.implementation")) - 1));
         assembly {
             sstore(_IMPLEMENTATION_SLOT,_implementation) 
         }
    }

    fallback() external payable {
        address target;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            target := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {
        emit Received(msg.value, msg.sender, "");
    }
}