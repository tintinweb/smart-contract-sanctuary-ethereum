/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Math {
    function multiplyBy20(uint toMultiply) public view returns (uint) {
        return toMultiply*20;
    }

    function Addition (uint firstNumber, uint secondNumber) public view returns (uint) {
        return firstNumber + secondNumber;
    }

      function Subtraktion (uint firstNumber, uint secondNumber) public view returns (uint) {
        return firstNumber - secondNumber;
    }

      function Division (uint firstNumber, uint secondNumber) public view returns (uint) {
        return firstNumber / secondNumber;
    }

      function Multiplikation (uint firstNumber, uint secondNumber) public view returns (uint) {
        return firstNumber * secondNumber;
    }
}