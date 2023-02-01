// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Gas {
    
    function forLoop() public pure {
        for(int i; i < 10; i++) {}
    }
}