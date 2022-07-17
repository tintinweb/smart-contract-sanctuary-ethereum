/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event TokensMinted(address indexed to, uint256 value, uint256 totalSupply);

}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }

}


contract SadCoin is ERC20Interface, SafeMath {
    string public symbol;
    string public name;
    uint public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address private owner;


    constructor() public {
        symbol = "SAD";
        name = "Sad Coin";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = 20000000000000000000000000;
        emit Transfer(address(0), msg.sender, 20000000000000000000000000);

    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // Approve a user to spend your tokens.
    function approve(address spender, uint256 tokens) public returns (bool success) {
        require(tokens > 0, "Can not approve an amount <= 0, Token.approve()");
        require(tokens <= balances[msg.sender], "Amount is greater than senders balance, Token.approve()");

        allowed[msg.sender][spender] = safeAdd(allowed[msg.sender][spender], tokens);
        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    // Transfer tokens to another address
    function transfer(address to, uint256 tokens) public returns (bool success) {
        // Ensure from address has a sufficient balance
        require(balances[msg.sender] >= tokens, "Insufficient balance");
        
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    // Tranfer on behalf of a user, from one address to another
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(tokens > 0, "Cannot transfer amount <= 0, Token.transferFrom()");
        require(tokens <= balances[from], "Account has insufficient balance, Token.transferFrom()");
        require(tokens <= allowed[from][msg.sender], "msg.sender has insufficient allowance, Token.transferFrom()");

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(from, to, tokens);

        return true;
    }
}