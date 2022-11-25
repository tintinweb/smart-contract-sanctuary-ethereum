// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStrategy {
    function rebalance()
        external
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        );

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function feeCollector() external view returns (address);

    function isReservedToken(address _token) external view returns (bool);

    function keepers() external view returns (address[] memory);

    function migrate(address _newStrategy) external;

    function token() external view returns (address);

    function pool() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function VERSION() external view returns (string memory);

    function collateral() external view returns (address);
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Pausable interface
 */
interface IPausable {
    function paused() external view returns (bool);

    function stopEverything() external view returns (bool);

    function pause() external;

    function unpause() external;

    function shutdown() external;

    function open() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IGovernable.sol";
import "./IPausable.sol";

interface IVesperPool is IGovernable, IPausable, IERC20Metadata {
    function calculateUniversalFee(uint256 _profit) external view returns (uint256 _fee);

    function deposit(uint256 _share) external;

    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool);

    function excessDebt(address _strategy) external view returns (uint256);

    function poolAccountant() external view returns (address);

    function poolRewards() external view returns (address);

    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external;

    function reportLoss(uint256 _loss) external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function keepers() external view returns (address[] memory);

    function isKeeper(address _address) external view returns (bool);

    function maintainers() external view returns (address[] memory);

    function isMaintainer(address _address) external view returns (bool);

    function pricePerShare() external view returns (uint256);

    function strategy(address _strategy)
        external
        view
        returns (
            bool _active,
            uint256 _interestFee, // Obsolete
            uint256 _debtRate, // Obsolete
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio,
            uint256 _externalDepositFee
        );

    function token() external view returns (IERC20);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address _strategy) external view returns (uint256);

    function totalValue() external view returns (uint256);

    function totalDebt() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase
// solhint-disable func-name-mixedcase

pragma solidity 0.8.9;

interface IConvexFraxPoolRegistry {
    function poolInfo(uint256)
        external
        view
        returns (
            address implementation,
            address stakingAddress,
            address stakingToken,
            address rewardsAddress,
            uint8 active
        );
}

interface IVaultRegistry {
    function createVault(uint256 _pid) external returns (address);
}

interface IProxyVault {
    function initialize(
        address _owner,
        address _stakingAddress,
        address _stakingToken,
        address _rewardsAddress
    ) external;

    function usingProxy() external returns (address);

    function owner() external returns (address);

    function stakingAddress() external returns (address);

    function rewards() external returns (address);

    function getReward() external;

    function getReward(bool _claim) external;

    function getReward(bool _claim, address[] calldata _rewardTokenList) external;

    function earned() external view returns (address[] memory token_addresses, uint256[] memory total_earned);
}

interface IStakingProxyBase is IProxyVault {
    //farming contract
    function stakingAddress() external view returns (address);

    //farming token
    function stakingToken() external view returns (address);

    function vaultVersion() external pure returns (uint256);
}

interface IStakingProxyConvex is IStakingProxyBase {
    function curveLpToken() external view returns (address);

    function convexDepositToken() external view returns (address);

    //create a new locked state of _secs timelength with a Curve LP token
    function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

    //create a new locked state of _secs timelength with a Convex deposit token
    function stakeLockedConvexToken(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

    //create a new locked state of _secs timelength
    function stakeLocked(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

    //add to a current lock
    function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external;

    //add to a current lock
    function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external;

    //add to a current lock
    function lockAdditionalConvexToken(bytes32 _kek_id, uint256 _addl_liq) external;

    // Extends the lock of an existing stake
    function lockLonger(bytes32 _kek_id, uint256 new_ending_ts) external;

    //withdraw a staked position
    //frax farm transfers first before updating farm state so will checkpoint during transfer
    function withdrawLocked(bytes32 _kek_id) external;

    //withdraw a staked position
    //frax farm transfers first before updating farm state so will checkpoint during transfer
    function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

    //helper function to combine earned tokens on staking contract and any tokens that are on this vault
    function earned() external view override returns (address[] memory token_addresses, uint256[] memory total_earned);
}

interface IFraxFarmERC20 {
    event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);

    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function owner() external view returns (address);

    function stakingToken() external view returns (address);

    function fraxPerLPToken() external view returns (uint256);

    function calcCurCombinedWeight(address account)
        external
        view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        );

    function lockedStakesOf(address account) external view returns (LockedStake[] memory);

    function lockedStakesOfLength(address account) external view returns (uint256);

    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;

    function lockLonger(bytes32 kek_id, uint256 new_ending_ts) external;

    function stakeLocked(uint256 liquidity, uint256 secs) external returns (bytes32);

    function withdrawLocked(bytes32 kek_id, address destination_address) external returns (uint256);

    function periodFinish() external view returns (uint256);

    function getAllRewardTokens() external view returns (address[] memory);

    function earned(address account) external view returns (uint256[] memory new_earned);

    function totalLiquidityLocked() external view returns (uint256);

    function lockedLiquidityOf(address account) external view returns (uint256);

    function totalCombinedWeight() external view returns (uint256);

    function combinedWeightOf(address account) external view returns (uint256);

    function lockMultiplier(uint256 secs) external view returns (uint256);

    function lock_time_min() external view returns (uint256);

