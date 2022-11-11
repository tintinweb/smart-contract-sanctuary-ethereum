/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
 
contract Hello {
    string one = "Hi ";
    string two = ", How are you today ? ";
 
    // Function to return message
    function welcome(string memory _name) public view returns (string memory) {
        return string.concat(one, _name, two);
    }
}