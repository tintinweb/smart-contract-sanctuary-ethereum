pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";

// https://docs.synthetix.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}

pragma solidity ^0.5.16;

// Internal references
import "./AddressResolver.sol";

// https://docs.synthetix.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second) internal pure returns (bytes32[] memory combination) {
        combination = new bytes32[](first.length + second.length);

        for (uint256 i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint256 j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination = resolver.requireAndGetAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}

pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";

// Internal references
import "./Proxyable.sol";

// https://docs.synthetix.io/contracts/source/contracts/proxy
contract Proxy is Owned {
    Proxyable public target;

    constructor(address _owner) public Owned(_owner) {}

    function setTarget(Proxyable _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(_target);
    }

    function _emit(
        bytes calldata callData,
        uint256 numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint256 size = callData.length;
        bytes memory _callData = callData;
        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
            case 0 {
                log0(add(_callData, 32), size)
            }
            case 1 {
                log1(add(_callData, 32), size, topic1)
            }
            case 2 {
                log2(add(_callData, 32), size, topic1, topic2)
            }
            case 3 {
                log3(add(_callData, 32), size, topic1, topic2, topic3)
            }
            case 4 {
                log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
            }
        }
    }

    // solhint-disable no-complex-fallback
    function() external payable {
        // Mutable call setting Proxyable.messageSender as this is using call not delegatecall
        target.setMessageSender(msg.sender);

        assembly {
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

            /* We must explicitly forward ether to the underlying contract as well. */
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

            if iszero(result) {
                revert(free_ptr, returndatasize)
            }
            return(free_ptr, returndatasize)
        }
    }

    modifier onlyTarget() {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}

pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";

// Internal references
import "./Proxy.sol";

// https://docs.synthetix.io/contracts/source/contracts/proxyable
contract Proxyable is Owned {
    // This contract should be treated like an abstract contract

    /* The proxy this contract exists behind. */
    Proxy public proxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address public messageSender;

    constructor(address payable _proxy) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address payable _proxy) external onlyOwner {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }

    modifier onlyProxy() {
        _onlyProxy();
        _;
    }

    function _onlyProxy() private view {
        require(Proxy(msg.sender) == proxy, "Only the proxy can call");
    }

    modifier optionalProxy() {
        _optionalProxy();
        _;
    }

    function _optionalProxy() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
    }

    modifier optionalProxy_onlyOwner() {
        _optionalProxy_onlyOwner();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _optionalProxy_onlyOwner() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
    }

    event ProxyUpdated(address proxyAddress);
}

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

// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface ICollateralAggregator {
    function collateralByIssuerAggregation(bytes32 collateralKey, address account) external view returns (uint256);

    function sendDeposit(
        address _account,
        uint256 amount,
        bytes32 collateralKey
    ) external;

    function sendWithdraw(
        address _account,
        uint256 amount,
        bytes32 collateralKey
    ) external;
}

pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint256[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        );

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    )
        external
        view
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        );

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 value,
            uint256 systemValue,
            uint256 systemSourceRate,
            uint256 systemDestinationRate
        );

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint256);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint256 startingRoundId,
        uint256 startingTimestamp,
        uint256 timediff
    ) external view returns (uint256);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint256 roundId) external view returns (uint256 rate, uint256 time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint256 rate, uint256 time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint256 rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint256);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint256);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint256 numRounds,
        uint256 roundId
    ) external view returns (uint256[] memory rates, uint256[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint256[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint256[] memory);

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);
}

pragma solidity >=0.4.24;
pragma experimental ABIEncoderV2;

// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    struct ExchangeEntrySettlement {
        bytes32 src;
        uint256 amount;
        bytes32 dest;
        uint256 reclaim;
        uint256 rebate;
        uint256 srcRoundIdAtPeriodEnd;
        uint256 destRoundIdAtPeriodEnd;
        uint256 timestamp;
    }

    struct ExchangeEntry {
        uint256 sourceRate;
        uint256 destinationRate;
        uint256 destinationAmount;
        uint256 exchangeFeeRate;
        uint256 exchangeDynamicFeeRate;
        uint256 roundIdForSrc;
        uint256 roundIdForDest;
    }

    struct ExchangeArgs {
        address fromAccount;
        address destAccount;
        bytes32 sourceCurrencyKey;
        bytes32 destCurrencyKey;
        uint256 sourceAmount;
        uint16 destChainId;
    }

    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint256 amount,
        uint256 refunded
    ) external view returns (uint256 amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint256);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint256 reclaimAmount,
            uint256 rebateAmount,
            uint256 numEntries
        );

    // function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint256);

    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint256 feeRate, bool tooVolatile);

    function getAmountsForExchange(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 amountReceived,
            uint256 fee,
            uint256 exchangeFeeRate
        );

    // function priceDeviationThresholdFactor() external view returns (uint256);

    // function waitingPeriodSecs() external view returns (uint256);

    // function lastExchangeRate(bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function exchange(
        address from,
        address rewardAddress,
        bytes32 trackingCode,
        ExchangeArgs calldata args
    ) external returns (uint256 amountReceived);

    function exchangeAtomically(
        bytes32 trackingCode,
        uint256 minAmount,
        ExchangeArgs calldata args
    ) external returns (uint256 amountReceived);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntries
        );

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;

    function updateDestinationForExchange(
        address recipient,
        bytes32 destinationKey,
        uint256 destinationAmount,
        uint256 fee
    ) external;
}

