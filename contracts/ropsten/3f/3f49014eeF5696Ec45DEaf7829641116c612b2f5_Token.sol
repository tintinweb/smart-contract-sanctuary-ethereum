// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Token{
    string public name = "GOLD LION Finance";
    string public symbol= "GLF";
    uint256 public totalSupply = 10000000;
    uint8 public decimal = 8;
    address public owner;

    mapping(address=>uint256) balances;

    constructor(){
        balances[msg.sender] =  totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender]>= amount,"Not enough tokens");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    function balanceOf(address account) external view returns(uint256){
        return balances[account];
    }
}