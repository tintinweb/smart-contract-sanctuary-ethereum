/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

// SPDX-License-Identifier: MIT

// File: contracts/libs/Address.sol

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: contracts/libs/IERC20.sol

pragma solidity >=0.4.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the erc20 token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: contracts/libs/SafeMath.sol

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// File: contracts/libs/SafeERC20.sol

pragma solidity ^0.8.0;




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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/libs/EnumerableSet.sol

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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
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
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
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
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
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
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
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
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts/libs/IERC721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: contracts/libs/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/libs/IERC721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// File: contracts/libs/Context.sol

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

// File: contracts/libs/Ownable.sol

pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/libs/Pausable.sol

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Ownable {
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
    function pause() external onlyOwner whenNotPaused {
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
    function _unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/libs/ReentrancyGuard.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


// File: contracts/NftStaking.sol



pragma solidity ^0.8.0;


contract NftStaking is ReentrancyGuard, Pausable, IERC721Receiver {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    enum Rarity {
        COMMON,
        RARE,
        ICONIC,
        GOLDEN
    }

    enum StakeType {
        UNLOCKED,
        LOCKED,
        PAIR_LOCKED
    }

    bytes32 public SEASON1_MERKLE_ROOT;
    bytes32 public SEASON2_MERKLE_ROOT;

    /** Season1 / Season2 NFT address */
    address public _season1Nft;
    address public _season2Nft;
    /** Reward Token address */
    address public _rewardToken;

    // Withdraw lock period
    uint256 public _lockPeriod = 60 days; // Lock period 60 days
    uint16 public _unstakeFee = 500; // Unstake fee 5%
    uint16 public _forcedUnstakeFee = 10000; // Force unstake fee 100%

    struct NftStakeInfo {
        Rarity _rarity;
        bool _isLocked;
        uint256 _pairedTokenId;
        uint256 _stakedAt;
    }

    struct UserInfo {
        EnumerableSet.UintSet _season1Nfts;
        EnumerableSet.UintSet _season2Nfts;
        mapping(uint256 => NftStakeInfo) _season1StakeInfos;
        mapping(uint256 => NftStakeInfo) _season2StakeInfos;
        uint256 _pending; // Not claimed
        uint256 _totalClaimed; // Claimed so far
        uint256 _lastClaimedAt;
        uint256 _pairCount; // Paired count
    }

    mapping(Rarity => uint256) _season1BaseRpds; // RPD: reward per day
    mapping(Rarity => uint16) _season1LockedExtras;
    mapping(Rarity => mapping(StakeType => uint16)) _season2Extras;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) private _userInfo;

    event Staked(
        address indexed account,
        uint256 tokenId,
        bool isSeason1,
        bool isLocked
    );
    event Unstaked(address indexed account, uint256 tokenId, bool isSeason1);
    event Locked(address indexed account, uint256 tokenId, bool isSeason1);
    event Paired(
        address indexed account,
        uint256 season1TokenId,
        uint256 season2TokenId
    );
    event Harvested(address indexed account, uint256 amount);
    event InsufficientRewardToken(
        address indexed account,
        uint256 amountNeeded,
        uint256 balance
    );

    constructor(address __rewardToken, address __season1Nft) {
        IERC20(__rewardToken).balanceOf(address(this));
        IERC721(__season1Nft).balanceOf(address(this));

        _rewardToken = __rewardToken;
        _season1Nft = __season1Nft;

        // Base reward per day
        _season1BaseRpds[Rarity.COMMON] = 50 ether;
        _season1BaseRpds[Rarity.RARE] = 125 ether;
        _season1BaseRpds[Rarity.ICONIC] = 250 ether;

        // Season1 locked cases extra percentage
        _season1LockedExtras[Rarity.COMMON] = 2000; // 20%
        _season1LockedExtras[Rarity.COMMON] = 2000; // 20%
        _season1LockedExtras[Rarity.COMMON] = 2000; // 20%

        // Season2 extra percentage
        _season2Extras[Rarity.COMMON][StakeType.UNLOCKED] = 1000;
        _season2Extras[Rarity.COMMON][StakeType.LOCKED] = 2000;
        _season2Extras[Rarity.COMMON][StakeType.PAIR_LOCKED] = 5000;
        _season2Extras[Rarity.RARE][StakeType.UNLOCKED] = 2000;
        _season2Extras[Rarity.RARE][StakeType.LOCKED] = 2000;
        _season2Extras[Rarity.RARE][StakeType.PAIR_LOCKED] = 5000;
        _season2Extras[Rarity.ICONIC][StakeType.UNLOCKED] = 3500;
        _season2Extras[Rarity.ICONIC][StakeType.LOCKED] = 2000;
        _season2Extras[Rarity.ICONIC][StakeType.PAIR_LOCKED] = 5000;
        _season2Extras[Rarity.GOLDEN][StakeType.UNLOCKED] = 5000;
        _season2Extras[Rarity.GOLDEN][StakeType.LOCKED] = 2000;
        _season2Extras[Rarity.GOLDEN][StakeType.PAIR_LOCKED] = 5000;
    }

    function setSeason2Nft(address __season2Nft) external onlyOwner {
        IERC721(__season2Nft).balanceOf(address(this));
        _season2Nft = __season2Nft;
    }

    function getRewardInNormal(
        uint256 __rpd,
        uint256 __stakedAt,
        uint256 __lastClaimedAt
    ) private view returns (uint256) {
        uint256 timePassed = __stakedAt > __lastClaimedAt
            ? block.timestamp.sub(__stakedAt)
            : block.timestamp.sub(__lastClaimedAt);
        return __rpd.mul(timePassed).div(1 days);
    }

    function getRewardInLocked(
        uint256 __rpd,
        uint256 __extraRate,
        uint256 __stakedAt,
        uint256 __lastClaimedAt
    ) private view returns (uint256 lockedAmount, uint256 unlockedAmount) {
        uint256 lockEndAt = __stakedAt.add(_lockPeriod);
        if (lockEndAt > block.timestamp) {
            lockedAmount = __rpd
                .mul(block.timestamp.sub(__stakedAt))
                .mul(uint256(10000).add(__extraRate))
                .div(10000)
                .div(1 days);
        } else {
            uint256 timePassed = __lastClaimedAt >= lockEndAt
                ? block.timestamp.sub(__lastClaimedAt)
                : block.timestamp.sub(__stakedAt);
            unlockedAmount = __rpd
                .mul(timePassed)
                .mul(uint256(10000).add(__extraRate))
                .div(10000)
                .div(1 days);
        }
    }

    function getSeason1Rewards(address __account, uint256 __nftId)
        private
        view
        returns (uint256 lockedAmount, uint256 unlockedAmount)
    {
        UserInfo storage user = _userInfo[__account];
        NftStakeInfo storage season1StakeInfo = user._season1StakeInfos[
            __nftId
        ];
        Rarity season1Rarity = season1StakeInfo._rarity;
        uint256 baseRpd = _season1BaseRpds[season1Rarity];

        // For the locked staking add extra percentage
        if (season1StakeInfo._isLocked) {
            (lockedAmount, unlockedAmount) = getRewardInLocked(
                baseRpd,
                _season1LockedExtras[season1Rarity],
                season1StakeInfo._stakedAt,
                user._lastClaimedAt
            );
        } else {
            unlockedAmount = getRewardInNormal(
                baseRpd,
                season1StakeInfo._stakedAt,
                user._lastClaimedAt
            );
        }
    }

    function getPairedSeason2Rewards(address __account, uint256 __nftId)
        private
        view
        returns (uint256 lockedAmount, uint256 unlockedAmount)
    {
        UserInfo storage user = _userInfo[__account];
        NftStakeInfo storage season1StakeInfo = user._season1StakeInfos[
            __nftId
        ];
        NftStakeInfo storage season2StakeInfo = user._season2StakeInfos[
            season1StakeInfo._pairedTokenId
        ];
        Rarity season1Rarity = season1StakeInfo._rarity;
        Rarity season2Rarity = season2StakeInfo._rarity;
        uint256 baseRpd = _season1BaseRpds[season1Rarity];
        if (season1StakeInfo._pairedTokenId == 0) {
            lockedAmount = 0;
            unlockedAmount = 0;
        } else if (season2StakeInfo._isLocked) {
            // extra rate is wheter season1 is locked or not
            uint256 rpdExtraRate = season1StakeInfo._isLocked
                ? _season2Extras[season2Rarity][StakeType.PAIR_LOCKED]
                : _season2Extras[season2Rarity][StakeType.LOCKED];
            (lockedAmount, unlockedAmount) = getRewardInLocked(
                baseRpd,
                rpdExtraRate,
                season2StakeInfo._stakedAt,
                user._lastClaimedAt
            );
        } else {
            // base rpd for the season2 unlocked
            baseRpd = baseRpd
                .mul(_season2Extras[season2Rarity][StakeType.UNLOCKED])
                .div(10000);
            unlockedAmount = getRewardInNormal(
                baseRpd,
                season2StakeInfo._stakedAt,
                user._lastClaimedAt
            );
        }
    }

    function viewProfit(address __account)
        public
        view
        returns (
            uint256 totalEarned,
            uint256 totalClaimed,
            uint256 lockedRewards,
            uint256 unlockedRewards
        )
    {
        UserInfo storage user = _userInfo[__account];
        totalClaimed = user._totalClaimed;
        unlockedRewards = user._pending;

        uint256 countSeason1Nfts = user._season1Nfts.length();
        uint256 index;
        for (index = 0; index < countSeason1Nfts; index++) {
            uint256 pendingLockedRewards = 0;
            uint256 pendingUnlockedRewards = 0;

            (pendingLockedRewards, pendingUnlockedRewards) = getSeason1Rewards(
                __account,
                user._season1Nfts.at(index)
            );

            // Add season1 reward
            if (pendingLockedRewards > 0) {
                lockedRewards = lockedRewards.add(pendingLockedRewards);
            }
            if (pendingUnlockedRewards > 0) {
                unlockedRewards = unlockedRewards.add(pendingUnlockedRewards);
            }

            (
                pendingLockedRewards,
                pendingUnlockedRewards
            ) = getPairedSeason2Rewards(__account, user._season1Nfts.at(index));

            // Add season2 reward
            if (pendingLockedRewards > 0) {
                lockedRewards = lockedRewards.add(pendingLockedRewards);
            }
            if (pendingUnlockedRewards > 0) {
                unlockedRewards = unlockedRewards.add(pendingUnlockedRewards);
            }
        }

        totalEarned = totalClaimed.add(lockedRewards).add(unlockedRewards);
    }

    /**
     * @notice Get season1 nfts
     */
    function viewSeason1Nfts(address __account)
        external
        view
        returns (uint256[] memory season1Nfts, bool[] memory lockStats)
    {
        UserInfo storage user = _userInfo[__account];
        uint256 countSeason1Nfts = user._season1Nfts.length();

        season1Nfts = new uint256[](countSeason1Nfts);
        lockStats = new bool[](countSeason1Nfts);
        uint256 index;
        uint256 tokenId;
        for (index = 0; index < countSeason1Nfts; index++) {
            tokenId = user._season1Nfts.at(index);
            season1Nfts[index] = tokenId;
            lockStats[index] = user._season1StakeInfos[tokenId]._isLocked;
        }
    }

    /**
     * @notice Get season2 nfts
     */
    function viewSeason2Nfts(address __account)
        external
        view
        returns (uint256[] memory season2Nfts, bool[] memory lockStats)
    {
        UserInfo storage user = _userInfo[__account];
        uint256 countSeason2Nfts = user._season2Nfts.length();

        season2Nfts = new uint256[](countSeason2Nfts);
        lockStats = new bool[](countSeason2Nfts);
        uint256 index;
        uint256 tokenId;
        for (index = 0; index < countSeason2Nfts; index++) {
            tokenId = user._season2Nfts.at(index);
            season2Nfts[index] = tokenId;
            lockStats[index] = user._season2StakeInfos[tokenId]._isLocked;
        }
    }

    /**
     * @notice Get paired season1 / season2 nfts
     */
    function viewPairedNfts(address __account)
        external
        view
        returns (
            uint256[] memory pairedSeason1Nfts,
            uint256[] memory pairedSeason2Nfts
        )
    {
        UserInfo storage user = _userInfo[__account];
        uint256 pairCount = user._pairCount;
        pairedSeason1Nfts = new uint256[](pairCount);
        pairedSeason2Nfts = new uint256[](pairCount);
        uint256 index;
        uint256 tokenId;
        uint256 rindex = 0;
        uint256 season2NftCount = user._season2Nfts.length();
        for (index = 0; index < season2NftCount; index++) {
            tokenId = user._season2Nfts.at(index);
            if (user._season2StakeInfos[tokenId]._pairedTokenId == 0) {
                continue;
            }
            pairedSeason1Nfts[rindex] = user
                ._season2StakeInfos[tokenId]
                ._pairedTokenId;
            pairedSeason2Nfts[rindex] = tokenId;
            rindex = rindex.add(1);
        }
    }

    // Verify that a given leaf is in the tree.
    function isWhiteListedSeason1(bytes32 _leafNode, bytes32[] memory _proof)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, SEASON1_MERKLE_ROOT, _leafNode);
    }

    function isWhiteListedSeason2(bytes32 _leafNode, bytes32[] memory _proof)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, SEASON2_MERKLE_ROOT, _leafNode);
    }

    // Generate the leaf node (just the hash of tokenID concatenated with the account address)
    function toLeaf(
        uint256 tokenID,
        uint256 index,
        uint256 amount
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, tokenID, amount));
    }

    function setMerkleRoot(bytes32 _season1Root, bytes32 _season2Root)
        external
        onlyOwner
    {
        SEASON1_MERKLE_ROOT = _season1Root;
        SEASON2_MERKLE_ROOT = _season2Root;
    }

    function updateFeeValues(uint16 __unstakeFee, uint16 __forcedUnstakeFee)
        external
        onlyOwner
    {
        _unstakeFee = __unstakeFee;
        _forcedUnstakeFee = __forcedUnstakeFee;
    }

    function updateLockPeriod(uint256 __lockPeriod) external onlyOwner {
        require(__lockPeriod > 0, "Invalid lock period");
        _lockPeriod = __lockPeriod;
    }

    function updateSeason1BaseRpd(Rarity __rarity, uint256 __rpd)
        external
        onlyOwner
    {
        require(__rpd > 0, "Non zero values required");
        _season1BaseRpds[__rarity] = __rpd;
    }

    function updateSeason1LockedExtraPercent(
        Rarity __rarity,
        uint16 __lockedExtraPercent
    ) external onlyOwner {
        _season1LockedExtras[__rarity] = __lockedExtraPercent;
    }

    function updateSeason2ExtraPercent(
        Rarity __rarity,
        StakeType __stakeType,
        uint16 __extraPercent
    ) external onlyOwner {
        _season2Extras[__rarity][__stakeType] = __extraPercent;
    }

    function isStaked(address __account, uint256 __tokenId)
        external
        view
        returns (bool)
    {
        UserInfo storage user = _userInfo[__account];
        return
            user._season1Nfts.contains(__tokenId) ||
            user._season2Nfts.contains(__tokenId);
    }

    /**
     * @notice Claim rewards
     */
    function claimRewards() external {
        UserInfo storage user = _userInfo[_msgSender()];
        (, , , uint256 unlockedRewards) = viewProfit(_msgSender());
        if (unlockedRewards > 0) {
            uint256 feeAmount = unlockedRewards.mul(_unstakeFee).div(10000);
            if (feeAmount > 0) {
                IERC20(_rewardToken).safeTransfer(DEAD, feeAmount);
                unlockedRewards = unlockedRewards.sub(feeAmount);
            }
            if (unlockedRewards > 0) {
                user._totalClaimed = user._totalClaimed.add(unlockedRewards);
                IERC20(_rewardToken).safeTransfer(_msgSender(), unlockedRewards);
            }
        }
        user._lastClaimedAt = block.timestamp;
    }

    /**
     * @notice Stake season1 nft
     */
    function stakeSeason1(
        bool __lockedStaking,
        uint256[] calldata __tokenIDList,
        uint256[] calldata __indexList,
        uint256[] calldata __rarityList,
        bytes32[][] calldata __proofList
    ) external nonReentrant whenNotPaused {
        require(
            IERC721(_season1Nft).isApprovedForAll(_msgSender(), address(this)),
            "Not approve nft to staker address"
        );

        UserInfo storage user = _userInfo[_msgSender()];
        for (uint256 i = 0; i < __tokenIDList.length; i++) {
            // Check if the params are correct
            require(
                isWhiteListedSeason1(
                    toLeaf(__tokenIDList[i], __indexList[i], __rarityList[i]),
                    __proofList[i]
                ),
                "Invalid params"
            );

            IERC721(_season1Nft).safeTransferFrom(
                _msgSender(),
                address(this),
                __tokenIDList[i]
            );

            user._season1Nfts.add(__tokenIDList[i]);
            user._season1StakeInfos[__tokenIDList[i]] = NftStakeInfo({
                _rarity: Rarity(__rarityList[i]),
                _isLocked: __lockedStaking,
                _stakedAt: block.timestamp,
                _pairedTokenId: 0
            });

            emit Staked(_msgSender(), __tokenIDList[i], true, __lockedStaking);
        }
    }

    /**
     * @notice Stake season2 nft
     */
    function stakeSeason2(
        bool __lockedStaking,
        uint256[] calldata __tokenIDList,
        uint256[] calldata __indexList,
        uint256[] calldata __rarityList,
        bytes32[][] calldata __proofList
    ) external nonReentrant whenNotPaused {
        require(
            IERC721(_season2Nft).isApprovedForAll(_msgSender(), address(this)),
            "Not approve nft to staker address"
        );

        UserInfo storage user = _userInfo[_msgSender()];
        for (uint256 i = 0; i < __tokenIDList.length; i++) {
            // Check if the params are correct
            require(
                isWhiteListedSeason2(
                    toLeaf(__tokenIDList[i], __indexList[i], __rarityList[i]),
                    __proofList[i]
                ),
                "Invalid params"
            );

            IERC721(_season2Nft).safeTransferFrom(
                _msgSender(),
                address(this),
                __tokenIDList[i]
            );

            user._season2Nfts.add(__tokenIDList[i]);
            user._season2StakeInfos[__tokenIDList[i]] = NftStakeInfo({
                _rarity: Rarity(__rarityList[i]),
                _isLocked: __lockedStaking,
                _stakedAt: block.timestamp,
                _pairedTokenId: 0
            });

            emit Staked(_msgSender(), __tokenIDList[i], false, __lockedStaking);
        }
    }

    function unstakeSeason1(uint256[] calldata __tokenIDList)
        external
        nonReentrant
    {
        UserInfo storage user = _userInfo[_msgSender()];
        for (uint256 i = 0; i < __tokenIDList.length; i++) {
            require(
                user._season1Nfts.contains(__tokenIDList[i]),
                "Not staked one of nfts"
            );

            IERC721(_season1Nft).safeTransferFrom(
                address(this),
                _msgSender(),
                __tokenIDList[i]
            );

            // locked rewards are sent to rewards back to the pool
            // unlocked rewards are added to the user rewards
            (, uint256 unlockedRewards) = getSeason1Rewards(
                _msgSender(),
                __tokenIDList[i]
            );
            user._pending = user._pending.add(unlockedRewards);

            user._season1Nfts.remove(__tokenIDList[i]);
            // If it was paired with a season2 nft, unpair them
            uint256 pairedTokenId = user
                ._season1StakeInfos[__tokenIDList[i]]
                ._pairedTokenId;
            if (pairedTokenId > 0) {
                user._season2StakeInfos[pairedTokenId]._pairedTokenId = 0;
                user._pairCount = user._pairCount.sub(1);
            }

            delete user._season1StakeInfos[__tokenIDList[i]];

            emit Unstaked(_msgSender(), __tokenIDList[i], true);
        }
    }

    function unstakeSeason2(uint256[] calldata __tokenIDList)
        external
        nonReentrant
    {
        UserInfo storage user = _userInfo[_msgSender()];
        for (uint256 i = 0; i < __tokenIDList.length; i++) {
            require(
                user._season2Nfts.contains(__tokenIDList[i]),
                "Not staked one of nfts"
            );

            IERC721(_season2Nft).safeTransferFrom(
                address(this),
                _msgSender(),
                __tokenIDList[i]
            );

            // If it was paired with a season1 nft, unpair them
            uint256 pairedTokenId = user
                ._season2StakeInfos[__tokenIDList[i]]
                ._pairedTokenId;

            if (pairedTokenId > 0) {
                // locked rewards are sent to rewards back to the pool
                // unlocked rewards are added to the user rewards
                (, uint256 unlockedRewards) = getPairedSeason2Rewards(
                    _msgSender(),
                    pairedTokenId
                );
                user._pending = user._pending.add(unlockedRewards);
            }

            user._season2Nfts.remove(__tokenIDList[i]);

            if (pairedTokenId > 0) {
                user._season1StakeInfos[pairedTokenId]._pairedTokenId = 0;
                user._pairCount = user._pairCount.sub(1);
            }
            delete user._season2StakeInfos[__tokenIDList[i]];

            emit Unstaked(_msgSender(), __tokenIDList[i], false);
        }
    }

    /**
     * @notice Lock season1 nft from the unlocked pool to the lock pool
     */
    function lockSeason1Nfts(uint256[] calldata __tokenIDList)
        external
        onlyOwner
    {
        UserInfo storage user = _userInfo[_msgSender()];
        for (uint256 i = 0; i < __tokenIDList.length; i++) {
            // Check if the params are correct
            require(
                user._season1Nfts.contains(__tokenIDList[i]),
                "One of nfts not staked yet"
            );
            require(
                !user._season1StakeInfos[__tokenIDList[i]]._isLocked,
                "Locked already"
            );
            (, uint256 unlockedRewards) = getSeason1Rewards(
                _msgSender(),
                __tokenIDList[i]
            );
            user._pending = user._pending.add(unlockedRewards);

            user._season1StakeInfos[__tokenIDList[i]]._isLocked = true;
            user._season1StakeInfos[__tokenIDList[i]]._stakedAt = block
                .timestamp;
            emit Locked(_msgSender(), __tokenIDList[i], true);
        }
    }

    /**
     * @notice Lock season2 nft from the unlocked pool to the lock pool
     */
    function lockSeason2Nfts(uint256[] calldata __tokenIDList)
        external
        onlyOwner
    {
        UserInfo storage user = _userInfo[_msgSender()];
        for (uint256 i = 0; i < __tokenIDList.length; i++) {
            // Check if the params are correct
            require(
                user._season2Nfts.contains(__tokenIDList[i]),
                "One of nfts not staked yet"
            );
            require(
                !user._season2StakeInfos[__tokenIDList[i]]._isLocked,
                "Locked already"
            );
            uint256 pairedTokenId = user
                ._season2StakeInfos[__tokenIDList[i]]
                ._pairedTokenId;

            if (pairedTokenId > 0) {
                (, uint256 unlockedRewards) = getPairedSeason2Rewards(
                    _msgSender(),
                    pairedTokenId
                );
                user._pending = user._pending.add(unlockedRewards);
            }
            user._season2StakeInfos[__tokenIDList[i]]._isLocked = true;
            user._season2StakeInfos[__tokenIDList[i]]._stakedAt = block
                .timestamp;

            emit Locked(_msgSender(), __tokenIDList[i], false);
        }
    }

    /**
     * @notice
     */
    function pairNfts(uint256 __season1TokenID, uint256 __season2TokenID)
        external
        nonReentrant
        whenNotPaused
    {
        UserInfo storage user = _userInfo[_msgSender()];
        require(
            user._season1Nfts.contains(__season1TokenID) &&
                user._season2Nfts.contains(__season2TokenID),
            "One of nfts is not staked"
        );
        require(
            user._season1StakeInfos[__season1TokenID]._pairedTokenId == 0 &&
                user._season2StakeInfos[__season2TokenID]._pairedTokenId == 0,
            "Already paired"
        );
        user
            ._season1StakeInfos[__season1TokenID]
            ._pairedTokenId = __season2TokenID;
        user
            ._season2StakeInfos[__season2TokenID]
            ._pairedTokenId = __season1TokenID;
        user._season2StakeInfos[__season2TokenID]._stakedAt = block.timestamp;
        user._pairCount = user._pairCount.add(1);

        emit Paired(_msgSender(), __season1TokenID, __season2TokenID);
    }

    function safeRewardTransfer(address __to, uint256 __amount)
        internal
        returns (uint256)
    {
        uint256 balance = IERC20(_rewardToken).balanceOf(address(this));
        if (balance >= __amount) {
            IERC20(_rewardToken).safeTransfer(__to, __amount);
            return __amount;
        }

        if (balance > 0) {
            IERC20(_rewardToken).safeTransfer(__to, balance);
        }
        emit InsufficientRewardToken(__to, __amount, balance);
        return balance;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}