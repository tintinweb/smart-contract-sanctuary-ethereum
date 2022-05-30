pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";

// Libraries
import "./SafeDecimalMath.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IDerivedPriceFeed.sol";

contract ExchangeRatesV2 is Owned, MixinSystemSettings, IExchangeRates {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    // Exchange rates and update times stored by currency code, e.g. 'DVDX', or 'USDx'
    mapping(bytes32 => mapping(uint256 => RateAndUpdatedTime)) private _rates;

    // The address of the oracle which pushes rate updates to this contract
    address public override oracle;
    address public override dvdxPair;
    address public priceOracle;

    // Decentralized oracle networks that feed into pricing aggregators
    mapping(bytes32 => address) new_aggregators;

    mapping(bytes32 => uint8) currencyKeyDecimals;

    // List of aggregator keys for convenient iteration
    bytes32[] aggregatorKeys;

    // Do not allow the oracle to submit times any further forward into the future than this constant.
    uint256 private constant ORACLE_FUTURE_LIMIT = 10 minutes;

    mapping(bytes32 => InversePricing) public override inversePricing;

    bytes32[] invertedKeys;

    mapping(bytes32 => uint256) public override currentRoundForRate;

    mapping(bytes32 => uint256) roundFrozen;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";

    //
    // ========== CONSTRUCTOR ==========

    constructor(
        address _owner,
        address _oracle,
        address _resolver,
        address _dvdxPair,
        address _priceOracle,
        bytes32[] memory _currencyKeys,
        uint256[] memory _newRates
    ) Owned(_owner) MixinSystemSettings(_resolver) {
        require(
            _currencyKeys.length == _newRates.length,
            "Currency key length and rate length must match."
        );

        oracle = _oracle;
        dvdxPair = _dvdxPair;
        priceOracle = _priceOracle;

        // The USDx rate is always 1 and is never stale.
        _setRate("USDx", SafeDecimalMath.unit(), block.timestamp);

        internalUpdateRates(_currencyKeys, _newRates, block.timestamp);
    }

    /* ========== SETTERS ========== */

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }

    function setDVDXPair(address _dvdxPair) external onlyOwner {
        dvdxPair = _dvdxPair;
        emit DVDXPairUpdated(dvdxPair);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function updateRates(
        bytes32[] calldata currencyKeys,
        uint256[] calldata newRates,
        uint256 timeSent
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
        uint256 entryPoint,
        uint256 upperLimit,
        uint256 lowerLimit,
        bool freezeAtUpperLimit,
        bool freezeAtLowerLimit
    ) external onlyOwner {
        // 0 < lowerLimit < entryPoint => 0 < entryPoint
        require(lowerLimit > 0, "17");
        require(upperLimit > entryPoint, "18");
        require(upperLimit < entryPoint.mul(2), "19");
        require(lowerLimit < entryPoint, "20");

        require(!(freezeAtUpperLimit && freezeAtLowerLimit), "21");

        InversePricing storage inverse = inversePricing[currencyKey];
        if (inverse.entryPoint == 0) {
            // then we are adding a new inverse pricing, so add this
            invertedKeys.push(currencyKey);
        }
        inverse.entryPoint = entryPoint;
        inverse.upperLimit = upperLimit;
        inverse.lowerLimit = lowerLimit;

        if (freezeAtUpperLimit || freezeAtLowerLimit) {
            // When indicating to freeze, we need to kblock.timestamp the rate to freeze it at - either upper or lower
            // this is useful in situations where ExchangeRates is updated and there are existing inverted
            // rates already frozen in the current contract that need persisting across the upgrade

            inverse.frozenAtUpperLimit = freezeAtUpperLimit;
            inverse.frozenAtLowerLimit = freezeAtLowerLimit;
            // uint256 roundId = _getCurrentRoundId(currencyKey);
            // roundFrozen[currencyKey] = roundId;
            emit InversePriceFrozen(
                currencyKey,
                freezeAtUpperLimit ? upperLimit : lowerLimit,
                // roundId,
                0,
                msg.sender
            );
        } else {
            // unfreeze if need be
            inverse.frozenAtUpperLimit = false;
            inverse.frozenAtLowerLimit = false;
            // remove any tracking
            // roundFrozen[currencyKey] = 0;
        }

        // SIP-78
        uint256 rate = _getRate(currencyKey);
        if (rate > 0) {
            exchanger().setLastExchangeRateForSynth(currencyKey, rate);
        }

        emit InversePriceConfigured(
            currencyKey,
            entryPoint,
            upperLimit,
            lowerLimit
        );
    }

    function removeInversePricing(bytes32 currencyKey) external onlyOwner {
        require(inversePricing[currencyKey].entryPoint > 0, "22");

        delete inversePricing[currencyKey];

        // block.timestamp remove inverted key from array
        bool wasRemoved = removeFromArray(currencyKey, invertedKeys);

        if (wasRemoved) {
            emit InversePriceConfigured(currencyKey, 0, 0, 0);
        }
    }

    // SIP-75 Public keeper function to freeze a synth that is out of bounds
    function freezeRate(bytes32 currencyKey) external override {
        InversePricing storage inverse = inversePricing[currencyKey];
        require(inverse.entryPoint > 0, "Cannot freeze non-inverse rate");
        require(
            !inverse.frozenAtUpperLimit && !inverse.frozenAtLowerLimit,
            "The rate is already frozen"
        );

        uint256 rate = _getRate(currencyKey);

        if (
            rate > 0 &&
            (rate >= inverse.upperLimit || rate <= inverse.lowerLimit)
        ) {
            inverse.frozenAtUpperLimit = (rate == inverse.upperLimit);
            inverse.frozenAtLowerLimit = (rate == inverse.lowerLimit);
            // uint256 currentRoundId = _getCurrentRoundId(currencyKey);
            // roundFrozen[currencyKey] = currentRoundId;
            emit InversePriceFrozen(
                currencyKey,
                rate,
                0,
                // currentRoundId,
                msg.sender
            );
        } else {
            revert("Rate within bounds");
        }
    }

    /* ========== VIEWS ========== */

    function resolverAddressesRequired()
        public
        view
        override
        returns (bytes32[] memory addresses)
    {
        bytes32[] memory existingAddresses = MixinSystemSettings
            .resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_EXCHANGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    // SIP-75 View to determine if freezeRate can be called safely
    function canFreezeRate(bytes32 currencyKey)
        external
        view
        override
        returns (bool)
    {
        InversePricing memory inverse = inversePricing[currencyKey];
        if (
            inverse.entryPoint == 0 ||
            inverse.frozenAtUpperLimit ||
            inverse.frozenAtLowerLimit
        ) {
            return false;
        } else {
            uint256 rate = _getRate(currencyKey);
            return (rate > 0 &&
                (rate >= inverse.upperLimit || rate <= inverse.lowerLimit));
        }
    }

    function currenciesUsingAggregator(address aggregator)
        external
        view
        override
        returns (bytes32[] memory currencies)
    {
        uint256 count = 0;
        currencies = new bytes32[](aggregatorKeys.length);
        for (uint256 i = 0; i < aggregatorKeys.length; i++) {
            bytes32 currencyKey = aggregatorKeys[i];
            if (address(new_aggregators[currencyKey]) == aggregator) {
                currencies[count++] = currencyKey;
            }
        }
    }

    function rateStalePeriod() external view override returns (uint256) {
        return getRateStalePeriod();
    }

    function aggregatorWarningFlags() external view override returns (address) {
        return getAggregatorWarningFlags();
    }

    function rateAndUpdatedTime(bytes32 currencyKey)
        external
        view
        override
        returns (uint256 rate, uint256 time)
    {
        RateAndUpdatedTime memory rateAndTime = _getRateAndUpdatedTime(
            currencyKey
        );
        return (rateAndTime.rate, rateAndTime.time);
    }

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint256 startingRoundId,
        uint256 startingTimestamp,
        uint256 timediff
    ) external view override returns (uint256) {
        uint256 roundId = startingRoundId;
        uint256 nextTimestamp = 0;
        while (true) {
            (, nextTimestamp) = _getRateAndTimestampAtRound(
                currencyKey,
                roundId + 1
            );
            // if there's no new round, then the previous roundId was the latest
            if (
                nextTimestamp == 0 ||
                nextTimestamp > startingTimestamp + timediff
            ) {
                return roundId;
            }
            roundId++;
        }
        return roundId;
    }

    function getCurrentRoundId(bytes32 currencyKey)
        external
        view
        override
        returns (uint256)
    {
        return 0;
        // return _getCurrentRoundId(currencyKey);
    }

    function effectiveValueAtRound(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) external view override returns (uint256 value) {
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) return sourceAmount;

        (uint256 srcRate, ) = _getRateAndTimestampAtRound(
            sourceCurrencyKey,
            roundIdForSrc
        );
        (uint256 destRate, ) = _getRateAndTimestampAtRound(
            destinationCurrencyKey,
            roundIdForDest
        );
        if (destRate == 0) {
            // prevent divide-by 0 error (this can happen when roundIDs jump epochs due
            // to aggregator upgrades)
            return 0;
        }
        // Calculate the effective value by going from source -> USD -> destination
        value = sourceAmount.multiplyDecimalRound(srcRate).divideDecimalRound(
            destRate
        );
    }

    function rateAndTimestampAtRound(bytes32 currencyKey, uint256 roundId)
        external
        view
        override
        returns (uint256 rate, uint256 time)
    {
        return _getRateAndTimestampAtRound(currencyKey, roundId);
    }

    function lastRateUpdateTimes(bytes32 currencyKey)
        external
        view
        override
        returns (uint256)
    {
        return _getUpdatedTime(currencyKey);
    }

    function lastRateUpdateTimesForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory lastUpdateTimes = new uint256[](currencyKeys.length);

        for (uint256 i = 0; i < currencyKeys.length; i++) {
            lastUpdateTimes[i] = _getUpdatedTime(currencyKeys[i]);
        }

        return lastUpdateTimes;
    }

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view override returns (uint256 value) {
        (value, , ) = _effectiveValueAndRates(
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey
        );
    }

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        override
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        )
    {
        return
            _effectiveValueAndRates(
                sourceCurrencyKey,
                sourceAmount,
                destinationCurrencyKey
            );
    }

    function rateForCurrency(bytes32 currencyKey)
        external
        view
        override
        returns (uint256)
    {
        return _getRateAndUpdatedTime(currencyKey).rate;
    }

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint256 numRounds
    )
        external
        view
        override
        returns (uint256[] memory rates, uint256[] memory times)
    {
        rates = new uint256[](numRounds);
        times = new uint256[](numRounds);

        uint256 roundId = _getCurrentRoundId(currencyKey);
        for (uint256 i = 0; i < numRounds; i++) {
            // fetch the rate and treat is as current, so inverse limits if frozen will always be applied
            // regardless of current rate
            (rates[i], times[i]) = _getRateAndTimestampAtRound(
                currencyKey,
                roundId
            );

            if (roundId == 0) {
                // if we hit the last round, then return what we have
                return (rates, times);
            } else {
                roundId--;
            }
        }
    }

    function ratesForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _localRates = new uint256[](currencyKeys.length);

        for (uint256 i = 0; i < currencyKeys.length; i++) {
            _localRates[i] = _getRate(currencyKeys[i]);
        }

        return _localRates;
    }

    function rateAndInvalid(bytes32 currencyKey)
        external
        view
        override
        returns (uint256 rate, bool isInvalid)
    {
        return (IDerivedPriceFeed(priceOracle).getPrice(currencyKey), false);
    }

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        override
        returns (uint256[] memory rates, bool anyRateInvalid)
    {
        rates = new uint256[](currencyKeys.length);

        uint256 _rateStalePeriod = getRateStalePeriod();

        // fetch all flags at once
        bool[] memory flagList = getFlagsForRates(currencyKeys);

        for (uint256 i = 0; i < currencyKeys.length; i++) {
            // do one lookup of the rate & time to minimize gas
            RateAndUpdatedTime memory rateEntry = _getRateAndUpdatedTime(
                currencyKeys[i]
            );
            rates[i] = rateEntry.rate;
            if (!anyRateInvalid && currencyKeys[i] != "USDx") {
                anyRateInvalid = flagList[1];
            }
        }
    }

    function rateIsStale(bytes32 currencyKey)
        external
        view
        override
        returns (bool)
    {
        return false;
    }

    function rateIsFrozen(bytes32 currencyKey)
        external
        view
        override
        returns (bool)
    {
        return false;
    }

    function rateIsInvalid(bytes32 currencyKey)
        external
        view
        override
        returns (bool)
    {
        return false;
    }

    function rateIsFlagged(bytes32 currencyKey)
        external
        view
        override
        returns (bool)
    {
        return false;
    }

    function anyRateIsInvalid(bytes32[] calldata currencyKeys)
        external
        view
        override
        returns (bool)
    {
        // Loop through each key and check whether the data point is stale.

        uint256 _rateStalePeriod = getRateStalePeriod();
        bool[] memory flagList = getFlagsForRates(currencyKeys);

        for (uint256 i = 0; i < currencyKeys.length; i++) {
            if (
                flagList[i]
                // flagList[i] || _rateIsStale(currencyKeys[i], _rateStalePeriod)
            ) {
                return true;
            }
        }

        return false;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function exchanger() internal view virtual returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function getFlagsForRates(bytes32[] memory currencyKeys)
        internal
        view
        virtual
        returns (bool[] memory flagList)
    {
        flagList = new bool[](currencyKeys.length);
    }

    function _setRate(
        bytes32 currencyKey,
        uint256 rate,
        uint256 time
    ) internal virtual {
        // Note: this will effectively start the rounds at 1, which matches Chainlink's Agggregators
        currentRoundForRate[currencyKey]++;

        _rates[currencyKey][
            currentRoundForRate[currencyKey]
        ] = RateAndUpdatedTime({rate: uint216(rate), time: uint40(time)});
    }

    function internalUpdateRates(
        bytes32[] memory currencyKeys,
        uint256[] memory newRates,
        uint256 timeSent
    ) internal virtual returns (bool) {
        require(
            currencyKeys.length == newRates.length,
            "Currency key array length must match rates array length."
        );
        require(
            timeSent < (block.timestamp + ORACLE_FUTURE_LIMIT),
            "Time is too far into the future"
        );

        // Loop through each key and perform update.
        for (uint256 i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];

            // Should not set any rate to zero ever, as no asset will ever be
            // truely worthless and still valid. In this scenario, we should
            // delete the rate and remove it from the system.
            require(newRates[i] != 0, "25");
            require(currencyKey != "USDx", "26");

            // We should only update the rate if it's at least the same age as the last rate we've got.
            if (timeSent < _getUpdatedTime(currencyKey)) {
                continue;
            }

            // Ok, go ahead with the update.
            _setRate(currencyKey, newRates[i], timeSent);
        }

        emit RatesUpdated(currencyKeys, newRates);

        return true;
    }

    function removeFromArray(bytes32 entry, bytes32[] storage array)
        internal
        virtual
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
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

    function _rateOrInverted(
        bytes32 currencyKey,
        uint256 rate,
        uint256 roundId
    ) internal view virtual returns (uint256 newRate) {
        // if an inverse mapping exists, adjust the price accordingly
        InversePricing memory inverse = inversePricing[currencyKey];
        if (inverse.entryPoint == 0 || rate == 0) {
            // when no inverse is set or when given a 0 rate, return the rate, regardless of the inverse status
            // (the latter is so when a new inverse is set but the underlying has no rate, it will return 0 as
            // the rate, not the lowerLimit)
            return rate;
        }

        newRate = rate;

        // Determine when round was frozen (if any)
        uint256 roundWhenRateFrozen = roundFrozen[currencyKey];
        // And if we're looking at a rate after frozen, and it's currently frozen, then apply the bounds limit even
        // if the current price is back within bounds
        if (roundId >= roundWhenRateFrozen && inverse.frozenAtUpperLimit) {
            newRate = inverse.upperLimit;
        } else if (
            roundId >= roundWhenRateFrozen && inverse.frozenAtLowerLimit
        ) {
            newRate = inverse.lowerLimit;
        } else {
            // this ensures any rate outside the limit will never be returned
            uint256 doubleEntryPoint = inverse.entryPoint.mul(2);
            if (doubleEntryPoint <= rate) {
                // avoid negative numbers for unsigned ints, so set this to 0
                // which by the requirement that lowerLimit be > 0 will
                // cause this to freeze the price to the lowerLimit
                newRate = 0;
            } else {
                newRate = doubleEntryPoint.sub(rate);
            }

            // block.timestamp ensure the rate is between the bounds
            if (newRate >= inverse.upperLimit) {
                newRate = inverse.upperLimit;
            } else if (newRate <= inverse.lowerLimit) {
                newRate = inverse.lowerLimit;
            }
        }
    }

    function _formatAggregatorAnswer(bytes32 currencyKey, int256 rate)
        internal
        view
        virtual
        returns (uint256)
    {
        require(rate >= 0, "24");
        if (currencyKeyDecimals[currencyKey] > 0) {
            uint256 multiplier = 10 **
                uint256(SafeMath.sub(18, currencyKeyDecimals[currencyKey]));
            return uint256(uint256(rate).mul(multiplier));
        }
        return uint256(rate);
    }

    function _getRateAndUpdatedTime(bytes32 currencyKey)
        internal
        view
        virtual
        returns (RateAndUpdatedTime memory)
    {
        return
            RateAndUpdatedTime({
                rate: uint216(
                    IDerivedPriceFeed(priceOracle).getPrice(currencyKey)
                ),
                time: uint40(block.timestamp)
            });
    }

    function _getCurrentRoundId(bytes32 currencyKey)
        internal
        view
        virtual
        returns (uint256)
    {
        return 0;
    }

    function _getRateAndTimestampAtRound(bytes32 currencyKey, uint256 roundId)
        internal
        view
        virtual
        returns (uint256 rate, uint256 time)
    {
        RateAndUpdatedTime memory rateAndTime = _getRateAndUpdatedTime(
            currencyKey
        );
        return (rateAndTime.rate, rateAndTime.time);
    }

    function _getRate(bytes32 currencyKey)
        internal
        view
        virtual
        returns (uint256)
    {
        return _getRateAndUpdatedTime(currencyKey).rate;
    }

    function _getUpdatedTime(bytes32 currencyKey)
        internal
        view
        virtual
        returns (uint256)
    {
        return _getRateAndUpdatedTime(currencyKey).time;
    }

    function _effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        internal
        view
        virtual
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
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
            // prevent divide-by 0 error (this happens if the dest is not a valid rate)
            if (destinationRate > 0) {
                value = sourceAmount
                    .multiplyDecimalRound(sourceRate)
                    .divideDecimalRound(destinationRate);
            }
        }
    }

    function _rateIsStale(bytes32 currencyKey, uint256 _rateStalePeriod)
        internal
        view
        virtual
        returns (bool)
    {
        return false;
    }

    function _rateIsStaleWithTime(uint256 _rateStalePeriod, uint256 _time)
        internal
        view
        virtual
        returns (bool)
    {
        return false;
    }

    function _rateIsFrozen(bytes32 currencyKey)
        internal
        view
        virtual
        returns (bool)
    {
        return false;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOracle() {
        _onlyOracle();
        _;
    }

    function _onlyOracle() internal view virtual {
        require(msg.sender == oracle, "23");
    }

    /* ========== EVENTS ========== */

    event OracleUpdated(address newOracle);
    event DVDXPairUpdated(address newDVDXPair);
    event RatesUpdated(bytes32[] currencyKeys, uint256[] newRates);
    event RateDeleted(bytes32 currencyKey);
    event InversePriceConfigured(
        bytes32 currencyKey,
        uint256 entryPoint,
        uint256 upperLimit,
        uint256 lowerLimit
    );
    event InversePriceFrozen(
        bytes32 currencyKey,
        uint256 rate,
        uint256 roundId,
        address initiator
    );
    event AggregatorAdded(bytes32 currencyKey, address aggregator);
    event AggregatorRemoved(bytes32 currencyKey, address aggregator);
}

