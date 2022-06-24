// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {IHeart} from "./interfaces/IHeart.sol";
import {IOperator} from "./interfaces/IOperator.sol";

import {OlympusPrice} from "../modules/PRICE.sol";

import {Kernel, Policy} from "../Kernel.sol";

import {TransferHelper} from "libraries/TransferHelper.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title  Olympus Heart
/// @notice Olympus Heart (Policy) Contract
/// @dev    The Olympus Heart contract provides keeper rewards to call the heart beat function which fuels
///         Olympus market operations. The Heart orchestrates state updates in the correct order to ensure
///         market operations use up to date information.
contract Heart is IHeart, Policy, ReentrancyGuard, Auth {
    using TransferHelper for ERC20;

    /* ========== ERRORS =========== */
    error Heart_OutOfCycle();
    error Heart_BeatStopped();
    error Heart_BeatFailed();
    error Heart_InvalidParams();

    /* ========== EVENTS =========== */

    event Beat(uint256 timestamp);
    event RewardTokenUpdated(ERC20 token);

    /* ========== STATE VARIABLES ========== */

    /// @notice Status of the Heart, false = stopped, true = beating
    bool public active;

    /// @notice Timestamp of the last beat (UTC, in seconds)
    uint256 public lastBeat;

    /// @notice Heart beat frequency, in seconds
    uint256 public frequency;

    /// @notice Reward for beating the Heart (in reward token decimals)
    uint256 public reward;

    /// @notice Reward token address that users are sent for beating the Heart
    ERC20 public rewardToken;

    /// Modules
    OlympusPrice internal PRICE;

    /// Policies
    IOperator internal _operator;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        Kernel kernel_,
        IOperator operator_,
        uint256 frequency_,
        ERC20 rewardToken_,
        uint256 reward_
    ) Policy(kernel_) Auth(address(kernel_), Authority(address(0))) {
        _operator = operator_;

        active = true;
        lastBeat = block.timestamp;
        frequency = frequency_;
        rewardToken = rewardToken_;
        reward = reward_;
    }

    /* ========== FRAMEWORK CONFIGURATION ========== */
    function configureReads() external override {
        PRICE = OlympusPrice(getModuleAddress("PRICE"));
        setAuthority(Authority(getModuleAddress("AUTHR")));
    }

    function requestRoles()
        external
        view
        override
        onlyKernel
        returns (Kernel.Role[] memory roles)
    {
        roles = new Kernel.Role[](1);
        roles[0] = PRICE.KEEPER();
    }

    /* ========== KEEPER FUNCTIONS ========== */

    /// @inheritdoc IHeart
    function beat() external nonReentrant {
        if (!active) revert Heart_BeatStopped();
        if (block.timestamp < lastBeat + frequency) revert Heart_OutOfCycle();

        /// Update the moving average on the Price module
        PRICE.updateMovingAverage();

        /// Trigger price range update and market operations
        _operator.operate();

        /// Update the last beat timestamp
        lastBeat = block.timestamp;

        /// Issue reward to sender
        _issueReward(msg.sender);

        /// Emit event
        emit Beat(block.timestamp);
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    function _issueReward(address to_) internal {
        rewardToken.safeTransfer(to_, reward);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /// @inheritdoc IHeart
    function resetBeat() external requiresAuth {
        lastBeat = block.timestamp - frequency;
    }

    /// @inheritdoc IHeart
    function toggleBeat() external requiresAuth {
        active = !active;
    }

    /// @inheritdoc IHeart
    function setReward(uint256 reward_) external requiresAuth {
        reward = reward_;
    }

    /// @inheritdoc IHeart
    function setRewardToken(ERC20 token_) external requiresAuth {
        rewardToken = token_;
        emit RewardTokenUpdated(token_);
    }

    /// @inheritdoc IHeart
    function withdrawUnspentRewards(ERC20 token_) external requiresAuth {
        token_.safeTransfer(msg.sender, token_.balanceOf(address(this)));
    }

    /// @inheritdoc IHeart
    function setFrequency(uint256 frequency_) external requiresAuth {
        if (frequency_ < 1 hours) revert Heart_InvalidParams();
        frequency = frequency_;
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

interface IHeart {
    /* ========== KEEPER FUNCTIONS ========== */
    /// @notice Beats the heart
    /// @notice Only callable when enough time has passed since last beat (determined by frequency variable)
    /// @notice This function is incentivized with a token reward (see rewardToken and reward variables).
    /// @dev    Triggers price oracle update and market operations
    function beat() external;

    /* ========== ADMIN FUNCTIONS ========== */
    /// @notice Unlocks the cycle if stuck on one side, eject function
    /// @notice Access restricted
    function resetBeat() external;

    /// @notice Turns the heart on or off, emergency stop and resume function
    /// @notice Access restricted
    function toggleBeat() external;

    /// @notice           Sets the keeper reward for the beat function
    /// @notice           Access restricted
    /// @param reward_    New reward amount, in units of the reward token
    function setReward(uint256 reward_) external;

    /// @notice           Sets the reward token for the beat function
    /// @notice           Access restricted
    /// @param token_     New reward token address
    function setRewardToken(ERC20 token_) external;

    /// @notice           Withdraws unspent balance of provided token to sender
    /// @notice           Access restricted
    function withdrawUnspentRewards(ERC20 token_) external;

    /// @notice           Sets the frequency of the beat, in seconds
    /// @notice           Access restricted
    /// @param frequency_ Frequency of the beat, in seconds
    function setFrequency(uint256 frequency_) external;
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
        uint32 cushionDebtBuffer; // Percentage over the initial debt to allow the market to accumulate at anyone time. Percent with 3 decimals, e.g. 1_000 = 1 %. See IBondAuctioneer for more info.
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

    /// @notice             Swap at the current wall prices
    /// @param tokenIn_     Token to swap into the wall
    ///                     If OHM: swap at the low wall price for Reserve
    ///                     If Reserve: swap at the high wall price for OHM
    /// @param amountIn_    Amount of tokenIn to swap
    /// @return amountOut   Amount of opposite token received
    function swap(ERC20 tokenIn_, uint256 amountIn_)
        external
        returns (uint256 amountOut);

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
    /// @param debtBuffer_      Percentage over the initial debt to allow the market to accumulate at anyone time. Percent with 3 decimals, e.g. 1_000 = 1 %. See IBondAuctioneer for more info.
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
pragma solidity ^0.8.13;

import {AggregatorV2V3Interface} from "interfaces/AggregatorV2V3Interface.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Kernel, Module} from "../Kernel.sol";

import {FullMath} from "libraries/FullMath.sol";

/* ========== ERRORS =========== */
error Price_InvalidParams();
error Price_NotInitialized();
error Price_AlreadyInitialized();

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
    AggregatorV2V3Interface internal _ohmEthPriceFeed;
    AggregatorV2V3Interface internal _reserveEthPriceFeed;
    uint8 internal _ohmEthDecimals;
    uint8 internal _reserveEthDecimals;

    /// Moving average data
    uint256 internal _movingAverage; /// See getMovingAverage()

    /// @notice Array of price observations ordered by when they were observed.
    /// @dev    Observations are continually stored and the moving average is over the last movingAverageDuration / observationFrequency observations.
    ///         This allows the contract to maintain historical data. Observations can be cleared by changing the movingAverageDuration or observationFrequency.
    uint256[] public observations;

    /// @notice Frequency (in seconds) that observations should be stored.
    uint48 public observationFrequency;

    /// @notice Duration (in seconds) over which the moving average is calculated.
    uint48 public movingAverageDuration;

    /// @notice Number of observations used in the moving average calculation. Computed from movingAverageDuration / observationFrequency.
    uint48 public numObservations;

    /// @notice Unix timestamp of last observation (in seconds).
    uint48 public lastObservationTime;

    /// @notice Number of decimals in the price values provided by the contract.
    uint8 public decimals;

    /// @notice Whether the price module is initialized (and therefore active).
    bool public initialized;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        Kernel kernel_,
        AggregatorV2V3Interface ohmEthPriceFeed_,
        AggregatorV2V3Interface reserveEthPriceFeed_,
        uint48 observationFrequency_,
        uint48 movingAverageDuration_
    ) Module(kernel_) {
        /// @dev Moving Average Duration should be divislble by Observation Frequency to get a whole number of observations
        if (movingAverageDuration_ % observationFrequency_ != 0)
            revert Price_InvalidParams();

        /// Set parameters and calculate number of observations
        _ohmEthPriceFeed = ohmEthPriceFeed_;
        _ohmEthDecimals = _ohmEthPriceFeed.decimals();

        _reserveEthPriceFeed = reserveEthPriceFeed_;
        _reserveEthDecimals = _reserveEthPriceFeed.decimals();

        decimals = 18;

        observationFrequency = observationFrequency_;
        movingAverageDuration = movingAverageDuration_;

        numObservations = movingAverageDuration_ / observationFrequency_;

        /// Store blank observations array
        observations = new uint256[](numObservations);
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
        /// TODO determine if this should be opened up (don't want to conflict with heart beat and have that fail)

        /// Revert if not initialized
        if (!initialized) revert Price_NotInitialized();

        /// Cache numObservations to save gas.
        uint48 numObs = numObservations;

        /// Get earliest observation in window
        uint256 earliestPrice = observations[(observations.length - numObs)];

        /// Get current price
        uint256 currentPrice = getCurrentPrice();

        /// Calculate new moving average
        if (currentPrice > earliestPrice) {
            _movingAverage += (currentPrice - earliestPrice) / numObs;
        } else {
            _movingAverage -= (earliestPrice - currentPrice) / numObs;
        }

        /// Push new observation into storage
        observations.push(currentPrice);

        /// Emit event
        emit NewObservation(block.timestamp, currentPrice);

        // lastObservationTime = currentTime;
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
            int256 ohmEthPriceInt = _ohmEthPriceFeed.latestAnswer();
            ohmEthPrice = uint256(ohmEthPriceInt);

            int256 reserveEthPriceInt = _reserveEthPriceFeed.latestAnswer();
            reserveEthPrice = uint256(reserveEthPriceInt);
        }

        /// Convert to OHM/RESERVE price
        uint256 currentPrice = ohmEthPrice.mulDiv(
            10**(decimals + _reserveEthDecimals),
            reserveEthPrice * 10**(_ohmEthDecimals)
        );

        return currentPrice;
    }

    /// @notice Get the last stored price observation of OHM in the Reserve asset
    function getLastPrice() external view returns (uint256) {
        /// Revert if not initialized
        if (!initialized) revert Price_NotInitialized();
        return observations[observations.length - 1];
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
        uint48 numObs = numObservations;

        /// Check that the number of start observations matches the number expected
        if (
            uint48(startObservations_.length) != numObs ||
            lastObservationTime_ > uint48(block.timestamp)
        ) revert Price_InvalidParams();

        /// Push start observations into storage and total up observations
        uint256 total;
        for (uint48 i; i < numObs; ++i) {
            total += startObservations_[i];
            observations[i] = startObservations_[i];
        }

        /// Set moving average, last observation time, and initialized flag
        _movingAverage = total / uint256(numObs);
        lastObservationTime = lastObservationTime_;
        initialized = true;
    }

    /// @notice                         Change the moving average window (duration)
    /// @param movingAverageDuration_   Moving average duration in seconds, must be a multiple of observation frequency
    /// @dev Setting the window to a larger number of observations than the current window will clear
    ///      the data in the current window and require the initialize function to be called again.
    ///      Ensure that you have saved the existing data and can re-populate before calling this
    ///      function with a number of observations larger than have been recorded.
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
        uint256 obsLength = observations.length;

        /// If the number of new observations is greater than the number of observations stored,
        /// the array will need to be reinitialized.
        /// Otherwise, keep the existing array and calculate the new moving average.
        if (newObservations > obsLength) {
            /// Store blank observations array of new size
            observations = new uint256[](newObservations);

            /// Set initialized to false
            initialized = false;
        } else {
            /// Update moving average
            uint256 startIdx = obsLength - newObservations;
            uint256 newMovingAverage;
            for (uint256 i; i < newObservations; ++i) {
                newMovingAverage += observations[startIdx + i];
            }
            _movingAverage = newMovingAverage / newObservations;
        }

        /// Set parameters and number of observations
        movingAverageDuration = movingAverageDuration_;
        numObservations = uint48(newObservations);
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

        /// Set initialized to false
        initialized = false;

        /// Set parameters and number of observations
        observationFrequency = observationFrequency_;
        numObservations = uint48(newObservations);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// ######################## ~ ERRORS ~ ########################

// MODULE

error Module_NotAuthorized();

// POLICY

error Policy_ModuleDoesNotExist(Kernel.Keycode keycode_);
error Policy_OnlyKernel(address caller_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
error Kernel_ModuleAlreadyInstalled(Kernel.Keycode module_);
error Kernel_ModuleAlreadyExists(Kernel.Keycode module_);
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
        if (kernel.hasRole(msg.sender, role_) == false) {
            revert Module_NotAuthorized();
        }
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

        // @NOTE check newModule_ != 0
        if (getModuleForKeycode[keycode] != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
    }

    function _upgradeModule(address newModule_) internal {
        Keycode keycode = Module(newModule_).KEYCODE();
        address oldModule = getModuleForKeycode[keycode];

        if (oldModule == address(0) || oldModule == newModule_)
            revert Kernel_ModuleAlreadyExists(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        _reconfigurePolicies();
    }

    function _approvePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == true)
            revert Kernel_PolicyAlreadyApproved(policy_);

        approvedPolicies[policy_] = true;

        Policy(policy_).configureReads();

        Role[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, true);

        allPolicies.push(policy_);
    }

    function _terminatePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == false)
            revert Kernel_PolicyNotApproved(policy_);

        approvedPolicies[policy_] = false;

        Role[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, false);
    }

    function _reconfigurePolicies() internal {
        for (uint256 i = 0; i < allPolicies.length; i++) {
            address policy_ = allPolicies[i];

            if (approvedPolicies[policy_] == true)
                Policy(policy_).configureReads();
        }
    }

    function _setPolicyRoles(
        address policy_,
        Role[] memory requests_,
        bool grant_
    ) internal {
        uint256 l = requests_.length;

        for (uint256 i = 0; i < l; ) {
            Role request = requests_[i];

            hasRole[policy_][request] = grant_;

            emit RolesUpdated(request, policy_, grant_);

            unchecked {
                i++;
            }
        }
    }
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

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
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
    /// @param amount_          Amount to deposit in exchange for bond
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @param feeInQuote_      Should the fee be paid in quote token (true) or payout token (false)
    /// @param fee_             Percent fee to pay the protocol
    /// @return payout          Amount of payout token to be received from the bond
    /// @return feeAmount       Fee amount to the protocol
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_,
        bool feeInQuote_,
        uint48 fee_
    ) external returns (uint256 payout, uint256 feeAmount);

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
    /// @return             amount of payout tokens to be paid
    function payoutFor(uint256 amount_, uint256 id_)
        external
        view
        returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    function maxAmountAccepted(uint256 id_) external view returns (uint256);

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
    /// @param outputAmount_    Amount of base tokens to be paid out to the market
    /// @dev Must transfer the output amount of base tokens back to the Teller
    /// @dev Should check that the quote tokens have been transferred to the contract in the _callback function
    function callback(
        uint256 id_,
        uint256 inputAmount_,
        uint256 outputAmount_
    ) external;

    /// @notice         Returns the number of quote tokens received and base tokens paid out for a market
    /// @param id_      ID of the market
    /// @return in_     Amount of quote tokens bonded to the market
    /// @return out_    Amount of base tokens paid out to the market
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
    function mulDivRoundingUp(
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
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return                 Amount of payout token to be received from the bond
    /// @return                 Timestamp at which the bond token can be redeemed for the underlying token
    function purchase(
        address recipient_,
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256, uint48);

    /// @notice         Get current fee charged by the teller for a partner's markets
    /// @param partner_ Address of the partner
    /// @return         Fee in basis points (3 decimal places)
    function getFee(address partner_) external view returns (uint48);

    /// @notice         Set fee for a partner tier
    /// @notice         Must be guardian
    /// @param tier_    Tier index for the fee being set (0 is the Default tier)
    /// @param fee_     Protocol fee in basis points (3 decimal places)
    function setFeeTier(uint256 tier_, uint48 fee_) external;

    /// @notice         Set the fee tier applicable to a partner
    /// @notice         Must be guardian
    /// @param partner_ Address of the partner
    /// @param tier_    Tier index to set for the partner (0 is the Default tier)
    function setPartnerFeeTier(address partner_, uint256 tier_) external;

    /// @notice         Claim fees accrued for input tokens and sends to protocol
    /// @notice         Must be guardian
    /// @param tokens_  Array of tokens to claim fees for
    function claimFees(ERC20[] memory tokens_) external;

    /// @notice         Changes a token's status as a protocol-preferred fee token
    /// @notice         Must be policy
    /// @param token_   ERC20 token to set the status for
    /// @param status_  Add preferred fee token (true) or remove preferred fee token (false)
    function changePreferredTokenStatus(ERC20 token_, bool status_) external;
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
    /// @return             amount of payout tokens to be paid
    function payoutFor(uint256 amount_, uint256 id_)
        external
        view
        returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    function maxAmountAccepted(uint256 id_) external view returns (uint256);

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
    /// @param isPayout_      If true, search by payout token, else search for quote token
    function liveMarketsFor(address token_, bool isPayout_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given payout and quote token
    /// @param payout_        Address of payout token
    /// @param quote_       Address of quote token
    function marketsFor(address payout_, address quote_)
        external
        view
        returns (uint256[] memory);

    /// @notice                 Returns the market ID with the highest current payoutToken payout for depositing quoteToken
    /// @param payout_            Address of payout token
    /// @param quote_           Address of quote token
    /// @param amountIn_        Amount of quote tokens to deposit
    /// @param minAmountOut_    Minimum amount of payout tokens to receive as payout
    /// @param maxExpiry_       Latest acceptable vesting timestamp for bond
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