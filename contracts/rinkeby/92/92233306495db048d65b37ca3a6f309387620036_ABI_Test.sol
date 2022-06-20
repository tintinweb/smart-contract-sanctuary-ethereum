/**
 *Submitted for verification at Etherscan.io on 2022-06-20
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

    }


    function getStringArray(string[] memory inArray) pure external returns(string[] memory returnedValue)
    {
        return inArray;
    }

    function getUintArray(uint[] memory inArray) pure external returns(uint[] memory returnedValue)
    {
        return inArray;
    }

    function getintArray(int[] memory inArray) pure external returns(int[] memory returnedValue)
    {
        return inArray;
    }

    function getAddressArray(address[] memory inArray) pure external returns(address[] memory returnedValue)
    {
        return inArray;
    }

    function getboolArray(bool[] memory inArray) pure external returns(bool[] memory returnedValue)
    {
        return inArray;
    }

    function getbytesArray(bytes[] memory inArray) pure external returns(bytes[] memory returnedValue)
    {
        return inArray;
    }

    function getbytesArray(TestStruct[] memory inArray) pure external returns(TestStruct[] memory returnedValue)
    {
        return inArray;
    }

}