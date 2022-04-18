/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SKYToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _ownerSupply;
    uint public tokenPrice;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        symbol = "SKY";
        name = "SKYToken";
        decimals = 0;
        tokenPrice = 0.0001 ether;
        _ownerSupply = 10000;
        _totalSupply = _ownerSupply + 10000;

        balances[msg.sender] = _ownerSupply;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), msg.sender, _ownerSupply);
        emit Transfer(address(0), address(this), _totalSupply);
    }
    
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address sender, address receiver, uint tokens) public override returns (bool success) {
        balances[sender] = safeSub(balances[sender], tokens);
        allowed[sender][msg.sender] = safeSub(allowed[sender][msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(sender, receiver, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function buyToken (uint _tokenAmount) public payable returns (bool success) {
        require(msg.value == _tokenAmount * tokenPrice);
        require(balanceOf(address(this)) >= _tokenAmount);
        
        balances[address(this)] = safeSub(balances[address(this)], _tokenAmount);
        balances[msg.sender] = safeAdd(balances[msg.sender], _tokenAmount);

        emit Transfer(address(this), msg.sender, _tokenAmount);
        return true;
    }
}