pragma solidity >=0.4.24;

import "../interfaces/ISynth.sol";

// https://docs.synthetix.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views

    function allNetworksDebtInfo()
        external
        view
        returns (
            uint256 debt,
            uint256 sharesSupply,
            bool isStale
        );

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function availableSynths(uint256 index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer) external view returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer) external view returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint256);

    function checkFreeCollateral(address _issuer, bytes32 _collateralKey) external view returns (uint256 withdrawableSynthr);

    function issueSynths(address from, uint256 amount) external;

    function issueSynthsOnBehalf(
        address issueFor,
        address from,
        uint256 amount
    ) external;

    function issueMaxSynths(address from) external;

    function issueMaxSynthsOnBehalf(address issueFor, address from) external;

    function burnSynths(address from, uint256 amount) external;

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint256 amount
    ) external;

    function burnSynthsToTarget(address from) external;

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint256 balance
    ) external;

    function setCurrentPeriodId(uint128 periodId) external;

    function liquidateAccount(
        address account,
        bytes32 collateralKey,
        bool isSelfLiquidation
    ) external returns (uint256 totalRedeemed, uint256 amountToLiquidate);

    function updateDebtForExchange(
        address sourceAccount,
        bytes32 destKey,
        address destAccount,
        uint256 destAmount,
        uint16 destChainId
    ) external;
}

pragma solidity >=0.4.24;

interface ILiquidator {
    // Views
    function issuanceRatio() external view returns (uint256);

    function liquidationDelay() external view returns (uint256);

    function liquidationRatio() external view returns (uint256);

    function liquidationEscrowDuration() external view returns (uint256);

    function liquidationPenalty() external view returns (uint256);

    function selfLiquidationPenalty() external view returns (uint256);

    function liquidateReward() external view returns (uint256);

    function flagReward() external view returns (uint256);

    function liquidationCollateralRatio() external view returns (uint256);

    function getLiquidationDeadlineForAccount(address account) external view returns (uint256);

    function getLiquidationCallerForAccount(address account) external view returns (address);

    function isLiquidationOpen(address account, bool isSelfLiquidation) external view returns (bool);

    function isLiquidationDeadlinePassed(address account) external view returns (bool);

    function calculateAmountToFixCollateral(
        uint256 debtBalance,
        uint256 collateral,
        uint256 penalty
    ) external view returns (uint256);

    // Mutative Functions
    function flagAccountForLiquidation(address account) external;

    // Restricted: used internally to Synthetix contracts
    function removeAccountInLiquidation(address account) external;

    function checkAndRemoveAccountInLiquidation(address account) external;
}

pragma solidity >=0.4.24;

interface ILiquidatorRewards {
    // Views
    function totalLiquidates() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    // Mutative
    function rewardRestitution(
        address _to,
        uint256 _amount,
        bytes32 _collateralKey
    ) external returns (bool);

    function getReward(address account) external;

    function notifyRewardAmount(uint256 reward) external;

    function updateEntry(address account) external;
}

pragma solidity ^0.5.16;

import "../interfaces/ILiquidatorRewards.sol";

interface ILiquidatorRewardsManager {
    // Views
    function getLiquidateReward(bytes32 key) external view returns (ILiquidatorRewards);

    function getLiquidateRewards() external view returns (bytes32[] memory);

    function totalLiquidatesBalanceOnChain() external view returns (uint256 _totalLiquidates);

    function totalLiquidateEarnedOnChain(address account) external view returns (uint256 _totalLiquidates);

    function totalLiquidateEarned(address account) external view returns (uint256);

    function totalLiquidateEarnedPerCurrencyKey(bytes32 currencyKey, address account) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */
    function updateEntry(address account) external;

    function sendUpdateEntry(
        bytes32 collateralKey,
        address account,
        uint256 amount
    ) external;

    function sendNotifyReward(bytes32 collateralKey, uint256 amount) external;
}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(
        address account,
        uint256 amount,
        bool isCrossChain
    ) external;

    function issue(
        address account,
        uint256 amount,
        bool isCrossChain
    ) external;
}

pragma solidity >=0.4.24;

import "./ISynth.sol";

// https://docs.synthetix.io/contracts/source/interfaces/isynthetix
interface ISynthetix {
    // Views
    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function chainBalanceOf(address account) external view returns (uint256);

    function chainBalanceOfPerKey(address _account, bytes32 _collateralKey) external view returns (uint256);

    function collateralCurrency(bytes32 _collateralKey) external view returns (address);

