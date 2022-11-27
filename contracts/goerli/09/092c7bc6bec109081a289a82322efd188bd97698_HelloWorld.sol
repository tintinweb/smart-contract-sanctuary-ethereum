/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    uint256 public age = 29;
    string public name = "Phatchara Narinrat";
    address public deployer;
    constructor() {
        deployer = msg.sender;
    }

    function setName(string memory newData)  public{
        require(msg.sender == deployer,"You are not authorized");
        name = newData;
    }

    function setAge(uint256 newAge) public{
        age = newAge;
    }
/*
    function setAge(string memory newData ,uint256 newAge) public{
        name = newData;
        age = newAge;
    }
    */
}