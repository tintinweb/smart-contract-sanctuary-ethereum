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

interface ICollateralManager {
    // Manager information
    function hasCollateral(address collateral) external view returns (bool);

    function isSynthManaged(bytes32 currencyKey) external view returns (bool);

    // State information
    function long(bytes32 synth) external view returns (uint256 amount);

    function short(bytes32 synth) external view returns (uint256 amount);

    function totalLong() external view returns (uint256 susdValue, bool anyRateIsInvalid);

    function totalShort() external view returns (uint256 susdValue, bool anyRateIsInvalid);

    function getBorrowRate() external view returns (uint256 borrowRate, bool anyRateIsInvalid);

    function getShortRate(bytes32 synth) external view returns (uint256 shortRate, bool rateIsInvalid);

    function getRatesAndTime(uint256 index)
        external
        view
        returns (
            uint256 entryRate,
            uint256 lastRate,
            uint256 lastUpdated,
            uint256 newIndex
        );

    function getShortRatesAndTime(bytes32 currency, uint256 index)
        external
        view
        returns (
            uint256 entryRate,
            uint256 lastRate,
            uint256 lastUpdated,
            uint256 newIndex
        );

    function exceedsDebtLimit(uint256 amount, bytes32 currency) external view returns (bool canIssue, bool anyRateIsInvalid);

    function areSynthsAndCurrenciesSet(bytes32[] calldata requiredSynthNamesInResolver, bytes32[] calldata synthKeys)
        external
        view
        returns (bool);

    function areShortableSynthsSet(bytes32[] calldata requiredSynthNamesInResolver, bytes32[] calldata synthKeys)
        external
        view
        returns (bool);

    // Loans
    function getNewLoanId() external returns (uint256 id);

    // Manager mutative
    function addCollaterals(address[] calldata collaterals) external;

    function removeCollaterals(address[] calldata collaterals) external;

    function addSynths(bytes32[] calldata synthNamesInResolver, bytes32[] calldata synthKeys) external;

    function removeSynths(bytes32[] calldata synths, bytes32[] calldata synthKeys) external;

    function addShortableSynths(bytes32[] calldata requiredSynthNamesInResolver, bytes32[] calldata synthKeys) external;

    function removeShortableSynths(bytes32[] calldata synths) external;

    // State mutative

    function incrementLongs(bytes32 synth, uint256 amount) external;

    function decrementLongs(bytes32 synth, uint256 amount) external;

    function incrementShorts(bytes32 synth, uint256 amount) external;

    function decrementShorts(bytes32 synth, uint256 amount) external;

    function accrueInterest(
        uint256 interestIndex,
        bytes32 currency,
        bool isShort
    ) external returns (uint256 difference, uint256 index);

    function updateBorrowRatesCollateral(uint256 rate) external;

    function updateShortRatesCollateral(bytes32 currency, uint256 rate) external;
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

interface IExchangeAgent {
    function getSYNTHExpectedAmount(address _tokenIn, uint256 _amountIn) external view returns (uint256);

    function getSYNTHExpectedAmountFromETH(uint256 _amountIn) external view returns (uint256);

    function getUSDCForSYNTH(uint256 amountIn) external view returns (uint256);

    function swapTokenToSYNTH(
        address _tokenIn,
        uint256 _amountIn,
        address _to
    ) external returns (uint256);

