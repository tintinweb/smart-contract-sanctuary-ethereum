/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/utils/structs/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/access/AccessControl.sol


pragma solidity 0.8.11;

// This is adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/access/AccessControl.sol
// The only difference is added getRoleMemberIndex(bytes32 role, address account) function.



/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the index of the account that have `role`.
     */
    function getRoleMemberIndex(bytes32 role, address account) public view returns (uint256) {
        return _roles[role].members._inner._indexes[bytes32(uint256(uint160(account)))];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File contracts/utils/Arrays.sol


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    function find(uint256[] storage values, uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256 i = 0;
        while (values[i] != value) {
            i++;
        }
        return i;
    }

    function removeByValue(uint256[] storage values, uint256 value) internal {
        uint256 length = values.length;
        for (uint256 i = find(values, value); i < length; ++i) {
            if (i < length - 1) {
                values[i] = values[i + 1];
            }
        }
        values.pop();
    }
}


// File contracts/ISafeMint.sol

pragma solidity ^0.8.11;

interface ISafeMint {
    /// @dev 状态枚举类型
    enum Status {
        pending, // 处理中
        passed, // 通过
        reject, // 驳回
        challenge, // 挑战
        locked // 锁定
    }
    /// @dev 项目信息
    struct Project {
        string name; // 项目名称(唯一)
        address owner; // 项目创建者
        uint256 createTime; // 创建时间
        address projectContract; // 项目合约地址
        uint256 startTime; // 开始铸造的时间
        uint256 endTime; // 结束铸造的时间
        string ipfsAddress; // ipfs中存储的json信息地址
        uint256 projectFee; // 项目提交费
        Status status; // 状态
    }

    /// @dev 提交项目
    event SaveProject(
        string indexed name,
        address indexed owner,
        address indexed projectContract,
        uint256 startTime,
        uint256 endTime,
        string ipfsAddress,
        uint256 projectPrice,
        uint256 projectId
    );

    /// @dev 编辑项目
    event EditProject(
        string indexed name,
        uint256 startTime,
        uint256 endTime,
        string ipfsAddress
    );

    /// @dev 状态转换
    event ProjectStatus(string indexed name, Status status);

    /// @dev 审计合约提币
    event AuditorClaimFee(string indexed name, uint256 projectFee);

    /// @dev 返回项目ID
    function projectId(string calldata name) external view returns (uint256);

    /// @dev 修改项目状态
    function projectStatus(string calldata name, Status status) external;

    /// @dev 获取项目信息
    function getProject(string calldata name)
        external
        view
        returns (uint256, Project memory);

    /// @dev 获取项目信息
    function getProjectById(uint256 _projectId)
        external
        view
        returns (Project memory);

    /// @dev 审计合约提币
    function auditorClaimFee(string calldata name) external;
}


// File contracts/SafeMintData.sol

pragma solidity ^0.8.11;

