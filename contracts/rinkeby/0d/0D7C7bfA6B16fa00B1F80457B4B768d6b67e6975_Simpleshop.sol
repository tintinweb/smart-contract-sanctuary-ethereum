// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8 .0;

contract Simpleshop {

    string public wordStr = "Hello World!";

    function setWord(string calldata str) public {
        wordStr = str;
    }
}