pragma solidity ^0.8.4;

/**
 * @title A contract with an owner.
 * @notice Contract ownership can be transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
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
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";

// Internal references
import "./AddressResolver.sol";
import "./ReadProxy.sol";

// contract that helps in storing the address of all synths
abstract contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
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
    function resolverAddressesRequired()
        public
        view
        virtual
        returns (bytes32[] memory addresses)
    {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(
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
            if (
                resolver.getAddress(name) != addressCache[name] ||
                addressCache[name] == address(0)
            ) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name)
        internal
        view
        returns (address)
    {
        address _foundAddress = addressCache[name];
        require(
            _foundAddress != address(0),
            string(abi.encodePacked("Missing address: ", name))
        );
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}

pragma solidity ^0.8.4;

import "./MixinResolver.sol";

// Internal references
import "./interfaces/IFlexibleStorage.sol";

abstract contract MixinSystemSettings is MixinResolver {
    // must match the one defined SystemSettingsLib, defined in both places due to sol v0.5 limitations
    bytes32 internal constant SETTING_CONTRACT_NAME = "SystemSettings";

    bytes32 internal constant SETTING_WAITING_PERIOD_SECS = "waitingPeriodSecs";
    bytes32 internal constant SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR = "priceDeviationThresholdFactor";
    bytes32 internal constant SETTING_ISSUANCE_RATIO = "issuanceRatio";
    bytes32 internal constant SETTING_FEE_PERIOD_DURATION = "feePeriodDuration";
    bytes32 internal constant SETTING_TARGET_THRESHOLD = "targetThreshold";
    bytes32 internal constant SETTING_LIQUIDATION_DELAY = "liquidationDelay";
    bytes32 internal constant SETTING_LIQUIDATION_RATIO = "liquidationRatio";
    bytes32 internal constant SETTING_LIQUIDATION_PENALTY = "liquidationPenalty";
    bytes32 internal constant SETTING_RATE_STALE_PERIOD = "rateStalePeriod";
    /* ========== Exchange Fees Related ========== */
    bytes32 internal constant SETTING_EXCHANGE_FEE_RATE = "exchangeFeeRate";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD = "exchangeDynamicFeeThreshold";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY = "exchangeDynamicFeeWeightDecay";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS = "exchangeDynamicFeeRounds";
    bytes32 internal constant SETTING_EXCHANGE_MAX_DYNAMIC_FEE = "exchangeMaxDynamicFee";
    /* ========== End Exchange Fees Related ========== */
    bytes32 internal constant SETTING_MINIMUM_STAKE_TIME = "minimumStakeTime";
    bytes32 internal constant SETTING_AGGREGATOR_WARNING_FLAGS = "aggregatorWarningFlags";
    bytes32 internal constant SETTING_TRADING_REWARDS_ENABLED = "tradingRewardsEnabled";
    bytes32 internal constant SETTING_DEBT_SNAPSHOT_STALE_TIME = "debtSnapshotStaleTime";
    bytes32 internal constant SETTING_CROSS_DOMAIN_DEPOSIT_GAS_LIMIT = "crossDomainDepositGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_ESCROW_GAS_LIMIT = "crossDomainEscrowGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_REWARD_GAS_LIMIT = "crossDomainRewardGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_WITHDRAWAL_GAS_LIMIT = "crossDomainWithdrawalGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_RELAY_GAS_LIMIT = "crossDomainRelayGasLimit";
    bytes32 internal constant SETTING_ETHER_WRAPPER_MAX_ETH = "etherWrapperMaxETH";
    bytes32 internal constant SETTING_ETHER_WRAPPER_MINT_FEE_RATE = "etherWrapperMintFeeRate";
    bytes32 internal constant SETTING_ETHER_WRAPPER_BURN_FEE_RATE = "etherWrapperBurnFeeRate";
    bytes32 internal constant SETTING_WRAPPER_MAX_TOKEN_AMOUNT = "wrapperMaxTokens";
    bytes32 internal constant SETTING_WRAPPER_MINT_FEE_RATE = "wrapperMintFeeRate";
    bytes32 internal constant SETTING_WRAPPER_BURN_FEE_RATE = "wrapperBurnFeeRate";
    bytes32 internal constant SETTING_INTERACTION_DELAY = "interactionDelay";
    bytes32 internal constant SETTING_COLLAPSE_FEE_RATE = "collapseFeeRate";
    bytes32 internal constant SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK = "atomicMaxVolumePerBlock";
    bytes32 internal constant SETTING_ATOMIC_TWAP_WINDOW = "atomicTwapWindow";
    bytes32 internal constant SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING = "atomicEquivalentForDexPricing";
    bytes32 internal constant SETTING_ATOMIC_EXCHANGE_FEE_RATE = "atomicExchangeFeeRate";
    bytes32 internal constant SETTING_ATOMIC_PRICE_BUFFER = "atomicPriceBuffer";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = "atomicVolConsiderationWindow";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD = "atomicVolUpdateThreshold";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    enum CrossDomainMessageGasLimits {Deposit, Escrow, Reward, Withdrawal, Relay}

    struct DynamicFeeConfig {
        uint threshold;
        uint weightDecay;
        uint rounds;
        uint maxFee;
    }

    constructor(address _resolver) MixinResolver(_resolver) {}

    function resolverAddressesRequired() public virtual override view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    function _getGasLimitSetting(CrossDomainMessageGasLimits gasLimitType) internal pure returns (bytes32) {
        if (gasLimitType == CrossDomainMessageGasLimits.Deposit) {
            return SETTING_CROSS_DOMAIN_DEPOSIT_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Escrow) {
            return SETTING_CROSS_DOMAIN_ESCROW_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Reward) {
            return SETTING_CROSS_DOMAIN_REWARD_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Withdrawal) {
            return SETTING_CROSS_DOMAIN_WITHDRAWAL_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Relay) {
            return SETTING_CROSS_DOMAIN_RELAY_GAS_LIMIT;
        } else {
            revert("Unknown gas limit type");
        }
    }

    function getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits gasLimitType) internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, _getGasLimitSetting(gasLimitType));
    }

    function getTradingRewardsEnabled() internal view returns (bool) {
        return flexibleStorage().getBoolValue(SETTING_CONTRACT_NAME, SETTING_TRADING_REWARDS_ENABLED);
    }

    function getWaitingPeriodSecs() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_WAITING_PERIOD_SECS);
    }

    function getPriceDeviationThresholdFactor() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR);
    }

    function getIssuanceRatio() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ISSUANCE_RATIO);
    }

    function getFeePeriodDuration() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_FEE_PERIOD_DURATION);
    }

    function getTargetThreshold() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_TARGET_THRESHOLD);
    }

    function getLiquidationDelay() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_DELAY);
    }

    function getLiquidationRatio() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_RATIO);
    }

    function getLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_PENALTY);
    }

    function getRateStalePeriod() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_RATE_STALE_PERIOD);
    }

    /* ========== Exchange Related Fees ========== */
    function getExchangeFeeRate(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    /// @notice Get exchange dynamic fee related keys
    /// @return threshold, weight decay, rounds, and max fee
    function getExchangeDynamicFeeConfig() internal view returns (DynamicFeeConfig memory) {
        bytes32[] memory keys = new bytes32[](4);
        keys[0] = SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD;
        keys[1] = SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY;
        keys[2] = SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS;
        keys[3] = SETTING_EXCHANGE_MAX_DYNAMIC_FEE;
        uint[] memory values = flexibleStorage().getUIntValues(SETTING_CONTRACT_NAME, keys);
        return DynamicFeeConfig({threshold: values[0], weightDecay: values[1], rounds: values[2], maxFee: values[3]});
    }

    /* ========== End Exchange Related Fees ========== */

    function getMinimumStakeTime() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MINIMUM_STAKE_TIME);
    }

    function getAggregatorWarningFlags() internal view returns (address) {
        return flexibleStorage().getAddressValue(SETTING_CONTRACT_NAME, SETTING_AGGREGATOR_WARNING_FLAGS);
    }

    function getDebtSnapshotStaleTime() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_DEBT_SNAPSHOT_STALE_TIME);
    }

    function getEtherWrapperMaxETH() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_MAX_ETH);
    }

    function getEtherWrapperMintFeeRate() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_MINT_FEE_RATE);
    }

    function getEtherWrapperBurnFeeRate() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_BURN_FEE_RATE);
    }

    function getWrapperMaxTokenAmount(address wrapper) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_MAX_TOKEN_AMOUNT, wrapper))
            );
    }

    function getWrapperMintFeeRate(address wrapper) internal view returns (int) {
        return
            flexibleStorage().getIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_MINT_FEE_RATE, wrapper))
            );
    }

    function getWrapperBurnFeeRate(address wrapper) internal view returns (int) {
        return
            flexibleStorage().getIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_BURN_FEE_RATE, wrapper))
            );
    }

    function getInteractionDelay(address collateral) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_INTERACTION_DELAY, collateral))
            );
    }

    function getCollapseFeeRate(address collateral) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_COLLAPSE_FEE_RATE, collateral))
            );
    }

    function getAtomicMaxVolumePerBlock() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK);
    }

    function getAtomicTwapWindow() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_TWAP_WINDOW);
    }

    function getAtomicEquivalentForDexPricing(bytes32 currencyKey) internal view returns (address) {
        return
            flexibleStorage().getAddressValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING, currencyKey))
            );
    }

    function getAtomicExchangeFeeRate(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    function getAtomicPriceBuffer(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_PRICE_BUFFER, currencyKey))
            );
    }

    function getAtomicVolatilityConsiderationWindow(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW, currencyKey))
            );
    }

    function getAtomicVolatilityUpdateThreshold(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD, currencyKey))
            );
    }
}

