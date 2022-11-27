/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld20221127 {
    uint256 public age = 14;
    string public name = "You lie.";
    address public deployer;

    constructor() {
        deployer = msg.sender;
    }

    function setName(string memory newName) public {
        require(msg.sender == deployer, "You're not authorized. Please request the authorized approve from Vladimir first !!!");
        name = newName;
    }
    // function setAge(uint256 newAge) public {
        //  age = newAge;
    // }
}