// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestContract {
    uint256 public immutable IMMUTABLE_TEST_UINT;
    uint256 private testUint = 0;

    event IncrementedTestUint();

    constructor(uint256 _immutable_test_uint) {
        IMMUTABLE_TEST_UINT = _immutable_test_uint;
    }

    function incrementTestUint() external {
        testUint += 1;
        emit IncrementedTestUint();
    }

    function decrementTestUint() external {
        require(testUint > 0, "testUint is 0");
        testUint -= 1;
    }

    function getTestUint() external view returns (uint256) {
        return testUint;
    }
}