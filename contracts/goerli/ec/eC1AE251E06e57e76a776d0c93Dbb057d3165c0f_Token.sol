/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    address public owner;
    mapping(address => bool) public whitelist;
    mapping(address => uint) public balances;

    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        owner = msg.sender;
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

    function sellTokens(uint amount) public onlyOwner {
        balances[owner] -= amount;
        balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
    }

    function sellTokensWhitelisted(uint amount) public onlyWhitelisted {
        balances[msg.sender] -= amount;
        balances[owner] += amount;
        emit Transfer(msg.sender, owner, amount);
    }
}