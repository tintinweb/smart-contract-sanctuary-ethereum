/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

contract MyDApp{
    string value;
    mapping (string => uint) nilai;
    constructor(){
        value = "Hello World";
        nilai["abc"] = 50;
    }
    event SetValue(string _value);
    function get() public view returns(string memory){
        return value;
    }
    function set(string memory _value) public{
        value = _value;
        emit SetValue(_value);
    } 
    function getMap() public view returns(uint){
        return nilai["abc"];
    }

    function randNumber(string memory _str) public pure returns(uint){
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand;
    }
}