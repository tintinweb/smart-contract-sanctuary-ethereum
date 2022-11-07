/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Starter {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    string public name = "Starter";string public symbol = "$Start";uint8 public decimals = 18;uint256 public totalSupply = 1e8 ether;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    constructor() {unchecked {balanceOf[msg.sender] = totalSupply;}}
    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balanceOf[msg.sender], "exceeds of balance");
        balanceOf[msg.sender] = balanceOf[msg.sender] - numTokens;
        balanceOf[receiver] = balanceOf[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;}
    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowance[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;}
    function transferFrom(address owner, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balanceOf[owner], "exceeds of balance");
        uint256 currentAllowance = allowance[owner][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        if (currentAllowance != type(uint256).max) {unchecked {allowance[owner][msg.sender] = allowance[owner][msg.sender] - amount;}}
        balanceOf[owner] = balanceOf[owner] - amount;
        balanceOf[recipient] = balanceOf[recipient] + amount;
        emit Transfer(owner, recipient, amount);
        return true;}}