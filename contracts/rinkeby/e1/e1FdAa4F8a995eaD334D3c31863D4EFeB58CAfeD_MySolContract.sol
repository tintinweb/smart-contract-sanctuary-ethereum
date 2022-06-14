// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MySolContract {
    uint256 public myVar;

    function updateVar(uint256 myNewVar) public {
        myVar = myNewVar;
    }
}