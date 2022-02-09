// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '../interfaces/IPoolFactory.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IVerification.sol';
import '../interfaces/IStrategyRegistry.sol';
import '../interfaces/IRepayment.sol';
import '../interfaces/IPriceOracle.sol';
import '../interfaces/ISavingsAccount.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../SavingsAccount/SavingsAccountUtil.sol';
import './Beacon.sol';
// import './MinimumBeaconProxy.sol';
import './MinimumBeaconProxy2.sol';

/**
 * @title Pool Factory contract with methods for handling different pools
 * @notice Implements the functions related to Pool (CRUD)
 * @author Sublime
 */
contract PoolFactory is Initializable, OwnableUpgradeable, IPoolFactory {
    using SafeMath for uint256;
    /*
     * @notice Used to define limits for the Pool parameters
     * @param min the minimum threshold for the parameter
     * @param max the maximum threshold for the parameter
     */
    struct Limits {
        uint256 min;
        uint256 max;
    }

    /**
     * @notice address of the contract storing the user registry
     */
    address public override userRegistry;

    /**
     * @notice address of the contract storing the strategy registry
     */
    address public strategyRegistry;

    /**
     * @notice address of the latest implementation of the extension logic
     */
    address public override extension;

    /**
     * @notice address of the latest implementation of the repayment logic
     */
    address public override repaymentImpl;

    /**
     * @notice address of the latest implementation of the pool logic
     */
    address public override priceOracle;

    /**
     * @notice address of the savings account used
     */
    address public override savingsAccount;

    /**
     * @notice the time interval for the lenders to make contributions to pool
     */
    uint256 public override collectionPeriod;

    /**
     * @notice the time interval for the borrower to withdraw the loan from pool
     */
    uint256 public override loanWithdrawalDuration;

    /**
     * @notice the time interval for the active stage of the margin call
     */
    uint256 public override marginCallDuration;

    /**
     * @notice Fraction of the requested amount for pool below which pool is cancelled
     */
    uint256 public override minBorrowFraction;

    /**
     * @notice the fraction used for calculating the liquidator reward
     */
    uint256 public override liquidatorRewardFraction;

    /**
     * @notice the fraction used for calculating the penalty when the pool is cancelled
     */
    uint256 public override poolCancelPenaltyMultiple;

    /**
     * @notice Contract Address of no yield
     */
    address public override noStrategyAddress;

    uint256 protocolFeeFraction;
    address protocolFeeCollector;

    address public beacon;

    /*
     * @notice Used to mark assets supported for borrowing
     */
    mapping(address => bool) isBorrowToken;

    /*
     * @notice Used to mark supported collateral assets
     */
    mapping(address => bool) isCollateralToken;

    /**
     * @notice Used to keep track of valid pool addresses
     */
    mapping(address => bool) public override poolRegistry;

    /*
     * @notice Used to set the min/max borrow amount for Pools
     */
    Limits poolSizeLimit;

    /*
     * @notice Used to set the min/max collateral ratio for Pools
     */
    Limits idealCollateralRatioLimit;

    /*
     * @notice Used to set the min/max borrow rates (interest rate provided by borrower) for Pools
     */
    Limits borrowRateLimit;

    /*
     * @notice used to set the min/max repayment interval for Pools
     */
    Limits repaymentIntervalLimit;

    /*
     * @notice used to set the min/max number of repayment intervals for Pools
     */
    Limits noOfRepaymentIntervalsLimit;

    /**
     * @notice functions affected by this modifier can only be invoked by the Pool
     */
    modifier onlyPool() {
        require(poolRegistry[msg.sender], 'PoolFactory::onlyPool - Only pool can destroy itself');
        _;
    }

    /**
     * @notice functions affected by this modifier can only be invoked by the borrow of the Pool
     */
    modifier onlyBorrower(address _verifier) {
        require(
            IVerification(userRegistry).isUser(msg.sender, _verifier),
            'PoolFactory::onlyBorrower - Only a valid Borrower can create Pool'
        );
        _;
    }

    /**
     * @notice returns the owner of the pool
     */
    function owner() public view override(IPoolFactory, OwnableUpgradeable) returns (address) {
        return OwnableUpgradeable.owner();
    }

    /**
     * @notice used to initialize the pool factory
     * @dev initializer can only be run once
     * @param _admin address of admin
     * @param _collectionPeriod period for which lenders can lend for pool
     * @param _loanWithdrawalDuration period for which lent tokens can be withdrawn after pool starts
     * @param _marginCallDuration duration of margin call before which collateral ratio has to be maintained
     * @param _liquidatorRewardFraction fraction of liquidation amount which is given to liquidator as reward multiplied by SCALING_FACTOR(10**30)
     * @param _poolCancelPenaltyMultiple multiple of borrow rate of pool as penality for cancellation of pool multiplied by SCALING_FACTOR(10**30)
     * @param _minBorrowFraction amountCollected/amountRequested for a pool, if less than fraction by pool start time then pool can be cancelled without penality multiplied by SCALING_FACTOR(10**30)
     * @param _protocolFeeFraction fraction of amount borrowed in pool which is collected as protocol fee
     * @param _protocolFeeCollector address where protocol fee is collected
     * @param _noStrategy address of the no strategy address
     */
    function initialize(
        address _admin,
        uint256 _collectionPeriod,
        uint256 _loanWithdrawalDuration,
        uint256 _marginCallDuration,
        uint256 _liquidatorRewardFraction,
        uint256 _poolCancelPenaltyMultiple,
        uint256 _minBorrowFraction,
        uint256 _protocolFeeFraction,
        address _protocolFeeCollector,
        address _noStrategy,
        address _beacon
    ) external initializer {
        {
            OwnableUpgradeable.__Ownable_init();
            OwnableUpgradeable.transferOwnership(_admin);
        }
        _updateCollectionPeriod(_collectionPeriod);
        _updateLoanWithdrawalDuration(_loanWithdrawalDuration);
        _updateMarginCallDuration(_marginCallDuration);
        _updateLiquidatorRewardFraction(_liquidatorRewardFraction);
        _updatePoolCancelPenaltyMultiple(_poolCancelPenaltyMultiple);
        _updateMinBorrowFraction(_minBorrowFraction);
        _updateProtocolFeeFraction(_protocolFeeFraction);
        _updateProtocolFeeCollector(_protocolFeeCollector);
        _updateNoStrategy(_noStrategy);
        beacon = _beacon;
    }

    /**
     * @notice used to setImplementation addresses
     * @dev used to set some of the contracts pool factory interacts with. only admin can invoke
     * @param _repaymentImpl address of the implementation address of repayments
     * @param _userRegistry address of the user registry where users are verified
     * @param _strategyRegistry address of the startegy registry where strategies are whitelisted
     * @param _priceOracle address of the price oracle
     * @param _savingsAccount address of the savings account contract
     * @param _extension address of the extension contract for pools
     */
    function setImplementations(
        address _repaymentImpl,
        address _userRegistry,
        address _strategyRegistry,
        address _priceOracle,
        address _savingsAccount,
        address _extension
    ) external onlyOwner {
        _updateRepaymentImpl(_repaymentImpl);
        _updateSavingsAccount(_savingsAccount);
        _updatedExtension(_extension);
        _updateUserRegistry(_userRegistry);
        _updateStrategyRegistry(_strategyRegistry);
        _updatePriceoracle(_priceOracle);
    }

    /**
     * @notice invoked when a new borrow pool is created. deploys a new pool for every borrow request
     * @param _poolSize loan amount requested
     * @param _borrowToken borrow asset requested
     * @param _collateralToken collateral asset requested
     * @param _idealCollateralRatio ideal pool collateral ratio set by the borrower
     * @param _borrowRate interest rate provided by the borrower
     * @param _repaymentInterval interval between the last dates of two repayment cycles
     * @param _noOfRepaymentIntervals number of repayments to be made during the duration of the loan
     * @param _poolSavingsStrategy savings strategy selected for the pool collateral
     * @param _collateralAmount collateral amount deposited
     * @param _transferFromSavingsAccount if true, initial collateral is transferred from borrower's savings account, if false, borrower transfers initial collateral deposit from wallet
     * @param _salt random and unique initial seed
     */
    function createPool(
        uint256 _poolSize,
        uint256 _borrowRate,
        address _borrowToken,
        address _collateralToken,
        uint256 _idealCollateralRatio,
        uint64 _repaymentInterval,
        uint64 _noOfRepaymentIntervals,
        address _poolSavingsStrategy,
        uint256 _collateralAmount,
        bool _transferFromSavingsAccount,
        bytes32 _salt,
        address _verifier,
        address _lenderVerifier
    ) external payable onlyBorrower(_verifier) {
        if (_collateralToken == address(0)) {
            require(msg.value == _collateralAmount, 'PoolFactory::createPool - Ether send is different from collateral amount specified');
        } else {
            require(msg.value == 0, 'PoolFactory::createPool - Ether not required when collateral Token is not ETH');
        }
        require(_borrowToken != _collateralToken, 'PoolFactory::createPool - cant borrow the asset put in as collateralToken');
        require(isBorrowToken[_borrowToken], 'PoolFactory::createPool - Invalid borrow token type');
        require(isCollateralToken[_collateralToken], 'PoolFactory::createPool - Invalid collateral token type');
        require(
            IPriceOracle(priceOracle).doesFeedExist(_collateralToken, _borrowToken),
            "PoolFactory::createPool - Price feed doesn't support token pair"
        );
        require(IStrategyRegistry(strategyRegistry).registry(_poolSavingsStrategy), 'PoolFactory::createPool - Invalid strategy');
        _limitPoolSizeInUSD(_borrowToken, _poolSize);
        // require(isWithinLimits(_poolSize, poolSizeLimit.min, poolSizeLimit.max), 'PoolFactory::createPool - PoolSize not within limits');
        require(
            isWithinLimits(_idealCollateralRatio, idealCollateralRatioLimit.min, idealCollateralRatioLimit.max),
            'PoolFactory::createPool - Collateral Ratio not within limits'
        );
        require(
            isWithinLimits(_borrowRate, borrowRateLimit.min, borrowRateLimit.max),
            'PoolFactory::createPool - Borrow rate not within limits'
        );
        require(
            isWithinLimits(_noOfRepaymentIntervals, noOfRepaymentIntervalsLimit.min, noOfRepaymentIntervalsLimit.max),
            'PoolFactory::createPool - Loan duration not within limits'
        );
        require(
            isWithinLimits(_repaymentInterval, repaymentIntervalLimit.min, repaymentIntervalLimit.max),
            'PoolFactory::createPool - Repayment interval not within limits'
        );
        _createPool(
            _poolSize,
            _borrowRate,
            _borrowToken,
            _collateralToken,
            _idealCollateralRatio,
            _repaymentInterval,
            _noOfRepaymentIntervals,
            _poolSavingsStrategy,
            _collateralAmount,
            _transferFromSavingsAccount,
            _salt,
            _lenderVerifier
        );
    }

    function _limitPoolSizeInUSD(address _borrowToken, uint256 _poolsize) internal {
        address usdcAsset = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC
        (uint256 RatioOfPrices, uint256 decimals) = IPriceOracle(priceOracle).getLatestPrice(_borrowToken, usdcAsset);
        uint256 _poolsizeInUSD = _poolsize.mul(RatioOfPrices).div(10**decimals);
        require(
            isWithinLimits(_poolsizeInUSD, poolSizeLimit.min, poolSizeLimit.max),
            'PoolFactory::createPool - PoolSize not within limits'
        );
    }

    function preComputeAddress(address creator, bytes32 salt) public view returns (address predicted) {
        salt = keccak256(abi.encode(creator, salt));

        bytes memory beaconProxyByteCode = abi.encodePacked(type(MinimumBeaconProxy).creationCode, abi.encode(beacon));

        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(beaconProxyByteCode)));

        return address(uint160(uint256(hash)));
    }

    // @dev These functions are used to avoid stack too deep
    function _createPool(
        uint256 _poolSize,
        uint256 _borrowRate,
        address _borrowToken,
        address _collateralToken,
        uint256 _idealCollateralRatio,
        uint64 _repaymentInterval,
        uint64 _noOfRepaymentIntervals,
        address _poolSavingsStrategy,
        uint256 _collateralAmount,
        bool _transferFromSavingsAccount,
        bytes32 _salt,
        address _lenderVerifier
    ) internal {
        _salt = keccak256(abi.encode(msg.sender, _salt));
        address addr = _create(_salt);
        _initPool(
            addr,
            _poolSize,
            _borrowRate,
            _borrowToken,
            _collateralToken,
            _idealCollateralRatio,
            _repaymentInterval,
            _noOfRepaymentIntervals,
            _poolSavingsStrategy,
            _collateralAmount,
            _transferFromSavingsAccount,
            _lenderVerifier
        );
        poolRegistry[addr] = true;
        emit PoolCreated(addr, msg.sender);
    }

    function _create(bytes32 _salt) internal returns (address) {
        address addr;
        bytes memory beaconProxyByteCode = abi.encodePacked(type(MinimumBeaconProxy).creationCode, abi.encode(beacon));

        assembly {
            addr := create2(callvalue(), add(beaconProxyByteCode, 0x20), mload(beaconProxyByteCode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    function _initPool(
        address _pool,
        uint256 _poolSize,
        uint256 _borrowRate,
        address _borrowToken,
        address _collateralToken,
        uint256 _idealCollateralRatio,
        uint64 _repaymentInterval,
        uint64 _noOfRepaymentIntervals,
        address _poolSavingsStrategy,
        uint256 _collateralAmount,
        bool _transferFromSavingsAccount,
        address _lenderVerifier
    ) internal {
        IPool pool = IPool(_pool);
        pool.initialize(
            _poolSize,
            _borrowRate,
            msg.sender,
            _borrowToken,
            _collateralToken,
            _idealCollateralRatio,
            _repaymentInterval,
            _noOfRepaymentIntervals,
            _poolSavingsStrategy,
            _collateralAmount,
            _transferFromSavingsAccount,
            _lenderVerifier,
            loanWithdrawalDuration,
            collectionPeriod
        );
    }

    /**
     * @notice invoked to check if pool parameters are within thresholds
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

    /**
     * @notice used to update the list of supported borrow tokens
     * @param _borrowToken address of the borrow asset
     * @param _isSupported true if _borrowToken is a valid borrow asset, false if _borrowToken is an invalid borrow asset
     */
    function updateSupportedBorrowTokens(address _borrowToken, bool _isSupported) external onlyOwner {
        _updateSupportedBorrowTokens(_borrowToken, _isSupported);
    }

    function _updateSupportedBorrowTokens(address _borrowToken, bool _isSupported) internal {
        isBorrowToken[_borrowToken] = _isSupported;
        emit BorrowTokenUpdated(_borrowToken, _isSupported);
    }

    /**
     * @notice used to update the list of supported Collateral tokens
     * @param _collateralToken address of the Collateral asset
     * @param _isSupported true if _collateralToken is a valid Collateral asset, false if _collateralToken is an invalid Collateral asset
     */
    function updateSupportedCollateralTokens(address _collateralToken, bool _isSupported) external onlyOwner {
        _updateSupportedCollateralTokens(_collateralToken, _isSupported);
    }

    function _updateSupportedCollateralTokens(address _collateralToken, bool _isSupported) internal {
        isCollateralToken[_collateralToken] = _isSupported;
        emit CollateralTokenUpdated(_collateralToken, _isSupported);
    }

    /**
     * @notice used to update the user registry
     * @param _userRegistry address of the contract storing the user registry
     */
    function updateUserRegistry(address _userRegistry) external onlyOwner {
        _updateUserRegistry(_userRegistry);
    }

    function _updateUserRegistry(address _userRegistry) internal {
        userRegistry = _userRegistry;
        emit UserRegistryUpdated(_userRegistry);
    }

    /**
     * @notice used to update the strategy registry
     * @param _strategyRegistry address of the contract storing the strategy registry
     */
    function updateStrategyRegistry(address _strategyRegistry) external onlyOwner {
        _updateStrategyRegistry(_strategyRegistry);
    }

    function _updateStrategyRegistry(address _strategyRegistry) internal {
        strategyRegistry = _strategyRegistry;
        emit StrategyRegistryUpdated(_strategyRegistry);
    }

    /**
     * @notice used to update the implementation of the repayment logic
     * @param _repaymentImpl address of the updated repayment.sol contract
     */
    function updateRepaymentImpl(address _repaymentImpl) external onlyOwner {
        _updateRepaymentImpl(_repaymentImpl);
    }

    function _updateRepaymentImpl(address _repaymentImpl) internal {
        repaymentImpl = _repaymentImpl;
        emit RepaymentImplUpdated(_repaymentImpl);
    }

    /**
     * @notice used to update contract address of nostrategy contract
     * @param _noStrategy address of the updated noYield.sol contract
     */
    function updateNoStrategy(address _noStrategy) external onlyOwner {
        _updateNoStrategy(_noStrategy);
    }

    function _updateNoStrategy(address _noStrategy) internal {
        noStrategyAddress = _noStrategy;
        emit NoStrategyUpdated(_noStrategy);
    }

    /**
     * @notice used to update the implementation of the price oracle logic
     * @param _priceOracle address of the updated price oracle contract
     */
    function updatePriceoracle(address _priceOracle) external onlyOwner {
        _updatePriceoracle(_priceOracle);
    }

    function _updatePriceoracle(address _priceOracle) internal {
        priceOracle = _priceOracle;
        emit PriceOracleUpdated(_priceOracle);
    }

    /**
     * @notice used to update the extensions contract
     * @param _extension address of the updated extensions contract
     */
    function updatedExtension(address _extension) external onlyOwner {
        _updatedExtension(_extension);
    }

    function _updatedExtension(address _extension) internal {
        extension = _extension;
        emit ExtensionImplUpdated(_extension);
    }

    /**
     * @notice used to update the savings account contract
     * @param _savingsAccount address of the updated savings account contract
     */
    function updateSavingsAccount(address _savingsAccount) external onlyOwner {
        _updateSavingsAccount(_savingsAccount);
    }

    function _updateSavingsAccount(address _savingsAccount) internal {
        savingsAccount = _savingsAccount;
        emit SavingsAccountUpdated(_savingsAccount);
    }

    /**
     * @notice used to update the collection period of the Pool
     * @param _collectionPeriod updated value of the collection period
     */
    function updateCollectionPeriod(uint256 _collectionPeriod) external onlyOwner {
        _updateCollectionPeriod(_collectionPeriod);
    }

    function _updateCollectionPeriod(uint256 _collectionPeriod) internal {
        collectionPeriod = _collectionPeriod;
        emit CollectionPeriodUpdated(_collectionPeriod);
    }

    /**
     * @notice used to update the loan withdrawal duration by owner
     * @param _loanWithdrawalDuration updated value of loanWithdrawalDuration
     */
    function updateLoanWithdrawalDuration(uint256 _loanWithdrawalDuration) external onlyOwner {
        _updateLoanWithdrawalDuration(_loanWithdrawalDuration);
    }

    function _updateLoanWithdrawalDuration(uint256 _loanWithdrawalDuration) internal {
        loanWithdrawalDuration = _loanWithdrawalDuration;
        emit LoanWithdrawalDurationUpdated(_loanWithdrawalDuration);
    }

    /**
     * @notice used to update the active stage of the margin call of the Pool
     * @param _marginCallDuration updated value of the margin call duration
     */
    function updateMarginCallDuration(uint256 _marginCallDuration) external onlyOwner {
        _updateMarginCallDuration(_marginCallDuration);
    }

    function _updateMarginCallDuration(uint256 _marginCallDuration) internal {
        marginCallDuration = _marginCallDuration;
        emit MarginCallDurationUpdated(_marginCallDuration);
    }

    /**
     * @notice used to update the min borrow fraction by owner
     * @param _minBorrowFraction updated value of min borrow fraction multiplied by SCALING_FACTOR(10**30)
     */
    function updateMinBorrowFraction(uint256 _minBorrowFraction) external onlyOwner {
        _updateMinBorrowFraction(_minBorrowFraction);
    }

    function _updateMinBorrowFraction(uint256 _minBorrowFraction) internal {
        minBorrowFraction = _minBorrowFraction;
        emit MinBorrowFractionUpdated(_minBorrowFraction);
    }

    /**
     * @notice used to update the reward fraction for liquidation of the Pool
     * @param _liquidatorRewardFraction updated value of the reward fraction for liquidation multiplied by SCALING_FACTOR(10**30)
     */
    function updateLiquidatorRewardFraction(uint256 _liquidatorRewardFraction) external onlyOwner {
        _updateLiquidatorRewardFraction(_liquidatorRewardFraction);
    }

    function _updateLiquidatorRewardFraction(uint256 _liquidatorRewardFraction) internal {
        liquidatorRewardFraction = _liquidatorRewardFraction;
        emit LiquidatorRewardFractionUpdated(_liquidatorRewardFraction);
    }

    /**
     * @notice used to update the pool cancel penalty multiple
     * @param _poolCancelPenaltyMultiple updated value of the pool cancel penalty multiple multiplied by SCALING_FACTOR(10**30)
     */
    function updatePoolCancelPenaltyMultiple(uint256 _poolCancelPenaltyMultiple) external onlyOwner {
        _updatePoolCancelPenaltyMultiple(_poolCancelPenaltyMultiple);
    }

    function _updatePoolCancelPenaltyMultiple(uint256 _poolCancelPenaltyMultiple) internal {
        poolCancelPenaltyMultiple = _poolCancelPenaltyMultiple;
        emit PoolCancelPenaltyMultipleUpdated(_poolCancelPenaltyMultiple);
    }

    /**
     * @notice used to update the fraction of borrowed amount charged as protocol fee
     * @param _protocolFee updated value of protocol fee fraction multiplied by SCALING_FACTOR(10**30)
     */
    function updateProtocolFeeFraction(uint256 _protocolFee) external onlyOwner {
        _updateProtocolFeeFraction(_protocolFee);
    }

    function _updateProtocolFeeFraction(uint256 _protocolFee) internal {
        protocolFeeFraction = _protocolFee;
        emit ProtocolFeeFractionUpdated(_protocolFee);
    }

    /**
     * @notice used to update the address in which protocol fee is collected
     * @param _protocolFeeCollector updated address of protocol fee collector
     */
    function updateProtocolFeeCollector(address _protocolFeeCollector) external onlyOwner {
        _updateProtocolFeeCollector(_protocolFeeCollector);
    }

    function _updateProtocolFeeCollector(address _protocolFeeCollector) internal {
        protocolFeeCollector = _protocolFeeCollector;
        emit ProtocolFeeCollectorUpdated(_protocolFeeCollector);
    }

    /**
     * @notice used to update the thresholds of the pool size of the Pool
     * @param _min updated value of the minimum threshold value of the pool size
     * @param _max updated value of the maximum threshold value of the pool size
     */
    function updatePoolSizeLimit(uint256 _min, uint256 _max) external onlyOwner {
        poolSizeLimit = Limits(_min, _max);
        emit LimitsUpdated('PoolSize', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the collateral ratio of the Pool
     * @param _min updated value of the minimum threshold value of the collateral ratio
     * @param _max updated value of the maximum threshold value of the collateral ratio
     */
    function updateidealCollateralRatioLimit(uint256 _min, uint256 _max) external onlyOwner {
        idealCollateralRatioLimit = Limits(_min, _max);
        emit LimitsUpdated('CollateralRatio', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the borrow rate of the Pool
     * @param _min updated value of the minimum threshold value of the borrow rate
     * @param _max updated value of the maximum threshold value of the borrow rate
     */
    function updateBorrowRateLimit(uint256 _min, uint256 _max) external onlyOwner {
        borrowRateLimit = Limits(_min, _max);
        emit LimitsUpdated('BorrowRate', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the repayment interval of the Pool
     * @param _min updated value of the minimum threshold value of the repayment interval
     * @param _max updated value of the maximum threshold value of the repayment interval
     */
    function updateRepaymentIntervalLimit(uint256 _min, uint256 _max) external onlyOwner {
        repaymentIntervalLimit = Limits(_min, _max);
        emit LimitsUpdated('RepaymentInterval', _min, _max);
    }

    /**
     * @notice used to update the thresholds of the number of repayment intervals of the Pool
     * @param _min updated value of the minimum threshold value of the number of repayment intervals
     * @param _max updated value of the maximum threshold value of the number of repayment intervals
     */
    function updateNoOfRepaymentIntervalsLimit(uint256 _min, uint256 _max) external onlyOwner {
        noOfRepaymentIntervalsLimit = Limits(_min, _max);
        emit LimitsUpdated('NoOfRepaymentIntervals', _min, _max);
    }

    /**
     * @notice used to query protocol fee fraction and address of the collector
     * @return protocolFee Fraction multiplied by SCALING_FACTOR(10**30)
     * @return address of protocol fee collector
     */
    function getProtocolFeeData() external view override returns (uint256, address) {
        return (protocolFeeFraction, protocolFeeCollector);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPoolFactory {
    /**
     * @notice emitted when a Pool is created
     * @param pool the address of the Pool
     * @param borrower the address of the borrower who created the pool
     */
    event PoolCreated(address indexed pool, address indexed borrower);

    /**
     * @notice emitted when the init function definition Pool.sol logic is updated
     * @param updatedSelector the new init function definition for the Pool logic contract
     */
    event PoolInitSelectorUpdated(bytes4 updatedSelector);

    /**
     * @notice emitted when the Pool.sol logic is updated
     * @param updatedPoolLogic the address of the new Pool logic contract
     */
    event PoolLogicUpdated(address indexed updatedPoolLogic);

    /**
     * @notice emitted when the user registry is updated
     * @param updatedBorrowerRegistry address of the contract storing the user registry
     */
    event UserRegistryUpdated(address indexed updatedBorrowerRegistry);

    /**
     * @notice emitted when the strategy registry is updated
     * @param updatedStrategyRegistry address of the contract storing the updated strategy registry
     */
    event StrategyRegistryUpdated(address indexed updatedStrategyRegistry);

    /**
     * @notice emitted when the Repayments.sol logic is updated
     * @param updatedRepaymentImpl the address of the new implementation of the Repayments logic
     */
    event RepaymentImplUpdated(address indexed updatedRepaymentImpl);

    /**
     * @notice emitted when the PriceOracle.sol is updated
     * @param updatedPriceOracle address of the new implementation of the PriceOracle
     */
    event PriceOracleUpdated(address indexed updatedPriceOracle);

    /**
     * @notice emitted when the Extension.sol is updated
     * @param updatedExtension address of the new implementation of the Extension
     */
    event ExtensionImplUpdated(address indexed updatedExtension);

    /**
     * @notice emitted when the SavingsAccount.sol is updated
     * @param savingsAccount address of the new implementation of the SavingsAccount
     */
    event SavingsAccountUpdated(address indexed savingsAccount);

    /**
     * @notice emitted when the collection period parameter for Pools is updated
     * @param updatedCollectionPeriod the new value of the collection period for Pools
     */
    event CollectionPeriodUpdated(uint256 updatedCollectionPeriod);

    /**
     * @notice emitted when the loan withdrawal parameter for Pools is updated
     * @param updatedLoanWithdrawalDuration the new value of the loan withdrawal period for Pools
     */
    event LoanWithdrawalDurationUpdated(uint256 updatedLoanWithdrawalDuration);

    /**
     * @notice emitted when the marginCallDuration variable is updated
     * @param updatedMarginCallDuration Duration (in seconds) for which a margin call is active
     */
    event MarginCallDurationUpdated(uint256 updatedMarginCallDuration);

    /**
     * @notice emitted when miBorrowFraction variable is updated
     * @param updatedMinBorrowFraction Updated value of miBorrowFraction
     */
    event MinBorrowFractionUpdated(uint256 updatedMinBorrowFraction);

    /**
     * @notice emitted when liquidatorRewardFraction variable is updated
     * @param updatedLiquidatorRewardFraction updated value of liquidatorRewardFraction
     */
    event LiquidatorRewardFractionUpdated(uint256 updatedLiquidatorRewardFraction);

    /**
     * @notice emitted when poolCancelPenaltyMultiple variable is updated
     * @param updatedPoolCancelPenaltyMultiple updated value of poolCancelPenaltyMultiple
     */
    event PoolCancelPenaltyMultipleUpdated(uint256 updatedPoolCancelPenaltyMultiple);

    /**
     * @notice emitted when fee that protocol changes for pools is updated
     * @param updatedProtocolFee updated value of protocolFeeFraction
     */
    event ProtocolFeeFractionUpdated(uint256 updatedProtocolFee);

    /**
     * @notice emitted when address which receives fee that protocol changes for pools is updated
     * @param updatedProtocolFeeCollector updated value of protocolFeeCollector
     */
    event ProtocolFeeCollectorUpdated(address updatedProtocolFeeCollector);

    /**
     * @notice emitted when threhsolds for one of the parameters (poolSizeLimit, collateralRatioLimit, borrowRateLimit, repaymentIntervalLimit, noOfRepaymentIntervalsLimit) is updated
     * @param limitType specifies the parameter whose limits are being updated
     * @param max maximum threshold value for limitType
     * @param min minimum threshold value for limitType
     */
    event LimitsUpdated(string indexed limitType, uint256 max, uint256 min);

    /**
     * @notice emitted when the list of supported borrow assets is updated
     * @param borrowToken address of the borrow asset
     * @param isSupported true if borrowToken is a valid borrow asset, false if borrowToken is an invalid borrow asset
     */
    event BorrowTokenUpdated(address indexed borrowToken, bool isSupported);

    /**
     * @notice emitted when the list of supported collateral assets is updated
     * @param collateralToken address of the collateral asset
     * @param isSupported true if collateralToken is a valid collateral asset, false if collateralToken is an invalid collateral asset
     */
    event CollateralTokenUpdated(address indexed collateralToken, bool isSupported);

    /**
     * @notice emitted when no strategy address in the pool is updated
     * @param noStrategy address of noYield contract
     */
    event NoStrategyUpdated(address noStrategy);

    function savingsAccount() external view returns (address savingsAccount);

    function owner() external view returns (address owner);

    function poolRegistry(address pool) external view returns (bool isPoolValid);

    function priceOracle() external view returns (address priceOracle);

    function extension() external view returns (address extension);

    function repaymentImpl() external view returns (address repaymentImpl);

    function userRegistry() external view returns (address userRegistry);

    function collectionPeriod() external view returns (uint256 collectionPeriod);

    function loanWithdrawalDuration() external view returns (uint256 loanWithdrawalDuration);

    function marginCallDuration() external view returns (uint256 marginCallDuration);

    function minBorrowFraction() external view returns (uint256 minBorrowFraction);

    function liquidatorRewardFraction() external view returns (uint256 liquidatorRewardFraction);

    function poolCancelPenaltyMultiple() external view returns (uint256 poolCancelPenaltyMultiple);

    function getProtocolFeeData() external view returns (uint256 protocolFeeFraction, address protocolFeeCollector);

    function noStrategyAddress() external view returns (address noStrategyAddress);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IPool {
    /**
     * @notice Emitted when pool is cancelled either on borrower request or insufficient funds collected
     */
    event PoolCancelled();

    /**
     * @notice Emitted when pool is terminated by admin
     */
    event PoolTerminated();

    /**
     * @notice Emitted when pool is closed after repayments are complete
     */
    event PoolClosed();

    /**
     * @notice emitted when borrower posts collateral
     * @param borrower address of the borrower
     * @param amount amount denominated in collateral asset
     * @param sharesReceived shares received after transferring collaterla to pool savings strategy
     */
    event CollateralAdded(address indexed borrower, uint256 amount, uint256 sharesReceived);

    /**
     * @notice emitted when borrower posts collateral after a margin call
     * @param borrower address of the borrower
     * @param lender lender who margin called
     * @param amount amount denominated in collateral asset
     * @param sharesReceived shares received after transferring collaterla to pool savings strategy
     */
    event MarginCallCollateralAdded(address indexed borrower, address indexed lender, uint256 amount, uint256 sharesReceived);

    /**
     * @notice emitted when borrower withdraws excess collateral
     * @param borrower address of borrower
     * @param amount amount of collateral withdrawn
     */
    event CollateralWithdrawn(address indexed borrower, uint256 amount);

    /**
     * @notice emitted when lender supplies liquidity to a pool
     * @param amountSupplied amount that was supplied
     * @param lenderAddress address of the lender. allows for delegation of lending
     */
    event LiquiditySupplied(uint256 amountSupplied, address indexed lenderAddress);

    /**
     * @notice emitted when borrower withdraws loan
     * @param amount tokens the borrower withdrew, taking into account the deducted protocol fee
     * @param protocolFee protocol fee deducted when borrower withdrew the amount
     */
    event AmountBorrowed(uint256 amount, uint256 protocolFee);

    /**
     * @notice emitted when lender withdraws from borrow pool
     * @param amount amount that lender withdraws from borrow pool
     * @param lenderAddress address to which amount is withdrawn
     */
    event LiquidityWithdrawn(uint256 amount, address indexed lenderAddress);

    /**
     * @notice emitted when lender exercises a margin/collateral call
     * @param lenderAddress address of the lender who exercises margin calls
     */
    event MarginCalled(address indexed lenderAddress);

    /**
     * @notice emitted when collateral backing lender is liquidated because of a margin call
     * @param liquidator address that calls the liquidateForLender() function
     * @param lender lender who initially exercised the margin call
     * @param _tokenReceived amount received by liquidator denominated in collateral asset
     */
    event LenderLiquidated(address indexed liquidator, address indexed lender, uint256 _tokenReceived);

    /**
     * @notice emitted when a pool is liquidated for missing repayment
     * @param liquidator address of the liquidator
     */
    event PoolLiquidated(address indexed liquidator);

    function getLoanStatus() external view returns (uint256 loanStatus);

    function depositCollateral(uint256 _amount, bool _transferFromSavingsAccount) external;

    function addCollateralInMarginCall(
        address _lender,
        uint256 _amount,
        bool _isDirect
    ) external;

    function withdrawBorrowedAmount() external;

    function borrower() external returns (address poolBorrower);

    function getMarginCallEndTime(address _lender) external returns (uint256 marginCallEndTimeForLender);

    function getBalanceDetails(address _lender) external view returns (uint256 lenderPoolTokens, uint256 totalPoolTokens);

    function totalSupply() external view returns (uint256 totalPoolTokens);

    function closeLoan() external;

    function initialize(
        uint256 _borrowAmountRequested,
        uint256 _borrowRate,
        address _borrower,
        address _borrowAsset,
        address _collateralAsset,
        uint256 _idealCollateralRatio,
        uint64 _repaymentInterval,
        uint64 _noOfRepaymentIntervals,
        address _poolSavingsStrategy,
        uint256 _collateralAmount,
        bool _transferFromSavingsAccount,
        address _lenderVerifier,
        uint256 _loanWithdrawalDuration,
        uint256 _collectionPeriod
    ) external;

    function lend(
        address _lender,
        uint256 _amount,
        address _strategy,
        bool _fromSavingsAccount
    ) external;
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

    function registerMasterAddress(address _masterAddress, bool _isMasterLinked) external;

    function unregisterMasterAddress(address _masterAddress, address _verifier) external;
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

    function registry(address _strategy) external view returns (bool isValidStrategy);

    function getStrategies() external view returns (address[] memory strategies);

    /**
     * @dev Add strategies to invest in. Please ensure that number of strategies are less than maxStrategies.
     * @param _strategy address of the owner of the savings account contract
     **/
    function addStrategy(address _strategy) external;

    /**
     * @dev Remove strategy to invest in.
     * @param _strategyIndex Index of the strategy to remove
     **/
    function removeStrategy(uint256 _strategyIndex) external;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IRepayment {
    /// @notice Event emitted when interest for the loann is partially repaid
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being repayed
    event InterestRepaid(address indexed poolID, uint256 repayAmount);

    /// @notice Event emitted when all interest for the pool is repaid
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being repayed
    event InterestRepaymentComplete(address indexed poolID, uint256 repayAmount);

    /// @notice Event emitted when pricipal is repaid
    /// @param poolID The address of the pool to which principal was paid
    /// @param repayAmount Amount being repayed
    event PrincipalRepaid(address indexed poolID, uint256 repayAmount);

    /// @notice Event emitted when Grace penalty and interest for previous period is completely repaid
    /// @param poolID The address of the pool to which repayment was made
    /// @param repayAmount Amount being repayed
    event GracePenaltyRepaid(address indexed poolID, uint256 repayAmount);

    /// @notice Event emitted when repayment for extension is completely done
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being re-payed by the borrower
    event ExtensionRepaid(address indexed poolID, uint256 repayAmount); // Made during current period interest repayment

    /// @notice Event to denote changes in the configurations of the pool factory
    /// @param poolFactory updated pool factory address
    event PoolFactoryUpdated(address indexed poolFactory);

    /// @notice Event to denote changes in the configurations of the Grace Penalty Rate
    /// @param gracePenaltyRate updated gracePenaltyRate
    event GracePenaltyRateUpdated(uint256 indexed gracePenaltyRate);

    /// @notice Event to denote changes in the configurations of the Grace Period Fraction
    /// @param gracePeriodFraction updated gracePeriodFraction
    event GracePeriodFractionUpdated(uint256 indexed gracePeriodFraction);

    function initializeRepayment(
        uint64 numberOfTotalRepayments,
        uint256 repaymentInterval,
        uint256 borrowRate,
        uint256 loanStartTime,
        address lentAsset
    ) external;

    function getTotalRepaidAmount(address poolID) external view returns (uint256 amountRepaid);

    function getInterestCalculationVars(address poolID) external view returns (uint256 loanDurationCovered, uint256 interestPerSecond);

    function getCurrentLoanInterval(address poolID) external view returns (uint256 scaledCurrentInterval);

    function instalmentDeadlineExtended(address _poolID) external;

    function didBorrowerDefault(address _poolID) external view returns (bool isBorrowerDefaulter);

    function getGracePeriodFraction() external view returns (uint256 gracePeriod);

    function getNextInstalmentDeadline(address _poolID) external view returns (uint256 nextInstalmentDeadlineTimestamp);
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
     * @param withdrawShares flag to represent if shares are directly wirthdrawn
     */
    event Withdrawn(
        address indexed from,
        address indexed to,
        uint256 sharesWithdrawn,
        address indexed token,
        address strategy,
        bool withdrawShares
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
     * @notice emitted when credit line address is updated
     * @param updatedCreditLine updated credit line contract address
     */
    event CreditLineUpdated(address indexed updatedCreditLine);

    /**
     * @notice emitted when strategy registry is updated
     * @param updatedStrategyRegistry updated strategy registry address
     */
    event StrategyRegistryUpdated(address indexed updatedStrategyRegistry);

    /**
     * @notice emitted when credit line allowance is refreshed
     * @param token token for which allowance is increased
     * @param from address of user from whcih allowance is increased
     * @param amount amount of tokens by which allowance is increased
     */
    event CreditLineAllowanceRefreshed(address indexed token, address indexed from, address indexed to, uint256 amount);

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
     * @param withdrawShares boolean indicating to withdraw in liquidity share or underlying token
     */
    function withdraw(
        address token,
        address strategy,
        address withdrawTo,
        uint256 amount,
        bool withdrawShares
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

    function balanceInShares(
        address user,
        address token,
        address strategy
    ) external view returns (uint256 shareBalance);

    function increaseAllowanceToCreditLine(
        address token,
        address from,
        uint256 amount
    ) external;

    function withdrawFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 amount,
        bool withdrawShares
    ) external returns (uint256 amountReceived);

    function getTotalTokens(address _user, address _token) external returns (uint256 _totalTokens);
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
pragma solidity 0.7.6;

import '../interfaces/ISavingsAccount.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

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
    ) internal returns (uint256) {
        transferTokens(_token, _from, address(this), _amount);
        address _approveTo = _strategy;
        IERC20(_token).safeApprove(_approveTo, _amount);
        uint256 _sharesReceived = _savingsAccount.deposit(_token, _strategy, _to, _amount);
        return _sharesReceived;
    }

    function savingsAccountTransferShares(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _shares,
        address _token,
        address _strategy
    ) internal returns (uint256) {
        if (_from == address(this)) {
            _savingsAccount.transferShares(_shares, _token, _strategy, _to);
        } else {
            _savingsAccount.transferSharesFrom(_shares, _token, _strategy, _from, _to);
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
    ) internal returns (uint256) {
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
    ) internal returns (uint256) {
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
        if (_amount == 0) {
            return 0;
        }
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
import '@openzeppelin/contracts/proxy/IBeacon.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Beacon is IBeacon, Ownable {
    address public impl;

    constructor(address _owner, address _impl) {
        impl = _impl;
        transferOwnership(_owner);
    }

    function implementation() external view override returns (address) {
        return impl;
    }

    function changeImpl(address _newImpl) external onlyOwner {
        impl = _newImpl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '@openzeppelin/contracts/proxy/IBeacon.sol';

contract MinimumBeaconProxy {
    address private immutable beacon;

    constructor(address _beacon) {
        beacon = _beacon;
    }

    function _implementation() internal view virtual returns (address) {
        return IBeacon(beacon).implementation();
    }

    fallback() external {
        address impl = _implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}