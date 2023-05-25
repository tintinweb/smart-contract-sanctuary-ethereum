/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's ERC20 Token
//
// https://github.com/bokkypoobah/Dexz
//
// SPDX-License-Identifier: MIT
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2023. The MIT Licence.
// ----------------------------------------------------------------------------


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}


contract Token is IERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(string memory _symbol, string memory _name, uint8 _decimals, uint fixedSupply) {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        _totalSupply = fixedSupply;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function totalSupply() external view override returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    function balanceOf(address tokenOwner) external view override returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) external override returns (bool success) {
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) external override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) external override returns (bool success) {
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) external view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}