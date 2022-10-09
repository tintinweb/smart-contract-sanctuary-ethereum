// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {BondBaseSDA, IBondAggregator, Authority} from "./bases/BondBaseSDA.sol";
import {IBondTeller} from "./interfaces/IBondTeller.sol";

/// @title Bond Fixed-Term Sequential Dutch Auctioneer
/// @notice Bond Fixed-Term Sequential Dutch Auctioneer Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The Fixed-Term Auctioneer is an implementation of the
///      Bond Base Auctioneer contract specific to creating bond markets where
///      purchases vest in a fixed amount of time after purchased (rounded to the day).
///
/// @author Oighty, Zeus, Potted Meat, indigo
contract BondFixedTermSDA is BondBaseSDA {
    /* ========== CONSTRUCTOR ========== */
    constructor(
        IBondTeller teller_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) BondBaseSDA(teller_, aggregator_, guardian_, authority_) {}

    /* ========== MARKET FUNCTIONS ========== */
    /// @inheritdoc BondBaseSDA
    function createMarket(bytes calldata params_) external override returns (uint256) {
        MarketParams memory params = abi.decode(params_, (MarketParams));
        return _createMarket(params);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {IBondSDA, IBondAuctioneer} from "../interfaces/IBondSDA.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondCallback} from "../interfaces/IBondCallback.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";

import {TransferHelper} from "../lib/TransferHelper.sol";
import {FullMath} from "../lib/FullMath.sol";

/// @title Bond Sequential Dutch Auctioneer (SDA)
/// @notice Bond Sequential Dutch Auctioneer Base Contract
/// @dev Bond Protocol is a system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The Auctioneer contract allows users to create and manage bond markets.
///      All bond pricing logic and market data is stored in the Auctioneer.
///      A Auctioneer is dependent on a Teller to serve external users and
///      an Aggregator to register new markets. This implementation of the Auctioneer
///      uses a Sequential Dutch Auction pricing system to buy a target amount of quote
///      tokens or sell a target amount of payout tokens over the duration of a market.
///
/// @author Oighty, Zeus, Potted Meat, indigo
abstract contract BondBaseSDA is IBondSDA, Auth {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== ERRORS ========== */

    error Auctioneer_OnlyMarketOwner();
    error Auctioneer_InitialPriceLessThanMin();
    error Auctioneer_MarketConcluded(uint256 conclusion_);
    error Auctioneer_MaxPayoutExceeded();
    error Auctioneer_AmountLessThanMinimum();
    error Auctioneer_NotEnoughCapacity();
    error Auctioneer_InvalidCallback();
    error Auctioneer_BadExpiry();
    error Auctioneer_InvalidParams();
    error Auctioneer_NotAuthorized();
    error Auctioneer_NewMarketsNotAllowed();

    /* ========== EVENTS ========== */

    event MarketCreated(
        uint256 indexed id,
        address indexed payoutToken,
        address indexed quoteToken,
        uint48 vesting,
        uint256 initialPrice
    );
    event MarketClosed(uint256 indexed id);
    event Tuned(uint256 indexed id, uint256 oldControlVariable, uint256 newControlVariable);

    /* ========== STATE VARIABLES ========== */

    /// @notice Main information pertaining to bond market
    mapping(uint256 => BondMarket) public markets;

    /// @notice Information used to control how a bond market changes
    mapping(uint256 => BondTerms) public terms;

    /// @notice Data needed for tuning bond market
    mapping(uint256 => BondMetadata) public metadata;

    /// @notice Control variable changes
    mapping(uint256 => Adjustment) public adjustments;

    /// @notice New address to designate as market owner. They must accept ownership to transfer permissions.
    mapping(uint256 => address) public newOwners;

    /// @notice Whether or not the auctioneer allows new markets to be created
    /// @dev    Changing to false will sunset the auctioneer after all active markets end
    bool public allowNewMarkets;

    /// @notice Whether or not the market creator is authorized to use a callback address
    mapping(address => bool) public callbackAuthorized;

    /// Sane defaults for tuning. Can be adjusted for a specific market via setters.
    uint32 public defaultTuneInterval;
    uint32 public defaultTuneAdjustment;
    /// Minimum values for decay, deposit interval, market duration and debt buffer.
    uint32 public minDebtDecayInterval;
    uint32 public minDepositInterval;
    uint32 public minMarketDuration;
    uint32 public minDebtBuffer;

    // A 'vesting' param longer than 50 years is considered a timestamp for fixed expiry.
    uint48 internal constant MAX_FIXED_TERM = 52 weeks * 50;
    uint48 internal constant FEE_DECIMALS = 1e5; // one percent equals 1000.

    // BondAggregator contract with utility functions
    IBondAggregator internal immutable _aggregator;

    // BondTeller contract that handles interactions with users and issues tokens
    IBondTeller internal immutable _teller;

    constructor(
        IBondTeller teller_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) Auth(guardian_, authority_) {
        _aggregator = aggregator_;
        _teller = teller_;

        defaultTuneInterval = 24 hours;
        defaultTuneAdjustment = 1 hours;
        minDebtDecayInterval = 3 days;
        minDepositInterval = 1 hours;
        minMarketDuration = 1 days;
        minDebtBuffer = 10000; // 10%

        allowNewMarkets = true;
    }

    /* ========== MARKET FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function createMarket(bytes calldata params_) external virtual returns (uint256);

    /// @notice core market creation logic, see IBondAuctioneer.createMarket documentation
    function _createMarket(MarketParams memory params_) internal returns (uint256) {
        {
            // Check that the auctioneer is allowing new markets to be created
            if (!allowNewMarkets) revert Auctioneer_NewMarketsNotAllowed();

            // Ensure params are in bounds
            uint8 payoutTokenDecimals = params_.payoutToken.decimals();
            uint8 quoteTokenDecimals = params_.quoteToken.decimals();

            if (payoutTokenDecimals < 6 || payoutTokenDecimals > 18)
                revert Auctioneer_InvalidParams();
            if (quoteTokenDecimals < 6 || quoteTokenDecimals > 18)
                revert Auctioneer_InvalidParams();
            if (params_.scaleAdjustment < -24 || params_.scaleAdjustment > 24)
                revert Auctioneer_InvalidParams();

            // Restrict the use of a callback address unless allowed
            if (!callbackAuthorized[msg.sender] && params_.callbackAddr != address(0))
                revert Auctioneer_NotAuthorized();
        }

        // Unit to scale calculation for this market by to ensure reasonable values
        // for price, debt, and control variable without under/overflows.
        // See IBondAuctioneer for more details.
        //
        // scaleAdjustment should be equal to (payoutDecimals - quoteDecimals) - ((payoutPriceDecimals - quotePriceDecimals) / 2)
        uint256 scale;
        unchecked {
            scale = 10**uint8(36 + params_.scaleAdjustment);
        }

        if (params_.formattedInitialPrice < params_.formattedMinimumPrice)
            revert Auctioneer_InitialPriceLessThanMin();

        // Record new market into array for later retrieval and get marketId
        uint256 marketId = _aggregator.registerMarket(params_.payoutToken, params_.quoteToken);

        uint32 secondsToConclusion;
        uint32 debtDecayInterval;
        {
            secondsToConclusion = uint32(params_.conclusion - block.timestamp);
            if (
                secondsToConclusion < minMarketDuration ||
                params_.depositInterval < minDepositInterval
            ) revert Auctioneer_InvalidParams();

            // At minimum, the interval is how long it takes for price to drop to 0. In reality, a 50% drop is likely a guaranteed
            // bond sale. So debt decay interval needs to be long enough to allow a bond to adjust if oversold.
            // Needs to be some multiple of deposit interval because you don't want to go from 100 to 0 during the time frame
            // you expected to sell a single bond. 5 is a sane default observed from running OP v1 bond markets.
            uint32 userDebtDecay = params_.depositInterval * 5;
            debtDecayInterval = minDebtDecayInterval > userDebtDecay
                ? minDebtDecayInterval
                : userDebtDecay;

            uint256 tuneIntervalCapacity = params_.capacity.mulDiv(
                uint256(
                    params_.depositInterval > defaultTuneInterval
                        ? params_.depositInterval
                        : defaultTuneInterval
                ),
                uint256(secondsToConclusion)
            );

            metadata[marketId] = BondMetadata({
                lastTune: uint48(block.timestamp),
                lastDecay: uint48(block.timestamp),
                length: secondsToConclusion,
                depositInterval: params_.depositInterval,
                tuneInterval: params_.depositInterval > defaultTuneInterval
                    ? params_.depositInterval
                    : defaultTuneInterval,
                tuneAdjustmentDelay: defaultTuneAdjustment,
                debtDecayInterval: debtDecayInterval,
                tuneIntervalCapacity: tuneIntervalCapacity,
                tuneBelowCapacity: params_.capacity - tuneIntervalCapacity,
                lastTuneDebt: (
                    params_.capacityInQuote
                        ? params_.capacity.mulDiv(scale, params_.formattedInitialPrice)
                        : params_.capacity
                ).mulDiv(uint256(debtDecayInterval), uint256(secondsToConclusion))
            });
        }

        // Initial target debt is equal to capacity scaled by the ratio of the debt decay interval and the length of the market.
        // This is the amount of debt that should be decayed over the decay interval if no purchases are made.
        // Note price should be passed in a specific format:
        // price = (payoutPriceCoefficient / quotePriceCoefficient)
        //         * 10**(36 + scaleAdjustment + quoteDecimals - payoutDecimals + payoutPriceDecimals - quotePriceDecimals)
        // See IBondAuctioneer for more details and variable definitions.
        uint256 targetDebt;
        uint256 maxPayout;
        {
            uint256 capacity = params_.capacityInQuote
                ? params_.capacity.mulDiv(scale, params_.formattedInitialPrice)
                : params_.capacity;

            targetDebt = capacity.mulDiv(uint256(debtDecayInterval), uint256(secondsToConclusion));

            // Max payout is the amount of capacity that should be utilized in a deposit
            // interval. for example, if capacity is 1,000 TOKEN, there are 10 days to conclusion,
            // and the preferred deposit interval is 1 day, max payout would be 100 TOKEN.
            maxPayout = capacity.mulDiv(
                uint256(params_.depositInterval),
                uint256(secondsToConclusion)
            );
        }

        markets[marketId] = BondMarket({
            owner: msg.sender,
            payoutToken: params_.payoutToken,
            quoteToken: params_.quoteToken,
            callbackAddr: params_.callbackAddr,
            capacityInQuote: params_.capacityInQuote,
            capacity: params_.capacity,
            totalDebt: targetDebt,
            minPrice: params_.formattedMinimumPrice,
            maxPayout: maxPayout,
            purchased: 0,
            sold: 0,
            scale: scale
        });

        // Max debt serves as a circuit breaker for the market. let's say the quote token is a stablecoin,
        // and that stablecoin depegs. without max debt, the market would continue to buy until it runs
        // out of capacity. this is configurable with a 3 decimal buffer (1000 = 1% above initial price).
        // Note that its likely advisable to keep this buffer wide.
        // Note that the buffer is above 100%. i.e. 10% buffer = initial debt * 1.1
        // 1e5 = 100,000. 10,000 / 100,000 = 10%.
        uint256 minDebtBuffer_ = maxPayout.mulDiv(FEE_DECIMALS, targetDebt) > minDebtBuffer
            ? maxPayout.mulDiv(FEE_DECIMALS, targetDebt)
            : minDebtBuffer;
        uint256 maxDebt = targetDebt +
            targetDebt.mulDiv(
                uint256(params_.debtBuffer > minDebtBuffer_ ? params_.debtBuffer : minDebtBuffer_),
                1e5
            );

        // The control variable is set so that initial price equals the desired initial price. the control
        // variable is the ultimate determinant of price, so we compute this last.
        //
        // price = control variable * debt / scale
        // therefore, control variable = price * scale / debt
        uint256 controlVariable = params_.formattedInitialPrice.mulDiv(scale, targetDebt);

        terms[marketId] = BondTerms({
            controlVariable: controlVariable,
            maxDebt: maxDebt,
            vesting: params_.vesting,
            conclusion: params_.conclusion
        });

        emit MarketCreated(
            marketId,
            address(params_.payoutToken),
            address(params_.quoteToken),
            params_.vesting,
            params_.formattedInitialPrice
        );

        return marketId;
    }

    /// @inheritdoc IBondAuctioneer
    function setIntervals(uint256 id_, uint32[3] calldata intervals_) external override {
        // Check that the intervals are non-zero
        if (intervals_[0] == 0 || intervals_[1] == 0 || intervals_[2] == 0)
            revert Auctioneer_InvalidParams();

        // Check that tuneInterval >= tuneAdjustmentDelay
        if (intervals_[0] < intervals_[1]) revert Auctioneer_InvalidParams();

        BondMetadata storage meta = metadata[id_];
        // Check that tuneInterval >= depositInterval
        if (intervals_[0] < meta.depositInterval) revert Auctioneer_InvalidParams();

        // Check that debtDecayInterval >= minDebtDecayInterval
        if (intervals_[2] < minDebtDecayInterval) revert Auctioneer_InvalidParams();

        // Check that sender is market owner
        BondMarket memory market = markets[id_];
        if (msg.sender != market.owner) revert Auctioneer_OnlyMarketOwner();

        // Update intervals
        meta.tuneInterval = intervals_[0];
        meta.tuneIntervalCapacity = market.capacity.mulDiv(
            uint256(intervals_[0]),
            uint256(terms[id_].conclusion) - block.timestamp
        ); // don't have a stored value for market duration, this will update tuneIntervalCapacity based on time remaining
        meta.tuneAdjustmentDelay = intervals_[1];
        meta.debtDecayInterval = intervals_[2];
    }

    /// @inheritdoc IBondAuctioneer
    function pushOwnership(uint256 id_, address newOwner_) external override {
        if (msg.sender != markets[id_].owner) revert Auctioneer_OnlyMarketOwner();
        newOwners[id_] = newOwner_;
    }

    /// @inheritdoc IBondAuctioneer
    function pullOwnership(uint256 id_) external override {
        if (msg.sender != newOwners[id_]) revert Auctioneer_NotAuthorized();
        markets[id_].owner = newOwners[id_];
    }

    /// @inheritdoc IBondAuctioneer
    function setDefaults(uint32[6] memory defaults_) external override requiresAuth {
        // Restricted to authorized addresses, initially restricted to policy
        defaultTuneInterval = defaults_[0];
        defaultTuneAdjustment = defaults_[1];
        minDebtDecayInterval = defaults_[2];
        minDepositInterval = defaults_[3];
        minMarketDuration = defaults_[4];
        minDebtBuffer = defaults_[5];
    }

    /// @inheritdoc IBondAuctioneer
    function setAllowNewMarkets(bool status_) external override requiresAuth {
        // Restricted to authorized addresses, initially restricted to guardian
        allowNewMarkets = status_;
    }

    /// @inheritdoc IBondAuctioneer
    function setCallbackAuthStatus(address creator_, bool status_) external override requiresAuth {
        // Restricted to authorized addresses, initially restricted to guardian
        callbackAuthorized[creator_] = status_;
    }

    /// @inheritdoc IBondAuctioneer
    function closeMarket(uint256 id_) external override {
        if (msg.sender != markets[id_].owner) revert Auctioneer_OnlyMarketOwner();
        _close(id_);
    }

    /* ========== TELLER FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external override returns (uint256 payout) {
        if (msg.sender != address(_teller)) revert Auctioneer_NotAuthorized();

        BondMarket storage market = markets[id_];
        BondTerms memory term = terms[id_];

        // Markets end at a defined timestamp
        uint48 currentTime = uint48(block.timestamp);
        if (currentTime >= term.conclusion) revert Auctioneer_MarketConcluded(term.conclusion);

        uint256 price;
        (price, payout) = _decayAndGetPrice(id_, amount_, uint48(block.timestamp)); // Debt and the control variable decay over time

        // Payout must be greater than user inputted minimum
        if (payout < minAmountOut_) revert Auctioneer_AmountLessThanMinimum();

        // Markets have a max payout amount, capping size because deposits
        // do not experience slippage. max payout is recalculated upon tuning
        if (payout > market.maxPayout) revert Auctioneer_MaxPayoutExceeded();

        // Update Capacity and Debt values

        // Capacity is either the number of payout tokens that the market can sell
        // (if capacity in quote is false),
        //
        // or the number of quote tokens that the market can buy
        // (if capacity in quote is true)

        // If amount/payout is greater than capacity remaining, revert
        if (market.capacityInQuote ? amount_ > market.capacity : payout > market.capacity)
            revert Auctioneer_NotEnoughCapacity();
        unchecked {
            // Capacity is decreased by the deposited or paid amount
            market.capacity -= market.capacityInQuote ? amount_ : payout;

            // Markets keep track of how many quote tokens have been
            // purchased, and how many payout tokens have been sold
            market.purchased += amount_;
            market.sold += payout;
        }

        // Circuit breaker. If max debt is breached, the market is closed
        if (term.maxDebt < market.totalDebt) {
            _close(id_);
        } else {
            // If market will continue, the control variable is tuned to hit targets on time
            _tune(id_, currentTime, price);
        }
    }

    /* ========== INTERNAL DEPO FUNCTIONS ========== */

    /// @notice          Close a market
    /// @dev             Closing a market sets capacity to 0 and immediately stops bonding
    function _close(uint256 id_) internal {
        terms[id_].conclusion = uint48(block.timestamp);
        markets[id_].capacity = 0;

        emit MarketClosed(id_);
    }

    /// @notice                 Decay debt, and adjust control variable if there is an active change
    /// @param id_              ID of market
    /// @param amount_          Amount of quote tokens being purchased
    /// @param time_            Current timestamp (saves gas when passed in)
    /// @return marketPrice_    Current market price of bond, accounting for decay
    /// @return payout_         Amount of payout tokens received at current price
    function _decayAndGetPrice(
        uint256 id_,
        uint256 amount_,
        uint48 time_
    ) internal returns (uint256 marketPrice_, uint256 payout_) {
        BondMarket memory market = markets[id_];

        // Debt is a time-decayed sum of tokens spent in a market
        // Debt is added when deposits occur and removed over time
        // |
        // |    debt falls with
        // |   / \  inactivity        / \
        // | /     \              /\ /   \
        // |         \           /        \ / \
        // |           \      /\/
        // |             \  /  and rises
        // |                with deposits
        // |
        // |------------------------------------| t

        // Decay debt by the amount of time since the last decay
        uint256 decayedDebt = currentDebt(id_);
        markets[id_].totalDebt = decayedDebt;

        // Control variable decay

        // The bond control variable is continually tuned. When it is lowered (which
        // lowers the market price), the change is carried out smoothly over time.
        if (adjustments[id_].active) {
            Adjustment storage adjustment = adjustments[id_];

            (uint256 adjustBy, uint48 secondsSince, bool stillActive) = _controlDecay(id_);
            terms[id_].controlVariable -= adjustBy;

            if (stillActive) {
                adjustment.change -= adjustBy;
                adjustment.timeToAdjusted -= secondsSince;
                adjustment.lastAdjustment = time_;
            } else {
                adjustment.active = false;
            }
        }

        // Price is not allowed to be lower than the minimum price
        marketPrice_ = _currentMarketPrice(id_);
        uint256 minPrice = market.minPrice;
        if (marketPrice_ < minPrice) marketPrice_ = minPrice;

        // Payout for the deposit = amount / price
        //
        // where:
        // payout = payout tokens out
        // amount = quote tokens in
        // price = quote tokens : payout token (i.e. 200 QUOTE : BASE), adjusted for scaling
        payout_ = amount_.mulDiv(market.scale, marketPrice_);

        // Cache storage variables to memory
        uint256 debtDecayInterval = uint256(metadata[id_].debtDecayInterval);
        uint256 lastTuneDebt = metadata[id_].lastTuneDebt;
        uint256 lastDecay = uint256(metadata[id_].lastDecay);

        // Set last decay timestamp based on size of purchase to linearize decay
        uint256 lastDecayIncrement = debtDecayInterval.mulDiv(payout_, lastTuneDebt);
        metadata[id_].lastDecay += uint48(lastDecayIncrement);

        // Update total debt following the purchase
        // Goal is to have the same decayed debt post-purchase as pre-purchase so that price is the same as before purchase and then add new debt to increase price
        // 1. Adjust total debt so that decayed debt is equal to the current debt after updating the last decay timestamp.
        //    This is the currentDebt function solved for totalDebt and adding lastDecayIncrement (the number of seconds lastDecay moves forward in time)
        //    to the number of seconds used to calculate the previous currentDebt.
        // 2. Add the payout to the total debt to increase the price.
        uint256 decayOffset = time_ > lastDecay
            ? (
                debtDecayInterval > (time_ - lastDecay)
                    ? debtDecayInterval - (time_ - lastDecay)
                    : 0
            )
            : debtDecayInterval + (lastDecay - time_);
        markets[id_].totalDebt =
            decayedDebt.mulDiv(debtDecayInterval, decayOffset + lastDecayIncrement) +
            payout_ +
            1; // add 1 to satisfy price inequality
    }

    /// @notice             Auto-adjust control variable to hit capacity/spend target
    /// @param id_          ID of market
    /// @param time_        Timestamp (saves gas when passed in)
    /// @param price_       Current price of the market
    function _tune(
        uint256 id_,
        uint48 time_,
        uint256 price_
    ) internal {
        BondMetadata memory meta = metadata[id_];
        BondMarket memory market = markets[id_];

        // Market tunes in 2 situations:
        // 1. If capacity has exceeded target since last tune adjustment and the market is oversold
        // 2. If a tune interval has passed since last tune adjustment and the market is undersold
        //
        // Intuition:
        // Markets are created with a target capacity with the expectation that capacity will
        // be utilized evenly over the duration of the market.
        // The intuition with tuning is:
        // - When the market is ahead of target capacity, we should tune based on capacity.
        // - When the market is behind target capacity, we should tune based on time.

        // Compute seconds remaining until market will conclude
        uint256 timeRemaining = uint256(terms[id_].conclusion - time_);

        // Standardize capacity into an payout token amount
        uint256 capacity = market.capacityInQuote
            ? market.capacity.mulDiv(market.scale, price_)
            : market.capacity;
        // Calculate initial capacity based on remaining capacity and amount sold/purchased up to this point
        uint256 initialCapacity = capacity +
            (market.capacityInQuote ? market.purchased.mulDiv(market.scale, price_) : market.sold);

        // Calculate timeNeutralCapacity as the capacity expected to be sold up to this point and the current capacity
        // Higher than initial capacity means the market is undersold, lower than initial capacity means the market is oversold
        uint256 timeNeutralCapacity = initialCapacity.mulDiv(
            uint256(meta.length) - timeRemaining,
            uint256(meta.length)
        ) + capacity;

        if (
            (market.capacity < meta.tuneBelowCapacity && timeNeutralCapacity < initialCapacity) ||
            (time_ >= meta.lastTune + meta.tuneInterval && timeNeutralCapacity > initialCapacity)
        ) {
            // Calculate the correct payout to complete on time assuming each bond
            // will be max size in the desired deposit interval for the remaining time
            //
            // i.e. market has 10 days remaining. deposit interval is 1 day. capacity
            // is 10,000 TOKEN. max payout would be 1,000 TOKEN (10,000 * 1 / 10).
            markets[id_].maxPayout = capacity.mulDiv(uint256(meta.depositInterval), timeRemaining);

            // Calculate ideal target debt to satisty capacity in the remaining time
            // The target debt is based on whether the market is under or oversold at this point in time
            // This target debt will ensure price is reactive while ensuring the magnitude of being over/undersold
            // doesn't cause larger fluctuations towards the end of the market.
            //

            // Calculate target debt from the timeNeutralCapacity and the ratio of debt decay interval and the length of the market
            uint256 targetDebt = timeNeutralCapacity.mulDiv(
                uint256(meta.debtDecayInterval),
                uint256(meta.length)
            );

            // Derive a new control variable from the target debt
            uint256 controlVariable = terms[id_].controlVariable;
            uint256 newControlVariable = price_.mulDivUp(market.scale, targetDebt);

            emit Tuned(id_, controlVariable, newControlVariable);

            if (newControlVariable < controlVariable) {
                // If decrease, control variable change will be carried out over the tune interval
                // this is because price will be lowered
                uint256 change = controlVariable - newControlVariable;
                adjustments[id_] = Adjustment(change, time_, meta.tuneAdjustmentDelay, true);
            } else {
                // Tune up immediately
                terms[id_].controlVariable = newControlVariable;
                // Set current adjustment to inactive (e.g. if we are re-tuning early)
                adjustments[id_].active = false;
            }

            metadata[id_].lastTune = time_;
            metadata[id_].tuneBelowCapacity = market.capacity > meta.tuneIntervalCapacity
                ? market.capacity - meta.tuneIntervalCapacity
                : 0;
            metadata[id_].lastTuneDebt = targetDebt;
        }
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @dev                See marketPrice() in IBondAuctioneer for explanation of price computation
    /// @dev                Uses info from storage because data has been updated before call (vs marketPrice())
    /// @param id_          Market ID
    /// @return             Price for market in payout token decimals
    function _currentMarketPrice(uint256 id_) internal view returns (uint256) {
        BondMarket memory market = markets[id_];
        return terms[id_].controlVariable.mulDiv(market.totalDebt, market.scale);
    }

    /// @notice                 Amount to decay control variable by
    /// @param id_              ID of market
    /// @return decay           change in control variable
    /// @return secondsSince    seconds since last change in control variable
    /// @return active          whether or not change remains active
    function _controlDecay(uint256 id_)
        internal
        view
        returns (
            uint256 decay,
            uint48 secondsSince,
            bool active
        )
    {
        Adjustment memory info = adjustments[id_];
        if (!info.active) return (0, 0, false);

        secondsSince = uint48(block.timestamp) - info.lastAdjustment;
        active = secondsSince < info.timeToAdjusted;
        decay = active
            ? info.change.mulDiv(uint256(secondsSince), uint256(info.timeToAdjusted))
            : info.change;
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function getMarketInfoForPurchase(uint256 id_)
        external
        view
        returns (
            address owner,
            address callbackAddr,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 vesting,
            uint256 maxPayout
        )
    {
        BondMarket memory market = markets[id_];
        return (
            market.owner,
            market.callbackAddr,
            market.payoutToken,
            market.quoteToken,
            terms[id_].vesting,
            market.maxPayout
        );
    }

    /// @inheritdoc IBondSDA
    function marketPrice(uint256 id_) public view override returns (uint256) {
        uint256 price = currentControlVariable(id_).mulDivUp(currentDebt(id_), markets[id_].scale);

        return (price > markets[id_].minPrice) ? price : markets[id_].minPrice;
    }

    /// @inheritdoc IBondAuctioneer
    function marketScale(uint256 id_) external view override returns (uint256) {
        return markets[id_].scale;
    }

    /// @inheritdoc IBondAuctioneer
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) public view override returns (uint256) {
        // Calculate the payout for the given amount of tokens
        uint256 fee = amount_.mulDiv(_teller.getFee(referrer_), 1e5);
        uint256 payout = (amount_ - fee).mulDiv(markets[id_].scale, marketPrice(id_));

        // Check that the payout is less than or equal to the maximum payout,
        // Revert if not, otherwise return the payout
        if (payout > markets[id_].maxPayout) {
            revert Auctioneer_MaxPayoutExceeded();
        } else {
            return payout;
        }
    }

    /// @inheritdoc IBondAuctioneer
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256) {
        // Calculate maximum amount of quote tokens that correspond to max bond size
        // Maximum of the maxPayout and the remaining capacity converted to quote tokens
        BondMarket memory market = markets[id_];
        uint256 price = marketPrice(id_);
        uint256 quoteCapacity = market.capacityInQuote
            ? market.capacity
            : market.capacity.mulDiv(price, market.scale);
        uint256 maxQuote = market.maxPayout.mulDiv(price, market.scale);
        uint256 amountAccepted = quoteCapacity < maxQuote ? quoteCapacity : maxQuote;

        // Take into account teller fees and return
        // Estimate fee based on amountAccepted. Fee taken will be slightly larger than
        // this given it will be taken off the larger amount, but this avoids rounding
        // errors with trying to calculate the exact amount.
        // Therefore, the maxAmountAccepted is slightly conservative.
        uint256 estimatedFee = amountAccepted.mulDiv(_teller.getFee(referrer_), 1e5);

        return amountAccepted + estimatedFee;
    }

    /// @inheritdoc IBondSDA
    function currentDebt(uint256 id_) public view override returns (uint256) {
        BondMetadata memory meta = metadata[id_];
        uint256 lastDecay = uint256(meta.lastDecay);
        uint256 currentTime = block.timestamp;

        // Determine if decay should increase or decrease debt based on last decay time
        // If last decay time is in the future, then debt should be increased
        // If last decay time is in the past, then debt should be decreased
        if (lastDecay > currentTime) {
            uint256 secondsUntil;
            unchecked {
                secondsUntil = lastDecay - currentTime;
            }
            return
                markets[id_].totalDebt.mulDiv(
                    uint256(meta.debtDecayInterval) + secondsUntil,
                    uint256(meta.debtDecayInterval)
                );
        } else {
            uint256 secondsSince;
            unchecked {
                secondsSince = currentTime - lastDecay;
            }
            return
                secondsSince > meta.debtDecayInterval
                    ? 0
                    : markets[id_].totalDebt.mulDiv(
                        uint256(meta.debtDecayInterval) - secondsSince,
                        uint256(meta.debtDecayInterval)
                    );
        }
    }

    /// @inheritdoc IBondSDA
    function currentControlVariable(uint256 id_) public view override returns (uint256) {
        (uint256 decay, , ) = _controlDecay(id_);
        return terms[id_].controlVariable - decay;
    }

    /// @inheritdoc IBondAuctioneer
    function isInstantSwap(uint256 id_) public view returns (bool) {
        uint256 vesting = terms[id_].vesting;
        return (vesting <= MAX_FIXED_TERM) ? vesting == 0 : vesting <= block.timestamp;
    }

    /// @inheritdoc IBondAuctioneer
    function isLive(uint256 id_) public view override returns (bool) {
        return (markets[id_].capacity != 0 && terms[id_].conclusion > block.timestamp);
    }

    /// @inheritdoc IBondAuctioneer
    function ownerOf(uint256 id_) external view override returns (address) {
        return markets[id_].owner;
    }

    /// @inheritdoc IBondAuctioneer
    function getTeller() external view override returns (IBondTeller) {
        return _teller;
    }

    /// @inheritdoc IBondAuctioneer
    function getAggregator() external view override returns (IBondAggregator) {
        return _aggregator;
    }

    /// @inheritdoc IBondAuctioneer
    function currentCapacity(uint256 id_) external view override returns (uint256) {
        return markets[id_].capacity;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondTeller {
    /// @notice                 Exchange quote tokens for a bond in a specified market
    /// @param recipient_       Address of recipient of bond. Allows deposits for other addresses
    /// @param referrer_        Address of referrer who will receive referral fee. For frontends to fill.
    ///                         Direct calls can use the zero address for no referrer fee.
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return                 Amount of payout token to be received from the bond
    /// @return                 Timestamp at which the bond token can be redeemed for the underlying token
    function purchase(
        address recipient_,
        address referrer_,
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256, uint48);

    /// @notice          Get current fee charged by the teller based on the combined protocol and referrer fee
    /// @param referrer_ Address of the referrer
    /// @return          Fee in basis points (3 decimal places)
    function getFee(address referrer_) external view returns (uint48);

    /// @notice         Set protocol fee
    /// @notice         Must be guardian
    /// @param fee_     Protocol fee in basis points (3 decimal places)
    function setProtocolFee(uint48 fee_) external;

    /// @notice         Set your fee as a referrer to the protocol
    /// @notice         Fee is set for sending address
    /// @param fee_     Referrer fee in basis points (3 decimal places)
    function setReferrerFee(uint48 fee_) external;

    /// @notice         Claim fees accrued for input tokens and sends to protocol
    /// @notice         Must be guardian
    /// @param tokens_  Array of tokens to claim fees for
    /// @param to_      Address to send fees to
    function claimFees(ERC20[] memory tokens_, address to_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondAuctioneer} from "../interfaces/IBondAuctioneer.sol";

interface IBondSDA is IBondAuctioneer {
    /// @notice Main information pertaining to bond market
    struct BondMarket {
        address owner; // market owner. sends payout tokens, receives quote tokens (defaults to creator)
        ERC20 payoutToken; // token to pay depositors with
        ERC20 quoteToken; // token to accept as payment
        address callbackAddr; // address to call for any operations on bond purchase. Must inherit to IBondCallback.
        bool capacityInQuote; // capacity limit is in payment token (true) or in payout (false, default)
        uint256 capacity; // capacity remaining
        uint256 totalDebt; // total payout token debt from market
        uint256 minPrice; // minimum price (debt will stop decaying to maintain this)
        uint256 maxPayout; // max payout tokens out in one order
        uint256 sold; // payout tokens out
        uint256 purchased; // quote tokens in
        uint256 scale; // scaling factor for the market (see MarketParams struct)
    }

    /// @notice Information used to control how a bond market changes
    struct BondTerms {
        uint256 controlVariable; // scaling variable for price
        uint256 maxDebt; // max payout token debt accrued
        uint48 vesting; // length of time from deposit to expiry if fixed-term, vesting timestamp if fixed-expiry
        uint48 conclusion; // timestamp when market no longer offered
    }

    /// @notice Data needed for tuning bond market
    /// @dev Has timestamps in uint32 (not int32), so is not subject to Y2K38 overflow
    struct BondMetadata {
        uint48 lastTune; // last timestamp when control variable was tuned
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint32 length; // time from creation to conclusion.
        uint32 depositInterval; // target frequency of deposits
        uint32 tuneInterval; // frequency of tuning
        uint32 tuneAdjustmentDelay; // time to implement downward tuning adjustments
        uint32 debtDecayInterval; // interval over which debt should decay completely
        uint256 tuneIntervalCapacity; // capacity expected to be used during a tuning interval
        uint256 tuneBelowCapacity; // capacity that the next tuning will occur at
        uint256 lastTuneDebt; // target debt calculated at last tuning
    }

    /// @notice Control variable adjustment data
    struct Adjustment {
        uint256 change;
        uint48 lastAdjustment;
        uint48 timeToAdjusted; // how long until adjustment happens
        bool active;
    }

    /// @notice             Parameters to create a new bond market
    /// @dev                Note price should be passed in a specific format:
    ///                     formatted price = (payoutPriceCoefficient / quotePriceCoefficient)
    ///                             * 10**(36 + scaleAdjustment + quoteDecimals - payoutDecimals + payoutPriceDecimals - quotePriceDecimals)
    ///                     where:
    ///                         payoutDecimals - Number of decimals defined for the payoutToken in its ERC20 contract
    ///                         quoteDecimals - Number of decimals defined for the quoteToken in its ERC20 contract
    ///                         payoutPriceCoefficient - The coefficient of the payoutToken price in scientific notation (also known as the significant digits)
    ///                         payoutPriceDecimals - The significand of the payoutToken price in scientific notation (also known as the base ten exponent)
    ///                         quotePriceCoefficient - The coefficient of the quoteToken price in scientific notation (also known as the significant digits)
    ///                         quotePriceDecimals - The significand of the quoteToken price in scientific notation (also known as the base ten exponent)
    ///                         scaleAdjustment - see below
    ///                         * In the above definitions, the "prices" need to have the same unit of account (i.e. both in OHM, $, ETH, etc.)
    ///                         If price is not provided in this format, the market will not behave as intended.
    /// @param params_      Encoded bytes array, with the following elements
    /// @dev                    0. Payout Token (token paid out)
    /// @dev                    1. Quote Token (token to be received)
    /// @dev                    2. Callback contract address, should conform to IBondCallback. If 0x00, tokens will be transferred from market.owner
    /// @dev                    3. Is Capacity in Quote Token?
    /// @dev                    4. Capacity (amount in quoteDecimals or amount in payoutDecimals)
    /// @dev                    5. Formatted initial price (see note above)
    /// @dev                    6. Formatted minimum price (see note above)
    /// @dev                    7. Debt buffer. Percent with 3 decimals. Percentage over the initial debt to allow the market to accumulate at anyone time.
    /// @dev                       Works as a circuit breaker for the market in case external conditions incentivize massive buying (e.g. stablecoin depeg).
    /// @dev                       Minimum is the greater of 10% or initial max payout as a percentage of capacity.
    /// @dev                       If the value is too small, the market will not be able function normally and close prematurely.
    /// @dev                       If the value is too large, the market will not circuit break when intended. The value must be > 10% but can exceed 100% if desired.
    /// @dev                    8. Is fixed term ? Vesting length (seconds) : Vesting expiry (timestamp).
    /// @dev                        A 'vesting' param longer than 50 years is considered a timestamp for fixed expiry.
    /// @dev                    9. Conclusion (timestamp)
    /// @dev                    10. Deposit interval (seconds)
    /// @dev                    11. Market scaling factor adjustment, ranges from -24 to +24 within the configured market bounds.
    /// @dev                        Should be calculated as: (payoutDecimals - quoteDecimals) - ((payoutPriceDecimals - quotePriceDecimals) / 2)
    /// @dev                        Providing a scaling factor adjustment that doesn't follow this formula could lead to under or overflow errors in the market.
    /// @return                 ID of new bond market
    struct MarketParams {
        ERC20 payoutToken;
        ERC20 quoteToken;
        address callbackAddr;
        bool capacityInQuote;
        uint256 capacity;
        uint256 formattedInitialPrice;
        uint256 formattedMinimumPrice;
        uint32 debtBuffer;
        uint48 vesting;
        uint48 conclusion;
        uint32 depositInterval;
        int8 scaleAdjustment;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @dev                Accounts for debt and control variable decay since last deposit (vs _marketPrice())
    /// @param id_          ID of market
    /// @return             Price for market in configured decimals (see MarketParams)
    //
    // price is derived from the equation
    //
    // p = c * d
    //
    // where
    // p = price
    // c = control variable
    // d = debt
    //
    // d -= ( d * (dt / l) )
    //
    // where
    // dt = change in time
    // l = length of program
    //
    // if price is below minimum price, minimum price is returned
    // this is enforced on deposits by manipulating total debt (see _decay())
    function marketPrice(uint256 id_) external view override returns (uint256);

    /// @notice             Calculate debt factoring in decay
    /// @dev                Accounts for debt decay since last deposit
    /// @param id_          ID of market
    /// @return             Current debt for market in payout token decimals
    function currentDebt(uint256 id_) external view returns (uint256);

    /// @notice             Up to date control variable
    /// @dev                Accounts for control variable adjustment
    /// @param id_          ID of market
    /// @return             Control variable for market in payout token decimals
    function currentControlVariable(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondCallback {
    /// @notice                 Send payout tokens to Teller while allowing market owners to perform custom logic on received or paid out tokens
    /// @notice                 Market ID on Teller must be whitelisted
    /// @param id_              ID of the market
    /// @param inputAmount_     Amount of quote tokens bonded to the market
    /// @param outputAmount_    Amount of payout tokens to be paid out to the market
    /// @dev Must transfer the output amount of payout tokens back to the Teller
    /// @dev Should check that the quote tokens have been transferred to the contract in the _callback function
    function callback(
        uint256 id_,
        uint256 inputAmount_,
        uint256 outputAmount_
    ) external;

    /// @notice         Returns the number of quote tokens received and payout tokens paid out for a market
    /// @param id_      ID of the market
    /// @return in_     Amount of quote tokens bonded to the market
    /// @return out_    Amount of payout tokens paid out to the market
    function amountsForMarket(uint256 id_) external view returns (uint256 in_, uint256 out_);

    /// @notice         Whitelist a teller and market ID combination
    /// @notice         Must be callback owner
    /// @param teller_  Address of the Teller contract which serves the market
    /// @param id_      ID of the market
    function whitelist(address teller_, uint256 id_) external;

    /// @notice         Withdraw tokens from the callback and update balances
    /// @notice         Only callback owner
    /// @param to_      Address of the recipient
    /// @param token_   Address of the token to withdraw
    /// @param amount_  Amount of tokens to withdraw
    function withdraw(
        address to_,
        ERC20 token_,
        uint256 amount_
    ) external;

    /// @notice         Deposit tokens to the callback and update balances
    /// @notice         Only callback owner
    /// @param token_   Address of the token to deposit
    /// @param amount_  Amount of tokens to deposit
    function deposit(ERC20 token_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondAuctioneer} from "../interfaces/IBondAuctioneer.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";

interface IBondAggregator {
    /// @notice             Register a auctioneer with the aggregator
    /// @notice             Only Guardian
    /// @param auctioneer_  Address of the Auctioneer to register
    /// @dev                A auctioneer must be registered with an aggregator to create markets
    function registerAuctioneer(IBondAuctioneer auctioneer_) external;

    /// @notice             Register a new market with the aggregator
    /// @notice             Only registered depositories
    /// @param payoutToken_ Token to be paid out by the market
    /// @param quoteToken_  Token to be accepted by the market
    /// @param marketId     ID of the market being created
    function registerMarket(ERC20 payoutToken_, ERC20 quoteToken_)
        external
        returns (uint256 marketId);

    /// @notice     Get the auctioneer for the provided market ID
    /// @param id_  ID of Market
    function getAuctioneer(uint256 id_) external view returns (IBondAuctioneer);

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @dev                Accounts for debt and control variable decay since last deposit (vs _marketPrice())
    /// @param id_          ID of market
    /// @return             Price for market (see the specific auctioneer for units)
    //
    // if price is below minimum price, minimum price is returned
    // this is enforced on deposits by manipulating total debt (see _decay())
    function marketPrice(uint256 id_) external view returns (uint256);

    /// @notice             Scale value to use when converting between quote token and payout token amounts with marketPrice()
    /// @param id_          ID of market
    /// @return             Scaling factor for market in configured decimals
    function marketScale(uint256 id_) external view returns (uint256);

    /// @notice             Payout due for amount of quote tokens
    /// @dev                Accounts for debt and control variable decay so it is up to date
    /// @param amount_      Amount of quote tokens to spend
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    /// @return             amount of payout tokens to be paid
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) external view returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256);

    /// @notice             Does market send payout immediately
    /// @param id_          Market ID to search for
    function isInstantSwap(uint256 id_) external view returns (bool);

    /// @notice             Is a given market accepting deposits
    /// @param id_          ID of market
    function isLive(uint256 id_) external view returns (bool);

    /// @notice             Returns array of active market IDs within a range
    /// @dev                Should be used if length exceeds max to query entire array
    function liveMarketsBetween(uint256 firstIndex_, uint256 lastIndex_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given quote token
    /// @param token_       Address of token to query by
    /// @param isPayout_    If true, search by payout token, else search for quote token
    function liveMarketsFor(address token_, bool isPayout_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given owner
    /// @param owner_       Address of owner to query by
    function liveMarketsBy(address owner_) external view returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given payout and quote token
    /// @param payout_      Address of payout token
    /// @param quote_       Address of quote token
    function marketsFor(address payout_, address quote_) external view returns (uint256[] memory);

    /// @notice                 Returns the market ID with the highest current payoutToken payout for depositing quoteToken
    /// @param payout_          Address of payout token
    /// @param quote_           Address of quote token
    /// @param amountIn_        Amount of quote tokens to deposit
    /// @param minAmountOut_    Minimum amount of payout tokens to receive as payout
    /// @param maxExpiry_       Latest acceptable vesting timestamp for bond
    ///                         Inputting the zero address will take into account just the protocol fee.
    function findMarketFor(
        address payout_,
        address quote_,
        uint256 amountIn_,
        uint256 minAmountOut_,
        uint256 maxExpiry_
    ) external view returns (uint256 id);

    /// @notice             Returns the Teller that services the market ID
    function getTeller(uint256 id_) external view returns (IBondTeller);

    /// @notice             Returns current capacity of a market
    function currentCapacity(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// @author Taken from Solmate.
library TransferHelper {
    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    // function safeApprove(
    //     ERC20 token,
    //     address to,
    //     uint256 amount
    // ) internal {
    //     (bool success, bytes memory data) = address(token).call(
    //         abi.encodeWithSelector(ERC20.approve.selector, to, amount)
    //     );

    //     require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    // }

    // function safeTransferETH(address to, uint256 amount) internal {
    //     (bool success, ) = to.call{value: amount}(new bytes(0));

    //     require(success, "ETH_TRANSFER_FAILED");
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";

interface IBondAuctioneer {
    /// @notice                 Creates a new bond market
    /// @param params_          Configuration data needed for market creation, encoded in a bytes array
    /// @dev                    See specific auctioneer implementations for details on encoding the parameters.
    /// @return id              ID of new bond market
    function createMarket(bytes memory params_) external returns (uint256);

    /// @notice                 Disable existing bond market
    /// @notice                 Must be market owner
    /// @param id_              ID of market to close
    function closeMarket(uint256 id_) external;

    /// @notice                 Exchange quote tokens for a bond in a specified market
    /// @notice                 Must be teller
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond (after fee has been deducted)
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return payout          Amount of payout token to be received from the bond
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256 payout);

    /// @notice                         Set market intervals to different values than the defaults
    /// @notice                         Must be market owner
    /// @dev                            Changing the intervals could cause markets to behave in unexpected way
    ///                                 tuneInterval should be greater than tuneAdjustmentDelay
    /// @param id_                      Market ID
    /// @param intervals_               Array of intervals (3)
    ///                                 1. Tune interval - Frequency of tuning
    ///                                 2. Tune adjustment delay - Time to implement downward tuning adjustments
    ///                                 3. Debt decay interval - Interval over which debt should decay completely
    function setIntervals(uint256 id_, uint32[3] calldata intervals_) external;

    /// @notice                      Designate a new owner of a market
    /// @notice                      Must be market owner
    /// @dev                         Doesn't change permissions until newOwner calls pullOwnership
    /// @param id_                   Market ID
    /// @param newOwner_             New address to give ownership to
    function pushOwnership(uint256 id_, address newOwner_) external;

    /// @notice                      Accept ownership of a market
    /// @notice                      Must be market newOwner
    /// @dev                         The existing owner must call pushOwnership prior to the newOwner calling this function
    /// @param id_                   Market ID
    function pullOwnership(uint256 id_) external;

    /// @notice             Set the auctioneer defaults
    /// @notice             Must be policy
    /// @param defaults_    Array of default values
    ///                     1. Tune interval - amount of time between tuning adjustments
    ///                     2. Tune adjustment delay - amount of time to apply downward tuning adjustments
    ///                     3. Minimum debt decay interval - minimum amount of time to let debt decay to zero
    ///                     4. Minimum deposit interval - minimum amount of time to wait between deposits
    ///                     5. Minimum market duration - minimum amount of time a market can be created for
    ///                     6. Minimum debt buffer - the minimum amount of debt over the initial debt to trigger a market shutdown
    /// @dev                The defaults set here are important to avoid edge cases in market behavior, e.g. a very short market reacts doesn't tune well
    /// @dev                Only applies to new markets that are created after the change
    function setDefaults(uint32[6] memory defaults_) external;

    /// @notice             Change the status of the auctioneer to allow creation of new markets
    /// @dev                Setting to false and allowing active markets to end will sunset the auctioneer
    /// @param status_      Allow market creation (true) : Disallow market creation (false)
    function setAllowNewMarkets(bool status_) external;

    /// @notice             Change whether a market creator is allowed to use a callback address in their markets or not
    /// @notice             Must be guardian
    /// @dev                Callback is believed to be safe, but a whitelist is implemented to prevent abuse
    /// @param creator_     Address of market creator
    /// @param status_      Allow callback (true) : Disallow callback (false)
    function setCallbackAuthStatus(address creator_, bool status_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice                 Provides information for the Teller to execute purchases on a Market
    /// @param id_              Market ID
    /// @return owner           Address of the market owner (tokens transferred from this address if no callback)
    /// @return callbackAddr    Address of the callback contract to get tokens for payouts
    /// @return payoutToken     Payout Token (token paid out) for the Market
    /// @return quoteToken      Quote Token (token received) for the Market
    /// @return vesting         Timestamp or duration for vesting, implementation-dependent
    /// @return maxPayout       Maximum amount of payout tokens you can purchase in one transaction
    function getMarketInfoForPurchase(uint256 id_)
        external
        view
        returns (
            address owner,
            address callbackAddr,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 vesting,
            uint256 maxPayout
        );

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @param id_          ID of market
    /// @return             Price for market in configured decimals
    //
    // if price is below minimum price, minimum price is returned
    // this is enforced on deposits by manipulating total debt (see _decay())
    function marketPrice(uint256 id_) external view returns (uint256);

    /// @notice             Scale value to use when converting between quote token and payout token amounts with marketPrice()
    /// @param id_          ID of market
    /// @return             Scaling factor for market in configured decimals
    function marketScale(uint256 id_) external view returns (uint256);

    /// @notice             Payout due for amount of quote tokens
    /// @dev                Accounts for debt and control variable decay so it is up to date
    /// @param amount_      Amount of quote tokens to spend
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    /// @return             amount of payout tokens to be paid
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) external view returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256);

    /// @notice             Does market send payout immediately
    /// @param id_          Market ID to search for
    function isInstantSwap(uint256 id_) external view returns (bool);

    /// @notice             Is a given market accepting deposits
    /// @param id_          ID of market
    function isLive(uint256 id_) external view returns (bool);

    /// @notice             Returns the address of the market owner
    /// @param id_          ID of market
    function ownerOf(uint256 id_) external view returns (address);

    /// @notice             Returns the Teller that services the Auctioneer
    function getTeller() external view returns (IBondTeller);

    /// @notice             Returns the Aggregator that services the Auctioneer
    function getAggregator() external view returns (IBondAggregator);

    /// @notice             Returns current capacity of a market
    function currentCapacity(uint256 id_) external view returns (uint256);
}