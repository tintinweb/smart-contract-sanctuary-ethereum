/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashLabs {
    string public name = "HashLabs";
    string public symbol = "HASH";
    uint256 public totalSupply = 1000000000;
    address public owner;
    
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    function transfer(address to, uint256 value) external {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
    }
    
    function mint(uint256 value) external onlyOwner {
        require(totalSupply + value > totalSupply, "Invalid mint amount");

        totalSupply += value;
        balanceOf[owner] += value;
        emit Mint(owner, value);
    }
}