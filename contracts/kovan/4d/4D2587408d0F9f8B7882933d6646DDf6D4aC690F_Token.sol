/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Token{
    string public name = "SHALALA Token";
    string public symbol = "SHALA";
    address public owner;
    uint public totalSupply = 1000000000;
    mapping(address => uint) balances;

    constructor(){
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint amount) external {
        require(balances[msg.sender] >= amount, 'Not enough tokens');
        // Deduct from sender, Add to receiver 
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

}