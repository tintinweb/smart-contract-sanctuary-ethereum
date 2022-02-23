/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract ERC20{
mapping(address => uint256) private _balances;

mapping(address => mapping(address => uint256)) private _allowances;

uint256 private _totalSupply;

string private _name;
string private _symbol;


constructor(string memory name_, string memory symbol_) {
_name = name_;
_symbol = symbol_;
}


function name() public view returns (string memory) {
return _name;
}


function symbol() public view returns (string memory) {
return _symbol;
}


function decimals() public pure returns (uint8) {
return 18;
}


function totalSupply() public view returns (uint256) {
return _totalSupply;
}


function balanceOf(address account) public view returns (uint256) {
return _balances[account];
}


function transfer(address to, uint256 amount) public returns (bool) {
_transfer(msg.sender, to, amount);
return true;
}

function allowance(address owner, address spender) public view returns (uint256) {
return _allowances[owner][spender];
}


function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}


function transferFrom(address from, address to, uint256 amount) public returns (bool) {
_spendAllowance(from, msg.sender, amount);
_transfer(from, to, amount);
return true;
}


function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
_approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
return true;
}


function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
require(_allowances[msg.sender][spender] >= subtractedValue, "ERC20: decreased allowance below zero");

unchecked {
_approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
}

return true;
}



function _mint(address account, uint256 amount) internal {
require(account != address(0), "ERC20: mint to the zero address");
_totalSupply += amount;
_balances[account] += amount;
}


function _burn(address account, uint256 amount) internal {
require(account != address(0), "ERC20: burn from the zero address");
require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
unchecked {
_balances[account] = _balances[account] - amount;
}
_totalSupply -= amount;
}

function _approve(address owner, address spender, uint256 amount) internal {
require(owner != address(0), "ERC20: approve from the zero address");
require(spender != address(0), "ERC20: approve to the zero address");

_allowances[owner][spender] = amount;
}

function _transfer(address from, address to, uint256 amount) internal {
require(from != address(0), "ERC20: transfer from the zero address");
require(to != address(0), "ERC20: transfer to the zero address");
require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

unchecked {
_balances[from] = _balances[from] - amount;
}
_balances[to] += amount;
}

function _spendAllowance(address owner, address spender, uint256 amount) internal {
uint256 currentAllowance = allowance(owner, spender);
if (currentAllowance != type(uint256).max) {
require(currentAllowance >= amount, "ERC20: insufficient allowance");
unchecked {
_approve(owner, spender, currentAllowance - amount);
}
}
}


}