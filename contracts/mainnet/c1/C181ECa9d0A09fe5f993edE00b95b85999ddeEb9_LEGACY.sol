/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

/*

Legacy Inu - the ultimate crypto influencer and market maven.

With a keen eye for identifying the next big coin and a track record of making profitable trades, 
Legacy Inu is the go-to source for all things cryptocurrency. 

But be warned, if you're not following him on Telegram, you're missing out on valuable insights and risk incurring his legendary wrath.

✅ Ownership Renounced
✅ Liquidity Locked
✅ Taxes : 0/0
✅ 100% tokens in LP

https://t.me/Legacy-Inu
https://Legacy-Inu.com
https://twitter.com/Legacy-Inu

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;

contract LEGACY {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Legacy Inu";
    string public symbol = "LEGACY";
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