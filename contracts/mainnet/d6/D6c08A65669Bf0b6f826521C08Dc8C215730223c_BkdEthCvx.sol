/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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


// File @openzeppelin/contracts/utils/structs/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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


// File interfaces/IGasBank.sol

pragma solidity 0.8.9;

interface IGasBank {
    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, address indexed receiver, uint256 value);

    function depositFor(address account) external payable;

    function withdrawUnused(address account) external;

    function withdrawFrom(address account, uint256 amount) external;

    function withdrawFrom(
        address account,
        address payable to,
        uint256 amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}


// File interfaces/IVaultReserve.sol

pragma solidity 0.8.9;

interface IVaultReserve {
    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event VaultListed(address indexed vault);

    function deposit(address token, uint256 amount) external payable returns (bool);

    function withdraw(address token, uint256 amount) external returns (bool);

    function getBalance(address vault, address token) external view returns (uint256);

    function canWithdraw(address vault) external view returns (bool);
}


// File interfaces/oracles/IOracleProvider.sol

pragma solidity 0.8.9;

interface IOracleProvider {
    /// @notice Quotes the USD price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address baseAsset) external view returns (uint256);

    /// @notice Quotes the ETH price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the ETH price of the asset
    function getPriceETH(address baseAsset) external view returns (uint256);
}


// File interfaces/IPreparable.sol

pragma solidity 0.8.9;

interface IPreparable {
    event ConfigPreparedAddress(bytes32 indexed key, address value, uint256 delay);
    event ConfigPreparedNumber(bytes32 indexed key, uint256 value, uint256 delay);

    event ConfigUpdatedAddress(bytes32 indexed key, address oldValue, address newValue);
    event ConfigUpdatedNumber(bytes32 indexed key, uint256 oldValue, uint256 newValue);

    event ConfigReset(bytes32 indexed key);
}


// File interfaces/IStrategy.sol

pragma solidity 0.8.9;

interface IStrategy {
    function name() external view returns (string memory);

    function deposit() external payable returns (bool);

    function balance() external view returns (uint256);

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAll() external returns (uint256);

    function harvestable() external view returns (uint256);

    function harvest() external returns (uint256);

    function strategist() external view returns (address);

    function shutdown() external returns (bool);

    function hasPendingFunds() external view returns (bool);
}


// File interfaces/IVault.sol

pragma solidity 0.8.9;


/**
 * @title Interface for a Vault
 */

interface IVault is IPreparable {
    event StrategyActivated(address indexed strategy);

    event StrategyDeactivated(address indexed strategy);

    /**
     * @dev 'netProfit' is the profit after all fees have been deducted
     */
    event Harvest(uint256 indexed netProfit, uint256 indexed loss);

    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external;

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external returns (bool);

    function initializeStrategy(address strategy_) external returns (bool);

    function withdrawAll() external;

    function withdrawFromReserve(uint256 amount) external;

    function getStrategy() external view returns (IStrategy);

    function getStrategiesWaitingForRemoval() external view returns (address[] memory);

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getUnderlying() external view returns (address);
}


// File interfaces/pool/ILiquidityPool.sol

pragma solidity 0.8.9;


interface ILiquidityPool is IPreparable {
    event Deposit(address indexed minter, uint256 depositAmount, uint256 mintedLpTokens);

    event DepositFor(
        address indexed minter,
        address indexed mintee,
        uint256 depositAmount,
        uint256 mintedLpTokens
    );

    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);

    event LpTokenSet(address indexed lpToken);

    event StakerVaultSet(address indexed stakerVault);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeem(uint256 redeemTokens, uint256 minRedeemAmount) external returns (uint256);

    function calcRedeem(address account, uint256 underlyingAmount) external returns (uint256);

    function deposit(uint256 mintAmount) external payable returns (uint256);

    function deposit(uint256 mintAmount, uint256 minTokenAmount) external payable returns (uint256);

    function depositAndStake(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        returns (uint256);

    function depositFor(address account, uint256 depositAmount) external payable returns (uint256);

    function depositFor(
        address account,
        uint256 depositAmount,
        uint256 minTokenAmount
    ) external payable returns (uint256);

    function unstakeAndRedeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        external
        returns (uint256);

    function handleLpTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function executeNewVault() external returns (address);

    function executeNewMaxWithdrawalFee() external returns (uint256);

    function executeNewRequiredReserves() external returns (uint256);

    function executeNewReserveDeviation() external returns (uint256);

    function setLpToken(address _lpToken) external returns (bool);

    function setStaker() external returns (bool);

    function isCapped() external returns (bool);

    function uncap() external returns (bool);

    function updateDepositCap(uint256 _depositCap) external returns (bool);

    function getUnderlying() external view returns (address);

    function getLpToken() external view returns (address);

    function getWithdrawalFee(address account, uint256 amount) external view returns (uint256);

    function getVault() external view returns (IVault);

    function exchangeRate() external view returns (uint256);
}


// File libraries/AddressProviderMeta.sol

pragma solidity 0.8.9;

library AddressProviderMeta {
    struct Meta {
        bool freezable;
        bool frozen;
    }

    function fromUInt(uint256 value) internal pure returns (Meta memory) {
        Meta memory meta;
        meta.freezable = (value & 1) == 1;
        meta.frozen = ((value >> 1) & 1) == 1;
        return meta;
    }

    function toUInt(Meta memory meta) internal pure returns (uint256) {
        uint256 value;
        value |= meta.freezable ? 1 : 0;
        value |= meta.frozen ? 1 << 1 : 0;
        return value;
    }
}


// File interfaces/IAddressProvider.sol

pragma solidity 0.8.9;





// solhint-disable ordering

interface IAddressProvider is IPreparable {
    event KnownAddressKeyAdded(bytes32 indexed key);
    event StakerVaultListed(address indexed stakerVault);
    event StakerVaultDelisted(address indexed stakerVault);
    event ActionListed(address indexed action);
    event PoolListed(address indexed pool);
    event PoolDelisted(address indexed pool);
    event VaultUpdated(address indexed previousVault, address indexed newVault);

    /** Key functions */
    function getKnownAddressKeys() external view returns (bytes32[] memory);

    function freezeAddress(bytes32 key) external;

    /** Pool functions */

    function allPools() external view returns (address[] memory);

    function addPool(address pool) external;

    function poolsCount() external view returns (uint256);

    function getPoolAtIndex(uint256 index) external view returns (address);

    function isPool(address pool) external view returns (bool);

    function removePool(address pool) external returns (bool);

