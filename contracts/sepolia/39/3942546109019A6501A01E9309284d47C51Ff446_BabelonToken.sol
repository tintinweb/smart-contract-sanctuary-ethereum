/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabelonToken {
    string public name = "Babelon";
    string public symbol = "BLON";
    uint256 public totalSupply = 500000000000; // 500 billion tokens
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) private ownerBalance;
    mapping(address => uint256) private purchaseAmount;
    mapping(address => uint256) private lastPurchaseTimestamp;
    mapping(address => uint256) public lockedUntil;
    mapping(address => uint256) public lastAccumulatedDay;
    mapping(address => uint256) public accumulatedRewards;

    uint256 public publicOfferingSupply = (totalSupply * 50) / 100; // 50% of the total supply for public offering
    uint256 public maxPurchaseAmount = (publicOfferingSupply * 1) / 100; // 1% of the public offering supply
    uint256 public maxPurchaseAmountPerDay = (totalSupply * 1) / 10000; // 1% of the total supply per day
    uint256 public rewardPercentage = 10; // 10% reward for accumulating tokens for 10 consecutive days

    constructor() {
        balanceOf[msg.sender] = totalSupply / 2; // Half of the tokens assigned to the owner's wallet
        balanceOf[address(this)] = publicOfferingSupply; // Public offering supply assigned to the contract
        ownerBalance[msg.sender] = balanceOf[msg.sender]; // Initialize the owner's balance
    }

    function buyTokens(uint256 amount) public {
        require(amount <= maxPurchaseAmount, "Exceeds maximum purchase amount");
        require(
            purchaseAmount[msg.sender] + amount <= maxPurchaseAmount,
            "Exceeds maximum purchase amount per address"
        );

        balanceOf[msg.sender] += amount;
        balanceOf[address(this)] -= amount;

        purchaseAmount[msg.sender] += amount;
        lastPurchaseTimestamp[msg.sender] = block.timestamp / 1 days;
        lockedUntil[msg.sender] = block.timestamp + 90 days; // Lock tokens for 3 months (90 days)
    }

    function transfer(address recipient, uint256 amount) public {
        require(block.timestamp >= lockedUntil[msg.sender], "Tokens are locked");

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
    }

    function getOwnerBalance() public view returns (uint256) {
        return ownerBalance[msg.sender];
    }

    function hideOwnerBalance() public {
        ownerBalance[msg.sender] = 0;
    }

    function accumulateTokens() public {
        uint256 today = block.timestamp / 1 days;

        if (lastAccumulatedDay[msg.sender] + 1 == today) {
            // User accumulated tokens on consecutive days
            accumulatedRewards[msg.sender] += (balanceOf[msg.sender] * rewardPercentage) / 100;
        } else {
            // Reset the accumulated rewards if user breaks the consecutive day streak
            accumulatedRewards[msg.sender] = 0;
        }

        balanceOf[msg.sender] += accumulatedRewards[msg.sender];
        lastAccumulatedDay[msg.sender] = today;
    }

    function getAvailablePurchaseAmount() public view returns (uint256) {
        uint256 remainingAmount = maxPurchaseAmount - purchaseAmount[msg.sender];
        uint256 today = block.timestamp / 1 days;

        if (lastPurchaseTimestamp[msg.sender] != today) {
            return remainingAmount;
        } else {
            uint256 remainingAmountPerDay = maxPurchaseAmountPerDay - purchaseAmount[msg.sender];
            return remainingAmountPerDay;
        }
    }
}