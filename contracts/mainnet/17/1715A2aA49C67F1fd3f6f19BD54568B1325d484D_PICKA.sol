/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;


contract PICKA {

    string public constant name = "Pickacoin";
    string public constant symbol = "PICKA";
    uint8 public constant decimal = 18;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        totalSupply_ = 10000000 * 10 ** decimal; // 10 Millions
        balances[msg.sender] = totalSupply_;
    } 

    function totalSupply() public view returns(uint){
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns(uint){
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }

    function approve(address delegate, uint tokens) public returns(bool){
        allowed[msg.sender][delegate] = tokens;
        emit Approval(msg.sender, delegate, tokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns(uint){
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint tokens) public returns(bool){
        require(tokens <= balances[owner]);
        require(tokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner] - tokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] = tokens;
        balances[buyer] = balances[buyer] + tokens;
        emit Transfer(owner, buyer, tokens);
        return true;
    }
}