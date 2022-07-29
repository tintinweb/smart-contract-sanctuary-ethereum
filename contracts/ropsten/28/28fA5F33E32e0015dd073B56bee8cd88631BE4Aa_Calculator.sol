// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

contract Calculator{
    function add(uint a ,uint b) public pure returns(uint) {
        uint c = a+b;
        return c;
    }
    function sub(uint a ,uint b) public pure returns(uint) {
       require(a>b,"Value of a should be large  then b");
        uint c = a-b;
        return c;
    }
    function Multiply(uint a ,uint b) public pure returns(uint) {
        uint c = a*b;
        return c;
    }
    function Division(uint a ,uint b) public pure returns(uint) {
        require(b >0, "value of b can't be zero");
        uint c = a/b;
        return c;
    }
}