    function rewardRates(uint256 token_idx) external view returns (uint256 rwd_rate);

    function userStakedFrax(address account) external view returns (uint256);

    function proxyStakedFrax(address proxy_address) external view returns (uint256);

    function maxLPForMaxBoost(address account) external view returns (uint256);

    function minVeFXSForMaxBoost(address account) external view returns (uint256);

    function minVeFXSForMaxBoostProxy(address proxy_address) external view returns (uint256);

    function veFXSMultiplier(address account) external view returns (uint256 vefxs_multiplier);

    function toggleValidVeFXSProxy(address proxy_address) external;

    function proxyToggleStaker(address staker_address) external;

    function stakerSetVeFXSProxy(address proxy_address) external;

    function getReward(address destination_address) external returns (uint256[] memory);

    function vefxs_max_multiplier() external view returns (uint256);

    function vefxs_boost_scale_factor() external view returns (uint256);

    function vefxs_per_frax_for_max_boost() external view returns (uint256);

    function getProxyFor(address addr) external view returns (address);

    function sync() external;
}

interface IMultiReward {
    function poolId() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardTokenLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address) external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

interface IAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

interface IDeposit2x {
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;
}

interface IDeposit3x {
    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;
}

interface IDeposit4x {
    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] memory _min_amounts) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[4] memory _amounts, bool is_deposit) external view returns (uint256);

    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

interface IDepositZap {
    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amount
    ) external;

    function calc_withdraw_one_coin(
        address _pool,
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);
}

interface IDepositZap3x is IDepositZap {
    function calc_token_amount(
        address _pool,
        uint256[3] memory _amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        address _pool,
        uint256[3] memory _deposit_amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity(
        address _pool,
        uint256 _burn_amount,
        uint256[3] memory _min_amounts
    ) external;
}

interface IDepositZap4x is IDepositZap {
    function calc_token_amount(
        address _pool,
        uint256[4] memory _amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        address _pool,
        uint256[4] memory _amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity(
        address _pool,
        uint256 _amount,
        uint256[4] memory _min_amounts
    ) external;
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

// Not a complete interface, but should have what we need
interface ILiquidityGaugeV2 is IERC20 {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function withdraw(uint256 _value) external;

    function claim_rewards(address addr) external;

    function claim_rewards() external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address, address) external returns (uint256);

    function integrate_fraction(address addr) external view returns (uint256);

    function user_checkpoint(address addr) external returns (bool);

    function reward_integral(address) external view returns (uint256);

    function reward_integral_for(address, address) external view returns (uint256);

    function lp_token() external view returns (address);

    function reward_count() external view returns (uint256);

    function reward_tokens(uint256 _i) external view returns (address);
}

interface ILiquidityGaugeV3 is ILiquidityGaugeV2 {
    function claimable_reward(address addr, address token) external view override returns (uint256);

    function claimable_reward_write(address addr, address token) external returns (uint256);
}

/* solhint-enable */

// SPDX-License-Identifier: MIT

/* solhint-disable func-name-mixedcase*/
pragma solidity 0.8.9;

interface IMetapoolFactory {
    function get_underlying_coins(address pool) external view returns (address[8] memory);

    function get_underlying_decimals(address pool) external view returns (uint256[8] memory);

    function get_coins(address pool) external view returns (address[4] memory);

    function get_n_coins(address pool) external view returns (uint256);

    function get_meta_n_coins(address pool) external view returns (uint256[2] memory);

    function get_decimals(address pool) external view returns (uint256[4] memory);

    function get_gauge(address pool) external view returns (address);

    function is_meta(address pool) external view returns (bool);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

interface IRegistry {
    function get_pool_from_lp_token() external view returns (address);

    function get_lp_token(address pool) external view returns (address);

    function get_n_coins(address pool) external view returns (uint256[2] memory);

    function get_underlying_coins(address pool) external view returns (address[8] memory);

    function get_underlying_decimals(address pool) external view returns (uint256[8] memory);

    function get_gauges(address pool) external view returns (address[10] memory);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

// Not a complete interface, but should have what we need
interface IStableSwap {
    function coins(uint256 i) external view returns (address);

    function fee() external view returns (uint256); // fee * 1e10

    function lp_token() external view returns (address);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;
}

interface IStableSwapV2 {
    function coins(int128 i) external view returns (address);
}

interface IStableSwapUnderlying is IStableSwap {
    function underlying_coins(uint256 i) external view returns (address);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external;
}

interface IStableSwap2x is IStableSwap {
    function calc_token_amount(uint256[2] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap3x is IStableSwap {
    function calc_token_amount(uint256[3] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap4x is IStableSwap {
    function calc_token_amount(uint256[4] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[4] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap2xUnderlying is IStableSwap2x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata min_amounts,
        bool use_underlying
    ) external;
}

interface IStableSwap3xUnderlying is IStableSwap3x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[3] calldata min_amounts,
        bool use_underlying
    ) external;
}

interface IStableSwap4xUnderlying is IStableSwap4x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[4] calldata min_amounts,
        bool use_underlying
    ) external;
}

/* solhint-enable */

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

// Not a complete interface, but should have what we need
interface ITokenMinter {
    function minted(address arg0, address arg1) external view returns (uint256);

