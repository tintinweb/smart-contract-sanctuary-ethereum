/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

contract Verify {
    string private greeting;

    constructor() {
    }

    function hello(bool sayHello) public pure returns (string memory) {
        if(sayHello) {
            return "hello";
        }
        return "";
    }
}