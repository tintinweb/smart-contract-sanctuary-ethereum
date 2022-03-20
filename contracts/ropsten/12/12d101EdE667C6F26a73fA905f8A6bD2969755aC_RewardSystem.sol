// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract RewardSystem {

    uint256 public totalAmountinPool = 0;
    mapping(address => uint256) public userDepositValue;
    address[] public uniqueAddress;

    constructor() {
        totalAmountinPool = 0;
    }

    function getRewardAmount(address user) public view returns(uint256) {
        return userDepositValue[user];
    }

    function putReward(uint256 amount) public {
        
        require(totalAmountinPool != 0);

        for (uint i = 0; i < uniqueAddress.length; i ++) {
            uint256 curValue = userDepositValue[uniqueAddress[i]];
            
            uint256 rewardAmount = curValue*amount/totalAmountinPool;
            userDepositValue[uniqueAddress[i]] += rewardAmount;
        }

        totalAmountinPool += amount;
    }

    function deposit(address user, uint256 amount) public {
        //require(msg.sender == user);

        if(userDepositValue[user] == 0) {
            uniqueAddress.push(user);
        }

        totalAmountinPool += amount;
        userDepositValue[user] += amount;
    }
}