    function getPoolForToken(address token) external view returns (ILiquidityPool);

    function safeGetPoolForToken(address token) external view returns (address);

    /** Vault functions  */

    function updateVault(address previousVault, address newVault) external;

    function allVaults() external view returns (address[] memory);

    function vaultsCount() external view returns (uint256);

    function getVaultAtIndex(uint256 index) external view returns (address);

    function isVault(address vault) external view returns (bool);

    /** Action functions */

    function allActions() external view returns (address[] memory);

    function addAction(address action) external returns (bool);

    function isAction(address action) external view returns (bool);

    /** Address functions */
    function initializeAddress(
        bytes32 key,
        address initialAddress,
        bool frezable
    ) external;

    function initializeAndFreezeAddress(bytes32 key, address initialAddress) external;

    function getAddress(bytes32 key) external view returns (address);

    function getAddress(bytes32 key, bool checkExists) external view returns (address);

    function getAddressMeta(bytes32 key) external view returns (AddressProviderMeta.Meta memory);

    function prepareAddress(bytes32 key, address newAddress) external returns (bool);

    function executeAddress(bytes32 key) external returns (address);

    function resetAddress(bytes32 key) external returns (bool);

    /** Staker vault functions */
    function allStakerVaults() external view returns (address[] memory);

    function tryGetStakerVault(address token) external view returns (bool, address);

    function getStakerVault(address token) external view returns (address);

    function addStakerVault(address stakerVault) external returns (bool);

    function isStakerVault(address stakerVault, address token) external view returns (bool);

    function isStakerVaultRegistered(address stakerVault) external view returns (bool);

    function isWhiteListedFeeHandler(address feeHandler) external view returns (bool);
}


// File interfaces/IRoleManager.sol

pragma solidity 0.8.9;

interface IRoleManager {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function hasAnyRole(bytes32[] memory roles, address account) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        address account
    ) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        address account
    ) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
}


// File interfaces/tokenomics/IBkdToken.sol

pragma solidity 0.8.9;

interface IBkdToken is IERC20 {
    function mint(address account, uint256 amount) external;
}


// File interfaces/tokenomics/IInflationManager.sol

pragma solidity 0.8.9;

interface IInflationManager {
    event KeeperGaugeListed(address indexed pool, address indexed keeperGauge);
    event AmmGaugeListed(address indexed token, address indexed ammGauge);
    event KeeperGaugeDelisted(address indexed pool, address indexed keeperGauge);
    event AmmGaugeDelisted(address indexed token, address indexed ammGauge);

    /** Pool functions */

    function setKeeperGauge(address pool, address _keeperGauge) external returns (bool);

    function setAmmGauge(address token, address _ammGauge) external returns (bool);

    function getAllAmmGauges() external view returns (address[] memory);

    function getLpRateForStakerVault(address stakerVault) external view returns (uint256);

    function getKeeperRateForPool(address pool) external view returns (uint256);

    function getAmmRateForToken(address token) external view returns (uint256);

    function getKeeperWeightForPool(address pool) external view returns (uint256);

    function getAmmWeightForToken(address pool) external view returns (uint256);

    function getLpPoolWeight(address pool) external view returns (uint256);

    function getKeeperGaugeForPool(address pool) external view returns (address);

    function getAmmGaugeForToken(address token) external view returns (address);

    function isInflationWeightManager(address account) external view returns (bool);

    function removeStakerVaultFromInflation(address stakerVault, address lpToken) external;

    function addGaugeForVault(address lpToken) external returns (bool);

    function whitelistGauge(address gauge) external;

    function checkpointAllGauges() external returns (bool);

    function mintRewards(address beneficiary, uint256 amount) external;

    function addStrategyToDepositStakerVault(address depositStakerVault, address strategyPool)
        external
        returns (bool);

    /** Weight setter functions **/

    function prepareLpPoolWeight(address lpToken, uint256 newPoolWeight) external returns (bool);

    function prepareAmmTokenWeight(address token, uint256 newTokenWeight) external returns (bool);

    function prepareKeeperPoolWeight(address pool, uint256 newPoolWeight) external returns (bool);

    function executeLpPoolWeight(address lpToken) external returns (uint256);

    function executeAmmTokenWeight(address token) external returns (uint256);

    function executeKeeperPoolWeight(address pool) external returns (uint256);

    function batchPrepareLpPoolWeights(address[] calldata lpTokens, uint256[] calldata weights)
        external
        returns (bool);

    function batchPrepareAmmTokenWeights(address[] calldata tokens, uint256[] calldata weights)
        external
        returns (bool);

    function batchPrepareKeeperPoolWeights(address[] calldata pools, uint256[] calldata weights)
        external
        returns (bool);

    function batchExecuteLpPoolWeights(address[] calldata lpTokens) external returns (bool);

    function batchExecuteAmmTokenWeights(address[] calldata tokens) external returns (bool);

    function batchExecuteKeeperPoolWeights(address[] calldata pools) external returns (bool);
}


// File interfaces/IController.sol

pragma solidity 0.8.9;





// solhint-disable ordering

interface IController is IPreparable {
    function addressProvider() external view returns (IAddressProvider);

    function inflationManager() external view returns (IInflationManager);

    function addStakerVault(address stakerVault) external returns (bool);

    function removePool(address pool) external returns (bool);

    /** Keeper functions */
    function prepareKeeperRequiredStakedBKD(uint256 amount) external;

    function executeKeeperRequiredStakedBKD() external;

    function getKeeperRequiredStakedBKD() external view returns (uint256);

    function canKeeperExecuteAction(address keeper) external view returns (bool);

    /** Miscellaneous functions */

    function getTotalEthRequiredForGas(address payer) external view returns (uint256);
}


// File libraries/AddressProviderKeys.sol

pragma solidity 0.8.9;

library AddressProviderKeys {
    bytes32 internal constant _TREASURY_KEY = "treasury";
    bytes32 internal constant _GAS_BANK_KEY = "gasBank";
    bytes32 internal constant _VAULT_RESERVE_KEY = "vaultReserve";
    bytes32 internal constant _SWAPPER_REGISTRY_KEY = "swapperRegistry";
    bytes32 internal constant _ORACLE_PROVIDER_KEY = "oracleProvider";
    bytes32 internal constant _POOL_FACTORY_KEY = "poolFactory";
    bytes32 internal constant _CONTROLLER_KEY = "controller";
    bytes32 internal constant _BKD_LOCKER_KEY = "bkdLocker";
    bytes32 internal constant _ROLE_MANAGER_KEY = "roleManager";
}


