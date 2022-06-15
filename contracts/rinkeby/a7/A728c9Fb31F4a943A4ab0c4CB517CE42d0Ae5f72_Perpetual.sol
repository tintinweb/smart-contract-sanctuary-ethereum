// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// contracts
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

// interfaces
import {IPerpetual} from "./interfaces/IPerpetual.sol";
import {IVBase} from "./interfaces/IVBase.sol";
import {IVQuote} from "./interfaces/IVQuote.sol";
import {ICryptoSwap} from "./interfaces/ICryptoSwap.sol";
import {IClearingHouse} from "./interfaces/IClearingHouse.sol";

// libraries
import {LibMath} from "./lib/LibMath.sol";
import {LibPerpetual} from "./lib/LibPerpetual.sol";

/// @notice Handles all the trading logic. Interact with the CryptoSwap pool
contract Perpetual is IPerpetual, Pausable {
    using LibMath for int256;
    using LibMath for uint256;

    // constants
    uint256 internal constant VQUOTE_INDEX = 0; // index of quote asset in curve pool
    uint256 internal constant VBASE_INDEX = 1; // index of base asset in curve pool
    uint256 internal constant CURVE_TRADING_FEE_PRECISION = 1e10; // curve trading fee precision

    // parameters
    uint256 public override twapFrequency; // period over which twap is calculated
    int256 public override sensitivity; // funding rate sensitivity to price deviations
    int256 public override maxBlockTradeAmount; // max trade amount in one block
    int256 public override tradingFee; // fee charged for each trade on the notional amount
    int256 public override insuranceFee; // paid on dollar value of an opened position (used in ClearingHouse)

    // dependencies

    /// @notice vBase token (traded on CryptoSwap pool)
    IVBase public override vBase;

    /// @notice vQuote token (traded on CryptoSwap pool)
    IVQuote public override vQuote;

    /// @notice Clearing House contract
    IClearingHouse public override clearingHouse;

    /// @notice Curve CryptoSwap pool
    ICryptoSwap public override market;

    // global state
    LibPerpetual.GlobalPosition internal globalPosition;

    int256 internal oracleCumulativeAmount;
    int256 internal oracleCumulativeAmountAtBeginningOfPeriod;
    int256 internal oracleTwap;

    int256 internal marketCumulativeAmount;
    // slither-disable-next-line similar-names
    int256 internal marketCumulativeAmountAtBeginningOfPeriod;
    int256 internal marketTwap;

    // user state
    mapping(address => LibPerpetual.TraderPosition) internal traderPosition;
    mapping(address => LibPerpetual.LiquidityProviderPosition) internal lpPosition;

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when twap is updated
    /// @param newOracleTwap Latest oracle Time-weighted-average-price
    /// @param newMarketTwap Latest market Time-weighted-average-price
    event TwapUpdated(int256 newOracleTwap, int256 newMarketTwap);

    /// @notice Emitted when funding rate is updated
    /// @param cumulativeFundingRate Cumulative sum of all funding rate updates
    /// @param fundingRate Latest fundingRate update
    event FundingRateUpdated(int256 cumulativeFundingRate, int256 fundingRate);

    /// @notice Emitted when swap with cryptoswap pool fails
    /// @param errorMessage Return error message
    event Log(string errorMessage);

    /// @notice Emitted when (base) dust is generated
    /// @param vBaseAmount Amount of dust
    event DustGenerated(uint256 vBaseAmount);

    /// @notice Emitted when parameters are changed
    event PerpetualParametersChanged(
        uint256 newTwapFrequency,
        int256 newSensitivity,
        int256 newMaxBlockTradeAmount,
        int256 newTradingFee,
        int256 newInsuranceFee
    );

    constructor(
        IVBase _vBase,
        IVQuote _vQuote,
        ICryptoSwap _market,
        IClearingHouse _clearingHouse,
        uint256 newTwapFrequency,
        int256 newSensitivity,
        int256 newMaxBlockTradeAmount,
        int256 newInsuranceFee,
        int256 _perpTradingFee
    ) {
        if (address(_vBase) == address(0)) revert Perpetual_ZeroAddressConstructor(0);
        if (address(_vQuote) == address(0)) revert Perpetual_ZeroAddressConstructor(1);
        if (address(_market) == address(0)) revert Perpetual_ZeroAddressConstructor(2);
        if (address(_clearingHouse) == address(0)) revert Perpetual_ZeroAddressConstructor(3);

        vBase = _vBase;
        vQuote = _vQuote;
        market = _market;
        clearingHouse = _clearingHouse;

        // approve all future transfers between Perpetual and market (curve pool)
        if (!vBase.approve(address(_market), type(uint256).max))
            revert Perpetual_VirtualTokenApprovalConstructor(VBASE_INDEX);
        if (!vQuote.approve(address(_market), type(uint256).max))
            revert Perpetual_VirtualTokenApprovalConstructor(VQUOTE_INDEX);

        // initialize global state
        _initGlobalState(_vBase.getIndexPrice(), _market.last_prices().toInt256());

        setParameters(newTwapFrequency, newSensitivity, newMaxBlockTradeAmount, newInsuranceFee, _perpTradingFee);

        if (market.mid_fee() != market.out_fee()) revert Perpetual_MarketEqualFees();
    }

    modifier onlyClearingHouse() {
        if (msg.sender != address(clearingHouse)) revert Perpetual_SenderNotClearingHouse();
        _;
    }

    // the owner of the market is the same owner as ClearingHouse
    modifier onlyClearingHouseOwner() {
        if (msg.sender != clearingHouse.getOwner()) revert Perpetual_SenderNotClearingHouseOwner();
        _;
    }

    /* ****************** */
    /*   Trader flow      */
    /* ****************** */

    function changePosition(
        address account,
        uint256 amount,
        LibPerpetual.Side direction,
        uint256 minAmount
    )
        external
        override
        whenNotPaused
        onlyClearingHouse
        returns (
            int256 openNotional,
            int256 positionSize,
            int256 profit,
            bool isPositionIncreased
        )
    {
        LibPerpetual.TraderPosition memory trader = traderPosition[account];
        bool isNewPosition = trader.positionSize == 0;

        if (
            isNewPosition || (trader.positionSize > 0 ? LibPerpetual.Side.Long : LibPerpetual.Side.Short) == direction
        ) {
            (openNotional, positionSize, profit) = _extendPositionMain(account, amount, direction, minAmount);
            isPositionIncreased = true;
        } else {
            (openNotional, positionSize, profit) = _reducePositionMain(account, amount, minAmount);
        }
    }

    function liquidatePosition(
        address account,
        uint256 amount,
        uint256 minAmount
    )
        external
        override
        whenNotPaused
        onlyClearingHouse
        returns (
            int256 openNotional,
            int256 positionSize,
            int256 profit
        )
    {
        (openNotional, positionSize, profit) = _reducePositionMain(account, amount, minAmount);
    }

    /// @notice Open or increase a position, either long or short
    /// @param account Address of the trader
    /// @param amount to be sold, in vQuote (if long) or vBase (if short)
    /// @param direction Long or Short
    /// @param minAmount Minimum amount received back, in vBase (if long) or vQuote (if short)
    /// @return openNotional Additional quote asset / liabilities accrued
    /// @return positionSize Additional base asset / liabilities accrued
    /// @return tradingFees Settled funding payments & Trading
    function _extendPositionMain(
        address account,
        uint256 amount,
        LibPerpetual.Side direction,
        uint256 minAmount
    )
        internal
        returns (
            int256 openNotional,
            int256 positionSize,
            int256 tradingFees
        )
    {
        /*
            if direction = LONG

                trader goes long EUR
                trader accrues openNotional debt
                trader receives positionSize assets

                openNotional = vQuote traded to market    ( < 0)
                positionSize = vBase received from market ( > 0)

            else direction = SHORT

                trader goes short EUR
                trader receives openNotional assets
                trader accrues positionSize debt

                openNotional = vQuote received from market ( > 0)
                positionSize = vBase traded to market      ( < 0)

        */

        LibPerpetual.TraderPosition storage trader = traderPosition[account];
        bool isLong = direction == LibPerpetual.Side.Long;

        // open position
        (openNotional, positionSize) = _extendPosition(amount, isLong, minAmount);

        // check max deviation
        _updateCurrentBlockTradeAmount(openNotional);
        if (!_checkBlockTradeAmount()) revert Perpetual_ExcessiveBlockTradeAmount();

        // update position
        tradingFees = -_chargeQuoteFees(openNotional);
        trader.openNotional += openNotional;
        trader.positionSize += positionSize;

        return (openNotional, positionSize, tradingFees);
    }

    /// @notice Closes position from account holder
    /// @param account Trader account to close position for.
    /// @param proposedAmount Amount of tokens to be sold, in vBase if LONG, in vQuote if SHORT. 18 decimals
    /// @param minAmount Minimum amount that the user is willing to accept, in vQuote if LONG, in vBase if SHORT. 18 decimals
    /// @return quoteProceeds Realized quote proceeds from closing the position
    /// @return baseProceeds Position size reduction
    /// @return profit Sum of PnL and trading fees
    function _reducePositionMain(
        address account,
        uint256 proposedAmount,
        uint256 minAmount
    )
        internal
        returns (
            int256 quoteProceeds,
            int256 baseProceeds,
            int256 profit
        )
    {
        /*
        after opening the position:

            trader has long position:
                openNotional = vQuote traded   to market   ( < 0)
                positionSize = vBase  received from market ( > 0)
            trader has short position
                openNotional = vQuote received from market ( > 0)
                positionSize = vBase  traded   to market   ( < 0)

        to close the position:

            trader has long position:
                @proposedAmount := amount of vBase used to reduce the position (must be below user.positionSize)
                => User trades the vBase tokens with the curve pool for vQuote tokens

            trader has short position:
                @proposedAmount := amount of vQuote required to repay the vBase debt (must be below 1.5 x market value of user.positionSize)
                => User incurred vBase debt when opening a position and must now trade enough
                  vQuote with the curve pool to repay his vBase debt in full.
                => Remaining balances can be traded with the market for vQuote.

                @audit Note that this mechanism can be exploited by inserting a large value here, since traders
                will have to pay transaction fees anyways (on the curve pool). We set a limit of 1.5 x market value in _checkProposedAmount()
        */
        LibPerpetual.TraderPosition storage trader = traderPosition[account];
        if (trader.openNotional == 0 && trader.positionSize == 0) revert Perpetual_NoOpenPosition();

        int256 positionPnL;
        int256 openNotionalToReduce;
        (baseProceeds, quoteProceeds, openNotionalToReduce, positionPnL) = _reducePosition(
            trader,
            proposedAmount,
            minAmount
        );

        _updateCurrentBlockTradeAmount(quoteProceeds);
        if (!_checkBlockTradeAmount()) revert Perpetual_ExcessiveBlockTradeAmount();

        // adjust trader position
        int256 quoteOnlyFees = _chargeQuoteFees(quoteProceeds);
        profit = positionPnL - quoteOnlyFees; // profit = pnl - quoteOnlyFees

        trader.openNotional -= openNotionalToReduce;
        trader.positionSize += baseProceeds;

        // if position has been closed entirely, delete it from the state
        if (trader.positionSize == 0) {
            delete traderPosition[account];
        }

        return (quoteProceeds, baseProceeds, profit);
    }

    function settleTrader(address account)
        external
        override
        onlyClearingHouse
        whenNotPaused
        returns (int256 fundingPayments)
    {
        LibPerpetual.TraderPosition storage trader = traderPosition[account];
        LibPerpetual.GlobalPosition storage global = globalPosition;

        _updateGlobalState();

        // apply funding rate on existing positionSize
        if (trader.positionSize != 0) {
            // settle trader funding rate
            fundingPayments = _getFundingPayments(
                trader.positionSize > 0,
                trader.cumFundingRate,
                global.cumFundingRate,
                trader.positionSize.abs()
            );
        }

        trader.cumFundingRate = global.cumFundingRate;

        return fundingPayments;
    }

    /* ******************************/
    /*     Liquidity provider flow  */
    /* ******************************/

    /// @notice Provide liquidity to the pool
    /// @param account Liquidity provider
    /// @param wadAmount Amount of vQuote provided. 18 decimals
    /// @param minLpAmount Minimum amount of Lp tokens minted. 18 decimals
    /// @return tradingFees Generated profit generated from trading fees
    function provideLiquidity(
        address account,
        uint256 wadAmount,
        uint256 minLpAmount
    ) external override whenNotPaused onlyClearingHouse returns (int256 tradingFees) {
        // reflect the added liquidity on the LP position
        LibPerpetual.LiquidityProviderPosition storage lp = lpPosition[account];
        LibPerpetual.GlobalPosition storage global = globalPosition;

        // update when has provided liquidity before
        if (lp.liquidityBalance != 0) {
            tradingFees = _settleLpTradingFees(lp, global).toInt256();

            // With previous liquidity providers, we must update the `totalBaseFeesGrowth` & `totalQuoteFeesGrowth` parameter
            // However, we do not account that for `older` liquidity we must still burn a larger share of the tokens
            // SOLUTION: Burn fees earned so far.
            (int256 baseFeesEarned, int256 quoteFeesEarned) = _getVirtualTokensEarnedAsCurveTradingFees(lp, global);
            lp.openNotional -= quoteFeesEarned;
            lp.positionSize -= baseFeesEarned;
        }

        uint256 basePrice;
        if (getTotalLiquidityProvided() == 0) {
            basePrice = marketPrice();
        } else {
            basePrice = market.balances(0).wadDiv(market.balances(1));
        }
        uint256 baseAmount = wadAmount.wadDiv(basePrice); // vQuote / vBase/vQuote  <=> 1 / 1.2 = 0.8

        // supply liquidity to curve pool
        vQuote.mint(wadAmount);
        vBase.mint(baseAmount);

        // Question: Should we compensate liquidity providers for the fee proportion in the pool (let them provider leveraged liquidity)
        // Answer: No, the relative difference of earlier and later liquidity providers do not matter. We only care for the pnL of them.
        uint256 liquidity = market.add_liquidity([wadAmount, baseAmount], minLpAmount); //  first token in curve pool is vQuote & second token is vBase

        // update state
        lp.openNotional -= wadAmount.toInt256();
        lp.positionSize -= baseAmount.toInt256();

        lp.totalTradingFeesGrowth = globalPosition.totalTradingFeesGrowth;
        lp.totalBaseFeesGrowth = globalPosition.totalBaseFeesGrowth;
        lp.totalQuoteFeesGrowth = globalPosition.totalQuoteFeesGrowth;

        lp.cumFundingRate = globalPosition.cumFundingRate;

        lp.liquidityBalance += liquidity;

        global.totalLiquidityProvided += wadAmount;
    }

    /// @notice Remove liquidity from the pool
    /// @param account Account of the LP to remove liquidity from
    /// @param liquidityAmountToRemove Amount of liquidity to be removed from the pool. 18 decimals
    /// @param minVTokenAmounts Minimum amount of virtual tokens [vQuote, vBase] withdrawn from the curve pool. 18 decimals
    /// @param proposedAmount Amount of tokens to be sold, in vBase if LONG, in vQuote if SHORT. 18 decimals
    /// @param minAmount Minimum amount that the user is willing to accept, in vQuote if LONG, in vBase if SHORT. 18 decimals
    /// @return profit Profit realized
    function removeLiquidity(
        address account,
        uint256 liquidityAmountToRemove,
        uint256[2] calldata minVTokenAmounts,
        uint256 proposedAmount,
        uint256 minAmount
    ) external override whenNotPaused onlyClearingHouse returns (int256 profit, uint256 reductionRatio) {
        LibPerpetual.LiquidityProviderPosition storage lp = lpPosition[account];
        LibPerpetual.GlobalPosition storage global = globalPosition;

        // slither-disable-next-line incorrect-equality
        if (liquidityAmountToRemove > lp.liquidityBalance) revert Perpetual_LPWithdrawExceedsBalance();

        profit += _settleLpTradingFees(lp, global).toInt256();
        // remove liquidity from curve pool
        (uint256 quoteAmount, uint256 baseAmount) = _removeLiquidity(
            lp,
            global,
            liquidityAmountToRemove,
            minVTokenAmounts
        );

        // settle previous active position
        reductionRatio = liquidityAmountToRemove.wadDiv(lp.liquidityBalance);

        (int256 pnl, int256 quoteProceeds) = _settleLpPosition(
            LibPerpetual.TraderPosition({
                openNotional: quoteAmount.toInt256() + lp.openNotional.wadMul(reductionRatio.toInt256()),
                positionSize: baseAmount.toInt256() + lp.positionSize.wadMul(reductionRatio.toInt256()),
                cumFundingRate: 0
            }),
            proposedAmount,
            minAmount
        );
        int256 quoteOnlyFees = _chargeQuoteFees(quoteProceeds);
        profit += pnl - quoteOnlyFees;

        // adjust balances to new position
        lp.openNotional += quoteAmount.toInt256();
        lp.positionSize += baseAmount.toInt256();
        lp.liquidityBalance -= liquidityAmountToRemove;

        lp.cumFundingRate = global.cumFundingRate;

        // if position has been closed entirely, delete it from the state
        // slither-disable-next-line incorrect-equality
        if (lp.liquidityBalance == 0) {
            delete lpPosition[account];
        }

        // Question: How should we think about this parameter?
        global.totalLiquidityProvided -= quoteAmount;
    }

    function settleLp(address account)
        external
        override
        whenNotPaused
        onlyClearingHouse
        returns (int256 fundingPayments)
    {
        LibPerpetual.LiquidityProviderPosition storage lp = lpPosition[account];
        LibPerpetual.GlobalPosition storage global = globalPosition;

        _updateGlobalState();

        if (lp.liquidityBalance == 0) {
            return 0;
        }

        // settle lp funding rate
        int256 virtualPositionSize = _getVBasePositionAfterVirtualWithdrawal(lp, global);

        fundingPayments = _getFundingPayments(
            virtualPositionSize > 0,
            lp.cumFundingRate,
            global.cumFundingRate,
            virtualPositionSize.abs()
        );

        lp.cumFundingRate = global.cumFundingRate;

        return fundingPayments;
    }

    ///// COMMON OPERATIONS \\\\\

    /// @notice Update Twap, Funding Rate and reset current block trade amount
    function _updateGlobalState() internal whenNotPaused {
        LibPerpetual.GlobalPosition storage global = globalPosition;
        uint256 currentTime = block.timestamp;
        uint256 timeOfLastTrade = uint256(global.timeOfLastTrade);

        // Don't update the state more than once per block
        // slither-disable-next-line timestamp
        if (currentTime > timeOfLastTrade) {
            _updateTwap();
            _updateFundingRate();
            _resetCurrentBlockTradeAmount();
        }
    }

    /* ****************** */
    /*     Governance     */
    /* ****************** */

    function setParameters(
        uint256 newTwapFrequency,
        int256 newSensitivity,
        int256 newMaxBlockTradeAmount,
        int256 newInsuranceFee,
        int256 newTradingFee
    ) public override onlyClearingHouseOwner {
        twapFrequency = newTwapFrequency;
        sensitivity = newSensitivity;
        maxBlockTradeAmount = newMaxBlockTradeAmount;

        if (newInsuranceFee < 1e15) revert Perpetual_InsuranceFeeInsufficient(newInsuranceFee);
        if (newInsuranceFee > 3e17) revert Perpetual_InsuranceFeeExcessive(newInsuranceFee);
        insuranceFee = newInsuranceFee;

        if (newTradingFee < 1e15) revert Perpetual_TradingFeeInsufficient(newTradingFee);
        if (newTradingFee > 3e17) revert Perpetual_TradingFeeExcessive(newTradingFee);
        tradingFee = newTradingFee;

        emit PerpetualParametersChanged(
            newTwapFrequency,
            newSensitivity,
            newMaxBlockTradeAmount,
            newTradingFee,
            newInsuranceFee
        );
    }

    /// @notice Pause the contract
    function pause() external override onlyClearingHouseOwner {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external override onlyClearingHouseOwner {
        _unpause();
    }

    /* ****************** */
    /*   Global getter    */
    /* ****************** */

    /// @notice Get global market position
    /// @return Global position
    function getGlobalPosition() external view override returns (LibPerpetual.GlobalPosition memory) {
        return globalPosition;
    }

    /// @notice Return the current off-chain exchange rate for vBase/vQuote
    /// @return Index price
    function indexPrice() public view override returns (int256) {
        return vBase.getIndexPrice();
    }

    /// @notice Return the last traded price (used for TWAP)
    /// @return lastPrice Last traded price
    function marketPrice() public view override returns (uint256) {
        return market.last_prices();
    }

    /// @notice Get the oracle Time-weighted-average-price
    /// @return oracle twap. 18 decimals
    function getOracleTwap() public view override returns (int256) {
        return oracleTwap;
    }

    /// @notice Get the market Time-weighted-average-price
    /// @return market twap. 18 decimals
    function getMarketTwap() public view override returns (int256) {
        return marketTwap;
    }

    /// @notice Get the market Total Liquidity provided to the Crypto Swap pool
    /// @return market twap. 18 decimals
    function getTotalLiquidityProvided() public view override returns (uint256) {
        return IERC20Metadata(market.token()).totalSupply();
    }

    /* ****************** */
    /*   User getter      */
    /* ****************** */

    // Trader

    /// @notice Get the approximate funding payments for a trader
    /// @param account Trader
    /// @return upcomingFundingPayment Funding payment. 18 decimals
    function getTraderFundingPayments(address account) external view override returns (int256 upcomingFundingPayment) {
        LibPerpetual.TraderPosition memory trader = traderPosition[account];
        LibPerpetual.GlobalPosition memory global = globalPosition;
        bool isLong = trader.positionSize > 0;

        return _getFundingPayments(isLong, trader.cumFundingRate, global.cumFundingRate, trader.positionSize.abs());
    }

    /// @notice Get the unrealized profit and Loss of a trader
    /// @param account Trader
    /// @return pnl Unrealized profit and loss. 18 decimals
    function getTraderUnrealizedPnL(address account) external view override returns (int256 pnl) {
        LibPerpetual.TraderPosition memory trader = traderPosition[account];
        return _getUnrealizedPnL(trader);
    }

    /// @notice Get the position of a trader
    /// @param account Address to get the trading position from
    /// @return Trader position
    function getTraderPosition(address account) external view override returns (LibPerpetual.TraderPosition memory) {
        return traderPosition[account];
    }

    function getTraderPositionHealth(address account) external view override returns (int256 pnL, int256 openNotional) {
        LibPerpetual.TraderPosition memory trader = traderPosition[account];

        openNotional = trader.openNotional;
        pnL = _getUnrealizedPnL(trader);

        return (pnL, openNotional);
    }

    // LP

    /// @notice Get the approximate funding payments for a Liquidity Provider
    /// @param account Liquidity Provider
    /// @return upcomingFundingPayment Funding payment. 18 decimals
    function getLpFundingPayments(address account) external view override returns (int256 upcomingFundingPayment) {
        LibPerpetual.LiquidityProviderPosition memory lp = lpPosition[account];
        LibPerpetual.GlobalPosition memory global = globalPosition;
        LibPerpetual.TraderPosition memory activeLpPosition = _getLpPositionAfterWithdrawal(lp, global);

        bool isLong = activeLpPosition.positionSize > 0;

        return
            _getFundingPayments(
                isLong,
                activeLpPosition.cumFundingRate,
                global.cumFundingRate,
                activeLpPosition.positionSize.abs()
            );
    }

    /// @notice Get the trading fees earned by a Liquidity Provider
    /// @param account Liquidity Provider
    /// @return tradingFeesEarned Trading fees earned by the Liquidity Provider. 18 decimals
    function getLpTradingFees(address account) external view override returns (uint256 tradingFeesEarned) {
        LibPerpetual.LiquidityProviderPosition memory lp = lpPosition[account];
        LibPerpetual.GlobalPosition memory global = globalPosition;

        return _getLpTradingFees(lp, global);
    }

    /// @notice Get the unrealized profit and Loss of a Liquidity Provider
    /// @param account Liquidity Provider
    /// @return pnl Unrealized profit and loss. 18 decimals
    function getLpUnrealizedPnL(address account) external view override returns (int256 pnl) {
        LibPerpetual.LiquidityProviderPosition memory lp = lpPosition[account];
        LibPerpetual.GlobalPosition memory global = globalPosition;

        LibPerpetual.TraderPosition memory activeLpPosition = _getLpPositionAfterWithdrawal(lp, global);
        int256 activePositionPnL = _getUnrealizedPnL(activeLpPosition);

        return activePositionPnL;
    }

    /// @notice Get the (active) position of a liquidity provider after withdrawing liquidity
    /// @param account Liquidity Provider
    /// @return (Active) Liquidity Provider position
    function getLpPositionAfterWithdrawal(address account)
        external
        view
        override
        returns (LibPerpetual.TraderPosition memory)
    {
        LibPerpetual.LiquidityProviderPosition memory lp = lpPosition[account];
        LibPerpetual.GlobalPosition memory global = globalPosition;
        return _getLpPositionAfterWithdrawal(lp, global);
    }

    /// @notice Get the position of a liquidity provider
    /// @param account Address to get the LP position from
    /// @return Liquidity Provider position
    function getLpPosition(address account)
        external
        view
        override
        returns (LibPerpetual.LiquidityProviderPosition memory)
    {
        return lpPosition[account];
    }

    /// @notice Get the approximate funding payments for a Liquidity Provider
    /// @param account Liquidity Provider
    function getLpPositionHealth(address account) external view override returns (int256 pnL, int256 openNotional) {
        LibPerpetual.LiquidityProviderPosition memory lp = lpPosition[account];
        LibPerpetual.GlobalPosition memory global = globalPosition;
        LibPerpetual.TraderPosition memory activeLpPosition = _getLpPositionAfterWithdrawal(lp, global);

        openNotional = activeLpPosition.openNotional;
        pnL = _getUnrealizedPnL(activeLpPosition) + _getLpTradingFees(lp, global).toInt256();

        return (pnL, openNotional);
    }

    /* ****************** */
    /*   Internal (Gov)   */
    /* ****************** */

    function _initGlobalState(int256 lastChainlinkPrice, int256 lastMarketPrice) internal {
        // initialize twap
        oracleTwap = lastChainlinkPrice;
        marketTwap = lastMarketPrice;

        // initialize funding
        globalPosition = LibPerpetual.GlobalPosition({
            timeOfLastTrade: uint128(block.timestamp),
            timeOfLastTwapUpdate: uint128(block.timestamp),
            cumFundingRate: 0,
            currentBlockTradeAmount: 0,
            totalTradingFeesGrowth: 0,
            totalLiquidityProvided: 0,
            totalBaseFeesGrowth: 0,
            totalQuoteFeesGrowth: 0
        });
    }

    /* ****************** */
    /*  Internal (Trading) */
    /* ****************** */

    function _extendPosition(
        uint256 amount,
        bool isLong,
        uint256 minAmount
    ) internal returns (int256 openNotional, int256 positionSize) {
        /*  if long:
                openNotional = vQuote traded   to market   (or "- vQuote")
                positionSize = vBase  received from market (or "+ vBase")
            if short:
                openNotional = vQuote received from market (or "+ vQuote")
                positionSize = vBase  traded   to market   (or "- vBase")
        */
        if (isLong) {
            openNotional = -amount.toInt256();
            positionSize = _quoteForBase(amount, minAmount).toInt256();
        } else {
            openNotional = _baseForQuote(amount, minAmount).toInt256();
            positionSize = -amount.toInt256();
        }

        return (openNotional, positionSize);
    }

    /// @dev Used both by traders closing their own positions and liquidators liquidating other people's positions
    /// @notice Profit is the sum of funding payments and the position PnL
    /// @param proposedAmount Amount of tokens to be sold, in vBase if LONG, in vQuote if SHORT. 18 decimals
    /// @param minAmount Minimum amount that the user is willing to accept, in vQuote if LONG, in vBase if SHORT. 18 decimals
    function _reducePosition(
        LibPerpetual.TraderPosition memory user,
        uint256 proposedAmount,
        uint256 minAmount
    )
        internal
        returns (
            int256 baseProceeds,
            int256 quoteProceeds,
            int256 openNotionalToReduce,
            int256 pnl
        )
    {
        bool isLong = user.positionSize > 0;

        _checkProposedAmount(isLong, user.positionSize, proposedAmount);

        // PnL of the position
        uint256 realizedReductionRatio;
        (baseProceeds, quoteProceeds, realizedReductionRatio) = _reducePositionOnMarket(
            isLong,
            user.positionSize,
            proposedAmount,
            minAmount
        );

        // take the realized reduction ratio when calculating the pnl
        openNotionalToReduce = user.openNotional.wadMul(realizedReductionRatio.toInt256());

        pnl = quoteProceeds + openNotionalToReduce;
    }

    /// @notice Returns baseProceeds and quoteProceeds to reflect how much the position has been reduced
    function _reducePositionOnMarket(
        bool isLong,
        int256 positionSize,
        uint256 proposedAmount,
        uint256 minAmount
    )
        internal
        returns (
            int256 baseProceeds,
            int256 quoteProceeds,
            uint256 realizedReductionRatio
        )
    {
        if (isLong) {
            uint256 amount = _baseForQuote(proposedAmount, minAmount);

            quoteProceeds = amount.toInt256();

            baseProceeds = -(proposedAmount.toInt256());

            realizedReductionRatio = proposedAmount.wadDiv(positionSize.abs().toUint256()); //  abs() in case of partial removing liquidity
        } else {
            uint256 positivePositionSize = (-positionSize).toUint256();
            uint256 vBaseProceeds = _quoteForBase(proposedAmount, minAmount);

            /*
            Question: Why do we make up to two swap when closing a short position?
            Answer: We have to calculate the amount of quoteTokens needed
                    to close the position off-chain. (No exact-output-swap function).
                    Results can deviate from the expected amount.

            Example:
                pay back 100 base debt (positionSize = -100)

            1) calculate how much quote you have to sell to pay back 100 base debt (positionSize = -100)
                i.e. proposedAmount ~ 100 * EUR_USD ~ 110


            2) Swap 'proposedAmount' for 'baseTokensReceived' base tokens

                Case I) baseTokensReceived > positionSize

                    swap (baseTokensReceived - positionSize) for quoteTokens

                        swap successful?

                            Case I) yes, continue

                            Case 2) no, donate (baseTokenReceived - positionSize)

                Case II) baseTokensReceived < positionSize

                    fail

            */
            uint256 additionalProceeds = 0;
            uint256 baseRemaining = 0;
            if (vBaseProceeds > positivePositionSize) {
                baseRemaining = vBaseProceeds - positivePositionSize;

                if (_canSellBase(baseRemaining)) {
                    // sell vBase tokens bought in excess
                    additionalProceeds = _baseForQuote(baseRemaining, 0);
                } else {
                    // dust vBase balance can not be sold
                    emit DustGenerated(baseRemaining);
                    _donate(baseRemaining);
                }
            }

            quoteProceeds = -proposedAmount.toInt256() + additionalProceeds.toInt256();

            // baseRemaining will be 0 if proposedAmount not more than what's needed to fully buy back short position
            baseProceeds = (vBaseProceeds - baseRemaining).toInt256();
            realizedReductionRatio = baseProceeds.toUint256().wadDiv(positivePositionSize);
        }

        return (baseProceeds, quoteProceeds, realizedReductionRatio);
    }

    function _quoteForBase(uint256 quoteAmount, uint256 minAmount) internal returns (uint256 vBaseAdjusted) {
        // perform swap

        // slither-disable-next-line unused-return
        vQuote.mint(quoteAmount);
        uint256 vBaseReceived = market.exchange(VQUOTE_INDEX, VBASE_INDEX, quoteAmount, minAmount);
        vBase.burn(vBaseReceived);

        // adjust for fees
        uint256 fees = market.mid_fee(); // can be changed by curve governance, so better to to get it every time
        vBaseAdjusted = _compensateForCurveTradingFees(vBaseReceived, fees);
        uint256 feesGrowth = ((vBaseAdjusted * fees) / CURVE_TRADING_FEE_PRECISION);
        globalPosition.totalBaseFeesGrowth += feesGrowth.wadDiv(vBase.totalSupply());
    }

    function _baseForQuote(uint256 baseAmount, uint256 minAmount) internal returns (uint256 vQuoteAdjusted) {
        // perform swap

        // slither-disable-next-line unused-return
        vBase.mint(baseAmount);
        uint256 vQuoteReceived = market.exchange(VBASE_INDEX, VQUOTE_INDEX, baseAmount, minAmount);
        vQuote.burn(vQuoteReceived);

        // adjust for fees
        uint256 fees = market.mid_fee(); // can be changed by curve governance, so better to to get it every time
        vQuoteAdjusted = _compensateForCurveTradingFees(vQuoteReceived, fees);

        uint256 feesGrowth = ((vQuoteAdjusted * fees) / CURVE_TRADING_FEE_PRECISION);
        globalPosition.totalQuoteFeesGrowth += feesGrowth.wadDiv(vQuote.totalSupply()); // TODO: use totalSupply() vs balanceOf(CurvePool)
    }

    /// @notice charge trading fee on notional amount
    function _chargeQuoteFees(int256 quoteProceeds) internal returns (int256) {
        int256 feesPayed = quoteProceeds.abs().wadMul(tradingFee);
        globalPosition.totalTradingFeesGrowth += feesPayed.toUint256().wadDiv(globalPosition.totalLiquidityProvided); // rate of return of this trade

        return feesPayed;
    }

    /* ****************** */
    /*  Internal (Liquidity) */
    /* ****************** */

    function _removeLiquidity(
        LibPerpetual.LiquidityProviderPosition memory lp,
        LibPerpetual.GlobalPosition memory global,
        uint256 liquidityAmountToRemove,
        uint256[2] memory minVTokenAmounts
    ) internal returns (uint256 quoteAmount, uint256 baseAmount) {
        // remove liquidity
        uint256 vQuoteBalanceBefore = vQuote.balanceOf(address(this));
        uint256 vBaseBalanceBefore = vBase.balanceOf(address(this));

        market.remove_liquidity(liquidityAmountToRemove, minVTokenAmounts);

        if (vQuote.balanceOf(address(market)) <= 0) revert Perpetual_MarketBalanceTooLow(VQUOTE_INDEX);
        if (vBase.balanceOf(address(market)) <= 0) revert Perpetual_MarketBalanceTooLow(VBASE_INDEX);

        uint256 vQuoteBalanceAfter = vQuote.balanceOf(address(this));
        uint256 vBaseBalanceAfter = vBase.balanceOf(address(this));

        uint256 quoteAmountInclFees = vQuoteBalanceAfter - vQuoteBalanceBefore;
        uint256 baseAmountInclFees = vBaseBalanceAfter - vBaseBalanceBefore;

        vQuote.burn(quoteAmountInclFees);
        vBase.burn(baseAmountInclFees);

        // remove fee component from quoteAmount
        quoteAmount = quoteAmountInclFees.wadDiv(1e18 + global.totalQuoteFeesGrowth - lp.totalQuoteFeesGrowth);
        baseAmount = baseAmountInclFees.wadDiv(1e18 + global.totalBaseFeesGrowth - lp.totalBaseFeesGrowth);
    }

    function _settleLpPosition(
        LibPerpetual.TraderPosition memory positionToClose,
        uint256 proposedAmount,
        uint256 minAmount
    ) internal returns (int256 pnl, int256 quoteProceeds) {
        int256 baseProceeds;

        (baseProceeds, quoteProceeds, , pnl) = _reducePosition(positionToClose, proposedAmount, minAmount);

        // check max deviation
        _updateCurrentBlockTradeAmount(quoteProceeds);
        if (!_checkBlockTradeAmount()) revert Perpetual_ExcessiveBlockTradeAmount();

        int256 diff = positionToClose.positionSize + baseProceeds;

        if (diff < 0) revert Perpetual_LPOpenPosition();

        // TODO: donate dust
    }

    function _settleLpTradingFees(
        LibPerpetual.LiquidityProviderPosition storage lp,
        LibPerpetual.GlobalPosition storage global
    ) internal returns (uint256 tradingFeesEarned) {
        // settle lp trading fees
        tradingFeesEarned = _getLpTradingFees(lp, global);

        lp.totalTradingFeesGrowth = global.totalTradingFeesGrowth;

        return tradingFeesEarned;
    }

    /* ************************ */
    /*  Internal (global state) */
    /* ************************ */
    function _updateFundingRate() internal {
        LibPerpetual.GlobalPosition storage global = globalPosition;
        uint256 currentTime = block.timestamp;

        int256 marketTWAP = getMarketTwap();
        int256 indexTWAP = getOracleTwap();

        int256 currentTraderPremium = (marketTWAP - indexTWAP).wadDiv(indexTWAP);
        int256 timePassedSinceLastTrade = (currentTime - global.timeOfLastTrade).toInt256();

        int256 fundingRate = (sensitivity.wadMul(currentTraderPremium) * timePassedSinceLastTrade) / 1 days;

        global.cumFundingRate += fundingRate;
        global.timeOfLastTrade = uint128(currentTime);

        emit FundingRateUpdated(global.cumFundingRate, fundingRate);
    }

    function _updateCurrentBlockTradeAmount(int256 vQuoteAmount) internal {
        globalPosition.currentBlockTradeAmount += vQuoteAmount.abs();
    }

    function _resetCurrentBlockTradeAmount() internal {
        globalPosition.currentBlockTradeAmount = 0;
    }

    function _updateTwap() internal {
        uint256 currentTime = block.timestamp;
        int256 timeElapsed = (currentTime - globalPosition.timeOfLastTrade).toInt256();

        /*
            priceCumulative1 = priceCumulative0 + price1 * timeElapsed
        */

        // will overflow in ~3000 years
        // update cumulative chainlink price feed
        int256 latestChainlinkPrice = indexPrice();
        oracleCumulativeAmount += latestChainlinkPrice * timeElapsed;

        // update cumulative market price feed
        int256 latestMarketPrice = marketPrice().toInt256();
        marketCumulativeAmount += latestMarketPrice * timeElapsed;

        uint256 timeElapsedSinceBeginningOfPeriod = block.timestamp - globalPosition.timeOfLastTwapUpdate;

        // slither-disable-next-line timestamp
        if (timeElapsedSinceBeginningOfPeriod >= twapFrequency) {
            /*
                TWAP = (priceCumulative1 - priceCumulative0) / timeElapsed
            */

            // calculate chainlink twap
            oracleTwap =
                (oracleCumulativeAmount - oracleCumulativeAmountAtBeginningOfPeriod) /
                timeElapsedSinceBeginningOfPeriod.toInt256();

            // calculate market twap
            marketTwap =
                (marketCumulativeAmount - marketCumulativeAmountAtBeginningOfPeriod) /
                timeElapsedSinceBeginningOfPeriod.toInt256();

            // reset cumulative amount and timestamp
            oracleCumulativeAmountAtBeginningOfPeriod = oracleCumulativeAmount;
            marketCumulativeAmountAtBeginningOfPeriod = marketCumulativeAmount;
            globalPosition.timeOfLastTwapUpdate = uint128(block.timestamp);

            emit TwapUpdated(oracleTwap, marketTwap);
        }
    }

    /************************** */
    /* Internal  (Misc)         */
    /************************** */

    // @notice Donate base tokens ("dust") to governance
    function _donate(uint256 baseAmount) internal {
        traderPosition[address(clearingHouse)].positionSize += baseAmount.toInt256();
    }

    /************************** */
    /* Internal Viewer (Trading) */
    /************************** */

    function _checkProposedAmount(
        bool isLong,
        int256 positionSize,
        uint256 proposedAmount
    ) internal view {
        /*
        Question: Why do we have to make use the proposedAmount parameters in our function?
        Answer: There is no equivalent to an swapForExact function in the CryptoSwap contract.
                https://docs.uniswap.org/protocol/guides/swaps/single-swaps#exact-output-swaps
                This means we in case of someone closing a short position (positionSize < 0)
                we can not calculate in our contract how many quoteTokens we have to swap with
                the curve Pool to pay pack the debt. Instead this is done outside of the contract.
                (see: TEST_get_exactOutputSwap() for an typescript implementation of a binary search
                to find the correct input amount).
                We only verify inside of the contract that our proposed amount is close enough
                to the initial estimate. All base tokens exceeding the positionSize are either swapped
                back for quoteTokens (dust is donated to the protocol)
                See: _reducePositionOnMarket for reference
        */

        if (isLong) {
            // proposedAmount is a vBase denominated amount
            // positionSize needs to be positive to allow LP positions looking like longs to be partially sold
            if (proposedAmount > positionSize.abs().toUint256()) revert Perpetual_ProposedAmountExceedsPositionSize();
        } else {
            // Check that `proposedAmount` isn't too far from the value in the market
            // to avoid creating large swings in the market (even though these swings would be cancelled out
            // by the fact that we sell any extra vBase bought)

            // USD_amount = EUR_USD * EUR_amount
            int256 positivePositionSize = -positionSize;
            int256 maxVQuoteAmount = (marketTwap + marketTwap / 2).wadMul(positivePositionSize); // 50% above the TWAP

            // Allow for a 50% deviation premium from the market vQuote TWAP price to close this position
            if (proposedAmount.toInt256() > maxVQuoteAmount) revert Perpetual_ProposedAmountExceedsMaxMarketPrice();
        }
    }

    function _canSellBase(uint256 sellAmount) internal returns (bool) {
        // slither-disable-next-line unused-return
        try market.get_dy(VBASE_INDEX, VQUOTE_INDEX, sellAmount) {
            return true;
        } catch {
            emit Log("Swap impossible");

            return false;
        }
    }

    /// @notice true if trade amount lower than max trade amount per block, false otherwise
    function _checkBlockTradeAmount() internal view returns (bool) {
        return globalPosition.currentBlockTradeAmount < maxBlockTradeAmount;
    }

    /// @notice Calculate missed funding payments
    // slither-disable-next-line timestamp
    function _getFundingPayments(
        bool isLong,
        int256 userCumFundingRate,
        int256 globalCumFundingRate,
        int256 vBaseAmountToSettle
    ) internal pure returns (int256 upcomingFundingPayment) {
        /* Funding rates (as defined in our protocol) are paid from longs to shorts

            case 1: user is long  => has missed making funding payments (positive or negative)
            case 2: user is short => has missed receiving funding payments (positive or negative)

            comment: Making an negative funding payment is equivalent to receiving a positive one.
        */
        if (userCumFundingRate != globalCumFundingRate) {
            int256 upcomingFundingRate = isLong
                ? userCumFundingRate - globalCumFundingRate
                : globalCumFundingRate - userCumFundingRate;

            // fundingPayments = fundingRate * vBaseAmountToSettle
            upcomingFundingPayment = upcomingFundingRate.wadMul(vBaseAmountToSettle);
        }
    }

    /// @notice Compensate traders by fees paid on cryptoswap pool

    function _compensateForCurveTradingFees(uint256 dyInclFees, uint256 curveTradingFee)
        internal
        pure
        returns (uint256 dyExclFees)
    {
        /*
            dy = dy ( 1 - fees )

            dyInclFees = dyExclFees * (CURVE_TRADING_FEE_PRECISION - fees) / CURVE_TRADING_FEE_PRECISION.

        <=> dyExclFees = dyInclFees * CURVE_TRADING_FEE_PRECISION / (CURVE_TRADING_FEE_PRECISION - curveTradingFee)

        */
        dyExclFees = (dyInclFees * CURVE_TRADING_FEE_PRECISION) / (CURVE_TRADING_FEE_PRECISION - curveTradingFee);
    }

    function _getUnrealizedPnL(LibPerpetual.TraderPosition memory trader) internal view returns (int256) {
        int256 oraclePrice = indexPrice();
        int256 vQuoteVirtualProceeds = trader.positionSize.wadMul(oraclePrice);
        int256 tradingFees = vQuoteVirtualProceeds.abs().wadMul(tradingFee);

        // in the case of a LONG, trader.openNotional is negative but vQuoteVirtualProceeds is positive
        // in the case of a SHORT, trader.openNotional is positive while vQuoteVirtualProceeds is negative
        return trader.openNotional + vQuoteVirtualProceeds - tradingFees;
    }

    /***************************** */
    /* Internal Viewer (Liquidity) */
    /***************************** */

    function _getVBasePositionAfterVirtualWithdrawal(
        LibPerpetual.LiquidityProviderPosition memory lp,
        LibPerpetual.GlobalPosition memory global
    ) internal view returns (int256 positionSizeAfterWithdrawal) {
        // LP position
        uint256 totalLiquidityProvided = getTotalLiquidityProvided();

        // adjust for trading fees earned
        (uint256 baseTokensExFees, ) = _getVirtualTokensWithdrawnFromCurvePool(
            totalLiquidityProvided,
            lp.liquidityBalance,
            market.balances(VBASE_INDEX),
            lp.totalBaseFeesGrowth,
            global.totalBaseFeesGrowth
        );
        positionSizeAfterWithdrawal = baseTokensExFees.toInt256() + lp.positionSize;
    }

    function _getVirtualTokensEarnedAsCurveTradingFees(
        LibPerpetual.LiquidityProviderPosition memory lp,
        LibPerpetual.GlobalPosition memory global
    ) internal view returns (int256 baseFeesEarned, int256 quoteFeesEarned) {
        // LP position
        uint256 totalLiquidityProvided = getTotalLiquidityProvided();

        (uint256 quoteTokensExFees, uint256 quoteTokensInclFees) = _getVirtualTokensWithdrawnFromCurvePool(
            totalLiquidityProvided,
            lp.liquidityBalance,
            market.balances(VQUOTE_INDEX),
            lp.totalQuoteFeesGrowth,
            global.totalQuoteFeesGrowth
        );
        quoteFeesEarned = (quoteTokensInclFees - quoteTokensExFees).toInt256();

        (uint256 baseTokensExFees, uint256 baseTokensInclFees) = _getVirtualTokensWithdrawnFromCurvePool(
            totalLiquidityProvided,
            lp.liquidityBalance,
            market.balances(VBASE_INDEX),
            lp.totalBaseFeesGrowth,
            global.totalBaseFeesGrowth
        );
        baseFeesEarned = (baseTokensInclFees - baseTokensExFees).toInt256();
    }

    function _getVirtualTokensWithdrawnFromCurvePool(
        uint256 totalLiquidityProvided,
        uint256 lpTokensLiquidityProvider,
        uint256 curvePoolBalance,
        uint256 userVirtualTokenGrowthRate,
        uint256 globalVirtualTokenTotalGrowth
    ) internal pure returns (uint256 tokensExFees, uint256 tokensInclFees) {
        tokensInclFees = (curvePoolBalance * lpTokensLiquidityProvider) / totalLiquidityProvided - 1;
        tokensExFees = tokensInclFees.wadDiv(1e18 + globalVirtualTokenTotalGrowth - userVirtualTokenGrowthRate);
    }

    /// @notice Get the trading fees earned by the liquidity provider
    function _getLpTradingFees(
        LibPerpetual.LiquidityProviderPosition memory lp,
        LibPerpetual.GlobalPosition memory global
    ) internal pure returns (uint256) {
        return lp.openNotional.abs().toUint256().wadMul(global.totalTradingFeesGrowth - lp.totalTradingFeesGrowth);
    }

    /// @notice Get the (active) position of a liquidity provider after withdrawing liquidity
    /// @return (Active) Liquidity Provider position
    function _getLpPositionAfterWithdrawal(
        LibPerpetual.LiquidityProviderPosition memory lp,
        LibPerpetual.GlobalPosition memory global
    ) internal view returns (LibPerpetual.TraderPosition memory) {
        // LP position
        uint256 totalLiquidityProvided = getTotalLiquidityProvided();

        (uint256 quoteTokensExFees, ) = _getVirtualTokensWithdrawnFromCurvePool(
            totalLiquidityProvided,
            lp.liquidityBalance,
            market.balances(VQUOTE_INDEX),
            lp.totalQuoteFeesGrowth,
            global.totalQuoteFeesGrowth
        );

        (uint256 baseTokensExFees, ) = _getVirtualTokensWithdrawnFromCurvePool(
            totalLiquidityProvided,
            lp.liquidityBalance,
            market.balances(VBASE_INDEX),
            lp.totalBaseFeesGrowth,
            global.totalBaseFeesGrowth
        );

        return
            LibPerpetual.TraderPosition({
                openNotional: lp.openNotional + quoteTokensExFees.toInt256(),
                positionSize: lp.positionSize + baseTokensExFees.toInt256(),
                cumFundingRate: lp.cumFundingRate
            });
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IClearingHouse} from "./IClearingHouse.sol";
import {IPerpetual} from "./IPerpetual.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IVault} from "./IVault.sol";
import {IInsurance} from "./IInsurance.sol";
import {ICryptoSwap} from "./ICryptoSwap.sol";

// libraries
import {LibPerpetual} from "../lib/LibPerpetual.sol";

interface IClearingHouse {
    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the zero address is provided as a parameter in the constructor
    error ClearingHouse_ZeroAddressConstructor(uint8 paramIndex);

    /// @notice Emitted when there is not enough margin to withdraw the requested amount
    error ClearingHouse_WithdrawInsufficientMargin();

    /// @notice Emitted when the position is not reduced entirely using closePositionWithdrawCollateral
    error ClearingHouse_ClosePositionStillOpen();

    /// @notice Emitted when the liquidatee does not have an open position
    error ClearingHouse_LiquidateInvalidPosition();

    /// @notice Emitted when the margin of the liquidatee's position is still valid
    error ClearingHouse_LiquidateValidMargin();

    /// @notice Emitted when the attempted liquidation does not close the full position
    error ClearingHouse_LiquidateInsufficientProposedAmount();

    /// @notice Emitted when attempting to seize collateral of a user with an open position
    error ClearingHouse_seizeCollateralStillOpen();

    /// @notice Emitted when a user attempts to provide liquidity with amount equal to 0
    error ClearingHouse_ProvideLiquidityZeroAmount();

    /// @notice Emitted when a user attempts to withdraw more liquidity than they have
    error ClearingHouse_RemoveLiquidityInsufficientFunds();

    /// @notice Emitted when vault withdrawal is unsuccessful
    error ClearingHouse_VaultWithdrawUnsuccessful();

    /// @notice Emitted when the proposed minMargin is too low
    error ClearingHouse_InsufficientMinMargin();

    /// @notice Emitted when the proposed minMargin is too high
    error ClearingHouse_ExcessiveMinMargin();

    /// @notice Emitted when the proposed minMarginAtCreation is too low
    error ClearingHouse_InsufficientMinMarginAtCreation();

    /// @notice Emitted when the proposed minMarginAtCreation is too low
    error ClearingHouse_ExcessiveMinMarginAtCreation();

    /// @notice Emitted when the proposed liquidation reward is too low
    error ClearingHouse_InsufficientLiquidationReward();

    /// @notice Emitted when the proposed liquidation reward is too high
    error ClearingHouse_ExcessiveLiquidationReward();

    /// @notice Emitted when the proposed insurance ratio is too low
    error ClearingHouse_InsufficientInsuranceRatio();

    /// @notice Emitted when the proposed insurance ratio is too high
    error ClearingHouse_ExcessiveInsuranceRatio();

    /// @notice Emitted when a user attempts to extend their position with amount equal to 0
    error ClearingHouse_ExtendPositionZeroAmount();

    /// @notice Emitted when there is not enough margin to extend to the proposed position amount
    error ClearingHouse_ExtendPositionInsufficientMargin();

    /// @notice Emitted when a user attempts to reduce their position with amount equal to 0
    error ClearingHouse_ReducePositionZeroAmount();

    error ClearingHouse_ChangePositionZeroAmount();

    /// @notice Emitted when a user tries to open a position with an incorrect open notional amount
    error ClearingHouse_UnderOpenNotionalAmountRequired();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function vault() external view returns (IVault);

    function insurance() external view returns (IInsurance);

    function perpetuals(uint256 idx) external view returns (IPerpetual);

    function getNumMarkets() external view returns (uint256);

    function getOwner() external view returns (address);

    function minMargin() external view returns (int256);

    function minMarginAtCreation() external view returns (int256);

    function minPositiveOpenNotional() external view returns (uint256);

    function liquidationReward() external view returns (uint256);

    function insuranceRatio() external view returns (uint256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function allowListPerpetual(IPerpetual perp) external;

    function pause() external;

    function unpause() external;

    function sellDust(
        uint256 idx,
        uint256 proposedAmount,
        uint256 minAmount,
        IERC20Metadata token
    ) external;

    function setParameters(
        int256 newMinMargin,
        int256 newMinMarginAtCreation,
        uint256 newMinPositiveOpenNotional,
        uint256 newLiquidationReward,
        uint256 newInsuranceRatio
    ) external;

    function deposit(
        uint256 idx,
        uint256 amount,
        IERC20Metadata token
    ) external;

    function withdraw(
        uint256 idx,
        uint256 amount,
        IERC20Metadata token
    ) external;

    function changePosition(
        uint256 idx,
        uint256 amount,
        LibPerpetual.Side direction,
        uint256 minAmount
    ) external;

    function extendPositionWithCollateral(
        uint256 idx,
        uint256 collateralAmount,
        IERC20Metadata token,
        uint256 positionAmount,
        LibPerpetual.Side direction,
        uint256 minAmount
    ) external;

    function closePositionWithdrawCollateral(
        uint256 idx,
        uint256 proposedAmount,
        uint256 minAmount,
        IERC20Metadata token
    ) external;

    function liquidate(
        uint256 idx,
        address liquidatee,
        uint256 proposedAmount,
        bool isTrader
    ) external;

    function seizeCollateral(
        uint256 idx,
        address liquidatee,
        bool isTrader
    ) external;

    function provideLiquidity(
        uint256 idx,
        uint256 amount,
        uint256 minLpAmount,
        IERC20Metadata token
    ) external;

    function removeLiquidity(
        uint256 idx,
        uint256 liquidityAmountToRemove,
        uint256[2] calldata minVTokenAmounts,
        uint256 proposedAmount,
        uint256 minAmount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

/// @dev Contract https://github.com/curvefi/curve-crypto-contract/blob/master/deployment-logs/2021-11-01.%20EURS%20on%20mainnet/CryptoSwap.vy
interface ICryptoSwap {
    function get_virtual_price() external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function mid_fee() external view returns (uint256);

    function out_fee() external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    // Swap token i to j with amount dx and min amount min_dy
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256); // WARNING: Has to be memory to be called within the perpetual contract, but you should use calldata

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external; // WARNING: Has to be memory to be called within the perpetual contract, but you should use calldata

    function last_prices() external view returns (uint256);

    function token() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

import {IClearingHouse} from "./IClearingHouse.sol";

interface IInsurance {
    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the zero address is provided as a parameter in the constructor
    error Insurance_ZeroAddressConstructor(uint8 paramIndex);

    /// @notice Emitted when the sender is not the vault address
    error Insurance_SenderNotVault();

    /// @notice Emitted when the sender is not the clearingHouse address
    error Insurance_SenderNotClearingHouse();

    /// @notice Emitted when the balance of the vault is less than the amount to be settled
    error Insurance_InsufficientBalance();

    /// @notice Emitted when locked insurance falls below insurance ratio
    error Insurance_InsufficientInsurance();

    /// @notice Emitted when the proposed clearingHouse address is equal to the zero address
    error Insurance_ClearingHouseZeroAddress();

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when a new ClearingHouse is connected to the issuer
    /// @param newClearingHouse New ClearingHouse contract address
    event ClearingHouseChanged(IClearingHouse newClearingHouse);

    /// @notice Emitted when (exceeding) insurance reserves are withdrawn by governance
    /// @param amount Amount of insurance reserves withdrawn. 18 decimals
    event InsuranceRemoved(uint256 amount);

    /// @notice Emitted when a bail out is asked for by the Vault
    /// @param amount Amount of insurance reserves withdrawn. 18 decimals
    event SettleDebt(uint256 amount);

    /// @notice Emitted when a bail out cant be fully served
    /// @param amount Amount of bad debt remaining. 18 decimals
    event SystemDebtGenerated(uint256 amount);

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function settleDebt(uint256 amount) external;

    function removeInsurance(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @notice Oracle interface created to ease oracle contract switch
interface IOracle {
    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the latest round is incomplete
    error Oracle_IncompleteRound();

    /// @notice Emitted when the latest round's price is invalid
    error Oracle_InvalidPrice();

    /// @notice Emitted when the proposed asset address is equal to the zero address
    error Oracle_AssetZeroAddress();

    /// @notice Emitted when the proposed aggregator address is equal to the zero address
    error Oracle_AggregatorZeroAddress();

    /// @notice Emitted when owner tries to set fixed price to an unsupported asset
    error Oracle_UnsupportedAsset();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function getPrice(address asset) external view returns (int256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function setOracle(address asset, AggregatorV3Interface aggregator) external;

    function setFixedPrice(address asset, int256 fixedPrice) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {ICryptoSwap} from "./ICryptoSwap.sol";
import {IVault} from "./IVault.sol";
import {ICryptoSwap} from "./ICryptoSwap.sol";
import {IVBase} from "./IVBase.sol";
import {IVQuote} from "./IVQuote.sol";
import {IInsurance} from "./IInsurance.sol";
import {IClearingHouse} from "./IClearingHouse.sol";

// libraries
import {LibPerpetual} from "../lib/LibPerpetual.sol";

interface IPerpetual {
    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the zero address is provided as a parameter in the constructor
    error Perpetual_ZeroAddressConstructor(uint256 paramIndex);

    /// @notice Emitted when the constructor fails to give approval of a virtual token to the market
    error Perpetual_VirtualTokenApprovalConstructor(uint256 tokenIndex);

    /// @notice Emitted when market mid fee does not equal out fee
    error Perpetual_MarketEqualFees();

    /// @notice Emitted when the sender is not the clearing house
    error Perpetual_SenderNotClearingHouse();

    /// @notice Emitted when the sender is not the clearing house owner
    error Perpetual_SenderNotClearingHouseOwner();

    /// @notice Emitted when the user attempts to reduce their position using extendPosition
    error Perpetual_AttemptReducePosition();

    /// @notice Emitted when the price impact of a position is too high
    error Perpetual_ExcessiveBlockTradeAmount();

    /// @notice Emitted when the user does not have an open position
    error Perpetual_NoOpenPosition();

    /// @notice Emitted when the user attempts to withdraw more liquidity than they have deposited
    error Perpetual_LPWithdrawExceedsBalance();

    /// @notice Emitted when the proposed insurance fee is insufficient
    error Perpetual_InsuranceFeeInsufficient(int256 fee);

    /// @notice Emitted when the proposed insurance fee is excessive
    error Perpetual_InsuranceFeeExcessive(int256 fee);

    /// @notice Emitted when the proposed trading fee is insufficient
    error Perpetual_TradingFeeInsufficient(int256 fee);

    /// @notice Emitted when the proposed trading fee is excessive
    error Perpetual_TradingFeeExcessive(int256 fee);

    /// @notice Emitted when a token balance of the market is lte 0
    error Perpetual_MarketBalanceTooLow(uint256 tokenIndex);

    /// @notice Emitted when the liquidity provider has an open position
    error Perpetual_LPOpenPosition();

    /// @notice Emitted when proposed amount is greater than position size
    error Perpetual_ProposedAmountExceedsPositionSize();

    /// @notice Emitted when proposed amount is greater than maxVQuoteAmount
    error Perpetual_ProposedAmountExceedsMaxMarketPrice();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function market() external view returns (ICryptoSwap);

    function vBase() external view returns (IVBase);

    function vQuote() external view returns (IVQuote);

    function clearingHouse() external view returns (IClearingHouse);

    function twapFrequency() external view returns (uint256);

    function sensitivity() external view returns (int256);

    function maxBlockTradeAmount() external view returns (int256);

    function tradingFee() external view returns (int256);

    function insuranceFee() external view returns (int256);

    function getTraderPosition(address account) external view returns (LibPerpetual.TraderPosition memory);

    function getLpPositionAfterWithdrawal(address account) external view returns (LibPerpetual.TraderPosition memory);

    function getLpPosition(address account) external view returns (LibPerpetual.LiquidityProviderPosition memory);

    function getGlobalPosition() external view returns (LibPerpetual.GlobalPosition memory);

    function getTraderUnrealizedPnL(address account) external view returns (int256);

    function getTraderFundingPayments(address account) external view returns (int256);

    function getLpUnrealizedPnL(address account) external view returns (int256);

    function getLpFundingPayments(address account) external view returns (int256);

    function getLpTradingFees(address account) external view returns (uint256);

    function marketPrice() external view returns (uint256);

    function indexPrice() external view returns (int256);

    function getTotalLiquidityProvided() external view returns (uint256);

    function getOracleTwap() external view returns (int256);

    function getMarketTwap() external view returns (int256);

    function getTraderPositionHealth(address account) external view returns (int256 pnL, int256 openNotional);

    function getLpPositionHealth(address account) external view returns (int256 pnL, int256 openNotional);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function changePosition(
        address account,
        uint256 amount,
        LibPerpetual.Side direction,
        uint256 minAmount
    )
        external
        returns (
            int256 openNotional,
            int256 positionSize,
            int256 profit,
            bool isPositionIncreased
        );

    function liquidatePosition(
        address account,
        uint256 amount,
        uint256 minAmount
    )
        external
        returns (
            int256 openNotional,
            int256 positionSize,
            int256 profit
        );

    function settleTrader(address account) external returns (int256 fundingPayments);

    function provideLiquidity(
        address account,
        uint256 wadAmount,
        uint256 minLpAmount
    ) external returns (int256 tradingFees);

    function removeLiquidity(
        address account,
        uint256 liquidityAmountToRemove,
        uint256[2] calldata minVTokenAmounts,
        uint256 proposedAmount,
        uint256 minAmount
    ) external returns (int256 profit, uint256 reductionRatio);

    function settleLp(address account) external returns (int256 fundingPayments);

    function pause() external;

    function unpause() external;

    function setParameters(
        uint256 newTwapFrequency,
        int256 newSensitivity,
        int256 newMaxBlockTradeAmount,
        int256 newInsuranceFee,
        int256 newTradingFee
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IVirtualToken} from "../interfaces/IVirtualToken.sol";

interface IVBase is IVirtualToken {
    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the proposed aggregators decimals are less than PRECISION
    error VBase_InsufficientPrecision();

    /// @notice Emitted when the latest round is incomplete
    error VBase_IncompleteRound();

    /// @notice Emitted when the latest round's price is invalid
    error VBase_InvalidPrice();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function getIndexPrice() external view returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IVirtualToken} from "../interfaces/IVirtualToken.sol";

interface IVQuote is IVirtualToken {}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IInsurance} from "./IInsurance.sol";
import {IOracle} from "./IOracle.sol";
import {IClearingHouse} from "./IClearingHouse.sol";

// @dev: deposit uint and withdraw int
// @author: The interface used in other contracts
interface IVault {
    struct Collateral {
        IERC20Metadata asset;
        uint256 weight;
        uint8 decimals;
        uint256 currentAmount;
        uint256 maxAmount;
    }

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the zero address is provided as a parameter in the constructor
    error Vault_ZeroAddressConstructor(uint8 paramIndex);

    /// @notice Emitted when user tries to withdraw collateral while having a UA debt
    error Vault_UADebt();

    /// @notice Emitted when the sender is not the clearing house
    error Vault_SenderNotClearingHouse();

    /// @notice Emitted when a user attempts to use a token which is not whitelisted as collateral
    error Vault_UnsupportedCollateral();

    /// @notice Emitted when owner tries to whitelist a collateral already whitelisted
    error Vault_CollateralAlreadyWhiteListed();

    /// @notice Emitted when a user attempts to withdraw with a reduction ratio above 1e18
    error Vault_WithdrawReductionRatioTooHigh();

    /// @notice Emitted when a user attempts to withdraw more than their balance
    error Vault_WithdrawExcessiveAmount();

    /// @notice Emitted when a collateral liquidation for a trader with no debt is tried
    error Vault_LiquidationDebtSizeZero();

    /// @notice Emitted when the proposed clearingHouse address is equal to the zero address
    error Vault_ClearingHouseZeroAddress();

    /// @notice Emitted when the proposed insurance address is equal to the zero address
    error Vault_InsuranceZeroAddress();

    /// @notice Emitted when the proposed oracle address is equal to the zero address
    error Vault_OracleZeroAddress();

    /// @notice Emitted when the proposed collateral weight is under the limit
    error Vault_InsufficientCollateralWeight();

    /// @notice Emitted when the proposed collateral weight is above the limit
    error Vault_ExcessiveCollateralWeight();

    /// @notice Emitted when a user attempts to withdraw more collateral than available in vault
    error Vault_InsufficientBalance();

    /// @notice Emitted when a user attempts to withdraw more collateral than available in vault
    error Vault_MaxCollateralAmountExceeded();

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when collateral is deposited into the vault
    /// @param idx Index of the perpetual market
    /// @param user User who deposited collateral
    /// @param asset Token to be used for the collateral
    /// @param amount Amount to be used as collateral. Might not be 18 decimals
    event Deposit(uint256 indexed idx, address indexed user, address indexed asset, uint256 amount);

    /// @notice Emitted when collateral is withdrawn from the vault
    /// @param idx Index of the perpetual market
    /// @param user User who deposited collateral
    /// @param asset Token to be used for the collateral
    /// @param amount Amount to be used as collateral. Might not be 18 decimals
    event Withdraw(uint256 indexed idx, address indexed user, address indexed asset, uint256 amount);

    /// @notice Emitted when bad debt is settled for by the insurance reserve
    /// @param idx Index of the perpetual market
    /// @param beneficiary Beneficiary of the insurance payment
    /// @param amount Amount of bad insurance requested
    event TraderBadDebtGenerated(uint256 idx, address beneficiary, uint256 amount);

    /// @notice Emitted when a new ClearingHouse is connected to the vault
    /// @param newClearingHouse New ClearingHouse contract address
    event ClearingHouseChanged(IClearingHouse newClearingHouse);

    /// @notice Emitted when a new Insurance is connected to the vault
    /// @param newInsurance New Insurance contract address
    event InsuranceChanged(IInsurance newInsurance);

    /// @notice Emitted when a new Oracle is connected to the vault
    /// @param newOracle New Oracle contract address
    event OracleChanged(IOracle newOracle);

    /// @notice Emitted when a new Oracle is connected to the vault
    /// @param asset Asset added as collateral
    /// @param weight Volatility measure of the asset
    /// @param maxAmount weight for the collateral
    event CollateralAdded(IERC20Metadata asset, uint256 weight, uint256 maxAmount);

    /// @notice Emitted when a collateral weight changed
    /// @param asset Asset targeted by the change
    /// @param newWeight New volatility measure for the collateral
    event CollateralWeightChanged(IERC20Metadata asset, uint256 newWeight);

    /// @notice Emitted when a collateral max amount changed
    /// @param asset Asset targeted by the change
    /// @param newMaxAmount New weight for the collateral
    event CollateralMaxAmountChanged(IERC20Metadata asset, uint256 newMaxAmount);

    /* ****************** */
    /*     Viewer         */
    /* ****************** */
    function insurance() external view returns (IInsurance);

    function oracle() external view returns (IOracle);

    function clearingHouse() external view returns (IClearingHouse);

    function getTotalValueLocked() external view returns (int256);

    function getBadDebt() external view returns (uint256);

    function getWhiteListedCollaterals() external view returns (Collateral[] memory);

    function getTraderReserveValue(uint256 marketIdx, address trader) external view returns (int256);

    function getLpReserveValue(uint256 marketIdx, address lp) external view returns (int256);

    function getLpBalance(
        address user,
        uint256 marketIdx,
        uint256 tokenIdx
    ) external view returns (int256);

    function getTraderBalance(
        address user,
        uint256 marketIdx,
        uint256 tokenIdx
    ) external view returns (int256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function deposit(
        uint256 idx,
        address user,
        uint256 amount,
        IERC20Metadata token,
        bool isTrader
    ) external returns (int256);

    function settlePnL(
        uint256 marketIdx,
        address user,
        int256 amount,
        bool isTrader
    ) external;

    function withdraw(
        uint256 idx,
        address user,
        uint256 amount,
        IERC20Metadata token,
        bool isTrader
    ) external;

    function withdrawPartial(
        uint256 idx,
        address user,
        uint256 reductionRatio,
        bool isTrader
    ) external;

    function withdrawAll(
        uint256 idx,
        address user,
        IERC20Metadata withdrawToken,
        bool isTrader
    ) external;

    function settleLiquidationOnCollaterals(
        address liquidator,
        address liquidatee,
        uint256 marketIdx,
        bool isTrader
    ) external;

    function transferUa(address user, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVirtualToken is IERC20Metadata {
    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function mint(uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// libraries
import {PRBMathUD60x18} from "prb-math/contracts/PRBMathUD60x18.sol";
import {PRBMathSD59x18} from "prb-math/contracts/PRBMathSD59x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * To be used if `b` decimals make `b` larger than what it would be otherwise.
 * Especially useful for fixed point numbers, i.e. a way to represent decimal
 * values without using decimals. E.g. 25e2 with 3 decimals represents 2.5%
 *
 * In our case, we get exchange rates with a 18 decimal precision
 * (Solidity doesn't support decimal values natively).
 * So if we have a EUR positions and want to get the equivalent USD amount
 * we have to do: EUR_position * EUR_USD / 1e18 else the value would be way too high.
 * To move from USD to EUR: (USD_position * 1e18) / EUR_USD else the value would
 * be way too low.
 *
 * In essence,
 * wadMul: a.mul(b).div(WAY)
 * wadDiv: a.mul(WAY).div(b)
 * where `WAY` represents the number of decimals
 */
library LibMath {
    // safe casting
    function toInt256(uint256 x) internal pure returns (int256) {
        return SafeCast.toInt256(x);
    }

    function toUint256(int256 x) internal pure returns (uint256) {
        return SafeCast.toUint256(x);
    }

    // absolute value
    function abs(int256 x) internal pure returns (int256) {
        return PRBMathSD59x18.abs(x);
    }

    // int256: wad division / multiplication
    function wadDiv(int256 x, int256 y) internal pure returns (int256) {
        return PRBMathSD59x18.div(x, y);
    }

    function wadMul(int256 x, int256 y) internal pure returns (int256) {
        return PRBMathSD59x18.mul(x, y);
    }

    // uint256: wad division / multiplication
    function wadMul(uint256 x, uint256 y) internal pure returns (uint256) {
        return PRBMathUD60x18.mul(x, y);
    }

    function wadDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return PRBMathUD60x18.div(x, y);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// libraries
import {LibMath} from "./LibMath.sol";

library LibPerpetual {
    using LibMath for int256;
    using LibMath for uint256;

    enum Side {
        // long position
        Long,
        // short position
        Short
    }

    struct LiquidityProviderPosition {
        // quote assets or liabilities
        int256 openNotional;
        // base assets or liabilities
        int256 positionSize;
        // user cumulative funding rate (updated when open/close position)
        int256 cumFundingRate;
        // lp token owned (is zero for traders)
        uint256 liquidityBalance;
        /* fees state */

        // total percentage return of liquidity providers index
        uint256 totalTradingFeesGrowth;
        // total base fees paid in cryptoswap pool
        uint256 totalBaseFeesGrowth;
        // total quote fees paid in cryptoswap pool
        uint256 totalQuoteFeesGrowth;
    }

    struct TraderPosition {
        // quote assets or liabilities
        int256 openNotional;
        // base assets or liabilities
        int256 positionSize;
        // user cumulative funding rate (updated when open/close position)
        int256 cumFundingRate;
    }

    struct GlobalPosition {
        /* twap state */

        // timestamp of last trade
        uint128 timeOfLastTrade;
        // timestamp of last TWAP update
        uint128 timeOfLastTwapUpdate;
        // global cumulative funding rate (updated every trade)
        int256 cumFundingRate;
        // current trade amount in the block
        int256 currentBlockTradeAmount;
        /* fees state */

        // total percentage return of liquidity providers index
        uint256 totalTradingFeesGrowth;
        // total liquidity provided (in vQuote)
        uint256 totalLiquidityProvided;
        // total base fees paid in cryptoswap pool
        uint256 totalBaseFeesGrowth;
        // total quote fees paid in cryptoswap pool
        uint256 totalQuoteFeesGrowth;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}