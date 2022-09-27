// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface NotHelloWorldInterface {
    function helloWorld() external view returns (string memory);

    function restore() external;
}

contract NotHelloWorld is NotHelloWorldInterface {
    string text = "Not Hello World";

    function helloWorld() public view override returns (string memory) {
        return text;
    }

    function restore() public override {
        text = "Not Hello World";
    }

    receive() external payable {
        text = "Thanks!";
    }

    fallback() external {
        text = "PANIC";
    }
}