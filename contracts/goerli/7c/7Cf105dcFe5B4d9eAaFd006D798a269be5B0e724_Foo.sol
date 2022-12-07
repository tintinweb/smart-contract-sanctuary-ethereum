// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Bar {
    event Log(string message);
    function log() public {
        emit Log("Bar is called");
    }
}

contract Foo {
    Bar bar;
    constructor(address _bar) {
        bar = Bar(_bar);
    }
    function callBar() public {
        bar.log();
    }
}