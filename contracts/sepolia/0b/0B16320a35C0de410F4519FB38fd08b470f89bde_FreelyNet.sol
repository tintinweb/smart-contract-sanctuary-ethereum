/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelyNet {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public startingPrice;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event StartingPriceSet(uint256 price);
    
    constructor() {
        name = "FreelyNet";
        symbol = "FREELY";
        decimals = 18;
        totalSupply = 1000000000 * 10 ** uint256(decimals); // Total supply of 1,000,000,000 tokens
        
        // Allocate 30% of the total supply to the owner's wallet
        uint256 ownerAllocation = totalSupply * 30 / 100;
        balanceOf[msg.sender] = ownerAllocation;
        emit Transfer(address(0), msg.sender, ownerAllocation);
        
        // Allocate the remaining supply to the contract creator's wallet
        uint256 contractAllocation = totalSupply - ownerAllocation;
        balanceOf[address(this)] = contractAllocation;
        emit Transfer(address(0), address(this), contractAllocation);
        
        // Set the starting price
        startingPrice = 100000000000000000; // 0.1 with 18 decimal places
        emit StartingPriceSet(startingPrice);
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        _transfer(from, to, value);
        _approve(from, msg.sender, allowance[from][msg.sender] - value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}