/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashLabs {
    string public name = "HashLabs";
    string public symbol = "HASH";
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => bool) private blacklist;
    address private owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    constructor() {
        owner = msg.sender;
        totalSupply = 1000000000;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier notBlacklisted(address _account) {
        require(!blacklist[_account], "Account is blacklisted");
        _;
    }

    function transfer(address _to, uint256 _value) external notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _account) external view returns (uint256) {
        return balances[_account];
    }

    function addToBlacklist(address _account) external onlyOwner {
        blacklist[_account] = true;
        emit BlacklistUpdated(_account, true);
    }

    function removeFromBlacklist(address _account) external onlyOwner {
        blacklist[_account] = false;
        emit BlacklistUpdated(_account, false);
    }

    function isBlacklisted(address _account) external view returns (bool) {
        return blacklist[_account];
    }

    function mint(uint256 _amount) external onlyOwner {
        totalSupply += _amount;
        balances[owner] += _amount;
        emit Transfer(address(0), owner, _amount);
    }
}