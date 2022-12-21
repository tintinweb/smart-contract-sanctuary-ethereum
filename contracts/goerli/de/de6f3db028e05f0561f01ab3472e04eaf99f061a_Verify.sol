/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor() {}

    function hello(bool sayHello) public pure returns (string memory) {
        if (sayHello) {
            return "hello";
        }
        return "";
    }
}