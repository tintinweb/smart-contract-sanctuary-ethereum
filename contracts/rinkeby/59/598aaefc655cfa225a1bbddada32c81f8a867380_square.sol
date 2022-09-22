/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract square {
    uint public result;

    function squ(uint _value)public returns (uint) {
        result = _value * _value;
        return result;
    }
    function squ3(uint _value)public returns (uint) {
        result = _value * _value * _value;
        return result;
    }
    function mok(uint _a, uint _b) public returns(uint){
        result = _a / _b;
        return result;
    }
    function namuji(uint _a, uint _b) public returns(uint){
        result = _a % _b;
        return result;
    }
}