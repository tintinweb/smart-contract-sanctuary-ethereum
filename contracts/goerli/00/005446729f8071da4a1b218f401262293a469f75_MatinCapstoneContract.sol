/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract MatinCapstoneContract{
    string public message = "Hello";
    
    function set(string memory x) public {
        message = x;
    }
    function get() public view returns (string memory) {
        return message;
    }
}