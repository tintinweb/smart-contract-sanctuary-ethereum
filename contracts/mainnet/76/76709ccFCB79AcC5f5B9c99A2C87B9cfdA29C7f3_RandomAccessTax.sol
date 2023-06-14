/**
 *Submitted for verification at Etherscan.io on 2023-06-14
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

interface IERC20Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract RandomAccessTax is IERC20, IERC20Metadata, Ownable {
    string private _name = "Random Access Tax";
    string private _symbol = "RAT";
    uint8 private _decimals = 18;
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    
    uint256 private _marketingFeePercentage = 50;
    uint256 private _reflectionFeePercentage = 50;
    uint256 private _taxRangeStart = 0;
    uint256 private _taxRangeEnd = 10;
    
    constructor() {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }
    
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view override returns (uint8) {
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
    
    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }
    
    function includeInFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }
    
    function setMarketingFeePercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 100, "Percentage must be between 0 and 100");
        _marketingFeePercentage = percentage;
    }
    
    function setReflectionFeePercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 100, "Percentage must be between 0 and 100");
        _reflectionFeePercentage = percentage;
    }
    
    function setTaxRange(uint256 rangeStart, uint256 rangeEnd) public onlyOwner {
        require(rangeStart >= 0 && rangeStart <= 100, "Range start must be between 0 and 100");
        require(rangeEnd >= rangeStart && rangeEnd <= 100, "Range end must be between range start and 100");
        _taxRangeStart = rangeStart;
        _taxRangeEnd = rangeEnd;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 marketingFeeAmount = amount * _marketingFeePercentage / 100;
        uint256 reflectionFeeAmount = amount * _reflectionFeePercentage / 100;
        uint256 taxedAmount = amount - marketingFeeAmount - reflectionFeeAmount;
        
        _balances[sender] -= amount;
        _balances[recipient] += taxedAmount;
        _balances[address(this)] += marketingFeeAmount;
        
        emit Transfer(sender, recipient, taxedAmount);
        
        if (!_isExcludedFromFees[recipient]) {
            uint256 reflectionFee = taxedAmount * _getRandomTaxPercentage() / 100;
            _balances[recipient] += reflectionFee;
            emit Transfer(sender, recipient, reflectionFee);
        }
        
        if (_balances[address(this)] > 0) {
            _sendMarketingFee(address(this), _balances[address(this)]);
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _getRandomTaxPercentage() private view returns (uint256) {
        uint256 range = _taxRangeEnd - _taxRangeStart + 1;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % range;
        return _taxRangeStart + randomNumber;
    }
    
    function _sendMarketingFee(address sender, uint256 amount) private {
        _balances[sender] -= amount;
        _balances[owner()] += amount;
        emit Transfer(sender, owner(), amount);
    }
}