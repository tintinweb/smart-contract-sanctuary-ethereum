// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FundMe {
    uint256 private number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }
}