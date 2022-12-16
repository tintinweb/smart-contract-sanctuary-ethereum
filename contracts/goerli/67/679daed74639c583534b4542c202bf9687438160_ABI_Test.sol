/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: UNLICENSED
// File: contracts/test_abi.sol



pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ABI_Test
 */
contract ABI_Test {

    struct SimpleStruct {

        string T_String;
        bool T_Bool;
        uint T_Uint;
        address T_Address;
        bytes T_Bytes;
        bytes10 T_FixedBytes;

    }

    struct ComplexStruct {

        string[] T_StringArray;
        bool T_IsBool;
        address[] T_AddressArray;
        string T_String;
        uint[] T_UintArray;
        uint T_Uint;
        address T_Address;
        bytes[] T_BytesArray;
        bytes10[] T_FixedBytesArray;

    }

    function getString(string memory inString) pure external returns(string memory returnedString)
    {
        return inString;
    }

    function getStringArray(string[] memory inStringArray) pure external returns(string[] memory returnedStringArray)
    {
        return inStringArray;
    }

    function getUint(uint inUnit) pure external returns(uint returnedUint)
    {
        return inUnit;
    }

    function getUintArray(uint[] memory inUintArray) pure external returns(uint[] memory returnedUintArray)
    {
        return inUintArray;
    }

    function getInt(int inInt) pure external returns(int returnedInt)
    {
        return inInt;
    }

    function getIntArray(int[] memory inIntArray) pure external returns(int[] memory returnedIntArray)
    {
        return inIntArray;
    }

    function getAddress(address inAddress) pure external returns(address returnedAddress)
    {
        return inAddress;
    }

    function getAddressArray(address[] memory inAddressArray) pure external returns(address[] memory returnedAddressArray)
    {
        return inAddressArray;
    }

    function getBool(bool inBool) pure external returns(bool returnedBool)
    {
        return inBool;
    }

    function getBoolArray(bool[] memory inBoolArray) pure external returns(bool[] memory returnedBoolArray)
    {
        return inBoolArray;
    }

    function getBytes(bytes memory inBytes) pure external returns(bytes memory returnedBytes)
    {
        return inBytes;
    }

    function getBytesArray(bytes[] memory inBytesArray) pure external returns(bytes[] memory returnedBytesArray)
    {
        return inBytesArray;
    }

    function getMixedBytes(bytes memory inBytes1, bytes5 inBytes2, string memory inString, bytes memory inBytes3) pure external returns(bytes memory returnedBytes1, bytes5 returnedBytes2, string memory returnedString, bytes memory returnedBytes3)
    {
        return (inBytes1, inBytes2, inString, inBytes3);
    }

    function getSimpleTuple(SimpleStruct memory inSimpletuple) pure external returns(SimpleStruct memory returnedSimpleTuple)
    {
        return inSimpletuple;
    }

    function getComplexTuple(ComplexStruct memory inComplextuple) pure external returns(ComplexStruct memory returnedComplexTuple)
    {
        return inComplextuple;
    }

    function getComplexTupleSecond(ComplexStruct memory inComplextuple, int inInt) pure external returns(ComplexStruct memory returnedTuple, int returnedInt)
    {
        return (inComplextuple, inInt);
    }

    function getTupleArray(SimpleStruct[] memory inTupleArray) pure external returns(SimpleStruct[] memory returnedTupleArray)
    {
        return inTupleArray;
    }

    function getFixedBytes(bytes4 inFixedBytes) pure external returns(bytes4 returnedFixedBytes)
    {
        return inFixedBytes;
    }

    function getFixedBytesArray(bytes4[] memory inFixedBytesArray) pure external returns(bytes4[] memory returnedFixedBytesArray)
    {
        return inFixedBytesArray;
    }

    function getStringArrayStatic(string[4] memory inStringArrayStatic) pure external returns(string[4] memory returnedStringArrayStatic)
    {
        return inStringArrayStatic;
    }

    function getUintArrayStatic(uint[4] memory inUintArrayStatic) pure external returns(uint[4] memory returnedUintArrayStatic)
    {
        return inUintArrayStatic;
    }

    function getBoolArrayStatic(bool[4] memory inBoolArrayStatic) pure external returns(bool[4] memory returnedBoolArrayStatic)
    {
        return inBoolArrayStatic;
    }

    function getAddressArrayStatic(address[4] memory inAddressArrayStatic) pure external returns(address[4] memory returnedAddressArrayStatic)
    {
        return inAddressArrayStatic;
    }

    function getBytesArrayStatic(bytes[4] memory inBytesArrayStatic) pure external returns(bytes[4] memory returnedBytesArrayStatic)
    {
        return inBytesArrayStatic;
    }

    function getFixedBytesArrayStatic(bytes5[4] memory inFixedBytesArrayStatic) pure external returns(bytes5[4] memory returnedFixedBytesArrayStatic)
    {
        return inFixedBytesArrayStatic;
    }

    function getStringAndUintArray(string[] memory inArrayString, uint[] memory inArrayUint) pure external 
    returns(string[] memory returnedArrayString, uint[] memory returnedArrayUint)
    {
        return (inArrayString, inArrayUint);
    }

    function getStringAndUint(string memory inString, uint inUint) pure external 
    returns(string memory returnedString, uint returnedUint)
    {
        return (inString, inUint);
    }

    function getStringAndAddress(string memory inString, address inAddress) pure external 
    returns(string memory returnedString, address returnedAddress)
    {
        return (inString, inAddress);
    }

    function getUintAndBool(uint inUint, bool inBool) pure external 
    returns(uint returnedUint, bool returnedBool)
    {
        return (inUint, inBool);
    }

    function getUintArrayAndBool(uint[] memory inUintArray, bool inBool) pure external 
    returns(uint[] memory returnedUintArray, bool returnedBool)
    {
        return (inUintArray, inBool);
    }

    function getFixedBytesArrayStaticAndString(bytes5[4] memory inFixedBytesArrayStatic, string memory inString) pure external returns(bytes5[4] memory returnedFixedBytesArrayStatic, string memory returnedString)
    {
        return (inFixedBytesArrayStatic, inString);
    }

    function getBytesStringUintString(bytes[4] memory inBytes, string memory inString , uint inUint, string[] memory inStringArray) pure external returns(bytes[4] memory returnedBytes, string memory returnedString, uint returnedUint, string[] memory returnedStringArray)
    {
        return (inBytes, inString, inUint, inStringArray);
    }

    function getMixedByes(bytes[] memory inBytes1, bytes10[] memory inBytes2, bytes[4] memory inBytes3, bytes5[5] memory inBytes4) pure external returns(bytes[] memory returnedBytes1, bytes10[] memory returnedBytes2, bytes[4] memory returnedBytes3, bytes5[5] memory returnedBytes4)
    {
        return (inBytes1, inBytes2, inBytes3, inBytes4);
    }

    function getStringArrayAndAddressAndUintArray(string[] memory inStringArray, address inAddress,uint[] memory inUintArray ) pure external 
    returns(string[] memory returnedStringArray, address returnedAddress,uint[] memory returnedUintArray)
    {
        return (inStringArray, inAddress, inUintArray);
    }

    function getMultipleStrings(string memory inString1, string memory inString2, string memory inString3, string memory inString4) pure external 
    returns(string memory returnedString1, string memory returnedString2, string memory returnedString3, string memory returnedString4)
    {
        return (inString1, inString2, inString3, inString4);
    }

    function getMultipleStringArrays(string[] memory inStringArray1,string[] memory inStringArray2, string[] memory inStringArray3, string[] memory inStringArray4) pure external 
    returns(string[] memory returnedStringArray1, string[] memory returnedStringArray2, string[] memory returnedStringArray3, string[] memory returnedStringArray4)
    {
        return (inStringArray1, inStringArray2, inStringArray3, inStringArray4);
    }

    function getMixedStringData(string[] memory inStringArray1,string memory inString2, string[] memory inStringArray3, string memory inString4) pure external 
    returns(string[] memory returnedStringArray1, string memory returnedString2, string[] memory returnedStringArray3, string memory returnedString4)
    {
        return (inStringArray1, inString2, inStringArray3, inString4);
    }

    function getMixedTuple(SimpleStruct[] memory inTupleArray, ComplexStruct memory inTuple) pure external returns(SimpleStruct[] memory returnedTupleArray, ComplexStruct memory returnedTuple)
    {
        return (inTupleArray,inTuple);
    }

    function getMixedTupleString(SimpleStruct[] memory inTupleArray, ComplexStruct memory inTuple, string memory inString) pure external returns(SimpleStruct[] memory returnedTupleArray, ComplexStruct memory returnedTuple, string memory returnedString)
    {
        return (inTupleArray, inTuple, inString);
    }

    function getMultipleTupleArray(SimpleStruct[] memory inTupleArray1, ComplexStruct[] memory inTupleArray2, SimpleStruct[] memory inTupleArray3) pure external returns(SimpleStruct[] memory returnedTupleArray1, ComplexStruct[] memory returnedTupleArray2, SimpleStruct[] memory returnedTupleArray3)
    {
        return (inTupleArray1, inTupleArray2, inTupleArray3);
    }

    function getMultipleTuples(SimpleStruct memory inTuple1, SimpleStruct memory inTuple2, ComplexStruct memory inTuple3) pure external returns(SimpleStruct memory returnedTuple1, SimpleStruct memory returnedTuple2, ComplexStruct memory returnedTuple3)
    {
        return (inTuple1, inTuple2, inTuple3);
    }

    function getData() pure external returns (bytes32, bytes32) 
    {
        bytes32 a = "abcd";
        bytes32 b = "wxyz";
        return (a, b);
    }

    uint256 number = 0;
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function storeNumber(uint256 num) public {
        number += num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieveNumber() public view returns (uint256){
        return number;
    }

}