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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Errors library
library Errors {
    string public constant INVALID_COLLATERAL_AMOUNT = "1"; // Collateral must be greater than 0 or > defined limit
    string public constant INVALID_SHARE_AMOUNT = "2"; // Share must be greater than 0
    string public constant INVALID_INPUT_LENGTH = "3"; // Input array length must be greater than 0
    string public constant INPUT_LENGTH_MISMATCH = "4"; // Input array length mismatch with another array length
    string public constant NOT_WHITELISTED_ADDRESS = "5"; // Caller is not whitelisted to withdraw without fee
    string public constant MULTI_TRANSFER_FAILED = "6"; // Multi transfer of tokens has failed
    string public constant FEE_COLLECTOR_NOT_SET = "7"; // Fee Collector is not set
    string public constant NOT_ALLOWED_TO_SWEEP = "8"; // Token is not allowed to sweep
    string public constant INSUFFICIENT_BALANCE = "9"; // Insufficient balance to performs operations to follow
    string public constant INPUT_ADDRESS_IS_ZERO = "10"; // Input address is zero
    string public constant FEE_LIMIT_REACHED = "11"; // Fee must be less than MAX_BPS
    string public constant ALREADY_INITIALIZED = "12"; // Data structure, contract, or logic already initialized and can not be called again
    string public constant ADD_IN_LIST_FAILED = "13"; // Cannot add address in address list
    string public constant REMOVE_FROM_LIST_FAILED = "14"; // Cannot remove address from address list
    string public constant STRATEGY_IS_ACTIVE = "15"; // Strategy is already active, an inactive strategy is required
    string public constant STRATEGY_IS_NOT_ACTIVE = "16"; // Strategy is not active, an active strategy is required
    string public constant INVALID_STRATEGY = "17"; // Given strategy is not a strategy of this pool
    string public constant DEBT_RATIO_LIMIT_REACHED = "18"; // Debt ratio limit reached. It must be less than MAX_BPS
    string public constant TOTAL_DEBT_IS_NOT_ZERO = "19"; // Strategy total debt must be 0
    string public constant LOSS_TOO_HIGH = "20"; // Strategy reported loss must be less than current debt
    string public constant INVALID_MAX_BORROW_LIMIT = "21"; // Max borrow limit is beyond range.
    string public constant MAX_LIMIT_LESS_THAN_MIN = "22"; // Max limit should be greater than min limit.
    string public constant INVALID_SLIPPAGE = "23"; // Slippage should be less than MAX_BPS
    string public constant WRONG_RECEIPT_TOKEN = "24"; // Wrong receipt token address
    string public constant AAVE_FLASH_LOAN_NOT_ACTIVE = "25"; // aave flash loan is not active
    string public constant DYDX_FLASH_LOAN_NOT_ACTIVE = "26"; // DYDX flash loan is not active
    string public constant INVALID_FLASH_LOAN = "27"; // invalid-flash-loan
    string public constant INVALID_INITIATOR = "28"; // "invalid-initiator"
    string public constant INCORRECT_WITHDRAW_AMOUNT = "29"; // withdrawn amount is not correct
    string public constant NO_MARKET_ID_FOUND = "30"; // dydx flash loan no marketId found for token
    string public constant SAME_AS_PREVIOUS = "31"; // Input should not be same as previous value.
    string public constant INVALID_INPUT = "32"; // Generic invalid input error code
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

interface IPoolRewards {
    /// Emitted after reward added
    event RewardAdded(address indexed rewardToken, uint256 reward, uint256 rewardDuration);
    /// Emitted whenever any user claim rewards
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 reward);
    /// Emitted after adding new rewards token into rewardTokens array
    event RewardTokenAdded(address indexed rewardToken, address[] existingRewardTokens);

    function claimReward(address) external;

    function notifyRewardAmount(
        address _rewardToken,
        uint256 _rewardAmount,
        uint256 _rewardDuration
    ) external;

    function notifyRewardAmount(
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts,
        uint256[] memory _rewardDurations
    ) external;

    function updateReward(address) external;

    function claimable(address _account)
        external
        view
        returns (address[] memory _rewardTokens, uint256[] memory _claimableAmounts);

    function lastTimeRewardApplicable(address _rewardToken) external view returns (uint256);

    function rewardForDuration()
        external
        view
        returns (address[] memory _rewardTokens, uint256[] memory _rewardForDuration);

    function rewardPerToken()
        external
        view
        returns (address[] memory _rewardTokens, uint256[] memory _rewardPerTokenRate);
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

// @dev Interface support both Aave v2 and v3 methods
interface PoolAddressesProvider {
    function getPool() external view returns (address);

    // Aave v2 method.
    function getLendingPool() external view returns (address);

    function getPoolDataProvider() external view returns (address);

    function getAddress(bytes32 id) external view returns (address);

    function getPriceOracle() external view returns (address);
}

interface AaveOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface AToken is IERC20 {
    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController() external view returns (address);

    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    //solhint-disable func-name-mixedcase
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

interface AaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    function getRewardsList() external view returns (address[] memory);
}

interface AaveLendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external;

    function getUserAccountData(address _user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface AaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );
}

