// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

/// @title Gnosis Safe Test Contract - A test contract to check all solidity types in the tx-builder Safe App.
/// @author Daniel Somoza - <[email protected]>
contract testContract {
    // Integers
    int8 int8Value;
    int32 int32Value;
    int128 int128Value;
    int256 int256Value;

    uint8 uInt8Value;
    uint32 uInt32Value;
    uint128 uInt128Value;
    uint256 uInt256Value;

    // Integer methods
    function testInt8Value(int8 newValue) public {
        int8Value = newValue;
    }

    function testInt32Value(int32 newValue) public {
        int32Value = newValue;
    }

    function testInt128Value(int128 newValue) public {
        int128Value = newValue;
    }

    function testInt256Value(int256 newValue) public {
        int256Value = newValue;
    }

    function testUInt8Value(uint8 newValue) public {
        uInt8Value = newValue;
    }

    function testUInt32Value(uint32 newValue) public {
        uInt32Value = newValue;
    }

    function testUInt128Value(uint128 newValue) public {
        uInt128Value = newValue;
    }

    function testUInt256Value(uint256 newValue) public {
        uInt256Value = newValue;
    }

    // many ints and uints values
    function testManyIntValues(
        int8 int8NewValue,
        int32 int32NewValue,
        int128 int128NewValue,
        int256 int256NewValue,
        uint8 uInt8NewValue,
        uint32 uInt32NewValue,
        uint128 uInt128NewValue,
        uint256 uInt256NewValue
    ) public {
        int8Value = int8NewValue;
        int32Value = int32NewValue;
        int128Value = int128NewValue;
        int256Value = int256NewValue;
        uInt8Value = uInt8NewValue;
        uInt32Value = uInt32NewValue;
        uInt128Value = uInt128NewValue;
        uInt256Value = uInt256NewValue;
    }

    //  methods to read values
    function getInt8Value() public view returns (int8) {
        return int8Value;
    }

    function getInt32Value() public view returns (int32) {
        return int32Value;
    }

    function getInt128Value() public view returns (int128) {
        return int128Value;
    }

    function getInt256Value() public view returns (int256) {
        return int256Value;
    }

    function getUInt8Value() public view returns (uint8) {
        return uInt8Value;
    }

    function getUInt32Value() public view returns (uint32) {
        return uInt32Value;
    }

    function getUInt128Value() public view returns (uint128) {
        return uInt128Value;
    }

    function getUInt256Value() public view returns (uint256) {
        return uInt256Value;
    }
}