// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

/// @title Matrix Types Test Contract - A test contract to check all solidity matrix types in the tx-builder Safe App.
/// @author Daniel Somoza - <[email protected]>
contract MatrixTypesTestContract {
    // TODO: matrix of address, bool, string, bytes, tuples

    // matrix of integers
    // int<bits>[][]
    int8[][] int8DynamicMatrixValue;
    int32[][] int32DynamicMatrixValue;
    int128[][] int128DynamicMatrixValue;
    int256[][] int256DynamicMatrixValue;

    // uint<bits>[][]
    uint8[][] uInt8DynamicMatrixValue;
    uint32[][] uInt32DynamicMatrixValue;
    uint128[][] uInt128DynamicMatrixValue;
    uint256[][] uInt256DynamicMatrixValue;

    // int<bits>[size][]
    int8[4][] int8_Fixed_x_Dynamic_MatrixValue;
    int32[4][] int32_Fixed_x_Dynamic_MatrixValue;
    int128[4][] int128_Fixed_x_Dynamic_MatrixValue;
    int256[4][] int256_Fixed_x_Dynamic_MatrixValue;

    // uint<bits>[size][]
    uint8[4][] uInt8_Fixed_x_Dynamic_MatrixValue;
    uint32[4][] uInt32_Fixed_x_Dynamic_MatrixValue;
    uint128[4][] uInt128_Fixed_x_Dynamic_MatrixValue;
    uint256[4][] uInt256_Fixed_x_Dynamic_MatrixValue;

    // int<bits>[][size]
    int8[][2] int8_Dynamic_x_Fixed_MatrixValue;
    int32[][2] int32_Dynamic_x_Fixed_MatrixValue;
    int128[][2] int128_Dynamic_x_Fixed_MatrixValue;
    int256[][2] int256_Dynamic_x_Fixed_MatrixValue;

    // uint<bits>[][size]
    uint8[][2] uInt8_Dynamic_x_Fixed_MatrixValue;
    uint32[][2] uInt32_Dynamic_x_Fixed_MatrixValue;
    uint128[][2] uInt128_Dynamic_x_Fixed_MatrixValue;
    uint256[][2] uInt256_Dynamic_x_Fixed_MatrixValue;

    // int<bits>[size][size]
    int8[3][2] int8FixedMatrixValue;
    int32[3][2] int32FixedMatrixValue;
    int128[3][2] int128FixedMatrixValue;
    int256[3][2] int256FixedMatrixValue;

    // uint<bits>[size][size]
    uint8[3][2] uInt8FixedMatrixValue;
    uint32[3][2] uInt32FixedMatrixValue;
    uint128[3][2] uInt128FixedMatrixValue;
    uint256[3][2] uInt256FixedMatrixValue;

    // TODO: create a mix method of matrix of ints, uints, addresses, bools, strings, bytes

    // matrix of integers write methods

    // matrix of int<bits>[][] write methods
    function testInt8DynamicMatrixValue(int8[][] memory newValue) public {
        int8DynamicMatrixValue = newValue;
    }

    function testInt32DynamicMatrixValue(int32[][] memory newValue) public {
        int32DynamicMatrixValue = newValue;
    }

    function testInt128DynamicMatrixValue(int128[][] memory newValue) public {
        int128DynamicMatrixValue = newValue;
    }

    function testInt256DynamicMatrixValue(int256[][] memory newValue) public {
        int256DynamicMatrixValue = newValue;
    }

    // matrix of uint<bits>[][] write methods
    function testUInt8DynamicMatrixValue(uint8[][] memory newValue) public {
        uInt8DynamicMatrixValue = newValue;
    }

    function testUInt32DynamicMatrixValue(uint32[][] memory newValue) public {
        uInt32DynamicMatrixValue = newValue;
    }

    function testUInt128DynamicMatrixValue(uint128[][] memory newValue) public {
        uInt128DynamicMatrixValue = newValue;
    }

    function testUInt256DynamicMatrixValue(uint256[][] memory newValue) public {
        uInt256DynamicMatrixValue = newValue;
    }

    // matrix of int<bits>[size][] write methods
    function testInt8_Fixed_x_Dynamic_MatrixValue(int8[4][] memory newValue) public {
        int8_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testInt32_Fixed_x_Dynamic_MatrixValue(int32[4][] memory newValue) public {
        int32_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testInt128_Fixed_x_Dynamic_MatrixValue(int128[4][] memory newValue) public {
        int128_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testInt256_Fixed_x_Dynamic_MatrixValue(int256[4][] memory newValue) public {
        int256_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    // matrix of uint<bits>[size][] write methods
    function testUInt8_Fixed_x_Dynamic_MatrixValue(uint8[4][] memory newValue) public {
        uInt8_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testUInt32_Fixed_x_Dynamic_MatrixValue(uint32[4][] memory newValue) public {
        uInt32_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testUInt128_Fixed_x_Dynamic_MatrixValue(uint128[4][] memory newValue) public {
        uInt128_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    function testUInt256_Fixed_x_Dynamic_MatrixValue(uint256[4][] memory newValue) public {
        uInt256_Fixed_x_Dynamic_MatrixValue = newValue;
    }

    // matrix of int<bits>[][size] write methods
    function testInt8_Dynamic_x_Fixed_MatrixValue(int8[][2] memory newValue) public {
        int8_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testInt32_Dynamic_x_Fixed_MatrixValue(int32[][2] memory newValue) public {
        int32_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testInt128_Dynamic_x_Fixed_MatrixValue(int128[][2] memory newValue) public {
        int128_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testInt256_Dynamic_x_Fixed_MatrixValue(int256[][2] memory newValue) public {
        int256_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    // matrix of uint<bits>[][size] write methods
    function testUInt8_Dynamic_x_Fixed_MatrixValue(uint8[][2] memory newValue) public {
        uInt8_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testUInt32_Dynamic_x_Fixed_MatrixValue(uint32[][2] memory newValue) public {
        uInt32_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testUInt128_Dynamic_x_Fixed_MatrixValue(uint128[][2] memory newValue) public {
        uInt128_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    function testUInt256_Dynamic_x_Fixed_MatrixValue(uint256[][2] memory newValue) public {
        uInt256_Dynamic_x_Fixed_MatrixValue = newValue;
    }

    // matrix of int<bits>[size][size] write methods
    function testInt8FixedMatrixValue(int8[3][2] memory newValue) public {
        int8FixedMatrixValue = newValue;
    }

    function testInt32FixedMatrixValue(int32[3][2] memory newValue) public {
        int32FixedMatrixValue = newValue;
    }

    function testInt128FixedMatrixValue(int128[3][2] memory newValue) public {
        int128FixedMatrixValue = newValue;
    }

    function testInt256FixedMatrixValue(int256[3][2] memory newValue) public {
        int256FixedMatrixValue = newValue;
    }

    // matrix of uint<bits>[size][size] write methods
    function testUInt8FixedMatrixValue(uint8[3][2] memory newValue) public {
        uInt8FixedMatrixValue = newValue;
    }

    function testUInt32FixedMatrixValue(uint32[3][2] memory newValue) public {
        uInt32FixedMatrixValue = newValue;
    }

    function testUInt128FixedMatrixValue(uint128[3][2] memory newValue) public {
        uInt128FixedMatrixValue = newValue;
    }

    function testUInt256FixedMatrixValue(uint256[3][2] memory newValue) public {
        uInt256FixedMatrixValue = newValue;
    }

    // read methods of int<bits>[][]
    function getInt8DynamicMatrixValue() public view returns (int8[][] memory) {
        return int8DynamicMatrixValue;
    }

    function getInt32DynamicMatrixValue() public view returns (int32[][] memory) {
        return int32DynamicMatrixValue;
    }

    function getInt128DynamicMatrixValue() public view returns (int128[][] memory) {
        return int128DynamicMatrixValue;
    }

    function getInt256DynamicMatrixValue() public view returns (int256[][] memory) {
        return int256DynamicMatrixValue;
    }

    // read methods of uint<bits>[][]
    function getUInt8DynamicMatrixValue() public view returns (uint8[][] memory) {
        return uInt8DynamicMatrixValue;
    }

    function getUInt32DynamicMatrixValue() public view returns (uint32[][] memory) {
        return uInt32DynamicMatrixValue;
    }

    function getUInt128DynamicMatrixValue() public view returns (uint128[][] memory) {
        return uInt128DynamicMatrixValue;
    }

    function getUInt256DynamicMatrixValue() public view returns (uint256[][] memory) {
        return uInt256DynamicMatrixValue;
    }

    // read methods of int<bits>[size][]
    function getInt8_Fixed_x_Dynamic_MatrixValue() public view returns (int8[4][] memory) {
        return int8_Fixed_x_Dynamic_MatrixValue;
    }

    function getInt32_Fixed_x_Dynamic_MatrixValue() public view returns (int32[4][] memory) {
        return int32_Fixed_x_Dynamic_MatrixValue;
    }

    function getInt128_Fixed_x_Dynamic_MatrixValue() public view returns (int128[4][] memory) {
        return int128_Fixed_x_Dynamic_MatrixValue;
    }

    function getInt256_Fixed_x_Dynamic_MatrixValue() public view returns (int256[4][] memory) {
        return int256_Fixed_x_Dynamic_MatrixValue;
    }

    // read methods of uint<bits>[size][]
    function getUInt8_Fixed_x_Dynamic_MatrixValue() public view returns (uint8[4][] memory) {
        return uInt8_Fixed_x_Dynamic_MatrixValue;
    }

    function getUInt32_Fixed_x_Dynamic_MatrixValue() public view returns (uint32[4][] memory) {
        return uInt32_Fixed_x_Dynamic_MatrixValue;
    }

    function getUInt128_Fixed_x_Dynamic_MatrixValue() public view returns (uint128[4][] memory) {
        return uInt128_Fixed_x_Dynamic_MatrixValue;
    }

    function getUInt256_Fixed_x_Dynamic_MatrixValue() public view returns (uint256[4][] memory) {
        return uInt256_Fixed_x_Dynamic_MatrixValue;
    }

    // read methods of int<bits>[][size]
    function getInt8_Dynamic_x_Fixed_MatrixValue() public view returns (int8[][2] memory) {
        return int8_Dynamic_x_Fixed_MatrixValue;
    }

    function getInt32_Dynamic_x_Fixed_MatrixValue() public view returns (int32[][2] memory) {
        return int32_Dynamic_x_Fixed_MatrixValue;
    }

    function getInt128_Dynamic_x_Fixed_MatrixValue() public view returns (int128[][2] memory) {
        return int128_Dynamic_x_Fixed_MatrixValue;
    }

    function getInt256_Dynamic_x_Fixed_MatrixValue() public view returns (int256[][2] memory) {
        return int256_Dynamic_x_Fixed_MatrixValue;
    }

    // read methods of uint<bits>[][size]
    function getUInt8_Dynamic_x_Fixed_MatrixValue() public view returns (uint8[][2] memory) {
        return uInt8_Dynamic_x_Fixed_MatrixValue;
    }

    function getUInt32_Dynamic_x_Fixed_MatrixValue() public view returns (uint32[][2] memory) {
        return uInt32_Dynamic_x_Fixed_MatrixValue;
    }

    function getUInt128_Dynamic_x_Fixed_MatrixValue() public view returns (uint128[][2] memory) {
        return uInt128_Dynamic_x_Fixed_MatrixValue;
    }

    function getUInt256_Dynamic_x_Fixed_MatrixValue() public view returns (uint256[][2] memory) {
        return uInt256_Dynamic_x_Fixed_MatrixValue;
    }

    // read methods of int<bits>[size][size]
    function getInt8FixedMatrixValue() public view returns (int8[3][2] memory) {
        return int8FixedMatrixValue;
    }

    function getInt32FixedMatrixValue() public view returns (int32[3][2] memory) {
        return int32FixedMatrixValue;
    }

    function getInt128FixedMatrixValue() public view returns (int128[3][2] memory) {
        return int128FixedMatrixValue;
    }

    function getInt256FixedMatrixValue() public view returns (int256[3][2] memory) {
        return int256FixedMatrixValue;
    }

    // read methods of uint<bits>[size][size]
    function getUInt8FixedMatrixValue() public view returns (uint8[3][2] memory) {
        return uInt8FixedMatrixValue;
    }

    function getUInt32FixedMatrixValue() public view returns (uint32[3][2] memory) {
        return uInt32FixedMatrixValue;
    }

    function getUInt128FixedMatrixValue() public view returns (uint128[3][2] memory) {
        return uInt128FixedMatrixValue;
    }

    function getUInt256FixedMatrixValue() public view returns (uint256[3][2] memory) {
        return uInt256FixedMatrixValue;
    }
}