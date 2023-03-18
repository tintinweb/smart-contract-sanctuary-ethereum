// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Caller {
    Callee public callee;

    constructor(Callee _callee) {
        callee = _callee;
    }

    function callCallee() public returns (uint256) {
        return callee.doSomething();
    }
}

contract Callee {
    uint256 public value;

    function doSomething() public returns (uint256) {
        value = value + 1;
        return value;
    }
}