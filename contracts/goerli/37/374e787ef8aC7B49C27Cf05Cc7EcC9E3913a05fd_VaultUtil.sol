// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.4.1) (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
     * - input must fit into 8 bits
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
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    PUT,
    PUT_SPREAD,
    CALL,
    CALL_SPREAD
}

/**
 * @dev action types
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    MergeOptionToken,
    SplitOptionToken,
    AddLong,
    RemoveLong,
    SettleAccount,
    // actions that influece more than one subAccounts:
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral direclty to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// for easier import
import "../core/oracles/errors.sol";
import "../core/engines/full-margin/errors.sol";
import "../core/engines/advanced-margin/errors.sol";
import "../core/engines/cross-margin/errors.sol";

/* ------------------------ *
 *      Shared Errors       *
 * -----------------------  */

error NoAccess();

/* ------------------------ *
 *      Grappa Errors       *
 * -----------------------  */

/// @dev asset already registered
error GP_AssetAlreadyRegistered();

/// @dev margin engine already registered
error GP_EngineAlreadyRegistered();

/// @dev oracle already registered
error GP_OracleAlreadyRegistered();

/// @dev registring oracle doesn't comply with the max dispute period constraint.
error GP_BadOracle();

/// @dev amounts length speicified to batch settle doesn't match with tokenIds
error GP_WrongArgumentLength();

/// @dev cannot settle an unexpired option
error GP_NotExpired();

/// @dev settlement price is not finalized yet
error GP_PriceNotFinalized();

/// @dev cannot mint token after expiry
error GP_InvalidExpiry();

/// @dev put and call should not contain "short stirkes"
error GP_BadStrikes();

/// @dev burn or mint can only be called by corresponding engine.
error GP_Not_Authorized_Engine();

/* ---------------------------- *
 *   Common BaseEngine Errors   *
 * ---------------------------  */

/// @dev can only merge subaccount with put or call.
error BM_CannotMergeSpread();

/// @dev only spread position can be split
error BM_CanOnlySplitSpread();

/// @dev type of existing short token doesn't match the incoming token
error BM_MergeTypeMismatch();

/// @dev product type of existing short token doesn't match the incoming token
error BM_MergeProductMismatch();

/// @dev expiry of existing short token doesn't match the incoming token
error BM_MergeExpiryMismatch();

/// @dev cannot merge type with the same strike. (should use burn instead)
error BM_MergeWithSameStrike();

/// @dev account is not healthy / account is underwater
error BM_AccountUnderwater();

/// @dev msg.sender is not authorized to ask margin account to pull token from {from} address
error BM_InvalidFromAddress();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./enums.sol";

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId grappa asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}

/**
 * @dev struct containing assets detail for an product
 * @param underlying    underlying address
 * @param strike        strike address
 * @param collateral    collateral address
 * @param collateralDecimals collateral asset decimals
 */
struct ProductDetails {
    address oracle;
    uint8 oracleId;
    address engine;
    uint8 engineId;
    address underlying;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    address strike;
    uint8 strikeId;
    uint8 strikeDecimals;
    address collateral;
    uint8 collateralId;
    uint8 collateralDecimals;
}

// todo: update doc
struct ActionArgs {
    ActionType action;
    bytes data;
}

struct BatchExecute {
    address subAccount;
    ActionArgs[] actions;
}

/**
 * @dev asset detail stored per asset id
 * @param addr address of the asset
 * @param decimals token decimals
 */