abstract contract SafeMintData is ISafeMint {
    /// @dev 用户地址=>布尔值,一个用户只能提交一个项目
    mapping(address => bool) public user;
    /// @dev 项目合约地址=>布尔值,一个项目地址只能提交一次
    mapping(address => bool) public contractAddress;
    /// @dev 项目名称hash=>项目ID,用项目名称找到项目ID
    mapping(bytes32 => uint256) public namehashToId;

    /// @dev ERC20 Token address
    address public token;
    /// @dev 通过的数组
    uint256[] public passedArr;
    /// @dev 处理中的数组
    uint256[] public pendingArr;
    /// @dev 驳回的数组
    uint256[] public rejectArr;
    /// @dev 锁定的数组
    uint256[] public lockedArr;
    /// @dev 挑战的数组
    uint256[] public challengeArr;
    /// @dev 项目的数组
    Project[] public projectArr;
    /// @dev 提交项目的价格
    uint256 public projectPrice;

    /// @dev Auditor 常量
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    /// @dev 报错
    error ProjectStatusError(Status projectStatus);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/SafeMint.sol

pragma solidity ^0.8.11;




contract SafeMint is AccessControl, SafeMintData {
    using Arrays for uint256[];
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "sender doesn't have admin role"
        );
        _;
    }

    modifier onlyAuditor() {
        // 确认审计员身份
        require(
            hasRole(AUDITOR_ROLE, msg.sender),
            "sender doesn't have auditor role"
        );
        _;
    }

    /// @dev 构造函数
    constructor(address _token) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = _token;
    }

    /**
     * @dev 提交项目
     * @param name 项目名称
     * @param projectContract 项目合约地址
     * @param startTime 开始铸造的时间
     * @param endTime 结束铸造的时间
     * @param ipfsAddress ipfs中存储的json信息地址
     */
    function saveProject(
        string calldata name,
        address projectContract,
        uint256 startTime,
        uint256 endTime,
        string calldata ipfsAddress
    ) public {
        // 验证项目收费
        IERC20(token).transferFrom(msg.sender, address(this), projectPrice);
        // 验证用户只能提交一次
        require(
            !user[msg.sender] && msg.sender == tx.origin,
            "user aleardy saved"
        );
        user[msg.sender] = true;
        // 一个项目地址只能提交一次
        require(
            !contractAddress[projectContract],
            "contractAddress aleardy saved"
        );
        contractAddress[projectContract] = true;
        // 验证项目名称
        require(!projectName(name), "name aleardy used");

        // 项目结构体
        Project memory _project = Project({
            name: name,
            owner: msg.sender,
            projectContract: projectContract,
            createTime: block.timestamp,
            startTime: startTime,
            endTime: endTime,
            ipfsAddress: ipfsAddress,
            projectFee: projectPrice,
            status: Status.pending
        });

        // 推入项目数组
        projectArr.push(_project);
        // 项目ID
        uint256 _projectId = projectArr.length;
        // 记录项目ID
        namehashToId[keccak256(abi.encodePacked(name))] = _projectId;
        // 推入处理中数组
        pendingArr.push(_projectId);
        emit SaveProject(
            name,
            msg.sender,
            projectContract,
            startTime,
            endTime,
            ipfsAddress,
            projectPrice,
            _projectId
        );
    }

    /**
     * @dev 修改
     * @param name 项目名称
     * @param startTime 开始铸造的时间
     * @param endTime 结束铸造的时间
     * @param ipfsAddress ipfs中存储的json信息地址
     */
    function editProject(
        string calldata name,
        uint256 startTime,
        uint256 endTime,
        string calldata ipfsAddress
    ) public {
        // 项目结构体
        (uint256 _projectId, Project memory _project) = getProject(name);
        // 确认调用者身份
        require(_project.owner == msg.sender, "caller is not project owner");
        // 确认状态输入正确
        require(_project.status == Status.reject, "Status error!");
        // 修改信息
        _project.startTime = startTime;
        _project.endTime = endTime;
        _project.ipfsAddress = ipfsAddress;
        _project.status = Status.pending;
        // 修改状态
        _saveProject(_projectId, _project);
        // 从驳回的数组中移除项目ID
        rejectArr.removeByValue(_projectId);
        // 推入到处理中数组
        pendingArr.push(_projectId);
        emit EditProject(name, startTime, endTime, ipfsAddress);
    }

    /**
     * @dev 状态转换
     * @param name 项目名称
     * @param status 结果状态
     */
    function projectStatus(string calldata name, Status status)
        public
        onlyAuditor
    {
        // 项目ID, 项目结构体
        (uint256 _projectId, Project memory _project) = getProject(name);
        if (_project.status == Status.pending) {
            // 确认状态输入正确
            require(
                status == Status.passed ||
                    status == Status.reject ||
                    status == Status.locked,
                "Status error!"
            );
            // 从pending数组中移除项目ID
            pendingArr.removeByValue(_projectId);
            // 如果状态为通过
            if (status == Status.passed) {
                // 推入通过数组
                passedArr.push(_projectId);
                // 修改状态
                _project.status = Status.passed;
            }
            // 如果状态为驳回
            if (status == Status.reject) {
                // 推入驳回数组
                rejectArr.push(_projectId);
                // 修改状态
                _project.status = Status.reject;
            }
            // 如果状态为锁定
            if (status == Status.locked) {
                // 推入锁定数组
                lockedArr.push(_projectId);
                // 修改状态
                _project.status = Status.locked;
            }
        } else if (_project.status == Status.challenge) {
            // 确认状态输入正确
            require(
                status == Status.passed || status == Status.locked,
                "1Status error!"
            );
            // 从挑战的数组中移除项目ID
            challengeArr.removeByValue(_projectId);
            if (status == Status.passed) {
                // 修改状态
                _project.status = Status.passed;
            }
            // 如果状态为锁定
            if (status == Status.locked) {
                // 从通过的数组中移除项目ID
                passedArr.removeByValue(_projectId);
                // 推入锁定数组
                lockedArr.push(_projectId);
                // 修改状态
                _project.status = Status.locked;
            }
        } else if (_project.status == Status.passed) {
            // 确认状态输入正确
            require(status == Status.challenge, "Status error!");
            // 推入挑战数组
            challengeArr.push(_projectId);
            // 修改状态
            _project.status = Status.challenge;
        } else {
            revert ProjectStatusError(_project.status);
        }
        _saveProject(_projectId, _project);
        // 触发事件
        emit ProjectStatus(name, status);
    }

    /// @dev 管理员设置价格
    function adminSetProjectPrice(uint256 _price) public onlyAdmin {
        projectPrice = _price;
    }

    /// @dev 管理员取款
    function adminWithdraw(address payable to) public onlyAdmin {
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    }

    function auditorClaimFee(string calldata name) public onlyAuditor {
        // 项目ID, 项目结构体
        (, Project memory _project) = getProject(name);
        require(
            _project.status == Status.locked ||
                _project.status == Status.passed,
            "Status error!"
        );
        if (_project.projectFee > 0) {
            IERC20(token).transfer(msg.sender, _project.projectFee);
            emit AuditorClaimFee(name, _project.projectFee);
        }
    }

    /// @dev 返回项目名称是否存在
    function projectName(string calldata name) public view returns (bool) {
        return namehashToId[keccak256(abi.encodePacked(name))] > 0;
    }

    function _saveProject(uint256 _projectId, Project memory _project) private {
        projectArr[_projectId - 1] = _project;
    }

    /**
     * @dev 根据开始索引和长度数量,返回制定数组
     * @param arr 指定的数组
     * @param start 开始索引
     * @param limit 返回数组长度
     */
    function getArrs(
        uint256[] memory arr,
        uint256 start,
        uint256 limit
    ) private view returns (Project[] memory) {
        // 数组长度赋值
        uint256 length = arr.length;
        // 如果开始的索引加返回的长度超过了数组的长度,则返回的长度等于数组长度减去开始索引
        uint256 _limit = start + limit <= length ? limit : length - start;
        // 返回的项目数组
        Project[] memory _projects = new Project[](_limit);
        // 开始的索引累加变量
        uint256 _index = start;
        // 用修改后的返回长度循环
        for (uint256 i = 0; i < _limit; ++i) {
            // 将项目信息赋值到新数组
            _projects[i] = projectArr[arr[_index] - 1];
            // 索引累加
            _index++;
        }
        // 返回数组
        return _projects;
    }

    /// @dev 返回通过的数组
    function getPassed(uint256 start, uint256 limit)
        public
        view
        returns (Project[] memory)
    {
        return getArrs(passedArr, start, limit);
    }

    /// @dev 返回处理中的数组
    function getPending(uint256 start, uint256 limit)
        public
        view
        returns (Project[] memory)
    {
        return getArrs(pendingArr, start, limit);
    }

    /// @dev 返回驳回的数组
    function getReject(uint256 start, uint256 limit)
        public
        view
        returns (Project[] memory)
    {
        return getArrs(rejectArr, start, limit);
    }

    /// @dev 返回锁定的数组
    function getLocked(uint256 start, uint256 limit)
        public
        view
        returns (Project[] memory)
    {
        return getArrs(lockedArr, start, limit);
    }

    /// @dev 返回挑战中的数组
    function getChallenge(uint256 start, uint256 limit)
        public
        view
        returns (Project[] memory)
    {
        return getArrs(challengeArr, start, limit);
    }

    function projectId(string calldata name)
        public
        view
        override
        returns (uint256)
    {
        uint256 _projectId = namehashToId[keccak256(abi.encodePacked(name))];
        require(_projectId > 0, "project not exist");
        return _projectId;
    }

    function getProject(string calldata name)
        public
        view
        returns (uint256, Project memory)
    {
        uint256 _projectId = projectId(name);
        return (_projectId, getProjectById(_projectId));
    }

    function getProjectById(uint256 _projectId)
        public
        view
        returns (Project memory)
    {
        Project memory _project = projectArr[_projectId - 1];
        return _project;
    }
}