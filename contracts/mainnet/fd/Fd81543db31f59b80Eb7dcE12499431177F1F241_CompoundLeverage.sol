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

interface CToken {
    function accrueInterest() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrow(uint256 borrowAmount) external returns (uint256);

    function mint() external payable; // For ETH

    function mint(uint256 mintAmount) external returns (uint256); // For ERC20

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable; // For ETH

    function repayBorrow(uint256 repayAmount) external returns (uint256); // For ERC20

    function transfer(address user, uint256 amount) external returns (bool);

    function getCash() external view returns (uint256);

    function transferFrom(
        address owner,
        address user,
        uint256 amount
    ) external returns (bool);

    function underlying() external view returns (address);

    function comptroller() external view returns (address);
}

interface Comptroller {
    function claimComp(address holder, address[] memory) external;

    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function compAccrued(address holder) external view returns (uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function markets(address market)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isCompted
        );

    function oracle() external view returns (address);
}

interface Oracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);

    function price(string memory symbol) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/** In order to keep code/files short, all libraries and interfaces are trimmed as per Vesper need */

library Account {
    enum Status {Normal, Liquid, Vapor}
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
}

library Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (publicly)
        Sell, // sell an amount of some token (publicly)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}

library Types {
    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }
}

interface ISoloMargin {
    function getMarketTokenAddress(uint256 marketId) external view returns (address);

    function getNumMarkets() external view returns (uint256);

    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
}

/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for Solo must implement in order to ingest data.
 */
interface ICallee {
    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to Solo
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    ) external;
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

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "vesper-pools/contracts/interfaces/vesper/IVesperPool.sol";
import "vesper-pools/contracts/Errors.sol";
import "../interfaces/aave/IAave.sol";
import "../interfaces/dydx/ISoloMargin.sol";

/**
 * @title FlashLoanHelper:: This contract does all heavy lifting to get flash loan via Aave and DyDx.
 * @dev End user has to override _flashLoanLogic() function to perform logic after flash loan is done.
 *      Also needs to approve token to aave and dydx via _approveToken function.
 *      2 utility internal functions are also provided to activate/deactivate flash loan providers.
 *      Utility function are provided as internal so that end user can choose controlled access via public functions.
 */
