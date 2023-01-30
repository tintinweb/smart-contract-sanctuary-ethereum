// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { VucaOwnable } from "./VucaOwnable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// VUCA + Pellar + LightLink 2023

contract VucaStaking is VucaOwnable {
  using SafeERC20 for IERC20;

  // constants
  enum UpdateParam {
    MaxStakeTokens,
    RewardTokensPerBlock,
    EndBlock
  }

  // Staking user data
  struct Staking {
    uint256 amount;
    uint256 accumulatedRewards;
    uint256 minusRewards; // rewards that user can not get computed by block
  }

  struct Extension {
    uint256 currentPoolChangeId;
    uint256 totalUserRewards;
    uint256 rewardsWithdrew;
    uint256 totalPoolRewards;
    uint256 noAddressRewards;
  }

  // Staking pool
  struct Pool {
    bool inited;
    address rewardToken; // require init
    address stakeToken; // require init
    uint32 updateDelay; // blocks // default 2048 blocks = 8 hours
    uint256 maxStakeTokens; // require init
    uint256 startBlock; // require init
    uint256 endBlock; // require init
    uint256 rewardTokensPerBlock; // require init
    uint256 tokensStaked;
    uint256 lastRewardedBlock; // require init
    uint256 accumulatedRewardsPerShare;
    Extension extension;
  }

  struct PoolChanges {
    bool applied;
    UpdateParam updateParamId;
    uint256 updateParamValue;
    uint256 timestamp;
    uint256 blockNumber;
  }

  uint256 public constant REWARDS_PRECISION = 1e18; // adjustment

  uint16 public currentPoolId;

  mapping(uint16 => Pool) public pools; // staking events

  // Mapping poolId =>
  mapping(uint16 => PoolChanges[]) public poolsChanges; // staking changes queue

  // Mapping poolId => user address => Staking
  mapping(uint16 => mapping(address => Staking)) public stakingUsersInfo;

  // Events
  event StakingChanged(uint8 indexed eventId, address indexed user, uint16 indexed poolId, Pool pool, Staking staking);
  event PoolCreated(uint8 indexed eventId, uint16 indexed poolId, Pool pool, uint256 activeBlock);
  event PoolUpdated(uint8 indexed eventId, uint16 indexed poolId, Pool pool, PoolChanges changes, uint256 activeBlock);
  event RewardsRetrieved(uint8 indexed eventId, uint16 indexed poolId, address sender, address to, uint256 amount);

  // Constructor
  constructor() {}

  /* View */
  // rewards w/o adjustment
  function getRawRewards(uint16 _poolId, address _account) internal view returns (uint256) {
    Staking memory staking = stakingUsersInfo[_poolId][_account];
    Pool memory pool = pools[_poolId];

    pool = _getPoolRewards(pool, block.number);

    return staking.accumulatedRewards + (staking.amount * pool.accumulatedRewardsPerShare) - staking.minusRewards;
  }

  // rewards with adjustment
  function getRewards(uint16 _poolId, address _account) internal view returns (uint256) {
    uint256 rawRewards = getRawRewards(_poolId, _account);

    return rawRewards / (10**IERC20Helper(pools[_poolId].stakeToken).decimals()) / REWARDS_PRECISION;
  }

  /* User */
  function stake(uint16 _poolId, uint256 _amount) external {
    _updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    require(pool.startBlock <= block.number, "Staking inactive");
    require(pool.endBlock >= block.number, "Staking ended");
    require(_amount > 0, "Invalid amount");
    require(_amount + pool.tokensStaked <= pool.maxStakeTokens, "Exceed max stake tokens");

    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];

    _updatePoolRewards(_poolId, block.number);
    // Update user
    staking.accumulatedRewards = getRawRewards(_poolId, msg.sender);
    staking.amount += _amount;
    staking.minusRewards = staking.amount * pool.accumulatedRewardsPerShare;

    // Update pool
    pool.tokensStaked += _amount;

    // Deposit tokens
    emit StakingChanged(0, msg.sender, _poolId, pool, staking);
    IERC20(pool.stakeToken).safeTransferFrom(address(msg.sender), address(this), _amount);
  }

  // rewards will be forfeited if this is called (use unStake to obtain rewards after staking period)
  function emergencyWithdraw(uint16 _poolId) external {
    _updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];
    uint256 amount = staking.amount;
    require(staking.amount > 0, "Insufficient funds");

    _updatePoolRewards(_poolId, block.number);
    uint256 rewards = getRewards(_poolId, msg.sender);
    // Update pool
    pool.tokensStaked -= amount;
    pool.extension.noAddressRewards += rewards;

    // Update staker
    staking.accumulatedRewards = 0;
    staking.minusRewards = 0;
    staking.amount = 0;

    emit StakingChanged(0, msg.sender, _poolId, pool, staking);

    // Withdraw tokens
    IERC20(pool.stakeToken).safeTransfer(address(msg.sender), amount);
  }

  // unstake, get rewards
  function unStake(uint16 _poolId) external {
    _updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    require(pool.endBlock < block.number, "Staking active");

    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];
    uint256 amount = staking.amount;
    require(staking.amount > 0, "Insufficient funds");

    _updatePoolRewards(_poolId, block.number);
    uint256 rewards = getRewards(_poolId, msg.sender);

    // Update pool
    pool.tokensStaked -= amount;

    // Update staker
    staking.accumulatedRewards = 0;
    staking.minusRewards = 0;
    staking.amount = 0;

    emit StakingChanged(0, msg.sender, _poolId, pool, staking);

    // Pay rewards
    IERC20(pool.rewardToken).safeTransfer(msg.sender, rewards);

    // Withdraw tokens
    IERC20(pool.stakeToken).safeTransfer(address(msg.sender), amount);
  }

  /* Admin */
  function createPool(
    address _rewardToken,
    address _stakeToken,
    uint256 _maxStakeTokens,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _rewardTokensPerBlock,
    uint32 _updateDelay
  ) external onlyOwner {
    require(_startBlock > block.number && _startBlock < _endBlock, "Invalid start/end block");
    require(_rewardToken != address(0), "Invalid reward token");
    require(_stakeToken != address(0), "Invalid staking token");
    require(currentPoolId == 0, "Staking pool was already created");

    pools[currentPoolId].inited = true;
    pools[currentPoolId].rewardToken = _rewardToken;
    pools[currentPoolId].stakeToken = _stakeToken;

    pools[currentPoolId].maxStakeTokens = _maxStakeTokens;
    pools[currentPoolId].startBlock = _startBlock;
    pools[currentPoolId].endBlock = _endBlock;

    pools[currentPoolId].rewardTokensPerBlock = _rewardTokensPerBlock * (10**IERC20Helper(_stakeToken).decimals()) * REWARDS_PRECISION;
    pools[currentPoolId].lastRewardedBlock = _startBlock;
    pools[currentPoolId].updateDelay = _updateDelay; // = 8 hours;

    emit PoolCreated(1, currentPoolId, pools[currentPoolId], block.number);
    currentPoolId += 1;
  }

  function depositPoolReward(uint16 _poolId, uint256 _amount) public {
    Pool storage pool = pools[_poolId];
    require(pool.inited, "Pool invalid");
    require(_amount > 0, "Invalid amount");
    _updatePoolInfo(_poolId);

    pool.extension.totalPoolRewards += _amount;

    IERC20(pool.rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

    PoolChanges memory changes;
    emit PoolUpdated(2, _poolId, pools[_poolId], changes, block.number);
  }

  function updateMaxStakeTokens(uint16 _poolId, uint256 _maxStakeTokens) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    _updatePoolInfo(_poolId);

    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");
    require(pools[_poolId].extension.currentPoolChangeId + 10 > poolsChanges[_poolId].length, "Exceed pending changes");

    PoolChanges memory changes = PoolChanges({
      applied: false, //
      updateParamId: UpdateParam.MaxStakeTokens,
      updateParamValue: _maxStakeTokens,
      timestamp: block.timestamp,
      blockNumber: block.number
    });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(2, _poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  function updateRewardTokensPerBlock(uint16 _poolId, uint256 _rewardTokensPerBlock) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    _updatePoolInfo(_poolId);

    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");
    require(pools[_poolId].extension.currentPoolChangeId + 10 > poolsChanges[_poolId].length, "Exceed pending changes");

    uint256 rewardTokensPerBlock = _rewardTokensPerBlock * (10**IERC20Helper(pools[_poolId].stakeToken).decimals()) * REWARDS_PRECISION;

    PoolChanges memory changes = PoolChanges({
      applied: false, //
      updateParamId: UpdateParam.RewardTokensPerBlock,
      updateParamValue: rewardTokensPerBlock,
      timestamp: block.timestamp,
      blockNumber: block.number
    });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(2, _poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  // end block updatable
  function updateEndBlock(uint16 _poolId, uint256 _endBlock) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    _updatePoolInfo(_poolId);

    require(_endBlock > block.number + pools[_poolId].updateDelay, "Invalid input");
    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");
    require(pools[_poolId].extension.currentPoolChangeId + 10 > poolsChanges[_poolId].length, "Exceed pending changes");

    PoolChanges memory changes = PoolChanges({
      applied: false, //
      updateParamId: UpdateParam.EndBlock,
      updateParamValue: _endBlock,
      timestamp: block.timestamp,
      blockNumber: block.number
    });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(2, _poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  // withdraw reward token held in contract
  function retrieveReward(uint16 _poolId, address _to) external onlyOwner {
    _updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    require(pool.endBlock < block.number, "Staking active");

    _updatePoolRewards(_poolId, block.number);

    uint256 totalPoolRewards = pool.extension.totalPoolRewards;
    uint256 noAddressRewards = pool.extension.noAddressRewards;
    uint256 rewardsWithdrew = pool.extension.rewardsWithdrew;

    uint256 totalUserRewards = pool.extension.totalUserRewards / (10**IERC20Helper(pool.stakeToken).decimals()) / REWARDS_PRECISION;

    require(totalPoolRewards + noAddressRewards > totalUserRewards + rewardsWithdrew, "Insufficient pool rewards");

    uint256 amount = totalPoolRewards + noAddressRewards - totalUserRewards - rewardsWithdrew;

    pool.extension.rewardsWithdrew += amount;

    emit RewardsRetrieved(3, _poolId, msg.sender, _to, amount);

    IERC20(pool.rewardToken).safeTransfer(_to, amount);
  }

  /* Internal */
  function _updatePoolInfo(uint16 _poolId) internal {
    Pool storage pool = pools[_poolId];

    uint256 size = poolsChanges[_poolId].length;
    uint256 i = pool.extension.currentPoolChangeId;
    for (; i < size; i++) {
      PoolChanges storage changes = poolsChanges[_poolId][i];

      uint256 updateAtBlock = changes.blockNumber + pool.updateDelay;
      if (!(pool.endBlock > updateAtBlock && block.number >= updateAtBlock)) {
        break;
      }

      _updatePoolRewards(_poolId, updateAtBlock);
      if (changes.updateParamId == UpdateParam.MaxStakeTokens) {
        pool.maxStakeTokens = changes.updateParamValue;
      } else if (changes.updateParamId == UpdateParam.EndBlock) {
        pool.endBlock = changes.updateParamValue;
      } else if (changes.updateParamId == UpdateParam.RewardTokensPerBlock) {
        pool.rewardTokensPerBlock = changes.updateParamValue;
      }
      changes.applied = true;
    }
    pool.extension.currentPoolChangeId = i;
  }

  function _updatePoolRewards(uint16 _poolId, uint256 _blockNumber) internal {
    Pool storage pool = pools[_poolId];

    Pool memory newPool = _getPoolRewards(pool, _blockNumber);

    pool.accumulatedRewardsPerShare = newPool.accumulatedRewardsPerShare;
    pool.extension.totalUserRewards = newPool.extension.totalUserRewards;
    pool.lastRewardedBlock = newPool.lastRewardedBlock;
  }

  function _getPoolRewards(Pool memory _pool, uint256 _blockNumber) internal pure returns (Pool memory) {
    uint256 floorBlock = _blockNumber <= _pool.endBlock ? _blockNumber : _pool.endBlock;

    if (_pool.tokensStaked == 0) {
      _pool.lastRewardedBlock = floorBlock;
      return _pool;
    }

    uint256 blocksSinceLastReward;
    if (floorBlock >= _pool.lastRewardedBlock) {
      blocksSinceLastReward = floorBlock - _pool.lastRewardedBlock;
    }
    uint256 rewards = blocksSinceLastReward * _pool.rewardTokensPerBlock;
    _pool.accumulatedRewardsPerShare = _pool.accumulatedRewardsPerShare + (rewards / _pool.tokensStaked);
    _pool.lastRewardedBlock = floorBlock;
    _pool.extension.totalUserRewards += rewards;

    return _pool;
  }

  function renounceOwnership() public virtual override onlyOwner {
    revert("Ownable: renounceOwnership function is disabled");
  }
}

interface IERC20Helper {
  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract VucaOwnable is Ownable {
  address public candidateOwner;
  event NewCandidateOwner(address indexed candidate);

  function transferOwnership(address _candidateOwner) public override onlyOwner {
    require(_candidateOwner != address(0), "Ownable: candidate owner is the zero address");
    candidateOwner = _candidateOwner;
    emit NewCandidateOwner(_candidateOwner);
  }

  function claimOwnership() external {
    require(candidateOwner == _msgSender(), "Ownable: caller is not the candidate owner");
    _transferOwnership(candidateOwner);
    candidateOwner = address(0);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}