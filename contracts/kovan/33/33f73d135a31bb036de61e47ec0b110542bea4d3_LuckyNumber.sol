/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LuckyNumber {
    uint256 public myLuckyNumber = 42;
    
    function setLuckyNumber(uint256 _luckyNumber) public {
        myLuckyNumber = _luckyNumber;
    }

}