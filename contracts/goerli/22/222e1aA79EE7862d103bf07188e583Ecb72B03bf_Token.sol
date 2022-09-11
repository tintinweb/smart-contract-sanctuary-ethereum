/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;


contract Token {
    string public name = "Burnable Token";
    string public symbol = "BRT";
    uint256 public totalSupply = 1_000_000_000_000_000_000_00;
    address public owner;
    uint256 public decimals;
    uint256 burningTime = block.timestamp;

    mapping(address => uint256) balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner!");
        _;
    }

    modifier checkBurningTime() {
        require(block.timestamp >= burningTime + 5 minutes, "invalid timestamp");
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        decimals = 18;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function burnTokens(uint256 amount) external onlyOwner checkBurningTime {
         require(balances[msg.sender] >= amount, "Not enough tokens");
        
        balances[msg.sender] -= amount;
        

        emit Transfer(msg.sender, address(0), amount);
    }
}