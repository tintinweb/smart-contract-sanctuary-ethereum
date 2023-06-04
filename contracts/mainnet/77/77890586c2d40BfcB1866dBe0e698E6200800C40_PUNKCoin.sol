/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

contract PUNKCoin is IERC20 {
    string public name = "PUNK Coin";
    string public symbol = "PUNK";
    uint8 public decimals = 18;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklist;
    
    uint256 private _totalSupply;
    uint256 private _maxBuyLimit;
    uint256 private _maxWalletLimit;
    uint256 private _buyTax;
    uint256 private _sellTax;
    address private _owner;
    address private _taxWallet;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }
    
    constructor(address taxWallet) {
        _totalSupply = 1_000_000_000 * 10**decimals;
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        _taxWallet = taxWallet;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
    
    function setMaxBuyLimit(uint256 limit) external onlyOwner {
        _maxBuyLimit = limit;
    }
    
    function setMaxWalletLimit(uint256 limit) external onlyOwner {
        _maxWalletLimit = limit;
    }
    
    function setBuyTax(uint256 tax) external onlyOwner {
        require(tax <= 10, "Buy tax cannot exceed 10%");
        _buyTax = tax;
    }
    
    function setSellTax(uint256 tax) external onlyOwner {
        require(tax <= 90, "Sell tax cannot exceed 90%");
        _sellTax = tax;
    }
    
    function addToBlacklist(address account) external onlyOwner {
        _blacklist[account] = true;
    }
    
    function removeFromBlacklist(address account) external onlyOwner {
        _blacklist[account] = false;
    }
    
    function isBlacklisted(address account) external view returns (bool) {
        return _blacklist[account];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_blacklist[sender], "Sender is blacklisted");
        require(!_blacklist[recipient], "Recipient is blacklisted");
        
        if (sender != _owner && recipient != _owner) {
            require(amount <= (_totalSupply * _maxBuyLimit) / 100, "Transfer amount exceeds the maximum buy limit");
            require(_balances[recipient] + amount <= (_totalSupply * _maxWalletLimit) / 100, "Recipient balance exceeds the maximum wallet limit");
        }
        
        uint256 taxAmount = 0;
        if (sender == _owner) {
            taxAmount = 0;
        } else if (recipient == _owner) {
            taxAmount = (amount * _sellTax) / 100;
        } else {
            taxAmount = (amount * _buyTax) / 100;
        }
        
        uint256 transferAmount = amount - taxAmount;
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _totalSupply -= taxAmount;
        
        emit Transfer(sender, recipient, transferAmount);
        if (taxAmount > 0) {
            emit Transfer(sender, _taxWallet, taxAmount);
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}