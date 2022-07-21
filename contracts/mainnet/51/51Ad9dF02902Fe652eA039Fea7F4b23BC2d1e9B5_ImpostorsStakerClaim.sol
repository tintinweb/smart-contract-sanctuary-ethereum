// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITiny721.sol";
import "../interfaces/staker/IFixedStaker.sol";
import "../libraries/EIP712.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotClaimInvalidSignature();
error CannotClaimAlreadyClaimed();
error SweepingTransferFailed();

/**
  @title The Impostors genesis season is over. Callers may claim pending BLOOD.
  @author Tim Clancy
  @author Rostislav Khlebnikov
  @author Liam Clancy
  @author 0xthrpw

  July 19th, 2022.
*/
contract ImpostorsStakerClaim is
  EIP712, Ownable, ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /// A constant hash of the claim operation's signature.
  bytes32 constant public CLAIM_TYPEHASH = keccak256(
    "claim(address _claimant,address _asset,uint256 _amount)"
  );

  /// The name of the vault.
  string public name;

  /// The address permitted to sign claim signatures.
  address public immutable signer;

  /// The address of the Impostors staker.
  address public immutable staker;

  /// The address of the Impostors items to unlock transfers for.
  address public immutable impostors;

  /// A mapping for whether or not a specific claimant has claimed.
  mapping ( address => bool ) public claimed;

  /**
    An event emitted when a claimant claims tokens.

    @param claimant The caller who claimed the tokens.
    @param asset The ERC-20 tokens being claimed.
    @param amount The amount of tokens claimed.
  */
  event Claimed (
    address indexed claimant,
    address indexed asset,
    uint256 amount
  );

  /**
    Construct a new vault by providing it a permissioned claim signer which may
    issue claims and claim amounts.

    @param _name The name of the vault used in EIP-712 domain separation.
    @param _signer The address permitted to sign claim signatures.
    @param _staker The address of the Impostors staker.
    @param _impostors The address of the Impostors items to unlock transfers on.
  */
  constructor (
    string memory _name,
    address _signer,
    address _staker,
    address _impostors
  ) EIP712(_name, "1") {
    name = _name;
    signer = _signer;
    staker = _staker;
    impostors = _impostors;
  }

  /**
    A private helper function to validate a signature supplied for token claims.
    This function constructs a digest and verifies that the signature signer was
    the authorized address we expect.

    @param _claimant The claimant attempting to claim tokens.
    @param _asset The address of the ERC-20 token being claimed.
    @param _amount The amount of tokens the claimant is trying to claim.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function validClaim (
    address _claimant,
    address _asset,
    uint256 _amount,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) private view returns (bool) {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            CLAIM_TYPEHASH,
            _claimant,
            _asset,
            _amount
          )
        )
      )
    );

    // The claim is validated if it was signed by our authorized signer.
    return ecrecover(digest, _v, _r, _s) == signer;
  }

  /**
    Allow a caller to claim any of their available tokens if
      1. the claim is backed by a valid signature from the trusted `signer`.
      2. the vault has enough tokens to fulfill the claim.
      3. the user's items are unlocked.

    @param _asset The address of the ERC-20 token being claimed.
    @param _amount The amount of tokens that the caller is trying to claim.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function claim (
    address _asset,
    uint256 _amount,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external nonReentrant {

    // Validate that the caller has not already claimed.
    if (claimed[_msgSender()]) {
      revert CannotClaimAlreadyClaimed();
    }

    // Validiate that the claim was provided by our trusted `signer`.
    bool validSignature = validClaim(
      _msgSender(),
      _asset,
      _amount,
      _v,
      _r,
      _s
    );
    if (!validSignature) {
      revert CannotClaimInvalidSignature();
    }

    // Mark the claim as fulfilled.
    claimed[_msgSender()] = true;

    /*
      Iterate through all pools in the staker to retrieve the caller's staked
      items.
    */
    for (uint256 poolId = 1; poolId < 5;) {
      (uint256[] memory flexStakedItems, ) = IFixedStaker(staker).getPosition(
        poolId,
        _msgSender()
      );

      // Unlock each item.
      for (uint256 i = 0; i < flexStakedItems.length;) {
        uint256 impostorId = flexStakedItems[i];
        ITiny721(impostors).lockTransfer(impostorId, false);

        // Increment.
        unchecked {
          ++i;
        }
      }

      // Increment.
      unchecked {
        ++poolId;
      }
    }

    // Transfer tokens to the claimant.
    IERC20(_asset).safeTransfer(
      _msgSender(),
      _amount
    );

    // Emit an event.
    emit Claimed(_msgSender(), _asset, _amount);
  }

  /**
    Allow the owner to sweep either Ether or a particular ERC-20 token from the
    contract and send it to another address. This allows the owner of the shop
    to withdraw their funds after the sale is completed.

    @param _token The token to sweep the balance from; if a zero address is sent
      then the contract's balance of Ether will be swept.
    @param _destination The address to send the swept tokens to.
    @param _amount The amount of token to sweep.
  */
  function sweep (
    address _token,
    address _destination,
    uint256 _amount
  ) external onlyOwner nonReentrant {

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

// SPDX-License-Identifier: AGPL-3.0-only
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
    Return the total number of this token that have ever been minted.

    @return The total supply of minted tokens.
  */
  function totalSupply () external view returns (uint256);

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
  ) external returns (uint256);

  /**
    Return the address that holds a particular token ID.

    @param _id The token ID to check for the holding address of.

    @return The address that holds the token with ID of `_id`.
  */
  function ownerOf (
    uint256 _id
  ) external returns (address);

  /**
    This function performs an unsafe transfer of token ID `_id` from address
    `_from` to address `_to`. The transfer is considered unsafe because it does
    not validate that the receiver can actually take proper receipt of an
    ERC-721 token.

    @param _from The address to transfer the token from.
    @param _to The address to transfer the token to.
    @param _id The ID of the token being transferred.
  */
  function transferFrom (
    address _from,
    address _to,
    uint256 _id
  ) external;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

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

  April 28th, 2022.