pragma solidity ^0.8.4;

interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    struct InversePricing {
        uint256 entryPoint;
        uint256 upperLimit;
        uint256 lowerLimit;
        bool frozenAtUpperLimit;
        bool frozenAtLowerLimit;
    }

    // Views
    //function aggregators(bytes32 currencyKey) external virtual view returns (address);

    function aggregatorWarningFlags() external view virtual returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys)
        external
        view
        virtual
        returns (bool);

    function canFreezeRate(bytes32 currencyKey)
        external
        view
        virtual
        returns (bool);

    function currentRoundForRate(bytes32 currencyKey)
        external
        view
        virtual
        returns (uint256);

    function currenciesUsingAggregator(address aggregator)
        external
        view
        virtual
        returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view virtual returns (uint256 value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        virtual
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        );

    function effectiveValueAtRound(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) external view virtual returns (uint256 value);

    function getCurrentRoundId(bytes32 currencyKey)
        external
        view
        virtual
        returns (uint256);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint256 startingRoundId,
        uint256 startingTimestamp,
        uint256 timediff
    ) external view virtual returns (uint256);

    function inversePricing(bytes32 currencyKey)
        external
        view
        virtual
        returns (
            uint256 entryPoint,
            uint256 upperLimit,
            uint256 lowerLimit,
            bool frozenAtUpperLimit,
            bool frozenAtLowerLimit
        );

    function lastRateUpdateTimes(bytes32 currencyKey)
        external
        view
        virtual
        returns (uint256);

    function oracle() external view virtual returns (address);

    function dvdxPair() external view virtual returns (address);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint256 roundId)
        external
        view
        virtual
        returns (uint256 rate, uint256 time);

    function rateAndUpdatedTime(bytes32 currencyKey)
        external
        view
        virtual
        returns (uint256 rate, uint256 time);

    function rateAndInvalid(bytes32 currencyKey)
        external
        view
        virtual
        returns (uint256 rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey)
        external
        view
        virtual
        returns (uint256);

    function rateIsFlagged(bytes32 currencyKey)
        external
        view
        virtual
        returns (bool);

    function rateIsFrozen(bytes32 currencyKey)
        external
        view
        virtual
        returns (bool);

    function rateIsInvalid(bytes32 currencyKey)
        external
        view
        virtual
        returns (bool);

    function rateIsStale(bytes32 currencyKey)
        external
        view
        virtual
        returns (bool);

    function rateStalePeriod() external view virtual returns (uint256);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint256 numRounds
    )
        external
        view
        virtual
        returns (uint256[] memory rates, uint256[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        virtual
        returns (uint256[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        virtual
        returns (uint256[] memory);

    // Mutative functions
    function freezeRate(bytes32 currencyKey) external virtual;
}

pragma solidity ^0.8.4;

interface IUniswapV2Pair {
    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

pragma solidity ^0.8.4;

interface IERC20 {
    // ERC20 Optional Views
    function name() external view virtual returns (string memory);

    function symbol() external view virtual returns (string memory);

    function decimals() external view virtual returns (uint8);

    // Views
    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        virtual
        returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value)
        external
        virtual
        returns (bool);

    function approve(address spender, uint256 value)
        external
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual returns (bool);

    // Events
    //event Transfer(address indexed from, address indexed to, uint value);

    //event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity ^0.8.4;

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// contract that provides the ability to manipulate fractional numbers, performing safe arithmetic with unsigned fixed-point decimals.
library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

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
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function multiplyDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function divideDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function divideDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        uint256 quotientTimesTen =
            i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }
}

pragma solidity >=0.4.24;

import "./IVirtualSynth.sol";

// https://docs.derived.fi/contracts/source/interfaces/iexchanger
interface IExchanger {
    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint amount,
        uint refunded
    ) external view returns (uint amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        );

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint exchangeFeeRate);

    function getAmountsForExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        );

    function priceDeviationThresholdFactor() external view returns (uint);

    function waitingPeriodSecs() external view returns (uint);

    // Mutative functions
    function exchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external virtual returns (uint amountReceived);

    function exchangeWithTracking(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        address originator,
        bytes32 trackingCode
    ) external virtual returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external virtual returns (uint amountReceived);

    //function exchangeWithVirtual(
    //    address from,
    //    bytes32 sourceCurrencyKey,
    //    uint sourceAmount,
    //    bytes32 destinationCurrencyKey,
    //    address destinationAddress,
    //    bytes32 trackingCode
    //) external virtual returns (uint amountReceived, IVirtualSynth vSynth);

    function settle(address from, bytes32 currencyKey)
        external virtual 
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    function setLastExchangeRateForSynth(bytes32 currencyKey, uint rate) external;

    //function suspendSynthWithInvalidRate(bytes32 currencyKey) external virtual;
}

