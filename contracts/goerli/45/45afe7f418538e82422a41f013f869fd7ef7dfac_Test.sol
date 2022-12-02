/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract Test {
    // The token name
    string public name = "test";

    // The token symbol
    string public symbol = "TST";

    // The address that will receive the tax
    address public taxDestination = 0x68A1212E4FD8185800E3E5AEC2C5194Dd702631C;

    // Total supply of tokens
    uint256 public totalSupply = 100000000;

    // Mapping from addresses to their token balances
    mapping(address => uint256) public balances;

    // Event for when tokens are transferred
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    // Function to mint new tokens
    function mint(uint256 value) public {
        require(msg.sender == address(this), "Only the contract owner can mint tokens");

        // Mint the new tokens
        balances[msg.sender] += value;
        totalSupply += value;
    }

    // Function to transfer tokens
    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value, "Not enough tokens");

        // Transfer the tokens
        balances[msg.sender] -= value;
        balances[to] += value;

        // Transfer the tax
        uint256 tax = value * 5 / 100;
        balances[taxDestination] += tax;

        // Emit the Transfer event
        emit Transfer(msg.sender, to, value);
    }
}