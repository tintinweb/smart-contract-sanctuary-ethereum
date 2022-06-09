/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: migrations/Migration_Saiph.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/migrations/Migration_Saiph.sol
* Docs: https://docs.synthetix.io/contracts/migrations/Migration_Saiph
*
* Contract Dependencies: 
*	- BaseMigration
*	- ExternStateToken
*	- IAddressResolver
*	- IERC20
*	- IIssuer
*	- IRewardEscrow
*	- IRewardsDistribution
*	- ISynth
*	- ISystemStatus
*	- LegacyOwned
*	- MixinResolver
*	- MixinSystemSettings
*	- Owned
*	- Proxy
*	- Proxyable
*	- State
*	- Synth
* Libraries: 
*	- SafeCast
*	- SafeDecimalMath
*	- SafeMath
*	- VestingEntries
*
* MIT License
* ===========
*
* Copyright (c) 2022 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



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

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


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

    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint);

    function transferableSynthetixAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    // Restricted: used internally to Synthetix
    function addSynths(ISynth[] calldata synthsToAdd) external;

    function issueSynths(address from, uint amount) external;

    function issueSynthsOnBehalf(
        address issueFor,
        address from,
        uint amount
    ) external;

    function issueMaxSynths(address from) external;

    function issueMaxSynthsOnBehalf(address issueFor, address from) external;

    function burnSynths(address from, uint amount) external;

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external;

    function burnSynthsToTarget(address from) external;

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint balance
    ) external;

    function setCurrentPeriodId(uint128 periodId) external;

    function liquidateAccount(address account, bool isSelfLiquidation)
        external
        returns (uint totalRedeemed, uint amountToLiquidate);

    function issueSynthsWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function burnSynthsWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);
}


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
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

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
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


// Inheritance


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
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


contract BaseMigration is Owned {
    constructor(address _owner) internal Owned(_owner) {}

    // safety value to return ownership (anyone can invoke)
    function returnOwnership(address forContract) public {
        bytes memory payload = abi.encodeWithSignature("nominateNewOwner(address)", owner);

        // solhint-disable avoid-low-level-calls
        (bool success, ) = forContract.call(payload);

        if (!success) {
            // then try legacy way
            bytes memory legacyPayload = abi.encodeWithSignature("nominateOwner(address)", owner);

            // solhint-disable avoid-low-level-calls
            (bool legacySuccess, ) = forContract.call(legacyPayload);

            require(legacySuccess, "Legacy nomination failed");
        }
    }
}


// https://docs.synthetix.io/contracts/source/interfaces/iflexiblestorage
interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int[] memory);

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
        uint value
    ) external;

    function setUIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        uint[] calldata values
    ) external;

    function setIntValue(
        bytes32 contractName,
        bytes32 record,
        int value
    ) external;

    function setIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        int[] calldata values
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


// Internal references


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
    bytes32 internal constant SETTING_SELF_LIQUIDATION_PENALTY = "selfLiquidationPenalty";
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
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = "atomicVolConsiderationWindow";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD = "atomicVolUpdateThreshold";
    bytes32 internal constant SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED = "pureChainlinkForAtomicsEnabled";
    bytes32 internal constant SETTING_CROSS_SYNTH_TRANSFER_ENABLED = "crossChainSynthTransferEnabled";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    enum CrossDomainMessageGasLimits {Deposit, Escrow, Reward, Withdrawal, CloseFeePeriod, Relay}

    struct DynamicFeeConfig {
        uint threshold;
        uint weightDecay;
        uint rounds;
        uint maxFee;
    }

    constructor(address _resolver) internal MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
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

    function getLiquidationEscrowDuration() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_ESCROW_DURATION);
    }

    function getLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_PENALTY);
    }

    function getSelfLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_SELF_LIQUIDATION_PENALTY);
    }

    function getFlagReward() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_FLAG_REWARD);
    }

    function getLiquidateReward() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATE_REWARD);
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

    function getPureChainlinkPriceForAtomicSwapsEnabled(bytes32 currencyKey) internal view returns (bool) {
        return
            flexibleStorage().getBoolValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED, currencyKey))
            );
    }

    function getCrossChainSynthTransferEnabled(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_CROSS_SYNTH_TRANSFER_ENABLED, currencyKey))
            );
    }
}


// SPDX-License-Identifier: MIT


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
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
        require(value < 2**128, "SafeCast: value doesn't fit in 128 bits");
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
        require(value < 2**64, "SafeCast: value doesn't fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn't fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn't fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn't fit in 8 bits");
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


// Libraries


// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
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


interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/isynthetix
interface ISynthetix {
    // Views
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint);

    function totalIssuedSynthsExcludeOtherCollateral(bytes32 currencyKey) external view returns (uint);

    function transferableSynthetix(address account) external view returns (uint transferable);

    // Mutative Functions
    function burnSynths(uint amount) external;

    function burnSynthsOnBehalf(address burnForAddress, uint amount) external;

    function burnSynthsToTarget() external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualSynth vSynth);

    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint minAmount
    ) external returns (uint amountReceived);

    function issueMaxSynths() external;

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function issueSynths(uint amount) external;

    function issueSynthsOnBehalf(address issueForAddress, uint amount) external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account) external returns (bool);

    function liquidateSelf() external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/ifeepool
interface IFeePool {
    // Views

    // solhint-disable-next-line func-name-mixedcase
    function FEE_ADDRESS() external view returns (address);

    function feesAvailable(address account) external view returns (uint, uint);

    function feePeriodDuration() external view returns (uint);

    function isFeesClaimable(address account) external view returns (bool);

    function targetThreshold() external view returns (uint);

    function totalFeesAvailable() external view returns (uint);

    function totalRewardsAvailable() external view returns (uint);

    // Mutative Functions
    function claimFees() external returns (bool);

    function claimOnBehalf(address claimingForAddress) external returns (bool);

    function closeCurrentFeePeriod() external;

    function closeSecondary(uint snxBackedDebt, uint debtShareSupply) external;

    function recordFeePaid(uint sUSDAmount) external;

    function setRewardsToDistribute(uint amount) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/isynthetixdebtshare
interface ISynthetixDebtShare {
    // Views

    function currentPeriodId() external view returns (uint128);

    function allowance(address account, address spender) external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function balanceOfOnPeriod(address account, uint periodId) external view returns (uint);

    function totalSupply() external view returns (uint);

    function sharePercent(address account) external view returns (uint);

    function sharePercentOnPeriod(address account, uint periodId) external view returns (uint);

    // Mutative functions

    function takeSnapshot(uint128 id) external;

    function mintShare(address account, uint256 amount) external;

    function burnShare(address account, uint256 amount) external;

    function approve(address, uint256) external pure returns (bool);

    function transfer(address to, uint256 amount) external pure returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function addAuthorizedBroker(address target) external;

    function removeAuthorizedBroker(address target) external;

    function addAuthorizedToSnapshot(address target) external;

    function removeAuthorizedToSnapshot(address target) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    struct ExchangeEntrySettlement {
        bytes32 src;
        uint amount;
        bytes32 dest;
        uint reclaim;
        uint rebate;
        uint srcRoundIdAtPeriodEnd;
        uint destRoundIdAtPeriodEnd;
        uint timestamp;
    }

    struct ExchangeEntry {
        uint sourceRate;
        uint destinationRate;
        uint destinationAmount;
        uint exchangeFeeRate;
        uint exchangeDynamicFeeRate;
        uint roundIdForSrc;
        uint roundIdForDest;
    }

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

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint);

    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint feeRate, bool tooVolatile);

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

    function lastExchangeRate(bytes32 currencyKey) external view returns (uint);

    // Mutative functions
    function exchange(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool virtualSynth,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualSynth vSynth);

    function exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bytes32 trackingCode,
        uint minAmount
    ) external returns (uint amountReceived);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/idelegateapprovals
interface IDelegateApprovals {
    // Views
    function canBurnFor(address authoriser, address delegate) external view returns (bool);

    function canIssueFor(address authoriser, address delegate) external view returns (bool);

    function canClaimFor(address authoriser, address delegate) external view returns (bool);

    function canExchangeFor(address authoriser, address delegate) external view returns (bool);

    // Mutative
    function approveAllDelegatePowers(address delegate) external;

    function removeAllDelegatePowers(address delegate) external;

    function approveBurnOnBehalf(address delegate) external;

    function removeBurnOnBehalf(address delegate) external;

    function approveIssueOnBehalf(address delegate) external;

    function removeIssueOnBehalf(address delegate) external;

    function approveClaimOnBehalf(address delegate) external;

    function removeClaimOnBehalf(address delegate) external;

    function approveExchangeOnBehalf(address delegate) external;

    function removeExchangeOnBehalf(address delegate) external;
}


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

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value);

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
        );

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        );

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint numRounds,
        uint roundId
    ) external view returns (uint[] memory rates, uint[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);
}


// https://docs.synthetix.io/contracts/source/interfaces/ihasbalance
interface IHasBalance {
    // Views
    function balanceOf(address account) external view returns (uint);
}


// https://docs.synthetix.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


interface ILiquidator {
    // Views
    function issuanceRatio() external view returns (uint);

    function liquidationDelay() external view returns (uint);

    function liquidationRatio() external view returns (uint);

    function liquidationEscrowDuration() external view returns (uint);

    function liquidationPenalty() external view returns (uint);

    function selfLiquidationPenalty() external view returns (uint);

    function liquidateReward() external view returns (uint);

    function flagReward() external view returns (uint);

    function liquidationCollateralRatio() external view returns (uint);

    function getLiquidationDeadlineForAccount(address account) external view returns (uint);

    function getLiquidationCallerForAccount(address account) external view returns (address);

    function isLiquidationOpen(address account, bool isSelfLiquidation) external view returns (bool);

    function isLiquidationDeadlinePassed(address account) external view returns (bool);

    function calculateAmountToFixCollateral(
        uint debtBalance,
        uint collateral,
        uint penalty
    ) external view returns (uint);

    // Mutative Functions
    function flagAccountForLiquidation(address account) external;

    // Restricted: used internally to Synthetix contracts
    function removeAccountInLiquidation(address account) external;

    function checkAndRemoveAccountInLiquidation(address account) external;
}


interface ILiquidatorRewards {
    // Views

    function earned(address account) external view returns (uint256);

    // Mutative

    function getReward(address account) external;

    function notifyRewardAmount(uint256 reward) external;

    function updateEntry(address account) external;
}


interface ICollateralManager {
    // Manager information
    function hasCollateral(address collateral) external view returns (bool);

    function isSynthManaged(bytes32 currencyKey) external view returns (bool);

    // State information
    function long(bytes32 synth) external view returns (uint amount);

    function short(bytes32 synth) external view returns (uint amount);

    function totalLong() external view returns (uint susdValue, bool anyRateIsInvalid);

    function totalShort() external view returns (uint susdValue, bool anyRateIsInvalid);

    function getBorrowRate() external view returns (uint borrowRate, bool anyRateIsInvalid);

    function getShortRate(bytes32 synth) external view returns (uint shortRate, bool rateIsInvalid);

    function getRatesAndTime(uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        );

    function getShortRatesAndTime(bytes32 currency, uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        );

    function exceedsDebtLimit(uint amount, bytes32 currency) external view returns (bool canIssue, bool anyRateIsInvalid);

    function areSynthsAndCurrenciesSet(bytes32[] calldata requiredSynthNamesInResolver, bytes32[] calldata synthKeys)
        external
        view
        returns (bool);

    function areShortableSynthsSet(bytes32[] calldata requiredSynthNamesInResolver, bytes32[] calldata synthKeys)
        external
        view
        returns (bool);

    // Loans
    function getNewLoanId() external returns (uint id);

    // Manager mutative
    function addCollaterals(address[] calldata collaterals) external;

    function removeCollaterals(address[] calldata collaterals) external;

    function addSynths(bytes32[] calldata synthNamesInResolver, bytes32[] calldata synthKeys) external;

    function removeSynths(bytes32[] calldata synths, bytes32[] calldata synthKeys) external;

    function addShortableSynths(bytes32[] calldata requiredSynthNamesInResolver, bytes32[] calldata synthKeys) external;

    function removeShortableSynths(bytes32[] calldata synths) external;

    // State mutative

    function incrementLongs(bytes32 synth, uint amount) external;

    function decrementLongs(bytes32 synth, uint amount) external;

    function incrementShorts(bytes32 synth, uint amount) external;

    function decrementShorts(bytes32 synth, uint amount) external;

    function accrueInterest(
        uint interestIndex,
        bytes32 currency,
        bool isShort
    ) external returns (uint difference, uint index);

    function updateBorrowRatesCollateral(uint rate) external;

    function updateShortRatesCollateral(bytes32 currency, uint rate) external;
}


pragma experimental ABIEncoderV2;

library VestingEntries {
    struct VestingEntry {
        uint64 endTime;
        uint256 escrowAmount;
    }
    struct VestingEntryWithID {
        uint64 endTime;
        uint256 escrowAmount;
        uint256 entryID;
    }
}

interface IRewardEscrowV2 {
    // Views
    function balanceOf(address account) external view returns (uint);

    function numVestingEntries(address account) external view returns (uint);

    function totalEscrowedAccountBalance(address account) external view returns (uint);

    function totalVestedAccountBalance(address account) external view returns (uint);

    function getVestingQuantity(address account, uint256[] calldata entryIDs) external view returns (uint);

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory);

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory);

    function getVestingEntryClaimable(address account, uint256 entryID) external view returns (uint);

    function getVestingEntry(address account, uint256 entryID) external view returns (uint64, uint256);

    // Mutative functions
    function vest(uint256[] calldata entryIDs) external;

    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) external;

    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external;

    function migrateVestingSchedule(address _addressToMigrate) external;

    function migrateAccountEscrowBalances(
        address[] calldata accounts,
        uint256[] calldata escrowBalances,
        uint256[] calldata vestedBalances
    ) external;

    // Account Merging
    function startMergingWindow() external;

    function mergeAccount(address accountToMerge, uint256[] calldata entryIDs) external;

    function nominateAccountToMerge(address account) external;

    function accountMergingIsOpen() external view returns (bool);

    // L2 Migration
    function importVestingEntries(
        address account,
        uint256 escrowedAmount,
        VestingEntries.VestingEntry[] calldata vestingEntries
    ) external;

    // Return amount of SNX transfered to SynthetixBridgeToOptimism deposit contract
    function burnForMigration(address account, uint256[] calldata entryIDs)
        external
        returns (uint256 escrowedAccountBalance, VestingEntries.VestingEntry[] memory vestingEntries);
}


interface ISynthRedeemer {
    // Rate of redemption - 0 for none
    function redemptions(address synthProxy) external view returns (uint redeemRate);

    // sUSD balance of deprecated token holder
    function balanceOf(IERC20 synthProxy, address account) external view returns (uint balanceOfInsUSD);

    // Full sUSD supply of token
    function totalSupply(IERC20 synthProxy) external view returns (uint totalSupplyInsUSD);

    function redeem(IERC20 synthProxy) external;

    function redeemAll(IERC20[] calldata synthProxies) external;

    function redeemPartial(IERC20 synthProxy, uint amountOfSynth) external;

    // Restricted to Issuer
    function deprecate(IERC20 synthProxy, uint rateToRedeem) external;
}


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


// Inheritance


// Internal references


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
        uint numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint size = callData.length;
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

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}


// Inheritance


