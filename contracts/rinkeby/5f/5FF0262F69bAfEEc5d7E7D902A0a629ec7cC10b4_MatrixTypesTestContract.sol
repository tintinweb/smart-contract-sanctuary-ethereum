// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

/// @title Matrix Types Test Contract - A test contract to check all solidity matrix types in the tx-builder Safe App.
/// @author Daniel Somoza - <[email protected]>
contract MatrixTypesTestContract {
    // matrix of integers
    // int<bits>[][]
    int128[][] int128DynamicMatrixValue;
    int256[][] int256DynamicMatrixValue;

    // uint<bits>[][]
    uint128[][] uInt128DynamicMatrixValue;
    uint256[][] uInt256DynamicMatrixValue;

    // int<bits>[size][]
    int128[4][] int128_Fixed_x_Dynamic_MatrixValue;
    int256[4][] int256_Fixed_x_Dynamic_MatrixValue;

    // uint<bits>[size][];
    uint128[4][] uInt128_Fixed_x_Dynamic_MatrixValue;
    uint256[4][] uInt256_Fixed_x_Dynamic_MatrixValue;

    // int<bits>[][size]
    int128[][2] int128_Dynamic_x_Fixed_MatrixValue;
    int256[][2] int256_Dynamic_x_Fixed_MatrixValue;

    // uint<bits>[][size]
    uint128[][2] uInt128_Dynamic_x_Fixed_MatrixValue;
    uint256[][2] uInt256_Dynamic_x_Fixed_MatrixValue;

    // int<bits>[size][size]
    int128[3][2] int128FixedMatrixValue;
    int256[3][2] int256FixedMatrixValue;

    // uint<bits>[size][size]
    uint128[3][2] uInt128FixedMatrixValue;
    uint256[3][2] uInt256FixedMatrixValue;

    // matrix of addresses
    address[][] addressDynamicMatrixValue;
    address[3][] address_Dynamic_x_Fixed_MatrixValue;
    address[][2] address_Fixed_x_Dynamic_MatrixValue;
    address[2][3] addressFixedMatrixValue;

    // // matrix of booleans
    bool[][] boolDynamicMatrixValue;
    bool[3][] bool_Dynamic_x_Fixed_MatrixValue;
    bool[][2] bool_Fixed_x_Dynamic_MatrixValue;
    bool[2][3] boolFixedMatrixValue;

    // matrix of strings
    string[][] stringDynamicMatrixValue;
    string[3][] string_Dynamic_x_Fixed_MatrixValue;
    string[][2] string_Fixed_x_Dynamic_MatrixValue;
    string[2][3] stringFixedMatrixValue;

    // // matrix of bytes
    bytes[][] bytesDynamicMatrixValue;
    bytes[3][] bytes_Dynamic_x_Fixed_MatrixValue;
    bytes[][2] bytes_Fixed_x_Dynamic_MatrixValue;
    bytes[2][3] bytesFixedMatrixValue;

    // TODO: tuples
    // TODO: write methods of tuples

    // TODO: create a mix method of matrix of ints, uints, addresses, bools, strings, bytes

    // matrix of addresses write methods
    function testAddressDynamicMatrixValue(address[][] memory newValue) public {
        addressDynamicMatrixValue = newValue;
    }

    function testAddress_Dynamic_x_Fixed_MatrixValue(address[3][] memory newValue) public {
        address_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testAddress_Fixed_x_Dynamic_MatrixValue(address[][2] memory newValue) public {
        address_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testAddressFixedMatrixValue(address[2][3] memory newValue) public {
        addressFixedMatrixValue = newValue;
    }

    // matrix of booleans write methods
    function testBooleanDynamicMatrixValue(bool[][] memory newValue) public {
        boolDynamicMatrixValue = newValue;
    }

    function testBoolean_Dynamic_x_Fixed_MatrixValue(bool[3][] memory newValue) public {
        bool_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testBoolean_Fixed_x_Dynamic_MatrixValue(bool[][2] memory newValue) public {
        bool_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testBooleanFixedMatrixValue(bool[2][3] memory newValue) public {
        boolFixedMatrixValue = newValue;
    }

    // matrix of strings write methods
    function testStringDynamicMatrixValue(string[][] memory newValue) public {
        stringDynamicMatrixValue = newValue;
    }

    function testString_Dynamic_x_Fixed_MatrixValue(string[3][] memory newValue) public {
        string_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testString_Fixed_x_Dynamic_MatrixValue(string[][2] memory newValue) public {
        string_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testStringFixedMatrixValue(string[2][3] memory newValue) public {
        stringFixedMatrixValue = newValue;
    }

    // matrix of bytes write methods
    function testBytesDynamicMatrixValue(bytes[][] memory newValue) public {
        bytesDynamicMatrixValue = newValue;
    }

    function testBytes_Dynamic_x_Fixed_MatrixValue(bytes[3][] memory newValue) public {
        bytes_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testBytes_Fixed_x_Dynamic_MatrixValue(bytes[][2] memory newValue) public {
        bytes_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testBytesFixedMatrixValue(bytes[2][3] memory newValue) public {
        bytesFixedMatrixValue = newValue;
    }

    // matrix of integers write methods

    // matrix of int<bits>[][] write methods
    function testInt128DynamicMatrixValue(int128[][] memory newValue) public {
        int128DynamicMatrixValue = newValue;
    }

    function testInt256DynamicMatrixValue(int256[][] memory newValue) public {
        int256DynamicMatrixValue = newValue;
    }

    // matrix of uint<bits>[][] write methods
    function testUInt128DynamicMatrixValue(uint128[][] memory newValue) public {
        uInt128DynamicMatrixValue = newValue;
    }

    function testUInt256DynamicMatrixValue(uint256[][] memory newValue) public {
        uInt256DynamicMatrixValue = newValue;
    }

    // matrix of int<bits>[size][] write methods
    function testInt128_Fixed_x_Dynamic_MatrixValue(int128[4][] memory newValue) public {
        int128_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testInt256_Fixed_x_Dynamic_MatrixValue(int256[4][] memory newValue) public {
        int256_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    // matrix of uint<bits>[size][] write methods
    function testUInt128_Fixed_x_Dynamic_MatrixValue(uint128[4][] memory newValue) public {
        uInt128_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testUInt256_Fixed_x_Dynamic_MatrixValue(uint256[4][] memory newValue) public {
        uInt256_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    // matrix of int<bits>[][size] write methods
    function testInt128_Dynamic_x_Fixed_MatrixValue(int128[][2] memory newValue) public {
        int128_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testInt256_Dynamic_x_Fixed_MatrixValue(int256[][2] memory newValue) public {
        int256_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    // matrix of uint<bits>[][size] write methods
    function testUInt128_Dynamic_x_Fixed_MatrixValue(uint128[][2] memory newValue) public {
        uInt128_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testUInt256_Dynamic_x_Fixed_MatrixValue(uint256[][2] memory newValue) public {
        uInt256_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    // matrix of int<bits>[size][size] write methods
    function testInt128FixedMatrixValue(int128[3][2] memory newValue) public {
        int128FixedMatrixValue = newValue;
    }

    function testInt256FixedMatrixValue(int256[3][2] memory newValue) public {
        int256FixedMatrixValue = newValue;
    }

    // matrix of uint<bits>[size][size] write methods
    function testUInt128FixedMatrixValue(uint128[3][2] memory newValue) public {
        uInt128FixedMatrixValue = newValue;
    }

    function testUInt256FixedMatrixValue(uint256[3][2] memory newValue) public {
        uInt256FixedMatrixValue = newValue;
    }

    // read methods of int<bits>[][]
    function getInt128DynamicMatrixValue() public view returns (int128[][] memory) {
        return int128DynamicMatrixValue;
    }

    function getInt256DynamicMatrixValue() public view returns (int256[][] memory) {
        return int256DynamicMatrixValue;
    }

    // read methods of uint<bits>[][]
    function getUInt128DynamicMatrixValue() public view returns (uint128[][] memory) {
        return uInt128DynamicMatrixValue;
    }

    function getUInt256DynamicMatrixValue() public view returns (uint256[][] memory) {
        return uInt256DynamicMatrixValue;
    }

    // read methods of int<bits>[size][]
    function getInt128_Fixed_x_Dynamic_MatrixValue() public view returns (int128[4][] memory) {
        return int128_Fixed_x_Dynamic_MatrixValue;
    }

    function getInt256_Fixed_x_Dynamic_MatrixValue() public view returns (int256[4][] memory) {
        return int256_Fixed_x_Dynamic_MatrixValue;
    }

    // read methods of uint<bits>[size][]
    function getUInt128_Fixed_x_Dynamic_MatrixValue() public view returns (uint128[4][] memory) {
        return uInt128_Fixed_x_Dynamic_MatrixValue;
    }

    function getUInt256_Fixed_x_Dynamic_MatrixValue() public view returns (uint256[4][] memory) {
        return uInt256_Fixed_x_Dynamic_MatrixValue;
    }

    // read methods of int<bits>[][size]
    function getInt128_Dynamic_x_Fixed_MatrixValue() public view returns (int128[][2] memory) {
        return int128_Dynamic_x_Fixed_MatrixValue;
    }

    function getInt256_Dynamic_x_Fixed_MatrixValue() public view returns (int256[][2] memory) {
        return int256_Dynamic_x_Fixed_MatrixValue;
    }

    // read methods of uint<bits>[][size]
    function getUInt128_Dynamic_x_Fixed_MatrixValue() public view returns (uint128[][2] memory) {
        return uInt128_Dynamic_x_Fixed_MatrixValue;
    }

    function getUInt256_Dynamic_x_Fixed_MatrixValue() public view returns (uint256[][2] memory) {
        return uInt256_Dynamic_x_Fixed_MatrixValue;
    }

    // read methods of int<bits>[size][size]
    function getInt128FixedMatrixValue() public view returns (int128[3][2] memory) {
        return int128FixedMatrixValue;
    }

    function getInt256FixedMatrixValue() public view returns (int256[3][2] memory) {
        return int256FixedMatrixValue;
    }

    // read methods of uint<bits>[size][size]
    function getUInt128FixedMatrixValue() public view returns (uint128[3][2] memory) {
        return uInt128FixedMatrixValue;
    }

    function getUInt256FixedMatrixValue() public view returns (uint256[3][2] memory) {
        return uInt256FixedMatrixValue;
    }

    // read methods of matrix of addresses
    function getAddressDynamicMatrixValue() public view returns (address[][] memory) {
        return addressDynamicMatrixValue;
    }

    function getAddress_Dynamic_x_Fixed_MatrixValue() public view returns (address[3][] memory) {
        return address_Dynamic_x_Fixed_MatrixValue;
    }

    function getAddress_Fixed_x_Dynamic_MatrixValue() public view returns (address[][2] memory) {
        return address_Fixed_x_Dynamic_MatrixValue;
    }

    function getAddressFixedMatrixValue() public view returns (address[2][3] memory) {
        return addressFixedMatrixValue;
    }

    // read methods of matrix of booleans
    function getBooleanDynamicMatrixValue() public view returns (bool[][] memory) {
        return boolDynamicMatrixValue;
    }

    function getBoolean_Dynamic_x_Fixed_MatrixValue() public view returns (bool[3][] memory) {
        return bool_Dynamic_x_Fixed_MatrixValue;
    }

    function getBoolean_Fixed_x_Dynamic_MatrixValue() public view returns (bool[][2] memory) {
        return bool_Fixed_x_Dynamic_MatrixValue;
    }

    function getBooleanFixedMatrixValue() public view returns (bool[2][3] memory) {
        return boolFixedMatrixValue;
    }

    // read methods of matrix of strings
    function getStringDynamicMatrixValue() public view returns (string[][] memory) {
        return stringDynamicMatrixValue;
    }

    function getString_Dynamic_x_Fixed_MatrixValue() public view returns (string[3][] memory) {
        return string_Dynamic_x_Fixed_MatrixValue;
    }

    function getString_Fixed_x_Dynamic_MatrixValue() public view returns (string[][2] memory) {
        return string_Fixed_x_Dynamic_MatrixValue;
    }

    function getStringFixedMatrixValue() public view returns (string[2][3] memory) {
        return stringFixedMatrixValue;
    }

    // read methods of matrix of bytes
    function getBytesDynamicMatrixValue() public view returns (bytes[][] memory) {
        return bytesDynamicMatrixValue;
    }

    function getBytes_Dynamic_x_Fixed_MatrixValue() public view returns (bytes[3][] memory) {
        return bytes_Dynamic_x_Fixed_MatrixValue;
    }

    function getBytes_Fixed_x_Dynamic_MatrixValue() public view returns (bytes[][2] memory) {
        return bytes_Fixed_x_Dynamic_MatrixValue;
    }

    function getBytesFixedMatrixValue() public view returns (bytes[2][3] memory) {
        return bytesFixedMatrixValue;
    }
}