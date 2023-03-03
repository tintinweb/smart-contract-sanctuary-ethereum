// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Demo {
    uint public num;

    function setNum(uint _num)public{
        num = _num;
    }

    string public str;

    function setString(string calldata _str)public {
        str = _str;
    }
}