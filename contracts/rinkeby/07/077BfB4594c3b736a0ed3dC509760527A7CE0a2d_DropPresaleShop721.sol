// SPDX-License-Identifier: GPL-3.0
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
error CannotEndSaleBeforeItStarts();
error CannotEndAtHigherPrice();
error CannotTransferIncorrectAmount();
error PaymentTransferFailed();
error CannotVerifyAsWhitelistMember();
error CannotExceedWhitelistAllowance();
error CannotBuyZeroItems();
error CannotBuyFromEndedSale();
error CannotExceedPerTransactionCap();
error CannotExceedPerCallerCap();
error CannotExceedTotalCap();
error CannotUnderpayForMint();
error RefundTransferFailed();
error SweepingTransferFailed();

/**
  @title A contract for selling NFTs via a merkle-based whitelist presale with
    conversion into a public sale.
  @author Tim Clancy
  @author Qazawat Zirak
  @author Rostislav Khlebnikov
  @author Nikita Elunin
  @author 0xthrpw

  This contract is a modified version of SuperFarm mint shops optimized for the
  specific use case of:
    1. selling a single type of ERC-721 item from a single contract
    2. running potentially multiple whitelisted presales with potentially
       multiple different participants and different prices
    3. selling the item for both ETH and an ERC-20 token during the presale
    4. converting into a public sale that can sell for ETH only

  This launchpad contract sells new items by minting them into existence. It
  cannot be used to sell items that already exist.

  March 10th, 2022.
*/
contract DropPresaleShop721 is
  Ownable, ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /// The address of the ERC-721 item being sold.
  address public immutable collection;

  /// The time when the public sale begins.
  uint256 public immutable startTime;

  /// The time when the public sale ends.
  uint256 public immutable endTime;

  /// The maximum number of items from the `collection` that may be sold.
  uint256 public immutable totalCap;

  /// The maximum number of items that a single address may purchase.
  uint256 public immutable callerCap;

  /// The maximum number of items that may be purchased in a single transaction.
  uint256 public immutable transactionCap;

  /// The price at which to sell the item.
  uint256 public immutable price;

  /**
    The number of whitelists that have been added. This is used for looking up
    specific whitelist details from the `whitelists` mapping.
  */
  uint256 public immutable whitelistCount;

  /**
    This struct is used at the moment of contract construction to specify a
    presale whitelist that should apply to the sale this shop runs.

    @param root The hash root of merkle tree uses to validate a caller's
      inclusion in this whitelist.
    @param startTime The starting time of this whitelist. When this is set to a
      time earlier than the contract's `startTime` storage variable, that means
      that this whitelist will begin earlier than the public sale. In effect,
      that means that this whitelist will define a presale.
    @param endTime The ending time of this whitelist. For standard presale
      behavior, this should be set equal to the contract's `startTime` storage
      variable to end the presale when the public sale begins. This can be set
      later than the contract's `startTime` storage variable, but it will have
      no effect. A presale whitelist may not be used once the public sale has
      begun. Likewise, a presale may not run longer than the public item sale.
      The public item sale `endTime` storage variable of this contract will
      always override a whitelist's ending time.
    @param price The price that applies to this presale whitelist.
    @param token The address of the token with which purchases in this whitelist
      will be made. If this is the zero address, then this whitelist will
      conduct purchases using ETH.
  */
  struct CreateWhitelist {
    bytes32 root;
    uint256 startTime;
    uint256 endTime;
    uint256 price;
    address token;
  }

  /// A mapping to look up whitelist details for a given whitelist ID.
  mapping ( uint256 => CreateWhitelist ) public whitelists;

  /// A mapping to track the number of items purchases by each caller.
  mapping ( address => uint256 ) public purchaseCounts;

  /// The total number of items sold by the shop.
  uint256 public sold;

  /**
    This struct is used at the moment of NFT purchase to let a caller submit
    proof that they are actually entitled to a position on a presale whitelist.

    @param id The ID of the whitelist to check proof against.
    @param index The element index in the original array for proof verification.
    @param allowance The quantity available to the caller for presale purchase.
    @param proof A submitted proof that the user is on the whitelist.
  */
  struct WhitelistProof {
    uint256 id;
    uint256 index;
    uint256 allowance;
    bytes32[] proof;
  }

  /*
    A struct used to pass shop configuration details upon contract construction.

    @param startTime The time when the public sale begins.
    @param endTime The time when the public sale ends.
    @param totalCap The maximum number of items from the `collection` that may
      be sold.
    @param callerCap The maximum number of items that a single address may
      purchase.
    @param transactionCap The maximum number of items that may be purchased in
      a single transaction.
    @param price The price to sell the item at.
  */
  struct ShopConfiguration {
    uint256 startTime;
    uint256 endTime;
    uint256 totalCap;
    uint256 callerCap;
    uint256 transactionCap;
    uint256 price;
  }

  /**
    Construct a new shop with configuration details about the intended sale.

    @param _collection The address of the ERC-721 item being sold.
    @param _configuration A parameter containing shop configuration information,
      passed here as a struct to avoid a stack-to-deep error.
    @param _whitelists The array of whitelist creation data containing details
      for any presales being run.
  */
  constructor (
    address _collection,
    ShopConfiguration memory _configuration,
    CreateWhitelist[] memory _whitelists
  ) {

    // Perform basic input validation.
    if (_configuration.endTime < _configuration.startTime) {
      revert CannotEndSaleBeforeItStarts();
    }

    // Once input parameters have been validated, set storage.
    collection = _collection;
    startTime = _configuration.startTime;
    endTime = _configuration.endTime;
    totalCap = _configuration.totalCap;
    callerCap = _configuration.callerCap;
    transactionCap = _configuration.transactionCap;
    price = _configuration.price;

    // Store all of the whitelists.
    whitelistCount = _whitelists.length;
    for (uint256 i = 0; i < _whitelists.length; i++) {
      whitelists[i] = _whitelists[i];
    }
  }

  /**
    A private helper function to sell an item to a public sale participant. This
    selling function refunds any overpayment to the user; refunding overpayment
    is expected to be a common situation given the price decay in the Dutch
    auction.

    @param _amount The number of items that the caller would like to purchase.
  */
  function sellPublic (
    uint256 _amount
  ) private {
    uint256 totalCharge = price * _amount;

    // Reject the purchase if the caller is underpaying.
    if (msg.value < totalCharge) { revert CannotUnderpayForMint(); }

    // Refund the caller's excess payment if they overpaid.
    if (msg.value > totalCharge) {
      uint256 excess = msg.value - totalCharge;
      (bool returned, ) = payable(_msgSender()).call{ value: excess }("");
      if (!returned) { revert RefundTransferFailed(); }
    }
  }

  /**
    Calculate a root hash from given parameters.

    @param _index The index of the hashed node from the list.
    @param _node The index of the hashed node at that index.
    @param _merkleProof An array of one required merkle hash per level.

    @return The root hash from given parameters.
  */
  function getRootHash (
    uint256 _index,
    bytes32 _node,
    bytes32[] calldata _merkleProof
  ) private pure returns (bytes32) {
    uint256 path = _index;
    for (uint256 i = 0; i < _merkleProof.length; i++) {
      if ((path & 0x01) == 1) {
        _node = keccak256(abi.encodePacked(_merkleProof[i], _node));
      } else {
        _node = keccak256(abi.encodePacked(_node, _merkleProof[i]));
      }
      path /= 2;
    }
    return _node;
  }

  /**
    A helper function to verify an access against a targeted on-chain merkle
    root.

    @param _accesslistId The id of the accesslist containing the merkleRoot.
    @param _index The index of the hashed node from off-chain list.
    @param _node The actual hashed node which needs to be verified.
    @param _merkleProof The merkle hashes from the off-chain merkle tree.

    @return Whether the provided merkle proof is verifiably part of the on-chain
      root.
  */
  function verify (
    uint256 _accesslistId,
    uint256 _index,
    bytes32 _node,
    bytes32[] calldata _merkleProof
  ) private view returns (bool) {
    if (whitelists[_accesslistId].root == 0) {
      return false;
    } else if (block.timestamp < whitelists[_accesslistId].startTime) {
      return false;
    } else if (block.timestamp > whitelists[_accesslistId].endTime) {
      return false;
    } else if (
      getRootHash(_index, _node, _merkleProof) != whitelists[_accesslistId].root
    ) {
      return false;
    }
    return true;
  }

  /**
    A private helper function to sell an item to a whitelist presale
    participant.

    @param _amount The number of items that the caller would like to purchase.
    @param _whitelist A whitelist proof for users to submit with their claim to
      verify that they are in fact on the whitelist.
  */
  function sellWhitelist (
    uint256 _amount,
    WhitelistProof calldata _whitelist
  ) private {

    // Verify that the caller is on the merkle whitelist.
    bool verified = verify(
      _whitelist.id,
      _whitelist.index,
      keccak256(
        abi.encodePacked(
          _whitelist.index,
          _msgSender(),
          _whitelist.allowance
        )
      ),
      _whitelist.proof
    );

    // Reject the purchase if the caller is not a valid whitelist member.
    if (!verified) { revert CannotVerifyAsWhitelistMember(); }

    // Reject the purchase if the caller is exceeding their whitelist allowance.
    if (purchaseCounts[_msgSender()] + _amount > _whitelist.allowance) {
      revert CannotExceedWhitelistAllowance();
    }

    // Calculate the sale token and price.
    address token = whitelists[_whitelist.id].token;
    uint256 whitelistPrice = whitelists[_whitelist.id].price * _amount;

    // The zero address indicates that the purchase asset is Ether.
    if (token == address(0)) {
      if (msg.value != whitelistPrice) {
        revert CannotTransferIncorrectAmount();
      }

    // Otherwise, the caller is making their purchase with an ERC-20 token.
    } else {
      IERC20(token).safeTransferFrom(
        _msgSender(),
        address(this),
        whitelistPrice
      );
    }
  }

  /**
    Allow a caller to purchase an item.

    @param _amount The amount of items that the caller would like to purchase.
    @param _whitelist The caller-subumitted whitelist proof to check if they
      belong on a presale whitelist.
  */
  function mint (
    uint256 _amount,
    WhitelistProof calldata _whitelist
  ) external payable nonReentrant {

    // Reject purchases for no items.
    if (_amount < 1) { revert CannotBuyZeroItems(); }

    /*
      Reject purchases that happen after the end of the public sale. Do note
      that this means that whitelist sales with an ending duration _after_ the
      end of the public sale are ignored completely. In other words: the ending
      time of the public sale takes precedent over the ending time of a
      whitelisted presale. A whitelisted presale may not continue selling items
      after the public sale has ended.
    */
    if (block.timestamp >= endTime) { revert CannotBuyFromEndedSale(); }

    // Reject purchases that exceed the per-transaction cap.
    if (_amount > transactionCap) {
      revert CannotExceedPerTransactionCap();
    }

    // Reject purchases that exceed the per-caller cap.
    if (purchaseCounts[_msgSender()] + _amount > callerCap) {
      revert CannotExceedPerCallerCap();
    }

    // Reject purchases that exceed the total sale cap.
    if (sold + _amount > totalCap) { revert CannotExceedTotalCap(); }

    /*
      If the current timestamp is greater than this contract's `startTime`, the
      public sale has begun and all users will be directed to the public sale
      functionality.
    */
    if (block.timestamp >= startTime) {
      sellPublic(_amount);

    /*
      Otherwise, since the public sale has not begun, attempt to sell to this
      user as a member of the presale whitelist.
    */
    } else {
      sellWhitelist(_amount, _whitelist);
    }

    // Update the count of items sold.
    sold += _amount;

    // Update the caller's purchase count.
    purchaseCounts[_msgSender()] += _amount;

    // Mint the items.
    ITiny721(collection).mint_Qgo(_msgSender(), _amount);
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