struct AssetDetail {
    address addr;
    uint8 decimals;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ------------------------ *
 *  Advanced Margin Errors
 * -----------------------  */

/// @dev full margin doesn't support this action (add long and remove long)
error AM_UnsupportedAction();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error AM_WrongCollateralId();

/// @dev trying to merge an long with a non-existant short position
error AM_ShortDoesnotExist();

/// @dev can only merge same amount of long and short
error AM_MergeAmountMisMatch();

/// @dev can only split same amount of existing spread into short + long
error AM_SplitAmountMisMatch();

/// @dev invalid tokenId specify to mint / burn actions
error AM_InvalidToken();

/// @dev no config set for this asset.
error AM_NoConfig();

/// @dev cannot liquidate or takeover position: account is healthy
error AM_AccountIsHealthy();

/// @dev cannot override a non-empty subaccount id
error AM_AccountIsNotEmpty();

/// @dev amounts to repay in liquidation are not valid. Missing call, put or not proportional to the amount in subaccount.
error AM_WrongRepayAmounts();

/// @dev cannot remove collateral because there are expired longs
error AM_ExpiredShortInAccount();

// Vol Oracle

/// @dev cannot re-set aggregator
error VO_AggregatorAlreadySet();

/// @dev no aggregator set
error VO_AggregatorNotSet();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../libraries/TokenIdUtil.sol";
import "../../../libraries/ArrayUtil.sol";

// cross margin types
import "./types.sol";

library AccountUtil {
    using TokenIdUtil for uint192;
    using TokenIdUtil for uint256;

    function append(CrossMarginDetail[] memory x, CrossMarginDetail memory v)
        internal
        pure
        returns (CrossMarginDetail[] memory y)
    {
        y = new CrossMarginDetail[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(Position[] memory x, Position memory v) internal pure returns (Position[] memory y) {
        y = new Position[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function concat(Position[] memory a, Position[] memory b) internal pure returns (Position[] memory y) {
        y = new Position[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];
            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];
            unchecked {
                ++i;
                ++v;
            }
        }
    }

    /// @dev currently unused
    function find(Position[] memory x, uint256 v) internal pure returns (bool f, Position memory p, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                p = x[i];
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function find(PositionOptim[] memory x, uint192 v) internal pure returns (bool f, PositionOptim memory p, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                p = x[i];
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function indexOf(Position[] memory x, uint256 v) internal pure returns (bool f, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function indexOf(PositionOptim[] memory x, uint192 v) internal pure returns (bool f, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function sum(PositionOptim[] memory x) internal pure returns (uint64 s) {
        for (uint256 i; i < x.length;) {
            s += x[i].amount;
            unchecked {
                ++i;
            }
        }
    }

    function getPositions(PositionOptim[] memory x) internal pure returns (Position[] memory y) {
        y = new Position[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = Position(x[i].tokenId.expand(), x[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    function getPositionOptims(Position[] memory x) internal pure returns (PositionOptim[] memory y) {
        y = new PositionOptim[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = getPositionOptim(x[i]);
            unchecked {
                ++i;
            }
        }
    }

    function pushPosition(PositionOptim[] storage x, Position memory y) internal {
        x.push(getPositionOptim(y));
    }

    function removePositionAt(PositionOptim[] storage x, uint256 y) internal {
        if (y >= x.length) return;
        x[y] = x[x.length - 1];
        x.pop();
    }

    function getPositionOptim(Position memory x) internal pure returns (PositionOptim memory) {
        return PositionOptim(x.tokenId.compress(), x.amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* --------------------- *
 *  Cross Margin Errors
 * --------------------- */

/// @dev cross margin doesn't support this action
error CM_UnsupportedAction();

/// @dev cannot override a non-empty subaccount id
error CM_AccountIsNotEmpty();

/// @dev unsupported token type
error CM_UnsupportedTokenType();

/// @dev can only add long tokens that are not expired
error CM_Option_Expired();

/// @dev can only add long tokens from authorized engines
error CM_Not_Authorized_Engine();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error CM_WrongCollateralId();

/// @dev invalid collateral:
error CM_CannotMintOptionWithThisCollateral();

/// @dev invalid tokenId specify to mint / burn actions
error CM_InvalidToken();

/* --------------------- *
 *  Cross Margin Math Errors
 * --------------------- */

/// @dev invalid put length given strikes
error CMM_InvalidPutLengths();

/// @dev invalid call length given strikes
error CMM_InvalidCallLengths();

/// @dev invalid put length of zero
error CMM_InvalidPutWeight();

/// @dev invalid call length of zero
error CMM_InvalidCallWeight();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../config/enums.sol";
import "../../../config/types.sol";

/**
 * @dev base unit of cross margin account. This is the data stored in the state
 *      storage packing is utilized to save gas.
 * @param shorts an array of short positions
 * @param longs an array of long positions
 * @param collaterals an array of collateral balances
 */
struct CrossMarginAccount {
    PositionOptim[] shorts;
    PositionOptim[] longs;
    Balance[] collaterals;
}

/**
 * @dev struct used in memory to represent a cross margin account's option set
 *      this is a grouping of like underlying, collateral, strike (asset), and expiry
 *      used to calculate margin requirements
 * @param putWeights            amount of put options held in account (shorts and longs)
 * @param putStrikes            strikes of put options held in account (shorts and longs)
 * @param callWeights           amount of call options held in account (shorts and longs)
 * @param callStrikes           strikes of call options held in account (shorts and longs)
 * @param underlyingId          grappa id for underlying asset
 * @param underlyingDecimals    decimal points of underlying asset
 * @param numeraireId           grappa id for numeraire (aka strike) asset
 * @param numeraireDecimals     decimal points of numeraire (aka strike) asset
 * @param spotPrice             current spot price of underlying in terms of strike asset
 * @param expiry                expiry of the option
 */
struct CrossMarginDetail {
    int256[] putWeights;
    uint256[] putStrikes;
    int256[] callWeights;
    uint256[] callStrikes;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    uint8 numeraireId;
    uint8 numeraireDecimals;
    uint256 expiry;
}

/**
 * @dev a compressed Position struct, compresses tokenId to save storage space
 * @param tokenId option token
 * @param amount number option tokens
 */
struct PositionOptim {
    uint192 tokenId;
    uint64 amount;
}

/**
 * @dev an uncompressed Position struct, expanding tokenId to uint256
 * @param tokenId grappa option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ------------------------ *
 *    Full Margin Errors
 * -----------------------  */

/// @dev full margin doesn't support this action
error FM_UnsupportedAction();

/// @dev invalid collateral:
///         call can only be collateralized by underlying
///         put can only be collateralized by strike
error FM_CannotMintOptionWithThisCollateral();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error FM_WrongCollateralId();

/// @dev invalid tokenId specify to mint / burn actions
error FM_InvalidToken();

/// @dev trying to merge an long with a non-existant short position
error FM_ShortDoesnotExist();

/// @dev can only merge same amount of long and short
error FM_MergeAmountMisMatch();

/// @dev can only split same amount of existing spread into short + long
error FM_SplitAmountMisMatch();

/// @dev trying to collateralized the position with different collateral than specified in productId
error FM_CollateraliMisMatch();

/// @dev cannot override a non-empty subaccount id
error FM_AccountIsNotEmpty();

/// @dev cannot remove collateral because there are expired longs
error FM_ExpiredShortInAccount();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error OC_CannotReportForFuture();

error OC_PriceNotReported();

error OC_PriceReported();

///@dev cannot dispute the settlement price after dispute period is over
error OC_DisputePeriodOver();

///@dev cannot force-set an settlement price until grace period is passed and no one has set the price.
error OC_GracePeriodNotOver();

///@dev already disputed
error OC_PriceDisputed();

///@dev owner trying to set a dispute period that is invalid
error OC_InvalidDisputePeriod();

// Chainlink oracle

error CL_AggregatorNotSet();

error CL_StaleAnswer();

error CL_RoundIdTooSmall();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/types.sol";

/**
 * @title libraries to encode action arguments
 * @dev   only used in tests
 */
library ActionUtil {
    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to deposit
     * @param from address to pull asset from
     */
    function createAddCollateralAction(uint8 collateralId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.AddCollateral, data: abi.encode(from, uint80(amount), collateralId)});
    }

    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to remove
     * @param recipient address to receive removed collateral
     */
    function createRemoveCollateralAction(uint8 collateralId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.RemoveCollateral, data: abi.encode(uint80(amount), recipient, collateralId)});
    }

    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to remove
     * @param recipient address to receive removed collateral
     */
    function createTransferCollateralAction(uint8 collateralId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferCollateral, data: abi.encode(uint80(amount), recipient, collateralId)});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient address to receive minted option
     */
    function createMintAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MintShort, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param subAccount sub account to receive minted option
     */
    function createMintIntoAccountAction(uint256 tokenId, uint256 amount, address subAccount)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MintShortIntoAccount, data: abi.encode(tokenId, subAccount, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient account to receive minted option
     */
    function createTranferLongAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferLong, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient account to receive minted option
     */
    function createTranferShortAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferShort, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to burn
     * @param amount amount of token to burn (6 decimals)
     * @param from address to burn option token from
     */
    function createBurnAction(uint256 tokenId, uint256 amount, address from) internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.BurnShort, data: abi.encode(tokenId, from, uint64(amount))});
    }

    /**
     * @param tokenId option token id of the incoming option token.
     * @param shortId the currently shorted "option token id" to merge the option token into
     * @param amount amount to merge
     * @param from which address to burn the incoming option from.
     */
    function createMergeAction(uint256 tokenId, uint256 shortId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MergeOptionToken, data: abi.encode(tokenId, shortId, from, amount)});
    }

    /**
     * @param spreadId current shorted "spread option id"
     * @param amount amount to split
     * @param recipient address to receive the "splited" long option token.
     */
    function createSplitAction(uint256 spreadId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.SplitOptionToken, data: abi.encode(spreadId, uint64(amount), recipient)});
    }

    /**
     * @param tokenId option token to be added to the account
     * @param amount amount to add
     * @param from address to pull the token from
     */
    function createAddLongAction(uint256 tokenId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.AddLong, data: abi.encode(tokenId, uint64(amount), from)});
    }

    /**
     * @param tokenId option token to be removed from an account
     * @param amount amount to remove
     * @param recipient address to receive the removed option
     */
    function createRemoveLongAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.RemoveLong, data: abi.encode(tokenId, uint64(amount), recipient)});
    }

    /**
     * @dev create action to settle an account
     */
    function createSettleAction() internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.SettleAccount, data: abi.encode(0)});
    }

    function concat(ActionArgs[] memory x, ActionArgs[] memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + v.length);
        uint256 z;
        uint256 i;
        for (i; i < x.length;) {
            y[z] = x[i];
            unchecked {
                ++z;
                ++i;
            }
        }
        for (i = 0; i < v.length;) {
            y[z] = v[i];
            unchecked {
                ++z;
                ++i;
            }
        }
    }

    function append(ActionArgs[] memory x, ActionArgs memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(BatchExecute[] memory x, BatchExecute memory v) internal pure returns (BatchExecute[] memory y) {
        y = new BatchExecute[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    // add a function prefixed with test here so forge coverage will ignore this file
    function testChillOnHelper() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "lib/grappa/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

library ArrayUtil {
    using SafeCast for uint256;
    using SafeCast for int256;

    error IndexOutOfBounds();

    /**
     * @dev Returns minimal element in array
     * @return m
     */
    function min(int256[] memory x) internal pure returns (int256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function minWithIndex(int256[] memory x) internal pure returns (int256 m, uint256 idx) {
        m = x[0];
        idx = 0;
        for (uint256 i; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
                idx = i;
            }
            unchecked {
                ++i;
            }
        }
    }

    function min(uint256[] memory x) internal pure returns (uint256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function minMax(uint256[] memory x) internal pure returns (uint256 min_, uint256 max_) {
        (min_, max_) = (x[0], x[0]);
        for (uint256 i; i < x.length;) {
            if (x[i] < min_) {
                min_ = x[i];
            }
            if (x[i] > max_) {
                max_ = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    // /**
    //  * @dev Returns minimal element's index
    //  * @return m
    //  */
    // function imin(uint256[] memory x) internal pure returns (uint256 m) {
    //     m = 0;
    //     for (uint256 i; i < x.length; i++) {
    //         if (x[i] < x[m]) {
    //             m = i;
    //         }
    //     }
    //     return m;
    // }

    /**
     * @dev Returns maximal element in array
     * @return m
     */
    function max(int256[] memory x) internal pure returns (int256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] > m) {
                m = x[i];
            }

            unchecked {
                ++i;
            }
        }
    }

    function max(uint256[] memory x) internal pure returns (uint256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] > m) {
                m = x[i];
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns maximal elements comparedTo value
     * @return y array
     */
    function maximum(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            if (x[i] > z) y[i] = x[i];
            else y[i] = z;

            unchecked {
                ++i;
            }
        }
    }

    // /**
    //  * @dev Returns maximal element's index
    //  * @return m maximal
    //  */
    // function imax(uint256[] memory x) internal pure returns (uint256 m) {
    //     for (uint256 i; i < x.length; i++) {
    //         if (x[i] > x[m]) {
    //             m = i;
    //         }
    //     }
    // }

    /**
     * @dev Removes element at index in a new unsigned int array, does not change x memory in place
     * @return y new array
     */
    function remove(uint256[] memory x, uint256 z) internal pure returns (uint256[] memory y) {
        if (z >= x.length) return x;
        y = new uint256[](x.length - 1);
        for (uint256 i; i < x.length;) {
            unchecked {
                if (i < z) y[i] = x[i];
                else if (i > z) y[i - 1] = x[i];
                ++i;
            }
        }
    }

    /**
     * @dev Removes element at index in a new signed int array, does not change x memory in place
     * @return y new array
     */
    function remove(int256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        if (z >= x.length) return x;
        y = new int256[](x.length - 1);
        for (uint256 i; i < x.length;) {
            unchecked {
                if (i < z) y[i] = x[i];
                else if (i > z) y[i - 1] = x[i];
                ++i;
            }
        }
    }

    /**
     * @dev Returns index of element
     * @return found
     * @return index
     */
    function indexOf(int256[] memory x, int256 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }

            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    function indexOf(bytes32[] memory x, bytes32 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }

            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    function indexOf(uint256[] memory x, uint256 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }

            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    /**
     * @dev Compute sum of all elements
     * @return s sum
     */
    function sum(int256[] memory x) internal pure returns (int256 s) {
        for (uint256 i; i < x.length;) {
            s += x[i];

            unchecked {
                ++i;
            }
        }
    }

    function sum(uint256[] memory x) internal pure returns (uint256 s) {
        for (uint256 i; i < x.length;) {
            s += x[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev put the min of last p elements in array at position p.
     */

    function argSort(uint256[] memory x) internal pure returns (uint256[] memory y, uint256[] memory ixArray) {
        ixArray = new uint256[](x.length);
        // fill in index array
        for (uint256 i; i < x.length;) {
            ixArray[i] = i;

            unchecked {
                ++i;
            }
        }
        // initialize copy of x
        y = new uint256[](x.length);
        populate(y, x, 0);
        // sort
        quickSort(y, int256(0), int256(y.length - 1), ixArray);
    }

    function sort(uint256[] memory x) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length);
        populate(y, x, 0);
        quickSort(y, int256(0), int256(y.length - 1));
    }

    /*
    @dev quicksort implementation, sorts arr input IN PLACE
    */
    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            uint256 pivot = arr[uint256(left + (right - left) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    /*
    @dev quicksort implementation with indexes, sorts input arr and indexArray IN PLACE
    */
    function quickSort(uint256[] memory arr, int256 left, int256 right, uint256[] memory indexArray) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            uint256 pivot = arr[uint256(left + (right - left) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    (indexArray[uint256(i)], indexArray[uint256(j)]) = (indexArray[uint256(j)], indexArray[uint256(i)]);
                    ++i;
                    --j;
                }
            }
            if (left < j) quickSort(arr, left, j, indexArray);
            if (i < right) quickSort(arr, i, right, indexArray);
        }
    }

    /**
     *  sort functions for int ***
     */

    function argSort(int256[] memory x) internal pure returns (int256[] memory y, uint256[] memory ixArray) {
        ixArray = new uint256[](x.length);
        // fill in index array
        for (uint256 i; i < x.length;) {
            ixArray[i] = i;

            unchecked {
                ++i;
            }
        }
        // initialize copy of x
        y = new int256[](x.length);
        populate(y, x, 0);
        // sort
        quickSort(y, int256(0), int256(y.length - 1), ixArray);
    }

    function sort(int256[] memory x) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        populate(y, x, 0);
        quickSort(y, int256(0), int256(y.length - 1));
    }

    // quicksort implementation, sorts arr in place
    function quickSort(int256[] memory arr, int256 left, int256 right) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            int256 pivot = arr[uint256(left + (right - left) / 2)];

            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    // quicksort implementation with indexes, sorts arr and indexArray in place
    function quickSort(int256[] memory arr, int256 left, int256 right, uint256[] memory indexArray) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            int256 pivot = arr[uint256(left + (right - left) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    (indexArray[uint256(i)], indexArray[uint256(j)]) = (indexArray[uint256(j)], indexArray[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j, indexArray);
        if (i < right) quickSort(arr, i, right, indexArray);
    }

    /**
     * End Sort Functions for Int ******
     */

    function sortByIndexes(int256[] memory x, uint256[] memory z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[z[i]];

            unchecked {
                ++i;
            }
        }
    }

    function append(bytes32[] memory x, bytes32 e) internal pure returns (bytes32[] memory y) {
        y = new bytes32[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];

            unchecked {
                ++i;
            }
        }
        y[i] = e;
    }

    function append(int256[] memory x, int256 v) internal pure returns (int256[] memory y) {
        y = new int256[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];

            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(uint256[] memory x, uint256 v) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];

            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function concat(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory y) {
        y = new int256[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];

            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];

            unchecked {
                ++i;
                ++v;
            }
        }
    }

    function concat(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory y) {
        y = new uint256[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];

            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];

            unchecked {
                ++i;
                ++v;
            }
        }
    }

    /*
    @dev this function modifies memory x IN PLACE. Fills x with value v
    */
    function fill(int256[] memory x, int256 v) internal pure {
        for (uint256 i; i < x.length;) {
            x[i] = v;

            unchecked {
                ++i;
            }
        }
    }

    /*
    @dev modifies memory a IN PLACE. Populates a starting at index z with values from b.
    */
    function populate(uint256[] memory a, uint256[] memory b, uint256 z) internal pure {
        for (uint256 i; i < a.length;) {
            a[z + i] = b[i];

            unchecked {
                ++i;
            }
        }
    }

    /*
    @dev modifies memory a IN PLACE. Populates a starting at index z with values from b.
    */
    function populate(int256[] memory a, int256[] memory b, uint256 z) internal pure {
        for (uint256 i; i < a.length;) {
            a[z + i] = b[i];

            unchecked {
                ++i;
            }
        }
    }

    function at(int256[] memory x, int256 i) internal pure returns (int256) {
        int256 len = x.length.toInt256();
        if (i > 0) {
            if (i > len) revert IndexOutOfBounds();
            return x[uint256(i)];
        } else {
            if (i < -len) revert IndexOutOfBounds();
            return x[(len + i).toUint256()];
        }
    }

    function at(uint256[] memory x, int256 i) internal pure returns (uint256) {
        int256 len = x.length.toInt256();
        if (i > 0) {
            if (i > len) revert IndexOutOfBounds();
            return x[uint256(i)];
        } else {
            if (i < -len) revert IndexOutOfBounds();
            return x[(len + i).toUint256()];
        }
    }

    function slice(int256[] memory x, int256 _start, int256 _end) internal pure returns (int256[] memory a) {
        int256 len = x.length.toInt256();
        if (_start < 0) _start = len + _start;
        if (_end <= 0) _end = len + _end;
        if (_end < _start) return new int256[](0);

        uint256 start = _start.toUint256();
        uint256 end = _end.toUint256();

        a = new int256[](end - start);
        uint256 y = 0;
        for (uint256 i = start; i < end;) {
            a[y] = x[i];

            unchecked {
                ++i;
                ++y;
            }
        }
    }

    function subEachFrom(uint256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = z.toInt256() - x[i].toInt256();

            unchecked {
                ++i;
            }
        }
    }

    function subEachBy(uint256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i].toInt256() - z.toInt256();

            unchecked {
                ++i;
            }
        }
    }

    function addEachBy(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i] + z;

            unchecked {
                ++i;
            }
        }
    }

    function add(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory y) {
        y = new int256[](a.length);
        for (uint256 i; i < a.length;) {
            y[i] = a[i] + b[i];

            unchecked {
                i++;
            }
        }
    }

    function eachMulDivDown(int256[] memory x, int256 z, int256 d) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = (x[i] * z) / d;

            unchecked {
                ++i;
            }
        }
    }

    function eachMulDivUp(int256[] memory x, int256 z, int256 d) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = ((x[i] * z) / d) + 1;

            unchecked {
                ++i;
            }
        }
    }

    function eachMul(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i] * z;

            unchecked {
                ++i;
            }
        }
    }

    function eachDiv(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i] / z;

            unchecked {
                ++i;
            }
        }
    }

    function dot(int256[] memory a, int256[] memory b) internal pure returns (int256 s) {
        for (uint256 i; i < a.length;) {
            s += a[i] * b[i];

            unchecked {
                ++i;
            }
        }
    }

    function dot(uint256[] memory a, int256[] memory b) internal pure returns (int256 s) {
        for (uint256 i; i < a.length;) {
            s += int256(a[i]) * b[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev converting array of variable types
     */

    function toInt256(uint256[] memory x) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i].toInt256();

            unchecked {
                ++i;
            }
        }
    }

    function toUint256(int256[] memory x) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i].toUint256();

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable max-line-length

