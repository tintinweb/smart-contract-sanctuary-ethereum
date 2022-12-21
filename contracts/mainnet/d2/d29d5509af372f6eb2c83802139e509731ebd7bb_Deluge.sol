/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: Unlicensed

/*
    Website: https://deluge.cash
    Twitter: https://twitter.com/DelugeCash
    Telegram: https://t.me/delugecashchat
*/

pragma solidity ^0.8.17;

contract Deluge {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    event Transfer(address from, address to, uint256 amount);

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_){
        _name = name_;
        _symbol = symbol_;
        _balances[msg.sender] = totalSupply_;
        _totalSupply = totalSupply_;
    }

    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function decimals() public pure returns(uint8){
        return 18;
    }

    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address addr) public view returns(uint256){
        return _balances[addr];
    }

    function allowance(address owner, address spender) public view returns(uint256){
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) public returns(bool){
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool){
        require(_allowances[from] [msg.sender] >= amount);
        _transfer(from, to, amount);
        _allowances[from] [msg.sender] -= amount;
        return true;
    }

    function approve(address spender, uint256 amount) public returns(bool){
        _approve(msg.sender, spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public returns(bool){
        _approve(msg.sender, spender, _allowances[msg.sender] [spender] - amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual{
        require(from != address(0));
        require(to != address(0));
        require(_balances[from] >= amount);
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual{
        _allowances[owner] [spender] = amount;
    }

    function _decreaseAllowance(address owner, address spender, uint256 amount) internal virtual{
        _allowances[owner] [spender] = amount;
    }
}