// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    int public number;
    function SetNumber(int _number) public{
        number = _number;
    }
}