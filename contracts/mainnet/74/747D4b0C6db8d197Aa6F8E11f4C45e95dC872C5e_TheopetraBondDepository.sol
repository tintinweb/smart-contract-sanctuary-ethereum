// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

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
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
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
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-1.0

pragma solidity >=0.7.5 <=0.8.10;

interface IBondCalculator {
    function valuation(address tokenIn, uint256 amount_) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IBondDepository {
    // Info about each type of market
    struct Market {
        uint256 capacity; // capacity remaining
        IERC20 quoteToken; // token to accept as payment
        bool capacityInQuote; // capacity limit is in payment token (true) or in THEO (false, default)
        uint256 sold; // base tokens out
        uint256 purchased; // quote tokens in
        uint256 totalDebt; // total debt from market
        uint256 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
    }

    // Info for creating new markets
    struct Terms {
        bool fixedTerm; // fixed term or fixed expiration
        uint48 vesting; // length of time from deposit to maturity if fixed-term
        uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
        int64 bondRateFixed; // 9 decimal fixed discount expressed as a proportion (that is, a percentage in its decimal form)
        int64 maxBondRateVariable; // 9 decimal maximum proportion (that is, a percentage in its decimal form) discount on current market price
        int64 discountRateBond; // 9 decimal
        int64 discountRateYield; // 9 decimal
        uint256 maxDebt; // 9 decimal debt maximum in THEO
    }

    // Additional info about market.
    struct Metadata {
        uint48 lastTune; // last timestamp when control variable was tuned
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint48 length; // time from creation to conclusion. used as speed to decay debt.
        uint64 depositInterval; // target frequency of deposits
        uint64 tuneInterval; // frequency of tuning
        uint8 quoteDecimals; // decimals of quote token
    }

    struct DepositArgs {
        uint256 id;
        uint256 amount;
        uint256 maxPrice;
        address user;
        address referral;
        bool autoStake;
    }

    /**
     * @notice deposit market
     * @param _bid uint256
     * @param _amount uint256
     * @param _maxPrice uint256
     * @param _user address
     * @param _referral address
     * @return payout_ uint256
     * @return expiry_ uint256
     * @return index_ uint256
     */
    function deposit(
        uint256 _bid,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral,
        bool _autoStake
    )
        external
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        );

    function create(
        IERC20 _quoteToken, // token used to deposit
        uint256[3] memory _market, // [capacity, initial price]
        bool[2] memory _booleans, // [capacity in quote, fixed term]
        uint256[2] memory _terms, // [vesting, conclusion]
        int64[4] memory _rates, // [bondRateFixed, maxBondRateVariable, initial discountRateBond (Drb), initial discountRateYield (Dyb)]
        uint64[2] memory _intervals // [deposit interval, tune interval]
    ) external returns (uint256 id_);

    function close(uint256 _id) external;

    function isLive(uint256 _bid) external view returns (bool);

    function liveMarkets() external view returns (uint256[] memory);

    function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);

    function getMarkets() external view returns (uint256[] memory);

    function getMarketsFor(address _quoteToken) external view returns (uint256[] memory);

    function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);

    function marketPrice(uint256 _bid) external view returns (uint256);

    function currentDebt(uint256 _bid) external view returns (uint256);

    function debtDecay(uint256 _bid) external view returns (uint64);

    function setDiscountRateBond(uint256 _id, int64 _discountRateBond) external;

    function setDiscountRateYield(uint256 _id, int64 _discountRateYield) external;

    function bondRateVariable(uint256 _id) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

interface INoteKeeper {
    /**
     * @notice  Info for market note
     * @dev     Note::payout is sTHEO remaining to be paid
     *          Note::created is the time the Note was created
     *          Note::matured is the timestamp when the Note is redeemable
     *          Note::redeemed is time market was redeemed
     *          Note::marketID is market ID of deposit. uint48 to avoid adding a slot.
     */
    struct Note {
        uint256 payout;
        uint48 created;
        uint48 matured;
        uint48 redeemed;
        uint48 marketID;
        uint48 discount;
        bool autoStake;
    }

    function redeem(address _user, uint256[] memory _indexes) external returns (uint256);

    function redeemAll(address _user) external returns (uint256);

    function pushNote(address to, uint256 index) external;