    function mint(address gauge_addr) external;
}
/* solhint-enable */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterOracle {
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);

    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut);

    function quoteTokenToUsd(address token_, uint256 amountIn_) external view returns (uint256 amountOut_);

    function quoteUsdToToken(address token_, uint256 amountIn_) external view returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Routed Swapper interface
 * @dev This contract doesn't support native coins (e.g. ETH, AVAX, MATIC, etc) use wrapper tokens instead
 */
interface IRoutedSwapper {
    /**
     * @notice The list of supported DEXes
     * @dev This function is gas intensive
     */
    function getAllExchanges() external view returns (address[] memory);

    /**
     * @notice Get *spot* quote
     * It will return the swap amount based on the current reserves of the best pair/path found (i.e. spot price).
     * @dev It shouldn't be used as oracle!!!
     */
    function getAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external returns (uint256 _amountIn);

    /**
     * @notice Get *spot* quote
     * It will return the swap amount based on the current reserves of the best pair/path found (i.e. spot price).
     * @dev It shouldn't be used as oracle!!!
     */
    function getAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut);

    /**
     * @notice Perform an exact input swap - will revert if there is no default routing
     */
    function swapExactInput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address _receiver
    ) external returns (uint256 _amountOut);

    /**
     * @notice Perform an exact output swap - will revert if there is no default routing
     */
    function swapExactOutput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address receiver_
    ) external returns (uint256 _amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IVesperPool.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/Context.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "vesper-commons/contracts/interfaces/vesper/IStrategy.sol";
import "../interfaces/swapper/IRoutedSwapper.sol";

abstract contract Strategy is IStrategy, Context {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public immutable collateralToken;
    address public receiptToken;
    address public immutable override pool;
    address public override feeCollector;
    IRoutedSwapper public swapper;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant MAX_UINT_VALUE = type(uint256).max;

    EnumerableSet.AddressSet private _keepers;

    event UpdatedFeeCollector(address indexed previousFeeCollector, address indexed newFeeCollector);
    event UpdatedSwapper(IRoutedSwapper indexed oldSwapper, IRoutedSwapper indexed newSwapper);

    constructor(
        address _pool,
        address _swapper,
        address _receiptToken
    ) {
        require(_pool != address(0), "pool-address-is-zero");
        require(_swapper != address(0), "swapper-address-is-zero");
        swapper = IRoutedSwapper(_swapper);
        pool = _pool;
        collateralToken = IVesperPool(_pool).token();
        receiptToken = _receiptToken;
        require(_keepers.add(_msgSender()), "add-keeper-failed");
    }

    modifier onlyGovernor() {
        require(_msgSender() == IVesperPool(pool).governor(), "caller-is-not-the-governor");
        _;
    }

    modifier onlyKeeper() {
        require(_keepers.contains(_msgSender()), "caller-is-not-a-keeper");
        _;
    }

    modifier onlyPool() {
        require(_msgSender() == pool, "caller-is-not-vesper-pool");
        _;
    }

    /**
     * @notice Add given address in keepers list.
     * @param _keeperAddress keeper address to add.
     */
    function addKeeper(address _keeperAddress) external onlyGovernor {
        require(_keepers.add(_keeperAddress), "add-keeper-failed");
    }

    /// @dev Approve all required tokens
    function approveToken() external onlyKeeper {
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }

    /// @notice Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool);

    /// @notice Return list of keepers
    function keepers() external view override returns (address[] memory) {
        return _keepers.values();
    }

    /**
     * @notice Migrate all asset and vault ownership,if any, to new strategy
     * @dev _beforeMigration hook can be implemented in child strategy to do extra steps.
     * @param _newStrategy Address of new strategy
     */
    function migrate(address _newStrategy) external virtual override onlyPool {
        require(_newStrategy != address(0), "new-strategy-address-is-zero");
        require(IStrategy(_newStrategy).pool() == pool, "not-valid-new-strategy");
        _beforeMigration(_newStrategy);
        IERC20(receiptToken).safeTransfer(_newStrategy, IERC20(receiptToken).balanceOf(address(this)));
        collateralToken.safeTransfer(_newStrategy, collateralToken.balanceOf(address(this)));
    }

    /**
     * @notice OnlyKeeper: Rebalance profit, loss and investment of this strategy.
     *  Calculate profit, loss and payback of this strategy and realize profit/loss and
     *  withdraw fund for payback, if any, and submit this report to pool.
     * @return _profit Realized profit in collateral.
     * @return _loss Realized loss, if any, in collateral.
     * @return _payback If strategy has any excess debt, we have to liquidate asset to payback excess debt.
     */
    function rebalance()
        external
        onlyKeeper
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        return _rebalance();
    }

    /**
     * @notice Remove given address from keepers list.
     * @param _keeperAddress keeper address to remove.
     */
    function removeKeeper(address _keeperAddress) external onlyGovernor {
        require(_keepers.remove(_keeperAddress), "remove-keeper-failed");
    }

    /**
     * @notice sweep given token to feeCollector of strategy
     * @param _fromToken token address to sweep
     */
    function sweepERC20(address _fromToken) external override onlyKeeper {
        require(feeCollector != address(0), "fee-collector-not-set");
        require(_fromToken != address(collateralToken), "not-allowed-to-sweep-collateral");
        require(!isReservedToken(_fromToken), "not-allowed-to-sweep");
        if (_fromToken == ETH) {
            Address.sendValue(payable(feeCollector), address(this).balance);
        } else {
            uint256 _amount = IERC20(_fromToken).balanceOf(address(this));
            IERC20(_fromToken).safeTransfer(feeCollector, _amount);
        }
    }

    /// @notice Returns address of token correspond to receipt token
    function token() external view override returns (address) {
        return receiptToken;
    }

    /// @notice Returns address of token correspond to collateral token
    function collateral() external view override returns (address) {
        return address(collateralToken);
    }

    /// @notice Returns total collateral locked in the strategy
    function tvl() external view virtual returns (uint256);

    /**
     * @notice Update fee collector
     * @param _feeCollector fee collector address
     */
    function updateFeeCollector(address _feeCollector) external onlyGovernor {
        require(_feeCollector != address(0), "fee-collector-address-is-zero");
        require(_feeCollector != feeCollector, "fee-collector-is-same");
        emit UpdatedFeeCollector(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    /**
     * @notice Update swapper
     * @param _swapper swapper address
     */
    function updateSwapper(IRoutedSwapper _swapper) external onlyGovernor {
        require(address(_swapper) != address(0), "swapper-address-is-zero");
        require(_swapper != swapper, "swapper-is-same");
        emit UpdatedSwapper(swapper, _swapper);
        swapper = _swapper;
    }

    /**
     * @notice Withdraw collateral token from end protocol.
     * @param _amount Amount of collateral token
     */
    function withdraw(uint256 _amount) external override onlyPool {
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        if (_collateralHere >= _amount) {
            collateralToken.safeTransfer(pool, _amount);
        } else {
            _withdrawHere(_amount - _collateralHere);
            // Do not assume _withdrawHere() will withdraw exact amount. Check balance again and transfer to pool
            _collateralHere = collateralToken.balanceOf(address(this));
            collateralToken.safeTransfer(pool, Math.min(_amount, _collateralHere));
        }
    }

    function _approveToken(uint256 _amount) internal virtual {
        collateralToken.safeApprove(pool, _amount);
    }

    /**
     * @dev some strategy may want to prepare before doing migration.
     *  Example In Maker old strategy want to give vault ownership to new strategy
     * @param _newStrategy .
     */
    function _beforeMigration(address _newStrategy) internal virtual;

    function _rebalance()
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        );

    function _swapExactInput(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal returns (uint256 _amountOut) {
        _amountOut = swapper.swapExactInput(_tokenIn, _tokenOut, _amountIn, 1, address(this));
    }

    function _safeSwapExactInput(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal {
        try swapper.swapExactInput(_tokenIn, _tokenOut, _amountIn, 1, address(this)) {} catch {} //solhint-disable no-empty-blocks
    }

    // These methods must be implemented by the inheriting strategy
    function _withdrawHere(uint256 _amount) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/convex/IConvexForFrax.sol";
import "../../strategies/curve/Curve.sol";

/**
 * @title Convex for Frax strategy
 * @dev This strategy only supports Curve deposits
 */
contract ConvexForFrax is Curve {
    using SafeERC20 for IERC20;

    IVaultRegistry public constant VAULT_REGISTRY = IVaultRegistry(0x569f5B842B5006eC17Be02B8b94510BA8e79FbCa);
    IConvexFraxPoolRegistry public constant POOL_REGISTRY =
        IConvexFraxPoolRegistry(0x41a5881c17185383e19Df6FA4EC158a6F4851A69);
    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

    /// @notice Frax Staking contract
    IFraxFarmERC20 public immutable fraxStaking;

    /// @notice Convex vault to interact with FRAX staking
    IStakingProxyConvex public immutable vault;

    /// @notice Convex Rewards contract
    IMultiReward public immutable rewards;

    /// @notice FRAX staking period
    /// @dev Uses the `lock_time_min` by default. Use `updateLockPeriod` to update it if needed.
    uint256 public lockPeriod;

    /// @notice Staking position ID
    bytes32 public kekId;

    /// @notice Next time where the withdraw will be available
    uint256 public unlockTime;

    /// @notice Emitted when `unlockTime` is updated
    event UnlockTimeUpdated(uint256 oldUnlockTime, uint256 newUnlockTime);

    constructor(
        address pool_,
        address crvPool_,
        PoolType curvePoolType_,
        address depositZap_,
        address crvToken_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        uint256 collateralIdx_,
        uint256 convexPoolId_,
        string memory name_
    )
        Curve(
            pool_,
            crvPool_,
            curvePoolType_,
            depositZap_,
            crvToken_,
            crvSlippage_,
            masterOracle_,
            swapper_,
            collateralIdx_,
            name_
        )
    {
        (, address _stakingAddress, , address _reward, ) = POOL_REGISTRY.poolInfo(convexPoolId_);
        rewards = IMultiReward(_reward);
        vault = IStakingProxyConvex(VAULT_REGISTRY.createVault(convexPoolId_));
        require(vault.curveLpToken() == address(crvLp), "incorrect-lp-token");
        fraxStaking = IFraxFarmERC20(_stakingAddress);
        lockPeriod = fraxStaking.lock_time_min();
        rewardTokens = _getRewardTokens();
    }

    function lpBalanceStaked() public view override returns (uint256 _total) {
        // Note: No need to specify which position here because we'll always have one open position at the same time
        // because of the open position is deleted when `vault.withdrawLockedAndUnwrap(kekId)` is called
        _total = fraxStaking.lockedLiquidityOf(address(vault));
    }

    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        crvLp.safeApprove(address(vault), amount_);
    }

    /// @dev
    function _claimRewards() internal override {
        // `getReward` reverts if there isn't an open position
        if (kekId == bytes32(0)) return;

        // solhint-disable-next-line no-empty-blocks
        try vault.getReward() {} catch {
            // It may fail if reward collection is paused on FRAX side
            // See more: https://github.com/convex-eth/frax-cvx-platform/blob/01855f4f82729b49cbed0b5fab37bdefe9fdb736/contracts/contracts/StakingProxyConvex.sol#L222-L225
            vault.getReward(false);
        }
    }

    /// @notice Get reward tokens
    function _getRewardTokens() private view returns (address[] memory _rewardTokens) {
        uint256 _extraRewardCount;
        uint256 _length = rewards.rewardTokenLength();

        for (uint256 i; i < _length; i++) {
            address _rewardToken = rewards.rewardTokens(i);
            // Some pool has CVX as extra rewards but other do not. CVX still reward token
            if (_rewardToken != CRV && _rewardToken != CVX && _rewardToken != FXS) {
                _extraRewardCount++;
            }
        }

        _rewardTokens = new address[](_extraRewardCount + 3);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        _rewardTokens[2] = FXS;
        uint256 _nextIdx = 3;

        for (uint256 i; i < _length; i++) {
            address _rewardToken = rewards.rewardTokens(i);
            // CRV and CVX already added in array
            if (_rewardToken != CRV && _rewardToken != CVX && _rewardToken != FXS) {
                _rewardTokens[_nextIdx++] = _rewardToken;
            }
        }
    }

    /**
     * @notice Stake Curve-LP token
     * @dev Stake to the current position if there is any
     */
    function _stakeAllLp() internal virtual override {
        uint256 _balance = crvLp.balanceOf(address(this));
        if (_balance > 0) {
            if (kekId != bytes32(0)) {
                // if there is an active position, lock more
                vault.lockAdditionalCurveLp(kekId, _balance);
            } else {
                // otherwise create a new position
                kekId = vault.stakeLockedCurveLp(_balance, lockPeriod);
                unlockTime = block.timestamp + lockPeriod;
            }
        }
    }

    /**
     * @notice Unstake all LPs
     * @dev This function is called by `_beforeMigration()` hook
     * @dev `withdrawLockedAndUnwrap` destroys current position
     * Should claim rewards that will be swept later
     */
    function _unstakeAllLp() internal override {
        require(block.timestamp >= unlockTime, "unlock-time-didnt-pass");
        vault.withdrawLockedAndUnwrap(kekId);
        kekId = 0x0;
    }

    /**
     * @notice Unstake LPs
     * @dev Unstake all because Convex-FRAX doesn't support partial unlocks
     */
    function _unstakeLp(uint256 _amount) internal override {
        if (_amount > 0) {
            _unstakeAllLp();
        }
    }

    /// @dev convex pool can add new rewards. This method refresh list.
    function setRewardTokens(
        address[] memory /*_rewardTokens*/
    ) external override onlyKeeper {
        // Claims all rewards, if any, before updating the reward list
        _claimRewardsAndConvertTo(address(collateralToken));
        rewardTokens = _getRewardTokens();
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }

    /// @notice Update `lockPeriod` param
    /// @dev To be used if the `lock_time_min` value changes or we want to increase it
    function updateLockPeriod(uint256 newLockPeriod_) external onlyGovernor {
        require(newLockPeriod_ >= fraxStaking.lock_time_min(), "period-lt-min");
        emit UnlockTimeUpdated(lockPeriod, newLockPeriod_);
        lockPeriod = newLockPeriod_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/SafeCast.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "../../interfaces/curve/IDeposit.sol";
import "../../interfaces/curve/IDepositZap.sol";
import "../../interfaces/curve/IStableSwap.sol";
import "../../interfaces/curve/ILiquidityGauge.sol";
import "../../interfaces/curve/ITokenMinter.sol";
import "../../interfaces/curve/IMetapoolFactory.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../../interfaces/one-oracle/IMasterOracle.sol";
import "../Strategy.sol";

/// @title This strategy will deposit collateral token in a Curve Pool and earn interest.
// solhint-disable no-empty-blocks
contract Curve is Strategy {
    using SafeERC20 for IERC20;

    enum PoolType {
        PLAIN_2_POOL,
        PLAIN_3_POOL,
        PLAIN_4_POOL,
        LENDING_2_POOL,
        LENDING_3_POOL,
        LENDING_4_POOL,
        META_3_POOL,
        META_4_POOL
    }

    string public constant VERSION = "5.0.0";
    uint256 internal constant MAX_BPS = 10_000;
    ITokenMinter public constant CRV_MINTER = ITokenMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0); // This contract only exists on mainnet
    IAddressProvider public constant ADDRESS_PROVIDER = IAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383); // Same address to all chains
    uint256 private constant FACTORY_ADDRESS_ID = 3;

    address public immutable CRV;
    IERC20 public immutable crvLp; // Note: Same as `receiptToken` but using this in order to save gas since it's `immutable` and `receiptToken` isn't
    address public immutable crvPool;
    ILiquidityGaugeV2 public immutable crvGauge;
    uint256 public immutable collateralIdx;
    address internal immutable depositZap;
    PoolType public immutable curvePoolType;
    bool private immutable isFactoryPool;

    string public NAME;
    uint256 public crvSlippage;
    IMasterOracle public masterOracle;
    address[] public rewardTokens;

    event CrvSlippageUpdated(uint256 oldCrvSlippage, uint256 newCrvSlippage);
    event MasterOracleUpdated(IMasterOracle oldMasterOracle, IMasterOracle newMasterOracle);

    constructor(
        address pool_,
        address crvPool_,
        PoolType curvePoolType_,
        address depositZap_,
        address crvToken_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        uint256 collateralIdx_,
        string memory name_
    ) Strategy(pool_, swapper_, address(0)) {
        require(crvToken_ != address(0), "crv-token-is-null");

        address _crvGauge;
        IRegistry _registry = IRegistry(ADDRESS_PROVIDER.get_registry());
        address _crvLp = _registry.get_lp_token(crvPool_);

        if (_crvLp != address(0)) {
            // Get data from Registry contract
            require(collateralIdx_ < _registry.get_n_coins(crvPool_)[1], "invalid-collateral");
            require(
                _registry.get_underlying_coins(crvPool_)[collateralIdx_] == address(collateralToken),
                "collateral-mismatch"
            );
            _crvGauge = _registry.get_gauges(crvPool_)[0];
        } else {
            // Get data from Factory contract
            IMetapoolFactory _factory = IMetapoolFactory(ADDRESS_PROVIDER.get_address(FACTORY_ADDRESS_ID));

            if (_factory.is_meta(crvPool_)) {
                require(collateralIdx_ < _factory.get_meta_n_coins(crvPool_)[1], "invalid-collateral");
                require(
                    _factory.get_underlying_coins(crvPool_)[collateralIdx_] == address(collateralToken),
                    "collateral-mismatch"
                );
            } else {
                require(collateralIdx_ < _factory.get_n_coins(crvPool_), "invalid-collateral");
                require(
                    _factory.get_coins(crvPool_)[collateralIdx_] == address(collateralToken),
                    "collateral-mismatch"
                );
            }
            _crvLp = crvPool_;
            _crvGauge = _factory.get_gauge(crvPool_);
        }

        require(crvPool_ != address(0), "pool-is-null");
        require(_crvLp != address(0), "lp-is-null");
        require(_crvGauge != address(0), "gauge-is-null");

        CRV = crvToken_;
        crvPool = crvPool_;
        crvLp = IERC20(_crvLp);
        crvGauge = ILiquidityGaugeV2(_crvGauge);
        crvSlippage = crvSlippage_;
        receiptToken = _crvLp;
        collateralIdx = collateralIdx_;
        curvePoolType = curvePoolType_;
        isFactoryPool = _crvLp == crvPool_;
        depositZap = depositZap_;
        masterOracle = IMasterOracle(masterOracle_);
        rewardTokens.push(crvToken_);
        NAME = name_;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address token_) public view override returns (bool) {
        return token_ == address(crvLp) || token_ == address(collateralToken);
    }

    // Gets LP value not staked in gauge
    function lpBalanceHere() public view virtual returns (uint256 _lpHere) {
        _lpHere = crvLp.balanceOf(address(this));
    }

    function lpBalanceHereAndStaked() public view virtual returns (uint256 _lpHereAndStaked) {
        _lpHereAndStaked = crvLp.balanceOf(address(this)) + lpBalanceStaked();
    }

    function lpBalanceStaked() public view virtual returns (uint256 _lpStaked) {
        _lpStaked = crvGauge.balanceOf(address(this));
    }

    /// @notice Returns collateral balance + collateral deposited to curve
    function tvl() external view override returns (uint256) {
        return
            collateralToken.balanceOf(address(this)) +
            _quoteLpToCoin(lpBalanceHereAndStaked(), SafeCast.toInt128(int256(collateralIdx)));
    }

    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);

        address _swapper = address(swapper);

        collateralToken.safeApprove(crvPool, amount_);
        collateralToken.safeApprove(_swapper, amount_);

        uint256 _rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < _rewardTokensLength; ++i) {
            IERC20(rewardTokens[i]).safeApprove(_swapper, amount_);
        }
        crvLp.safeApprove(address(crvGauge), amount_);

        if (depositZap != address(0)) {
            collateralToken.safeApprove(depositZap, amount_);
            crvLp.safeApprove(depositZap, amount_);
        }
    }

    /// @notice Unstake LP tokens in order to transfer to the new strategy
    function _beforeMigration(address newStrategy_) internal override {
        require(IStrategy(newStrategy_).collateral() == address(collateralToken), "wrong-collateral-token");
        require(IStrategy(newStrategy_).token() == address(crvLp), "wrong-receipt-token");
        _unstakeAllLp();
    }

    function _calculateAmountOutMin(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOutMin) {
        _amountOutMin = (masterOracle.quote(tokenIn_, tokenOut_, amountIn_) * (MAX_BPS - crvSlippage)) / MAX_BPS;
    }

    function _claimRewards() internal virtual {
        if (block.chainid == 1) {
            // Side-chains don't have minter contract
            CRV_MINTER.mint(address(crvGauge));
        }
        try crvGauge.claim_rewards() {} catch {
            // This call may fail in some scenarios
            // e.g. 3Crv gauge doesn't have such function
        }
    }

    /**
     * @notice Curve pool may have more than one reward token. Child contract should override _claimRewards
     */
    function _claimRewardsAndConvertTo(address tokenOut_) internal virtual {
        _claimRewards();
        uint256 _rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < _rewardTokensLength; ++i) {
            address _rewardToken = rewardTokens[i];
            uint256 _amountIn = IERC20(_rewardToken).balanceOf(address(this));
            if (_amountIn > 0) {
                try swapper.swapExactInput(_rewardToken, tokenOut_, _amountIn, 1, address(this)) {} catch {
                    // Note: It may fail under some conditions
                    // For instance: 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT'
                }
            }
        }
    }

