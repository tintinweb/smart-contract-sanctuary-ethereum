/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

interface IDataTypesPractice {
    function getInt256() external view returns(int256);
    function getUint256() external view returns(uint256);
    function getIint8() external view returns(int8);
    function getUint8() external view returns(uint8);
    function getBool() external view returns(bool);
    function getAddress() external view returns(address);
    function getBytes32() external view returns(bytes32);
    function getArrayUint5() external view returns(uint256[5] memory);
    function getArrayUint() external view returns(uint256[] memory);
    function getString() external view returns(string memory);

    function getBigUint() external pure returns(uint256);
}

contract DataTypesHP is IDataTypesPractice {
    int256 constant int256var = -57896044618658097711785492504343953926634992332820282019728792003956564819968;
    uint256 constant uint256var = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    int8 constant int8var = -128;
    uint8 constant uint8var = 255;
    bool constant boolvar = true;
    address constant myAddrDonateHereHehehe = address(0x12F3D0A3BfEe2F73459554538bDa2557318Fd467);
    bytes32 constant bytes32var = "0foobarfoobarfoobarfoobarfoobar0";
    uint256[5] uint256FixedSizevar = [1,2,3,4,5];
    uint256[] uint256DynSizevar = [6,7,8,9,10];
    string constant stringvar = "Hello World!";

    function getInt256() external view returns(int256) {
        return int256var;
    }
    function getUint256() external view returns(uint256) {
        return uint256var;
    }
    function getIint8() external view returns(int8) {
        return int8var;
    }
    function getUint8() external view returns(uint8) {
        return uint8var;
    }
    function getBool() external view returns(bool) {
        return boolvar;
    }
    function getAddress() external view returns(address) {
        return myAddrDonateHereHehehe;
    }
    function getBytes32() external view returns(bytes32) {
        return bytes32var;
    }
    function getArrayUint5() external view returns(uint256[5] memory) {
        return uint256FixedSizevar;
    }
    function getArrayUint() external view returns(uint256[] memory) {
        return uint256DynSizevar;
    }
    function getString() external view returns(string memory) {
        return stringvar;
    }
    function getBigUint() external pure returns(uint256) {
        uint256 v1 = 1;
        uint256 v2 = 2;
        unchecked {
            return v1 - v2;
        }
    }
}