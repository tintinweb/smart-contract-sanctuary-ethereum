/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

//SPDX-License-Identifier: UNLICENSED
//This is the contract for $PepeMars.

//Solidity 0.8.2 - PepeMars Contract available to the public
pragma solidity ^0.8.2;

// PepeMars name, symbol, totalSupply and decimals defined
contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 400000000000000 * 10 ** 18;
    string public name = "PepeMars";
    string public symbol = "PEPEMARS";
    uint public decimals = 18;

//Security Mesures
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    
//PepeMars events (Transfer and Approval)
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval (address indexed PEPEMARSCommunity, address indexed spender, uint value);

//PepeMars constructor 
    constructor() {
        balances[msg.sender] = totalSupply;
    }

//PepeMars Functions (balanceOf)
    function balanceOf(address PEPEMARSCommunity) public view returns(uint) {
        return balances[PEPEMARSCommunity];
    }

//PepeMars Functions (transfer)    
    function transfer(address to, uint value) public noReentrant returns(bool) {
        require(balanceOf(msg.sender) >= value, 'insufficient fund ERROR');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

//PepeMars Functions (transferFrom)     
    function transferFrom(address from, address to, uint value) public noReentrant returns(bool) {
        require(balanceOf(from) >= value, 'insufficient fund ERROR');
        require(allowance[from][msg.sender] >= value, 'insufficient fund ERROR');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

//PepeMars Functions (approve)     
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}