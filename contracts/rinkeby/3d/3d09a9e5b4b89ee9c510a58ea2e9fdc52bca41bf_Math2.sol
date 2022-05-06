/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;
contract Math2 {

uint result=10;

    function Calculator() public {
    
  }

    function getResult() public view returns (uint) {
    return result;
  }

    function addToNumber(uint num) public {
    result += num;
  }

    function substractNumber(uint num) public {
    result -= num;
  }

    function multiplyWithNumber(uint num) public {
    result *= num;
  }

    function divideByNumber(uint num) public {
    result /= num;
  }

}