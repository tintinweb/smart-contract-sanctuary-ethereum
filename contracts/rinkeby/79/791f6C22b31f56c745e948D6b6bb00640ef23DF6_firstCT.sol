// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";


contract firstCT{
    uint public num1;
    uint public num2;
    function get1(uint a) public {
        num1 = a;
    }
    function get2(uint b) public{
        num2 = b;
    }
    function add() view public returns (uint){
        uint sum = num1 + num2;
        return sum;
    }
    function subtract() view public returns (uint){
         uint sub = num1 - num2;
         return sub;
    }
}