    function swapETHToSYNTH(uint256 _amountIn, address _to) external payable returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiquidatorRewards {
    // Views
    function totalLiquidates() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function earnedInUSDC(address account) external view returns (uint256);

    function earnedCrossChainInUSDC(address account) external view returns (uint256);

    function rewardsToIncrease(uint256 debtShareToBurn, uint256 notifyAmount) external view returns (uint256);

    // Mutative
    function rewardRestitution(address _to, uint256 _amount) external returns (bool);

    function getReward(address account) external payable;

    function notifyRewardAmount(uint256 reward) external;

    function updateEntry(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function balanceOf(address account) external view returns (uint256);

    function balanceOfInUSDC(address account) external view returns (uint256);

    function balanceOfCrossChainInUSDC(address account) external view returns (uint256);

    function numVestingEntries(address account) external view returns (uint256);

    function totalEscrowedBalance() external view returns (uint256);

    function totalEscrowedAccountBalance(address account) external view returns (uint256);

    function totalVestedAccountBalance(address account) external view returns (uint256);

    function getVestingQuantity(address account, uint256[] calldata entryIDs) external view returns (uint256);

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

    function getVestingEntryClaimable(address account, uint256 entryID) external view returns (uint256);

    function getVestingEntry(address account, uint256 entryID) external view returns (uint64, uint256);

    // Mutative functions
    function vest(uint256[] calldata entryIDs) external payable;

    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) external payable;

    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external;
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

interface ISynthrAggregator {
    /* ========== VIEW FUNCTIONS ========== */
    function collateralByIssuerAggregation(bytes32 collateralKey, address account) external view returns (uint256);

    function synthTotalSupply(bytes32 currencyKey) external view returns (uint256);

    function synthBalanceOf(bytes32 currencyKey, address account) external view returns (uint256);

    function currentPeriodId() external view returns (uint128);

    function debtShareTotalSupply() external view returns (uint256);

    function debtShareBalanceOf(address account) external view returns (uint256);

    function sharePercent(address account) external view returns (uint256);

    function sharePercentOnPeriod(address account, uint256 periodId) external view returns (uint256);

    function takeDebtShareSnapShot(uint128 id) external;

    function earned(address account, uint256 debtShare) external view returns (uint256);

    function escrowedBalanceOf(address account) external view returns (uint256);

    function totalEscrowedBalance() external view returns (uint256);
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

import "./IERC20.sol";

interface ISynthRedeemer {
    // Rate of redemption - 0 for none
    function redemptions(address synthProxy) external view returns (uint256 redeemRate);

    // sUSD balance of deprecated token holder
    function balanceOf(IERC20 synthProxy, address account) external view returns (uint256 balanceOfInsUSD);

    // Full sUSD supply of token
    function totalSupply(IERC20 synthProxy) external view returns (uint256 totalSupplyInsUSD);

    function redeem(IERC20 synthProxy) external;

    function redeemAll(IERC20[] calldata synthProxies) external;

    function redeemPartial(IERC20 synthProxy, uint256 amountOfSynth) external;

    // Restricted to Issuer
    function deprecate(IERC20 synthProxy, uint256 rateToRedeem) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Owned.sol";
import "../MixinSystemSettings.sol";
import "../interfaces/IIssuer.sol";

// Libraries
import "../SafeCast.sol";
import "../SafeDecimalMath.sol";

// Internal references
// import "../interfaces/IIssuerInternalDebtCache.sol";
import "../interfaces/ISynth.sol";
import "../interfaces/ISynthetix.sol";
import "../interfaces/IFeePool.sol";
import "../interfaces/ISynthetixDebtShare.sol";
import "../interfaces/IExchanger.sol";
import "../interfaces/IExchangeRates.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILiquidator.sol";
import "../interfaces/ILiquidatorRewards.sol";
import "../interfaces/ICollateralManager.sol";
import "../interfaces/IRewardEscrowV2.sol";
import "../interfaces/ISynthRedeemer.sol";
import "../interfaces/ISystemStatus.sol";
import "../interfaces/IIssuedSynthAggregator.sol";
import "../interfaces/ISynthrAggregator.sol";
import "../interfaces/ISynthrBridge.sol";
import "../interfaces/IExchangeAgent.sol";

// import "../Proxyable.sol";
interface IProxy {
    function target() external view returns (address);
}

// https://docs.synthetix.io/contracts/source/contracts/issuer
contract SynthrIssuer is Owned, MixinSystemSettings, IIssuer {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    bytes32 public constant CONTRACT_NAME = "Issuer";

    // SIP-165: Circuit breaker for Debt Synthesis
    uint256 public constant CIRCUIT_BREAKER_SUSPENSION_REASON = 165;
    address internal constant NULL_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Available Synths which can be used with the system
    ISynth[] public availableSynths;
    mapping(bytes32 => ISynth) public synths;
    mapping(address => bytes32) public synthsByAddress;

    uint256 public lastDebtRatio;

    /* ========== ENCODED NAMES ========== */

    bytes32 internal constant sUSD = "sUSD";
    bytes32 internal constant sETH = "sETH";

    // Flexible storage names

    bytes32 internal constant LAST_ISSUE_EVENT = "lastIssueEvent";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_SYNTHETIXDEBTSHARE = "SynthetixDebtShare";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_LIQUIDATOR = "Liquidator";
    bytes32 private constant CONTRACT_SYNTHREDEEMER = "SynthRedeemer";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";

    bytes32 private constant CONTRACT_ISSUED_SYNTH_AGGREGATOR = "IssuedSynthAggregator";
    bytes32 private constant CONTRACT_LIQUIDATOR_REWARDS = "LiquidatorRewards";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_SYNTHR_BRIDGE = "SynthrBridge";
    bytes32 private constant CONTRACT_SYNTHR_AGGREGATOR = "SynthrAggregator";
    bytes32 private constant CONTRACT_EXCHANGEAGENT = "ExchangeAgent";

    // LZ Packet types
    uint16 private constant PT_SYNTH_MINT = 1; // including depositing collateral
    uint16 private constant PT_SYNTH_BURN = 3; // burn synth
    uint16 private constant PT_LIQUIDATE = 6;

    constructor(address _owner, address _resolver) Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */
    function resolverAddressesRequired() public view override returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](14);
        newAddresses[0] = CONTRACT_SYNTHETIX;
        newAddresses[1] = CONTRACT_EXCHANGER;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_SYNTHETIXDEBTSHARE;
        newAddresses[4] = CONTRACT_FEEPOOL;
        newAddresses[5] = CONTRACT_LIQUIDATOR;
        newAddresses[6] = CONTRACT_SYNTHREDEEMER;
        newAddresses[7] = CONTRACT_SYSTEMSTATUS;
        newAddresses[8] = CONTRACT_ISSUED_SYNTH_AGGREGATOR;
        newAddresses[9] = CONTRACT_LIQUIDATOR_REWARDS;
        newAddresses[10] = CONTRACT_REWARDESCROW_V2;
        newAddresses[11] = CONTRACT_SYNTHR_BRIDGE;
        newAddresses[12] = CONTRACT_SYNTHR_AGGREGATOR;
        newAddresses[13] = CONTRACT_EXCHANGEAGENT;
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

    function exchangeAgent() internal view returns (IExchangeAgent) {
        return IExchangeAgent(requireAndGetAddress(CONTRACT_EXCHANGEAGENT));
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

    function rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(requireAndGetAddress(CONTRACT_REWARDESCROW_V2));
    }

    function synthRedeemer() internal view returns (ISynthRedeemer) {
        return ISynthRedeemer(requireAndGetAddress(CONTRACT_SYNTHREDEEMER));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function issuedSynthAggregator() internal view returns (IIssuedSynthAggregator) {
        return IIssuedSynthAggregator(requireAndGetAddress(CONTRACT_ISSUED_SYNTH_AGGREGATOR));
    }

    function synthrBridge() internal view returns (ISynthrBridge) {
        return ISynthrBridge(requireAndGetAddress(CONTRACT_SYNTHR_BRIDGE));
    }

    function synthrAggregator() internal view returns (ISynthrAggregator) {
        return ISynthrAggregator(requireAndGetAddress(CONTRACT_SYNTHR_AGGREGATOR));
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
        uint256 rawIssuedSynths = issuedSynthAggregator().totalIssuedSynths();

        uint256 rawRatio = synthetixDebtShare().debtRatio();

        debt = rawIssuedSynths;
        sharesSupply = rawRatio == 0 ? 0 : debt.divideDecimalRoundPrecise(uint256(rawRatio));
        isStale = false;
    }

    function issuanceRatio() external view returns (uint256) {
        return getIssuanceRatio();
    }

    function _sharesForDebt(uint256 debtAmount) internal view returns (uint256) {
        uint256 rawRatio = synthetixDebtShare().debtRatio();

        return rawRatio == 0 ? 0 : debtAmount.divideDecimalRoundPrecise(rawRatio);
    }

    function _debtForShares(uint256 sharesAmount) internal view returns (uint256) {
        uint256 rawRatio = synthetixDebtShare().debtRatio();

        return sharesAmount.multiplyDecimalRoundPrecise(rawRatio);
    }

    function _availableCurrencyKeys() internal view returns (bytes32[] memory) {
        bytes32[] memory currencyKeys = new bytes32[](availableSynths.length);

        for (uint256 i = 0; i < availableSynths.length; i++) {
            currencyKeys[i] = synthsByAddress[address(availableSynths[i])];
        }
        return currencyKeys;
    }

    // Returns the total value of the debt pool in currency specified by `currencyKey`.
    // To return only the SNX-backed debt, set `excludeCollateral` to true.
    function _totalIssuedSynths(bytes32 currencyKey) internal view returns (uint256 totalIssued) {
        totalIssued = issuedSynthAggregator().totalIssuedSynthPerAsset(currencyKey);
    }

    function _debtBalanceOfAndTotalDebt(uint256 debtShareBalance, bytes32 currencyKey)
        internal
        view
        returns (
            uint256 debtBalance,
            uint256 totalSystemValue,
            bool anyRateIsInvalid
        )
    {
        // What's the total value of the system excluding ETH backed synths in their requested currency?
        (uint256 snxBackedAmount, , bool debtInfoStale) = allNetworksDebtInfo();

        if (debtShareBalance == 0) {
            return (0, snxBackedAmount, debtInfoStale);
        }
        // existing functionality requires for us to convert into the exchange rate specified by `currencyKey`
        (uint256 currencyRate, bool currencyRateInvalid) = exchangeRates().rateAndInvalid(currencyKey);

        debtBalance = _debtForShares(debtShareBalance).divideDecimalRound(currencyRate);
        totalSystemValue = snxBackedAmount;

        anyRateIsInvalid = currencyRateInvalid || debtInfoStale;
    }

    function _canBurnSynths(address account) internal view returns (bool) {
        return block.timestamp >= _lastIssueEvent(account).add(getMinimumStakeTime());
    }

    function _lastIssueEvent(address account) internal view returns (uint256) {
        //  Get the timestamp of the last issue this account made
        return flexibleStorage().getUIntValue(CONTRACT_NAME, keccak256(abi.encodePacked(LAST_ISSUE_EVENT, account)));
    }

    function _liquidationFixFactor() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FIX_FACTOR);
    }

    // get remaining issuable synth amount on the chain but not cross chain
    function _remainingIssuableSynths(address _issuer)
        internal
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt,
            bool anyRateIsInvalid
        )
    {
        (alreadyIssued, totalSystemDebt, anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(
            synthetixDebtShare().balanceOf(_issuer),
            sUSD
        );
        uint256 issuable = _maxIssuableSynths(_issuer);
        maxIssuable = issuable;
        anyRateIsInvalid = anyRateIsInvalid;

        if (alreadyIssued >= maxIssuable) {
            maxIssuable = 0;
        } else {
            maxIssuable = maxIssuable.sub(alreadyIssued);
        }
    }

    function _maxIssuableSynths(address _issuer) internal view returns (uint256) {
        // What is the value of their SNX balance in sUSD
        uint256 destinationValue = _collateral(_issuer);

        // They're allowed to issue up to issuanceRatio of that value
        return destinationValue.multiplyDecimal(getIssuanceRatio());
    }

    function _maxIssuableSynthsCrossChain(address _issuer) internal view returns (uint256) {
        // What is the value of their SNX balance in sUSD
        uint256 destinationValue = _collateralCrossChain(_issuer);

        // They're allowed to issue up to issuanceRatio of that value
        return destinationValue.multiplyDecimal(getIssuanceRatio());
    }

    function _collateralisationRatioCrossChain(address _issuer) internal view returns (uint256, bool) {
        uint256 totalOwnedSynthetix = _collateralCrossChain(_issuer);
        (uint256 debtBalance, , bool anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(
            synthetixDebtShare().balanceOfCrossChain(_issuer),
            sUSD
        );

        // it's more gas intensive to put this check here if they have 0 SNX, but it complies with the interface
        if (totalOwnedSynthetix == 0) return (0, anyRateIsInvalid);

        return (debtBalance.divideDecimalRound(totalOwnedSynthetix), anyRateIsInvalid);
    }

    function _collateralisationRatio(address _issuer) internal view returns (uint256, bool) {
        uint256 totalOwnedSynthetix = _collateral(_issuer);
        (uint256 debtBalance, , bool anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(
            synthetixDebtShare().balanceOf(_issuer),
            sUSD
        );
        // it's more gas intensive to put this check here if they have 0 SNX, but it complies with the interface
        if (totalOwnedSynthetix == 0) return (0, anyRateIsInvalid);

        return (debtBalance.divideDecimalRound(totalOwnedSynthetix), anyRateIsInvalid);
    }

    function _collateralCrossChain(address account) internal view returns (uint256) {
        uint256 balance = IERC20(address(synthetix())).balanceOf(account);

        if (address(rewardEscrowV2()) != address(0)) {
            balance = balance.add(rewardEscrowV2().balanceOfCrossChainInUSDC(account));
        }

        if (address(liquidatorRewards()) != address(0)) {
            balance = balance.add(liquidatorRewards().earnedCrossChainInUSDC(account));
        }

        return balance;
    }

    function _collateral(address account) internal view returns (uint256) {
        uint256 balance = synthetix().chainBalanceOf(account);

        if (address(rewardEscrowV2()) != address(0)) {
            balance = balance.add(rewardEscrowV2().balanceOfInUSDC(account));
        }

        if (address(liquidatorRewards()) != address(0)) {
            balance = balance.add(liquidatorRewards().earnedInUSDC(account));
        }

        return balance;
    }

    function minimumStakeTime() external view returns (uint256) {
        return getMinimumStakeTime();
    }

    function canBurnSynths(address account) external view returns (bool) {
        return _canBurnSynths(account);
    }

    function availableCurrencyKeys() external view returns (bytes32[] memory) {
        return _availableCurrencyKeys();
    }

    function availableSynthCount() external view returns (uint256) {
        return availableSynths.length;
    }

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint256 totalIssued) {
        totalIssued = _totalIssuedSynths(currencyKey);
    }

    function lastIssueEvent(address account) external view returns (uint256) {
        return _lastIssueEvent(account);
    }

    function collateralisationRatioCrossChain(address _issuer) external view returns (uint256 cratio) {
        (cratio, ) = _collateralisationRatioCrossChain(_issuer);
    }

    function collateralisationRatio(address _issuer) external view returns (uint256 cratio) {
        (cratio, ) = _collateralisationRatio(_issuer);
    }

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint256 cratio, bool anyRateIsInvalid)
    {
        return _collateralisationRatio(_issuer);
    }

    function collateralCrossChain(address account) external view returns (uint256) {
        return _collateralCrossChain(account);
    }

    function collateral(address account) external view returns (uint256) {
        return _collateral(account);
    }

    function debtBalanceOf(address _issuer) external view returns (uint256 debtBalance) {
        // What was their initial debt ownership?
        uint256 debtShareBalance = synthetixDebtShare().balanceOf(_issuer);

        // If it's zero, they haven't issued, and they have no debt.
        if (debtShareBalance == 0) return 0;

        (debtBalance, , ) = _debtBalanceOfAndTotalDebt(debtShareBalance, sUSD);
    }

    function debtBalanceOfCrossChain(address _issuer) external view returns (uint256 debtBalance) {
        // What was their initial debt ownership?
        uint256 debtShareBalance = synthetixDebtShare().balanceOfCrossChain(_issuer);

        // If it's zero, they haven't issued, and they have no debt.
        if (debtShareBalance == 0) return 0;

        (debtBalance, , ) = _debtBalanceOfAndTotalDebt(debtShareBalance, sUSD);
    }

    function remainingIssuableSynths(address _issuer)
        external
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt
        )
    {
        (maxIssuable, alreadyIssued, totalSystemDebt, ) = _remainingIssuableSynths(_issuer);
    }

    function maxIssuableSynths(address _issuer) external view returns (uint256) {
        uint256 maxIssuable = _maxIssuableSynths(_issuer);
        return maxIssuable;
    }

    function issuableSynthExpected(
        address _issuer,
        bytes32 _collateralKey,
        uint256 _collateralAmount,
        uint256 _cRatio
    ) external view returns (uint256 maxIssuable) {
        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        uint256 collateralInUSD = _collateralAmount.multiplyDecimal(collateralRate);
        (uint256 alreadyIssued, , ) = _debtBalanceOfAndTotalDebt(synthetixDebtShare().balanceOf(_issuer), sUSD);
        uint256 currentCollateral = _collateral(_issuer);
        uint256 desiredRatio = SafeDecimalMath.unit().divideDecimal(_cRatio);
        uint256 totalCollateralExpected = currentCollateral + collateralInUSD;

        // They're allowed to issue up to issuanceRatio of that value
        maxIssuable = totalCollateralExpected.multiplyDecimal(desiredRatio);

        if (alreadyIssued >= maxIssuable) {
            maxIssuable = 0;
        } else {
            maxIssuable = maxIssuable.sub(alreadyIssued);
        }
    }

    function checkFreeCollateral(address _issuer, bytes32 _collateralKey) external view returns (uint256 withdrawableSynthr) {
        (uint256 alreadyIssued, , ) = _debtBalanceOfAndTotalDebt(synthetixDebtShare().balanceOf(_issuer), sUSD);
        uint256 lockedCollateralValue = alreadyIssued.divideDecimalRound(getIssuanceRatio());
        uint256 currentCollateral = synthetix().chainBalanceOf(_issuer);
        uint256 currentCollateralForKey = synthetix().chainBalanceOfPerKey(_issuer, _collateralKey);
        if (lockedCollateralValue >= currentCollateral) {
            withdrawableSynthr = 0;
        } else {
            uint256 freeCollateral = currentCollateral - lockedCollateralValue;
            uint256 actualFreeCollateral = freeCollateral > currentCollateralForKey ? currentCollateralForKey : freeCollateral;
            (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
            withdrawableSynthr = actualFreeCollateral.divideDecimalRound(collateralRate);
        }
    }

    function liquidateAmount(
        address _account,
        bytes32 _collateralKey,
        bool _isSelfLiquidation
    )
        external
        view
        returns (
            uint256 totalRedeemed,
            uint256 amountToLiquidate,
            bool removeFlag
        )
    {
        (totalRedeemed, amountToLiquidate, removeFlag) = _calcLiquidateAccount(_account, _collateralKey, _isSelfLiquidation);
    }

    function getSendMintGasFee(
        address _account,
        bytes32 _collateralKey,
        uint256 _collateralAmount,
        uint256 _synthToMint,
        uint16 _destChainId,
        bool _issueMax
    ) external view returns (uint256) {
        (uint256 maxIssuable, , , ) = _remainingIssuableSynths(_account);
        if (_issueMax) {
            _synthToMint = maxIssuable;
        }
        uint256 debtShares = _sharesForDebt(_synthToMint);
        bytes memory lzPayload = abi.encode(
            PT_SYNTH_MINT,
            abi.encodePacked(_account),
            _collateralKey,
            _collateralAmount,
            sUSD,
            _synthToMint,
            debtShares,
            _destChainId
        );
        return synthrBridge().calcLZFee(lzPayload, PT_SYNTH_MINT);
    }

    function getSendBurnGasFee(
        address account,
        uint256 amount,
        bytes32 synthKey,
        bool burnToTarget
    ) external view returns (uint256) {
        (uint256 existingDebt, , ) = _debtBalanceOfAndTotalDebt(synthetixDebtShare().balanceOf(account), sUSD);
        // max issuable synth in USD
        uint256 maxIssuableSynthsForAccount = _maxIssuableSynths(account);
        if (burnToTarget) {
            if (existingDebt >= maxIssuableSynthsForAccount) {
                uint256 amountInUSD = existingDebt.sub(maxIssuableSynthsForAccount);
                amount = amountInUSD;
                if (synthKey != sUSD) {
                    amount = exchangeRates().effectiveValue(sUSD, amountInUSD, synthKey);
                }
            }
        }

        uint256 existingSynth = IERC20(address(synths[synthKey])).balanceOf(account);
        uint256 synthAmount = existingSynth < amount ? existingSynth : amount;

        uint256 currentDebtShare = synthetixDebtShare().balanceOf(account);
        uint256 totalSharesToRemove = _sharesForDebt(synthAmount);
        uint256 sharesToRemove = totalSharesToRemove.multiplyDecimal(currentDebtShare).divideDecimal(
            synthetixDebtShare().balanceOfCrossChain(account)
        );
        uint256 debtShare = sharesToRemove < currentDebtShare ? sharesToRemove : currentDebtShare;
        if (burnToTarget) {
            debtShare = totalSharesToRemove < currentDebtShare ? totalSharesToRemove : currentDebtShare;
        }
        bytes memory lzPayload = abi.encode(
            PT_SYNTH_BURN,
            abi.encodePacked(account),
            synthKey,
            synthAmount,
            debtShare,
            burnToTarget
        );
        return synthrBridge().calcLZFee(lzPayload, PT_SYNTH_BURN);
    }

    function getSendLiquidateGasFee(
        address _account,
        bytes32 _collateralKey,
        bool _isSelf
    ) external view returns (uint256) {
        (uint256 totalRedeemed, uint256 amountToLiquidate, ) = _calcLiquidateAccount(_account, _collateralKey, _isSelf);
        uint256 currentDebtShare = synthetixDebtShare().balanceOf(_account);
        uint256 totalSharesToRemove = _sharesForDebt(amountToLiquidate);
        uint256 sharesToRemove = totalSharesToRemove < currentDebtShare ? totalSharesToRemove : currentDebtShare;
        uint256 actualRedeemed = totalRedeemed;
        if (!_isSelf) {
            uint256 flagReward = liquidator().flagReward();
            uint256 liquidateReward = liquidator().liquidateReward();
            if (totalRedeemed > flagReward.add(liquidateReward)) {
                actualRedeemed = totalRedeemed.sub(flagReward.add(liquidateReward));
            }
        }
        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        uint256 collateralAmount = actualRedeemed.divideDecimalRound(collateralRate);
        uint256 notifyAmount;
        if (synthetix().collateralCurrency(_collateralKey) == NULL_ADDRESS) {
            notifyAmount = exchangeAgent().getSYNTHExpectedAmountFromETH(collateralAmount);
        } else {
            notifyAmount = exchangeAgent().getSYNTHExpectedAmount(
                synthetix().collateralCurrency(_collateralKey),
                collateralAmount
            );
        }
        bytes memory lzPayload = abi.encode(
            PT_LIQUIDATE,
            abi.encodePacked(_account),
            _collateralKey,
            collateralAmount,
            sharesToRemove,
            liquidatorRewards().rewardsToIncrease(sharesToRemove, notifyAmount)
        );
        return synthrBridge().calcLZFee(lzPayload, PT_LIQUIDATE);
    }

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory) {
        uint256 numKeys = currencyKeys.length;
        ISynth[] memory addresses = new ISynth[](numKeys);

        for (uint256 i = 0; i < numKeys; i++) {
            addresses[i] = synths[currencyKeys[i]];
        }

        return addresses;
    }

    function _calculateFixFactor(address _account) internal view returns (uint256) {
        uint256 targetRatio = getIssuanceRatio();
        (uint256 currentRatio, ) = _collateralisationRatio(_account);
        uint256 factor = _liquidationFixFactor();
        uint256 fixFactor = (
            SafeDecimalMath.unit().divideDecimal(targetRatio).sub(SafeDecimalMath.unit().divideDecimal(currentRatio))
        ).multiplyDecimal(factor);
        fixFactor = fixFactor.add(fixFactor < 5e16 ? 2e17 : 1e17);
        return fixFactor;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _addSynth(ISynth synth) internal {
        bytes32 currencyKey = synth.currencyKey();
        require(synths[currencyKey] == ISynth(address(0)), "Synth exists");
        require(synthsByAddress[address(synth)] == bytes32(0), "Synth address already exists");

        availableSynths.push(synth);
        synths[currencyKey] = synth;
        synthsByAddress[address(synth)] = currencyKey;

        emit SynthAdded(currencyKey, address(synth));
    }

    function addSynth(ISynth synth) external onlyOwner {
        _addSynth(synth);
    }

    function _removeSynth(bytes32 currencyKey) internal {
        address synthToRemove = address(synths[currencyKey]);
        require(synthToRemove != address(0), "Synth does not exist");
        require(currencyKey != sUSD, "Cannot remove synth");

        uint256 synthSupply = IERC20(synthToRemove).totalSupply();

        if (synthSupply > 0) {
            (uint256 amountOfsUSD, uint256 rateToRedeem, ) = exchangeRates().effectiveValueAndRates(
                currencyKey,
                synthSupply,
                "sUSD"
            );
            require(rateToRedeem > 0, "Cannot remove synth to redeem without rate");
            ISynthRedeemer _synthRedeemer = synthRedeemer();
            synths[sUSD].issue(address(_synthRedeemer), amountOfsUSD);
            // _synthRedeemer.deprecate(IERC20(address(Proxyable(synthToRemove).proxy())), rateToRedeem);
            _synthRedeemer.deprecate(IERC20(synthToRemove), rateToRedeem);
        }

        // Remove the synth from the availableSynths array.
        for (uint256 i = 0; i < availableSynths.length; i++) {
            if (address(availableSynths[i]) == synthToRemove) {
                // Copy the last synth into the place of the one we just deleted
                // If there's only one synth, this is synths[0] = synths[0].
                // If we're deleting the last one, it's also a NOOP in the same way.
                availableSynths[i] = availableSynths[availableSynths.length - 1];
                availableSynths.pop();

                break;
            }
        }

        // And remove it from the synths mapping
        delete synthsByAddress[synthToRemove];
        delete synths[currencyKey];

        emit SynthRemoved(currencyKey, synthToRemove);
    }

    function removeSynth(bytes32 currencyKey) external onlyOwner {
        _removeSynth(currencyKey);
    }

    /**
     * Function used to migrate balances from the CollateralShort contract
     * @param short The address of the CollateralShort contract to be upgraded
     * @param amount The amount of sUSD collateral to be burnt
     */
    function upgradeCollateralShort(address short, uint256 amount) external onlyOwner {
        require(short != address(0), "Issuer: invalid address");
        require(short == resolver.getAddress("CollateralShortLegacy"), "Issuer: wrong short address");
        require(address(synths[sUSD]) != address(0), "Issuer: synth doesn't exist");
        require(amount > 0, "Issuer: cannot burn 0 synths");

        exchanger().settle(short, sUSD);

        synths[sUSD].burn(short, amount);
    }

    function issueSynths(
        address from,
        uint256 amount,
        uint256 destChainId
    ) external onlySynthetix returns (uint256 synthAmount, uint256 debtShare) {
        require(amount > 0, "Issuer: cannot issue 0 synths");

        (synthAmount, debtShare) = _issueSynths(from, amount, destChainId, false);
    }

    function issueMaxSynths(address from, uint256 destChainId)
        external
        onlySynthetix
        returns (uint256 synthAmount, uint256 debtShare)
    {
        (synthAmount, debtShare) = _issueSynths(from, 0, destChainId, true);
    }

    function burnSynths(
        address from,
        bytes32 synthKey,
        uint256 amount
    ) external onlySynthetix returns (uint256 synthAmount, uint256 debtShare) {
        (synthAmount, debtShare) = _voluntaryBurnSynths(from, synthKey, amount, false);
    }

    function burnSynthsToTarget(address from, bytes32 synthKey)
        external
        onlySynthetix
        returns (uint256 synthAmount, uint256 debtShare)
    {
        (synthAmount, debtShare) = _voluntaryBurnSynths(from, synthKey, 0, true);
    }

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint256 balance
    ) external onlySynthRedeemer {
        ISynth(IProxy(deprecatedSynthProxy).target()).burn(account, balance);
    }

    /// @param account The account to be liquidated
    /// @param _collateralKey collateral key to use to fix the account's c-ratio
    /// @param isSelfLiquidation boolean to determine if this is a forced or self-invoked liquidation
    /// @return totalRedeemed the total amount of collateral to redeem
    /// @return amountToLiquidate the amount of debt (sUSD) to burn in order to fix the account's c-ratio
    /// @return sharesToRemove amount of debt share to burn in order to fix the account's c-ratio
    function liquidateAccount(
        address account,
        bytes32 _collateralKey,
        bool isSelfLiquidation
    )
        external
        onlySynthetix
        returns (
            uint256 totalRedeemed,
            uint256 amountToLiquidate,
            uint256 sharesToRemove
        )
    {
        require(liquidator().isLiquidationOpen(account, isSelfLiquidation), "Not open for liquidation");

        bool removeFlag = true;
        (totalRedeemed, amountToLiquidate, removeFlag) = _calcLiquidateAccount(account, _collateralKey, isSelfLiquidation);
        // Reduce debt shares by amount to liquidate.
        // _removeFromDebtRegister(account, amountToLiquidate, debtBalance);
        (sharesToRemove, ) = _removeCoveredDebtShare(account, amountToLiquidate, true);

        // Remove liquidation flag
        if (removeFlag) {
            liquidator().removeAccountInLiquidation(account);
        }
    }

    function _calcLiquidateAccount(
        address _account,
        bytes32 _collateralKey,
        bool _isSelf
    )
        internal
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        // Get the penalty for the liquidation type
        uint256 penalty = _isSelf ? getSelfLiquidationPenalty() : getSnxLiquidationPenalty();

        // Get the account's debt balance
        (uint256 debtBalance, , bool anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(
            synthetixDebtShare().balanceOf(_account),
            sUSD
        );

        // Get the SNX rate
        // (uint256 snxRate, bool snxRateInvalid) = exchangeRates().rateAndInvalid(SNX);
        _requireRatesNotInvalid(anyRateIsInvalid);

        // Get the total amount of SNX collateral (including escrows and rewards)
        uint256 collateralForAccount = _collateral(_account);

        // Calculate the amount of debt to liquidate to fix c-ratio
        uint256 amountToLiquidate = liquidator().calculateAmountToFixCollateral(
            debtBalance,
            collateralForAccount,
            // _snxToUSD(collateralForAccount, snxRate),
            penalty
        );

        // Get the equivalent amount of SNX for the amount to liquidate
        // Note: While amountToLiquidate takes the penalty into account, it does not accommodate for the addition of the penalty in terms of SNX.
        // Therefore, it is correct to add the penalty modification below to the totalRedeemed.
        // totalRedeemed = _usdToSnx(amountToLiquidate, snxRate).multiplyDecimal(SafeDecimalMath.unit().add(penalty));
        uint256 totalRedeemed = amountToLiquidate.multiplyDecimal(
            SafeDecimalMath.unit().add(penalty).sub(_calculateFixFactor(_account))
        );

        // The balanceOf here can be considered "transferable" since it's not escrowed,
        // and it is the only SNX that can potentially be transfered if unstaked.
        // uint256 transferableBalance = IERC20(address(synthetix())).balanceOf(account);
        uint256 transferableBalance = synthetix().chainBalanceOfPerKey(_account, _collateralKey);
        bool removeFlag = true;
        if (totalRedeemed > transferableBalance) {
            // Liquidate the account's debt based on the liquidation penalty.
            amountToLiquidate = amountToLiquidate.multiplyDecimal(transferableBalance).divideDecimal(totalRedeemed);

            // Set totalRedeemed to all transferable collateral.
            // i.e. the value of the account's staking position relative to balanceOf will be unwound.
            totalRedeemed = transferableBalance;
            removeFlag = false;
        }
        return (totalRedeemed, amountToLiquidate, removeFlag);
    }

    function setLastDebtRatio(uint256 ratio) external onlyOwner {
        lastDebtRatio = ratio;
    }

    function destIssue(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount,
        uint256 _debtShare
    ) external onlySynthrBridge {
        synths[_synthKey].issue(_account, _synthAmount);
        liquidatorRewards().updateEntry(_account);
        emit DestIssue(_account, _synthKey, _synthAmount, _debtShare);
    }

    function destBurn(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount,
        uint256 debtShare
    ) external onlySynthrBridge {
        uint256 debtToRemove = exchangeRates().effectiveValue(_synthKey, _synthAmount, sUSD);
        (uint256 actualDebtRemoved, ) = _removeCoveredDebtShare(_account, debtToRemove, false);
        liquidatorRewards().updateEntry(_account);
        emit DestBurn(_account, _synthKey, _synthAmount, actualDebtRemoved);
    }

    function setCurrentPeriodId(uint128 periodId) external {
        require(msg.sender == address(feePool()), "Must be fee pool");

        if (synthrAggregator().currentPeriodId() < periodId) {
            synthrAggregator().takeDebtShareSnapShot(periodId);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _requireRatesNotInvalid(bool anyRateIsInvalid) internal pure {
        require(!anyRateIsInvalid, "A synth or SNX rate is invalid");
    }

    function _issueSynths(
        address from,
        uint256 amount,
        uint256 destChainId,
        bool issueMax
    ) internal returns (uint256 synthAmount, uint256 debtShare) {
        // check breaker
        if (!_verifyCircuitBreaker()) {
            return (0, 0);
        }

        (uint256 maxIssuable, , , bool anyRateIsInvalid) = _remainingIssuableSynths(from);
        _requireRatesNotInvalid(anyRateIsInvalid);

        if (!issueMax) {
            require(amount <= maxIssuable, "Try again with lower amount.");
        } else {
            amount = maxIssuable;
        }

        // record issue timestamp
        _setLastIssueEvent(from);

        // Create their synths if user wants to issue synth on the chain
        if (destChainId == 0) {
            // _addToDebtRegister(from, amount);
            synths[sUSD].issue(from, amount);
        }
        // Keep track of the debt they're about to create
        debtShare = _addCoveredDebtShare(from, amount);

        synthAmount = amount;

        // // Account for the issued debt in the cache
        // debtCache().updateCachedsUSDDebt(SafeCast.toInt256(amount));
    }

    function _burnSynths(
        address debtAccount,
        address burnAccount,
        bytes32 synthKey,
        uint256 amount,
        bool burnToTarget
    ) internal returns (uint256 amountBurnt, uint256 debtShareBurnt) {
        // check breaker
        if (!_verifyCircuitBreaker()) {
            return (0, 0);
        }

        // liquidation requires sUSD to be already settled / not in waiting period

        // If they're trying to burn more debt than they actually owe, rather than fail the transaction, let's just
        // clear their debt and leave them be.
        uint256 existingDebt = IERC20(address(synths[synthKey])).balanceOf(burnAccount);
        amountBurnt = existingDebt < amount ? existingDebt : amount;

        uint256 amountBurntInUSD = amountBurnt;
        if (synthKey != sUSD) {
            amountBurntInUSD = exchangeRates().effectiveValue(synthKey, amountBurnt, sUSD);
        }
        // Remove liquidated debt from the ledger
        // debtShareBurnt = _removeFromDebtRegister(debtAccount, amountBurntInUSD, existingDebt);
        (, debtShareBurnt) = _removeCoveredDebtShare(debtAccount, amountBurntInUSD, burnToTarget ? true : false);
        // synth.burn does a safe subtraction on balance (so it will revert if there are not enough synths).
        synths[synthKey].burn(burnAccount, amountBurnt);

        // // Account for the burnt debt in the cache.
        // debtCache().updateCachedsUSDDebt(-SafeCast.toInt256(amountBurnt));
    }

    // If burning to target, `amount` is ignored, and the correct quantity of sUSD is burnt to reach the target
    // c-ratio, allowing fees to be claimed. In this case, pending settlements will be skipped as the user
    // will still have debt remaining after reaching their target.
    function _voluntaryBurnSynths(
        address from,
        bytes32 synthKey,
        uint256 amount,
        bool burnToTarget
    ) internal returns (uint256 synthAmount, uint256 debtShare) {
        // check breaker
        if (!_verifyCircuitBreaker()) {
            return (0, 0);
        }

        if (!burnToTarget) {
            // If not burning to target, then burning requires that the minimum stake time has elapsed.
            require(_canBurnSynths(from), "Please try again after sometime.");
            // First settle anything pending into sUSD as burning or issuing impacts the size of the debt pool
            (, uint256 refunded, uint256 numEntriesSettled) = exchanger().settle(from, synthKey);
            if (numEntriesSettled > 0) {
                amount = exchanger().calculateAmountAfterSettlement(from, synthKey, amount, refunded);
            }
        }

        (uint256 existingDebt, , bool anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(synthetixDebtShare().balanceOf(from), sUSD);
        // max issuable synth in USD
        uint256 maxIssuableSynthsForAccount = _maxIssuableSynths(from);
        _requireRatesNotInvalid(anyRateIsInvalid);

        if (burnToTarget) {
            if (existingDebt >= maxIssuableSynthsForAccount) {
                uint256 amountInUSD = existingDebt.sub(maxIssuableSynthsForAccount);
                amount = amountInUSD;
                if (synthKey != sUSD) {
                    amount = exchangeRates().effectiveValue(sUSD, amountInUSD, synthKey);
                }
            }
        }

        (synthAmount, debtShare) = _burnSynths(from, from, synthKey, amount, burnToTarget);

        // Check and remove liquidation if existingDebt after burning is <= maxIssuableSynths
        // Issuance ratio is fixed so should remove any liquidations
        uint256 synthAmountBurntInUSD = synthAmount;
        if (synthKey != sUSD) {
            synthAmountBurntInUSD = exchangeRates().effectiveValue(synthKey, synthAmount, sUSD);
        }
        if (existingDebt >= synthAmountBurntInUSD) {
            if (existingDebt.sub(synthAmountBurntInUSD) <= maxIssuableSynthsForAccount) {
                liquidator().removeAccountInLiquidation(from);
            }
        }
    }

    function _setLastIssueEvent(address account) internal {
        // Set the timestamp of the last issueSynths
        flexibleStorage().setUIntValue(CONTRACT_NAME, keccak256(abi.encodePacked(LAST_ISSUE_EVENT, account)), block.timestamp);
    }

    function _addCoveredDebtShare(address from, uint256 amount) internal returns (uint256) {
        ISynthetixDebtShare sds = synthetixDebtShare();
        uint256 debtShares = _sharesForDebt(amount);
        if (debtShares == 0) {
            sds.mintShare(from, amount);
            return amount;
        } else {
            sds.mintShare(from, debtShares);
            return debtShares;
        }
    }

    function _removeCoveredDebtShare(
        address from,
        uint256 amount,
        bool isMax
    ) internal returns (uint256, uint256) {
        ISynthetixDebtShare sds = synthetixDebtShare();
        uint256 currentDebtShare = sds.balanceOf(from);
        uint256 totalSharesToRemove = _sharesForDebt(amount);
        if (isMax) {
            if (currentDebtShare > totalSharesToRemove) {
                sds.burnShare(from, totalSharesToRemove);
            } else {
                sds.burnShare(from, currentDebtShare);
            }
            return (totalSharesToRemove < currentDebtShare ? totalSharesToRemove : currentDebtShare, totalSharesToRemove);
        } else {
            uint256 totalDebtShare = sds.balanceOfCrossChain(from);
            uint256 sharesToRemove = totalSharesToRemove.multiplyDecimal(currentDebtShare).divideDecimal(totalDebtShare);
            if (currentDebtShare > sharesToRemove) {
                sds.burnShare(from, sharesToRemove);
            } else {
                sds.burnShare(from, currentDebtShare);
            }
            return (sharesToRemove < currentDebtShare ? sharesToRemove : currentDebtShare, totalSharesToRemove);
        }
    }

    function _verifyCircuitBreaker() internal returns (bool) {
        uint256 rawRatio = synthetixDebtShare().debtRatio();

        uint256 deviation = _calculateDeviation(lastDebtRatio, rawRatio);

        if (deviation >= getPriceDeviationThresholdFactor()) {
            systemStatus().suspendIssuance(CIRCUIT_BREAKER_SUSPENSION_REASON);
            return false;
        }
        lastDebtRatio = rawRatio;

        return true;
    }

    function _calculateDeviation(uint256 last, uint256 fresh) internal pure returns (uint256 deviation) {
        if (last == 0) {
            deviation = 1;
        } else if (fresh == 0) {
            deviation = type(uint256).max;
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

    modifier onlyExchanger() {
        require(msg.sender == address(exchanger()), "Issuer: Only the exchanger contract can perform this action");
        _;
    }

    function _onlySynthRedeemer() internal view {
        require(msg.sender == address(synthRedeemer()), "Issuer: Only the SynthRedeemer contract can perform this action");
    }

    modifier onlySynthRedeemer() {
        _onlySynthRedeemer();
        _;
    }

    modifier onlySynthrBridge() {
        require(msg.sender == address(synthrBridge()), "Issuer: Only the SynthrBridge contract can perform this action");
        _;
    }

    modifier issuanceActive() {
        _issuanceActive();
        _;
    }

    function _issuanceActive() private view {
        systemStatus().requireIssuanceActive();
    }

    modifier synthActive(bytes32 currencyKey) {
        _synthActive(currencyKey);
        _;
    }

    function _synthActive(bytes32 currencyKey) private view {
        systemStatus().requireSynthActive(currencyKey);
    }

    /* ========== EVENTS ========== */

    event SynthAdded(bytes32 currencyKey, address synth);
    event SynthRemoved(bytes32 currencyKey, address synth);
    event DestIssue(address indexed account, bytes32 currencyKey, uint256 synthAmount, uint256 debtShare);
    event DestBurn(address indexed account, bytes32 currencyKey, uint256 synthAmount, uint256 debtShare);
}