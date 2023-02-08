// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Logic {

    address public implementation;

    uint256 public x = 99;
    event CallSuccess();

    function increment()external returns(uint256){
        emit CallSuccess();
        return x + 1;
    }
}