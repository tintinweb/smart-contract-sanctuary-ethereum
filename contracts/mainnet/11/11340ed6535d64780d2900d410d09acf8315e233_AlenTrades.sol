/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract AlenTrades {

    string public constant name = "Alen Trades";
    string public constant symbol = "ALN";
    uint8 public constant decimals = 6;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalBalance;
    address _owner;
    constructor(uint256 total) {
        _owner = msg.sender;
        totalBalance = total;
        balances[msg.sender] = totalBalance;
    }

    function setOwner(address _newOwner) public {
        require(msg.sender==_owner,"Only owner");
        _owner=_newOwner;
    }

    function totalSupply() public view returns (uint256) {
        return totalBalance;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transfer(address receiver,uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner],"Insufficient balance");
        require(numTokens <= allowed[owner][msg.sender],"Insufficient alloance");
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function burn(uint _amount) public {
        require(msg.sender==_owner,"Only owner");

        balances[msg.sender] -= _amount;
        totalBalance -= _amount;
    }

    event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}