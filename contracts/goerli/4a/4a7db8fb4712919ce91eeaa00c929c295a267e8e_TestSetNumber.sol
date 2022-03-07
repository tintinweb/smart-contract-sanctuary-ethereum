// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract TestSetNumber {
    uint256 public testNumber;
    function setNumberPublic(uint256 number_) public {
        testNumber = number_;
    }

    function setNumberExternal(uint256 number_) external {
        testNumber = number_;
    }
}