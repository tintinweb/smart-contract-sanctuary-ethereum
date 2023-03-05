/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0; 

interface IBEP20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Staking {
    struct Stake {
        uint amount;
        uint unlockTime;
        uint lastRewardClaimed;
        uint totalReward;
        uint rewardRemaining;
        uint totalLockPeriod;
        address staker;
        uint8 plan;
        bool active;
    }
    
    uint public constant PLAN_ONE_REWARD_PERCENTAGE = 35;
    uint public constant PLAN_TWO_REWARD_PERCENTAGE = 125;
    uint public constant PLAN_THREE_REWARD_PERCENTAGE = 250;
    uint public constant PLAN_FOUR_REWARD_PERCENTAGE = 500;

    uint public constant PLAN_ONE_LOCK_PERIOD = 180 seconds;
    uint public constant PLAN_TWO_LOCK_PERIOD = 360 seconds;
    uint public constant PLAN_THREE_LOCK_PERIOD = 720 seconds;
    uint public constant PLAN_FOUR_LOCK_PERIOD = 900 seconds;

    uint public totalStakes;
    uint public totalUsers;
    uint public totalStakedAmount;
    uint public totalRewardAmount;
    uint public maxStakeAmount = 125000;
    uint public maxRewardAmount = 62500;

    IBEP20 public token = IBEP20(0xb238a36d64509969329153DE8BAd1b52fa0C7b9e); // CHANGE ADDRESS
    bool public maxUserReached;

    address owner = msg.sender; // contract deployer is owner

    mapping(uint => Stake) public stakeInfo;
    mapping(address => uint[]) private _userStakeIds;
    

    function stake(uint amount, uint8 plan) external {
        require(!maxUserReached, "max user limit");
        require(amount > 0, "no amount");
        require(totalStakedAmount + amount <= maxStakeAmount, "exceeds max stake amount");
        

        uint utime; 
        uint reward; 
        uint lockPeriod;

        if(plan == 1) {
            utime = block.timestamp + PLAN_ONE_LOCK_PERIOD;
            lockPeriod = PLAN_ONE_LOCK_PERIOD;
            reward = (amount * PLAN_ONE_REWARD_PERCENTAGE) / 1000;
        } else if(plan == 2) {
            utime = block.timestamp + PLAN_TWO_LOCK_PERIOD;
            lockPeriod = PLAN_TWO_LOCK_PERIOD;
            reward = (amount * PLAN_TWO_REWARD_PERCENTAGE) / 1000;
        } else if(plan == 3) {
            utime = block.timestamp + PLAN_THREE_LOCK_PERIOD;
            lockPeriod = PLAN_THREE_LOCK_PERIOD;
            reward = (amount * PLAN_THREE_REWARD_PERCENTAGE) / 1000;
        } else if(plan == 4) {
            utime = block.timestamp + PLAN_FOUR_LOCK_PERIOD;
            lockPeriod = PLAN_FOUR_LOCK_PERIOD;
            reward = (amount * PLAN_FOUR_REWARD_PERCENTAGE) / 1000;
        } else {
            revert("invalid plan");
        }

        require(reward > 0, "amount too small for reward");
        require(totalRewardAmount + reward <= maxRewardAmount, "exceeds max reward");

        if(_userStakeIds[msg.sender].length == 0) {
            totalUsers += 1;
            if(totalUsers == 100000) {
                maxUserReached = true;
            }
        }

        totalStakedAmount += amount;
        totalRewardAmount += reward;

        uint sId = totalStakes++;

        stakeInfo[sId] = Stake(amount, utime, block.timestamp, reward, reward, lockPeriod, msg.sender, plan, true);
        _userStakeIds[msg.sender].push(sId);

        token.transferFrom(msg.sender, address(this), amount);
    }  

    function claimReward(uint stakeId) external {
        Stake storage stk = stakeInfo[stakeId];
        require(msg.sender == stk.staker, "not staker");

        uint rwd = getClaimableReward(stakeId);

        require(rwd > 0, "no reward");

        stk.rewardRemaining -= rwd;
        stk.lastRewardClaimed = block.timestamp;

        token.transfer(msg.sender, rwd);
    }

    function unstake(uint stakeId) external {
        Stake storage stk = stakeInfo[stakeId];
        require(msg.sender == stk.staker, "not staker");
        require(stk.active, "unstaked already");
        require(block.timestamp > stk.unlockTime, "not unlocked");

        stk.active = false;
        totalStakedAmount -= stk.amount;
        
        token.transfer(msg.sender, stk.amount+getClaimableReward(stakeId));
    }

    function getClaimableReward(uint stakeId) public view returns (uint) {
        uint amount = (block.timestamp - stakeInfo[stakeId].lastRewardClaimed) * stakeInfo[stakeId].totalReward / stakeInfo[stakeId].totalLockPeriod;
        if(amount > stakeInfo[stakeId].rewardRemaining) {
            return stakeInfo[stakeId].rewardRemaining;
        } else {
            return amount;
        }
    }

    function getStakeIds(address staker) external view returns (uint[] memory) {
        return _userStakeIds[staker];
    }

    /*//////////////////////////////////////////////////////////////
                                 OWNER
    //////////////////////////////////////////////////////////////*/

    function changeMaxStakeAmount(uint newAmount) external {
        require(msg.sender == owner, "not owner");
        maxStakeAmount = newAmount;
    }

    function changeMaxRewardAmount(uint newAmount) external {
        require(msg.sender == owner, "not owner");
        maxRewardAmount = newAmount;
    }

    function withdraw(uint amount) external {
        require(msg.sender == owner, "not owner");
        token.transfer(msg.sender, amount);
    }
}