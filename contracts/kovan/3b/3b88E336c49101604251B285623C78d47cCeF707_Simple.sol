/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Simple {
    address public owner;
    uint256 public answer;

    constructor(uint256 _answer) {
        owner = msg.sender;
        answer = _answer;
    }

    function setAnswer(uint256 _answer) public {
        answer = _answer;
    }
}