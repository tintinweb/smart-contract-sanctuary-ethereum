pragma solidity ^0.5.16;

// Libraries
// import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./externals/openzeppelin/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int256 x) internal pure returns (int256) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int256 x) internal pure returns (uint256) {
        return uint256(signedAbs(x));
    }
}

pragma solidity ^0.5.16;

// Internal references
import "./interfaces/IFlexibleStorage.sol";

// Libraries
import "./SafeDecimalMath.sol";

/// This library is to reduce SystemSettings contract size only and is not really
/// a proper library - so it shares knowledge of implementation details
/// Some of the setters were refactored into this library, and some setters remain in the
/// contract itself (SystemSettings)
library SystemSettingsLib {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    bytes32 public constant SETTINGS_CONTRACT_NAME = "SystemSettings";

    // No more synths may be issued than the value of SNX backing them.
    uint256 public constant MAX_ISSUANCE_RATIO = 1e18;

    // The fee period must be between 1 day and 60 days.
    uint256 public constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint256 public constant MAX_FEE_PERIOD_DURATION = 60 days;

    uint256 public constant MAX_TARGET_THRESHOLD = 50;

    uint256 public constant MAX_LIQUIDATION_RATIO = 1e18; // 100% issuance ratio
    uint256 public constant RATIO_FROM_TARGET_BUFFER = 2e18; // 200% - mininimum buffer between issuance ratio and liquidation ratio

    uint256 public constant MAX_LIQUIDATION_PENALTY = 9e18 / 10; // Max 90% liquidation penalty / bonus

    uint256 public constant MAX_LIQUIDATION_DELAY = 3 days;
    uint256 public constant MIN_LIQUIDATION_DELAY = 300; // 5 min

    // Exchange fee may not exceed 10%.
    uint256 public constant MAX_EXCHANGE_FEE_RATE = 1e18 / 10;

    // Minimum Stake time may not exceed 1 weeks.
    uint256 public constant MAX_MINIMUM_STAKE_TIME = 1 weeks;

    uint256 public constant MAX_CROSS_DOMAIN_GAS_LIMIT = 12e6;
    uint256 public constant MIN_CROSS_DOMAIN_GAS_LIMIT = 3e6;

    int256 public constant MAX_WRAPPER_MINT_FEE_RATE = 1e18;

    int256 public constant MAX_WRAPPER_BURN_FEE_RATE = 1e18;

    // Atomic block volume limit is encoded as uint192.
    uint256 public constant MAX_ATOMIC_VOLUME_PER_BLOCK = uint192(-1);

    // TWAP window must be between 1 min and 1 day.
    uint256 public constant MIN_ATOMIC_TWAP_WINDOW = 60;
    uint256 public constant MAX_ATOMIC_TWAP_WINDOW = 86400;

    // Volatility consideration window must be between 1 min and 1 day.
    uint256 public constant MIN_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = 60;
    uint256 public constant MAX_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = 86400;

    // workaround for library not supporting public constants in sol v0.5
    function contractName() external view returns (bytes32) {
        return SETTINGS_CONTRACT_NAME;
    }

    function setCrossDomainMessageGasLimit(
        IFlexibleStorage flexibleStorage,
        bytes32 gasLimitSettings,
        uint256 crossDomainMessageGasLimit
    ) external {
        require(
            crossDomainMessageGasLimit >= MIN_CROSS_DOMAIN_GAS_LIMIT && crossDomainMessageGasLimit <= MAX_CROSS_DOMAIN_GAS_LIMIT,
            "Out of range xDomain gasLimit"
        );
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, gasLimitSettings, crossDomainMessageGasLimit);
    }

    function setIssuanceRatio(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 ratio
    ) external {
        require(ratio <= MAX_ISSUANCE_RATIO, "New issuance ratio cannot exceed MAX_ISSUANCE_RATIO");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, ratio);
    }

    function setTradingRewardsEnabled(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bool _tradingRewardsEnabled
    ) external {
        flexibleStorage.setBoolValue(SETTINGS_CONTRACT_NAME, settingName, _tradingRewardsEnabled);
    }

    function setWaitingPeriodSecs(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _waitingPeriodSecs
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _waitingPeriodSecs);
    }

    function setPriceDeviationThresholdFactor(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _priceDeviationThresholdFactor
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _priceDeviationThresholdFactor);
    }

    function setFeePeriodDuration(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _feePeriodDuration
    ) external {
        require(_feePeriodDuration >= MIN_FEE_PERIOD_DURATION, "value < MIN_FEE_PERIOD_DURATION");
        require(_feePeriodDuration <= MAX_FEE_PERIOD_DURATION, "value > MAX_FEE_PERIOD_DURATION");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _feePeriodDuration);
    }

    function setTargetThreshold(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 percent
    ) external returns (uint256 threshold) {
        require(percent <= MAX_TARGET_THRESHOLD, "Threshold too high");
        threshold = percent.mul(SafeDecimalMath.unit()).div(100);

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, threshold);
    }

    function setLiquidationDelay(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 time
    ) external {
        require(time <= MAX_LIQUIDATION_DELAY, "Must be less than MAX_LIQUIDATION_DELAY");
        require(time >= MIN_LIQUIDATION_DELAY, "Must be greater than MIN_LIQUIDATION_DELAY");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, time);
    }

    function setLiquidationRatio(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _liquidationRatio,
        uint256 getSnxLiquidationPenalty,
        uint256 getIssuanceRatio
    ) external {
        require(
            _liquidationRatio <= MAX_LIQUIDATION_RATIO.divideDecimal(SafeDecimalMath.unit().add(getSnxLiquidationPenalty)),
            "liquidationRatio > MAX_LIQUIDATION_RATIO / (1 + penalty)"
        );

        // MIN_LIQUIDATION_RATIO is a product of target issuance ratio * RATIO_FROM_TARGET_BUFFER
        // Ensures that liquidation ratio is set so that there is a buffer between the issuance ratio and liquidation ratio.
        uint256 MIN_LIQUIDATION_RATIO = getIssuanceRatio.multiplyDecimal(RATIO_FROM_TARGET_BUFFER);
        require(_liquidationRatio >= MIN_LIQUIDATION_RATIO, "liquidationRatio < MIN_LIQUIDATION_RATIO");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _liquidationRatio);
    }

    function setLiquidationEscrowDuration(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 duration
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, duration);
    }

    function setSnxLiquidationPenalty(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 penalty
    ) external {
        // MAX_LIQUIDATION_PENALTY is enforced on both Collateral and SNX liquidations
        require(penalty <= MAX_LIQUIDATION_PENALTY, "penalty > MAX_LIQUIDATION_PENALTY");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, penalty);
    }

    function setSelfLiquidationPenalty(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 penalty
    ) external {
        require(penalty <= MAX_LIQUIDATION_PENALTY, "penalty > MAX_LIQUIDATION_PENALTY");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, penalty);
    }

    function setLiquidationPenalty(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 penalty
    ) external {
        require(penalty <= MAX_LIQUIDATION_PENALTY, "penalty > MAX_LIQUIDATION_PENALTY");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, penalty);
    }

    function setFlagReward(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 reward
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, reward);
    }

    function setLiquidateReward(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 reward
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, reward);
    }

    function setRateStalePeriod(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 period
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, period);
    }

    function setExchangeFeeRateForSynths(
        IFlexibleStorage flexibleStorage,
        bytes32 settingExchangeFeeRate,
        bytes32[] calldata synthKeys,
        uint256[] calldata exchangeFeeRates
    ) external {
        require(synthKeys.length == exchangeFeeRates.length, "Array lengths dont match");
        for (uint256 i = 0; i < synthKeys.length; i++) {
            require(exchangeFeeRates[i] <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");
            flexibleStorage.setUIntValue(
                SETTINGS_CONTRACT_NAME,
                keccak256(abi.encodePacked(settingExchangeFeeRate, synthKeys[i])),
                exchangeFeeRates[i]
            );
        }
    }

    function setMinimumStakeTime(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _seconds
    ) external {
        require(_seconds <= MAX_MINIMUM_STAKE_TIME, "stake time exceed maximum 1 week");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _seconds);
    }

    function setDebtSnapshotStaleTime(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _seconds
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _seconds);
    }

    function setAggregatorWarningFlags(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _flags
    ) external {
        require(_flags != address(0), "Valid address must be given");
        flexibleStorage.setAddressValue(SETTINGS_CONTRACT_NAME, settingName, _flags);
    }

    function setInteractionDelay(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _collateral,
        uint256 _interactionDelay
    ) external {
        require(_interactionDelay <= SafeDecimalMath.unit() * 3600, "Max 1 hour");
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _collateral)),
            _interactionDelay
        );
    }

    function setCollapseFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _collateral,
        uint256 _collapseFeeRate
    ) external {
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _collateral)),
            _collapseFeeRate
        );
    }

    function setAtomicMaxVolumePerBlock(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _maxVolume
    ) external {
        require(_maxVolume <= MAX_ATOMIC_VOLUME_PER_BLOCK, "Atomic max volume exceed maximum uint192");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _maxVolume);
    }

    function setAtomicTwapWindow(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _window
    ) external {
        require(_window >= MIN_ATOMIC_TWAP_WINDOW, "Atomic twap window under minimum 1 min");
        require(_window <= MAX_ATOMIC_TWAP_WINDOW, "Atomic twap window exceed maximum 1 day");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _window);
    }

    function setAtomicEquivalentForDexPricing(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        address _equivalent
    ) external {
        require(_equivalent != address(0), "Atomic equivalent is 0 address");
        flexibleStorage.setAddressValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _equivalent
        );
    }

    function setAtomicExchangeFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint256 _exchangeFeeRate
    ) external {
        require(_exchangeFeeRate <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _exchangeFeeRate
        );
    }

    function setAtomicVolatilityConsiderationWindow(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint256 _window
    ) external {
        if (_window != 0) {
            require(
                _window >= MIN_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
                "Atomic volatility consideration window under minimum 1 min"
            );
            require(
                _window <= MAX_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
                "Atomic volatility consideration window exceed maximum 1 day"
            );
        }
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _currencyKey)), _window);
    }

    function setAtomicVolatilityUpdateThreshold(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint256 _threshold
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _currencyKey)), _threshold);
    }

    function setPureChainlinkPriceForAtomicSwapsEnabled(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        bool _enabled
    ) external {
        flexibleStorage.setBoolValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _currencyKey)), _enabled);
    }

    function setCrossChainSynthTransferEnabled(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint256 _value
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _currencyKey)), _value);
    }

    function setExchangeMaxDynamicFee(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 maxFee
    ) external {
        require(maxFee != 0, "Max dynamic fee cannot be 0");
        require(maxFee <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, maxFee);
    }
}

