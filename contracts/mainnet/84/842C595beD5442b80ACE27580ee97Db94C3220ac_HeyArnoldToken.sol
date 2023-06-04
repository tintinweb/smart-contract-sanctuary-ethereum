/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HeyArnoldToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    address public owner;
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "HeyArnold!";
        symbol = "ARNLD";
        totalSupply = 100000000000000;
        decimals = 9;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function sell(uint256 value) external onlyOwner returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");

        balances[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender, address(0), value);
        return true;
    }
}