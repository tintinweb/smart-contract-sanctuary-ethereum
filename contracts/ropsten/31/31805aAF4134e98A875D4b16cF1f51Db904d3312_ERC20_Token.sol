/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20_Token {
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
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 6;
        _totalSupply = 0;
        _mint(msg.sender, 50000000 * 10 ** 6);
    }

    mapping(address => uint256) private _balances;
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0));
        return _balances[account];
    }

    event Transfer(address indexed, address indexed, uint256);
    function transfer(address to, uint256 amount) public returns (bool) {
        address from = msg.sender;
        require(balanceOf(from) >= amount);
        require(to != address(0));

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);

        return true;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    event Approval(address indexed, address indexed, uint256);
    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(balanceOf(from) >= amount);

        address caller = msg.sender;
        if (from != caller) {
            uint256 oldAllowance = allowance(from, caller);
            require(oldAllowance >= amount);

            uint256 newAllowance = oldAllowance - amount;
            _allowances[from][caller] = newAllowance;
            emit Approval(from, caller, newAllowance);
        }

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