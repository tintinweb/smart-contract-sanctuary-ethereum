/**
 *Submitted for verification at Etherscan.io on 2023-06-10
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
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

interface INFT {
    function createNFT(address recipient, uint256 tokenId) external;
    // Outras funcionalidades do NFT podem ser adicionadas aqui
}

contract EcoVerseToken {
    string public name = "EcoVerse";
    string public symbol = "ECV";
    uint8 public decimals = 18;
    uint256 public totalSupply = 460 * 10**12 * 10**uint256(decimals);
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 public marketingFeePercentage = 5;
    address public marketingWallet;
    address public owner;
    address public nftContractAddress;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed account, uint256 amount);

    constructor(address _marketingWallet, address _nftContractAddress) {
        marketingWallet = _marketingWallet;
        owner = msg.sender;
        nftContractAddress = _nftContractAddress;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint

currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowances[account][msg.sender];
        require(currentAllowance >= amount, "Burn amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function setMarketingFeePercentage(uint256 _percentage) public onlyOwner {
        require(_percentage <= 100, "Percentage must be between 0 and 100");
        marketingFeePercentage = _percentage;
    }

    function createNFT(address recipient, uint256 tokenId) public onlyOwner {
        INFT(nftContractAddress).createNFT(recipient, tokenId);
    }

    // Implemente a funcionalidade da roleta e outras funcionalidades conforme necessário

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balances[sender], "Insufficient balance");

        uint256 marketingFee = (amount * marketingFeePercentage) / 100;
        uint256 transferAmount = amount - marketingFee;

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[marketingWallet] += marketingFee;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, marketingWallet, marketingFee);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "Burn from the zero address");
        require(amount > 0, "Burn amount must be greater than zero");
        require(amount <= balances[account], "Insufficient balance");

        balances[account] -= amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }
}