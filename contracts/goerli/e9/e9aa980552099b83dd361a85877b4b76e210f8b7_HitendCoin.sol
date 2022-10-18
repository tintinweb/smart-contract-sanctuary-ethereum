/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ERC20TokenInterface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BasicMaths {
    function newbasicAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c > a);
    }

    function newbasicSub(uint a, uint b) public pure returns (uint c) {
        require(a >= b);
        c = a - b;
    }
 
    function newbasicMul(uint a, uint b) public pure returns (uint c) {
        require(a >= b && b > 1);
        c = a * b;
        require(c / a == b);
    }

    function newbasicDiv(uint a, uint b) public pure returns (uint c) {
        require(a > b && b > 0);
        c = a/b;
    }
}

contract HitendCoin is ERC20TokenInterface, BasicMaths {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        name = "HitendaToken";
        symbol = "HTO";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() override public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) override public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) override public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) override public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) override public returns (bool success) {
        balances[msg.sender] = newbasicSub(balances[msg.sender], tokens);
        balances[to] = newbasicAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
        balances[from] = newbasicSub(balances[from], tokens);
        allowed[from][msg.sender] = newbasicSub(allowed[from][msg.sender], tokens);
        balances[to] = newbasicAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}