abstract contract FlashLoanHelper {
    using SafeERC20 for IERC20;

    PoolAddressesProvider internal poolAddressesProvider;

    address internal constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    uint256 public dyDxMarketId;
    bytes32 private constant AAVE_PROVIDER_ID = 0x0100000000000000000000000000000000000000000000000000000000000000;
    bool public isAaveActive = false;
    bool public isDyDxActive = false;

    constructor(address _aaveAddressesProvider) {
        require(_aaveAddressesProvider != address(0), Errors.INPUT_ADDRESS_IS_ZERO);

        poolAddressesProvider = PoolAddressesProvider(_aaveAddressesProvider);
    }

    function _updateAaveStatus(bool _status) internal {
        isAaveActive = _status;
    }

    function _updateDyDxStatus(bool _status, address _token) internal {
        if (_status) {
            dyDxMarketId = _getMarketIdFromTokenAddress(SOLO, _token);
        }
        isDyDxActive = _status;
    }

    /// @notice Approve all required tokens for flash loan
    function _approveToken(address _token, uint256 _amount) internal {
        IERC20(_token).safeApprove(SOLO, _amount);
        IERC20(_token).safeApprove(poolAddressesProvider.getLendingPool(), _amount);
    }

    /// @dev Override this function to execute logic which uses flash loan amount
    function _flashLoanLogic(bytes memory _data, uint256 _repayAmount) internal virtual;

    /***************************** Aave flash loan functions ***********************************/

    bool private awaitingFlash = false;

    /**
     * @notice This is entry point for Aave flash loan
     * @param _token Token for which we are taking flash loan
     * @param _amountDesired Flash loan amount
     * @param _data This will be passed downstream for processing. It can be empty.
     */
    function _doAaveFlashLoan(
        address _token,
        uint256 _amountDesired,
        bytes memory _data
    ) internal returns (uint256 _amount) {
        require(isAaveActive, Errors.AAVE_FLASH_LOAN_NOT_ACTIVE);
        AaveLendingPool _aaveLendingPool = AaveLendingPool(poolAddressesProvider.getLendingPool());
        AaveProtocolDataProvider _aaveProtocolDataProvider =
            AaveProtocolDataProvider(poolAddressesProvider.getAddress(AAVE_PROVIDER_ID));
        // Check token liquidity in Aave
        (uint256 _availableLiquidity, , , , , , , , , ) = _aaveProtocolDataProvider.getReserveData(_token);
        if (_amountDesired > _availableLiquidity) {
            _amountDesired = _availableLiquidity;
        }

        address[] memory assets = new address[](1);
        assets[0] = _token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amountDesired;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        // Anyone can call aave flash loan to us, so we need some protection
        awaitingFlash = true;

        // function params: receiver, assets, amounts, modes, onBehalfOf, data, referralCode
        _aaveLendingPool.flashLoan(address(this), assets, amounts, modes, address(this), _data, 0);
        _amount = _amountDesired;
        awaitingFlash = false;
    }

    /// @dev Aave will call this function after doing flash loan
    function executeOperation(
        address[] calldata, /*_assets*/
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address _initiator,
        bytes calldata _data
    ) external returns (bool) {
        require(msg.sender == poolAddressesProvider.getLendingPool(), "!aave-pool");
        require(awaitingFlash, Errors.INVALID_FLASH_LOAN);
        require(_initiator == address(this), Errors.INVALID_INITIATOR);

        // Flash loan amount + flash loan fee
        uint256 _repayAmount = _amounts[0] + _premiums[0];
        _flashLoanLogic(_data, _repayAmount);
        return true;
    }

    /***************************** Aave flash loan functions ends ***********************************/

    /***************************** DyDx flash loan functions ***************************************/

    /**
     * @notice This is entry point for DyDx flash loan
     * @param _token Token for which we are taking flash loan
     * @param _amountDesired Flash loan amount
     * @param _data This will be passed downstream for processing. It can be empty.
     */
    function _doDyDxFlashLoan(
        address _token,
        uint256 _amountDesired,
        bytes memory _data
    ) internal returns (uint256 _amount) {
        require(isDyDxActive, Errors.DYDX_FLASH_LOAN_NOT_ACTIVE);

        // Check token liquidity in DyDx
        uint256 amountInSolo = IERC20(_token).balanceOf(SOLO);
        if (_amountDesired > amountInSolo) {
            _amountDesired = amountInSolo;
        }
        // Repay amount, amount with fee, can be 2 wei higher. Consider 2 wei as fee
        uint256 repayAmount = _amountDesired + 2;

        // Encode custom data for callFunction
        bytes memory _callData = abi.encode(_data, repayAmount);

        // 1. Withdraw _token
        // 2. Call callFunction(...) which will call loanLogic
        // 3. Deposit _token back
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(dyDxMarketId, _amountDesired);
        operations[1] = _getCallAction(_callData);
        operations[2] = _getDepositAction(dyDxMarketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        ISoloMargin(SOLO).operate(accountInfos, operations);
        _amount = _amountDesired;
    }

    /// @dev DyDx calls this function after doing flash loan
    function callFunction(
        address _sender,
        Account.Info memory, /* _account */
        bytes memory _callData
    ) external {
        (bytes memory _data, uint256 _repayAmount) = abi.decode(_callData, (bytes, uint256));
        require(msg.sender == SOLO, "!solo");
        require(_sender == address(this), Errors.INVALID_INITIATOR);
        _flashLoanLogic(_data, _repayAmount);
    }

    /********************************* DyDx helper functions *********************************/
    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 1});
    }

    function _getMarketIdFromTokenAddress(address _solo, address token) internal view returns (uint256) {
        ISoloMargin solo = ISoloMargin(_solo);

        uint256 numMarkets = solo.getNumMarkets();

        address curToken;
        for (uint256 i = 0; i < numMarkets; i++) {
            curToken = solo.getMarketTokenAddress(i);

            if (curToken == token) {
                return i;
            }
        }

        revert(Errors.NO_MARKET_ID_FOUND);
    }

    function _getWithdrawAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    function _getCallAction(bytes memory data) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: 0
                }),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: data
            });
    }

    function _getDepositAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    /***************************** DyDx flash loan functions end *****************************/
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
// Heavily inspired from CompoundLeverage strategy of Yearn. https://etherscan.io/address/0x4031afd3B0F71Bace9181E554A9E680Ee4AbE7dF#code

