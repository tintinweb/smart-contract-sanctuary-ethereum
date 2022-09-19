/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract StorageBox {
    // slot #0
    uint256 public s0;

    // slot #1
    uint256 public s1;

    // slot #2
    uint256 public s2;

    // slot #3 -> 128-bit part #0
    uint128 public s3p0;
    // slot #3 -> 128-bit part #1
    uint64 public s3p1;

    struct U128Triple {
        uint128 a;
        uint128 b;
        uint128 c;
    }

    // slot #4 -> 128-bit part #0
    uint128 public s4p0;

    // slot #4 -> 128-bit part #1 
    // (unused)

    // slot #5
    // slot #6 -> 128-bit part #0 
    U128Triple public structField;

    // slot #6 -> 128-bit part #1
    // (unused)
    
    // slot #7, 128-bit part #0
    uint128 public s7p0;

    // slot #8
    // slot #9
    uint128[3] staticArray;

    // slot #10
    uint128[] public dynamicArray;

    // slot #11
    mapping (uint128 => uint256) mappingUint128;  

    // slot #12
    mapping (string => uint256) mappingString;

    // slot #13
    bytes26 public bytes26Field;

    // slot #14
    bytes public bytesField;

    // slot #15
    string public stringField;

    function setS0(uint256 _s0) public {
        s0 = _s0;
    }

    function setS1(uint256 _s1) public {
        s1 = _s1;
    }

    function setS2(uint256 _s2) public {
        s2 = _s2;
    }

    function setS3p0(uint128 _s3p0) public {
        s3p0 = _s3p0;
    }

    function setS3p1(uint64 _s3p1) public {
        s3p1 = _s3p1;
    }

    function setS4p0(uint128 _s4p0) public {
        s4p0 = _s4p0;
    }

    function setStruct(uint128 _a, uint128 _b, uint128 _c) public {
        structField.a = _a;
        structField.b = _b;
        structField.c = _c;
    }

    function setStructWhole(U128Triple calldata _struct) external {
        structField = _struct;
    }
    
    function setS7p0(uint128 _s7p0) public {
        s7p0 = _s7p0;
    }

    function setStaticArrayAt(uint index, uint128 value) public {
        staticArray[index] = value;
    }

    function pushIntoDynamicArray(uint128 value) public {
        dynamicArray.push(value);
    }

    function setMappingUint128(uint128 key, uint256 value) public {
        mappingUint128[key] = value;
    }

    function setMappingString(string memory key, uint256 value) public {
        mappingString[key] = value;
    }

    function setBytes26(bytes26 _bytes26) public {
        bytes26Field = _bytes26;
    }

    function setBytes(bytes memory _bytes) public {
        bytesField = _bytes;
    }

    function setString(string memory _string) public {
        stringField = _string;
    }

    function setStorageAt(uint256 slot, uint256 value) public {
        assembly {
            sstore(slot, value)
        }
    }
}