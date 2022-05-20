/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string private _name;
    function name() public view returns (string memory) {
        return _name;
    }
    string private _symbol;
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    uint8 private _decimals;
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    uint256 _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    constructor(
        string memory name_, 
        string memory symbol_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = 0;
        _mint(msg.sender, totalSupply_ * 10 ** 18);
    }

    mapping(address => uint256) private _balances;
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    event Transfer(address, address, uint256);
    function transfer(address to, uint256 amount) public returns (bool) {
        address from = msg.sender;
        require(balanceOf(from) >= amount, "you ain't got no money, bruh");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);

        return true;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    event Approval(address, address, uint256);
    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address caller = msg.sender;
        require(allowance(from, caller) >= amount, "you can't spend this money, bruh");
        require(balanceOf(from) >= amount, "this bloke ain't got no money, bruh");

        _allowances[from][caller] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);

        return true;
    }

    function _mint(address account, uint256 amount) private {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}