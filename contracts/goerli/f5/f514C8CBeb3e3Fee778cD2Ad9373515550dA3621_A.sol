/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//call function
//we are going to write contract B to access the funtions of contract A using call function
//we are going to use the contract address from this and use it for the call method
//we can use the functions and variables of contract A in contract B
//the state of contract A changes and the state of contract B does not change
contract A {
    string public car = "benz";
    function thecarA (string memory _car) external {
    car = _car;
    }
}