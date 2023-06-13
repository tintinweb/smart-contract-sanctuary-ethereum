/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


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

contract FarmingContract {
    using SafeMath for uint256;
    
    IERC20 public lpToken;
    IERC20 public rewardToken;
    
    address public owner;
    uint256 public totalRewards;
    uint256 public duration;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public rewardsPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    uint256 public lastUpdateTime;
    
    uint256 public constant PRECISION = 10**18;
    uint256 public lpTokenDecimal;
    uint256 public rewardTokenDecimal;

    constructor(
        address _owner,
        address _lpToken,
        uint256 _lpTokenDecimal,
        address _rewardToken,
        uint256 _rewardTokenDecimal,
        uint256 _totalRewards,
        uint256 _duration
    ) {
        owner = _owner;
        lpToken = IERC20(_lpToken);
        lpTokenDecimal = _lpTokenDecimal;
        rewardToken = IERC20(_rewardToken);
        rewardTokenDecimal = _rewardTokenDecimal;
        totalRewards = _totalRewards.mul(PRECISION).div(10**_rewardTokenDecimal); // convert to standard precision 
        duration = _duration.mul(1 days);
        lastUpdateTime = block.timestamp;

        require(lpToken.approve(address(this), type(uint256).max), "LP Token approve failed.");
        require(rewardToken.approve(address(this), type(uint256).max), "Reward Token approve failed.");
    }

    function startFarming() external {
        require(msg.sender == owner, "Only the contract owner can start farming.");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Farm not open.");
        
        uint256 _totalSupply = lpToken.balanceOf(address(this)).mul(PRECISION).div(10**lpTokenDecimal); // convert to standard precision
        rewardsPerTokenStored = rewardsPerToken();
        lastUpdateTime = block.timestamp;
        emit FarmingStarted(_totalSupply);
    }

    function claimRewards() external {
        updateReward(msg.sender);
        require(rewards[msg.sender] > 0, "No rewards to claim.");
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }
    
    function withdrawLP(uint256 _amount) external {
        require(msg.sender == owner, "Only the contract owner can withdraw LP tokens.");
        require(lpToken.transfer(owner, _amount), "LP token transfer failed.");
        emit LPTokenWithdrawn(owner, _amount);
    }

    function calculateRewards(uint256 _amount) public view returns (uint256) {
        uint256 _totalSupply = lpToken.balanceOf(address(this)).mul(PRECISION).div(10**lpTokenDecimal); // convert to standard precision
        uint256 _rewards = _amount.mul(totalRewards).div(_totalSupply);
        return _rewards.mul(10**rewardTokenDecimal).div(PRECISION); // convert to reward token decimal precision
    }
    
    function rewardsPerToken() public view returns (uint256) {
        uint256 _totalSupply = lpToken.balanceOf(address(this)).mul(PRECISION).div(10**lpTokenDecimal); // convert to standard precision
        if (_totalSupply == 0) {
            return rewardsPerTokenStored;
        }
        uint256 _lastUpdateTime = lastTimeRewardApplicable();
        uint256 _timeDelta = _lastUpdateTime.sub(lastUpdateTime);
        uint256 _rewardRate = totalRewards.div(duration);
        uint256 _rewardDelta = _timeDelta.mul(_rewardRate).mul(PRECISION).div(_totalSupply);
        return rewardsPerTokenStored.add(_rewardDelta);
    }

    function updateReward(address _account) internal {
        rewardsPerTokenStored = rewardsPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardsPerTokenStored;
        }
    }

    function earned(address _account) public view returns (uint256) {
        uint256 _balance = lpToken.balanceOf(address(this)).mul(PRECISION).div(10**lpTokenDecimal); // convert to standard precision
        return _balance.mul(rewardsPerToken().sub(userRewardPerTokenPaid[_account])).div(PRECISION).add(rewards[_account]);
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return block.timestamp < endTime ? block.timestamp : endTime;
    }

    event FarmingStarted(uint256 _totalSupply);
    event RewardClaimed(address indexed _account, uint256 _reward);
    event LPTokenWithdrawn(address indexed _owner, uint _amount);
}