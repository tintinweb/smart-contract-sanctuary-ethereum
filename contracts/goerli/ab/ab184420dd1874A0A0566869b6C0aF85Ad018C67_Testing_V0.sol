pragma solidity >=0.8.2 <0.9.0;
// SPDX-License-Identifier: MIT

contract Testing_V0 {
    string public myString;
    uint public myUint;
    string[] public stringList;
    uint[] public uintList;

    constructor(string memory initString) {
        myString = initString;
    }
    
    function setString(string memory _value) public {
        myString = _value;
    }
    
    function getString() public view returns (string memory) {
        return myString;
    }
    
    function setUint(uint _value) public {
        myUint = _value;
    }
    
    function getUint() public view returns (uint) {
        return myUint;
    }
    
    function setStringList(string[] memory _values) public {
        stringList = _values;
    }
    
    function getStringList() public view returns (string[] memory) {
        return stringList;
    }
    
    function setUintList(uint[] memory _values) public {
        uintList = _values;
    }
    
    function getUintList() public view returns (uint[] memory) {
        return uintList;
    }
}