pragma solidity ^0.5.16;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/iflexiblestorage
interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint256);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint256[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int256);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int256[] memory);

    function getAddressValue(bytes32 contractName, bytes32 record) external view returns (address);

    function getAddressValues(bytes32 contractName, bytes32[] calldata records) external view returns (address[] memory);

    function getBoolValue(bytes32 contractName, bytes32 record) external view returns (bool);

    function getBoolValues(bytes32 contractName, bytes32[] calldata records) external view returns (bool[] memory);

    function getBytes32Value(bytes32 contractName, bytes32 record) external view returns (bytes32);

    function getBytes32Values(bytes32 contractName, bytes32[] calldata records) external view returns (bytes32[] memory);

    // Mutative functions
    function deleteUIntValue(bytes32 contractName, bytes32 record) external;

    function deleteIntValue(bytes32 contractName, bytes32 record) external;

    function deleteAddressValue(bytes32 contractName, bytes32 record) external;

    function deleteBoolValue(bytes32 contractName, bytes32 record) external;

    function deleteBytes32Value(bytes32 contractName, bytes32 record) external;

    function setUIntValue(
        bytes32 contractName,
        bytes32 record,
        uint256 value
    ) external;

    function setUIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        uint256[] calldata values
    ) external;

    function setIntValue(
        bytes32 contractName,
        bytes32 record,
        int256 value
    ) external;

    function setIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        int256[] calldata values
    ) external;

    function setAddressValue(
        bytes32 contractName,
        bytes32 record,
        address value
    ) external;

    function setAddressValues(
        bytes32 contractName,
        bytes32[] calldata records,
        address[] calldata values
    ) external;

    function setBoolValue(
        bytes32 contractName,
        bytes32 record,
        bool value
    ) external;

    function setBoolValues(
        bytes32 contractName,
        bytes32[] calldata records,
        bool[] calldata values
    ) external;

    function setBytes32Value(
        bytes32 contractName,
        bytes32 record,
        bytes32 value
    ) external;

    function setBytes32Values(
        bytes32 contractName,
        bytes32[] calldata records,
        bytes32[] calldata values
    ) external;
}