//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    struct TestStruct {
        uint[] testArr;
    }

    address addr;
    TestStruct testStruct;

    function updateStruct(address _addr, TestStruct[] memory _testStructArr) public {
        addr = _addr;
        testStruct = _testStructArr[0];
    }
}