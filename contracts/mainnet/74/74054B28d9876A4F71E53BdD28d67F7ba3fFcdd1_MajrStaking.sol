// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMajrNFT {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IMajrCanon {
  function paused() external view returns (bool);
}

contract MajrStaking is Ownable, ReentrancyGuard, Pausable {
  /// @notice Address of the reward token (MAJR ERC20 token)
  IERC20 public immutable rewardsToken;

  /// @notice Address of the staking token
  IMajrNFT public immutable stakingToken;

  /// @notice Address of the MAJR Canon (governance) contract
  IMajrCanon public majrCanon;

  /// @notice Tracks the period where users stop earning rewards
  uint256 public periodFinish = 0;

  /// @notice Rewards rate that users are earning
  uint256 public rewardRate = 0;

  /// @notice How long the rewards lasts, it updates when more rewards are added
  uint256 public rewardsDuration = 4383 days; // ~ 12 years, including the leap years of 2024, 2028 & 2032

  /// @notice Last time rewards were updated
  uint256 public lastUpdateTime;

  /// @notice Amount of reward calculated per token stored
  uint256 public rewardPerTokenStored;

  /// @notice Track the rewards paid to users
  mapping(address => uint256) public userRewardPerTokenPaid;

  /// @notice Tracks the user rewards
  mapping(address => uint256) public rewards;

  /// @notice Tracks which user has staked which token Ids
  mapping(address => uint256[]) public userStakedTokenIds;

  /// @dev Tracks the total supply of staked tokens
  uint256 private _totalSupply;

  /// @dev Tracks the amount of staked tokens per user
  mapping(address => uint256) private _balances;

  /// @notice An event emitted when a reward is added
  event RewardAdded(uint256 reward);

  /// @notice An event emitted when a single NFT is staked
  event Stake(address indexed user, uint256 tokenId);

  /// @notice An event emitted when all NFTs from a single transaction are staked by a user
  event StakeTotal(address indexed user, uint256 amount);

  /// @notice An event emitted when a single staked NFT is withdrawn
  event Withdraw(address indexed user, uint256 tokenId);

  /// @notice An event emitted when all staked tokens are withdrawn in a single transaction by a user
  event WithdrawTotal(address indexed user, uint256 amount);

  /// @notice An event emitted when reward is paid to a user
  event RewardPaid(address indexed user, uint256 reward);

  /// @notice An event emitted when the rewards duration is updated
  event RewardsDurationUpdated(uint256 newDuration);

  /**
   * @notice Constructor
   * @param _owner address
   * @param _rewardsToken address
   * @param _stakingToken uint256
   */
  constructor(address _owner, address _rewardsToken, address _stakingToken) {
    rewardsToken = IERC20(_rewardsToken);
    stakingToken = IMajrNFT(_stakingToken);
    transferOwnership(_owner);
  }

  /**
   * @notice Updates the reward and time on call
   * @param _account address
   */
  modifier updateReward(address _account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();

    if (_account != address(0)) {
      rewards[_account] = earned(_account);
      userRewardPerTokenPaid[_account] = rewardPerTokenStored;
    }
    _;
  }

  /** 
   * @notice Returns the total amount of staked tokens
   * @return uint256
  */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @notice Returns the amount of staked tokens from a specific user
   * @param _account address
   * @return uint256
   */
  function balanceOf(address _account) external view returns (uint256) {
    return _balances[_account];
  }

  /**
   * @notice Returns the total amount of tokens to be distributed as a reward
   * @return uint256
   */ 
  function getRewardForDuration() external view returns (uint256) {
    return rewardRate * rewardsDuration;
  }

  /**
   * @notice Returns the IDs of all NFTs that a particular user has staked
   * @param _user address
   * @return uint256[] memory
   */
  function getUserStakedTokenIds(address _user) external view returns (uint256[] memory) {
    return userStakedTokenIds[_user];
  }

  /**
   * @notice Transfers staking tokens (NFTs) to the staking contract
   * @param _tokenIds uint256[] calldata
   * @dev Updates rewards on call
   */
  function stake(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender)  {
    require(_tokenIds.length > 0, "MajrStaking: Cannot stake 0 tokens.");

    _totalSupply += _tokenIds.length;
    _balances[msg.sender] += _tokenIds.length;

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      userStakedTokenIds[msg.sender].push(_tokenIds[i]);
      stakingToken.transferFrom(msg.sender, address(this), _tokenIds[i]);

      emit Stake(msg.sender, _tokenIds[i]);
    }

    emit StakeTotal(msg.sender, _tokenIds.length);
  }

  /// @notice Removes all stake and transfers all rewards to the staker
  function exit() external {
    withdraw(_balances[msg.sender]);
    getReward();
  }

  /**
   * @notice Notifies the contract that reward has been added to be given
   * @param _reward uint
   * @dev Only owner can call it
   * @dev Increases duration of rewards
   */
  function notifyRewardAmount(uint256 _reward) external onlyOwner updateReward(address(0)) {
    if (block.timestamp >= periodFinish) {
      rewardRate = _reward / rewardsDuration;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftover = remaining * rewardRate;
      rewardRate = (_reward + leftover) / rewardsDuration;
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(rewardRate <= balance / rewardsDuration, "MajrStaking: Provided reward too high");
    
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardsDuration;

    emit RewardAdded(_reward);
  }

  /**
   * @notice Updates the reward duration
   * @param _rewardsDuration uint
   * @dev Only owner can call it
   * @dev Previous rewards must be completed
   */
  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(block.timestamp > periodFinish, "MajrStaking: Previous rewards period must be complete before changing the duration for the new period.");

    rewardsDuration = _rewardsDuration;

    emit RewardsDurationUpdated(rewardsDuration);
  }

  /**
   * @notice Returns the minimum between the current block timestamp or the finish period of rewards
    * @return uint256
   */ 
  function lastTimeRewardApplicable() public view returns (uint256) {
    return min(block.timestamp, periodFinish);
  }

  /**
   * @notice Returns the calculated reward per token deposited
   * @return uint256
   */ 
  function rewardPerToken() public view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }

    return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate) / _totalSupply;
  }

  /**
   * @notice Returns the amount of reward tokens a user has earned
   * @param _account address
   * @return uint256
   */
  function earned(address _account) public view returns (uint256) {
    return _balances[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account]) + rewards[_account];
  }

  /**
   * @notice Returns the minimun between two variables
   * @param _a uint
   * @param _b uint
   * @return uint256
   */
  function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }

  /**
   * @notice Removes staking tokens and transfers them back to the staker. Users can only withdraw while the voting in the MAJR Canon (governance) contract is not active
   * @param _amount uint
   * @dev Updates rewards on call
   */
  function withdraw(uint256 _amount) public nonReentrant updateReward(msg.sender) {
    require(_amount > 0, "MajrStaking: Cannot withdraw 0 tokens.");
    require(_amount <= _balances[msg.sender], "MajrStaking: Cannot withdraw more tokens than staked.");
    require(isVotingActive() == false, "MajrStaking: Cannot withdraw staked MAJR IDs while voting is active.");

    _totalSupply = _totalSupply - _amount;
    _balances[msg.sender] = _balances[msg.sender] - _amount;

    for (uint256 i = 0; i < _amount; i++) {
      uint256 tokenId = userStakedTokenIds[msg.sender][userStakedTokenIds[msg.sender].length - 1];

      userStakedTokenIds[msg.sender].pop();
      stakingToken.transferFrom(address(this), msg.sender, tokenId);

      emit Withdraw(msg.sender, tokenId);
    }

    emit WithdrawTotal(msg.sender, _amount);
  }

  /**
   * @notice Transfers the current amount of rewards tokens earned to the caller
   * @dev Updates rewards on call
   */
  function getReward() public nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];

    if (reward > 0) {
      rewards[msg.sender] = 0;

      bool sent = rewardsToken.transfer(msg.sender, reward);
      require(sent, "MajrStaking: ERC20 token transfer failed.");

      emit RewardPaid(msg.sender, reward);
    }
  }

  /**
   * @notice Pauses the pausable functions inside the contract
   * @dev Only owner can call it
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the pausable functions inside the contract
   * @dev Only owner can call it
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Returns whether or not the voting is currently active in the MAJR Canon contract. Voting is considered to be active only if the MAJR Canon contract is not paused
   * @return bool
   */
  function isVotingActive() public view returns (bool) {
    return majrCanon.paused() == false;
  }

  /**
   * @notice Sets the new governance contract (MAJR Canon) address
   * @dev Only owner can call it
   */
  function setMajrCanon(address _majrCanon) external onlyOwner {
    majrCanon = IMajrCanon(_majrCanon);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}