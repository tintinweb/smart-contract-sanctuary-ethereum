// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {IOperator} from "policies/interfaces/IOperator.sol";
import {IBondAuctioneer} from "interfaces/IBondAuctioneer.sol";
import {IBondCallback} from "interfaces/IBondCallback.sol";

import {OlympusTreasury} from "modules/TRSRY.sol";
import {OlympusMinter} from "modules/MINTR.sol";
import {OlympusPrice} from "modules/PRICE.sol";
import {OlympusRange} from "modules/RANGE.sol";

import {Kernel, Policy} from "src/Kernel.sol";

import {TransferHelper} from "libraries/TransferHelper.sol";
import {FullMath} from "libraries/FullMath.sol";

/// @title  Olympus Range Operator
/// @notice Olympus Range Operator (Policy) Contract
/// @dev    The Olympus Range Operator performs market operations to enforce OlympusDAO's OHM price range
///         guidance policies against a specific reserve asset. The Operator is maintained by a keeper-triggered
///         function on the Olympus Heart contract, which orchestrates state updates in the correct order to ensure
///         market operations use up to date information. When the price of OHM against the reserve asset exceeds
///         the cushion spread, the Operator deploys bond markets to support the price. The Operator also offers
///         zero slippage swaps at prices dictated by the wall spread from the moving average. These market operations
///         are performed up to a specific capacity before the market must stabilize to regenerate the capacity.
contract Operator is IOperator, Policy, ReentrancyGuard, Auth {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== ERRORS =========== */

    error Operator_InvalidParams();
    error Operator_InsufficientCapacity();
    error Operator_AmountLessThanMinimum(
        uint256 amountOut,
        uint256 minAmountOut
    );
    error Operator_WallDown();
    error Operator_AlreadyInitialized();
    error Operator_NotInitialized();

    /* ========== EVENTS =========== */
    event Swap(
        ERC20 indexed tokenIn_,
        ERC20 indexed tokenOut_,
        uint256 amountIn_,
        uint256 amountOut_
    );

    /* ========== STATE VARIABLES ========== */

    /// Operator variables, defined in the interface on the external getter functions
    Status internal _status;
    Config internal _config;

    /// @notice    Whether the Operator has been initialized
    bool public initialized;

    /// Modules
    OlympusPrice internal PRICE;
    OlympusRange internal RANGE;
    OlympusTreasury internal TRSRY;
    OlympusMinter internal MINTR;

    /// External contracts
    /// @notice     Auctioneer contract used for cushion bond market deployments
    IBondAuctioneer public auctioneer;
    /// @notice     Callback contract used for cushion bond market payouts
    IBondCallback public callback;

    /// Tokens
    /// @notice     OHM token contract
    ERC20 public immutable ohm;
    uint8 public immutable ohmDecimals;
    /// @notice     Reserve token contract
    ERC20 public immutable reserve;
    uint8 public immutable reserveDecimals;

    /// Constants
    uint32 public constant FACTOR_SCALE = 1e4;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        Kernel kernel_,
        IBondAuctioneer auctioneer_,
        IBondCallback callback_,
        ERC20[2] memory tokens_, // [ohm, reserve]
        uint32[8] memory configParams // [cushionFactor, cushionDuration, cushionDebtBuffer, cushionDepositInterval, reserveFactor, regenWait, regenThreshold, regenObserve]
    ) Policy(kernel_) Auth(address(kernel_), Authority(address(0))) {
        /// Check params are valid
        if (
            address(auctioneer_) == address(0) ||
            address(callback_) == address(0)
        ) revert Operator_InvalidParams();

        if (
            configParams[1] > uint256(7 days) ||
            configParams[1] < uint256(1 days)
        ) revert Operator_InvalidParams();

        if (configParams[2] < uint32(10_000)) revert Operator_InvalidParams();

        if (
            configParams[3] < uint32(1 hours) ||
            configParams[3] > configParams[1]
        ) revert Operator_InvalidParams();

        if (configParams[4] > 10000 || configParams[4] < 100)
            revert Operator_InvalidParams();

        if (
            configParams[5] < 1 hours ||
            configParams[6] > configParams[7] ||
            configParams[7] == uint32(0)
        ) revert Operator_InvalidParams();

        auctioneer = auctioneer_;
        callback = callback_;
        ohm = tokens_[0];
        ohmDecimals = tokens_[0].decimals();
        reserve = tokens_[1];
        reserveDecimals = tokens_[1].decimals();

        Regen memory regen = Regen({
            count: uint32(0),
            lastRegen: uint48(block.timestamp),
            nextObservation: uint32(0),
            observations: new bool[](configParams[7])
        });

        _config = Config({
            cushionFactor: configParams[0],
            cushionDuration: configParams[1],
            cushionDebtBuffer: configParams[2],
            cushionDepositInterval: configParams[3],
            reserveFactor: configParams[4],
            regenWait: configParams[5],
            regenThreshold: configParams[6],
            regenObserve: configParams[7]
        });

        _status = Status({low: regen, high: regen});
    }

    /* ========== FRAMEWORK CONFIGURATION ========== */
    /// @inheritdoc Policy
    function configureReads() public override {
        PRICE = OlympusPrice(getModuleAddress("PRICE"));
        RANGE = OlympusRange(getModuleAddress("RANGE"));
        TRSRY = OlympusTreasury(getModuleAddress("TRSRY"));
        MINTR = OlympusMinter(getModuleAddress("MINTR"));
        setAuthority(Authority(getModuleAddress("AUTHR")));

        /// Approve MINTR for burning OHM (called here so that it is re-approved on updates)
        ohm.safeApprove(address(MINTR), type(uint256).max);
    }

    /// @inheritdoc Policy
    function requestRoles()
        external
        view
        override
        returns (Kernel.Role[] memory roles)
    {
        roles = new Kernel.Role[](4);
        roles[0] = RANGE.OPERATOR();
        roles[1] = TRSRY.APPROVER();
        roles[2] = MINTR.MINTER();
        roles[3] = MINTR.BURNER();
    }

    /* ========== HEART FUNCTIONS ========== */
    /// @inheritdoc IOperator
    function operate() external override requiresAuth {
        /// Revert if not initialized
        if (!initialized) revert Operator_NotInitialized();

        /// Update the prices for the range, save new regen observations, and update capacities based on bond market activity
        _updateRangePrices();
        _addObservation();
        _updateCapacity(true, 0);
        _updateCapacity(false, 0);

        /// Cache config in memory
        Config memory config_ = _config;

        /// Check if walls can regenerate capacity
        if (
            uint48(block.timestamp) >=
            RANGE.lastActive(true) + uint48(config_.regenWait) &&
            _status.high.count >= config_.regenThreshold
        ) {
            _regenerate(true);
        }
        if (
            uint48(block.timestamp) >=
            RANGE.lastActive(false) + uint48(config_.regenWait) &&
            _status.low.count >= config_.regenThreshold
        ) {
            _regenerate(false);
        }

        /// Cache range data after potential regeneration
        OlympusRange.Range memory range = RANGE.range();

        /// Get latest price
        /// See note in addObservation() for more details
        uint256 currentPrice = PRICE.getLastPrice();

        /// Check if the cushion bond markets are active
        /// if so, determine if it should stay open or close
        /// if not, check if a new one should be opened
        if (range.low.active)
            if (auctioneer.isLive(range.low.market)) {
                /// if active, check if the price is back above the cushion
                /// or if the price is below the wall
                /// if so, close the market
                if (
                    currentPrice > range.cushion.low.price ||
                    currentPrice < range.wall.low.price
                ) {
                    _deactivate(false);
                }
            } else {
                /// if not active, check if the price is below the cushion
                /// if so, open a new bond market
                if (
                    currentPrice < range.cushion.low.price &&
                    currentPrice > range.wall.low.price
                ) {
                    _activate(false);
                }
            }
        if (range.high.active) {
            if (auctioneer.isLive(range.high.market)) {
                /// if active, check if the price is back under the cushion
                /// or if the price is above the wall
                /// if so, close the market
                if (
                    currentPrice < range.cushion.high.price ||
                    currentPrice > range.wall.high.price
                ) {
                    _deactivate(true);
                }
            } else {
                /// if not active, check if the price is above the cushion
                /// if so, open a new bond market
                if (
                    currentPrice > range.cushion.high.price &&
                    currentPrice < range.wall.high.price
                ) {
                    _activate(true);
                }
            }
        }
    }

    /* ========== OPEN MARKET OPERATIONS (WALL) ========== */
    /// @inheritdoc IOperator
    function swap(
        ERC20 tokenIn_,
        uint256 amountIn_,
        uint256 minAmountOut_
    ) external override nonReentrant returns (uint256 amountOut) {
        if (tokenIn_ == ohm) {
            /// Revert if lower wall is inactive
            if (!RANGE.active(false)) revert Operator_WallDown();

            /// Calculate amount out (checks for sufficient capacity)
            amountOut = getAmountOut(tokenIn_, amountIn_);

            /// Revert if amount out less than the minimum specified
            /// @dev even though price is fixed most of the time,
            /// it is possible that the amount out could change on a sender
            /// due to the wall prices being updated before their transaction is processed.
            /// This would be the equivalent of the heart.beat front-running the sender.
            if (amountOut < minAmountOut_)
                revert Operator_AmountLessThanMinimum(amountOut, minAmountOut_);

            /// Decrement wall capacity
            _updateCapacity(false, amountOut);

            /// If wall is down after swap, deactive the cushion as well
            _checkCushion(false);

            /// Transfer OHM from sender
            ohm.safeTransferFrom(msg.sender, address(this), amountIn_);

            /// Burn OHM
            MINTR.burnOhm(address(this), amountIn_);

            /// Withdraw and transfer reserve to sender
            TRSRY.withdrawReserves(msg.sender, reserve, amountOut);

            emit Swap(ohm, reserve, amountIn_, amountOut);
        } else if (tokenIn_ == reserve) {
            /// Revert if upper wall is inactive
            if (!RANGE.active(true)) revert Operator_WallDown();

            /// Calculate amount out (checks for sufficient capacity)
            amountOut = getAmountOut(tokenIn_, amountIn_);

            /// Revert if amount out less than the minimum specified
            /// @dev even though price is fixed most of the time,
            /// it is possible that the amount out could change on a sender
            /// due to the wall prices being updated before their transaction is processed.
            /// This would be the equivalent of the heart.beat front-running the sender.
            if (amountOut < minAmountOut_)
                revert Operator_AmountLessThanMinimum(amountOut, minAmountOut_);

            /// Decrement wall capacity
            _updateCapacity(true, amountOut);

            /// If wall is down after swap, deactive the cushion as well
            _checkCushion(true);

            /// Transfer reserves to treasury
            reserve.safeTransferFrom(msg.sender, address(TRSRY), amountIn_);

            /// Mint OHM to sender
            MINTR.mintOhm(msg.sender, amountOut);

            emit Swap(reserve, ohm, amountIn_, amountOut);
        } else {
            revert Operator_InvalidParams();
        }
    }

    /* ========== BOND MARKET OPERATIONS (CUSHION) ========== */
    /// @notice             Records a bond purchase and updates capacity correctly
    /// @notice             Access restricted (BondCallback)
    /// @param id_          ID of the bond market
    /// @param amountOut_   Amount of capacity expended
    function bondPurchase(uint256 id_, uint256 amountOut_)
        external
        requiresAuth
    {
        if (id_ == RANGE.market(true)) {
            _updateCapacity(true, amountOut_);
            _checkCushion(true);
        }
        if (id_ == RANGE.market(false)) {
            _updateCapacity(false, amountOut_);
            _checkCushion(false);
        }
    }

    /// @notice      Activate a cushion by deploying a bond market
    /// @param high_ Whether the cushion is for the high or low side of the range (true = high, false = low)
    function _activate(bool high_) internal {
        OlympusRange.Range memory range = RANGE.range();

        if (high_) {
            /// Calculate scaleAdjustment for bond market
            int8 priceDecimals = _getPriceDecimals(range.cushion.high.price);
            int8 scaleAdjustment = int8(ohmDecimals) -
                int8(reserveDecimals) -
                (priceDecimals / 2);

            /// Calculate scale with scale adjustment and format prices for bond market
            uint8 oracleDecimals = PRICE.decimals();
            uint256 scale = 10 **
                uint8(
                    36 +
                        scaleAdjustment +
                        int8(reserveDecimals) -
                        int8(ohmDecimals) +
                        priceDecimals
                );

            uint256 initialPrice = range.wall.high.price.mulDiv(
                scale,
                10**oracleDecimals
            );
            uint256 minimumPrice = range.cushion.high.price.mulDiv(
                scale,
                10**oracleDecimals
            );

            /// Cache config struct to avoid multiple SLOADs
            Config memory config_ = _config;

            /// Calculate market capacity from the cushion factor
            uint256 marketCapacity = range.high.capacity.mulDiv(
                config_.cushionFactor,
                FACTOR_SCALE
            );

            /// Create new bond market to buy the reserve with OHM
            IBondAuctioneer.MarketParams memory params = IBondAuctioneer
                .MarketParams({
                    payoutToken: ohm,
                    quoteToken: reserve,
                    callbackAddr: address(callback),
                    capacityInQuote: false,
                    capacity: marketCapacity,
                    formattedInitialPrice: initialPrice,
                    formattedMinimumPrice: minimumPrice,
                    debtBuffer: config_.cushionDebtBuffer,
                    vesting: uint48(0), // Instant swaps
                    conclusion: uint48(
                        block.timestamp + config_.cushionDuration
                    ),
                    depositInterval: config_.cushionDepositInterval,
                    scaleAdjustment: scaleAdjustment
                });

            uint256 market = auctioneer.createMarket(params);

            /// Whitelist the bond market on the callback
            callback.whitelist(address(auctioneer.getTeller()), market);

            /// Update the market information on the range module
            RANGE.updateMarket(true, market, marketCapacity);
        } else {
            /// Calculate inverse prices from the oracle feed for the low side
            uint8 oracleDecimals = PRICE.decimals();
            uint256 invCushionPrice = 10**(oracleDecimals * 2) /
                range.cushion.low.price;
            uint256 invWallPrice = 10**(oracleDecimals * 2) /
                range.wall.low.price;

            /// Calculate scaleAdjustment for bond market
            int8 priceDecimals = _getPriceDecimals(invCushionPrice);
            int8 scaleAdjustment = int8(reserveDecimals) -
                int8(ohmDecimals) -
                (priceDecimals / 2);

            /// Calculate scale with scale adjustment and format prices for bond market
            uint256 scale = 10 **
                uint8(
                    36 +
                        scaleAdjustment +
                        int8(ohmDecimals) -
                        int8(reserveDecimals) +
                        priceDecimals
                );

            uint256 initialPrice = invWallPrice.mulDiv(
                scale,
                10**oracleDecimals
            );
            uint256 minimumPrice = invCushionPrice.mulDiv(
                scale,
                10**oracleDecimals
            );

            /// Cache config struct to avoid multiple SLOADs
            Config memory config_ = _config;

            /// Calculate market capacity from the cushion factor
            uint256 marketCapacity = range.low.capacity.mulDiv(
                config_.cushionFactor,
                FACTOR_SCALE
            );

            /// Create new bond market to buy OHM with the reserve
            IBondAuctioneer.MarketParams memory params = IBondAuctioneer
                .MarketParams({
                    payoutToken: reserve,
                    quoteToken: ohm,
                    callbackAddr: address(callback),
                    capacityInQuote: false,
                    capacity: marketCapacity,
                    formattedInitialPrice: initialPrice,
                    formattedMinimumPrice: minimumPrice,
                    debtBuffer: config_.cushionDebtBuffer,
                    vesting: uint48(0), // Instant swaps
                    conclusion: uint48(
                        block.timestamp + config_.cushionDuration
                    ),
                    depositInterval: config_.cushionDepositInterval,
                    scaleAdjustment: scaleAdjustment
                });

            uint256 market = auctioneer.createMarket(params);

            /// Whitelist the bond market on the callback
            callback.whitelist(address(auctioneer.getTeller()), market);

            /// Update the market information on the range module
            RANGE.updateMarket(false, market, marketCapacity);
        }
    }

    /// @notice      Deactivate a cushion by closing a bond market (if it is active)
    /// @param high_ Whether the cushion is for the high or low side of the range (true = high, false = low)
    function _deactivate(bool high_) internal {
        uint256 market = RANGE.market(high_);
        if (auctioneer.isLive(market)) {
            auctioneer.closeMarket(market);
            RANGE.updateMarket(high_, type(uint256).max, 0);
        }
    }

    /// @notice         Helper function to calculate number of price decimals based on the value returned from the price feed.
    /// @param price_   The price to calculate the number of decimals for
    /// @return         The number of decimals
    function _getPriceDecimals(uint256 price_) internal view returns (int8) {
        int8 decimals;
        while (price_ >= 10) {
            price_ = price_ / 10;
            decimals++;
        }

        /// Subtract the stated decimals from the calculated decimals to get the relative price decimals.
        /// Required to do it this way vs. normalizing at the beginning since price decimals can be negative.
        return decimals - int8(PRICE.decimals());
    }

    /* ========== OPERATOR CONFIGURATION ========== */
    /// @inheritdoc IOperator
    function setSpreads(uint256 cushionSpread_, uint256 wallSpread_)
        external
        requiresAuth
    {
        /// Set spreads on the range module
        RANGE.setSpreads(cushionSpread_, wallSpread_);

        /// Update range prices (wall and cushion)
        _updateRangePrices();
    }

    /// @inheritdoc IOperator
    function setThresholdFactor(uint256 thresholdFactor_)
        external
        requiresAuth
    {
        /// Set threshold factor on the range module
        RANGE.setThresholdFactor(thresholdFactor_);
    }

    /// @inheritdoc IOperator
    function setCushionFactor(uint32 cushionFactor_) external requiresAuth {
        /// Confirm factor is within allowed values
        if (cushionFactor_ > 10000 || cushionFactor_ < 100)
            revert Operator_InvalidParams();

        /// Set factor
        _config.cushionFactor = cushionFactor_;
    }

    /// @inheritdoc IOperator
    function setCushionParams(
        uint32 duration_,
        uint32 debtBuffer_,
        uint32 depositInterval_
    ) external requiresAuth {
        /// Confirm values are valid
        if (duration_ > uint256(7 days) || duration_ < uint256(1 days))
            revert Operator_InvalidParams();
        if (debtBuffer_ < uint32(10_000)) revert Operator_InvalidParams();
        if (depositInterval_ < uint32(1 hours) || depositInterval_ > duration_)
            revert Operator_InvalidParams();

        /// Update values
        _config.cushionDuration = duration_;
        _config.cushionDebtBuffer = debtBuffer_;
        _config.cushionDepositInterval = depositInterval_;
    }

    /// @inheritdoc IOperator
    function setReserveFactor(uint32 reserveFactor_) external requiresAuth {
        /// Confirm factor is within allowed values
        if (reserveFactor_ > 10000 || reserveFactor_ < 100)
            revert Operator_InvalidParams();

        /// Set factor
        _config.reserveFactor = reserveFactor_;
    }

    /// @inheritdoc IOperator
    function setRegenParams(
        uint32 wait_,
        uint32 threshold_,
        uint32 observe_
    ) external requiresAuth {
        /// Confirm regen parameters are within allowed values
        if (wait_ < 1 hours || threshold_ > observe_ || observe_ == 0)
            revert Operator_InvalidParams();

        /// Set regen params
        _config.regenWait = wait_;
        _config.regenThreshold = threshold_;
        _config.regenObserve = observe_;

        /// Re-initialize regen structs with new values (except for last regen)
        _status.high.count = 0;
        _status.high.nextObservation = 0;
        _status.high.observations = new bool[](observe_);

        _status.low.count = 0;
        _status.low.nextObservation = 0;
        _status.low.observations = new bool[](observe_);
    }

    /// @inheritdoc IOperator
    function setBondContracts(
        IBondAuctioneer auctioneer_,
        IBondCallback callback_
    ) external requiresAuth {
        if (
            address(auctioneer_) == address(0) ||
            address(callback_) == address(0)
        ) revert Operator_InvalidParams();
        /// Set contracts
        auctioneer = auctioneer_;
        callback = callback_;
    }

    /// @inheritdoc IOperator
    function initialize() external requiresAuth {
        /// Can only call once
        if (initialized) revert Operator_AlreadyInitialized();

        /// Request approval for reserves from TRSRY
        TRSRY.setApprovalFor(address(this), reserve, type(uint256).max);

        /// Update range prices (wall and cushion)
        _updateRangePrices();

        /// Regenerate sides
        _regenerate(true);
        _regenerate(false);

        /// Set initialized flag
        initialized = true;
    }

    /// @inheritdoc IOperator
    function regenerate(bool high_) external requiresAuth {
        /// Regenerate side
        _regenerate(high_);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice          Update the capacity on the RANGE module.
    /// @param high_     Whether to update the high side or low side capacity (true = high, false = low).
    /// @param reduceBy_ The amount to reduce the capacity by (OHM tokens for high side, Reserve tokens for low side).
    function _updateCapacity(bool high_, uint256 reduceBy_) internal {
        /// Initialize update variables, decrement capacity if a reduceBy amount is provided
        uint256 capacity = RANGE.capacity(high_) - reduceBy_;

        /// Update capacities on the range module for the wall and market
        RANGE.updateCapacity(high_, capacity);
    }

    /// @notice Update the prices on the RANGE module
    function _updateRangePrices() internal {
        /// Get latest moving average from the price module
        uint256 movingAverage = PRICE.getMovingAverage();

        /// Update the prices on the range module
        RANGE.updatePrices(movingAverage);
    }

    /// @notice Add an observation to the regeneration status variables for each side
    function _addObservation() internal {
        /// Get latest moving average from the price module
        uint256 movingAverage = PRICE.getMovingAverage();

        /// Get latest price
        /// TODO determine if this should use the last price from the MA or recalculate the current price, ideally last price is ok since it should have been just updated and should include check against secondary?
        /// Current price is guaranteed to be up to date, but may be a bad value if not checked?
        uint256 currentPrice = PRICE.getLastPrice();

        /// Store observations and update counts for regeneration

        /// Update low side regen status with a new observation
        /// Observation is positive if the current price is greater than the MA
        uint32 observe = _config.regenObserve;
        Regen memory regen = _status.low;
        if (currentPrice >= movingAverage) {
            if (!regen.observations[regen.nextObservation]) {
                _status.low.observations[regen.nextObservation] = true;
                _status.low.count++;
            }
        } else {
            if (regen.observations[regen.nextObservation]) {
                _status.low.observations[regen.nextObservation] = false;
                _status.low.count--;
            }
        }
        _status.low.nextObservation = (regen.nextObservation + 1) % observe;

        /// Update high side regen status with a new observation
        /// Observation is positive if the current price is less than the MA
        regen = _status.high;
        if (currentPrice <= movingAverage) {
            if (!regen.observations[regen.nextObservation]) {
                _status.high.observations[regen.nextObservation] = true;
                _status.high.count++;
            }
        } else {
            if (regen.observations[regen.nextObservation]) {
                _status.high.observations[regen.nextObservation] = false;
                _status.high.count--;
            }
        }
        _status.high.nextObservation = (regen.nextObservation + 1) % observe;
    }

    /// @notice      Regenerate the wall for a side
    /// @param high_ Whether to regenerate the high side or low side (true = high, false = low)
    function _regenerate(bool high_) internal {
        /// Deactivate cushion if active on the side being regenerated
        _deactivate(high_);

        if (high_) {
            /// Reset the regeneration data for the side
            _status.high.count = uint32(0);
            _status.high.observations = new bool[](_config.regenObserve);
            _status.high.nextObservation = uint32(0);
            _status.high.lastRegen = uint48(block.timestamp);

            /// Calculate capacity
            uint256 capacity = fullCapacity(true);

            /// Regenerate the side with the capacity
            RANGE.regenerate(true, capacity);
        } else {
            /// Reset the regeneration data for the side
            _status.low.count = uint32(0);
            _status.low.observations = new bool[](_config.regenObserve);
            _status.low.nextObservation = uint32(0);
            _status.low.lastRegen = uint48(block.timestamp);

            /// Calculate capacity
            uint256 capacity = fullCapacity(false);

            /// Regenerate the side with the capacity
            RANGE.regenerate(false, capacity);
        }
    }

    /// @notice      Takes down cushions (if active) when a wall is taken down or if available capacity drops below cushion capacity
    /// @param high_ Whether to check the high side or low side cushion (true = high, false = low)
    function _checkCushion(bool high_) internal {
        /// Check if the wall is down, if so ensure the cushion is also down
        /// Additionally, if wall is not down, but the wall capacity has dropped below the cushion capacity, take the cushion down
        bool active = RANGE.active(high_);
        uint256 market = RANGE.market(high_);
        if (
            !active ||
            (active &&
                auctioneer.isLive(market) &&
                RANGE.capacity(high_) < auctioneer.currentCapacity(market))
        ) {
            _deactivate(high_);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */
    /// @inheritdoc IOperator
    function getAmountOut(ERC20 tokenIn_, uint256 amountIn_)
        public
        view
        returns (uint256)
    {
        if (tokenIn_ == ohm) {
            /// Calculate amount out
            uint256 amountOut = amountIn_.mulDiv(
                10**reserveDecimals * RANGE.price(true, false),
                10**ohmDecimals * 10**PRICE.decimals()
            );

            /// Revert if amount out exceeds capacity
            if (amountOut > RANGE.capacity(false))
                revert Operator_InsufficientCapacity();

            return amountOut;
        } else if (tokenIn_ == reserve) {
            /// Calculate amount out
            uint256 amountOut = amountIn_.mulDiv(
                10**ohmDecimals * 10**PRICE.decimals(),
                10**reserveDecimals * RANGE.price(true, true)
            );

            /// Revert if amount out exceeds capacity
            if (amountOut > RANGE.capacity(true))
                revert Operator_InsufficientCapacity();

            return amountOut;
        } else {
            revert Operator_InvalidParams();
        }
    }

    /// @inheritdoc IOperator
    function fullCapacity(bool high_) public view override returns (uint256) {
        uint256 reservesInTreasury = TRSRY.getReserveBalance(reserve);
        uint256 capacity = (reservesInTreasury * _config.reserveFactor) /
            FACTOR_SCALE;
        if (high_) {
            capacity =
                (capacity.mulDiv(
                    10**ohmDecimals * 10**PRICE.decimals(),
                    10**reserveDecimals * RANGE.price(true, true)
                ) * (FACTOR_SCALE + RANGE.spread(true) * 2)) /
                FACTOR_SCALE;
        }
        return capacity;
    }

    /// @inheritdoc IOperator
    function status() external view override returns (Status memory) {
        return _status;
    }

    /// @inheritdoc IOperator
    function config() external view override returns (Config memory) {
        return _config;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

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

    /*//////////////////////////////////////////////////////////////
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

    modifier requiresAuth() virtual {
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
import {IBondAuctioneer} from "interfaces/IBondAuctioneer.sol";
import {IBondCallback} from "interfaces/IBondCallback.sol";

interface IOperator {
    /* ========== STRUCTS =========== */

    /// @notice Configuration variables for the Operator
    struct Config {
        uint32 cushionFactor; // percent of capacity to be used for a single cushion deployment, assumes 2 decimals (i.e. 1000 = 10%)
        uint32 cushionDuration; // duration of a single cushion deployment in seconds
        uint32 cushionDebtBuffer; // Percentage over the initial debt to allow the market to accumulate at any one time. Percent with 3 decimals, e.g. 1_000 = 1 %. See IBondAuctioneer for more info.
        uint32 cushionDepositInterval; // Target frequency of deposits. Determines max payout of the bond market. See IBondAuctioneer for more info.
        uint32 reserveFactor; // percent of reserves in treasury to be used for a single wall, assumes 2 decimals (i.e. 1000 = 10%)
        uint32 regenWait; // minimum duration to wait to reinstate a wall in seconds
        uint32 regenThreshold; // number of price points on other side of moving average to reinstate a wall
        uint32 regenObserve; // number of price points to observe to determine regeneration
    }

    /// @notice Combines regeneration status for low and high sides of the range
    struct Status {
        Regen low; // regeneration status for the low side of the range
        Regen high; // regeneration status for the high side of the range
    }

    /// @notice Tracks status of when a specific side of the range can be regenerated by the Operator
    struct Regen {
        uint32 count; // current number of price points that count towards regeneration
        uint48 lastRegen; // timestamp of the last regeneration
        uint32 nextObservation; // index of the next observation in the observations array
        bool[] observations; // individual observations: true = price on other side of average, false = price on same side of average
    }

    /* ========== HEART FUNCTIONS ========== */

    /// @notice     Executes market operations logic.
    /// @notice     Access restricted
    /// @dev        This function is triggered by a keeper on the Heart contract.
    function operate() external;

    /* ========== OPEN MARKET OPERATIONS (WALL) ========== */

    /// @notice              Swap at the current wall prices
    /// @param tokenIn_      Token to swap into the wall
    ///                      If OHM: swap at the low wall price for Reserve
    ///                      If Reserve: swap at the high wall price for OHM
    /// @param amountIn_     Amount of tokenIn to swap
    /// @param minAmountOut_ Minimum amount of opposite token to receive
    /// @return amountOut    Amount of opposite token received
    function swap(
        ERC20 tokenIn_,
        uint256 amountIn_,
        uint256 minAmountOut_
    ) external returns (uint256 amountOut);

    /// @notice             Returns the amount to be received from a swap
    /// @param tokenIn_     Token to swap into the wall
    ///                     If OHM: swap at the low wall price for Reserve
    ///                     If Reserve: swap at the high wall price for OHM
    /// @param amountIn_    Amount of tokenIn to swap
    /// @return             Amount of opposite token received
    function getAmountOut(ERC20 tokenIn_, uint256 amountIn_)
        external
        view
        returns (uint256);

    /* ========== OPERATOR CONFIGURATION ========== */

    /// @notice                 Set the wall and cushion spreads
    /// @notice                 Access restricted
    /// @dev                    Interface for externally setting these values on the RANGE module
    /// @param cushionSpread_   Percent spread to set the cushions at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%)
    /// @param wallSpread_      Percent spread to set the walls at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%)
    function setSpreads(uint256 cushionSpread_, uint256 wallSpread_) external;

    /// @notice                 Set the threshold factor for when a wall is considered "down"
    /// @notice                 Access restricted
    /// @dev                    Interface for externally setting this value on the RANGE module
    /// @param thresholdFactor_ Percent of capacity that the wall should close below, assumes 2 decimals (i.e. 1000 = 10%)
    function setThresholdFactor(uint256 thresholdFactor_) external;

    /// @notice                 Set the cushion factor
    /// @notice                 Access restricted
    /// @param cushionFactor_   Percent of wall capacity that the operator will deploy in the cushion, assumes 2 decimals (i.e. 1000 = 10%)
    function setCushionFactor(uint32 cushionFactor_) external;

    /// @notice                 Set the parameters used to deploy cushion bond markets
    /// @notice                 Access restricted
    /// @param duration_        Duration of cushion bond markets in seconds
    /// @param debtBuffer_      Percentage over the initial debt to allow the market to accumulate at any one time. Percent with 3 decimals, e.g. 1_000 = 1 %. See IBondAuctioneer for more info.
    /// @param depositInterval_ Target frequency of deposits in seconds. Determines max payout of the bond market. See IBondAuctioneer for more info.
    function setCushionParams(
        uint32 duration_,
        uint32 debtBuffer_,
        uint32 depositInterval_
    ) external;

    /// @notice                 Set the reserve factor
    /// @notice                 Access restricted
    /// @param reserveFactor_   Percent of treasury reserves to deploy as capacity for market operations, assumes 2 decimals (i.e. 1000 = 10%)
    function setReserveFactor(uint32 reserveFactor_) external;

    /// @notice                 Set the wall regeneration parameters
    /// @notice                 Access restricted
    /// @param wait_            Minimum duration to wait to reinstate a wall in seconds
    /// @param threshold_       Number of price points on other side of moving average to reinstate a wall
    /// @param observe_         Number of price points to observe to determine regeneration
    /// @dev                    We must see Threshold number of price points that meet our criteria within the last Observe number of price points to regenerate a wall.
    function setRegenParams(
        uint32 wait_,
        uint32 threshold_,
        uint32 observe_
    ) external;

    /// @notice                 Set the contracts that the Operator deploys bond markets with.
    /// @notice                 Access restricted
    /// @param auctioneer_      Address of the bond auctioneer to use.
    /// @param callback_        Address of the callback to use.
    function setBondContracts(
        IBondAuctioneer auctioneer_,
        IBondCallback callback_
    ) external;

    /// @notice                 Initialize the Operator to begin market operations
    /// @notice                 Access restricted
    /// @notice                 Can only be called once
    /// @dev                    This function executes actions required to start operations that cannot be done prior to the Operator policy being approved by the Kernel.
    function initialize() external;

    /// @notice      Regenerate the wall for a side
    /// @notice      Access restricted
    /// @param high_ Whether to regenerate the high side or low side (true = high, false = low)
    /// @dev         This function is an escape hatch to trigger out of cycle regenerations and may be useful when doing migrations of Treasury funds
    function regenerate(bool high_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice         Returns the full capacity of the specified wall (if it was regenerated now)
    /// @dev            Calculates the capacity to deploy for a wall based on the amount of reserves owned by the treasury and the reserve factor.
    /// @param high_    Whether to return the full capacity for the high or low wall
    function fullCapacity(bool high_) external view returns (uint256);

    /// @notice   Returns the status variable of the Operator as a Status struct
    function status() external view returns (Status memory);

    /// @notice   Returns the config variable of the Operator as a Config struct
    function config() external view returns (Config memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondTeller} from "./IBondTeller.sol";
import {IBondAggregator} from "./IBondAggregator.sol";

interface IBondAuctioneer {
    /// @notice             Creates a new bond market
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
    /// @dev                    8. Is fixed term ? Vesting length (seconds) : Vesting expiration (timestamp).
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

    /// @notice                 Creates a new bond market
    /// @param params_          Configuration data needed for market creation
    /// @return id              ID of new bond market
    function createMarket(MarketParams memory params_)
        external
        returns (uint256);

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
    function maxAmountAccepted(uint256 id_, address referrer_)
        external
        view
        returns (uint256);

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
    function amountsForMarket(uint256 id_)
        external
        view
        returns (uint256 in_, uint256 out_);

    /// @notice         Whitelist a teller and market ID combination
    /// @notice         Must be callback owner
    /// @param teller_  Address of the Teller contract which serves the market
    /// @param id_      ID of the market
    function whitelist(address teller_, uint256 id_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

import {TransferHelper} from "libraries/TransferHelper.sol";

import {Kernel, Module} from "src/Kernel.sol";

// ERRORS
error TRSRY_NotApproved();

/// @title TRSRY - OlympusTreasury
/// @notice Treasury holds reserves, LP tokens and all other assets under the control
/// of the protocol. Any contracts that need access to treasury assets should
/// be whitelisted by governance and given proper role.
contract OlympusTreasury is Module, ReentrancyGuard {
    using TransferHelper for ERC20;

    event ApprovedForWithdrawal(
        address indexed policy_,
        ERC20 indexed token_,
        uint256 amount_
    );
    event Withdrawal(
        address indexed policy_,
        address indexed withdrawer_,
        ERC20 indexed token_,
        uint256 amount_
    );
    event DebtIncurred(
        ERC20 indexed token_,
        address indexed policy_,
        uint256 amount_
    );
    event DebtRepaid(
        ERC20 indexed token_,
        address indexed policy_,
        uint256 amount_
    );
    event DebtSet(
        ERC20 indexed token_,
        address indexed policy_,
        uint256 amount_
    );

    Kernel.Role public constant APPROVER = Kernel.Role.wrap("TRSRY_Approver");
    Kernel.Role public constant BANKER = Kernel.Role.wrap("TRSRY_Banker");
    Kernel.Role public constant DEBT_ADMIN =
        Kernel.Role.wrap("TRSRY_DebtAdmin");

    // user -> reserve -> amount
    // infinite approval is max(uint256). Should be reserved monitored subsystems.
    mapping(address => mapping(ERC20 => uint256)) public withdrawApproval;

    // TODO debt for address and token mapping
    mapping(ERC20 => uint256) public totalDebt; // reserve -> totalDebt
    mapping(ERC20 => mapping(address => uint256)) public reserveDebt; // TODO reserve -> debtor -> debt

    constructor(Kernel kernel_) Module(kernel_) {}

    function KEYCODE() public pure override returns (Kernel.Keycode) {
        return Kernel.Keycode.wrap("TRSRY");
    }

    function ROLES() public pure override returns (Kernel.Role[] memory roles) {
        roles = new Kernel.Role[](3);
        roles[0] = APPROVER;
        roles[1] = BANKER;
        roles[2] = DEBT_ADMIN;
    }

    function getReserveBalance(ERC20 token_) external view returns (uint256) {
        return token_.balanceOf(address(this)) + totalDebt[token_];
    }

    // Set approval for specific addresses
    function setApprovalFor(
        address withdrawer_,
        ERC20 token_,
        uint256 amount_
    ) external onlyRole(APPROVER) {
        withdrawApproval[withdrawer_][token_] = amount_;

        emit ApprovedForWithdrawal(withdrawer_, token_, amount_);
    }

    // Allow withdrawal of reserve funds from pre-approved addresses
    function withdrawReserves(
        address to_,
        ERC20 token_,
        uint256 amount_
    ) public {
        _checkApproval(msg.sender, token_, amount_);

        token_.safeTransfer(to_, amount_);

        emit Withdrawal(msg.sender, to_, token_, amount_);
    }

    // DEBT FUNCTIONS

    function loanReserves(ERC20 token_, uint256 amount_)
        external
        onlyRole(BANKER)
    {
        _checkApproval(msg.sender, token_, amount_);

        // Add debt to caller
        reserveDebt[token_][msg.sender] += amount_;
        totalDebt[token_] += amount_;

        token_.safeTransfer(msg.sender, amount_);

        emit DebtIncurred(token_, msg.sender, amount_);
    }

    function repayLoan(ERC20 token_, uint256 amount_)
        external
        nonReentrant
        onlyRole(BANKER)
    {
        // Deposit from caller first (to handle nonstandard token transfers)
        uint256 prevBalance = token_.balanceOf(address(this));
        token_.safeTransferFrom(msg.sender, address(this), amount_);

        uint256 received = token_.balanceOf(address(this)) - prevBalance;

        // Subtract debt to caller
        reserveDebt[token_][msg.sender] -= received;
        totalDebt[token_] -= received;

        emit DebtRepaid(token_, msg.sender, received);
    }

    // To be used as escape hatch for setting debt in special cases, like swapping reserves to another token
    function setDebt(
        ERC20 token_,
        address debtor_,
        uint256 amount_
    ) external onlyRole(DEBT_ADMIN) {
        uint256 oldDebt = reserveDebt[token_][debtor_];

        // Set debt for debtor
        reserveDebt[token_][debtor_] = amount_;

        if (oldDebt < amount_) totalDebt[token_] += amount_ - oldDebt;
        else totalDebt[token_] -= oldDebt - amount_;

        emit DebtSet(token_, debtor_, amount_);
    }

    function _checkApproval(
        address withdrawer_,
        ERC20 token_,
        uint256 amount_
    ) internal {
        // Must be approved
        uint256 approval = withdrawApproval[withdrawer_][token_];
        if (approval < amount_) revert TRSRY_NotApproved();

        // Check for infinite approval
        if (approval != type(uint256).max) {
            unchecked {
                withdrawApproval[withdrawer_][token_] = approval - amount_;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {OlympusERC20Token as OHM} from "src/external/OlympusERC20.sol";
import {Kernel, Module} from "src/Kernel.sol";

// Wrapper for minting and burning functions of OHM token
contract OlympusMinter is Module {
    // ######################## ~ CONSTANTS ~ ########################

    Kernel.Role public constant MINTER = Kernel.Role.wrap("MINTR_Minter");
    Kernel.Role public constant BURNER = Kernel.Role.wrap("MINTR_Burner");

    OHM public immutable ohm;

    // ######################## ~ KERNEL INTERFACE ~ ########################

    constructor(Kernel kernel_, address ohm_) Module(kernel_) {
        ohm = OHM(ohm_);
    }

    function KEYCODE() public pure override returns (Kernel.Keycode) {
        return Kernel.Keycode.wrap("MINTR");
    }

    function ROLES() public pure override returns (Kernel.Role[] memory roles) {
        roles = new Kernel.Role[](2);
        roles[0] = MINTER;
        roles[1] = BURNER;
    }

    // ######################## ~ INTERFACE ~ ########################

    function mintOhm(address to_, uint256 amount_) public onlyRole(MINTER) {
        ohm.mint(to_, amount_);
    }

    function burnOhm(address from_, uint256 amount_) public onlyRole(BURNER) {
        ohm.burnFrom(from_, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {AggregatorV2V3Interface} from "interfaces/AggregatorV2V3Interface.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Kernel, Module} from "src/Kernel.sol";

import {FullMath} from "libraries/FullMath.sol";

/* ========== ERRORS =========== */
error Price_InvalidParams();
error Price_NotInitialized();
error Price_AlreadyInitialized();
error Price_BadFeed(address priceFeed);

/// @title  Olympus Price Oracle
/// @notice Olympus Price Oracle (Module) Contract
/// @dev    The Olympus Price Oracle contract provides a standard interface for OHM price data against a reserve asset.
///         It also implements a moving average price calculation (same as a TWAP) on the price feed data over a configured
///         duration and observation frequency. The data provided by this contract is used by the Olympus Range Operator to
///         perform market operations. The Olympus Price Oracle is updated each epoch by the Olympus Heart contract.
contract OlympusPrice is Module {
    using FullMath for uint256;

    /* ========== EVENTS =========== */
    event NewObservation(uint256 timestamp, uint256 price);

    /* ========== STATE VARIABLES ========== */

    Kernel.Role public constant KEEPER = Kernel.Role.wrap("PRICE_Keeper");
    Kernel.Role public constant GUARDIAN = Kernel.Role.wrap("PRICE_Guardian");

    /// Chainlink Price Feeds
    /// @dev Chainlink typically provides price feeds for an asset in ETH. Therefore, we use two price feeds against ETH, one for OHM and one for the Reserve asset, to calculate the relative price of OHM in the Reserve asset.
    AggregatorV2V3Interface internal immutable _ohmEthPriceFeed;
    AggregatorV2V3Interface internal immutable _reserveEthPriceFeed;

    /// Moving average data
    uint256 internal _movingAverage; /// See getMovingAverage()

    /// @notice Array of price observations. Check nextObsIndex to determine latest data point.
    /// @dev    Observations are stored in a ring buffer where the moving average is the sum of all observations divided by the number of observations.
    ///         Observations can be cleared by changing the movingAverageDuration or observationFrequency and must be re-initialized.
    uint256[] public observations;

    /// @notice Index of the next observation to make. The current value at this index is the oldest observation.
    uint32 public nextObsIndex;

    /// @notice Number of observations used in the moving average calculation. Computed from movingAverageDuration / observationFrequency.
    uint32 public numObservations;

    /// @notice Frequency (in seconds) that observations should be stored.
    uint48 public observationFrequency;

    /// @notice Duration (in seconds) over which the moving average is calculated.
    uint48 public movingAverageDuration;

    /// @notice Unix timestamp of last observation (in seconds).
    uint48 public lastObservationTime;

    /// @notice Number of decimals in the price values provided by the contract.
    uint8 public constant decimals = 18;

    /// @notice Whether the price module is initialized (and therefore active).
    bool public initialized;

    // Scale factor for converting prices, calculated from decimal values.
    uint256 internal immutable _scaleFactor;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        Kernel kernel_,
        AggregatorV2V3Interface ohmEthPriceFeed_,
        AggregatorV2V3Interface reserveEthPriceFeed_,
        uint48 observationFrequency_,
        uint48 movingAverageDuration_
    ) Module(kernel_) {
        /// @dev Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (
            movingAverageDuration_ == 0 ||
            movingAverageDuration_ % observationFrequency_ != 0
        ) revert Price_InvalidParams();

        // Set price feeds, decimals, and scale factor
        _ohmEthPriceFeed = ohmEthPriceFeed_;
        uint8 ohmEthDecimals = _ohmEthPriceFeed.decimals();

        _reserveEthPriceFeed = reserveEthPriceFeed_;
        uint8 reserveEthDecimals = _reserveEthPriceFeed.decimals();

        uint256 exponent = decimals + reserveEthDecimals - ohmEthDecimals;
        if (exponent > 38) revert Price_InvalidParams();
        _scaleFactor = 10**exponent;

        /// Set parameters and calculate number of observations
        observationFrequency = observationFrequency_;
        movingAverageDuration = movingAverageDuration_;

        numObservations = uint32(
            movingAverageDuration_ / observationFrequency_
        );

        /// Store blank observations array
        observations = new uint256[](numObservations);
        /// nextObsIndex is initialized to 0
    }

    /* ========== FRAMEWORK CONFIGURATION ========== */
    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Kernel.Keycode) {
        return Kernel.Keycode.wrap("PRICE");
    }

    function ROLES() public pure override returns (Kernel.Role[] memory roles) {
        roles = new Kernel.Role[](2);
        roles[0] = KEEPER;
        roles[1] = GUARDIAN;
    }

    /* ========== POLICY FUNCTIONS ========== */
    /// @notice Trigger an update of the moving average
    /// @notice Access restricted to approved policies
    /// @dev This function does not have a time-gating on the observationFrequency on this contract. It is set on the Heart policy contract.
    ///      The Heart beat frequency should be set to the same value as the observationFrequency.
    function updateMovingAverage() external onlyRole(KEEPER) {
        /// Revert if not initialized
        if (!initialized) revert Price_NotInitialized();

        /// Cache numbe of observations to save gas.
        uint32 numObs = numObservations;

        /// Get earliest observation in window
        uint256 earliestPrice = observations[nextObsIndex];

        /// Get current price
        uint256 currentPrice = getCurrentPrice();

        /// Calculate new moving average
        if (currentPrice > earliestPrice) {
            _movingAverage += (currentPrice - earliestPrice) / numObs;
        } else {
            _movingAverage -= (earliestPrice - currentPrice) / numObs;
        }

        /// Push new observation into storage and store timestamp taken at
        observations[nextObsIndex] = currentPrice;
        lastObservationTime = uint48(block.timestamp);
        nextObsIndex = (nextObsIndex + 1) % numObs;

        /// Emit event
        emit NewObservation(block.timestamp, currentPrice);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Get the current price of OHM in the Reserve asset from the price feeds
    function getCurrentPrice() public view returns (uint256) {
        /// Revert if not initialized
        if (!initialized) revert Price_NotInitialized();

        /// Get prices from feeds
        uint256 ohmEthPrice;
        uint256 reserveEthPrice;
        {
            (, int256 ohmEthPriceInt, , uint256 updatedAt, ) = _ohmEthPriceFeed
                .latestRoundData();
            /// Use a multiple of observation frequency to determine what is too old to use.
            /// Price feeds will not provide an updated answer if the data doesn't change much.
            /// This would be similar to if the feed just stopped updating; therefore, we need a cutoff.
            if (updatedAt < block.timestamp - 3 * uint256(observationFrequency))
                revert Price_BadFeed(address(_ohmEthPriceFeed));
            ohmEthPrice = uint256(ohmEthPriceInt);

            int256 reserveEthPriceInt;
            (, reserveEthPriceInt, , updatedAt, ) = _reserveEthPriceFeed
                .latestRoundData();
            if (updatedAt < block.timestamp - uint256(observationFrequency))
                revert Price_BadFeed(address(_reserveEthPriceFeed));
            reserveEthPrice = uint256(reserveEthPriceInt);
        }

        /// Convert to OHM/RESERVE price
        uint256 currentPrice = (ohmEthPrice * _scaleFactor) / reserveEthPrice;

        return currentPrice;
    }

    /// @notice Get the last stored price observation of OHM in the Reserve asset
    function getLastPrice() external view returns (uint256) {
        /// Revert if not initialized
        if (!initialized) revert Price_NotInitialized();
        uint32 lastIndex = nextObsIndex == 0
            ? numObservations - 1
            : nextObsIndex - 1;
        return observations[lastIndex];
    }

    /// @notice Get the moving average of OHM in the Reserve asset over the defined window (see movingAverageDuration and observationFrequency).
    function getMovingAverage() external view returns (uint256) {
        /// Revert if not initialized
        if (!initialized) revert Price_NotInitialized();
        return _movingAverage;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /// @notice                     Initialize the price module
    /// @notice                     Access restricted to approved policies
    /// @param startObservations_   Array of observations to initialize the moving average with. Must be of length numObservations.
    /// @param lastObservationTime_ Unix timestamp of last observation being provided (in seconds).
    /// @dev This function must be called after the Price module is deployed to activate it and after updating the observationFrequency
    ///      or movingAverageDuration (in certain cases) in order for the Price module to function properly.
    function initialize(
        uint256[] memory startObservations_,
        uint48 lastObservationTime_
    ) external onlyRole(GUARDIAN) {
        /// Revert if already initialized
        if (initialized) revert Price_AlreadyInitialized();

        /// Cache numObservations to save gas.
        uint256 numObs = observations.length;

        /// Check that the number of start observations matches the number expected
        if (
            startObservations_.length != numObs ||
            lastObservationTime_ > uint48(block.timestamp)
        ) revert Price_InvalidParams();

        /// Push start observations into storage and total up observations
        uint256 total;
        for (uint256 i; i < numObs; ) {
            if (startObservations_[i] == 0) revert Price_InvalidParams();
            total += startObservations_[i];
            observations[i] = startObservations_[i];
            unchecked {
                ++i;
            }
        }

        /// Set moving average, last observation time, and initialized flag
        _movingAverage = total / numObs;
        lastObservationTime = lastObservationTime_;
        initialized = true;
    }

    /// @notice                         Change the moving average window (duration)
    /// @param movingAverageDuration_   Moving average duration in seconds, must be a multiple of observation frequency
    /// @dev Changing the moving average duration will erase the current observations array
    ///      and require the initialize function to be called again. Ensure that you have saved
    ///      the existing data and can re-populate before calling this function.
    function changeMovingAverageDuration(uint48 movingAverageDuration_)
        external
        onlyRole(GUARDIAN)
    {
        /// Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (
            movingAverageDuration_ == 0 ||
            movingAverageDuration_ % observationFrequency != 0
        ) revert Price_InvalidParams();

        /// Calculate the new number of observations
        uint256 newObservations = uint256(
            movingAverageDuration_ / observationFrequency
        );

        /// Store blank observations array of new size
        observations = new uint256[](newObservations);

        /// Set initialized to false and update state variables
        initialized = false;
        lastObservationTime = 0;
        _movingAverage = 0;
        nextObsIndex = 0;
        movingAverageDuration = movingAverageDuration_;
        numObservations = uint32(newObservations);
    }

    /// @notice   Change the observation frequency of the moving average (i.e. how often a new observation is taken)
    /// @param    observationFrequency_   Observation frequency in seconds, must be a divisor of the moving average duration
    /// @dev      Changing the observation frequency clears existing observation data since it will not be taken at the right time intervals.
    ///           Ensure that you have saved the existing data and/or can re-populate before calling this function.
    function changeObservationFrequency(uint48 observationFrequency_)
        external
        onlyRole(GUARDIAN)
    {
        /// Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (
            observationFrequency_ == 0 ||
            movingAverageDuration % observationFrequency_ != 0
        ) revert Price_InvalidParams();

        /// Calculate the new number of observations
        uint256 newObservations = uint256(
            movingAverageDuration / observationFrequency_
        );

        /// Since the old observations will not be taken at the right intervals,
        /// the observations array will need to be reinitialized.
        /// Although, there are a handful of situations that could be handled
        /// (e.g. clean multiples of the old frequency),
        /// it is easier to do so off-chain and reinitialize the array.

        /// Store blank observations array of new size
        observations = new uint256[](newObservations);

        /// Set initialized to false and update state variables
        initialized = false;
        lastObservationTime = 0;
        _movingAverage = 0;
        nextObsIndex = 0;
        observationFrequency = observationFrequency_;
        numObservations = uint32(newObservations);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {TransferHelper} from "libraries/TransferHelper.sol";
import {FullMath} from "libraries/FullMath.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Kernel, Module} from "src/Kernel.sol";

error RANGE_InvalidParams();

/// @title  Olympus Range Data
/// @notice Olympus Range Data (Module) Contract
/// @dev    The Olympus Range Data contract stores information about the Olympus Range market operations status.
///         It provides a standard interface for Range data, including range prices and capacities of each range side.
///         The data provided by this contract is used by the Olympus Range Operator to perform market operations.
///         The Olympus Range Data is updated each epoch by the Olympus Range Operator contract.
contract OlympusRange is Module {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== EVENTS =========== */

    event WallUp(bool high, uint256 timestamp, uint256 capacity);
    event WallDown(bool high, uint256 timestamp);
    event CushionUp(bool high, uint256 timestamp, uint256 capacity);
    event CushionDown(bool high, uint256 timestamp);

    /* ========== STRUCTS =========== */

    struct Line {
        uint256 price; // Price for the specified level
    }

    struct Band {
        Line high; // Price of the high side of the band
        Line low; // Price of the low side of the band
        uint256 spread; // Spread of the band (increase/decrease from the moving average to set the band prices), percent with 2 decimal places (i.e. 1000 = 10% spread)
    }

    struct Side {
        bool active; // Whether or not the side is active (i.e. the Operator is performing market operations on this side, true = active, false = inactive)
        uint48 lastActive; // Unix timestamp when the side was last active (in seconds)
        uint256 capacity; // Amount of tokens that can be used to defend the side of the range. Specified in OHM tokens on the high side and Reserve tokens on the low side.
        uint256 threshold; // Amount of tokens under which the side is taken down. Specified in OHM tokens on the high side and Reserve tokens on the low side.
        uint256 market; // Market ID of the cushion bond market for the side. If no market is active, the market ID is set to max uint256 value.
    }

    struct Range {
        Side low; // Data specific to the low side of the range
        Side high; // Data specific to the high side of the range
        Band cushion; // Data relevant to cushions on both sides of the range
        Band wall; // Data relevant to walls on both sides of the range
    }

    /* ========== STATE VARIABLES ========== */

    Kernel.Role public constant OPERATOR = Kernel.Role.wrap("RANGE_Operator");

    /// Range data singleton. See range().
    Range internal _range;

    /// @notice Threshold factor for the change, a percent in 2 decimals (i.e. 1000 = 10%). Determines how much of the capacity must be spent before the side is taken down.
    /// @dev    A threshold is required so that a wall is not "active" with a capacity near zero, but unable to be depleted practically (dust).
    uint256 public thresholdFactor;

    /// Constants
    uint256 public constant FACTOR_SCALE = 1e4;

    /// Tokens
    /// @notice OHM token contract address
    ERC20 public immutable ohm;

    /// @notice Reserve token contract address
    ERC20 public immutable reserve;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        Kernel kernel_,
        ERC20[2] memory tokens_,
        uint256[3] memory rangeParams_ // [thresholdFactor, cushionSpread, wallSpread]
    ) Module(kernel_) {
        _range = Range({
            low: Side({
                active: false,
                lastActive: uint48(block.timestamp),
                capacity: 0,
                threshold: 0,
                market: type(uint256).max
            }),
            high: Side({
                active: false,
                lastActive: uint48(block.timestamp),
                capacity: 0,
                threshold: 0,
                market: type(uint256).max
            }),
            cushion: Band({
                low: Line({price: 0}),
                high: Line({price: 0}),
                spread: rangeParams_[1]
            }),
            wall: Band({
                low: Line({price: 0}),
                high: Line({price: 0}),
                spread: rangeParams_[2]
            })
        });

        thresholdFactor = rangeParams_[0];
        ohm = tokens_[0];
        reserve = tokens_[1];
    }

    /* ========== FRAMEWORK CONFIGURATION ========== */
    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Kernel.Keycode) {
        return Kernel.Keycode.wrap("RANGE");
    }

    function ROLES() public pure override returns (Kernel.Role[] memory roles) {
        roles = new Kernel.Role[](1);
        roles[0] = OPERATOR;
    }

    /* ========== POLICY FUNCTIONS ========== */
    /// @notice                 Update the capacity for a side of the range.
    /// @notice                 Access restricted to approved policies.
    /// @param high_            Specifies the side of the range to update capacity for (true = high side, false = low side).
    /// @param capacity_        Amount to set the capacity to (OHM tokens for high side, Reserve tokens for low side).
    function updateCapacity(bool high_, uint256 capacity_)
        external
        onlyRole(OPERATOR)
    {
        if (high_) {
            /// Update capacity
            _range.high.capacity = capacity_;

            /// If the new capacity is below the threshold, deactivate the wall if they are currently active
            if (capacity_ < _range.high.threshold && _range.high.active) {
                /// Set wall to inactive
                _range.high.active = false;
                _range.high.lastActive = uint48(block.timestamp);

                // /// Set cushion to inactive
                // updateMarket(true, type(uint256).max, 0);

                /// Emit event
                emit WallDown(true, block.timestamp);
            }
        } else {
            /// Update capacity
            _range.low.capacity = capacity_;

            /// If the new capacity is below the threshold, deactivate the wall if they are currently active
            if (capacity_ < _range.low.threshold && _range.low.active) {
                /// Set wall to inactive
                _range.low.active = false;
                _range.low.lastActive = uint48(block.timestamp);

                // /// Set cushion to inactive
                // updateMarket(false, type(uint256).max, 0);

                /// Emit event
                emit WallDown(false, block.timestamp);
            }
        }
    }

    /// @notice                 Update the prices for the low and high sides.
    /// @notice                 Access restricted to approved policies.
    /// @param movingAverage_   Current moving average price to set range prices from.
    function updatePrices(uint256 movingAverage_) external onlyRole(OPERATOR) {
        /// Cache the spreads
        uint256 wallSpread = _range.wall.spread;
        uint256 cushionSpread = _range.cushion.spread;

        /// Calculate new wall and cushion values from moving average and spread
        _range.wall.low.price =
            (movingAverage_ * (FACTOR_SCALE - wallSpread)) /
            FACTOR_SCALE;
        _range.wall.high.price =
            (movingAverage_ * (FACTOR_SCALE + wallSpread)) /
            FACTOR_SCALE;

        _range.cushion.low.price =
            (movingAverage_ * (FACTOR_SCALE - cushionSpread)) /
            FACTOR_SCALE;
        _range.cushion.high.price =
            (movingAverage_ * (FACTOR_SCALE + cushionSpread)) /
            FACTOR_SCALE;
    }

    /// @notice                 Regenerate a side of the range to a specific capacity.
    /// @notice                 Access restricted to approved policies.
    /// @param high_            Specifies the side of the range to regenerate (true = high side, false = low side).
    /// @param capacity_        Amount to set the capacity to (OHM tokens for high side, Reserve tokens for low side).
    function regenerate(bool high_, uint256 capacity_)
        external
        onlyRole(OPERATOR)
    {
        uint256 threshold = (capacity_ * thresholdFactor) / FACTOR_SCALE;

        if (high_) {
            /// Re-initialize the high side
            _range.high = Side({
                active: true,
                lastActive: uint48(block.timestamp),
                capacity: capacity_,
                threshold: threshold,
                market: _range.high.market
            });
        } else {
            /// Reinitialize the low side
            _range.low = Side({
                active: true,
                lastActive: uint48(block.timestamp),
                capacity: capacity_,
                threshold: threshold,
                market: _range.low.market
            });
        }

        emit WallUp(high_, block.timestamp, capacity_);
    }

    /// @notice                 Update the market ID (cushion) for a side of the range.
    /// @notice                 Access restricted to approved policies.
    /// @param high_            Specifies the side of the range to update market for (true = high side, false = low side).
    /// @param market_          Market ID to set for the side.
    /// @param marketCapacity_  Amount to set the last market capacity to (OHM tokens for high side, Reserve tokens for low side).
    function updateMarket(
        bool high_,
        uint256 market_,
        uint256 marketCapacity_
    ) public onlyRole(OPERATOR) {
        /// If market id is max uint256, then marketCapacity must be 0
        if (market_ == type(uint256).max && marketCapacity_ != 0)
            revert RANGE_InvalidParams();

        /// Store updated state
        if (high_) {
            _range.high.market = market_;
        } else {
            _range.low.market = market_;
        }

        /// Emit events
        if (market_ == type(uint256).max) {
            emit CushionDown(high_, block.timestamp);
        } else {
            emit CushionUp(high_, block.timestamp, marketCapacity_);
        }
    }

    /// @notice                 Set the wall and cushion spreads.
    /// @notice                 Access restricted to approved policies.
    /// @param cushionSpread_   Percent spread to set the cushions at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%).
    /// @param wallSpread_      Percent spread to set the walls at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%).
    /// @dev The new spreads will not go into effect until the next time updatePrices() is called.
    function setSpreads(uint256 cushionSpread_, uint256 wallSpread_)
        external
        onlyRole(OPERATOR)
    {
        /// Confirm spreads are within allowed values
        if (
            wallSpread_ > 10000 ||
            wallSpread_ < 100 ||
            cushionSpread_ > 10000 ||
            cushionSpread_ < 100 ||
            cushionSpread_ > wallSpread_
        ) revert RANGE_InvalidParams();

        /// Set spreads
        _range.wall.spread = wallSpread_;
        _range.cushion.spread = cushionSpread_;
    }

    /// @notice                 Set the threshold factor for when a wall is considered "down".
    /// @notice                 Access restricted to approved policies.
    /// @param thresholdFactor_ Percent of capacity that the wall should close below, assumes 2 decimals (i.e. 1000 = 10%).
    /// @dev The new threshold factor will not go into effect until the next time regenerate() is called for each side of the wall.
    function setThresholdFactor(uint256 thresholdFactor_)
        external
        onlyRole(OPERATOR)
    {
        /// Confirm threshold factor is within allowed values
        if (thresholdFactor_ > 10000 || thresholdFactor_ < 100)
            revert RANGE_InvalidParams();

        /// Set threshold factor
        thresholdFactor = thresholdFactor_;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Get the full Range data in a struct.
    function range() external view returns (Range memory) {
        return _range;
    }

    /// @notice         Get the capacity for a side of the range.
    /// @param high_    Specifies the side of the range to get capacity for (true = high side, false = low side).
    function capacity(bool high_) external view returns (uint256) {
        if (high_) {
            return _range.high.capacity;
        } else {
            return _range.low.capacity;
        }
    }

    /// @notice         Get the status of a side of the range (whether it is active or not).
    /// @param high_    Specifies the side of the range to get status for (true = high side, false = low side).
    function active(bool high_) external view returns (bool) {
        if (high_) {
            return _range.high.active;
        } else {
            return _range.low.active;
        }
    }

    /// @notice         Get the price for the wall or cushion for a side of the range.
    /// @param wall_    Specifies the band to get the price for (true = wall, false = cushion).
    /// @param high_    Specifies the side of the range to get the price for (true = high side, false = low side).
    function price(bool wall_, bool high_) external view returns (uint256) {
        if (wall_) {
            if (high_) {
                return _range.wall.high.price;
            } else {
                return _range.wall.low.price;
            }
        } else {
            if (high_) {
                return _range.cushion.high.price;
            } else {
                return _range.cushion.low.price;
            }
        }
    }

    /// @notice        Get the spread for the wall or cushion band.
    /// @param wall_   Specifies the band to get the spread for (true = wall, false = cushion).
    function spread(bool wall_) external view returns (uint256) {
        if (wall_) {
            return _range.wall.spread;
        } else {
            return _range.cushion.spread;
        }
    }

    /// @notice         Get the market ID for a side of the range.
    /// @param high_    Specifies the side of the range to get market for (true = high side, false = low side).
    function market(bool high_) external view returns (uint256) {
        if (high_) {
            return _range.high.market;
        } else {
            return _range.low.market;
        }
    }

    /// @notice         Get the timestamp when the range was last active.
    /// @param high_    Specifies the side of the range to get timestamp for (true = high side, false = low side).
    function lastActive(bool high_) external view returns (uint256) {
        if (high_) {
            return _range.high.lastActive;
        } else {
            return _range.low.lastActive;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

// ######################## ~ ERRORS ~ ########################

// MODULE

error Module_NotAuthorized();

// POLICY

error Policy_ModuleDoesNotExist(Kernel.Keycode keycode_);
error Policy_OnlyKernel(address caller_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
error Kernel_ModuleAlreadyInstalled(Kernel.Keycode module_);
error Kernel_InvalidModuleUpgrade(Kernel.Keycode module_);
error Kernel_PolicyAlreadyApproved(address policy_);
error Kernel_PolicyNotApproved(address policy_);

// ######################## ~ GLOBAL TYPES ~ ########################

enum Actions {
    InstallModule,
    UpgradeModule,
    ApprovePolicy,
    TerminatePolicy,
    ChangeExecutor
}

struct Instruction {
    Actions action;
    address target;
}

// ######################## ~ CONTRACT TYPES ~ ########################

abstract contract Module {
    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    modifier onlyRole(Kernel.Role role_) {
        if (!kernel.hasRole(msg.sender, role_)) revert Module_NotAuthorized();
        _;
    }

    function KEYCODE() public pure virtual returns (Kernel.Keycode);

    function ROLES() public pure virtual returns (Kernel.Role[] memory roles);

    /// @notice Specify which version of a module is being implemented.
    /// @dev Minor version change retains interface. Major version upgrade indicates
    ///      breaking change to the interface.
    function VERSION()
        external
        pure
        virtual
        returns (uint8 major, uint8 minor)
    {}
}

abstract contract Policy {
    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert Policy_OnlyKernel(msg.sender);
        _;
    }

    function configureReads() external virtual onlyKernel {}

    function requestRoles()
        external
        view
        virtual
        returns (Kernel.Role[] memory roles)
    {}

    function getModuleAddress(bytes5 keycode_) internal view returns (address) {
        Kernel.Keycode keycode = Kernel.Keycode.wrap(keycode_);
        address moduleForKeycode = kernel.getModuleForKeycode(keycode);

        if (moduleForKeycode == address(0))
            revert Policy_ModuleDoesNotExist(keycode);

        return moduleForKeycode;
    }
}

contract Kernel {
    // ######################## ~ TYPES ~ ########################

    type Role is bytes32;
    type Keycode is bytes5;

    // ######################## ~ VARS ~ ########################

    address public executor;

    // ######################## ~ DEPENDENCY MANAGEMENT ~ ########################

    address[] public allPolicies;

    mapping(Keycode => address) public getModuleForKeycode; // get contract for module keycode

    mapping(address => Keycode) public getKeycodeForModule; // get module keycode for contract

    mapping(address => bool) public approvedPolicies; // whitelisted apps

    mapping(address => mapping(Role => bool)) public hasRole;

    // ######################## ~ EVENTS ~ ########################

    event RolesUpdated(
        Role indexed role_,
        address indexed policy_,
        bool indexed granted_
    );

    event ActionExecuted(Actions indexed action_, address indexed target_);

    // ######################## ~ BODY ~ ########################

    constructor() {
        executor = msg.sender;
    }

    // ######################## ~ MODIFIERS ~ ########################

    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    // ######################## ~ KERNEL INTERFACE ~ ########################

    function executeAction(Actions action_, address target_)
        external
        onlyExecutor
    {
        if (action_ == Actions.InstallModule) {
            _installModule(target_);
        } else if (action_ == Actions.UpgradeModule) {
            _upgradeModule(target_);
        } else if (action_ == Actions.ApprovePolicy) {
            _approvePolicy(target_);
        } else if (action_ == Actions.TerminatePolicy) {
            _terminatePolicy(target_);
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    // ######################## ~ KERNEL INTERNAL ~ ########################

    function _installModule(address newModule_) internal {
        Keycode keycode = Module(newModule_).KEYCODE();

        if (getModuleForKeycode[keycode] != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
    }

    function _upgradeModule(address newModule_) internal {
        Keycode keycode = Module(newModule_).KEYCODE();
        address oldModule = getModuleForKeycode[keycode];

        if (oldModule == address(0) || oldModule == newModule_)
            revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        _reconfigurePolicies();
    }

    function _approvePolicy(address policy_) internal {
        if (approvedPolicies[policy_])
            revert Kernel_PolicyAlreadyApproved(policy_);

        approvedPolicies[policy_] = true;

        Policy(policy_).configureReads();

        Role[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, true);

        allPolicies.push(policy_);
    }

    function _terminatePolicy(address policy_) internal {
        if (!approvedPolicies[policy_])
            revert Kernel_PolicyNotApproved(policy_);

        approvedPolicies[policy_] = false;

        Role[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, false);
    }

    function _reconfigurePolicies() internal {
        uint256 len = allPolicies.length;
        for (uint256 i; i < len; ) {
            address policy_ = allPolicies[i];

            if (approvedPolicies[policy_]) Policy(policy_).configureReads();

            unchecked {
                ++i;
            }
        }
    }

    function _setPolicyRoles(
        address policy_,
        Role[] memory requests_,
        bool grant_
    ) internal {
        uint256 len = requests_.length;

        for (uint256 i; i < len; ) {
            Role request = requests_[i];

            hasRole[policy_][request] = grant_;

            emit RolesUpdated(request, policy_, grant_);

            unchecked {
                ++i;
            }
        }
    }

    function iterate(uint256 index_, uint256 condition_) internal pure {}
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
            abi.encodeWithSelector(
                ERC20.transferFrom.selector,
                from,
                to,
                amount
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.approve.selector, to, amount)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "APPROVE_FAILED"
        );
    }
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondAuctioneer} from "./IBondAuctioneer.sol";
import {IBondTeller} from "./IBondTeller.sol";

interface IBondAggregator {
    /// @notice             Register a auctioneer with the aggregator
    /// @notice             Only Guardian
    /// @param auctioneer_  Address of the Auctioneer to register
    /// @dev                A auctioneer must be registered with an aggregator to create markets
    function registerAuctioneer(IBondAuctioneer auctioneer_) external;

    /// @notice             Register a new market with the aggregator
    /// @notice             Only registered depositories
    /// @param payoutToken_   Token to be paid out by the market
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
    function maxAmountAccepted(uint256 id_, address referrer_)
        external
        view
        returns (uint256);

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

    /// @notice             Returns an array of all active market IDs for a given payout and quote token
    /// @param payout_      Address of payout token
    /// @param quote_       Address of quote token
    function marketsFor(address payout_, address quote_)
        external
        view
        returns (uint256[] memory);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

/// @notice Olympus OHM token
/// @dev This contract is the legacy v2 OHM token. Included in the repo for completeness,
///      since it is not being changed and is imported in some contracts.

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event GuardianPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event PolicyPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event VaultPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// File: types/OlympusAccessControlled.sol

abstract contract OlympusAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPermitted() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IOlympusAuthority _newAuthority)
        external
        onlyGovernor
    {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// File: cryptography/ECDSA.sol

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(
                vs,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// File: cryptography/EIP712.sol

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = chainID;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        if (chainID == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    chainID,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// File: interfaces/IERC20Permit.sol

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as th xe allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: interfaces/IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: interfaces/IOHM.sol

interface IOHM is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// File: libraries/SafeMath.sol

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// File: libraries/Counters.sol

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: types/ERC20.sol

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
        keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

// File: types/ERC20Permit.sol

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner)
        internal
        virtual
        returns (uint256 current)
    {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// File: OlympusERC20.sol

contract OlympusERC20Token is ERC20Permit, IOHM, OlympusAccessControlled {
    using SafeMath for uint256;

    constructor(address _authority)
        ERC20("Olympus", "OHM", 9)
        ERC20Permit("Olympus")
        OlympusAccessControlled(IOlympusAuthority(_authority))
    {}

    function mint(address account_, uint256 amount_)
        external
        override
        onlyVault
    {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external override {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
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

interface AggregatorV2V3Interface is
    AggregatorInterface,
    AggregatorV3Interface
{}