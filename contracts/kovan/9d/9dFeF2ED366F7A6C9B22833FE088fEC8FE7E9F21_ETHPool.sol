// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// NOTE: This is just a test contract, please delete me

contract ETHPool {
    mapping(address => bool) teams;
    mapping(address => uint256) shares;
    struct Reward {
        uint256 amount;
        uint256 time;
    }
    struct Deposit {
        address user;
        uint256 amount;
        uint256 time;
    }
    Reward[] rewards;
    Deposit[] deposits;
    uint256 rewardDepositPeriod = 1 weeks;
    uint256 lastRewardDepositTime;
    constructor() {}

    function deposit() public payable {
        if (teams[msg.sender]) { // Reward can be deposited only once a week by team
            require(block.timestamp>lastRewardDepositTime+rewardDepositPeriod, "Reward can be deposited only once a week");
            rewards.push(Reward(msg.value, block.timestamp));
            lastRewardDepositTime = block.timestamp;
        } else { // Individual user can deposit ETH to get reward
            shares[msg.sender] = shares[msg.sender] + msg.value;
            deposits.push(Deposit(msg.sender, msg.value, block.timestamp));
        }
    }

    function withdraw() public {
        require(shares[msg.sender] > 0, "You didn't deposit ETH");
        require(teams[msg.sender]==false, "Team can not withdraw ETH");
        payable(msg.sender).transfer(shares[msg.sender] + calculateReward(msg.sender));
        shares[msg.sender] = 0;
    }

    function calculateReward(address _address) internal view returns (uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            (uint256 numerator, uint256 denominator) = getRatioBeforeReward(_address, rewards[i].time);
            if (denominator == 0) continue;
            totalReward = totalReward + (rewards[i].amount * numerator) / denominator;
        }
        return totalReward;
    }

    function getRatioBeforeReward(address _address, uint256 _time) internal view returns (uint256, uint256) {
        uint256 numerator = 0;
        uint256 denominator = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].time < _time) {
                denominator = denominator + deposits[i].amount;
                if (_address == deposits[i].user) numerator = numerator + deposits[i].amount;
            }
        }
        return (numerator, denominator);
    }

    function registerTeam(address _address) external {
        teams[_address] = true;
    }

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }
}