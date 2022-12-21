/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    uint256 public age = 27;

    // public, private, internal
    string public name = "PTK on the move";

    function setName(string memory newName) public {
        name = newName; 
    }
    
    function setAge(uint256 newAge) public {
        age = newAge;
    }
}