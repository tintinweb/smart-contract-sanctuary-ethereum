// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICILStaking} from "./interfaces/ICILStaking.sol";

/// @notice cilistia staking contract
contract CILStaking is ICILStaking {
  /// @notice multi sign wallet address of team
  address public immutable multiSig;
  /// @notice cil token address
  address public immutable cil;
  /// @notice p2p marketplace contract address
  address public immutable marketplace;

  struct Stake {
    uint256 tokenAmount; // amount of tokens locked in a stake
    uint256 lockedAmount; // amount of tokens locked in a stake
    uint256 stakedTime; // start time of locking
  }

  /// @notice active stakes for each user
  mapping(address => Stake) public stakes;
  /// @notice active user address list
  address[] private users;

  /// @notice total staked token amount
  uint256 public totalStakedAmount;

  /// @notice lock time - immutable 1 weeks
  uint256 public immutable lockTime = 1 weeks;

  /**
   * @param cil_ cil token address
   * @param marketplace_ marketplace address
   * @param multiSig_ multi sign wallet address
   */
  constructor(
    address cil_,
    address marketplace_,
    address multiSig_
  ) {
    cil = cil_;
    marketplace = marketplace_;
    multiSig = multiSig_;
  }

  /**
   * @dev stake token with amount
   * @param amount token amount to stake
   */
  function stake(uint256 amount) external {
    Stake memory newStake = stakes[msg.sender];
    if (newStake.tokenAmount > 0) {
      newStake.tokenAmount += _collectedTokenAmount(msg.sender);
    } else {
      users.push(msg.sender);
    }

    newStake.tokenAmount += amount;
    totalStakedAmount += (newStake.tokenAmount - stakes[msg.sender].tokenAmount);
    newStake.stakedTime = block.timestamp;

    stakes[msg.sender] = newStake;

    IERC20(cil).transferFrom(msg.sender, address(this), amount);

    emit StakeUpdated(msg.sender, newStake.tokenAmount, newStake.lockedAmount);
  }

  /**
   * @dev unstake staked token
   * @param amount token amount to unstake
   */
  function unStake(uint256 amount) external {
    uint256 rewardAmount = _collectedTokenAmount(msg.sender);

    Stake memory newStake = stakes[msg.sender];
    uint256 newTotalStakedAmount = totalStakedAmount;

    uint256 withdrawAmount = amount;

    if (newStake.tokenAmount + rewardAmount < newStake.lockedAmount + amount) {
      withdrawAmount = newStake.tokenAmount + rewardAmount - newStake.lockedAmount;
    }

    newStake.tokenAmount += rewardAmount;
    newStake.tokenAmount -= withdrawAmount;

    newTotalStakedAmount += rewardAmount;
    newTotalStakedAmount -= withdrawAmount;

    if (newStake.tokenAmount == 0) {
      for (uint256 i = 0; i < users.length; i++) {
        if (users[i] == msg.sender) {
          users[i] = users[users.length - 1];
          users.pop();
        }
      }
    }

    stakes[msg.sender] = newStake;
    totalStakedAmount = newTotalStakedAmount;

    IERC20(cil).transfer(msg.sender, withdrawAmount);

    emit UnStaked(msg.sender, withdrawAmount);
  }

  /**
   * @dev return colleted token amount
   * @return collectedAmount total collected token amount
   */
  function collectedToken(address user) external view returns (uint256 collectedAmount) {
    collectedAmount = _collectedTokenAmount(user);
  }

  /**
   * @dev return colleted token amount
   * @param user user address
   * @return stakingAmount lockable staking token amount
   */
  function lockableCil(address user) external view returns (uint256 stakingAmount) {
    stakingAmount = stakes[user].tokenAmount - stakes[user].lockedAmount;
  }

  /**
   * @dev return colleted token amount
   * @param user user address
   * @return stakingAmount unlocked staking token amount
   */
  function lockedCil(address user) external view returns (uint256 stakingAmount) {
    stakingAmount = stakes[user].lockedAmount;
  }

  /**
   * @dev lock staked token: called from marketplace contract
   * @param amount token amount to lock
   */
  function lock(address user, uint256 amount) external {
    require(msg.sender == marketplace, "CILStaking: forbidden");
    require(stakes[user].tokenAmount >= amount, "CILStaking: insufficient staking amount");

    stakes[user].lockedAmount = amount;

    emit StakeUpdated(user, stakes[user].tokenAmount, amount);
  }

  /// @dev remove staking data
  function remove(address user) external {
    require(msg.sender == marketplace, "CILStaking: forbidden");

    Stake memory newStake = stakes[user];

    uint256 reward = _collectedTokenAmount(user) + newStake.stakedTime;

    newStake.stakedTime = block.timestamp;
    newStake.tokenAmount = 0;
    newStake.lockedAmount = 0;

    stakes[user] = newStake;

    IERC20(cil).transfer(multiSig, reward);

    emit StakeUpdated(user, 0, 0);
  }

  /// @dev return total releasable token amount of staking contract
  function _totalReleasable() private view returns (uint256) {
    return IERC20(cil).balanceOf(address(this)) - totalStakedAmount;
  }

  /// @dev return total stake point of staking contract stake point = amount * period
  function _totalStakePoint() private view returns (uint256 totalStakePoint) {
    totalStakePoint = 0;
    for (uint256 i = 0; i < users.length; i++) {
      totalStakePoint +=
        stakes[users[i]].tokenAmount *
        (block.timestamp - stakes[users[i]].stakedTime);
    }
  }

  /// @dev get collected token amount
  function _collectedTokenAmount(address user) private view returns (uint256) {
    uint256 totalReleasable = _totalReleasable();
    uint256 totalStakePoint = _totalStakePoint();
    uint256 stakePoint = stakes[user].tokenAmount * (block.timestamp - stakes[user].stakedTime);

    if (stakePoint == 0) {
      return 0;
    }

    return (totalReleasable * stakePoint) / totalStakePoint;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

/// @notice cilistia staking contract interface
interface ICILStaking {
  /// @notice fires when stake state changes
  event StakeUpdated(address user, uint256 stakedAmount, uint256 lockedAmount);

  /// @notice fires when unstake token
  event UnStaked(address user, uint256 rewardAmount);

  /// @dev unstake staked token
  function lock(address user, uint256 amount) external;

  /// @dev remove staking data
  function remove(address user) external;

  /// @dev return colleted token amount
  function collectedToken(address user) external view returns (uint256);

  /// @dev return lockable token amount
  function lockableCil(address user) external view returns (uint256);

  /// @dev return locked token amount
  function lockedCil(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}