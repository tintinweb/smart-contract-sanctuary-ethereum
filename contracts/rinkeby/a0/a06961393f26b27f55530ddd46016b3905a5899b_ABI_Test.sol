/**
 *Submitted for verification at Etherscan.io on 2022-06-27
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

    function getFixedBytesArray(bytes4[] memory inArray) pure external returns(bytes4[] memory returnedValue)
    {
        return inArray;
    }

    function getStringArrayStatic(string[4] memory inArray) pure external returns(string[4] memory returnedValue)
    {
        return inArray;
    }

    function getUintArrayStatic(uint[4] memory inArray) pure external returns(uint[4] memory returnedValue)
    {
        return inArray;
    }

    function getBoolArrayStatic(bool[4] memory inArray) pure external returns(bool[4] memory returnedValue)
    {
        return inArray;
    }

    function getAddressArrayStatic(address[4] memory inArray) pure external returns(address[4] memory returnedValue)
    {
        return inArray;
    }

    function getBytesArrayStatic(bytes[4] memory inArray) pure external returns(bytes[4] memory returnedValue)
    {
        return inArray;
    }

    uint256 number = 0;
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number += num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

}