/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Calculator {
    uint256 public lastValue;
    address payable public owner;

    event Calc(uint256 lastValue, string action);

    function add(uint256 value) public {
        lastValue += value;
        emit Calc(lastValue, "add");
    }

    function subtract(uint256 value) public {
        lastValue -= value;
        emit Calc(lastValue, "subtract");
    }
}