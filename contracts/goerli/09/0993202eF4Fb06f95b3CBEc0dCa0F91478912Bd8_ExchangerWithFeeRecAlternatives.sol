// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";

// https://docs.synthetix.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) Owned(_owner) {}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Inheritance
import "./Owned.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./interfaces/IExchanger.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IExchangeState.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IExchangeCircuitBreaker.sol";
import "./interfaces/ISynthetix.sol";
import "./interfaces/ISynthetixDebtShare.sol";
import "./interfaces/IIssuedSynthAggregator.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/ITradingRewards.sol";
import "./interfaces/ISynthrBridge.sol";

// import "./Proxyable.sol";

// Used to have strongly-typed access to internal mutative functions in Synthetix
interface ISynthetixInternal {
    function emitExchangeTracking(
        bytes32 trackingCode,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        uint256 fee
    ) external;

    function emitSynthExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    ) external;

    function emitAtomicSynthExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    ) external;

    function emitExchangeReclaim(
        address account,
        bytes32 currencyKey,
        uint256 amount
    ) external;

    function emitExchangeRebate(
        address account,
        bytes32 currencyKey,
        uint256 amount
    ) external;
}

// interface IExchangerInternalDebtCache {
//     function updateCachedSynthDebtsWithRates(bytes32[] calldata currencyKeys, uint256[] calldata currencyRates) external;

//     function updateCachedSynthDebts(bytes32[] calldata currencyKeys) external;
// }

