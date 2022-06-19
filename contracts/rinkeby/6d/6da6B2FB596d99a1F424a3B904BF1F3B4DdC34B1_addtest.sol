/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11; //指定編譯器版本
contract addtest{ //合約
   uint result; //全域性變數

   function getResult(uint _a, uint _b) public returns (uint){ //內部函式
      result = _a + _b;
      return (result);
   }
    function getResult1(uint _a, uint _b) public returns (uint){ //內部函式
      result = _a * _b;
      return (result);
   }
}