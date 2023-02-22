/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
}
// Author: @muharrem
contract TradingRewards {
    IERC20 public rewardsToken;

    address public owner;

    uint public duration;
    uint public finishAt;
    uint public periodDuration;
    uint public originalStart;
    uint public currentPeriodNonce;
    uint public updatedAt;

    uint public rewardPerSecond;
    uint public rewardRatePerTraded;

    struct PeriodDetail {
        uint periodEndRewardRate;
        uint totalTraded;
    }
    mapping(uint => PeriodDetail) public periods;

    uint public rewardRateLastStored;

    mapping(address => uint) public rewards;

    struct UserTrade {
        uint lastPeriodNonce;
        uint lastRewardRate;
        uint lastTraded;
    }
    mapping(address => UserTrade) public usersLastTrade;

    constructor(address _rewardToken) {
        owner = msg.sender;
        rewardsToken = IERC20(_rewardToken);
        originalStart = block.timestamp;
        currentPeriodNonce = 0;
        updatedAt = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier updateReward(address _account, uint _amount) {
        rewardRatePerTraded = rewardPerTrade(_amount);

        if (_amount != 0 ) {
            updatedAt = lastTimeRewardApplicable();
        }

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            UserTrade memory t = usersLastTrade[_account];
            if (t.lastPeriodNonce == currentPeriodNonce) {
                usersLastTrade[_account] = UserTrade({
                    lastPeriodNonce: currentPeriodNonce,
                    lastRewardRate: rewardRatePerTraded,
                    lastTraded: t.lastTraded + _amount
                });
            } else {
                usersLastTrade[_account] = UserTrade({
                    lastPeriodNonce: currentPeriodNonce,
                    lastRewardRate: rewardRatePerTraded,
                    lastTraded: _amount
                });
            }
        }
        _;
    }

    function getReward() external updateReward(address(0), 0) {
        UserTrade memory t = usersLastTrade[msg.sender];

        if (t.lastPeriodNonce < currentPeriodNonce) {
            uint totalRewardPreviousPeriods = (
                (t.lastTraded *
                    (periods[t.lastPeriodNonce].periodEndRewardRate -
                        t.lastRewardRate))
            ) + rewards[msg.sender];
            if (totalRewardPreviousPeriods > 0) {
                rewards[msg.sender] = 0;
                rewardsToken.transfer(msg.sender, totalRewardPreviousPeriods);
                usersLastTrade[msg.sender] = UserTrade({
                    lastPeriodNonce: 0,
                    lastRewardRate: 0,
                    lastTraded: 0
                });
            }
        }
    }

    function recordTrade(
        address _account,
        uint _tradeAmount
    ) external updateReward(_account, _tradeAmount) {
        require(_tradeAmount > 0, "amount = 0");
        require(finishAt > block.timestamp, "finishAt <= block.timestamp");
        PeriodDetail memory p = periods[currentPeriodNonce];
        periods[currentPeriodNonce] = PeriodDetail({
            periodEndRewardRate: rewardRatePerTraded,
            totalTraded: _tradeAmount + p.totalTraded
        });
    }

    function rewardPerTrade(uint _amount) private returns (uint) {
        PeriodDetail memory p = periods[currentPeriodNonce];
        if (
            currentPeriodNonce ==
            ((lastTimeRewardApplicable() - originalStart) / periodDuration)
        ) {
            if (p.totalTraded == 0) {
                return p.periodEndRewardRate;
            } else {
                if (_amount == 0) {
                    return p.periodEndRewardRate;
                } else {
                    return
                        p.periodEndRewardRate +
                        (rewardPerSecond *
                            (lastTimeRewardApplicable() - updatedAt)) /
                        p.totalTraded;
                }
            }
        } else {
            uint newCurrentPeriodNonce = ((lastTimeRewardApplicable() -
                originalStart) / periodDuration);

            if (_amount == 0) {
                uint rLast = p.periodEndRewardRate +
                    (rewardPerSecond *
                        (originalStart +
                            (currentPeriodNonce + 1) *
                            periodDuration -
                            updatedAt)) /
                    p.totalTraded;
                periods[currentPeriodNonce].periodEndRewardRate = rLast;
            } else {
                if (p.totalTraded == 0) {
                    uint rLast = 0;
                    periods[currentPeriodNonce].periodEndRewardRate = rLast;
                } else {
                    uint rLast = p.periodEndRewardRate +
                        (rewardPerSecond *
                            (lastTimeRewardApplicable() - updatedAt)) /
                        p.totalTraded;
                    periods[currentPeriodNonce].periodEndRewardRate = rLast;
                }
            }

            periods[newCurrentPeriodNonce] = PeriodDetail({
                periodEndRewardRate: 0,
                totalTraded: 0
            });
            currentPeriodNonce = newCurrentPeriodNonce;
            return periods[newCurrentPeriodNonce].periodEndRewardRate;
        }
    }

    function setRewardsDuration(
        uint _duration,
        uint _periodDuration
    ) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished yet");
        duration = _duration;
        periodDuration = _periodDuration;
        finishAt = block.timestamp + duration;
    }

    function setRewardAmount(
        uint _amount
    ) external onlyOwner updateReward(address(0), _amount) {
        if (block.timestamp >= finishAt) {
            rewardPerSecond = (_amount * 1e18) / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) *
                rewardPerSecond;
            rewardPerSecond = (_amount * 1e18 + remainingRewards) / duration;
        }
        require(rewardPerSecond > 0, "rewardPerSecond is zero");
        require(
            rewardPerSecond * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > contract balance"
        );
        if (finishAt == 0) {
            finishAt = originalStart + duration;
        }
        // updatedAt = block.timestamp;
    }

    function earned(address _account) public view returns (uint) {
        UserTrade memory t = usersLastTrade[_account];
        if (currentPeriodNonce == t.lastPeriodNonce) {
            return
                ((t.lastTraded * (rewardRatePerTraded - t.lastRewardRate))) +
                rewards[_account];
        } else {
            return
                (
                    (t.lastTraded *
                        (periods[t.lastPeriodNonce].periodEndRewardRate -
                            t.lastRewardRate))
                ) + rewards[_account];
        }
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}