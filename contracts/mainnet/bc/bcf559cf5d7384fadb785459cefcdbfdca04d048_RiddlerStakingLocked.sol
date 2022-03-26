pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract RiddlerStakingLocked is Ownable {
    using SafeMath for uint256;

    uint256 public totalStaked;
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public apr;
    uint256 public lockDuration;
    uint256 public stakeStart;

    bool public stakingEnabled = false;
    
    struct Staker {
        address staker;
        uint256 start;
        uint256 staked;
        uint256 earned;
    }

    mapping(address => Staker) private _stakers;

    constructor (IERC20 _stakingToken, IERC20 _rewardToken, uint256 _startAPR, uint256 _duration) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        apr = _startAPR;
        lockDuration = _duration;
        stakeStart = block.timestamp;
    }

    function isStaking(address stakerAddr) public view returns (bool) {
        return _stakers[stakerAddr].staker == stakerAddr;
    }

    function userStaked(address staker) public view returns (uint256) {
        return _stakers[staker].staked;
    }

    function userEarnedTotal(address staker) public view returns (uint256) {
        uint256 currentlyEarned = _userEarned(staker);
        uint256 previouslyEarned = _stakers[msg.sender].earned;

        if (previouslyEarned > 0) return currentlyEarned.add(previouslyEarned);
        return currentlyEarned;
    }

    function stakingStart(address staker) public view returns (uint256) {
        return _stakers[staker].start;
    }

    function _isLocked(address staker) private view returns (bool) {
        bool isLocked = false;

        uint256 _stakeDay = _stakers[staker].start / 1 days;
        if (_stakeDay - stakeStart / 1 days < lockDuration) {
           if (block.timestamp / 1 days - _stakeDay < lockDuration) {
               isLocked = true;
           }
        }

        return isLocked;
    }

    function _userEarned(address staker) private view returns (uint256) {
        require(isStaking(staker), "User is not staking.");

        uint256 staked = userStaked(staker);
        uint256 stakersStartInSeconds = _stakers[staker].start.div(1 seconds);
        uint256 blockTimestampInSeconds = block.timestamp.div(1 seconds);
        uint256 secondsStaked = blockTimestampInSeconds.sub(stakersStartInSeconds);


        uint256 decAPR = apr.div(100);
        uint256 rewardPerSec = staked.mul(decAPR).div(365).div(24).div(60).div(60);
        uint256 earned = rewardPerSec.mul(secondsStaked).div(10**18);

        return earned;
    }
 
    function stake(uint256 stakeAmount) external {
        require(stakingEnabled, "Staking is not enabled");

        // Check user is registered as staker
        if (isStaking(msg.sender)) {
            _stakers[msg.sender].staked += stakeAmount;
            _stakers[msg.sender].earned += _userEarned(msg.sender);
            _stakers[msg.sender].start = block.timestamp;
        } else {
            _stakers[msg.sender] = Staker(msg.sender, block.timestamp, stakeAmount, 0);
        }

        totalStaked += stakeAmount;
        stakingToken.transferFrom(msg.sender, address(this), stakeAmount);
    }
    
    function claim() external {
        require(stakingEnabled, "Staking is not enabled");
        require(isStaking(msg.sender), "You are not staking!?");

        uint256 reward = userEarnedTotal(msg.sender);
        stakingToken.transfer(msg.sender, reward);

        _stakers[msg.sender].start = block.timestamp;
        _stakers[msg.sender].earned = 0;
    }

    function unstake() external {
        require(stakingEnabled, "Staking is not enabled");
        require(isStaking(msg.sender), "You are not staking!?");
        require(!_isLocked(msg.sender), "Your tokens are currently locked");

        uint256 reward = userEarnedTotal(msg.sender);
        stakingToken.transfer(msg.sender, _stakers[msg.sender].staked.add(reward));

        totalStaked -= _stakers[msg.sender].staked;

        delete _stakers[msg.sender];
    }
    
    function emergencyWithdrawToken(IERC20 token) external onlyOwner() {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function emergencyWithdrawTokenAmount(IERC20 token, uint256 amount) external onlyOwner() {
        token.transfer(msg.sender, amount);
    }

    function setState(bool onoff) external onlyOwner() {
        stakingEnabled = onoff;
    }

    receive() external payable {}
}