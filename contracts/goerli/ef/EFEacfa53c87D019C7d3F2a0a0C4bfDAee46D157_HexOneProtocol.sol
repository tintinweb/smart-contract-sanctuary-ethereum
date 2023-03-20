// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IHexOneProtocol.sol";
import "./interfaces/IHexOneVault.sol";
import "./interfaces/IHexOneStakingMaster.sol";
import "./interfaces/IHexOneToken.sol";

contract HexOneProtocol is Ownable, IHexOneProtocol {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private vaults;

    /// @notice Allowed token info based on allowed vaults.    
    EnumerableSet.AddressSet private allowedTokens;

    /// @notice Minimum stake duration. (days)
    uint256 public MIN_DURATION;

    /// @notice Maximum stake duration. (days)
    uint256 public MAX_DURATION;

    /// @notice The address of $HEX1.
    address public hexOneToken;

    /// @notice The address of staking master.
    address public stakingMaster;

    /// @notice The address of HexOneEscrow.
    address public hexOneEscrow;

    /// @dev The address to burn tokens.
    address public DEAD;

    uint16 public FIXED_POINT;

    /// @notice Show vault address from token address.
    mapping(address => address) private vaultInfos;

    /// @notice Show deposited token addresses by user.
    mapping(address => EnumerableSet.AddressSet) private depositedTokenInfos;

    /// @notice Fee Info by token.
    mapping(address => Fee) public fees;

    constructor (
        address _hexOneToken,
        address[] memory _vaults,
        address _stakingMaster,
        uint256 _minDuration,
        uint256 _maxDuration
    ) {
        require (_hexOneToken != address(0), "zero $HEX1 token address");
        require (_maxDuration > _minDuration, "max Duration is less min duration");
        require (_stakingMaster != address(0), "zero staking master address");
        MIN_DURATION = _minDuration;
        MAX_DURATION = _maxDuration;
        hexOneToken = _hexOneToken;
        _setVaults(_vaults, true);
        stakingMaster = _stakingMaster;

        DEAD = 0x000000000000000000000000000000000000dEaD;
        FIXED_POINT = 1000;
    }

    /// @inheritdoc IHexOneProtocol
    function setMinDuration(uint256 _minDuration) external override onlyOwner {
        require (_minDuration < MAX_DURATION, "minDuration is bigger than maxDuration");
        MIN_DURATION = _minDuration;
    }

    /// @inheritdoc IHexOneProtocol
    function setMaxDuration(uint256 _maxDuration) external override onlyOwner {
        require (_maxDuration > MIN_DURATION, "maxDuration is less than minDuration");
        MAX_DURATION = _maxDuration;
    }

    /// @inheritdoc IHexOneProtocol
    function setVaults(address[] memory _vaults, bool _add) external onlyOwner override {
        _setVaults(_vaults, _add);
    }

    /// @inheritdoc IHexOneProtocol
    function setEscrowContract(address _escrowCA) external onlyOwner override {
        require (_escrowCA != address(0), "zero escrow contract address");
        hexOneEscrow = _escrowCA;
    }

    /// @inheritdoc IHexOneProtocol
    function setStakingPool(address _stakingMaster) external onlyOwner override {
        stakingMaster = _stakingMaster;
    }

    /// @inheritdoc IHexOneProtocol
    function isAllowedToken(
        address _token
    ) external view override returns (bool) {
        return allowedTokens.contains(_token);
    }

    /// @inheritdoc IHexOneProtocol
    function getVaultAddress(
        address _token
    ) external view override returns (address) {
        return vaultInfos[_token];
    }

    /// @inheritdoc IHexOneProtocol
    function setDepositFee(address _token, uint16 _fee) external onlyOwner override {
        require (allowedTokens.contains(_token), "not allowed token");
        require (_fee < FIXED_POINT, "invalid fee rate");
        fees[_token] = Fee(_fee, true);
    }

    /// @inheritdoc IHexOneProtocol
    function setDepositFeeEnable(address _token, bool _enable) external onlyOwner override {
        require (allowedTokens.contains(_token), "not allowed token");
        fees[_token].enabled = _enable;
    }

    /// @inheritdoc IHexOneProtocol
    function borrowHexOne(
        address _token,
        uint256 _depositId,
        uint256 _amount
    ) external override {
        address sender = msg.sender;
        require (sender != address(0), "zero caller address");
        require (allowedTokens.contains(_token), "not allowed token");
        require (depositedTokenInfos[sender].contains(_token), "not deposited token");

        IHexOneVault hexOneVault = IHexOneVault(vaultInfos[_token]);
        hexOneVault.borrowHexOne(sender, _depositId, _amount);
        IHexOneToken(hexOneToken).mintToken(_amount, sender);
    }

    /// @inheritdoc IHexOneProtocol
    function depositCollateral(
        address _token, 
        uint256 _amount, 
        uint16 _duration
    ) external override {
        address sender = msg.sender;
        require (sender != address(0), "zero address caller");
        require (allowedTokens.contains(_token), "invalid token");
        require (_amount > 0, "invalid amount");
        require (_duration >= MIN_DURATION && _duration <= MAX_DURATION, "invalid duration");

        IHexOneVault hexOneVault = IHexOneVault(vaultInfos[_token]);
        _amount = _transferDepositTokenWithFee(sender, _token, _amount);
        uint256 mintAmount = hexOneVault.depositCollateral(
            sender, 
            _amount, 
            _duration
        );

        require (mintAmount > 0, "depositing amount is too small to mint $HEX1");
        if (!depositedTokenInfos[sender].contains(_token)) {
            depositedTokenInfos[sender].add(_token);
        }
        IHexOneToken(hexOneToken).mintToken(mintAmount, sender);

        emit HexOneMint(sender, mintAmount);
    }

    /// @inheritdoc IHexOneProtocol
    function claimCollateral(address _token, uint256 _depositId) external override {
        address sender = msg.sender;
        require (sender != address(0), "zero caller address");
        require (allowedTokens.contains(_token), "not allowed token");

        bool restake = (sender == hexOneEscrow);
        (
            uint256 burnAmount,
            uint256 mintAmount
        ) = IHexOneVault(vaultInfos[_token]).claimCollateral(sender, _depositId, restake);

        if (burnAmount > 0) {
            IHexOneToken(hexOneToken).burnToken(burnAmount, sender);
        }

        if (mintAmount > 0) {
            IHexOneToken(hexOneToken).mintToken(mintAmount, sender);
        }
    }

    /// @notice Add/Remove vault and base token addresses.
    function _setVaults(address[] memory _vaults, bool _add) internal {
        uint256 length = _vaults.length;
        for (uint256 i = 0; i < length; i ++) {
            address vault = _vaults[i];
            address token = IHexOneVault(vault).baseToken();
            require (
                (_add && !vaults.contains(vault)) ||
                (!_add && vaults.contains(vault)), 
                "already set"
            );
            if (_add) { 
                vaults.add(vault); 
                require (!allowedTokens.contains(token), "already exist vault has same base token");
                allowedTokens.add(token);
                vaultInfos[token] = vault;
            } else { 
                vaults.remove(vault); 
                allowedTokens.remove(token);
                vaultInfos[token] = address(0);
            }
        }
    }

    /// @notice Transfer token from sender and take fee.
    /// @param _depositor The address of depositor.
    /// @param _token The address of deposit token.
    /// @param _amount The amount of token to deposit.
    /// @return Real token amount without fee.
    function _transferDepositTokenWithFee(
        address _depositor,
        address _token,
        uint256 _amount
    ) internal returns (uint256) {
        uint16 fee = fees[_token].enabled ? fees[_token].feeRate : 0;
        uint256 feeAmount = _amount * fee / FIXED_POINT;
        uint256 realAmount = _amount - feeAmount;
        IERC20(_token).safeTransferFrom(_depositor, address(this), _amount);
        address vaultAddress = vaultInfos[_token];
        require (vaultAddress != address(0), "proper vault is not set");
        IERC20(_token).safeApprove(vaultAddress, realAmount);
        IERC20(_token).safeApprove(stakingMaster, feeAmount);
        IHexOneStakingMaster(stakingMaster).updateRewards(_token, feeAmount);

        return realAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHexOneProtocol {

    struct Fee {
        uint16 feeRate;
        bool enabled;
    }

    /// @notice Add/Remove vaults.
    /// @dev Only owner can call this function.
    /// @param _vaults The address of vaults.
    /// @param _add Add/Remove = true/false.
    function setVaults(address[] memory _vaults, bool _add) external;

    /// @notice Set HexOneEscrow conract address.
    /// @dev Only owner can call this function.
    function setEscrowContract(address _escrowCA) external;

    /// @notice Set stakingMaster contract address.
    /// @dev Only owner can call this function.
    /// @param _stakingMaster The address of staking Pool.
    function setStakingPool(address _stakingMaster) external;

    /// @notice Set Min stake duration.
    /// @dev Only owner can call this function.
    /// @param _minDuration The min stake duration days.
    function setMinDuration(uint256 _minDuration) external;

    /// @notice Set Max stake duration.
    /// @dev Only owner can call this function.
    /// @param _maxDuration The max stake duration days.
    function setMaxDuration(uint256 _maxDuration) external;

    /// @notice Set deposit fee by token.
    /// @dev Only owner can call this function.
    /// @param _token The address of token.
    /// @param _fee Deposit fee percent.
    function setDepositFee(address _token, uint16 _fee) external;

    /// @notice Enable/Disable deposit fee by token.
    /// @dev Only owner can call this function.
    /// @param _token The address of token.
    /// @param _enable Enable/Disable = true/false
    function setDepositFeeEnable(address _token, bool _enable) external;

    /// @notice Deposit collateral and receive $HEX1 token.
    /// @param _token The address of collateral to deposit.
    /// @param _amount The amount of collateral to deposit.
    /// @param _duration The duration days.
    function depositCollateral(
        address _token, 
        uint256 _amount, 
        uint16 _duration
    ) external;

    /// @notice Borrow more $HEX1 token based on already deposited collateral.
    /// @param _token The address of token already deposited.
    /// @param _depositId The vault depositId to borrow.
    /// @param _amount The amount of $HEX1 to borrow.
    function borrowHexOne(
        address _token,
        uint256 _depositId,
        uint256 _amount
    ) external;

    /// @notice Claim/restake collateral
    /// @param _token The address of collateral.
    /// @param _depositId The deposit id to claim.
    function claimCollateral(
        address _token,
        uint256 _depositId
    ) external;

    /// @notice Check that token is allowed or not.
    function isAllowedToken(
        address _token
    ) external view returns (bool);

    /// @notice Get vault contract address by token.
    function getVaultAddress(address _token) external view returns (address);

    event HexOneMint(address indexed recipient, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IHexOneStaking {

    struct Rewards {
        uint256 stakeId;
        uint256 stakedAmount;
        uint256 claimableRewards;
        address rewardToken;
        address stakeToken;
    }

    struct StakeInfo {
        uint256 stakedTimestamp;
        uint256 stakedAmount;
        uint256 currentPoolAmount;
    }

    struct PoolInfo {
        uint256 totalStakedAmount;
        uint256 poolAmount;
    }

    /// @notice Set StakingMaster address.
    /// @dev Only ower can call this function.
    function setStakingMaster(address _stakingMaster) external;

    /// @notice Stake ERC20 tokens.
    function stakeERC20Start(
        address _staker,
        address _rewardToken,
        uint256 _amount
    ) external;

    /// @notice Stake ERC721 tokens.
    function stakeERC721Start(
        address _staker,
        address _rewardToken,
        uint256[] memory _tokenIds
    ) external;

    /// @notice Unstake ERC20 tokens.
    /// @return staked amount and claimable rewards info.
    function stakeERC20End(
        address _staker,
        address _rewardToken, 
        uint256 _stakeId
    ) external returns (uint256, uint256);

    /// @notice Unstake ERC721 tokens.
    function stakeERC721End(
        address _staker,
        address _rewardToken, 
        uint256 _stakeId
    ) external returns (uint256, uint256[] memory);

    /// @notice Get claimable rewards.
    function claimableRewards(
        address _staker,
        address _rewardToken
    ) external view returns (Rewards[] memory);

    function baseToken() external view returns (address baseToken);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IHexOneStaking.sol";

interface IHexOneStakingMaster {

    struct AllowedToken {
        address stakingPool;
        uint16 rewardRate;
        bool isEnable;
    }

    /// @notice Set hexOneProtocol contract address.
    /// @dev Only owner can call this function.
    function setHexOneProtocol(address _hexOneProtocol) external;

    /// @notice Set reward tokens for stake token.
    /// @dev Only owner can call this function.
    function setAllowedRewardTokens(
        address _baseToken, 
        address[] memory _rewardTokens, 
        bool _isAllow
    ) external;

    /// @notice Set fee receiver address.
    /// @dev Only owner can call this function.
    function setFeeReceiver(
        address _feeReceiver
    ) external;

    /// @notice Set withdraw fee rate.
    /// @dev Only owner can call this function.
    function setWithdrawFeeRate(
        uint16 _feeRate
    ) external;

    /// @notice Enable/Disable allow tokens.
    /// @dev Only owner can call this function.
    /// @param _tokens The address of tokens.
    /// @param _isEnable Enable/Disable = true/false.
    function setAllowTokens(
        address[] memory _tokens, 
        bool _isEnable
    ) external;

    /// @notice Set rewards rate per token.
    function setRewardsRate(
        address[] memory _tokens, 
        uint16[] memory _rewardsRate
    ) external;

    /// @notice Set staking contract for base token.
    /// @dev Only owner can call this function.
    function setStakingPools(
        address[] memory _tokens,
        address[] memory _stakingPools
    ) external;

    /// @notice Get allowed reward tokens for base token.
    function getAllowedRewardTokens(
        address _baseToken
    ) external view returns (address[] memory);

    /// @notice Stake ERC20 tokens.
    function stakeERC20Start(
        address _token,
        address _rewardToken,
        uint256 _amount
    ) external;

    /// @notice Stake ERC721 tokens.
    function stakeERC721Start(
        address _collection,
        address _rewardToken,
        uint256[] memory _tokenIds
    ) external;

    /// @notice Unstake ERC20 tokens.
    function stakeERC20End(address _token, address _rewardToken, uint256 _stakeId) external;

    /// @notice Unstake ERC721 tokens.
    function stakeERC721End(address _collection, address _rewardToken, uint256 _stakeId) external;

    function claimableRewards(
        address _staker, 
        address _stakeToken,
        address _rewardToken
    ) external view returns (IHexOneStaking.Rewards[] memory);

    /// @notice update reward pool amount.
    /// @dev Only HexOneProtocol can call this function.
    function updateRewards(address _token, uint256 _amount) external;

    /// @notice Return reward rate for reward token.
    function getRewardRate(address _token) external view returns (uint16);

    /// @notice Return pool amount of reward token.
    function getTotalPoolAmount(address _rewardToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHexOneToken {

    /// @notice Mint $HEX1 token to recipient.
    /// @dev Only HexOneProtocol can call this function.
    /// @param _amount The amount of $HEX1 to mint.
    /// @param _recipient The address of recipient.
    function mintToken(uint256 _amount, address _recipient) external;

    /// @notice burn $HEX1 token as much as _amount.
    function burnToken(uint256 _amount, address _account) external;

    /// @notice Set admin address. HexOneProtocol is admin.
    /// @dev This function can be called by only owner.
    /// @param _admin The address of admin.
    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHexOneVault {

    struct DepositInfo {
        uint256 vaultDepositId;
        uint256 stakeId;
        uint256 amount;
        uint256 shares;
        uint256 mintAmount;
        uint256 depositedHexDay;
        uint256 initHexPrice;
        uint16 duration;
        uint16 graceDay;
        bool exist;
    }

    struct UserInfo {
        uint256 depositId;
        uint256 shareBalance;
        uint256 depositedBalance;
        uint256 totalBorrowedAmount;
        mapping(uint256 => DepositInfo) depositInfos;
    }

    struct DepositShowInfo {
        uint256 depositId;
        uint256 depositAmount;
        uint256 shareAmount;
        uint256 mintAmount;
        uint256 borrowableAmount;
        uint256 effectiveAmount;
        uint256 initialHexPrice;
        uint256 lockedHexDay;
        uint256 endHexDay;
        uint256 curHexDay;
    }

    struct BorrowableInfo {
        uint256 depositId;
        uint256 borrowableAmount;
    }

    struct VaultDepositInfo {
        address userAddress;
        uint256 userDepositId;
    }

    struct LiquidateInfo {
        address depositor;
        uint256 depositId;
        uint256 curHexDay;
        uint256 endDay;
        uint256 effectiveHex;
        uint256 borrowedHexOne;
        uint256 initHexPrice;
        uint256 currentHexPrice;
        uint256 depositedHexAmount;
        uint256 currentValue;
        uint256 initUSDValue;
        uint256 currentUSDValue;
        uint16 graceDay;
        bool liquidable;
    }

    function baseToken() external view returns (address baseToken);

    /// @notice Get borrowable amount based on already deposited collateral amount.
    function getBorrowableAmounts(address _account) external view returns (BorrowableInfo[] memory);

    /// @notice Get total borrowed $HEX1 of user.
    /// @param _account The address of _account.
    function getBorrowedBalance(address _account) external view returns (uint256);
    
    /// @notice Borrow additional $HEX1 from already deposited collateral amount.
    /// @dev If collateral price is increased, there will be profit.
    ///         Based on that profit, depositors can borrow $HEX1 additionally.
    /// @param _depositor The address of depositor (borrower)
    /// @param _vaultDepositId The vault deposit id to borrow.
    /// @param _amount The amount of $HEX1 token.
    function borrowHexOne(address _depositor, uint256 _vaultDepositId, uint256 _amount) external;

    /// @notice Set hexOneProtocol contract address.
    /// @dev Only owner can call this function and 
    ///      it should be called as intialize step.
    /// @param _hexOneProtocol The address of hexOneProtocol contract.
    function setHexOneProtocol(address _hexOneProtocol) external;

    /// @notice Deposit collateral and mint $HEX1 token to depositor.
    ///         Collateral should be converted to T-SHARES and return.
    /// @dev Only HexOneProtocol can call this function.
    ///      T-SHARES will be locked for maturity, 
    ///      it means deposit can't retrieve collateral before maturity.
    /// @param _depositor The address of depositor.
    /// @param _amount The amount of collateral.
    /// @param _duration The maturity duration.
    /// @return mintAmount The amount of $HEX1 to mint.
    function depositCollateral(
        address _depositor, 
        uint256 _amount, 
        uint16 _duration
    ) external returns (uint256 mintAmount);

    /// @notice Retrieve collateral after maturity.
    /// @dev Users can claim collateral after maturity.
    /// @return burnAmount Amount of $HEX1 token to burn.
    /// @return mintAmount Amount of $HEX1 token to mint.
    function claimCollateral(
        address _claimer,
        uint256 _vaultDepositId,
        bool _restake
    ) external returns (uint256 burnAmount, uint256 mintAmount);

    /// @notice Get liquidable vault deposit Ids.
    function getLiquidableDeposits() external view returns (LiquidateInfo[] memory);

    /// @notice Get t-share balance of user.
    function getShareBalance(address _account) external view returns (uint256);

    function getUserInfos(address _account) external view returns (DepositShowInfo[] memory);

    /// @notice Set limit claim duration.
    /// @dev Only owner can call this function.
    function setLimitClaimDuration(uint16 _duration) external;

    event CollateralClaimed(address indexed claimer, uint256 claimedAmount);

    event CollateralRestaked(address indexed staker, uint256 restakedAmount, uint16 restakeDuration);
}