// Internal references


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

    modifier onlyProxy {
        _onlyProxy();
        _;
    }

    function _onlyProxy() private view {
        require(Proxy(msg.sender) == proxy, "Only the proxy can call");
    }

    modifier optionalProxy {
        _optionalProxy();
        _;
    }

    function _optionalProxy() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
    }

    modifier optionalProxy_onlyOwner {
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


interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


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


/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface AggregatorV2V3Interface {
  //
  // V2 Interface:
  //
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

  //
  // V3 Interface:
  //
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


// Inheritance


// Libraries


// Internal references


interface IProxy {
    function target() external view returns (address);
}

interface IIssuerInternalDebtCache {
    function updateCachedSynthDebtWithRate(bytes32 currencyKey, uint currencyRate) external;

    function updateCachedSynthDebtsWithRates(bytes32[] calldata currencyKeys, uint[] calldata currencyRates) external;

    function updateDebtCacheValidity(bool currentlyInvalid) external;

    function totalNonSnxBackedDebt() external view returns (uint excludedDebt, bool isInvalid);

    function cacheInfo()
        external
        view
        returns (
            uint cachedDebt,
            uint timestamp,
            bool isInvalid,
            bool isStale
        );

    function updateCachedsUSDDebt(int amount) external;
}

// https://docs.synthetix.io/contracts/source/contracts/issuer
contract Issuer is Owned, MixinSystemSettings, IIssuer {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "Issuer";

    // SIP-165: Circuit breaker for Debt Synthesis
    uint public constant CIRCUIT_BREAKER_SUSPENSION_REASON = 165;

    // Available Synths which can be used with the system
    ISynth[] public availableSynths;
    mapping(bytes32 => ISynth) public synths;
    mapping(address => bytes32) public synthsByAddress;

    uint public lastDebtRatio;

    /* ========== ENCODED NAMES ========== */

    bytes32 internal constant sUSD = "sUSD";
    bytes32 internal constant sETH = "sETH";
    bytes32 internal constant SNX = "SNX";

    // Flexible storage names

    bytes32 internal constant LAST_ISSUE_EVENT = "lastIssueEvent";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_SYNTHETIXDEBTSHARE = "SynthetixDebtShare";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_DELEGATEAPPROVALS = "DelegateApprovals";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_SYNTHETIXESCROW = "SynthetixEscrow";
    bytes32 private constant CONTRACT_LIQUIDATOR = "Liquidator";
    bytes32 private constant CONTRACT_LIQUIDATOR_REWARDS = "LiquidatorRewards";
    bytes32 private constant CONTRACT_DEBTCACHE = "DebtCache";
    bytes32 private constant CONTRACT_SYNTHREDEEMER = "SynthRedeemer";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_SYNTHETIXBRIDGETOOPTIMISM = "SynthetixBridgeToOptimism";
    bytes32 private constant CONTRACT_SYNTHETIXBRIDGETOBASE = "SynthetixBridgeToBase";

    bytes32 private constant CONTRACT_EXT_AGGREGATOR_ISSUED_SYNTHS = "ext:AggregatorIssuedSynths";
    bytes32 private constant CONTRACT_EXT_AGGREGATOR_DEBT_RATIO = "ext:AggregatorDebtRatio";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](15);
        newAddresses[0] = CONTRACT_SYNTHETIX;
        newAddresses[1] = CONTRACT_EXCHANGER;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_SYNTHETIXDEBTSHARE;
        newAddresses[4] = CONTRACT_FEEPOOL;
        newAddresses[5] = CONTRACT_DELEGATEAPPROVALS;
        newAddresses[6] = CONTRACT_REWARDESCROW_V2;
        newAddresses[7] = CONTRACT_SYNTHETIXESCROW;
        newAddresses[8] = CONTRACT_LIQUIDATOR;
        newAddresses[9] = CONTRACT_LIQUIDATOR_REWARDS;
        newAddresses[10] = CONTRACT_DEBTCACHE;
        newAddresses[11] = CONTRACT_SYNTHREDEEMER;
        newAddresses[12] = CONTRACT_SYSTEMSTATUS;
        newAddresses[13] = CONTRACT_EXT_AGGREGATOR_ISSUED_SYNTHS;
        newAddresses[14] = CONTRACT_EXT_AGGREGATOR_DEBT_RATIO;
        return combineArrays(existingAddresses, newAddresses);
    }

    function synthetix() internal view returns (ISynthetix) {
        return ISynthetix(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function synthetixDebtShare() internal view returns (ISynthetixDebtShare) {
        return ISynthetixDebtShare(requireAndGetAddress(CONTRACT_SYNTHETIXDEBTSHARE));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function liquidator() internal view returns (ILiquidator) {
        return ILiquidator(requireAndGetAddress(CONTRACT_LIQUIDATOR));
    }

    function liquidatorRewards() internal view returns (ILiquidatorRewards) {
        return ILiquidatorRewards(requireAndGetAddress(CONTRACT_LIQUIDATOR_REWARDS));
    }

    function delegateApprovals() internal view returns (IDelegateApprovals) {
        return IDelegateApprovals(requireAndGetAddress(CONTRACT_DELEGATEAPPROVALS));
    }

    function rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(requireAndGetAddress(CONTRACT_REWARDESCROW_V2));
    }

    function synthetixEscrow() internal view returns (IHasBalance) {
        return IHasBalance(requireAndGetAddress(CONTRACT_SYNTHETIXESCROW));
    }

    function debtCache() internal view returns (IIssuerInternalDebtCache) {
        return IIssuerInternalDebtCache(requireAndGetAddress(CONTRACT_DEBTCACHE));
    }

    function synthRedeemer() internal view returns (ISynthRedeemer) {
        return ISynthRedeemer(requireAndGetAddress(CONTRACT_SYNTHREDEEMER));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function allNetworksDebtInfo()
        public
        view
        returns (
            uint256 debt,
            uint256 sharesSupply,
            bool isStale
        )
    {
        (, int256 rawIssuedSynths, , uint issuedSynthsUpdatedAt, ) =
            AggregatorV2V3Interface(requireAndGetAddress(CONTRACT_EXT_AGGREGATOR_ISSUED_SYNTHS)).latestRoundData();

        (, int256 rawRatio, , uint ratioUpdatedAt, ) =
            AggregatorV2V3Interface(requireAndGetAddress(CONTRACT_EXT_AGGREGATOR_DEBT_RATIO)).latestRoundData();

        debt = uint(rawIssuedSynths);
        sharesSupply = rawRatio == 0 ? 0 : debt.divideDecimalRoundPrecise(uint(rawRatio));
        isStale =
            block.timestamp - getRateStalePeriod() > issuedSynthsUpdatedAt ||
            block.timestamp - getRateStalePeriod() > ratioUpdatedAt;
    }

    function issuanceRatio() external view returns (uint) {
        return getIssuanceRatio();
    }

    function _sharesForDebt(uint debtAmount) internal view returns (uint) {
        (, int256 rawRatio, , , ) =
            AggregatorV2V3Interface(requireAndGetAddress(CONTRACT_EXT_AGGREGATOR_DEBT_RATIO)).latestRoundData();

        return rawRatio == 0 ? 0 : debtAmount.divideDecimalRoundPrecise(uint(rawRatio));
    }

    function _debtForShares(uint sharesAmount) internal view returns (uint) {
        (, int256 rawRatio, , , ) =
            AggregatorV2V3Interface(requireAndGetAddress(CONTRACT_EXT_AGGREGATOR_DEBT_RATIO)).latestRoundData();

        return sharesAmount.multiplyDecimalRoundPrecise(uint(rawRatio));
    }

    function _availableCurrencyKeysWithOptionalSNX(bool withSNX) internal view returns (bytes32[] memory) {
        bytes32[] memory currencyKeys = new bytes32[](availableSynths.length + (withSNX ? 1 : 0));

        for (uint i = 0; i < availableSynths.length; i++) {
            currencyKeys[i] = synthsByAddress[address(availableSynths[i])];
        }

        if (withSNX) {
            currencyKeys[availableSynths.length] = SNX;
        }

        return currencyKeys;
    }

    // Returns the total value of the debt pool in currency specified by `currencyKey`.
    // To return only the SNX-backed debt, set `excludeCollateral` to true.
    function _totalIssuedSynths(bytes32 currencyKey, bool excludeCollateral)
        internal
        view
        returns (uint totalIssued, bool anyRateIsInvalid)
    {
        (uint debt, , bool cacheIsInvalid, bool cacheIsStale) = debtCache().cacheInfo();
        anyRateIsInvalid = cacheIsInvalid || cacheIsStale;

        IExchangeRates exRates = exchangeRates();

        // Add total issued synths from non snx collateral back into the total if not excluded
        if (!excludeCollateral) {
            (uint nonSnxDebt, bool invalid) = debtCache().totalNonSnxBackedDebt();
            debt = debt.add(nonSnxDebt);
            anyRateIsInvalid = anyRateIsInvalid || invalid;
        }

        if (currencyKey == sUSD) {
            return (debt, anyRateIsInvalid);
        }

        (uint currencyRate, bool currencyRateInvalid) = exRates.rateAndInvalid(currencyKey);
        return (debt.divideDecimalRound(currencyRate), anyRateIsInvalid || currencyRateInvalid);
    }

    function _debtBalanceOfAndTotalDebt(uint debtShareBalance, bytes32 currencyKey)
        internal
        view
        returns (
            uint debtBalance,
            uint totalSystemValue,
            bool anyRateIsInvalid
        )
    {
        // What's the total value of the system excluding ETH backed synths in their requested currency?
        (uint snxBackedAmount, , bool debtInfoStale) = allNetworksDebtInfo();

        if (debtShareBalance == 0) {
            return (0, snxBackedAmount, debtInfoStale);
        }

        // existing functionality requires for us to convert into the exchange rate specified by `currencyKey`
        (uint currencyRate, bool currencyRateInvalid) = exchangeRates().rateAndInvalid(currencyKey);

        debtBalance = _debtForShares(debtShareBalance).divideDecimalRound(currencyRate);
        totalSystemValue = snxBackedAmount;

        anyRateIsInvalid = currencyRateInvalid || debtInfoStale;
    }

    function _canBurnSynths(address account) internal view returns (bool) {
        return now >= _lastIssueEvent(account).add(getMinimumStakeTime());
    }

    function _lastIssueEvent(address account) internal view returns (uint) {
        //  Get the timestamp of the last issue this account made
        return flexibleStorage().getUIntValue(CONTRACT_NAME, keccak256(abi.encodePacked(LAST_ISSUE_EVENT, account)));
    }

    function _remainingIssuableSynths(address _issuer)
        internal
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt,
            bool anyRateIsInvalid
        )
    {
        (alreadyIssued, totalSystemDebt, anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(
            synthetixDebtShare().balanceOf(_issuer),
            sUSD
        );
        (uint issuable, bool isInvalid) = _maxIssuableSynths(_issuer);
        maxIssuable = issuable;
        anyRateIsInvalid = anyRateIsInvalid || isInvalid;

        if (alreadyIssued >= maxIssuable) {
            maxIssuable = 0;
        } else {
            maxIssuable = maxIssuable.sub(alreadyIssued);
        }
    }

    function _snxToUSD(uint amount, uint snxRate) internal pure returns (uint) {
        return amount.multiplyDecimalRound(snxRate);
    }

    function _usdToSnx(uint amount, uint snxRate) internal pure returns (uint) {
        return amount.divideDecimalRound(snxRate);
    }

    function _maxIssuableSynths(address _issuer) internal view returns (uint, bool) {
        // What is the value of their SNX balance in sUSD
        (uint snxRate, bool isInvalid) = exchangeRates().rateAndInvalid(SNX);
        uint destinationValue = _snxToUSD(_collateral(_issuer), snxRate);

        // They're allowed to issue up to issuanceRatio of that value
        return (destinationValue.multiplyDecimal(getIssuanceRatio()), isInvalid);
    }

    function _collateralisationRatio(address _issuer) internal view returns (uint, bool) {
        uint totalOwnedSynthetix = _collateral(_issuer);

        (uint debtBalance, , bool anyRateIsInvalid) =
            _debtBalanceOfAndTotalDebt(synthetixDebtShare().balanceOf(_issuer), SNX);

        // it's more gas intensive to put this check here if they have 0 SNX, but it complies with the interface
        if (totalOwnedSynthetix == 0) return (0, anyRateIsInvalid);

        return (debtBalance.divideDecimalRound(totalOwnedSynthetix), anyRateIsInvalid);
    }

    function _collateral(address account) internal view returns (uint) {
        uint balance = IERC20(address(synthetix())).balanceOf(account);

        if (address(synthetixEscrow()) != address(0)) {
            balance = balance.add(synthetixEscrow().balanceOf(account));
        }

        if (address(rewardEscrowV2()) != address(0)) {
            balance = balance.add(rewardEscrowV2().balanceOf(account));
        }

        if (address(liquidatorRewards()) != address(0)) {
            balance = balance.add(liquidatorRewards().earned(account));
        }

        return balance;
    }

    function minimumStakeTime() external view returns (uint) {
        return getMinimumStakeTime();
    }

    function canBurnSynths(address account) external view returns (bool) {
        return _canBurnSynths(account);
    }

    function availableCurrencyKeys() external view returns (bytes32[] memory) {
        return _availableCurrencyKeysWithOptionalSNX(false);
    }

    function availableSynthCount() external view returns (uint) {
        return availableSynths.length;
    }

    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid) {
        (, anyRateInvalid) = exchangeRates().ratesAndInvalidForCurrencies(_availableCurrencyKeysWithOptionalSNX(true));
    }

    function totalIssuedSynths(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint totalIssued) {
        (totalIssued, ) = _totalIssuedSynths(currencyKey, excludeOtherCollateral);
    }

    function lastIssueEvent(address account) external view returns (uint) {
        return _lastIssueEvent(account);
    }

    function collateralisationRatio(address _issuer) external view returns (uint cratio) {
        (cratio, ) = _collateralisationRatio(_issuer);
    }

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid)
    {
        return _collateralisationRatio(_issuer);
    }

    function collateral(address account) external view returns (uint) {
        return _collateral(account);
    }

    function debtBalanceOf(address _issuer, bytes32 currencyKey) external view returns (uint debtBalance) {
        ISynthetixDebtShare sds = synthetixDebtShare();

        // What was their initial debt ownership?
        uint debtShareBalance = sds.balanceOf(_issuer);

        // If it's zero, they haven't issued, and they have no debt.
        if (debtShareBalance == 0) return 0;

        (debtBalance, , ) = _debtBalanceOfAndTotalDebt(debtShareBalance, currencyKey);
    }

    function remainingIssuableSynths(address _issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        )
    {
        (maxIssuable, alreadyIssued, totalSystemDebt, ) = _remainingIssuableSynths(_issuer);
    }

    function maxIssuableSynths(address _issuer) external view returns (uint) {
        (uint maxIssuable, ) = _maxIssuableSynths(_issuer);
        return maxIssuable;
    }

    function transferableSynthetixAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid)
    {
        // How many SNX do they have, excluding escrow?
        // Note: We're excluding escrow here because we're interested in their transferable amount
        // and escrowed SNX are not transferable.

        // How many of those will be locked by the amount they've issued?
        // Assuming issuance ratio is 20%, then issuing 20 SNX of value would require
        // 100 SNX to be locked in their wallet to maintain their collateralisation ratio
        // The locked synthetix value can exceed their balance.
        uint debtBalance;
        (debtBalance, , anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(synthetixDebtShare().balanceOf(account), SNX);
        uint lockedSynthetixValue = debtBalance.divideDecimalRound(getIssuanceRatio());

        // If we exceed the balance, no SNX are transferable, otherwise the difference is.
        if (lockedSynthetixValue >= balance) {
            transferable = 0;
        } else {
            transferable = balance.sub(lockedSynthetixValue);
        }
    }

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory) {
        uint numKeys = currencyKeys.length;
        ISynth[] memory addresses = new ISynth[](numKeys);

        for (uint i = 0; i < numKeys; i++) {
            addresses[i] = synths[currencyKeys[i]];
        }

        return addresses;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _addSynth(ISynth synth) internal {
        bytes32 currencyKey = synth.currencyKey();
        require(synths[currencyKey] == ISynth(0), "Synth exists");
        require(synthsByAddress[address(synth)] == bytes32(0), "Synth address already exists");

        availableSynths.push(synth);
        synths[currencyKey] = synth;
        synthsByAddress[address(synth)] = currencyKey;

        emit SynthAdded(currencyKey, address(synth));
    }

    function addSynth(ISynth synth) external onlyOwner {
        _addSynth(synth);
        // Invalidate the cache to force a snapshot to be recomputed. If a synth were to be added
        // back to the system and it still somehow had cached debt, this would force the value to be
        // updated.
        debtCache().updateDebtCacheValidity(true);
    }

    function addSynths(ISynth[] calldata synthsToAdd) external onlyOwner {
        uint numSynths = synthsToAdd.length;
        for (uint i = 0; i < numSynths; i++) {
            _addSynth(synthsToAdd[i]);
        }

        // Invalidate the cache to force a snapshot to be recomputed.
        debtCache().updateDebtCacheValidity(true);
    }

    function _removeSynth(bytes32 currencyKey) internal {
        address synthToRemove = address(synths[currencyKey]);
        require(synthToRemove != address(0), "Synth does not exist");
        require(currencyKey != sUSD, "Cannot remove synth");

        uint synthSupply = IERC20(synthToRemove).totalSupply();

        if (synthSupply > 0) {
            (uint amountOfsUSD, uint rateToRedeem, ) =
                exchangeRates().effectiveValueAndRates(currencyKey, synthSupply, "sUSD");
            require(rateToRedeem > 0, "Cannot remove synth to redeem without rate");
            ISynthRedeemer _synthRedeemer = synthRedeemer();
            synths[sUSD].issue(address(_synthRedeemer), amountOfsUSD);
            // ensure the debt cache is aware of the new sUSD issued
            debtCache().updateCachedsUSDDebt(SafeCast.toInt256(amountOfsUSD));
            _synthRedeemer.deprecate(IERC20(address(Proxyable(address(synthToRemove)).proxy())), rateToRedeem);
        }

        // Remove the synth from the availableSynths array.
        for (uint i = 0; i < availableSynths.length; i++) {
            if (address(availableSynths[i]) == synthToRemove) {
                delete availableSynths[i];

                // Copy the last synth into the place of the one we just deleted
                // If there's only one synth, this is synths[0] = synths[0].
                // If we're deleting the last one, it's also a NOOP in the same way.
                availableSynths[i] = availableSynths[availableSynths.length - 1];

                // Decrease the size of the array by one.
                availableSynths.length--;

                break;
            }
        }

        // And remove it from the synths mapping
        delete synthsByAddress[synthToRemove];
        delete synths[currencyKey];

        emit SynthRemoved(currencyKey, synthToRemove);
    }

    function removeSynth(bytes32 currencyKey) external onlyOwner {
        // Remove its contribution from the debt pool snapshot, and
        // invalidate the cache to force a new snapshot.
        IIssuerInternalDebtCache cache = debtCache();
        cache.updateCachedSynthDebtWithRate(currencyKey, 0);
        cache.updateDebtCacheValidity(true);

        _removeSynth(currencyKey);
    }

    function removeSynths(bytes32[] calldata currencyKeys) external onlyOwner {
        uint numKeys = currencyKeys.length;

        // Remove their contributions from the debt pool snapshot, and
        // invalidate the cache to force a new snapshot.
        IIssuerInternalDebtCache cache = debtCache();
        uint[] memory zeroRates = new uint[](numKeys);
        cache.updateCachedSynthDebtsWithRates(currencyKeys, zeroRates);
        cache.updateDebtCacheValidity(true);

        for (uint i = 0; i < numKeys; i++) {
            _removeSynth(currencyKeys[i]);
        }
    }

    function issueSynthsWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external onlyTrustedMinters returns (bool rateInvalid) {
        require(address(synths[currencyKey]) != address(0), "Issuer: synth doesn't exist");
        require(amount > 0, "Issuer: cannot issue 0 synths");

        // record issue timestamp
        _setLastIssueEvent(to);

        // Create their synths
        synths[currencyKey].issue(to, amount);

        // Account for the issued debt in the cache
        (uint rate, bool rateInvalid) = exchangeRates().rateAndInvalid(currencyKey);
        debtCache().updateCachedsUSDDebt(SafeCast.toInt256(amount.multiplyDecimal(rate)));

        // returned so that the caller can decide what to do if the rate is invalid
        return rateInvalid;
    }

    function burnSynthsWithoutDebt(
        bytes32 currencyKey,
        address from,
        uint amount
    ) external onlyTrustedMinters returns (bool rateInvalid) {
        require(address(synths[currencyKey]) != address(0), "Issuer: synth doesn't exist");
        require(amount > 0, "Issuer: cannot issue 0 synths");

        exchanger().settle(from, currencyKey);

        // Burn some synths
        synths[currencyKey].burn(from, amount);

        // Account for the burnt debt in the cache. If rate is invalid, the user won't be able to exchange
        (uint rate, bool rateInvalid) = exchangeRates().rateAndInvalid(currencyKey);
        debtCache().updateCachedsUSDDebt(-SafeCast.toInt256(amount.multiplyDecimal(rate)));

        // returned so that the caller can decide what to do if the rate is invalid
        return rateInvalid;
    }

    /**
     * Function used to migrate balances from the CollateralShort contract
     * @param short The address of the CollateralShort contract to be upgraded
     * @param amount The amount of sUSD collateral to be burnt
     */
    function upgradeCollateralShort(address short, uint amount) external onlyOwner {
        require(short != address(0), "Issuer: invalid address");
        require(short == resolver.getAddress("CollateralShortLegacy"), "Issuer: wrong short address");
        require(address(synths[sUSD]) != address(0), "Issuer: synth doesn't exist");
        require(amount > 0, "Issuer: cannot burn 0 synths");

        exchanger().settle(short, sUSD);

        synths[sUSD].burn(short, amount);
    }

    function issueSynths(address from, uint amount) external onlySynthetix {
        require(amount > 0, "Issuer: cannot issue 0 synths");

        _issueSynths(from, amount, false);
    }

    function issueMaxSynths(address from) external onlySynthetix {
        _issueSynths(from, 0, true);
    }

    function issueSynthsOnBehalf(
        address issueForAddress,
        address from,
        uint amount
    ) external onlySynthetix {
        _requireCanIssueOnBehalf(issueForAddress, from);
        _issueSynths(issueForAddress, amount, false);
    }

    function issueMaxSynthsOnBehalf(address issueForAddress, address from) external onlySynthetix {
        _requireCanIssueOnBehalf(issueForAddress, from);
        _issueSynths(issueForAddress, 0, true);
    }

    function burnSynths(address from, uint amount) external onlySynthetix {
        _voluntaryBurnSynths(from, amount, false);
    }

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external onlySynthetix {
        _requireCanBurnOnBehalf(burnForAddress, from);
        _voluntaryBurnSynths(burnForAddress, amount, false);
    }

    function burnSynthsToTarget(address from) external onlySynthetix {
        _voluntaryBurnSynths(from, 0, true);
    }

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from) external onlySynthetix {
        _requireCanBurnOnBehalf(burnForAddress, from);
        _voluntaryBurnSynths(burnForAddress, 0, true);
    }

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint balance
    ) external onlySynthRedeemer {
        ISynth(IProxy(deprecatedSynthProxy).target()).burn(account, balance);
    }

    // SIP-148: Upgraded Liquidation Mechanism
    /// @notice This is where the core internal liquidation logic resides. This function can only be invoked by Synthetix.
    /// @param account The account to be liquidated
    /// @param isSelfLiquidation boolean to determine if this is a forced or self-invoked liquidation
    /// @return uint the total amount of collateral (SNX) to redeem
    /// @return uint the amount of debt (sUSD) to burn in order to fix the account's c-ratio
    function liquidateAccount(address account, bool isSelfLiquidation)
        external
        onlySynthetix
        returns (uint totalRedeemed, uint amountToLiquidate)
    {
        require(liquidator().isLiquidationOpen(account, isSelfLiquidation), "Not open for liquidation");

        // Get the penalty for the liquidation type
        uint penalty = isSelfLiquidation ? getSelfLiquidationPenalty() : getLiquidationPenalty();

        // Get the account's debt balance
        (uint debtBalance, , bool anyRateIsInvalid) =
            _debtBalanceOfAndTotalDebt(synthetixDebtShare().balanceOf(account), sUSD);

        // Get the SNX rate
        (uint snxRate, bool snxRateInvalid) = exchangeRates().rateAndInvalid(SNX);
        _requireRatesNotInvalid(anyRateIsInvalid || snxRateInvalid);

        // Get the total amount of SNX collateral (including escrows and rewards)
        uint collateralForAccount = _collateral(account);

        // Calculate the amount of debt to liquidate to fix c-ratio
        amountToLiquidate = liquidator().calculateAmountToFixCollateral(
            debtBalance,
            _snxToUSD(collateralForAccount, snxRate),
            penalty
        );

        // Get the equivalent amount of SNX for the amount to liquidate
        // Note: While amountToLiquidate takes the penalty into account, it does not accommodate for the addition of the penalty in terms of SNX.
        // Therefore, it is correct to add the penalty modification below to the totalRedeemed.
        totalRedeemed = _usdToSnx(amountToLiquidate, snxRate).multiplyDecimal(SafeDecimalMath.unit().add(penalty));

        // The balanceOf here can be considered "transferable" since it's not escrowed,
        // and it is the only SNX that can potentially be transfered if unstaked.
        uint transferableBalance = IERC20(address(synthetix())).balanceOf(account);
        if (totalRedeemed > transferableBalance) {
            // Liquidate the account's debt based on the liquidation penalty.
            amountToLiquidate = amountToLiquidate.multiplyDecimal(transferableBalance).divideDecimal(totalRedeemed);

            // Set totalRedeemed to all transferable collateral.
            // i.e. the value of the account's staking position relative to balanceOf will be unwound.
            totalRedeemed = transferableBalance;
        }

        // Reduce debt shares by amount to liquidate.
        _removeFromDebtRegister(account, amountToLiquidate, debtBalance);

        // Remove liquidation flag
        liquidator().removeAccountInLiquidation(account);
    }

    function setCurrentPeriodId(uint128 periodId) external {
        require(msg.sender == address(feePool()), "Must be fee pool");

        ISynthetixDebtShare sds = synthetixDebtShare();

        if (sds.currentPeriodId() < periodId) {
            sds.takeSnapshot(periodId);
        }
    }

    function setLastDebtRatio(uint256 ratio) external onlyOwner {
        lastDebtRatio = ratio;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _requireRatesNotInvalid(bool anyRateIsInvalid) internal pure {
        require(!anyRateIsInvalid, "A synth or SNX rate is invalid");
    }

    function _requireCanIssueOnBehalf(address issueForAddress, address from) internal view {
        require(delegateApprovals().canIssueFor(issueForAddress, from), "Not approved to act on behalf");
    }

    function _requireCanBurnOnBehalf(address burnForAddress, address from) internal view {
        require(delegateApprovals().canBurnFor(burnForAddress, from), "Not approved to act on behalf");
    }

    function _issueSynths(
        address from,
        uint amount,
        bool issueMax
    ) internal {
        // check breaker
        if (!_verifyCircuitBreaker()) {
            return;
        }

        (uint maxIssuable, , , bool anyRateIsInvalid) = _remainingIssuableSynths(from);
        _requireRatesNotInvalid(anyRateIsInvalid);

        if (!issueMax) {
            require(amount <= maxIssuable, "Amount too large");
        } else {
            amount = maxIssuable;
        }

        // Keep track of the debt they're about to create
        _addToDebtRegister(from, amount);

        // record issue timestamp
        _setLastIssueEvent(from);

        // Create their synths
        synths[sUSD].issue(from, amount);

        // Account for the issued debt in the cache
        debtCache().updateCachedsUSDDebt(SafeCast.toInt256(amount));
    }

    function _burnSynths(
        address debtAccount,
        address burnAccount,
        uint amount,
        uint existingDebt
    ) internal returns (uint amountBurnt) {
        // check breaker
        if (!_verifyCircuitBreaker()) {
            return 0;
        }

        // liquidation requires sUSD to be already settled / not in waiting period

        // If they're trying to burn more debt than they actually owe, rather than fail the transaction, let's just
        // clear their debt and leave them be.
        amountBurnt = existingDebt < amount ? existingDebt : amount;

        // Remove liquidated debt from the ledger
        _removeFromDebtRegister(debtAccount, amountBurnt, existingDebt);

        // synth.burn does a safe subtraction on balance (so it will revert if there are not enough synths).
        synths[sUSD].burn(burnAccount, amountBurnt);

        // Account for the burnt debt in the cache.
        debtCache().updateCachedsUSDDebt(-SafeCast.toInt256(amountBurnt));
    }

    // If burning to target, `amount` is ignored, and the correct quantity of sUSD is burnt to reach the target
    // c-ratio, allowing fees to be claimed. In this case, pending settlements will be skipped as the user
    // will still have debt remaining after reaching their target.
    function _voluntaryBurnSynths(
        address from,
        uint amount,
        bool burnToTarget
    ) internal {
        // check breaker
        if (!_verifyCircuitBreaker()) {
            return;
        }

        if (!burnToTarget) {
            // If not burning to target, then burning requires that the minimum stake time has elapsed.
            require(_canBurnSynths(from), "Minimum stake time not reached");
            // First settle anything pending into sUSD as burning or issuing impacts the size of the debt pool
            (, uint refunded, uint numEntriesSettled) = exchanger().settle(from, sUSD);
            if (numEntriesSettled > 0) {
                amount = exchanger().calculateAmountAfterSettlement(from, sUSD, amount, refunded);
            }
        }

        (uint existingDebt, , bool anyRateIsInvalid) =
            _debtBalanceOfAndTotalDebt(synthetixDebtShare().balanceOf(from), sUSD);
        (uint maxIssuableSynthsForAccount, bool snxRateInvalid) = _maxIssuableSynths(from);
        _requireRatesNotInvalid(anyRateIsInvalid || snxRateInvalid);
        require(existingDebt > 0, "No debt to forgive");

        if (burnToTarget) {
            amount = existingDebt.sub(maxIssuableSynthsForAccount);
        }

        uint amountBurnt = _burnSynths(from, from, amount, existingDebt);

        // Check and remove liquidation if existingDebt after burning is <= maxIssuableSynths
        // Issuance ratio is fixed so should remove any liquidations
        if (existingDebt.sub(amountBurnt) <= maxIssuableSynthsForAccount) {
            liquidator().removeAccountInLiquidation(from);
        }
    }

    function _setLastIssueEvent(address account) internal {
        // Set the timestamp of the last issueSynths
        flexibleStorage().setUIntValue(
            CONTRACT_NAME,
            keccak256(abi.encodePacked(LAST_ISSUE_EVENT, account)),
            block.timestamp
        );
    }

    function _addToDebtRegister(address from, uint amount) internal {
        // important: this has to happen before any updates to user's debt shares
        liquidatorRewards().updateEntry(from);

        ISynthetixDebtShare sds = synthetixDebtShare();

        // it is possible (eg in tests, system initialized with extra debt) to have issued debt without any shares issued
        // in which case, the first account to mint gets the debt. yw.
        uint debtShares = _sharesForDebt(amount);
        if (debtShares == 0) {
            sds.mintShare(from, amount);
        } else {
            sds.mintShare(from, debtShares);
        }
    }

    function _removeFromDebtRegister(
        address from,
        uint debtToRemove,
        uint existingDebt
    ) internal {
        // important: this has to happen before any updates to user's debt shares
        liquidatorRewards().updateEntry(from);

        ISynthetixDebtShare sds = synthetixDebtShare();

        uint currentDebtShare = sds.balanceOf(from);

        if (debtToRemove == existingDebt) {
            sds.burnShare(from, currentDebtShare);
        } else {
            uint sharesToRemove = _sharesForDebt(debtToRemove);
            sds.burnShare(from, sharesToRemove < currentDebtShare ? sharesToRemove : currentDebtShare);
        }
    }

    function _verifyCircuitBreaker() internal returns (bool) {
        (, int256 rawRatio, , , ) =
            AggregatorV2V3Interface(requireAndGetAddress(CONTRACT_EXT_AGGREGATOR_DEBT_RATIO)).latestRoundData();

        uint deviation = _calculateDeviation(lastDebtRatio, uint(rawRatio));

        if (deviation >= getPriceDeviationThresholdFactor()) {
            systemStatus().suspendIssuance(CIRCUIT_BREAKER_SUSPENSION_REASON);
            return false;
        }
        lastDebtRatio = uint(rawRatio);

        return true;
    }

    function _calculateDeviation(uint last, uint fresh) internal pure returns (uint deviation) {
        if (last == 0) {
            deviation = 1;
        } else if (fresh == 0) {
            deviation = uint(-1);
        } else if (last > fresh) {
            deviation = last.divideDecimal(fresh);
        } else {
            deviation = fresh.divideDecimal(last);
        }
    }

    /* ========== MODIFIERS ========== */
    modifier onlySynthetix() {
        require(msg.sender == address(synthetix()), "Issuer: Only the synthetix contract can perform this action");
        _;
    }

    modifier onlyTrustedMinters() {
        address bridgeL1 = resolver.getAddress(CONTRACT_SYNTHETIXBRIDGETOOPTIMISM);
        address bridgeL2 = resolver.getAddress(CONTRACT_SYNTHETIXBRIDGETOBASE);
        require(msg.sender == bridgeL1 || msg.sender == bridgeL2, "Issuer: only trusted minters");
        require(bridgeL1 == address(0) || bridgeL2 == address(0), "Issuer: one minter must be 0x0");
        _;
    }

    function _onlySynthRedeemer() internal view {
        require(msg.sender == address(synthRedeemer()), "Issuer: Only the SynthRedeemer contract can perform this action");
    }

    modifier onlySynthRedeemer() {
        _onlySynthRedeemer();
        _;
    }

    modifier issuanceActive() {
        _issuanceActive();
        _;
    }

    function _issuanceActive() private {
        systemStatus().requireIssuanceActive();
    }

    modifier synthActive(bytes32 currencyKey) {
        _synthActive(currencyKey);
        _;
    }

    function _synthActive(bytes32 currencyKey) private {
        systemStatus().requireSynthActive(currencyKey);
    }

    /* ========== EVENTS ========== */

    event SynthAdded(bytes32 currencyKey, address synth);
    event SynthRemoved(bytes32 currencyKey, address synth);
}


