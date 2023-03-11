/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Testnet {
    string public name = "Testnet";
    string public symbol = "Test";
    uint256 public totalSupply = 5_000_000 * 10 ** 18;
    uint8 public decimals = 18;
    
    address public owner;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender] == true, "Address is not whitelisted");
        _;
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
    }

    function sellTokens(uint256 amount) public onlyOwner {
        require(balances[owner] >= amount, "Insufficient balance");
        balances[owner] -= amount;
        balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
    }

    function sellTokensWhitelisted(uint256 amount) public onlyWhitelisted {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[owner] += amount;
        emit Transfer(msg.sender, owner, amount);
    }
}