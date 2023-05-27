// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDataTypesPractice {
    function getInt256() external view returns (int256);

    function getUint256() external view returns (uint256);

    function getInt8() external view returns (int8);

    function getUint8() external view returns (uint8);

    function getBool() external view returns (bool);

    function getAddress() external view returns (address);

    function getBytes32() external view returns (bytes32);

    function getArrayUint5() external view returns (uint256[5] memory);

    function getArrayUint() external view returns (uint256[] memory);

    function getString() external view returns (string memory);

    function getBigUint() external pure returns (uint256);
}


contract Task2 is IDataTypesPractice {
    int256 signedValue = 21;
    uint256 unsignedValue = 2200;
    int8 signedValueTwo = 20;
    uint8 unsignedIntValue = 19;
    bool result = true;
    address reciever = address(0x76fF81E7F075f2E171b745f11C6E0202Da12d87A);
    bytes32 message = "Hello World!";
    uint256[5] values = [1, 2, 3, 4, 5];
    uint256[] numbers;
    string greeting = "Hello World!";

    function getInt256() external view returns (int256) {
        return signedValue;
    }

    function getUint256() external view returns (uint256) {
        return unsignedValue;
    }

    function getInt8() external view returns (int8) {
        return signedValueTwo;
    }

    function getUint8() external view returns (uint8) {
        return unsignedIntValue;
    }

    function getBool() external view returns (bool) {
        return result;
    }

    function getAddress() external view returns (address) {
        return reciever;
    }

    function getBytes32() external view returns (bytes32) {
        return message; 
    }

    function getArrayUint5() external view returns (uint256[5] memory) {
        return values; 
    }    

    function getArrayUint() external view returns (uint256[] memory) {
        return numbers;
    }

    function getString() external view returns (string memory) {
        return greeting; 
    }

    function getBigUint() external pure returns (uint256) {
        uint256 v1 = 1;
        uint256 v2 = 2;
        return (v1 | v2) << 1;
    }
}