*/
interface IFixedStaker {

  /**
    Retrieve details about a particular staker `_staker`'s `Position` in a
    particular pool `_id`.

    @param _id The ID of the pool to retrieve a position for.
    @param _staker The address of the staker to retrieve a position for.

    @return A deconstructed `Position` as a tuple of the array of staked item
      IDs and the amount of token paid out in total for that user's position.
  */
  function getPosition (
    uint256 _id,
    address _staker
  ) external view returns (uint256[] memory, uint256);

  /**
    View to retrieve current pending rewards for a user

    @param _poolIds the pools we are inquiring about
    @param _user the address of the account being queried
  */
  function pendingClaims (
    uint256[] memory _poolIds,
    address _user
  ) external view returns (uint256 totalClaimAmount);

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
  ) external;

  /**
    Claim all of the caller's pending tokens from the specified pools.

    @param _poolIds The IDs of the pools to claim pending token rewards from.
  */
  function claim (
    uint256[] memory _poolIds
  ) external;

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
  ) external;

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
  ) external;

  /**
    Allow the owner to forcibly unlock some particular token IDs from some
    particular contract addresses from some particular `Pool` of this Staker.
    The eviction mechanic allows the owner to intervene in cases where item
    locks induce issues in the broader third-party ecosystem, namely in regards
    to unfulfillable marketplace listings. An address whose items are being
    forcibly evicted may optionally be banned from staking and may optionally
    have its rewards not delivered.

    @param _evictee The address being evicted from the specified pool.
    @param _poolId The ID of the `Pool` to evict items from.
    @param _tokenIds An array of token IDs corresponding to specific tokens in
      the item contract from `Pool` with the ID of `_poolId` that are to be
      evicted.
    @param _ban Whether or not the `_evictee` should be banned from future
      staking.
    @param _skipClaim Whether or not the `_evictee`'s pending claims should be
      skipped.
  */
  function evict (
    address _evictee,
    uint256 _poolId,
    uint256[] calldata _tokenIds,
    bool _ban,
    bool _skipClaim
  ) external;

  /**
    Set whether or not an address is banned from staking.

    @param _caller The caller to ban or unban.
    @param _banned Whether or not `_caller` is banned.
  */
  function setBan (
    address _caller,
    bool _banned
  ) external;

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
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

abstract contract EIP712 {
  bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256 (
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  );

  struct EIP712Domain {
    string  name;
    string  version;
    uint256 chainId;
    address verifyingContract;
  }

  bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

  bytes32 immutable public DOMAIN_SEPARATOR;

  constructor (
    string memory _name,
    string memory _version
  ) {
    uint chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = hash(EIP712Domain({
      name: _name,
      version: _version,
      chainId: chainId,
      verifyingContract: address(this)
    }));
  }

  function hash (
    EIP712Domain memory eip712Domain
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(
      EIP712DOMAIN_TYPEHASH,
      keccak256(bytes(eip712Domain.name)),
      keccak256(bytes(eip712Domain.version)),
      eip712Domain.chainId,
      eip712Domain.verifyingContract
    ));
  }

  function parseSignature (
    bytes memory signature
  ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }
    return (v,r,s);
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