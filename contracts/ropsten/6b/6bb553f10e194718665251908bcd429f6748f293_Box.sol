//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Box {
    uint public val;
    uint public balance;

    function initialize(uint _val, uint _balance) external {
        val = _val;
        balance = _balance;
    }
}