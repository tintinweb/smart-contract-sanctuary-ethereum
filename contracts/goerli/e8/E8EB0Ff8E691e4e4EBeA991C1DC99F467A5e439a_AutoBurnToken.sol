/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AutoBurnToken is IERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public constant burnTaxPercentage = 5;
    uint256 public constant sellTaxPercentage = 5;

    event Burn(address indexed from, uint256 amount);
    
    constructor() {
        name = "AutoBurn Token";
        symbol = "ABT";
        decimals = 18;
        _totalSupply = 49999 * (10 ** decimals);
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        uint256 burnAmount = calculateTax(amount, burnTaxPercentage);
        uint256 netAmount = amount - burnAmount;

        _balances[msg.sender] -= amount;
        _balances[recipient] += netAmount;

        emit Transfer(msg.sender, recipient, netAmount);
        
        if (burnAmount > 0) {
            _totalSupply -= burnAmount;
            emit Burn(msg.sender, burnAmount);
        }

        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");

        uint256 burnAmount = calculateTax(amount, burnTaxPercentage);
        uint256 netAmount = amount - burnAmount;

        _balances[sender] -= amount;
        _balances[recipient] += netAmount;

        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, netAmount);
        
        if (burnAmount > 0) {
            _totalSupply -= burnAmount;
            emit Burn(sender, burnAmount);
        }

        return true;
    }

    function calculateTax(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return (amount * percentage) / 100;
    }
}