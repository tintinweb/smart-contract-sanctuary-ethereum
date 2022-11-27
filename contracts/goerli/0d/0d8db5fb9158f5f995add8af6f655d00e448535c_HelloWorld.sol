/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    uint256 public age = 32;
    string public name = "Best Jarupum";
    address public deployer;

    constructor() {
        deployer = msg.sender;
    }

    function setName(string memory newName) public {
        require(msg.sender == deployer, "You're not authorized!");
        name = newName;
    }

    function setAge(uint256 newAge) public {
        age = newAge;
    }
}