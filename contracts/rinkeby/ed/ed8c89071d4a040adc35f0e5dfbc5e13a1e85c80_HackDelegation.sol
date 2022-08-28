// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

contract HackDelegation {
    bytes4 public showHex;

    function updateShowHex() public {
        showHex = bytes4(keccak256("pwd()"));
    }
 
}