contract LegacyOwned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        owner = _owner;
    }

    function nominateOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner);
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


contract LegacyTokenState is LegacyOwned {
    // the address of the contract that can modify balances and allowances
    // this can only be changed by the owner of this contract
    address public associatedContract;

    // ERC20 fields.
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address _owner, address _associatedContract) public LegacyOwned(_owner) {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    function setAllowance(
        address tokenOwner,
        address spender,
        uint value
    ) external onlyAssociatedContract {
        allowance[tokenOwner][spender] = value;
    }

    function setBalanceOf(address account, uint value) external onlyAssociatedContract {
        balanceOf[account] = value;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract);
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address _associatedContract);
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/state
contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/tokenstate
contract TokenState is Owned, State {
    /* ERC20 fields. */
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}

    /* ========== SETTERS ========== */

    /**
     * @notice Set ERC20 allowance.
     * @dev Only the associated contract may call this.
     * @param tokenOwner The authorising party.
     * @param spender The authorised party.
     * @param value The total value the authorised party may spend on the
     * authorising party's behalf.
     */
    function setAllowance(
        address tokenOwner,
        address spender,
        uint value
    ) external onlyAssociatedContract {
        allowance[tokenOwner][spender] = value;
    }

    /**
     * @notice Set the balance in a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param value The new balance of the given account.
     */
    function setBalanceOf(address account, uint value) external onlyAssociatedContract {
        balanceOf[account] = value;
    }
}


