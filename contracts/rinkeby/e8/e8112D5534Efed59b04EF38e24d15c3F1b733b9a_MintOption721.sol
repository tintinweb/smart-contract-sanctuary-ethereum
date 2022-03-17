// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ITiny721.sol";

error AmountGreaterThanRemaining();
error CannotUnderpayForMint();
error RefundTransferFailed();
error NotExercisableYet();
error NotOptionOwner();
error OptionAlreadyExercised();
error SaleNotStarted();
error SweepingTransferFailed();
error ZeroBasicPriceConfig();
error ZeroMinPriceConfig();
error ZeroPricePurchase();

interface IOption721 {
  function mintOpt( uint256 amount, uint256 claimStamp, address recipient ) external;
  function transferFrom( address from, address to, uint256 tokenId ) external;
  function exercisable( uint256 tokenId ) external returns ( uint256 );
  function ownerOf( uint256 id ) external returns ( address );
}

interface IERC20 {
  function transfer( address _destination, uint256 _amount ) external;
}

/**
  @title MintOption721
  @author 0xthrpw
  @author Doctor Classic

  This contract, along with the Option721 contract, allows users to purchase an
  option to mint an item at a time-based discount.  Users purchase an option
  token with a capped per term discount, and specify the length of time they are
  willing to wait between paying for the option and exercising the option.  Once
  the term is complete, users can exercise their option and redeem it to mint
  their item. Users with low time preference can choose to forgo the option
  method entirely and purchase their item immediately with no discount.

  Additionally, the system can be configured to allow the number of option
  tokens that can be minted to exceed the corresponding number of items that can
  be minted.  This creates an effect where users that purchase options for
  longer terms may not be able to exercise their options before the actual item
  collection sells out (expiry).  The introduction of this risk creates a
  disincentive to 'game' the system by blindly maxing out the term length for
  the largest discount.  It is recognized that this may not be desirable for all
  projects, so this setting is optional which will allow for guaranteed
  option/item redemption.

  March 13th, 2022
*/
contract MintOption721 is Ownable, ReentrancyGuard {

  address public paymentReceiver;

  address public option;

  address public item;

  uint256 public sellableCount;


  /**
    The settings that govern all option behavior for a given round

    @param startTime the starting time for options calculations
    @param basicPrice
    @param minPrice
    @param discountPerTermUnit
    @param termUnit
    @param syncSupply
  */
  struct Config {
    uint256 startTime;
    uint256 basicPrice;
    uint256 minPrice;
    uint256 discountPerTermUnit;
    uint256 termUnit;
    bool syncSupply;
  }

  /// roundId > configuration struct
  mapping(uint256 => Config) public configs;

  /**
    Construct a new instance of this contract.

    @param _item The contract address of the collection being sold
    @param _option The address of the collection's option contract.
    @param _paymentReceiver The address of the recipient of sale proceeds.
    @param _sellableCount The running number of items this contract can sell.
  */
  constructor(
    address _item,
    address _option,
    address _paymentReceiver,
    uint256 _sellableCount
  ) {
    item = _item;
    option = _option;
    paymentReceiver = _paymentReceiver;
    sellableCount = _sellableCount;
  }

  event Exercised(
    uint256 indexed tokenId,
    address indexed user
  );

  /**
    Set the configuration of a redemption at index 'roundId'.  Each round's
    config consists of a `Config` struct.  See the comments above for the struct
    itself for more detail on the contained parameters.

    @param _roundId The index in the configs array where this config is stored.
    @param _config The configuration data for the specified round.
  */
  function setConfig (uint256 _roundId, Config memory _config) external onlyOwner {
    configs[_roundId] = _config;
  }

  /**
    Purchase and option token that can be redeemed to mint an item from this
    contract once the exercise time is reached and the term is satisfied.

    @param _roundId the index of the configuration for this round
    @param _termLength the number of termUnits the user will wait before exercising
    @param _amount the number of options the user is purchasing
  */
  function purchaseOption (
    uint256 _roundId,
    uint256 _termLength,
    uint256 _amount
  ) external payable nonReentrant {
    Config memory config = configs[_roundId];
    // Make sure sale has started
    if( config.startTime > block.timestamp){ revert SaleNotStarted(); }

    // Make sure config isn't empty
    if( config.basicPrice == 0 ){ revert ZeroBasicPriceConfig(); }
    if( config.minPrice == 0 ){ revert ZeroMinPriceConfig(); }

    // Calculate the option discount.
    uint256 discount = _termLength * config.discountPerTermUnit;

    // Check if price has broken minimum price threshold.
    uint256 price = (config.minPrice + discount > config.basicPrice)
      ? config.minPrice
      : config.basicPrice - discount ;

    // Calculate the timestamp of when the option becomes exercisable.
    uint256 claimStamp = block.timestamp + ( _termLength * config.termUnit );

    // Calculate the total cost of this purchase.
    uint256 totalCharge = price * _amount;

    // If set, check sellable amount of items
    if( config.syncSupply ){
      if( _amount > sellableCount ){
        revert AmountGreaterThanRemaining();
      }
      sellableCount -= _amount;
    }

    // Reject the purchase if the caller is underpaying.
    if (msg.value < totalCharge) { revert CannotUnderpayForMint(); }

    // Refund the caller's excess payment if they overpaid.
    if (msg.value > totalCharge) {
      uint256 excess = msg.value - totalCharge;
      (bool returned, ) = payable(_msgSender()).call{ value: excess }("");
      if (!returned) { revert RefundTransferFailed(); }
    }

    // Mint the option.
    IOption721(option).mintOpt(_amount, claimStamp, msg.sender);
  }


  /**
    Purchase tokens without using the option system, this function will allow
    a user to buy at this configuration's basicPrice.

    @param _roundId the index of the configuration for this round
    @param _amount the number of tokens the user is purchasing
  */
  function purchaseToken (
    uint256 _roundId,
    uint256 _amount
  ) external payable nonReentrant {
    Config memory config = configs[_roundId];
    // Make sure sale has started
    if( config.startTime > block.timestamp){ revert SaleNotStarted(); }

    // Make sure config isn't empty
    if( config.basicPrice == 0 ){ revert ZeroBasicPriceConfig(); }
    if( config.minPrice == 0 ){ revert ZeroMinPriceConfig(); }

    // If set, check sellable amount of items
    if( config.syncSupply ){
      if( _amount > sellableCount ){
        revert AmountGreaterThanRemaining();
      }
      sellableCount -= _amount;
    }

    // Calculate the total cost of this purchase.
    uint256 totalCharge = config.basicPrice * _amount;

    // Reject the purchase if the caller is underpaying.
    if (msg.value < totalCharge) { revert CannotUnderpayForMint(); }

    // Refund the caller's excess payment if they overpaid.
    if (msg.value > totalCharge) {
      uint256 excess = msg.value - totalCharge;
      (bool returned, ) = payable(_msgSender()).call{ value: excess }("");
      if (!returned) { revert RefundTransferFailed(); }
    }

    // Mint the item.
    ITiny721(item).mint_Qgo(msg.sender, _amount);
  }

  /**
    Exercise an option token once the exercisable time is reached.  Once the
    option is exercised, it is sent to the option contract itself.  This removes
    it from circulation and allows for distinguishing between tokenIds that dont
    exist yet from those that have been exercised.

    @param _tokenId the ID of the option token being exercised
  */
  function exerciseOption ( uint256 _tokenId ) external nonReentrant {
    // Check the option's claimstamp.
    if( IOption721(option).exercisable(_tokenId) > block.timestamp ){
      revert NotExercisableYet();
    }

    // Double check the option's ownership.
    if( IOption721(option).ownerOf(_tokenId) != msg.sender ){
      revert NotOptionOwner();
    }

    // Deactivate the option by sending it to its contract.
    IOption721(option).transferFrom(msg.sender, option, _tokenId);

    // Mint the item.
    ITiny721(item).mint_Qgo(msg.sender, 1);
    emit Exercised(_tokenId, msg.sender);
  }

  /**
    Allow any caller to send this contract's balance of Ether to the payment
    destination.
  */
  function claim () external nonReentrant {
    (bool success, ) = payable(paymentReceiver).call{
      value: address(this).balance
    }("");
    if (!success) { revert SweepingTransferFailed(); }
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
      IERC20(_token).transfer(_destination, _amount);
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
    Provided with an address parameter, this function returns the number of all
    tokens in this collection that are owned by the specified address.

    @param _owner The address of the account for which we are checking balances
  */
  function balanceOf (
    address _owner
  ) external returns ( uint256 );

  /**
    Provided with the ID of a token, this function returns the address of the
    current owner of the token with the specified ID.

    @param id The ID of the token for which we are checking ownership
  */
  function ownerOf (
    uint256 id
  ) external returns ( address );

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