pragma solidity ^0.8.4;

interface IDerivedPriceFeed {
    function getPrice(bytes32) external view returns (uint256);
}

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";

// Address resolver contract
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external onlyOwner {
        require(
            names.length == destinations.length,
            "Input lengths must match"
        );

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

    function areAddressesImported(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view override returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        override
        returns (address)
    {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view override returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}

pragma solidity ^0.8.4;

import "./Owned.sol";

// Contract to read the proxy contracts
contract ReadProxy is Owned {
    address public target;

    constructor(address _owner) public Owned(_owner) {}

    function setTarget(address _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(target);
    }

    fallback() external {
        // The basics of a proxy read call
        // Note that msg.sender in the underlying will always be the address of this contract.
        assembly {
            calldatacopy(0, 0, calldatasize())

            // Use of staticcall - this will revert if the underlying function mutates state
            let result := staticcall(
                gas(),
                sload(target.slot),
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            if iszero(result) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    event TargetUpdated(address newTarget);
}

pragma solidity ^0.8.4;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address);
}

pragma solidity ^0.8.4;

import "../interfaces/ISynth.sol";

interface IIssuer {
    // Views
    function anySynthOrDVDXRateIsInvalid()
        external
        view
        returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function availableSynths(uint256 index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer)
        external
        view
        returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey)
        external
        view
        returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer)
        external
        view
        returns (uint256 maxIssuable);

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

    function getSynths(bytes32[] calldata currencyKeys)
        external
        view
        returns (ISynth[] memory);

    function synthsByAddress(address synthAddress)
        external
        view
        returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey, bool excludeEtherCollateral)
        external
        view
        returns (uint256);

    function transferableDerivedAndAnyRateIsInvalid(
        address account,
        uint256 balance
    ) external view returns (uint256 transferable, bool anyRateIsInvalid);

    // Restricted: used internally to Derived
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

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from)
        external;

    function liquidateDelinquentAccount(
        address account,
        uint256 USDxAmount,
        address liquidator
    ) external returns (uint256 totalRedeemed, uint256 amountToLiquidate);
}