// Inheritance


// Libraries


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/externstatetoken
contract ExternStateToken is Owned, Proxyable {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== STATE VARIABLES ========== */

    /* Stores balances and allowances. */
    TokenState public tokenState;

    /* Other ERC20 fields. */
    string public name;
    string public symbol;
    uint public totalSupply;
    uint8 public decimals;

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        uint8 _decimals,
        address _owner
    ) public Owned(_owner) Proxyable(_proxy) {
        tokenState = _tokenState;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner's funds.
     */
    function allowance(address owner, address spender) public view returns (uint) {
        return tokenState.allowance(owner, spender);
    }

    /**
     * @notice Returns the ERC20 token balance of a given account.
     */
    function balanceOf(address account) external view returns (uint) {
        return tokenState.balanceOf(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the tokenState at 0x000..
     * as balances would be unreachable.
     */
    function setTokenState(TokenState _tokenState) external optionalProxy_onlyOwner {
        tokenState = _tokenState;
        emitTokenStateUpdated(address(_tokenState));
    }

    function _internalTransfer(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0) && to != address(this) && to != address(proxy), "Cannot transfer to this address");

        // Insufficient balance will be handled by the safe subtraction.
        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));
        tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

        // Emit a standard ERC20 transfer event
        emitTransfer(from, to, value);

        return true;
    }

    /**
     * @dev Perform an ERC20 token transfer. Designed to be called by transfer functions possessing
     * the onlyProxy or optionalProxy modifiers.
     */
    function _transferByProxy(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        return _internalTransfer(from, to, value);
    }

    /*
     * @dev Perform an ERC20 token transferFrom. Designed to be called by transferFrom functions
     * possessing the optionalProxy or optionalProxy modifiers.
     */
    function _transferFromByProxy(
        address sender,
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        /* Insufficient allowance will be handled by the safe subtraction. */
        tokenState.setAllowance(from, sender, tokenState.allowance(from, sender).sub(value));
        return _internalTransfer(from, to, value);
    }

    /**
     * @notice Approves spender to transfer on the message sender's behalf.
     */
    function approve(address spender, uint value) public optionalProxy returns (bool) {
        address sender = messageSender;

        tokenState.setAllowance(sender, spender, value);
        emitApproval(sender, spender, value);
        return true;
    }

    /* ========== EVENTS ========== */
    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event Transfer(address indexed from, address indexed to, uint value);
    bytes32 internal constant TRANSFER_SIG = keccak256("Transfer(address,address,uint256)");

    function emitTransfer(
        address from,
        address to,
        uint value
    ) internal {
        proxy._emit(abi.encode(value), 3, TRANSFER_SIG, addressToBytes32(from), addressToBytes32(to), 0);
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    bytes32 internal constant APPROVAL_SIG = keccak256("Approval(address,address,uint256)");

    function emitApproval(
        address owner,
        address spender,
        uint value
    ) internal {
        proxy._emit(abi.encode(value), 3, APPROVAL_SIG, addressToBytes32(owner), addressToBytes32(spender), 0);
    }

    event TokenStateUpdated(address newTokenState);
    bytes32 internal constant TOKENSTATEUPDATED_SIG = keccak256("TokenStateUpdated(address)");

    function emitTokenStateUpdated(address newTokenState) internal {
        proxy._emit(abi.encode(newTokenState), 1, TOKENSTATEUPDATED_SIG, 0, 0, 0);
    }
}


interface IFuturesMarketManager {
    function markets(uint index, uint pageSize) external view returns (address[] memory);

    function numMarkets() external view returns (uint);

    function allMarkets() external view returns (address[] memory);

    function marketForKey(bytes32 marketKey) external view returns (address);

    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory);

    function totalDebt() external view returns (uint debt, bool isInvalid);
}


// Inheritance


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/synth
contract Synth is Owned, IERC20, ExternStateToken, MixinResolver, ISynth {
    bytes32 public constant CONTRACT_NAME = "Synth";

    /* ========== STATE VARIABLES ========== */

    // Currency key which identifies this Synth to the Synthetix system
    bytes32 public currencyKey;

    uint8 public constant DECIMALS = 18;

    // Where fees are pooled in sUSD
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_FUTURESMARKETMANAGER = "FuturesMarketManager";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _owner,
        bytes32 _currencyKey,
        uint _totalSupply,
        address _resolver
    )
        public
        ExternStateToken(_proxy, _tokenState, _tokenName, _tokenSymbol, _totalSupply, DECIMALS, _owner)
        MixinResolver(_resolver)
    {
        require(_proxy != address(0), "_proxy cannot be 0");
        require(_owner != address(0), "_owner cannot be 0");

        currencyKey = _currencyKey;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address to, uint value) public onlyProxyOrInternal returns (bool) {
        _ensureCanTransfer(messageSender, value);

        // transfers to FEE_ADDRESS will be exchanged into sUSD and recorded as fee
        if (to == FEE_ADDRESS) {
            return _transferToFeeAddress(to, value);
        }

        // transfers to 0x address will be burned
        if (to == address(0)) {
            return _internalBurn(messageSender, value);
        }

        return super._internalTransfer(messageSender, to, value);
    }

    function transferAndSettle(address to, uint value) public onlyProxyOrInternal returns (bool) {
        // Exchanger.settle ensures synth is active
        (, , uint numEntriesSettled) = exchanger().settle(messageSender, currencyKey);

        // Save gas instead of calling transferableSynths
        uint balanceAfter = value;

        if (numEntriesSettled > 0) {
            balanceAfter = tokenState.balanceOf(messageSender);
        }

        // Reduce the value to transfer if balance is insufficient after reclaimed
        value = value > balanceAfter ? balanceAfter : value;

        return super._internalTransfer(messageSender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) public onlyProxyOrInternal returns (bool) {
        _ensureCanTransfer(from, value);

        return _internalTransferFrom(from, to, value);
    }

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) public onlyProxyOrInternal returns (bool) {
        // Exchanger.settle() ensures synth is active
        (, , uint numEntriesSettled) = exchanger().settle(from, currencyKey);

        // Save gas instead of calling transferableSynths
        uint balanceAfter = value;

        if (numEntriesSettled > 0) {
            balanceAfter = tokenState.balanceOf(from);
        }

        // Reduce the value to transfer if balance is insufficient after reclaimed
        value = value >= balanceAfter ? balanceAfter : value;

        return _internalTransferFrom(from, to, value);
    }

    /**
     * @notice _transferToFeeAddress function
     * non-sUSD synths are exchanged into sUSD via synthInitiatedExchange
     * notify feePool to record amount as fee paid to feePool */
    function _transferToFeeAddress(address to, uint value) internal returns (bool) {
        uint amountInUSD;

        // sUSD can be transferred to FEE_ADDRESS directly
        if (currencyKey == "sUSD") {
            amountInUSD = value;
            super._internalTransfer(messageSender, to, value);
        } else {
            // else exchange synth into sUSD and send to FEE_ADDRESS
            (amountInUSD, ) = exchanger().exchange(
                messageSender,
                messageSender,
                currencyKey,
                value,
                "sUSD",
                FEE_ADDRESS,
                false,
                address(0),
                bytes32(0)
            );
        }

        // Notify feePool to record sUSD to distribute as fees
        feePool().recordFeePaid(amountInUSD);

        return true;
    }

    function issue(address account, uint amount) external onlyInternalContracts {
        _internalIssue(account, amount);
    }

    function burn(address account, uint amount) external onlyInternalContracts {
        _internalBurn(account, amount);
    }

    function _internalIssue(address account, uint amount) internal {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).add(amount));
        totalSupply = totalSupply.add(amount);
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }

    function _internalBurn(address account, uint amount) internal returns (bool) {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount);
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);

        return true;
    }

    // Allow owner to set the total supply on import.
    function setTotalSupply(uint amount) external optionalProxy_onlyOwner {
        totalSupply = amount;
    }

    /* ========== VIEWS ========== */

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](5);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_EXCHANGER;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_FEEPOOL;
        addresses[4] = CONTRACT_FUTURESMARKETMANAGER;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURESMARKETMANAGER));
    }

    function _ensureCanTransfer(address from, uint value) internal view {
        require(exchanger().maxSecsLeftInWaitingPeriod(from, currencyKey) == 0, "Cannot transfer during waiting period");
        require(transferableSynths(from) >= value, "Insufficient balance after any settlement owing");
        systemStatus().requireSynthActive(currencyKey);
    }

    function transferableSynths(address account) public view returns (uint) {
        (uint reclaimAmount, , ) = exchanger().settlementOwing(account, currencyKey);

        // Note: ignoring rebate amount here because a settle() is required in order to
        // allow the transfer to actually work

        uint balance = tokenState.balanceOf(account);

        if (reclaimAmount > balance) {
            return 0;
        } else {
            return balance.sub(reclaimAmount);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _internalTransferFrom(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        // Skip allowance update in case of infinite allowance
        if (tokenState.allowance(from, messageSender) != uint(-1)) {
            // Reduce the allowance by the amount we're transferring.
            // The safeSub call will handle an insufficient allowance.
            tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));
        }

        return super._internalTransfer(from, to, value);
    }

    /* ========== MODIFIERS ========== */

    function _isInternalContract(address account) internal view returns (bool) {
        return
            account == address(feePool()) ||
            account == address(exchanger()) ||
            account == address(issuer()) ||
            account == address(futuresMarketManager());
    }

    modifier onlyInternalContracts() {
        require(_isInternalContract(msg.sender), "Only internal contracts allowed");
        _;
    }

    modifier onlyProxyOrInternal {
        _onlyProxyOrInternal();
        _;
    }

    function _onlyProxyOrInternal() internal {
        if (msg.sender == address(proxy)) {
            // allow proxy through, messageSender should be already set correctly
            return;
        } else if (_isInternalTransferCaller(msg.sender)) {
            // optionalProxy behaviour only for the internal legacy contracts
            messageSender = msg.sender;
        } else {
            revert("Only the proxy can call");
        }
    }

    /// some legacy internal contracts use transfer methods directly on implementation
    /// which isn't supported due to SIP-238 for other callers
    function _isInternalTransferCaller(address caller) internal view returns (bool) {
        // These entries are not required or cached in order to allow them to not exist (==address(0))
        // e.g. due to not being available on L2 or at some future point in time.
        return
            // ordered to reduce gas for more frequent calls
            caller == resolver.getAddress("CollateralShort") ||
            // not used frequently
            caller == resolver.getAddress("SynthRedeemer") ||
            caller == resolver.getAddress("WrapperFactory") || // transfer not used by users
            // legacy
            caller == resolver.getAddress("NativeEtherWrapper") ||
            caller == resolver.getAddress("Depot");
    }

    /* ========== EVENTS ========== */
    event Issued(address indexed account, uint value);

    bytes32 private constant ISSUED_SIG = keccak256("Issued(address,uint256)");

    function emitIssued(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, ISSUED_SIG, addressToBytes32(account), 0, 0);
    }

    event Burned(address indexed account, uint value);

    bytes32 private constant BURNED_SIG = keccak256("Burned(address,uint256)");

    function emitBurned(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, BURNED_SIG, addressToBytes32(account), 0, 0);
    }
}


interface IWETH {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // WETH-specific functions.
    function deposit() external payable;

    function withdraw(uint amount) external;

    // Events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Deposit(address indexed to, uint amount);
    event Withdrawal(address indexed to, uint amount);
}


// https://docs.synthetix.io/contracts/source/interfaces/ietherwrapper
contract IEtherWrapper {
    function mint(uint amount) external;

    function burn(uint amount) external;

    function distributeFees() external;

    function capacity() external view returns (uint);

    function getReserves() external view returns (uint);

    function totalIssuedSynths() external view returns (uint);

    function calculateMintFee(uint amount) public view returns (uint);

    function calculateBurnFee(uint amount) public view returns (uint);

    function maxETH() public view returns (uint256);

    function mintFeeRate() public view returns (uint256);

    function burnFeeRate() public view returns (uint256);

    function weth() public view returns (IWETH);
}


// https://docs.synthetix.io/contracts/source/interfaces/iwrapperfactory
interface IWrapperFactory {
    function isWrapper(address possibleWrapper) external view returns (bool);

    function createWrapper(
        IERC20 token,
        bytes32 currencyKey,
        bytes32 synthContractName
    ) external returns (address);

    function distributeFees() external;
}


// Inheritance


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/multicollateralsynth
contract MultiCollateralSynth is Synth {
    bytes32 public constant CONTRACT_NAME = "MultiCollateralSynth";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_COLLATERALMANAGER = "CollateralManager";
    bytes32 private constant CONTRACT_ETHER_WRAPPER = "EtherWrapper";
    bytes32 private constant CONTRACT_WRAPPER_FACTORY = "WrapperFactory";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _owner,
        bytes32 _currencyKey,
        uint _totalSupply,
        address _resolver
    ) public Synth(_proxy, _tokenState, _tokenName, _tokenSymbol, _owner, _currencyKey, _totalSupply, _resolver) {}

    /* ========== VIEWS ======================= */

    function collateralManager() internal view returns (ICollateralManager) {
        return ICollateralManager(requireAndGetAddress(CONTRACT_COLLATERALMANAGER));
    }

    function etherWrapper() internal view returns (IEtherWrapper) {
        return IEtherWrapper(requireAndGetAddress(CONTRACT_ETHER_WRAPPER));
    }

    function wrapperFactory() internal view returns (IWrapperFactory) {
        return IWrapperFactory(requireAndGetAddress(CONTRACT_WRAPPER_FACTORY));
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = Synth.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](3);
        newAddresses[0] = CONTRACT_COLLATERALMANAGER;
        newAddresses[1] = CONTRACT_ETHER_WRAPPER;
        newAddresses[2] = CONTRACT_WRAPPER_FACTORY;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Function that allows multi Collateral to issue a certain number of synths from an account.
     * @param account Account to issue synths to
     * @param amount Number of synths
     */
    function issue(address account, uint amount) external onlyInternalContracts {
        super._internalIssue(account, amount);
    }

    /**
     * @notice Function that allows multi Collateral to burn a certain number of synths from an account.
     * @param account Account to burn synths from
     * @param amount Number of synths
     */
    function burn(address account, uint amount) external onlyInternalContracts {
        super._internalBurn(account, amount);
    }

    /* ========== MODIFIERS ========== */

    // overriding modifier from super to add more internal contracts and checks
    function _isInternalContract(address account) internal view returns (bool) {
        return
            super._isInternalContract(account) ||
            collateralManager().hasCollateral(account) ||
            wrapperFactory().isWrapper(account) ||
            (account == address(etherWrapper()));
    }
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/proxyerc20
contract ProxyERC20 is Proxy, IERC20 {
    constructor(address _owner) public Proxy(_owner) {}

    // ------------- ERC20 Details ------------- //

    function name() public view returns (string memory) {
        // Immutable static call from target contract
        return IERC20(address(target)).name();
    }

    function symbol() public view returns (string memory) {
        // Immutable static call from target contract
        return IERC20(address(target)).symbol();
    }

    function decimals() public view returns (uint8) {
        // Immutable static call from target contract
        return IERC20(address(target)).decimals();
    }

    // ------------- ERC20 Interface ------------- //

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        // Immutable static call from target contract
        return IERC20(address(target)).totalSupply();
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address account) public view returns (uint256) {
        // Immutable static call from target contract
        return IERC20(address(target)).balanceOf(account);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        // Immutable static call from target contract
        return IERC20(address(target)).allowance(owner, spender);
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        // Mutable state call requires the proxy to tell the target who the msg.sender is.
        target.setMessageSender(msg.sender);

        // Forward the ERC20 call to the target contract
        IERC20(address(target)).transfer(to, value);

        // Event emitting will occur via Synthetix.Proxy._emit()
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        // Mutable state call requires the proxy to tell the target who the msg.sender is.
        target.setMessageSender(msg.sender);

        // Forward the ERC20 call to the target contract
        IERC20(address(target)).approve(spender, value);

        // Event emitting will occur via Synthetix.Proxy._emit()
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        // Mutable state call requires the proxy to tell the target who the msg.sender is.
        target.setMessageSender(msg.sender);

        // Forward the ERC20 call to the target contract
        IERC20(address(target)).transferFrom(from, to, value);

        // Event emitting will occur via Synthetix.Proxy._emit()
        return true;
    }
}


// https://docs.synthetix.io/contracts/source/interfaces/irewardescrow
interface IRewardEscrow {
    // Views
    function balanceOf(address account) external view returns (uint);

    function numVestingEntries(address account) external view returns (uint);

    function totalEscrowedAccountBalance(address account) external view returns (uint);

    function totalVestedAccountBalance(address account) external view returns (uint);

    function getVestingScheduleEntry(address account, uint index) external view returns (uint[2] memory);

    function getNextVestingIndex(address account) external view returns (uint);

    // Mutative functions
    function appendVestingEntry(address account, uint quantity) external;

    function vest() external;
}


// Inheritance