// File libraries/AddressProviderHelpers.sol

pragma solidity 0.8.9;







library AddressProviderHelpers {
    /**
     * @return The address of the treasury.
     */
    function getTreasury(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._TREASURY_KEY);
    }

    /**
     * @return The gas bank.
     */
    function getGasBank(IAddressProvider provider) internal view returns (IGasBank) {
        return IGasBank(provider.getAddress(AddressProviderKeys._GAS_BANK_KEY));
    }

    /**
     * @return The address of the vault reserve.
     */
    function getVaultReserve(IAddressProvider provider) internal view returns (IVaultReserve) {
        return IVaultReserve(provider.getAddress(AddressProviderKeys._VAULT_RESERVE_KEY));
    }

    /**
     * @return The address of the swapperRegistry.
     */
    function getSwapperRegistry(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._SWAPPER_REGISTRY_KEY);
    }

    /**
     * @return The oracleProvider.
     */
    function getOracleProvider(IAddressProvider provider) internal view returns (IOracleProvider) {
        return IOracleProvider(provider.getAddress(AddressProviderKeys._ORACLE_PROVIDER_KEY));
    }

    /**
     * @return the address of the BKD locker
     */
    function getBKDLocker(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._BKD_LOCKER_KEY);
    }

    /**
     * @return the address of the BKD locker
     */
    function getRoleManager(IAddressProvider provider) internal view returns (IRoleManager) {
        return IRoleManager(provider.getAddress(AddressProviderKeys._ROLE_MANAGER_KEY));
    }

    /**
     * @return the controller
     */
    function getController(IAddressProvider provider) internal view returns (IController) {
        return IController(provider.getAddress(AddressProviderKeys._CONTROLLER_KEY));
    }
}


// File libraries/ScaledMath.sol

pragma solidity 0.8.9;

/*
 * @dev To use functions of this contract, at least one of the numbers must
 * be scaled to `DECIMAL_SCALE`. The result will scaled to `DECIMAL_SCALE`
 * if both numbers are scaled to `DECIMAL_SCALE`, otherwise to the scale
 * of the number not scaled by `DECIMAL_SCALE`
 */
library ScaledMath {
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant DECIMAL_SCALE = 1e18;
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant ONE = 1e18;

    /**
     * @notice Performs a multiplication between two scaled numbers
     */
    function scaledMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / DECIMAL_SCALE;
    }

    /**
     * @notice Performs a division between two scaled numbers
     */
    function scaledDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE) / b;
    }

    /**
     * @notice Performs a division between two numbers, rounding up the result
     */
    function scaledDivRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE + b - 1) / b;
    }

    /**
     * @notice Performs a division between two numbers, ignoring any scaling and rounding up the result
     */
    function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }
}


// File contracts/utils/CvxMintAmount.sol

pragma solidity 0.8.9;

abstract contract CvxMintAmount {
    uint256 private constant _CLIFF_SIZE = 100000 * 1e18; //new cliff every 100,000 tokens
    uint256 private constant _CLIFF_COUNT = 1000; // 1,000 cliffs
    uint256 private constant _MAX_SUPPLY = 100000000 * 1e18; //100 mil max supply
    IERC20 private constant _CVX_TOKEN =
        IERC20(address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B)); // CVX Token

    function getCvxMintAmount(uint256 crvEarned) public view returns (uint256) {
        //first get total supply
        uint256 cvxTotalSupply = _CVX_TOKEN.totalSupply();

        //get current cliff
        uint256 currentCliff = cvxTotalSupply / _CLIFF_SIZE;

        //if current cliff is under the max
        if (currentCliff >= _CLIFF_COUNT) return 0;

        //get remaining cliffs
        uint256 remaining = _CLIFF_COUNT - currentCliff;

        //multiply ratio of remaining cliffs to total cliffs against amount CRV received
        uint256 cvxEarned = (crvEarned * remaining) / _CLIFF_COUNT;

        //double check we have not gone over the max supply
        uint256 amountTillMax = _MAX_SUPPLY - cvxTotalSupply;
        if (cvxEarned > amountTillMax) cvxEarned = amountTillMax;
        return cvxEarned;
    }
}


// File libraries/Errors.sol

pragma solidity 0.8.9;

// solhint-disable private-vars-leading-underscore

