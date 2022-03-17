//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ReadTestV2 {
    address public owner;
    uint256 public mapNum = 0;
    uint256 public mapNestNum = 0;

    mapping (uint256 => address) public mapBasic;
    mapping (uint256 => mapping (uint256 => address)) public mapNest;

    uint256[] public uintArray = [1,2,3,4,5,6];
    uint256[][] public uint2Array = [[1,2,3],[4,5,6],[7,8,9]];


    string[] public stringArray = ["test1","test2","test3"];
    string[][] public string2Array = [["test1","test2","test3"],["test4","test5","test6"],["test7","test8","test9"]];

    constructor() {
        owner = msg.sender;
    }

    function addMap(address _address) public {
        mapBasic[mapNum] = _address;
    }

    function addMapNest(address _address) public {
        mapNest[mapNestNum][0] = _address;
        mapNest[mapNestNum][1] = _address;
        mapNest[mapNestNum][2] = _address;
    }

    function writeUintArray(uint256[] memory _value) public {
        uintArray = _value;
    }

    function readUintArray() public view returns (uint256[] memory) {
        return uintArray;
    }

    function readUint2Array() public view returns (uint256[][] memory) {
        return uint2Array;
    }

    function writeStringArray(string[] memory _value) public {
        stringArray = _value;
    }

    function readStringArray() public view returns (string[] memory) {
        return stringArray;
    }

    function readString2Array() public view returns (string[][] memory) {
        return string2Array;
    }
}