// Libraries


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/rewardescrow
contract RewardEscrow is Owned, IRewardEscrow {
    using SafeMath for uint;

    /* The corresponding Synthetix contract. */
    ISynthetix public synthetix;

    IFeePool public feePool;

    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of SNX vests. */
    mapping(address => uint[2][]) public vestingSchedules;

    /* An account's total escrowed synthetix balance to save recomputing this for fee extraction purposes. */
    mapping(address => uint) public totalEscrowedAccountBalance;

    /* An account's total vested reward synthetix. */
    mapping(address => uint) public totalVestedAccountBalance;

    /* The total remaining escrowed balance, for verifying the actual synthetix balance of this contract against. */
    uint public totalEscrowedBalance;

    uint internal constant TIME_INDEX = 0;
    uint internal constant QUANTITY_INDEX = 1;

    /* Limit vesting entries to disallow unbounded iteration over vesting schedules.
     * There are 5 years of the supply schedule */
    uint public constant MAX_VESTING_ENTRIES = 52 * 5;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        ISynthetix _synthetix,
        IFeePool _feePool
    ) public Owned(_owner) {
        synthetix = _synthetix;
        feePool = _feePool;
    }

    /* ========== SETTERS ========== */

    /**
     * @notice set the synthetix contract address as we need to transfer SNX when the user vests
     */
    function setSynthetix(ISynthetix _synthetix) external onlyOwner {
        synthetix = _synthetix;
        emit SynthetixUpdated(address(_synthetix));
    }

    /**
     * @notice set the FeePool contract as it is the only authority to be able to call
     * appendVestingEntry with the onlyFeePool modifer
     */
    function setFeePool(IFeePool _feePool) external onlyOwner {
        feePool = _feePool;
        emit FeePoolUpdated(address(_feePool));
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice A simple alias to totalEscrowedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) public view returns (uint) {
        return totalEscrowedAccountBalance[account];
    }

    function _numVestingEntries(address account) internal view returns (uint) {
        return vestingSchedules[account].length;
    }

    /**
     * @notice The number of vesting dates in an account's schedule.
     */
    function numVestingEntries(address account) external view returns (uint) {
        return vestingSchedules[account].length;
    }

    /**
     * @notice Get a particular schedule entry for an account.
     * @return A pair of uints: (timestamp, synthetix quantity).
     */
    function getVestingScheduleEntry(address account, uint index) public view returns (uint[2] memory) {
        return vestingSchedules[account][index];
    }

    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index) public view returns (uint) {
        return getVestingScheduleEntry(account, index)[TIME_INDEX];
    }

    /**
     * @notice Get the quantity of SNX associated with a given schedule entry.
     */
    function getVestingQuantity(address account, uint index) public view returns (uint) {
        return getVestingScheduleEntry(account, index)[QUANTITY_INDEX];
    }

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(address account) public view returns (uint) {
        uint len = _numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, synthetix quantity). */
    function getNextVestingEntry(address account) public view returns (uint[2] memory) {
        uint index = getNextVestingIndex(account);
        if (index == _numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account) external view returns (uint) {
        return getNextVestingEntry(account)[TIME_INDEX];
    }

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account) external view returns (uint) {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }

    /**
     * @notice return the full vesting schedule entries vest for a given user.
     * @dev For DApps to display the vesting schedule for the
     * inflationary supply over 5 years. Solidity cant return variable length arrays
     * so this is returning pairs of data. Vesting Time at [0] and quantity at [1] and so on
     */
    function checkAccountSchedule(address account) public view returns (uint[520] memory) {
        uint[520] memory _result;
        uint schedules = _numVestingEntries(account);
        for (uint i = 0; i < schedules; i++) {
            uint[2] memory pair = getVestingScheduleEntry(account, i);
            _result[i * 2] = pair[0];
            _result[i * 2 + 1] = pair[1];
        }
        return _result;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _appendVestingEntry(address account, uint quantity) internal {
        /* No empty or already-passed vesting entries allowed. */
        require(quantity != 0, "Quantity cannot be zero");

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalEscrowedBalance = totalEscrowedBalance.add(quantity);
        require(
            totalEscrowedBalance <= IERC20(address(synthetix)).balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        /* Escrow the tokens for 1 year. */
        uint time = now + 52 weeks;

        if (scheduleLength == 0) {
            totalEscrowedAccountBalance[account] = quantity;
        } else {
            /* Disallow adding new vested SNX earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(
                getVestingTime(account, scheduleLength - 1) < time,
                "Cannot add new vested entries earlier than the last one"
            );
            totalEscrowedAccountBalance[account] = totalEscrowedAccountBalance[account].add(quantity);
        }

        vestingSchedules[account].push([time, quantity]);

        emit VestingEntryCreated(account, now, quantity);
    }

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should accompany a previous successful call to synthetix.transfer(rewardEscrow, amount),
     * to ensure that when the funds are withdrawn, there is enough balance.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it's only withinn the 4 year period of the weekly inflation schedule.
     * @param account The account to append a new vesting entry to.
     * @param quantity The quantity of SNX that will be escrowed.
     */
    function appendVestingEntry(address account, uint quantity) external onlyFeePool {
        _appendVestingEntry(account, quantity);
    }

    /**
     * @notice Allow a user to withdraw any SNX in their schedule that have vested.
     */
    function vest() external {
        uint numEntries = _numVestingEntries(msg.sender);
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint time = getVestingTime(msg.sender, i);
            /* The list is sorted; when we reach the first future time, bail out. */
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty > 0) {
                vestingSchedules[msg.sender][i] = [0, 0];
                total = total.add(qty);
            }
        }

        if (total != 0) {
            totalEscrowedBalance = totalEscrowedBalance.sub(total);
            totalEscrowedAccountBalance[msg.sender] = totalEscrowedAccountBalance[msg.sender].sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].add(total);
            IERC20(address(synthetix)).transfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyFeePool() {
        bool isFeePool = msg.sender == address(feePool);

        require(isFeePool, "Only the FeePool contracts can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event SynthetixUpdated(address newSynthetix);

    event FeePoolUpdated(address newFeePool);

    event Vested(address indexed beneficiary, uint time, uint value);

    event VestingEntryCreated(address indexed beneficiary, uint time, uint value);
}


// https://docs.synthetix.io/contracts/source/interfaces/irewardsdistribution
interface IRewardsDistribution {
    // Structs
    struct DistributionData {
        address destination;
        uint amount;
    }

    // Views
    function authority() external view returns (address);

    function distributions(uint index) external view returns (address destination, uint amount); // DistributionData

    function distributionsLength() external view returns (uint);

    // Mutative Functions
    function distributeRewards(uint amount) external returns (bool);
}


// Inheritance


// Libraires


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/rewardsdistribution
contract RewardsDistribution is Owned, IRewardsDistribution {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /**
     * @notice Authorised address able to call distributeRewards
     */
    address public authority;

    /**
     * @notice Address of the Synthetix ProxyERC20
     */
    address public synthetixProxy;

    /**
     * @notice Address of the RewardEscrow contract
     */
    address public rewardEscrow;

    /**
     * @notice Address of the FeePoolProxy
     */
    address public feePoolProxy;

    /**
     * @notice An array of addresses and amounts to send
     */
    DistributionData[] public distributions;

    /**
     * @dev _authority maybe the underlying synthetix contract.
     * Remember to set the authority on a synthetix upgrade
     */
    constructor(
        address _owner,
        address _authority,
        address _synthetixProxy,
        address _rewardEscrow,
        address _feePoolProxy
    ) public Owned(_owner) {
        authority = _authority;
        synthetixProxy = _synthetixProxy;
        rewardEscrow = _rewardEscrow;
        feePoolProxy = _feePoolProxy;
    }

    // ========== EXTERNAL SETTERS ==========

    function setSynthetixProxy(address _synthetixProxy) external onlyOwner {
        synthetixProxy = _synthetixProxy;
    }

    function setRewardEscrow(address _rewardEscrow) external onlyOwner {
        rewardEscrow = _rewardEscrow;
    }

    function setFeePoolProxy(address _feePoolProxy) external onlyOwner {
        feePoolProxy = _feePoolProxy;
    }

    /**
     * @notice Set the address of the contract authorised to call distributeRewards()
     * @param _authority Address of the authorised calling contract.
     */
    function setAuthority(address _authority) external onlyOwner {
        authority = _authority;
    }

    // ========== EXTERNAL FUNCTIONS ==========

    /**
     * @notice Adds a Rewards DistributionData struct to the distributions
     * array. Any entries here will be iterated and rewards distributed to
     * each address when tokens are sent to this contract and distributeRewards()
     * is called by the autority.
     * @param destination An address to send rewards tokens too
     * @param amount The amount of rewards tokens to send
     */
    function addRewardDistribution(address destination, uint amount) external onlyOwner returns (bool) {
        require(destination != address(0), "Cant add a zero address");
        require(amount != 0, "Cant add a zero amount");

        DistributionData memory rewardsDistribution = DistributionData(destination, amount);
        distributions.push(rewardsDistribution);

        emit RewardDistributionAdded(distributions.length - 1, destination, amount);
        return true;
    }

    /**
     * @notice Deletes a RewardDistribution from the distributions
     * so it will no longer be included in the call to distributeRewards()
     * @param index The index of the DistributionData to delete
     */
    function removeRewardDistribution(uint index) external onlyOwner {
        require(index <= distributions.length - 1, "index out of bounds");

        // shift distributions indexes across
        for (uint i = index; i < distributions.length - 1; i++) {
            distributions[i] = distributions[i + 1];
        }
        distributions.length--;

        // Since this function must shift all later entries down to fill the
        // gap from the one it removed, it could in principle consume an
        // unbounded amount of gas. However, the number of entries will
        // presumably always be very low.
    }

    /**
     * @notice Edits a RewardDistribution in the distributions array.
     * @param index The index of the DistributionData to edit
     * @param destination The destination address. Send the same address to keep or different address to change it.
     * @param amount The amount of tokens to edit. Send the same number to keep or change the amount of tokens to send.
     */
    function editRewardDistribution(
        uint index,
        address destination,
        uint amount
    ) external onlyOwner returns (bool) {
        require(index <= distributions.length - 1, "index out of bounds");

        distributions[index].destination = destination;
        distributions[index].amount = amount;

        return true;
    }

    function distributeRewards(uint amount) external returns (bool) {
        require(amount > 0, "Nothing to distribute");
        require(msg.sender == authority, "Caller is not authorised");
        require(rewardEscrow != address(0), "RewardEscrow is not set");
        require(synthetixProxy != address(0), "SynthetixProxy is not set");
        require(feePoolProxy != address(0), "FeePoolProxy is not set");
        require(
            IERC20(synthetixProxy).balanceOf(address(this)) >= amount,
            "RewardsDistribution contract does not have enough tokens to distribute"
        );

        uint remainder = amount;

        // Iterate the array of distributions sending the configured amounts
        for (uint i = 0; i < distributions.length; i++) {
            if (distributions[i].destination != address(0) || distributions[i].amount != 0) {
                remainder = remainder.sub(distributions[i].amount);

                // Transfer the SNX
                IERC20(synthetixProxy).transfer(distributions[i].destination, distributions[i].amount);

                // If the contract implements RewardsDistributionRecipient.sol, inform it how many SNX its received.
                bytes memory payload = abi.encodeWithSignature("notifyRewardAmount(uint256)", distributions[i].amount);

                // solhint-disable avoid-low-level-calls
                (bool success, ) = distributions[i].destination.call(payload);

                if (!success) {
                    // Note: we're ignoring the return value as it will fail for contracts that do not implement RewardsDistributionRecipient.sol
                }
            }
        }

        // After all ditributions have been sent, send the remainder to the RewardsEscrow contract
        IERC20(synthetixProxy).transfer(rewardEscrow, remainder);

        // Tell the FeePool how much it has to distribute to the stakers
        IFeePool(feePoolProxy).setRewardsToDistribute(remainder);

        emit RewardsDistributed(amount);
        return true;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Retrieve the length of the distributions array
     */
    function distributionsLength() external view returns (uint) {
        return distributions.length;
    }

    /* ========== Events ========== */

    event RewardDistributionAdded(uint index, address destination, uint amount);
    event RewardsDistributed(uint amount);
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/systemstatus
contract SystemStatus is Owned, ISystemStatus {
    mapping(bytes32 => mapping(address => Status)) public accessControl;

    uint248 public constant SUSPENSION_REASON_UPGRADE = 1;

    bytes32 public constant SECTION_SYSTEM = "System";
    bytes32 public constant SECTION_ISSUANCE = "Issuance";
    bytes32 public constant SECTION_EXCHANGE = "Exchange";
    bytes32 public constant SECTION_FUTURES = "Futures";
    bytes32 public constant SECTION_SYNTH_EXCHANGE = "SynthExchange";
    bytes32 public constant SECTION_SYNTH = "Synth";

    bytes32 public constant CONTRACT_NAME = "SystemStatus";

    Suspension public systemSuspension;

    Suspension public issuanceSuspension;

    Suspension public exchangeSuspension;

    Suspension public futuresSuspension;

    mapping(bytes32 => Suspension) public synthExchangeSuspension;

    mapping(bytes32 => Suspension) public synthSuspension;

    mapping(bytes32 => Suspension) public futuresMarketSuspension;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== VIEWS ========== */
    function requireSystemActive() external view {
        _internalRequireSystemActive();
    }

    function systemSuspended() external view returns (bool) {
        return systemSuspension.suspended;
    }

    function requireIssuanceActive() external view {
        // Issuance requires the system be active
        _internalRequireSystemActive();

        // and issuance itself of course
        _internalRequireIssuanceActive();
    }

    function requireExchangeActive() external view {
        // Exchanging requires the system be active
        _internalRequireSystemActive();

        // and exchanging itself of course
        _internalRequireExchangeActive();
    }

    function requireSynthExchangeActive(bytes32 currencyKey) external view {
        // Synth exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireSynthExchangeActive(currencyKey);
    }

    function requireFuturesActive() external view {
        _internalRequireSystemActive();
        _internalRequireExchangeActive();
        _internalRequireFuturesActive();
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function requireFuturesMarketActive(bytes32 marketKey) external view {
        _internalRequireSystemActive();
        _internalRequireExchangeActive(); // exchanging implicitely used
        _internalRequireFuturesActive(); // futures global flag
        _internalRequireFuturesMarketActive(marketKey); // specific futures market flag
    }

    function synthSuspended(bytes32 currencyKey) external view returns (bool) {
        return systemSuspension.suspended || synthSuspension[currencyKey].suspended;
    }

    function requireSynthActive(bytes32 currencyKey) external view {
        // Synth exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireSynthActive(currencyKey);
    }

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Synth exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireSynthActive(sourceCurrencyKey);
        _internalRequireSynthActive(destinationCurrencyKey);
    }

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Synth exchange and transfer requires the system be active
        _internalRequireSystemActive();

        // and exchanging must be active
        _internalRequireExchangeActive();

        // and the synth exchanging between the synths must be active
        _internalRequireSynthExchangeActive(sourceCurrencyKey);
        _internalRequireSynthExchangeActive(destinationCurrencyKey);

        // and finally, the synths cannot be suspended
        _internalRequireSynthActive(sourceCurrencyKey);
        _internalRequireSynthActive(destinationCurrencyKey);
    }

    function isSystemUpgrading() external view returns (bool) {
        return systemSuspension.suspended && systemSuspension.reason == SUSPENSION_REASON_UPGRADE;
    }

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons)
    {
        exchangeSuspensions = new bool[](synths.length);
        reasons = new uint256[](synths.length);

        for (uint i = 0; i < synths.length; i++) {
            exchangeSuspensions[i] = synthExchangeSuspension[synths[i]].suspended;
            reasons[i] = synthExchangeSuspension[synths[i]].reason;
        }
    }

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons)
    {
        suspensions = new bool[](synths.length);
        reasons = new uint256[](synths.length);

        for (uint i = 0; i < synths.length; i++) {
            suspensions[i] = synthSuspension[synths[i]].suspended;
            reasons[i] = synthSuspension[synths[i]].reason;
        }
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons)
    {
        suspensions = new bool[](marketKeys.length);
        reasons = new uint256[](marketKeys.length);

        for (uint i = 0; i < marketKeys.length; i++) {
            suspensions[i] = futuresMarketSuspension[marketKeys[i]].suspended;
            reasons[i] = futuresMarketSuspension[marketKeys[i]].reason;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateAccessControl(section, account, canSuspend, canResume);
    }

    function updateAccessControls(
        bytes32[] calldata sections,
        address[] calldata accounts,
        bool[] calldata canSuspends,
        bool[] calldata canResumes
    ) external onlyOwner {
        require(
            sections.length == accounts.length &&
                accounts.length == canSuspends.length &&
                canSuspends.length == canResumes.length,
            "Input array lengths must match"
        );
        for (uint i = 0; i < sections.length; i++) {
            _internalUpdateAccessControl(sections[i], accounts[i], canSuspends[i], canResumes[i]);
        }
    }

    function suspendSystem(uint256 reason) external {
        _requireAccessToSuspend(SECTION_SYSTEM);
        systemSuspension.suspended = true;
        systemSuspension.reason = uint248(reason);
        emit SystemSuspended(systemSuspension.reason);
    }

    function resumeSystem() external {
        _requireAccessToResume(SECTION_SYSTEM);
        systemSuspension.suspended = false;
        emit SystemResumed(uint256(systemSuspension.reason));
        systemSuspension.reason = 0;
    }

    function suspendIssuance(uint256 reason) external {
        _requireAccessToSuspend(SECTION_ISSUANCE);
        issuanceSuspension.suspended = true;
        issuanceSuspension.reason = uint248(reason);
        emit IssuanceSuspended(reason);
    }

    function resumeIssuance() external {
        _requireAccessToResume(SECTION_ISSUANCE);
        issuanceSuspension.suspended = false;
        emit IssuanceResumed(uint256(issuanceSuspension.reason));
        issuanceSuspension.reason = 0;
    }

    function suspendExchange(uint256 reason) external {
        _requireAccessToSuspend(SECTION_EXCHANGE);
        exchangeSuspension.suspended = true;
        exchangeSuspension.reason = uint248(reason);
        emit ExchangeSuspended(reason);
    }

    function resumeExchange() external {
        _requireAccessToResume(SECTION_EXCHANGE);
        exchangeSuspension.suspended = false;
        emit ExchangeResumed(uint256(exchangeSuspension.reason));
        exchangeSuspension.reason = 0;
    }

    function suspendFutures(uint256 reason) external {
        _requireAccessToSuspend(SECTION_FUTURES);
        futuresSuspension.suspended = true;
        futuresSuspension.reason = uint248(reason);
        emit FuturesSuspended(reason);
    }

    function resumeFutures() external {
        _requireAccessToResume(SECTION_FUTURES);
        futuresSuspension.suspended = false;
        emit FuturesResumed(uint256(futuresSuspension.reason));
        futuresSuspension.reason = 0;
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external {
        bytes32[] memory marketKeys = new bytes32[](1);
        marketKeys[0] = marketKey;
        _internalSuspendFuturesMarkets(marketKeys, reason);
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function suspendFuturesMarkets(bytes32[] calldata marketKeys, uint256 reason) external {
        _internalSuspendFuturesMarkets(marketKeys, reason);
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function resumeFuturesMarket(bytes32 marketKey) external {
        bytes32[] memory marketKeys = new bytes32[](1);
        marketKeys[0] = marketKey;
        _internalResumeFuturesMarkets(marketKeys);
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function resumeFuturesMarkets(bytes32[] calldata marketKeys) external {
        _internalResumeFuturesMarkets(marketKeys);
    }

    function suspendSynthExchange(bytes32 currencyKey, uint256 reason) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalSuspendSynthExchange(currencyKeys, reason);
    }

    function suspendSynthsExchange(bytes32[] calldata currencyKeys, uint256 reason) external {
        _internalSuspendSynthExchange(currencyKeys, reason);
    }

    function resumeSynthExchange(bytes32 currencyKey) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalResumeSynthsExchange(currencyKeys);
    }

    function resumeSynthsExchange(bytes32[] calldata currencyKeys) external {
        _internalResumeSynthsExchange(currencyKeys);
    }

    function suspendSynth(bytes32 currencyKey, uint256 reason) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalSuspendSynths(currencyKeys, reason);
    }

    function suspendSynths(bytes32[] calldata currencyKeys, uint256 reason) external {
        _internalSuspendSynths(currencyKeys, reason);
    }

    function resumeSynth(bytes32 currencyKey) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalResumeSynths(currencyKeys);
    }

    function resumeSynths(bytes32[] calldata currencyKeys) external {
        _internalResumeSynths(currencyKeys);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _requireAccessToSuspend(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canSuspend, "Restricted to access control list");
    }

    function _requireAccessToResume(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canResume, "Restricted to access control list");
    }

    function _internalRequireSystemActive() internal view {
        require(
            !systemSuspension.suspended,
            systemSuspension.reason == SUSPENSION_REASON_UPGRADE
                ? "Synthetix is suspended, upgrade in progress... please stand by"
                : "Synthetix is suspended. Operation prohibited"
        );
    }

    function _internalRequireIssuanceActive() internal view {
        require(!issuanceSuspension.suspended, "Issuance is suspended. Operation prohibited");
    }

    function _internalRequireExchangeActive() internal view {
        require(!exchangeSuspension.suspended, "Exchange is suspended. Operation prohibited");
    }

    function _internalRequireFuturesActive() internal view {
        require(!futuresSuspension.suspended, "Futures markets are suspended. Operation prohibited");
    }

    function _internalRequireSynthExchangeActive(bytes32 currencyKey) internal view {
        require(!synthExchangeSuspension[currencyKey].suspended, "Synth exchange suspended. Operation prohibited");
    }

    function _internalRequireSynthActive(bytes32 currencyKey) internal view {
        require(!synthSuspension[currencyKey].suspended, "Synth is suspended. Operation prohibited");
    }

    function _internalRequireFuturesMarketActive(bytes32 marketKey) internal view {
        require(!futuresMarketSuspension[marketKey].suspended, "Market suspended");
    }

    function _internalSuspendSynths(bytes32[] memory currencyKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_SYNTH);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            synthSuspension[currencyKey].suspended = true;
            synthSuspension[currencyKey].reason = uint248(reason);
            emit SynthSuspended(currencyKey, reason);
        }
    }

    function _internalResumeSynths(bytes32[] memory currencyKeys) internal {
        _requireAccessToResume(SECTION_SYNTH);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            emit SynthResumed(currencyKey, uint256(synthSuspension[currencyKey].reason));
            delete synthSuspension[currencyKey];
        }
    }

    function _internalSuspendSynthExchange(bytes32[] memory currencyKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_SYNTH_EXCHANGE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            synthExchangeSuspension[currencyKey].suspended = true;
            synthExchangeSuspension[currencyKey].reason = uint248(reason);
            emit SynthExchangeSuspended(currencyKey, reason);
        }
    }

    function _internalResumeSynthsExchange(bytes32[] memory currencyKeys) internal {
        _requireAccessToResume(SECTION_SYNTH_EXCHANGE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            emit SynthExchangeResumed(currencyKey, uint256(synthExchangeSuspension[currencyKey].reason));
            delete synthExchangeSuspension[currencyKey];
        }
    }

    function _internalSuspendFuturesMarkets(bytes32[] memory marketKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_FUTURES);
        for (uint i = 0; i < marketKeys.length; i++) {
            bytes32 marketKey = marketKeys[i];
            futuresMarketSuspension[marketKey].suspended = true;
            futuresMarketSuspension[marketKey].reason = uint248(reason);
            emit FuturesMarketSuspended(marketKey, reason);
        }
    }

    function _internalResumeFuturesMarkets(bytes32[] memory marketKeys) internal {
        _requireAccessToResume(SECTION_FUTURES);
        for (uint i = 0; i < marketKeys.length; i++) {
            bytes32 marketKey = marketKeys[i];
            emit FuturesMarketResumed(marketKey, uint256(futuresMarketSuspension[marketKey].reason));
            delete futuresMarketSuspension[marketKey];
        }
    }

    function _internalUpdateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal {
        require(
            section == SECTION_SYSTEM ||
                section == SECTION_ISSUANCE ||
                section == SECTION_EXCHANGE ||
                section == SECTION_FUTURES ||
                section == SECTION_SYNTH_EXCHANGE ||
                section == SECTION_SYNTH,
            "Invalid section supplied"
        );
        accessControl[section][account].canSuspend = canSuspend;
        accessControl[section][account].canResume = canResume;
        emit AccessControlUpdated(section, account, canSuspend, canResume);
    }

    /* ========== EVENTS ========== */

    event SystemSuspended(uint256 reason);
    event SystemResumed(uint256 reason);

    event IssuanceSuspended(uint256 reason);
    event IssuanceResumed(uint256 reason);

    event ExchangeSuspended(uint256 reason);
    event ExchangeResumed(uint256 reason);

    event FuturesSuspended(uint256 reason);
    event FuturesResumed(uint256 reason);

    event SynthExchangeSuspended(bytes32 currencyKey, uint256 reason);
    event SynthExchangeResumed(bytes32 currencyKey, uint256 reason);

    event SynthSuspended(bytes32 currencyKey, uint256 reason);
    event SynthResumed(bytes32 currencyKey, uint256 reason);

    event FuturesMarketSuspended(bytes32 marketKey, uint256 reason);
    event FuturesMarketResumed(bytes32 marketKey, uint256 reason);

    event AccessControlUpdated(bytes32 indexed section, address indexed account, bool canSuspend, bool canResume);
}


interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_Saiph is BaseMigration {
    // https://etherscan.io/address/0xEb3107117FEAd7de89Cd14D463D340A2E6917769;
    address public constant OWNER = 0xEb3107117FEAd7de89Cd14D463D340A2E6917769;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://etherscan.io/address/0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83
    AddressResolver public constant addressresolver_i = AddressResolver(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83);
    // https://etherscan.io/address/0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
    Proxy public constant proxysynthetix_i = Proxy(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    // https://etherscan.io/address/0x696c905F8F8c006cA46e9808fE7e00049507798F
    SystemStatus public constant systemstatus_i = SystemStatus(0x696c905F8F8c006cA46e9808fE7e00049507798F);
    // https://etherscan.io/address/0x5b1b5fEa1b99D83aD479dF0C222F0492385381dD
    LegacyTokenState public constant tokenstatesynthetix_i = LegacyTokenState(0x5b1b5fEa1b99D83aD479dF0C222F0492385381dD);
    // https://etherscan.io/address/0xb671F2210B1F6621A2607EA63E6B2DC3e2464d1F
    RewardEscrow public constant rewardescrow_i = RewardEscrow(0xb671F2210B1F6621A2607EA63E6B2DC3e2464d1F);
    // https://etherscan.io/address/0x29C295B046a73Cde593f21f63091B072d407e3F2
    RewardsDistribution public constant rewardsdistribution_i =
        RewardsDistribution(0x29C295B046a73Cde593f21f63091B072d407e3F2);
    // https://etherscan.io/address/0x10A5F7D9D65bCc2734763444D4940a31b109275f
    MultiCollateralSynth public constant synthsusd_i = MultiCollateralSynth(0x10A5F7D9D65bCc2734763444D4940a31b109275f);
    // https://etherscan.io/address/0x05a9CBe762B36632b3594DA4F082340E0e5343e8
    TokenState public constant tokenstatesusd_i = TokenState(0x05a9CBe762B36632b3594DA4F082340E0e5343e8);
    // https://etherscan.io/address/0x57Ab1ec28D129707052df4dF418D58a2D46d5f51
    Proxy public constant proxysusd_i = Proxy(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    // https://etherscan.io/address/0xa8E31E3C38aDD6052A9407298FAEB8fD393A6cF9
    MultiCollateralSynth public constant synthseur_i = MultiCollateralSynth(0xa8E31E3C38aDD6052A9407298FAEB8fD393A6cF9);
    // https://etherscan.io/address/0x6568D9e750fC44AF00f857885Dfb8281c00529c4
    TokenState public constant tokenstateseur_i = TokenState(0x6568D9e750fC44AF00f857885Dfb8281c00529c4);
    // https://etherscan.io/address/0xD71eCFF9342A5Ced620049e616c5035F1dB98620
    ProxyERC20 public constant proxyseur_i = ProxyERC20(0xD71eCFF9342A5Ced620049e616c5035F1dB98620);
    // https://etherscan.io/address/0xE1cc2332852B2Ac0dA59A1f9D3051829f4eF3c1C
    MultiCollateralSynth public constant synthsjpy_i = MultiCollateralSynth(0xE1cc2332852B2Ac0dA59A1f9D3051829f4eF3c1C);
    // https://etherscan.io/address/0x4dFACfB15514C21c991ff75Bc7Bf6Fb1F98361ed
    TokenState public constant tokenstatesjpy_i = TokenState(0x4dFACfB15514C21c991ff75Bc7Bf6Fb1F98361ed);
    // https://etherscan.io/address/0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d
    ProxyERC20 public constant proxysjpy_i = ProxyERC20(0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d);
    // https://etherscan.io/address/0xfb020CA7f4e8C4a5bBBe060f59a249c6275d2b69
    MultiCollateralSynth public constant synthsaud_i = MultiCollateralSynth(0xfb020CA7f4e8C4a5bBBe060f59a249c6275d2b69);
    // https://etherscan.io/address/0xCb29D2cf2C65d3Be1d00F07f3441390432D55203
    TokenState public constant tokenstatesaud_i = TokenState(0xCb29D2cf2C65d3Be1d00F07f3441390432D55203);
    // https://etherscan.io/address/0xF48e200EAF9906362BB1442fca31e0835773b8B4
    ProxyERC20 public constant proxysaud_i = ProxyERC20(0xF48e200EAF9906362BB1442fca31e0835773b8B4);
    // https://etherscan.io/address/0xdc883b9d9Ee16f74bE08826E68dF4C9D9d26e8bD
    MultiCollateralSynth public constant synthsgbp_i = MultiCollateralSynth(0xdc883b9d9Ee16f74bE08826E68dF4C9D9d26e8bD);
    // https://etherscan.io/address/0x7e88D19A79b291cfE5696d496055f7e57F537A75
    TokenState public constant tokenstatesgbp_i = TokenState(0x7e88D19A79b291cfE5696d496055f7e57F537A75);
    // https://etherscan.io/address/0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F
    ProxyERC20 public constant proxysgbp_i = ProxyERC20(0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F);
    // https://etherscan.io/address/0xBb5b03E920cF702De5A3bA9Fc1445aF4B3919c88
    MultiCollateralSynth public constant synthschf_i = MultiCollateralSynth(0xBb5b03E920cF702De5A3bA9Fc1445aF4B3919c88);
    // https://etherscan.io/address/0x52496fE8a4feaEFe14d9433E00D48E6929c13deC
    TokenState public constant tokenstateschf_i = TokenState(0x52496fE8a4feaEFe14d9433E00D48E6929c13deC);
    // https://etherscan.io/address/0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d
    ProxyERC20 public constant proxyschf_i = ProxyERC20(0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d);
    // https://etherscan.io/address/0xdAe6C79c46aB3B280Ca28259000695529cbD1339
    MultiCollateralSynth public constant synthskrw_i = MultiCollateralSynth(0xdAe6C79c46aB3B280Ca28259000695529cbD1339);
    // https://etherscan.io/address/0x93B6e9FbBd2c32a0DC3C2B943B7C3CBC2fE23730
    TokenState public constant tokenstateskrw_i = TokenState(0x93B6e9FbBd2c32a0DC3C2B943B7C3CBC2fE23730);
    // https://etherscan.io/address/0x269895a3dF4D73b077Fc823dD6dA1B95f72Aaf9B
    ProxyERC20 public constant proxyskrw_i = ProxyERC20(0x269895a3dF4D73b077Fc823dD6dA1B95f72Aaf9B);
    // https://etherscan.io/address/0x1cB004a8e84a5CE95C1fF895EE603BaC8EC506c7
    MultiCollateralSynth public constant synthsbtc_i = MultiCollateralSynth(0x1cB004a8e84a5CE95C1fF895EE603BaC8EC506c7);
    // https://etherscan.io/address/0x4F6296455F8d754c19821cF1EC8FeBF2cD456E67
    TokenState public constant tokenstatesbtc_i = TokenState(0x4F6296455F8d754c19821cF1EC8FeBF2cD456E67);
    // https://etherscan.io/address/0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6
    ProxyERC20 public constant proxysbtc_i = ProxyERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);
    // https://etherscan.io/address/0x5D4C724BFe3a228Ff0E29125Ac1571FE093700a4
    MultiCollateralSynth public constant synthseth_i = MultiCollateralSynth(0x5D4C724BFe3a228Ff0E29125Ac1571FE093700a4);
    // https://etherscan.io/address/0x34A5ef81d18F3a305aE9C2d7DF42beef4c79031c
    TokenState public constant tokenstateseth_i = TokenState(0x34A5ef81d18F3a305aE9C2d7DF42beef4c79031c);
    // https://etherscan.io/address/0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb
    ProxyERC20 public constant proxyseth_i = ProxyERC20(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb);
    // https://etherscan.io/address/0xDF69bC4541b86Aa4c5A470B4347E730c38b2c3B2
    MultiCollateralSynth public constant synthslink_i = MultiCollateralSynth(0xDF69bC4541b86Aa4c5A470B4347E730c38b2c3B2);
    // https://etherscan.io/address/0x577D4a7395c6A5f46d9981a5F83fa7294926aBB0
    TokenState public constant tokenstateslink_i = TokenState(0x577D4a7395c6A5f46d9981a5F83fa7294926aBB0);
    // https://etherscan.io/address/0xbBC455cb4F1B9e4bFC4B73970d360c8f032EfEE6
    ProxyERC20 public constant proxyslink_i = ProxyERC20(0xbBC455cb4F1B9e4bFC4B73970d360c8f032EfEE6);
    // https://etherscan.io/address/0x91b82d62Ff322b8e02b86f33E9A99a813437830d
    MultiCollateralSynth public constant synthsada_i = MultiCollateralSynth(0x91b82d62Ff322b8e02b86f33E9A99a813437830d);
    // https://etherscan.io/address/0x9956c5019a24fbd5B506AD070b771577bAc5c343
    TokenState public constant tokenstatesada_i = TokenState(0x9956c5019a24fbd5B506AD070b771577bAc5c343);
    // https://etherscan.io/address/0xe36E2D3c7c34281FA3bC737950a68571736880A1
    ProxyERC20 public constant proxysada_i = ProxyERC20(0xe36E2D3c7c34281FA3bC737950a68571736880A1);
    // https://etherscan.io/address/0x942Eb6e8c029EB22103743C99985aF4F4515a559
    MultiCollateralSynth public constant synthsaave_i = MultiCollateralSynth(0x942Eb6e8c029EB22103743C99985aF4F4515a559);
    // https://etherscan.io/address/0x9BcED8A8E3Ad81c9b146FFC880358f734A06f7c0
    TokenState public constant tokenstatesaave_i = TokenState(0x9BcED8A8E3Ad81c9b146FFC880358f734A06f7c0);
    // https://etherscan.io/address/0xd2dF355C19471c8bd7D8A3aa27Ff4e26A21b4076
    ProxyERC20 public constant proxysaave_i = ProxyERC20(0xd2dF355C19471c8bd7D8A3aa27Ff4e26A21b4076);
    // https://etherscan.io/address/0x75A0c1597137AA36B40b6a515D997F9a6c6eefEB
    MultiCollateralSynth public constant synthsdot_i = MultiCollateralSynth(0x75A0c1597137AA36B40b6a515D997F9a6c6eefEB);
    // https://etherscan.io/address/0x73B1a2643507Cd30F11Dfcf2D974f4373E5BC077
    TokenState public constant tokenstatesdot_i = TokenState(0x73B1a2643507Cd30F11Dfcf2D974f4373E5BC077);
    // https://etherscan.io/address/0x1715AC0743102BF5Cd58EfBB6Cf2dC2685d967b6
    ProxyERC20 public constant proxysdot_i = ProxyERC20(0x1715AC0743102BF5Cd58EfBB6Cf2dC2685d967b6);
    // https://etherscan.io/address/0x07C1E81C345A7c58d7c24072EFc5D929BD0647AD
    MultiCollateralSynth public constant synthsethbtc_i = MultiCollateralSynth(0x07C1E81C345A7c58d7c24072EFc5D929BD0647AD);
    // https://etherscan.io/address/0x042A7A0022A7695454ac5Be77a4860e50c9683fC
    TokenState public constant tokenstatesethbtc_i = TokenState(0x042A7A0022A7695454ac5Be77a4860e50c9683fC);
    // https://etherscan.io/address/0x104eDF1da359506548BFc7c25bA1E28C16a70235
    ProxyERC20 public constant proxysethbtc_i = ProxyERC20(0x104eDF1da359506548BFc7c25bA1E28C16a70235);
    // https://etherscan.io/address/0x918b1dbf0917FdD74D03fB9434915E2ECEc89286
    MultiCollateralSynth public constant synthsdefi_i = MultiCollateralSynth(0x918b1dbf0917FdD74D03fB9434915E2ECEc89286);
    // https://etherscan.io/address/0x7Ac2D37098a65B0f711CFfA3be635F1E6aCacFaB
    TokenState public constant tokenstatesdefi_i = TokenState(0x7Ac2D37098a65B0f711CFfA3be635F1E6aCacFaB);
    // https://etherscan.io/address/0xe1aFe1Fd76Fd88f78cBf599ea1846231B8bA3B6B
    ProxyERC20 public constant proxysdefi_i = ProxyERC20(0xe1aFe1Fd76Fd88f78cBf599ea1846231B8bA3B6B);
    // https://etherscan.io/address/0xE5CC99EFA57943F4EA0cE6bed265318697748649
    Issuer public constant issuer_i = Issuer(0xE5CC99EFA57943F4EA0cE6bed265318697748649);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    // https://etherscan.io/address/0x08F30Ecf2C15A783083ab9D5b9211c22388d0564
    address public constant new_Synthetix_contract = 0x08F30Ecf2C15A783083ab9D5b9211c22388d0564;
    // https://etherscan.io/address/0xE5CC99EFA57943F4EA0cE6bed265318697748649
    address public constant new_Issuer_contract = 0xE5CC99EFA57943F4EA0cE6bed265318697748649;
    // https://etherscan.io/address/0x10A5F7D9D65bCc2734763444D4940a31b109275f
    address public constant new_SynthsUSD_contract = 0x10A5F7D9D65bCc2734763444D4940a31b109275f;
    // https://etherscan.io/address/0xE1cc2332852B2Ac0dA59A1f9D3051829f4eF3c1C
    address public constant new_SynthsJPY_contract = 0xE1cc2332852B2Ac0dA59A1f9D3051829f4eF3c1C;
    // https://etherscan.io/address/0xa8E31E3C38aDD6052A9407298FAEB8fD393A6cF9
    address public constant new_SynthsEUR_contract = 0xa8E31E3C38aDD6052A9407298FAEB8fD393A6cF9;
    // https://etherscan.io/address/0xfb020CA7f4e8C4a5bBBe060f59a249c6275d2b69
    address public constant new_SynthsAUD_contract = 0xfb020CA7f4e8C4a5bBBe060f59a249c6275d2b69;
    // https://etherscan.io/address/0xdc883b9d9Ee16f74bE08826E68dF4C9D9d26e8bD
    address public constant new_SynthsGBP_contract = 0xdc883b9d9Ee16f74bE08826E68dF4C9D9d26e8bD;
    // https://etherscan.io/address/0xBb5b03E920cF702De5A3bA9Fc1445aF4B3919c88
    address public constant new_SynthsCHF_contract = 0xBb5b03E920cF702De5A3bA9Fc1445aF4B3919c88;
    // https://etherscan.io/address/0xdAe6C79c46aB3B280Ca28259000695529cbD1339
    address public constant new_SynthsKRW_contract = 0xdAe6C79c46aB3B280Ca28259000695529cbD1339;
    // https://etherscan.io/address/0x5D4C724BFe3a228Ff0E29125Ac1571FE093700a4
    address public constant new_SynthsETH_contract = 0x5D4C724BFe3a228Ff0E29125Ac1571FE093700a4;
    // https://etherscan.io/address/0x1cB004a8e84a5CE95C1fF895EE603BaC8EC506c7
    address public constant new_SynthsBTC_contract = 0x1cB004a8e84a5CE95C1fF895EE603BaC8EC506c7;
    // https://etherscan.io/address/0xDF69bC4541b86Aa4c5A470B4347E730c38b2c3B2
    address public constant new_SynthsLINK_contract = 0xDF69bC4541b86Aa4c5A470B4347E730c38b2c3B2;
    // https://etherscan.io/address/0x942Eb6e8c029EB22103743C99985aF4F4515a559
    address public constant new_SynthsAAVE_contract = 0x942Eb6e8c029EB22103743C99985aF4F4515a559;
    // https://etherscan.io/address/0x91b82d62Ff322b8e02b86f33E9A99a813437830d
    address public constant new_SynthsADA_contract = 0x91b82d62Ff322b8e02b86f33E9A99a813437830d;
    // https://etherscan.io/address/0x75A0c1597137AA36B40b6a515D997F9a6c6eefEB
    address public constant new_SynthsDOT_contract = 0x75A0c1597137AA36B40b6a515D997F9a6c6eefEB;
    // https://etherscan.io/address/0x918b1dbf0917FdD74D03fB9434915E2ECEc89286
    address public constant new_SynthsDEFI_contract = 0x918b1dbf0917FdD74D03fB9434915E2ECEc89286;
    // https://etherscan.io/address/0x07C1E81C345A7c58d7c24072EFc5D929BD0647AD
    address public constant new_SynthsETHBTC_contract = 0x07C1E81C345A7c58d7c24072EFc5D929BD0647AD;

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](52);
        contracts[0] = address(addressresolver_i);
        contracts[1] = address(proxysynthetix_i);
        contracts[2] = address(systemstatus_i);
        contracts[3] = address(tokenstatesynthetix_i);
        contracts[4] = address(rewardescrow_i);
        contracts[5] = address(rewardsdistribution_i);
        contracts[6] = address(synthsusd_i);
        contracts[7] = address(tokenstatesusd_i);
        contracts[8] = address(proxysusd_i);
        contracts[9] = address(synthseur_i);
        contracts[10] = address(tokenstateseur_i);
        contracts[11] = address(proxyseur_i);
        contracts[12] = address(synthsjpy_i);
        contracts[13] = address(tokenstatesjpy_i);
        contracts[14] = address(proxysjpy_i);
        contracts[15] = address(synthsaud_i);
        contracts[16] = address(tokenstatesaud_i);
        contracts[17] = address(proxysaud_i);
        contracts[18] = address(synthsgbp_i);
        contracts[19] = address(tokenstatesgbp_i);
        contracts[20] = address(proxysgbp_i);
        contracts[21] = address(synthschf_i);
        contracts[22] = address(tokenstateschf_i);
        contracts[23] = address(proxyschf_i);
        contracts[24] = address(synthskrw_i);
        contracts[25] = address(tokenstateskrw_i);
        contracts[26] = address(proxyskrw_i);
        contracts[27] = address(synthsbtc_i);
        contracts[28] = address(tokenstatesbtc_i);
        contracts[29] = address(proxysbtc_i);
        contracts[30] = address(synthseth_i);
        contracts[31] = address(tokenstateseth_i);
        contracts[32] = address(proxyseth_i);
        contracts[33] = address(synthslink_i);
        contracts[34] = address(tokenstateslink_i);
        contracts[35] = address(proxyslink_i);
        contracts[36] = address(synthsada_i);
        contracts[37] = address(tokenstatesada_i);
        contracts[38] = address(proxysada_i);
        contracts[39] = address(synthsaave_i);
        contracts[40] = address(tokenstatesaave_i);
        contracts[41] = address(proxysaave_i);
        contracts[42] = address(synthsdot_i);
        contracts[43] = address(tokenstatesdot_i);
        contracts[44] = address(proxysdot_i);
        contracts[45] = address(synthsethbtc_i);
        contracts[46] = address(tokenstatesethbtc_i);
        contracts[47] = address(proxysethbtc_i);
        contracts[48] = address(synthsdefi_i);
        contracts[49] = address(tokenstatesdefi_i);
        contracts[50] = address(proxysdefi_i);
        contracts[51] = address(issuer_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_0();
        // Rebuild the resolver caches in all MixinResolver contracts - batch 1;
        addressresolver_rebuildCaches_1();
        // Rebuild the resolver caches in all MixinResolver contracts - batch 2;
        addressresolver_rebuildCaches_2();
        // Ensure the SNX proxy has the correct Synthetix target set;
        proxysynthetix_i.setTarget(Proxyable(new_Synthetix_contract));
        // Ensure Issuer contract can suspend issuance - see SIP-165;
        systemstatus_i.updateAccessControl("Issuance", new_Issuer_contract, true, false);
        // Ensure the Synthetix contract can write to its TokenState contract;
        tokenstatesynthetix_i.setAssociatedContract(new_Synthetix_contract);
        // Ensure the legacy RewardEscrow contract is connected to the Synthetix contract;
        rewardescrow_i.setSynthetix(ISynthetix(new_Synthetix_contract));
        // Ensure the RewardsDistribution has Synthetix set as its authority for distribution;
        rewardsdistribution_i.setAuthority(new_Synthetix_contract);
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sUSD();
        // Ensure the sUSD synth can write to its TokenState;
        tokenstatesusd_i.setAssociatedContract(new_SynthsUSD_contract);
        // Ensure the sUSD synth Proxy is correctly connected to the Synth;
        proxysusd_i.setTarget(Proxyable(new_SynthsUSD_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sEUR();
        // Ensure the sEUR synth can write to its TokenState;
        tokenstateseur_i.setAssociatedContract(new_SynthsEUR_contract);
        // Ensure the sEUR synth Proxy is correctly connected to the Synth;
        proxyseur_i.setTarget(Proxyable(new_SynthsEUR_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sJPY();
        // Ensure the sJPY synth can write to its TokenState;
        tokenstatesjpy_i.setAssociatedContract(new_SynthsJPY_contract);
        // Ensure the sJPY synth Proxy is correctly connected to the Synth;
        proxysjpy_i.setTarget(Proxyable(new_SynthsJPY_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sAUD();
        // Ensure the sAUD synth can write to its TokenState;
        tokenstatesaud_i.setAssociatedContract(new_SynthsAUD_contract);
        // Ensure the sAUD synth Proxy is correctly connected to the Synth;
        proxysaud_i.setTarget(Proxyable(new_SynthsAUD_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sGBP();
        // Ensure the sGBP synth can write to its TokenState;
        tokenstatesgbp_i.setAssociatedContract(new_SynthsGBP_contract);
        // Ensure the sGBP synth Proxy is correctly connected to the Synth;
        proxysgbp_i.setTarget(Proxyable(new_SynthsGBP_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sCHF();
        // Ensure the sCHF synth can write to its TokenState;
        tokenstateschf_i.setAssociatedContract(new_SynthsCHF_contract);
        // Ensure the sCHF synth Proxy is correctly connected to the Synth;
        proxyschf_i.setTarget(Proxyable(new_SynthsCHF_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sKRW();
        // Ensure the sKRW synth can write to its TokenState;
        tokenstateskrw_i.setAssociatedContract(new_SynthsKRW_contract);
        // Ensure the sKRW synth Proxy is correctly connected to the Synth;
        proxyskrw_i.setTarget(Proxyable(new_SynthsKRW_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sBTC();
        // Ensure the sBTC synth can write to its TokenState;
        tokenstatesbtc_i.setAssociatedContract(new_SynthsBTC_contract);
        // Ensure the sBTC synth Proxy is correctly connected to the Synth;
        proxysbtc_i.setTarget(Proxyable(new_SynthsBTC_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sETH();
        // Ensure the sETH synth can write to its TokenState;
        tokenstateseth_i.setAssociatedContract(new_SynthsETH_contract);
        // Ensure the sETH synth Proxy is correctly connected to the Synth;
        proxyseth_i.setTarget(Proxyable(new_SynthsETH_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sLINK();
        // Ensure the sLINK synth can write to its TokenState;
        tokenstateslink_i.setAssociatedContract(new_SynthsLINK_contract);
        // Ensure the sLINK synth Proxy is correctly connected to the Synth;
        proxyslink_i.setTarget(Proxyable(new_SynthsLINK_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sADA();
        // Ensure the sADA synth can write to its TokenState;
        tokenstatesada_i.setAssociatedContract(new_SynthsADA_contract);
        // Ensure the sADA synth Proxy is correctly connected to the Synth;
        proxysada_i.setTarget(Proxyable(new_SynthsADA_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sAAVE();
        // Ensure the sAAVE synth can write to its TokenState;
        tokenstatesaave_i.setAssociatedContract(new_SynthsAAVE_contract);
        // Ensure the sAAVE synth Proxy is correctly connected to the Synth;
        proxysaave_i.setTarget(Proxyable(new_SynthsAAVE_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sDOT();
        // Ensure the sDOT synth can write to its TokenState;
        tokenstatesdot_i.setAssociatedContract(new_SynthsDOT_contract);
        // Ensure the sDOT synth Proxy is correctly connected to the Synth;
        proxysdot_i.setTarget(Proxyable(new_SynthsDOT_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sETHBTC();
        // Ensure the sETHBTC synth can write to its TokenState;
        tokenstatesethbtc_i.setAssociatedContract(new_SynthsETHBTC_contract);
        // Ensure the sETHBTC synth Proxy is correctly connected to the Synth;
        proxysethbtc_i.setTarget(Proxyable(new_SynthsETHBTC_contract));
        // Ensure the new synth has the totalSupply from the previous one;
        copyTotalSupplyFrom_sDEFI();
        // Ensure the sDEFI synth can write to its TokenState;
        tokenstatesdefi_i.setAssociatedContract(new_SynthsDEFI_contract);
        // Ensure the sDEFI synth Proxy is correctly connected to the Synth;
        proxysdefi_i.setTarget(Proxyable(new_SynthsDEFI_contract));
        // Add synths to the Issuer contract - batch 1;
        issuer_addSynths_70();

        // NOMINATE OWNERSHIP back to owner for aforementioned contracts
        nominateAll();
    }

    function acceptAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            Owned(contracts[i]).acceptOwnership();
        }
    }

    function nominateAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            returnOwnership(contracts[i]);
        }
    }

    function addressresolver_importAddresses_0() internal {
        bytes32[] memory addressresolver_importAddresses_names_0_0 = new bytes32[](17);
        addressresolver_importAddresses_names_0_0[0] = bytes32("Synthetix");
        addressresolver_importAddresses_names_0_0[1] = bytes32("Issuer");
        addressresolver_importAddresses_names_0_0[2] = bytes32("SynthsUSD");
        addressresolver_importAddresses_names_0_0[3] = bytes32("SynthsJPY");
        addressresolver_importAddresses_names_0_0[4] = bytes32("SynthsEUR");
        addressresolver_importAddresses_names_0_0[5] = bytes32("SynthsAUD");
        addressresolver_importAddresses_names_0_0[6] = bytes32("SynthsGBP");
        addressresolver_importAddresses_names_0_0[7] = bytes32("SynthsCHF");
        addressresolver_importAddresses_names_0_0[8] = bytes32("SynthsKRW");
        addressresolver_importAddresses_names_0_0[9] = bytes32("SynthsETH");
        addressresolver_importAddresses_names_0_0[10] = bytes32("SynthsBTC");
        addressresolver_importAddresses_names_0_0[11] = bytes32("SynthsLINK");
        addressresolver_importAddresses_names_0_0[12] = bytes32("SynthsAAVE");
        addressresolver_importAddresses_names_0_0[13] = bytes32("SynthsADA");
        addressresolver_importAddresses_names_0_0[14] = bytes32("SynthsDOT");
        addressresolver_importAddresses_names_0_0[15] = bytes32("SynthsDEFI");
        addressresolver_importAddresses_names_0_0[16] = bytes32("SynthsETHBTC");
        address[] memory addressresolver_importAddresses_destinations_0_1 = new address[](17);
        addressresolver_importAddresses_destinations_0_1[0] = address(new_Synthetix_contract);
        addressresolver_importAddresses_destinations_0_1[1] = address(new_Issuer_contract);
        addressresolver_importAddresses_destinations_0_1[2] = address(new_SynthsUSD_contract);
        addressresolver_importAddresses_destinations_0_1[3] = address(new_SynthsJPY_contract);
        addressresolver_importAddresses_destinations_0_1[4] = address(new_SynthsEUR_contract);
        addressresolver_importAddresses_destinations_0_1[5] = address(new_SynthsAUD_contract);
        addressresolver_importAddresses_destinations_0_1[6] = address(new_SynthsGBP_contract);
        addressresolver_importAddresses_destinations_0_1[7] = address(new_SynthsCHF_contract);
        addressresolver_importAddresses_destinations_0_1[8] = address(new_SynthsKRW_contract);
        addressresolver_importAddresses_destinations_0_1[9] = address(new_SynthsETH_contract);
        addressresolver_importAddresses_destinations_0_1[10] = address(new_SynthsBTC_contract);
        addressresolver_importAddresses_destinations_0_1[11] = address(new_SynthsLINK_contract);
        addressresolver_importAddresses_destinations_0_1[12] = address(new_SynthsAAVE_contract);
        addressresolver_importAddresses_destinations_0_1[13] = address(new_SynthsADA_contract);
        addressresolver_importAddresses_destinations_0_1[14] = address(new_SynthsDOT_contract);
        addressresolver_importAddresses_destinations_0_1[15] = address(new_SynthsDEFI_contract);
        addressresolver_importAddresses_destinations_0_1[16] = address(new_SynthsETHBTC_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_0_0,
            addressresolver_importAddresses_destinations_0_1
        );
    }

    function addressresolver_rebuildCaches_1() internal {
        MixinResolver[] memory addressresolver_rebuildCaches_destinations_1_0 = new MixinResolver[](20);
        addressresolver_rebuildCaches_destinations_1_0[0] = MixinResolver(0xDA4eF8520b1A57D7d63f1E249606D1A459698876);
        addressresolver_rebuildCaches_destinations_1_0[1] = MixinResolver(0x0e5fe1b05612581576e9A3dB048416d0B1E3C425);
        addressresolver_rebuildCaches_destinations_1_0[2] = MixinResolver(0xf79603a71144e415730C1A6f57F366E4Ea962C00);
        addressresolver_rebuildCaches_destinations_1_0[3] = MixinResolver(0xD64D83829D92B5bdA881f6f61A4e4E27Fc185387);
        addressresolver_rebuildCaches_destinations_1_0[4] = MixinResolver(new_Issuer_contract);
        addressresolver_rebuildCaches_destinations_1_0[5] = MixinResolver(0x62922670313bf6b41C580143d1f6C173C5C20019);
        addressresolver_rebuildCaches_destinations_1_0[6] = MixinResolver(0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F);
        addressresolver_rebuildCaches_destinations_1_0[7] = MixinResolver(new_Synthetix_contract);
        addressresolver_rebuildCaches_destinations_1_0[8] = MixinResolver(0x89FCb32F29e509cc42d0C8b6f058C993013A843F);
        addressresolver_rebuildCaches_destinations_1_0[9] = MixinResolver(0x3B2f389AeE480238A49E3A9985cd6815370712eB);
        addressresolver_rebuildCaches_destinations_1_0[10] = MixinResolver(0x1620Aa736939597891C1940CF0d28b82566F9390);
        addressresolver_rebuildCaches_destinations_1_0[11] = MixinResolver(0xeAcaEd9581294b1b5cfb6B941d4B8B81B2005437);
        addressresolver_rebuildCaches_destinations_1_0[12] = MixinResolver(0xe533139Af961c9747356D947838c98451015e234);
        addressresolver_rebuildCaches_destinations_1_0[13] = MixinResolver(new_SynthsUSD_contract);
        addressresolver_rebuildCaches_destinations_1_0[14] = MixinResolver(new_SynthsEUR_contract);
        addressresolver_rebuildCaches_destinations_1_0[15] = MixinResolver(new_SynthsJPY_contract);
        addressresolver_rebuildCaches_destinations_1_0[16] = MixinResolver(new_SynthsAUD_contract);
        addressresolver_rebuildCaches_destinations_1_0[17] = MixinResolver(new_SynthsGBP_contract);
        addressresolver_rebuildCaches_destinations_1_0[18] = MixinResolver(new_SynthsCHF_contract);
        addressresolver_rebuildCaches_destinations_1_0[19] = MixinResolver(new_SynthsKRW_contract);
        addressresolver_i.rebuildCaches(addressresolver_rebuildCaches_destinations_1_0);
    }

    function addressresolver_rebuildCaches_2() internal {
        MixinResolver[] memory addressresolver_rebuildCaches_destinations_2_0 = new MixinResolver[](16);
        addressresolver_rebuildCaches_destinations_2_0[0] = MixinResolver(new_SynthsBTC_contract);
        addressresolver_rebuildCaches_destinations_2_0[1] = MixinResolver(new_SynthsETH_contract);
        addressresolver_rebuildCaches_destinations_2_0[2] = MixinResolver(new_SynthsLINK_contract);
        addressresolver_rebuildCaches_destinations_2_0[3] = MixinResolver(new_SynthsADA_contract);
        addressresolver_rebuildCaches_destinations_2_0[4] = MixinResolver(new_SynthsAAVE_contract);
        addressresolver_rebuildCaches_destinations_2_0[5] = MixinResolver(new_SynthsDOT_contract);
        addressresolver_rebuildCaches_destinations_2_0[6] = MixinResolver(new_SynthsETHBTC_contract);
        addressresolver_rebuildCaches_destinations_2_0[7] = MixinResolver(new_SynthsDEFI_contract);
        addressresolver_rebuildCaches_destinations_2_0[8] = MixinResolver(0xC1AAE9d18bBe386B102435a8632C8063d31e747C);
        addressresolver_rebuildCaches_destinations_2_0[9] = MixinResolver(0x067e398605E84F2D0aEEC1806e62768C5110DCc6);
        addressresolver_rebuildCaches_destinations_2_0[10] = MixinResolver(0x02f9bC46beD33acdB9cb002fe346734CeF8a9480);
        addressresolver_rebuildCaches_destinations_2_0[11] = MixinResolver(0x5c8344bcdC38F1aB5EB5C1d4a35DdEeA522B5DfA);
        addressresolver_rebuildCaches_destinations_2_0[12] = MixinResolver(0xaa03aB31b55DceEeF845C8d17890CC61cD98eD04);
        addressresolver_rebuildCaches_destinations_2_0[13] = MixinResolver(0x1F2c3a1046c32729862fcB038369696e3273a516);
        addressresolver_rebuildCaches_destinations_2_0[14] = MixinResolver(0x7C22547779c8aa41bAE79E03E8383a0BefBCecf0);
        addressresolver_rebuildCaches_destinations_2_0[15] = MixinResolver(0x7A3d898b717e50a96fd8b232E9d15F0A547A7eeb);
        addressresolver_i.rebuildCaches(addressresolver_rebuildCaches_destinations_2_0);
    }

    function copyTotalSupplyFrom_sUSD() internal {
        // https://etherscan.io/address/0x7df9b3f8f1C011D8BD707430e97E747479DD532a;
        Synth existingSynth = Synth(0x7df9b3f8f1C011D8BD707430e97E747479DD532a);
        // https://etherscan.io/address/0x10A5F7D9D65bCc2734763444D4940a31b109275f;
        Synth newSynth = Synth(0x10A5F7D9D65bCc2734763444D4940a31b109275f);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sEUR() internal {
        // https://etherscan.io/address/0x1b06a00Df0B27E7871E753720D4917a7D1aac68b;
        Synth existingSynth = Synth(0x1b06a00Df0B27E7871E753720D4917a7D1aac68b);
        // https://etherscan.io/address/0xa8E31E3C38aDD6052A9407298FAEB8fD393A6cF9;
        Synth newSynth = Synth(0xa8E31E3C38aDD6052A9407298FAEB8fD393A6cF9);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sJPY() internal {
        // https://etherscan.io/address/0xB82f11f3168Ece7D56fe6a5679567948090de7C5;
        Synth existingSynth = Synth(0xB82f11f3168Ece7D56fe6a5679567948090de7C5);
        // https://etherscan.io/address/0xE1cc2332852B2Ac0dA59A1f9D3051829f4eF3c1C;
        Synth newSynth = Synth(0xE1cc2332852B2Ac0dA59A1f9D3051829f4eF3c1C);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sAUD() internal {
        // https://etherscan.io/address/0xC4546bDd93cDAADA6994e84Fb6F2722C620B019C;
        Synth existingSynth = Synth(0xC4546bDd93cDAADA6994e84Fb6F2722C620B019C);
        // https://etherscan.io/address/0xfb020CA7f4e8C4a5bBBe060f59a249c6275d2b69;
        Synth newSynth = Synth(0xfb020CA7f4e8C4a5bBBe060f59a249c6275d2b69);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sGBP() internal {
        // https://etherscan.io/address/0xAE7A2C1e326e59f2dB2132652115a59E8Adb5eBf;
        Synth existingSynth = Synth(0xAE7A2C1e326e59f2dB2132652115a59E8Adb5eBf);
        // https://etherscan.io/address/0xdc883b9d9Ee16f74bE08826E68dF4C9D9d26e8bD;
        Synth newSynth = Synth(0xdc883b9d9Ee16f74bE08826E68dF4C9D9d26e8bD);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sCHF() internal {
        // https://etherscan.io/address/0xCC83a57B080a4c7C86F0bB892Bc180C8C7F8791d;
        Synth existingSynth = Synth(0xCC83a57B080a4c7C86F0bB892Bc180C8C7F8791d);
        // https://etherscan.io/address/0xBb5b03E920cF702De5A3bA9Fc1445aF4B3919c88;
        Synth newSynth = Synth(0xBb5b03E920cF702De5A3bA9Fc1445aF4B3919c88);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sKRW() internal {
        // https://etherscan.io/address/0x527637bE27640d6C3e751d24DC67129A6d13E11C;
        Synth existingSynth = Synth(0x527637bE27640d6C3e751d24DC67129A6d13E11C);
        // https://etherscan.io/address/0xdAe6C79c46aB3B280Ca28259000695529cbD1339;
        Synth newSynth = Synth(0xdAe6C79c46aB3B280Ca28259000695529cbD1339);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sBTC() internal {
        // https://etherscan.io/address/0x18FcC34bdEaaF9E3b69D2500343527c0c995b1d6;
        Synth existingSynth = Synth(0x18FcC34bdEaaF9E3b69D2500343527c0c995b1d6);
        // https://etherscan.io/address/0x1cB004a8e84a5CE95C1fF895EE603BaC8EC506c7;
        Synth newSynth = Synth(0x1cB004a8e84a5CE95C1fF895EE603BaC8EC506c7);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sETH() internal {
        // https://etherscan.io/address/0x4FB63c954Ef07EC74335Bb53835026C75DD91dC6;
        Synth existingSynth = Synth(0x4FB63c954Ef07EC74335Bb53835026C75DD91dC6);
        // https://etherscan.io/address/0x5D4C724BFe3a228Ff0E29125Ac1571FE093700a4;
        Synth newSynth = Synth(0x5D4C724BFe3a228Ff0E29125Ac1571FE093700a4);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sLINK() internal {
        // https://etherscan.io/address/0xe08518bA3d2467F7cA50eFE68AA00C5f78D4f3D6;
        Synth existingSynth = Synth(0xe08518bA3d2467F7cA50eFE68AA00C5f78D4f3D6);
        // https://etherscan.io/address/0xDF69bC4541b86Aa4c5A470B4347E730c38b2c3B2;
        Synth newSynth = Synth(0xDF69bC4541b86Aa4c5A470B4347E730c38b2c3B2);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sADA() internal {
        // https://etherscan.io/address/0xB34F4d7c207D8979D05EDb0F63f174764Bd67825;
        Synth existingSynth = Synth(0xB34F4d7c207D8979D05EDb0F63f174764Bd67825);
        // https://etherscan.io/address/0x91b82d62Ff322b8e02b86f33E9A99a813437830d;
        Synth newSynth = Synth(0x91b82d62Ff322b8e02b86f33E9A99a813437830d);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sAAVE() internal {
        // https://etherscan.io/address/0x95aE43E5E96314E4afffcf19D9419111cd11169e;
        Synth existingSynth = Synth(0x95aE43E5E96314E4afffcf19D9419111cd11169e);
        // https://etherscan.io/address/0x942Eb6e8c029EB22103743C99985aF4F4515a559;
        Synth newSynth = Synth(0x942Eb6e8c029EB22103743C99985aF4F4515a559);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sDOT() internal {
        // https://etherscan.io/address/0x27b45A4208b87A899009f45888139882477Acea5;
        Synth existingSynth = Synth(0x27b45A4208b87A899009f45888139882477Acea5);
        // https://etherscan.io/address/0x75A0c1597137AA36B40b6a515D997F9a6c6eefEB;
        Synth newSynth = Synth(0x75A0c1597137AA36B40b6a515D997F9a6c6eefEB);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sETHBTC() internal {
        // https://etherscan.io/address/0x6DF798ec713b33BE823b917F27820f2aA0cf7662;
        Synth existingSynth = Synth(0x6DF798ec713b33BE823b917F27820f2aA0cf7662);
        // https://etherscan.io/address/0x07C1E81C345A7c58d7c24072EFc5D929BD0647AD;
        Synth newSynth = Synth(0x07C1E81C345A7c58d7c24072EFc5D929BD0647AD);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function copyTotalSupplyFrom_sDEFI() internal {
        // https://etherscan.io/address/0xf533aeEe48f0e04E30c2F6A1f19FbB675469a124;
        Synth existingSynth = Synth(0xf533aeEe48f0e04E30c2F6A1f19FbB675469a124);
        // https://etherscan.io/address/0x918b1dbf0917FdD74D03fB9434915E2ECEc89286;
        Synth newSynth = Synth(0x918b1dbf0917FdD74D03fB9434915E2ECEc89286);
        newSynth.setTotalSupply(existingSynth.totalSupply());
    }

    function issuer_addSynths_70() internal {
        ISynth[] memory issuer_addSynths_synthsToAdd_70_0 = new ISynth[](15);
        issuer_addSynths_synthsToAdd_70_0[0] = ISynth(new_SynthsUSD_contract);
        issuer_addSynths_synthsToAdd_70_0[1] = ISynth(new_SynthsEUR_contract);
        issuer_addSynths_synthsToAdd_70_0[2] = ISynth(new_SynthsJPY_contract);
        issuer_addSynths_synthsToAdd_70_0[3] = ISynth(new_SynthsAUD_contract);
        issuer_addSynths_synthsToAdd_70_0[4] = ISynth(new_SynthsGBP_contract);
        issuer_addSynths_synthsToAdd_70_0[5] = ISynth(new_SynthsCHF_contract);
        issuer_addSynths_synthsToAdd_70_0[6] = ISynth(new_SynthsKRW_contract);
        issuer_addSynths_synthsToAdd_70_0[7] = ISynth(new_SynthsBTC_contract);
        issuer_addSynths_synthsToAdd_70_0[8] = ISynth(new_SynthsETH_contract);
        issuer_addSynths_synthsToAdd_70_0[9] = ISynth(new_SynthsLINK_contract);
        issuer_addSynths_synthsToAdd_70_0[10] = ISynth(new_SynthsADA_contract);
        issuer_addSynths_synthsToAdd_70_0[11] = ISynth(new_SynthsAAVE_contract);
        issuer_addSynths_synthsToAdd_70_0[12] = ISynth(new_SynthsDOT_contract);
        issuer_addSynths_synthsToAdd_70_0[13] = ISynth(new_SynthsETHBTC_contract);
        issuer_addSynths_synthsToAdd_70_0[14] = ISynth(new_SynthsDEFI_contract);
        issuer_i.addSynths(issuer_addSynths_synthsToAdd_70_0);
    }
}