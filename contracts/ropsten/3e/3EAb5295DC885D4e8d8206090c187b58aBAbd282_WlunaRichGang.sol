/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract WlunaRichGang {

    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    address public burnWallet;
    uint256 public totalSupply;
    uint256 private _maxSupply;
    uint256 private _minSupply;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, uint256 maxSupply_, uint256 minSupply_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        owner = msg.sender;
        burnWallet = msg.sender;
        totalSupply = totalSupply_;
        _maxSupply = maxSupply_;
        _minSupply = minSupply_;
        _balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        if(to == owner) {
          burn(value);
        } else {
          _transfer(_msgSender(), to, value);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal virtual {
        require(from != address(0));
        require(to != address(0));
        uint256 senderBalance = _balances[from];
        require(senderBalance >= value);
        _balances[from] = senderBalance - value;
        _balances[to] += value;
    }

    function burn(uint256 value) public {
        require(_msgSender() != address(0));
        require(totalSupply > _minSupply);
        require(totalSupply - value >= _minSupply);
        uint256 accountBalance = _balances[_msgSender()];
        require(accountBalance >= value);
        _balances[_msgSender()] = accountBalance - value;
        totalSupply -= value;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount);
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue);
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function allowance(address from, address spender) external view returns (uint256) {
        return _allowances[from][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address from, address spender, uint256 amount) internal virtual {
        require(from != address(0));
        require(spender != address(0));

        _allowances[from][spender] = amount;
    }
    
}