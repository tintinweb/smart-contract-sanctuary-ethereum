/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GameZoneToken {
    string public name = "GameZone";
    string public symbol = "GMZe";
    uint256 public totalSupply = 100000000 * 10**18; // 100 million tokens
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) private lastTransactionTime;
    uint256 private transactionLimitTime = 5 seconds; // Adjust the time limit as needed

    address public owner;
    uint256 public publicSupply = (totalSupply * 50) / 100; // 50% of the total supply for public offering

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply / 2; // Half of the tokens assigned to the owner's wallet
        balanceOf[address(this)] = publicSupply; // Public offering supply assigned to the contract
        isWhitelisted[owner] = true; // Owner address is whitelisted
    }

    function transfer(address recipient, uint256 amount) public {
        require(block.timestamp >= lastTransactionTime[msg.sender] + transactionLimitTime, "Transaction rate limit exceeded");
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        lastTransactionTime[msg.sender] = block.timestamp;
    }

    function burn(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
    }

    function whitelistAddress(address _address) public onlyOwner {
        isWhitelisted[_address] = true;
    }

    function removeAddressFromWhitelist(address _address) public onlyOwner {
        isWhitelisted[_address] = false;
    }

    function buyTokens(uint256 amount) public {
        require(isWhitelisted[msg.sender], "Address not whitelisted");
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf[address(this)] >= amount, "Insufficient token balance in contract");

        balanceOf[msg.sender] += amount;
        balanceOf[address(this)] -= amount;

        emit Transfer(address(this), msg.sender, amount);
    }
}