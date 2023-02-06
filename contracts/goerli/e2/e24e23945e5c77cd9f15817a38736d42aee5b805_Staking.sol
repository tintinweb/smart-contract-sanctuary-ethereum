/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

//      BigBrain AI is Decentrazlized Artificial Intelligence Technology which is here to discover Big Rewards.

//      Website: https://bigbrainai.app
//      Telegram: https://t.me/Bigbrainai   
//      Twitter: https://twitter.com/bigbrainai


// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Staking {
    uint256 public constant MIN_STAKE = 0.0001 * 10**18;
    uint256 public constant MAX_STAKE = 0.02 * 10**18;
    uint256 public constant REWARD_FACTOR_10_DAYS = 1.5 * 10**18;
    uint256 public constant REWARD_FACTOR_20_DAYS = 2.2 * 10**18;
    uint256 public constant REWARD_FACTOR_30_DAYS = 3 * 10**18;

    uint256 public totalSupply;
    mapping (address => uint256) public stakes;
    mapping (address => uint256) public rewards;
    mapping (address => uint256) public startTime;

    event Staked(address indexed staker, uint256 stake, uint256 reward, uint256 startTime);
    event Unstaked(address indexed staker, uint256 unstake, uint256 reward);

    function stake(uint256 stakeAmount) public {
        require(stakeAmount >= MIN_STAKE, "Minimum stake should be higher than 0.01% of total supply");
        require(stakeAmount <= MAX_STAKE, "Maximum stake should be 2% of total supply");
        require(stakeAmount <= totalSupply, "Stake amount should be less than or equal to the total supply");

        startTime[msg.sender] = block.timestamp;
        stakes[msg.sender] += stakeAmount;
        totalSupply -= stakeAmount;

        uint256 duration = block.timestamp - startTime[msg.sender];
        if (duration >= 10 days) {
            rewards[msg.sender] = stakes[msg.sender] * REWARD_FACTOR_10_DAYS;
        } else if (duration >= 20 days) {
            rewards[msg.sender] = stakes[msg.sender] * REWARD_FACTOR_20_DAYS;
        } else if (duration >= 30 days) {
            rewards[msg.sender] = stakes[msg.sender] * REWARD_FACTOR_30_DAYS;
        }

        emit Staked(msg.sender, stakeAmount, rewards[msg.sender], startTime[msg.sender]);
    }

    function unstake(uint256 unstakeAmount) public {
        require(unstakeAmount <= stakes[msg.sender], "Unstake amount should be less than or equal to the staked amount");

        stakes[msg.sender] -= unstakeAmount;
        totalSupply += unstakeAmount;

        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;

        emit Unstaked(msg.sender, unstakeAmount, reward);
    }
}