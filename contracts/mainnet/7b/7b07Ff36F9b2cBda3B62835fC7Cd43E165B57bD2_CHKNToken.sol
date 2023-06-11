/**
 *Submitted for verification at Etherscan.io on 2023-06-11
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

contract CHKNToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public override totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => address) private _originalSenders;

    uint256 private _sellTaxRate = 10; // 0.1% (10 basis points)
    bool private _temporarySellTaxActive;

    address private _owner;

    constructor() {
        name = "Chinese Chicken";
        symbol = "CCHKN";
        decimals = 18;
        totalSupply = 100000000000000 * 10**uint256(decimals);
        _balances[msg.sender] = totalSupply;
        _owner = msg.sender;
        _temporarySellTaxActive = true; // Activate temporary sell tax by default
    }

    modifier onlyOwner() {
        require(_owner != address(0), "Contract owner has renounced ownership");
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _originalSenders[recipient] = msg.sender;
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _originalSenders[recipient] = sender;
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function setTemporarySellTaxActive(bool active) internal onlyOwner {
        _temporarySellTaxActive = active;
    }

    function isTemporarySellTaxActive() internal view onlyOwner returns (bool) {
        return _temporarySellTaxActive;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");

        uint256 sellTaxAmount = 0;
        if (_temporarySellTaxActive && _originalSenders[sender] != _owner) {
            sellTaxAmount = amount * _sellTaxRate / 10000;
            _balances[sender] -= sellTaxAmount;
            _balances[_owner] += sellTaxAmount;
            emit Transfer(sender, _owner, sellTaxAmount);
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    event OwnershipRenounced(address indexed previousOwner);

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }
}