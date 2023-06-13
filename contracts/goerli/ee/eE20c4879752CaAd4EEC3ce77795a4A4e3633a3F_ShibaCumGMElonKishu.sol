// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";

contract ShibaCumGMElonKishu is ERC20, Ownable {
    // Links to social media accounts
    string public constant TWITTER_LINK = "https://twitter.com/scgmektafminu?s=21&t=3vuL4hhTdPG6WhyRTL3ccw";
    string public constant TELEGRAM_LINK = "https://t.me/+zkpSh3V9Bf9hZTZk";

    // Mapping to keep track of blacklisted addresses
    mapping(address => bool) public isBlacklisted;

    // Mapping to keep track of locked liquidity
    mapping(address => uint256) public lockedLiquidity;

    // Mapping to store timestamp when liquidity can be withdrawn
    mapping(address => uint256) public liquidityUnlockTime;

    // Token price in Wei
    uint256 public tokenPriceInWei = 0.0001 ether; // For example, 1 token = 1 Ether

    // Events
    event Blacklisted(address indexed target);
    event Unblacklisted(address indexed target);
    event LiquidityLocked(address indexed account, uint256 amount, uint256 unlockTime);
    event LiquidityWithdrawn(address indexed account, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint initialSupply,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        require(initialSupply > 0, "Initial supply has to be greater than 0");
        _mint(address(this), initialSupply * 10 ** 18); // Mint tokens to the contract itself for selling
    }

    // Modifier to check if sender is not blacklisted
    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "Address is blacklisted");
        _;
    }

    // Function to buy tokens by sending Ether
    function buyTokens() external payable notBlacklisted {
        uint256 tokensToBuy = msg.value / tokenPriceInWei;
        require(tokensToBuy > 0, "Not enough Ether to buy tokens");
        _transfer(address(this), msg.sender, tokensToBuy * 10 ** 18);
    }

    // Function to blacklist an address
    function blacklistAddress(address _address) external onlyOwner {
        isBlacklisted[_address] = true;
        emit Blacklisted(_address);
    }

    // Function to remove an address from blacklist
    function unblacklistAddress(address _address) external onlyOwner {
        isBlacklisted[_address] = false;
        emit Unblacklisted(_address);
    }

    // Function to lock liquidity
    function lockLiquidity(uint256 amount, uint256 unlockTime) external notBlacklisted {
        require(amount > 0, "Amount should be greater than 0");
        require(unlockTime > block.timestamp, "Unlock time should be in the future");
        
        // Transfer tokens to this contract
        _transfer(msg.sender, address(this), amount);
        
        // Set locked liquidity amount and unlock time
        lockedLiquidity[msg.sender] = lockedLiquidity[msg.sender] + amount;
        liquidityUnlockTime[msg.sender] = unlockTime;
        
        emit LiquidityLocked(msg.sender, amount, unlockTime);
    }
    
    // Function to withdraw locked liquidity
    function withdrawLiquidity() external notBlacklisted {
        require(liquidityUnlockTime[msg.sender] <= block.timestamp, "Liquidity is still locked");
        uint256 amount = lockedLiquidity[msg.sender];
        require(amount > 0, "No locked liquidity to withdraw");
        
        // Reset locked liquidity
        lockedLiquidity[msg.sender] = 0;
        
        // Transfer tokens back to the user
        _transfer(address(this), msg.sender, amount);

        emit LiquidityWithdrawn(msg.sender, amount);
    }

    // Function to burn tokens from the caller's account
    function burn(uint256 amount) external notBlacklisted {
        _burn(msg.sender, amount);
    }

    // Function to withdraw Ether from the contract (only by owner)
    function withdrawEther(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }
}