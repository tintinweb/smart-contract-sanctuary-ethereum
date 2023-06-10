/**
 *Submitted for verification at Etherscan.io on 2023-06-09
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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BSZMEGYToken is IERC20, Ownable {
    string private _name = "baszodjmegmarhogynemmegy";
    string private _symbol = "BSZMEGY";
    uint256 private _decimals = 18;
    uint256 private _totalSupply = 100000 * 10**_decimals;
    uint256 private _maxHoldingPercent = 1;
    uint256 private _tax1Percentage = 25;
    uint256 private _tax2Percentage = 2;
    uint256 private _tax3Percentage = 3;

    address private _tax1Address = 0x592878FDf9e7b2B0AE6A55bf22534133592A139f;
    address private _tax3Address = 0x945AE692Ae6C1EB4237F1C87aa56B06E6EFB385f;
    address private _lpAddress;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function setLPAddress(address lpAddress) external onlyOwner {
        require(_lpAddress == address(0), "LP address already set");
        _lpAddress = lpAddress;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        uint256 tax1Amount = (amount * _tax1Percentage) / 100;
        uint256 tax2Amount = (amount * _tax2Percentage) / 100;
        uint256 tax3Amount = (amount * _tax3Percentage) / 100;

        uint256 transferAmount = amount - tax1Amount - tax2Amount - tax3Amount;
        require(transferAmount > 0, "ERC20: transfer amount after taxes must be greater than zero");

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_tax1Address] += tax1Amount;
        _balances[_tax3Address] += tax3Amount;

        if (_lpAddress != address(0)) {
            uint256 lpAmount = (amount * _tax2Percentage) / 100;
            _balances[_lpAddress] += lpAmount;
            emit Transfer(sender, _lpAddress, lpAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _tax1Address, tax1Amount);
        emit Transfer(sender, _tax3Address, tax3Amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}