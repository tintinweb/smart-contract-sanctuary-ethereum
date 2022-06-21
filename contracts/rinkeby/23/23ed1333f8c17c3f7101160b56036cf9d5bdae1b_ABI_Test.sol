/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: UNLICENSED
// File: contracts/test_abi.sol



pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ABI_Test
 */
contract ABI_Test {

        struct TestStruct {

        string ThisIsString;
        bool ThisIsBool;
        uint ThisIsUint;
        int ThisIsInt;
        address ThisIsAddress;
        bytes ThisIsBytes;
        bytes10 ThisIsFixedBytes;

    }


    function getStringArray(string[] memory inArray) pure external returns(string[] memory returnedValue)
    {
        return inArray;
    }

    function getUintArray(uint[] memory inArray) pure external returns(uint[] memory returnedValue)
    {
        return inArray;
    }

    function getIntArray(int[] memory inArray) pure external returns(int[] memory returnedValue)
    {
        return inArray;
    }

    function getAddressArray(address[] memory inArray) pure external returns(address[] memory returnedValue)
    {
        return inArray;
    }

    function getBoolArray(bool[] memory inArray) pure external returns(bool[] memory returnedValue)
    {
        return inArray;
    }

    function getBytesArray(bytes[] memory inArray) pure external returns(bytes[] memory returnedValue)
    {
        return inArray;
    }

    function getTuple(TestStruct memory intuple) pure external returns(TestStruct memory returnedValue)
    {
        return intuple;
    }

    function getTupleArray(TestStruct[] memory inArray) pure external returns(TestStruct[] memory returnedValue)
    {
        return inArray;
    }

    function getFixedbytesArray(bytes4[] memory inArray) pure external returns(bytes4[] memory returnedValue)
    {
        return inArray;
    }

}