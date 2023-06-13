/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Staking {
    using SafeMath for uint256;

    uint256 constant REWARD_STEP_COUNT = 43200; // Number of steps for reward distribution
    uint256 constant REWARD_EACH_STEP_DURATION = 1; // Duration of each reward step in seconds
    uint256 constant ONE_YEAR_IN_SECOND = 31536000; // Number of seconds in one year

    IERC20 public ourToken;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    struct AmountHistory {
        uint256 amount;
        uint256 fromTimestamp;
        uint256 toTimestamp;
    }

    mapping(address => AmountHistory[]) userStakingHistory;
    
    AmountHistory[] rewardHistoryList;
    AmountHistory[] rewardPerTokenHistoryList;

    uint256 totalClaimedReward;
    uint256 totalStakedBalance;

    constructor(address _ourToken) {
        ourToken = IERC20(_ourToken);
    }

    function currentApy() external view returns (uint256) {
        uint256 rewardPerToken = calculateRewardPerToken();
        uint256 annualReward = rewardPerToken.mul(ONE_YEAR_IN_SECOND.div(REWARD_EACH_STEP_DURATION));
        uint256 apyPercent = 0;
        if(annualReward > 1e18)
            apyPercent = annualReward.sub(1e18);
        return apyPercent;
    }

    function updateRewardPool() public {
        uint256 currentRewardBalance = ourToken.balanceOf(address(this)).sub(totalStakedBalance).add(totalClaimedReward);
        uint256 lastRewardBalance = 0;

        if (rewardHistoryList.length > 0) {
            lastRewardBalance = rewardHistoryList[rewardHistoryList.length - 1].amount;
        }

        if (currentRewardBalance > lastRewardBalance) {
            uint256 newBalance = currentRewardBalance.sub(lastRewardBalance);
            rewardHistoryList.push(AmountHistory(newBalance, block.timestamp, block.timestamp.add(REWARD_STEP_COUNT.mul(REWARD_EACH_STEP_DURATION))));
            updateRewardPerToken();
        } else {
            revert("FailedToDetectNewRewardDeposit");
        }
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Invalid amount");

        totalStakedBalance = totalStakedBalance.add(amount);

        uint256 lastUserStakedBalance = 0;

        if(userStakingHistory[msg.sender].length > 0){
            userStakingHistory[msg.sender][userStakingHistory[msg.sender].length - 1].toTimestamp = block.timestamp;
            lastUserStakedBalance = userStakingHistory[msg.sender][userStakingHistory[msg.sender].length - 1].amount;
        }
 
        userStakingHistory[msg.sender].push(AmountHistory(lastUserStakedBalance.add(amount), block.timestamp, 0));
        
        updateRewardPerToken();

        bool result = ourToken.transferFrom(msg.sender, address(this), amount);
        require(result, "FailedToTransferToken");

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(totalStakedBalance >= amount, "Invalid amount");

        totalStakedBalance = totalStakedBalance.sub(amount);

        uint256 lastUserStakedBalance = 0;

        if(userStakingHistory[msg.sender].length > 0){
            userStakingHistory[msg.sender][userStakingHistory[msg.sender].length - 1].toTimestamp = block.timestamp;
            lastUserStakedBalance = userStakingHistory[msg.sender][userStakingHistory[msg.sender].length - 1].amount;
        }

        require(lastUserStakedBalance >= amount, "InsufficientBalance");

        userStakingHistory[msg.sender].push(AmountHistory(lastUserStakedBalance.sub(amount), block.timestamp, 0));

        updateRewardPerToken();


        bool result = ourToken.transfer(msg.sender, amount);
        require(result, "FailedToTransferToken");

        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external {
        uint256 availableReward = rewardBalance();
        require(availableReward > 0, "InsufficientBalance");

        totalClaimedReward = totalClaimedReward.add(availableReward);

        uint256 lastUserStakedBalance = 0;

        if (userStakingHistory[msg.sender].length > 0)
            lastUserStakedBalance = userStakingHistory[msg.sender][userStakingHistory[msg.sender].length - 1].amount;


        delete userStakingHistory[msg.sender];
        userStakingHistory[msg.sender].push(AmountHistory(lastUserStakedBalance, block.timestamp, 0));    

        
        bool result = ourToken.transfer(msg.sender, availableReward);
        require(result, "FailedToTransferToken");

        emit RewardClaimed(msg.sender, availableReward);
    }

    function stakeBalance(address user) external view returns (uint256) {
        uint256 balance = userStakingHistory[user].length > 0 ? userStakingHistory[user][userStakingHistory[user].length - 1].amount : 0;
        return balance;
    }

    function rewardBalance() public view returns (uint256) {
        uint256 calculatedReward = 0;

        for (uint256 i = 0; i < userStakingHistory[msg.sender].length; i++) {
            AmountHistory storage userHistory = userStakingHistory[msg.sender][i];
            uint256 userStartTime = userHistory.fromTimestamp;
            uint256 userEndTime = userHistory.toTimestamp > 0 ? userHistory.toTimestamp : block.timestamp;

            for (uint256 j = 0; j < rewardPerTokenHistoryList.length; j++) {
                AmountHistory storage rewardHistory = rewardPerTokenHistoryList[j];
                uint256 rewardStartTime = rewardHistory.fromTimestamp;
                uint256 rewardEndTime = rewardHistory.toTimestamp > 0 ? rewardHistory.toTimestamp : block.timestamp;
                
                if (rewardHistory.amount > 0 && (rewardStartTime < userEndTime || rewardEndTime > userStartTime)) {
                    uint256 endDuration = min(rewardEndTime, userEndTime);
                    uint256 startDuration = max(rewardStartTime, userStartTime);
                    
                    if (startDuration <= endDuration){
                        uint256 rewardDuration = endDuration.sub(startDuration);
                        calculatedReward = calculatedReward.add(rewardDuration.mul(rewardHistory.amount).mul(userHistory.amount.div(1e18)));
                    }
                }
            }
        }

        return calculatedReward;
    }

    function calculateRewardPerToken() internal view returns (uint256) {
        uint256 rewardRatePerStep = 0;

        for (uint256 i = 0; i < rewardHistoryList.length; i++) {
            if (rewardHistoryList[i].toTimestamp > block.timestamp && totalStakedBalance > 0) {
                rewardRatePerStep = rewardRatePerStep.add(rewardHistoryList[i].amount.div(REWARD_STEP_COUNT).div(totalStakedBalance.div(1e18)));
            }
        }

        return rewardRatePerStep;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a <= b ? a : b;
    }


    function updateRewardPerToken() private {
        if(rewardPerTokenHistoryList.length > 0)
            rewardPerTokenHistoryList[rewardPerTokenHistoryList.length - 1].toTimestamp = block.timestamp;

        rewardPerTokenHistoryList.push(AmountHistory(calculateRewardPerToken(), block.timestamp, 0));
    }
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}