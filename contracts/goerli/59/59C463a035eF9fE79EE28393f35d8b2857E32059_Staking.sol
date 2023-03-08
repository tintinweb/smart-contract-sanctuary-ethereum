/**
 *Submitted for verification at Etherscan.io on 2023-03-08
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

    uint public constant PLAN_ONE_LOCK_PERIOD = 1000 seconds;//180 seconds;
    uint public constant PLAN_TWO_LOCK_PERIOD = 10000 seconds;//360 seconds;
    uint public constant PLAN_THREE_LOCK_PERIOD = 10000 seconds; //720 seconds;
    uint public constant PLAN_FOUR_LOCK_PERIOD = 5000 seconds;//900 seconds;

    uint public totalStakes;
    uint public totalUsers;
    uint public totalStakedAmount;
    uint public totalRewardAmount;
    uint public maxStakeAmount = 125000;
    uint public maxRewardAmount = 62500;

    // Change the address to the actual token address
    IBEP20 public token = IBEP20(0xfE364e416f8bA3f3CAF44198cC306960898e2a93);

    bool public maxUserReached;

    address public owner = msg.sender;

    mapping(uint => Stake) public stakeInfo;
    mapping(address => uint[]) private _userStakeIds;

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    function stake(uint amount, uint8 plan) external {
        require(!maxUserReached, "max user limit");
        require(amount > 0, "no amount");
        require(totalStakedAmount + amount <= maxStakeAmount, "exceeds max stake amount");

        uint utime;
        uint reward;
        uint lockPeriod;

        if (plan == 1) {
            utime = block.timestamp + PLAN_ONE_LOCK_PERIOD;
            lockPeriod = PLAN_ONE_LOCK_PERIOD;
            reward = (amount * PLAN_ONE_REWARD_PERCENTAGE) / 1000;
        } else if (plan == 2) {
            utime = block.timestamp + PLAN_TWO_LOCK_PERIOD;
            lockPeriod = PLAN_TWO_LOCK_PERIOD;
            reward = (amount * PLAN_TWO_REWARD_PERCENTAGE) / 1000;
        } else if (plan == 3) {
            utime = block.timestamp + PLAN_THREE_LOCK_PERIOD;
            lockPeriod = PLAN_THREE_LOCK_PERIOD;
            reward = (amount * PLAN_THREE_REWARD_PERCENTAGE) / 1000;
        } else if (plan == 4) {
            utime= block.timestamp + PLAN_FOUR_LOCK_PERIOD;
            lockPeriod = PLAN_FOUR_LOCK_PERIOD;
            reward = (amount * PLAN_FOUR_REWARD_PERCENTAGE) / 1000;
            } else {
            revert("invalid plan");
            }

                require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");

    Stake memory newStake = Stake({
        amount: amount,
        unlockTime: utime,
        lastRewardClaimed: block.timestamp,
        totalReward: reward,
        rewardRemaining: reward,
        totalLockPeriod: lockPeriod,
        staker: msg.sender,
        plan: plan,
        active: true
    });

    totalStakes++;
    totalStakedAmount += amount;
    totalRewardAmount += reward;

    uint stakeId = totalStakes;
    stakeInfo[stakeId] = newStake;
    _userStakeIds[msg.sender].push(stakeId);

    if (_userStakeIds[msg.sender].length >= 5) {
        maxUserReached = true;
    }

    totalUsers++;
}

function claimReward(uint stakeId) external {
    require(stakeId <= totalStakes, "invalid stake id");

    Stake storage stake = stakeInfo[stakeId];

    require(stake.active, "inactive stake");
    require(block.timestamp >= stake.unlockTime, "locked stake");

    uint reward = calculateReward(stakeId);

    require(token.transfer(stake.staker, reward), "transfer failed");

    stake.lastRewardClaimed = block.timestamp;
    stake.rewardRemaining -= reward;

    if (stake.rewardRemaining == 0) {
        stake.active = false;
    }
}

        function calculateReward(uint stakeId) public view returns (uint) {
            Stake memory stake = stakeInfo[stakeId];

            uint duration = block.timestamp - stake.lastRewardClaimed;
            uint reward = (stake.totalReward * duration * 100) / (stake.totalLockPeriod * 1 days * 1000);
            uint remainingReward = stake.rewardRemaining;

            if (reward > remainingReward) {
                reward = remainingReward;
            }

            return reward;
        }

        function getStakeIds(address staker) external view returns (uint[] memory) {
            return _userStakeIds[staker];
        }

        function setMaxStakeAmount(uint amount) external onlyOwner {
            maxStakeAmount = amount;
        }

        function setMaxRewardAmount(uint amount) external onlyOwner {
            maxRewardAmount = amount;
        }

        function setTokenAddress(address tokenAddress) external onlyOwner {
            token = IBEP20(tokenAddress);
        }

        function transferOwnership(address newOwner) external onlyOwner {
            require(newOwner != address(0), "new owner address is the zero address");
            owner = newOwner;
        }
}