// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

/// @title Basic Types Test Contract - A test contract to check all basic solidity types in the tx-builder Safe App.
/// @author Daniel Somoza - <[email protected]>
contract BasicTypesTestContract {
    // TODO: ADD int and uint

    // integers
    int8 int8Value;
    int32 int32Value;
    int128 int128Value;
    int256 int256Value;

    uint8 uInt8Value;
    uint32 uInt32Value;
    uint128 uInt128Value;
    uint256 uInt256Value;

    // arrays of integers
    int8[] int8DynamicArrayValue;
    int128[] int128DynamicArrayValue;
    int256[] int256DynamicArrayValue;

    uint8[] uInt8DynamicArrayValue;
    uint128[] uInt128DynamicArrayValue;
    uint256[] uInt256DynamicArrayValue;

    int8[3] int8FixedArrayValue;
    int128[3] int128FixedArrayValue;
    int256[3] int256FixedArrayValue;

    uint8[3] uInt8FixedArrayValue;
    uint128[3] uInt128FixedArrayValue;
    uint256[3] uInt256FixedArrayValue;

    // address
    address addressValue;

    // array of addresses
    address[] addressDynamicArrayValue;
    address[2] addressFixedArrayValue;

    // bool
    bool booleanValue;

    // array of booleans
    bool[] booleanDynamicArrayValue;
    bool[5] booleanFixedArrayValue;

    // string
    string stringValue;

    // array of strings
    string[] stringDynamicArrayValue;
    string[5] stringFixedArrayValue;

    // function (callback)
    function(uint256) external functionValue;

    // bytes
    bytes bytesValue;
    bytes1 bytes1Value;
    bytes2 bytes2Value;
    bytes8 bytes8Value;
    bytes16 bytes16Value;
    bytes32 bytes32Value;

    // array of bytes
    bytes[] bytesDynamicArrayValue;
    bytes1[] bytes1DynamicArrayValue;
    bytes2[] bytes2DynamicArrayValue;
    bytes8[] bytes8DynamicArrayValue;
    bytes16[] bytes16DynamicArrayValue;
    bytes32[] bytes32DynamicArrayValue;

    bytes[3] bytesFixedArrayValue;
    bytes1[3] bytes1FixedArrayValue;
    bytes2[3] bytes2FixedArrayValue;
    bytes8[3] bytes8FixedArrayValue;
    bytes16[3] bytes16FixedArrayValue;
    bytes32[3] bytes32FixedArrayValue;

    // TODO: tuples & structs

    // TODO: multiDimensional arrays of int, uint, address, bool, string, bytes

    // TODO: create a mix method of int, uint, address, bool, string, bytes

    // TODO: create a mix method of array of ints, uints, addresses, bools, strings, bytes

    // TODO: create a mix method of multiDimensional array of ints, uints, addresses, bools, strings, bytes

    // bytes write methods
    function testBytesValue(bytes memory newValue) public {
        bytesValue = newValue;
    }

    function testBytes1Value(bytes1 newValue) public {
        bytes1Value = newValue;
    }

    function testBytes2Value(bytes2 newValue) public {
        bytes2Value = newValue;
    }

    function testBytes8Value(bytes8 newValue) public {
        bytes8Value = newValue;
    }

    function testBytes16Value(bytes16 newValue) public {
        bytes16Value = newValue;
    }

    function testBytes32Value(bytes32 newValue) public {
        bytes32Value = newValue;
    }

    // arrays of bytes write methods
    function testBytesDynamicArrayValue(bytes[] memory newValue) public {
        bytesDynamicArrayValue = newValue;
    }

    function testBytes1DynamicArrayValue(bytes1[] memory newValue) public {
        bytes1DynamicArrayValue = newValue;
    }

    function testBytes2DynamicArrayValue(bytes2[] memory newValue) public {
        bytes2DynamicArrayValue = newValue;
    }

    function testBytes8DynamicArrayValue(bytes8[] memory newValue) public {
        bytes8DynamicArrayValue = newValue;
    }

    function testBytes16DynamicArrayValue(bytes16[] memory newValue) public {
        bytes16DynamicArrayValue = newValue;
    }

    function testBytes32DynamicArrayValue(bytes32[] memory newValue) public {
        bytes32DynamicArrayValue = newValue;
    }

    function testBytesFixedArrayValue(bytes[3] memory newValue) public {
        bytesFixedArrayValue = newValue;
    }

    function testBytes1FixedArrayValue(bytes1[3] memory newValue) public {
        bytes1FixedArrayValue = newValue;
    }

    function testBytes2FixedArrayValue(bytes2[3] memory newValue) public {
        bytes2FixedArrayValue = newValue;
    }

    function testBytes8FixedArrayValue(bytes8[3] memory newValue) public {
        bytes8FixedArrayValue = newValue;
    }

    function testBytes16FixedArrayValue(bytes16[3] memory newValue) public {
        bytes16FixedArrayValue = newValue;
    }

    function testBytes32FixedArrayValue(bytes32[3] memory newValue) public {
        bytes32FixedArrayValue = newValue;
    }

    // function write methods
    function testFuntionValue(function(uint256) external callback) public {
        functionValue = callback;
    }

    // address write methods
    function testAddressValue(address newValue) public {
        addressValue = newValue;
    }

    // arrays of addresses write methods
    function testAddressDynamicArrayValue(address[] memory newValue) public {
        addressDynamicArrayValue = newValue;
    }

    function testAddressFixedArrayValue(address[2] memory newValue) public {
        addressFixedArrayValue = newValue;
    }

    // bool write methods
    function testBooleanValue(bool newValue) public {
        booleanValue = newValue;
    }

    // arrays of booleans write methods
    function testBooleanDynamicArrayValue(bool[] memory newValue) public {
        booleanDynamicArrayValue = newValue;
    }

    function testBooleanFixedArrayValue(bool[5] memory newValue) public {
        booleanFixedArrayValue = newValue;
    }

    // string write methods
    function testStringValue(string memory newValue) public {
        stringValue = newValue;
    }

    // array of strings write methods
    function testStringDynamicArrayValue(string[] memory newValue) public {
        stringDynamicArrayValue = newValue;
    }

    function testStringFixedArrayValue(string[5] memory newValue) public {
        stringFixedArrayValue = newValue;
    }

    // integer write methods
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

    // many ints and uints
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

    // arrays of integers write methods
    function testInt8DynamicArrayValue(int8[] memory newValue) public {
        int8DynamicArrayValue = newValue;
    }

    function testInt128DynamicArrayValue(int128[] memory newValue) public {
        int128DynamicArrayValue = newValue;
    }

    function testInt256DynamicArrayValue(int256[] memory newValue) public {
        int256DynamicArrayValue = newValue;
    }

    function testUInt8DynamicArrayValue(uint8[] memory newValue) public {
        uInt8DynamicArrayValue = newValue;
    }

    function testUInt128DynamicArrayValue(uint128[] memory newValue) public {
        uInt128DynamicArrayValue = newValue;
    }

    function testUInt256DynamicArrayValue(uint256[] memory newValue) public {
        uInt256DynamicArrayValue = newValue;
    }

    function testInt8FixedArrayValue(int8[3] memory newValue) public {
        int8FixedArrayValue = newValue;
    }

    function testInt128FixedArrayValue(int128[3] memory newValue) public {
        int128FixedArrayValue = newValue;
    }

    function testInt256FixedArrayValue(int256[3] memory newValue) public {
        int256FixedArrayValue = newValue;
    }

    function testUInt8FixedArrayValue(uint8[3] memory newValue) public {
        uInt8FixedArrayValue = newValue;
    }

    function testUInt128FixedArrayValue(uint128[3] memory newValue) public {
        uInt128FixedArrayValue = newValue;
    }

    function testUInt256FixedArrayValue(uint256[3] memory newValue) public {
        uInt256FixedArrayValue = newValue;
    }

    // many arrays of integers
    function testManyArrayOfIntValues(
        int8[] memory int8DynamicArrayNewValue,
        int128[] memory int128DynamicArrayNewValue,
        int256[] memory int256DynamicArrayNewValue,
        uint8[] memory uInt8DynamicArrayNewValue,
        uint128[] memory uInt128DynamicArrayNewValue,
        uint256[] memory uInt256DynamicArrayNewValue,
        int8[3] memory int8FixedArrayNewValue,
        int128[3] memory int128FixedArrayNewValue,
        int256[3] memory int256FixedArrayNewValue,
        uint8[3] memory uInt8FixedArrayNewValue,
        uint128[3] memory uInt128FixedArrayNewValue,
        uint256[3] memory uInt256FixedArrayNewValue
    ) public {
        int8DynamicArrayValue = int8DynamicArrayNewValue;
        int128DynamicArrayValue = int128DynamicArrayNewValue;
        int256DynamicArrayValue = int256DynamicArrayNewValue;

        uInt8DynamicArrayValue = uInt8DynamicArrayNewValue;
        uInt128DynamicArrayValue = uInt128DynamicArrayNewValue;
        uInt256DynamicArrayValue = uInt256DynamicArrayNewValue;

        int8FixedArrayValue = int8FixedArrayNewValue;
        int128FixedArrayValue = int128FixedArrayNewValue;
        int256FixedArrayValue = int256FixedArrayNewValue;

        uInt8FixedArrayValue = uInt8FixedArrayNewValue;
        uInt128FixedArrayValue = uInt128FixedArrayNewValue;
        uInt256FixedArrayValue = uInt256FixedArrayNewValue;
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

    // arrays of integers read methods
    function getInt8DynamicArrayValue() public view returns (int8[] memory) {
        return int8DynamicArrayValue;
    }

    function getInt128DynamicArrayValue() public view returns (int128[] memory) {
        return int128DynamicArrayValue;
    }

    function getInt256DynamicArrayValue() public view returns (int256[] memory) {
        return int256DynamicArrayValue;
    }

    function getUInt8DynamicArrayValue() public view returns (uint8[] memory) {
        return uInt8DynamicArrayValue;
    }

    function getUInt128DynamicArrayValue() public view returns (uint128[] memory) {
        return uInt128DynamicArrayValue;
    }

    function getUInt256DynamicArrayValue() public view returns (uint256[] memory) {
        return uInt256DynamicArrayValue;
    }

    function getInt8FixedArrayValue() public view returns (int8[3] memory) {
        return int8FixedArrayValue;
    }

    function getInt128FixedArrayValue() public view returns (int128[3] memory) {
        return int128FixedArrayValue;
    }

    function getInt256FixedArrayValue() public view returns (int256[3] memory) {
        return int256FixedArrayValue;
    }

    function getUInt8FixedArrayValue() public view returns (uint8[3] memory) {
        return uInt8FixedArrayValue;
    }

    function getUInt128FixedArrayValue() public view returns (uint128[3] memory) {
        return uInt128FixedArrayValue;
    }

    function getUInt256FixedArrayValue() public view returns (uint256[3] memory) {
        return uInt256FixedArrayValue;
    }

    // address read methods
    function getAddressValue() public view returns (address) {
        return addressValue;
    }

    function getAddressDynamicArrayValue() public view returns (address[] memory) {
        return addressDynamicArrayValue;
    }

    function getAddressFixedArrayValue() public view returns (address[2] memory) {
        return addressFixedArrayValue;
    }

    // boolean read methods
    function getBooleanValue() public view returns (bool) {
        return booleanValue;
    }

    function getBooleanDynamicArrayValue() public view returns (bool[] memory) {
        return booleanDynamicArrayValue;
    }

    function getBooleanFixedArrayValue() public view returns (bool[5] memory) {
        return booleanFixedArrayValue;
    }

    // string read methods
    function getStringValue() public view returns (string memory) {
        return stringValue;
    }

    function getStringDynamicArrayValue() public view returns (string[] memory) {
        return stringDynamicArrayValue;
    }

    function getStringFixedArrayValue() public view returns (string[5] memory) {
        return stringFixedArrayValue;
    }

    // function read methods
    function getFunctionValue() public view returns (function(uint256) external) {
        return functionValue;
    }

    // bytes read methods
    function getBytesValue() public view returns (bytes memory) {
        return bytesValue;
    }

    function getBytes1Value() public view returns (bytes1) {
        return bytes1Value;
    }

    function getBytes2Value() public view returns (bytes2) {
        return bytes2Value;
    }

    function getBytes8Value() public view returns (bytes8) {
        return bytes8Value;
    }

    function getBytes16Value() public view returns (bytes16) {
        return bytes16Value;
    }

    function getBytes32Value() public view returns (bytes32) {
        return bytes32Value;
    }

    function getBytesDynamicArrayValue() public view returns (bytes[] memory) {
        return bytesDynamicArrayValue;
    }

    function getBytes1DynamicArrayValue() public view returns (bytes1[] memory) {
        return bytes1DynamicArrayValue;
    }

    function getBytes2DynamicArrayValue() public view returns (bytes2[] memory) {
        return bytes2DynamicArrayValue;
    }

    function getBytes8DynamicArrayValue() public view returns (bytes8[] memory) {
        return bytes8DynamicArrayValue;
    }

    function getBytes16DynamicArrayValue() public view returns (bytes16[] memory) {
        return bytes16DynamicArrayValue;
    }

    function getBytes32DynamicArrayValue() public view returns (bytes32[] memory) {
        return bytes32DynamicArrayValue;
    }

    function getBytesFixedArrayValue() public view returns (bytes[3] memory) {
        return bytesFixedArrayValue;
    }

    function getBytes1FixedArrayValue() public view returns (bytes1[3] memory) {
        return bytes1FixedArrayValue;
    }

    function getBytes2FixedArrayValue() public view returns (bytes2[3] memory) {
        return bytes2FixedArrayValue;
    }

    function getBytes8FixedArrayValue() public view returns (bytes8[3] memory) {
        return bytes8FixedArrayValue;
    }

    function getBytes16FixedArrayValue() public view returns (bytes16[3] memory) {
        return bytes16FixedArrayValue;
    }

    function getBytes32FixedArrayValue() public view returns (bytes32[3] memory) {
        return bytes32FixedArrayValue;
    }
}