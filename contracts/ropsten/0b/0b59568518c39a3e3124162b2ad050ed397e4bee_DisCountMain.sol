/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-04
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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

pragma solidity ^0.8.0;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
    function insert(AddressSet storage set, address value) internal returns (bool) {
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
    function insert(UintSet storage set, uint256 value) internal returns (bool) {
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

// File: contracts\interfaces\IPancakeRouter01.sol

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


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
     * by making the `nonReentrant` function external, and making it call a
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

interface IDisCountMain{
    function PlatformWalletAddress() external view returns (address);
    function treasuryWallet() external view returns (address);
    function PlatformRaisedAmountFee() external view returns (uint256);
    function isWhiteListContainsAtPool(address pool,address account) external view returns(bool);
    function isPoolBlock(address pool) external view returns (bool);
    function isWhiteList(address pool) external view returns (bool);
    function minimumClaimedDays() external view returns (uint256);
    function maximumClaimedDays() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IDiscountPool{
    function poolAdmin() external view returns (address);
    function claimState() external view returns(bool);
    function burnState() external view returns(bool);
    function createdState() external view returns(bool);
    function poolTimeUpdate(uint256,uint256) external;
}

pragma solidity ^0.8.0;

contract DiscountPool is Ownable,ReentrancyGuard,Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using Address for address payable;

    IDisCountMain public DiscountMain;
    IBEP20 public saleToken;
    IPancakeRouter02 public pancake; 

    address public poolAdmin;
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    bool public buyBackState;
    bool public claimState;
    bool public burnState;
    bool public createdState;
    bool public autoBuyBackEnabled;
    bool public initializeState;
    bool inBuyBack;
    
    uint256 public totalAmounUsedtoBuyBack;
    uint256 public soldTokens;
    uint256 public redeemTokens;
    uint256 public minimumBuyBackAmount;
    uint256 public saleAmount;
    uint256 public discount;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minimumDeposit;
    uint256 public maximumDeposit;
    uint256 public buyBackFee;
    uint256 public claimDays;

    string public profileURI;
    
    struct userLockStore {
        uint256 lockAmount;
        uint256 lockTime;
        uint256 claimTime;
    }    

    mapping (address => userLockStore) public userLockInfo;

    constructor () {}
    
    receive() external payable {}

    modifier onlyAuthorisedPeople() {
        require((msg.sender == poolAdmin) || (msg.sender == DiscountMain.PlatformWalletAddress()), "unable to access");
        _;
    }

    event lockEvent(
        address indexed user,
        uint256 amount,
        uint256 time
    );
    event unlockEvent(
        address indexed user,
        uint256 amount,
        uint256 time
    );

        /**
     * @dev Triggers stopped state.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - The contract must not be paused.
    */
    function pause() public onlyAuthorisedPeople{
      _pause();
    }
    
    /**
     * @dev Triggers normal state.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - The contract must not be unpaused.
     */
    function unpause() public onlyAuthorisedPeople{
      _unpause();
    }

    function initialize(
        address _DisCountMain,
        address _token,
        address _poolAdmin,
        uint256 _saleAmount,
        uint256 _discount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minimumDeposit,
        uint256 _maximumDeposit,
        uint256 _buyBackFee,
        uint256 _claimDays,
        string memory _profileURI
    ) external {
        require(!initializeState, "Initializable: contract is already initialized");
        require(_poolAdmin != address(0), "poolAdmin Can't be zero");
        DiscountMain = IDisCountMain(_DisCountMain);
        saleToken = IBEP20(_token);
        poolAdmin = _poolAdmin;
        saleAmount = _saleAmount;
        discount = _discount;
        startTime = _startTime;
        endTime = _endTime;
        minimumDeposit = _minimumDeposit;
        maximumDeposit = _maximumDeposit;
        buyBackFee = _buyBackFee;
        minimumBuyBackAmount = 25e16;
        claimDays = _claimDays;
        initializeState = true;
        createdState = true;
        profileURI = _profileURI;

        // testnet
        pancake = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        // mainnet
        // pancake = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    modifier buyBackLock {
        require(!inBuyBack, "ReentrancyGuard: reentrant call");
        inBuyBack = true;
        _;
        inBuyBack = false;
    }

    function setProfileURI(string memory _profileURI) public onlyAuthorisedPeople {
        profileURI = _profileURI;
    }

    function setClaimDays(uint256 day) public onlyAuthorisedPeople {
        require(day >= DiscountMain.minimumClaimedDays() && day <= DiscountMain.maximumClaimedDays(), "claim days is invalid");
        claimDays = day;
    }

    /**
     * @dev Return the PlatformRaisedAmountFee.
     */     
    function getPlatFormBuyBackFee() public view returns (uint256) {
        return DiscountMain.PlatformRaisedAmountFee();
    }

    /**
     * @dev Returns the amount of tokens owned by `pool`.
     */  
    function bnbBalance() public view returns (uint256) {
        return (address(this).balance);        
    }

    /**
     * @dev Returns the amount of tokens owned by `pool`.
     */  
    function tokenBalance() public view returns (uint256) {
        return saleToken.balanceOf(address(this));
    }

    /**
     * @dev Transfers poolAdmin ownership of the contract to a new account (`newOwner`).
     * Can only be called by the poolAdmin.
     */
    function transferProjectOwnerShip(address newOwner) external returns (bool) {        
        require(newOwner != address(0), "can't be a zero address");

        poolAdmin = newOwner;
        return true;
    }

    /**
     * @dev This function is help to update the minimumBuyBackAmount percentage.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `amount` minimumBuyBackAmount value.
     */ 
    function minimumBuyBackAmountUpdate(uint256 amount,bool status) external onlyAuthorisedPeople returns (bool)  {
        minimumBuyBackAmount = amount;
        autoBuyBackEnabled = status;
        return true;
    }

    /**
     * @dev This function is help to the swap to pool token0 to token1.
     * 
     * Can only be called by the discountSale contract.
     * 
     * - E.g. User can swap bnb to busd. User can able to receive 30% more than pancakeswap.
     */   
    function swap() external payable nonReentrant whenNotPaused returns (bool) {
        require(!isBlockedPool(), "pool is blocked");
        require(minimumDeposit <= msg.value && maximumDeposit >= msg.value, "deposit amount is invalid");
        require(startTime < block.timestamp && endTime > block.timestamp, "expired");

        if(DiscountMain.isWhiteList(address(this))){
            require(DiscountMain.isWhiteListContainsAtPool(address(this),msg.sender), "only whitelist people can able to access"); 
        }

        address[] memory path = new address[](2);
        path[0] = pancake.WETH();
        path[1] = address(saleToken);

        uint[] memory getAmountOut = pancake.getAmountsOut(msg.value,path);
        uint256 amountOut = getAmountOut[1].add(getAmountOut[1].mul(discount).div(100));
        soldTokens = soldTokens.add(amountOut);

        if(claimDays == 0){
            saleToken.safeTransfer(msg.sender,amountOut);
        }else {
            userLockInfo[msg.sender].lockAmount = userLockInfo[msg.sender].lockAmount.add(amountOut);
            userLockInfo[msg.sender].lockTime = block.timestamp;
            emit lockEvent(msg.sender,amountOut,block.timestamp);
        }
        if(autoBuyBackEnabled && address(this).balance >= minimumBuyBackAmount){
            autoBuyBack(path,minimumBuyBackAmount);
        }
        return true;
    }

    function autoBuyBack(address[] memory path,uint256 amount) private buyBackLock returns(bool){
        pancake.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );
        return true;
    }

    /**
     * @dev This function is help to the buyback the all funds.
     *
     * Can only be called by the project owner and platform owner. 
     * 
     * 
     * - E.g. After the discount sale admin can be able to buyback the bnb to token.
     * 
     */  
    function buyBack() external whenNotPaused nonReentrant onlyAuthorisedPeople{
        require(endTime < block.timestamp, "sale still not over");

        uint256 currentBalance = address(this).balance;        
        uint256 getAmountOut = currentBalance.mul(buyBackFee).div(1e2);
        uint256 platFormFee = currentBalance.mul(getPlatFormBuyBackFee()).div(1e2);
        payable(DiscountMain.PlatformWalletAddress()).sendValue(platFormFee / 2);
        payable(DiscountMain.treasuryWallet()).sendValue(platFormFee / 2);
        totalAmounUsedtoBuyBack = totalAmounUsedtoBuyBack.add(getAmountOut.add(platFormFee));
        buyBackState = true;

        address[] memory path = new address[](2);
        path[0] = pancake.WETH();
        path[1] = address(saleToken);

        pancake.swapExactETHForTokensSupportingFeeOnTransferTokens{value: getAmountOut}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }
 
    /**
     * @dev This function is help to the claim all remaining tokens
     * 
     * Can only be called by the discountSale contract.
     * 
     * - E.g. after the confirm execution,admin can be able to claim the remaining token
     * - If platform owner doing this process, all the tokens will goes to the project owner.
     */    
    function claim() external nonReentrant whenNotPaused onlyAuthorisedPeople returns (bool) {
        require(endTime < block.timestamp, "sale still not over");
        require(buyBackState, "buyBack still not happen");
        payable(poolAdmin).sendValue(address(this).balance);
        saleToken.safeTransfer(poolAdmin,saleToken.balanceOf(address(this)).sub(soldTokens.sub(redeemTokens)));
        claimState = true;
        return true;
    }

    /**
     * @dev This function is help to the burn all remaining tokens.
     * 
     * Can only be called by the discountSale contract.
     * 
     * - E.g. after the confirm execution,admin can be able to burn the remaining token
     * - If platform owner doing this process, all the tokens will goes to the dead wallet.
     */    
    function burn() external nonReentrant whenNotPaused onlyAuthorisedPeople returns (bool){
        require(buyBackState, "buyBack still not happen");
        require(endTime < block.timestamp, "sale still not over");
        payable(poolAdmin).sendValue(address(this).balance);
        IBEP20(saleToken).safeTransfer(deadWallet,saleToken.balanceOf(address(this)).sub(soldTokens.sub(redeemTokens)));
        burnState = true;
        return true;
    }

    function redeem() public nonReentrant whenNotPaused {
        userLockStore storage store = userLockInfo[msg.sender];
        require(store.lockAmount > 0, "Invalid user");
        require(unlockTime() < block.timestamp, "time invalid");
        
        saleToken.safeTransfer(msg.sender,store.lockAmount);
        redeemTokens = redeemTokens.add(store.lockAmount);
        store.lockAmount = 0;
        store.claimTime = block.timestamp;
        emit unlockEvent(msg.sender,store.lockAmount,block.timestamp);
    }

    function unlockTime() public view returns (uint256){
        return (endTime + (84600 * claimDays));
    }

    /**
     * @dev This function is help to the recover the stucked funds.
     *
     * Can only be called by the platform owner. 
     * 
     * Requirements:
     *
     * - `token` token contract address.
     * - `amount` amount of tokens
     * 
     */      
    function recoverOtherToken(address _token,uint256 amount) external {
        require(msg.sender == DiscountMain.PlatformWalletAddress(), "unable to access");
        require(address(saleToken)  != _token, "is not possible to recover the funds");
        saleToken.safeTransfer(DiscountMain.PlatformWalletAddress(),amount);
    }

    function poolTimeUpdate(uint256 _startTime,uint256 _endTime) external onlyAuthorisedPeople{
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @dev Returns the pool current state.It means block or unblock.
     */
    function isBlockedPool() public view returns (bool) {
        return DiscountMain.isPoolBlock(address(this));
    }
}


pragma solidity ^0.8.0;

contract DisCountMain is Ownable, Pausable{
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    uint256 public PlatformFlatFee;
    uint256 public PlatformSoldTokensFee;
    uint256 public PlatformRaisedAmountFee;
    uint256 public minimumBuyBack;
    uint256 public maximumBuyBack;
    uint256 public maxSellDuration;
    uint256 public minimumDiscount;
    uint256 public maximumDiscount;
    uint256 public minimumClaimedDays;
    uint256 public maximumClaimedDays;
    
    bool public platformSoldTokensFeeEnabled;
    
    address public treasuryWallet;
    address public PlatformWalletAddress;

    mapping (uint256 => address) private _discountContract;
    mapping (address => address) public pairInfo;
    mapping (address => bool) public isWhiteList;
    mapping (address => EnumerableSet.AddressSet) private poolWhiteListStore;
    mapping (address => bool) private pairBlock;
    EnumerableSet.AddressSet private pools;
    
    receive() external payable {}
    
    constructor() {
        PlatformFlatFee = 0.001 ether;
        PlatformSoldTokensFee = 2;
        PlatformRaisedAmountFee = 2;
        treasuryWallet = 0x6aC646018d6c82c1e51836658F9ca95885443e1c;
        PlatformWalletAddress = 0x6aC646018d6c82c1e51836658F9ca95885443e1c;
        minimumBuyBack = 70;
        maximumBuyBack = 100;
        maxSellDuration = 6048000;
        minimumDiscount = 1;
        maximumDiscount = 90;
        minimumClaimedDays = 1;
        maximumClaimedDays = 90;
    }    

    /**
     * @dev Triggers stopped state.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - The contract must not be paused.
    */
    function pause() public onlyOwner{
      _pause();
    }
    
    /**
     * @dev Triggers normal state.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - The contract must not be unpaused.
     */
    function unpause() public onlyOwner{
      _unpause();
    }

    /**
     * @dev This function is help to update the discount minimum and maximum percentage.
     * 
     * Can only be called by the project owner.
     * 
     * Requirements:
     *
     * - `minimum` minimum discount value.
     * - `maximum` maximum discount value.
     */  
    function setDiscountMinAndMax(uint256 minimum,uint256 maximum) public onlyOwner {
        minimumDiscount = minimum;
        maximumDiscount = maximum;
    }

    function setClaimDays(uint256 _min,uint256 _max) public onlyOwner {
        minimumClaimedDays = _min;
        maximumClaimedDays = _max;
    }

    /**
     * @dev This function is help to update the MinimumBuyBack fee and MaximumBuyBack fee.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `minimum` minimum buyback fee. eg like 70%.
     * - `maximum` maximum buyback fee. eg like 100%.
     */    
    function buyBackUpdate(uint256 minimum,uint256 maximum) public onlyOwner {
        minimumBuyBack = minimum;
        maximumBuyBack = maximum;
    }

    /**
     * @dev This function is help to update the platformSoldTokensFeeEnabled state.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `status` true means enable and false means disable.
     */      
    function PlatformSoldTokensFeeEnabledUpdate(bool status) external onlyOwner {
        platformSoldTokensFeeEnabled = status;
    }

    /**
     * @dev This function is help to update the PlatformFlatFee percentage.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `amount` PlatformFlatFee value.
     */          
    function PlatformFlatFeeUpdate(uint256 amount) public onlyOwner {
        require(amount != 0, "invalid amount");
        PlatformFlatFee = amount;
    }

    /**
     * @dev This function is help to update the PlatformSoldTokensFee percentage.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `amount` PlatformSoldTokensFee value.
     */    
    function PlatformSoldTokensFeeUpdate(uint256 amount) public onlyOwner {
        require(amount != 0, "invalid amount");
        PlatformSoldTokensFee = amount;
    }

    /**
     * @dev This function is help to update the treasuryWallet account.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `account` new treasuryWallet.
     */    
    function treasuryWalletUpdate(address account) public onlyOwner {
        treasuryWallet = account;
    }
    
    /**
     * @dev This function is help to update the PlatformWalletAddress account.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `account` new PlatformWalletAddress.
     */ 
    function PlatformWalletAddressUpdate(address account) public onlyOwner {
        PlatformWalletAddress = account;
    }

    /**
     * @dev This function is help to update the PlatformRaisedAmountFee percentage.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `amount` new PlatformRaisedAmountFee.
     */     
    function PlatformRaisedAmountFeeUpdate(uint256 amount) public onlyOwner {
        require(amount != 0, "invalid amount");
        PlatformRaisedAmountFee = amount;
    }

    /**
     * @dev This function is help to update the maxSellDuration duration. 
     * Eg contract currently have a 7 days.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `newDuration` new Duration.
     */     
    function maxSellDurationUpdate(uint256 newDuration) public onlyOwner {
        maxSellDuration = newDuration;
    }

    /**
     * @dev This function is help to block the particular pool.
     * If it's enable, no one can able to use the that discountSale contract.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `pool` discountPool address.     
     * - `status` true means enable and false means disable.
     */     
    function blockPool(address pool,bool status) public onlyOwner {
        require(IDiscountPool(pool).createdState(), "invalid pool address provided");
        pairBlock[pool] = status;
    }
    
    function poolTimeUpdateForTesting(address pool,uint256 startTime,uint256 endTime) public onlyOwner{
        IDiscountPool(pool).poolTimeUpdate(startTime,endTime);
    }

    /**
     * @dev This function is help to update the platformSoldTokensFeeEnabled state.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - `pool` discountPool address.       
     * - `status` true means enable and false means disable.
     */      
    function poolWhiteListUpdate(address pool,bool status) public {
        require(msg.sender == owner() || msg.sender == IDiscountPool(pool).poolAdmin(), "unable to access");
        
        isWhiteList[pool] = status;
    }

    /**
     * @dev This function is help to add the address of users authorized to participate in whitelist.
     * 
     * Can only be called by the project owner and platform owner.
     * 
     * Requirements:
     *
     * - `pool` discountPool address.       
     * - `accounts` user accounts.
     */ 
    function addWhiteListForPool(address pool,address[] memory accounts) public {
        require(isWhiteList[pool], "whitelist is not enable");
        require(msg.sender == owner() || msg.sender == IDiscountPool(pool).poolAdmin(), "unable to access");

        for(uint256 i;i<accounts.length;i++){
            poolWhiteListStore[pool].insert(accounts[i]);
        }
    }

    /**
     * @dev This function is help to remove the users from the whitelist.
     * 
     * Can only be called by the project owner and platform owner.
     * 
     * Requirements:
     *
     * - `pool` discountPool address.       
     * - `accounts` user accounts.
     */    
    function removeWhiteListForPool(address pool,address[] memory accounts) public {
        require(isWhiteList[pool], "whitelist is not enable");
        require(msg.sender == owner() || msg.sender == IDiscountPool(pool).poolAdmin(), "unable to access");

        for(uint256 i;i<accounts.length;i++){
            poolWhiteListStore[pool].remove(accounts[i]);
        }
    }

    struct Parameters {
        address token;
        uint256 saleAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 discount;
        address poolAdmin;
        uint256 minimumDeposit;
        uint256 maximumDeposit;
        uint256 buyBackFee;
        uint256 claimDays;
        string profile;
    }

    /**
     * @dev This function is help to create the discountPool.
     * 
     * No restriction, anyone can call.
     * 
     * Requirements:
     *
     * - `token` from and to tokens.From token must be authorized by admin.       
     * - `saleAmount` How many token our you going to give the discountPool.       
     * - `startTime` Pool starttime.       
     * - `endTime` Pool endtime.       
     * - `discount` discount percentage eg 30%.       
     * - `poolAdmin` project owner.        
     * - `minimumDeposit` Minimum amount of from token.       
     * - `maximumDeposit` Maximum amount of from token.
     * - `buyBackFee` Buyback fee.
     */     
    function createPool(Parameters calldata store) external payable whenNotPaused {
        require(block.timestamp < store.startTime && store.startTime < store.endTime && store.startTime.add(maxSellDuration) >= store.endTime, "invalid time duration");
        require(msg.value >= PlatformFlatFee, "insufficient bnb amount");
        require(store.buyBackFee >= minimumBuyBack && store.buyBackFee <= maximumBuyBack, "buyback is invalid");
        require(store.discount >= minimumDiscount && store.discount <= maximumDiscount, "Discount");
        require(store.claimDays >= minimumClaimedDays && store.claimDays <= maximumClaimedDays, "claim days is invalid");
        
        if(poolContains(pairInfo[store.token])){
            require(IDiscountPool(pairInfo[store.token]).claimState() || 
            IDiscountPool(pairInfo[store.token]).burnState(), "still not overed");
        }

        DiscountPool newPool = new DiscountPool();

        newPool.initialize(
            address(this),
            store.token,
            store.poolAdmin,
            store.saleAmount,
            store.discount,
            store.startTime,
            store.endTime,
            store.minimumDeposit,
            store.maximumDeposit,
            store.buyBackFee,
            store.claimDays,
            store.profile
        );
        
        IBEP20(store.token).safeTransferFrom(_msgSender(),address(newPool),store.saleAmount);
        
        if(platformSoldTokensFeeEnabled){
            uint256 saleFee = store.saleAmount.mul(PlatformSoldTokensFee).div(1e2);
            IBEP20(store.token).safeTransferFrom(_msgSender(),owner(),saleFee);
        }

        pairInfo[store.token] = address(newPool);
        pools.insert(address(newPool));
        payable(treasuryWallet).sendValue(PlatformFlatFee/2);
        payable(PlatformWalletAddress).sendValue(PlatformFlatFee/2);
    }
    
    /**
     * @dev Returns true if the contract is in the discountpool. 
     */
    function poolContains(address pool) public view returns (bool) {
        return pools.contains(pool);
    }

    /**
     * @dev Returns the number of discountPools.
     */
    function poolLength() public view returns (uint256) {
        return pools.length();
    }

    /**
     * @dev Returns the value stored at position `index` in the discountPool.
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function poolAt(uint256 index) public view returns (address) {
        return pools.at(index);
    }

    /**
     * @dev Return the entire discountPool in an array
     */
    function allPool() public view returns (address[] memory) {
        return pools.values();
    }

    /**
     * @dev Returns true if the pool is in the whitelist. 
     */   
    function isWhiteListContainsAtPool(address pool,address account) external view returns (bool) {
        return poolWhiteListStore[pool].contains(account);
    }

    /**
     * @dev Returns the number of accounts in the whitelist.
     */
    function whiteListPoolLength(address pool) public view returns (uint256) {
        return poolWhiteListStore[pool].length();
    }

    /**
     * @dev Returns the value stored at position `index` in the wgitelistpool.
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function whiteListPoolAt(address pool,uint256 index) public view returns (address) {
        return poolWhiteListStore[pool].at(index);
    }

    /**
     * @dev Return the entire whitelist accounts in an array.
     */
    function whiteListPoolAccounts(address pool) public view returns (address[] memory) {
        return poolWhiteListStore[pool].values();
    }

    /**
     * @dev Returns true if the pool is in the blocked. 
     */      
    function isPoolBlock(address pool) external view returns (bool) {
        return pairBlock[pool];
    }
}