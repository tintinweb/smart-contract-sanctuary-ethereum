// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Bank {
    uint256 public totalBalance;

    uint256 public constant REWARD_SPEED = 1;

    struct UserInfo {
        uint256 balance;
        uint256 lastRewardTimestamp;
    }
    mapping(address => UserInfo) public users;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function getUserBalance(address _user) public view returns(uint256) {
        uint256 reward = (block.timestamp - users[_user].lastRewardTimestamp) *REWARD_SPEED;
        
        return users[_user].balance + reward;
    }

    function deposit(uint256 _amount) public {
        updateReward(msg.sender);

        users[msg.sender].balance += _amount;

        totalBalance += _amount;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public {
        updateReward(msg.sender);

        users[msg.sender].balance -= _amount;

        totalBalance -= _amount;

        emit Withdraw(msg.sender, _amount);
    }

    function updateReward(address _user) public {
        if (users[_user].balance == 0) {
            users[_user].lastRewardTimestamp = block.timestamp;
        }
        else {
            uint256 reward = (block.timestamp - users[_user].lastRewardTimestamp) * REWARD_SPEED;

            users[_user].balance += reward;
            users[_user].lastRewardTimestamp = block.timestamp;
        }
    }
}