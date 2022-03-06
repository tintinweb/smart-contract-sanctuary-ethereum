// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol";
import "./SelfDestructible.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
// AggregatorInterface from Chainlink represents a decentralized pricing network for a single currency key
interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

contract ExchangeRates is OwnedwManager, SelfDestructible {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Exchange rates and update times stored by currency code, e.g. 'OKS', or 'USD'
    mapping(bytes32 => mapping(uint => RateAndUpdatedTime)) private _rates;

    // The address of the oracle which pushes rate updates to this contract
    address public oracle;

    // Decentralized oracle networks that feed into pricing aggregators
    mapping(bytes32 => AggregatorInterface) public aggregators;

    // List of aggregator keys for convenient iteration
    bytes32[] public aggregatorKeys;

    // Do not allow the oracle to submit times any further forward into the future than this constant.
    uint private constant ORACLE_FUTURE_LIMIT = 10 minutes;

    // How long will the contract assume the rate of any asset is correct
    uint public rateStalePeriod = 3 hours;

    // For inverted prices, keep a mapping of their entry, limits and frozen status
    struct InversePricing {
        uint entryPoint;
        uint upperLimit;
        uint lowerLimit;
        bool frozen;
    }
    mapping(bytes32 => InversePricing) public inversePricing;
    bytes32[] public invertedKeys;

    mapping(bytes32 => uint) public currentRoundForRate;

    //
    // ========== CONSTRUCTOR ==========

    constructor(
        address _owner,
        address _oracle,
        bytes32[] memory _currencyKeys,
        uint[] memory _newRates
    ) OwnedwManager(_owner, _owner) SelfDestructible() {
        require(_currencyKeys.length == _newRates.length, "Currency key length and rate length must match.");

        oracle = _oracle;
 
        internalUpdateRates(_currencyKeys, _newRates, block.timestamp);
    }

    /* ========== SETTERS ========== */

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }

    function setRateStalePeriod(uint _time) external onlyOwner {
        rateStalePeriod = _time;
        emit RateStalePeriodUpdated(rateStalePeriod);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function updateRates(
        bytes32[] calldata currencyKeys,
        uint[] calldata newRates,
        uint timeSent
    ) external onlyOracle returns (bool) {
        return internalUpdateRates(currencyKeys, newRates, timeSent);
    }

    function deleteRate(bytes32 currencyKey) external onlyOracle {
        require(_getRate(currencyKey) > 0, "Rate is zero");

        delete _rates[currencyKey][currentRoundForRate[currencyKey]];

        currentRoundForRate[currencyKey]--;

        emit RateDeleted(currencyKey);
    }

    function setInversePricing(
        bytes32 currencyKey,
        uint entryPoint,
        uint upperLimit,
        uint lowerLimit,
        bool freeze,
        bool freezeAtUpperLimit
    ) external onlyOwner {
        // 0 < lowerLimit < entryPoint => 0 < entryPoint
        require(lowerLimit > 0, "lowerLimit must be above 0");
        require(upperLimit > entryPoint, "upperLimit must be above the entryPoint");
        require(upperLimit < entryPoint.mul(2), "upperLimit must be less than double entryPoint");
        require(lowerLimit < entryPoint, "lowerLimit must be below the entryPoint");

        if (inversePricing[currencyKey].entryPoint <= 0) {
            // then we are adding a new inverse pricing, so add this
            invertedKeys.push(currencyKey);
        }
        inversePricing[currencyKey].entryPoint = entryPoint;
        inversePricing[currencyKey].upperLimit = upperLimit;
        inversePricing[currencyKey].lowerLimit = lowerLimit;
        inversePricing[currencyKey].frozen = freeze;

        emit InversePriceConfigured(currencyKey, entryPoint, upperLimit, lowerLimit);

        // When indicating to freeze, we need to know the rate to freeze it at - either upper or lower
        // this is useful in situations where ExchangeRates is updated and there are existing inverted
        // rates already frozen in the current contract that need persisting across the upgrade
        if (freeze) {
            emit InversePriceFrozen(currencyKey);

            _setRate(currencyKey, freezeAtUpperLimit ? upperLimit : lowerLimit, block.timestamp);
        }
    }

    function removeInversePricing(bytes32 currencyKey) external onlyOwner {
        require(inversePricing[currencyKey].entryPoint > 0, "No inverted price exists");

        inversePricing[currencyKey].entryPoint = 0;
        inversePricing[currencyKey].upperLimit = 0;
        inversePricing[currencyKey].lowerLimit = 0;
        inversePricing[currencyKey].frozen = false;

        // block.timestamp remove inverted key from array
        bool wasRemoved = removeFromArray(currencyKey, invertedKeys);

        if (wasRemoved) {
            emit InversePriceConfigured(currencyKey, 0, 0, 0);
        }
    }

    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external onlyOwner {
        AggregatorInterface aggregator = AggregatorInterface(aggregatorAddress);
        // This check tries to make sure that a valid aggregator is being added.
        // It checks if the aggregator is an existing smart contract that has implemented `latestTimestamp` function.
        require(aggregator.latestTimestamp() >= 0, "Given Aggregator is invalid");
        if (address(aggregators[currencyKey]) == address(0)) {
            aggregatorKeys.push(currencyKey);
        }
        aggregators[currencyKey] = aggregator;
        emit AggregatorAdded(currencyKey, address(aggregator));
    }

    function removeAggregator(bytes32 currencyKey) external onlyOwner {
        address aggregator = address(aggregators[currencyKey]);
        require(aggregator != address(0), "No aggregator exists for key");
        delete aggregators[currencyKey];

        bool wasRemoved = removeFromArray(currencyKey, aggregatorKeys);

        if (wasRemoved) {
            emit AggregatorRemoved(currencyKey, aggregator);
        }
    }

    /* ========== VIEWS ========== */

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time) {
        RateAndUpdatedTime memory rateAndTime = _getRateAndUpdatedTime(currencyKey);
        return (rateAndTime.rate, rateAndTime.time);
    }

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint) {
        uint roundId = startingRoundId;
        uint nextTimestamp = 0;
        while (true) {
            (, nextTimestamp) = _getRateAndTimestampAtRound(currencyKey, roundId + 1);
            // if there's no new round, then the previous roundId was the latest
            if (nextTimestamp == 0 || nextTimestamp > startingTimestamp + timediff) {
                return roundId;
            }
            roundId++;
        }
        return roundId;
    }

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint) {
        return _getCurrentRoundId(currencyKey);
    }

    function effectiveValueAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    ) external view returns (uint value) {
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) return sourceAmount;

        (uint srcRate, ) = _getRateAndTimestampAtRound(sourceCurrencyKey, roundIdForSrc);
        (uint destRate, ) = _getRateAndTimestampAtRound(destinationCurrencyKey, roundIdForDest);
        // Calculate the effective value by going from source -> USD -> destination
        value = sourceAmount.multiplyDecimalRound(srcRate).divideDecimalRound(destRate);
    }

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time) {
        return _getRateAndTimestampAtRound(currencyKey, roundId);
    }

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256) {
        return _getUpdatedTime(currencyKey);
    }

    function lastRateUpdateTimesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory) {
        uint[] memory lastUpdateTimes = new uint[](currencyKeys.length);

        for (uint i = 0; i < currencyKeys.length; i++) {
            lastUpdateTimes[i] = _getUpdatedTime(currencyKeys[i]);
        }

        return lastUpdateTimes;
    }

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value) {
        (value, , ) = _effectiveValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        )
    {
        return _effectiveValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

    function rateForCurrency(bytes32 currencyKey) external view returns (uint) {
        return _getRateAndUpdatedTime(currencyKey).rate;
    }

    function ratesAndUpdatedTimeForCurrencyLastNRounds(bytes32 currencyKey, uint numRounds)
        external
        view
        returns (uint[] memory rates, uint[] memory times)
    {
        rates = new uint[](numRounds);
        times = new uint[](numRounds);

        uint roundId = _getCurrentRoundId(currencyKey);
        for (uint i = 0; i < numRounds; i++) {
            (rates[i], times[i]) = _getRateAndTimestampAtRound(currencyKey, roundId);
            if (roundId == 0) {
                // if we hit the last round, then return what we have
                return (rates, times);
            } else {
                roundId--;
            }
        }
    }

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory) {
        uint[] memory _localRates = new uint[](currencyKeys.length);

        for (uint i = 0; i < currencyKeys.length; i++) {
            _localRates[i] = _getRate(currencyKeys[i]);
        }

        return _localRates;
    }

    function ratesAndStaleForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory, bool) {
        uint[] memory _localRates = new uint[](currencyKeys.length);

        bool anyRateStale = false;
        uint period = rateStalePeriod;
        for (uint i = 0; i < currencyKeys.length; i++) {
            RateAndUpdatedTime memory rateAndUpdateTime = _getRateAndUpdatedTime(currencyKeys[i]);
            _localRates[i] = uint256(rateAndUpdateTime.rate);
            if (!anyRateStale) {
                anyRateStale = (currencyKeys[i] != "USD" && uint256(rateAndUpdateTime.time).add(period) < block.timestamp);
            }
        }

        return (_localRates, anyRateStale);
    }

    function rateIsStale(bytes32 currencyKey) external view returns (bool) {
        // USD is a special case and is never stale.
        if (currencyKey == "USD") return false;

        return _getUpdatedTime(currencyKey).add(rateStalePeriod) < block.timestamp;
    }

    function rateIsFrozen(bytes32 currencyKey) external view returns (bool) {
        return inversePricing[currencyKey].frozen;
    }

    function anyRateIsStale(bytes32[] calldata currencyKeys) external view returns (bool) {
        // Loop through each key and check whether the data point is stale.
        uint256 i = 0;

        while (i < currencyKeys.length) {
            // USD is a special case and is never false
            if (currencyKeys[i] != "USD" && _getUpdatedTime(currencyKeys[i]).add(rateStalePeriod) < block.timestamp) {
                return true;
            }
            i += 1;
        }

        return false;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _setRate(
        bytes32 currencyKey,
        uint256 rate,
        uint256 time
    ) internal {
        // Note: this will effectively start the rounds at 1, which matches Chainlink's Agggregators
        currentRoundForRate[currencyKey]++;

        _rates[currencyKey][currentRoundForRate[currencyKey]] = RateAndUpdatedTime({
            rate: uint216(rate),
            time: uint40(time)
        });
    }

    function internalUpdateRates(
        bytes32[] memory currencyKeys,
        uint[] memory newRates,
        uint timeSent
    ) internal returns (bool) {
        require(currencyKeys.length == newRates.length, "Currency key array length must match rates array length.");
        //require(timeSent < (block.timestamp + ORACLE_FUTURE_LIMIT), "Time is too far into the future");

        // Loop through each key and perform update.
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];

            // Should not set any rate to zero ever, as no asset will ever be
            // truely worthless and still valid. In this scenario, we should
            // delete the rate and remove it from the system.
            require(newRates[i] != 0, "Zero is not a valid rate, please call deleteRate instead.");
            //require(currencyKey != "USD", "Rate of USD cannot be updated, it's always UNIT.");

            // We should only update the rate if it's at least the same age as the last rate we've got.
            if (timeSent < _getUpdatedTime(currencyKey)) {
                continue;
            }

            newRates[i] = rateOrInverted(currencyKey, newRates[i]);

            // Ok, go ahead with the update.
            _setRate(currencyKey, newRates[i], timeSent);
        }

        emit RatesUpdated(currencyKeys, newRates);

        return true;
    }

    function rateOrInverted(bytes32 currencyKey, uint rate) internal returns (uint) {
        // if an inverse mapping exists, adjust the price accordingly
        InversePricing storage inverse = inversePricing[currencyKey];
        if (inverse.entryPoint <= 0) {
            return rate;
        }

        // set the rate to the current rate initially (if it's frozen, this is what will be returned)
        uint newInverseRate = _getRate(currencyKey);

        // get the new inverted rate if not frozen
        if (!inverse.frozen) {
            uint doubleEntryPoint = inverse.entryPoint.mul(2);
            if (doubleEntryPoint <= rate) {
                // avoid negative numbers for unsigned ints, so set this to 0
                // which by the requirement that lowerLimit be > 0 will
                // cause this to freeze the price to the lowerLimit
                newInverseRate = 0;
            } else {
                newInverseRate = doubleEntryPoint.sub(rate);
            }

            // block.timestamp if new rate hits our limits, set it to the limit and freeze
            if (newInverseRate >= inverse.upperLimit) {
                newInverseRate = inverse.upperLimit;
            } else if (newInverseRate <= inverse.lowerLimit) {
                newInverseRate = inverse.lowerLimit;
            }

            if (newInverseRate == inverse.upperLimit || newInverseRate == inverse.lowerLimit) {
                inverse.frozen = true;
                emit InversePriceFrozen(currencyKey);
            }
        }

        return newInverseRate;
    }

    function removeFromArray(bytes32 entry, bytes32[] storage array) internal returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == entry) {
                delete array[i];

                // Copy the last key into the place of the one we just deleted
                // If there's only one key, this is array[0] = array[0].
                // If we're deleting the last one, it's also a NOOP in the same way.
                array[i] = array[array.length - 1];

                // Decrease the size of the array by one.
                array.pop();

                return true;
            }
        }
        return false;
    }

    function _getRateAndUpdatedTime(bytes32 currencyKey) internal view returns (RateAndUpdatedTime memory) {
        if (address(aggregators[currencyKey]) != address(0)) {
            return
                RateAndUpdatedTime({
                    rate: uint216(aggregators[currencyKey].latestAnswer() * 1e10),
                    time: uint40(aggregators[currencyKey].latestTimestamp())
                });
        } else {
            return _rates[currencyKey][currentRoundForRate[currencyKey]];
        }
    }

    function _getCurrentRoundId(bytes32 currencyKey) internal view returns (uint) {
        if (address(aggregators[currencyKey]) != address(0)) {
            AggregatorInterface aggregator = aggregators[currencyKey];
            return aggregator.latestRound();
        } else {
            return currentRoundForRate[currencyKey];
        }
    }

    function _getRateAndTimestampAtRound(bytes32 currencyKey, uint roundId) internal view returns (uint rate, uint time) {
        if (address(aggregators[currencyKey]) != address(0)) {
            AggregatorInterface aggregator = aggregators[currencyKey];
            return (uint(aggregator.getAnswer(roundId) * 1e10), aggregator.getTimestamp(roundId));
        } else {
            RateAndUpdatedTime storage update = _rates[currencyKey][roundId];
            return (update.rate, update.time);
        }
    }

    function _getRate(bytes32 currencyKey) internal view returns (uint256) {
        return _getRateAndUpdatedTime(currencyKey).rate;
    }

    function _getUpdatedTime(bytes32 currencyKey) internal view returns (uint256) {
        return _getRateAndUpdatedTime(currencyKey).time;
    }

    function _effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        internal
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        )
    {
        sourceRate = _getRate(sourceCurrencyKey);
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) {
            destinationRate = sourceRate;
            value = sourceAmount;
        } else {
            // Calculate the effective value by going from source -> USD -> destination
            destinationRate = _getRate(destinationCurrencyKey);
            value = sourceAmount.multiplyDecimalRound(sourceRate).divideDecimalRound(destinationRate);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOracle {
        require(msg.sender == oracle, "Only the oracle can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event OracleUpdated(address newOracle);
    event RateStalePeriodUpdated(uint rateStalePeriod);
    event RatesUpdated(bytes32[] currencyKeys, uint[] newRates);
    event RateDeleted(bytes32 currencyKey);
    event InversePriceConfigured(bytes32 currencyKey, uint entryPoint, uint upperLimit, uint lowerLimit);
    event InversePriceFrozen(bytes32 currencyKey);
    event AggregatorAdded(bytes32 currencyKey, address aggregator);
    event AggregatorRemoved(bytes32 currencyKey, address aggregator);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol";


// https://docs.elysian.cash/contracts/SelfDestructible
abstract contract SelfDestructible is OwnedwManager {
    uint public constant SELFDESTRUCT_DELAY = 4 weeks; 

    uint public initiationTime;
    bool public selfDestructInitiated;

    address public selfDestructBeneficiary;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        selfDestructBeneficiary = owner;
        emit SelfDestructBeneficiaryUpdated(owner);
    }

    /**
     * @notice Set the beneficiary address of this contract.
     * @dev Only the contract owner may call this. The provided beneficiary must be non-null.
     * @param _beneficiary The address to pay any eth contained in this contract to upon self-destruction.
     */
    function setSelfDestructBeneficiary(address payable _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "Beneficiary must not be zero");
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

    /**
     * @notice Begin the self-destruction counter of this contract.
     * Once the delay has elapsed, the contract may be self-destructed.
     * @dev Only the contract owner may call this.
     */
    function initiateSelfDestruct() external onlyOwner {
        initiationTime = block.timestamp;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }  

    /**
     * @notice Terminate and reset the self-destruction timer.
     * @dev Only the contract owner may call this.
     */
    function terminateSelfDestruct() external onlyOwner {
        initiationTime = 0;
        selfDestructInitiated = false;
        emit SelfDestructTerminated();
    }

    /**
     * @notice If the self-destruction delay has elapsed, destroy this contract and
     * remit any ether it owns to the beneficiary address.
     * @dev Only the contract owner may call this.
     */
    function selfDestruct() external onlyOwner {
        require(selfDestructInitiated, "Self Destruct not yet initiated");
        require(initiationTime + SELFDESTRUCT_DELAY < block.timestamp, "Self destruct delay not met");
        emit SelfDestructed(selfDestructBeneficiary);
        selfdestruct(address(uint160(selfDestructBeneficiary)));
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Libraries
// TODO(zx): Replace all instances of SafeMath with OZ implementation
import "./libraries/SafeMath.sol";  
    
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 9;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
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
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
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
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

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
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
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
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
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
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
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
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

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
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
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
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint a, uint b) internal pure returns (uint) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int x) internal pure returns (uint) {
        return uint(signedAbs(x));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract OwnedwManager {
    address public owner;
    address public manager;

    address public nominatedOwner;

    constructor(address _owner, address _manager) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        manager = _manager;
        emit OwnerChanged(address(0), _owner);
        emit ManagerChanged(_manager);
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

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    modifier onlyManager {
        _onlyManager();
        _;
    }
    
    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    function _onlyManager() private view {
        require(msg.sender == manager, "Only the contract owner may perform this action");
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
        emit ManagerChanged(_manager);
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
    event ManagerChanged(address newManager);
}