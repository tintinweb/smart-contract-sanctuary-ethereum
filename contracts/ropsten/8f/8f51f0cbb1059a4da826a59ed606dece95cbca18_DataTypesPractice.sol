// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./IDataTypesPractice.sol";

contract DataTypesPractice is IDataTypesPractice {
    int256 i256;
    uint256 u256;
    int8 i8;
    uint8 u8;
    bool truth;
    address addr;
    bytes32 b32;
    uint256[5] arrFixed;
    uint256[] arrDynamic;
    string str;

    constructor() {
        i256 = 128;
        u256 = 256;
        i8 = 8;
        u8 = 16;
        truth = true;
        addr = address(0x809C163eB90c13BBDA82FEDB47eD2816BB145542);
        arrFixed = [1, 2, 3, 4, 5];
        arrDynamic = [0, 5];
        str = "Hello World!";
        b32 = bytes32("Distributed Lab Solidity");
    }

    function getInt256() external view returns (int256) {
        return i256;
    }

    function getUint256() external view returns (uint256) {
        return u256;
    }

    function getIint8() external view returns (int8) {
        return i8;
    }

    function getUint8() external view returns (uint8) {
        return u8;
    }

    function getBool() external view returns (bool) {
        return truth;
    }

    function getAddress() external view returns (address) {
        return addr;
    }

    function getBytes32() external view returns (bytes32) {
        return b32;
    }

    function getArrayUint5() external view returns (uint256[5] memory) {
        return arrFixed;
    }

    function getArrayUint() external view returns (uint256[] memory) {
        return arrDynamic;
    }

    function getString() external view returns (string memory) {
        return str;
    }

    function getBigUint() external pure returns (uint256) {
        uint256 v1 = 1;
        uint256 v2 = 2;
        return ~(v1 - v2 / v2); // max uint256
    }
}