/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Staking {
    uint private singleEpochDuration = 5 minutes;
    uint private singleEpochRewardCoefficientPerLP = 5; // 20%
    uint private minimalStakingTime = 5 minutes;

    IERC20 private _lpToken;
    IERC20 private _rewardToken;

    address private _owner;
    mapping(address => StakeInfo) private _stakers;
    mapping(address => uint) private _unclaimedRewards;
    uint private _rewardPoolSize;

    constructor(address lpTokenAddress, address rewardTokenAddress) {
        _lpToken = IERC20(lpTokenAddress);
        _rewardToken = IERC20(rewardTokenAddress);
        _owner = msg.sender;
    }

    struct StakeInfo {
        uint stakedTimestamp;
        uint claimedTimestamp;
        uint amount;
    }


    function stake(uint amount) public {
        address sender = msg.sender;
        address contractAddress = address(this);

        bool transferred = _transferTokens(sender, contractAddress, _lpToken, amount);
        require(transferred, "Can't transfer lp tokens");

        _unclaimedRewards[sender] = _calculateRewardFor(sender);

        StakeInfo storage stakeInfo = _stakers[sender];
        stakeInfo.stakedTimestamp = block.timestamp;
        stakeInfo.claimedTimestamp = block.timestamp;
        stakeInfo.amount += amount;
    }

    function claim() public {
        address sender = msg.sender;
        address contractAddress = address(this);

        uint reward = _calculateRewardFor(sender);

        StakeInfo storage stakeInfo = _stakers[sender];
        stakeInfo.claimedTimestamp = block.timestamp;
        delete _unclaimedRewards[sender];

        bool transferred = _transferTokens(contractAddress, sender, _rewardToken, reward);
        require(transferred, "Can't transfer reward tokens");
        _rewardPoolSize -= reward;
    }

    function unstake() public {
        address sender = msg.sender;
        address contractAddress = address(this);

        StakeInfo storage stakeInfo = _stakers[sender];
        require(block.timestamp - stakeInfo.stakedTimestamp >= minimalStakingTime, "Wait to unstake");

        _unclaimedRewards[sender] = _calculateRewardFor(sender);

        bool transferred = _transferTokens(contractAddress, sender, _lpToken, stakeInfo.amount);
        require(transferred, "Can't transfer lp tokens");

        delete _stakers[sender];
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
        uint newReward =  epochsToReward * stakedLp / singleEpochRewardCoefficientPerLP;

        uint reward = _unclaimedRewards[user] + newReward;

        return reward;
    }

    function _transferTokens(address from, address to, IERC20 token, uint amount) private returns (bool) {
        address contractAddress = address(this);

        if (from != contractAddress) {
            uint allowance = token.allowance(from, to);
            require(allowance >= amount, "Allowance is needed");

            return token.transferFrom(from, to, amount);
        } else {
            return token.transfer(to, amount);
        }
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
        unclaimedReward = _unclaimedRewards[sender];
    }

    function getSingleEpochDuration() public view returns (uint) {
        return singleEpochDuration;
    }

    function getSingleEpochRewardCoefficientPerLP() public view returns (uint) {
        return singleEpochRewardCoefficientPerLP;
    }

    function getMinimalStakingTime() public view returns (uint) {
        return minimalStakingTime;
    }

    function setSingleEpochDuration(uint value) public CalledByOwner {
        singleEpochDuration = value;
    }

    function setSingleEpochRewardCoefficientPerLP(uint value) public CalledByOwner {
        singleEpochRewardCoefficientPerLP = value;
    }

    function setMinimalStakingTime(uint value) public CalledByOwner {
        minimalStakingTime = value;
    }

    function getRewardPoolSize() public view returns (uint) {
        return _rewardPoolSize;
    }

    modifier CalledByOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }
}