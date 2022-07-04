/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.15;

contract HelloWorld {
    string public greet = "Hello World!";
    uint8 a = 1;

    function sayHello() public pure returns (string memory) {
    	return "Hello";
    }

    function incrementA() external {
        a = a + 1;
    }
}