/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "My Token";
    string public symbol = "TKN";
    uint public decimals = 18;
    address public owner; 
    // uint256 public sellStartTime = 1657473000; //2022.07.10 7:10:00pm GMT+2
    uint256 public sellStartTime = 1656895529; // for the test
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function balanceOf(address user) public view returns(uint) {
        return balances[user];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(block.timestamp >= sellStartTime || msg.sender == owner || isContract(msg.sender), "Time locked for token sell.");
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(block.timestamp >= sellStartTime || msg.sender == owner || isContract(from), "Time locked for token sell.");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}