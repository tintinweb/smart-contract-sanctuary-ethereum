// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./ErrorCodes.sol";

/**
 * @title MNTSource Contract
 * @notice Distributes a token to a different contract at a fixed rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Minterest
 */
contract MNTSource {
    /// @notice The block number when the MNTSource started (immutable)
    uint256 public dripStart;

    /// @notice Tokens per block that to drip to target (immutable)
    uint256 public dripRate;

    /// @notice Reference to token to drip (immutable)
    IERC20 public token;

    /// @notice Target to receive dripped tokens (immutable)
    address public target;

    /// @notice Amount that has already been dripped
    uint256 public dripped;

    /**
     * @notice Constructs a MNTSource
     * @param dripRate_ Number of tokens per block to drip
     * @param token_ The token to drip
     * @param target_ The recipient of dripped tokens
     */
    constructor(
        uint256 dripRate_,
        IERC20 token_,
        address target_
    ) {
        require(target_ != address(0), ErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);
        dripStart = block.number;
        dripRate = dripRate_;
        token = token_;
        target = target_;
        dripped = 0;
    }

    /**
     * @notice Drips the maximum amount of tokens to match the drip rate since inception
     * @dev Note: this will only drip up to the amount of tokens available.
     * @return The amount of tokens dripped in this call
     */
    function drip() external returns (uint256) {
        // First, read storage into memory
        IERC20 token_ = token;
        uint256 mntSourceBalance_ = token_.balanceOf(address(this));
        uint256 dripRate_ = dripRate;
        uint256 dripStart_ = dripStart;
        uint256 dripped_ = dripped;
        address target_ = target;
        uint256 blockNumber_ = block.number;

        // Next, calculate intermediate values
        uint256 dripTotal_ = dripRate_ * (blockNumber_ - dripStart_);
        uint256 deltaDrip_ = dripTotal_ - dripped_;
        uint256 toDrip_ = Math.min(mntSourceBalance_, deltaDrip_);
        uint256 drippedNext_ = dripped_ + toDrip_;

        // Finally, write new `dripped` value and transfer tokens to target
        dripped = drippedNext_;
        require(token_.transfer(target_, toDrip_));

        return toDrip_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

library ErrorCodes {
    // Common
    string internal constant ADMIN_ONLY = "E101";
    string internal constant UNAUTHORIZED = "E102";
    string internal constant OPERATION_PAUSED = "E103";
    string internal constant WHITELISTED_ONLY = "E104";

    // Invalid input
    string internal constant ADMIN_ADDRESS_CANNOT_BE_ZERO = "E201";
    string internal constant INVALID_REDEEM = "E202";
    string internal constant REDEEM_TOO_MUCH = "E203";
    string internal constant WITHDRAW_NOT_ALLOWED = "E204";
    string internal constant MARKET_NOT_LISTED = "E205";
    string internal constant INSUFFICIENT_LIQUIDITY = "E206";
    string internal constant INVALID_SENDER = "E207";
    string internal constant BORROW_CAP_REACHED = "E208";
    string internal constant BALANCE_OWED = "E209";
    string internal constant UNRELIABLE_LIQUIDATOR = "E210";
    string internal constant INVALID_DESTINATION = "E211";
    string internal constant CONTRACT_DOES_NOT_SUPPORT_INTERFACE = "E212";
    string internal constant INSUFFICIENT_STAKE = "E213";
    string internal constant INVALID_DURATION = "E214";
    string internal constant INVALID_PERIOD_RATE = "E215";
    string internal constant EB_TIER_LIMIT_REACHED = "E216";
    string internal constant INVALID_DEBT_REDEMPTION_RATE = "E217";
    string internal constant LQ_INVALID_SEIZE_DISTRIBUTION = "E218";
    string internal constant EB_TIER_DOES_NOT_EXIST = "E219";
    string internal constant EB_ZERO_TIER_CANNOT_BE_ENABLED = "E220";
    string internal constant EB_ALREADY_ACTIVATED_TIER = "E221";
    string internal constant EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT = "E222";
    string internal constant EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER = "E223";
    string internal constant EB_EMISSION_BOOST_IS_NOT_IN_RANGE = "E224";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E225";
    string internal constant INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT = "E226";
    string internal constant VESTING_SCHEDULE_ALREADY_EXISTS = "E227";
    string internal constant INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE = "E228";
    string internal constant NO_VESTING_SCHEDULE = "E229";
    string internal constant SCHEDULE_IS_IRREVOCABLE = "E230";
    string internal constant SCHEDULE_START_IS_ZERO = "E231";
    string internal constant MNT_AMOUNT_IS_ZERO = "E232";
    string internal constant RECEIVER_ALREADY_LISTED = "E233";
    string internal constant RECEIVER_ADDRESS_CANNOT_BE_ZERO = "E234";
    string internal constant CURRENCY_ADDRESS_CANNOT_BE_ZERO = "E235";
    string internal constant INCORRECT_AMOUNT = "E236";
    string internal constant RECEIVER_NOT_IN_APPROVED_LIST = "E237";
    string internal constant MEMBERSHIP_LIMIT = "E238";
    string internal constant MEMBER_NOT_EXIST = "E239";
    string internal constant MEMBER_ALREADY_ADDED = "E240";
    string internal constant MEMBERSHIP_LIMIT_REACHED = "E241";
    string internal constant REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO = "E242";
    string internal constant MTOKEN_ADDRESS_CANNOT_BE_ZERO = "E243";
    string internal constant TOKEN_ADDRESS_CANNOT_BE_ZERO = "E244";
    string internal constant REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO = "E245";
    string internal constant FL_TOKEN_IS_NOT_UNDERLYING = "E246";
    string internal constant FL_AMOUNT_IS_TOO_LARGE = "E247";
    string internal constant FL_CALLBACK_FAILED = "E248";
    string internal constant DD_UNSUPPORTED_TOKEN = "E249";
    string internal constant DD_MARKET_ADDRESS_IS_ZERO = "E250";
    string internal constant DD_ROUTER_ADDRESS_IS_ZERO = "E251";
    string internal constant DD_RECEIVER_ADDRESS_IS_ZERO = "E252";
    string internal constant DD_BOT_ADDRESS_IS_ZERO = "E253";
    string internal constant DD_MARKET_NOT_FOUND = "E254";
    string internal constant DD_ROUTER_NOT_FOUND = "E255";
    string internal constant DD_RECEIVER_NOT_FOUND = "E256";
    string internal constant DD_BOT_NOT_FOUND = "E257";
    string internal constant DD_ROUTER_ALREADY_SET = "E258";
    string internal constant DD_RECEIVER_ALREADY_SET = "E259";
    string internal constant DD_BOT_ALREADY_SET = "E260";
    string internal constant EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX = "E261";
    string internal constant MV_BLOCK_NOT_YET_MINED = "E262";
    string internal constant MV_SIGNATURE_EXPIRED = "E263";
    string internal constant MV_INVALID_NONCE = "E264";
    string internal constant DD_EXPIRED_DEADLINE = "E265";
    string internal constant LQ_INVALID_DRR_ARRAY = "E266";
    string internal constant LQ_INVALID_SEIZE_ARRAY = "E267";
    string internal constant LQ_INVALID_DEBT_REDEMPTION_RATE = "E268";
    string internal constant LQ_INVALID_SEIZE_INDEX = "E269";
    string internal constant LQ_DUPLICATE_SEIZE_INDEX = "E270";

    // Protocol errors
    string internal constant INVALID_PRICE = "E301";
    string internal constant MARKET_NOT_FRESH = "E302";
    string internal constant BORROW_RATE_TOO_HIGH = "E303";
    string internal constant INSUFFICIENT_TOKEN_CASH = "E304";
    string internal constant INSUFFICIENT_TOKENS_FOR_RELEASE = "E305";
    string internal constant INSUFFICIENT_MNT_FOR_GRANT = "E306";
    string internal constant TOKEN_TRANSFER_IN_UNDERFLOW = "E307";
    string internal constant NOT_PARTICIPATING_IN_BUYBACK = "E308";
    string internal constant NOT_ENOUGH_PARTICIPATING_ACCOUNTS = "E309";
    string internal constant NOTHING_TO_DISTRIBUTE = "E310";
    string internal constant ALREADY_PARTICIPATING_IN_BUYBACK = "E311";
    string internal constant MNT_APPROVE_FAILS = "E312";
    string internal constant TOO_EARLY_TO_DRIP = "E313";
    string internal constant INSUFFICIENT_SHORTFALL = "E315";
    string internal constant HEALTHY_FACTOR_NOT_IN_RANGE = "E316";
    string internal constant BUYBACK_DRIPS_ALREADY_HAPPENED = "E317";
    string internal constant EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL = "E318";
    string internal constant NO_VESTING_SCHEDULES = "E319";
    string internal constant INSUFFICIENT_UNRELEASED_TOKENS = "E320";
    string internal constant INSUFFICIENT_FUNDS = "E321";
    string internal constant ORACLE_PRICE_EXPIRED = "E322";
    string internal constant TOKEN_NOT_FOUND = "E323";
    string internal constant RECEIVED_PRICE_HAS_INVALID_ROUND = "E324";
    string internal constant FL_PULL_AMOUNT_IS_TOO_LOW = "E325";
    string internal constant INSUFFICIENT_TOTAL_PROTOCOL_INTEREST = "E326";
    string internal constant BB_ACCOUNT_RECENTLY_VOTED = "E327";
    // Invalid input - Admin functions
    string internal constant ZERO_EXCHANGE_RATE = "E401";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant MARKET_ALREADY_LISTED = "E403";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant NEW_ORACLE_MISMATCH = "E406";
    string internal constant EC_INVALID_PROVIDER_REPRESENTATIVE = "E407";
    string internal constant EC_PROVIDER_CANT_BE_REPRESENTATIVE = "E408";
    string internal constant OR_ORACLE_ADDRESS_CANNOT_BE_ZERO = "E409";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO = "E410";
    string internal constant OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO = "E411";
    string internal constant CONTRACT_ALREADY_SET = "E412";
    string internal constant INVALID_TOKEN = "E413";
    string internal constant INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA = "E414";
    string internal constant INVALID_REDUCE_AMOUNT = "E415";
    string internal constant LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO = "E416";
    string internal constant INVALID_UTILISATION_FACTOR_MANTISSA = "E417";
    string internal constant INVALID_MTOKENS_OR_BORROW_CAPS = "E418";
    string internal constant FL_PARAM_IS_TOO_LARGE = "E419";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E420";
    string internal constant INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL = "E421";
    string internal constant EC_INVALID_BOOSTS = "E422";
    string internal constant EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER = "E423";
    string internal constant EC_ACCOUNT_HAS_NO_AGREEMENT = "E424";
    string internal constant OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO = "E425";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG = "E426";
    string internal constant OR_REPORTER_MULTIPLIER_TOO_BIG = "E427";
    string internal constant SHOULD_HAVE_REVOCABLE_SCHEDULE = "E428";
    string internal constant MEMBER_NOT_IN_DELAY_LIST = "E429";
    string internal constant DELAY_LIST_LIMIT = "E430";
}