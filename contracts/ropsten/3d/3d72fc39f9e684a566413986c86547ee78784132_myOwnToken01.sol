/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

contract SafeMath {
 
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address owner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint remaining);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed owner, address indexed spender, uint tokens);
}
 
contract ApproveAndCallFallBack {
    function getApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
contract myOwnToken01 is ERC20Interface, SafeMath {
    uint public _totalSupply;
    string public  name;
    string public symbol;
    uint8 public decimals;
 
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        name = "myOwnToken01";
        symbol = "MOT1";
        decimals = 0;
        _totalSupply = 100;
        balances[0xB6d0E23fFE9D6cbd23F3dB65B787260573a3CDC3] = _totalSupply;
        emit Transfer(address(0), 0xB6d0E23fFE9D6cbd23F3dB65B787260573a3CDC3, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address owner) public constant returns (uint balance) {
        return balances [owner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = sub(balances[from], tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function allowance(address owner, address spender) public constant returns (uint remaining) {
        return allowed[owner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).getApproval(msg.sender, tokens, this, data);
        return true;
    }
 
    function () public payable {
        revert();
    }
}