/**
 * @title ProductIdUtil
 * @dev used to parse and compose productId
 * Product Id =
 * * ----------------- | ----------------- | ---------------------- | ------------------ | ---------------------- *
 * | oracleId (8 bits) | engineId (8 bits) | underlying ID (8 bits) | strike ID (8 bits) | collateral ID (8 bits) |
 * * ----------------- | ----------------- | ---------------------- | ------------------ | ---------------------- *
 *
 */
library ProductIdUtil {
    /**
     * @dev parse product id into composing asset ids
     *
     * productId (40 bits) =
     *
     * @param _productId product id
     */
    function parseProductId(uint40 _productId)
        internal
        pure
        returns (uint8 oracleId, uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            oracleId := shr(32, _productId)
            engineId := shr(24, _productId)
            underlyingId := shr(16, _productId)
            strikeId := shr(8, _productId)
        }
        collateralId = uint8(_productId);
    }

    /**
     * @dev parse collateral id from product Id.
     *      since collateral id is uint8 of the last 8 bits of productId, we can just cast to uint8
     */
    function getCollateralId(uint40 _productId) internal pure returns (uint8) {
        return uint8(_productId);
    }

    /**
     * @notice    get product id from underlying, strike and collateral address
     * @dev       function will still return even if some of the assets are not registered
     * @param underlyingId  underlying id
     * @param strikeId      strike id
     * @param collateralId  collateral id
     */
    function getProductId(uint8 oracleId, uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId)
        internal
        pure
        returns (uint40 id)
    {
        unchecked {
            id = (uint40(oracleId) << 32) + (uint40(engineId) << 24) + (uint40(underlyingId) << 16) + (uint40(strikeId) << 8)
                + (uint40(collateralId));
        }
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable max-line-length

pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/errors.sol";

/**
 * Token ID =
 *
 *  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
 *  | tokenType (24 bits) | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
 *  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
 */

/**
 * Compressed Token ID =
 *
 *  * ------------------- | ------------------- | ---------------- | -------------------- *
 *  | tokenType (24 bits) | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
 *  * ------------------- | ------------------- | ---------------- | -------------------- *
 */
library TokenIdUtil {
    function getTokenId(TokenType tokenType, uint40 productId, uint256 expiry, uint256 longStrike, uint256 shortStrike)
        internal
        pure
        returns (uint256 tokenId)
    {
        tokenId = formatTokenId(tokenType, productId, uint64(expiry), uint64(longStrike), uint64(shortStrike));
    }

    /**
     * @notice calculate ERC1155 token id for given option parameters. See table above for tokenId
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param longStrike strike price of the long option, with 6 decimals
     * @param shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     * @return tokenId token id
     */
    function formatTokenId(TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike)
        internal
        pure
        returns (uint256 tokenId)
    {
        unchecked {
            tokenId = (uint256(tokenType) << 232) + (uint256(productId) << 192) + (uint256(expiry) << 128)
                + (uint256(longStrike) << 64) + uint256(shortStrike);
        }
    }

    /**
     * @notice calculate non-complaint ERC1155 token id for given option parameters. See table above for shorttokenId
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param longStrike strike price of the long option, with 6 decimals
     * @return tokenId token id
     */
    function formatShortTokenId(TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike)
        internal
        pure
        returns (uint192 tokenId)
    {
        unchecked {
            tokenId = (uint192(tokenType) << 168) + (uint192(productId) << 128) + (uint192(expiry) << 64) + uint192(longStrike);
        }
    }

    /**
     * @notice derive option, product, expiry and strike price from ERC1155 token id
     * @dev    See table above for tokenId composition
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId 32 bits product id
     * @return expiry timestamp of option expiry
     * @return longStrike strike price of the long option, with 6 decimals
     * @return shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     */
    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
            productId := shr(192, tokenId)
            expiry := shr(128, tokenId)
            longStrike := shr(64, tokenId)
            shortStrike := tokenId
        }
    }

    /**
     * @notice parse collateral id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return collatearlId
     */
    function parseCollateralId(uint256 tokenId) internal pure returns (uint8 collatearlId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            collatearlId := shr(192, tokenId)
        }
    }

    /**
     * @notice parse engine id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return engineId
     */
    function parseEngineId(uint256 tokenId) internal pure returns (uint8 engineId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            engineId := shr(216, tokenId) // 192 to get product id, another 24 to get engineId
        }
    }

    /**
     * @notice derive option, product, expiry and strike price from short token id (no shortStrike)
     * @dev    See table above for tokenId composition
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId 32 bits product id
     * @return expiry timestamp of option expiry
     * @return longStrike strike price of the long option, with 6 decimals
     */
    function parseShortTokenId(uint192 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(168, tokenId)
            productId := shr(128, tokenId)
            expiry := shr(64, tokenId)
            longStrike := tokenId
        }
    }

    /**
     * @notice derive option type from ERC1155 token id
     * @param tokenId token id
     * @return tokenType TokenType enum
     */
    function parseTokenType(uint256 tokenId) internal pure returns (TokenType tokenType) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
        }
    }

    /**
     * @notice derive if option is expired from ERC1155 token id
     * @param tokenId token id
     * @return expired bool
     */
    function isExpired(uint256 tokenId) internal view returns (bool expired) {
        uint64 expiry;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            expiry := shr(128, tokenId)
        }

        expired = block.timestamp >= expiry;
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | spread type (24 b)  | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   this function will: override tokenType, remove shortStrike.
     * @param _tokenId token id to change
     */
    function convertToVanillaId(uint256 _tokenId) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shr(64, _tokenId) // step 1: >> 64 to wipe out shortStrike
            newId := shl(64, newId) // step 2: << 64 go back

            newId := sub(newId, shl(232, 1)) // step 3: new tokenType = spread type - 1
        }
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | spread type         | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *
     * this function convert put or call type to spread type, add shortStrike.
     * @param _tokenId token id to change
     * @param _shortStrike strike to add
     */
    function convertToSpreadId(uint256 _tokenId, uint256 _shortStrike) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        unchecked {
            newId = _tokenId + _shortStrike;
            return newId + (1 << 232); // new type (spread type) = old type + 1
        }
    }

    /**
     * @notice Compresses tokenId by removing shortStrike.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     *
     * @param _tokenId token id to change
     */
    function compress(uint256 _tokenId) internal pure returns (uint192 newId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shr(64, _tokenId) // >> 64 to wipe out shortStrike
        }
    }

    /**
     * @notice convert a shortened tokenId back ERC1155 compliant.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *
     * @param _tokenId token id to change
     */
    function expand(uint192 _tokenId) internal pure returns (uint256 newId) {
        newId = uint256(_tokenId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shl(64, newId)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../lib/grappa/src/config/types.sol" as Grappa;
import "../../lib/grappa/src/core/engines/cross-margin/types.sol" as MarginEngine;

interface IMarginEngine {
    function grappa() external view returns (address);

    function optionToken() external view returns (address);

    function marginAccounts(address)
        external
        view
        returns (MarginEngine.Position[] memory shorts, MarginEngine.Position[] memory longs, Grappa.Balance[] memory collaterals);

    function execute(address account, Grappa.ActionArgs[] calldata actions) external;

    function batchExecute(Grappa.BatchExecute[] calldata batchActions) external;

    function previewMinCollateral(MarginEngine.Position[] memory shorts, MarginEngine.Position[] memory longs)
        external
        view
        returns (Grappa.Balance[] memory);
}

interface IGrappa {
    function assets(uint8) external view returns (Grappa.AssetDetail memory);

    function assetIds(address) external view returns (uint8);

    function engineIds(address) external view returns (uint8);

    function oracleIds(address) external view returns (uint8);

    function getPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, address collateral, uint256 payout);

    function getProductId(address oracle, address engine, address underlying, address strike, address collateral)
        external
        view
        returns (uint40 id);

    function getDetailFromProductId(uint40 productId)
        external
        view
        returns (
            address oracle,
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );
}

interface IOptionToken {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IOracle {
    /**
     * @notice  get spot price of _base, denominated in _quote.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @return price with 6 decimals
     */
    function getSpotPrice(address _base, address _quote) external view returns (uint256);

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @param _expiry expiry timestamp
     *
     * @return price with 6 decimals
     */
    function getPriceAtExpiry(address _base, address _quote, uint256 _expiry)
        external
        view
        returns (uint256 price, bool isFinalized);

    /**
     * @dev return the maximum dispute period for the oracle
     * @dev this will only be checked during oracle registration, as a soft constraint on integrating oracles.
     */
    function maxDisputePeriod() external view returns (uint256 disputePeriod);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../libraries/BatchAuctionQ.sol";

interface IBatchAuction {
    struct Collateral {
        //ERC20 token for the required collateral
        address addr;
        // The amount of tokens required for the collateral
        uint80 amount;
    }

    struct Auction {
        // Seller wallet address
        address seller;
        // ERC1155 address
        address optionTokenAddr;
        // ERC1155 Id of auctioned token
        uint256[] optionTokens;
        // ERC20 Token to bid for optionToken
        address biddingToken;
        // List of collateral requirements for each ERC20 token
        Collateral[] collaterals;
        // Price per optionToken denominated in biddingToken
        int256 minPrice;
        // Minimum optionToken amount acceptable for a single bid
        uint256 minBidSize;
        // Total available optionToken amount
        uint256 totalSize;
        // Remaining available optionToken amount
        // This figure is updated after each successfull bid
        uint256 availableSize;
        // Auction end time
        uint256 endTime;
        // clearing price
        int256 clearingPrice;
        // has the auction been settled
        bool settled;
        // whitelist address
        address whitelist;
    }

    function createAuction(
        address optionTokenAddr,
        uint256[] calldata optionTokens,
        address biddingToken,
        Collateral[] calldata collaterals,
        int256 minPrice,
        uint256 minBidSize,
        uint256 totalSize,
        uint256 endTime,
        address whitelist
    ) external returns (uint256 auctionId);

    function placeBid(uint256 auctionId, uint256 quantity, int256 price) external;

    function cancelBid(uint256 auctionId, uint256 bidId) external;

    function auctions(uint256) external view returns (IBatchAuction.Auction memory auction);

    function settleAuction(uint256 auctionId) external returns (int256 clearingPrice, uint256 totalSold);

    function claim(uint256 auctionId) external;

    function getBids(uint256 auctionId) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISanctionsList {
    function isSanctioned(address _address) external view returns (bool);
}

interface IWhitelist {
    function isCustomer(address _address) external view returns (bool);

    function isLP(address _address) external view returns (bool);

    function isOTC(address _address) external view returns (bool);

    function isVault(address vault) external view returns (bool);

    function engineAccess(address _address) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ArrayUtil } from "../../lib/grappa/src/libraries/ArrayUtil.sol";

import "../libraries/Errors.sol";

/// @notice a special queue struct for auction mechanics
library BatchAuctionQ {
    struct Queue {
        int256 clearingPrice;
        ///@notice array of bid prices in time order
        int256[] bidPriceList;
        ///@notice array of bid quantities in time order
        uint256[] bidQuantityList;
        ///@notice array of bidders
        address[] bidOwnerList;
        ///@notice winning bids
        uint256[] filledAmount;
    }

    function isEmpty(Queue storage self) external view returns (bool) {
        return self.bidPriceList.length == 0;
    }

    ///@notice insert bid in heap
    function insert(Queue storage self, address owner, int256 price, uint256 quantity) external returns (uint256 index) {
        self.bidPriceList.push(price);
        self.bidQuantityList.push(quantity);
        self.bidOwnerList.push(owner);
        self.filledAmount.push(0);

        index = self.bidPriceList.length - 1;
    }

    /// @notice remove deletes the owner from the owner list, so checking for a 0 address checks that a bid was pulled
    function remove(Queue storage self, uint256 index) external {
        delete self.bidOwnerList[index];
        delete self.bidQuantityList[index];
        delete self.bidPriceList[index];
        delete self.filledAmount[index];
    }

    /**
     * @notice fills as many bids as possible at the highest price as possible, the lowest price bid that was filled should become the clearing price
     */
    function computeFills(Queue storage self, uint256 totalSize) external returns (uint256 totalFilled, int256 clearingPrice) {
        uint256 bidLength = self.bidQuantityList.length;

        if (bidLength == 0) return (0, 0);

        if (ArrayUtil.sum(self.bidQuantityList) == 0) return (0, 0);

        uint256 bidId;
        uint256 bidQuantity;
        uint256 orderFilled;
        uint256 lastFilledBidId;

        // sort the bids by price and return an array of indices
        (, uint256[] memory bidOrder) = ArrayUtil.argSort(self.bidPriceList);

        // start from back of list to reverse sort
        uint256 i = bidLength - 1;
        bool endOfBids = false;

        while (totalFilled < totalSize && !endOfBids) {
            bidId = bidOrder[i];

            endOfBids = i == 0;

            // decrease index here, do not use i after this
            unchecked {
                --i;
            }

            // if this bid was removed, skip it
            if (self.bidOwnerList[bidId] == address(0)) continue;

            bidQuantity = self.bidQuantityList[bidId];

            //check if we can only partly fill a bid
            if ((totalFilled + bidQuantity) > totalSize) {
                orderFilled = totalSize - totalFilled;
            } else {
                orderFilled = bidQuantity;
            }

            self.filledAmount[bidId] = orderFilled;

            totalFilled += orderFilled;

            lastFilledBidId = bidId;
        }

        self.clearingPrice = clearingPrice = self.bidPriceList[lastFilledBidId];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// Vault
error HV_ActiveRound();
error HV_AuctionInProgress();
error HV_BadAddress();
error HV_BadAmount();
error HV_BadCap();
error HV_BadCollaterals();
error HV_BadCollateralPosition();
error HV_BadDepositAmount();
error HV_BadDuration();
error HV_BadExpiry();
error HV_BadFee();
error HV_BadLevRatio();
error HV_BadNumRounds();
error HV_BadNumShares();
error HV_BadNumStrikes();
error HV_BadOption();
error HV_BadPPS();
error HV_BadRound();
error HV_BadSB();
error HV_BadStructures();
error HV_CustomerNotPermissioned();
error HV_ExistingWithdraw();
error HV_ExceedsCap();
error HV_ExceedsAvailable();
error HV_Initialized();
error HV_InsufficientFunds();
error HV_OptionNotExpired();
error HV_RoundClosed();
error HV_RoundNotClosed();
error HV_Unauthorized();
error HV_Uninitialized();

// VaultPauser
error VP_BadAddress();
error VP_CustomerNotPermissioned();
error VP_Overflow();
error VP_PositionPaused();
error VP_RoundOpen();
error VP_Unauthorized();
error VP_VaultNotPermissioned();

// VaultUtil
error VL_BadCap();
error VL_BadCollateral();
error VL_BadCollateralAddress();
error VL_BadDuration();
error VL_BadExpiryDate();
error VL_BadFee();
error VL_BadFeeAddress();
error VL_BadGrappaAddress();
error VL_BadId();
error VL_BadInstruments();
error VL_BadManagerAddress();
error VL_BadOracleAddress();
error VL_BadOwnerAddress();
error VL_BadPauserAddress();
error VL_BadPrecision();
error VL_BadProduct();
error VL_BadStrike();
error VL_BadStrikeAddress();
error VL_BadSupply();
error VL_BadToken();
error VL_BadUnderlyingAddress();
error VL_BadWeight();
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_Overflow();
error VL_Unauthorized();

// ShareMath
error SM_NPSLow();
error SM_Overflow();

// BatchAuction
error BA_AuctionClosed();
error BA_AuctionNotClosed();
error BA_AuctionSettled();
error BA_AuctionUnsettled();
error BA_BadAddress();
error BA_BadAmount();
error BA_BadBiddingAddress();
error BA_BadCollateral();
error BA_BadOptionAddress();
error BA_BadOptions();
error BA_BadPrice();
error BA_BadSize();
error BA_BadTime();
error BA_EmptyAuction();
error BA_Unauthorized();
error BA_Uninitialized();

// Whitelist
error WL_BadAddress();
error WL_BadRole();
error WL_Paused();
error WL_Unauthorized();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { Vault } from "./Vault.sol";
import "../libraries/Errors.sol";

library ShareMath {
    using FixedPointMathLib for uint256;

    function navToShares(uint256 nav, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= Vault.PLACEHOLDER_UINT) revert SM_NPSLow();

        return nav.mulDivDown(Vault.UNIT, navPerShare);
    }

    function sharesToNAV(uint256 shares, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= Vault.PLACEHOLDER_UINT) revert SM_NPSLow();

        return shares.mulDivDown(navPerShare, Vault.UNIT);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param navPerShare is the price in asset per share
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 navPerShare,
        uint256 depositNAV
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = navToShares(depositNAV, navPerShare);

            return uint256(depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return depositReceipt.unredeemedShares;
    }

    function pricePerShare(uint256 totalSupply, uint256 totalBalanceNAV, uint256 pendingNAV) internal pure returns (uint256) {
        return totalSupply > 0 ? (totalBalanceNAV - pendingNAV).mulDivDown(Vault.UNIT, totalSupply) : Vault.UNIT;
    }

    /**
     *
     *  HELPERS
     *
     */

    function assertUint104(uint256 num) internal pure {
        if (num > type(uint104).max) revert SM_Overflow();
    }

    function assertUint128(uint256 num) internal pure {
        if (num > type(uint128).max) revert SM_Overflow();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { TokenType } from "../../lib/grappa/src/config/enums.sol";

library Vault {
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    // Fees are 18-decimal places. For example: 20 * 10**18 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10 ** 18;

    // Otokens have 6 decimal places.
    uint256 internal constant DECIMALS = 6;

    // Otokens have 6 decimal places.
    uint256 internal constant UNIT = 10 ** 6;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _auctionDuration is the duration of the gnosis auction
     * @param _instruments linear combination of options
     */
    struct InitParams {
        address _owner;
        address _manager;
        address _feeRecipient;
        address _oracle;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        address _vaultPauser;
        address _batchAuction;
        Instrument[] _instruments;
        Collateral[] _collaterals;
        uint256 _auctionDuration;
        uint256 _leverageRatio;
        RoundConfig _roundConfig;
    }

    struct Collateral {
        // Grappa asset Id
        uint8 id;
        // ERC20 token address for the required collateral
        address addr;
        // the amount of decimals or token
        uint8 decimals;
    }

    struct Instrument {
        TokenType tokenType;
        // Indicated how much the vault is short or long this instrument in a structure
        int64 weight;
        // oracle for product
        address oracle;
        // Underlying asset of the options
        address underlying;
        // asset that the strike price is denominated in
        address strike;
        // Asset backing the option
        address collateral;
    }

    struct VaultParams {
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct OptionState {
        // Option that the vault is shorting / longing in the next cycle
        uint256[] nextOptions;
        // Option that the vault is currently shorting / longing
        uint256[] currentOptions;
        // Current premium per structure
        int256 premium;
        // Max number of structures possible to sell based on
        // = lockedBalance * leverageRatio
        uint256 maxStructures;
        // Total structures minted this round
        uint256 mintedStructures;
        // Amount of collateral required by the vault per structure
        uint256[] vault;
        // Amount of collateral required by the counterparty per structure
        uint256[] counterparty;
    }

    struct VaultState {
        // 32 byte slot 1
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint vault tokens
        uint128 totalPending;
        // store the number of shares queued for withdraw this round
        // zero'ed out at the start of each round, pauser withdraws all queued shares.
        uint128 queuedWithdrawShares;
    }

    struct DepositReceipt {
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct RoundConfig {
        // the duration of the auction
        uint32 duration;
        // day of the week the auction should begin. 0-8, 0 is sunday, 7 is sunday, 8 is wild
        uint8 dayOfWeek;
        // hour of the day the auction should begin. 0 is midnight
        uint8 hourOfDay;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { TokenIdUtil } from "../../lib/grappa/src/libraries/TokenIdUtil.sol";
import { ProductIdUtil } from "../../lib/grappa/src/libraries/ProductIdUtil.sol";
import { ActionUtil } from "../../lib/grappa/src/libraries/ActionUtil.sol";
import { AccountUtil } from "../../lib/grappa/src/core/engines/cross-margin/AccountUtil.sol";
import { TokenType, ActionType } from "../../lib/grappa/src/config/enums.sol";

import { Vault } from "./Vault.sol";
import { ShareMath } from "./ShareMath.sol";

import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { IBatchAuction } from "../interfaces/IBatchAuction.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";
import "../interfaces/GrappaInterfaces.sol";

import "./Errors.sol";

library VaultUtil {
    using AccountUtil for MarginEngine.Position[];
    using ActionUtil for Grappa.ActionArgs[];
    using ActionUtil for Grappa.BatchExecute[];
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Detailed;
    using SafeMath for uint256;
    using TokenIdUtil for uint256;
    using ProductIdUtil for uint40;

    /**
     * @dev structure used in memory to close a round
     */
    struct CloseParams {
        uint256 currentShareSupply;
        uint256 queuedWithdrawShares;
        uint256 managementFee;
        uint256 performanceFee;
        address feeRecipient;
        address oracleAddr;
        Vault.Collateral[] collaterals;
        uint256[] roundStartingBalances;
        uint256 expiry;
    }

    /**
     * @dev structure used in memory to start an auction
     */
    struct AuctionParams {
        address auctionAddr;
        address premiumToken;
        Vault.Collateral[] collaterals;
        uint256[] counterparty;
        uint256 duration;
        address engineAddr;
        uint256 maxStructures;
        uint256[] options;
        int256 premium;
        uint256 structures;
        address whitelist;
    }

    /**
     * @dev structure used in memory to mint structures in grappa
     */
    struct CreateStructuresParams {
        address batchAuctionAddr;
        Vault.Collateral[] collaterals;
        uint256[] counterparty;
        address engineAddr;
        Vault.Instrument[] instruments;
        uint256[] options;
        uint256 structuresToMint;
        uint256 maxStructures;
        uint256[] vault;
    }

    /**
     * @notice Sets the next option the vault will be writing
     * @param engineAddr is the address of the margin engine
     * @param strikes is the new prices for each instruments
     * @param instruments is the linear combination of options
     * @param roundConfig the round configuration
     * @return options is the ids of the new options
     */
    function stageStructure(
        address engineAddr,
        uint256[] calldata strikes,
        Vault.Instrument[] calldata instruments,
        Vault.RoundConfig storage roundConfig
    ) external view returns (uint256[] memory options, uint256 expiry) {
        if (strikes.length != instruments.length) revert VL_BadStrike();

        IMarginEngine engine = IMarginEngine(engineAddr);
        IGrappa grappa = IGrappa(engine.grappa());

        expiry = getNextExpiry(roundConfig);

        options = new uint256[](instruments.length);

        for (uint256 i = 0; i < instruments.length; i++) {
            uint40 productId = grappa.getProductId(
                instruments[i].oracle, engineAddr, instruments[i].underlying, instruments[i].strike, instruments[i].collateral
            );

            verifyProduct(productId, grappa, engine, instruments[i]);

            uint256 strike = strikes[i];

            options[i] = TokenIdUtil.getTokenId(instruments[i].tokenType, productId, expiry, strike, 0);
        }
    }

    /**
     * @notice Verify the productId has the correct oracle, engine and assets
     * @param productId is the struct with details on previous option and strike selection details
     * @param grappa interface to grappa
     * @param marginEngine interface to margin engine
     * @param instrument is the struct with vault general data
     */
    function verifyProduct(uint40 productId, IGrappa grappa, IMarginEngine marginEngine, Vault.Instrument calldata instrument)
        private
        view
    {
        if (address(grappa) == address(0)) revert VL_BadGrappaAddress();
        if (productId == 0) revert VL_BadProduct();

        (address oracle, address engine, address underlying,, address strike,, address collateral, uint8 collateralDecimals) =
            grappa.getDetailFromProductId(productId);

        if (oracle != instrument.oracle) revert VL_BadOracleAddress();
        if (engine != address(marginEngine)) revert VL_BadGrappaAddress();
        if (underlying != instrument.underlying) {
            revert VL_BadUnderlyingAddress();
        }
        if (strike != instrument.strike) revert VL_BadStrikeAddress();
        if (collateral != instrument.collateral) {
            revert VL_BadCollateralAddress();
        }
        if (collateralDecimals != IERC20Detailed(collateral).decimals()) {
            revert VL_BadPrecision();
        }
    }

    /**
     * @notice Closes round by collecting fees, calculating PPS and number of new shares to mint
     * @param vaultState is the storage variable vaultState passed from HashnoteVault
     * @param params is the parameters passed to compute the next state
     * @return currentBalances is the balances of each asset at the start of the round
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return totalFees is the amount of fees paid in each asset
     * @return perforamceFees is the amount of performance fees paid in each asset
     */
    function closeRound(Vault.VaultState storage vaultState, CloseParams calldata params)
        external
        returns (
            uint256[] memory currentBalances,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256[] memory totalFees,
            uint256[] memory perforamceFees
        )
    {
        uint256 currentNAV;
        uint256 pendingNAV;

        // calculate and transfer round fees
        (currentBalances, totalFees, perforamceFees) = processFees(params, vaultState.totalPending);

        // net asset value held by the vault and that of deposits pending inclusion (pendingNAV is a subset of currentNAV)
        (currentNAV, pendingNAV) = _calculateNAV(vaultState, params);

        // rounds price per share based on assets used in last round and total supply
        newPricePerShare = ShareMath.pricePerShare(params.currentShareSupply, currentNAV, pendingNAV);

        // after settling positions, if the options expire in-the-money (ITM) vault PPS will go down due to decrease in NAV
        // newly minted shares do not take on the loss
        mintShares = ShareMath.navToShares(pendingNAV, newPricePerShare);
    }

    /**
     * @notice calculates Net Asset Value of all the assets held by vault as well as the pending deposits
     */
    function _calculateNAV(Vault.VaultState storage vaultState, CloseParams calldata params)
        internal
        view
        returns (uint256 currentNAV, uint256 pendingNAV)
    {
        (currentNAV) = calculateTotalBalanceNAV(params.oracleAddr, params.collaterals, params.expiry);

        pendingNAV = uint256(vaultState.totalPending);

        if (pendingNAV > 0) {
            pendingNAV = calculateRelativeNAV(
                params.oracleAddr, params.collaterals, params.roundStartingBalances, pendingNAV, params.expiry
            );
        }
    }

    /**
     * @notice Creates the Grappa option position
     * @dev depositings collateral on behalf of vault and counterparty
     * @dev counterparty positions are held in the vaults sub account until bidders novate their portion
     */
    function createStructures(CreateStructuresParams memory params) external returns (uint256[] memory depositAmounts) {
        // if set then premium paid by vault, removing allowance incase it wasnt fully used in auction
        if (params.batchAuctionAddr != address(0)) {
            IERC20(params.collaterals[0].addr).safeApprove(params.batchAuctionAddr, 0);
        }

        IMarginEngine engine = IMarginEngine(params.engineAddr);

        Grappa.ActionArgs[] memory vActions;
        Grappa.ActionArgs[] memory cpActions;

        // vaults collateral deposit action
        (vActions, depositAmounts) = _createMarginDepositActions(
            params.engineAddr, params.structuresToMint, params.maxStructures, params.collaterals, params.vault
        );

        // counterparty collateral deposit action
        (cpActions,) = _createMarginDepositActions(
            params.engineAddr, params.structuresToMint, params.maxStructures, params.collaterals, params.counterparty
        );

        // vault sub account to store counterparty position
        address cpSubAccount = address(uint160(address(this)) ^ uint160(1));

        for (uint256 i; i < params.options.length;) {
            Vault.Instrument memory instrument = params.instruments[i];

            uint256 option = params.options[i];

            // number of options to mint given total structured sold in last auction
            uint256 amount = params.structuresToMint.mulDivDown(_toUint256(instrument.weight), Vault.UNIT);

            // vault receives positive weighted instruments (vault is long)
            // counterparty receives negative weighted instruments (vault is short)
            if (instrument.weight < 0) {
                vActions = vActions.append(ActionUtil.createMintIntoAccountAction(option, amount, cpSubAccount));
            } else {
                cpActions = cpActions.append(ActionUtil.createMintIntoAccountAction(option, amount, address(this)));
            }

            unchecked {
                ++i;
            }
        }

        Grappa.BatchExecute[] memory batch = new Grappa.BatchExecute[](1);

        // batch execute vault actions
        batch[0] = Grappa.BatchExecute(address(this), vActions);

        if (cpActions.length != 0) {
            // batch execute counterparty actions
            batch = batch.append(Grappa.BatchExecute(cpSubAccount, cpActions));
        }

        engine.batchExecute(batch);
    }

    /**
     * @notice Helper function to setup deposit collateral action
     * @dev calculates collateral deposit based on total structures sold in last auction
     * @dev increases margin engines allowance to pull funds across vault + counterparty deposit actions
     * @return actions array of collateral deposits
     * @return amounts of asset desposited
     */
    function _createMarginDepositActions(
        address engineAddr,
        uint256 structuresToMint,
        uint256 maxStructures,
        Vault.Collateral[] memory collaterals,
        uint256[] memory balances
    ) private returns (Grappa.ActionArgs[] memory actions, uint256[] memory amounts) {
        actions = new Grappa.ActionArgs[](balances.length);

        amounts = new uint256[](balances.length);

        for (uint256 i; i < balances.length;) {
            amounts[i] = structuresToMint.mulDivDown(balances[i], maxStructures);

            IERC20(collaterals[i].addr).safeIncreaseAllowance(engineAddr, amounts[i]);

            actions[i] = ActionUtil.createAddCollateralAction(collaterals[i].id, amounts[i], address(this));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice transfers bidders winnings from vault sub account
     * @dev calculates bidders portion based on how much of their bids were filled
     */
    function novate(
        address engineAddr,
        Vault.Instrument[] memory instruments,
        uint256[] memory options,
        Vault.Collateral[] memory collaterals,
        uint256[] memory counterparty,
        address recipient,
        uint256 amount
    ) external {
        IMarginEngine engine = IMarginEngine(engineAddr);

        // vault sub account that custodies counterparty side of trade
        // bidders can claim any time after the auction settles
        address cpSubAccount = address(uint160(address(this)) ^ uint160(1));

        Grappa.ActionArgs[] memory collateralActions = new Grappa.ActionArgs[](0);
        Grappa.ActionArgs[] memory longActions = new Grappa.ActionArgs[](0);
        Grappa.ActionArgs[] memory shortActions = new Grappa.ActionArgs[](0);

        uint256 i;
        for (i; i < counterparty.length;) {
            uint256 collateralAmount = amount.mulDivDown(counterparty[i], Vault.UNIT);

            collateralActions = collateralActions.append(
                ActionUtil.createTransferCollateralAction(collaterals[i].id, collateralAmount, recipient)
            );

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < instruments.length;) {
            Vault.Instrument memory instrument = instruments[i];

            uint256 option = options[i];

            uint256 numOfOptions = amount.mulDivDown(_toUint256(instrument.weight), Vault.UNIT);

            // counterparty is long negative instruments
            // counterparty is short positive instruments
            if (instrument.weight < 0) {
                longActions = longActions.append(ActionUtil.createTranferLongAction(option, numOfOptions, recipient));
            } else {
                shortActions = shortActions.append(ActionUtil.createTranferShortAction(option, numOfOptions, recipient));
            }

            unchecked {
                ++i;
            }
        }

        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](0);

        if (collateralActions.length != 0) actions = actions.concat(collateralActions);
        if (longActions.length != 0) actions = actions.concat(longActions);
        if (shortActions.length != 0) actions = actions.concat(shortActions);

        // if actions is empty dont execute
        if (actions.length != 0) engine.execute(cpSubAccount, actions);
    }

    /**
     * @notice Settles the vaults position(s) in grappa.
     * @param engineAddress is the address of the grappa margin engine contract
     * @return withdrawAmounts is the amounts returned to the vault
     */
    function settleOptions(address engineAddress) external returns (uint256[] memory withdrawAmounts) {
        IMarginEngine engine = IMarginEngine(engineAddress);

        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](1);

        actions[0] = ActionUtil.createSettleAction();

        engine.execute(address(this), actions);

        // gets the accounts collateral balances
        (,, Grappa.Balance[] memory collaterals) = engine.marginAccounts(address(this));

        actions = new Grappa.ActionArgs[](collaterals.length);
        withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] =
                ActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, collaterals[i].amount, address(this));

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        if (actions.length != 0) engine.execute(address(this), actions);
    }

    /**
     * @notice calculates Net Asset Value of all the assets held by the vault
     * @dev this includes assts in the vault as well as pending deposits
     */
    function calculateTotalBalanceNAV(address oracleAddr, Vault.Collateral[] calldata collaterals, uint256 expiry)
        public
        view
        returns (uint256 totalNAV)
    {
        // primary asset that all other assets will be quotes in
        address quote = collaterals[0].addr;

        for (uint256 i; i < collaterals.length;) {
            uint256 price = Vault.UNIT;

            // if collateral is primary asset, leave price as 1 (scale 1e6)
            if (collaterals[i].addr != quote) {
                price = _getPrice(oracleAddr, collaterals[i].addr, quote, expiry);
            }

            uint256 balance = IERC20(collaterals[i].addr).balanceOf(address(this));

            // sum of all asset(s) NAV
            totalNAV += price.mulDivDown(balance, 10 ** collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice calculates relative Net Asset Value based on the primary asset and a rounds starting balanace(s)
     * @dev used in pending deposits (per account and in aggregate)
     */
    function calculateRelativeNAV(
        address oracleAddr,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata roundStartingBalances,
        uint256 primaryDeposited,
        uint256 expiry
    ) public view returns (uint256 totalNAV) {
        // primary collateral addr, all other assets will be quotes in this
        address quote = collaterals[0].addr;

        // primary asset amount used to calculating the amount of secondary assets deposted in the round
        uint256 primaryTotal = roundStartingBalances[0];

        for (uint256 i; i < collaterals.length;) {
            uint256 price = Vault.UNIT;

            if (collaterals[i].addr != quote) {
                price = _getPrice(oracleAddr, collaterals[i].addr, quote, expiry);
            }

            uint256 balance = roundStartingBalances[i].mulDivDown(primaryDeposited, primaryTotal);

            totalNAV += price.mulDivDown(balance, 10 ** collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Queries total balance(s) of collateral
     * @dev used in processFees
     */
    function getCurrentBalances(Vault.Collateral[] calldata collaterals) public view returns (uint256[] memory balances) {
        balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            balances[i] = IERC20(collaterals[i].addr).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice get spot price of base, denominated in quote.
     * @dev used in Net Asset Value calculations
     * @dev
     * @param oracleAddr Chainlink Oracle for Grappa options
     * @param base base asset. for ETH/USD price, ETH is the base asset
     * @param quote quote asset. for ETH/USD price, USD is the quote asset
     * @param expiry price at a given timestamp
     * @return price with 6 decimals
     */
    function _getPrice(address oracleAddr, address base, address quote, uint256 expiry) internal view returns (uint256 price) {
        IOracle oracle = IOracle(oracleAddr);

        // if timestamp is the placeholder (1) then get the spot
        if (expiry == Vault.PLACEHOLDER_UINT) {
            price = oracle.getSpotPrice(base, quote);
        } else {
            (price,) = oracle.getPriceAtExpiry(base, quote, expiry);
        }
    }

    /**
     * @notice Transfers assets between account holder and vault
     */
    function transferAssets(
        uint256 primaryDeposit,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata roundStartingBalances,
        address recipient
    ) public returns (uint256[] memory amounts) {
        // primary asset amount used to calculating the amount of secondary assets deposted in the round
        uint256 primaryTotal = roundStartingBalances[0];

        bool isWithdraw = recipient != address(this);

        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = roundStartingBalances[i];

            if (isWithdraw) {
                amounts[i] = balance.mulDivDown(primaryDeposit, primaryTotal);
            } else {
                amounts[i] = balance.mulDivUp(primaryDeposit, primaryTotal);
            }

            if (amounts[i] != 0) {
                if (isWithdraw) {
                    IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
                } else {
                    IERC20(collaterals[i].addr).safeTransferFrom(msg.sender, recipient, amounts[i]);
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Rebalances assets
     * @dev will only allow surplus assets to be exchanged
     */
    function rebalance(
        address otc,
        uint256[] calldata amounts,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata vault,
        address whitelist
    ) external {
        if (collaterals.length != amounts.length) revert VL_DifferentLengths();

        if (!IWhitelist(whitelist).isOTC(otc)) revert VL_Unauthorized();

        for (uint256 i; i < collaterals.length;) {
            if (amounts[i] != 0) {
                IERC20 asset = IERC20(collaterals[i].addr);

                uint256 surplus = asset.balanceOf(address(this)) - vault[i];

                if (amounts[i] > surplus) revert VL_ExceedsSurplus();

                asset.safeTransfer(otc, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Processes withdrawing assets based on shares
     * @dev used to send assets to the pauser at the end of each round
     */
    function withdrawWithShares(address recipient, uint256 shares, uint256 totalSupply, Vault.Collateral[] calldata collaterals)
        external
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = IERC20(collaterals[i].addr).balanceOf(address(this));

            amounts[i] = balance.mulDivDown(shares, totalSupply);

            if (amounts[i] != 0) {
                IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates the management and performance fee for the current round
     * @param params CloseParams passed to closeRound
     * @param pendingAmount is the pending deposit amount
     * @return currentBalances is the asset balances at the start of the next round
     * @return totalFees is the amounts paid in each asset
     * @return perforamceFees is the amounts paid in each asset
     */
    function processFees(CloseParams calldata params, uint256 pendingAmount)
        public
        returns (uint256[] memory currentBalances, uint256[] memory totalFees, uint256[] memory perforamceFees)
    {
        currentBalances = getCurrentBalances(params.collaterals);

        totalFees = new uint256[](currentBalances.length);
        perforamceFees = new uint256[](currentBalances.length);

        // primary asset amount used to calculating the amount of secondary assets deposted in the round
        uint256 primaryTotal = params.roundStartingBalances[0];

        for (uint256 i; i < currentBalances.length;) {
            uint256 lockedBalanceSansPending;
            uint256 managementFeeInAsset;
            uint256 performanceFeeInAsset;

            uint256 currentBalance = currentBalances[i];

            uint256 pendingBalance = params.roundStartingBalances[i].mulDivDown(pendingAmount, primaryTotal);

            // At round 1, currentBalance is 0 and pendingAmount > 0, we do not take on the first round
            if (currentBalance > pendingBalance) {
                lockedBalanceSansPending = currentBalance.sub(pendingBalance);
            }

            managementFeeInAsset = lockedBalanceSansPending.mulDivDown(params.managementFee, 100 * Vault.FEE_MULTIPLIER);

            // Performance fee proceesed ONLY if difference between starting balance(s) and ending
            // balance(s) (excluding pending depositing) is positive
            // If the balance is negative, the the round did not profit.
            if (lockedBalanceSansPending > params.roundStartingBalances[i]) {
                if (params.performanceFee != 0) {
                    uint256 performanceAmount = lockedBalanceSansPending.sub(params.roundStartingBalances[i]);

                    performanceFeeInAsset = performanceAmount.mulDivDown(params.performanceFee, 100 * Vault.FEE_MULTIPLIER);

                    perforamceFees[i] = performanceFeeInAsset;
                }
            }

            totalFees[i] = managementFeeInAsset + performanceFeeInAsset;

            if (totalFees[i] != 0) {
                // deducting fees from current balances
                currentBalances[i] -= totalFees[i];

                IERC20(params.collaterals[i].addr).safeTransfer(params.feeRecipient, totalFees[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Starts the Batch Auction
     * @param params is the struct with all the parameters of the auction
     * @return auctionId the auction id of the newly created auction
     */
    function startAuction(AuctionParams calldata params) external returns (uint256 auctionId) {
        if (params.structures > type(uint64).max) revert VL_Overflow();

        uint256 unsignedPremium = _toUint256(params.premium);

        IERC20Detailed premiumToken = IERC20Detailed(params.premiumToken);

        int256 premium;

        {
            uint256 decimals = premiumToken.decimals();

            unsignedPremium = decimals > 18
                ? unsignedPremium.mul(10 ** (decimals.sub(18)))
                : unsignedPremium.div(10 ** (uint256(18).sub(decimals)));

            premium = params.premium < 0 ? -int256(unsignedPremium) : int256(unsignedPremium);
        }

        if (premium < 0) {
            premiumToken.safeApprove(params.auctionAddr, unsignedPremium.mulDivUp(params.structures, Vault.UNIT));
        }

        auctionId = IBatchAuction(params.auctionAddr).createAuction(
            IMarginEngine(params.engineAddr).optionToken(),
            params.options,
            params.premiumToken,
            _marginCollateralsToAuctionCollaterals(params.collaterals, params.counterparty, params.maxStructures),
            premium,
            1,
            params.structures,
            block.timestamp.add(params.duration),
            params.whitelist
        );
    }

    /**
     * @notice helper function to convert Vault.Collateral to IBatchAuction.Collateral
     */
    function _marginCollateralsToAuctionCollaterals(
        Vault.Collateral[] calldata vaultCollaterals,
        uint256[] calldata balances,
        uint256 maxStructures
    ) internal pure returns (IBatchAuction.Collateral[] memory collaterals) {
        collaterals = new IBatchAuction.Collateral[](balances.length);

        for (uint256 i; i < balances.length;) {
            uint256 amount = balances[i].mulDivUp(Vault.UNIT, maxStructures);

            if (amount > type(uint80).max) revert VL_Overflow();

            collaterals[i] = IBatchAuction.Collateral(vaultCollaterals[i].addr, uint80(amount));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param initParams is the struct with vault general data
     * @param vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(Vault.InitParams calldata initParams, Vault.VaultParams calldata vaultParams)
        external
        pure
    {
        if (initParams._owner == address(0)) revert VL_BadOwnerAddress();
        if (initParams._manager == address(0)) revert VL_BadManagerAddress();
        if (initParams._feeRecipient == address(0)) revert VL_BadFeeAddress();
        if (initParams._oracle == address(0)) revert VL_BadOracleAddress();
        if (initParams._vaultPauser == address(0)) revert VL_BadPauserAddress();
        if (initParams._performanceFee > 100 * Vault.FEE_MULTIPLIER || initParams._managementFee > 100 * Vault.FEE_MULTIPLIER) {
            revert VL_BadFee();
        }
        if (bytes(initParams._tokenName).length == 0 || bytes(initParams._tokenSymbol).length == 0) {
            revert VL_BadToken();
        }

        if (initParams._instruments.length == 0) revert VL_BadInstruments();

        for (uint256 i; i < initParams._instruments.length;) {
            if (initParams._instruments[i].weight == 0) revert VL_BadWeight();
            if (initParams._instruments[i].oracle == address(0)) {
                revert VL_BadOracleAddress();
            }
            if (initParams._instruments[i].underlying == address(0)) {
                revert VL_BadUnderlyingAddress();
            }
            if (initParams._instruments[i].strike == address(0)) {
                revert VL_BadStrikeAddress();
            }
            if (initParams._instruments[i].collateral == address(0)) {
                revert VL_BadCollateralAddress();
            }

            unchecked {
                ++i;
            }
        }

        if (initParams._collaterals.length == 0) revert VL_BadCollateral();
        for (uint256 i; i < initParams._collaterals.length;) {
            if (initParams._collaterals[i].id == 0) revert VL_BadCollateral();
            if (initParams._collaterals[i].addr == address(0)) {
                revert VL_BadCollateralAddress();
            }
            if (initParams._collaterals[i].decimals == 0) {
                revert VL_BadPrecision();
            }

            unchecked {
                ++i;
            }
        }

        if (vaultParams.minimumSupply == 0) revert VL_BadSupply();
        if (vaultParams.cap == 0) revert VL_BadCap();
        if (vaultParams.cap <= vaultParams.minimumSupply) revert VL_BadCap();

        if (
            initParams._roundConfig.duration == 0 || initParams._roundConfig.dayOfWeek > 8
                || initParams._roundConfig.hourOfDay >= 24
        ) revert VL_BadDuration();
    }

    /**
     * @notice Gets the next option expiry from the given timestamp
     * @param roundConfig the configuration used to calculate the option expiry
     */
    function getNextExpiry(Vault.RoundConfig storage roundConfig) internal view returns (uint256 nextTime) {
        uint256 offset = block.timestamp + roundConfig.duration;

        // The offset will always be greater than the options expiry, so we subtract a week in order to get the day the option should expire, or subtract a day to get the hour the option should start if the dayOfWeek is wild (8)
        if (roundConfig.dayOfWeek != 8) offset -= 1 weeks;
        else offset -= 1 days;

        nextTime = getNextDayTimeOfWeek(offset, roundConfig.dayOfWeek, roundConfig.hourOfDay);

        //if timestamp is in the past relative to the offset, it means we've tried to calculate an expiry of an option which has too short of length. I.e trying to run a 1 day option on a Tuesday which should expire Friday
        if (nextTime < offset) revert VL_BadExpiryDate();
    }

    /**
     * @notice Calculates the next day/hour of the week
     * @param timestamp is the expiry timestamp of the current option
     * @param dayOfWeek is the day of the week we're looking for (sun:0/7 - sat:6), 8 will be treated as disabled and the next available hourOfDay will be returned
     * @param hourOfDay is the next hour of the day we want to expire on (midnight:0)
     *
     * Examples when day = 5, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday) -> week 2 friday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 2 friday:0800
     *
     * Examples when day = 7, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0500) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0900) -> week 1 saturday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 1 sunday:0800
     */
    function getNextDayTimeOfWeek(uint256 timestamp, uint256 dayOfWeek, uint256 hourOfDay)
        internal
        pure
        returns (uint256 nextStartTime)
    {
        // we want sunday to have a value of 7
        if (dayOfWeek == 0) dayOfWeek = 7;

        // dayOfWeek = 0 (sunday) - 6 (saturday) calculated from epoch time
        uint256 timestampDayOfWeek = ((timestamp / 1 days) + 4) % 7;
        //Calculate the nextDayOfWeek by figuring out how much time is between now and then in seconds
        uint256 nextDayOfWeek =
            timestamp + ((7 + (dayOfWeek == 8 ? timestampDayOfWeek : dayOfWeek) - timestampDayOfWeek) % 7) * 1 days;
        //Calculate the nextStartTime by removing the seconds past midnight, then adding the amount seconds after midnight we wish to start
        nextStartTime = nextDayOfWeek - (nextDayOfWeek % 24 hours) + (hourOfDay * 1 hours);

        // If the date has passed, we simply increment it by a week to get the next dayOfWeek, or by a day if we only want the next hourOfDay
        if (timestamp >= nextStartTime) {
            if (dayOfWeek == 8) nextStartTime += 1 days;
            else nextStartTime += 7 days;
        }
    }

    /**
     * @notice helper function to convert int256 to uint256
     */
    function _toUint256(int256 variable) internal pure returns (uint256) {
        if (variable < 0) return uint256(-variable);
        else return uint256(variable);
    }
}