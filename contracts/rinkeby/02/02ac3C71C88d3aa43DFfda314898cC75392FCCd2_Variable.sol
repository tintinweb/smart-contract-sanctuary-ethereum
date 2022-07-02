//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Variable {
    int256 public myInt = 1;
    uint256 public myUint256 = 1;
    uint8 public myUint8 = 1;

    string public myString = "Hello, World";
    bytes32 public myBytes32 = "Hello, World";

    struct MyStruct {
        uint256 myUint256;
        bytes32 myBytes32;
    }

    MyStruct public myStruct = MyStruct(1, "Hello World!");

    function getValueofInt256() public view returns (int256) {
        return myInt;
    }

    function getValueofUint256() public view returns (uint256) {
        return myUint256;
    }

    function getValueofString() public view returns (bytes32) {
        return myBytes32;
    }

    function getValue() public pure returns (uint256) {
        uint256 value = 1;
        return value;
    }
}