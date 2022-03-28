// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ITiny721.sol";
import "../../libraries/EIP712.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error InvalidMusicId();
error InvalidMusicCap();
error InvalidCreditId();
error CannotMintExpiredSignature();
error CannotMintInvalidSignature();
error CannotExceedMusicCap();
error SweepingTransferFailed();

/**
  @title A contract which accepts signatures from a trusted signer to mint an
    ERC-721 item in exchange for payment in some ERC-20 token.
  @author Tim Clancy
  @author Rostislav Khlebnikov

  This token contract allows for the implementation of off-chain systems that
  mint items to callers using entirely off-chain data.

  March 26th, 2022.
*/
contract ClaimableMint is
  EIP712, Ownable, ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /**
    A constant hash of the mint operation's signature.

    @dev _minter The address of the minter for the signed-for item. This must
      be the address of the caller.
    @dev _expiry The expiry time after which this signature cannot execute.
    @dev _cost The cost in `token` of this mint.
    @dev _musicId The ID of a particular piece of music being minted.
    @dev _cap The cap on the maximum number of instances of `_musicId` items
      that may be minted.
    @dev _creditId An ID for some simple off-chain verification that this
      minting event succeeded.
  */
  bytes32 constant public MINT_TYPEHASH = keccak256(
    "mint(address _minter,uint256 _expiry,uint256 _cost,uint256 _musicId,uint256 _cap,uint256 _creditId)"
  );

  /// The name of this minter.
  string public name;

  /// The address permitted to sign claim signatures.
  address public immutable signer;

  /// The address of the ERC-20 token to accept minting payment in.
  address public immutable token;

  /// The address of the Tiny721 item to mint new items into.
  address public immutable item;

  /// The address where all `token` payments are sent to.
  address public immutable paymentDestination;

  /**
    This mapping tracks the cap on the number of individual instances of a song
    for each song ID `_musicId`. It is set by the first mint of a particular
    song and is used thereafter to verify that the cap is not being exceeded
    during minting.
  */
  mapping ( uint256 => uint256 ) public caps;

  /**
    This mapping tracks the next instance ID of a song that should be minted for
    each song ID `_musicId`. Its logic is overridden specifically on the first
    mint such that the song instances begin with an ID of 1.
  */
  mapping ( uint256 => uint256 ) public nextInstanceId;

  /**
    This struct defines the specific instance of a particular song that is
    associated with some particular ID in `item`.

    @param musicId The ID of the particular piece of music minted.
    @param instanceId The ID of some piece within that music's cap.
  */
  struct Song {
    uint256 musicId;
    uint256 instanceId;
  }

  /**
    This mapping allows the `item` contract to be the sole controller of the
    token ID space while still allowing us to correlate sequentially-minted
    items with an ID for off-chain data look-up. That is, whenever an item is
    minted, it will be given the next ID in the item's sequence such that the
    on-chain ID space is not gappy. However, we might want to correlate that
    item to off-chain data that has already been pre-generated with a different
    ID. The most obvious use-case for this is the ascension of off-chain items.
  */
  mapping ( uint256 => Song ) public song;

  /**
    This struct defines the snapshot of progress through a song's mint obtained
    when a particular `_creditId` was fulfilled.

    @param musicId The ID of a particular piece of music.
    @param cap The cap on the number of mints possible for a particular song.
    @param mintCount The number of items minted against the song's cap.
  */
  struct MintProgress {
    uint256 musicId;
    uint256 cap;
    uint256 mintCount;
  }

  /**
    This mapping tracks whether or not a particular mint event has happened. It
    correlates a particular `_creditId` to the new state of progression through
    its particular song's minting cap. Off-chain systems can use this to
    reliably detect whether or not someoff-chain event should be fired for the
    specific mint. This works because each individual mint event is uniquely
    determined by the input `_creditId` parameter. The provided `_musicId` and
    `_cap` parameters merely determine specific instances within a given minting
    cap.
  */
  mapping ( uint256 => MintProgress ) public fulfilledCreditId;

  /**
    An event emitted when a caller mints a new item.

    @param timestamp The timestamp of the mint.
    @param caller The caller who claimed the tokens.
    @param id The ID of the specific item within the ERC-721 `item` contract.
    @param musicId The ID of the particular piece of music minted.
    @param instanceId The ID of some piece within that music's cap.
    @param creditId The ID for any off-chain resource mapped to the item as a
      part of this mint.
  */
  event Minted (
    uint256 timestamp,
    address indexed caller,
    uint256 id,
    uint256 musicId,
    uint256 instanceId,
    uint256 creditId
  );

  /**
    Construct a new minter by providing it a permissioned claim signer which may
    issue claims and claim amounts, the payment token, and the item to mint in.

    @param _name The name of the vault used in EIP-712 domain separation.
    @param _signer The address permitted to sign claim signatures.
    @param _token The address of the ERC-20 token used to pay for mints.
    @param _item The address of the Tiny721 contract that items are minted into.
    @param _paymentDestination The destination address that all `_token` minting
      payments are sent to.
  */
  constructor (
    string memory _name,
    address _signer,
    address _token,
    address _item,
    address _paymentDestination
  ) EIP712(_name, "1") {
    name = _name;
    signer = _signer;
    token = _token;
    item = _item;
    paymentDestination = _paymentDestination;
  }

  /**
    A private helper function to validate a signature supplied for item mints.
    This function constructs a digest and verifies that the signature signer was
    the authorized address we expect.

    @param _minter The address of the minter for the signed-for item. This must
      be the address of the caller.
    @param _expiry The expiry time after which this signature cannot execute.
    @param _cost The cost in `token` of this mint.
    @param _musicId The ID of a particular piece of music being minted.
    @param _cap The cap on the maximum number of instances of `_musicId` items
      that may be minted.
    @param _creditId An ID for some simple off-chain verification that this
      minting event succeeded.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function validMint (
    address _minter,
    uint256 _expiry,
    uint256 _cost,
    uint256 _musicId,
    uint256 _cap,
    uint256 _creditId,
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
            MINT_TYPEHASH,
            _minter,
            _expiry,
            _cost,
            _musicId,
            _cap,
            _creditId
          )
        )
      )
    );

    // The claim is validated if it was signed by our authorized signer.
    return ecrecover(digest, _v, _r, _s) == signer;
  }

  /**
    Allow a caller to mint a new item if
      1. the mint is backed by a valid signature from the trusted `signer`.
      2. the caller has enough `token` to pay the minting cost.
      3. the signature is not expired.
      4. the song instance being minted is not sold out.

    @param _expiry The expiry time after which this signature cannot execute.
    @param _cost The cost in `token` of this mint.
    @param _musicId The ID of a particular piece of music being minted.
    @param _cap The cap on the maximum number of instances of `_musicId` items
      that may be minted.
    @param _creditId An ID for some simple off-chain verification that this
      minting event succeeded.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function mint (
    uint256 _expiry,
    uint256 _cost,
    uint256 _musicId,
    uint256 _cap,
    uint256 _creditId,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external nonReentrant {

    // Perform basic input validation on `_musicId`.
    if (_musicId < 1) { revert InvalidMusicId(); }

    // Perform basic input validation on `_cap`.
    if (_cap < 1) { revert InvalidMusicCap(); }

    // Perform basic input validation on `_creditId`.
    if (_creditId < 1) { revert InvalidCreditId(); }

    // Validate the expiration time.
    if (_expiry < block.timestamp) { revert CannotMintExpiredSignature(); }

    // Validiate that the claim was provided by our trusted `signer`.
    bool validSignature = validMint(
      _msgSender(),
      _expiry,
      _cost,
      _musicId,
      _cap,
      _creditId,
      _v,
      _r,
      _s
    );
    if (!validSignature) {
      revert CannotMintInvalidSignature();
    }

    // Charge the caller the mint price.
    IERC20(token).safeTransferFrom(
      _msgSender(),
      paymentDestination,
      _cost
    );

    // Set the song cap if it is uninitialized or being lowered.
    if (caps[_musicId] < 1 || _cap < caps[_musicId]) {
      caps[_musicId] = _cap;
    }

    // Reject mints that are attempting to exceed the mint cap.
    if (_cap > caps[_musicId]) { revert CannotExceedMusicCap(); }

    // Validate that the mint will not exceed any prior cap on this song ID.
    uint256 nextId = nextInstanceId[_musicId];
    if (nextId < 1) {
      nextId = 1;
    }
    if (nextId > _cap) { revert CannotExceedMusicCap(); }

    // Mint the new item.
    ITiny721 itemContract = ITiny721(item);
    itemContract.mint_Qgo(_msgSender(), 1);

    // Store details correlating the item minted to its song.
    uint256 newItemId = itemContract.totalSupply();
    song[newItemId] = Song({
      musicId: _musicId,
      instanceId: nextId
    });

    // Increment the next instance ID for this minted piece of music.
    nextInstanceId[_musicId] = nextId + 1;

    // Mark this credit ID as fulfilled.
    fulfilledCreditId[_creditId] = MintProgress({
      musicId: _musicId,
      cap: _cap,
      mintCount: nextId
    });

    // Emit an event.
    emit Minted(
      block.timestamp,
      _msgSender(),
      newItemId,
      _musicId,
      nextId,
      _creditId
    );
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    Return the total number of this token that have ever been minted.

    @return The total supply of minted tokens.
  */
  function totalSupply () external returns (uint256);

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

pragma solidity ^0.8.11;

abstract contract EIP712 {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

    bytes32 immutable public DOMAIN_SEPARATOR;

    constructor(string memory name, string memory version){
        uint chainId_;
        assembly{
            chainId_ := chainid()
        }
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name              : name,
            version           : version,
            chainId           : chainId_,
            verifyingContract : address(this)
        }));
    }

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function parseSignature(bytes memory signature)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return(v,r,s);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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