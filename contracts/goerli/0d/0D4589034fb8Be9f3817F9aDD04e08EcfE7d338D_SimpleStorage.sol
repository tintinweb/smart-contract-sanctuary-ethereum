// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Storage {
    enum TestEnum { A, B, C }
    struct SimpleStruct { bytes32 a; uint128 b; uint128 c; }
    struct ComplexStruct {
        int32 a;
        mapping(uint32 => string) b;
    }

    int public minInt256;
    int8 public minInt8;
    uint8 public uint8Test;
    bool public boolTest;
    string public stringTest;
    string public longStringTest;
    bytes public bytesTest;
    bytes public longBytesTest;
    Storage public contractTest;
    TestEnum public enumTest;
    SimpleStruct public simpleStruct;
    ComplexStruct public complexStruct;
    uint64[5] public uint64FixedArray;
    uint128[5][6] public uint128FixedNestedArray;
    uint64[2][2][2] public uint64FixedMultiNestedArray;
    int64[] public int64DynamicArray;
    SimpleStruct[] public simpleStructDynamicArray;
    mapping(string => string) public stringToStringMapping;
    mapping(string => string) public longStringToLongStringMapping;
    mapping(string => uint) public stringToUint256Mapping;
    mapping(string => bool) public stringToBoolMapping;
    mapping(string => address) public stringToAddressMapping;
    mapping(string => SimpleStruct) public stringToStructMapping;
    mapping(uint => string) public uint256ToStringMapping;
    mapping(uint8 => string) public uint8ToStringMapping;
    mapping(uint128 => string) public uint128ToStringMapping;
    mapping(int => string) public int256ToStringMapping;
    mapping(int8 => string) public int8ToStringMapping;
    mapping(int128 => string) public int128ToStringMapping;
    mapping(address => string) public addressToStringMapping;
    mapping(bytes => string) public bytesToStringMapping;
    mapping(string => mapping(string => string)) public nestedMapping;
    mapping(uint8 => mapping(string => mapping(address => uint))) public multiNestedMapping;

    function getComplexStructMappingVal(uint32 _mappingKey) external view returns (string memory) {
        return complexStruct.b[_mappingKey];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Storage } from "./Storage.t.sol";

contract SimpleStorage {
    Storage public myStorage;
}