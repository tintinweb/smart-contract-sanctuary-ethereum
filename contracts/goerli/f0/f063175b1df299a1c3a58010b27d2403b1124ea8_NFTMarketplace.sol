/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


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


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IKRC20 is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract NFTMarketplace is Context, Ownable, Pausable, ReentrancyGuard {
    // Libraries
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;
    using SafeERC20 for IKRC20;

    // Variables
    address private immutable USDT; // Native ERC20 token for trades
    uint8 private tradeFee; // marketplace fee
    address private admin; // marketplace controller
    uint8 private constant minFees = 0; // 1% == 100 etc.
    uint16 private constant maxFees = 1000; // 1000 == 10%
    address private proxyAdmin; // marketplace data management

    // Enums
    enum Status {
        Unverified,
        Verified
    }

    // Events
    event ItemListed(
        address indexed seller,
        uint32 indexed tokenId,
        uint256 indexed price
    );
    event ItemUpdated(
        address indexed owner,
        uint32 indexed tokenId,
        uint256 indexed newPrice
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        uint32 indexed tokenId,
        uint256 price
    );
    event ItemDelisted(uint32 tokenId);
    event CollectionAdded(address collection);
    event CollectionUpdated(address collection);
    event CollectionUnverify(address collection);
    event CollectionVerify(address collection);
    event CollectionRemoved(address collection);
    event OfferCreated(
        address indexed creator,
        address indexed owner,
        uint256 indexed value
    );
    event OfferUpdated(
        address indexed creator,
        address indexed owner,
        uint256 indexed value
    );
    event OfferCancelled(address creator, address collection, uint256 token);
    event OfferAccepted(
        address indexed owner,
        address indexed creator,
        address collection,
        uint256 token
    );
    event TokenRecovery(address indexed tokenAddress, uint256 indexed amount);
    event NFTRecovery(
        address indexed collectionAddress,
        uint256 indexed tokenId
    );
    event TradeFeeUpdated(uint256 fees);
    event AdminUpdated(address indexed admin);
    event RevenueWithdrawn(address indexed eoa, uint256 indexed amount);
    event Pause(string reason);
    event Unpause(string reason);

    // Constructor
    /**
     * @notice Constructor for the marketplace
     * @param _tradeFee trade fee to be in counts of 100: 1% == 100, 10% = 1000
     * @param _admin address of the admin
     * @param _USDT address of the USDT token
     */
    constructor(
        uint8 _tradeFee, // trade fee to be in counts of 100: 1% == 100, 10% = 1000
        address _admin,
        address _USDT
    ) {
        tradeFee = _tradeFee;
        admin = _admin;
        proxyAdmin = _admin;
        USDT = _USDT;
        Ownable(_msgSender());
    }

    // Structs
    // Stores Listing data
    struct Listing {
        address seller;
        uint256 price;
        address collection;
        uint256 tokenId;
    }
    // Stores data about an Offer. The buyer and the offer value
    struct Offer {
        address buyer;
        uint256 price;
    }
    // A struct that tracks the royalty fees collection address, its royalty fees and state of its verification. Paramount for future updates when making the marketplace decentralized
    struct Collection {
        address collectionAddress;
        uint256 royaltyFees;
        Status status;
    }
    // An array of recent NFT listings
    Listing[] private recentlyListed;
    // An address set of all supported collections
    EnumerableSet.AddressSet private collectionAddresses;

    // data mappings
    // mapping from collection address to tokenId to the Listing struct, containing seller address and price
    mapping(address => mapping(uint256 => Listing)) private sellNFT;
    // mapping from collection address to an enumerable set of tokenIds. Used to keep track of token existence in the smart contract storage as listed
    mapping(address => EnumerableSet.UintSet) private tokenIdExists;
    // tracks the revenue generation for the protocol and the collection royalty fees
    mapping(address => uint256) private revenue;
    // mapping from an EOA address to a collection address then to an enumerable set of tokenIds. Used to keep track of token existence in the smart contract storage as having an offer created by a user for that NFT collection, tokenId
    mapping(address => mapping(address => EnumerableSet.UintSet))
        private userOfferExists;
    // Maps a collection address to its information
    mapping(address => Collection) private collection;
    // mapping from a collection to a tokenId to an offer creator which maps to the details of the Offer created
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        private offer;
    // mapping from a collection to a tokenId that stores all addresses that has created an offer for that NFT. Used to track and limit users from creating multiple offer instances and allow offer updates only if the offer was created before
    mapping(address => mapping(uint256 => EnumerableSet.AddressSet))
        private offerCreator;
    // mapping from a collection address to an array of recent listings for that collection
    mapping(address => Listing[]) private collectionRecentlyListed;

    /// All read functions
    /**
     * @notice Generate all recent listings
     */
    function getAllRecentListings()
        external
        view
        returns (Listing[] memory recentNFTListings)
    {
        uint256 length = recentlyListed.length;
        recentNFTListings = new Listing[](length);
        for (uint256 i = 0; i < length; i++) {
            recentNFTListings[i] = recentlyListed[i];
        }
        return recentNFTListings;
    }

    /**
     * @notice Generate all recent listings for a collection
     * @param _collection address to check listings from
     */
    function getCollectionRecentListings(address _collection)
        external
        view
        returns (Listing[] memory dataPoints)
    {
        uint256 length = collectionRecentlyListed[_collection].length;
        dataPoints = new Listing[](length);
        for (uint256 i = 0; i < length; i++) {
            dataPoints[i] = collectionRecentlyListed[_collection][i];
        }
        return dataPoints;
    }

    /**
     * @notice Generate all offers a user has created for a set of NFTs in a collection
     * @param _collection address to check offers from
     */
    function getUserOffers(address _collection)
        external
        view
        returns (uint256[] memory tokens)
    {
        uint256 length = userOfferExists[_collection][_msgSender()].length();
        tokens = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = userOfferExists[_collection][_msgSender()].at(i);
        }
        return tokens;
    }

    /**
     * @notice Generate listing info for a collection
     * @param _collection address to check listings from
     */
    function getAllListings(address _collection)
        external
        view
        returns (Listing[] memory listingData)
    {
        uint256 length = tokenIdExists[_collection].length();
        uint256[] memory nfts = new uint256[](length);
        listingData = new Listing[](length);
        for (uint256 i = 0; i < length; i++) {
            nfts[i] = tokenIdExists[_collection].at(i);
            listingData[i] = sellNFT[_collection][nfts[i]];
        }
        return listingData;
    }

    /** 
        @notice a getter function that returns all the offers for all NFTs in a collection, gets all listed tokenIds from tokenIdExists, gets the length of offerCreators for each, reads from the offer mapping and returns a struct of Offers
        @param _collection address to check offers from
    */
    function getAllOffers(address _collection)
        external
        view
        returns (Offer[][] memory offerInfo)
    {
        uint256 length = tokenIdExists[_collection].length();
        uint256[] memory nfts = new uint256[](length);
        offerInfo = new Offer[][](length);
        for (uint256 i = 0; i < length; i++) {
            nfts[i] = tokenIdExists[_collection].at(i);
            uint256 offerLength = offerCreator[_collection][nfts[i]].length();
            offerInfo[i] = new Offer[](offerLength);
            for (uint256 j = 0; j < offerLength; j++) {
                offerInfo[i][j] = offer[_collection][nfts[i]][
                    offerCreator[_collection][nfts[i]].at(j)
                ];
            }
        }
        return offerInfo;
    }

    /**
     * @notice Get all collections supported by the marketplace
     */
    function getSupportedCollections()
        external
        view
        returns (address[] memory availableCollections)
    {
        uint256 length = collectionAddresses.length();
        availableCollections = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            availableCollections[i] = collectionAddresses.at(i);
        }
        return availableCollections;
    }

    /**
     * @notice Get all listings and offers for a set of NFTs in a collection. Function also calls availableOffers() to get all offers for each NFT in the collection
     * @param _collection address to check offers from
     */
    function getAllListingsAndOffers(address _collection)
        public
        view
        returns (Listing[] memory listingData, Offer[][] memory offerInfo)
    {
        uint256 length = tokenIdExists[_collection].length();
        uint256[] memory nfts = new uint256[](length);
        listingData = new Listing[](length);
        offerInfo = new Offer[][](length);
        for (uint256 i = 0; i < length; i++) {
            nfts[i] = tokenIdExists[_collection].at(i);
            listingData[i] = sellNFT[_collection][nfts[i]];
            uint256 offerLength = offerCreator[_collection][nfts[i]].length();
            address[] memory offerCreators = new address[](offerLength);
            offerInfo[i] = new Offer[](offerLength);
            for (uint256 j = 0; j < offerLength; j++) {
                offerCreators[j] = offerCreator[_collection][nfts[i]].at(j);
                offerInfo[i][j] = offer[_collection][nfts[i]][offerCreators[j]];
            }
        }
        return (listingData, offerInfo);
    }

    /**
     * @notice a public getter function to read from sellNFT mapping to get listing data for an  NFT of a collection
     * @param _collection address to check listing from
     * @param _tokenId uint256 to check listing from
     */
    function getListing(address _collection, uint256 _tokenId)
        public
        view
        returns (Listing memory)
    {
        return sellNFT[_collection][_tokenId];
    }

    /**
     * @notice Generate all offers available for a tokenId in a collection
     * @param _collection address to check offers from
     * @param _tokenId uint256 to check offers from
     */
    function getOffers(address _collection, uint256 _tokenId)
        public
        view
        returns (Offer[] memory offerInfo)
    {
        uint256 length = offerCreator[_collection][_tokenId].length();
        address[] memory offerCreators = new address[](length);
        offerInfo = new Offer[](length);
        for (uint256 i = 0; i < length; i++) {
            offerCreators[i] = offerCreator[_collection][_tokenId].at(i);
            offerInfo[i] = offer[_collection][_tokenId][offerCreators[i]];
        }
        return offerInfo;
    }

    /**
     * @notice a public getter function to get a collection information from the collection mapping
     * @param _collection address to check offer from
     */
    function getCollectionData(address _collection)
        public
        view
        returns (Collection memory)
    {
        return collection[_collection];
    }

    // Modifiers
    // modifier to check that the NFT is approved for sale
    modifier isApproved(address _collection, uint256 _tokenId) {
        require(
            IERC721(_collection).getApproved(_tokenId) == address(this),
            "Marketplace not approved to sell NFT"
        );
        _;
    }
    // modifier to check that only admin can call the function
    modifier isAdmin() {
        require(_msgSender() == admin, "Caller != Marketplace Admin");
        _;
    }
    // modifier to check that only proxy admin can call the function
    modifier isProxyAdmin() {
        require(
            _msgSender() == proxyAdmin,
            "Caller != Marketplace Proxy Admin"
        );
        _;
    }
    // modifier to check that price is > 0
    modifier isPriceValid(uint256 _price) {
        require(_price > 0, "Price must be > 0");
        _;
    }
    // modifier to check if a collection is supported
    modifier isCollection(address _collection) {
        require(
            collectionAddresses.contains(_collection),
            "Collection not supported"
        );
        _;
    }
    // modifier to check if msg.sender is the NFT owner
    modifier isNftOwner(address _collection, uint256 _tokenId) {
        require(
            IERC721(_collection).ownerOf(_tokenId) == _msgSender(),
            "Caller != NFT Owner"
        );
        _;
    }
    // modifier to check if msg.sender is the NFT seller
    modifier isSeller(address _collection, uint256 _tokenId) {
        require(
            sellNFT[_collection][_tokenId].seller == _msgSender(),
            "Caller != NFT Seller"
        );
        _;
    }
    // modifier to check if msg.sender is the NFT offer creator
    modifier isOfferCreator(address _collection, uint256 _tokenId) {
        require(
            offer[_collection][_tokenId][_msgSender()].buyer == _msgSender(),
            "Caller != Offer Creator"
        );
        _;
    }
    // modifier to check if NFT is listed for sale
    modifier isListed(address _collection, uint256 _tokenId) {
        require(
            tokenIdExists[_collection].contains(_tokenId),
            "NFT isn't listed for sale"
        );
        _;
    }
    // modifier to check if NFT is not listed for sale
    modifier isNotListed(address _collection, uint256 _tokenId) {
        require(
            !tokenIdExists[_collection].contains(_tokenId),
            "NFT is already listed for sale"
        );
        _;
    }
    // modifier to check if offer exists
    modifier offerAvailable(address _collection, uint256 _tokenId) {
        require(
            userOfferExists[_collection][_msgSender()].contains(_tokenId),
            "Offer doesn't exist"
        );
        _;
    }
    // modifier to check if offer doesn't exist
    modifier offerNotAvailable(address _collection, uint256 _tokenId) {
        require(
            !userOfferExists[_collection][_msgSender()].contains(_tokenId),
            "Offer already exists"
        );
        _;
    }

    // Write functions

    /**
     * @notice Internal function to delete first array element if recentlyListed array length is > 5 || if collectionRecentlyListed for the _collection param array length > 3
     * @param _collection address to pass to collectionRecentlyListed mapping, 0x0 for recentlyListed array
     * @return bool to indicate if array element was deleted
     */
    function _deleteFirstArrayElement(address _collection)
        private
        returns (bool)
    {
        if (_collection == address(0)) {
            // if (recentlyListed.length > 5) {
            delete recentlyListed[0];
            for (uint256 i; i < recentlyListed.length - 1; i++) {
                recentlyListed[i] = recentlyListed[i + 1];
            }
            recentlyListed.pop();
            return true;
            // }
        } else if (_collection != address(0)){
            // if (collectionRecentlyListed[_collection].length > 3) {
            delete collectionRecentlyListed[_collection][0];
            for (
                uint256 i;
                i < collectionRecentlyListed[_collection].length - 1;
                i++
            ) {
                collectionRecentlyListed[_collection][
                    i
                ] = collectionRecentlyListed[_collection][i + 1];
            }
            collectionRecentlyListed[_collection].pop();
            return true;
            // }
        }
        return false;
    }

    /**
     * @notice List an NFT for sale
     * @param _collection address of the collection
     * @param _tokenId uint256 of the tokenId
     * @param _price uint256 sale price
     */
    function list(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    )
        external
        whenNotPaused
        isCollection(_collection)
        isNftOwner(_collection, _tokenId)
        isApproved(_collection, _tokenId)
        isNotListed(_collection, _tokenId)
        isPriceValid(_price)
    {
        Listing memory listing = Listing(
            _msgSender(),
            _price,
            _collection,
            _tokenId
        );
        sellNFT[_collection][_tokenId] = listing;
        tokenIdExists[_collection].add(_tokenId);
        recentlyListed.push(listing);
        collectionRecentlyListed[_collection].push(listing);
        if (recentlyListed.length > 9) {
            require(
                _deleteFirstArrayElement(address(0)),
                "Error deleting first array element"
            );
        }
        if (collectionRecentlyListed[_collection].length > 9) {
            require(
                _deleteFirstArrayElement(_collection),
                "Error deleting first array element"
            );
        }
        emit ItemListed(_msgSender(), uint32(_tokenId), _price);
    }

    /**
     * @notice Update the price of an NFT listing
     * @param _collection address of the collection
     * @param _tokenId uint256 of the tokenId
     * @param _newPrice uint256 new sale price
     * @return bool to indicate if listing was updated
     */
    function updateListing(
        address _collection,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        isListed(_collection, _tokenId)
        whenNotPaused
        isNftOwner(_collection, _tokenId)
        isApproved(_collection, _tokenId)
        returns (bool)
    {
        sellNFT[_collection][_tokenId].price = _newPrice;
        emit ItemUpdated(_msgSender(), uint32(_tokenId), _newPrice);
        return true;
    }

    /**
     * @notice Cancel an NFT listing
     * @param _collection address of the collection
     * @param _tokenId uint256 of the tokenId
     */
    function cancelListing(address _collection, uint256 _tokenId)
        external
        isListed(_collection, _tokenId)
        nonReentrant
        isNftOwner(_collection, _tokenId)
    {
        delete (sellNFT[_collection][_tokenId]);
        tokenIdExists[_collection].remove(_tokenId);
        emit ItemDelisted(uint32(_tokenId));
    }

    /**
     * @notice Buy an NFT
     * @param _collection address of the collection
     * @param _tokenId uint256 of the tokenId
     * @param _price uint256 sale price
     */
    function buyNFT(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    )
        external
        isListed(_collection, _tokenId)
        whenNotPaused
        nonReentrant
        isApproved(_collection, _tokenId)
    {
        require(
            _price == sellNFT[_collection][_tokenId].price,
            "Price mismatch"
        );
        require(
            IKRC20(USDT).allowance(_msgSender(), address(this)) >= _price,
            "Insufficient USDT allowance"
        );
        IKRC20(USDT).safeTransferFrom(
            address(msg.sender),
            address(this),
            _price
        );
        _buyNFT(_collection, _tokenId, _price);
    }

    /**
     * @notice Internal function to execute Buy NFT
     * @param _collection address of the collection
     * @param _tokenId uint256 of the tokenId
     * @param _price uint256 sale price
     */
    function _buyNFT(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    ) private {
        Listing memory listing = sellNFT[_collection][_tokenId];
        IERC721 nft = IERC721(_collection);
        (uint256 amount, uint256 marketplaceFee, uint256 collectionFee) = _fees(
            _collection,
            _price
        );
        delete (sellNFT[_collection][_tokenId]);
        tokenIdExists[_collection].remove(_tokenId);
        if (offerCreator[_collection][_tokenId].contains(_msgSender())) {
            delete (offer[_collection][_tokenId][_msgSender()]);
            offerCreator[_collection][_tokenId].remove(_msgSender());
            userOfferExists[_collection][_msgSender()].remove(_tokenId);
        }
        if (collectionFee != 0) {
            revenue[collection[_collection].collectionAddress] += collectionFee;
        }
        if (marketplaceFee != 0) {
            revenue[admin] += marketplaceFee;
        }
        IKRC20(USDT).safeTransfer(listing.seller, amount);
        nft.safeTransferFrom(listing.seller, _msgSender(), _tokenId);
        emit ItemSold(listing.seller, _msgSender(), uint32(_tokenId), _price);
    }

    function _fees(address _collection, uint256 _price)
        internal
        view
        returns (
            uint256 amount,
            uint256 marketplaceFee,
            uint256 collectionFee
        )
    {
        marketplaceFee = (_price * tradeFee) / 10000;
        collectionFee = (_price * collection[_collection].royaltyFees) / 10000;
        amount = _price - (marketplaceFee + collectionFee);
        return (amount, marketplaceFee, collectionFee);
    }

    /** 
        @notice Add a collection to the marketplace
        @param _collection address of the collection
        @param _walletAddressForRoyalty address of the royalty fees receiver
        @param _royaltyFees uint256 of the royalty fees (100 ~ 1% & 1000 ~ 10%)
    */
    function addCollection(
        address _collection,
        address _walletAddressForRoyalty,
        uint256 _royaltyFees
    ) external whenNotPaused isAdmin {
        require(
            !collectionAddresses.contains(_collection),
            "Collection exists"
        );
        require(
            IERC721(_collection).supportsInterface(0x80ac58cd) || IERC1155(_collection).supportsInterface(0x80ac58cd),
            "NFT Standards, not supported"
        );
        require(
            _royaltyFees >= minFees && _royaltyFees <= (maxFees - tradeFee),
            "Royalty fees are high"
        );
        collectionAddresses.add(_collection);
        collection[_collection] = Collection(
            _walletAddressForRoyalty,
            _royaltyFees,
            Status.Unverified
        );
        emit CollectionAdded(_collection);
    }

    /** 
        @notice Update a collection to the marketplace
        @param _collection address of the collection
        @param _collectionAddress address of the royalty fees receiver
        @param _royaltyFees uint256 of the royalty fees
    */
    function updateCollection(
        address _collection,
        address _collectionAddress,
        uint256 _royaltyFees
    ) external whenNotPaused isAdmin isCollection(_collection) {
        require(
            _royaltyFees >= minFees && _royaltyFees <= (maxFees - tradeFee),
            "Royalty fees are high"
        );
        collection[_collection] = Collection(
            _collectionAddress,
            _royaltyFees,
            Status.Verified
        );
        emit CollectionUpdated(_collection);
    }

    /** 
        @notice Remove a collection from the marketplace
        @param _collection address of the collection
    */
    function removeCollection(address _collection)
        external
        whenNotPaused
        isAdmin
        isCollection(_collection)
    {
        require(
            collection[_collection].status == Status.Unverified,
            "Can't remove a Verified collection"
        );
        collectionAddresses.remove(_collection);
        delete (collection[_collection]);
        emit CollectionRemoved(_collection);
    }

    /** 
        @notice Verify a collection from the marketplace
        @param _collection address of the collection
    */
    function verifyCollection(address _collection)
        external
        isAdmin
        isCollection(_collection)
    {
        Collection storage collectionStatus = collection[_collection];
        collectionStatus.status = Status.Verified;
        emit CollectionVerify(_collection);
    }

    /** 
        @notice Unverify a collection from the marketplace
        @param _collection address of the collection
    */
    function unverifyCollection(address _collection)
        external
        isAdmin
        isCollection(_collection)
    {
        Collection storage collectionStatus = collection[_collection];
        collectionStatus.status = Status.Unverified;
        emit CollectionUnverify(_collection);
    }

    /**
     * @notice Create an Offer for a NFT
     * @param _collection address to create an offer for
     * @param _tokenId uint256 of the tokenId
     * @param _value uint256 of the offer value
     * @return bool true if the offer is created successfully
     */
    function createOffer(
        address _collection,
        uint256 _tokenId,
        uint256 _value
    )
        external
        isListed(_collection, _tokenId)
        whenNotPaused
        nonReentrant
        offerNotAvailable(_collection, _tokenId)
        returns (bool)
    {
        require(
            !offerCreator[_collection][_tokenId].contains(_msgSender()),
            "Two offer Instances"
        );
        require(
            IKRC20(USDT).allowance(_msgSender(), address(this)) >= _value,
            "Approve value first"
        );
        require(
            sellNFT[_collection][_tokenId].price != _value,
            "Value can't be the same"
        );
        IERC721 nft = IERC721(_collection);
        address itemOwner = nft.ownerOf(_tokenId);
        require(itemOwner != _msgSender(), "Owner can't make Offers");
        offer[_collection][_tokenId][_msgSender()] = Offer(
            _msgSender(),
            _value
        );
        userOfferExists[_collection][_msgSender()].add(_tokenId);
        offerCreator[_collection][_tokenId].add(_msgSender());
        emit OfferCreated(_msgSender(), itemOwner, _value);
        return true;
    }

    /**
     * @notice Update an Offer for a NFT
     * @param _collection address to update an offer for
     * @param _tokenId uint256 of the tokenId
     * @param _newValue uint256 of the new offer value
     * @return bool true if the offer is updated successfully
     */
    function updateOffer(
        address _collection,
        uint256 _tokenId,
        uint256 _newValue
    )
        external
        isListed(_collection, _tokenId)
        whenNotPaused
        nonReentrant
        offerAvailable(_collection, _tokenId)
        returns (bool)
    {
        require(
            IKRC20(USDT).allowance(_msgSender(), address(this)) >= _newValue,
            "Approve value first"
        );
        require(
            sellNFT[_collection][_tokenId].price != _newValue,
            "Value can't be the same"
        );
        Offer storage changeOffer = offer[_collection][_tokenId][_msgSender()];
        require(changeOffer.price != _newValue, "New value must be provided");
        IERC721 nft = IERC721(_collection);
        address itemOwner = nft.ownerOf(_tokenId);
        changeOffer.price = _newValue;
        emit OfferUpdated(_msgSender(), itemOwner, _newValue);
        return true;
    }

    /**
     * @notice Cancel an Offer for a NFT
     * @param _collection address to cancel an offer for
     * @param _tokenId uint256 of the tokenId
     */
    function cancelOffer(address _collection, uint256 _tokenId)
        external
        nonReentrant
        offerAvailable(_collection, _tokenId)
    {
        delete (offer[_collection][_tokenId][_msgSender()]);
        userOfferExists[_collection][_msgSender()].remove(_tokenId);
        offerCreator[_collection][_tokenId].remove(_msgSender());
        emit OfferCancelled(_msgSender(), _collection, _tokenId);
    }

    /**
     * @notice Accept an Offer for a NFT
     * @param _collection address to accept an offer for
     * @param _tokenId uint256 of the tokenId
     * @param _offerer address of the offer creator
     */
    function acceptOffer(
        address _collection,
        uint256 _tokenId,
        address _offerer
    ) external whenNotPaused nonReentrant isNftOwner(_collection, _tokenId) {
        require(
            userOfferExists[_collection][_offerer].contains(_tokenId),
            "Offer doesn't exist"
        );
        uint256 value = offer[_collection][_tokenId][_offerer].price;
        require(
            IKRC20(USDT).balanceOf(_offerer) >= value,
            "Offer creator balance is less than value"
        );
        require(
            IKRC20(USDT).allowance(_offerer, address(this)) >= value,
            "Offer creator allowance is less than value"
        );
        IKRC20(USDT).safeTransferFrom(_offerer, address(this), value);
        delete (offer[_collection][_tokenId][_offerer]);
        offerCreator[_collection][_tokenId].remove(_offerer);
        userOfferExists[_collection][_offerer].remove(_tokenId);
        delete (sellNFT[_collection][_tokenId]);
        tokenIdExists[_collection].remove(_tokenId);
        _acceptOffer(_collection, _tokenId, value, _offerer);
    }

    function _acceptOffer(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        address _offerInitiator
    ) private {
        IERC721 nft = IERC721(_collection);
        (uint256 amount, uint256 marketplaceFee, uint256 collectionFee) = _fees(
            _collection,
            _price
        );
        if (collectionFee != 0) {
            revenue[collection[_collection].collectionAddress] += collectionFee;
        }
        if (tradeFee != 0) {
            revenue[admin] += marketplaceFee;
        }
        IKRC20(USDT).safeTransfer(_msgSender(), amount);
        nft.safeTransferFrom(_msgSender(), _offerInitiator, _tokenId);
        emit OfferAccepted(
            _msgSender(),
            _offerInitiator,
            _collection,
            _tokenId
        );
    }

    /**
     * @notice Withdraw revenue generated from the marketplace
     */
    function withdrawRevenue() external whenNotPaused nonReentrant {
        uint256 revenueGenerated = revenue[_msgSender()];
        require(revenueGenerated != 0, "Nill Revenue");
        revenue[_msgSender()] = 0;
        IKRC20(USDT).safeTransfer(_msgSender(), revenueGenerated);
        emit RevenueWithdrawn(_msgSender(), revenueGenerated);
    }

    // Proxy admin functions
    /** 
        @dev script checks for approval and delists the NFT
        @param _collection address to delist from
        @param _tokenId nft to delist
    */
    function proxyDelistToken(address _collection, uint256 _tokenId)
        external
        isProxyAdmin
        isListed(_collection, _tokenId)
        nonReentrant
    {
        IERC721 nft = IERC721(_collection);
        require(
            nft.getApproved(_tokenId) != address(this),
            "NFT is approved. Cannot delist"
        );
        delete (sellNFT[_collection][_tokenId]);
        tokenIdExists[_collection].remove(_tokenId);
        emit ItemDelisted(uint32(_tokenId));
    }

    /** 
        @dev script checks for USDT approval and removes the Offer if conditions are met
        @param _collection address to read offer from
        @param _tokenId nft to read offer delist
        @param _offerCreator address of offer Creator
    */
    function proxyRemoveOffer(
        address _collection,
        uint256 _tokenId,
        address _offerCreator
    ) external isProxyAdmin isListed(_collection, _tokenId) nonReentrant {
        require(
            userOfferExists[_collection][_offerCreator].contains(_tokenId),
            "Offer doesn't exist"
        );
        uint256 value = offer[_collection][_tokenId][_offerCreator].price;
        require(
            IKRC20(USDT).balanceOf(_offerCreator) < value,
            "Offer creator balance is sufficient"
        );
        require(
            IKRC20(USDT).allowance(_offerCreator, address(this)) < value,
            "Offer creator allowance is sufficient"
        );
        delete (offer[_collection][_tokenId][_offerCreator]);
        userOfferExists[_collection][_offerCreator].remove(_tokenId);
        offerCreator[_collection][_tokenId].remove(_offerCreator);
        emit OfferCancelled(_offerCreator, _collection, _tokenId);
    }

    //OnlyOwner function calls
    /** 
        @notice update the trade fee
        @param _newTradeFee uint8 of the new trade fee
    */
    function updateTradeFee(uint8 _newTradeFee) external whenPaused onlyOwner {
        tradeFee = _newTradeFee;
        emit TradeFeeUpdated(_newTradeFee);
    }

    /** 
        @notice update the admin address
        @param _newAdmin address of the new admin
    */
    function updateAdmin(address _newAdmin) external whenPaused onlyOwner {
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    /** 
        @notice update the proxy admin address
        @param _newAdmin address of the new admin
    */
    function updateProxyAdmin(address _newAdmin) external whenPaused onlyOwner {
        proxyAdmin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    /** 
        @notice recover any ERC20 token sent to the contract
        @param _token address of the token to recover
        @param _amount amount of the token to recover
    */
    function recoverToken(address _token, uint256 _amount)
        external
        whenPaused
        onlyOwner
    {
        IKRC20(_token).safeTransfer(address(msg.sender), _amount);
        emit TokenRecovery(_token, _amount);
    }

    /** 
        @notice recover any ERC721 token sent to the contract
        @param _collection address of the collection to recover
        @param _tokenId uint256 of the tokenId to recover
    */
    function recoverNFT(address _collection, uint256 _tokenId)
        external
        whenPaused
        onlyOwner
    {
        IERC721 nft = IERC721(_collection);
        nft.safeTransferFrom(address(this), address(msg.sender), _tokenId);
        emit NFTRecovery(_collection, _tokenId);
    }

    /** 
        @notice pause the marketplace
        @param _reason string of the reason for pausing the marketplace
    */
    function pauseMarketplace(string calldata _reason)
        external
        whenNotPaused
        onlyOwner
    {
        _pause();
        emit Pause(_reason);
    }

    /** 
        @notice unpause the marketplace
        @param _reason string of the reason for unpausing the marketplace
    */
    function unpauseMarketplace(string calldata _reason)
        external
        whenPaused
        onlyOwner
    {
        _unpause();
        emit Unpause(_reason);
    }
}