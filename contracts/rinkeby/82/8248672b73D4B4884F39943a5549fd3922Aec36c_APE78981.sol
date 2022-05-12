// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1 <0.9.0;

contract APE78981 {

    string saySomething;

    constructor() {
        saySomething = "Hello World!";
    }

    function speak() public view returns(string memory) {
        return saySomething;
    }
}