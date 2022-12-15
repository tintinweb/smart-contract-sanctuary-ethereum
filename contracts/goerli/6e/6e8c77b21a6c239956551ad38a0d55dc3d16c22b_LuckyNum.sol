/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LuckyNum {

    mapping ( address => uint) luckyNumbers;

    function setLuckyNumber(uint _luckyNum) public {
        luckyNumbers[msg.sender] = _luckyNum;
    }

    function getLuckyNumber() public view returns(uint){
        return luckyNumbers[msg.sender];
    }
}