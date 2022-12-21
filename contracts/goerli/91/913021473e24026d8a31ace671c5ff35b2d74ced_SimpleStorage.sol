/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.8.0;

contract SimpleStorage {
    uint a;
    uint b = 42;
    address owner;
    mapping(address => uint) values;

    mapping(uint => uint) map;

    constructor() {
    }

    function setA(uint _a) public {
        a = _a;
    }

    function getA() public view returns (uint) {
        return a;
    }

    function setB(uint _b) public {
        b = _b;
    }

    function getB() public view returns (uint) {
        return b;
    }

    function getValue(address _address) public view returns (uint) {
        return values[_address];
    }

    function setValue(uint _value) public {
        values[msg.sender] = _value;
    }

    function insert(uint _key, uint _value) public {
        map[_key] = _value;
    }

    function get(uint _key) public view returns (uint){
        return map[_key];
    }
}