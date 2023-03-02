/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

pragma solidity >=0.4.22 <0.9.0;

contract testAAA {
    // generate a struct
    struct person {
        string name;
        uint age;
        address addr;
    }

    // generate test bytes32 functon
    function testHash(bytes32 hash) public pure returns (bytes32) {
        return hash;
    }

    // generate test bytes4 function
    function testBytes4(bytes4 b) public pure returns (bytes4) {
        return b;
    }

    // generate test address functon
    function testAddress(address addr) public pure returns (address) {
        return addr;
    }

    // generate test string functon
    function testString(string memory str) public pure returns (string memory) {
        return str;
    }

    // generate test int8 functon
    function testInt8(int8 num) public pure returns (int8) {
        return num;
    }

    // generate test int16 functon
    function testInt16(int16 num) public pure returns (int16) {
        return num;
    }

    // generate test int32 functon
    function testInt32(int32 num) public pure returns (int32) {
        return num;
    }

    // generate test int64 function
    function testInt64(int64 num) public pure returns (int64) {
        return num;
    }

    // generate test int128 functon
    function testInt128(int128 num) public pure returns (int128) {
        return num;
    }

    // generate test int256 functon
    function testInt256(int256 num) public pure returns (int256) {
        return num;
    }

    // generate test uint8 functon
    function testUint8(uint8 num) public pure returns (uint8) {
        return num;
    }

    // generate test uint16 functon
    function testUint16(uint16 num) public pure returns (uint16) {
        return num;
    }

    // generate test uint32 functon
    function testUint32(uint32 num) public pure returns (uint32) {
        return num;
    }

    // generate test uint64 functon
    function testUint64(uint64 num) public pure returns (uint64) {
        return num;
    }

    // generate test uint128 functon
    function testUint128(uint128 num) public pure returns (uint128) {
        return num;
    }

    // generate test uint256 functon
    function testUint256(uint256 num) public pure returns (uint256) {
        return num;
    }

    // generate test tuple functon
    function testTuple(person memory p) public pure returns (person memory) {
        return p;
    }

    // generate test int8 arr functon
    function int8Arr(int8[] memory nums) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < nums.length; i++) {
            num = num + int256(nums[i]);
        }
        return num;
    }

    function int16Arr(int16[] memory nums) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < nums.length; i++) {
            num = num + int256(nums[i]);
        }
        return num;
    }

    // generate test int32 arr functon
    function int32Arr(int32[] memory nums) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < nums.length; i++) {
            num = num + int256(nums[i]);
        }
        return num;
    }

    // generate test int64 arr functon
    function int64Arr(int64[] memory nums) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < nums.length; i++) {
            num = num + int256(nums[i]);
        }
        return num;
    }

    // generate test int128 arr functon
    function int128Arr(int128[] memory nums) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < nums.length; i++) {
            num = num + int256(nums[i]);
        }
        return num;
    }

    // generate test int256 arr functon
    function int256Arr(int256[] memory nums) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < nums.length; i++) {
            num = num + nums[i];
        }
        return num;
    }

    function testStringArr(string[] memory strArr) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < strArr.length; i++) {
            num++;
        }
        return num;
    }

    // generate test address arr functon
    function testAddressArr(address[] memory addrArr) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < addrArr.length; i++) {
            num++;
        }
        return num;
    }
    
    // test double params int
    function testDoubleInt(int256 num1, int256 num2) public pure returns (int256) {
        return num1 + num2;
    }
    

    function testTupleArr(person[] memory personArr) public pure returns (int256) {
        int256 num = 0;
        for (uint i=0;i < personArr.length; i++) {
            num++;
        }
        return num;
    }
}