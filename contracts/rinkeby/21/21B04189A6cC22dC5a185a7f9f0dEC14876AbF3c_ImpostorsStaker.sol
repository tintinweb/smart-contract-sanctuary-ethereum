// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITiny721.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotAddPoolWithInvalidId();
error CannotStakeAfterDeadline();
error CannotStakeInactivePool();
error CannotStakeUnownedItem();
error CannotStakeTimeLockedItem();
error CannotWithdrawUnownedItem();
error CannotWithdrawTimeLockedItem();
error CannotWithdrawUnstakedItem();
error SweepingTransferFailed();
error EmptyTokenIdsArray();

/**
  @title A simple staking contract for transfer-locking `Tiny721` items in
    exchange for tokens.
  @author Tim Clancy
  @author Rostislav Khlebnikov
  @author 0xthrpw

  This staking contract disburses tokens from its internal reservoir to those
  who stake `Tiny721` items, at a fixed rate of token per item independent of
  the number of items staked. It supports defining multiple time-locked pools
  with different rates.

  March 7th, 2022.
*/
contract ImpostorsStaker is
  Ownable, ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /// The name of this Staker.
  string public name;

  /// The token to disburse.
  address public immutable token;

  /**
    This struct is used to define information regarding a particular pool that
    the user may choose to stake their items against.

    @param item The address of the item contract that is allowed to be staked in
      this pool.
    @param lockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is locked during the `lockDuration`.
    @param unlockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is unlocked and available for
      withdrawal.
    @param lockDuration The amount of time in seconds wherein this pool requires
      that the asset remain time-locked and unavailable to withdraw. Once the
      item has been staked for `lockDuration` seconds, the item may be
      withdrawn from the pool and the number of tokens earned changes to the
      `unlockedTokensPerSecond` rate.
    @param deadline Determines the time after which no more stakes are accepted
  */
  struct Pool {
    address item;
    uint256 lockedTokensPerSecond;
    uint256 unlockedTokensPerSecond;
    uint256 lockDuration;
    uint256 deadline;
  }

  /// A mapping with to look up information for each specific pool.
  mapping ( uint256 => Pool ) public pools;

  /**
    This struct is used to define information surrounding the status of a
    particular item in this staking contract.

    @param stakedPool The ID of the pool where this item is currently staked. An
      ID of zero indicates that the item is not staked to any pool.
    @param stakedAt The time when this item was last staked in the pool. This is
      used to control earning rates due to time-locking in a pool.
    @param tokenClaimed The number of tokens claimed by this item so far. This
      is used to support partial claiming of earned tokens during a pool's full
      `_lockDuration`.
  */
  struct ItemStatus {
    uint256 stakedPool;
    uint256 stakedAt;
    uint256 tokenClaimed;
  }

  /**
    A double mapping relating a `Tiny721` item address and the ID of a specific
    token to details about its status in the pool where it is currently staked.
  */
  mapping ( address => mapping ( uint256 => ItemStatus )) public itemStatuses;

  /**
    This struct is used to define information regarding a particular caller's
    position in a particular pool.

    @param stakedItems An array of all token IDs staked by a caller in this
      particular position.
    @param tokenPaid The value of the caller's total earning that has been paid
      out in this position.
  */
  struct Position {
    uint256[] stakedItems;
    uint256 tokenPaid;
  }

  /**
    A double mapping relating a particular pool ID to and the address of a
    caller to information about the caller's `Position` in that pool.
  */
  mapping ( uint256 => mapping ( address => Position )) public positions;

  /// The total amount of the disbursed `token` ever emitted by this Staker.
  uint256 public totalTokenDisbursed;

  /**
    An event tracking a claim of tokens for some pools from this staker.

    @param timestamp The block timestamp when this event was emitted.
    @param caller The caller who triggered the claim.
    @param poolIds The array of pool IDs where tokens were claimed from.
    @param amount The amount of `token` claimed by the `caller` in this event.
  */
  event Claim (
    uint256 timestamp,
    address indexed caller,
    uint256[] poolIds,
    uint256 amount
  );

  /**
    An event tracking a staking of the specified `tokenIds` into a specific pool
    of this staker.

    @param timestamp The block timestamp when this event was emitted.
    @param caller The caller who triggered the claim.
    @param poolId The ID of the pool that tokens were staked into.
    @param item The address of the item smart contract with the token IDs
      specified in `tokenIds`.
    @param tokenIds The IDs of the tokens staked into this pool.
  */
  event Stake (
    uint256 timestamp,
    address indexed caller,
    uint256 poolId,
    address indexed item,
    uint256[] tokenIds
  );

  /**
    An event tracking a withdrawal of the specified `tokenIds` from a specific
    pool of this staker.

    @param timestamp The block timestamp when this event was emitted.
    @param caller The caller who triggered the claim.
    @param poolId The ID of the pool that tokens were withdrawn from.
    @param item The address of the item smart contract with the token IDs
      specified in `tokenIds`.
    @param tokenIds The IDs of the tokens withdrawn from this pool.
  */
  event Withdraw (
    uint256 timestamp,
    address indexed caller,
    uint256 poolId,
    address indexed item,
    uint256[] tokenIds
  );

  /**
    Construct a new Staker by providing it a name and the token to disburse.

    @param _name The name of the Staker contract.
    @param _token The token to reward stakers in this contract with.
  */
  constructor (
    string memory _name,
    address _token
  ) {
    name = _name;
    token = _token;
  }

  function getPosition(uint256 _id, address _addr) public view returns (uint256[] memory, uint256){
    Position memory p = positions[_id][_addr];
    return (p.stakedItems, p.tokenPaid);
  }

  function getItemsPosition(uint256 _id, address _addr) public view returns (uint256[] memory){
    Position memory p = positions[_id][_addr];
    return p.stakedItems;
  }

  /**
    Allow the contract owner to add a new staking `Pool` to the Staker or
    overwrite the configuration of an existing one.

    @param _id The ID of the `Pool` to add or update.
    @param _item The address of the item contract that is staked in this pool.
    @param _lockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is locked during the `lockDuration`.
    @param _unlockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is unlocked and available for
      withdrawal.
    @param _lockDuration The amount of time in seconds where this pool requires
      that the asset remain time-locked and unavailable to withdraw. Once the
      item has been staked for `lockDuration` seconds, the item may be
      withdrawn from the pool and the number of tokens earned changes to the
      `unlockedTokensPerSecond` rate.
    @param _deadline The timestamp stakes must be created by, any stakes to
      pool that are attempted after this timestamp will revert.
  */
  function setPool (
    uint256 _id,
    address _item,
    uint256 _lockedTokensPerSecond,
    uint256 _unlockedTokensPerSecond,
    uint256 _lockDuration,
    uint256 _deadline
  ) external onlyOwner {

    // There may be no pool with ID of 0.
    if (_id < 1) {
      revert CannotAddPoolWithInvalidId();
    }

    // Update the `Pool` being tracked in the `pools` mapping.
    pools[_id].item = _item;
    pools[_id].lockedTokensPerSecond = _lockedTokensPerSecond;
    pools[_id].unlockedTokensPerSecond = _unlockedTokensPerSecond;
    pools[_id].lockDuration = _lockDuration;
    pools[_id].deadline = _deadline;
  }

  /**
    Claim all of the caller's pending tokens from the specified pools.

    @param _poolIds The IDs of the pools to claim pending token rewards from.
  */
  function claim (
    uint256[] memory _poolIds
  ) public nonReentrant {
    uint256 totalClaimAmount;
    for (uint256 poolIndex; poolIndex < _poolIds.length; ++poolIndex) {
      uint256 poolId = _poolIds[poolIndex];
      Pool storage pool = pools[poolId];
      Position storage position = positions[poolId][_msgSender()];

      /*
        Iterate through each item that the caller has staked into this pool. If
        the caller has staked assets, transfer any accrued balance to them.
      */
      for (uint256 i; i < position.stakedItems.length; ++i) {
        uint256 stakedItemId = position.stakedItems[i];

        /*
          Retrieve the status of each staked item and calculate the total amount
          that has been earned by each staked item in this pool.
        */
        ItemStatus storage status = itemStatuses[pool.item][stakedItemId];
        uint256 lockEnds = status.stakedAt + pool.lockDuration;
        uint256 totalEarnings;

        // We are within the unlocked period for this item.
        if (block.timestamp > lockEnds) {
          totalEarnings = pool.lockDuration * pool.lockedTokensPerSecond;
          totalEarnings += (block.timestamp - lockEnds) * pool.unlockedTokensPerSecond;

        // We are within the time-locked period for this item.
        } else {
          totalEarnings = (block.timestamp - status.stakedAt) * pool.lockedTokensPerSecond;
        }

        // Subtract any previously-claimed amount from the total amount earned.
        uint256 tokenClaimed = status.tokenClaimed;
        uint256 unclaimedReward = totalEarnings - tokenClaimed;

        // Update the number of tokens claimed by this item in its present pool.
        status.tokenClaimed = totalEarnings;

        // Update the amount historically claimed by the caller in this pool.
        position.tokenPaid = position.tokenPaid + unclaimedReward;

        // Transfer the unclaimed reward to the user.
        totalClaimAmount = totalClaimAmount + unclaimedReward;
      }
    }

    // Update the total amount of token disbursed by this contract.
    totalTokenDisbursed = totalTokenDisbursed + totalClaimAmount;
    IERC20(token).safeTransfer(
      _msgSender(),
      totalClaimAmount
    );

    // Emit an event.
    emit Claim(block.timestamp, _msgSender(), _poolIds, totalClaimAmount);
  }

  /**
    View to retrieve current pending rewards for a user

    @param _poolIds the pools we are inquiring about
    @param _user the address of the account being queried
  */
  function pendingClaims (
    uint256[] memory _poolIds,
    address _user
  ) external view returns (uint256 totalClaimAmount) {
    for (uint256 poolIndex; poolIndex < _poolIds.length; ++poolIndex) {
      uint256 poolId = _poolIds[poolIndex];
      Pool storage pool = pools[poolId];
      Position storage position = positions[poolId][_user];

      /*
        Iterate through each item that the caller has staked into this pool.
      */
      for (uint256 i = 0; i < position.stakedItems.length; ++i) {
        uint256 stakedItemId = position.stakedItems[i];

        /*
          Retrieve the status of each staked item and calculate the total amount
          that has been earned by each staked item in this pool.
        */
        ItemStatus storage status = itemStatuses[pool.item][stakedItemId];
        uint256 lockEnds = status.stakedAt + pool.lockDuration;
        bool itemUnlocked = block.timestamp > lockEnds;
        uint256 totalEarnings;

        // We are within the unlocked period for this item.
        if (itemUnlocked) {
          totalEarnings = pool.lockDuration * pool.lockedTokensPerSecond;
          uint256 flexibleDuration = block.timestamp - lockEnds;
          totalEarnings += flexibleDuration * pool.unlockedTokensPerSecond;

        // We are within the time-locked period for this item.
        } else {
          uint256 stakeDuration = block.timestamp - status.stakedAt;
          totalEarnings = stakeDuration * pool.lockedTokensPerSecond;
        }

        // Subtract any previously-claimed amount from the total amount earned.
        totalClaimAmount = totalClaimAmount + totalEarnings - status.tokenClaimed;
      }
    }
    return totalClaimAmount;
  }

  /**
    This private helper function converts a number into a single-element array.

    @param _element The element to convert to an array.

    @return The array containing the single `_element`.
  */
  function _asSingletonArray (
    uint256 _element
  ) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = _element;
    return array;
  }

  /**
    Lock some particular token IDs from some particular contract addresses into
    some particular `Pool` of this Staker.

    @param _poolId The ID of the `Pool` to stake items in.
    @param _tokenIds An array of token IDs corresponding to specific tokens in
      the item contract from `Pool` with the ID of `_poolId`.
  */
  function stake (
    uint256 _poolId,
    uint256[] calldata _tokenIds
  ) external  {
    if (_tokenIds.length == 0) {
      revert EmptyTokenIdsArray();
    }

    Pool storage pool = pools[_poolId];

    // Reject stakes for inactive pools.
    if (pool.lockedTokensPerSecond < 1) {
      revert CannotStakeInactivePool();
    }

    // Enforce a deadline on pool entry.
    if (block.timestamp > pool.deadline) {
      revert CannotStakeAfterDeadline();
    }

    // Claim pending tokens.
    claim(_asSingletonArray(_poolId));

    // Stake the caller's items by locking transfer of that item.
    ITiny721 item = ITiny721(pool.item);
    for (uint256 i; i < _tokenIds.length; ++i) {
      uint256 tokenId = _tokenIds[i];

      // Verify that the caller owns the token being locked.
      if (item.ownerOf(tokenId) != _msgSender()) {
        revert CannotStakeUnownedItem();
      }

      /*
        Retrieve the status of each item to see if it is new to the pool, new to
        the staker, or unlocked. In short, we verify that the item is able to be
        staked into this pool.
      */
      ItemStatus storage status = itemStatuses[pool.item][tokenId];
      uint256 lockEnds = status.stakedAt + pool.lockDuration;
      bool itemUnlocked = block.timestamp > lockEnds;

      /*
        Reject requests trying to stake an item that has not completed its lock
        duration. This prevents callers from double-dipping by staking the
        same item to multiple pools.
      */
      if (!itemUnlocked) {
        revert CannotStakeTimeLockedItem();
      }

      /*
        We allow the caller to re-lock their item into a pool without having to
        withdraw it first if it has completed its time lock. To accomodate this,
        we must reset storage regarding the status of the item being staked.
      */
      status.stakedPool = _poolId;
      status.stakedAt = block.timestamp;
      status.tokenClaimed = 0;

      /*
        Update the caller's staked items to add each new item ID to the caller's
        array of staked token IDs if it is not already present as a staked item.
      */
      Position storage position = positions[_poolId][_msgSender()];

      // Check each token ID to see if it is already present as a staked ID.
      bool alreadyStaked = false;
      for (
        uint256 stakedIndex;
        stakedIndex < position.stakedItems.length;
        ++stakedIndex
      ) {
        uint256 stakedId = position.stakedItems[stakedIndex];
        if (tokenId == stakedId) {
          alreadyStaked = true;
          break;
        }
      }

      // If this is truly a newly-staked item, add it to the array.
      if (!alreadyStaked) {
        position.stakedItems.push(tokenId);
      }

      /*
        If the item beingstaked is not already transfer-locked, then lock
        any transfers of the item that has been staked.
      */
      if (!item.transferLocks(tokenId)) {
        item.lockTransfer(tokenId, true);
      }
    }

    // Emit an event.
    emit Stake(block.timestamp, _msgSender(), _poolId, pool.item, _tokenIds);
  }

  /**
    Unlock some particular token IDs from some particular contract addresses
    from some particular `Pool` of this Staker.

    @param _poolId The ID of the `Pool` to unstake items from.
    @param _tokenIds An array of token IDs corresponding to specific tokens in
      the item contract from `Pool` with the ID of `_poolId` that are to be
      unstaked.
  */
  function withdraw (
    uint256 _poolId,
    uint256[] calldata _tokenIds
  ) external {
    Pool storage pool = pools[_poolId];
    Position storage position = positions[_poolId][_msgSender()];

    // Claim pending tokens.
    claim(_asSingletonArray(_poolId));

    // Withdraw the caller's items by unlocking transfer of that item.
    ITiny721 item = ITiny721(pool.item);
    for (uint256 i = 0; i < _tokenIds.length; ++i ) {
      uint256 tokenId = _tokenIds[i];

      // Verify that the caller owns the token being unlocked.
      if (item.ownerOf(tokenId) != _msgSender()) {
        revert CannotWithdrawUnownedItem();
      }

      // Verify that any time lock on withdrawing the item has completed.
      ItemStatus storage status = itemStatuses[pool.item][tokenId];
      uint256 lockEnds = status.stakedAt + pool.lockDuration;
      bool itemUnlocked = block.timestamp > lockEnds;
      if (!itemUnlocked) {
        revert CannotWithdrawTimeLockedItem();
      }

      /*
        Verify that the item was actually staked in this pool. This check
        prevents withdrawing an item from a different pool by using the
        time-lock of this pool.
      */
      if (_poolId != status.stakedPool) {
        revert CannotWithdrawUnstakedItem();
      }

      // Clear storage mapping now that the item is unlocked.
      status.stakedPool = 0;
      status.stakedAt = 0;
      status.tokenClaimed = 0;

      // Check each token ID to find its index.
      for (
        uint256 stakedIndex;
        stakedIndex < position.stakedItems.length;
        ++stakedIndex
      ) {
        uint256 stakedId = position.stakedItems[stakedIndex];
        if (tokenId == stakedId) {

          // Remove the element at the matching index.
          for (
            uint256 r = stakedIndex;
            r < position.stakedItems.length - 1;
            ++r
          ) {
            position.stakedItems[r] = position.stakedItems[r + 1];
          }
          position.stakedItems.pop();
          break;
        }
      }

      // Unlock transfers of the item.
      item.lockTransfer(tokenId, false);
    }

    // Emit an event.
    emit Withdraw(block.timestamp, _msgSender(), _poolId, pool.item, _tokenIds);
  }

  /**
    Allow the owner to sweep either Ether or a particular ERC-20 token from the
    contract and send it to another address. This allows the owner of the shop
    to withdraw their funds after the sale is completed.

    @param _token The token to sweep the balance from; if a zero address is sent
      then the contract's balance of Ether will be swept.
    @param _amount The amount of token to sweep.
    @param _destination The address to send the swept tokens to.
  */
  function sweep (
    address _token,
    address _destination,
    uint256 _amount
  ) external onlyOwner {

    // A zero address means we should attempt to sweep Ether.
    if (_token == address(0)) {
      (bool success, ) = payable(_destination).call{ value: _amount }("");
      if (!success) { revert SweepingTransferFailed(); }

    // Otherwise, we should try to sweep an ERC-20 token.
    } else {
      IERC20(_token).safeTransfer(_destination, _amount);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

/**
  @title A minimalistic, gas-efficient ERC-721 implementation forked from the
    `Super721` ERC-721 implementation used by SuperFarm.
  @author Tim Clancy
  @author 0xthrpw
  @author Qazawat Zirak
  @author Rostislav Khlebnikov

  Compared to the original `Super721` implementation that this contract forked
  from, this is a very pared-down contract that includes simple delegated
  minting and transfer locks.

  This contract includes the gas efficiency techniques graciously shared with
  the world in the specific ERC-721 implementation by Chiru Labs that is being
  called "ERC-721A" (https://github.com/chiru-labs/ERC721A). We have validated
  this contract against their test cases.

  February 8th, 2022.
*/
interface ITiny721 {

  /**
    Return whether or not the transfer of a particular token ID `_id` is locked.

    @param _id The ID of the token to check the lock status of.

    @return Whether or not the particular token ID `_id` has transfers locked.
  */
  function transferLocks (
    uint256 _id
  ) external returns (bool);

  /**
    Provided with an address parameter, this function returns the number of all
    tokens in this collection that are owned by the specified address.

    @param _owner The address of the account for which we are checking balances
  */
  function balanceOf (
    address _owner
  ) external returns ( uint256 );

  /**
    Return the address that holds a particular token ID.

    @param _id The token ID to check for the holding address of.

    @return The address that holds the token with ID of `_id`.
  */
  function ownerOf (
    uint256 _id
  ) external returns (address);

  /**
    This function allows permissioned minters of this contract to mint one or
    more tokens dictated by the `_amount` parameter. Any minted tokens are sent
    to the `_recipient` address.

    Note that tokens are always minted sequentially starting at one. That is,
    the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
    Also note that per our use cases the intended recipient of these minted
    items will always be externally-owned accounts and not other contracts. As a
    result there is no safety check on whether or not the mint destination can
    actually correctly handle an ERC-721 token.

    @param _recipient The recipient of the tokens being minted.
    @param _amount The amount of tokens to mint.
  */
  function mint_Qgo (
    address _recipient,
    uint256 _amount
  ) external;

  /**
    This function allows an administrative caller to lock the transfer of
    particular token IDs. This is designed for a non-escrow staking contract
    that comes later to lock a user's NFT while still letting them keep it in
    their wallet.

    @param _id The ID of the token to lock.
    @param _locked The status of the lock; true to lock, false to unlock.
  */
  function lockTransfer (
    uint256 _id,
    bool _locked
  ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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