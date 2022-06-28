//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    struct TestStruct {
        address addr;
        uint[] testArr;
    }

    struct TestStruct3 {
        address addr;
        uint num;
    }

    TestStruct public testStruct;
    TestStruct public testStruct2;
    TestStruct3 public testStruct3;
    uint[] testArr;
    uint num;

    function updateStruct(TestStruct[] memory _testStructArr) public {
        testStruct = _testStructArr[0];
    }
    
    function updateTestArr(uint[] memory _testArr) public {
        testArr = _testArr;
    }

    function updateNum(uint _num) public {
        num = _num;
    }

    function updateTestStruct2(TestStruct memory _testStruct) public {
        testStruct2 = _testStruct;
    }

    function updateTestStruct3(TestStruct3 memory _testStruct) public {
        testStruct3 = _testStruct;
    }

    function getFirstTestArrItem() public view returns (uint) {
        return testStruct.testArr[0];
    }
}