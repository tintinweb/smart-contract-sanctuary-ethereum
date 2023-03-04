//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Greeter {
    address private greeting;

    constructor(address _greeting) {
        greeting = _greeting;
    }
}