// https://docs.synthetix.io/contracts/source/contracts/exchanger
contract Exchanger is Owned, MixinSystemSettings {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    bytes32 public constant CONTRACT_NAME = "Exchanger";

    bytes32 internal constant sUSD = "sUSD";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGESTATE = "ExchangeState";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_TRADING_REWARDS = "TradingRewards";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_SYNTHETIX_DEBTSHARE = "SynthetixDebtShare";
    // bytes32 private constant CONTRACT_DEBTCACHE = "DebtCache";
    bytes32 private constant CONTRACT_CIRCUIT_BREAKER = "ExchangeCircuitBreaker";
    bytes32 private constant CONTRACT_ISSUED_SYNTH_AGGREGATOR = "IssuedSynthAggregator";
    bytes32 private constant CONTRACT_SYNTHR_BRIDGE = "SynthrBridge";

    constructor(address _owner, address _resolver) Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view override returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](11);
        newAddresses[0] = CONTRACT_SYSTEMSTATUS;
        newAddresses[1] = CONTRACT_EXCHANGESTATE;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_SYNTHETIX;
        newAddresses[4] = CONTRACT_FEEPOOL;
        newAddresses[5] = CONTRACT_TRADING_REWARDS;
        newAddresses[6] = CONTRACT_ISSUER;
        newAddresses[7] = CONTRACT_CIRCUIT_BREAKER;
        newAddresses[8] = CONTRACT_ISSUED_SYNTH_AGGREGATOR;
        newAddresses[9] = CONTRACT_SYNTHR_BRIDGE;
        newAddresses[10] = CONTRACT_SYNTHETIX_DEBTSHARE;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function exchangeState() internal view returns (IExchangeState) {
        return IExchangeState(requireAndGetAddress(CONTRACT_EXCHANGESTATE));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function synthrBridge() internal view returns (ISynthrBridge) {
        return ISynthrBridge(requireAndGetAddress(CONTRACT_SYNTHR_BRIDGE));
    }

    function exchangeCircuitBreaker() internal view returns (IExchangeCircuitBreaker) {
        return IExchangeCircuitBreaker(requireAndGetAddress(CONTRACT_CIRCUIT_BREAKER));
    }

    function synthetix() internal view returns (ISynthetix) {
        return ISynthetix(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function tradingRewards() internal view returns (ITradingRewards) {
        return ITradingRewards(requireAndGetAddress(CONTRACT_TRADING_REWARDS));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    // function debtCache() internal view returns (IExchangerInternalDebtCache) {
    //     return IExchangerInternalDebtCache(requireAndGetAddress(CONTRACT_DEBTCACHE));
    // }

    function synthetixDebtShare() internal view returns (ISynthetixDebtShare) {
        return ISynthetixDebtShare(requireAndGetAddress(CONTRACT_SYNTHETIX_DEBTSHARE));
    }

    function issuedSynthAggregator() internal view returns (IIssuedSynthAggregator) {
        return IIssuedSynthAggregator(requireAndGetAddress(CONTRACT_ISSUED_SYNTH_AGGREGATOR));
    }

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) public view returns (uint256) {
        return secsLeftInWaitingPeriodForExchange(exchangeState().getMaxTimestamp(account, currencyKey));
    }

    // function waitingPeriodSecs() external view returns (uint256) {
    //     return getWaitingPeriodSecs();
    // }

    function tradingRewardsEnabled() external view returns (bool) {
        return getTradingRewardsEnabled();
    }

    // function priceDeviationThresholdFactor() external view returns (uint256) {
    //     return getPriceDeviationThresholdFactor();
    // }

    // function lastExchangeRate(bytes32 currencyKey)
    //     external
    //     view
    //     returns (uint256)
    // {
    //     return exchangeCircuitBreaker().lastExchangeRate(currencyKey);
    // }

    function settlementOwing(address account, bytes32 currencyKey)
        public
        view
        returns (
            uint256 reclaimAmount,
            uint256 rebateAmount,
            uint256 numEntries
        )
    {
        (reclaimAmount, rebateAmount, numEntries, ) = _settlementOwing(account, currencyKey);
    }

    // Internal function to aggregate each individual rebate and reclaim entry for a synth
    function _settlementOwing(address account, bytes32 currencyKey)
        internal
        view
        returns (
            uint256 reclaimAmount,
            uint256 rebateAmount,
            uint256 numEntries,
            IExchanger.ExchangeEntrySettlement[] memory
        )
    {
        // Need to sum up all reclaim and rebate amounts for the user and the currency key
        numEntries = exchangeState().getLengthOfEntries(account, currencyKey);

        // For each unsettled exchange

        IExchanger.ExchangeEntrySettlement[] memory settlements = new IExchanger.ExchangeEntrySettlement[](numEntries);
        for (uint256 i = 0; i < numEntries; i++) {
            uint256 reclaims;
            uint256 rebate;
            // fetch the entry from storage

            IExchangeState.ExchangeEntry memory exchangeEntry = _getExchangeEntry(account, currencyKey, i);

            // determine the last round ids for src and dest pairs when period ended or latest if not over
            (uint256 srcRoundIdAtPeriodEnd, uint256 destRoundIdAtPeriodEnd) = getRoundIdsAtPeriodEnd(exchangeEntry);

            // given these round ids, determine what effective value they should have received
            (uint256 destinationAmount, , ) = exchangeRates().effectiveValueAndRatesAtRound(
                exchangeEntry.src,
                exchangeEntry.amount,
                exchangeEntry.dest,
                srcRoundIdAtPeriodEnd,
                destRoundIdAtPeriodEnd
            );

            // and deduct the fee from this amount using the exchangeFeeRate from storage
            uint256 amountShouldHaveReceived = _deductFeesFromAmount(destinationAmount, exchangeEntry.exchangeFeeRate);

            // SIP-65 settlements where the amount at end of waiting period is beyond the threshold, then
            // settle with no reclaim or rebate
            bool sip65condition = exchangeCircuitBreaker().isDeviationAboveThreshold(
                exchangeEntry.amountReceived,
                amountShouldHaveReceived
            );
            if (!sip65condition) {
                if (exchangeEntry.amountReceived > amountShouldHaveReceived) {
                    // if they received more than they should have, add to the reclaim tally
                    reclaims = exchangeEntry.amountReceived.sub(amountShouldHaveReceived);
                    reclaimAmount = reclaimAmount.add(reclaims);
                } else if (amountShouldHaveReceived > exchangeEntry.amountReceived) {
                    // if less, add to the rebate tally
                    rebate = amountShouldHaveReceived.sub(exchangeEntry.amountReceived);
                    rebateAmount = rebateAmount.add(rebate);
                }
            }

            settlements[i] = IExchanger.ExchangeEntrySettlement({
                src: exchangeEntry.src,
                amount: exchangeEntry.amount,
                dest: exchangeEntry.dest,
                reclaim: reclaims,
                rebate: rebate,
                srcRoundIdAtPeriodEnd: srcRoundIdAtPeriodEnd,
                destRoundIdAtPeriodEnd: destRoundIdAtPeriodEnd,
                timestamp: exchangeEntry.timestamp
            });
        }

        return (reclaimAmount, rebateAmount, numEntries, settlements);
    }

    function _getExchangeEntry(
        address account,
        bytes32 currencyKey,
        uint256 index
    ) internal view returns (IExchangeState.ExchangeEntry memory) {
        (
            bytes32 src,
            uint256 amount,
            bytes32 dest,
            uint256 amountReceived,
            uint256 exchangeFeeRate,
            uint256 timestamp,
            uint256 roundIdForSrc,
            uint256 roundIdForDest
        ) = exchangeState().getEntryAt(account, currencyKey, index);

        return
            IExchangeState.ExchangeEntry({
                src: src,
                amount: amount,
                dest: dest,
                amountReceived: amountReceived,
                exchangeFeeRate: exchangeFeeRate,
                timestamp: timestamp,
                roundIdForSrc: roundIdForSrc,
                roundIdForDest: roundIdForDest
            });
    }

    // function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool) {
    //     if (maxSecsLeftInWaitingPeriod(account, currencyKey) != 0) {
    //         return true;
    //     }

    //     (uint256 reclaimAmount, , , ) = _settlementOwing(account, currencyKey);

    //     return reclaimAmount > 0;
    // }

    /* ========== SETTERS ========== */

    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint256 amount,
        uint256 refunded
    ) public view returns (uint256 amountAfterSettlement) {
        amountAfterSettlement = amount;

        // balance of a synth will show an amount after settlement
        uint256 balanceOfSourceAfterSettlement = IERC20(address(issuer().synths(currencyKey))).balanceOf(from);

        // when there isn't enough supply (either due to reclamation settlement or because the number is too high)
        if (amountAfterSettlement > balanceOfSourceAfterSettlement) {
            // then the amount to exchange is reduced to their remaining supply
            amountAfterSettlement = balanceOfSourceAfterSettlement;
        }

        if (refunded > 0) {
            amountAfterSettlement = amountAfterSettlement.add(refunded);
        }
    }

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool) {
        (, bool invalid) = exchangeCircuitBreaker().rateWithInvalid(currencyKey);
        return invalid;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function exchange(
        address rewardAddress,
        bytes32 trackingCode,
        IExchanger.ExchangeArgs calldata args
    ) external payable onlySynthetixorSynth returns (uint256 amountReceived) {
        uint256 fee;
        (amountReceived, fee) = _exchange(args);

        _processTradingRewards(fee, rewardAddress);

        if (trackingCode != bytes32(0)) {
            _emitTrackingEvent(trackingCode, args.destCurrencyKey, amountReceived, fee);
        }
    }

    function updateDestinationForExchange(
        address recipient,
        bytes32 destinationKey,
        uint256 destinationAmount
    ) public onlySynthrBridge {
        require(destinationKey != bytes32(0), "dest key didn't set.");
        ISynth dest = issuer().synths(destinationKey);
        dest.issue(recipient, destinationAmount);
    }

    function _emitTrackingEvent(
        bytes32 trackingCode,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        uint256 fee
    ) internal {
        ISynthetixInternal(address(synthetix())).emitExchangeTracking(trackingCode, toCurrencyKey, toAmount, fee);
    }

    function _processTradingRewards(uint256 fee, address rewardAddress) internal {
        if (fee > 0 && rewardAddress != address(0) && getTradingRewardsEnabled()) {
            tradingRewards().recordExchangeFeeForAccount(fee, rewardAddress);
        }
    }

    function _settleAndCalcSourceAmountRemaining(
        uint256 sourceAmount,
        address from,
        bytes32 sourceCurrencyKey
    )
        internal
        returns (
            uint256 sourceAmountAfterSettlement,
            uint256 reclaimed,
            uint256 refunded
        )
    {
        uint256 numEntriesSettled;
        (reclaimed, refunded, numEntriesSettled) = _internalSettle(from, sourceCurrencyKey);

        sourceAmountAfterSettlement = sourceAmount;

        // when settlement was required
        if (numEntriesSettled > 0) {
            // ensure the sourceAmount takes this into account
            sourceAmountAfterSettlement = calculateAmountAfterSettlement(from, sourceCurrencyKey, sourceAmount, refunded);
        }
    }

    function _exchange(IExchanger.ExchangeArgs memory args) internal returns (uint256 amountReceived, uint256 fee) {
        require(args.sourceAmount > 0, "Zero amount");

        // Using struct to resolve stack too deep error
        IExchanger.ExchangeEntry memory entry;

        entry.roundIdForSrc = exchangeRates().getCurrentRoundId(args.sourceCurrencyKey);
        entry.roundIdForDest = exchangeRates().getCurrentRoundId(args.destCurrencyKey);

        (args.sourceAmount, args.reclaimed, args.refunded) = _settleAndCalcSourceAmountRemaining(
            args.sourceAmount,
            args.fromAccount,
            args.sourceCurrencyKey
        );

        // If, after settlement the user has no balance left (highly unlikely), then return to prevent
        // emitting events of 0 and don't revert so as to ensure the settlement queue is emptied
        if (args.sourceAmount == 0) {
            return (0, 0);
        }

        (entry.destinationAmount, entry.sourceRate, entry.destinationRate) = exchangeRates().effectiveValueAndRatesAtRound(
            args.sourceCurrencyKey,
            args.sourceAmount,
            args.destCurrencyKey,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );

        _ensureCanExchangeAtRound(args.sourceCurrencyKey, args.destCurrencyKey, entry.roundIdForSrc, entry.roundIdForDest);

        // SIP-65: Decentralized Circuit Breaker
        // mutative call to suspend system if the rate is invalid
        if (_exchangeRatesCircuitBroken(args.sourceCurrencyKey, args.destCurrencyKey)) {
            return (0, 0);
        }

        bool tooVolatile;
        (entry.exchangeFeeRate, tooVolatile) = _feeRateForExchangeAtRounds(
            args.sourceCurrencyKey,
            args.destCurrencyKey,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );

        if (tooVolatile) {
            // do not exchange if rates are too volatile, this to prevent charging
            // dynamic fees that are over the max value
            return (0, 0);
        }

        amountReceived = _deductFeesFromAmount(entry.destinationAmount, entry.exchangeFeeRate);
        // Note: `fee` is denominated in the destinationCurrencyKey.
        fee = entry.destinationAmount.sub(amountReceived);

        args.destAmount = amountReceived;
        args.fee = fee;

        // Note: We don't need to check their balance as the _convert() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.
        _convert(args);

        // Let the DApps know there was a Synth exchange
        ISynthetixInternal(address(synthetix())).emitSynthExchange(
            args.fromAccount,
            args.sourceCurrencyKey,
            args.sourceAmount,
            args.destCurrencyKey,
            amountReceived,
            args.destAccount
        );

        // if the waiting period is gt 0
        if (getWaitingPeriodSecs() > 0) {
            // persist the exchange information for the dest key
            appendExchange(
                args.destAccount,
                args.sourceCurrencyKey,
                args.sourceAmount,
                args.destCurrencyKey,
                amountReceived,
                entry.exchangeFeeRate
            );
        }
    }

    // SIP-65: Decentralized Circuit Breaker
    function _exchangeRatesCircuitBroken(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        internal
        returns (bool circuitBroken)
    {
        // check both currencies unless they're sUSD, since its rate is never invalid (gas savings)
        if (sourceCurrencyKey != sUSD) {
            (, circuitBroken) = exchangeCircuitBreaker().rateWithBreakCircuit(sourceCurrencyKey);
        }

        if (destinationCurrencyKey != sUSD) {
            // we're not skipping the suspension check if the circuit was broken already
            // this is not terribly important, but is more consistent (so that results don't
            // depend on which synth is source and which is destination)
            bool destCircuitBroken;
            (, destCircuitBroken) = exchangeCircuitBreaker().rateWithBreakCircuit(destinationCurrencyKey);
            circuitBroken = circuitBroken || destCircuitBroken;
        }
    }

    function _convert(
        IExchanger.ExchangeArgs memory args // uint256 sourceAmountAfterSettlement, // uint256 amountReceived, // uint256 fee,
    ) internal {
        // Burn the source amount
        issuer().synths(args.sourceCurrencyKey).burn(args.fromAccount, args.sourceAmount);
        // synthetixDebtShare()

        if (args.destChainId == 0) {
            ISynth dest = issuer().synths(args.destCurrencyKey);

            dest.issue(args.destAccount, args.destAmount);
        }
        // Note: As of this point, `fee` is denominated in sUSD.
        // Remit the fee if required
        if (args.fee > 0) {
            // Normalize fee to sUSD
            // Note: `fee` is being reused to avoid stack too deep errors.
            args.fee = exchangeRates().effectiveValue(args.destCurrencyKey, args.fee, sUSD);

            // Remit the fee in sUSDs
            issuer().synths(sUSD).issue(feePool().FEE_ADDRESS(), args.fee);

            // Tell the fee pool about this
            feePool().recordFeePaid(args.fee);
        }
        synthrBridge().sendExchange{value: msg.value}(args);
    }

    // Note: this function can intentionally be called by anyone on behalf of anyone else (the caller just pays the gas)
    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntriesSettled
        )
    {
        systemStatus().requireSynthActive(currencyKey);
        return _internalSettle(from, currencyKey);
    }

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external {
        systemStatus().requireSystemActive();
        // SIP-65: Decentralized Circuit Breaker
        (, bool circuitBroken) = exchangeCircuitBreaker().rateWithBreakCircuit(currencyKey);
        require(circuitBroken, "Synth price is valid");
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _ensureCanExchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) internal view {
        // require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same synth");
        require(sourceAmount > 0, "Zero amount");

        bytes32[] memory synthKeys = new bytes32[](2);
        synthKeys[0] = sourceCurrencyKey;
        synthKeys[1] = destinationCurrencyKey;
        require(!exchangeRates().anyRateIsInvalid(synthKeys), "src/dest value is invalid.");
    }

    function _ensureCanExchangeAtRound(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) internal view {
        // require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same synth");

        bytes32[] memory synthKeys = new bytes32[](2);
        synthKeys[0] = sourceCurrencyKey;
        synthKeys[1] = destinationCurrencyKey;

        uint256[] memory roundIds = new uint256[](2);
        roundIds[0] = roundIdForSrc;
        roundIds[1] = roundIdForDest;
        require(!exchangeRates().anyRateIsInvalidAtRound(synthKeys, roundIds), "src/dest value is invalid.");
    }

    function _internalSettle(address from, bytes32 currencyKey)
        internal
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntriesSettled
        )
    {
        require(maxSecsLeftInWaitingPeriod(from, currencyKey) == 0, "Cannot settle during waiting period");

        (
            uint256 reclaimAmount,
            uint256 rebateAmount,
            uint256 entries,
            IExchanger.ExchangeEntrySettlement[] memory settlements
        ) = _settlementOwing(from, currencyKey);

        if (reclaimAmount > rebateAmount) {
            reclaimed = reclaimAmount.sub(rebateAmount);
            reclaim(from, currencyKey, reclaimed);
        } else if (rebateAmount > reclaimAmount) {
            refunded = rebateAmount.sub(reclaimAmount);
            refund(from, currencyKey, refunded);
        }

        // // by checking a reclaim or refund we also check that the currency key is still a valid synth,
        // // as the deviation check will return 0 if the synth has been removed.
        // if (updateCache && (reclaimed > 0 || refunded > 0)) {
        //     bytes32[] memory key = new bytes32[](1);
        //     key[0] = currencyKey;
        //     debtCache().updateCachedSynthDebts(key);
        // }

        // emit settlement event for each settled exchange entry
        for (uint256 i = 0; i < settlements.length; i++) {
            emit ExchangeEntrySettled(
                from,
                settlements[i].src,
                settlements[i].amount,
                settlements[i].dest,
                settlements[i].reclaim,
                settlements[i].rebate,
                settlements[i].srcRoundIdAtPeriodEnd,
                settlements[i].destRoundIdAtPeriodEnd,
                settlements[i].timestamp
            );
        }

        numEntriesSettled = entries;

        // Now remove all entries, even if no reclaim and no rebate
        exchangeState().removeEntries(from, currencyKey);
    }

    function reclaim(
        address from,
        bytes32 currencyKey,
        uint256 amount
    ) internal {
        // burn amount from user
        issuer().synths(currencyKey).burn(from, amount);
        ISynthetixInternal(address(synthetix())).emitExchangeReclaim(from, currencyKey, amount);
    }

    function refund(
        address from,
        bytes32 currencyKey,
        uint256 amount
    ) internal {
        // issue amount to user
        issuer().synths(currencyKey).issue(from, amount);
        ISynthetixInternal(address(synthetix())).emitExchangeRebate(from, currencyKey, amount);
    }

    function secsLeftInWaitingPeriodForExchange(uint256 timestamp) internal view returns (uint256) {
        uint256 _waitingPeriodSecs = getWaitingPeriodSecs();
        if (timestamp == 0 || block.timestamp >= timestamp.add(_waitingPeriodSecs)) {
            return 0;
        }

        return timestamp.add(_waitingPeriodSecs).sub(block.timestamp);
    }

    /* ========== Exchange Related Fees ========== */
    /// @notice public function to get the total fee rate for a given exchange
    /// @param sourceCurrencyKey The source currency key
    /// @param destinationCurrencyKey The destination currency key
    /// @return The exchange fee rate, and whether the rates are too volatile
    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint256) {
        (uint256 feeRate, bool tooVolatile) = _feeRateForExchange(sourceCurrencyKey, destinationCurrencyKey);
        require(!tooVolatile, "too volatile");
        return feeRate;
    }

    /// @notice public function to get the dynamic fee rate for a given exchange
    /// @param sourceCurrencyKey The source currency key
    /// @param destinationCurrencyKey The destination currency key
    /// @return feeRate The exchange dynamic fee rate
    /// @return tooVolatile if rates are too volatile
    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint256 feeRate, bool tooVolatile)
    {
        return _dynamicFeeRateForExchange(sourceCurrencyKey, destinationCurrencyKey);
    }

    /// @notice Calculate the exchange fee for a given source and destination currency key
    /// @param sourceCurrencyKey The source currency key
    /// @param destinationCurrencyKey The destination currency key
    /// @return feeRate The exchange fee rate
    /// @return tooVolatile The exchange dynamic fee rate and if rates are too volatile
    function _feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        internal
        view
        returns (uint256 feeRate, bool tooVolatile)
    {
        // Get the exchange fee rate as per the source currencyKey and destination currencyKey
        uint256 baseRate = getExchangeFeeRate(sourceCurrencyKey).add(getExchangeFeeRate(destinationCurrencyKey));
        uint256 dynamicFee;
        (dynamicFee, tooVolatile) = _dynamicFeeRateForExchange(sourceCurrencyKey, destinationCurrencyKey);
        return (baseRate.add(dynamicFee), tooVolatile);
    }

    /// @notice Calculate the exchange fee for a given source and destination currency key
    /// @param sourceCurrencyKey The source currency key
    /// @param destinationCurrencyKey The destination currency key
    /// @param roundIdForSrc The round id of the source currency.
    /// @param roundIdForDest The round id of the target currency.
    /// @return feeRate The exchange fee rate
    /// @return tooVolatile The exchange dynamic fee rate
    function _feeRateForExchangeAtRounds(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) internal view returns (uint256 feeRate, bool tooVolatile) {
        // Get the exchange fee rate as per the source currencyKey and destination currencyKey
        uint256 baseRate = getExchangeFeeRate(sourceCurrencyKey).add(getExchangeFeeRate(destinationCurrencyKey));
        uint256 dynamicFee;
        (dynamicFee, tooVolatile) = _dynamicFeeRateForExchangeAtRounds(
            sourceCurrencyKey,
            destinationCurrencyKey,
            roundIdForSrc,
            roundIdForDest
        );
        return (baseRate.add(dynamicFee), tooVolatile);
    }

    function _dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        internal
        view
        returns (uint256 dynamicFee, bool tooVolatile)
    {
        DynamicFeeConfig memory config = getExchangeDynamicFeeConfig();
        (uint256 dynamicFeeDst, bool dstVolatile) = _dynamicFeeRateForCurrency(destinationCurrencyKey, config);
        (uint256 dynamicFeeSrc, bool srcVolatile) = _dynamicFeeRateForCurrency(sourceCurrencyKey, config);
        dynamicFee = dynamicFeeDst.add(dynamicFeeSrc);
        // cap to maxFee
        bool overMax = dynamicFee > config.maxFee;
        dynamicFee = overMax ? config.maxFee : dynamicFee;
        return (dynamicFee, overMax || dstVolatile || srcVolatile);
    }

    function _dynamicFeeRateForExchangeAtRounds(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) internal view returns (uint256 dynamicFee, bool tooVolatile) {
        DynamicFeeConfig memory config = getExchangeDynamicFeeConfig();
        (uint256 dynamicFeeDst, bool dstVolatile) = _dynamicFeeRateForCurrencyRound(
            destinationCurrencyKey,
            roundIdForDest,
            config
        );
        (uint256 dynamicFeeSrc, bool srcVolatile) = _dynamicFeeRateForCurrencyRound(sourceCurrencyKey, roundIdForSrc, config);
        dynamicFee = dynamicFeeDst.add(dynamicFeeSrc);
        // cap to maxFee
        bool overMax = dynamicFee > config.maxFee;
        dynamicFee = overMax ? config.maxFee : dynamicFee;
        return (dynamicFee, overMax || dstVolatile || srcVolatile);
    }

    /// @notice Get dynamic dynamicFee for a given currency key (SIP-184)
    /// @param currencyKey The given currency key
    /// @param config dynamic fee calculation configuration params
    /// @return dynamicFee The dynamic fee
    /// @return tooVolatile if it exceeds max dynamic fee set in config
    function _dynamicFeeRateForCurrency(bytes32 currencyKey, DynamicFeeConfig memory config)
        internal
        view
        returns (uint256 dynamicFee, bool tooVolatile)
    {
        // no dynamic dynamicFee for sUSD or too few rounds
        if (currencyKey == sUSD || config.rounds <= 1) {
            return (0, false);
        }
        uint256 roundId = exchangeRates().getCurrentRoundId(currencyKey);
        return _dynamicFeeRateForCurrencyRound(currencyKey, roundId, config);
    }

    /// @notice Get dynamicFee for a given currency key (SIP-184)
    /// @param currencyKey The given currency key
    /// @param roundId The round id
    /// @param config dynamic fee calculation configuration params
    /// @return dynamicFee The dynamic fee
    /// @return tooVolatile if it exceeds max dynamic fee set in config
    function _dynamicFeeRateForCurrencyRound(
        bytes32 currencyKey,
        uint256 roundId,
        DynamicFeeConfig memory config
    ) internal view returns (uint256 dynamicFee, bool tooVolatile) {
        // no dynamic dynamicFee for sUSD or too few rounds
        if (currencyKey == sUSD || config.rounds <= 1) {
            return (0, false);
        }
        uint256[] memory prices;
        (prices, ) = exchangeRates().ratesAndUpdatedTimeForCurrencyLastNRounds(currencyKey, config.rounds, roundId);
        dynamicFee = _dynamicFeeCalculation(prices, config.threshold, config.weightDecay);
        // cap to maxFee
        bool overMax = dynamicFee > config.maxFee;
        dynamicFee = overMax ? config.maxFee : dynamicFee;
        return (dynamicFee, overMax);
    }

    /// @notice Calculate dynamic fee according to SIP-184
    /// @param prices A list of prices from the current round to the previous rounds
    /// @param threshold A threshold to clip the price deviation ratop
    /// @param weightDecay A weight decay constant
    /// @return uint dynamic fee rate as decimal
    function _dynamicFeeCalculation(
        uint256[] memory prices,
        uint256 threshold,
        uint256 weightDecay
    ) internal pure returns (uint256) {
        // don't underflow
        if (prices.length == 0) {
            return 0;
        }

        uint256 dynamicFee = 0; // start with 0
        // go backwards in price array
        for (uint256 i = prices.length - 1; i > 0; i--) {
            // apply decay from previous round (will be 0 for first round)
            dynamicFee = dynamicFee.multiplyDecimal(weightDecay);
            // calculate price deviation
            uint256 deviation = _thresholdedAbsDeviationRatio(prices[i - 1], prices[i], threshold);
            // add to total fee
            dynamicFee = dynamicFee.add(deviation);
        }
        return dynamicFee;
    }

    /// absolute price deviation ratio used by dynamic fee calculation
    /// deviationRatio = (abs(current - previous) / previous) - threshold
    /// if negative, zero is returned
    function _thresholdedAbsDeviationRatio(
        uint256 price,
        uint256 previousPrice,
        uint256 threshold
    ) internal pure returns (uint256) {
        if (previousPrice == 0) {
            return 0; // don't divide by zero
        }
        // abs difference between prices
        uint256 absDelta = price > previousPrice ? price - previousPrice : previousPrice - price;
        // relative to previous price
        uint256 deviationRatio = absDelta.divideDecimal(previousPrice);
        // only the positive difference from threshold
        return deviationRatio > threshold ? deviationRatio - threshold : 0;
    }

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
        )
    {
        // The checks are added for consistency with the checks performed in _exchange()
        // The reverts (instead of no-op returns) are used order to prevent incorrect usage in calling contracts
        // (The no-op in _exchange() is in order to trigger system suspension if needed)

        // check synths active
        systemStatus().requireSynthActive(sourceCurrencyKey);
        systemStatus().requireSynthActive(destinationCurrencyKey);

        // check rates don't deviate above ciruit breaker allowed deviation
        (, bool srcInvalid) = exchangeCircuitBreaker().rateWithInvalid(sourceCurrencyKey);
        (, bool dstInvalid) = exchangeCircuitBreaker().rateWithInvalid(destinationCurrencyKey);
        require(!srcInvalid, "source synth rate invalid");
        require(!dstInvalid, "destination synth rate invalid");

        // check rates not stale or flagged
        _ensureCanExchange(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

        bool tooVolatile;
        (exchangeFeeRate, tooVolatile) = _feeRateForExchange(sourceCurrencyKey, destinationCurrencyKey);

        // check rates volatility result
        require(!tooVolatile, "exchange rates too volatile");

        (uint256 destinationAmount, , ) = exchangeRates().effectiveValueAndRates(
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey
        );

        amountReceived = _deductFeesFromAmount(destinationAmount, exchangeFeeRate);
        fee = destinationAmount.sub(amountReceived);
    }

    function _deductFeesFromAmount(uint256 destinationAmount, uint256 exchangeFeeRate)
        internal
        pure
        returns (uint256 amountReceived)
    {
        amountReceived = destinationAmount.multiplyDecimal(SafeDecimalMath.unit().sub(exchangeFeeRate));
    }

    function appendExchange(
        address account,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 amountReceived,
        uint256 exchangeFeeRate
    ) internal {
        IExchangeRates exRates = exchangeRates();
        uint256 roundIdForSrc = exRates.getCurrentRoundId(src);
        uint256 roundIdForDest = exRates.getCurrentRoundId(dest);
        exchangeState().appendExchangeEntry(
            account,
            src,
            amount,
            dest,
            amountReceived,
            exchangeFeeRate,
            block.timestamp,
            roundIdForSrc,
            roundIdForDest
        );

        emit ExchangeEntryAppended(account, src, amount, dest, amountReceived, exchangeFeeRate, roundIdForSrc, roundIdForDest);
    }

    function getRoundIdsAtPeriodEnd(IExchangeState.ExchangeEntry memory exchangeEntry)
        internal
        view
        returns (uint256 srcRoundIdAtPeriodEnd, uint256 destRoundIdAtPeriodEnd)
    {
        IExchangeRates exRates = exchangeRates();
        uint256 _waitingPeriodSecs = getWaitingPeriodSecs();

        srcRoundIdAtPeriodEnd = exRates.getLastRoundIdBeforeElapsedSecs(
            exchangeEntry.src,
            exchangeEntry.roundIdForSrc,
            exchangeEntry.timestamp,
            _waitingPeriodSecs
        );
        destRoundIdAtPeriodEnd = exRates.getLastRoundIdBeforeElapsedSecs(
            exchangeEntry.dest,
            exchangeEntry.roundIdForDest,
            exchangeEntry.timestamp,
            _waitingPeriodSecs
        );
    }

    // ========== MODIFIERS ==========

    modifier onlySynthetixorSynth() {
        ISynthetix _synthetix = synthetix();
        require(
            msg.sender == address(_synthetix) || issuer().synthsByAddress(msg.sender) != bytes32(0),
            "Exchanger: Only synthetix or a synth contract can perform this action"
        );
        _;
    }

    modifier onlySynthrBridge() {
        require(msg.sender == address(synthrBridge()), "Exchanger: Only synthr bridge can call");
        _;
    }

    // ========== EVENTS ==========
    event ExchangeEntryAppended(
        address indexed account,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 amountReceived,
        uint256 exchangeFeeRate,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    );

    event ExchangeEntrySettled(
        address indexed from,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 reclaim,
        uint256 rebate,
        uint256 srcRoundIdAtPeriodEnd,
        uint256 destRoundIdAtPeriodEnd,
        uint256 exchangeTimestamp
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Exchanger.sol";

// Internal references
import "./MinimalProxyFactory.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IExchanger.sol";

// https://docs.synthetix.io/contracts/source/contracts/exchangerwithfeereclamationalternatives
contract ExchangerWithFeeRecAlternatives is Exchanger {
    // bytes32 public constant override CONTRACT_NAME = "ExchangerWithFeeRecAlternatives";

    using SafeMath for uint256;

    struct ExchangeVolumeAtPeriod {
        uint64 time;
        uint192 volume;
    }

    ExchangeVolumeAtPeriod public lastAtomicVolume;
    uint16 private constant PT_EXCHANGE = 5;

    constructor(address _owner, address _resolver)
        // MinimalProxyFactory()
        Exchanger(_owner, _resolver)
    {}

    /* ========== VIEWS ========== */

    function getAmountsForAtomicExchange(
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
        )
    {
        (amountReceived, fee, exchangeFeeRate, , , ) = _getAmountsForAtomicExchangeMinusFees(
            sourceAmount,
            sourceCurrencyKey,
            destinationCurrencyKey
        );
    }

    function getSendExchangeGasFee(
        address _account,
        bytes32 _sourceKey,
        uint256 _sourceAmount,
        bytes32 _destKey,
        uint16 _destChainId
    ) external view returns (uint256) {
        uint256 amountReceived;
        uint256 fee;

        (amountReceived, fee, , , , ) = _getAmountsForAtomicExchangeMinusFees(_sourceAmount, _sourceKey, _destKey);
        bytes memory lzPayload = abi.encode(
            PT_EXCHANGE,
            abi.encodePacked(_account),
            _sourceKey,
            _sourceAmount,
            abi.encodePacked(_account),
            _destKey,
            amountReceived,
            fee,
            _destChainId
        );

        return synthrBridge().calcLZFee(lzPayload, PT_EXCHANGE);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function exchangeAtomically(
        bytes32 trackingCode,
        uint256 minAmount,
        IExchanger.ExchangeArgs calldata args
    ) external payable onlySynthetixorSynth returns (uint256 amountReceived) {
        uint256 fee;
        (amountReceived, fee) = _exchangeAtomically(args);

        require(amountReceived >= minAmount, "The amount received is below the minimum amount specified.");

        _processTradingRewards(fee, args.destAccount);

        if (trackingCode != bytes32(0)) {
            _emitTrackingEvent(trackingCode, args.destCurrencyKey, amountReceived, fee);
        }
    }

    function _exchangeAtomically(IExchanger.ExchangeArgs memory _args) internal returns (uint256 amountReceived, uint256 fee) {
        IExchanger.ExchangeArgs memory args = _args;
        _ensureCanExchange(args.sourceCurrencyKey, args.sourceAmount, args.destCurrencyKey);
        require(!exchangeRates().synthTooVolatileForAtomicExchange(args.sourceCurrencyKey), "Src synth value is volatile.");
        require(!exchangeRates().synthTooVolatileForAtomicExchange(args.destCurrencyKey), "Dest synth value is volatile.");

        (args.sourceAmount, args.reclaimed, args.refunded) = _settleAndCalcSourceAmountRemaining(
            args.sourceAmount,
            args.fromAccount,
            args.sourceCurrencyKey
        );

        // If, after settlement the user has no balance left (highly unlikely), then return to prevent
        // emitting events of 0 and don't revert so as to ensure the settlement queue is emptied
        if (args.sourceAmount == 0) {
            return (0, 0);
        }

        uint256 exchangeFeeRate;
        uint256 systemConvertedAmount;
        uint256 systemSourceRate;
        uint256 systemDestinationRate;

        // Note: also ensures the given synths are allowed to be atomically exchanged
        (
            amountReceived, // output amount with fee taken out (denominated in dest currency)
            fee, // fee amount (denominated in dest currency)
            exchangeFeeRate, // applied fee rate
            systemConvertedAmount, // current system value without fees (denominated in dest currency)
            systemSourceRate, // current system rate for src currency
            systemDestinationRate // current system rate for dest currency
        ) = _getAmountsForAtomicExchangeMinusFees(args.sourceAmount, args.sourceCurrencyKey, args.destCurrencyKey);

        args.destAmount = amountReceived;
        args.fee = fee;

        // SIP-65: Decentralized Circuit Breaker (checking current system rates)
        if (_exchangeRatesCircuitBroken(args.sourceCurrencyKey, args.destCurrencyKey)) {
            return (0, 0);
        }

        // Sanity check atomic output's value against current system value (checking atomic rates)
        require(
            !exchangeCircuitBreaker().isDeviationAboveThreshold(systemConvertedAmount, amountReceived.add(fee)),
            "Atomic rate deviates too much"
        );

        // Determine sUSD value of exchange
        uint256 sourceSusdValue;
        if (args.sourceCurrencyKey == sUSD) {
            // Use after-settled amount as this is amount converted (not sourceAmount)
            sourceSusdValue = _args.sourceAmount;
        } else if (args.destCurrencyKey == sUSD) {
            // In this case the systemConvertedAmount would be the fee-free sUSD value of the source synth
            sourceSusdValue = systemConvertedAmount;
        } else {
            // Otherwise, convert source to sUSD value
            (uint256 amountReceivedInUSD, uint256 sUsdFee, , , , ) = _getAmountsForAtomicExchangeMinusFees(
                _args.sourceAmount,
                args.sourceCurrencyKey,
                sUSD
            );
            sourceSusdValue = amountReceivedInUSD.add(sUsdFee);
        }

        // Check and update atomic volume limit
        _checkAndUpdateAtomicVolume(sourceSusdValue);

        // Note: We don't need to check their balance as the _convert() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.
        _convert(args);

        // Let the DApps know there was a Synth exchange
        ISynthetixInternal(address(synthetix())).emitSynthExchange(
            args.fromAccount,
            args.sourceCurrencyKey,
            args.sourceAmount,
            args.destCurrencyKey,
            amountReceived,
            args.destAccount
        );

        // Emit separate event to track atomic exchanges
        ISynthetixInternal(address(synthetix())).emitAtomicSynthExchange(
            args.fromAccount,
            args.sourceCurrencyKey,
            args.sourceAmount,
            args.destCurrencyKey,
            amountReceived,
            args.destAccount
        );
    }

    function _checkAndUpdateAtomicVolume(uint256 sourceSusdValue) internal {
        uint256 currentVolume = uint256(lastAtomicVolume.time) == block.timestamp
            ? uint256(lastAtomicVolume.volume).add(sourceSusdValue)
            : sourceSusdValue;
        require(currentVolume <= getAtomicMaxVolumePerBlock(), "Surpassed volume limit");
        lastAtomicVolume.time = uint64(block.timestamp);
        lastAtomicVolume.volume = uint192(currentVolume); // Protected by volume limit check above
    }

    function _feeRateForAtomicExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        internal
        view
        returns (uint256)
    {
        // Get the exchange fee rate as per source and destination currencyKey
        uint256 baseRate = getAtomicExchangeFeeRate(sourceCurrencyKey).add(getAtomicExchangeFeeRate(destinationCurrencyKey));
        if (baseRate == 0) {
            // If no atomic rate was set, fallback to the regular exchange rate
            baseRate = getExchangeFeeRate(sourceCurrencyKey).add(getExchangeFeeRate(destinationCurrencyKey));
        }

        return baseRate;
    }

    function _getAmountsForAtomicExchangeMinusFees(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        internal
        view
        returns (
            uint256 amountReceived,
            uint256 fee,
            uint256 exchangeFeeRate,
            uint256 systemConvertedAmount,
            uint256 systemSourceRate,
            uint256 systemDestinationRate
        )
    {
        uint256 destinationAmount;
        (destinationAmount, systemConvertedAmount, systemSourceRate, systemDestinationRate) = exchangeRates()
            .effectiveAtomicValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

        exchangeFeeRate = _feeRateForAtomicExchange(sourceCurrencyKey, destinationCurrencyKey);
        amountReceived = _deductFeesFromAmount(destinationAmount, exchangeFeeRate);
        fee = destinationAmount.sub(amountReceived);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/IExchangeCircuitBreaker
interface IExchangeCircuitBreaker {
    // Views

    function exchangeRates() external view returns (address);

    function rateWithInvalid(bytes32 currencyKey) external view returns (uint256, bool);

    function priceDeviationThresholdFactor() external view returns (uint256);

    function isDeviationAboveThreshold(uint256 base, uint256 comparison) external view returns (bool);

    function lastExchangeRate(bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function resetLastExchangeRate(bytes32[] calldata currencyKeys) external;

    function rateWithBreakCircuit(bytes32 currencyKey) external returns (uint256 lastValidRate, bool circuitBroken);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        uint256 destAmount;
        uint256 fee;
        uint256 reclaimed;
        uint256 refunded;
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
        address rewardAddress,
        bytes32 trackingCode,
        ExchangeArgs calldata args
    ) external payable returns (uint256 amountReceived);

    function exchangeAtomically(
        bytes32 trackingCode,
        uint256 minAmount,
        ExchangeArgs calldata args
    ) external payable returns (uint256 amountReceived);

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
        uint256 destinationAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/iexchangestate
interface IExchangeState {
    // Views
    struct ExchangeEntry {
        bytes32 src;
        uint256 amount;
        bytes32 dest;
        uint256 amountReceived;
        uint256 exchangeFeeRate;
        uint256 timestamp;
        uint256 roundIdForSrc;
        uint256 roundIdForDest;
    }

    function getLengthOfEntries(address account, bytes32 currencyKey) external view returns (uint256);

    function getEntryAt(
        address account,
        bytes32 currencyKey,
        uint256 index
    )
        external
        view
        returns (
            bytes32 src,
            uint256 amount,
            bytes32 dest,
            uint256 amountReceived,
            uint256 exchangeFeeRate,
            uint256 timestamp,
            uint256 roundIdForSrc,
            uint256 roundIdForDest
        );

    function getMaxTimestamp(address account, bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function appendExchangeEntry(
        address account,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 amountReceived,
        uint256 exchangeFeeRate,
        uint256 timestamp,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) external;

    function removeEntries(address account, bytes32 currencyKey) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/ifeepool
interface IFeePool {
    // Views

    // solhint-disable-next-line func-name-mixedcase
    function FEE_ADDRESS() external view returns (address);

    function feesAvailable(address account) external view returns (uint256, uint256);

    function feePeriodDuration() external view returns (uint256);

    function isFeesClaimable(address account) external view returns (bool);

    function targetThreshold() external view returns (uint256);

    function totalFeesAvailable() external view returns (uint256);

    function totalRewardsAvailable() external view returns (uint256);

    // Mutative Functions
    function claimFees() external payable returns (bool);

    function closeCurrentFeePeriod() external;

    function recordFeePaid(uint256 sUSDAmount) external;

    function setRewardsToDistribute(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIssuedSynthAggregator {
    function totalIssuedSynths() external view returns (uint256 _issuedSynths);

    function totalIssuedSynthsPerIssuer(address account) external view returns (uint256 _issuedSynths);

    function totalIssuedSynthPerAsset(bytes32 currencyKey) external view returns (uint256 _issuedSynth);

    function totalIssuedSynthPerAssetAndIssuer(bytes32 currencyKey, address account) external view returns (uint256 _issuedSynth);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    function debtBalanceOf(address issuer) external view returns (uint256 debtBalance);

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

    function issueSynths(
        address from,
        uint256 amount,
        uint256 destChainId
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function issueMaxSynths(address from, uint256 destChainId) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynths(
        address from,
        bytes32 synthKey,
        uint256 amount
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynthsToTarget(address from, bytes32 synthKey) external returns (uint256 synthAmount, uint256 debtShare);

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint256 balance
    ) external;

    function liquidateAccount(
        address account,
        bytes32 collateralKey,
        bool isSelfLiquidation
    )
        external
        returns (
            uint256 totalRedeemed,
            uint256 amountToLiquidate,
            uint256 sharesToRemove
        );

    function destIssue(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount,
        uint256 _debtShare
    ) external;

    function destBurn(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount,
        uint256 _debtShare
    ) external;

    function setCurrentPeriodId(uint128 periodId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value) external payable returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external payable returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISynth.sol";

// https://docs.synthetix.io/contracts/source/interfaces/isynthetix
interface ISynthetix {
    // Views
    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function chainBalanceOf(address account) external view returns (uint256);

    function chainBalanceOfPerKey(address _account, bytes32 _collateralKey) external view returns (uint256);

    function collateralCurrency(bytes32 _collateralKey) external view returns (address);

    function getAvailableCollaterals() external view returns (bytes32[] memory);

    // Mutative Functions
    function burnSynths(uint256 amount, bytes32 synthKey) external;

    function withdrawCollateral(bytes32 collateralKey, uint256 collateralAmount) external;

    function burnSynthsToTarget(bytes32 synthKey) external;

    function exchange(
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
    ) external payable returns (uint256 amountReceived);

    // function exchangeWithTrackingForInitiator(
    //     bytes32 sourceCurrencyKey,
    //     uint256 sourceAmount,
    //     bytes32 destinationCurrencyKey,
    //     address rewardAddress,
    //     bytes32 trackingCode,
    //     uint16 destChainId
    // ) external payable returns (uint256 amountReceived);

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
    ) external payable returns (uint256 amountReceived);

    function issueMaxSynths(uint16 destChainId) external payable;

    function issueSynths(
        bytes32 currencyKey,
        uint256 amount,
        uint256 synthToMint,
        uint16 destChainId
    ) external payable;

    // Liquidations
    function liquidateDelinquentAccount(address account, bytes32 collateralKey) external returns (bool);

    function liquidateSelf(bytes32 collateralKey) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/isynthetixdebtshare
interface ISynthetixDebtShare {
    // Views
    function balanceOf(address account) external view returns (uint256);

    function balanceOfCrossChain(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyCrossChain() external view returns (uint256);

    function sharePercent(address account) external view returns (uint256);

    function sharePercentCrossChain(address account) external view returns (uint256);

    function debtRatio() external view returns (uint256);

    // Mutative functions
    function mintShare(address account, uint256 amount) external;

    function burnShare(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExchanger.sol";

interface ISynthrBridge {
    /* ========== MUTATIVE FUNCTIONS ========== */

    // if destChainId equals to zero, it means minting synth on the same chain.
    // Therefore, just update and broadcast collateral and synth, debtshare info like before.
    // if not, should call destIssue function of source contract(SynthrGateway.sol) on the dest chain
    // note: should update entry for liquidatorRewards whenever calling this function.
    function sendMint(
        address _accountForCollateral,
        bytes32 _collateralKey,
        uint256 _collateralAmount,
        address _accountForSynth,
        bytes32 _synthKey,
        uint256 _synthAmount,
        uint256 _debtShare,
        uint16 _destChainId
    ) external payable;

    function sendWithdraw(
        address account,
        bytes32 collateralKey,
        uint256 amount
    ) external payable;

    // should call destBurn function of source contract(SynthrGateway.sol) on the dest chains while broadcasting message
    // note: should update entry for liquidatorRewards whenever calling this function.
    function sendBurn(
        address accountForSynth,
        bytes32 synthKey,
        uint256 synthAmount,
        uint256 debtShare,
        bool burnToTarget
    ) external payable;

    function sendExchange(IExchanger.ExchangeArgs calldata args) external payable;

    function sendLiquidate(
        address account,
        bytes32 collateralKey,
        uint256 collateralAmount,
        uint256 debtShare,
        uint256 notifyAmount
    ) external payable;

    // this function is that transfer synth assets.
    function sendTransferFrom(
        bytes32 currencyKey,
        address from,
        address to,
        uint256 amount
    ) external payable;

    function sendREAppend(
        address account,
        uint256 amount,
        bool isFromFeePool
    ) external payable;

    function sendVest(address account, uint256 amount) external payable;

    function calcLZFee(bytes memory lzPayload, uint16 packetType) external view returns (uint256 totalFee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/itradingrewards
interface ITradingRewards {
    /* ========== VIEWS ========== */

    function getAvailableRewards() external view returns (uint256);

    function getUnassignedRewards() external view returns (uint256);

    function getRewardsToken() external view returns (address);

    function getPeriodController() external view returns (address);

    function getCurrentPeriod() external view returns (uint256);

    function getPeriodIsClaimable(uint256 periodID) external view returns (bool);

    function getPeriodIsFinalized(uint256 periodID) external view returns (bool);

    function getPeriodRecordedFees(uint256 periodID) external view returns (uint256);

    function getPeriodTotalRewards(uint256 periodID) external view returns (uint256);

    function getPeriodAvailableRewards(uint256 periodID) external view returns (uint256);

    function getUnaccountedFeesForAccountForPeriod(address account, uint256 periodID) external view returns (uint256);

    function getAvailableRewardsForAccountForPeriod(address account, uint256 periodID) external view returns (uint256);

    function getAvailableRewardsForAccountForPeriods(address account, uint256[] calldata periodIDs)
        external
        view
        returns (uint256 totalRewards);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claimRewardsForPeriod(uint256 periodID) external;

    function claimRewardsForPeriods(uint256[] calldata periodIDs) external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function recordExchangeFeeForAccount(uint256 usdFeeAmount, address account) external;

    function closeCurrentPeriodWithRewards(uint256 rewards) external;

    function recoverTokens(address tokenAddress, address recoverAddress) external;

    function recoverUnassignedRewardTokens(address recoverAddress) external;

    function recoverAssignedRewardTokensAndDestroyPeriod(address recoverAddress, uint256 periodID) external;

    function setPeriodController(address newPeriodController) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/minimalproxyfactory
contract MinimalProxyFactory {
    function _cloneAsMinimalProxy(address _base, string memory _revertMsg) internal returns (address clone) {
        bytes memory createData = _generateMinimalProxyCreateData(_base);

        assembly {
            clone := create(
                0, // no value
                add(createData, 0x20), // data
                55 // data is always 55 bytes (10 constructor + 45 code)
            )
        }

        // If CREATE fails for some reason, address(0) is returned
        require(clone != address(0), _revertMsg);
    }

    function _generateMinimalProxyCreateData(address _base) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                //---- constructor -----
                bytes10(0x3d602d80600a3d3981f3),
                //---- proxy code -----
                bytes10(0x363d3d373d3d3d363d73),
                _base,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Internal references
import "./AddressResolver.sol";

// https://docs.synthetix.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) {
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
    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses) {}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MixinResolver.sol";

// Internal references
import "./interfaces/IFlexibleStorage.sol";

// https://docs.synthetix.io/contracts/source/contracts/mixinsystemsettings
contract MixinSystemSettings is MixinResolver {
    // must match the one defined SystemSettingsLib, defined in both places due to sol v0.5 limitations
    bytes32 internal constant SETTING_CONTRACT_NAME = "SystemSettings";

    bytes32 internal constant SETTING_WAITING_PERIOD_SECS = "waitingPeriodSecs";
    bytes32 internal constant SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR = "priceDeviationThresholdFactor";
    bytes32 internal constant SETTING_ISSUANCE_RATIO = "issuanceRatio";
    bytes32 internal constant SETTING_FEE_PERIOD_DURATION = "feePeriodDuration";
    bytes32 internal constant SETTING_TARGET_THRESHOLD = "targetThreshold";
    bytes32 internal constant SETTING_LIQUIDATION_DELAY = "liquidationDelay";
    bytes32 internal constant SETTING_LIQUIDATION_RATIO = "liquidationRatio";
    bytes32 internal constant SETTING_LIQUIDATION_ESCROW_DURATION = "liquidationEscrowDuration";
    bytes32 internal constant SETTING_LIQUIDATION_PENALTY = "liquidationPenalty";
    bytes32 internal constant SETTING_SNX_LIQUIDATION_PENALTY = "snxLiquidationPenalty";
    bytes32 internal constant SETTING_SELF_LIQUIDATION_PENALTY = "selfLiquidationPenalty";
    bytes32 internal constant SETTING_LIQUIDATION_FIX_FACTOR = "liquidationFixFactor";
    bytes32 internal constant SETTING_FLAG_REWARD = "flagReward";
    bytes32 internal constant SETTING_LIQUIDATE_REWARD = "liquidateReward";
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
    bytes32 internal constant SETTING_CROSS_DOMAIN_FEE_PERIOD_CLOSE_GAS_LIMIT = "crossDomainCloseGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_RELAY_GAS_LIMIT = "crossDomainRelayGasLimit";
    bytes32 internal constant SETTING_INTERACTION_DELAY = "interactionDelay";
    bytes32 internal constant SETTING_COLLAPSE_FEE_RATE = "collapseFeeRate";
    bytes32 internal constant SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK = "atomicMaxVolumePerBlock";
    bytes32 internal constant SETTING_ATOMIC_TWAP_WINDOW = "atomicTwapWindow";
    bytes32 internal constant SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING = "atomicEquivalentForDexPricing";
    bytes32 internal constant SETTING_ATOMIC_EXCHANGE_FEE_RATE = "atomicExchangeFeeRate";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = "atomicVolConsiderationWindow";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD = "atomicVolUpdateThreshold";
    bytes32 internal constant SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED = "pureChainlinkForAtomicsEnabled";
    bytes32 internal constant SETTING_CROSS_SYNTH_TRANSFER_ENABLED = "crossChainSynthTransferEnabled";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    enum CrossDomainMessageGasLimits {
        Deposit,
        Escrow,
        Reward,
        Withdrawal,
        CloseFeePeriod,
        Relay
    }

    struct DynamicFeeConfig {
        uint256 threshold;
        uint256 weightDecay;
        uint256 rounds;
        uint256 maxFee;
    }

    constructor(address _resolver) MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view virtual override returns (bytes32[] memory addresses) {
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
        } else if (gasLimitType == CrossDomainMessageGasLimits.CloseFeePeriod) {
            return SETTING_CROSS_DOMAIN_FEE_PERIOD_CLOSE_GAS_LIMIT;
        } else {
            revert("Unknown gas limit type");
        }
    }

    function getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits gasLimitType) internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, _getGasLimitSetting(gasLimitType));
    }

    function getTradingRewardsEnabled() internal view returns (bool) {
        return flexibleStorage().getBoolValue(SETTING_CONTRACT_NAME, SETTING_TRADING_REWARDS_ENABLED);
    }

    function getWaitingPeriodSecs() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_WAITING_PERIOD_SECS);
    }

    function getPriceDeviationThresholdFactor() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR);
    }

    function getIssuanceRatio() internal view returns (uint256) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ISSUANCE_RATIO);
    }

    function getFeePeriodDuration() internal view returns (uint256) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_FEE_PERIOD_DURATION);
    }

    function getTargetThreshold() internal view returns (uint256) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_TARGET_THRESHOLD);
    }

    function getLiquidationDelay() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_DELAY);
    }

    function getLiquidationRatio() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_RATIO);
    }

    function getLiquidationEscrowDuration() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_ESCROW_DURATION);
    }

    function getLiquidationPenalty() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_PENALTY);
    }

    function getSnxLiquidationPenalty() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_SNX_LIQUIDATION_PENALTY);
    }

    function getSelfLiquidationPenalty() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_SELF_LIQUIDATION_PENALTY);
    }

    function getFlagReward() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_FLAG_REWARD);
    }

    function getLiquidateReward() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATE_REWARD);
    }

    function getLiquidationFixFactor() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FIX_FACTOR);
    }

    function getRateStalePeriod() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_RATE_STALE_PERIOD);
    }

    /* ========== Exchange Related Fees ========== */
    function getExchangeFeeRate(bytes32 currencyKey) internal view returns (uint256) {
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
        uint256[] memory values = flexibleStorage().getUIntValues(SETTING_CONTRACT_NAME, keys);
        return DynamicFeeConfig({threshold: values[0], weightDecay: values[1], rounds: values[2], maxFee: values[3]});
    }

    /* ========== End Exchange Related Fees ========== */

    function getMinimumStakeTime() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MINIMUM_STAKE_TIME);
    }

    function getAggregatorWarningFlags() internal view returns (address) {
        return flexibleStorage().getAddressValue(SETTING_CONTRACT_NAME, SETTING_AGGREGATOR_WARNING_FLAGS);
    }

    function getDebtSnapshotStaleTime() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_DEBT_SNAPSHOT_STALE_TIME);
    }

    function getInteractionDelay(address collateral) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_INTERACTION_DELAY, collateral))
            );
    }

    function getCollapseFeeRate(address collateral) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_COLLAPSE_FEE_RATE, collateral))
            );
    }

    function getAtomicMaxVolumePerBlock() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK);
    }

    function getAtomicTwapWindow() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_TWAP_WINDOW);
    }

    function getAtomicEquivalentForDexPricing(bytes32 currencyKey) internal view returns (address) {
        return
            flexibleStorage().getAddressValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING, currencyKey))
            );
    }

    function getAtomicExchangeFeeRate(bytes32 currencyKey) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    function getAtomicVolatilityConsiderationWindow(bytes32 currencyKey) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW, currencyKey))
            );
    }

    function getAtomicVolatilityUpdateThreshold(bytes32 currencyKey) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD, currencyKey))
            );
    }

    function getPureChainlinkPriceForAtomicSwapsEnabled(bytes32 currencyKey) internal view returns (bool) {
        return
            flexibleStorage().getBoolValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED, currencyKey))
            );
    }

    function getCrossChainSynthTransferEnabled(bytes32 currencyKey) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_CROSS_SYNTH_TRANSFER_ENABLED, currencyKey))
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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