//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../PriceFeed/PriceFeed.sol";


contract PriceFeedMock is PriceFeed {


    mapping(address => int256) prices;

    function getLatestPriceUSD(address _token) public override  view returns (int256, uint8) {
        require(prices[_token] != 0, "This token is not supported");
        return (prices[_token], 18);
    }

    function setPriceForToken(address _token, int256 _price) public {
        prices[_token] = _price * 1e18;
    }

    function getLatestPriceUSDOriginal(address _token) public  view returns (int256, uint8) {
        return super.getLatestPriceUSD(_token);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/Errors.sol";

/**
* @dev hardcoded values are all for Kovan
 */
contract PriceFeed is Ownable{

    mapping(address => address) priceFeedAddresses;
    // Events
    event PriceFeedAdded(uint256 timestamp, address indexed token, address indexed priceFeed);

    constructor() Ownable(){}

    /// @dev function for owner to add more price feeds
    function addPriceFeed(address _token, address _feed) external onlyOwner{
        priceFeedAddresses[_token] = _feed;
        emit PriceFeedAdded(block.timestamp, _token, _feed);
    }

    /**
     * Returns the latest price
     */
    function getLatestPriceUSD(address _token) public view virtual returns (int , uint8) {
        require(priceFeedAddresses[_token] != address(0), Errors.PRICE_FEED_TOKEN_NOT_SUPPORTED);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddresses[_token]);
        (
            , 
            int price
            ,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return (price, priceFeed.decimals());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Konstantin Samarin
 * @notice Defines the error messages emitted by the different contracts of the RociFi protocol
 * @dev Error messages prefix glossary:
 *  - NFCS = NFCS
 *  - BONDS = Bonds
 *  - INVESTOR = Investor
 *  - POOL_INVESTOR = PoolInvestor
 *  - SCORE_DB = ScoreConfigs, ScoreDB, ScoreDBV2
 *  - PAYMENT = ERC20CollateralPayment, ERC20PaymentStandard, RociPayment
 *  - PRICE_FEED = PriceFeed
 *  - REVENUE = PaymentSplitter, RevenueManager
 *  - LOAN = Loan 
 *  - VERSION = Version
 */
library Errors {
  string public constant NFCS_TOKEN_MINTED = '0'; //  Token already minted
  string public constant NFCS_TOKEN_NOT_MINTED = '1'; //  No token minted for address
  string public constant NFCS_ADDRESS_BUNDLED = '2';  // Address already bundled
  string public constant NFCS_WALLET_VERIFICATION_FAILED = '3'; //  Wallet verification failed
  string public constant NFCS_NONEXISTENT_TOKEN = '4';  // Nonexistent NFCS token
  string public constant NFCS_TOKEN_HAS_BUNDLE = '5'; //  Token already has an associated bundle
  string public constant NFCS_TOKEN_HAS_NOT_BUNDLE = '6'; //  Token does not have an associated bundle

  string public constant BONDS_HASH_AND_ENCODING = '100'; //  Hash of data signed must be the paymentContractAddress and id encoded in that order
  string public constant BONDS_BORROWER_SIGNATURE = '101';  // Data provided must be signed by the borrower
  string public constant BONDS_NOT_STACKING = '102'; //  Not staking any NFTs
  string public constant BONDS_NOT_STACKING_INDEX = '103'; //  Not staking any tokens at this index
  string public constant BONDS_DELETE_HEAD = '104';  // Cannot delete the head

  string public constant INVESTOR_ISSUE_BONDS = '200'; //  Issue minting bonds
  string public constant INVESTOR_INSUFFICIENT_AMOUNT = '201'; //  Cannot borrow an amount of 0

  string public constant POOL_INVESTOR_INTEREST_RATE = '300';  // Interest rate has to be greater than zero
  string public constant POOL_INVESTOR_ZERO_POOL_VALUE = '301';  // Pool value is zero
  string public constant POOL_INVESTOR_ZERO_TOTAL_SUPPLY = '302';  // Total supply is zero
  string public constant POOL_INVESTOR_BONDS_LOST = '303';  // Bonds were lost in unstaking
  string public constant POOL_INVESTOR_NOT_ENOUGH_FUNDS = '304';  // Not enough funds to fulfill the loan

  string public constant MANAGER_COLLATERAL_NOT_ACCEPTED = '400';  // Collateral is not accepted
  string public constant MANAGER_COLLATERAL_INCREASE = '401';  // When increasing collateral, the same ERC20 address should be used
  string public constant MANAGER_ZERO_WITHDRAW = '402';  // Cannot withdrawal zero
  string public constant MANAGER_EXCEEDING_WITHDRAW = '403';  // Requested withdrawal amount is too large

  string public constant SCORE_DB_EQUAL_LENGTH = '501';  // Arrays must be of equal length
  string public constant SCORE_DB_VERIFICATION = '502';  // Unverified score
  string public constant SCORE_DB_SCORE_NOT_GENERATED= '503';  // Score not yet generated.
  string public constant SCORE_DB_SCORE_GENERATING = '504';  // Error generating score.
  string public constant SCORE_DB_UNKNOW_FETCHING_SCORE = '505';  //  Unknown error fetching score.


  string public constant PAYMENT_NFCS_OUTDATED = '600';  // Outdated NFCS score outdated
  string public constant PAYMENT_ZERO_LTV = '601';  // LTV cannot be zero
  string public constant PAYMENT_NOT_ENOUGH_COLLATERAL = '602';  // Not enough collateral to issue a loan
  string public constant PAYMENT_NO_BONDS = '603';  // There is no bonds to liquidate a loan
  string public constant PAYMENT_FULFILLED = '604';  // Contract is paid off
  string public constant PAYMENT_NFCS_OWNERSHIP = '605';  // NFCS ID must belong to the borrower
  string public constant PAYMENT_NON_ISSUED_LOAN = '606';  // Loan has not been issued
  string public constant PAYMENT_WITHDRAWAL_COLLECTION = '607';  // There are not enough payments available for collection
  string public constant PAYMENT_LOAN_NOT_DELINQUENT = '608';  // Loan not delinquent
  string public constant PAYMENT_AMOUNT_TOO_LARGE = '609';  // Payment amount is too large

  string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = '700';  // Token is not supported
  
  string public constant REVENUE_ADDRESS_TO_SHARE = '800';  // Non-equal length of addresses and shares
  string public constant REVENUE_UNIQUE_INDEXES = '801';  // Indexes in an array must not be duplicate
  string public constant REVENUE_FAILED_ETHER_TX = '802';  // Failed to send Ether
  string public constant REVENUE_UNVERIFIED_INVESTOR = '803';  // Only verified investors may request funds or make a payment
  string public constant REVENUE_NOT_ENOUGH_FUNDS = '804';  // Not enough funds to complete this request

  string public constant LOAN_MIN_PAYMENT = '900';  // Minimal payment should be made
  string public constant LOAN_DAILY_LIMIT = '901';  // Exceeds daily borrow limit
  string public constant LOAN_DAILY_LIMIT_USER = '902';  // Exceeds user daily borrow limit
  string public constant LOAN_TOTAL_LIMIT_USER = '903';  // Exceeds user total borrow limit
  string public constant LOAN_TOTAL_LIMIT = '904';  // Exceeds total borrow limit
  string public constant LOAN_CONFIGURATION = '905';  // Loan that is already issued, or not configured cannot be issued
  string public constant LOAN_TOTAL_LIMIT_NFCS = '906';  // Exceeds total nfcs borrow limit
  string public constant LOAN_DAILY_LIMIT_NFCS = '907';  // Exceeds daily nfcs borrow limit

  string public constant VERSION = '1000';  // Incorrect version of contract

   
  string public constant ADDRESS_BOOK_SET_MIN_SCORE = '1100';  // New min score must be less then maxScore
  string public constant ADDRESS_BOOK_SET_MAX_SCORE = '1101';  // New max score must be more then minScore
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