//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    struct TestStruct {
        address addr;
        uint[] testArr;
    }

    TestStruct public testStruct;

    function updateStruct(TestStruct[] memory _testStructArr) public {
        testStruct = _testStructArr[0];
    }
}