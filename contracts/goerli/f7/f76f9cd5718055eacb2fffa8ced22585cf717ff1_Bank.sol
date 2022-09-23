// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Bank {
    // ******************* //
    //  State Variables    //
    // ******************* //

    struct UserInfo {
        uint256 balance;
        uint256 lastRewardTimestamp;
    }
    mapping(address => UserInfo) public users;

    uint256 public constant REWARD_SPEED = 1;

    // ******************* //
    //     Events          //
    // ******************* //

    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event RewardUpdated(address indexed user, uint256 newReward);

    // ******************* //
    //    Functions        //
    // ******************* //

    function getUserBalance(address _user) public view returns(uint256) {
        uint256 lastTime = users[_user].lastRewardTimestamp;

        uint256 newReward = ( block.timestamp - lastTime ) * REWARD_SPEED;
        return users[_user].balance + newReward;
    }

    function deposit(uint256 _amount) external payable  {
        updateReward(msg.sender);
        users[msg.sender].balance += _amount;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external payable {
        require(users[msg.sender].balance <= _amount, "Insufficient Amount");

        updateReward(msg.sender);
        users[msg.sender].balance -= _amount;
    
        emit Withdraw(msg.sender, _amount);
    }

    function updateReward(address _user) public {
        if (users[_user].balance == 0) {
            users[_user].lastRewardTimestamp = block.timestamp;
        }
        else {
            uint256 lastTime = users[_user].lastRewardTimestamp;

            uint256 newReward = ( block.timestamp - lastTime ) * REWARD_SPEED;

            users[_user].balance += newReward;

            emit RewardUpdated(_user, newReward);
        }
    }
}