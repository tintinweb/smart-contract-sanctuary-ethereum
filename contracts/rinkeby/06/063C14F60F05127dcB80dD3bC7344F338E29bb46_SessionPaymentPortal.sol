// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FP_DECIMALS = 18;
/// @dev The number `1` in the standard fixed point math scaling. Most of the
/// differences between fixed point math and regular math is multiplying or
/// dividing by `ONE` after the appropriate scaling has been applied.
uint256 constant FP_ONE = 10**FP_DECIMALS;

/// @title FixedPointMath
/// @notice Sometimes we want to do math with decimal values but all we have
/// are integers, typically uint256 integers. Floats are very complex so we
/// don't attempt to simulate them. Instead we provide a standard definition of
/// "one" as 10 ** 18 and scale everything up/down to this as fixed point math.
/// Overflows are errors as per Solidity.
library FixedPointMath {
    /// Scale a fixed point decimal of some scale factor to match `DECIMALS`.
    /// @param a_ Some fixed point decimal value.
    /// @param aDecimals_ The number of fixed decimals of `a_`.
    /// @return `a_` scaled to match `DECIMALS`.
    function scale18(uint256 a_, uint256 aDecimals_)
        internal
        pure
        returns (uint256)
    {
        if (FP_DECIMALS == aDecimals_) {
            return a_;
        } else if (FP_DECIMALS > aDecimals_) {
            return a_ * 10**(FP_DECIMALS - aDecimals_);
        } else {
            return a_ / 10**(aDecimals_ - FP_DECIMALS);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` to some other scale.
    /// @param a_ A `DECIMALS` fixed point decimals.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @return `a_` rescaled from `DECIMALS` to `targetDecimals_`.
    function scaleN(uint256 a_, uint256 targetDecimals_)
        internal
        pure
        returns (uint256)
    {
        if (targetDecimals_ == FP_DECIMALS) {
            return a_;
        } else if (FP_DECIMALS > targetDecimals_) {
            return a_ / 10**(FP_DECIMALS - targetDecimals_);
        } else {
            return a_ * 10**(targetDecimals_ - FP_DECIMALS);
        }
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// The caller MUST ensure the end result matches `DECIMALS` if other
    /// functions in this library are to work correctly.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(uint256 a_, int8 scaleBy_)
        internal
        pure
        returns (uint256)
    {
        if (scaleBy_ == 0) {
            return a_;
        } else if (scaleBy_ > 0) {
            return a_ * 10**uint8(scaleBy_);
        } else {
            return a_ / 10**(~uint8(scaleBy_) + 1);
        }
    }

    /// Fixed point multiplication in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` multiplied by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointMul(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        return (a_ * b_) / FP_ONE;
    }

    /// Fixed point division in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` divided by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointDiv(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        return (a_ * FP_ONE) / b_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@beehiveinnovation/rain-protocol/contracts/math/FixedPointMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev USDT token contract is already deployed and can never change its
/// decimals value.
uint256 constant USDT_DECIMALS = 6;

/// @dev 0.3% as FixedPointMath.DECIMALS. If the Uniswap fee ever changes this
/// constant should be moved to an immutable value.
/// Compile time constant equivalent to `FixedPointMath.scale18(997, 3)`.
uint256 constant UNISWAP_FEE = 997 * 10**(FP_DECIMALS - 3);

/// @title ALBTOracle
/// @notice Chainlink AggregatorV3Interface defines a robust interface into
/// oracle prices that is simultaneously under and overpowered for our needs.
/// All we need is a single 18 fixed point decimal price value representing the
/// conversion of USDT to ALBT for some USDT amount. We do NOT need the round
/// data returned by Chainlink but we do need the decimals reported by the feed
/// to be scaled correctly for standard fixed point math. We also want all our
/// prices to be handled as `uint256` values, not as Chainlink `int256` prices.
contract ALBTOracle {
    using SafeCast for int256;
    using FixedPointMath for uint256;

    /// @dev Chainlink price feed aggregator.
    AggregatorV3Interface private immutable priceFeed;

    /// @param priceFeed_ Address of the Chainlink price feed.
    constructor(address priceFeed_) {
        require(
            priceFeed_ != address(0),
            "ALBTOracle: Price feed address cannot be 0"
        );
        priceFeed = AggregatorV3Interface(priceFeed_);
    }

    /// Calculate the amount of ALBT you will get for an amount of USDT, using
    /// the chainlink price feed.
    /// @param usdtAmount_ USDT amount to calculate ALBT equivalent amount_ of.
    /// USDT amount input is in `USDT_DECIMALS` and ALBT output is standard 18
    /// decimal fixed point ERC20 amount.
    function calculateUSDTtoALBT(uint256 usdtAmount_)
        internal
        view
        returns (uint256)
    {
        (, int256 price_, , , ) = priceFeed.latestRoundData();
        return
            usdtAmount_
                .scale18(USDT_DECIMALS)
                .fixedPointMul(UNISWAP_FEE)
                .fixedPointDiv(
                    price_.toUint256().scale18(priceFeed.decimals())
                );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@beehiveinnovation/rain-protocol/contracts/math/FixedPointMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Defines a single share of some payment.
/// Not useful individually but a Share[] can define a list of split payments.
/// The total of all shares in a Share[] must add to `FP_ONE`.
/// @param recipient of this share.
/// @param fractional share for this recipient as an 18 fixed point decimal.
struct Share {
    address recipient;
    uint256 share;
}

/// @title SplitPayment
/// @notice Implements a "push" model of payment across "arbitrary" shares of
/// recipients. "Arbitrary" is in quotes because gas ensures we won't achieve
/// particularly long lists of shares in practise, and statistically the risk
/// of a payment rollback increases as the recipients list becomes longer.
/// For short lists over trusted tokens and recipients this can be a useful
/// construct to easily push out payments inline with other operations.
library SplitPayment {
    using SafeERC20 for IERC20;
    using FixedPointMath for uint256;

    /// Enforces that the passed shares meet standard integrity requirements.
    /// It is best to do these once upon construction/initialization and then
    /// never again. E.g. try to avoid running the integrity checks alonside
    /// every `splitTransfer` call unless the shares really might change every
    /// transfer.
    /// @param shares_ An array of shares to ensure overall integrity of.
    function enforceSharesIntegrity(Share[] memory shares_) internal pure {
        require(shares_.length > 0, "SplitPayment: 0 shares");
        uint256 totalShares_ = 0;
        for (uint256 i_ = 0; i_ < shares_.length; i_++) {
            require(
                shares_[i_].recipient != address(0),
                "SplitPayment: 0 recipient address"
            );
            require(shares_[i_].share > 0, "SplitPayment: 0 share");
            totalShares_ += shares_[i_].share;
        }
        require(
            totalShares_ == FP_ONE,
            "SplitPayment: Shares total is not 10**18"
        );
    }

    /// Processes transfers according to an array of shares.
    /// Does NOT check the integrity of the shares; assumes
    /// `enforceSharesIntegrity` has been run at least once over the inputs.
    /// @param token_ The token to transfer. May be either approved or owned
    /// by the sending contract.
    /// @param from_ The address to send the token. May NOT be the calling
    /// contract if appropriate approvals have been made by the owner.
    /// @param totalAmount_ The total amount to transfer across all shares.
    /// @param shares_ The share splits to spread `totalAmount_` across.
    function splitTransfer(
        address token_,
        address from_,
        uint256 totalAmount_,
        Share[] memory shares_
    ) internal {
        unchecked {
            bool fromThis_ = from_ == address(this);
            for (uint256 i_ = 0; i_ < shares_.length; i_++) {
                // FixedPointMath uses checked math so disallows overflow.
                // Integrity checks disallow `0` shares.
                uint256 amount_ = totalAmount_.fixedPointMul(shares_[i_].share);
                if (fromThis_) {
                    IERC20(token_).safeTransfer(shares_[i_].recipient, amount_);
                } else {
                    IERC20(token_).safeTransferFrom(
                        from_,
                        shares_[i_].recipient,
                        amount_
                    );
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../payment/SplitPayment.sol";
import "../oracle/ALBTOracle.sol";

/// Configuration for each payment.
/// This must be the same for every payment as the correct config is hashed on
/// deploy then everyone passes it for each payment as calldata. In this way
/// the `PaymentConfig` is never saved or loaded from storage.
/// @param albt Address of the ALBT token.
/// @param shares List of shares as per `SplitPayment`.
/// @param USDTPrice The per-approval price denominated in USDT. Will be
/// converted to ALBT amount by the oracle.
struct PaymentConfig {
    address albt;
    Share[] shares;
    uint256 USDTPrice;
}

/// Construction configuration for a `SessionPaymentPortal` deployment.
/// @param paymentConfig The correct payment config for every payment.
/// @param priceFeed Chainlink oracle address for the `ALBTOracle` constructor.
struct ConstructionConfig {
    PaymentConfig paymentConfig;
    address priceFeed;
}

/// @title SessionPaymentPortal
/// @notice Processes payments associated with a single ad-hoc session.
/// Every session payment is split in exactly the same way according to the
/// shared `paymentConfig_` that is provided by the payer.
/// When the payer calls `payALBT` they must pass in some arbitrary bytes that
/// are expected to be meaningful to some external system, e.g. to prove that
/// a session has been paid for.
///
/// For example, a proxy API that holds keys to an expensive upstream provider
/// can issue a single use challenge to an anon user that wants access. The
/// anon can pay and pass the challenge to the payment function. The proxy API
/// can watch for the event, either from an RPC or indexer. The `msg.sender` of
/// the payment can then request access to the underlying API and the proxy can
/// grant it to them. The proxy MUST ensure that all requests after and
/// associated with the payment are nonced and signed by the `msg.sender` of
/// the payment to prevent other keypairs from stealing the challenge
/// (or replaying requests) and using it for themselves.
/// (as the payment data is completely public).
contract SessionPaymentPortal is ALBTOracle {
    /// Emitted upon construction with the deployer and all relevant config.
    /// @param sender `msg.sender` that constructed the contract.
    /// @param config All construction config.
    event Construction(address sender, ConstructionConfig config);
    /// Emitted when a session is paid for successfully.
    /// @param sender `msg.sender` that paid for the session.
    /// Delegated payments are NOT supported.
    /// @param data Opaque ID that is supposed to bind the payment to some
    /// offchain session, such that the sender can sign requests against the
    /// session and prove that they have paid for it.
    event SessionPaid(address sender, bytes data);

    /// @dev Hash of the payment config so we can immutably enforce correctness
    /// without touching storage.
    uint256 private immutable paymentConfigHash;

    /// Constructor sets up the oracle and hashes over the payment config.
    /// @param config_ All oracle and payment config.
    constructor(ConstructionConfig memory config_)
        ALBTOracle(config_.priceFeed)
    {
        require(
            config_.paymentConfig.albt != address(0),
            "SessionPaymentPortal: 0 ALBT address."
        );
        SplitPayment.enforceSharesIntegrity(config_.paymentConfig.shares);
        require(
            config_.paymentConfig.USDTPrice > 0,
            "SessionPaymentPortal: 0 price."
        );
        paymentConfigHash = uint256(
            keccak256(abi.encode(config_.paymentConfig))
        );
        emit Construction(msg.sender, config_);
    }

    /// User pays for their session by providing some data that binds the
    /// payment to the session somehow offchain.
    /// @param paymentConfig_ Must be the same payment config hashed during
    /// construction of the contract.
    /// @param maxALBT_ User can set a maximum ALBT that they are willing to
    /// pay for the transaction. As the price is converted by USDT to ALBT by
    /// the oracle it is possible for the exchange rate to move against the
    /// user while the transaction is being mined. If the ALBT amount exceeds
    /// the limit the transaction will rollback.
    /// @param data_ The session data that binds the payment to the session.
    /// The offchain handling MUST be secure despite the session data being
    /// completely public in the associated `SessionPaid` event. This can be
    /// achieved (for example) by having the `msg.sender` sign a request for
    /// a session key separate to the public session ID in `data_`. This way
    /// the offchain consumer knows that the payer and session key requestor
    /// are the same entity.
    function payALBT(
        PaymentConfig calldata paymentConfig_,
        uint256 maxALBT_,
        bytes calldata data_
    ) external {
        require(
            paymentConfigHash == uint256(keccak256(abi.encode(paymentConfig_))),
            "SessionPaymentPortal: Wrong payment config."
        );
        emit SessionPaid(msg.sender, data_);

        // Process payment.
        uint256 albtAmount_ = calculateUSDTtoALBT(paymentConfig_.USDTPrice);
        require(
            albtAmount_ <= maxALBT_,
            "SessionPaymentPortal: Required ALBT exceeds user limit."
        );
        SplitPayment.splitTransfer(
            paymentConfig_.albt,
            msg.sender,
            albtAmount_,
            paymentConfig_.shares
        );
    }

    // Returns the amount of ALBT you need to pay when paying with ALBT
    /// @param paymentConfig_ Must be the same payment config hashed during
    /// construction of the contract.
    function getPriceInALBT(PaymentConfig calldata paymentConfig_) external view returns (uint256) {
        require(paymentConfigHash == uint256(keccak256(abi.encode(paymentConfig_))),
            "SessionPaymentPortal: Wrong payment config."
        );
        return calculateUSDTtoALBT(paymentConfig_.USDTPrice);
    }
}