    function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index)
        external
        view
        returns (
            uint256 payout_,
            uint48 created_,
            uint48 expiry_,
            uint48 timeRemaining_,
            bool matured_,
            uint48 discount_
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IStakedTHEOToken is IERC20 {
    function rebase(uint256 theoProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view override returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _claim
    ) external returns (uint256, uint256 _index);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit(uint256 _index) external;

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function claimAll(address _recipient) external returns (uint256);

    function pushClaim(address _to, uint256 _index) external;

    function pullClaim(address _from, uint256 _index) external returns (uint256 newIndex_);

    function pushClaimForBond(address _to, uint256 _index) external returns (uint256 newIndex_);

    function basis() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITheopetraAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event ManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event SignerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event ManagerPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event SignerPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function manager() external view returns (address);

    function vault() external view returns (address);

    function whitelistSigner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IBondCalculator.sol";

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function tokenPerformanceUpdate() external;

    function baseSupply() external view returns (uint256);

    function deltaTokenPrice() external view returns (int256);

    function deltaTreasuryYield() external view returns (int256);

    function getTheoBondingCalculator() external view returns (IBondCalculator);

    function setTheoBondingCalculator(address _theoBondingCalculator) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import { IERC20 } from "../Interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{ value: amount }(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../Types/NoteKeeper.sol";

import "../Libraries/SafeERC20.sol";

import "../Interfaces/IERC20Metadata.sol";
import "../Interfaces/IBondDepository.sol";
import "../Interfaces/ITreasury.sol";
import "../Interfaces/IBondCalculator.sol";

/**
 * @title Theopetra Bond Depository
 * @notice Originally based off of Olympus Bond Depository V2
 */

contract TheopetraBondDepository is IBondDepository, NoteKeeper {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /* ======== EVENTS ======== */

    event CreateMarket(uint256 indexed id, address indexed baseToken, address indexed quoteToken, uint256 initialPrice);
    event CloseMarket(uint256 indexed id);
    event Bond(uint256 indexed id, uint256 amount, uint256 price);
    event SetDYB(uint256 indexed id, int64 dYB);
    event SetDRB(uint256 indexed id, int64 dRB);

    /* ======== STATE VARIABLES ======== */

    // Storage
    Market[] public markets; // persistent market data
    Terms[] public terms; // deposit construction data
    Metadata[] public metadata; // extraneous market data

    // Queries
    mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token

    /* ======== STRUCTS ======== */

    struct PriceInfo {
        uint256 price;
        uint48 bondRateVariable;
    }

    /* ======== CONSTRUCTOR ======== */

    constructor(
        ITheopetraAuthority _authority,
        IERC20 _theo,
        IStakedTHEOToken _stheo,
        IStaking _staking,
        ITreasury _treasury
    ) NoteKeeper(_authority, _theo, _stheo, _staking, _treasury) {
        // save gas for users by bulk approving stake() transactions
        _theo.approve(address(_staking), 1e45);
    }

    /* ======== DEPOSIT ======== */

    /**
     * @notice             deposit quote tokens in exchange for a bond from a specified market
     * @param _id          the ID of the market
     * @param _amount      the amount of quote token to spend
     * @param _maxPrice    the maximum price at which to buy
     * @param _user        the recipient of the payout
     * @param _referral    the front end operator address
     * @return payout_     the amount of sTHEO due
     * @return expiry_     the timestamp at which payout is redeemable
     * @return index_      the user index of the Note (used to redeem or query information)
     */
    function deposit(
        uint256 _id,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral,
        bool _autoStake
    )
        external
        override
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        )
    {
        // prevent "stack too deep"
        DepositArgs memory depositInfo = DepositArgs(_id, _amount, _maxPrice, _user, _referral, _autoStake);

        Market storage market = markets[depositInfo.id];
        Terms memory term = terms[depositInfo.id];
        PriceInfo memory priceInfo;
        uint48 currentTime = uint48(block.timestamp);

        // Markets end at a defined timestamp
        // |-------------------------------------| t
        require(currentTime < term.conclusion, "Depository: market concluded");

        // Debt decays over time
        _decay(depositInfo.id, currentTime);

        // Users input a maximum price, which protects them from price changes after
        // entering the mempool. max price is a slippage mitigation measure
        priceInfo.price = marketPrice(depositInfo.id);
        require(priceInfo.price <= depositInfo.maxPrice, "Depository: more than max price");
        /**
         * payout for the deposit = amount / price
         *
         * where
         * payout = THEO out
         * amount = quote tokens in
         * price = quote tokens : theo (i.e. 42069 DAI : THEO)
         *
         * 1e18 = THEO decimals (9) + price decimals (9)
         */
        payout_ = ((depositInfo.amount * 1e18) / priceInfo.price) / (10**metadata[depositInfo.id].quoteDecimals);

        // markets have a max payout amount, capping size because deposits
        // do not experience slippage. max payout is recalculated upon tuning
        require(payout_ <= market.maxPayout, "Depository: max size exceeded");

        /*
         * each market is initialized with a capacity
         *
         * this is either the number of THEO that the market can sell
         * (if capacity in quote is false),
         *
         * or the number of quote tokens that the market can buy
         * (if capacity in quote is true)
         */
        market.capacity -= market.capacityInQuote ? depositInfo.amount : payout_;

        /**
         * bonds mature with a cliff at a set timestamp
         * prior to the expiry timestamp, no payout tokens are accessible to the user
         * after the expiry timestamp, the entire payout can be redeemed
         *
         * there are two types of bonds: fixed-term and fixed-expiration
         *
         * fixed-term bonds mature in a set amount of time from deposit
         * i.e. term = 1 week. when alice deposits on day 1, her bond
         * expires on day 8. when bob deposits on day 2, his bond expires day 9.
         *
         * fixed-expiration bonds mature at a set timestamp
         * i.e. expiration = day 10. when alice deposits on day 1, her term
         * is 9 days. when bob deposits on day 2, his term is 8 days.
         */
        expiry_ = term.fixedTerm ? term.vesting + currentTime : term.vesting;

        // markets keep track of how many quote tokens have been
        // purchased, and how much THEO has been sold
        market.purchased += depositInfo.amount;
        market.sold += payout_;

        // increment total debt, which is later compared to maxDebt (this can be a circuit-breaker)
        market.totalDebt += payout_;

        emit Bond(depositInfo.id, depositInfo.amount, priceInfo.price);

        /**
         * user data is stored as Notes. these are isolated array entries
         * storing the amount due, the time created, the time when payout
         * is redeemable, the time when payout was redeemed, the ID
         * of the market deposited into, and the Bond Rate Variable (Brv) discount on the bond
         */
        priceInfo.bondRateVariable = uint48(bondRateVariable(depositInfo.id));
        index_ = addNote(
            depositInfo.user,
            payout_,
            uint48(expiry_),
            uint48(depositInfo.id),
            depositInfo.referral,
            priceInfo.bondRateVariable,
            depositInfo.autoStake
        );

        // transfer payment to treasury
        market.quoteToken.safeTransferFrom(msg.sender, address(treasury), depositInfo.amount);

        // if max debt is breached, the market is closed
        // this a circuit breaker
        if (term.maxDebt < market.totalDebt) {
            market.capacity = 0;
            emit CloseMarket(depositInfo.id);
        } else {
            // if market will continue, the control variable is tuned to hit targets on time
            _tune(depositInfo.id, currentTime);
        }
    }

    /**
     * @notice             decay debt, and adjust control variable if there is an active change
     * @param _id          ID of market
     * @param _time        uint48 timestamp (saves gas when passed in)
     */
    function _decay(uint256 _id, uint48 _time) internal {
        // Debt decay

        /*
         * Debt is a time-decayed sum of tokens spent in a market
         * Debt is added when deposits occur and removed over time
         * |
         * |    debt falls with
         * |   / \  inactivity       / \
         * | /     \              /\/    \
         * |         \           /         \
         * |           \      /\/            \
         * |             \  /  and rises       \
         * |                with deposits
         * |
         * |------------------------------------| t
         */
        markets[_id].totalDebt -= debtDecay(_id);
        metadata[_id].lastDecay = _time;
    }

    /**
     * @notice          adjust the market's maxPayout
     * @dev             calculate the correct payout to complete on time assuming each bond
     *                  will be max size in the desired deposit interval for the remaining time
     *                  i.e. market has 10 days remaining. deposit interval is 1 day. capacity
     *                  is 10,000 THEO. max payout would be 1,000 THEO (10,000 * 1 / 10).
     * @param _id       ID of market
     * @param _time     uint48 timestamp (saves gas when passed in)
     */
    function _tune(uint256 _id, uint48 _time) internal {
        Metadata memory meta = metadata[_id];

        if (_time >= meta.lastTune + meta.tuneInterval) {
            Market memory market = markets[_id];

            // compute seconds remaining until market will conclude
            uint256 timeRemaining = terms[_id].conclusion - _time;
            uint256 price = marketPrice(_id);

            // standardize capacity into a base token amount
            // theo decimals (9) + price decimals (9)
            uint256 capacity = market.capacityInQuote
                ? ((market.capacity * 1e18) / price) / (10**meta.quoteDecimals)
                : market.capacity;

            markets[_id].maxPayout = uint256((capacity * meta.depositInterval) / timeRemaining);

            metadata[_id].lastTune = _time;
        }
    }

    /* ======== CREATE ======== */

    /**
     * @notice             creates a new market type
     * @dev                current price should be in 9 decimals.
     * @param _quoteToken  token used to deposit
     * @param _market      [capacity (in THEO or quote), initial price / THEO (9 decimals), debt buffer (3 decimals)]
     * @param _booleans    [capacity in quote, fixed term]
     * @param _terms       [vesting length (if fixed term) or vested timestamp, conclusion timestamp]
     * @param _rates       [bondRateFixed, maxBondRateVariable, initial discountRateBond (Drb), initial discountRateYield (Dyb)]
     * @param _intervals   [deposit interval (seconds), tune interval (seconds)]
     * @return id_         ID of new bond market
     */
    function create(
        IERC20 _quoteToken,
        uint256[3] memory _market,
        bool[2] memory _booleans,
        uint256[2] memory _terms,
        int64[4] memory _rates,
        uint64[2] memory _intervals
    ) external override onlyPolicy returns (uint256 id_) {
        // the length of the program, in seconds
        uint256 secondsToConclusion = _terms[1] - block.timestamp;

        // the decimal count of the quote token
        uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();

        /*
         * initial target debt is equal to capacity (this is the amount of debt
         * that will decay over in the length of the program if price remains the same).
         * it is converted into base token terms if passed in in quote token terms.
         *
         * 1e18 = theo decimals (9) + initial price decimals (9)
         */
        uint256 targetDebt = uint256(_booleans[0] ? ((_market[0] * 1e18) / _market[1]) / 10**decimals : _market[0]);

        /*
         * max payout is the amount of capacity that should be utilized in a deposit
         * interval. for example, if capacity is 1,000 THEO, there are 10 days to conclusion,
         * and the preferred deposit interval is 1 day, max payout would be 100 THEO.
         */
        uint256 maxPayout = (targetDebt * _intervals[0]) / secondsToConclusion;

        /*
         * max debt serves as a circuit breaker for the market. let's say the quote
         * token is a stablecoin, and that stablecoin depegs. without max debt, the
         * market would continue to buy until it runs out of capacity. this is
         * configurable with a 3 decimal buffer (1000 = 1% above initial price).
         * note that its likely advisable to keep this buffer wide.
         * note that the buffer is above 100%. i.e. 10% buffer = initial debt * 1.1
         */
        uint256 maxDebt = targetDebt + ((targetDebt * _market[2]) / 1e5); // 1e5 = 100,000. 10,000 / 100,000 = 10%.

        // depositing into, or getting info for, the created market uses this ID
        id_ = markets.length;

        markets.push(
            Market({
                quoteToken: _quoteToken,
                capacityInQuote: _booleans[0],
                capacity: _market[0],
                totalDebt: targetDebt,
                maxPayout: maxPayout,
                purchased: 0,
                sold: 0
            })
        );

        terms.push(
            Terms({
                fixedTerm: _booleans[1],
                vesting: uint48(_terms[0]),
                conclusion: uint48(_terms[1]),
                bondRateFixed: int64(_rates[0]),
                maxBondRateVariable: int64(_rates[1]),
                discountRateBond: int64(_rates[2]),
                discountRateYield: int64(_rates[3]),
                maxDebt: maxDebt
            })
        );

        metadata.push(
            Metadata({
                lastTune: uint48(block.timestamp),
                lastDecay: uint48(block.timestamp),
                length: uint48(secondsToConclusion),
                depositInterval: uint64(_intervals[0]),
                tuneInterval: uint64(_intervals[1]),
                quoteDecimals: uint8(decimals)
            })
        );

        marketsForQuote[address(_quoteToken)].push(id_);

        emit CreateMarket(id_, address(theo), address(_quoteToken), _market[1]);
    }

    /**
     * @notice             disable existing market
     * @param _id          ID of market to close
     */
    function close(uint256 _id) external override onlyPolicy {
        terms[_id].conclusion = uint48(block.timestamp);
        markets[_id].capacity = 0;
        emit CloseMarket(_id);
    }

    /* ======== BONDING RATES ======== */

    /**
     * @notice                      update the Discount Rate Return Bond (Drb) for a specified market
     * @param _id                   uint256 the ID of the bond market to update
     * @param _discountRateBond     uint64 the new Discount Rate Return Bond (Drb), 9 decimals
     */
    function setDiscountRateBond(uint256 _id, int64 _discountRateBond) external override onlyPolicy {
        terms[_id].discountRateBond = _discountRateBond;
        emit SetDRB(_id, _discountRateBond);
    }

    /**
     * @notice                      update the Discount Rate Return Yield (Dyb) for a specified market
     * @param _id                   uint256 the ID of the bond market to update
     * @param _discountRateYield    uint64 the new Discount Rate Return Yield (Dyb), 9 decimals
     */
    function setDiscountRateYield(uint256 _id, int64 _discountRateYield) external override onlyPolicy {
        terms[_id].discountRateYield = _discountRateYield;
        emit SetDYB(_id, _discountRateYield);
    }

    /**
     * @notice                  calculate bond rate variable (Brv)
     * @dev                     see marketPrice for calculation details.
     * @param _id               ID of market
     */
    function bondRateVariable(uint256 _id) public view override returns (uint256) {
        int256 bondRateVariable = int64(terms[_id].bondRateFixed) +
            ((int64(terms[_id].discountRateBond) * ITreasury(treasury).deltaTokenPrice()) / 10**9) + //deltaTokenPrice is 9 decimals
            ((int64(terms[_id].discountRateYield) * ITreasury(treasury).deltaTreasuryYield()) / 10**9); // deltaTreasuryYield is 9 decimals

        if (bondRateVariable <= 0) {
            return 0;
        } else if (bondRateVariable >= terms[_id].maxBondRateVariable) {
            return uint256(uint64(terms[_id].maxBondRateVariable));
        } else {
            return bondRateVariable.toUint256();
        }
    }

    /* ======== EXTERNAL VIEW ======== */

    /**
     * @notice             calculate current market price of quote token in base token (i.e. quote tokens per THEO)
     * @dev                uses the theoBondingCalculator.valuation method (using an amount of 1) to get the quote token value (Quote-Token per THEO).
     * @param _id          ID of market
     * @return             price for market in THEO decimals
     *
     * price is derived from the equation
     *
     * P = Cmv * (1 - Brv)
     *
     * where
     * p = price
     * cmv = current market value
     * Brv = bond rate, variable. This is a proportion (that is, a percentage in its decimal form), with 9 decimals
     *
     * Brv = Brf + Bcrb + Bcyb
     *
     * where
     * Brf = bond rate, fixed
     * Bcrb = Drb * deltaTokenPrice
     * Bcyb = Dyb * deltaTreasuryYield
     *
     *
     * where
     * Drb is a discount rate as a proportion (that is, a percentage in its decimal form) applied to the fluctuation in token price (deltaTokenPrice)
     * Dyb is a discount rate as a proportion (that is a percentage in its decimal form) applied to the fluctuation of the treasury yield (deltaTreasuryYield)
     * Drb, Dyb, deltaTokenPrice and deltaTreasuryYield are expressed as proportions (that is, they are a percentages in decimal form), with 9 decimals
     */
    function marketPrice(uint256 _id) public view override returns (uint256) {
        IBondCalculator theoBondingCalculator = ITreasury(NoteKeeper.treasury).getTheoBondingCalculator();
        if (address(theoBondingCalculator) == address(0)) {
            revert("No bonding calculator");
        }
        uint8 quoteTokenDecimals = IERC20Metadata(address(markets[_id].quoteToken)).decimals();
        return
            ((10**18 / (theoBondingCalculator.valuation(address(markets[_id].quoteToken), 10**quoteTokenDecimals))) *
                (10**9 - bondRateVariable(_id))) / 10**9;
    }

    /**
     * @notice             payout due for amount of quote tokens
     * @dev                accounts for debt and control variable decay so it is up to date
     * @param _amount      amount of quote tokens to spend
     * @param _id          ID of market
     * @return             amount of THEO to be paid in THEO decimals
     *
     * @dev 1e18 = theo decimals (9) + market price decimals (9)
     */
    function payoutFor(uint256 _amount, uint256 _id) external view override returns (uint256) {
        Metadata memory meta = metadata[_id];
        return (_amount * 1e18) / marketPrice(_id) / 10**meta.quoteDecimals;
    }

    /**
     * @notice             calculate debt factoring in decay
     * @dev                accounts for debt decay since last deposit
     * @param _id          ID of market
     * @return             current debt for market in THEO decimals
     */
    function currentDebt(uint256 _id) external view override returns (uint256) {
        return markets[_id].totalDebt - debtDecay(_id);
    }

    /**
     * @notice             amount of debt to decay from total debt for market ID
     * @param _id          ID of market
     * @return             amount of debt to decay
     */
    function debtDecay(uint256 _id) public view override returns (uint64) {
        Metadata memory meta = metadata[_id];

        uint256 secondsSince = block.timestamp - meta.lastDecay;

        return uint64((markets[_id].totalDebt * secondsSince) / meta.length);
    }

    /**
     * @notice             is a given market accepting deposits
     * @param _id          ID of market
     */
    function isLive(uint256 _id) public view override returns (bool) {
        return (markets[_id].capacity != 0 && terms[_id].conclusion > block.timestamp);
    }

    /**
     * @notice returns an array of all active market IDs
     */
    function liveMarkets() external view override returns (uint256[] memory) {
        uint256 num;
        for (uint256 i = 0; i < markets.length; i++) {
            if (isLive(i)) num++;
        }

        uint256[] memory ids = new uint256[](num);
        uint256 nonce;
        for (uint256 i = 0; i < markets.length; i++) {
            if (isLive(i)) {
                ids[nonce] = i;
                nonce++;
            }
        }
        return ids;
    }

    /**
     * @notice             returns an array of all active market IDs for a given quote token
     * @param _token       quote token to check for
     */
    function liveMarketsFor(address _token) external view override returns (uint256[] memory) {
        uint256[] memory mkts = marketsForQuote[_token];
        uint256 num;

        for (uint256 i = 0; i < mkts.length; i++) {
            if (isLive(mkts[i])) num++;
        }

        uint256[] memory ids = new uint256[](num);
        uint256 nonce;

        for (uint256 i = 0; i < mkts.length; i++) {
            if (isLive(mkts[i])) {
                ids[nonce] = mkts[i];
                nonce++;
            }
        }
        return ids;
    }

    /**
     * @notice returns an array of market IDs for historical analysis
     */
    function getMarkets() external view override returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
                ids[i] = i;
        }
        return ids;
    }

    /**
     * @notice             returns an array of all market IDs for a given quote token
     * @param _token       quote token to check for
     */
    function getMarketsFor(address _token) external view override returns (uint256[] memory) {
        uint256[] memory mkts = marketsForQuote[_token];
        uint256[] memory ids = new uint256[](mkts.length);

        for (uint256 i = 0; i < mkts.length; i++) {
            ids[i] = mkts[i];
        }
        return ids;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../Types/TheopetraAccessControlled.sol";
import "../Interfaces/IERC20.sol";

abstract contract FrontEndRewarder is TheopetraAccessControlled {
    /* ========= STATE VARIABLES ========== */

    uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
    uint256 public refReward; // % reward for referrer (3 decimals: 100 = 1%)
    mapping(address => uint256) public rewards; // front end operator rewards
    mapping(address => bool) public whitelisted; // whitelisted status for operators

    IERC20 internal immutable theo; // reward token

    event SetRewards(uint256 toRef, uint256 toDao);
    constructor(ITheopetraAuthority _authority, IERC20 _theo) TheopetraAccessControlled(_authority) {
        theo = _theo;
    }

    /* ========= EXTERNAL FUNCTIONS ========== */

    // pay reward to front end operator
    function getReward() external {
        uint256 reward = rewards[msg.sender];

        rewards[msg.sender] = 0;
        theo.transfer(msg.sender, reward);
    }

    /* ========= INTERNAL ========== */

    /**
     * @notice add new market payout to user data
     */
    function _giveRewards(uint256 _payout, address _referral) internal returns (uint256) {
        // first we calculate rewards paid to the DAO and to the front end operator (referrer)
        uint256 toDAO = (_payout * daoReward) / 1e4;
        uint256 toRef = (_payout * refReward) / 1e4;

        // and store them in our rewards mapping
        if (whitelisted[_referral]) {
            rewards[_referral] += toRef;
            rewards[authority.guardian()] += toDAO;
        } else {
            // the DAO receives both rewards if referrer is not whitelisted
            rewards[authority.guardian()] += toDAO + toRef;
        }
        return toDAO + toRef;
    }

    /**
     * @notice set rewards for front end operators and DAO
     */
    function setRewards(uint256 _toFrontEnd, uint256 _toDAO) external onlyGovernor {
        refReward = _toFrontEnd;
        daoReward = _toDAO;

        emit SetRewards(_toFrontEnd, _toDAO);
    }

    /**
     * @notice add or remove addresses from the reward whitelist
     */
    function whitelist(address _operator) external onlyPolicy {
        whitelisted[_operator] = !whitelisted[_operator];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./FrontEndRewarder.sol";

import "../Interfaces/IStakedTHEOToken.sol";
import "../Interfaces/IStaking.sol";
import "../Interfaces/ITreasury.sol";
import "../Interfaces/INoteKeeper.sol";

abstract contract NoteKeeper is INoteKeeper, FrontEndRewarder {
    mapping(address => Note[]) public notes; // user deposit data
    mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership
    mapping(address => mapping(uint256 => uint256)) private noteForClaim; // index of staking claim for a user's note

    event TreasuryUpdated(address addr);
    event PushNote(address from, address to, uint256 noteId);
    event PullNote(address from, address to, uint256 noteId);

    IStakedTHEOToken internal immutable sTHEO;
    IStaking internal immutable staking;
    ITreasury internal treasury;

    constructor(
        ITheopetraAuthority _authority,
        IERC20 _theo,
        IStakedTHEOToken _stheo,
        IStaking _staking,
        ITreasury _treasury
    ) FrontEndRewarder(_authority, _theo) {
        sTHEO = _stheo;
        staking = _staking;
        treasury = _treasury;
    }

    // if treasury address changes on authority, update it
    function updateTreasury() external {
        require(
            msg.sender == authority.governor() ||
                msg.sender == authority.guardian() ||
                msg.sender == authority.policy(),
            "Only authorized"
        );
        address treasuryAddress = authority.vault();
        treasury = ITreasury(treasuryAddress);
        emit TreasuryUpdated(treasuryAddress);
    }

    /* ========== ADD ========== */

    /**
     * @notice             adds a new Note for a user, stores the front end & DAO rewards, and mints & stakes payout & rewards
     * @param _user        the user that owns the Note
     * @param _payout      the amount of THEO due to the user
     * @param _expiry      the timestamp when the Note is redeemable
     * @param _marketID    the ID of the market deposited into
     * @param _discount    the discount on the bond (that is, the bond rate, variable). This is a proportion (that is, a percentage in its decimal form), with 9 decimals
     * @return index_      the index of the Note in the user's array
     */
    function addNote(
        address _user,
        uint256 _payout,
        uint48 _expiry,
        uint48 _marketID,
        address _referral,
        uint48 _discount,
        bool _autoStake
    ) internal returns (uint256 index_) {
        // the index of the note is the next in the user's array
        index_ = notes[_user].length;

        // the new note is pushed to the user's array
        notes[_user].push(
            Note({
                payout: _payout,
                created: uint48(block.timestamp),
                matured: _expiry,
                redeemed: 0,
                marketID: _marketID,
                discount: _discount,
                autoStake: _autoStake
            })
        );

        // front end operators can earn rewards by referring users
        uint256 rewards = _giveRewards(_payout, _referral);

        // mint and stake payout
        treasury.mint(address(this), _payout + rewards);

        if (_autoStake) {
            // note that only the payout gets staked (front end rewards are in THEO)
            // Get index for the claim to approve for pushing
            (, uint256 claimIndex) = staking.stake(address(this), _payout, true);
            // approve the user to transfer the staking claim
            staking.pushClaim(_user, claimIndex);

            // Map the index of the user's note to the claimIndex
            noteForClaim[_user][index_] = claimIndex;
        }
    }

    /* ========== REDEEM ========== */

    /**
     * @notice             redeem notes for user
     * @dev                adapted from Olympus V2. Olympus V2 either sends payout as gOHM
     *                     or calls an `unwrap` function on the staking contract
     *                     to convert the payout from gOHM into sOHM and then send as sOHM.
     *                     This current contract sends payout as sTHEO.
     * @param _user        the user to redeem for
     * @param _indexes     the note indexes to redeem
     * @return payout_     sum of payout sent, in sTHEO
     */
    function redeem(address _user, uint256[] memory _indexes) public override returns (uint256 payout_) {
        uint48 time = uint48(block.timestamp);
        uint256 sTheoPayout = 0;
        uint256 theoPayout = 0;

        for (uint256 i = 0; i < _indexes.length; i++) {
            (uint256 pay, , , , bool matured, ) = pendingFor(_user, _indexes[i]);

            if (matured) {
                notes[_user][_indexes[i]].redeemed = time; // mark as redeemed
                payout_ += pay;
                if (notes[_user][_indexes[i]].autoStake) {
                    uint256 _claimIndex = noteForClaim[_user][_indexes[i]];
                    staking.pushClaimForBond(_user, _claimIndex);
                    sTheoPayout += pay;
                } else {
                    theoPayout += pay;
                }
            }
        }
        if (theoPayout > 0) theo.transfer(_user, theoPayout);
        if (sTheoPayout > 0) sTHEO.transfer(_user, sTheoPayout);
    }

    /**
     * @notice             redeem all redeemable markets for user
     * @dev                if possible, query indexesFor() off-chain and input in redeem() to save gas
     * @param _user        user to redeem all notes for
     * @return             sum of payout sent, in sTHEO
     */
    function redeemAll(address _user) external override returns (uint256) {
        return redeem(_user, indexesFor(_user));
    }

    /* ========== TRANSFER ========== */

    /**
     * @notice             approve an address to transfer a note
     * @param _to          address to approve note transfer for
     * @param _index       index of note to approve transfer for
     */
    function pushNote(address _to, uint256 _index) external override {
        require(notes[msg.sender][_index].created != 0, "Depository: note not found");
        noteTransfers[msg.sender][_index] = _to;

        emit PushNote(msg.sender, _to, _index);
    }

    /**
     * @notice             transfer a note that has been approved by an address
     * @dev                if the note being pulled is autostaked then update noteForClaim as follows:
     *                     get the relevant `claimIndex` associated with the note that is being pulled.
     *                     Then add the claimIndex to the recipient's noteForClaim.
     *                     After updating noteForClaim, the staking claim is pushed to the recipient, in order to
     *                     update `claimTransfers` in the Staking contract and thereby change claim ownership (from the note's pusher to the note's recipient)
     * @param _from        the address that approved the note transfer
     * @param _index       the index of the note to transfer (in the sender's array)
     */
    function pullNote(address _from, uint256 _index) external override returns (uint256 newIndex_) {
        require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
        require(notes[_from][_index].redeemed == 0, "Depository: note redeemed");

        newIndex_ = notes[msg.sender].length;

        if (notes[_from][_index].autoStake) {
            uint256 claimIndex = noteForClaim[_from][_index];
            noteForClaim[msg.sender][newIndex_] = claimIndex;
            staking.pushClaim(msg.sender, claimIndex);
        }
        notes[msg.sender].push(notes[_from][_index]);

        delete notes[_from][_index];
        emit PullNote(_from, msg.sender, _index);
    }

    /* ========== VIEW ========== */

    // Note info

    /**
     * @notice             all pending notes for user
     * @param _user        the user to query notes for
     * @return             the pending notes for the user
     */
    function indexesFor(address _user) public view override returns (uint256[] memory) {
        Note[] memory info = notes[_user];

        uint256 length;
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0 && info[i].payout != 0) length++;
        }

        uint256[] memory indexes = new uint256[](length);
        uint256 position;

        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0 && info[i].payout != 0) {
                indexes[position] = i;
                position++;
            }
        }

        return indexes;
    }

    /**
     * @notice                  calculate amount available for claim for a single note
     * @param _user             the user that the note belongs to
     * @param _index            the index of the note in the user's array
     * @return payout_          the payout due, in sTHEO
     * @return created_         the time the note was created
     * @return expiry_          the time the note is redeemable
     * @return timeRemaining_   the time remaining until the note is matured
     * @return matured_         if the payout can be redeemed
     */
    function pendingFor(address _user, uint256 _index)
        public
        view
        override
        returns (
            uint256 payout_,
            uint48 created_,
            uint48 expiry_,
            uint48 timeRemaining_,
            bool matured_,
            uint48 discount_
        )
    {
        Note memory note = notes[_user][_index];

        payout_ = note.payout;
        created_ = note.created;
        expiry_ = note.matured;
        timeRemaining_ = note.matured > block.timestamp ? uint48(note.matured - block.timestamp) : 0;
        matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
        discount_ = note.discount;
    }

    function getNotesCount(address _user) external view returns (uint256) {
        return notes[_user].length;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../Interfaces/ITheopetraAuthority.sol";

abstract contract TheopetraAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(ITheopetraAuthority indexed authority);

    string constant UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    ITheopetraAuthority public authority;

    /* ========== Constructor ========== */

    constructor(ITheopetraAuthority _authority) {
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

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == authority.manager(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(ITheopetraAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}