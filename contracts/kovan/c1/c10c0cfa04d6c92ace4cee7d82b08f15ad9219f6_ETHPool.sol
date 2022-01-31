/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Edge and Node - Smart Contract Challenge (#4): ETHPool
/// @author Andrea Chello - https://github.com/andreachello

/**
 * Requirements:
 *
 * - Only the team can deposit rewards.
 * - The team can deposit rewards at any time.
 * - Deposited rewards go to the pool of users, not to individual users.
 * - Users should be able to withdraw their deposits along with their share
 *   of rewards considering the time when they deposited. They should not get
 *   rewards for the ones distributed before their deposits.
 *
 */

contract ETHPool {

    // front end events
    event Deposit(address indexed _address, uint256 _value);
    event Withdraw(address indexed _address, uint256 _value);

    // current total staked balance
    uint public totalCurrentStake;


    // array of stakers
    address[] public stakers;

    // keep track of amount staked
    mapping(address => uint) public stakingBalance;
    // keep track of if investors have staked or not in the past
    // this in order to not double count stakers
    mapping(address => bool) public hasStaked;

    // Receive ETH from users assuming no message data is sent
    // We do this instead of using a fallback function
    receive() external payable {

        if(!hasStaked[msg.sender]){
            stakers.push(msg.sender);
        }

        // update staking balance and logic
        stakingBalance[msg.sender] += msg.value;
        hasStaked[msg.sender] = true;

        // update total being staked
        totalCurrentStake += msg.value;

        // emit event
        emit Deposit(msg.sender, msg.value);
    }

    // Team deposits the rewards
    // no need to manually keep track of the rewards if distributed this way
    function depositRewards() public payable {
        require(totalCurrentStake > 0, "In order to deposit rewards there must be stakers currently in the pool");

        for (uint i = 0; i < stakers.length; i++) {

            address _staker = stakers[i];

            uint _rewards = (((stakingBalance[_staker] * 100) / totalCurrentStake) * msg.value)/100;

            stakingBalance[_staker] += _rewards;
        }
    }

    function withdraw() public {
        uint _balance = stakingBalance[msg.sender];

        require(_balance > 0, "Nothing left to withdraw");

        // reset staker balance and current stake
        stakingBalance[msg.sender] = 0;

        payable(msg.sender).transfer(_balance);

        // emit event
        emit Withdraw(msg.sender, _balance);
    }
}