/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

/*

Introducing the Angry Rabbit, a ferocious creature that will stop at nothing to devour its prey.

With razor-sharp teeth and powerful legs, this rabbit is not to be underestimated. 
Beware, for if you cross its path, it will not hesitate to eat you alive. But be warned, 
this rabbit is not to be trifled with, it will attack if you don't shill. 

So stay alert and keep your distance, or risk becoming its next meal.

✅ Ownership Renounced
✅ Liquidity Locked
✅ Taxes : 0/0
✅ 100% tokens in LP

https://t.me/angryrabbit_erc20

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;

contract AR {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Angry Rabbit";
    string public symbol = "AR";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) view public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(to != address(0), 'invalid address');
        require(value > 0, 'invalid value');
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(to != address(0), 'invalid address');
        require(value > 0, 'invalid value');
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        allowance[from][msg.sender] -= value;
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        require(spender != address(0), 'invalid address');
        require(value > 0, 'invalid value');
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}