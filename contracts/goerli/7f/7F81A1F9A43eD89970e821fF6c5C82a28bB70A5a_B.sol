// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract B {
    uint256 public num;
    address public user;

    function setNum(uint256 value) public {
        num = value;
        user = msg.sender;
    }
}