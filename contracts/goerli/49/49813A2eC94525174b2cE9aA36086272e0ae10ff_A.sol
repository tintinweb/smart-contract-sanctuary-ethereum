/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract A {
    address public admin;

    address public implementation;

    constructor(address _implementation){
        implementation = _implementation;
        admin = msg.sender;
    }

    function _delegateTo() internal {
        // delegate all other functions to current implementation
        (bool success,) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 {revert(free_mem_ptr, returndatasize())}
            default {return (free_mem_ptr, returndatasize())}
        }
    }

    fallback() payable external {
        _delegateTo();
    }

    receive() payable external {
        _delegateTo();
    }
}