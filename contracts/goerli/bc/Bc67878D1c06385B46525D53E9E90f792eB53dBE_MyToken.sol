/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private lockedWallets;
    mapping(address => bool) private whitelistedWallets;

    uint256 public taxFee;
    uint256 public lotteryFee;
    address public lotteryAddress;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event WalletLocked(address indexed wallet);
    event WalletUnlocked(address indexed wallet);
    event WalletWhitelisted(address indexed wallet);
    event WalletBlacklisted(address indexed wallet);
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        uint256 _taxFee,
        uint256 _lotteryFee,
        address _lotteryAddress
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * (10**uint256(decimals));
        taxFee = _taxFee;
        lotteryFee = _lotteryFee;
        lotteryAddress = _lotteryAddress;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount > 0, "Amount must be greater than zero.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        require(!lockedWallets[msg.sender], "Sender wallet is locked.");
        require(whitelistedWallets[recipient], "Recipient is not whitelisted.");

        uint256 taxAmount = (amount * taxFee) / 100;
        uint256 lotteryAmount = (amount * lotteryFee) / 100;

        balances[msg.sender] -= amount;
        balances[recipient] += amount - taxAmount - lotteryAmount;
        balances[lotteryAddress] += lotteryAmount;

        emit Transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, lotteryAddress, lotteryAmount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount > 0, "Amount must be greater than zero.");
        require(balances[sender] >= amount, "Insufficient balance.");
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance.");
        require(!lockedWallets[sender], "Sender wallet is locked.");
        require(whitelistedWallets[recipient], "Recipient is not whitelisted.");

        uint256 taxAmount = (amount * taxFee) / 100;
        uint256 lotteryAmount = (amount * lotteryFee) / 100;

        balances[sender] -= amount;
        balances[recipient] += amount - taxAmount - lotteryAmount;
        balances[lotteryAddress] += lotteryAmount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, lotteryAddress, lotteryAmount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(amount > 0, "Amount must be greater than zero.");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(addedValue > 0, "Added value must be greater than zero.");

        allowances[msg.sender][spender] += addedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(subtractedValue > 0, "Subtracted value must be greater than zero.");

        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Allowance is lower than the subtracted value.");

        allowances[msg.sender][spender] = currentAllowance - subtractedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);

        return true;
    }

    function lockWallet(address wallet) public onlyOwner {
        lockedWallets[wallet] = true;

        emit WalletLocked(wallet);
    }

    function unlockWallet(address wallet) public onlyOwner {
        lockedWallets[wallet] = false;

        emit WalletUnlocked(wallet);
    }

    function whitelistWallet(address wallet) public onlyOwner {
        whitelistedWallets[wallet] = true;

        emit WalletWhitelisted(wallet);
    }

    function blacklistWallet(address wallet) public onlyOwner {
        whitelistedWallets[wallet] = false;

        emit WalletBlacklisted(wallet);
    }

    function updateTaxFee(uint256 newTaxFee) public onlyOwner {
        require(newTaxFee >= 0 && newTaxFee <= 100, "Tax fee must be between 0 and 100.");

        taxFee = newTaxFee;
    }

    function updateLotteryFee(uint256 newLotteryFee) public onlyOwner {
        require(newLotteryFee >= 0 && newLotteryFee <= 100, "Lottery fee must be between 0 and 100.");

        lotteryFee = newLotteryFee;
    }

    function updateLotteryAddress(address newLotteryAddress) public onlyOwner {
        lotteryAddress = newLotteryAddress;
    }
}