    function collateralByAddress(address _collateralCurrency) external view returns (bytes32);

    function getAvailableCollaterals() external view returns (bytes32[] memory);

    // Mutative Functions
    function burnSynths(uint256 amount) external;

    function withdrawCollateral(bytes32 collateralKey, uint256 collateralAmount) external;

    function burnSynthsOnBehalf(address burnForAddress, uint256 amount) external;

    function burnSynthsToTarget() external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint16 destChainId
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint16 destChainId
    ) external returns (uint256 amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode,
        uint16 destChainId
    ) external returns (uint256 amountReceived);

    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode,
        uint16 destChainId
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode,
        uint16 destChainId
    ) external returns (uint256 amountReceived);

    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint256 minAmount,
        uint16 destChainId
    ) external returns (uint256 amountReceived);

    function issueMaxSynths() external;

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function issueSynths(
        bytes32 currencyKey,
        uint256 amount,
        uint256 synthToMint
    ) external payable;

    function issueSynthsOnBehalf(
        address issueForAddress,
        bytes32 _collateralKey,
        uint256 _collateralAmount,
        uint256 _synthToMint
    ) external payable;

    function mint() external returns (bool);

    // Liquidations
    function liquidateDelinquentAccount(address account, bytes32 collateralKey) external returns (bool);

    function liquidateSelf(bytes32 collateralKey) external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint256 amount) external;

    function mintSecondaryRewards(uint256 amount) external;

    function burnSecondary(address account, uint256 amount) external;
}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/isystemstatus
interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function systemSuspended() external view returns (bool);

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireFuturesActive() external view;

    function requireFuturesMarketActive(bytes32 marketKey) external view;

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function synthSuspended(bytes32 currencyKey) external view returns (bool);

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function futuresSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.5.16;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
// Inheritance
import "../interfaces/IERC20.sol";
import "./ExternWrappedStateToken.sol";
import "../MixinResolver.sol";
import "../interfaces/ISynthetix.sol";

// Internal references
import "../interfaces/ISynth.sol";
import "../interfaces/ICollateralAggregator.sol";
import "../interfaces/ISystemStatus.sol";
import "../interfaces/IExchanger.sol";
import "../interfaces/IExchangeRates.sol";
import "../interfaces/IIssuer.sol";
import "../interfaces/ILiquidator.sol";
import "../interfaces/ILiquidatorRewards.sol";
import "../interfaces/ILiquidatorRewardsManager.sol";
import "../libraries/TransferHelper.sol";

