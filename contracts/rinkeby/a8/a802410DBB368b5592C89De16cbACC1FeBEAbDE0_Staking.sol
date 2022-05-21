//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./console.sol";
import "./ERC20.sol";
import "./AccessControl.sol";

contract Staking is AccessControl {
    IERC20 public rewardToken;
    IERC20 public stakingToken;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    struct Balance {
        uint256 unclaimableBalance;
        uint256 claimableBalance;
        uint256 unstakeTime;
        uint256 claimableReward;
        uint256 pendingRewards;
        uint256 timeToReward;
    }

    mapping(address => Balance) public balances;

    uint256 public rewardTime = 10; //minutes
    uint256 public lockUpTime = 20; //minutes
    uint256 public rewardRate = 20; //% of reward tokens

    uint256 public totalSupply;

    constructor(address _rewardToken, address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    //Admin functions:
    function changeRewardTime(uint256 _time) public onlyRole(ADMIN) {
        rewardTime = _time;
    }

    function changeLockUpTime(uint256 _time) public onlyRole(ADMIN) {
        lockUpTime = _time;
    }

    //Main functions:
    function stake(uint256 _amount)
        external
        updateBalance(msg.sender)
        updateReward(msg.sender)
    {
        //stake lp tokens
        balances[msg.sender].unclaimableBalance += _amount;
        balances[msg.sender].unstakeTime =
            block.timestamp +
            lockUpTime *
            1 minutes;
        balances[msg.sender].pendingRewards += (_amount * rewardRate) / 100;
        balances[msg.sender].timeToReward =
            block.timestamp +
            rewardTime *
            1 minutes;
        totalSupply += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function claim()
        external
        updateBalance(msg.sender)
        updateReward(msg.sender)
    {
        //withdraw reward
        uint256 reward = balances[msg.sender].claimableReward;
        require(reward >= 0, "Reward is not available");
        balances[msg.sender].claimableReward = 0;
        stakingToken.transfer(msg.sender, reward);
    }

    function unstake(uint256 _amount)
        external
        updateBalance(msg.sender)
        updateReward(msg.sender)
    {
        require(
            (balances[msg.sender].unclaimableBalance +
                balances[msg.sender].claimableBalance) > 0,
            "No tokens staked"
        );
        uint256 unstakeAmount = balances[msg.sender].claimableBalance;
        require(unstakeAmount > 0, "Lockup time doesn't over");
        require(unstakeAmount > _amount, "Not enough tokens");
        unstakeAmount -= _amount;
        rewardToken.transfer(msg.sender, _amount);
    }

    modifier updateReward(address _account) {
        if (
            (balances[_account].unclaimableBalance +
                balances[_account].claimableBalance) == 0
        ) {
            _;
        } else {
            if (block.timestamp >= balances[_account].timeToReward) {
                balances[_account].claimableReward += balances[_account]
                    .pendingRewards;
                balances[_account].pendingRewards = 0;
                _;
            } else {
                _;
            }
        }
    }

    modifier updateBalance(address _account) {
        if (
            (balances[_account].unclaimableBalance +
                balances[_account].claimableBalance) == 0
        ) {
            _;
        } else {
            if (block.timestamp >= balances[_account].unstakeTime) {
                balances[_account].claimableBalance += balances[_account]
                    .unclaimableBalance;
                balances[_account].unclaimableBalance = 0;
                _;
            } else {
                _;
            }
        }
    }
}