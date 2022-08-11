/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InputDataExercise {
    mapping(address => uint256) public luckyNumbers;

    function tellMeYourLuckyNumber(uint _luckyNumber) public {
        luckyNumbers[msg.sender] = _luckyNumber;
    }

    function getFunctionSelector() public pure returns (bytes4) {
        return this.tellMeYourLuckyNumber.selector;
    }
}