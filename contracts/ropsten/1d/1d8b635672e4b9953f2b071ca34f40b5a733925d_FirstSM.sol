// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./IDataTypesPratice.sol";

contract FirstSM is IDataTypesPractice {
    int256 valueInt256 = 10; 
    uint256 valueUInt256 = 11;

    int8 valueInt8 = 12; 
    uint8 valueUInt8 = 13; 

    bool valueBool = true; 

    address valueAddress = address(1);

    bytes32 valueBytes32 = "0x1";

    uint256[5] valueArrayUint5 = [0, 1, 2, 3, 4];
    uint256[] valueArrayUint = [0, 1, 2];

    string valueString = "Hello World";

    function getInt256() external view returns(int256) {
        return valueInt256;
    }

    function getUint256() external view returns(uint256) {
        return valueUInt256;
    }

    function getIint8() external view returns(int8) {
        return valueInt8;
    }
    
    function getUint8() external view returns(uint8) {
        return valueUInt8;
    }

    function getBool() external view returns(bool) {
        return valueBool;
    }

    function getAddress() external view returns(address) {
        return valueAddress;
    }

    function getBytes32() external view returns(bytes32) {
        return valueBytes32;
    }

    function getArrayUint5() external view returns(uint256[5] memory) {
        return valueArrayUint5;
    }

    function getArrayUint() external view returns(uint256[] memory) {
        return valueArrayUint;
    }
    
    function getString() external view returns(string memory) {
        return valueString;
    }

    function getBigUint() external pure returns(uint256) {
        uint256 v1 = 1;
        uint256 v2 = 2;

        return ~(v1 / v2);
    }
}