pragma solidity 0.8.9;

import "../../interfaces/compound/ICompound.sol";
import "../Strategy.sol";
import "../FlashLoanHelper.sol";
import "./CompoundLeverageBase.sol";

// solhint-disable no-empty-blocks

/// @title This strategy will deposit collateral token in Compound and based on position
/// it will borrow same collateral token. It will use borrowed asset as supply and borrow again.
contract CompoundLeverage is CompoundLeverageBase, FlashLoanHelper {
    using SafeERC20 for IERC20;

    constructor(
        address _pool,
        address _swapper,
        address _comptroller,
        address _rewardToken,
        address _aaveAddressesProvider,
        address _receiptToken,
        string memory _name
    )
        CompoundLeverageBase(_pool, _swapper, _comptroller, _rewardToken, _receiptToken, _name)
        FlashLoanHelper(_aaveAddressesProvider)
    {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        FlashLoanHelper._approveToken(address(collateralToken), _amount);
    }

    /**
     * @dev Aave flash is used only for withdrawal due to high fee compare to DyDx
     * @param _flashAmount Amount for flash loan
     * @param _shouldRepay Flag indicating we want to leverage or deleverage
     * @return Total amount we leverage or deleverage using flash loan
     */
    function _doFlashLoan(uint256 _flashAmount, bool _shouldRepay) internal override returns (uint256) {
        uint256 _totalFlashAmount;
        // Due to less fee DyDx is our primary flash loan provider
        if (isDyDxActive && _flashAmount > 0) {
            bytes memory _data = abi.encode(_flashAmount, _shouldRepay);
            _totalFlashAmount = _doDyDxFlashLoan(address(collateralToken), _flashAmount, _data);
            _flashAmount -= _totalFlashAmount;
        }
        if (isAaveActive && _shouldRepay && _flashAmount > 0) {
            bytes memory _data = abi.encode(_flashAmount, _shouldRepay);
            _totalFlashAmount += _doAaveFlashLoan(address(collateralToken), _flashAmount, _data);
        }
        return _totalFlashAmount;
    }

    /**
     * @notice This function will be called by flash loan
     * @dev In case of borrow, DyDx is preferred as fee is so low that it does not effect
     * our collateralRatio and liquidation risk.
     */
    function _flashLoanLogic(bytes memory _data, uint256 _repayAmount) internal override {
        (uint256 _amount, bool _deficit) = abi.decode(_data, (uint256, bool));
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        require(_collateralHere >= _amount, "FLASH_FAILED"); // to stop malicious calls

        //if in deficit we repay amount and then withdraw
        if (_deficit) {
            _repayBorrow(_amount);
            //if we are withdrawing we take more to cover fee
            _redeemUnderlying(_repayAmount);
        } else {
            _mint(_collateralHere);
            //borrow more to cover fee
            _borrowCollateral(_repayAmount);
        }
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/

    function updateAaveStatus(bool _status) external onlyGovernor {
        _updateAaveStatus(_status);
    }

    function updateDyDxStatus(bool _status) external virtual onlyGovernor {
        _updateDyDxStatus(_status, address(collateralToken));
    }
}

// SPDX-License-Identifier: MIT
// Heavily inspired from CompoundLeverage strategy of Yearn. https://etherscan.io/address/0x4031afd3B0F71Bace9181E554A9E680Ee4AbE7dF#code

pragma solidity 0.8.9;

import "../../interfaces/compound/ICompound.sol";
import "../Strategy.sol";

/// @title This strategy will deposit collateral token in Compound and based on position
/// it will borrow same collateral token. It will use borrowed asset as supply and borrow again.
abstract contract CompoundLeverageBase is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowRatio = 5_000; // 50%
    uint256 public maxBorrowRatio = 6_000; // 60%
    uint256 internal constant COLLATERAL_FACTOR_LIMIT = 9_500; // 95%
    CToken internal cToken;

    Comptroller public immutable comptroller;
    address public rewardToken;

    event UpdatedBorrowRatio(
        uint256 previousMinBorrowRatio,
        uint256 newMinBorrowRatio,
        uint256 previousMaxBorrowRatio,
        uint256 newMaxBorrowRatio
    );

    constructor(
        address _pool,
        address _swapper,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        string memory _name
    ) Strategy(_pool, _swapper, _receiptToken) {
        NAME = _name;
        require(_comptroller != address(0), "comptroller-address-is-zero");
        comptroller = Comptroller(_comptroller);
        rewardToken = _rewardToken;

        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
    }

    /**
     * @notice Current borrow ratio, calculated as current borrow divide by max allowed borrow
     * Return value is based on basis points, i.e. 7500 = 75% ratio
     */
    function currentBorrowRatio() external view returns (uint256) {
        (uint256 _supply, uint256 _borrow) = getPosition();
        return _borrow == 0 ? 0 : (_borrow * MAX_BPS) / _supply;
    }

    /// @notice Return supply and borrow position. Position may return few block old value
    function getPosition() public view returns (uint256 _supply, uint256 _borrow) {
        (, uint256 _cTokenBalance, uint256 _borrowBalance, uint256 _exchangeRate) =
            cToken.getAccountSnapshot(address(this));
        _supply = (_cTokenBalance * _exchangeRate) / 1e18;
        _borrow = _borrowBalance;
    }

    /// @inheritdoc Strategy
    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(cToken) || _token == address(collateralToken);
    }

    /// @inheritdoc Strategy
    function tvl() public view virtual override returns (uint256) {
        (uint256 _supply, uint256 _borrow) = getPosition();
        return collateralToken.balanceOf(address(this)) + _supply - _borrow;
    }

    /**
     * @dev Adjust position by normal leverage and deleverage.
     * @param _adjustBy Amount by which we want to increase or decrease _borrow
     * @param _shouldRepay True indicate we want to deleverage
     * @return amount Actual adjusted amount
     */
    function _adjustPosition(uint256 _adjustBy, bool _shouldRepay) internal returns (uint256 amount) {
        // We can get position via view function, as this function will be called after _calculateDesiredPosition
        (uint256 _supply, uint256 _borrow) = getPosition();

        // If no borrow then there is nothing to deleverage
        if (_borrow == 0 && _shouldRepay) {
            return 0;
        }

        uint256 collateralFactor = _getCollateralFactor();

        if (_shouldRepay) {
            amount = _normalDeleverage(_adjustBy, _supply, _borrow, collateralFactor);
        } else {
            amount = _normalLeverage(_adjustBy, _supply, _borrow, collateralFactor);
        }
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(address(cToken), _amount);
        IERC20(rewardToken).safeApprove(address(swapper), _amount);
    }

    /**
     * @dev Payback borrow before migration
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        require(IStrategy(_newStrategy).token() == address(cToken), "wrong-receipt-token");
        minBorrowRatio = 0;
        // It will calculate amount to repay based on borrow limit and payback all
        _deposit();
    }

    function _borrowCollateral(uint256 _amount) internal virtual {
        require(cToken.borrow(_amount) == 0, "borrow-from-compound-failed");
    }

    /**
     * @notice Calculate borrow position based on borrow ratio, current supply, borrow, amount
     * being deposited or withdrawn.
     * @param _amount Collateral amount
     * @param _isDeposit Flag indicating whether we are depositing _amount or withdrawing
     * @return _position Amount of borrow that need to be adjusted
     * @return _shouldRepay Flag indicating whether _position is borrow amount or repay amount
     */
    function _calculateDesiredPosition(uint256 _amount, bool _isDeposit)
        internal
        returns (uint256 _position, bool _shouldRepay)
    {
        uint256 _totalSupply = cToken.balanceOfUnderlying(address(this));
        uint256 _currentBorrow = cToken.borrowBalanceStored(address(this));
        // If minimum borrow limit set to 0 then repay borrow
        if (minBorrowRatio == 0) {
            return (_currentBorrow, true);
        }

        uint256 _supply = _totalSupply - _currentBorrow;

        // In case of withdraw, _amount can be greater than _supply
        uint256 _newSupply = _isDeposit ? _supply + _amount : _supply > _amount ? _supply - _amount : 0;

        // (supply * borrowRatio)/(BPS - borrowRatio)
        uint256 _borrowUpperBound = (_newSupply * maxBorrowRatio) / (MAX_BPS - maxBorrowRatio);
        uint256 _borrowLowerBound = (_newSupply * minBorrowRatio) / (MAX_BPS - minBorrowRatio);

        // If our current borrow is greater than max borrow allowed, then we will have to repay
        // some to achieve safe position else borrow more.
        if (_currentBorrow > _borrowUpperBound) {
            _shouldRepay = true;
            // If borrow > upperBound then it is greater than lowerBound too.
            _position = _currentBorrow - _borrowLowerBound;
        } else if (_currentBorrow < _borrowLowerBound) {
            _shouldRepay = false;
            // We can borrow more.
            _position = _borrowLowerBound - _currentBorrow;
        }
    }

    /// @notice Claim rewardToken and convert rewardToken into collateral token.
    function _claimRewardsAndConvertTo(address _toToken) internal virtual {
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        comptroller.claimComp(address(this), _markets);
        uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardAmount > 0) {
            _safeSwapExactInput(rewardToken, _toToken, _rewardAmount);
        }
    }

    /// @notice Deposit collateral in Compound and adjust borrow position
    function _deposit() internal {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        (uint256 _position, bool _shouldRepay) = _calculateDesiredPosition(_collateralBalance, true);
        // Supply collateral to compound.
        _mint(_collateralBalance);

        // During reinvest, _shouldRepay will be false which indicate that we will borrow more.
        _position -= _doFlashLoan(_position, _shouldRepay);

        uint256 i;
        while (_position > 0 && i <= 6) {
            unchecked {
                _position -= _adjustPosition(_position, _shouldRepay);
                i++;
            }
        }
    }

    /**
     * @dev Aave flash is used only for withdrawal due to high fee compare to DyDx
     * @param _flashAmount Amount for flash loan
     * @param _shouldRepay Flag indicating we want to leverage or deleverage
     * @return Total amount we leverage or deleverage using flash loan
     */
    function _doFlashLoan(uint256 _flashAmount, bool _shouldRepay) internal virtual returns (uint256);

    /**
     * @notice Generate report for pools accounting and also send profit and any payback to pool.
     * @dev Claim rewardToken and convert to collateral.
     */
    function _generateReport()
        internal
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        (, , , , uint256 _totalDebt, , , uint256 _debtRatio, ) = IVesperPool(pool).strategy(address(this));

        // Claim rewardToken and convert to collateral token
        _claimRewardsAndConvertTo(address(collateralToken));
        // Invested collateral = supply - borrow
        uint256 _investedCollateral =
            cToken.balanceOfUnderlying(address(this)) - cToken.borrowBalanceStored(address(this));

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _investedCollateral + _collateralHere;

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_collateralHere < _profitAndExcessDebt) {
            uint256 _totalAmountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _investedCollateral);
            if (_totalAmountToWithdraw > 0) {
                _withdrawHere(_totalAmountToWithdraw);
                _collateralHere = collateralToken.balanceOf(address(this));
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;

        // Handle scenario if debtRatio is zero and some supply left.
        // Remaining tokens are profit.
        if (_debtRatio == 0) {
            (uint256 _supply, uint256 _borrow) = getPosition();
            if (_supply > 0 && _borrow == 0) {
                // This will redeem all cTokens this strategy has
                _redeemUnderlying(MAX_UINT_VALUE);
                _profit += _supply;
            }
        }
    }

    /**
     * @notice Get Collateral Factor
     */
    function _getCollateralFactor() internal view virtual returns (uint256 _collateralFactor) {
        (, _collateralFactor, ) = comptroller.markets(address(cToken));
        // Take 95% of collateralFactor to avoid any rounding issue.
        _collateralFactor = (_collateralFactor * COLLATERAL_FACTOR_LIMIT) / MAX_BPS;
    }

    /**
     * @dev Compound support ETH as collateral not WETH. So ETH strategy can override
     * below functions and handle wrap/unwrap of WETH.
     */
    function _mint(uint256 _amount) internal virtual {
        require(cToken.mint(_amount) == 0, "supply-to-compound-failed");
    }

    /**
     * Deleverage: Reduce borrow to achieve safe position
     * @param _maxDeleverage Reduce borrow by this amount
     * @return _deleveragedAmount Amount we actually reduced
     */
    function _normalDeleverage(
        uint256 _maxDeleverage,
        uint256 _supply,
        uint256 _borrow,
        uint256 _collateralFactor
    ) internal returns (uint256 _deleveragedAmount) {
        uint256 _theoreticalSupply;

        if (_collateralFactor > 0) {
            // Calculate minimum supply required to support _borrow
            _theoreticalSupply = (_borrow * 1e18) / _collateralFactor;
        }

        _deleveragedAmount = _supply - _theoreticalSupply;

        if (_deleveragedAmount >= _borrow) {
            _deleveragedAmount = _borrow;
        }
        if (_deleveragedAmount >= _maxDeleverage) {
            _deleveragedAmount = _maxDeleverage;
        }

        _redeemUnderlying(_deleveragedAmount);
        _repayBorrow(_deleveragedAmount);
    }

    /**
     * Leverage: Borrow more
     * @param _maxLeverage Max amount to borrow
     * @return _leveragedAmount Amount we actually borrowed
     */
    function _normalLeverage(
        uint256 _maxLeverage,
        uint256 _supply,
        uint256 _borrow,
        uint256 _collateralFactor
    ) internal returns (uint256 _leveragedAmount) {
        // Calculate maximum we can borrow at current _supply
        uint256 theoreticalBorrow = (_supply * _collateralFactor) / 1e18;

        _leveragedAmount = theoreticalBorrow - _borrow;

        if (_leveragedAmount >= _maxLeverage) {
            _leveragedAmount = _maxLeverage;
        }
        _borrowCollateral(_leveragedAmount);
        _mint(collateralToken.balanceOf(address(this)));
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

    function _redeemUnderlying(uint256 _amount) internal virtual {
        if (_amount == MAX_UINT_VALUE) {
            // Withdraw all cTokens
            require(cToken.redeem(cToken.balanceOf(address(this))) == 0, "withdraw-from-compound-failed");
        } else {
            // Withdraw underlying
            require(cToken.redeemUnderlying(_amount) == 0, "withdraw-from-compound-failed");
        }
    }

    function _repayBorrow(uint256 _amount) internal virtual {
        require(cToken.repayBorrow(_amount) == 0, "repay-to-compound-failed");
    }

    /// @dev Withdraw collateral here.
    function _withdrawHere(uint256 _amount) internal override {
        (uint256 _position, bool _shouldRepay) = _calculateDesiredPosition(_amount, false);
        if (_shouldRepay) {
            // Do deleverage by flash loan
            _position -= _doFlashLoan(_position, _shouldRepay);

            // If we still have _position to deleverage do it via normal deleverage
            uint256 i;
            while (_position > 0 && i <= 10) {
                unchecked {
                    _position -= _adjustPosition(_position, true);
                    i++;
                }
            }

            (uint256 _supply, uint256 _borrow) = getPosition();
            // If we are not able to deleverage enough
            if (_position > 0) {
                // Calculate redeemable at current borrow and supply.
                uint256 _supplyToSupportBorrow;
                if (maxBorrowRatio > 0) {
                    _supplyToSupportBorrow = (_borrow * MAX_BPS) / maxBorrowRatio;
                }
                // Current supply minus supply required to support _borrow at _maxBorrowRatio
                uint256 _redeemable = _supply - _supplyToSupportBorrow;
                if (_amount > _redeemable) {
                    _amount = _redeemable;
                }
            }
            // Position is 0 and amount > supply due to deleverage
            else if (_amount > _supply) {
                _amount = _supply;
            }
        }
        _redeemUnderlying(_amount);
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/

    /**
     * @notice Update upper and lower borrow ratio
     * @dev It is possible to set 0 as _minBorrowRatio to not borrow anything
     * @param _minBorrowRatio Minimum % we want to borrow
     * @param _maxBorrowRatio Maximum % we want to borrow
     */
    function updateBorrowRatio(uint256 _minBorrowRatio, uint256 _maxBorrowRatio) external onlyGovernor {
        // CollateralFactor is 1e18 based and borrow ratio is 1e4 based. Hence using 1e14 for conversion.
        require(_maxBorrowRatio < (_getCollateralFactor() / 1e14), "invalid-max-borrow-limit");
        require(_maxBorrowRatio > _minBorrowRatio, "max-should-be-higher-than-min");
        emit UpdatedBorrowRatio(minBorrowRatio, _minBorrowRatio, maxBorrowRatio, _maxBorrowRatio);
        minBorrowRatio = _minBorrowRatio;
        maxBorrowRatio = _maxBorrowRatio;
    }
}