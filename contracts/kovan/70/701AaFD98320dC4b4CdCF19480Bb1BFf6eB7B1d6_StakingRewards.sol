/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
}

// File: contracts/StakingRewards.sol

// SPDX-License-Identifier: MIT
// Optimization: 1500
pragma solidity ^0.8.2;


contract StakingRewards {
  IERC20 public stakingToken;

  uint public rewardPerToken;

  uint public _totalSupply;
  mapping(address => uint) public _balances;
  mapping(address => uint) public _rewardsTally;

  constructor(address _stakingToken) {
    stakingToken = IERC20(_stakingToken);
  }

  function distribute(uint reward) public {
    if (_totalSupply != 0) {
      rewardPerToken = rewardPerToken + reward / _totalSupply;
    }
  }

  /**
    Calculate earned for given account
   */
  function earned(address account) public view returns (uint) {
    return _balances[account] * rewardPerToken - _rewardsTally[account];
  }

  /**
    Stake
   */
  function stake(uint _amount) external {
    _totalSupply += _amount;
    _balances[msg.sender] += _amount;
    _rewardsTally[msg.sender] = _rewardsTally[msg.sender] + rewardPerToken * _amount;
    stakingToken.transferFrom(msg.sender, address(this), _amount);
  }

  /**
    See how many tokens each user can unstake
    Calculate the amount for unstake = balance + earned
   */
  function calcUnstake(address account) public view returns (uint) {
    return _balances[account] + earned(account);
  }

  /**
    Unstake (would be a plus if caller can unstake part of stake)
    Unstake given amount
   */
  function unstake(uint _amount) external {
    _totalSupply -= _amount;
    _balances[msg.sender] -= _amount;
    _rewardsTally[msg.sender] = _rewardsTally[msg.sender] - rewardPerToken * _amount;
    stakingToken.transfer(msg.sender, _amount);
  }

  /**
    Get(claim) reward 
   */
  function getReward() external {
    uint reward = earned(msg.sender);
    _rewardsTally[msg.sender] = _balances[msg.sender] * rewardPerToken;
    stakingToken.transfer(msg.sender, reward);
  }
}