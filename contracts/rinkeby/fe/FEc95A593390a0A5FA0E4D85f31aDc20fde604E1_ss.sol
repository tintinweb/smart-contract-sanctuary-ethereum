// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ss {
    uint public num;

    function retrieve() public view returns (uint) {
        return num;
    }

    function setNum(uint number) public {
        num = number;
    }
}