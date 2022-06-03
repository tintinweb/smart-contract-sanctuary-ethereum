/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract HelloWorld {

    string saySomething;

    constructor() {
        saySomething = "Hello World!";
    }

    function speak() public view returns(string memory) {
        return saySomething;
    }
}