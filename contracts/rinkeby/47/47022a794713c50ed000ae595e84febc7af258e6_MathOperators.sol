/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract MathOperators{
    function multiply(uint v, uint k) public pure returns(uint){
    return v*k;
    }
    function divide(uint v, uint k) public pure returns(uint){
    return v/k;
    }
    function subtract(uint v, uint k) public pure returns(uint){
    return v-k;
    }
    function add(uint v, uint k) public pure returns(uint){
    return v+k;
    }
}