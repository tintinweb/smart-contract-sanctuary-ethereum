/**
 *Submitted for verification at Etherscan.io on 2023-03-19
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

contract BitCoin is IERC20 {
    string public constant name = "Bit Coin";
    string public constant symbol = "BTC";
    uint8 public constant decimals = 6;
    uint256 private constant _initialSupply = 10000 * 10 ** decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _pancakeSwap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private _marketingAddress = 0x6bAf3Cff4990Ab11BcD83b3904dd1640e1d79067;
    address private _dividendContract = 0x55d398326f99059fF775485246999027B3197955;
    uint256 private _minDividendBalance = 100 * 10 ** decimals;
    uint256 private _buyLiquidityFee = 2;
    uint256 private _buyMarketingFee = 2;
    uint256 private _buyDividendFee = 3;
    uint256 private _buyBurnFee = 4;
    uint256 private _sellLiquidityFee = 2;
    uint256 private _sellMarketingFee = 2;
    uint256 private _sellDividendFee = 3;
    uint256 private _sellBurnFee = 4;
    address private owner = msg.sender;
    uint256 private _maxTxAmount = 1000000000000000000; // 1 ETH

    constructor() {
        _totalSupply = _initialSupply;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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

 
    function allowance(address _owner, address spender) public view override returns (uint256) {
    return _allowances[_owner][spender];
    }


    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        bool takeFee = true;
        if (recipient == _pancakeSwap) {
            takeFee = false;
        }
        if (sender != msg.sender && recipient != msg.sender) {
    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
    if (recipient == _dividendContract) {
        require(senderBalance - amount >= _minDividendBalance, "Balance must be greater than minDividendBalance to transfer to dividend contract");
        }
    }
        uint256 liquidityFee = 0;
        uint256 marketingFee = 0;
        uint256 dividendFee = 0;
        uint256 burnFee = 0;
        if (takeFee) {
            if (recipient == _pancakeSwap) {
                liquidityFee = amount * _buyLiquidityFee / 100;
                marketingFee = amount * _buyMarketingFee / 100; 
                dividendFee = amount * _buyDividendFee / 100;
                burnFee = amount * _buyBurnFee / 100;
            } else {
                liquidityFee = amount * _sellLiquidityFee / 100;
                marketingFee = amount * _sellMarketingFee / 100;
                dividendFee = amount * _sellDividendFee / 100;
                burnFee = amount * _sellBurnFee / 100;
            }
            _balances[_marketingAddress] += marketingFee;
            _balances[address(0)] += burnFee;
            _balances[_pancakeSwap] += liquidityFee;
            _balances[_dividendContract] += dividendFee;
            emit Transfer(sender, _marketingAddress, marketingFee);
            emit Transfer(sender, address(0), burnFee);
            emit Transfer(sender, _pancakeSwap, liquidityFee);
            emit Transfer(sender, _dividendContract, dividendFee);
        }
        uint256 transferAmount = amount - liquidityFee - marketingFee - dividendFee - burnFee;
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_dividendContract] += dividendFee;
        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _dividendContract, dividendFee);
    }

   function _approve(address _owner, address spender, uint256 amount) private {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[_owner][spender] = amount;
    emit Approval(_owner, spender, amount);
    }
}