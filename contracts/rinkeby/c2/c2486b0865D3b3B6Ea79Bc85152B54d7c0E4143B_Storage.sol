// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

    uint256 number;

    function setNumber(uint256 num) public {
        number = num;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}