// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IDataTypesPractice {
    function getInt256() external view returns (int256);

    function getUint256() external view returns (uint256);

    function getIint8() external view returns (int8);

    function getUint8() external view returns (uint8);

    function getBool() external view returns (bool);

    function getAddress() external view returns (address);

    function getBytes32() external view returns (bytes32);

    function getArrayUint5() external view returns (uint256[5] memory);

    function getArrayUint() external view returns (uint256[] memory);

    function getString() external view returns (string memory);

    function getBigUint() external pure returns (uint256);
}

contract Practice1 is IDataTypesPractice {
    int256 signedNum = 0xFFFFFFFFFFFFFFFFFFFF;

    function getInt256() external view returns (int256) {
        return signedNum;
    }

    uint256 unsignedNum = 0x0000001;

    function getUint256() external view returns (uint256) {
        return unsignedNum;
    }

    int8 someByte = 120;

    function getIint8() external view returns (int8) {
        return someByte;
    }

    uint8 someUnsignedByte = 255;

    function getUint8() external view returns (uint8) {
        return someUnsignedByte;
    }

    bool someBool = true;

    function getBool() external view returns (bool) {
        return someBool;
    }

    address someAddress = 0xd35c0a2d081493467196A01769B63616F8D8805f;

    function getAddress() external view returns (address) {
        return someAddress;
    }

    bytes32 someBytes = "some bytes";

    function getBytes32() external view returns (bytes32) {
        return someBytes;
    }

    uint256[5] numbersArray = [1, 2, 3, 4, 5];

    function getArrayUint5() external view returns (uint256[5] memory) {
        return numbersArray;
    }

    uint256[] numbers = new uint256[](10);

    function getArrayUint() external view returns (uint256[] memory) {
        return numbers;
    }

    string someString = "Hello World!";

    function getString() external view returns (string memory) {
        return someString;
    }

    function getBigUint() external pure returns (uint256) {
        uint256 v1 = 1;
        // uint256 v2 = 2;

        return ~v1; // inverts all bits
    }
}