    function _deposit() internal {
        _depositToCurve(collateralToken.balanceOf(address(this)));
        _stakeAllLp();
    }

    function _depositTo2PlainPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[2] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        IStableSwap2x(crvPool).add_liquidity(_depositAmounts, lpAmountOutMin_);
    }

    function _depositTo2LendingPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[2] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        // Note: Using use_underlying = true to deposit underlying instead of IB token
        IStableSwap2xUnderlying(crvPool).add_liquidity(_depositAmounts, lpAmountOutMin_, true);
    }

    function _depositTo3PlainPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[3] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        IStableSwap3x(crvPool).add_liquidity(_depositAmounts, lpAmountOutMin_);
    }

    function _depositTo3LendingPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[3] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        // Note: Using use_underlying = true to deposit underlying instead of IB token
        IStableSwap3xUnderlying(crvPool).add_liquidity(_depositAmounts, lpAmountOutMin_, true);
    }

    function _depositTo4PlainOrMetaPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[4] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        IDeposit4x(depositZap).add_liquidity(_depositAmounts, lpAmountOutMin_);
    }

    function _depositTo3FactoryMetaPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[3] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        // Note: The function below won't return a reason when reverting due to slippage
        IDepositZap3x(depositZap).add_liquidity(address(crvPool), _depositAmounts, lpAmountOutMin_);
    }

    function _depositTo4FactoryMetaPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[4] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        // Note: The function below won't return a reason when reverting due to slippage
        IDepositZap4x(depositZap).add_liquidity(address(crvPool), _depositAmounts, lpAmountOutMin_);
    }

    function _depositToCurve(uint256 coinAmountIn_) private {
        if (coinAmountIn_ == 0) {
            return;
        }

        uint256 _lpAmountOutMin = _calculateAmountOutMin(address(collateralToken), address(crvLp), coinAmountIn_);

        if (curvePoolType == PoolType.PLAIN_2_POOL) {
            return _depositTo2PlainPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.LENDING_2_POOL) {
            return _depositTo2LendingPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.PLAIN_3_POOL) {
            return _depositTo3PlainPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.LENDING_3_POOL) {
            return _depositTo3LendingPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.PLAIN_4_POOL) {
            return _depositTo4PlainOrMetaPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.META_3_POOL) {
            return _depositTo3FactoryMetaPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.META_4_POOL) {
            if (isFactoryPool) {
                return _depositTo4FactoryMetaPool(coinAmountIn_, _lpAmountOutMin);
            }
            return _depositTo4PlainOrMetaPool(coinAmountIn_, _lpAmountOutMin);
        }

        revert("deposit-to-curve-failed");
    }

    function _generateReport()
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _strategyDebt = IVesperPool(pool).totalDebtOf(address(this));

        _claimRewardsAndConvertTo(address(collateralToken));

        int128 _i = SafeCast.toInt128(int256(collateralIdx));
        uint256 _lpHere = lpBalanceHere();
        uint256 _totalLp = _lpHere + lpBalanceStaked();
        uint256 _collateralInCurve = _quoteLpToCoin(_totalLp, _i);
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + _collateralInCurve;

        if (_totalCollateral > _strategyDebt) {
            _profit = _totalCollateral - _strategyDebt;
        } else {
            _loss = _strategyDebt - _totalCollateral;
        }

        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_profitAndExcessDebt > _collateralHere) {
            uint256 _totalAmountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _collateralInCurve);
            if (_totalAmountToWithdraw > 0) {
                uint256 _lpToBurn = Math.min((_totalAmountToWithdraw * _totalLp) / _collateralInCurve, _totalLp);

                if (_lpToBurn > 0) {
                    if (_lpToBurn > _lpHere) {
                        _unstakeLp(_lpToBurn - _lpHere);
                    }

                    _withdrawFromCurve(_lpToBurn, _i);

                    _collateralHere = collateralToken.balanceOf(address(this));
                }
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
    }

    function _quoteLpToCoin(uint256 amountIn_, int128 toIdx_) private view returns (uint256 _amountOut) {
        if (amountIn_ == 0) {
            return 0;
        }

        if (curvePoolType == PoolType.PLAIN_4_POOL) {
            return IDeposit4x(depositZap).calc_withdraw_one_coin(amountIn_, toIdx_);
        }
        if (curvePoolType == PoolType.META_3_POOL) {
            return IDepositZap3x(depositZap).calc_withdraw_one_coin(address(crvLp), amountIn_, toIdx_);
        }
        if (curvePoolType == PoolType.META_4_POOL) {
            if (isFactoryPool) {
                return IDepositZap4x(depositZap).calc_withdraw_one_coin(address(crvLp), amountIn_, toIdx_);
            }
            return IDeposit4x(depositZap).calc_withdraw_one_coin(amountIn_, toIdx_);
        }

        return IStableSwap(crvPool).calc_withdraw_one_coin(amountIn_, toIdx_);
    }

    function _rebalance()
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        (_profit, _loss, _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }

    // Requires that gauge has approval for lp token
    function _stakeAllLp() internal virtual {
        uint256 _balance = crvLp.balanceOf(address(this));
        if (_balance > 0) {
            crvGauge.deposit(_balance);
        }
    }

    function _unstakeAllLp() internal virtual {
        _unstakeLp(crvGauge.balanceOf(address(this)));
    }

    function _unstakeLp(uint256 amount_) internal virtual {
        if (amount_ > 0) {
            crvGauge.withdraw(amount_);
        }
    }

    function _withdrawFromPlainPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        IStableSwap(crvPool).remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_);
    }

    function _withdrawFrom2LendingPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        // Note: Using use_underlying = true to withdraw underlying instead of IB token
        IStableSwap2xUnderlying(crvPool).remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_, true);
    }

    function _withdrawFrom3LendingPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        // Note: Using use_underlying = true to withdraw underlying instead of IB token
        IStableSwap3xUnderlying(crvPool).remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_, true);
    }

    function _withdrawFrom4PlainOrMetaPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        IDeposit4x(depositZap).remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_);
    }

    function _withdrawFrom3FactoryMetaOr4FactoryMetaPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        // Note: The function below won't return a reason when reverting due to slippage
        IDepositZap(depositZap).remove_liquidity_one_coin(address(crvLp), lpAmount_, i_, minAmountOut_);
    }

    function _withdrawFromCurve(uint256 lpToBurn_, int128 coinIdx_) internal {
        if (lpToBurn_ == 0) {
            return;
        }

        uint256 _minCoinAmountOut = _calculateAmountOutMin(address(crvLp), address(collateralToken), lpToBurn_);

        if (curvePoolType == PoolType.PLAIN_2_POOL || curvePoolType == PoolType.PLAIN_3_POOL) {
            return _withdrawFromPlainPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.LENDING_2_POOL) {
            return _withdrawFrom2LendingPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.LENDING_3_POOL) {
            return _withdrawFrom3LendingPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.PLAIN_4_POOL) {
            return _withdrawFrom4PlainOrMetaPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.META_3_POOL) {
            return _withdrawFrom3FactoryMetaOr4FactoryMetaPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.META_4_POOL) {
            if (isFactoryPool) {
                return _withdrawFrom3FactoryMetaOr4FactoryMetaPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
            }
            return _withdrawFrom4PlainOrMetaPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }

        revert("withdraw-from-curve-failed");
    }

    function _withdrawHere(uint256 coinAmountOut_) internal override {
        int128 _i = SafeCast.toInt128(int256(collateralIdx));

        uint256 _lpHere = lpBalanceHere();
        uint256 _totalLp = _lpHere + lpBalanceStaked();
        uint256 _lpToBurn = Math.min((coinAmountOut_ * _totalLp) / _quoteLpToCoin(_totalLp, _i), _totalLp);

        if (_lpToBurn == 0) return;

        if (_lpToBurn > _lpHere) {
            _unstakeLp(_lpToBurn - _lpHere);
        }

        _withdrawFromCurve(_lpToBurn, _i);
    }

    /// @dev Rewards token in gauge can be updated any time. Governor can set reward tokens
    /// Different version of gauge has different method to read reward tokens better governor set it
    function setRewardTokens(address[] memory rewardTokens_) external virtual onlyGovernor {
        rewardTokens = rewardTokens_;
        address _receiptToken = receiptToken;
        uint256 _rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < _rewardTokensLength; ++i) {
            require(
                rewardTokens_[i] != _receiptToken &&
                    rewardTokens_[i] != address(collateralToken) &&
                    rewardTokens_[i] != pool &&
                    rewardTokens_[i] != address(crvLp),
                "Invalid reward token"
            );
        }
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }

    function updateCrvSlippage(uint256 newCrvSlippage_) external onlyGovernor {
        require(newCrvSlippage_ < MAX_BPS, "invalid-slippage-value");
        emit CrvSlippageUpdated(crvSlippage, newCrvSlippage_);
        crvSlippage = newCrvSlippage_;
    }

    function updateMasterOracle(IMasterOracle newMasterOracle_) external onlyGovernor {
        emit MasterOracleUpdated(masterOracle, newMasterOracle_);
        masterOracle = newMasterOracle_;
    }
}