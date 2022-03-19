// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../interfaces/IPriceOracle.sol';
import '../interfaces/IYield.sol';
import '../interfaces/ISavingsAccount.sol';
import '../interfaces/IStrategyRegistry.sol';
import '../interfaces/ICreditLine.sol';

/**
 * @title Credit Line contract with Methods related to creditLines
 * @notice Implements the functions related to Credit Line
 * @author Sublime
 **/

contract CreditLine is ReentrancyGuardUpgradeable, OwnableUpgradeable, ICreditline {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //-------------------------------- Constants start --------------------------------//

    // number of seconds in an year
    uint256 constant YEAR_IN_SECONDS = 365 days;

    // Factor to multiply variables to maintain precision
    uint256 constant SCALING_FACTOR = 1e18;

    // address of USDC contract
    address immutable USDC;

    //-------------------------------- Constants end --------------------------------//

    //-------------------------------- Global vars starts --------------------------------//

    /**
     * @notice stores the address of savings account contract
     **/
    address public savingsAccount;

    /**
     * @notice stores the address of price oracle contract
     **/
    address public priceOracle;

    /**
     * @notice stores the address of strategy registry contract
     **/
    address public strategyRegistry;

    /**
     * @notice stores the address of default strategy
     **/
    address public defaultStrategy;

    /**
     * @notice stores the fraction of borrowed amount charged as fee by protocol
     * @dev it is multiplied by SCALING_FACTOR to maintain precision
     **/
    uint256 public protocolFeeFraction;

    /**
     * @notice address where protocol fee is collected
     **/
    address public protocolFeeCollector;

    /**
     * @notice stores the fraction of amount liquidated given as reward to liquidator
     * @dev it is multiplied by SCALING_FACTOR to maintain precision
     **/
    uint256 public liquidatorRewardFraction;

    //-------------------------------- Global vars ends --------------------------------//

    //-------------------------------- Variable limits starts --------------------------------//

    /*
     * @notice Used to define limits for the credit line parameters
     * @param min the minimum threshold for the parameter
     * @param max the maximum threshold for the parameter
     */
    struct Limits {
        uint256 min;
        uint256 max;
    }

    /*
     * @notice Used to set the min/max borrow limits for credit lines
     */
    Limits public borrowLimitLimits;

    /*
     * @notice Used to set the min/max collateral ratio for credit lines
     * @dev multiplied by SCALING_FACTOR to maintain precision
     */
    Limits public idealCollateralRatioLimits;

    /*
     * @notice Used to set the min/max borrow rate for credit lines
     * @dev multiplied by SCALING_FACTOR to maintain precision
     */
    Limits public borrowRateLimits;

    //-------------------------------- Variable limits ends --------------------------------//

    //-------------------------------- CreditLine state starts --------------------------------//

    /**
     * @notice Various states a credit line can be in
     */
    enum CreditLineStatus {
        NOT_CREATED,
        REQUESTED,
        ACTIVE
    }

    /**
    * @notice Struct to store all the variables for a credit line
    * @param status Represents the status of credit line
    * @param principal total principal borrowed in credit line
    * @param totalInterestRepaid total interest repaid in the credit line
    * @param lastPrincipalUpdateTime timestamp when principal was last updated. Principal is 
                updated on borrow or repay
    * @param interestAccruedTillLastPrincipalUpdate interest accrued till last time principal was updated
     */
    struct CreditLineVariables {
        CreditLineStatus status;
        uint256 principal;
        uint256 totalInterestRepaid;
        uint256 lastPrincipalUpdateTime;
        uint256 interestAccruedTillLastPrincipalUpdate;
    }

    /**
    * @notice Struct to store all the constants for a credit line
    * @dev only borrowLimit can be updated by lender
    * @param autoLiquidation if true, anyone can liquidate if collateral ratio is below threshold
    * @param requestByLender if true, lender else borrower created credit line request 
    * @param borrowLimit max amount of borrowAsset that can be borrowed in aggregate at any point
    * @param borrowRate Rate of interest multiplied by SCALING_FACTOR
    * @param idealCollateralRatio ratio of collateral to debt below which collateral is 
                                    liquidated multiplied by SCALING_FACTOR
    * @param lender address of the lender of credit line
    * @param borrower address of the borrower of credit line
    * @param borrowAsset address of asset borrowed in credit line
    * @param collateralAsset address of asset collateralized in credit line
    * @param collateralStrategy address of the strategy into which collateral is deposited
     */
    struct CreditLineConstants {
        bool autoLiquidation;
        bool requestByLender;
        uint128 borrowLimit;
        uint128 borrowRate;
        uint256 idealCollateralRatio;
        address lender;
        address borrower;
        address borrowAsset;
        address collateralAsset;
        address collateralStrategy;
    }

    /**
     * @notice counter that tracks the number of credit lines created
     * @dev used to create unique identifier for credit lines
     **/
    uint256 public creditLineCounter;

    /**
     * @notice stores the collateral shares in collateral strategy
     * @dev creditLineId => collateralShares
     **/
    mapping(uint256 => uint256) public collateralShareInStrategy;

    /**
     * @notice stores the variables to maintain a credit line
     **/
    mapping(uint256 => CreditLineVariables) public creditLineVariables;

    /**
     * @notice stores the constants related to a credit line
     **/
    mapping(uint256 => CreditLineConstants) public creditLineConstants;

    //-------------------------------- CreditLine State ends --------------------------------//

    //-------------------------------- Modifiers start --------------------------------//

    /**
     * @dev checks if called by credit Line Borrower
     * @param _id identifier for the credit line
     **/
    modifier onlyCreditLineBorrower(uint256 _id) {
        require(creditLineConstants[_id].borrower == msg.sender, 'OCLB1');
        _;
    }

    /**
     * @dev checks if called by credit Line Lender
     * @param _id identifier for the credit line
     **/
    modifier onlyCreditLineLender(uint256 _id) {
        require(creditLineConstants[_id].lender == msg.sender, 'OCLL1');
        _;
    }

    //-------------------------------- Modifiers end --------------------------------//

    //-------------------------------- Events start --------------------------------//

    //--------------------------- Limits event start ---------------------------//

    /**
     * @notice emitted when threhsolds for one of the parameters (borrowLimitLimits, idealCollateralRatioLimits, borrowRateLimits) is updated
     * @param limitType specifies the parameter whose limits are being updated
     * @param max maximum threshold value for limitType
     * @param min minimum threshold value for limitType
     */
    event LimitsUpdated(string indexed limitType, uint256 max, uint256 min);

    //--------------------------- Limits event end ---------------------------//

    //--------------------------- Global variable update events start ---------------------------//

    /**
     * @notice emitted when default strategy for the credit line is updated
     * @param defaultStrategy address of the strategy contract that is used as default by credit lines
     */
    event DefaultStrategyUpdated(address indexed defaultStrategy);

    /**
     * @notice emitted when the price oracle is updated
     * @param priceOracle address of the updated price oracle
     */
    event PriceOracleUpdated(address indexed priceOracle);

    /**
     * @notice emitted when the savings account address is updated
     * @param savingsAccount address of the updated savingsAccount
     */
    event SavingsAccountUpdated(address indexed savingsAccount);

    /**
     * @notice emitted when strategy registry address is updated
     * @param strategyRegistry address of the updated strategy registry
     */
    event StrategyRegistryUpdated(address indexed strategyRegistry);

    /**
     * @notice emitted when fee that protocol charges for credit line is updated
     * @dev updatedProtocolFee is scaled by SCALING_FACTOR
     * @param updatedProtocolFee updated value of protocolFeeFraction
     */
    event ProtocolFeeFractionUpdated(uint256 updatedProtocolFee);

    /**
     * @notice emitted when address which receives fee that protocol changes for pools is updated
     * @param updatedProtocolFeeCollector updated value of protocolFeeCollector
     */
    event ProtocolFeeCollectorUpdated(address indexed updatedProtocolFeeCollector);

    /**
     * @notice emitted when liquidatorRewardFraction is updated
     * @dev liquidatorRewardFraction is scaled by SCALING_FACTOR
     * @param liquidatorRewardFraction fraction of the liquidated amount given as reward to the liquidator
     */
    event LiquidationRewardFractionUpdated(uint256 liquidatorRewardFraction);

    //--------------------------- Global variable update events end ---------------------------//

    //--------------------------- CreditLine state events start ---------------------------//

    /**
     * @notice emitted when a collateral is deposited into credit line
     * @param id identifier for the credit line
     * @param amount amount of collateral deposited
     * @param strategy address of the strategy into which collateral is deposited
     */
    event CollateralDeposited(uint256 indexed id, uint256 amount, address indexed strategy);

    /**
     * @notice emitted when collateral is withdrawn from credit line
     * @param id identifier for the credit line
     * @param amount amount of collateral withdrawn
     */
    event CollateralWithdrawn(uint256 indexed id, uint256 amount);

    /**
     * @notice emitted when a request for new credit line is placed
     * @param id identifier for the credit line for which request was made
     * @param lender address of the lender for credit line
     * @param borrower address of the borrower for credit line
     * @param requestByLender true if lender made request, false if borrower did
     */
    event CreditLineRequested(uint256 indexed id, address indexed lender, address indexed borrower, bool requestByLender);

    /**
     * @notice emitted when a credit line is liquidated
     * @param id identifier for the credit line which is liquidated
     * @param liquidator address of the liquidator
     */
    event CreditLineLiquidated(uint256 indexed id, address indexed liquidator);

    /**
     * @notice emitted when tokens are borrowed from credit line
     * @param id identifier for the credit line from which tokens are borrowed
     * @param borrowAmount amount of tokens borrowed
     */
    event BorrowedFromCreditLine(uint256 indexed id, uint256 borrowAmount);

    /**
     * @notice emitted when credit line is accepted
     * @param id identifier for the credit line that was accepted
     */
    event CreditLineAccepted(uint256 indexed id);

    /**
     * @notice emitted when credit line is completely repaid and reset
     * @param id identifier for the credit line that is reset
     */
    event CreditLineReset(uint256 indexed id);

    /**
     * @notice emitted when the credit line is partially repaid
     * @param id identifier for the credit line
     * @param repayer address of the repayer
     * @param repayAmount amount repaid
     */
    event PartialCreditLineRepaid(uint256 indexed id, address indexed repayer, uint256 repayAmount);

    /**
     * @notice emitted when the credit line is completely repaid
     * @param id identifier for the credit line
     * @param repayer address of the repayer
     * @param repayAmount amount repaid
     */
    event CompleteCreditLineRepaid(uint256 indexed id, address indexed repayer, uint256 repayAmount);

    /**
     * @notice emitted when credit line is cancelled
     * @param id id of the credit line that was cancelled
     */
    event CreditLineCancelled(uint256 indexed id);

    /**
     * @notice emitted when the credit line is closed by one of the parties of credit line
     * @param id identifier for the credit line
     * @param closedByLender is true when it is closed by lender
     */
    event CreditLineClosed(uint256 indexed id, bool closedByLender);

    /**
     * @notice emitted when the borrow limit is updated for the credit line
     * @param id identifier for the credit line
     * @param updatedBorrowLimit updated value of borrow limit
     */
    event BorrowLimitUpdated(uint256 id, uint128 updatedBorrowLimit);

    //--------------------------- CreditLine state events end ---------------------------//

    //-------------------------------- Events end --------------------------------//

    //-------------------------------- Limits code starts --------------------------------//

    /**
     * @notice invoked to check if credit lines parameters are within thresholds
     * @param _value supplied value of the parameter
     * @param _min minimum threshold of the parameter
     * @param _max maximum threshold of the parameter
     */
    function isWithinLimits(
        uint256 _value,
        uint256 _min,
        uint256 _max
    ) internal pure returns (bool) {
        if (_min != 0 && _max != 0) {
            return (_value >= _min && _value <= _max);
        } else if (_min != 0) {
            return (_value >= _min);
        } else if (_max != 0) {
            return (_value <= _max);
        } else {
            return true;
        }
    }

    function _limitBorrowedInUSD(address _borrowToken, uint256 _borrowLimit) internal view {
        (uint256 _ratioOfPrices, uint256 _decimals) = IPriceOracle(priceOracle).getLatestPrice(_borrowToken, USDC);
        uint256 _poolsizeInUSD = _borrowLimit.mul(_ratioOfPrices).div(10**_decimals);
        require(isWithinLimits(_poolsizeInUSD, borrowLimitLimits.min, borrowLimitLimits.max), 'ILB1');
    }

    /**
     * @notice used to update the thresholds of the borrow limit of the credit line
     * @param _min updated value of the minimum threshold value of the borrow limit in lowest units of USDC
     * @param _max updated value of the maximum threshold value of the borrow limit in lowest units of USDC
     */
    function updateBorrowLimitLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min < _max, 'UBLL1');
        if (borrowLimitLimits.min == _min && borrowLimitLimits.max == _max) {
            require(false, 'Same values used for update');
        }
        borrowLimitLimits = Limits(_min, _max);
        emit LimitsUpdated('borrowLimit', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the ideal collateral ratio of the credit line
     * @dev ideal collateral ratio limits are multiplied by SCALING_FACTOR
     * @param _min updated value of the minimum threshold value of the ideal collateral ratio
     * @param _max updated value of the maximum threshold value of the ideal collateral ratio
     */
    function updateIdealCollateralRatioLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min < _max, 'UICRL1');
        if (idealCollateralRatioLimits.min == _min && idealCollateralRatioLimits.max == _max) {
            require(false, 'Same values used for update');
        }
        idealCollateralRatioLimits = Limits(_min, _max);
        emit LimitsUpdated('idealCollateralRatio', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the borrow rate of the credit line
     * @dev borrow rate limits are multiplied by SCALING_FACTOR
     * @param _min updated value of the minimum threshold value of the borrow rate
     * @param _max updated value of the maximum threshold value of the borrow rate
     */
    function updateBorrowRateLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min < _max, 'UBRL1');
        if (borrowRateLimits.min == _min && borrowRateLimits.max == _max) {
            require(false, 'Same values used for update');
        }
        borrowRateLimits = Limits(_min, _max);
        emit LimitsUpdated('borrowRate', _min, _max);
    }

    //-------------------------------- Limits code end --------------------------------//

    //-------------------------------- Global var update code start --------------------------------//

    /**
     * @notice used to update the default strategy
     * @dev can only be updated by owner
     * @param _defaultStrategy address of the updated default strategy
     */
    function updateDefaultStrategy(address _defaultStrategy) external onlyOwner {
        require(defaultStrategy != _defaultStrategy, 'Same value used for update');
        _updateDefaultStrategy(_defaultStrategy);
    }

    function _updateDefaultStrategy(address _defaultStrategy) internal {
        require(IStrategyRegistry(strategyRegistry).registry(_defaultStrategy) != 0, 'IUDS1');
        defaultStrategy = _defaultStrategy;
        emit DefaultStrategyUpdated(_defaultStrategy);
    }

    /**
     * @notice used to update the price oracle
     * @dev can only be updated by owner
     * @param _priceOracle address of the updated price oracle
     */
    function updatePriceOracle(address _priceOracle) external onlyOwner {
        require(priceOracle != _priceOracle, 'Same value used for update');
        _updatePriceOracle(_priceOracle);
    }

    function _updatePriceOracle(address _priceOracle) internal {
        require(_priceOracle != address(0), 'Price Oracle cannot be updated to 0');
        priceOracle = _priceOracle;
        emit PriceOracleUpdated(_priceOracle);
    }

    /**
     * @notice used to update the savings account address
     * @dev can only be updated by owner
     * @param _savingsAccount address of the updated savings account
     */
    function updateSavingsAccount(address _savingsAccount) external onlyOwner {
        require(savingsAccount != _savingsAccount, 'Same value used for update');
        _updateSavingsAccount(_savingsAccount);
    }

    function _updateSavingsAccount(address _savingsAccount) internal {
        require(_savingsAccount != address(0), 'Savings Account cannot be updated to 0');
        savingsAccount = _savingsAccount;
        emit SavingsAccountUpdated(_savingsAccount);
    }

    /**
     * @notice used to update the protocol fee fraction
     * @dev can only be updated by owner. Scaled by SCALING_FACTOR
     * @param _protocolFee fraction of the borrower amount collected as protocol fee
     */
    function updateProtocolFeeFraction(uint256 _protocolFee) external onlyOwner {
        require(protocolFeeFraction != _protocolFee, 'Same value used for update');
        _updateProtocolFeeFraction(_protocolFee);
    }

    function _updateProtocolFeeFraction(uint256 _protocolFee) internal {
        require(_protocolFee <= SCALING_FACTOR, 'IUPFF1');
        require(_protocolFee != 0, 'Protocol fee cannot be updated to 0');
        protocolFeeFraction = _protocolFee;
        emit ProtocolFeeFractionUpdated(_protocolFee);
    }

    /**
     * @notice used to update the protocol fee collector
     * @dev can only be updated by owner
     * @param _protocolFeeCollector address in which protocol fee is collected
     */
    function updateProtocolFeeCollector(address _protocolFeeCollector) external onlyOwner {
        require(protocolFeeCollector != _protocolFeeCollector, 'Same value used for update');
        _updateProtocolFeeCollector(_protocolFeeCollector);
    }

    function _updateProtocolFeeCollector(address _protocolFeeCollector) internal {
        require(_protocolFeeCollector != address(0), 'IUPFC1');
        protocolFeeCollector = _protocolFeeCollector;
        emit ProtocolFeeCollectorUpdated(_protocolFeeCollector);
    }

    /**
     * @notice used to update the strategy registry address
     * @dev can only be updated by owner
     * @param _strategyRegistry address of the updated strategy registry
     */
    function updateStrategyRegistry(address _strategyRegistry) external onlyOwner {
        require(strategyRegistry != _strategyRegistry, 'Same value used for update');
        _updateStrategyRegistry(_strategyRegistry);
    }

    function _updateStrategyRegistry(address _strategyRegistry) internal {
        require(_strategyRegistry != address(0), 'IUSR1');
        strategyRegistry = _strategyRegistry;
        emit StrategyRegistryUpdated(_strategyRegistry);
    }

    /**
     * @notice used to update the liquidatorRewardFraction
     * @dev can only be updated by owner. Scaled by SCALING_FACTOR
     * @param _rewardFraction fraction of liquidated amount given to liquidator as reward
     */
    function updateLiquidatorRewardFraction(uint256 _rewardFraction) external onlyOwner {
        require(liquidatorRewardFraction != _rewardFraction, 'Same value used for update');
        _updateLiquidatorRewardFraction(_rewardFraction);
    }

    function _updateLiquidatorRewardFraction(uint256 _rewardFraction) internal {
        require(_rewardFraction <= SCALING_FACTOR, 'IULRF1');
        require(_rewardFraction != 0, 'Reward fraction cannot be updated to 0');
        liquidatorRewardFraction = _rewardFraction;
        emit LiquidationRewardFractionUpdated(_rewardFraction);
    }

    //-------------------------------- Global var update code end --------------------------------//

    //-------------------------------- Initialize code start --------------------------------//

    /**
     * @notice used to initialize the immutables in contract
     * @param _usdc address of usdc contract
     */
    constructor(address _usdc) {
        USDC = _usdc;
    }

    /**
     * @notice used to initialize the contract
     * @dev can only be called once during the life cycle of the contract
     * @param _defaultStrategy default strategy used in credit lines
     * @param _priceOracle address of the priceOracle
     * @param _savingsAccount address of  the savings account contract
     * @param _strategyRegistry address of the strategy registry contract
     * @param _owner address of owner who can change global variables
     * @param _protocolFeeFraction fraction of the fee charged by protocol. Scaled by SCALING_FACTOR
     * @param _protocolFeeCollector address to which protocol fee is charged to
     * @param _liquidatorRewardFraction fraction of the liquidated amount given as reward to the liquidator.
                                        Scaled by SCALING_FACTOR
     */
    function initialize(
        address _defaultStrategy,
        address _priceOracle,
        address _savingsAccount,
        address _strategyRegistry,
        address _owner,
        uint256 _protocolFeeFraction,
        address _protocolFeeCollector,
        uint256 _liquidatorRewardFraction
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        OwnableUpgradeable.transferOwnership(_owner);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        _updateStrategyRegistry(_strategyRegistry);
        _updateSavingsAccount(_savingsAccount);
        _updatePriceOracle(_priceOracle);
        _updateDefaultStrategy(_defaultStrategy);
        _updateProtocolFeeFraction(_protocolFeeFraction);
        _updateProtocolFeeCollector(_protocolFeeCollector);
        _updateLiquidatorRewardFraction(_liquidatorRewardFraction);
    }

    //-------------------------------- Initialize code end --------------------------------//

    //-------------------------------- CreditLine creation code start --------------------------------//

    /**
     * @notice used to request a credit line either by borrower or lender
     * @param _requestTo Address to which creditLine is requested, 
                        if borrower creates request then lender address and 
                        if lender creates then borrower address
     * @param _borrowLimit maximum borrow amount in a credit line
     * @param _borrowRate Interest Rate at which credit Line is requested. Scaled by SCALING_FACTOR
     * @param _autoLiquidation if true, anyone can liquidate loan, otherwise only lender
     * @param _collateralRatio ratio of the collateral to the debt below which credit line can be liquidated.
                                Scaled by SCALING_FACTOR
     * @param _borrowAsset address of the token to be borrowed
     * @param _collateralAsset address of the token provided as collateral
     * @param _requestAsLender if true, lender is placing request, otherwise borrower
     * @return identifier for the credit line
     */
    function request(
        address _requestTo,
        uint128 _borrowLimit,
        uint128 _borrowRate,
        bool _autoLiquidation,
        uint256 _collateralRatio,
        address _borrowAsset,
        address _collateralAsset,
        address _collateralStrategy,
        bool _requestAsLender
    ) external returns (uint256) {
        require(_borrowAsset != _collateralAsset, 'R1');
        require(_requestTo != address(0), 'R: cannot request credit line to address 0');
        require(IPriceOracle(priceOracle).doesFeedExist(_borrowAsset, _collateralAsset), 'R2');
        _limitBorrowedInUSD(_borrowAsset, _borrowLimit);
        require(isWithinLimits(_borrowRate, borrowRateLimits.min, borrowRateLimits.max), 'R3');
        require(isWithinLimits(_collateralRatio, idealCollateralRatioLimits.min, idealCollateralRatioLimits.max), 'R4');
        require(IStrategyRegistry(strategyRegistry).registry(_collateralStrategy) != 0, 'R5');

        address _lender = _requestTo;
        address _borrower = msg.sender;
        if (_requestAsLender) {
            _lender = msg.sender;
            _borrower = _requestTo;
        }

        require(_lender != _borrower, 'R7');

        uint256 _id = _createRequest(
            _lender,
            _borrower,
            _borrowLimit,
            _borrowRate,
            _autoLiquidation,
            _collateralRatio,
            _borrowAsset,
            _collateralAsset,
            _collateralStrategy,
            _requestAsLender
        );

        emit CreditLineRequested(_id, _lender, _borrower, _requestAsLender);
        return _id;
    }

    function _createRequest(
        address _lender,
        address _borrower,
        uint128 _borrowLimit,
        uint128 _borrowRate,
        bool _autoLiquidation,
        uint256 _collateralRatio,
        address _borrowAsset,
        address _collateralAsset,
        address _collateralStrategy,
        bool _requestByLender
    ) internal returns (uint256) {
        require(_lender != _borrower, 'ICR1');
        uint256 _id = ++creditLineCounter;
        creditLineVariables[_id].status = CreditLineStatus.REQUESTED;
        creditLineConstants[_id].borrower = _borrower;
        creditLineConstants[_id].lender = _lender;
        creditLineConstants[_id].borrowLimit = _borrowLimit;
        creditLineConstants[_id].autoLiquidation = _autoLiquidation;
        creditLineConstants[_id].idealCollateralRatio = _collateralRatio;
        creditLineConstants[_id].borrowRate = _borrowRate;
        creditLineConstants[_id].borrowAsset = _borrowAsset;
        creditLineConstants[_id].collateralAsset = _collateralAsset;
        creditLineConstants[_id].collateralStrategy = _collateralStrategy;
        creditLineConstants[_id].requestByLender = _requestByLender;
        return _id;
    }

    /**
     * @notice used to accept a credit line
     * @dev if borrower places request, lender can accept and vice versa
     * @param _id identifier for the credit line
     */
    function accept(uint256 _id) external {
        require(creditLineVariables[_id].status == CreditLineStatus.REQUESTED, 'A1');
        bool _requestByLender = creditLineConstants[_id].requestByLender;
        require(
            _requestByLender ? (msg.sender == creditLineConstants[_id].borrower) : (msg.sender == creditLineConstants[_id].lender),
            'A2'
        );
        creditLineVariables[_id].status = CreditLineStatus.ACTIVE;
        emit CreditLineAccepted(_id);
    }

    //-------------------------------- CreditLine creation code end --------------------------------//

    //-------------------------------- Collateral management start --------------------------------//

    /**
     * @notice used to deposit collateral into the credit line
     * @dev collateral tokens have to be approved in savingsAccount or token contract
     * @param _id identifier for the credit line
     * @param _amount amount of collateral being deposited
     * @param _fromSavingsAccount if true, tokens are transferred from savingsAccount 
                                otherwise direct from collateral token contract
     */
    function depositCollateral(
        uint256 _id,
        uint256 _amount,
        bool _fromSavingsAccount
    ) external override nonReentrant {
        require(creditLineVariables[_id].status == CreditLineStatus.ACTIVE, 'DC1');
        require(creditLineConstants[_id].lender != msg.sender, 'DC2');

        address _collateralAsset = creditLineConstants[_id].collateralAsset;
        address _strategy = creditLineConstants[_id].collateralStrategy;
        ISavingsAccount _savingsAccount = ISavingsAccount(savingsAccount);
        uint256 _sharesDeposited;

        if (_fromSavingsAccount) {
            _sharesDeposited = _savingsAccount.transferFrom(_collateralAsset, _strategy, msg.sender, address(this), _amount);
        } else {
            IERC20(_collateralAsset).safeTransferFrom(msg.sender, address(this), _amount);
            IERC20(_collateralAsset).approve(_strategy, _amount);

            _sharesDeposited = _savingsAccount.deposit(_collateralAsset, _strategy, address(this), _amount);
        }
        collateralShareInStrategy[_id] = collateralShareInStrategy[_id].add(_sharesDeposited);

        emit CollateralDeposited(_id, _amount, _strategy);
    }

    /**
     * @notice used to withdraw any excess collateral
     * @dev collateral can't be withdraw if collateralRatio goes below the ideal value. Only borrower can withdraw
     * @param _id identifier for the credit line
     * @param _amount amount of collateral to withdraw
     * @param _toSavingsAccount if true, tokens are transferred from savingsAccount 
                                otherwise direct from collateral token contract
     */
    function withdrawCollateral(
        uint256 _id,
        uint256 _amount,
        bool _toSavingsAccount
    ) external nonReentrant onlyCreditLineBorrower(_id) {
        uint256 _currentWithdrawableCollateral = withdrawableCollateral(_id);
        require(_amount <= _currentWithdrawableCollateral, 'WC1');
        _transferCollateral(_id, creditLineConstants[_id].collateralAsset, msg.sender, _amount, _toSavingsAccount);
        emit CollateralWithdrawn(_id, _amount);
    }

    /**
     * @notice used to withdraw all the permissible collateral as per the current col ratio
     * @dev if the withdrawable collateral amount is non-zero the transaction will pass
     * @param _id identifier for the credit line
    * @param _toSavingsAccount if true, tokens are transferred from savingsAccount 
                                otherwise direct from collateral token contract
     */
    function withdrawCollateral(uint256 _id, bool _toSavingsAccount) external nonReentrant onlyCreditLineBorrower(_id) {
        _withdrawCollateral(_id, msg.sender, _toSavingsAccount);
    }

    function _withdrawCollateral(
        uint256 _id,
        address _to,
        bool _toSavingsAccount
    ) internal {
        uint256 _currentWithdrawableCollateral = withdrawableCollateral(_id);
        _transferCollateral(_id, creditLineConstants[_id].collateralAsset, _to, _currentWithdrawableCollateral, _toSavingsAccount);
        emit CollateralWithdrawn(_id, _currentWithdrawableCollateral);
    }

    /**
     * @notice used to calculate the collateral that can be withdrawn
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view
     * @param _id identifier for the credit line
     * @return total collateral withdrawable by borrower
     */
    function withdrawableCollateral(uint256 _id) public returns (uint256) {
        uint256 _ratioOfPrices;
        uint256 _decimals;
        uint256 _totalCollateralTokens;
        {
            // avoids stack too deep by restricting scope of _collateralAsset
            address _collateralAsset = creditLineConstants[_id].collateralAsset;
            _totalCollateralTokens = _calculateTotalCollateralTokens(_id, _collateralAsset);

            (_ratioOfPrices, _decimals) = IPriceOracle(priceOracle).getLatestPrice(_collateralAsset, creditLineConstants[_id].borrowAsset);
        }
        uint256 _currentDebt = calculateCurrentDebt(_id);

        uint256 _collateralNeeded = _currentDebt
            .mul(creditLineConstants[_id].idealCollateralRatio)
            .mul(10**_decimals)
            .div(_ratioOfPrices)
            .div(SCALING_FACTOR);

        if (_collateralNeeded >= _totalCollateralTokens) return 0;

        return _totalCollateralTokens.sub(_collateralNeeded);
    }

    function _transferCollateral(
        uint256 _id,
        address _asset,
        address _to,
        uint256 _amountInTokens,
        bool _toSavingsAccount
    ) internal {
        address _strategy = creditLineConstants[_id].collateralStrategy;
        uint256 _amountInShares = IYield(_strategy).getSharesForTokens(_amountInTokens, _asset);
        ISavingsAccount _savingsAccount = ISavingsAccount(savingsAccount);

        collateralShareInStrategy[_id] = collateralShareInStrategy[_id].sub(_amountInShares);

        if (_toSavingsAccount) {
            _savingsAccount.transferShares(_amountInShares, _asset, _strategy, _to);
        } else {
            _savingsAccount.withdrawShares(_asset, _strategy, _to, _amountInShares, false);
        }
    }

    //-------------------------------- Collateral management end --------------------------------//

    //-------------------------------- Borrow code start --------------------------------//

    /**
     * @notice used to update the borrow limit of the creditLine
     * @dev can only be updated by lender
     * @param _id identifier for the credit line
     * @param _newBorrowLimit updated value of the borrow limit for the credit line
     */
    function updateBorrowLimit(uint256 _id, uint128 _newBorrowLimit) external onlyCreditLineLender(_id) {
        creditLineConstants[_id].borrowLimit = _newBorrowLimit;
        emit BorrowLimitUpdated(_id, _newBorrowLimit);
    }

    /**
     * @notice used to calculate amount that can be borrowed by the borrower
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view.
            borrowableAmount changes per block as interest changes per block.
     * @param _id identifier for the credit line
     * @return amount that can be borrowed from the credit line
     */
    function calculateBorrowableAmount(uint256 _id) public returns (uint256) {
        CreditLineStatus _status = creditLineVariables[_id].status;
        require(_status == CreditLineStatus.ACTIVE || _status == CreditLineStatus.REQUESTED, 'CBA1');
        address _collateralAsset = creditLineConstants[_id].collateralAsset;
        (uint256 _ratioOfPrices, uint256 _decimals) = IPriceOracle(priceOracle).getLatestPrice(
            _collateralAsset,
            creditLineConstants[_id].borrowAsset
        );

        uint256 _totalCollateralToken = _calculateTotalCollateralTokens(_id, _collateralAsset);

        uint256 _collateralRatio = creditLineConstants[_id].idealCollateralRatio;
        uint256 _maxPossible = type(uint256).max;
        if (_collateralRatio != 0) {
            _maxPossible = _totalCollateralToken.mul(_ratioOfPrices).div(_collateralRatio).mul(SCALING_FACTOR).div(10**_decimals);
        }

        uint256 _borrowLimit = creditLineConstants[_id].borrowLimit;

        if (_maxPossible > _borrowLimit) _maxPossible = _borrowLimit;

        uint256 _currentDebt = calculateCurrentDebt(_id);
        if (_maxPossible > _currentDebt) return (_maxPossible - _currentDebt);

        return 0;
    }

    /**
    @dev Used to withdraw the borrow amount by the borrower from the list of different strategies where the borrow tokens are deposited.
        Implicitly implies that the borrower isn't necessarily borrowing entire borrowable amount, but only the _amountInTokens amount
     */
    function _withdrawBorrowAmount(
        address _asset,
        address _lender,
        uint256 _amountInTokens
    ) internal {
        address[] memory _strategyList = IStrategyRegistry(strategyRegistry).getStrategies();
        ISavingsAccount _savingsAccount = ISavingsAccount(savingsAccount);
        uint256 _activeAmount;

        for (uint256 _index; _index < _strategyList.length; ++_index) {
            uint256 _liquidityShares = _savingsAccount.balanceInShares(_lender, _asset, _strategyList[_index]);
            if (_liquidityShares == 0) continue;
            uint256 tokenInStrategy = IYield(_strategyList[_index]).getTokensForShares(_liquidityShares, _asset);
            uint256 _tokensToTransfer = tokenInStrategy;
            if (_activeAmount.add(tokenInStrategy) >= _amountInTokens) {
                _tokensToTransfer = (_amountInTokens.sub(_activeAmount));
            }
            try _savingsAccount.withdrawFrom(_asset, _strategyList[_index], _lender, address(this), _tokensToTransfer, false) {
                _activeAmount = _activeAmount.add(_tokensToTransfer);
            } catch {}
            if (_activeAmount == _amountInTokens) return;
        }
        require(_activeAmount == _amountInTokens, 'IWBA1');
    }

    /**
     * @notice used to borrow tokens from credit line by borrower
     * @dev only borrower can call this function. Amount that can actually be borrowed is 
            min(amount based on borrowLimit, allowance to creditLine contract, balance of lender)
     * @param _id identifier for the credit line
     * @param _amount amount of tokens to borrow
     */
    function borrow(uint256 _id, uint256 _amount) external nonReentrant onlyCreditLineBorrower(_id) {
        require(creditLineVariables[_id].status == CreditLineStatus.ACTIVE, 'B1');
        require(_amount <= calculateBorrowableAmount(_id), 'B2');
        address _borrowAsset = creditLineConstants[_id].borrowAsset;
        address _lender = creditLineConstants[_id].lender;

        creditLineVariables[_id].interestAccruedTillLastPrincipalUpdate = calculateInterestAccrued(_id);
        creditLineVariables[_id].lastPrincipalUpdateTime = block.timestamp;

        uint256 _balanceBefore = IERC20(_borrowAsset).balanceOf(address(this));
        _withdrawBorrowAmount(_borrowAsset, _lender, _amount);
        uint256 _balanceAfter = IERC20(_borrowAsset).balanceOf(address(this));

        uint256 _tokenDiffBalance = _balanceAfter.sub(_balanceBefore);
        creditLineVariables[_id].principal = creditLineVariables[_id].principal.add(_tokenDiffBalance);

        uint256 _protocolFee = _tokenDiffBalance.mul(protocolFeeFraction).div(SCALING_FACTOR);
        _tokenDiffBalance = _tokenDiffBalance.sub(_protocolFee);

        IERC20(_borrowAsset).safeTransfer(protocolFeeCollector, _protocolFee);
        IERC20(_borrowAsset).safeTransfer(msg.sender, _tokenDiffBalance);
        emit BorrowedFromCreditLine(_id, _tokenDiffBalance);
    }

    //-------------------------------- Borrow code end --------------------------------//

    //-------------------------------- Repayments code start --------------------------------//

    /**
    @dev Regarding increaseAllowanceToCreditLineSince the borrower is giving money into the credit line, 
        we need to make sure that the Credit Line then has the allowance to use those funds
     */
    function _repay(uint256 _id, uint256 _amount) internal {
        ISavingsAccount _savingsAccount = ISavingsAccount(savingsAccount);
        address _defaultStrategy = defaultStrategy;
        address _borrowAsset = creditLineConstants[_id].borrowAsset;
        address _lender = creditLineConstants[_id].lender;
        IERC20(_borrowAsset).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_borrowAsset).approve(_defaultStrategy, _amount);
        _savingsAccount.deposit(_borrowAsset, _defaultStrategy, _lender, _amount);
    }

    /**
     * @notice used to repay interest and principal to credit line. Interest has to be repaid before repaying principal
     * @dev partial repayments possible
     * @param _id identifier for the credit line
     * @param _amount amount being repaid
     */

    function repay(uint256 _id, uint256 _amount) external override nonReentrant {
        require(creditLineVariables[_id].status == CreditLineStatus.ACTIVE, 'R1');
        require(creditLineConstants[_id].lender != msg.sender, 'R2');

        uint256 _totalInterestAccrued = calculateInterestAccrued(_id);
        uint256 _interestToPay = _totalInterestAccrued.sub(creditLineVariables[_id].totalInterestRepaid);
        uint256 _totalCurrentDebt = _interestToPay.add(creditLineVariables[_id].principal);

        if (_amount >= _totalCurrentDebt) {
            _amount = _totalCurrentDebt;
            emit CompleteCreditLineRepaid(_id, msg.sender, _amount);
        } else {
            emit PartialCreditLineRepaid(_id, msg.sender, _amount);
        }

        if (_amount > _interestToPay) {
            creditLineVariables[_id].principal = _totalCurrentDebt.sub(_amount);
            creditLineVariables[_id].interestAccruedTillLastPrincipalUpdate = _totalInterestAccrued;
            creditLineVariables[_id].lastPrincipalUpdateTime = block.timestamp;
            creditLineVariables[_id].totalInterestRepaid = _totalInterestAccrued;
        } else {
            creditLineVariables[_id].totalInterestRepaid = creditLineVariables[_id].totalInterestRepaid.add(_amount);
        }

        _repay(_id, _amount);

        if (creditLineVariables[_id].principal == 0) {
            _resetCreditLine(_id);
        }
    }

    function _resetCreditLine(uint256 _id) internal {
        creditLineVariables[_id].lastPrincipalUpdateTime = 0;
        creditLineVariables[_id].totalInterestRepaid = 0;
        creditLineVariables[_id].interestAccruedTillLastPrincipalUpdate = 0;
        emit CreditLineReset(_id);
    }

    //-------------------------------- Repayments code end --------------------------------//

    //-------------------------------- Liquidation code start --------------------------------//

    /**
     * @notice used to liquidate credit line in case collateral ratio goes below the threshold
     * @dev if lender liquidates, then collateral is directly transferred. 
            If autoLiquidation is true, anyone can liquidate by providing enough borrow tokens
     * @param _id identifier for the credit line
     * @param _toSavingsAccount if true, tokens are transferred from savingsAccount 
                                otherwise direct from collateral token contract
     */
    function liquidate(uint256 _id, bool _toSavingsAccount) external nonReentrant {
        require(creditLineVariables[_id].status == CreditLineStatus.ACTIVE, 'L1');
        require(creditLineVariables[_id].principal != 0, 'L2');
        address _borrowAsset = creditLineConstants[_id].borrowAsset;

        (uint256 currentCollateralRatio, uint256 _totalCollateralTokens) = calculateCurrentCollateralRatio(_id);
        require(currentCollateralRatio < creditLineConstants[_id].idealCollateralRatio, 'L3');

        address _lender = creditLineConstants[_id].lender;
        require(creditLineConstants[_id].autoLiquidation || msg.sender == _lender, 'L4');

        address _collateralAsset = creditLineConstants[_id].collateralAsset;

        if (creditLineConstants[_id].autoLiquidation && _lender != msg.sender) {
            uint256 _borrowTokens = _borrowTokensToLiquidate(_borrowAsset, _collateralAsset, _totalCollateralTokens);
            IERC20(_borrowAsset).safeTransferFrom(msg.sender, _lender, _borrowTokens);
        }

        _transferCollateral(_id, _collateralAsset, msg.sender, _totalCollateralTokens, _toSavingsAccount);
        delete creditLineConstants[_id];
        delete creditLineVariables[_id];
        emit CreditLineLiquidated(_id, msg.sender);
    }

    /**
     * @notice used to calculate the borrow tokens necessary for liquidator to liquidate
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view
     * @param _id identifier for the credit line
     * @return borrow tokens necessary for liquidator to liquidate
     */
    function borrowTokensToLiquidate(uint256 _id) external returns (uint256) {
        address _collateralAsset = creditLineConstants[_id].collateralAsset;
        uint256 _totalCollateralTokens = _calculateTotalCollateralTokens(_id, _collateralAsset);

        return _borrowTokensToLiquidate(creditLineConstants[_id].borrowAsset, _collateralAsset, _totalCollateralTokens);
    }

    function _borrowTokensToLiquidate(
        address _borrowAsset,
        address _collateralAsset,
        uint256 _totalCollateralTokens
    ) internal view returns (uint256) {
        (uint256 _ratioOfPrices, uint256 _decimals) = IPriceOracle(priceOracle).getLatestPrice(_collateralAsset, _borrowAsset);
        uint256 _borrowTokens = (
            _totalCollateralTokens.mul(uint256(SCALING_FACTOR).sub(liquidatorRewardFraction)).div(SCALING_FACTOR).mul(_ratioOfPrices).div(
                10**_decimals
            )
        );

        return _borrowTokens;
    }

    //-------------------------------- Liquidation code end --------------------------------//

    //-------------------------------- close/cancel code start --------------------------------//
    /**
     * @dev used to close credit line by borrower or lender
     * @param _id identifier for the credit line
     */
    function close(uint256 _id) external {
        require(msg.sender == creditLineConstants[_id].borrower || msg.sender == creditLineConstants[_id].lender, 'C1');
        require(creditLineVariables[_id].status == CreditLineStatus.ACTIVE, 'C2');
        require(creditLineVariables[_id].principal == 0, 'C3');

        _withdrawCollateral(_id, creditLineConstants[_id].borrower, false);

        delete creditLineConstants[_id];
        delete creditLineVariables[_id];
        emit CreditLineClosed(_id, msg.sender == creditLineConstants[_id].lender);
    }

    /**
     * @dev used to cancel credit line by borrower or lender
     * @param _id identifier for the credit line
     */
    function cancel(uint256 _id) external {
        require(msg.sender == creditLineConstants[_id].borrower || msg.sender == creditLineConstants[_id].lender, 'CP1');
        require(creditLineVariables[_id].status == CreditLineStatus.REQUESTED, 'CP2');
        delete creditLineVariables[_id];
        delete creditLineConstants[_id];
        emit CreditLineCancelled(_id);
    }

    //-------------------------------- close/cancel code end --------------------------------//

    //-------------------------------- Utilities code start --------------------------------//

    /**
     * @notice used to calculate the current collateral ratio
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view.
            Interest is also considered while calculating debt
     * @param _id identifier for the credit line
     * @return collateral ratio multiplied by SCALING_FACTOR to retain precision
     */
    function calculateCurrentCollateralRatio(uint256 _id) public returns (uint256, uint256) {
        address _collateralAsset = creditLineConstants[_id].collateralAsset;
        (uint256 _ratioOfPrices, uint256 _decimals) = IPriceOracle(priceOracle).getLatestPrice(
            _collateralAsset,
            creditLineConstants[_id].borrowAsset
        );

        uint256 currentDebt = calculateCurrentDebt(_id);
        uint256 totalCollateralTokens = _calculateTotalCollateralTokens(_id, _collateralAsset);
        uint256 currentCollateralRatio = totalCollateralTokens.mul(_ratioOfPrices).div(10**_decimals).mul(SCALING_FACTOR).div(currentDebt);

        return (currentCollateralRatio, totalCollateralTokens);
    }

    /**
     * @notice used to calculate the total collateral tokens
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view
     * @param _id identifier for the credit line
     * @return _amount total collateral tokens deposited into the credit line
     */
    function calculateTotalCollateralTokens(uint256 _id) public returns (uint256) {
        address _collateralAsset = creditLineConstants[_id].collateralAsset;
        return _calculateTotalCollateralTokens(_id, _collateralAsset);
    }

    function _calculateTotalCollateralTokens(uint256 _id, address _collateralAsset) internal returns (uint256) {
        address _strategy = creditLineConstants[_id].collateralStrategy;

        uint256 _collateralShares = collateralShareInStrategy[_id];
        uint256 _collateral = IYield(_strategy).getTokensForShares(_collateralShares, _collateralAsset);

        return _collateral;
    }

    /**
     * @dev Used to Calculate Interest Per second on given principal and Interest rate
     * @param _principal principal Amount for which interest has to be calculated
     * @param _borrowRate It is the Interest Rate at which Credit Line is approved
     * @param _timeElapsed It is the time interval in seconds for which interest is calculated
     * @return interest per second for the given parameters
     */
    function calculateInterest(
        uint256 _principal,
        uint256 _borrowRate,
        uint256 _timeElapsed
    ) public pure returns (uint256) {
        return (_principal.mul(_borrowRate).mul(_timeElapsed).div(SCALING_FACTOR).div(YEAR_IN_SECONDS));
    }

    /**
     * @dev Used to calculate interest accrued since last repayment
     * @param _id identifier for the credit line
     * @return interest accrued over current borrowed amount since last repayment
     */
    function calculateInterestAccrued(uint256 _id) public view returns (uint256) {
        uint256 _lastPrincipalUpdateTime = creditLineVariables[_id].lastPrincipalUpdateTime;
        if (_lastPrincipalUpdateTime == 0) return 0;
        uint256 _timeElapsed = (block.timestamp).sub(_lastPrincipalUpdateTime);
        uint256 _interestAccrued = calculateInterest(creditLineVariables[_id].principal, creditLineConstants[_id].borrowRate, _timeElapsed);
        return _interestAccrued.add(creditLineVariables[_id].interestAccruedTillLastPrincipalUpdate);
    }

    /**
     * @dev Used to calculate current debt of borrower against a credit line.
     * @param _id identifier for the credit line
     * @return current debt of borrower
     */
    function calculateCurrentDebt(uint256 _id) public view returns (uint256) {
        uint256 _interestAccrued = calculateInterestAccrued(_id);
        uint256 _currentDebt = (creditLineVariables[_id].principal).add(_interestAccrued).sub(creditLineVariables[_id].totalInterestRepaid);
        return _currentDebt;
    }

    /**
     * @dev Used to get the current status of the credit line
     * @param _id identifier for the credit line
     * @return credit line status
     */
    function getCreditLineStatus(uint256 _id) external view returns (CreditLineStatus) {
        return creditLineVariables[_id].status;
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
     * @notice emitted when tokens' shares are burnt by the owner
     * @param token address of the token whose shares were burnt
     * @param strategy address of the strategy from which shares were burnt
     * @param from address of the user that burnt their token shares
     * @param amount amount of token shares burnt
     */
    event Burned(address indexed token, address strategy, address indexed from, uint256 amount);

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
        uint256 _shares,
        address _token,
        address _strategy,
        address _to
    ) external returns (uint256);

    function transfer(
        address token,
        address strategy,
        address to,
        uint256 amount
    ) external returns (uint256 tokensReceived);

    function transferSharesFrom(
        uint256 shares,
        address token,
        address strategy,
        address from,
        address to
    ) external returns (uint256);

    function transferFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 tokensReceived);

    function burn(
        uint256 amount,
        address token,
        address poolSavingsStrategy
    ) external returns (uint256);

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
     **/
    function removeStrategy(uint256 strategyIndex) external;

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

interface ICreditline {
    function depositCollateral(
        uint256 _id,
        uint256 _amount,
        bool _fromSavingsAccount
    ) external;

    function repay(uint256 _id, uint256 _amount) external;
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