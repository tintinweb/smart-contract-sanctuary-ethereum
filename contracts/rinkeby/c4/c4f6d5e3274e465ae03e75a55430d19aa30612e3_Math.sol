/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Math{
    function add(int number1, int number2) public view returns(int){
        return number1+number2;
    }

    function subtract(int number1, int number2) public view returns(int){
        return number1-number2;
    }
    
    function multiply(int number1, int number2) public view returns(int){
        return number1*number2;
    }

    function divide(int number1, int number2) public view returns(int){
        return number1/number2;
    }
}