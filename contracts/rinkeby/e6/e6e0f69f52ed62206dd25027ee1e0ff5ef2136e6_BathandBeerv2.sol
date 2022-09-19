/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BathandBeerv2{
    string[] public nameArray;
    uint[] public studentID;
    address[] public walletAddress;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender, "No Permission");
        _;
    }

    function addName(string memory name, uint256 id) public{
        nameArray.push(name);
        studentID.push(id);
        walletAddress.push(msg.sender);
    }
}