pragma solidity ^0.8.4;

interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account)
        external
        view
        returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value)
        external
        returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Restricted: used internally to Derived
    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

pragma solidity ^0.8.4;

interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record)
        external
        view
        returns (uint256);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records)
        external
        view
        returns (uint256[] memory);

    function getIntValue(bytes32 contractName, bytes32 record)
        external
        view
        returns (int256);

    function getIntValues(bytes32 contractName, bytes32[] calldata records)
        external
        view
        returns (int256[] memory);

    function getAddressValue(bytes32 contractName, bytes32 record)
        external
        view
        returns (address);

    function getAddressValues(bytes32 contractName, bytes32[] calldata records)
        external
        view
        returns (address[] memory);

    function getBoolValue(bytes32 contractName, bytes32 record)
        external
        view
        returns (bool);

    function getBoolValues(bytes32 contractName, bytes32[] calldata records)
        external
        view
        returns (bool[] memory);

    function getBytes32Value(bytes32 contractName, bytes32 record)
        external
        view
        returns (bytes32);

    function getBytes32Values(bytes32 contractName, bytes32[] calldata records)
        external
        view
        returns (bytes32[] memory);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.4;

import "./ISynth.sol";

interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account)
        external
        view
        returns (uint256);

    function rate() external view returns (uint256);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint256);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}