/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Staking {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    bool public paused;
    
    uint256 public duration; // Duration of rewards to be paid out (in seconds)
    uint256 public finishAt; // Timestamp of when the rewards finish
    uint256 public updatedAt; // Minimum of last updated time and reward finish time
    uint256 public rewardRate; // Reward to be paid out per second
    uint256 public rewardPerTokenStored; // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public totalSupply; // Total staked

   
    mapping(address => uint256) public userRewardPerTokenPaid;  // User address => rewardPerTokenStored
    mapping(address => uint256) public rewards; // User address => rewards to be claimed
    mapping(address => uint256) public balanceOf; // User address => staked amount
    
    error AmountZero();
    error NothingToClaim();
    error RewardsNotFinished();
    error InsufficientBalance();
    error RewardRateZero();
    error Paused();

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    
    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        if(paused) revert Paused();
        if(_amount == 0) revert AmountZero();
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit Stake(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        if(paused) revert Paused();
        if(_amount == 0) revert AmountZero();
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function compound() external updateReward(msg.sender) {
        if(paused) revert Paused();
        uint256 amount = rewards[msg.sender];
        if (amount == 0) revert NothingToClaim();
        rewards[msg.sender] = 0;
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Compound(msg.sender, amount);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function claimReward() external updateReward(msg.sender) {
        if(paused) revert Paused();
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert NothingToClaim();
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        if(finishAt >= block.timestamp) revert RewardsNotFinished();
        duration = _duration;
    }

    function notifyRewardAmount(
        uint256 _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        if(rewardRate == 0) revert RewardRateZero();
        if(rewardRate * duration > rewardsToken.balanceOf(address(this))) revert InsufficientBalance();

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}