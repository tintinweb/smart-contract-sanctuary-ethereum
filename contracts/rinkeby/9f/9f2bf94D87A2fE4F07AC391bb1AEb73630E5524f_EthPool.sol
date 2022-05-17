// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EthPool {
    struct PoolDeposit {
        uint256 epoch; // epoch = first not calculated interest
        uint256 amount;
    }

    struct PoolRewards {
        uint256 amount;
        uint256 poolWeight;
    }

    PoolRewards[] public rewards;

    address public owner;
    mapping(address => PoolDeposit) public deposits;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid Owner Account.");
        _;
    }

    // Deposit new rewards to the pool
    // constraints :
    // Just the owner could deposit rewards.
    // Can't deposit without users in the pool because this will lead to inaccessible funds.
    function depositRewards() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No active users.");
        rewards.push(PoolRewards(msg.value, balance - msg.value));
    }

    // Deposit eth in the pool
    // I assume that the owner can participate as depositant.
    // If the used have a previous balance in the pool, first calculate the total balance
    // with all rewards (& compound interest), then add the new deposit to the balance and update the epoch
    // epoch = first not calculated interest
    function depositToPool() public payable {
        PoolDeposit memory lastDeposit = deposits[msg.sender];
        uint256 depositAmount = lastDeposit.amount;
        PoolRewards[] memory _rewards = rewards;
        if (depositAmount != 0) {
            for (
                uint256 rewardsIndex = lastDeposit.epoch;
                rewardsIndex < _rewards.length;
                rewardsIndex++
            ) {
                depositAmount +=
                    (_rewards[rewardsIndex].amount * depositAmount) /
                    _rewards[rewardsIndex].poolWeight;
            }
        }
        PoolDeposit memory deposit = PoolDeposit(
            rewards.length,
            depositAmount + msg.value
        );
        deposits[msg.sender] = deposit;
    }

    // Calculate total amount for an account.
    function totalOfAccount() public view returns (uint256) {
        PoolDeposit memory lastDeposit = deposits[msg.sender];
        uint256 depositAmount = lastDeposit.amount;
        if (depositAmount != 0) {
            for (
                uint256 rewardsIndex = lastDeposit.epoch;
                rewardsIndex < rewards.length;
                rewardsIndex++
            ) {
                depositAmount +=
                    (rewards[rewardsIndex].amount * depositAmount) /
                    rewards[rewardsIndex].poolWeight;
            }
        }
        return depositAmount;
    }

    // Withdraw all funds
    // Min withdraw 0,001 eth
    function withdrawAll() public payable {
        uint256 total = totalOfAccount();
        require(1000000000000000 < total, "Min amount 1000000000000000");
        //require(total > 0, "Out of funds.");
        deposits[msg.sender].amount = 0;
        deposits[msg.sender].epoch = rewards.length;
        payable(msg.sender).transfer(total);
    }

    //Partial withdraw
    // Min withdraw 0,001 eth
    function withdraw(uint256 withdrawAmount) public payable {
        require(
            1000000000000000 < withdrawAmount,
            "Min amount 1000000000000000"
        );
        uint256 total = totalOfAccount();
        require(total >= withdrawAmount, "Insufficient funds.");
        deposits[msg.sender].amount = total - withdrawAmount;
        deposits[msg.sender].epoch = rewards.length;
        payable(msg.sender).transfer(withdrawAmount);
    }
}