library Error {
    string internal constant ADDRESS_WHITELISTED = "address already whitelisted";
    string internal constant ADMIN_ALREADY_SET = "admin has already been set once";
    string internal constant ADDRESS_NOT_WHITELISTED = "address not whitelisted";
    string internal constant ADDRESS_NOT_FOUND = "address not found";
    string internal constant CONTRACT_INITIALIZED = "contract can only be initialized once";
    string internal constant CONTRACT_PAUSED = "contract is paused";
    string internal constant INVALID_AMOUNT = "invalid amount";
    string internal constant INVALID_INDEX = "invalid index";
    string internal constant INVALID_VALUE = "invalid msg.value";
    string internal constant INVALID_SENDER = "invalid msg.sender";
    string internal constant INVALID_TOKEN = "token address does not match pool's LP token address";
    string internal constant INVALID_DECIMALS = "incorrect number of decimals";
    string internal constant INVALID_ARGUMENT = "invalid argument";
    string internal constant INVALID_PARAMETER_VALUE = "invalid parameter value attempted";
    string internal constant INVALID_IMPLEMENTATION = "invalid pool implementation for given coin";
    string internal constant INVALID_POOL_IMPLEMENTATION =
        "invalid pool implementation for given coin";
    string internal constant INVALID_LP_TOKEN_IMPLEMENTATION =
        "invalid LP Token implementation for given coin";
    string internal constant INVALID_VAULT_IMPLEMENTATION =
        "invalid vault implementation for given coin";
    string internal constant INVALID_STAKER_VAULT_IMPLEMENTATION =
        "invalid stakerVault implementation for given coin";
    string internal constant INSUFFICIENT_BALANCE = "insufficient balance";
    string internal constant ADDRESS_ALREADY_SET = "Address is already set";
    string internal constant INSUFFICIENT_STRATEGY_BALANCE = "insufficient strategy balance";
    string internal constant INSUFFICIENT_FUNDS_RECEIVED = "insufficient funds received";
    string internal constant ADDRESS_DOES_NOT_EXIST = "address does not exist";
    string internal constant ADDRESS_FROZEN = "address is frozen";
    string internal constant ROLE_EXISTS = "role already exists";
    string internal constant CANNOT_REVOKE_ROLE = "cannot revoke role";
    string internal constant UNAUTHORIZED_ACCESS = "unauthorized access";
    string internal constant SAME_ADDRESS_NOT_ALLOWED = "same address not allowed";
    string internal constant SELF_TRANSFER_NOT_ALLOWED = "self-transfer not allowed";
    string internal constant ZERO_ADDRESS_NOT_ALLOWED = "zero address not allowed";
    string internal constant ZERO_TRANSFER_NOT_ALLOWED = "zero transfer not allowed";
    string internal constant THRESHOLD_TOO_HIGH = "threshold is too high, must be under 10";
    string internal constant INSUFFICIENT_THRESHOLD = "insufficient threshold";
    string internal constant NO_POSITION_EXISTS = "no position exists";
    string internal constant POSITION_ALREADY_EXISTS = "position already exists";
    string internal constant PROTOCOL_NOT_FOUND = "protocol not found";
    string internal constant TOP_UP_FAILED = "top up failed";
    string internal constant SWAP_PATH_NOT_FOUND = "swap path not found";
    string internal constant UNDERLYING_NOT_SUPPORTED = "underlying token not supported";
    string internal constant NOT_ENOUGH_FUNDS_WITHDRAWN =
        "not enough funds were withdrawn from the pool";
    string internal constant FAILED_TRANSFER = "transfer failed";
    string internal constant FAILED_MINT = "mint failed";
    string internal constant FAILED_REPAY_BORROW = "repay borrow failed";
    string internal constant FAILED_METHOD_CALL = "method call failed";
    string internal constant NOTHING_TO_CLAIM = "there is no claimable balance";
    string internal constant ERC20_BALANCE_EXCEEDED = "ERC20: transfer amount exceeds balance";
    string internal constant INVALID_MINTER =
        "the minter address of the LP token and the pool address do not match";
    string internal constant STAKER_VAULT_EXISTS = "a staker vault already exists for the token";
    string internal constant DEADLINE_NOT_ZERO = "deadline must be 0";
    string internal constant DEADLINE_NOT_SET = "deadline is 0";
    string internal constant DEADLINE_NOT_REACHED = "deadline has not been reached yet";
    string internal constant DELAY_TOO_SHORT = "delay be at least 3 days";
    string internal constant INSUFFICIENT_UPDATE_BALANCE =
        "insufficient funds for updating the position";
    string internal constant SAME_AS_CURRENT = "value must be different to existing value";
    string internal constant NOT_CAPPED = "the pool is not currently capped";
    string internal constant ALREADY_CAPPED = "the pool is already capped";
    string internal constant EXCEEDS_DEPOSIT_CAP = "deposit exceeds deposit cap";
    string internal constant VALUE_TOO_LOW_FOR_GAS = "value too low to cover gas";
    string internal constant NOT_ENOUGH_FUNDS = "not enough funds to withdraw";
    string internal constant ESTIMATED_GAS_TOO_HIGH = "too much ETH will be used for gas";
    string internal constant DEPOSIT_FAILED = "deposit failed";
    string internal constant GAS_TOO_HIGH = "too much ETH used for gas";
    string internal constant GAS_BANK_BALANCE_TOO_LOW = "not enough ETH in gas bank to cover gas";
    string internal constant INVALID_TOKEN_TO_ADD = "Invalid token to add";
    string internal constant INVALID_TOKEN_TO_REMOVE = "token can not be removed";
    string internal constant TIME_DELAY_NOT_EXPIRED = "time delay not expired yet";
    string internal constant UNDERLYING_NOT_WITHDRAWABLE =
        "pool does not support additional underlying coins to be withdrawn";
    string internal constant STRATEGY_SHUT_DOWN = "Strategy is shut down";
    string internal constant STRATEGY_DOES_NOT_EXIST = "Strategy does not exist";
    string internal constant UNSUPPORTED_UNDERLYING = "Underlying not supported";
    string internal constant NO_DEX_SET = "no dex has been set for token";
    string internal constant INVALID_TOKEN_PAIR = "invalid token pair";
    string internal constant TOKEN_NOT_USABLE = "token not usable for the specific action";
    string internal constant ADDRESS_NOT_ACTION = "address is not registered action";
    string internal constant INVALID_SLIPPAGE_TOLERANCE = "Invalid slippage tolerance";
    string internal constant POOL_NOT_PAUSED = "Pool must be paused to withdraw from reserve";
    string internal constant INTERACTION_LIMIT = "Max of one deposit and withdraw per block";
    string internal constant GAUGE_EXISTS = "Gauge already exists";
    string internal constant GAUGE_DOES_NOT_EXIST = "Gauge does not exist";
    string internal constant EXCEEDS_MAX_BOOST = "Not allowed to exceed maximum boost on Convex";
    string internal constant PREPARED_WITHDRAWAL =
        "Cannot relock funds when withdrawal is being prepared";
    string internal constant ASSET_NOT_SUPPORTED = "Asset not supported";
    string internal constant STALE_PRICE = "Price is stale";
    string internal constant NEGATIVE_PRICE = "Price is negative";
    string internal constant NOT_ENOUGH_BKD_STAKED = "Not enough BKD tokens staked";
    string internal constant RESERVE_ACCESS_EXCEEDED = "Reserve access exceeded";
}


// File libraries/Roles.sol

pragma solidity 0.8.9;

// solhint-disable private-vars-leading-underscore

library Roles {
    bytes32 internal constant GOVERNANCE = "governance";
    bytes32 internal constant ADDRESS_PROVIDER = "address_provider";
    bytes32 internal constant POOL_FACTORY = "pool_factory";
    bytes32 internal constant CONTROLLER = "controller";
    bytes32 internal constant GAUGE_ZAP = "gauge_zap";
    bytes32 internal constant MAINTENANCE = "maintenance";
    bytes32 internal constant INFLATION_MANAGER = "inflation_manager";
    bytes32 internal constant POOL = "pool";
    bytes32 internal constant VAULT = "vault";
}


// File contracts/access/AuthorizationBase.sol

pragma solidity 0.8.9;


/**
 * @notice Provides modifiers for authorization
 */
