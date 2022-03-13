/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// Solidity program to demonstrate
// a constructoor, function and state variable

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Creating a contract
contract App {

    // Declaring state variable
    string str;

    // Creating a constructor
    constructor(string memory _param) {
        
    // to set value of 'str'
        str = _param;

    }

    // Defining function
    function setApp(string memory _HelloWorld) public {
        
    }

    function viewApp() public view returns(string memory) {
        return str;
    }
}