//solhint-disable func-name-mixedcase
interface StakedAave is IERC20 {
    function claimRewards(address to, uint256 amount) external;

    function cooldown() external;

    function stake(address onBehalfOf, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function getTotalRewardsBalance(address staker) external view returns (uint256);

    function stakersCooldowns(address staker) external view returns (uint256);

    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);
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

    /// @notice Returns address of token correspond to collateral token
    function token() external view override returns (address) {
        return receiptToken;
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
    ) internal {
        swapper.swapExactInput(_tokenIn, _tokenOut, _amountIn, 1, address(this));
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

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "vesper-pools/contracts/Errors.sol";
import "../../../interfaces/aave/IAave.sol";

/// @title This contract provide core operations for Aave
abstract contract AaveV2Core {
    //solhint-disable-next-line const-name-snakecase
    StakedAave public constant stkAAVE = StakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    AaveLendingPool public immutable aaveLendingPool;
    AaveProtocolDataProvider public aaveProtocolDataProvider;
    AaveIncentivesController public immutable aaveIncentivesController;
    PoolAddressesProvider internal immutable aaveAddressesProvider_;

    AToken internal immutable aToken;
    bytes32 private constant AAVE_PROVIDER_ID = 0x0100000000000000000000000000000000000000000000000000000000000000;

    constructor(address _receiptToken) {
        require(_receiptToken != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        aToken = AToken(_receiptToken);
        // If there is no AAVE incentive then below call will fail
        try AToken(_receiptToken).getIncentivesController() returns (address _aaveIncentivesController) {
            aaveIncentivesController = AaveIncentivesController(_aaveIncentivesController);
        } catch {} //solhint-disable no-empty-blocks
        aaveAddressesProvider_ = PoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
        aaveLendingPool = AaveLendingPool(aaveAddressesProvider_.getLendingPool());
        aaveProtocolDataProvider = AaveProtocolDataProvider(aaveAddressesProvider_.getAddress(AAVE_PROVIDER_ID));
    }

    ///////////////////////// External access functions /////////////////////////

    /**
     * @notice Initiate cooldown to unstake aave.
     * @dev We only want to call this function when cooldown is expired and
     * that's the reason we have 'if' condition.
     * @dev Child contract should expose this function as external and onlyKeeper
     */
    function _startCooldown() internal returns (bool) {
        if (canStartCooldown()) {
            stkAAVE.cooldown();
            return true;
        }
        return false;
    }

    /**
     * @notice Unstake Aave from stakedAave contract
     * @dev We want to unstake as soon as favorable condition exit
     * @dev No guarding condition thus this call can fail, if we can't unstake.
     * @dev Child contract should expose this function as external and onlyKeeper
     */
    function _unstakeAave() internal {
        stkAAVE.redeem(address(this), type(uint256).max);
    }

    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns true if Aave can be unstaked
    function canUnstake() external view returns (bool) {
        (, uint256 _cooldownEnd, uint256 _unstakeEnd) = cooldownData();
        return _canUnstake(_cooldownEnd, _unstakeEnd);
    }

    /// @notice Returns true if we should start cooldown
    function canStartCooldown() public view returns (bool) {
        (uint256 _cooldownStart, , uint256 _unstakeEnd) = cooldownData();
        return _canStartCooldown(_cooldownStart, _unstakeEnd);
    }

    /// @notice Return cooldown related timestamps
    function cooldownData()
        public
        view
        returns (
            uint256 _cooldownStart,
            uint256 _cooldownEnd,
            uint256 _unstakeEnd
        )
    {
        _cooldownStart = stkAAVE.stakersCooldowns(address(this));
        _cooldownEnd = _cooldownStart + stkAAVE.COOLDOWN_SECONDS();
        _unstakeEnd = _cooldownEnd + stkAAVE.UNSTAKE_WINDOW();
    }

    /**
     * @notice Claim Aave. Also unstake all Aave if favorable condition exits or start cooldown.
     * @dev If we unstake all Aave, we can't start cooldown because it requires StakedAave balance.
     * @dev DO NOT convert 'if else' to 2 'if's as we are reading cooldown state once to save gas.
     * @dev Not all collateral token has aave incentive
     */
    function _claimAave() internal returns (uint256) {
        if (address(aaveIncentivesController) == address(0)) {
            return 0;
        }
        (uint256 _cooldownStart, uint256 _cooldownEnd, uint256 _unstakeEnd) = cooldownData();
        if (_cooldownStart == 0 || block.timestamp > _unstakeEnd) {
            // claim stkAave when its first rebalance or unstake period passed.
            aaveIncentivesController.claimRewards(getAssets(), type(uint256).max, address(this));
        }
        // Fetch and check again for next action.
        (_cooldownStart, _cooldownEnd, _unstakeEnd) = cooldownData();
        if (_canUnstake(_cooldownEnd, _unstakeEnd)) {
            stkAAVE.redeem(address(this), type(uint256).max);
        } else if (_canStartCooldown(_cooldownStart, _unstakeEnd)) {
            stkAAVE.cooldown();
        }

        stkAAVE.claimRewards(address(this), type(uint256).max);
        return IERC20(AAVE).balanceOf(address(this));
    }

    /// @notice Deposit asset into Aave
    function _deposit(address _asset, uint256 _amount) internal {
        if (_amount > 0) {
            try aaveLendingPool.deposit(_asset, _amount, address(this), 0) {} catch Error(string memory _reason) {
                // Aave uses liquidityIndex and some other indexes as needed to normalize input.
                // If normalized input equals to 0 then error will be thrown with '56' error code.
                // CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
                // Hence discard error where error code is '56'
                require(bytes32(bytes(_reason)) == "56", "deposit failed");
            }
        }
    }

    function getAssets() internal view returns (address[] memory) {
        address[] memory _assets = new address[](1);
        _assets[0] = address(aToken);
        return _assets;
    }

    /**
     * @notice Safe withdraw will make sure to check asking amount against available amount.
     * @dev Check we have enough aToken and liquidity to support this withdraw
     * @param _asset Address of asset to withdraw
     * @param _to Address that will receive collateral token.
     * @param _amount Amount of collateral to withdraw.
     * @return Actual collateral withdrawn
     */
    function _safeWithdraw(
        address _asset,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 _aTokenBalance = aToken.balanceOf(address(this));
        // If Vesper becomes large liquidity provider in Aave(This happened in past in vUSDC 1.0)
        // In this case we might have more aToken compare to available liquidity in Aave and any
        // withdraw asking more than available liquidity will fail. To do safe withdraw, check
        // _amount against available liquidity.
        uint256 _availableLiquidity = IERC20(_asset).balanceOf(address(aToken));

        // Get minimum of _amount, _aTokenBalance and _availableLiquidity
        return _withdraw(_asset, _to, Math.min(_amount, Math.min(_aTokenBalance, _availableLiquidity)));
    }

    /**
     * @notice Withdraw given amount of collateral from Aave to given address
     * @param _asset Address of asset to withdraw
     * @param _to Address that will receive collateral token.
     * @param _amount Amount of collateral to withdraw.
     * @return Actual collateral withdrawn
     */
    function _withdraw(
        address _asset,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount > 0) {
            require(aaveLendingPool.withdraw(_asset, _amount, _to) == _amount, Errors.INCORRECT_WITHDRAW_AMOUNT);
        }
        return _amount;
    }

    /**
     * @dev Return true, only if we have StakedAave balance and either cooldown expired or cooldown is zero
     * @dev If we are in cooldown period we cannot unstake Aave. But our cooldown is still valid so we do
     * not want to reset/start cooldown.
     */
    function _canStartCooldown(uint256 _cooldownStart, uint256 _unstakeEnd) internal view returns (bool) {
        return stkAAVE.balanceOf(address(this)) > 0 && (_cooldownStart == 0 || block.timestamp > _unstakeEnd);
    }

    /// @dev Return true, if cooldown is over and we are in unstake window.
    function _canUnstake(uint256 _cooldownEnd, uint256 _unstakeEnd) internal view returns (bool) {
        return block.timestamp > _cooldownEnd && block.timestamp <= _unstakeEnd;
    }

    /**
     * @notice Return total AAVE incentive allocated to this address
     * @dev Aave and StakedAave are 1:1
     * @dev Not all collateral token has aave incentive
     */
    function _totalAave() internal view returns (uint256) {
        if (address(aaveIncentivesController) == address(0)) {
            return 0;
        }
        // TotalAave = Get current StakedAave rewards from controller +
        //             StakedAave balance here +
        //             Aave rewards by staking Aave in StakedAave contract
        return
            aaveIncentivesController.getRewardsBalance(getAssets(), address(this)) +
            stkAAVE.balanceOf(address(this)) +
            stkAAVE.getTotalRewardsBalance(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IVesperPool.sol";
import "./AaveV2Xy.sol";

/// @title Deposit Collateral in Aave and earn interest by depositing borrowed token in a Vesper Pool.
contract AaveV2VesperXy is AaveV2Xy {
    using SafeERC20 for IERC20;

    // Destination Grow Pool for borrowed Token
    IVesperPool public immutable vPool;
    // VSP token address
    address public immutable vsp;

    constructor(
        address _pool,
        address _swapper,
        address _rewardToken,
        address _receiptToken,
        address _borrowToken,
        address _vPool,
        address _vspAddress,
        string memory _name
    ) AaveV2Xy(_pool, _swapper, _rewardToken, _receiptToken, _borrowToken, _name) {
        require(_vspAddress != address(0), "invalid-vsp-address");
        require(address(IVesperPool(_vPool).token()) == borrowToken, "invalid-grow-pool");
        vPool = IVesperPool(_vPool);
        vsp = _vspAddress;
    }

    /// @notice Claim VSP and convert to collateral token
    function harvestVSP() external {
        address _poolRewards = vPool.poolRewards();
        if (_poolRewards != address(0)) {
            IPoolRewards(_poolRewards).claimReward(address(this));
        }
        uint256 _vspAmount = IERC20(vsp).balanceOf(address(this));
        if (_vspAmount > 0) {
            _swapExactInput(vsp, address(collateralToken), _vspAmount);
        }
    }

    /// @notice After borrowing Y, deposit to Vesper Pool
    function _afterBorrowY(uint256 _amount) internal virtual override {
        vPool.deposit(_amount);
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        IERC20(borrowToken).safeApprove(address(vPool), _amount);
        IERC20(vsp).safeApprove(address(swapper), _amount);
    }

    /// @notice Before repaying Y, withdraw it from Vesper Pool
    function _beforeRepayY(uint256 _amount) internal virtual override {
        _withdrawFromVesperPool(_amount);
    }

    /// @notice Borrowed Y balance deposited in Vesper Pool
    function _getInvestedBorrowBalance() internal view virtual override returns (uint256) {
        return
            IERC20(borrowToken).balanceOf(address(this)) +
            ((vPool.pricePerShare() * vPool.balanceOf(address(this))) / 1e18);
    }

    /// @notice Swap excess borrow for more collateral when underlying VSP pool is making profits
    function _rebalanceBorrow(uint256 _excessBorrow) internal virtual override {
        if (_excessBorrow > 0) {
            _withdrawFromVesperPool(_excessBorrow);
            uint256 _borrowedHere = IERC20(borrowToken).balanceOf(address(this));
            if (_borrowedHere > 0) {
                _safeSwapExactInput(borrowToken, address(collateralToken), _borrowedHere);
            }
        }
    }

    /// @notice Withdraw _shares proportional to collateral _amount from vPool
    function _withdrawFromVesperPool(uint256 _amount) internal {
        if (_amount > 0) {
            uint256 _pricePerShare = vPool.pricePerShare();
            uint256 _shares = (_amount * 1e18) / _pricePerShare;
            _shares = _amount > ((_shares * _pricePerShare) / 1e18) ? _shares + 1 : _shares;
            vPool.withdraw(Math.min(_shares, vPool.balanceOf(address(this))));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "../../../interfaces/aave/IAave.sol";
import "../../Strategy.sol";
import "./AaveV2Core.sol";

// solhint-disable no-empty-blocks

/// @title Deposit Collateral in Aave and earn interest by depositing borrowed token in a Vesper Pool.
contract AaveV2Xy is Strategy, AaveV2Core {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowLimit = 7_000; // 70% of actual collateral factor of protocol
    uint256 public maxBorrowLimit = 8_500; // 85% of actual collateral factor of protocol

    uint32 internal constant TWAP_PERIOD = 3600;
    address public rewardToken;
    address public borrowToken;
    AToken public vdToken; // Variable Debt Token
    address internal aBorrowToken;
    event UpdatedBorrowLimit(
        uint256 previousMinBorrowLimit,
        uint256 newMinBorrowLimit,
        uint256 previousMaxBorrowLimit,
        uint256 newMaxBorrowLimit
    );

    constructor(
        address _pool,
        address _swapper,
        address _rewardToken,
        address _receiptToken,
        address _borrowToken,
        string memory _name
    ) Strategy(_pool, _swapper, _receiptToken) AaveV2Core(_receiptToken) {
        NAME = _name;
        rewardToken = _rewardToken;
        (address _aBorrowToken, , address _vdToken) = aaveProtocolDataProvider.getReserveTokensAddresses(_borrowToken);
        vdToken = AToken(_vdToken);
        borrowToken = _borrowToken;
        aBorrowToken = _aBorrowToken;
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(aToken) || address(vdToken) == _token || borrowToken == _token;
    }

    /// @notice Returns total collateral locked in the strategy
    function tvl() external view override returns (uint256) {
        return aToken.balanceOf(address(this)) + collateralToken.balanceOf(address(this));
    }

    /// @notice After borrowing Y Hook
    function _afterBorrowY(uint256 _amount) internal virtual {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(address(aToken), _amount);
        collateralToken.safeApprove(address(aaveLendingPool), _amount);
        IERC20(borrowToken).safeApprove(address(aaveLendingPool), _amount);
        IERC20(collateralToken).safeApprove(address(swapper), _amount);
        IERC20(rewardToken).safeApprove(address(swapper), _amount);
        IERC20(borrowToken).safeApprove(address(swapper), _amount);
    }

    /**
     * @notice Claim rewardToken and transfer to new strategy
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        require(IStrategy(_newStrategy).token() == address(aToken), "wrong-receipt-token");
        _repayY(vdToken.balanceOf(address(this)));
    }

    /// @notice Before repaying Y Hook
    function _beforeRepayY(uint256 _amount) internal virtual {}

    function _borrowY(uint256 _amount) internal virtual {
        if (_amount > 0) {
            // 2 for variable rate borrow, 0 for referralCode
            aaveLendingPool.borrow(borrowToken, _amount, 2, 0, address(this));
            _afterBorrowY(_amount);
        }
    }

    /**
     * @notice Calculate borrow and repay amount based on current collateral and new deposit/withdraw amount.
     * @param _depositAmount deposit amount
     * @param _withdrawAmount withdraw amount
     * @return _borrowAmount borrow more amount
     * @return _repayAmount repay amount to keep ltv within limit
     */
    function _calculateBorrowPosition(uint256 _depositAmount, uint256 _withdrawAmount)
        internal
        view
        returns (uint256 _borrowAmount, uint256 _repayAmount)
    {
        require(_depositAmount == 0 || _withdrawAmount == 0, "all-input-gt-zero");
        uint256 _borrowed = vdToken.balanceOf(address(this));
        // If maximum borrow limit set to 0 then repay borrow
        if (maxBorrowLimit == 0) {
            return (0, _borrowed);
        }
        uint256 _collateral = aToken.balanceOf(address(this));
        // In case of withdraw, _amount can be greater than _supply
        uint256 _hypotheticalCollateral =
            _depositAmount > 0 ? _collateral + _depositAmount : _collateral > _withdrawAmount
                ? _collateral - _withdrawAmount
                : 0;
        if (_hypotheticalCollateral == 0) {
            return (0, _borrowed);
        }
        AaveOracle _aaveOracle = AaveOracle(aaveAddressesProvider_.getPriceOracle());
        // Oracle prices are in 18 decimal
        uint256 _borrowTokenPrice = _aaveOracle.getAssetPrice(borrowToken);
        uint256 _collateralTokenPrice = _aaveOracle.getAssetPrice(address(collateralToken));
        if (_borrowTokenPrice == 0 || _collateralTokenPrice == 0) {
            // Oracle problem. Lets payback all
            return (0, _borrowed);
        }
        // _collateralFactor in 4 decimal. 10_000 = 100%
        (, uint256 _collateralFactor, , , , , , , , ) =
            aaveProtocolDataProvider.getReserveConfigurationData(address(collateralToken));

        // Collateral in base currency based on oracle price and cf;
        uint256 _actualCollateralForBorrow =
            (_hypotheticalCollateral * _collateralFactor * _collateralTokenPrice) /
                (MAX_BPS * (10**IERC20Metadata(address(collateralToken)).decimals()));
        // Calculate max borrow possible in borrow token number
        uint256 _maxBorrowPossible =
            (_actualCollateralForBorrow * (10**IERC20Metadata(address(borrowToken)).decimals())) / _borrowTokenPrice;
        if (_maxBorrowPossible == 0) {
            return (0, _borrowed);
        }
        // Safe buffer to avoid liquidation due to price variations.
        uint256 _borrowUpperBound = (_maxBorrowPossible * maxBorrowLimit) / MAX_BPS;

        // Borrow up to _borrowLowerBound and keep buffer of _borrowUpperBound - _borrowLowerBound for price variation
        uint256 _borrowLowerBound = (_maxBorrowPossible * minBorrowLimit) / MAX_BPS;

        // If current borrow is greater than max borrow, then repay to achieve safe position.
        if (_borrowed > _borrowUpperBound) {
            // If borrow > upperBound then it is greater than lowerBound too.
            _repayAmount = _borrowed - _borrowLowerBound;
        } else if (_borrowLowerBound > _borrowed) {
            _borrowAmount = _borrowLowerBound - _borrowed;
            uint256 _availableLiquidity = IERC20(borrowToken).balanceOf(aBorrowToken);
            if (_borrowAmount > _availableLiquidity) {
                _borrowAmount = _availableLiquidity;
            }
        }
    }

    /// @notice Deposit collateral in Aave and adjust borrow position
    function _deposit() internal {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));

        (uint256 _borrowAmount, uint256 _repayAmount) = _calculateBorrowPosition(_collateralBalance, 0);

        if (_repayAmount > 0) {
            // Repay _borrowAmount to maintain safe position
            _repayY(_repayAmount);
            _mint(_collateralBalance);
        } else {
            // Happy path, mint more borrow more
            _mint(_collateralBalance);
            _borrowY(_borrowAmount);
        }
    }

    /// @notice Borrowed Y balance deposited here or elsewhere hook
    function _getInvestedBorrowBalance() internal view virtual returns (uint256) {
        return IERC20(borrowToken).balanceOf(address(this));
    }

    /**
     * @dev Aave support WETH as collateral.
     */
    function _mint(uint256 _amount) internal virtual {
        _deposit(address(collateralToken), _amount);
    }

    /**
     * @notice Generate report for pools accounting and also send profit and any payback to pool.
     * @dev Claim rewardToken and convert to collateral.
     */
    function _rebalance()
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        // Claim rewards and convert to collateral token
        uint256 _aaveAmount = _claimAave();
        if (_aaveAmount > 0) {
            _safeSwapExactInput(rewardToken, address(collateralToken), _aaveAmount);
        }

        uint256 _supply = aToken.balanceOf(address(this));
        uint256 _borrow = vdToken.balanceOf(address(this));

        uint256 _investedBorrowBalance = _getInvestedBorrowBalance();

        // _borrow increases every block. Convert collateral to borrowToken.
        if (_borrow > _investedBorrowBalance) {
            _swapToBorrowToken(_borrow - _investedBorrowBalance);
        } else {
            // When _investedBorrowBalance exceeds _borrow balance from Aave
            // Customize this hook to handle the excess borrowToken for profit
            _rebalanceBorrow(_investedBorrowBalance - _borrow);
        }

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _supply + _collateralHere;

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_collateralHere < _profitAndExcessDebt) {
            uint256 _totalAmountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _supply);
            if (_totalAmountToWithdraw > 0) {
                _withdrawHere(_totalAmountToWithdraw);
                _collateralHere = collateralToken.balanceOf(address(this));
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }

    /// @notice Swap excess borrow for more collateral hook
    function _rebalanceBorrow(uint256 _excessBorrow) internal virtual {}

    function _redeemX(uint256 _amount) internal virtual {
        _withdraw(address(collateralToken), address(this), _amount);
    }

    function _repayY(uint256 _amount) internal virtual {
        _beforeRepayY(_amount);
        aaveLendingPool.repay(borrowToken, _amount, 2, address(this));
    }

    /**
     * @notice Swap given token to borrowToken
     * @param _shortOnBorrow Expected output of this swap
     */
    function _swapToBorrowToken(uint256 _shortOnBorrow) internal {
        // Looking for _amountIn using fixed output amount
        uint256 _amountIn = swapper.getAmountIn(address(collateralToken), borrowToken, _shortOnBorrow);
        if (_amountIn > 0) {
            uint256 _collateralHere = collateralToken.balanceOf(address(this));
            // If we do not have enough _from token to get expected output, either get
            // some _from token or adjust expected output.
            if (_amountIn > _collateralHere) {
                // Redeem some collateral, so that we have enough collateral to get expected output
                _redeemX(_amountIn - _collateralHere);
            }
            swapper.swapExactOutput(address(collateralToken), borrowToken, _shortOnBorrow, _amountIn, address(this));
        }
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 _requireAmount) internal override {
        (, uint256 _repayAmount) = _calculateBorrowPosition(0, _requireAmount);
        if (_repayAmount > 0) {
            _repayY(_repayAmount);
        }
        // withdraw asking more than available liquidity will fail. To do safe withdraw, check
        // _requireAmount against available liquidity.
        uint256 _possibleWithdraw =
            Math.min(
                _requireAmount,
                Math.min(IERC20(receiptToken).balanceOf(address(this)), collateralToken.balanceOf(receiptToken))
            );
        _redeemX(_possibleWithdraw);
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/
    /**
     * @notice Update upper and lower borrow limit. Usually maxBorrowLimit < 100% of actual collateral factor of protocol.
     * @dev It is possible to set _maxBorrowLimit and _minBorrowLimit as 0 to not borrow anything
     * @param _minBorrowLimit It is % of actual collateral factor of protocol
     * @param _maxBorrowLimit It is % of actual collateral factor of protocol
     */
    function updateBorrowLimit(uint256 _minBorrowLimit, uint256 _maxBorrowLimit) external onlyGovernor {
        require(_maxBorrowLimit < MAX_BPS, "invalid-max-borrow-limit");
        // set _maxBorrowLimit and _minBorrowLimit to disable borrow;
        require(
            (_maxBorrowLimit == 0 && _minBorrowLimit == 0) || _maxBorrowLimit > _minBorrowLimit,
            "max-should-be-higher-than-min"
        );
        emit UpdatedBorrowLimit(minBorrowLimit, _minBorrowLimit, maxBorrowLimit, _maxBorrowLimit);
        minBorrowLimit = _minBorrowLimit;
        maxBorrowLimit = _maxBorrowLimit;
    }
}