// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./IERC20.sol";

contract Staking {
    uint private singleEpochDuration = 5 minutes;
    uint private singleEpochRewardNumerator = 20;
    uint private singleEpochRewardDenominator = 100; // 20 / 100 = 20%
    uint private minimalStakingTime = 5 minutes;

    IERC20 private _lpToken;
    address private _lpTokenAddress;
    IERC20 private _rewardToken;
    address private _rewardTokenAddress;

    address private _owner;
    mapping(address => StakeInfo) private _stakers;
    uint private _rewardPoolSize;

    constructor(address lpTokenAddress, address rewardTokenAddress) {
        _lpTokenAddress = lpTokenAddress;
        _lpToken = IERC20(lpTokenAddress);
        _rewardTokenAddress = rewardTokenAddress;
        _rewardToken = IERC20(rewardTokenAddress);
        _owner = msg.sender;
    }

    struct StakeInfo {
        uint stakedTimestamp;
        uint claimedTimestamp;
        uint amount;
        uint unclaimedReward;
    }


    function stake(uint amount) public {
        address sender = msg.sender;
        address contractAddress = address(this);

        bool transferred = _transferTokens(sender, contractAddress, _lpToken, amount);
        require(transferred, "Can't transfer lp tokens");

        StakeInfo storage stakeInfo = _stakers[sender];
        stakeInfo.unclaimedReward = _calculateRewardFor(sender);
        stakeInfo.stakedTimestamp = block.timestamp;
        stakeInfo.claimedTimestamp = block.timestamp; //due to recalculate unclaimedReward
        stakeInfo.amount += amount;

        emit Staked(sender, amount);
    }

    function claim() public {
        address sender = msg.sender;
        address contractAddress = address(this);

        uint reward = _calculateRewardFor(sender);

        StakeInfo storage stakeInfo = _stakers[sender];
        stakeInfo.claimedTimestamp = block.timestamp;
        stakeInfo.unclaimedReward = 0;

        bool transferred = _transferTokens(contractAddress, sender, _rewardToken, reward);
        require(transferred, "Can't transfer reward tokens");
        _rewardPoolSize -= reward;

        emit Claimed(sender, reward);
    }

    function unstake() public {
        address sender = msg.sender;
        address contractAddress = address(this);

        StakeInfo storage stakeInfo = _stakers[sender];
        require(block.timestamp - stakeInfo.stakedTimestamp >= minimalStakingTime, "Wait to unstake");
        stakeInfo.unclaimedReward = _calculateRewardFor(sender);

        bool transferred = _transferTokens(contractAddress, sender, _lpToken, stakeInfo.amount);
        require(transferred, "Can't transfer lp tokens");

        emit Unstaked(sender, stakeInfo.amount);
        stakeInfo.amount = 0;
    }

    function depositRewardPool(uint amount) public CalledByOwner {
        address sender = msg.sender;
        address contractAddress = address(this);

        bool transferred = _transferTokens(sender, contractAddress, _rewardToken, amount);
        require(transferred, "Can't transfer reward tokens");
        _rewardPoolSize += amount;
    }

    function withdrawRewardPool() public CalledByOwner {
        address sender = msg.sender;
        address contractAddress = address(this);

        bool transferred = _transferTokens(contractAddress, sender, _rewardToken, _rewardPoolSize);
        require(transferred, "Can't transfer reward tokens");
        _rewardPoolSize = 0;
    }

    function _calculateRewardFor(address user) private view returns (uint) {
        StakeInfo memory stakeInfo = _stakers[user];

        uint stakedLp = stakeInfo.amount;
        uint periodToReward = block.timestamp - stakeInfo.claimedTimestamp;
        uint epochsToReward = periodToReward / singleEpochDuration;
        uint newReward =  epochsToReward * stakedLp * singleEpochRewardNumerator / singleEpochRewardDenominator;

        uint reward = stakeInfo.unclaimedReward + newReward;

        return reward;
    }

    function _transferTokens(address from, address to, IERC20 token, uint amount) private returns (bool) {
        address contractAddress = address(this);

        if (from != contractAddress) {
            return token.transferFrom(from, to, amount);
        } else {
            return token.transfer(to, amount);
        }
    }

    function getLpTokenAddress() public view returns (address) {
        return _lpTokenAddress;
    }

    function getRewardTokenAddress() public view returns (address) {
        return _rewardTokenAddress;
    }

    function getMyStakeInfo() public view returns (
        uint stakedTimestamp,
        uint claimedTimestamp,
        uint amount,
        uint unclaimedReward
    ) {
        address sender = msg.sender;
        StakeInfo memory stakeInfo = _stakers[sender];

        stakedTimestamp = stakeInfo.stakedTimestamp;
        claimedTimestamp = stakeInfo.claimedTimestamp;
        amount = stakeInfo.amount;
        unclaimedReward = stakeInfo.unclaimedReward;
    }

    function getSingleEpochDuration() public view returns (uint) {
        return singleEpochDuration;
    }

    function getSingleEpochRewardNumerator() public view returns (uint) {
        return singleEpochRewardNumerator;
    }

    function getSingleEpochRewardDenominator() public view returns (uint) {
        return singleEpochRewardDenominator;
    }

    function getMinimalStakingTime() public view returns (uint) {
        return minimalStakingTime;
    }

    function setSingleEpochDuration(uint value) public CalledByOwner {
        singleEpochDuration = value;
    }

    function setSingleEpochRewardNumerator(uint value) public CalledByOwner {
        singleEpochRewardNumerator = value;
    }

    function setSingleEpochRewardDenominator(uint value) public CalledByOwner {
        singleEpochRewardDenominator = value;
    }

    function setMinimalStakingTime(uint value) public CalledByOwner {
        minimalStakingTime = value;
    }

    function getRewardPoolSize() public view returns (uint) {
        return _rewardPoolSize;
    }

    event Staked(address by, uint amount);
    event Unstaked(address by, uint amount);
    event Claimed(address by, uint amount);

    modifier CalledByOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }
}