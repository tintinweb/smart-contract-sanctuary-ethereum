/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MemeDogToken {
    string public name = "Meme Dog";
    string public symbol = "DOGE";
    uint256 public totalSupply = 99000000000 * 10 ** 18; // 99 billion tokens
    uint8 public decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address private liquidityWallet;
    address private marketingWallet;
    uint256 private maxWalletPercent = 5; // 5% maximum wallet percentage

    uint256 private liquidityTax = 1; // 1% liquidity tax
    uint256 private marketingTax = 2; // 2% marketing tax
    uint256 private maxTax = 3; // 3% max tax

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(amount <= getMaxWalletTokens(), "Exceeds maximum wallet token limit");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");
        require(amount <= getMaxWalletTokens(), "Exceeds maximum wallet token limit");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setLiquidityTax(uint256 taxPercent) public {
        require(taxPercent <= maxTax, "Invalid tax percentage");
        liquidityTax = taxPercent;
    }

    function setMarketingTax(uint256 taxPercent) public {
        require(taxPercent <= maxTax, "Invalid tax percentage");
        marketingTax = taxPercent;
    }

    function setMarketingWallet(address wallet) public {
        require(wallet != address(0), "Invalid wallet address");
        marketingWallet = wallet;
    }

    function setLiquidityWallet(address wallet) public {
        require(wallet != address(0), "Invalid wallet address");
        liquidityWallet = wallet;
    }

    function setMaxWalletPercent(uint256 percent) public {
        require(percent <= 100, "Invalid percent value");
        maxWalletPercent = percent;
    }

    function transferOwnership(address newOwner) public {
        require(newOwner != address(0), "Invalid owner address");
        balances[newOwner] = balances[msg.sender];
        balances[msg.sender] = 0;
        emit Transfer(msg.sender, newOwner, balances[newOwner]);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid transfer amount");

        uint256 maxWalletTokens = getMaxWalletTokens();
        if (recipient != address(this)) {
            require(balances[recipient] + amount <= maxWalletTokens, "Exceeds maximum wallet token limit");
        }

        uint256 liquidityAmount = (amount * liquidityTax) / 100;
        uint256 marketingAmount = (amount * marketingTax) / 100;
        uint256 transferAmount = amount - liquidityAmount - marketingAmount;

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[liquidityWallet] += liquidityAmount;
        balances[marketingWallet] += marketingAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, liquidityWallet, liquidityAmount);
        emit Transfer(sender, marketingWallet, marketingAmount);
    }

    function getMaxWalletTokens() public view returns (uint256) {
        return (totalSupply * maxWalletPercent) / 100;
    }
}