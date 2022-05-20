//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import ".././contracts/IERC20.sol";

/// @title Staking Platform
/// @notice Allows to stake ERC-20 tokens and get reward for holding.
/// @notice Has customizable reward rate, reward delay and unstake delay
/// @notice Can be locked to change staking and reward tokens.
contract StakingPlatform {
    struct Stake {
        uint256 amount;
        uint256 reward;
        uint256 lastStakeDate;
        uint256 lastRewardDate;
    }

    /// @notice Informs that reward rate is changed
    event RewardRateChanged(uint8 indexed rewardPercentage);
    /// @notice Informs that reward delay is changed
    event RewardDelayChanged(uint32 indexed rewardDelay);
    /// @notice Informs that unstake delay is changed
    event UnstakeDelayChanged(uint32 indexed unstakeDelay);

    //uint32 covers 136 years, it's more than enough for delays
    uint32 private _rewardDelay = 10 minutes;
    uint32 private _unstakeDelay = 20 minutes;
    uint8 private _rewardPercentage = 20;
    bool private _isLocked = true;
    address private _owner;
    IERC20 private _stakingToken;
    IERC20 private _rewardToken;
    mapping(address => Stake) private _stakes;

    modifier onlyOwner() {
        require(msg.sender == _owner, "No access");
        _;
    }

    modifier whenLocked() {
        require(_isLocked, "Should be locked");
        _;
    }

    modifier whenUnlocked() {
        require(!_isLocked, "Functionality is locked");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    /// @notice Returns current Reward Percentage
    function getRewardPercentage() external view returns(uint256) {
        return _rewardPercentage;
    }
    
    /// @notice Returns current Reward Delay.
    /// @notice Shows how long Claim cannot be called since last Stake.
    /// @notice Shows how long a period which will be rewarded afterthat
    function getRewardDelay() external view returns(uint256) {
        return _rewardDelay;
    }

    /// @notice Returns current Unstake Delay.
    /// @notice Shows how long Unstake cannot be called since last Stake
    function getUnstakeDelay() external view returns(uint256) {
        return _unstakeDelay;
    }

    /// @notice Returns current state for the specifed `staker`
    function getDetails(address staker) external view returns(Stake memory) {
        require(msg.sender == staker || msg.sender == _owner, "No access");
        return _stakes[staker];
    }

    /// @notice Returns address of the current staking token
    function getStakingToken() external view returns(address) {
        return address(_stakingToken);
    }

    /// @notice Returns address of the current reward token
    function getRewardToken() external view returns(address) {
        return address(_rewardToken);
    }

    /// @notice Allows to lock or unlock the platform
    function setLock(bool value) external onlyOwner {
        _isLocked = value;
    }

    /// @notice Allows to change Reward Percentage.
    /// @notice Emits `RewardRateChanged` event
    function setRewardPercentage(uint8 newRewardPercentage)
        public
        onlyOwner
    {
        _rewardPercentage = newRewardPercentage;
        emit RewardRateChanged(newRewardPercentage);
    }

    /// @notice Allows to change Reward Delay.
    /// @notice Emits `RewardDelayChanged` event
    function setRewardDelay(uint32 newRewardDelay) public onlyOwner {
        _rewardDelay = newRewardDelay;
        emit RewardDelayChanged(newRewardDelay);
    }

    /// @notice Allows to change Unstake Delay.
    /// @notice Emits `UnstakeDelayChanged` event
    function setUnstakeDelay(uint32 newUnstakeDelay) public onlyOwner {
        _unstakeDelay = newUnstakeDelay;
        emit UnstakeDelayChanged(newUnstakeDelay);
    }

    /// @notice Allows to change the reward token, if the platform is locked
    function setRewardToken(address newRewardToken) 
        public 
        onlyOwner 
        whenLocked 
    {
        _rewardToken = IERC20(newRewardToken);
    }

    /// @notice Allows to change the staking token, if the platform is locked
    function setStakingToken(address newStakingToken) 
        public 
        onlyOwner 
        whenLocked 
    {
        _stakingToken = IERC20(newStakingToken);
    }

    /// @notice Calculates reward based on currently staked amount, if possible
    /// @notice Updates the state: dates & amounts
    /// @notice Transfers from the sender the specified amount of tokens, 
    /// which should be already approved by the sender
    function stake(uint256 amount) public whenUnlocked {
        Stake storage staking = _stakes[msg.sender];
        uint256 calculatedReward = _calculateCurrentReward(
            staking.amount, 
            _getRewardPeriodsNumber(staking.lastRewardDate)
        );

        staking.lastRewardDate = block.timestamp;
        staking.lastStakeDate = block.timestamp;
        staking.reward += calculatedReward;
        staking.amount += amount;
        
        _stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Checks if it is possible to unstake.
    /// @notice Calculates reward based on currently staked amount.
    /// @notice Resets staked amount and transfers it back to the owner 
    function unstake() public whenUnlocked {
        Stake storage staking = _stakes[msg.sender];
        require(
            staking.amount > 0 &&
            block.timestamp > staking.lastStakeDate + _unstakeDelay,
            "Cannot unstake yet"
        );
        uint256 stakedAmount = staking.amount;
        staking.amount = 0;

        uint256 periods = _getRewardPeriodsNumber(staking.lastRewardDate);
        uint256 calculatedReward = _calculateCurrentReward(stakedAmount, periods);
        
        staking.reward += calculatedReward;
        staking.lastRewardDate =
            staking.lastRewardDate + periods * _rewardDelay;
        
        _stakingToken.transfer(msg.sender, stakedAmount);
    }

    /// @notice Checks if it is possible to calculate a reward.
    /// @notice Calculates and transfer calculated amount of reward tokens
    function claim() public whenUnlocked {
        Stake storage staking = _stakes[msg.sender];
        bool canBeClaimed = staking.lastRewardDate > 0 &&
            block.timestamp > staking.lastRewardDate + _rewardDelay;
        require(canBeClaimed || staking.reward > 0, "Nothing to claim yet");
        
        uint256 totalReward = staking.reward;
        uint256 periods = _getRewardPeriodsNumber(staking.lastRewardDate);

        staking.reward = 0;
        staking.lastRewardDate =
            staking.lastRewardDate + periods * _rewardDelay;
        
        totalReward += _calculateCurrentReward(staking.amount, periods);
        _rewardToken.transfer(msg.sender, totalReward);
    }

    /// @dev Gives number of period which should be rewarded since given date
    function _getRewardPeriodsNumber(uint256 lastRewardDate)
        private
        view
        returns (uint256)
    {
        return (block.timestamp - lastRewardDate) / _rewardDelay;
    }

    /// @dev Gives reward for current reward rate and given amount and periods
    function _calculateCurrentReward(
        uint256 stakedAmount,
        uint256 numberOfPeriods
    ) private view returns (uint256) {
        return numberOfPeriods * (stakedAmount * _rewardPercentage / 100);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed from,
        address indexed spender,
        uint256 value
    );
}

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 value) external;
}