abstract contract AuthorizationBase {
    /**
     * @notice Only allows a sender with `role` to perform the given action
     */
    modifier onlyRole(bytes32 role) {
        require(_roleManager().hasRole(role, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with GOVERNANCE role to perform the given action
     */
    modifier onlyGovernance() {
        require(_roleManager().hasRole(Roles.GOVERNANCE, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles2(bytes32 role1, bytes32 role2) {
        require(_roleManager().hasAnyRole(role1, role2, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles3(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _roleManager().hasAnyRole(role1, role2, role3, msg.sender),
            Error.UNAUTHORIZED_ACCESS
        );
        _;
    }

    function roleManager() external view virtual returns (IRoleManager) {
        return _roleManager();
    }

    function _roleManager() internal view virtual returns (IRoleManager);
}


// File contracts/access/Authorization.sol

pragma solidity 0.8.9;

contract Authorization is AuthorizationBase {
    IRoleManager internal immutable __roleManager;

    constructor(IRoleManager roleManager) {
        __roleManager = roleManager;
    }

    function _roleManager() internal view override returns (IRoleManager) {
        return __roleManager;
    }
}


// File contracts/utils/SlippageTolerance.sol

pragma solidity 0.8.9;


contract SlippageTolerance is Authorization {
    using ScaledMath for uint256;

    uint256 public slippageTolerance;

    event SetSlippageTolerance(uint256 value); // Emitted after a succuessful setting of slippage tolerance

    constructor(IRoleManager roleManager) Authorization(roleManager) {
        slippageTolerance = 0.97e18;
    }

    /**
     * @notice Set slippage tolerance for reward token swaps.
     * @dev Stored as a multiplier, e.g. 2% would be set as 0.98.
     * @param _slippageTolerance New imbalance tolarance out.
     * @return True if successfully set.
     */
    function setSlippageTolerance(uint256 _slippageTolerance)
        external
        onlyGovernance
        returns (bool)
    {
        require(_slippageTolerance <= ScaledMath.ONE, Error.INVALID_SLIPPAGE_TOLERANCE);
        require(_slippageTolerance > 0.8e18, Error.INVALID_SLIPPAGE_TOLERANCE);
        slippageTolerance = _slippageTolerance;
        emit SetSlippageTolerance(_slippageTolerance);
        return true;
    }
}


// File interfaces/vendor/IBooster.sol

pragma solidity 0.8.9;

interface IBooster {
    function poolInfo(uint256 pid)
        external
        returns (
            address lpToken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    /**
     * @dev `_pid` is the ID of the Convex for a specific Curve LP token.
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);
}


// File interfaces/vendor/ICurveSwapEth.sol

pragma solidity 0.8.9;

interface ICurveSwapEth {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function coins(uint256 i) external view returns (address);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}


// File interfaces/vendor/IRewardStaking.sol

pragma solidity 0.8.9;

interface IRewardStaking {
    function stakeFor(address, uint256) external;

    function stake(uint256) external;

    function stakeAll() external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account, bool _claimExtras) external;

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 _pid) external view returns (address);

    function rewardToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);
}


// File interfaces/vendor/UniswapRouter02.sol

pragma solidity 0.8.9;

interface UniswapRouter02 {
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountOut);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function WETH() external pure returns (address);
}

interface UniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


// File interfaces/vendor/IWETH.sol

pragma solidity 0.8.9;

/**
 * @notice Interface for WETH9
 * @dev https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}


// File contracts/strategies/BkdEthCvx.sol

pragma solidity 0.8.9;













/**
 * This is the BkdEthCvx strategy, which is designed to be used by a Backd ETH Vault.
 * The strategy holds ETH as it's underlying and allocates liquidity to Convex via given Curve Pool with 2 underlying tokens.
 * Rewards received on Convex (CVX, CRV), are sold in part for the underlying.
 * A share of earned CVX & CRV are retained on behalf of the Backd community to participate in governance.
 */
contract BkdEthCvx is IStrategy, CvxMintAmount, SlippageTolerance {
    using ScaledMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressProviderHelpers for IAddressProvider;

    uint256 private constant _CURVE_CVX_INDEX = 1;
    uint256 private constant _CURVE_ETH_INDEX = 0;

    IBooster private constant _BOOSTER = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31); // Convex Booster Contract
    IERC20 private constant _CVX = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B); // CVX
    IWETH private constant _WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
    IERC20 private constant _CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV
    UniswapRouter02 private constant _SUSHISWAP =
        UniswapRouter02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // Sushiswap Router for swaps
    UniswapRouter02 private constant _UNISWAP =
        UniswapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap Router for swaps
    ICurveSwapEth internal constant _CVX_ETH_CURVE_POOL =
        ICurveSwapEth(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4); // CVX/ETH Curve Pool

    IAddressProvider internal immutable _addressProvider; // Address provider used for getting oracle provider
    address payable public immutable vault; // Backd Vault
    ICurveSwapEth public immutable curvePool; // Curve Pool
    IERC20 public immutable lp; // Curve Pool LP Token
    IRewardStaking public immutable rewards; // Rewards Contract for claiming Convex Rewards
    uint256 public immutable convexPid; // Index of Convex Pool in Booster Contract
    uint256 public immutable curveIndex; // Underlying index in Curve Pool

    uint256 public imbalanceToleranceIn; // Maximum allowed slippage from Curve Pool Imbalance for depositing
    uint256 public imbalanceToleranceOut; // Maximum allowed slippage from Curve Pool Imbalance for withdrawing
    address public communityReserve; // Address for sending CVX & CRV Community Reserve share
    uint256 public cvxCommunityReserveShare; // Share of CVX sent to Community Reserve
    uint256 public crvCommunityReserveShare; // Share of CRV sent to Community Reserve
    address public override strategist; // The strategist for the strategy
    bool public isShutdown; // If the strategy is shutdown, stops all deposits
    mapping(address => UniswapRouter02) public tokenDex; // Dex to use for swapping for a given token

    EnumerableSet.AddressSet private _rewardTokens; // List of additional reward tokens when claiming rewards on Convex

    event Deposit(uint256 amount); // Emitted after a successfull deposit
    event Withdraw(uint256 amount); // Emitted after a successful withdrawal
    event WithdrawAll(uint256 amount); // Emitted after successfully withdrwaing all
    event Harvest(uint256 amount); // Emitted after a successful harvest
    event Shutdown(); // Emitted after a successful shutdown
    event SetCommunityReserve(address reserve); // Emitted after a succuessful setting of reserve
    event SetCrvCommunityReserveShare(uint256 value); // Emitted after a succuessful setting of CRV Community Reserve Share
    event SetCvxCommunityReserveShare(uint256 value); // Emitted after a succuessful setting of CVX Community Reserve Share
    event SetImbalanceToleranceIn(uint256 value); // Emitted after a succuessful setting of imbalance tolerance in
    event SetImbalanceToleranceOut(uint256 value); // Emitted after a succuessful setting of imbalance tolerance out
    event SetStrategist(address strategist); // Emitted after a succuessful setting of strategist
    event AddRewardToken(address token); // Emitted after successfully adding a new reward token
    event RemoveRewardToken(address token); // Emitted after successfully removing a reward token
    event SwapDex(address token, address newDex); // Emitted after successfully swapping a tokens dex

    modifier onlyVault() {
        require(msg.sender == vault, Error.UNAUTHORIZED_ACCESS);
        _;
    }

    constructor(
        address vault_,
        address strategist_,
        address curvePool_,
        uint256 convexPid_,
        uint256 curveIndex_,
        IAddressProvider addressProvider_
    ) SlippageTolerance(addressProvider_.getRoleManager()) {
        // Setting inputs
        vault = payable(vault_);
        strategist = strategist_;
        curvePool = ICurveSwapEth(curvePool_);
        convexPid = convexPid_;
        curveIndex = curveIndex_;
        _addressProvider = addressProvider_;

        // Setting LP and Rewards contracts
        (address lp_, , , address rewards_, , ) = _BOOSTER.poolInfo(convexPid_);
        lp = IERC20(lp_);
        rewards = IRewardStaking(rewards_);

        // Setting default values
        imbalanceToleranceIn = 0.0007e18;
        imbalanceToleranceOut = 0.0104e18;

        // Setting dexes
        _setDex(address(_CRV), _SUSHISWAP);
        _setDex(address(_CVX), _SUSHISWAP);

        // Approvals
        IERC20(lp_).safeApprove(address(_BOOSTER), type(uint256).max);
        _CVX.safeApprove(address(_CVX_ETH_CURVE_POOL), type(uint256).max);
        _CRV.safeApprove(address(_SUSHISWAP), type(uint256).max);
    }

    receive() external payable {}

    /**
     * @notice Deposit all available underlying into Convex pool.
     * @dev Liquidity is added to Curve Pool then Curve LP tokens are deposited
     * 		into Convex and Convex LP tokens are staked for rewards by default.
     * @return True if successful deposit.
     */
    function deposit() external payable override onlyVault returns (bool) {
        require(!isShutdown, Error.STRATEGY_SHUT_DOWN);

        // Depositing into Curve Pool
        uint256 underlyingBalance = _underlyingBalance();
        if (underlyingBalance == 0) return false;
        uint256[2] memory amounts;
        amounts[curveIndex] = underlyingBalance;
        curvePool.add_liquidity{value: underlyingBalance}(
            amounts,
            _minLpAccepted(underlyingBalance)
        );

        // Depositing into Convex and Staking
        if (!_BOOSTER.depositAll(convexPid, true)) return false;
        emit Deposit(underlyingBalance);
        return true;
    }

    /**
     * @notice Withdraw an amount of underlying to the vault.
     * @dev This can only be called by the vault.
     *      If the amount is not available, it will be made liquid.
     * @param amount Amount of underlying to withdraw.
     * @return True if successful withdrawal.
     */
    function withdraw(uint256 amount) external override onlyVault returns (bool) {
        if (amount == 0) return false;
        uint256 underlyingBalance = _underlyingBalance();

        // Transferring from idle balance if enough
        if (underlyingBalance >= amount) {
            if (!vault.send(amount)) return false;
            emit Withdraw(amount);
            return true;
        }

        // Unstaking needed LP Tokens from Convex
        uint256 requiredUnderlyingAmount = amount - underlyingBalance;
        uint256 maxLpBurned = _maxLpBurned(requiredUnderlyingAmount);
        uint256 requiredLpAmount = maxLpBurned - _lpBalance();
        if (!rewards.withdrawAndUnwrap(requiredLpAmount, false)) return false;

        // Removing needed liquidity from Curve
        uint256[2] memory amounts;
        // solhint-disable-next-line reentrancy
        amounts[curveIndex] = requiredUnderlyingAmount;
        curvePool.remove_liquidity_imbalance(amounts, maxLpBurned);
        vault.transfer(amount);
        emit Withdraw(amount);
        return true;
    }

    /**
     * @notice Withdraw all underlying to vault.
     * @dev This does not liquidate reward tokens and only considers
     *      idle underlying, idle lp tokens and staked lp tokens.
     * @return Amount of underlying withdrawn
     */
    function withdrawAll() external override returns (uint256) {
        require(
            msg.sender == vault || _roleManager().hasRole(Roles.GOVERNANCE, msg.sender),
            Error.UNAUTHORIZED_ACCESS
        );
        // Unstaking and withdrawing from Convex pool
        uint256 stakedBalance = _stakedBalance();
        if (stakedBalance > 0) {
            if (!rewards.withdrawAndUnwrap(stakedBalance, false)) return 0;
        }

        // Removing liquidity from Curve
        uint256 lpBalance = _lpBalance();
        if (lpBalance > 0) {
            curvePool.remove_liquidity_one_coin(
                lpBalance,
                int128(uint128(curveIndex)),
                _minUnderlyingAccepted(lpBalance)
            );
        }

        // Transferring underlying to vault
        uint256 underlyingBalance = _underlyingBalance();
        if (underlyingBalance == 0) return 0;
        vault.transfer(underlyingBalance);
        emit WithdrawAll(underlyingBalance);
        return underlyingBalance;
    }

    /**
     * @notice Harvests reward tokens and sells these for the underlying.
     * @dev Any underlying harvested is not redeposited by this method.
     * @return Amount of underlying harvested.
     */
    function harvest() external override onlyVault returns (uint256) {
        uint256 underlyingBalance = _underlyingBalance();

        // Claim Convex rewards
        rewards.getReward(address(this), false);

        // Sending share to Community Reserve
        _sendCommunityReserveShare();

        // Swap CVX for WETH
        _swapAllForWeth(_CVX);

        // Swap CRV for WETH
        _swapAllForWeth(_CRV);

        // Swap Extra Rewards for WETH
        for (uint256 i = 0; i < _rewardTokens.length(); i++) {
            _swapAllForWeth(IERC20(_rewardTokens.at(i)));
        }

        // Swap WETH for underlying
        _swapWethForUnderlying();

        uint256 harvested = _underlyingBalance() - underlyingBalance;
        emit Harvest(harvested);
        return harvested;
    }

    /**
     * @notice Shuts down the strategy, disabling deposits.
     * @return True if the strategy was succesfully shutdown
     */
    function shutdown() external override onlyVault returns (bool) {
        if (isShutdown) return false;
        isShutdown = true;
        emit Shutdown();
        return true;
    }

    /**
     * @notice Set the address of the communit reserve.
     * @dev CRV & CVX will be taxed and allocated to the reserve,
     *      such that Backd can participate in governance.
     * @param _communityReserve Address of the community reserve.
     * @return True if successfully set.
     */
    function setCommunityReserve(address _communityReserve) external onlyGovernance returns (bool) {
        communityReserve = _communityReserve;
        emit SetCommunityReserve(_communityReserve);
        return true;
    }

    /**
     * @notice Set the share of CRV to send to the Community Reserve.
     * @param crvCommunityReserveShare_ New fee charged on CRV rewards for governance.
     * @return True if successfully set.
     */
    function setCrvCommunityReserveShare(uint256 crvCommunityReserveShare_)
        external
        onlyGovernance
        returns (bool)
    {
        require(crvCommunityReserveShare_ <= ScaledMath.ONE, Error.INVALID_AMOUNT);
        require(communityReserve != address(0), "Community reserve must be set");
        crvCommunityReserveShare = crvCommunityReserveShare_;
        emit SetCrvCommunityReserveShare(crvCommunityReserveShare_);
        return true;
    }

    /**
     * @notice Set the share of CVX to send to the Community Reserve.
     * @param cvxCommunityReserveShare_ New fee charged on CVX rewards for governance.
     * @return True if successfully set.
     */
    function setCvxCommunityReserveShare(uint256 cvxCommunityReserveShare_)
        external
        onlyGovernance
        returns (bool)
    {
        require(cvxCommunityReserveShare_ <= ScaledMath.ONE, Error.INVALID_AMOUNT);
        require(communityReserve != address(0), "Community reserve must be set");
        cvxCommunityReserveShare = cvxCommunityReserveShare_;
        emit SetCvxCommunityReserveShare(cvxCommunityReserveShare_);
        return true;
    }

    /**
     * @notice Set imbalance tolerance for Curve Pool deposits.
     * @dev Stored as a percent, e.g. 1% would be set as 0.01
     * @param _imbalanceToleranceIn New imbalance tolarance in.
     * @return True if successfully set.
     */
    function setImbalanceToleranceIn(uint256 _imbalanceToleranceIn)
        external
        onlyGovernance
        returns (bool)
    {
        imbalanceToleranceIn = _imbalanceToleranceIn;
        emit SetImbalanceToleranceIn(_imbalanceToleranceIn);
        return true;
    }

    /**
     * @notice Set imbalance tolerance for Curve Pool withdrawals.
     * @dev Stored as a percent, e.g. 1% would be set as 0.01
     * @param _imbalanceToleranceOut New imbalance tolarance out.
     * @return True if successfully set.
     */
    function setImbalanceToleranceOut(uint256 _imbalanceToleranceOut)
        external
        onlyGovernance
        returns (bool)
    {
        imbalanceToleranceOut = _imbalanceToleranceOut;
        emit SetImbalanceToleranceOut(_imbalanceToleranceOut);
        return true;
    }

    /**
     * @notice Set strategist.
     * @dev Can only be set by current strategist.
     * @param _strategist Address of new strategist.
     * @return True if successfully set.
     */
    function setStrategist(address _strategist) external returns (bool) {
        require(msg.sender == strategist, Error.UNAUTHORIZED_ACCESS);
        strategist = _strategist;
        emit SetStrategist(_strategist);
        return true;
    }

    /**
     * @notice Add a reward token to list of extra reward tokens.
     * @dev These are tokens that are not the main assets of the strategy. For instance, temporary incentives.
     * @param token Address of token to add to reward token list.
     * @return True if successfully added.
     */
    function addRewardToken(address token) external onlyGovernance returns (bool) {
        require(
            token != address(_CVX) && token != address(_CRV) && token != address(_WETH),
            Error.INVALID_TOKEN_TO_ADD
        );
        if (_rewardTokens.contains(token)) return false;
        _rewardTokens.add(token);
        _setDex(token, _SUSHISWAP);
        IERC20(token).safeApprove(address(_SUSHISWAP), 0);
        IERC20(token).safeApprove(address(_SUSHISWAP), type(uint256).max);
        emit AddRewardToken(token);
        return true;
    }

    /**
     * @notice Remove a reward token.
     * @param token Address of token to remove from reward token list.
     * @return True if successfully removed.
     */
    function removeRewardToken(address token) external onlyGovernance returns (bool) {
        if (!_rewardTokens.contains(token)) return false;
        if (!_rewardTokens.remove(token)) return false;
        emit RemoveRewardToken(token);
        return true;
    }

    /**
     * @notice Set the DEX that should be used for swapping for a specific coin.
     *         If Uniswap is active, it will switch to SushiSwap and vice versa.
     * @dev Only SushiSwap and Uniswap are supported.
     * @param token Address of token for which the DEX should be updated.
     */
    function swapDex(address token) external onlyGovernance returns (bool) {
        UniswapRouter02 currentDex = tokenDex[token];
        require(address(currentDex) != address(0), Error.NO_DEX_SET);
        UniswapRouter02 newDex = currentDex == _SUSHISWAP ? _UNISWAP : _SUSHISWAP;
        _setDex(token, newDex);
        IERC20(token).safeApprove(address(newDex), 0);
        IERC20(token).safeApprove(address(newDex), type(uint256).max);
        emit SwapDex(token, address(newDex));
        return true;
    }

    /**
     * @notice Returns the name of the strategy.
     * @return The name of the strategy.
     */
    function name() external view override returns (string memory) {
        return "BkdEthCvx";
    }

    /**
     * @notice Amount of rewards that can be harvested in the underlying.
     * @dev Includes rewards for CRV & CVX.
     * @return Estimated amount of underlying available to harvest.
     */
    function harvestable() external view override returns (uint256) {
        uint256 crvAmount_ = rewards.earned(address(this));
        if (crvAmount_ == 0) return 0;
        return
            _underlyingAmountOut(
                _CRV,
                crvAmount_.scaledMul(ScaledMath.ONE - crvCommunityReserveShare)
            ) +
            _underlyingAmountOut(
                _CVX,
                getCvxMintAmount(crvAmount_).scaledMul(ScaledMath.ONE - cvxCommunityReserveShare)
            );
    }

    /**
     * @dev Contract does not stash tokens.
     */
    function hasPendingFunds() external pure override returns (bool) {
        return false;
    }

    /**
     * @notice Get the total underlying balance of the strategy.
     * @dev This includes idle underlying, idle LP and LP deposited on Convex.
     * @return Underlying balance of strategy.
     */
    function balance() public view override returns (uint256) {
        return _underlyingBalance() + _lpToUnderlying(_stakedBalance() + _lpBalance());
    }

    /**
     * @dev Set the dex to use for a token.
     * @param token Address of token to set the dex for.
     * @param dex Dex to use for swaps with that token.
     */
    function _setDex(address token, UniswapRouter02 dex) internal {
        tokenDex[token] = dex;
    }

    /**
     * @notice Swaps all balance of a token for WETH.
     * @param token Address of the token to swap for WETH.
     */
    function _swapAllForWeth(IERC20 token) internal {
        uint256 amount = token.balanceOf(address(this));
        return _swapForWeth(token, amount);
    }

    /**
     * @notice Swaps a token for WETH.
     * @param token Address of the token to swap for WETH.
     * @param amount Amount of the token to swap for WETH.
     */
    function _swapForWeth(IERC20 token, uint256 amount) internal {
        if (amount == 0) return;

        // Handling CVX Swaps
        if (token == _CVX) {
            _CVX_ETH_CURVE_POOL.exchange(
                _CURVE_CVX_INDEX,
                _CURVE_ETH_INDEX,
                amount,
                amount
                    .scaledMul(_addressProvider.getOracleProvider().getPriceETH(address(_CVX)))
                    .scaledMul(slippageTolerance)
            );
            return;
        }

        // Handling other swaps
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(_WETH);
        tokenDex[address(token)].swapExactTokensForTokens(
            amount,
            amount
                .scaledMul(_addressProvider.getOracleProvider().getPriceETH(address(token)))
                .scaledMul(slippageTolerance),
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @notice Swaps all available WETH for underlying.
     */
    function _swapWethForUnderlying() internal {
        uint256 wethBalance = _WETH.balanceOf(address(this));
        if (wethBalance == 0) return;
        _WETH.withdraw(wethBalance);
    }

    /**
     * @notice Sends a share of the current balance of CRV and CVX to the Community Reserve.
     */
    function _sendCommunityReserveShare() internal {
        address communityReserve_ = communityReserve;
        if (communityReserve_ == address(0)) return;
        uint256 cvxCommunityReserveShare_ = cvxCommunityReserveShare;
        if (cvxCommunityReserveShare_ > 0) {
            uint256 cvxBalance_ = _CVX.balanceOf(address(this));
            if (cvxBalance_ > 0) {
                _CVX.safeTransfer(
                    communityReserve_,
                    cvxBalance_.scaledMul(cvxCommunityReserveShare_)
                );
            }
        }
        uint256 crvCommunityReserveShare_ = crvCommunityReserveShare;
        if (crvCommunityReserveShare_ > 0) {
            uint256 crvBalance_ = _CRV.balanceOf(address(this));
            if (crvBalance_ > 0) {
                _CRV.safeTransfer(
                    communityReserve_,
                    crvBalance_.scaledMul(crvCommunityReserveShare_)
                );
            }
        }
    }

    /**
     * @dev Get the balance of the underlying.
     */
    function _underlyingBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get the balance of the lp.
     */
    function _lpBalance() internal view returns (uint256) {
        return lp.balanceOf(address(this));
    }

    /**
     * @dev Get the balance of the underlying staked in the Curve pool.
     */
    function _stakedBalance() internal view returns (uint256) {
        return rewards.balanceOf(address(this));
    }

    /**
     * @notice Gets the amount of underlying that would be received by selling the token.
     * @return Underlying amount that would be received.
     */
    function _underlyingAmountOut(IERC20 token, uint256 amountIn) internal view returns (uint256) {
        if (amountIn == 0) return 0;
        if (token == _CVX) {
            return _CVX_ETH_CURVE_POOL.get_dy(_CURVE_CVX_INDEX, _CURVE_ETH_INDEX, amountIn);
        }
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(_WETH);
        return tokenDex[address(token)].getAmountsOut(amountIn, path)[1];
    }

    /**
     * @notice Calculates the minimum LP to accept when depositing underlying into Curve Pool.
     * @param _underlyingAmount Amount of underlying that is being deposited into Curve Pool.
     * @return The minimum LP balance to accept.
     */
    function _minLpAccepted(uint256 _underlyingAmount) internal view returns (uint256) {
        return _underlyingToLp(_underlyingAmount).scaledMul(ScaledMath.ONE - imbalanceToleranceIn);
    }

    /**
     * @notice Calculates the maximum LP to accept burning when withdrawing amount from Curve Pool.
     * @param _underlyingAmount Amount of underlying that is being widthdrawn from Curve Pool.
     * @return The maximum LP balance to accept burning.
     */
    function _maxLpBurned(uint256 _underlyingAmount) internal view returns (uint256) {
        return _underlyingToLp(_underlyingAmount).scaledMul(ScaledMath.ONE + imbalanceToleranceOut);
    }

    /**
     * @notice Calculates the minimum underlying to accept when burning LP tokens to withdraw from Curve Pool.
     * @param _lpAmount Amount of LP tokens being burned to withdraw from Curve Pool.
     * @return The minimum underlying balance to accept.
     */
    function _minUnderlyingAccepted(uint256 _lpAmount) internal view returns (uint256) {
        return _lpToUnderlying(_lpAmount).scaledMul(ScaledMath.ONE - imbalanceToleranceOut);
    }

    /**
     * @notice Converts an amount of underlying into their estimated LP value.
     * @dev Uses get_virtual_price which is less suceptible to manipulation.
     *  But is also less accurate to how much could be withdrawn.
     * @param _underlyingAmount Amount of underlying to convert.
     * @return The estimated value in the LP.
     */
    function _underlyingToLp(uint256 _underlyingAmount) internal view returns (uint256) {
        return _underlyingAmount.scaledDiv(curvePool.get_virtual_price());
    }

    /**
     * @notice Converts an amount of LP into their estimated underlying value.
     * @dev Uses get_virtual_price which is less suceptible to manipulation.
     *  But is also less accurate to how much could be withdrawn.
     * @param _lpAmount Amount of LP to convert.
     * @return The estimated value in the underlying.
     */
    function _lpToUnderlying(uint256 _lpAmount) internal view returns (uint256) {
        return _lpAmount.scaledMul(curvePool.get_virtual_price());
    }
}