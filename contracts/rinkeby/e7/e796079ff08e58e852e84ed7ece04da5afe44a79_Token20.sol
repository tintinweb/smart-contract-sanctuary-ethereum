/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken20 {
    event Transfer(address from, address to, uint amount);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external view returns (uint);
    
    function balanceOf(address account) external view returns (uint);
    
    function transfer(address to, uint amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint);
    
    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface ITokenMetadata is IToken20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

contract Token20 is IToken20, ITokenMetadata {
    address private _owner;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    uint private _totalSupply;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;

    constructor(string memory name_, string memory symbol_) {
        require(bytes(name_).length > 0);
        require(bytes(symbol_).length > 2);

        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;

        mint(msg.sender, 100 * (10 ** _decimals));
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function balanceOf(address addr) external view override returns (uint) {
        return _balances[addr];
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }
    
    function allowance(address owner, address spender) public view override returns (uint) {
        require(owner != spender, "Token20: Error to allow self");
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint value) external override returns (bool) {
        _allowances[msg.sender][spender] = value;
        return true;
    }

    function burn(address from, uint amount) external onlyOwner returns (bool) {
        require(from != address(0), "Token20: Burn from address 0");
        require(_balances[from] >= amount, "Token20: Burn amount exceeds balance");
        
        _balances[from] -= amount;
        _totalSupply -= amount;

        emit Transfer(from, address(0), amount);
        return true;
    }

    function transfer(address recipient, uint value) external override returns (bool) {
        _transfer(msg.sender, recipient, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function _approve(address owner, address spender, uint value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _spendAllowance(address owner, address spender, uint value) internal {
        uint currentAllowance = _allowances[owner][spender];

        require(currentAllowance != type(uint).max);

        _approve(owner, spender, currentAllowance - value);
    }

    function mint(address to, uint amount) public onlyOwner returns (bool) {
        require(to != address(0), "Mint to address 0");
        
        _totalSupply += amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function _transfer(address from, address to, uint value) internal {
        require(to != address(0), "Token20: Transfer to the zero address");

        require(_balances[msg.sender] >= value, "Token20: Transfer amount exceeds balance");

        _balances[from] -= value;
        _balances[to] += value;
        
        emit Transfer(from, to, value);
    }
}