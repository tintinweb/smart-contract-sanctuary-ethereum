/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleAddition {
    uint256 public firstNumber;
    uint256 public secondNumber;

    constructor() {
        firstNumber = 30;
        secondNumber = 90;
    }

    function add() public view returns (uint256) {
        uint256 sum;
        sum = firstNumber + secondNumber;
        return sum;
    }
}