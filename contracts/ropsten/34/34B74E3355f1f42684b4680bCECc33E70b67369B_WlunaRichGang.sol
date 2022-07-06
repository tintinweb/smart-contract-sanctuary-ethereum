/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract WlunaRichGang {

    string public name;
    string public symbol;
    uint8 public decimals;
    address public contractOwner;
    address public burnWallet;
    uint256 public totalSupply;
    uint256 private _maxSupply;
    uint256 private _minSupply;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Bought(address indexed from, address indexed to, uint256 amount);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, uint256 maxSupply_, uint256 minSupply_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        contractOwner = msg.sender;
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
        if(to == contractOwner) {
          burn(value);
          emit Burn(_msgSender(), to, value);
        } else {
          _transfer(_msgSender(), to, value);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[from];
        require(senderBalance >= value, "ERC20: transfer value exceeds balance");
        _balances[from] = senderBalance - value;
        _balances[to] += value;

        emit Transfer(from, to, value);
    }

    function burn(uint256 value) public {
        require(_msgSender() != address(0), "ERC20: burn from the zero address");
        require(totalSupply > _minSupply, "ERC20: can not burn more tokens");
        require(totalSupply - value >= _minSupply, "ERC20: can not burn more tokens");
        uint256 accountBalance = _balances[_msgSender()];
        require(accountBalance >= value, "ERC20: burn value exceeds balance");
        _balances[_msgSender()] = accountBalance - value;
        totalSupply -= value;

        emit Burn(_msgSender(), address(0), value);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
}