contract BaseWrappedSynthr is IERC20, ExternWrappedStateToken, MixinResolver, ISynthetix {
    // ========== STATE VARIABLES ==========

    // Available Synths which can be used with the system
    string public constant TOKEN_NAME = "Wrapped Synthr";
    string public constant TOKEN_SYMBOL = "SNX";
    uint8 public constant DECIMALS = 18;
    bytes32 public constant sUSD = "sUSD";

    address internal constant NULL_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // ========== ADDRESS RESOLVER CONFIGURATION ==========
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_LIQUIDATOR = "Liquidator";
    bytes32 private constant CONTRACT_COLLATERAL_AGGREGATOR = "CollateralAggregator";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_LIQUIDATOR_REWARDS_MANAGER = "LiquidatorRewardsManager";

    mapping(bytes32 => address) public collateralCurrency;
    mapping(address => bytes32) public collateralByAddress;
    bytes32[] public availableCollateralCurrencies;
    mapping(bytes32 => mapping(address => uint256)) public collateralByIssuer;

    // ========== CONSTRUCTOR ==========
    constructor(
        address payable _proxy,
        address _owner,
        uint256 _totalSupply,
        address _resolver
    ) public ExternWrappedStateToken(_proxy, TOKEN_NAME, TOKEN_SYMBOL, _totalSupply, DECIMALS, _owner) MixinResolver(_resolver) {}

    // ========== VIEWS ==========

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](7);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_EXCHANGER;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_LIQUIDATOR;
        addresses[4] = CONTRACT_COLLATERAL_AGGREGATOR;
        addresses[5] = CONTRACT_EXRATES;
        addresses[6] = CONTRACT_LIQUIDATOR_REWARDS_MANAGER;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function liquidatorRewardsManager() internal view returns (ILiquidatorRewardsManager) {
        return ILiquidatorRewardsManager(requireAndGetAddress(CONTRACT_LIQUIDATOR_REWARDS_MANAGER));
    }

    function liquidatorRewards(bytes32 key) internal view returns (ILiquidatorRewards) {
        return liquidatorRewardsManager().getLiquidateReward(key);
    }

    function liquidator() internal view returns (ILiquidator) {
        return ILiquidator(requireAndGetAddress(CONTRACT_LIQUIDATOR));
    }

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool) {
        return exchanger().maxSecsLeftInWaitingPeriod(messageSender, currencyKey) > 0;
    }

    function collateralAggregator() internal view returns (ICollateralAggregator) {
        return ICollateralAggregator(requireAndGetAddress(CONTRACT_COLLATERAL_AGGREGATOR));
    }

    function allowance(address, address) external view returns (uint256) {
        _notImplemented();
        return 0;
    }

    function getAvailableCollaterals() external view returns (bytes32[] memory) {
        return availableCollateralCurrencies;
    }

    // ========== MUTATIVE FUNCTIONS ==========

    function addCollateralCurrency(address _collateralAddress, bytes32 _currencyKey) external optionalProxy onlyOwner {
        require(collateralCurrency[_currencyKey] == address(0), "Collateral Currency Key exists already");
        require(collateralByAddress[_collateralAddress] == bytes32(0), "Collateral Address exists already");
        collateralCurrency[_currencyKey] = _collateralAddress;
        collateralByAddress[_collateralAddress] = _currencyKey;
        availableCollateralCurrencies.push(_currencyKey);
        emit CollateralCurrencyAdded(_currencyKey, _collateralAddress);
    }

    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint16 destChainId
    ) external exchangeActive(sourceCurrencyKey, destinationCurrencyKey) optionalProxy returns (uint256 amountReceived) {
        IExchanger.ExchangeArgs memory args = IExchanger.ExchangeArgs({
            fromAccount: messageSender,
            destAccount: messageSender,
            sourceCurrencyKey: sourceCurrencyKey,
            destCurrencyKey: destinationCurrencyKey,
            sourceAmount: sourceAmount,
            destChainId: destChainId
        });
        (amountReceived) = exchanger().exchange(messageSender, messageSender, bytes32(0), args);
    }

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint16 destChainId
    ) external exchangeActive(sourceCurrencyKey, destinationCurrencyKey) optionalProxy returns (uint256 amountReceived) {
        IExchanger.ExchangeArgs memory args = IExchanger.ExchangeArgs({
            fromAccount: exchangeForAddress,
            destAccount: exchangeForAddress,
            sourceCurrencyKey: sourceCurrencyKey,
            destCurrencyKey: destinationCurrencyKey,
            sourceAmount: sourceAmount,
            destChainId: destChainId
        });
        (amountReceived) = exchanger().exchange(messageSender, exchangeForAddress, bytes32(0), args);
    }

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode,
        uint16 destChainId
    ) external exchangeActive(sourceCurrencyKey, destinationCurrencyKey) optionalProxy returns (uint256 amountReceived) {
        IExchanger.ExchangeArgs memory args = IExchanger.ExchangeArgs({
            fromAccount: messageSender,
            destAccount: messageSender,
            sourceCurrencyKey: sourceCurrencyKey,
            destCurrencyKey: destinationCurrencyKey,
            sourceAmount: sourceAmount,
            destChainId: destChainId
        });
        (amountReceived) = exchanger().exchange(messageSender, rewardAddress, trackingCode, args);
    }

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode,
        uint16 destChainId
    ) external exchangeActive(sourceCurrencyKey, destinationCurrencyKey) optionalProxy returns (uint256 amountReceived) {
        IExchanger.ExchangeArgs memory args = IExchanger.ExchangeArgs({
            fromAccount: exchangeForAddress,
            destAccount: exchangeForAddress,
            sourceCurrencyKey: sourceCurrencyKey,
            destCurrencyKey: destinationCurrencyKey,
            sourceAmount: sourceAmount,
            destChainId: destChainId
        });
        (amountReceived) = exchanger().exchange(messageSender, rewardAddress, trackingCode, args);
    }

    function approve(address, uint256) external returns (bool) {
        _notImplemented();
        return true;
    }

    function transfer(address, uint256) external systemActive returns (bool) {
        _notImplemented();
        return true;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external systemActive returns (bool) {
        _notImplemented();
        return true;
    }

    function burnSynths(uint256 amount) external issuanceActive optionalProxy {
        return issuer().burnSynths(messageSender, amount);
    }

    function burnSynthsOnBehalf(address burnForAddress, uint256 amount) external issuanceActive optionalProxy {
        return issuer().burnSynthsOnBehalf(burnForAddress, messageSender, amount);
    }

    function burnSynthsToTarget() external issuanceActive optionalProxy {
        return issuer().burnSynthsToTarget(messageSender);
    }

    function burnSynthsToTargetOnBehalf(address burnForAddress) external issuanceActive optionalProxy {
        return issuer().burnSynthsToTargetOnBehalf(burnForAddress, messageSender);
    }

    function collateralTransfer(
        address _to,
        bytes32 _collateralKey,
        uint256 _usdAmount
    ) public systemActive optionalProxy returns (bool) {
        require(collateralCurrency[_collateralKey] != address(0), "");
        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        uint256 collateralAmount = _usdAmount.divideDecimalRound(collateralRate);
        if (collateralCurrency[_collateralKey] == NULL_ADDRESS) {
            require(address(this).balance >= collateralAmount, "Insufficient ETH amount to transfer");
            TransferHelper.safeTransferETH(_to, collateralAmount);
        } else {
            require(
                IERC20(collateralCurrency[_collateralKey]).balanceOf(address(this)) >= collateralAmount,
                "Insufficient collateral amount to transfer"
            );
            TransferHelper.safeTransfer(collateralCurrency[_collateralKey], _to, collateralAmount);
        }
        return true;
    }

    /// @notice Force liquidate a delinquent account and distribute the redeemed SNX rewards amongst the appropriate recipients.
    /// @dev The SNX transfers will revert if the amount to send is more than balanceOf account (i.e. due to escrowed balance).
    function liquidateDelinquentAccount(address account, bytes32 collateralKey)
        external
        systemActive
        optionalProxy
        returns (bool)
    {
        (uint256 totalRedeemed, uint256 amountLiquidated) = issuer().liquidateAccount(account, collateralKey, false);

        emitAccountLiquidated(account, totalRedeemed, amountLiquidated, messageSender);

        if (totalRedeemed > 0) {
            uint256 stakerRewards; // The amount of rewards to be sent to the LiquidatorRewards contract.
            uint256 flagReward = liquidator().flagReward();
            uint256 liquidateReward = liquidator().liquidateReward();
            // Check if the total amount of redeemed SNX is enough to payout the liquidation rewards.
            if (totalRedeemed > flagReward.add(liquidateReward)) {
                // Transfer the flagReward to the account who flagged this account for liquidation.
                address flagger = liquidator().getLiquidationCallerForAccount(account);
                bool flagRewardTransferSucceeded = collateralTransfer(flagger, collateralKey, flagReward);
                require(flagRewardTransferSucceeded, "Flag reward transfer did not succeed");

                // Transfer the liquidateReward to liquidator (the account who invoked this liquidation).
                // bool liquidateRewardTransferSucceeded = _transferByProxy(account, messageSender, liquidateReward);
                bool liquidateRewardTransferSucceeded = collateralTransfer(messageSender, collateralKey, liquidateReward);
                require(liquidateRewardTransferSucceeded, "Liquidate reward transfer did not succeed");

                // The remaining SNX to be sent to the LiquidatorRewards contract.
                stakerRewards = totalRedeemed.sub(flagReward.add(liquidateReward));
            } else {
                /* If the total amount of redeemed SNX is greater than zero 
                but is less than the sum of the flag & liquidate rewards,
                then just send all of the SNX to the LiquidatorRewards contract. */
                stakerRewards = totalRedeemed;
            }

            bool liquidatorRewardTransferSucceeded = collateralTransfer(
                address(liquidatorRewards(collateralKey)),
                collateralKey,
                stakerRewards
            );
            require(liquidatorRewardTransferSucceeded, "Transfer to LiquidatorRewards failed");
            _burn(account, totalRedeemed, collateralKey);

            // Inform the LiquidatorRewards contract about the incoming SNX rewards.
            (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(collateralKey);
            uint256 collateralAmount = stakerRewards.divideDecimalRound(collateralRate);
            liquidatorRewards(collateralKey).notifyRewardAmount(collateralAmount);

            return true;
        } else {
            // In this unlikely case, the total redeemed SNX is not greater than zero so don't perform any transfers.
            return false;
        }
    }

    /// @notice Allows an account to self-liquidate anytime its c-ratio is below the target issuance ratio.
    function liquidateSelf(bytes32 collateralKey) external systemActive optionalProxy returns (bool) {
        // Self liquidate the account (`isSelfLiquidation` flag must be set to `true`).
        (uint256 totalRedeemed, uint256 amountLiquidated) = issuer().liquidateAccount(messageSender, collateralKey, true);

        emitAccountLiquidated(messageSender, totalRedeemed, amountLiquidated, messageSender);

        // Transfer the redeemed SNX to the LiquidatorRewards contract.
        // Reverts if amount to redeem is more than balanceOf account (i.e. due to escrowed balance).
        bool success = collateralTransfer(address(liquidatorRewards(collateralKey)), collateralKey, totalRedeemed);
        require(success, "Transfer to LiquidatorRewards failed");
        _burn(messageSender, totalRedeemed, collateralKey);

        // Inform the LiquidatorRewards contract about the incoming SNX rewards.
        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(collateralKey);
        uint256 collateralAmount = totalRedeemed.divideDecimalRound(collateralRate);
        liquidatorRewards(collateralKey).notifyRewardAmount(collateralAmount);

        return success;
    }

    /**
     * @notice Once off function for SIP-239 to recover unallocated SNX rewards
     * due to an initialization issue in the LiquidatorRewards contract deployed in SIP-148.
     * @param amount The amount of SNX to be recovered and distributed to the rightful owners
     */
    bool public restituted = false;

    function initializeLiquidatorRewardsRestitution(uint256 amount, bytes32 _collateralKey) external onlyOwner {
        if (!restituted) {
            restituted = true;
            bool success = liquidatorRewards(_collateralKey).rewardRestitution(owner, amount, _collateralKey);
            // bool success = _transferByProxy(address(liquidatorRewards()), owner, amount);
            require(success, "restitution transfer failed");
        }
    }

    function mint() external returns (bool) {
        _notImplemented();
    }

    function mintSecondary(address, uint256) external {
        _notImplemented();
    }

    function mintSecondaryRewards(uint256) external {
        _notImplemented();
    }

    function burnSecondary(address, uint256) external {
        _notImplemented();
    }

    function _mint(
        address _to,
        uint256 _synthrAmount,
        bytes32 _collateralKey
    ) internal returns (bool) {
        emitTransfer(address(0), _to, _synthrAmount);

        // Increase total supply by minted amount
        totalSupply = totalSupply.add(_synthrAmount);

        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        uint256 collateralAmount = _synthrAmount.divideDecimalRound(collateralRate);
        collateralByIssuer[_collateralKey][_to] = collateralByIssuer[_collateralKey][_to].add(collateralAmount);
        collateralAggregator().sendDeposit(_to, collateralAmount, _collateralKey);

        return true;
    }

    function _burn(
        address _to,
        uint256 _synthrAmount,
        bytes32 _collateralKey
    ) internal returns (bool) {
        emitTransfer(_to, address(0), _synthrAmount);

        // Increase total supply by minted amount
        totalSupply = totalSupply.sub(_synthrAmount);

        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        uint256 collateralAmount = _synthrAmount.divideDecimalRound(collateralRate);
        collateralByIssuer[_collateralKey][_to] = collateralByIssuer[_collateralKey][_to].sub(collateralAmount);
        collateralAggregator().sendWithdraw(_to, collateralAmount, _collateralKey);

        return true;
    }

    function _notImplemented() internal pure {
        revert("Cannot be run on this layer");
    }

    // ========== MODIFIERS ==========

    modifier systemActive() {
        _systemActive();
        _;
    }

    function _systemActive() private view {
        systemStatus().requireSystemActive();
    }

    modifier issuanceActive() {
        _issuanceActive();
        _;
    }

    function _issuanceActive() private view {
        systemStatus().requireIssuanceActive();
    }

    modifier exchangeActive(bytes32 src, bytes32 dest) {
        _exchangeActive(src, dest);
        _;
    }

    function _exchangeActive(bytes32 src, bytes32 dest) private view {
        systemStatus().requireExchangeBetweenSynthsAllowed(src, dest);
    }

    modifier onlyExchanger() {
        _onlyExchanger();
        _;
    }

    function _onlyExchanger() private view {
        require(msg.sender == address(exchanger()), "Only Exchanger can invoke this");
    }

    // ========== EVENTS ==========
    event CollateralCurrencyAdded(bytes32 currencyKey, address collateralCurrency);

    event AccountLiquidated(address indexed account, uint256 snxRedeemed, uint256 amountLiquidated, address liquidator);
    bytes32 internal constant ACCOUNTLIQUIDATED_SIG = keccak256("AccountLiquidated(address,uint256,uint256,address)");

    function emitAccountLiquidated(
        address account,
        uint256 snxRedeemed,
        uint256 amountLiquidated,
        address liquidator_
    ) internal {
        proxy._emit(
            abi.encode(snxRedeemed, amountLiquidated, liquidator_),
            2,
            ACCOUNTLIQUIDATED_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }

    event SynthExchange(
        address indexed account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    );
    bytes32 internal constant SYNTH_EXCHANGE_SIG = keccak256("SynthExchange(address,bytes32,uint256,bytes32,uint256,address)");

    function emitSynthExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    ) external onlyExchanger {
        proxy._emit(
            abi.encode(fromCurrencyKey, fromAmount, toCurrencyKey, toAmount, toAddress),
            2,
            SYNTH_EXCHANGE_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }

    event ExchangeTracking(bytes32 indexed trackingCode, bytes32 toCurrencyKey, uint256 toAmount, uint256 fee);
    bytes32 internal constant EXCHANGE_TRACKING_SIG = keccak256("ExchangeTracking(bytes32,bytes32,uint256,uint256)");

    function emitExchangeTracking(
        bytes32 trackingCode,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        uint256 fee
    ) external onlyExchanger {
        proxy._emit(abi.encode(toCurrencyKey, toAmount, fee), 2, EXCHANGE_TRACKING_SIG, trackingCode, 0, 0);
    }

    event ExchangeReclaim(address indexed account, bytes32 currencyKey, uint256 amount);
    bytes32 internal constant EXCHANGERECLAIM_SIG = keccak256("ExchangeReclaim(address,bytes32,uint256)");

    function emitExchangeReclaim(
        address account,
        bytes32 currencyKey,
        uint256 amount
    ) external onlyExchanger {
        proxy._emit(abi.encode(currencyKey, amount), 2, EXCHANGERECLAIM_SIG, addressToBytes32(account), 0, 0);
    }

    event ExchangeRebate(address indexed account, bytes32 currencyKey, uint256 amount);
    bytes32 internal constant EXCHANGEREBATE_SIG = keccak256("ExchangeRebate(address,bytes32,uint256)");

    function emitExchangeRebate(
        address account,
        bytes32 currencyKey,
        uint256 amount
    ) external onlyExchanger {
        proxy._emit(abi.encode(currencyKey, amount), 2, EXCHANGEREBATE_SIG, addressToBytes32(account), 0, 0);
    }
}

pragma solidity ^0.5.16;

// Inheritance
import "../Owned.sol";
import "../Proxyable.sol";

// Libraries
import "../SafeDecimalMath.sol";

// https://docs.synthetix.io/contracts/source/contracts/externstatetoken
contract ExternWrappedStateToken is Owned, Proxyable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /* Other ERC20 fields. */
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    constructor(
        address payable _proxy,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimals,
        address _owner
    ) public Owned(_owner) Proxyable(_proxy) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;
    }

    /* ========== EVENTS ========== */
    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    bytes32 internal constant TRANSFER_SIG = keccak256("Transfer(address,address,uint256)");

    function emitTransfer(
        address from,
        address to,
        uint256 value
    ) internal {
        proxy._emit(abi.encode(value), 3, TRANSFER_SIG, addressToBytes32(from), addressToBytes32(to), 0);
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

// Inheritance
import "./BaseWrappedSynthr.sol";
import "../SafeDecimalMath.sol";
import "../interfaces/IExchanger.sol";

// Internal references
import "../libraries/TransferHelper.sol";

// https://docs.synthetix.io/contracts/source/contracts/synthetix
contract WrappedSynthr is BaseWrappedSynthr {
    using SafeDecimalMath for uint256;
    bytes32 public constant CONTRACT_NAME = "Synthetix";

    // ========== ADDRESS RESOLVER CONFIGURATION ==========

    // ========== CONSTRUCTOR ==========

    constructor(
        address payable _proxy,
        address _owner,
        uint256 _totalSupply,
        address _resolver
    ) public BaseWrappedSynthr(_proxy, _owner, _totalSupply, _resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseWrappedSynthr.resolverAddressesRequired();
        addresses = existingAddresses;
        // bytes32[] memory newAddresses = new bytes32[](1);
        // newAddresses[0] = CONTRACT_SUPPLYSCHEDULE;
        // return combineArrays(existingAddresses, newAddresses);
    }

    // ========== VIEWS ==========

    function chainBalanceOf(address account) external view returns (uint256) {
        uint256 synthrBalance;
        for (uint256 ii = 0; ii < availableCollateralCurrencies.length; ii++) {
            bytes32 _collateralCurrencyKey = availableCollateralCurrencies[ii];
            if (collateralByIssuer[_collateralCurrencyKey][account] > 0) {
                (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralCurrencyKey);
                synthrBalance += collateralByIssuer[_collateralCurrencyKey][account].multiplyDecimal(collateralRate);
            }
        }
        return synthrBalance;
    }

    function chainBalanceOfPerKey(address _account, bytes32 _collateralKey) external view returns (uint256) {
        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        return collateralByIssuer[_collateralKey][_account].multiplyDecimal(collateralRate);
    }

    // ========== OVERRIDDEN FUNCTIONS ==========
    function balanceOf(address account) external view returns (uint256) {
        uint256 synthrBalance;
        for (uint256 ii = 0; ii < availableCollateralCurrencies.length; ii++) {
            bytes32 _collateralCurrencyKey = availableCollateralCurrencies[ii];
            if (collateralAggregator().collateralByIssuerAggregation(_collateralCurrencyKey, account) > 0) {
                (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralCurrencyKey);
                synthrBalance += collateralAggregator()
                    .collateralByIssuerAggregation(_collateralCurrencyKey, account)
                    .multiplyDecimal(collateralRate);
            }
        }
        return synthrBalance;
    }

    // SIP-140 The initiating user of this exchange will receive the proceeds of the exchange
    // Note: this function may have unintended consequences if not understood correctly. Please
    // read SIP-140 for more information on the use-case
    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode,
        uint16 destChainId
    ) external exchangeActive(sourceCurrencyKey, destinationCurrencyKey) optionalProxy returns (uint256 amountReceived) {
        IExchanger.ExchangeArgs memory args = IExchanger.ExchangeArgs({
            fromAccount: messageSender,
            destAccount: tx.origin,
            sourceCurrencyKey: sourceCurrencyKey,
            destCurrencyKey: destinationCurrencyKey,
            sourceAmount: sourceAmount,
            destChainId: destChainId
        });
        (amountReceived) = exchanger().exchange(messageSender, rewardAddress, trackingCode, args);
    }

    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint256 minAmount,
        uint16 destChainId
    ) external exchangeActive(sourceCurrencyKey, destinationCurrencyKey) optionalProxy returns (uint256 amountReceived) {
        IExchanger.ExchangeArgs memory args = IExchanger.ExchangeArgs({
            fromAccount: messageSender,
            destAccount: messageSender,
            sourceCurrencyKey: sourceCurrencyKey,
            destCurrencyKey: destinationCurrencyKey,
            sourceAmount: sourceAmount,
            destChainId: destChainId
        });
        return exchanger().exchangeAtomically(trackingCode, minAmount, args);
    }

    function settle(bytes32 currencyKey)
        external
        optionalProxy
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntriesSettled
        )
    {
        return exchanger().settle(messageSender, currencyKey);
    }

    function issueSynths(
        bytes32 _collateralKey,
        uint256 _collateralAmount,
        uint256 _synthToMint
    ) external payable issuanceActive optionalProxy {
        if (_collateralAmount > 0) {
            _issueSynths(messageSender, messageSender, _collateralKey, _collateralAmount);
        }
        if (_synthToMint > 0) {
            return issuer().issueSynths(messageSender, _synthToMint);
        }
        return;
    }

    function issueSynthsOnBehalf(
        address issueForAddress,
        bytes32 _collateralKey,
        uint256 _collateralAmount,
        uint256 _synthToMint
    ) external payable issuanceActive optionalProxy {
        if (_collateralAmount > 0) {
            _issueSynths(messageSender, issueForAddress, _collateralKey, _collateralAmount);
        }
        if (_synthToMint > 0) {
            return issuer().issueSynthsOnBehalf(issueForAddress, messageSender, _synthToMint);
        }
        return;
    }

    function issueMaxSynths() external issuanceActive optionalProxy {
        return issuer().issueMaxSynths(messageSender);
    }

    function issueMaxSynthsOnBehalf(address issueForAddress) external issuanceActive optionalProxy {
        return issuer().issueMaxSynthsOnBehalf(issueForAddress, messageSender);
    }

    function _issueSynths(
        address from,
        address to,
        bytes32 _collateralKey,
        uint256 _collateralAmount
    ) internal {
        require(collateralCurrency[_collateralKey] != address(0), "No Collateral Currency exists.");
        if (collateralCurrency[_collateralKey] == NULL_ADDRESS) {
            require(msg.value >= _collateralAmount, "Synthr: insufficient eth amount");
            if (msg.value > _collateralAmount) {
                (bool success, ) = from.call.value(msg.value - _collateralAmount)("");
                require(success, "Transfer failed");
            }
        } else {
            TransferHelper.safeTransferFrom(collateralCurrency[_collateralKey], from, address(this), _collateralAmount);
        }

        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        uint256 synthrToMint = _collateralAmount.multiplyDecimal(collateralRate);
        bool isSucceed = _mint(to, synthrToMint, _collateralKey);
        require(isSucceed, "Mint Synthr failed");
    }

    function withdrawCollateral(bytes32 _collateralKey, uint256 _collateralAmount) external issuanceActive optionalProxy {
        require(collateralCurrency[_collateralKey] != address(0), "No Collateral Currency exists.");
        require(
            collateralAggregator().collateralByIssuerAggregation(_collateralKey, messageSender) >= _collateralAmount,
            "Insufficient Collateral Balance to burn."
        );
        require(_collateralAmount <= issuer().checkFreeCollateral(messageSender, _collateralKey), "Overflow free collateral.");
        if (collateralCurrency[_collateralKey] == NULL_ADDRESS) {
            require(address(this).balance >= _collateralAmount, "Insufficient ETH balance to burn.");
            TransferHelper.safeTransferETH(messageSender, _collateralAmount);
        } else {
            require(
                IERC20(collateralCurrency[_collateralKey]).balanceOf(address(this)) >= _collateralAmount,
                "Insufficient Collateral Balance to burn on Contract."
            );
            TransferHelper.safeTransfer(collateralCurrency[_collateralKey], messageSender, _collateralAmount);
        }

        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        uint256 synthrToBurn = _collateralAmount.multiplyDecimal(collateralRate);
        bool isSucceed = _burn(messageSender, synthrToBurn, _collateralKey);
        require(isSucceed, "Burn Synthr failed.");

        emit WithdrawCollateral(
            messageSender,
            _collateralKey,
            collateralCurrency[_collateralKey],
            _collateralAmount,
            synthrToBurn
        );
    }

    // ========== EVENTS ==========
    event WithdrawCollateral(
        address from,
        bytes32 collateralKey,
        address collateralCurrency,
        uint256 collateralAmount,
        uint256 synthrToBurn
    );

    event AtomicSynthExchange(
        address indexed account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    );
    bytes32 internal constant ATOMIC_SYNTH_EXCHANGE_SIG =
        keccak256("AtomicSynthExchange(address,bytes32,uint256,bytes32,uint256,address)");

    function emitAtomicSynthExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    ) external onlyExchanger {
        proxy._emit(
            abi.encode(fromCurrencyKey, fromAmount, toCurrencyKey, toAmount, toAddress),
            2,
            ATOMIC_SYNTH_EXCHANGE_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }
}