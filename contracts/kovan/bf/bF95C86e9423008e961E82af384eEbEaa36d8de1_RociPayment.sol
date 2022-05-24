/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./ERC20CollateralPayment.sol";

import {IRociPayment} from "../interfaces/newInterfaces/payment/IRociPayment.sol";
import {ROCI_PAYMENT_VERSION} from "../ContractVersions.sol";
import {Errors} from "../libraries/Errors.sol";

contract RociPayment is ERC20CollateralPayment, IRociPayment{

    // Events
    event LiquidatedByAdmin(uint256 timestamp, uint256 indexed loanId);

    constructor(address _addressBook) ERC20CollateralPayment(_addressBook){}
    /**
     * @dev function for admin to liquidate a loan manually
     */
    function liquidateByAdmin(uint256 _id) external override onlyRole(Role.admin) {
        require(isDelinquent(_id), Errors.PAYMENT_LOAN_NOT_DELINQUENT);
            _liquidate(_id, address(this));
        emit LiquidatedByAdmin(block.timestamp, _id);
    }

    /**
    * @dev function to get a user's total outstanding balance (By NFCS ID)  
    * @param _nfcsId NFCS ID
    * @return total Outstanding balance
    */
    function getNFCSTotalOutstanding(uint _nfcsId) external override view returns(uint){
        return(Loan.getOutstanding(nfcsLoanLookup[_nfcsId]));
    }

    /**
    * @dev function to get a user's total outstanding balance (By NFCS ID)  
    * @param _nfcsId NFCS ID
    * @return total Outstanding balance
    */
    function getUserTotalOutstanding(uint _nfcsId) external override view returns(uint){
        address user = IERC721(lookup(Role.NFCS)).ownerOf(_nfcsId);
        return(Loan.getOutstanding(globalLoanLookup[user]));
    }


    /**
    * @dev function to get a system total outstanding balance  
    * @return total Outstanding balance
    */
    function getTotalOutstanding() external override view returns(uint){
        return(Loan.getOutstanding(globalLoanLookup[address(0)]));
    }

    /**
     * @notice returns the current version of the contract.
     */
    function currentVersion() public pure override returns (string memory) {
        return ROCI_PAYMENT_VERSION;
    }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {ONE_HUNDRED_PERCENT} from "../Globals.sol";
import {ScoreDBV2Interface} from "../interfaces/ScoreDBV2Interface.sol";


import "./ERC20PaymentStandard.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IBonds.sol";
import "../interfaces/newInterfaces/managers/ICollateralManager.sol";
import "../libraries/Structs.sol";
import "../libraries/Tracker.sol";
import "../Version/Version.sol";
import {Errors} from "../libraries/Errors.sol";

import {IERC20CollateralPayment} from "../interfaces/newInterfaces/payment/IERC20CollateralPayment.sol";

/**
 * @title ERC20CollateralPayment
 * @author Carson Case
 * @notice this is an example of a override of ERC20PaymentStandard. This offers ERC20 collateral to be be added
 * @dev the goal here is to keep this lightweight for Roci as investor is a heavy contract. Try and move as much
 *   functionality as possible to CollateralManager or other contracts
 */
abstract contract ERC20CollateralPayment is
    IERC20CollateralPayment,
    Version,
    ERC20PaymentStandard
{
    using Tracker for Tracker.outstandings;
    using Loan for Loan.loan;
    // Struct for housing priced loan info
    struct PricedLoanInfo {
        int256 collateralUSD;
        int256 outstandingUSD;
        uint256 ltv;
        uint256 lt;
        uint16 score;
    }

    struct LoanValueLimits{
      uint256 ltv;
      uint256 lt;
    }

    mapping(uint256 => LoanValueLimits) public LoanValueLimitsById;
    
    // Collateral objects contain a mapping of each token and it's outstandin amount
    mapping(address => Tracker.outstandings) internal usersCollateral;

    mapping(address => uint256[]) internal usersActiveLoans;

    // Events
    event CollateralDeposited(
      uint256 timestamp,
      address indexed borrower,
      address indexed token,
      uint256 indexed amount
    );
    event CollateralWithdrawn(
      uint256 timestamp,
      address indexed borrower,
      address indexed token,
      uint256 indexed amount
    );

    constructor(address _addressBook)
        ERC20PaymentStandard(IAddressBook(_addressBook))
    {}

    function collateralManager() private view returns (ICollateralManager) {
      return ICollateralManager(lookup(Role.collateralManager));
    }

   /**
   * @notice Access data from oracle
   * @param nfcsId id of NFCS token
   * @param ERC20Address address of ERC20 token
   * @param checkNFCSTimestamp check NFCS token for freshness
   * @return ltv
   * @return lt
   * @return creditScore
   */
    function getDataFromOracle(
      uint256 nfcsId,
      address ERC20Address, 
      bool checkNFCSTimestamp
    ) 
      private 
      view 
      returns (uint256 ltv, uint256 lt, uint16 creditScore) 
    {
      ScoreDBV2Interface oracle = ScoreDBV2Interface(lookup(Role.oracle));
      Structs.Score memory score = oracle.getScore(nfcsId);
      if (checkNFCSTimestamp) {
        require(
          block.timestamp >= score.timestamp && block.timestamp - score.timestamp <= addressBook.scoreValidityPeriod(),
          Errors.PAYMENT_NFCS_OUTDATED
        );
      }
      ltv = oracle.LTV(ERC20Address, score.creditScore);
      lt = oracle.LT(ERC20Address, score.creditScore);
      require(ltv > 0, Errors.PAYMENT_ZERO_LTV);
      return (ltv, lt, score.creditScore);
    }

    /**
     * @notice addCollateral must be called before issuing loan
     * @param _ERC20Contract address of the ERC20 you want to have as collaterall. DOES NOT have to be equal to payment ERC20
     * @param _amount is the ammount to add as collateral
     */
    function addCollateral(
        address _from,
        address _ERC20Contract,
        uint256 _amount
    ) external virtual override whenNotPaused {
        collateralManager().deposit(_from, _ERC20Contract, _amount);
        emit CollateralDeposited(block.timestamp, _from, _ERC20Contract, _amount);
    }

   /**
   * @notice called when bonds are issued so as to make sure lender can only mint bonds once.
   * @param _id loan ID
   * @return principal (so bonds knows how many NFTs to mint)
   * @return borrower address (so bonds can make sure borrower is calling this function)
   */
  function issueBonds(uint256 _id)
    public
    virtual
    override(IERC20PaymentStandard, ERC20PaymentStandard)
    whenNotPaused
    onlyRole(Role.bonds)
    returns (uint256 principal, address borrower)
  {
    Loan.loan memory ln = _loanLookup[_id];
    usersCollateral[ln.borrower].updateCollateral(ln);

    (uint256 ltv, uint256 lt,) = getDataFromOracle(ln.nfcsID, ln.ERC20Address, false);

    LoanValueLimitsById[_id] = 
      LoanValueLimits({
          ltv: ltv,
          lt: lt
        });

    (principal, borrower) = super.issueBonds(_id);
    PricedLoanInfo memory infoHolder = pricedLoanInfo(_id);

    require(
      isWithinLimit(infoHolder.collateralUSD, infoHolder.outstandingUSD, infoHolder.ltv), 
      Errors.PAYMENT_NOT_ENOUGH_COLLATERAL
    );
  }

    /*
     * @notice function for user to claim their collateral as they go. Must be within their LTV
     * @param _id ...
     * @param _amount to withdrawal
     */
    function claimCollateral(address _token, uint256 _amount, string memory version) 
      external 
      override 
      checkVersion(version)
      whenNotPaused
    {
      collateralManager().withdrawal(msg.sender, _amount, msg.sender);
  
      for(uint i = 0; i < usersActiveLoans[msg.sender].length; i++){
        // only perform check if the token is != 0 address, which would mean it was a deleted loan
        if(_loanLookup[usersActiveLoans[msg.sender][i]].ERC20Address != address(0)){
          require (!isDelinquent(usersActiveLoans[msg.sender][i]),"Cannot claim collateral if this collateral is necessary for any non Closed/Liquidated loan's delinquency status");
        }
      }

        emit CollateralWithdrawn(
          block.timestamp,
          msg.sender,
          _token,
          _amount
        );
    }

    /**
     * @notice override isDelinquent to factor in LTV
     * @dev returns false if the outstanding balance / collateral is >= LTV for the user at the time of calling
     * @param _id is the loan id
     * @return a bool representing if the loan does not have sufficient collateral OR has missed payments
     */
    function isDelinquent(uint256 _id)
        public
        view
        override(IERC20PaymentStandard, ERC20PaymentStandard)
        returns (bool)
    {
        // if missed payments
        if (super.isDelinquent(_id)) {
            return true;
        }

        PricedLoanInfo memory infoHolder = pricedLoanInfo(_id);
        if (!isWithinLimit(infoHolder.collateralUSD, infoHolder.outstandingUSD, infoHolder.lt)) {
            return true;
        } else {
            return false;
        }
    }
    
    /**
     * @dev a useful little function to get the loan's priced info via oracles
     * @param _id loan ID
     * NOTE returns are in order
     * @return Object containing collateral value in USD, outstanding value in USD, Roci score for the loan's NFCS ID, LTV
     */
    function pricedLoanInfo(uint256 _id)
        private
        view
        returns (PricedLoanInfo memory)
    {
        Loan.loan memory ln = _loanLookup[_id];
        PricedLoanInfo memory infoHolder;

        (address erc20Contract, uint256 collateral) = collateralManager()
            .getCollateralLookup(address(this), ln.borrower);

        (infoHolder.ltv, infoHolder.lt, infoHolder.score) = getDataFromOracle(ln.nfcsID, ln.ERC20Address, true);

        (int256 price, uint8 feederDecimals) = _safeGetPriceOf(erc20Contract);
        
        int8 decimalsDifference = int8(IERC20Metadata(erc20Contract).decimals()) - int8(IERC20Metadata(ln.ERC20Address).decimals());
        
        infoHolder.collateralUSD = calculateCollateralUSD(collateral, price, decimalsDifference, feederDecimals);

        (address[] memory tokens,) = usersCollateral[ln.borrower].toArrays();
        
        infoHolder.outstandingUSD = 0;
        // add up the outstanding USD value of all the tokens the user is borrowing
        for(uint i = 0; i < tokens.length; i++){
            uint256 tempID = usersActiveLoans[ln.borrower][i];

            (int256 _price, uint8 _feederDecimals) = _safeGetPriceOf(_loanLookup[tempID].ERC20Address);

            infoHolder.outstandingUSD += ( _price * int256(_loanLookup[tempID].getOutstanding())) / int256(10 ** uint256(_feederDecimals));           
        }

        return (infoHolder);
    }

    /**
     * @dev a function that calculates collateral equivalent in USD
     * @param collateralValue collateral which need to calculate
     * @param price price of collateral in USD from priceFeed
     * @param decimalsDifference diffrence between desimals of collateral contract and asset contract
     * @param feederDecimals decimals of data feeder from priceFeed
     * @return int256 value of USD equivalent of given collateral
     */
  function calculateCollateralUSD(uint256 collateralValue, int256 price, int8 decimalsDifference, uint8 feederDecimals) internal pure returns(int256){
        int256 collateralUSD = (( price * int256(collateralValue) ) / int256(10 ** uint256(feederDecimals)));

        if (decimalsDifference > 0){
          collateralUSD /= int256(10 ** uint8(decimalsDifference));
        }else if(decimalsDifference < 0){
          collateralUSD *= int256(10 ** uint8(-decimalsDifference));
        }
        return collateralUSD;
  }

  /**
  * @dev sometimes the priceFeed errors when looking up a token that ins't registered in the price feed.
  * Sometimes it shouldn't revert, instead we just have it return 0
   */
  function _safeGetPriceOf(address _tokenToGetPrice) internal view returns(int256 tempPrice, uint8 decimals){
    IPriceFeed priceFeedc = IPriceFeed(lookup(Role.priceFeed));
    // if there's an error looking up price then it's worth nothing
    try priceFeedc.getLatestPriceUSD(_tokenToGetPrice) returns(int256 _price, uint8 _decimals){
      tempPrice = _price;
      decimals = _decimals;
    }catch{
      revert(Errors.PRICE_FEED_TOKEN_NOT_SUPPORTED);
    }

  }

  /**
  * @dev liquidate function callable by bond holders
   */
  function liquidate(uint256 _id, address _receiver) external virtual override {
    IBonds bonds = IBonds(lookup(Role.bonds));
    require(bonds.balanceOf(msg.sender, _id) >= 0, Errors.PAYMENT_NO_BONDS);
    _liquidate(_id, _receiver);
  }

  /**
    * @dev function handle liqidation logic. can be overriden to have more logic
    */
  function _liquidate(uint256 _id, address _receiver) internal virtual {
      (, uint256 amount) = collateralManager()
        .getCollateralLookup(
          address(this),
          _loanLookup[_id].borrower
      );

      Loan.onLiquidate(_loanLookup[_id]);

      collateralManager().withdrawal(_loanLookup[_id].borrower, amount, _receiver);
  }

  /**
  * @dev return true if outstanding balance / collateral > parameter or just 0 if collateralUSD = 0
  *      parameter is LT or LTV
  */
  function isWithinLimit(
    int256 collateralUSD,
    int256 outstandingUSD,
    uint256 parameter
  ) 
    internal pure returns (bool) 
  {
    return collateralUSD == 0 ? false : 
      ((outstandingUSD * int256(ONE_HUNDRED_PERCENT)) / collateralUSD <= int256(parameter));
  }

    /**
    * @dev function hook to execute every time a loan is changed
     */
  function _afterLoanChange(Loan.loan memory _ln, uint256 _id)
    internal
    virtual
    override
  {
    if(_ln.status != Loan.Status.UNISSUED){
        usersCollateral[_ln.borrower].updateCollateral(_ln);
    }
    // if loan is new push it to the array of active loans
    if (_ln.status == Loan.Status.NEW) {
      usersActiveLoans[_ln.borrower].push(_id);
      // if it is not closed or liquidated remove it from the array
    } else if (
      _ln.status == Loan.Status.CLOSED || _ln.status == Loan.Status.LIQUIDATED
    ) {
      // find the loan by looping through the entire array
      for (uint256 i = 0; i < usersActiveLoans[_ln.borrower].length; i++) {
        // once finding it, delete it (sets value to 0) and return
        if (usersActiveLoans[_ln.borrower][i] == _id) {
          delete usersActiveLoans[_ln.borrower][i];
          return;
        }
      }
    }
  }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC20CollateralPayment.sol";
/**
 * @title IRociPayment
 * @author Carson Case
 * @dev 
 * Anything specific to Roci should be in this contract if we choose to use it such as Ownable logic and onlyOwner 
 * functions, whitelists and global limits.
*/
interface IRociPayment is IERC20CollateralPayment {
    /**
     * @dev function for admin to liquidate a loan manually
     */
    function liquidateByAdmin(uint256 _id) external;


}

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;
string constant NFCS_VERSION = "1.0.0";
string constant POOL_INVESTOR_VERSION = "1.0.0";
string constant ROCI_PAYMENT_VERSION = "1.0.0";

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

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;
uint constant ONE_HUNDRED_PERCENT = 100 ether;      // NOTE This CAN NOT exceed 2^256/2 -1 as type casting to int occurs

uint constant ONE_YEAR = 31556926;
uint constant ONE_DAY = 60*60*24;
uint constant APY_CONST = 3000000000 gwei;


address constant DEAD = 0x000000000000000000000000000000000000dEaD;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/Structs.sol";
import "./IScoreConfigs.sol";

/// @notice Interface for the ScoreDB contract.

interface ScoreDBV2Interface is IScoreConfigs {
    // Returns the current scored for the token from the on-chain storage.
    function getScore(uint256 tokenId)
        external
        view
        returns (Structs.Score memory);

    // Called by the lending contract, initiates logic to update score and fulfill loan.
    function pause() external;

    // UnPauses the contract [OWNER]
    function unpause() external;
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import { DEAD, ONE_HUNDRED_PERCENT } from "../Globals.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/Loan.sol";
import {NFCSInterface} from "../NFCS/NFCSInterface.sol";
import { ScoreDBV2Interface } from "../interfaces/ScoreDBV2Interface.sol";
import {IERC20PaymentStandard} from "../interfaces/newInterfaces/payment/IERC20PaymentStandard.sol";
import {Version} from "../Version/Version.sol";
import {Errors} from "../libraries/Errors.sol";
import "../utilities/AddressHandler.sol";

/**
 * @title ERC20PaymentStandard
 * @author Carson Case
 * @notice This contract is a standard meant to be overriden that works with the Bonds contract to offer noncolateralized, flexable lending onchain
 */
abstract contract ERC20PaymentStandard is
  IERC20PaymentStandard,
  AddressHandler,
  Pausable,
  Version
{
  using SafeERC20 for IERC20Metadata;
  // Two mappings. One to get the loans for a user. And the other to get the the loans based off id

  mapping(uint256 => Loan.loan) internal _loanLookup;
  // note 0x0 maps to the contract global for all loans
  mapping(address => Loan.globalInfo) internal globalLoanLookup;

  mapping(uint => Loan.globalInfo) internal nfcsLoanLookup;

  mapping(address => uint256[]) public loanIDs;

  uint256 public override MAXIMUM_BORROW_LIMIT;
  string public override investorsAddressLookupCategory;
  // Events
  event LoanRepaid(
    uint256 timestamp,
    address indexed borrower,
    address indexed repayer,
    uint256 indexed loanId,
    uint256 principal,
    uint256 amountRepaid,
    Loan.Status status
  );

  constructor(IAddressBook _addressBook)
    AddressHandler(_addressBook, "NewDeploy")
  {}

  /// @notice requires contract is not paid off
  modifier incomplete(uint256 _id) {
    require(!isComplete(_id), Errors.PAYMENT_FULFILLED);
    _;
  }

  function loanLookup(uint256 _id)
    external
    view
    override
    returns (Loan.loan memory)
  {
    return _loanLookup[_id];
  }

  /**
   * @notice called when bonds are issued so as to make sure lender can only mint bonds once.
   * @param _id loan ID
   * @return the loan principal (so bonds knows how many NFTs to mint)
   * @return the borrowers address (so bonds can make sure borrower is calling this function)
   */
  function issueBonds(uint256 _id)
    public
    virtual
    override
    whenNotPaused
    onlyRole(Role.bonds)
    returns (uint256, address)
  {
    Loan.loan storage ln = _loanLookup[_id];
    uint NFCSID=ln.nfcsID;
    Loan.issue(ln, globalLoanLookup[ln.borrower], globalLoanLookup[address(0)], nfcsLoanLookup[NFCSID]);
    _afterLoanChange(ln, _id);


    NFCSInterface nfcs = NFCSInterface(lookup(Role.NFCS));
    (uint128 dailyLimit,uint128 globalLimit,uint128 userDailyLimit,uint128 userGlobalLimit) = nfcs.getLimits();
    (,uint128 nfcsGlobalLimit) = nfcs.getNFCSLimits(NFCSID);
    (uint gloablOutstanding,uint userOutstanding,uint nfcsOutstanding) = nfcs.getTotalOutstanding(NFCSID);
    // preform the check on daily and global limit with the total outstanding balance looked up
    Loan.limitDailyCheck(
      ln, globalLoanLookup[ln.borrower], 
      userDailyLimit,
      Errors.LOAN_DAILY_LIMIT_USER
      );
    if (nfcsGlobalLimit!=0) {
    Loan.limitGlobalCheck(
      nfcsOutstanding,
      nfcsGlobalLimit,
      Errors.LOAN_TOTAL_LIMIT_NFCS
      );

    } else {
    Loan.limitGlobalCheck(
      userOutstanding,
      userGlobalLimit,
      Errors.LOAN_TOTAL_LIMIT_USER
      );
    }

    Loan.limitDailyCheck(
      ln, globalLoanLookup[address(0)], 
      dailyLimit,
      Errors.LOAN_DAILY_LIMIT
      );  
    Loan.limitGlobalCheck(
      gloablOutstanding,
      globalLimit,
      Errors.LOAN_TOTAL_LIMIT
      );
    return (ln.principal, ln.borrower);
  }



  /**
   * @notice gets the number of loans a person has
   * @param _who is who to look up
   * @return length
   */
  function getNumberOfLoans(address _who)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return loanIDs[_who].length;
  }

  /**
   * @notice Called each time new NFTs are minted by staking
   * @param _am the amount of interest to add
   * @param _id is the id of the loan
   * @return true if added. Will not add interest if payment has been completed.
   *This prevents lenders from refusing to end a loan when it is rightfully over by forever
   *increasing the totalPaymentsValue through interest staking and never fully collecting payment.
   *This also means that if lenders do not realize interest gains soon enough they may not be able to collect them before
   *the borrower can complete the loan.
   */
  function addInterest(uint256 _am, uint256 _id)
    external
    virtual
    override
    whenNotPaused
    onlyRole(Role.bonds)
    returns (bool)
  {
    if (!isComplete(_id)) {
      Loan.increaseTotalPaymentsValue(
        _loanLookup[_id],
        globalLoanLookup[_loanLookup[_id].borrower],
        globalLoanLookup[address(0)],
        nfcsLoanLookup[_loanLookup[_id].nfcsID],
        _am,
        addressBook.penaltyAPYMultiplier()
      );
      _afterLoanChange(_loanLookup[_id], _id);
      return true;
    } else {
      return false;
    }
  }

  /**
   * @notice This contract is not very forgiving. Miss one payment and you're marked as delinquent. Unless contract is complete
   * @param _id is the hash id of the loan. Same as bond ERC1155 ID as well
   * @return if delinquent or not. Meaning missed a payment
   */
  function isDelinquent(uint256 _id)
    public
    view
    virtual
    override
    returns (bool)
  {
    return (_isLate(_id) &&
      block.timestamp >= _loanLookup[_id].maturityDate + addressBook.gracePeriod());
  }

  /**
   * @notice contract must be configured before bonds are issued. Pushes new loan to array for user
   * @dev borrower is msg.sender for testing. In production might want to make this a param
   * @param _erc20 is the ERC20 contract address that will be used for payments
   * @param _borrower is the borrower loan is being configured for. Keep in mind. ONLY this borrower can mint bonds to start the loan
   * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
   * @param _minPayment is the minimum payment that must be made before the payment period ends
   * @param _maturityDate payment must be made by this time or delinquent function will return true
   * @param _principal the origional loan value before interest
   * @param _interestRate the interest rate expressed as inverse. 2% = 1/5 = inverse of 5
   * @param _accrualPeriod the time it takes for interest to accrue in seconds
   * @return the id it just created
   */
  function configureNew(
    address _erc20,
    address _borrower,
    uint256 _minPayment,
    uint256 _NFCSID,
    uint256 _maturityDate,
    uint256 _principal,
    uint256 _interestRate,
    uint256 _accrualPeriod
  ) external virtual override whenNotPaused returns (uint256) {
    require(
      IERC721(lookup(Role.NFCS)).ownerOf(_NFCSID) == _borrower,
      Errors.PAYMENT_NFCS_OWNERSHIP
    );
    //Create new ID for the loan
    uint256 id = getId(_borrower, loanIDs[_borrower].length);
    //Push to loan IDs
    loanIDs[_borrower].push(id);
    // Grab LTV and LT for this tokenId's score
    ScoreDBV2Interface oracle = ScoreDBV2Interface(lookup(Role.oracle));
    uint LTV = oracle.LTV(_erc20, oracle.getScore(_NFCSID).creditScore);
    uint LT = oracle.LT(_erc20, oracle.getScore(_NFCSID).creditScore);

    //Add loan info to lookup
    _loanLookup[id] = Loan.loan({
      status: Loan.Status.NEW,
      ERC20Address: _erc20,
      borrower: _borrower,
      nfcsID: _NFCSID,
      maturityDate: _maturityDate,
      issueDate: 0,
      minPayment: _minPayment,
      interestRate: _interestRate,
      accrualPeriod: _accrualPeriod,
      principal: _principal,
      totalPaymentsValue: _principal, //For now. Will update with interest updates
      awaitingCollection: 0,
      paymentComplete: 0,
      ltv: LTV,
      lt: LT
    });
    _afterLoanChange(_loanLookup[id], id);
    return id;
  }

  /**
   * @notice MUST approve this contract to spend your ERC1155s in bonds. Used to have this auto handled by the on received function.
   * However that was not a good idea as a hacker could create fake bonds.
   * @param _id is the id of the bond to send in
   * @param _am is the amount to send
   * @param _receiver is the receiver of erc20 tokens
   */
  function withdrawl(
    uint256 _id,
    uint256 _am,
    address _receiver
  ) external virtual override whenNotPaused {
    uint256 awaitingCollectionBeforeChange = _loanLookup[_id]
      .awaitingCollection;
    Loan.loan storage ln = _loanLookup[_id];
    Loan.onWithdrawal(
      ln,
      globalLoanLookup[_loanLookup[_id].borrower],
      globalLoanLookup[address(0)],
      nfcsLoanLookup[_loanLookup[_id].nfcsID],
      _am
    );
    _afterLoanChange(ln, _id);
    IERC1155 Bonds = IERC1155(lookup(Role.bonds));
    IERC20Metadata erc20 = IERC20Metadata(_loanLookup[_id].ERC20Address);
    require(
      _loanLookup[_id].status != Loan.Status.UNISSUED,
      Errors.PAYMENT_NON_ISSUED_LOAN
    );
    require(
      _am <= awaitingCollectionBeforeChange,
      Errors.PAYMENT_WITHDRAWAL_COLLECTION
    );
    Bonds.safeTransferFrom(_receiver, DEAD, _id, _am, "");
    erc20.safeTransfer(_receiver, _am);
  }

  /**
   * @notice function handles the payment of the loan. Does not have to be borrower
   *as payment comes in. The contract holds it until collection by bond owners. MUST APPROVE FIRST in ERC20 contract first
   * @param _id to pay off
   * @param _erc20Amount is amount in loan's ERC20 to pay
   */
  function payment(uint256 _id, uint256 _erc20Amount, string memory version)
    external
    virtual
    override
    whenNotPaused
    checkVersion(version)
    incomplete(_id)
  {
    Loan.loan storage ln = _loanLookup[_id];

    require(_erc20Amount<=ln.totalPaymentsValue, Errors.PAYMENT_AMOUNT_TOO_LARGE);
    
    Loan.onPayment(
      ln,
      globalLoanLookup[_loanLookup[_id].borrower],
      globalLoanLookup[address(0)],
      nfcsLoanLookup[_loanLookup[_id].nfcsID],
      _erc20Amount
    );
    _afterLoanChange(ln, _id);

    IERC20Metadata(ln.ERC20Address).safeTransferFrom(
      msg.sender,
      address(this),
      _erc20Amount
    );

    emit LoanRepaid(
      block.timestamp,
      _loanLookup[_id].borrower,
      msg.sender,
      _id,
      _loanLookup[_id].principal,
      _erc20Amount,
      _loanLookup[_id].status
    );
  }

  /**
   * @notice helper function
   * @param _id of loan to check
   * @return return if the contract is payed off or not as bool
   */
  function isComplete(uint256 _id) public view virtual override returns (bool) {
    return Loan.isComplete(_loanLookup[_id]);
  }

  /**
   * @notice Returns the ID for a loan given the borrower and index in the array
   * @param _borrower is borrower
   * @param _index is the index in the borrowers loan array
   * @return the loan ID
   */
  //
  function getId(address _borrower, uint256 _index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    uint256 id = uint256(
      keccak256(abi.encodePacked(address(this), _borrower, _index))
    );
    return id;
  }

  function getGlobalDailyBorrowedAmount()
    public
    view
    returns (uint128)
  {
    return globalLoanLookup[address(0)].borrowedToday;
  }

    /**
   * @notice Returns borrowed daily amount for user
   * @param _borrower address
   * @return borrowedAmount
   */
  //
  function getUserDailyBorrowedAmount(address _borrower)
    public
    view
    returns (uint128)
  {
    Loan.globalInfo memory user = globalLoanLookup[address(_borrower)];
    if ((block.timestamp - user.lastBorrowTimestamp) >= ONE_DAY) {
      return 0;
    }
    return user.borrowedToday;
  }

  /**
   * @dev this is a function to return if a loan is late on payments
   * @param _id is the loan id
   * @return true or false
   */
  function _isLate(uint256 _id) internal view virtual returns (bool) {
    return (Loan.isLate(_loanLookup[_id]) && !isComplete(_id));
  }

  /**
   * @dev function hook to execute every time a loan is changed
   */
  function _afterLoanChange(Loan.loan memory _ln, uint256 _id)
    internal
    virtual
  {}

  /**
   * @dev function hook to execute every time a loan is changed
   */
  function _afterLoanChange(Loan.loan memory _ln) internal virtual {}

  function pause() public onlyRole(Role.admin) {
    _pause();
  }

  function unpause() public onlyRole(Role.admin) {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPriceFeed{
    function getLatestPriceUSD(address) external view returns (int, uint8);
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBonds is IERC1155{
    function IDToContract(uint256) external returns(address);

    function head() external returns(uint256);

    function llTail(address) external returns(uint256);
    
    function getStakingAt(address, uint256) external view returns(uint, uint, uint256, uint256, uint256);

    function newLoan(address, uint256, bytes32, bytes memory) external;
    
    function stake(uint256, uint256) external returns(uint);

    function unstake(uint256) external returns(bool);    

    function getAccruances(address, uint256) external view returns(uint256);

    function getInterest(address, uint256, uint256, uint256) external view returns(uint256);

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IManager.sol";


/**
 * @title ICollateralManager
 * @author Carson Case
 * @notice A contract to manage the collateral of the Roci protocol
 * @dev the overrides of deposit/withdrawal will probably need to use data to store the loan ID
 */
interface ICollateralManager is IManager {


    /**
    * @dev function to return the ERC20 contract AND amount for a collateral deposit
    * @param _paymentContract address
    * @param _user of borrower
    * @return ERC20 contract address of collateral
    * @return Collateral amount deposited
     */
    function getCollateralLookup(address _paymentContract,  address _user)
        external
        view
        returns (address, uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct Score {
        uint256 tokenId;
        uint256 timestamp;
        uint16 creditScore;
    }

    /**
        * @param _amount to borrow
        * @param _duration of loan in seconds
        * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
        * @param _collateralAmount is the amount of collateral to send in
        * @param _collateral is the ERC20 address of the collateral
        * @param _hash is the hash of this address and the loan ID. See Bonds.sol for more info on this @newLoan()
        * @param _signature is the signature of the data hashed for hash
    */
    struct BorrowArgs{
        uint256 _amount;
        uint256 _NFCSID;
        uint256 _collateralAmount;
        address _collateral;
        bytes32 _hash;
        bytes _signature;
    }

    /// @notice collateral info is stored in a struct/mapping pair
    struct collateral {
        uint256 creationTimestamp;
        address ERC20Contract;
        uint256 amount;
    }

    // Share struct that decides the share of each address
    struct Share{
        address payee;
        uint share;
    }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Loan.sol";

/**
* @title Tracker
* @author Carson Case ([email protected])
* @dev V1 untested
*   The linked list this relies on was written by hand for this since the OZ one only works with uint -> address
*   so hopefully there's no issues with it
 */
library Tracker{

  address constant TAIL = 0x000000000000000000000000000000000000dEaD;
  struct node{
    address next;
    uint val;
  }
  // each object contains an enumerable map of payment token addresses => outstanding balance
  struct outstandings{
    address head;
    uint length;
    mapping(address => node) tokenToLoan;
  }

  function updateCollateral(outstandings storage c, Loan.loan memory ln) internal{
    // if this is the first time this token is input push it to the list of tokens
    // meaning if next points to 0 but it's not just the first element
    if(c.tokenToLoan[ln.ERC20Address].next == address(0)){
      _push(c, ln.ERC20Address);
    }
    
    // then update the value
    c.tokenToLoan[ln.ERC20Address].val = Loan.getOutstanding(ln);
  }

  function toArrays(outstandings storage c) internal view returns(address[] memory tokens, uint[] memory amounts){
    address tmp = (c.head == address(0)) ? TAIL : c.head;
    tokens = new address[](c.length);
    amounts = new uint[](c.length);

    for(uint i = 0; i < c.length; i++){
      tokens[i] = tmp;
      amounts[i] = c.tokenToLoan[tmp].val;
      tmp = c.tokenToLoan[tmp].next;

    }
  }

  function _push(outstandings storage c, address key) private{
    if(c.head == address(0)){
      c.head = key;
      c.tokenToLoan[key].next = TAIL;
    }else{
      c.tokenToLoan[key].next = c.head;
      c.head = key;
    }
    c.length++;
  }

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import {IVersion} from "./IVersion.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title  Abstract contract for implementing versioning functionality
/// @author Konstantin Samarin
/// @notice Used to mark backwards-incompatible changes to the contract logic.
///         checkVersion modifier should be applied to all external mutating methods

abstract contract Version is IVersion {
    /**
     * @notice converts string to bytes32
     */
    function getVersionAsBytes(string memory v) public pure override returns (bytes32 result) {
        if (bytes(v).length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(v, 32))
        }
    }

    /**
     * @notice 
     * Controls the call of mutating methods in versioned contract.
     * The following modifier reverts unless the value of the `versionToCheck` argument
     * matches the one provided in currentVersion method.
     */
    modifier checkVersion(string memory versionToCheck) {
        require(
            getVersionAsBytes(this.currentVersion()) == getVersionAsBytes(versionToCheck),
            Errors.VERSION
        );
        _;
    }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC20PaymentStandard.sol";
import "../../../Version/IVersion.sol";

/**
 * @title IERC20PaymentStandard
 * @author Carson Case
 * @dev 
 * ERC20CollateralPayment should only deal with adding collateral to the existing payment system. 
 * CollateralPayment changes the definition of delinquent loans to be loans that don’t meat LTV/LT requirements 
 * as defined by a loan’s NFCS. Collateral payment also allows for liquidations by liquidators. 
 * However, collateralPayment does not hold any collateral and instead delegates the holding of collateral to a manager. 
 * CollateralPayment only handles logic for collateral and it’s relation to a loan’s status. 
*/
interface IERC20CollateralPayment is IVersion, IERC20PaymentStandard {
    // more addresses for address book
    enum addresses_Collateral{
        bondContract,
        NFCS,
        collateralManager,
        priceFeed,
        oracle
    }

    // addresses removed in favor of addressBook.

    /**
     * @notice addCollateral must be called before issuing loan
     * @param _ERC20Contract address of the ERC20 you want to have as collaterall. DOES NOT have to be equal to payment ERC20
     * @param _amount is the ammount to add as collateral
     */
    function addCollateral(
        address _from,
        address _ERC20Contract,
        uint256 _amount
    ) external;

    // NOTE no need for changing manager or price feed since they're in addressBook

    /**
    * @dev liquidate function callable by bond holders
    */
    function liquidate(uint256 _id, address _receiver) external;

    /*
     * @notice function for user to claim their collateral as they go. Must be within their LTV
     * @param _token to collect
     * @param _amount to withdrawal
     */
    function claimCollateral(address _token, uint256 _amount, string memory version) external;

    // NOTE removed liquidate by admin

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title ScoreConfigs
* @author Carson Case ([email protected])
* @dev abstract contract to hold information the scores translate too such as LTV and LV
 */
interface IScoreConfigs{
    function LTV(address _token, uint16 _score) external view returns(uint256);

    function LT(address _token, uint16 _score) external view returns(uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {ONE_DAY} from "../Globals.sol";
import {Errors} from "../libraries/Errors.sol";
/**
* @title Loan
* @author Carson Case
* @dev Library to abstract out edits to Loan object to help with global variable tracking
    NOTE
    In this library the function paramaters may seem confusing
    This is because there are special global/local instances of these loan objects

    _ln is an individual loan
    _user is a user's global amount in this payment contract
    _global is the payment contracts total sums
 */
library Loan{
   
    //Loan object. Stores lots of info about each loan
    enum Status{UNISSUED, NEW, APPROVED, PAIDPART, CLOSED, PAIDLATE, LIQUIDATED}
    struct loan {
        Status status;
        address ERC20Address;
        address borrower;
        uint256 nfcsID;
        uint256 maturityDate;
        uint128 issueDate;
        uint256 minPayment;
        uint256 interestRate;
        uint256 accrualPeriod;
        uint256 principal;
        uint256 totalPaymentsValue;
        uint256 awaitingCollection;
        uint256 paymentComplete;
        uint256 ltv;
        uint256 lt;
    }

    struct globalInfo{
        uint256 principal;
        uint256 totalPaymentsValue;
        uint256 awaitingCollection;
        uint256 paymentComplete;
        uint128 borrowedToday;
        uint128 lastBorrowTimestamp;
    }


    /**
    * @dev onPayment function to check and handle updates to struct for payments
    * @param _ln individual loan
    * @param _user global loan for user
    * @param _global global loan for the whole contract
     */
    function onPayment(loan storage _ln, globalInfo storage _user, globalInfo storage _global, globalInfo storage _nfcs, uint _erc20Amount) internal{
        require(
            _erc20Amount >= _ln.minPayment || //Payment must be more than min payment
                (
                getOutstanding(_ln) < _ln.minPayment  //Exception for the last payment (remainder)
                &&
                _erc20Amount >= getOutstanding(_ln)  // Exception is only valid if user is paying the loan off in full on this transaction
                ),
            Errors.LOAN_MIN_PAYMENT
        );

        _ln.awaitingCollection += _erc20Amount;
        _user.awaitingCollection += _erc20Amount;
        _global.awaitingCollection += _erc20Amount;
        _nfcs.awaitingCollection += _erc20Amount;


        _ln.paymentComplete += _erc20Amount; //Increase paymentComplete
        _user.paymentComplete += _erc20Amount;
        _global.paymentComplete += _erc20Amount;
        _nfcs.paymentComplete += _erc20Amount;

        // do a status update for anything payment dependant
        if(isComplete(_ln)){
            _ln.status = Status.CLOSED;
        }else if(_erc20Amount > 0 && !isLate(_ln)){
            _ln.status = Status.PAIDPART;
        } else if(isLate(_ln)){
            _ln.status = Status.PAIDLATE;
        }

        _updateLoanDay(_user);
        _updateLoanDay(_global);
    }

    function onWithdrawal(loan storage _ln, globalInfo storage _user, globalInfo storage _global, globalInfo storage _nfcs, uint _erc20Amount) internal{
        _ln.awaitingCollection -= _erc20Amount;
        _user.awaitingCollection -= _erc20Amount;
        _global.awaitingCollection -= _erc20Amount;
        _nfcs.awaitingCollection -= _erc20Amount;
    }

    function onLiquidate(loan storage _ln) internal{
        _ln.status = Status.LIQUIDATED;
    }


    function limitGlobalCheck(uint _totalOutstanding,  uint128  _limit,  string memory exeption) pure internal{
        if(_limit != 0) {
            require(_totalOutstanding <= _limit, exeption);
        }
    }        


    function limitDailyCheck(loan storage _ln, globalInfo storage _limitInfo, uint128  _limit, string memory exeption) internal{
        if(_limit != 0) {
            _updateLoanDay(_limitInfo);
            require(_limitInfo.borrowedToday + _ln.principal <= _limit, exeption);
            _limitInfo.borrowedToday += uint128(_ln.principal);
        }
    }


    /**
    * @dev function increases the total payment value on the loan for interest accrual
    * @param _ln individual loan
    * @param _user global loan for user
    * @param _global global loan for the whole contract
     */

    function increaseTotalPaymentsValue(loan storage _ln, globalInfo storage _user, globalInfo storage _global, globalInfo storage _nfcs, uint _am, uint penaltyAPYMultiplier) internal{
        // if loan is late we give an APR multiplier
        if(isLate(_ln)){
            _ln.interestRate = _ln.interestRate * penaltyAPYMultiplier;
        }

        _ln.totalPaymentsValue += _am;
        _user.totalPaymentsValue += _am;
        _global.totalPaymentsValue += _am;
        _nfcs.totalPaymentsValue += _am;

    }

    /// @dev function to issue a loan
    function issue(loan storage _ln, globalInfo storage _user, globalInfo storage _global, globalInfo storage _nfcs) internal{
        require(
            _ln.status == Status.NEW,
            Errors.LOAN_CONFIGURATION
        );

        _ln.status = Status.APPROVED;
        _ln.issueDate = uint128(block.timestamp);

        _user.principal += _ln.principal;
        _user.totalPaymentsValue += _ln.totalPaymentsValue;
        _user.awaitingCollection += _ln.awaitingCollection;
        _user.paymentComplete += _ln.paymentComplete;

        _global.principal += _ln.principal;
        _global.totalPaymentsValue += _ln.totalPaymentsValue;
        _global.awaitingCollection += _ln.awaitingCollection;
        _global.paymentComplete += _ln.paymentComplete;

        _nfcs.principal += _ln.principal;
        _nfcs.totalPaymentsValue += _ln.totalPaymentsValue;
        _nfcs.awaitingCollection += _ln.awaitingCollection;
        _nfcs.paymentComplete += _ln.paymentComplete;

    }

    /// @dev helper function returns if loan is complete
    function isComplete(loan storage _ln) internal view returns (bool) {
        return
            _ln.paymentComplete >=
            _ln.totalPaymentsValue;
    }

    /// @dev function returns if loan is late
    function isLate(loan storage _ln) internal view returns (bool) {
        return (block.timestamp >= _ln.maturityDate);
    }

    function getOutstanding(loan memory _ln) internal pure returns(uint){
        if(_ln.paymentComplete > _ln.totalPaymentsValue){
            return 0;
        }
        return(_ln.totalPaymentsValue - _ln.paymentComplete);
    }
    function getOutstanding(globalInfo memory _global) internal pure returns(uint){
        if(_global.paymentComplete > _global.totalPaymentsValue){
            return 0;
        }
        return(_global.totalPaymentsValue - _global.paymentComplete);
    }
    function _updateLoanDay(globalInfo storage _user) private{
        if((block.timestamp - _user.lastBorrowTimestamp) >= ONE_DAY){
            _user.borrowedToday = 0;
        }
        _user.lastBorrowTimestamp = uint128(block.timestamp);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IVersion} from "../Version/IVersion.sol";

interface NFCSInterface is IVersion {
    // Receives an address array, verifies ownership of addrs [WIP], mints a token, stores the bundle against token ID, sends token to msg.sender
    function mintToken(
        address[] memory bundle,
        bytes[] memory signatures,
        string memory _message,
        uint256 _nonce,
        string memory version
    ) external;

    // Receives a tokenId, returns corresponding address bundle
    function getBundle(uint256 tokenId)
        external
        view
        returns (address[] memory);

    // Receives an address, returns tokenOwned by it if any, otherwise reverts
    function getToken(address tokenOwner) external view returns (uint256);

    // Tells if an address owns a token or not
    function tokenExistence(address user) external view returns (bool);

    function getTotalOutstanding(uint _nfcsId) external view returns(uint,uint,uint);


    // function getUserAddressTotalOustanding(address _user) external view returns(uint);

    // function getGlobalTotalOustanding() external view returns(uint);

    function getLimits() external view returns(uint128, uint128,uint128, uint128);

    function getNFCSLimits(uint _nfcsId) external view returns(uint128, uint128);

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../../IAddressBook.sol";
import "../../../libraries/Loan.sol";
import {IVersion} from "../../../Version/IVersion.sol";

/**
 * @title IERC20PaymentStandard
 * @author Carson Case
 * @dev
 * Payment Standard is meant to be the bare minimum of payment logic required to interact with Bonds 
 * and the rest of the ecosystem. 
 * Payment contract should only have logic for starting loans (configure and issue), 
 * making payments, collecting interest, and retrieving getting loan info.
 *
 * There should also only be **one** Payment contract. The key difference here for Payment Standard is that it is no 
 * longer unique to each investor. And instead will share it’s logic with all of them. 
 * Payment Standard also should be marked abstract enforcing that it is inherited by it’s child.
 * This means removing all the limits logic and moving it to a child contract like collateral or a specific RociPayment contract.
 */
 
interface IERC20PaymentStandard is IVersion {
    // NOTE 154 Bonds.sol 
    // (uint256 interest, ) = pc.getLoanInfo(id);
    // this function is removed. Use loanLookup in Bonds

    // ---------------
    // State Variables
    // ---------------
    function MAXIMUM_BORROW_LIMIT() external returns(uint);
    
    // note addresses are replaced with address book
    // enum is the index in the array returned by addressBook's function
    enum addresses_Payment{
        bondContract,
        NFCS
    }

    function investorsAddressLookupCategory() external returns(string memory);

    // Two mappings. One to get the loans for a user. And the other to get the the loans based off id
    
    // note these are removed as they're mappings and mess with the inheritance. If needed replace with getter functions
    function loanLookup(uint _id) external view returns(Loan.loan memory);
    // function loanIDs(address) external returns(uint[] memory);


    /**
     * @notice called when bonds are issued so as to make sure lender can only mint bonds once.
     * @param _id loan ID
     * @return the loan principal (so bonds knows how many NFTs to mint)
     * @return the borrowers address (so bonds can make sure borrower is calling this function)
     */
    function issueBonds(uint256 _id)
        external
        returns (uint256, address);

    /**
     * @notice gets the number of loans a person has
     * @param _who is who to look up
     * @return length
     */
    function getNumberOfLoans(address _who)
        external
        view
        returns (uint256);

    /**
     * @notice Called each time new NFTs are minted by staking
     * @param _am the amount of interest to add
     * @param _id is the id of the loan
     * @return true if added. Will not add interest if payment has been completed.
     *This prevents lenders from refusing to end a loan when it is rightfully over by forever
     *increasing the totalPaymentsValue through interest staking and never fully collecting payment.
     *This also means that if lenders do not realize interest gains soon enough they may not be able to collect them before
     *the borrower can complete the loan.
     */
    function addInterest(uint256 _am, uint256 _id)
        external
        returns (bool);


    /**
     * @param _id is the hash id of the loan. Same as bond ERC1155 ID as well
     * @return if delinquent or not. Meaning missed a payment
     */
    function isDelinquent(uint256 _id) external view returns (bool);

    /**
     * @notice contract must be configured before bonds are issued. Pushes new loan to array for user
     * @param _erc20 is the ERC20 contract address that will be used for payments
     * @param _borrower is the borrower loan is being configured for. Keep in mind. ONLY this borrower can mint bonds to start the loan
     * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
     * @param _minPayment is the minimum payment that must be made before the payment period ends
     * @param _maturityDate payment must be made by this time or delinquent function will return true
     * @param _principal the origional loan value before interest
     * @param _interestRate the interest rate expressed as inverse. 2% = 1/5 = inverse of 5
     * @param _accrualPeriod the time it takes for interest to accrue in seconds
     * @return the id it just created
     */
    function configureNew(
        address _erc20,
        address _borrower,
        uint256 _minPayment,
        uint256 _NFCSID,
        uint256 _maturityDate,
        uint256 _principal,
        uint256 _interestRate,
        uint256 _accrualPeriod
    ) external returns (uint256);

    /**
     * @notice MUST approve this contract to spend your ERC1155s in bonds. Used to have this auto handled by the on received function.
     * However that was not a good idea as a hacker could create fake bonds.
     * @param _id is the id of the bond to send in
     * @param _amm is the amount to send
     * @param _receiver is the receiver of erc20 tokens
     */
    function withdrawl(
        uint256 _id,
        uint256 _amm,
        address _receiver
    ) external;

    /**
     * @notice function handles the payment of the loan. Does not have to be borrower
     *as payment comes in. The contract holds it until collection by bond owners. MUST APPROVE FIRST in ERC20 contract first
     * @param _id to pay off
     * @param _erc20Amount is amount in loan's ERC20 to pay
     */
    function payment(uint256 _id, uint256 _erc20Amount, string memory version)
        external;

    /**
     * @notice helper function
     * @param _id of loan to check
     * @return return if the contract is payed off or not as bool
     */
    function isComplete(uint256 _id) external view returns (bool);

    /**
     * @notice Returns the ID for a loan given the borrower and index in the array
     * @param _borrower is borrower
     * @param _index is the index in the borrowers loan array
     * @return the loan ID
     */
    //
    function getId(address _borrower, uint256 _index)
        external
        view
        returns (uint256);

    /**
    * @dev function to get a user's total outstanding balance (By NFCS ID)  
    * @param _nfcsId NFCS ID
    * @return total Oustanding balance
    */
    function getNFCSTotalOutstanding(uint _nfcsId) external view returns(uint);


    /**
    * @dev function to get a user's total outstanding balance (By NFCS ID)  
    * @param _nfcsId NFCS ID
    * @return total Oustanding balance
    */
    function getUserTotalOutstanding(uint _nfcsId) external view returns(uint);

 /**
    * @dev function to get a system total outstanding balance  
    * @return total Oustanding balance
    */
    function getTotalOutstanding() external view returns(uint);

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../interfaces/IAddressBook.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AddressHandler{
    string internal _category;
    enum Role{
        token,
        bonds,
        paymentContract,
        revManager,
        NFCS,
        collateralManager,
        priceFeed,
        oracle,
        admin
    }

    IAddressBook public addressBook;

    constructor(IAddressBook _addressBook, string memory _startingCategory){
        addressBook = _addressBook;
        _category = _startingCategory;
    }

    modifier onlyRole(Role _role){
        require(msg.sender == lookup(_role),
                string(
                    abi.encodePacked(
                        "AddressHandler: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        _;
    }

    function changeCateogory(string memory _newCategory) external onlyRole(Role.admin){
        _category = _newCategory;
    }

    function lookup(Role _role) internal view returns(address contractAddress){
        contractAddress = addressBook.addressList(_category)[uint(_role)];
        require(contractAddress != address(0), 
            string(
                abi.encodePacked("AddressHandler: lookup failed for role: ", 
                Strings.toHexString(uint256(_role), 32)
                )
            )
        );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/// @title  Interface for implementing versioning of contracts
/// @author Konstantin Samarin
/// @notice Used to mark backwards-incompatible changes to the contract logic.
///         All interfaces of versioned contracts should inherit this interface

interface IVersion {
    /**
     * @notice returns the current version of the contract
     */
    function currentVersion() external pure returns(string memory);

    /**
     * @notice converts string to bytes32
     */
    function getVersionAsBytes(string memory v) external pure returns (bytes32 result);
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IAddressBook{
    function addressList(string memory _category) external view returns(address[] memory);
    function dailyLimit() external  view returns (uint128);
    function globalLimit() external view returns (uint128);
    function setDailyLimit(uint128 newLimit) external;
    function setGlobalLimit(uint128 newLimit) external;
    function getMaturityDate() external view returns (uint256);
    function setLoanDuration(uint256 _newLoanDuration) external;

    function userDailyLimit() external  view returns (uint128);
    function userGlobalLimit() external view returns (uint128);
    function setUserDailyLimit(uint128 newLimit) external;
    function setUserGlobalLimit(uint128 newLimit) external;


    function globalNFCSLimit(uint _nfcsId) external view  returns (uint128);
    function setGlobalNFCSLimit(uint _nfcsId, uint128 newLimit) external;



    function latePenalty() external  view returns (uint);
    function scoreValidityPeriod() external view returns (uint);
    function setLatePenalty(uint newPenalty) external;
    function setScoreValidityPeriod(uint newValidityPeriod) external;

    function minScore() external  view returns (uint16);
    function maxScore() external view returns (uint16);
    function setMinScore(uint16 newScore) external;
    function setMaxScore(uint16 newScore) external;

    function notGenerated() external  view returns (uint16);
    function generationError() external view returns (uint16);
    function setNotGenerated(uint16 newValue) external;
    function setGenerationError(uint16 newValue) external;

    function penaltyAPYMultiplier() external  view returns (uint8);
    function gracePeriod() external view returns (uint128);
    function setPenaltyAPYMultiplier(uint8 newMultiplier) external;
    function setGracePeriod(uint128 newPeriod) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
pragma solidity ^0.8.0;

import {IAddressBook} from "../../IAddressBook.sol";

/**
* @title IManager
* @author Carson Case ([email protected])
* @dev base contract for other managers. Contracts that hold funds for others, keep track of the owners,
*   and also have accepted deposited fund types that can be updated.
 */
interface IManager{
    // function deposit(uint _amount, bytes memory _data) external;
    function deposit(address _from, address _erc20,  uint256 _amount) external;
    // function withdrawal(uint _amount, address _receiver, bytes memory _data) external;
    function withdrawal(address user, uint256 _amount, address _receiver) external;
    function addAcceptedDeposits(address[] memory) external;
    function removeAcceptedDeposits(address[] memory) external;
}