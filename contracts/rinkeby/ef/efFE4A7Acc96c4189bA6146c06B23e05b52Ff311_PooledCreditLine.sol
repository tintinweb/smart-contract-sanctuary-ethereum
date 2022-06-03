// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/SafeCast.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../Math.sol';
import '../interfaces/IPriceOracle.sol';
import '../interfaces/IYield.sol';
import '../interfaces/ISavingsAccount.sol';
import '../SavingsAccount/SavingsAccountUtil.sol';
import '../interfaces/IStrategyRegistry.sol';
import '../interfaces/ILenderPool.sol';
import '../interfaces/IVerification.sol';
import '../interfaces/IPooledCreditLine.sol';

/**
 * @title Pooled Credit Line contract with Methods related to creditLines
 * @notice Implements the functions related to Credit Line
 * @author Sublime
 **/

contract PooledCreditLine is ReentrancyGuardUpgradeable, OwnableUpgradeable, IPooledCreditLine {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //-------------------------------- Constants start --------------------------------//

    // number of seconds in an year
    uint256 internal constant YEAR_IN_SECONDS = 365 days;
    // Factor to multiply variables to maintain precision
    uint256 internal constant SCALING_FACTOR = 1e18;

    /**
     * @notice address of lender pool contract
     */
    ILenderPool public immutable LENDER_POOL;

    /**
     * @notice address of USDC token
     */
    address public immutable USDC;

    /**
     * @notice stores the address of savings account contract
     **/
    ISavingsAccount public immutable SAVINGS_ACCOUNT;

    /**
     * @notice stores the address of price oracle contract
     **/
    IPriceOracle public immutable PRICE_ORACLE;

    /**
     * @notice stores the address of strategy registry contract
     **/
    IStrategyRegistry public immutable STRATEGY_REGISTRY;

    /**
     * @notice address that the borrower for pooled credit line should be verified with
     **/
    IVerification public immutable VERIFICATION;

    //-------------------------------- Constants end --------------------------------//

    //-------------------------------- Global vars starts --------------------------------//
    /**
     * @notice stores the fraction of borrowed amount charged as fee by protocol
     * @dev it is multiplied by SCALING_FACTOR
     **/
    uint256 public protocolFeeFraction;

    /**
     * @notice maximimum protocol fee fraction
     */
    uint256 public immutable maximumProtocolFeeFraction;

    /**
     * @notice address where protocol fee is collected
     **/
    address public protocolFeeCollector;

    //-------------------------------- Global vars end --------------------------------//

    //-------------------------------- Variable limits starts --------------------------------//

    /*
     * @notice Used to define limits for the pooled credit line parameters
     * @param min the minimum threshold for the parameter
     * @param max the maximum threshold for the parameter
     */
    struct Limits {
        uint256 min;
        uint256 max;
    }

    /*
     * @notice Used to set the min/max borrow limits for pooled credit lines
     */
    Limits borrowLimitLimits;

    /*
     * @notice Used to set the min/max collateral ratio for pooled credit lines
     */
    Limits idealCollateralRatioLimits;

    /*
     * @notice Used to set the min/max borrow rate for pooled credit lines
     */
    Limits borrowRateLimits;

    /*
     * @notice Used to set the min/max collection period for pooled credit lines
     */
    Limits collectionPeriodLimits;

    /*
     * @notice Used to set the min/max duration of pooled credit lines
     */
    Limits durationLimits;

    /*
     * @notice Used to set the min/max grace period before default for pooled credit lines
     */
    Limits defaultGracePeriodLimits;

    /*
     * @notice Used to set the min/max Penalty rate during grace period for pooled credit lines
     */
    Limits gracePenaltyRateLimits;

    //-------------------------------- Variable limits ends --------------------------------//

    //-------------------------------- CreditLine state starts --------------------------------//

    /**
    * @notice Struct to store all the variables for a pooled credit line
    * @param status Represents the status of pooled credit line
    * @param principal total principal borrowed in pooled credit line
    * @param totalInterestRepaid total interest repaid in the pooled credit line
    * @param lastPrincipalUpdateTime timestamp when principal was last updated. Principal is 
             updated on borrow or repay
    * @param interestAccruedTillLastPrincipalUpdate interest accrued till last time
             principal was updated
     */
    struct PooledCreditLineVariables {
        PooledCreditLineStatus status;
        uint256 principal;
        uint256 totalInterestRepaid;
        uint256 lastPrincipalUpdateTime;
        uint256 interestAccruedTillLastPrincipalUpdate;
    }

    /**
    * @notice Struct to store all the constants for a pooled credit line
    * @param borrowLimit max amount of borrowAsset that can be borrowed in aggregate at any point
    * @param borrowRate Rate of interest (multiplied by SCALING_FACTOR) for eg 8.25% becomes 8.25 / 1e2 * 1e18
    * @param idealCollateralRatio ratio of collateral to debt below which collateral is 
             liquidated (multiplied by SCALING_FACTOR)
    * @param borrower address of the borrower of credit line
    * @param borrowAsset address of asset borrowed in credit line
    * @param collateralAsset address of asset collateralized in credit line
    * @param collateralAssetStrategy address of the strategy into which collateral is deposited
    * @param startsAt timestamp at which pooled credit line starts
    * @param endsAt timestamp at which pooled credit line ends
    * @param defaultsAt timestamp at which pooled credit line defaults after grace period completes
    * @param borrowAssetStrategy strategy into which lent tokens are deposited
    * @param gracePenaltyRate rate at which penalty is levied during grace period (multiplied by SCALING_FACTOR)
     */
    struct PooledCreditLineConstants {
        uint128 borrowLimit;
        uint128 borrowRate;
        uint256 idealCollateralRatio;
        address borrower;
        address borrowAsset;
        address collateralAsset;
        uint256 startsAt;
        uint256 endsAt;
        uint256 defaultsAt;
        address borrowAssetStrategy;
        address collateralAssetStrategy;
        uint256 gracePenaltyRate;
    }

    /**
     * @notice counter that tracks the number of pooled credit lines created
     * @dev used to create unique identifier for pooled credit lines
     **/
    uint256 public pooledCreditLineCounter;

    /**
     * @notice stores the collateral shares in a pooled credit line per collateral strategy
     * @dev creditLineId => collateralShares
     **/
    mapping(uint256 => uint256) public depositedCollateralInShares;

    /**
     * @notice stores the variables to maintain a pooled credit line
     **/
    mapping(uint256 => PooledCreditLineVariables) public pooledCreditLineVariables;

    /**
     * @notice stores the constants related to a pooled credit line
     **/
    mapping(uint256 => PooledCreditLineConstants) public pooledCreditLineConstants;

    //-------------------------------- CreditLine State ends --------------------------------//

    //-------------------------------- Modifiers starts --------------------------------//

    /**
     * @dev checks if called by pooled credit Line Borrower
     * @param _id identifier for the pooled credit line
     **/
    modifier onlyCreditLineBorrower(uint256 _id) {
        require(pooledCreditLineConstants[_id].borrower == msg.sender, 'PCL:OCLB1');
        _;
    }

    /**
     * @dev checks if called by credit Line Lender Pool
     **/
    modifier onlyLenderPool() {
        require(address(LENDER_POOL) == msg.sender, 'PCL:OLP1');
        _;
    }

    //-------------------------------- Modifiers end --------------------------------//

    //-------------------------------- Events start --------------------------------//

    //--------------------------- Limits event start ---------------------------//

    /**
     * @notice emitted when threhsolds for one of the parameters is updated
     * @param limitType specifies the parameter whose limits are being updated
     * @param min minimum threshold value for limitType
     * @param max maximum threshold value for limitType
     */
    event LimitsUpdated(string indexed limitType, uint256 min, uint256 max);

    //--------------------------- Limits event end ---------------------------//

    //--------------------------- Global variable update events start ---------------------------//

    /**
     * @notice emitted when fee that protocol charges for pooled credit line is updated
     * @param updatedProtocolFee updated value of protocolFeeFraction
     */
    event ProtocolFeeFractionUpdated(uint256 updatedProtocolFee);

    /**
     * @notice emitted when address which receives fee that protocol changes for pools is updated
     * @param updatedProtocolFeeCollector updated value of protocolFeeCollector
     */
    event ProtocolFeeCollectorUpdated(address indexed updatedProtocolFeeCollector);

    //--------------------------- Global variable update events end ---------------------------//

    //--------------------------- CreditLine state events start ---------------------------//

    /**
     * @notice emitted when a collateral is deposited into pooled credit line
     * @param id identifier for the pooled credit line
     * @param shares amount of shares of collateral deposited
     * @param strategy address of the strategy into which collateral is deposited
     */
    event CollateralDeposited(uint256 indexed id, uint256 shares, address indexed strategy);

    /**
     * @notice emitted when collateral is withdrawn from pooled credit line
     * @param id identifier for the pooled credit line
     * @param shares amount of shares of collateral withdrawn
     */
    event CollateralWithdrawn(uint256 indexed id, uint256 shares);

    /**
     * @notice emitted when a request for new pooled credit line is placed
     * @param id identifier for the pooled credit line
     * @param borrower address of the borrower for credit line
     * @param borrowerVerifier address of the verifier with which borrower is verified
     */
    event PooledCreditLineRequested(uint256 indexed id, address indexed borrower, address indexed borrowerVerifier);

    /**
     * @notice emitted when a pooled credit line is liquidated
     * @param id identifier for the pooled credit line
     */
    event PooledCreditLineLiquidated(uint256 indexed id);

    /**
     * @notice emitted when tokens are borrowed from pooled credit line
     * @param id identifier for the pooled credit line
     * @param borrowAmount amount of tokens borrowed
     */
    event BorrowedFromPooledCreditLine(uint256 indexed id, uint256 borrowAmount);

    /**
     * @notice Emitted when pooled credit line is accepted
     * @param id idenitifer for the pooled credit line
     * @param amount total amount of tokens lent to pooled credit line
     */
    event PooledCreditLineAccepted(uint256 indexed id, uint256 amount);

    /**
     * @notice emitted when the pooled credit line is partially repaid
     * @param id identifier for the pooled credit line
     * @param repayer address of the repayer
     * @param repayAmount amount repaid
     */
    event PartialPooledCreditLineRepaid(uint256 indexed id, address indexed repayer, uint256 repayAmount);

    /**
     * @notice emitted when the pooled credit line is completely repaid
     * @param id identifier for the pooled credit line
     * @param repayer address of the repayer
     * @param repayAmount amount repaid
     */
    event CompletePooledCreditLineRepaid(uint256 indexed id, address indexed repayer, uint256 repayAmount);

    /**
     * @notice emitted when the pooled credit line is closed by one of the parties of credit line
     * @param id identifier for the pooled credit line
     */
    event PooledCreditLineClosed(uint256 indexed id);

    /**
     * @notice emitted when the pooled credit line is cancelled by the borrower while in REQUESTED state
     * @param id identifier for the pooled credit line
     * @param reason identifier which specifies the reason for which PCL was cancelled
     */
    event PooledCreditLineCancelled(uint256 indexed id, string indexed reason);

    /**
     * @notice emitted when the pooled credit line is terminatd by owner
     * @param id identifier for the pooled credit line
     */
    event PooledCreditLineTerminated(uint256 indexed id);

    //--------------------------- CreditLine state events end ---------------------------//

    //-------------------------------- Events end --------------------------------//

    //-------------------------------- Limits code starts --------------------------------//

    /**
     * @notice invoked to check if credit lines parameters are within thresholds
     * @dev min or max = 0 is considered as no limit set
     * @param _value supplied value of the parameter
     * @param _min minimum threshold of the parameter
     * @param _max maximum threshold of the parameter
     */
    function isWithinLimits(
        uint256 _value,
        uint256 _min,
        uint256 _max
    ) private pure returns (bool) {
        return (_value >= _min && _value <= _max);
    }

    function _limitBorrowedInUSD(
        address _borrowAsset,
        uint256 _borrowLimit,
        uint256 _minBorrowAmount
    ) private view {
        (uint256 _ratioOfPrices, uint256 _decimals) = PRICE_ORACLE.getLatestPrice(_borrowAsset, USDC);
        uint256 _poolSizeInUSD = _borrowLimit.mul(_ratioOfPrices).div(10**_decimals);
        uint256 _borrowLimitMin = borrowLimitLimits.min;
        require(isWithinLimits(_poolSizeInUSD, _borrowLimitMin, borrowLimitLimits.max), 'PCL:ILB1');

        require(_minBorrowAmount <= _borrowLimit, 'PCL:ILB2');
        uint256 _minBorrowLimitInUSD = _minBorrowAmount.mul(_ratioOfPrices).div(10**_decimals);
        require(_minBorrowLimitInUSD >= _borrowLimitMin, 'PCL:ILB3');
    }

    /**
     * @notice used to update the thresholds of the borrow limit of the pooled credit line
     * @param _min updated value of the minimum threshold value of the borrow limit in lowest units of USDC
     * @param _max updated value of the maximum threshold value of the borrow limit in lowest units of USDC
     */
    function updateBorrowLimitLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, 'PCL:UBLL1');
        require(!(borrowLimitLimits.min == _min && borrowLimitLimits.max == _max), 'PCL:UBLL2');
        borrowLimitLimits = Limits(_min, _max);
        emit LimitsUpdated('borrowLimit', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the ideal collateral ratio of the pooled credit line
     * @param _min updated value of the minimum threshold value of the ideal collateral ratio
     * @param _max updated value of the maximum threshold value of the ideal collateral ratio
     */
    function updateIdealCollateralRatioLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, 'PCL:UICRL1');
        require(!(idealCollateralRatioLimits.min == _min && idealCollateralRatioLimits.max == _max), 'PCL:UICRL2');
        idealCollateralRatioLimits = Limits(_min, _max);
        emit LimitsUpdated('idealCollateralRatio', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the borrow rate of the pooled credit line
     * @param _min updated value of the minimum threshold value of the borrow rate
     * @param _max updated value of the maximum threshold value of the borrow rate
     */
    function updateBorrowRateLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, 'PCL:UBRL1');
        require(!(borrowRateLimits.min == _min && borrowRateLimits.max == _max), 'PCL:UBRL2');
        borrowRateLimits = Limits(_min, _max);
        emit LimitsUpdated('borrowRate', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the collection period of the pooled credit line
     * @param _min updated value of the minimum threshold value of the collection period
     * @param _max updated value of the maximum threshold value of the collection period
     */
    function updateCollectionPeriodLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, 'PCL:UCPL1');
        require(!(collectionPeriodLimits.min == _min && collectionPeriodLimits.max == _max), 'PCL:UCPL2');
        collectionPeriodLimits = Limits(_min, _max);
        emit LimitsUpdated('collectionPeriod', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the duration of the pooled credit line
     * @param _min updated value of the minimum threshold value of the duration
     * @param _max updated value of the maximum threshold value of the duration
     */
    function updateDurationLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, 'PCL:UDL1');
        require(!(durationLimits.min == _min && durationLimits.max == _max), 'PCL:UDL2');
        durationLimits = Limits(_min, _max);
        emit LimitsUpdated('duration', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the grace period after which pooled credit line defaults
     * @param _min updated value of the minimum threshold value of the default grace period
     * @param _max updated value of the maximum threshold value of the default grace period
     */
    function updateDefaultGracePeriodLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, 'PCL:UDGPL1');
        require(!(defaultGracePeriodLimits.min == _min && defaultGracePeriodLimits.max == _max), 'PCL:UDGPL2');
        defaultGracePeriodLimits = Limits(_min, _max);
        emit LimitsUpdated('defaultGracePeriod', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the penalty rate in grace period of the pooled credit line
     * @param _min updated value of the minimum threshold value of the penalty rate in grace period
     * @param _max updated value of the maximum threshold value of the penalty rate in grace period
     */
    function updateGracePenaltyRateLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, 'PCL:UGPRL1');
        require(!(gracePenaltyRateLimits.min == _min && gracePenaltyRateLimits.max == _max), 'PCL:UGPRL2');
        gracePenaltyRateLimits = Limits(_min, _max);
        emit LimitsUpdated('gracePenaltyRate', _min, _max);
    }

    //-------------------------------- Limits code end --------------------------------//

    //-------------------------------- Global var update code start --------------------------------//

    /**
     * @notice used to update the protocol fee fraction
     * @dev can only be updated by owner
     * @param _protocolFeeFraction fraction of the borrower amount collected as protocol fee
     */
    function updateProtocolFeeFraction(uint256 _protocolFeeFraction) external onlyOwner {
        require(protocolFeeFraction != _protocolFeeFraction, 'PCL:UPFF1');
        _updateProtocolFeeFraction(_protocolFeeFraction);
    }

    function _updateProtocolFeeFraction(uint256 _protocolFeeFraction) private {
        require(_protocolFeeFraction <= maximumProtocolFeeFraction, 'PCL:IUPFF1');
        protocolFeeFraction = _protocolFeeFraction;
        emit ProtocolFeeFractionUpdated(_protocolFeeFraction);
    }

    /**
     * @notice used to update the protocol fee collector
     * @dev can only be updated by owner
     * @param _protocolFeeCollector address in which protocol fee is collected
     */
    function updateProtocolFeeCollector(address _protocolFeeCollector) external onlyOwner {
        require(protocolFeeCollector != _protocolFeeCollector, 'PCL:UPFC1');
        _updateProtocolFeeCollector(_protocolFeeCollector);
    }

    function _updateProtocolFeeCollector(address _protocolFeeCollector) private {
        require(_protocolFeeCollector != address(0), 'PCL:IUPFC1');
        protocolFeeCollector = _protocolFeeCollector;
        emit ProtocolFeeCollectorUpdated(_protocolFeeCollector);
    }

    //-------------------------------- Global var update code end --------------------------------//

    //-------------------------------- Initialize code start --------------------------------//

    /**
     * @notice constructor to initialize immutables
     * @param _lenderPool address of lenderPool contract
     * @param _usdc address of usdc contract
     * @param _priceOracle address of the priceOracle
     * @param _savingsAccount address of  the savings account contract
     * @param _strategyRegistry address of the strategy registry contract
     * @param _verification address of the verification contract
     */
    constructor(
        address _lenderPool,
        address _usdc,
        address _priceOracle,
        address _savingsAccount,
        address _strategyRegistry,
        address _verification,
        uint256 _maximumProtocolFeeFraction
    ) {
        require(_lenderPool != address(0), 'PCL:CON1');
        require(_usdc != address(0), 'PCL:CON2');
        require(_priceOracle != address(0), 'PCL:CON3');
        require(_savingsAccount != address(0), 'PCL:CON4');
        require(_strategyRegistry != address(0), 'PCL:CON5');
        require(_verification != address(0), 'PCL:CON6');
        LENDER_POOL = ILenderPool(_lenderPool);
        USDC = _usdc;
        PRICE_ORACLE = IPriceOracle(_priceOracle);
        SAVINGS_ACCOUNT = ISavingsAccount(_savingsAccount);
        STRATEGY_REGISTRY = IStrategyRegistry(_strategyRegistry);
        VERIFICATION = IVerification(_verification);
        maximumProtocolFeeFraction = _maximumProtocolFeeFraction;
    }

    /**
     * @notice used to initialize the contract
     * @dev can only be called once during the life cycle of the contract
     * @param _owner address of owner who can change global variables
     * @param _protocolFeeFraction fraction of the fee charged by protocol (multiplied by SCALING_FACTOR)
     * @param _protocolFeeCollector address to which protocol fee is charged to
     
     */
    function initialize(
        address _owner,
        uint256 _protocolFeeFraction,
        address _protocolFeeCollector
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        OwnableUpgradeable.transferOwnership(_owner);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        _updateProtocolFeeFraction(_protocolFeeFraction);
        _updateProtocolFeeCollector(_protocolFeeCollector);
    }

    //-------------------------------- Initialize code end --------------------------------//

    //-------------------------------- CreditLine creation code start --------------------------------//

    /**
     * @notice used to request a pooled credit line by borrower
     * @param _request Credit line creation request
     * @return identifier for the pooled credit line
     */

    function request(Request calldata _request) external nonReentrant returns (uint256) {
        require(VERIFICATION.isUser(msg.sender, _request.borrowerVerifier), 'PCL:R1');
        require(_request.borrowAsset != _request.collateralAsset, 'PCL:R2');
        require(PRICE_ORACLE.doesFeedExist(_request.borrowAsset, _request.collateralAsset), 'PCL:R3');
        require(_request.borrowAsset != address(0) && _request.collateralAsset != address(0), 'PCL:R4');
        require(STRATEGY_REGISTRY.registry(_request.borrowAssetStrategy) != 0, 'PCL:R5');
        require(STRATEGY_REGISTRY.registry(_request.collateralAssetStrategy) != 0, 'PCL:R6');
        _limitBorrowedInUSD(_request.borrowAsset, _request.borrowLimit, _request.minBorrowAmount);
        require(isWithinLimits(_request.borrowRate, borrowRateLimits.min, borrowRateLimits.max), 'PCL:R7');
        // collateral ratio = 0 is a special case which is allowed
        if (_request.collateralRatio != 0) {
            require(isWithinLimits(_request.collateralRatio, idealCollateralRatioLimits.min, idealCollateralRatioLimits.max), 'PCL:R8');
        }
        require(isWithinLimits(_request.collectionPeriod, collectionPeriodLimits.min, collectionPeriodLimits.max), 'PCL:R9');
        require(isWithinLimits(_request.duration, durationLimits.min, durationLimits.max), 'PCL:R10');
        require(isWithinLimits(_request.defaultGracePeriod, defaultGracePeriodLimits.min, defaultGracePeriodLimits.max), 'PCL:R11');
        require(isWithinLimits(_request.gracePenaltyRate, gracePenaltyRateLimits.min, gracePenaltyRateLimits.max), 'PCL:R12');

        require(VERIFICATION.verifiers(_request.lenderVerifier), 'PCL:R13');

        uint256 _id = _createRequest(_request);

        _notifyRequest(
            _id,
            _request.lenderVerifier,
            _request.borrowAsset,
            _request.borrowAssetStrategy,
            _request.borrowLimit,
            _request.minBorrowAmount,
            _request.collectionPeriod,
            _request.areTokensTransferable
        );
        emit PooledCreditLineRequested(_id, msg.sender, _request.borrowerVerifier);
        return _id;
    }

    function _createRequest(Request calldata _request) private returns (uint256) {
        uint256 _id = ++pooledCreditLineCounter;
        pooledCreditLineVariables[_id].status = PooledCreditLineStatus.REQUESTED;

        PooledCreditLineConstants storage _clc = pooledCreditLineConstants[_id];
        _clc.borrower = msg.sender;
        _clc.borrowLimit = _request.borrowLimit;
        _clc.idealCollateralRatio = _request.collateralRatio;
        _clc.borrowRate = _request.borrowRate;
        _clc.borrowAsset = _request.borrowAsset;
        _clc.collateralAsset = _request.collateralAsset;
        _clc.collateralAssetStrategy = _request.collateralAssetStrategy;
        uint256 _endsAt = block.timestamp.add(_request.collectionPeriod).add(_request.duration);
        _clc.startsAt = block.timestamp.add(_request.collectionPeriod);
        _clc.endsAt = _endsAt;
        _clc.defaultsAt = _endsAt.add(_request.defaultGracePeriod);
        _clc.gracePenaltyRate = _request.gracePenaltyRate;
        _clc.borrowAssetStrategy = _request.borrowAssetStrategy;
        return _id;
    }

    function _notifyRequest(
        uint256 _id,
        address _lenderVerifier,
        address _borrowAsset,
        address _borrowAssetStrategy,
        uint256 _borrowLimit,
        uint256 _minBorrowedAmount,
        uint256 _collectionPeriod,
        bool _areTokensTransferable
    ) private {
        LENDER_POOL.create(
            _id,
            _lenderVerifier,
            _borrowAsset,
            _borrowAssetStrategy,
            _borrowLimit,
            _minBorrowedAmount,
            _collectionPeriod,
            _areTokensTransferable
        );
    }

    /**
     * @notice used to accept a pooled credit line
     * @dev only lenderPool can accept
     * @param _id identifier for the pooled credit line
     * @param _amount Borrow Limit
     */
    function accept(uint256 _id, uint256 _amount) external override nonReentrant onlyLenderPool {
        require(pooledCreditLineVariables[_id].status == PooledCreditLineStatus.REQUESTED, 'PCL:A1');
        pooledCreditLineVariables[_id].status = PooledCreditLineStatus.ACTIVE;
        pooledCreditLineConstants[_id].borrowLimit = SafeCast.toUint128(_amount);
        emit PooledCreditLineAccepted(_id, _amount);
    }

    //-------------------------------- CreditLine creation code end --------------------------------//

    //-------------------------------- Collateral management start --------------------------------//

    /**
     * @notice used to deposit collateral into the pooled credit line
     * @dev collateral tokens have to be approved in savingsAccount or token contract
     * @param _id identifier for the pooled credit line
     * @param _amount amount of collateral being deposited
     * @param _fromSavingsAccount if true, tokens are transferred from savingsAccount
                                otherwise direct from collateral token contract
     */
    function depositCollateral(
        uint256 _id,
        uint256 _amount,
        bool _fromSavingsAccount
    ) external nonReentrant {
        PooledCreditLineStatus _status = getStatusAndUpdate(_id);
        require(_status == PooledCreditLineStatus.ACTIVE || _status == PooledCreditLineStatus.EXPIRED, 'PCL:DC1');
        address _collateralAsset = pooledCreditLineConstants[_id].collateralAsset;
        address _strategy = pooledCreditLineConstants[_id].collateralAssetStrategy;
        uint256 _sharesDeposited;

        if (_fromSavingsAccount) {
            _sharesDeposited = SAVINGS_ACCOUNT.transferFrom(_collateralAsset, _strategy, msg.sender, address(this), _amount);
        } else {
            IERC20(_collateralAsset).safeTransferFrom(msg.sender, address(this), _amount);
            IERC20(_collateralAsset).safeApprove(_strategy, _amount);

            _sharesDeposited = SAVINGS_ACCOUNT.deposit(_collateralAsset, _strategy, address(this), _amount);
        }
        depositedCollateralInShares[_id] = depositedCollateralInShares[_id].add(_sharesDeposited);

        emit CollateralDeposited(_id, _sharesDeposited, _strategy);
    }

    /**
     * @notice used to withdraw any excess collateral
     * @dev collateral can't be withdraw if collateralRatio goes below the ideal value. Only borrower can withdraw
     * @param _id identifier for the pooled credit line
     * @param _amount amount of collateral to withdraw
     * @param _toSavingsAccount if true, tokens are transferred to savingsAccount, else to borrower address directly
     */
    function withdrawCollateral(
        uint256 _id,
        uint256 _amount,
        bool _toSavingsAccount
    ) external nonReentrant onlyCreditLineBorrower(_id) {
        uint256 _withdrawableCollateral = withdrawableCollateral(_id);
        require(_amount <= _withdrawableCollateral, 'PCL:WC1');
        require(_amount != 0, 'PCL:WC2');
        (, uint256 _amountInShares) = _transferCollateral(_id, pooledCreditLineConstants[_id].collateralAsset, _amount, _toSavingsAccount);
        emit CollateralWithdrawn(_id, _amountInShares);
    }

    /**
     * @notice used to withdraw all the permissible collateral as per the current col ratio
     * @dev if the withdrawable collateral amount is non-zero the transaction will pass
     * @param _id identifier for the pooled credit line
     * @param _toSavingsAccount if true, tokens are transferred from savingsAccount
                                otherwise direct from collateral token contract
     */

    function withdrawAllCollateral(uint256 _id, bool _toSavingsAccount) external nonReentrant onlyCreditLineBorrower(_id) {
        uint256 _collateralWithdrawn = _withdrawAllCollateral(_id, _toSavingsAccount);
        require(_collateralWithdrawn != 0, 'PCL:WAC1');
    }

    function _withdrawAllCollateral(uint256 _id, bool _toSavingsAccount) private returns (uint256 _collateralWithdrawn) {
        uint256 _withdrawableCollateral = withdrawableCollateral(_id);
        if (_withdrawableCollateral == 0) {
            return 0;
        }
        (, uint256 _amountInShares) = _transferCollateral(
            _id,
            pooledCreditLineConstants[_id].collateralAsset,
            _withdrawableCollateral,
            _toSavingsAccount
        );
        emit CollateralWithdrawn(_id, _amountInShares);
        return _withdrawableCollateral;
    }

    /**
     * @notice used to calculate the collateral that can be withdrawn
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view
     * @param _id identifier for the pooled credit line
     * @return total collateral withdrawable by borrower
     */
    function withdrawableCollateral(uint256 _id) public returns (uint256) {
        PooledCreditLineStatus _status = getStatusAndUpdate(_id);
        if (
            _status == PooledCreditLineStatus.EXPIRED ||
            _status == PooledCreditLineStatus.CANCELLED ||
            _status == PooledCreditLineStatus.REQUESTED
        ) {
            return 0;
        }

        uint256 _totalCollateral = calculateTotalCollateralTokens(_id);

        if (_status == PooledCreditLineStatus.LIQUIDATED || _status == PooledCreditLineStatus.CLOSED) {
            return _totalCollateral;
        }

        (uint256 _ratioOfPrices, uint256 _decimals) = PRICE_ORACLE.getLatestPrice(
            pooledCreditLineConstants[_id].collateralAsset,
            pooledCreditLineConstants[_id].borrowAsset
        );

        uint256 _currentDebt = calculateCurrentDebt(_id);
        uint256 _collateralRatio = pooledCreditLineConstants[_id].idealCollateralRatio;

        // borrowAsset decimals range (2 - 35)
        // collateralRatio decimals range (14 - 22)
        // ratioOfPrices decimals range (6 - 30)
        // decimals always has value 18 and scaling factor is 10^18 - they cancel out each other
        uint256 _collateralNeeded = _currentDebt.mul(_collateralRatio).div(_ratioOfPrices).mul(10**_decimals).div(SCALING_FACTOR);

        if (_collateralNeeded >= _totalCollateral) {
            return 0;
        }
        return _totalCollateral.sub(_collateralNeeded);
    }

    function _transferCollateral(
        uint256 _id,
        address _asset,
        uint256 _amountInTokens,
        bool _toSavingsAccount
    ) private returns (uint256, uint256) {
        address _strategy = pooledCreditLineConstants[_id].collateralAssetStrategy;
        uint256 _amountInShares = IYield(_strategy).getSharesForTokens(_amountInTokens, _asset);
        uint256 _amountReceived;

        depositedCollateralInShares[_id] = depositedCollateralInShares[_id].sub(_amountInShares, 'PCL:ITC1');

        if (_toSavingsAccount) {
            _amountReceived = SAVINGS_ACCOUNT.transferShares(_asset, _strategy, msg.sender, _amountInShares);
        } else {
            _amountReceived = SAVINGS_ACCOUNT.withdrawShares(_asset, _strategy, msg.sender, _amountInShares, false);
        }

        return (_amountReceived, _amountInShares);
    }

    /**
     * @notice used to calculate the total collateral tokens
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view
     * @param _id identifier for the pooled credit line
     * @return _amount total collateral tokens deposited into the pooled credit line
     */
    function calculateTotalCollateralTokens(uint256 _id) public returns (uint256) {
        address _strategy = pooledCreditLineConstants[_id].collateralAssetStrategy;
        require(_strategy != address(0), 'PCL:CTCT1');
        address _collateralAsset = pooledCreditLineConstants[_id].collateralAsset;

        uint256 _collateralShares = depositedCollateralInShares[_id];
        uint256 _collateral = IYield(_strategy).getTokensForShares(_collateralShares, _collateralAsset);

        return _collateral;
    }

    function getRequiredCollateral(uint256 _id, uint256 _borrowTokenAmount) external view returns (uint256) {
        address _collateralAsset = pooledCreditLineConstants[_id].collateralAsset;
        address _borrowAsset = pooledCreditLineConstants[_id].borrowAsset;

        uint256 _collateral = _equivalentCollateral(_collateralAsset, _borrowAsset, _borrowTokenAmount);

        return _collateral.mul(pooledCreditLineConstants[_id].idealCollateralRatio).div(SCALING_FACTOR);
    }

    //-------------------------------- Collateral management end --------------------------------//

    //-------------------------------- Borrow code start --------------------------------//

    /**
     * @notice used to borrow tokens from credit line by borrower
     * @dev only borrower can call this function. Amount that can actually be borrowed is
            min(amount based on borrowLimit, allowance to creditLine contract, balance of lender)
     * @param _id identifier for the pooled credit line
     * @param _amount amount of tokens to borrow
     */
    function borrow(uint256 _id, uint256 _amount) external nonReentrant onlyCreditLineBorrower(_id) {
        _borrow(_id, _amount);
    }

    function _borrow(uint256 _id, uint256 _amount) private {
        require(_amount != 0, 'PCL:IB1');
        require(block.timestamp >= pooledCreditLineConstants[_id].startsAt, 'PCL:IB2');
        // calculateBorrowableAmount is 0, hence statement reverts for all states except ACTIVE
        require(_amount <= calculateBorrowableAmount(_id), 'PCL:IB3');

        address _borrowAsset = pooledCreditLineConstants[_id].borrowAsset;

        uint256 _balanceBefore = IERC20(_borrowAsset).balanceOf(address(this));

        uint256 _sharesWithdrawn = _withdrawBorrowAmount(_borrowAsset, pooledCreditLineConstants[_id].borrowAssetStrategy, _amount);
        LENDER_POOL.borrowed(_id, _sharesWithdrawn);
        uint256 _balanceAfter = IERC20(_borrowAsset).balanceOf(address(this));

        uint256 _borrowedAmount = _balanceAfter.sub(_balanceBefore);
        updateStateOnPrincipalChange(_id, pooledCreditLineVariables[_id].principal.add(_borrowedAmount));

        uint256 _protocolFee = _borrowedAmount.mul(protocolFeeFraction).div(SCALING_FACTOR);
        _borrowedAmount = _borrowedAmount.sub(_protocolFee);

        IERC20(_borrowAsset).safeTransfer(protocolFeeCollector, _protocolFee);
        IERC20(_borrowAsset).safeTransfer(msg.sender, _borrowedAmount);
        emit BorrowedFromPooledCreditLine(_id, _borrowedAmount);
    }

    /**
     * @notice used to calculate amount that can be borrowed by the borrower
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view.
            borrowableAmount changes per block as interest changes per block.
     * @param _id identifier for the pooled credit line
     * @return amount that can be borrowed from the pooled credit line
     */
    function calculateBorrowableAmount(uint256 _id) public returns (uint256) {
        PooledCreditLineStatus _status = getStatusAndUpdate(_id);
        if (_status != PooledCreditLineStatus.ACTIVE) {
            return 0;
        }
        (uint256 _ratioOfPrices, uint256 _decimals) = PRICE_ORACLE.getLatestPrice(
            pooledCreditLineConstants[_id].collateralAsset,
            pooledCreditLineConstants[_id].borrowAsset
        );

        uint256 _totalCollateral = calculateTotalCollateralTokens(_id);

        uint256 _currentDebt = calculateCurrentDebt(_id);

        uint256 _collateralRatio = pooledCreditLineConstants[_id].idealCollateralRatio;
        uint256 _maxPossible = type(uint256).max;
        if (_collateralRatio != 0) {
            _maxPossible = _totalCollateral.mul(_ratioOfPrices).div(_collateralRatio).mul(SCALING_FACTOR).div(10**_decimals);
        }

        uint256 _borrowLimit = pooledCreditLineConstants[_id].borrowLimit;
        uint256 _principal = pooledCreditLineVariables[_id].principal;

        if (_maxPossible <= _currentDebt) return 0;

        // using direct subtraction for _maxPossible because we have a check above for it being greater than _currentDebt
        return Math.min(_borrowLimit.sub(_principal), _maxPossible - _currentDebt);
    }

    function _withdrawBorrowAmount(
        address _asset,
        address _strategy,
        uint256 _amountInTokens
    ) private returns (uint256) {
        uint256 _shares = IYield(_strategy).getSharesForTokens(_amountInTokens, _asset);
        SAVINGS_ACCOUNT.withdrawFrom(_asset, _strategy, address(LENDER_POOL), address(this), _amountInTokens, false);
        return _shares;
    }

    //-------------------------------- Borrow code end --------------------------------//

    //-------------------------------- Repayments code start --------------------------------//

    /**
     * @notice used to repay interest and principal to pooled credit line. Interest has to be repaid before
               repaying principal
     * @dev partial repayments possible
     * @param _id identifier for the pooled credit line
     * @param _amount amount being repaid
     */
    function repay(uint256 _id, uint256 _amount) external nonReentrant {
        PooledCreditLineStatus currentStatus = getStatusAndUpdate(_id);
        require(currentStatus == PooledCreditLineStatus.ACTIVE || currentStatus == PooledCreditLineStatus.EXPIRED, 'PCL:REP1');

        uint256 _currentPrincipal = pooledCreditLineVariables[_id].principal;
        uint256 _totalInterestAccrued = calculateInterestAccrued(_id);
        uint256 _interestToPay = _totalInterestAccrued.sub(pooledCreditLineVariables[_id].totalInterestRepaid);
        uint256 _currentDebt = (_currentPrincipal).add(_interestToPay);

        require(_currentDebt != 0, 'PCL:REP2');

        // in case the interest to pay is 0 (expect when interest rate is 0) no repayment can happen
        // this is because it can be then possible to borrow small amounts for short period of time
        // then pay it back with 0 interest. to be safe we allow repayment when there is some _interestToPay
        if (pooledCreditLineConstants[_id].borrowRate != 0) {
            require(_interestToPay != 0, 'PCL:REP3');
        }

        if (_amount >= _currentDebt) {
            _amount = _currentDebt;
            emit CompletePooledCreditLineRepaid(_id, msg.sender, _amount);
        } else {
            emit PartialPooledCreditLineRepaid(_id, msg.sender, _amount);
        }

        uint256 _principalPaid;
        if (_amount > _interestToPay) {
            _principalPaid = _amount.sub(_interestToPay);
            pooledCreditLineVariables[_id].principal = _currentPrincipal.sub(_principalPaid);
            pooledCreditLineVariables[_id].interestAccruedTillLastPrincipalUpdate = _totalInterestAccrued;
            pooledCreditLineVariables[_id].lastPrincipalUpdateTime = block.timestamp;
            pooledCreditLineVariables[_id].totalInterestRepaid = _totalInterestAccrued;
        } else {
            pooledCreditLineVariables[_id].totalInterestRepaid = pooledCreditLineVariables[_id].totalInterestRepaid.add(_amount);
        }

        uint256 _interestPaid = _amount.sub(_principalPaid);
        uint256 _repaidInterestShares = IYield(pooledCreditLineConstants[_id].borrowAssetStrategy).getSharesForTokens(
            _interestPaid,
            pooledCreditLineConstants[_id].borrowAsset
        );

        uint256 _repaidShares = _repay(_id, _amount);
        LENDER_POOL.repaid(_id, _repaidShares, _repaidInterestShares);

        if ((pooledCreditLineVariables[_id].principal == 0) && (currentStatus == PooledCreditLineStatus.EXPIRED)) {
            pooledCreditLineVariables[_id].status = PooledCreditLineStatus.CLOSED;
            emit PooledCreditLineClosed(_id);
        }
    }

    function _repay(uint256 _id, uint256 _amount) private returns (uint256) {
        address _strategy = pooledCreditLineConstants[_id].borrowAssetStrategy;
        address _borrowAsset = pooledCreditLineConstants[_id].borrowAsset;
        uint256 _sharesReceived = IYield(_strategy).getSharesForTokens(_amount, _borrowAsset);
        IERC20(_borrowAsset).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_borrowAsset).safeApprove(_strategy, _amount);
        SAVINGS_ACCOUNT.deposit(_borrowAsset, _strategy, address(LENDER_POOL), _amount);
        return _sharesReceived;
    }

    /**
     * @dev Used to calculate interest accrued since last repayment
     * @param _id identifier for the pooled credit line
     * @return interest accrued over current borrowed amount since last repayment
     */

    function calculateInterestAccrued(uint256 _id) public view returns (uint256) {
        uint256 _lastPrincipalUpdateTime = pooledCreditLineVariables[_id].lastPrincipalUpdateTime;
        uint256 _principal = pooledCreditLineVariables[_id].principal;
        if (_lastPrincipalUpdateTime == 0 && _principal == 0) return 0;
        uint256 _timeElapsed = (block.timestamp).sub(_lastPrincipalUpdateTime);
        uint256 _endTime = pooledCreditLineConstants[_id].endsAt;
        uint256 _penaltyRate = pooledCreditLineConstants[_id].gracePenaltyRate;
        uint256 _borrowRate = pooledCreditLineConstants[_id].borrowRate;
        uint256 _penaltyInterest;
        if (_lastPrincipalUpdateTime <= _endTime && block.timestamp > _endTime) {
            _penaltyInterest = _calculateInterest(_principal, _penaltyRate, block.timestamp.sub(_endTime));
        } else if (_lastPrincipalUpdateTime > _endTime) {
            _penaltyInterest = _calculateInterest(_principal, _penaltyRate, block.timestamp.sub(_lastPrincipalUpdateTime));
        }
        uint256 _interestAccrued = _calculateInterest(_principal, _borrowRate, _timeElapsed);
        _interestAccrued = _interestAccrued.add(_penaltyInterest);
        return _interestAccrued.add(pooledCreditLineVariables[_id].interestAccruedTillLastPrincipalUpdate);
    }

    /**
     * @dev Used to calculate current debt of borrower against a pooled credit line.
     * @param _id identifier for the pooled credit line
     * @return current debt of borrower
     */
    function calculateCurrentDebt(uint256 _id) public view returns (uint256) {
        uint256 _interestAccrued = calculateInterestAccrued(_id);
        uint256 _currentDebt = (pooledCreditLineVariables[_id].principal).add(_interestAccrued).sub(
            pooledCreditLineVariables[_id].totalInterestRepaid
        );
        return _currentDebt;
    }

    //-------------------------------- Repayments code end --------------------------------//

    //-------------------------------- Liquidation code start --------------------------------//

    /**
     * @notice used to liquidate credit line in case collateral ratio goes below the threshold
     * @dev then collateral is directly transferred to lenderPool
     * @param _id identifier for the pooled credit line
     * @return collateral asset received, amount of collateral asset received
     */
    function liquidate(uint256 _id) external override nonReentrant onlyLenderPool returns (address, uint256) {
        PooledCreditLineStatus currentStatus = getStatusAndUpdate(_id);
        require(pooledCreditLineVariables[_id].principal != 0, 'PCL:L1');
        require(currentStatus == PooledCreditLineStatus.ACTIVE || currentStatus == PooledCreditLineStatus.EXPIRED, 'PCL:L2');

        address _collateralAsset = pooledCreditLineConstants[_id].collateralAsset;

        uint256 currentCollateralRatio = calculateCurrentCollateralRatio(_id);
        require(
            currentCollateralRatio < pooledCreditLineConstants[_id].idealCollateralRatio ||
                block.timestamp >= pooledCreditLineConstants[_id].defaultsAt,
            'PCL:L3'
        );
        uint256 _currentDebt = calculateCurrentDebt(_id);
        address _borrowAsset = pooledCreditLineConstants[_id].borrowAsset;
        uint256 _collateralToLiquidate = _equivalentCollateral(_collateralAsset, _borrowAsset, _currentDebt);
        uint256 _totalCollateral = calculateTotalCollateralTokens(_id);
        if (_collateralToLiquidate > _totalCollateral) {
            _collateralToLiquidate = _totalCollateral;
        }

        pooledCreditLineVariables[_id].status = PooledCreditLineStatus.LIQUIDATED;

        uint256 _collateralReceived;
        if (_collateralToLiquidate != 0) {
            (_collateralReceived, ) = _transferCollateral(_id, _collateralAsset, _collateralToLiquidate, false);
        }

        emit PooledCreditLineLiquidated(_id);

        return (_collateralAsset, _collateralReceived);
    }

    /**
     * @notice used to calculate the collateral tokens necessary for specified borrow tokens
     * @param _id identifier for the pooled credit line
     * @param _borrowTokenAmount amount of borrow tokens for which equivalent collateral is calculated
     * @return collateral tokens equivalent to _borrowTokenAmount
     */
    function collateralTokensToLiquidate(uint256 _id, uint256 _borrowTokenAmount) external view returns (uint256) {
        address _collateralAsset = pooledCreditLineConstants[_id].collateralAsset;
        require(_collateralAsset != address(0), 'PCL:CTTL1');
        address _borrowAsset = pooledCreditLineConstants[_id].borrowAsset;

        return _equivalentCollateral(_collateralAsset, _borrowAsset, _borrowTokenAmount);
    }

    //-------------------------------- Liquidation code end --------------------------------//

    //-------------------------------- close/cancel code start --------------------------------//

    /**
     * @dev used to close pooled credit line by borrower
     * @param _id identifier for the pooled credit line
     */
    function close(uint256 _id) external nonReentrant onlyCreditLineBorrower(_id) {
        PooledCreditLineStatus _status = pooledCreditLineVariables[_id].status;
        require(_status == PooledCreditLineStatus.ACTIVE || _status == PooledCreditLineStatus.EXPIRED, 'PCL:C1');
        require(pooledCreditLineVariables[_id].principal == 0, 'PCL:C2');
        pooledCreditLineVariables[_id].status = PooledCreditLineStatus.CLOSED;
        _withdrawAllCollateral(_id, false);
        emit PooledCreditLineClosed(_id);
    }

    /**
     * @notice used to cancel a pooled credit line request
     * @dev only callable by the borrower in REQUESTED state
     * @param _id identifier for the pooled credit line
     */
    function cancelRequest(uint256 _id) external nonReentrant onlyCreditLineBorrower(_id) {
        require(pooledCreditLineVariables[_id].status == PooledCreditLineStatus.REQUESTED, 'PCL:CR1');
        require(block.timestamp < pooledCreditLineConstants[_id].startsAt, 'PCL:CR2');
        LENDER_POOL.requestCancelled(_id);
        _cancelRequest(_id, 'BORROWER_BEFORE_START');
    }

    /**
     * @notice Function invoked when pooled credit line cancelled because of low collection
     * @dev only pooledCreditLineContract can invoke
     * @param _id identifier for the pooled credit line
     */
    function cancelRequestOnLowCollection(uint256 _id) external override nonReentrant onlyLenderPool {
        _cancelRequest(_id, 'LENDER_LOW_COLLECTION');
    }

    /**
     * @notice Function invoked when pooled credit line cancelled because it was't active even after end time
     * @dev only pooledCreditLineContract can invoke
     * @param _id identifier for the pooled credit line
     */
    function cancelRequestOnRequestedStateAtEnd(uint256 _id) external override nonReentrant onlyLenderPool returns (bool _isCancelled) {
        _cancelRequest(_id, 'LENDER_NOT_STARTED_AT_END');
    }

    /**
     * @notice Function invoked when pooled credit line is terminated by admin
     * @dev only owner can invoke
     * @param _id identifier for the pooled credit line
     */
    function terminate(uint256 _id) external nonReentrant onlyOwner {
        // This function reverts in `NOT_CREATED` or `CANCELLED` state and hence can't terminate
        uint256 _allCollateral = calculateTotalCollateralTokens(_id);
        if (_allCollateral != 0) {
            _transferCollateral(_id, pooledCreditLineConstants[_id].collateralAsset, _allCollateral, false);
        }
        LENDER_POOL.terminate(_id, msg.sender);
        delete pooledCreditLineVariables[_id];
        delete pooledCreditLineConstants[_id];
        emit PooledCreditLineTerminated(_id);
    }

    function _cancelRequest(uint256 _id, string memory _reason) private {
        delete pooledCreditLineVariables[_id];
        delete pooledCreditLineConstants[_id];
        pooledCreditLineVariables[_id].status = PooledCreditLineStatus.CANCELLED;
        emit PooledCreditLineCancelled(_id, _reason);
    }

    //-------------------------------- close/cancel code end --------------------------------//

    //-------------------------------- Utilities code start --------------------------------//

    /**
     * @notice used to get the principal borrowed in a pooled credit line
     * @param _id identifier for the pooled credit line
     * @return Returns principal for the given pooled credit line
     */
    function getPrincipal(uint256 _id) external view override returns (uint256) {
        return pooledCreditLineVariables[_id].principal;
    }

    /**
     * @notice used to get the timestamp at which pooled credit line ends
     * @param _id identifier for the pooled credit line
     */
    function getEndsAt(uint256 _id) external view override returns (uint256) {
        return pooledCreditLineConstants[_id].endsAt;
    }

    /**
     * @notice used to update(if required) and get the status of pooled credit line
     * @dev keeps track of status based on end time
     * @param _id identifier for the pooled credit line
     * @return status of pooled credit line
     */
    function getStatusAndUpdate(uint256 _id) public override returns (PooledCreditLineStatus) {
        PooledCreditLineStatus currentStatus = pooledCreditLineVariables[_id].status;
        if (currentStatus == PooledCreditLineStatus.ACTIVE && pooledCreditLineConstants[_id].endsAt <= block.timestamp) {
            if (pooledCreditLineVariables[_id].principal != 0) {
                currentStatus = PooledCreditLineStatus.EXPIRED;
            } else {
                currentStatus = PooledCreditLineStatus.CLOSED;
            }
            pooledCreditLineVariables[_id].status = currentStatus;
        }
        return currentStatus;
    }

    /**
     * @dev Used to Calculate Interest Per second on given principal and Interest rate
     * @param _principal principal Amount for which interest has to be calculated.
     * @param _borrowRate It is the Interest Rate at which pooled Credit Line is approved
     * @param _timeElapsed time in seconds to calculate interest for
     * @return interest per second for the given parameters
     */
    function _calculateInterest(
        uint256 _principal,
        uint256 _borrowRate,
        uint256 _timeElapsed
    ) private pure returns (uint256) {
        return (_principal.mul(_borrowRate).mul(_timeElapsed).div(YEAR_IN_SECONDS).div(SCALING_FACTOR));
    }

    function updateStateOnPrincipalChange(uint256 _id, uint256 _updatedPrincipal) private {
        uint256 _totalInterestAccrued = calculateInterestAccrued(_id);
        pooledCreditLineVariables[_id].interestAccruedTillLastPrincipalUpdate = _totalInterestAccrued;
        pooledCreditLineVariables[_id].lastPrincipalUpdateTime = block.timestamp;
        pooledCreditLineVariables[_id].principal = _updatedPrincipal;
    }

    /**
     * @notice used to calculate the current collateral ratio
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view.
            Interest is also considered while calculating debt
     * @param _id identifier for the pooled credit line
     * @return collateral ratio multiplied by SCALING_FACTOR to retain precision
     */
    function calculateCurrentCollateralRatio(uint256 _id) public returns (uint256) {
        (uint256 _ratioOfPrices, uint256 _decimals) = PRICE_ORACLE.getLatestPrice(
            pooledCreditLineConstants[_id].collateralAsset,
            pooledCreditLineConstants[_id].borrowAsset
        );

        uint256 _currentDebt = calculateCurrentDebt(_id);
        uint256 _currentCollateralRatio = type(uint256).max;
        if (_currentDebt != 0) {
            _currentCollateralRatio = calculateTotalCollateralTokens(_id).mul(_ratioOfPrices).div(_currentDebt).mul(SCALING_FACTOR).div(
                10**_decimals
            );
        }

        return _currentCollateralRatio;
    }

    function _equivalentCollateral(
        address _collateralAsset,
        address _borrowAsset,
        uint256 _borrowTokenAmount
    ) private view returns (uint256) {
        (uint256 _ratioOfPrices, uint256 _decimals) = PRICE_ORACLE.getLatestPrice(_collateralAsset, _borrowAsset);
        uint256 _collateralTokenAmount = (_borrowTokenAmount.mul(10**_decimals).div(_ratioOfPrices));

        return _collateralTokenAmount;
    }

    //-------------------------------- Utilities code end --------------------------------//
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IPriceOracle {
    /**
     * @notice emitted when chainlink price feed for a token is updated
     * @param token address of token for which price feed is updated
     * @param priceOracle address of the updated price feed for the token
     */
    event ChainlinkFeedUpdated(address indexed token, address indexed priceOracle);

    /**
     * @notice emitted when uniswap price feed for a token pair is updated
     * @param token1 address of numerator address in price feed
     * @param token2 address of denominator address in price feed
     * @param feedId unique id for the token pair irrespective of the order of tokens
     * @param pool address of the pool from which price feed can be queried
     */
    event UniswapFeedUpdated(address indexed token1, address indexed token2, bytes32 feedId, address indexed pool);

    /**
     * @notice emitted when price averaging window for uniswap price feeds is updated
     * @param uniswapPriceAveragingPeriod period during which uniswap prices are averaged over to avoid attacks
     */
    event UniswapPriceAveragingPeriodUpdated(uint32 uniswapPriceAveragingPeriod);

    function getLatestPrice(address num, address den) external view returns (uint256 price, uint256 decimals);

    function doesFeedExist(address token1, address token2) external view returns (bool feedExists);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IYield {
    /**
     * @dev emitted when tokens are locked
     * @param user the address of user, tokens locked for
     * @param investedTo the address of contract to invest in
     * @param lpTokensReceived the amount of shares received
     **/
    event LockedTokens(address indexed user, address indexed investedTo, uint256 lpTokensReceived);

    /**
     * @dev emitted when tokens are unlocked/redeemed
     * @param investedTo the address of contract invested in
     * @param collateralReceived the amount of underlying asset received
     **/
    event UnlockedTokens(address indexed investedTo, uint256 collateralReceived);

    /**
     * @notice emitted when a shares are unlocked from yield
     * @param asset address of the base token for which shares are being withdrawn
     * @param sharesReleased amount of shares unlocked
     */
    event UnlockedShares(address indexed asset, uint256 sharesReleased);

    /**
     * @notice emitted when savings account address is updated
     * @param savingsAccount updated address of the savings account contract
     */
    event SavingsAccountUpdated(address indexed savingsAccount);

    /**
     * @dev Used to get liquidity token address from asset address
     * @param asset the address of underlying token
     * @return tokenAddress address of liquidity token
     **/
    function liquidityToken(address asset) external view returns (address tokenAddress);

    /**
     * @dev Used to lock tokens in available protocol
     * @param user the address of user locking tokens
     * @param asset the address of token to invest
     * @param amount the amount of asset
     * @return sharesReceived amount of shares received
     **/
    function lockTokens(
        address user,
        address asset,
        uint256 amount
    ) external returns (uint256 sharesReceived);

    /**
     * @dev Used to unlock tokens from available protocol
     * @param asset the address of underlying token
     * @param to the address to which tokens are transferred after unlock
     * @param amount the amount of liquidity shares to unlock
     * @return tokensReceived amount of tokens received
     **/
    function unlockTokens(
        address asset,
        address to,
        uint256 amount
    ) external returns (uint256 tokensReceived);

    function unlockShares(
        address asset,
        address to,
        uint256 amount
    ) external returns (uint256 received);

    /**
     * @dev Used to get amount of underlying tokens for current number of shares
     * @param shares the amount of shares
     * @param asset the address of token locked
     * @return amount amount of underlying tokens
     **/
    function getTokensForShares(uint256 shares, address asset) external returns (uint256 amount);

    function getSharesForTokens(uint256 amount, address asset) external returns (uint256 shares);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ISavingsAccount {
    /**
     * @notice emitted when tokens are deposited into savings account
     * @param user address of user depositing the tokens
     * @param sharesReceived amount of shares received for deposit
     * @param token address of token that is deposited
     * @param strategy strategy into which tokens are deposited
     */
    event Deposited(address indexed user, uint256 sharesReceived, address indexed token, address indexed strategy);

    /**
     * @notice emitted when tokens are switched from one strategy to another
     * @param user address of user switching strategies
     * @param token address of token for which strategies are switched
     * @param sharesDecreasedInCurrentStrategy shares decreased in current strategy
     * @param sharesIncreasedInNewStrategy shares increased in new strategy
     * @param currentStrategy address of the strategy from which tokens are switched
     * @param newStrategy address of the strategy to which tokens are switched
     */
    event StrategySwitched(
        address indexed user,
        address indexed token,
        uint256 sharesDecreasedInCurrentStrategy,
        uint256 sharesIncreasedInNewStrategy,
        address currentStrategy,
        address indexed newStrategy
    );

    /**
     * @notice emitted when tokens are withdrawn from savings account
     * @param from address of user from which tokens are withdrawn
     * @param to address of user to which tokens are withdrawn
     * @param sharesWithdrawn amount of shares withdrawn
     * @param token address of token that is withdrawn
     * @param strategy strategy into which tokens are withdrawn
     * @param receiveShares flag to represent if shares are directly wirthdrawn
     */
    event Withdrawn(
        address indexed from,
        address indexed to,
        uint256 sharesWithdrawn,
        address indexed token,
        address strategy,
        bool receiveShares
    );

    /**
     * @notice emitted when all tokens are withdrawn
     * @param user address of user withdrawing tokens
     * @param tokenReceived amount of tokens withdrawn
     * @param token address of the token withdrawn
     */
    event WithdrawnAll(address indexed user, uint256 tokenReceived, address indexed token);

    /**
     * @notice emitted when tokens are approved
     * @param token address of token approved
     * @param from address of user from who tokens are approved
     * @param to address of user to whom tokens are approved
     * @param amount amount of tokens approved
     */
    event Approved(address indexed token, address indexed from, address indexed to, uint256 amount);

    /**
     * @notice emitted when tokens are transferred
     * @param token address of token transferred
     * @param strategy address of strategy from which tokens are transferred
     * @param from address of user from whom tokens are transferred
     * @param to address of user to whom tokens are transferred
     * @param amount amount of tokens transferred
     */
    event Transfer(address indexed token, address strategy, address indexed from, address indexed to, uint256 amount);

    /**
     * @notice emitted when tokens are transferred
     * @param token address of token transferred
     * @param strategy address of strategy from which tokens are transferred
     * @param from address of user from whom tokens are transferred
     * @param to address of user to whom tokens are transferred
     * @param shares amount of tokens transferred
     */
    event TransferShares(address indexed token, address strategy, address indexed from, address indexed to, uint256 shares);

    /**
     * @notice emitted when strategy registry is updated
     * @param updatedStrategyRegistry updated strategy registry address
     */
    event StrategyRegistryUpdated(address indexed updatedStrategyRegistry);

    function allowance(
        address user,
        address token,
        address to
    ) external returns (uint256 userAllowance);

    function deposit(
        address token,
        address strategy,
        address to,
        uint256 amount
    ) external returns (uint256 sharesReceived);

    /**
     * @dev Used to switch saving strategy of an token
     * @param currentStrategy initial strategy of token
     * @param newStrategy new strategy to invest
     * @param token address of the token
     * @param amount amount of tokens to be reinvested
     */
    function switchStrategy(
        address currentStrategy,
        address newStrategy,
        address token,
        uint256 amount
    ) external;

    /**
     * @dev Used to withdraw token from Saving Account
     * @param withdrawTo address to which token should be sent
     * @param amount amount of tokens to withdraw
     * @param token address of the token to be withdrawn
     * @param strategy strategy from where token has to withdrawn(ex:- compound,Aave etc)
     * @param receiveShares boolean indicating to withdraw in liquidity share or underlying token
     */
    function withdraw(
        address token,
        address strategy,
        address withdrawTo,
        uint256 amount,
        bool receiveShares
    ) external returns (uint256 amountWithdrawn);

    function withdrawAll(address token) external returns (uint256 tokenReceived);

    function withdrawAll(address token, address strategy) external returns (uint256 tokenReceived);

    function approve(
        address token,
        address to,
        uint256 amount
    ) external;

    function increaseAllowance(
        address token,
        address to,
        uint256 amount
    ) external;

    function decreaseAllowance(
        address token,
        address to,
        uint256 amount
    ) external;

    function transferShares(
        address _token,
        address _strategy,
        address _to,
        uint256 _shares
    ) external returns (uint256);

    function transfer(
        address token,
        address strategy,
        address to,
        uint256 amount
    ) external returns (uint256 tokensReceived);

    function transferSharesFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 _shares
    ) external returns (uint256);

    function transferFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 tokensReceived);

    function balanceInShares(
        address user,
        address token,
        address strategy
    ) external view returns (uint256 shareBalance);

    function withdrawFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 amount,
        bool receiveShares
    ) external returns (uint256 amountReceived);

    function withdrawShares(
        address token,
        address strategy,
        address to,
        uint256 shares,
        bool receiveShares
    ) external returns (uint256 amountReceived);

    function withdrawSharesFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 shares,
        bool receiveShares
    ) external returns (uint256 amountReceived);

    function getTotalTokens(address _user, address _token) external returns (uint256 _totalTokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '../interfaces/ISavingsAccount.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

library SavingsAccountUtil {
    using SafeERC20 for IERC20;

    function depositFromSavingsAccount(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount,
        bool _withdrawShares,
        bool _toSavingsAccount
    ) internal returns (uint256) {
        require(_token != address(0), 'SAU:IDFSA1');
        if (_toSavingsAccount) {
            return savingsAccountTransfer(_savingsAccount, _token, _strategy, _from, _to, _amount);
        } else {
            return withdrawFromSavingsAccount(_savingsAccount, _token, _strategy, _from, _to, _amount, _withdrawShares);
        }
    }

    function directDeposit(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount,
        bool _toSavingsAccount
    ) internal returns (uint256) {
        require(_token != address(0), 'SAU:IDD1');
        if (_toSavingsAccount) {
            return directSavingsAccountDeposit(_savingsAccount, _token, _strategy, _from, _to, _amount);
        } else {
            return transferTokens(_token, _from, _to, _amount);
        }
    }

    function directSavingsAccountDeposit(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256) {
        transferTokens(_token, _from, address(this), _amount);
        address _approveTo = _strategy;
        IERC20(_token).safeApprove(_approveTo, _amount);
        uint256 _sharesReceived = _savingsAccount.deposit(_token, _strategy, _to, _amount);
        return _sharesReceived;
    }

    function savingsAccountTransferShares(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _shares
    ) internal returns (uint256) {
        if (_from == address(this)) {
            _savingsAccount.transferShares(_token, _strategy, _to, _shares);
        } else {
            _savingsAccount.transferSharesFrom(_token, _strategy, _from, _to, _shares);
        }
        return _shares;
    }

    function savingsAccountTransfer(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256) {
        if (_from == address(this)) {
            return _savingsAccount.transfer(_token, _strategy, _to, _amount);
        } else {
            return _savingsAccount.transferFrom(_token, _strategy, _from, _to, _amount);
        }
    }

    function withdrawFromSavingsAccount(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount,
        bool _withdrawShares
    ) private returns (uint256) {
        uint256 _amountReceived;
        if (_from == address(this)) {
            _amountReceived = _savingsAccount.withdraw(_token, _strategy, _to, _amount, _withdrawShares);
        } else {
            _amountReceived = _savingsAccount.withdrawFrom(_token, _strategy, _from, _to, _amount, _withdrawShares);
        }
        return _amountReceived;
    }

    function transferTokens(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == 0) return 0;

        if (_from == address(this)) {
            IERC20(_token).safeTransfer(_to, _amount);
        } else {
            //pool
            IERC20(_token).safeTransferFrom(_from, _to, _amount);
        }
        return _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IStrategyRegistry {
    /**
     * @notice emitted when a strategy is added to registry
     * @param strategy address of the stratgy added
     */
    event StrategyAdded(address indexed strategy);

    /**
     * @notice emitted when a strategy is removed to registry
     * @param strategy address of the stratgy removed
     */
    event StrategyRemoved(address indexed strategy);

    /**
     * @notice emitted when a maximum number of approved strategies is updated
     * @param maxStrategies updated number of maximum approved strategies
     */
    event MaxStrategiesUpdated(uint256 maxStrategies);

    function registry(address _strategy) external view returns (uint256);

    function isValidStrategy(address strategy) external view returns (bool validStrategy);

    function getStrategies() external view returns (address[] memory strategies);

    /**
     * @dev Add strategies to invest in. Please ensure that number of strategies are less than maxStrategies.
     * @param strategy address of the owner of the savings account contract
     **/
    function addStrategy(address strategy) external;

    /**
     * @dev Remove strategy to invest in.
     * @param strategyIndex Index of the strategy to remove
     * @param strategyAddress Address of the strategy to remove
     **/
    function removeStrategy(uint256 strategyIndex, address strategyAddress) external;

    /**
     * @dev Update strategy to invest in.
     * @param _strategyIndex Index of the strategy to remove
     * @param _oldStrategy Strategy that is to be removed
     * @param _newStrategy Updated strategy
     **/
    function updateStrategy(
        uint256 _strategyIndex,
        address _oldStrategy,
        address _newStrategy
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ILenderPool {
    /**
     * @notice emitted when lender withdraws from pool of poole-credit-lines
     * @param amount amount that lender withdraws from borrow pool
     * @param lenderAddress address to which amount is withdrawn
     */
    event LiquidityWithdrawn(uint256 amount, address indexed lenderAddress);

    function create(
        uint256 _id,
        address _verifier,
        address _token,
        address _strategy,
        uint256 _borrowLimit,
        uint256 _minBorrowAmount,
        uint256 _collectionPeriod,
        bool _areTokensTransferable
    ) external;

    function start(uint256 _id) external;

    function borrowed(uint256 _id, uint256 _sharesBorrowed) external;

    function repaid(
        uint256 _id,
        uint256 _sharesRepaid,
        uint256 _interestShares
    ) external;

    function requestCancelled(uint256 _id) external;

    function terminate(uint256 id, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVerification {
    /// @notice Event emitted when a verifier is added as valid by admin
    /// @param verifier The address of the verifier contract to be added
    event VerifierAdded(address indexed verifier);

    /// @notice Event emitted when a verifier is to be marked as invalid by admin
    /// @param verifier The address of the verified contract to be marked as invalid
    event VerifierRemoved(address indexed verifier);

    /// @notice Event emitted when a master address is verified by a valid verifier
    /// @param masterAddress The masterAddress which is verifier by the verifier
    /// @param verifier The verifier which verified the masterAddress
    /// @param activatesAt Timestamp at which master address is considered active after the cooldown period
    event UserRegistered(address indexed masterAddress, address indexed verifier, uint256 activatesAt);

    /// @notice Event emitted when a master address is marked as invalid/unregisterd by a valid verifier
    /// @param masterAddress The masterAddress which is unregistered
    /// @param verifier The verifier which verified the masterAddress
    /// @param unregisteredBy The msg.sender by which the user was unregistered
    event UserUnregistered(address indexed masterAddress, address indexed verifier, address indexed unregisteredBy);

    /// @notice Event emitted when an address is linked to masterAddress
    /// @param linkedAddress The address which is linked to masterAddress
    /// @param masterAddress The masterAddress to which address is linked
    /// @param activatesAt Timestamp at which linked address is considered active after the cooldown period
    event AddressLinked(address indexed linkedAddress, address indexed masterAddress, uint256 activatesAt);

    /// @notice Event emitted when an address is unlinked from a masterAddress
    /// @param linkedAddress The address which is linked to masterAddress
    /// @param masterAddress The masterAddress to which address was linked
    event AddressUnlinked(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when master address placed a request to link another address to itself
    /// @param linkedAddress The address which is to be linked to masterAddress
    /// @param masterAddress The masterAddress to which address is to be linked
    event AddressLinkingRequested(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when master address cancels the request placed to link another address to itself
    /// @param linkedAddress The address which is to be linked to masterAddress
    /// @param masterAddress The masterAddress to which address is to be linked
    event AddressLinkingRequestCancelled(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when activation delay is updated
    /// @param activationDelay updated value of activationDelay in seconds
    event ActivationDelayUpdated(uint256 activationDelay);

    function isUser(address _user, address _verifier) external view returns (bool isMsgSenderUser);

    function verifiers(address _verifier) external view returns (bool isValid);

    function registerMasterAddress(address _masterAddress, bool _isMasterLinked) external;

    function unregisterMasterAddress(address _masterAddress, address _verifier) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '../interfaces/IPooledCreditLineDeclarations.sol';

interface IPooledCreditLine is IPooledCreditLineDeclarations {
    function accept(uint256 _id, uint256 _amount) external;

    function getPrincipal(uint256 _id) external view returns (uint256);

    function getEndsAt(uint256 _id) external view returns (uint256);

    function getStatusAndUpdate(uint256 _id) external returns (PooledCreditLineStatus);

    function liquidate(uint256 _id) external returns (address, uint256);

    function cancelRequestOnLowCollection(uint256 _id) external;

    function cancelRequestOnRequestedStateAtEnd(uint256 _id) external returns (bool _isCancelled);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import './IPooledCreditLineEnums.sol';

interface IPooledCreditLineDeclarations is IPooledCreditLineEnums {
    /**
     * @notice Struct containing various parameters needed to initialize a pooled credit line
     * @param collateralRatio Ratio of collateral value to debt above which liquidations can happen
     * @param duration time for which pooled credit line will stay active
     * @param lenderVerifier verifier with which lender should be verified
     * @param defaultGracePeriod time given after duration of pooled credit line ends as grace period   
        only after which liquidations can happen
     * @param gracePenaltyRate Extra interest rate levied for repayments during grace period
     * @param collectionPeriod time for which lenders can lend to pooled credit line until borrow limit is reached
     * @param minBorrowAmount min amount of borrow tokens below which pooled credit line will be cancelled
     * @param borrowLimit Max amount of borrow tokens requested by borrower
     * @param borrowRate Interest rate at which tokens can be borrowed from pooled credit line
     * @param collateralAsset address of token which is used as collateral
     * @param borrowAssetStrategy address of strategy into which borrow tokens are deposited
     * @param collateralAssetStrategy address  of strategy into which collateral tokens are depositeds
     * @param borrowAsset address of token that is borrowed
     * @param borrowerVerifier verifier with which borrower needs to be verified
     * @param areTokensTransferable flag that represents if the pooled credit line tokens which represents 
        borrower share are transferable
     */
    struct Request {
        uint256 collateralRatio;
        uint256 duration;
        address lenderVerifier;
        uint256 defaultGracePeriod;
        uint256 gracePenaltyRate;
        uint256 collectionPeriod;
        uint256 minBorrowAmount;
        uint128 borrowLimit;
        uint128 borrowRate;
        address collateralAsset;
        address borrowAssetStrategy;
        address collateralAssetStrategy;
        address borrowAsset;
        address borrowerVerifier;
        bool areTokensTransferable;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IPooledCreditLineEnums {
    enum PooledCreditLineStatus {
        NOT_CREATED,
        REQUESTED,
        ACTIVE,
        CLOSED,
        EXPIRED,
        LIQUIDATED,
        CANCELLED
    }
}