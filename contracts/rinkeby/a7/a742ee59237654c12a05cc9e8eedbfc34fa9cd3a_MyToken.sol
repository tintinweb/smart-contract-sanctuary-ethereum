/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MyToken
pragma solidity ^0.8.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address receiver, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address owner, address receiver, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MyToken is ERC20Interface  {
    // ERC20 tokens also feature additional fields
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;  // Two dimensional array

    constructor() {
        name = "MyTokenNameUpdated";
        symbol = "MTN";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;  //number of token

        balances[msg.sender] = _totalSupply; // Intraction adddress

        emit Transfer(address(0), msg.sender, _totalSupply);  // Creating zero blocks with 0x0000 address
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address receiver, uint tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[receiver] = balances[receiver] - tokens;
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }

    function transferFrom(address owner, address receiver, uint tokens) public override returns (bool success) {
        balances[owner] = balances[owner] - tokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(owner, receiver, tokens);
        return true;
    }
}