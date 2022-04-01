// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/Decimals.sol';
import './libraries/TransferHelper.sol';
import './libraries/NFTHelper.sol';

/**
 * @title HedgeyOTC is an over the counter peer to peer trading contract
 * @notice This contract allows for a seller to generate a unique over the counter deal, which can be private or public
 * @notice The public deals allow anyone to participate and purchase tokens from the seller, whereas a private deal allows only a single whitelisted address to participate
 * @notice The Seller decides how much tokens to sell and at what price
 * @notice The Seller also decides if the tokens being sold must be time locked - which means that there is a vesting period before the buyers can access those tokens
 */
contract HedgeyOTC is ReentrancyGuard {
  using SafeERC20 for IERC20;

  /// @dev we set the WETH address so that we can wrap and unwrap ETH sending to and from the smart contract
  /// @dev the smart contract always stores WETH, but receives and delivers ETH to and from users
  address payable public weth;
  /// @dev d is a basic counter, used for indexing all of the deals - and deals are mapped to each index d
  uint256 public d = 0;
  /// @dev the futureContract is used to time lock tokens. This contract points to one specific contract for time locking
  /// @dev the futureContract is an ERC721 contract that locks the tokens for users until they are unlocked and can be redeemed
  address public futureContract;

  constructor(address payable _weth, address _fc) {
    weth = _weth;
    futureContract = _fc;
  }

  /**
   * @notice Deal is the struct that defines a single OTC offer, created by a seller
   * @dev  Deal struct contains the following parameter definitions:
   * @dev 1) seller: This is the creator and seller of the deal
   * @dev 2) token: This is the token that the seller is selling! Must be a standard ERC20 token, parameter is the contract address of the ERC20
   * @dev ... the ERC20 contract is required to have a public call function decimals() that returns a uint. This is required to price the amount of tokens being purchase
   * @dev ... by the buyer - calculating exactly how much to deliver to the seller.
   * @dev 3) paymentCurrency: This is also an ERC20 which the seller will get paid in during the act of a buyer buying tokens - also the ERC20 contract address
   * @dev 4) remainingAmount: This initially is the entire deposit the seller is selling, but as people purchase chunks of the deal, the remaining amount is decreased to 0
   * @dev 5) minimumPurchase: This is the minimum chunk size that a buyer can purchase, defined by the seller, must be greater than 0.
   * @dev 6) price: The Price is the per token cost which buyers pay to the seller, denominated in the payment currency. This is not the total price of the deal
   * @dev ... the total price is calculated by the remainingAmount * price (then adjusting for the decimals of the payment currency)
   * @dev 7) maturity: this is the unix time defining the period in which the deal is valid. After the maturity no purchases can be made.
   * @dev 8) unlockDate: this is the unix time which may be used to time lock tokens that are sold. If the unlock date is 0 or less than current block time
   * @dev ... at the time of purchase, the tokens are not locked but rather delivered directly to the buyer from the contract
   * @dev 9) buyer: this is a whitelist address for the buyer. It can either be the Zero address - which indicates that Anyone can purchase
   * @dev ... or it is a single address that only that owner of the address can participate in purchasing the tokens
   */
  struct Deal {
    address seller;
    address token;
    address paymentCurrency;
    uint256 remainingAmount;
    uint256 minimumPurchase;
    uint256 price;
    uint256 maturity;
    uint256 unlockDate;
    address buyer;
  }

  /// @dev the Deals are all mapped via the indexer d to deals mapping
  mapping(uint256 => Deal) public deals;

  receive() external payable {}

  /**
   * @notice This function is what the seller uses to create a new OTC offering
   * @notice Once this function has been completed - buyers can purchase tokens from the seller based on the price and parameters set
   * @dev this function will pull in tokens from the seller, create a new Deal struct and mapped to the current index d
   * @dev this function does not allow for taxed / deflationary tokens - as the amount that is pulled into the contract must match with what is being sent
   * @dev this function requires that the _token has a decimals() public function on its ERC20 contract to be called
   * @param _token is the ERC20 contract address that the seller is going to create the over the counter offering for
   * @param _paymentCurrency is the ERC20 contract address of the opposite ERC20 that the seller wants to get paid in when selling the token (use WETH for ETH)
   * ... this can also be used for a token SWAP - where the ERC20 address of the token being swapped to is input as the paymentCurrency
   * @param _amount is the amount of tokens that you as the seller want to sell
   * @param _min is the minimum amount of tokens that a buyer can purchase from you. this should be less than or equal to the total amount
   * @param _price is the price per token which the seller will get paid, denominated in the payment currency
   * ... if this is a token SWAP, then the _price needs to be set as the ratio of the tokens being swapped - ie 10 for 10 paymentCurrency tokens to 1 token
   * @param _maturity is how long you would like to allow buyers to purchase tokens from this deal, in unix time. this needs to be beyond current block time
   * @param _unlockDate is used if you are requiring that tokens purchased by buyers are locked. If this is set to 0 or anything less than current block time
   * ... any tokens purchased will not be locked but immediately delivered to the buyers. Otherwise the unlockDate will lock the tokens in the associated
   * ... futureContract and mint the buyer an NFT - which will hold the tokens in escrow until the unlockDate has passed - whereupon the owner of the NFT can redeem the tokens
   * @param _buyer is a special option to make this a private deal - where only a specific buyer's address can participate and make the purchase. If this is set to the
   * ... Zero address - then it is publicly available and anyone can purchase tokens from this deal
   */
  function create(
    address _token,
    address _paymentCurrency,
    uint256 _amount,
    uint256 _min,
    uint256 _price,
    uint256 _maturity,
    uint256 _unlockDate,
    address payable _buyer
  ) external payable nonReentrant {
    /// @dev check to make sure that the maturity is beyond current block time
    require(_maturity > block.timestamp, 'OTC01');
    /// @dev check to make sure that the total amount is grater than or equal to the minimum
    require(_amount >= _min, 'OTC02');
    /// @dev this checks to make sure that if someone purchases the minimum amount, it is never equal to 0
    /// @dev where someone could find a small enough minimum to purchase all of the tokens for free.
    require((_min * _price) / (10**Decimals(_token).decimals()) > 0, 'OTC03');
    /// @dev creates the Deal struct with all of the parameters for inputs - and set the bool 'open' to true so that this offer can now be purchased
    deals[d++] = Deal(msg.sender, _token, _paymentCurrency, _amount, _min, _price, _maturity, _unlockDate, _buyer);
    /// @dev pulls the tokens into this contract so that they can be purchased. If ETH is being used, it will pull ETH and wrap and receive WETH into this contract
    TransferHelper.transferPayment(weth, _token, payable(msg.sender), payable(address(this)), _amount);
    /// @dev emit an event with the parameters of the deal, because counter d has already been increased by 1, need to subtract one when emitting the event
    emit NewDeal(d - 1, msg.sender, _token, _paymentCurrency, _amount, _min, _price, _maturity, _unlockDate, _buyer);
  }

  /**
   * @notice This function lets a seller cancel their existing deal anytime they if they want to, including before the maturity date
   * @notice all that is required is that the deal has not been closed, and that there is still a reamining balance
   * @dev you need to know the index _d of the deal you are trying to close and that is it
   * @dev only the seller can close this deal
   * @dev once this has been called the Deal struct in storage is deleted so that it cannot be accessed for any further methods
   * @param _d is the dealID that is mapped to the Struct Deal
   */
  function close(uint256 _d) external nonReentrant {
    /// @dev grabs from storage the deal, and temporarily stores in memory
    Deal memory deal = deals[_d];
    /// @dev only the seller can call this function
    require(msg.sender == deal.seller, 'OTC04');
    /// @dev the remaining amount must be greater than 0
    require(deal.remainingAmount > 0, 'OTC05');
    /// @dev delete the struct so it can no longer be used
    delete deals[_d];
    /// @dev withdraw the reamining tokens to the seller (msg.sender), if its WETH send back ETH to seller
    TransferHelper.withdrawPayment(weth, deal.token, payable(msg.sender), deal.remainingAmount);
    /// @dev emit an event to announce the deal has been closed
    emit DealClosed(_d);
  }

  /**
   * @notice This function is what buyers use to make purchases from the sellers
   * @param _d is the index of the deal that a buyer wants to participate in and make a purchase
   * @param _amount is the amount of tokens the buyer is purchasing, which must be at least the minimumPurchase
   * ... and at most the remainingAmount for this deal (or the remainingAmount if that is less than the minimum)
   * @notice ensure when using this function that you are aware of the minimums, and price per token to ensure sufficient balances to make a purchase
   * @notice if the deal has an unlockDate that is beyond the current block time - no tokens will be received by the buyer, but rather they will receive
   * @notice an NFT, which represents their ability to redeem and claim the locked tokens after the unlockDate has passed
   * @notice the NFT is minted from the futureContract, where the locked tokens are delivered to and held
   * @notice the Seller will receive payment in full immediately when triggering this function, there is no lock on payments
   * @dev this function can also be used to execute a token SWAP function, where the swap is executed through this function
   */
  function buy(uint256 _d, uint256 _amount) external payable nonReentrant {
    /// @dev pull the deal details from storage, placed in memory
    Deal memory deal = deals[_d];
    /// @dev we do not let the seller sell to themselves, must be a separate buyer
    require(msg.sender != deal.seller, 'OTC06');
    /// @dev require that the deal order is still valid by checking if the block time is not passed the maturity date
    require(deal.maturity >= block.timestamp, 'OTC07');
    /// @dev if the deal had a whitelist - then require the msg.sender to be that buyer, otherwise if there was no whitelist, anyone can buy
    require(msg.sender == deal.buyer || deal.buyer == address(0x0), 'OTC08');
    /// @dev require that the amount being purchased is greater than the deal minimum, or that the amount being purchased is the entire remainder of whats left
    /// @dev AND require that the remaining amount in the deal actually equals or exceeds what the buyer wants to purchase
    require(
      (_amount >= deal.minimumPurchase || _amount == deal.remainingAmount) && deal.remainingAmount >= _amount,
      'OTC09'
    );
    /// @dev we calculate the purchase amount taking the decimals from the token first
    /// @dev then multiply the amount by the per token price, and now to get back to an amount denominated in the payment currency divide by the factor of token decimals
    uint256 decimals = Decimals(deal.token).decimals();
    uint256 purchase = (_amount * deal.price) / (10**decimals);
    /// @dev transfer the paymentCurrency purchase amount from the buyer to the seller's address. If the paymentCurrency is WETH - seller will receive ETH
    TransferHelper.transferPayment(weth, deal.paymentCurrency, msg.sender, payable(deal.seller), purchase);
    /// @dev reduce the deal remaining amount by how much was purchased
    deal.remainingAmount -= _amount;
    /// @dev emit an even signifying that the buyer has purchased tokens from the seller, what amount, and how much remains to be purchased in this deal
    emit TokensBought(_d, _amount, deal.remainingAmount);
    if (deal.unlockDate > block.timestamp) {
      /// @dev if the unlockdate is the in future, then tokens will be sent to the futureContract, and NFT minted to the buyer
      /// @dev the buyer can redeem and unlock their tokens interacting with the futureContract after the unlockDate has passed
      NFTHelper.lockTokens(futureContract, msg.sender, deal.token, _amount, deal.unlockDate);
      /// @dev emit an event that a Future, ie locked tokens event, has happened
      emit FutureCreated(msg.sender, deal.token, _amount, deal.unlockDate);
    } else {
      /// @dev if the unlockDate is in the past or now - then tokens are already unlocked and delivered directly to the buyer
      TransferHelper.withdrawPayment(weth, deal.token, payable(msg.sender), _amount);
    }
    /// @dev if the reaminder is 0, then we simply delete the storage struct Deal so that it is effectively closed
    if (deal.remainingAmount == 0) {
      delete deals[_d];
    } else {
      /// @dev if there is still a remainder - we need to update our global public deal struct in storage
      deals[_d].remainingAmount = deal.remainingAmount;
    }
  }

  /// @dev events for each function
  event NewDeal(
    uint256 _d,
    address _seller,
    address _token,
    address _paymentCurrency,
    uint256 _remainingAmount,
    uint256 _minimumPurchase,
    uint256 _price,
    uint256 _maturity,
    uint256 _unlockDate,
    address _buyer
  );
  event TokensBought(uint256 _d, uint256 _amount, uint256 _remainingAmount);
  event DealClosed(uint256 _d);
  event FutureCreated(address _owner, address _token, uint256 _amount, uint256 _unlockDate);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @dev this interface is a critical addition that is not part of the standard ERC-20 specifications
/// @dev this is required to do the calculation of the total price required, when pricing things in the payment currency
/// @dev only the payment currency is required to have a decimals impelementation on the ERC20 contract, otherwise it will fail
interface Decimals {
  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IWETH.sol';

/// @notice Library to help safely transfer tokens and handle ETH wrapping and unwrapping of WETH
library TransferHelper {
  using SafeERC20 for IERC20;

  /// @notice Internal function used for standard ERC20 transferFrom method
  /// @notice it contains a pre and post balance check
  /// @notice as well as a check on the msg.senders balance
  /// @param token is the address of the ERC20 being transferred
  /// @param from is the remitting address
  /// @param to is the location where they are being delivered
  function transferTokens(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    require(IERC20(token).balanceOf(msg.sender) >= amount, 'THL01');
    SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

  /// @notice Internal function is used with standard ERC20 transfer method
  /// @notice this function ensures that the amount received is the amount sent with pre and post balance checking
  /// @param token is the ERC20 contract address that is being transferred
  /// @param to is the address of the recipient
  /// @param amount is the amount of tokens that are being transferred
  function withdrawTokens(
    address token,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    SafeERC20.safeTransfer(IERC20(token), to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

  /// @dev Internal function that handles transfering payments from buyers to sellers with special WETH handling
  /// @dev this function assumes that if the recipient address is a contract, it cannot handle ETH - so we always deliver WETH
  /// @dev special care needs to be taken when using contract addresses to sell deals - to ensure it can handle WETH properly when received
  function transferPayment(
    address weth,
    address token,
    address from,
    address payable to,
    uint256 amount
  ) internal {
    if (token == weth) {
      require(msg.value == amount, 'THL03');
      if (!Address.isContract(to)) {
        (bool success, ) = to.call{value: amount}('');
        require(success, 'THL04');
      } else {
        /// @dev we want to deliver WETH from ETH here for better handling at contract
        IWETH(weth).deposit{value: amount}();
        assert(IWETH(weth).transfer(to, amount));
      }
    } else {
      transferTokens(token, from, to, amount);
    }
  }

  /// @dev Internal funciton that handles withdrawing tokens and WETH that are up for sale to buyers
  /// @dev this function is only called if the tokens are not timelocked
  /// @dev this function handles weth specially and delivers ETH to the recipient
  function withdrawPayment(
    address weth,
    address token,
    address payable to,
    uint256 amount
  ) internal {
    if (token == weth) {
      IWETH(weth).withdraw(amount);
      (bool success, ) = to.call{value: amount}('');
      require(success, 'THL04');
    } else {
      withdrawTokens(token, to, amount);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/INFT.sol';

/// @notice Library to lock tokens and mint an NFT
/// @notice this NFTHelper is used by the HedgeyOTC contract to lock tokens and instruct the Hedgeys contract to mint an NFT
library NFTHelper {
  /// @dev internal function that handles the locking of the tokens in the NFT Futures contract
  /// @param futureContract is the address of the NFT contract that will mint the NFT and lock tokens
  /// @param _holder address here becomes the owner of the newly minted NFT
  /// @param _token address here is the ERC20 contract address of the tokens being locked by the NFT contract
  /// @param _amount is the amount of tokens that will be locked
  /// @param _unlockDate provides the unlock date which is the expiration date for the Future generated
  function lockTokens(
    address futureContract,
    address _holder,
    address _token,
    uint256 _amount,
    uint256 _unlockDate
  ) internal {
    /// @dev ensure that the _unlockDate is in the future compared to the current block timestamp
    require(_unlockDate > block.timestamp, 'NHL01');
    /// @dev similar to checking the balances for the OTC contract when creating a new deal - we check the current and post balance in the NFT contract
    /// @dev to ensure that 100% of the amount of tokens to be locked are in fact locked in the contract address
    uint256 currentBalance = IERC20(_token).balanceOf(futureContract);
    /// @dev increase allowance so that the NFT contract can pull the total funds
    /// @dev this is a safer way to ensure that the entire amount is delivered to the NFT contract
    SafeERC20.safeIncreaseAllowance(IERC20(_token), futureContract, _amount);
    /// @dev this function points to the NFT Futures contract and calls its function to mint an NFT and generate the locked tokens future struct
    INFT(futureContract).createNFT(_holder, _amount, _token, _unlockDate);
    /// @dev check to make sure that _holder is received by the futures contract equals the total amount we have delivered
    /// @dev this prevents functionality with deflationary or tax tokens that have not whitelisted these address
    uint256 postBalance = IERC20(_token).balanceOf(futureContract);
    assert(postBalance - currentBalance == _amount);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @dev used for handling ETH wrapping into WETH to be stored in smart contracts upon deposit,
/// ... and used to unwrap WETH into ETH to deliver when withdrawing from smart contracts
interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @dev this is the one contract call that the OTC needs to interact with the NFT contract
interface INFT {
  /// @notice function for publicly viewing a lockedToken (future) details
  /// @param _id is the id of the NFT which is mapped to the future struct
  /// @dev this returns the amount of tokens locked, the token address and the date that they are unlocked
  function futures(uint256 _id)
    external
    view
    returns (
      uint256 amount,
      address token,
      uint256 unlockDate
    );

  /// @param _holder is the new owner of the NFT and timelock future - this can be any address
  /// @param _amount is the amount of tokens that are going to be locked
  /// @param _token is the token address to be locked by the NFT. Use WETH address for ETH - but WETH must be held by the msg.sender
  /// ... as there is no automatic wrapping from ETH to WETH for this function.
  /// @param _unlockDate is the date which the tokens become unlocked and available to be redeemed and withdrawn from the contract
  /// @dev this is a public function that anyone can call
  /// @dev the _holder can be defined as your address, or any chose address - and so you can directly mint NFTs to other addresses
  /// ... in a way to airdrop NFTs directly to contributors
  function createNFT(
    address _holder,
    uint256 _amount,
    address _token,
    uint256 _unlockDate
  ) external returns (uint256);

  /// @dev function for redeeming an NFT
  /// @notice this function will burn the NFT and delete the future struct - in return the locked tokens will be delivered
  function redeemNFT(uint256 _id) external returns (bool);

  /// @notice this event spits out the details of the NFT and future struct when a new NFT & Future is minted
  event NFTCreated(uint256 _i, address _holder, uint256 _amount, address _token, uint256 _unlockDate);

  /// @notice this event spits out the details of the NFT and future structe when an existing NFT and Future is redeemed
  event NFTRedeemed(uint256 _i, address _holder, uint256 _amount, address _token, uint256 _unlockDate);

  /// @notice this event is fired the one time when the baseURI is updated
  event URISet(string newURI);
}