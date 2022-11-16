// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }
}

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuardStatus} from "../structs/ReentrancyGuardStatus.sol";
import {StorageReentrancyGuard} from "../storage/StorageReentrancyGuard.sol";

/// @author Amit Molek
/// @dev Diamond compatible reentrancy guard
contract DiamondReentrancyGuard {
    modifier nonReentrant() {
        StorageReentrancyGuard.DiamondStorage
            storage ds = StorageReentrancyGuard.diamondStorage();

        // On first call, status MUST be NOT_ENTERED
        require(
            ds.status != ReentrancyGuardStatus.ENTERED,
            "LibReentrancyGuard: reentrant call"
        );

        // About to enter the function, set guard.
        ds.status = ReentrancyGuardStatus.ENTERED;
        _;

        // Existed function, reset guard
        ds.status = ReentrancyGuardStatus.NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IDeploymentRefund} from "../../interfaces/IDeploymentRefund.sol";
import {LibDeploymentRefund} from "../../libraries/LibDeploymentRefund.sol";
import {DiamondReentrancyGuard} from "../../access/DiamondReentrancyGuard.sol";

/// @author Amit Molek
/// @dev Please see `IDeploymentRefund` for docs
contract DeploymentRefundFacet is IDeploymentRefund, DiamondReentrancyGuard {
    function calculateDeploymentCostRefund(uint256 ownershipUnits)
        external
        view
        override
        returns (uint256)
    {
        return
            LibDeploymentRefund._calculateDeploymentCostRefund(ownershipUnits);
    }

    function deploymentCostToRefund() external view override returns (uint256) {
        return LibDeploymentRefund._deploymentCostToRefund();
    }

    function deploymentCostPaid() external view override returns (uint256) {
        return LibDeploymentRefund._deploymentCostPaid();
    }

    function refundable() external view override returns (uint256) {
        return LibDeploymentRefund._refundable();
    }

    function withdrawDeploymentRefund() external override nonReentrant {
        LibDeploymentRefund._withdrawDeploymentRefund();
    }

    function initDeploymentCost(uint256 deploymentGasUsed, address deployer_)
        external
        override
    {
        LibDeploymentRefund._initDeploymentCost(deploymentGasUsed, deployer_);
    }

    function deployer() external view override returns (address) {
        return LibDeploymentRefund._deployer();
    }

    /// @return the refund amount withdrawn by the deployer
    function withdrawnByDeployer() external view returns (uint256) {
        return LibDeploymentRefund._withdrawn();
    }

    /// @return true, if the deployer joined the group
    function isDeployerJoined() external view returns (bool) {
        return LibDeploymentRefund._isDeployerJoined();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Deployment refund actions
interface IDeploymentRefund {
    /// @dev Emitted on deployer withdraws deployment refund
    /// @param account the deployer that withdraw
    /// @param amount the refund amount
    event WithdrawnDeploymentRefund(address account, uint256 amount);

    /// @dev Emitted on deployment cost initialization
    /// @param gasUsed gas used in the group contract deployment
    /// @param gasPrice gas cost in the deployment
    /// @param deployer the account that deployed the group
    event InitializedDeploymentCost(
        uint256 gasUsed,
        uint256 gasPrice,
        address deployer
    );

    /// @dev Emitted on deployer joins the group
    /// @param ownershipUnits amount of ownership units acquired
    event DeployerJoined(uint256 ownershipUnits);

    /// @return The refund amount needed to be paid based on `units`.
    /// If the refund was fully funded, this will return 0
    /// If the refund amount is bigger than what is left to be refunded, this will return only
    /// what is left to be refunded. e.g. Need to refund 100 wei and 70 wei was already paid,
    /// if a new member joins and buys 40% ownership he will only need to pay 30 wei (100-70).
    function calculateDeploymentCostRefund(uint256 units)
        external
        view
        returns (uint256);

    /// @return The deployment cost needed to be refunded
    function deploymentCostToRefund() external view returns (uint256);

    /// @return The deployment cost already paid
    function deploymentCostPaid() external view returns (uint256);

    /// @return The refund amount that can be withdrawn by the deployer
    function refundable() external view returns (uint256);

    /// @notice Deployment cost refund withdraw (collected so far)
    /// @dev Refunds the deployer with the collected deployment cost
    /// Emits `WithdrawnDeploymentRefund` event
    function withdrawDeploymentRefund() external;

    /// @return The address of the contract/group deployer
    function deployer() external view returns (address);

    /// @dev Initializes the deployment cost.
    /// SHOULD be called together with the deployment of the contract, because this function uses
    /// `tx.gasprice`. So for the best accuracy initialize the contract and call this function in the same transaction.
    /// @param deploymentGasUsed Gas used to deploy the contract/group
    /// @param deployer_ The address who deployed the contract/group
    function initDeploymentCost(uint256 deploymentGasUsed, address deployer_)
        external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageDeploymentCost} from "../storage/StorageDeploymentCost.sol";
import {LibOwnership} from "./LibOwnership.sol";
import {LibTransfer} from "./LibTransfer.sol";

/// @author Amit Molek
/// @dev Please see `IDeploymentRefund` for docs
library LibDeploymentRefund {
    event WithdrawnDeploymentRefund(address account, uint256 amount);
    event InitializedDeploymentCost(
        uint256 gasUsed,
        uint256 gasPrice,
        address deployer
    );
    event DeployerJoined(uint256 ownershipUnits);

    /// @dev The total refund amount can't exceed the deployment cost, so
    /// if the deployment cost refund based on `ownershipUnits` exceeds the
    /// deployment cost, the refund will be equal to only the delta left (deploymentCost - paidSoFar)
    /// @return The deployment cost refund amount that needs to be paid,
    /// if the member acquires `ownershipUnits` ownership units
    function _calculateDeploymentCostRefund(uint256 ownershipUnits)
        internal
        view
        returns (uint256)
    {
        uint256 totalOwnershipUnits = LibOwnership._totalOwnershipUnits();

        require(
            ownershipUnits <= totalOwnershipUnits,
            "DeploymentRefund: Invalid units"
        );

        uint256 deploymentCost = _deploymentCostToRefund();
        uint256 refundPayment = (deploymentCost * ownershipUnits) /
            totalOwnershipUnits;
        uint256 paidSoFar = _deploymentCostPaid();

        // Can't refund more than the deployment cost
        return
            refundPayment + paidSoFar > deploymentCost
                ? deploymentCost - paidSoFar
                : refundPayment;
    }

    function _payDeploymentCost(uint256 refundAmount) internal {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        ds.paid += refundAmount;
    }

    function _initDeploymentCost(uint256 deploymentGasUsed, address deployer)
        internal
    {
        require(
            deploymentGasUsed > 0,
            "DeploymentRefund: Deployment gas can't be 0"
        );
        require(
            deployer != address(0),
            "DeploymentRefund: Invalid deployer address"
        );

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        require(
            ds.deploymentCostToRefund == 0,
            "DeploymentRefund: Deployment cost already initialized"
        );

        uint256 gasPrice = tx.gasprice;
        ds.deploymentCostToRefund = deploymentGasUsed * gasPrice;
        ds.deployer = deployer;

        emit InitializedDeploymentCost(deploymentGasUsed, gasPrice, deployer);
    }

    function _deployerJoin(address member, uint256 deployerOwnershipUnits)
        internal
    {
        require(
            !_isDeployerJoined(),
            "DeploymentRefund: Deployer already joined"
        );

        require(
            _isDeploymentCostSet(),
            "DeploymentRefund: Must initialized deployment cost first"
        );

        require(member == _deployer(), "DeploymentRefund: Not the deployer");

        require(
            deployerOwnershipUnits > 0,
            "DeploymentRefund: Invalid ownership units"
        );

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        uint256 deployerDeploymentCost = _calculateDeploymentCostRefund(
            deployerOwnershipUnits
        );

        // The deployer already paid
        ds.paid += deployerDeploymentCost;
        // The deployer can't withdraw his payment
        ds.withdrawn += deployerDeploymentCost;
        ds.isDeployerJoined = true;

        emit DeployerJoined(deployerOwnershipUnits);
    }

    function _isDeploymentCostSet() internal view returns (bool) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deploymentCostToRefund > 0;
    }

    function _deploymentCostToRefund() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deploymentCostToRefund;
    }

    function _deploymentCostPaid() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.paid;
    }

    function _withdrawn() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.withdrawn;
    }

    function _deployer() internal view returns (address) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deployer;
    }

    function _refundable() internal view returns (uint256) {
        return _deploymentCostPaid() - _withdrawn();
    }

    function _isDeployerJoined() internal view returns (bool) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.isDeployerJoined;
    }

    function _withdrawDeploymentRefund() internal {
        address deployer = _deployer();

        // Only the deployer can withdraw the deployment cost refund
        require(
            msg.sender == deployer,
            "DeploymentRefund: caller not the deployer"
        );

        uint256 refundAmount = _refundable();
        require(refundAmount > 0, "DeploymentRefund: nothing to withdraw");

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();
        ds.withdrawn += refundAmount;

        emit WithdrawnDeploymentRefund(deployer, refundAmount);

        LibTransfer._untrustedSendValue(payable(deployer), refundAmount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageOwnershipUnits} from "../storage/StorageOwnershipUnits.sol";
import {LibState} from "../libraries/LibState.sol";
import {StateEnum} from "../structs/StateEnum.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

/// @author Amit Molek
/// @dev Please see `IOwnership` for docs
library LibOwnership {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// @notice Adds `account` as an onwer
    /// @dev For internal use only
    /// You must call this function with join's deposit value attached
    function _addOwner(address account, uint256 ownershipUnits) internal {
        // Verify that the group is still open
        LibState._stateGuard(StateEnum.OPEN);

        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        // Update the member's ownership units
        require(
            ds.ownershipUnits.set(account, ownershipUnits),
            "Ownership: existing member"
        );

        // Verify ownership deposit is valid
        _depositGuard(ownershipUnits);

        // Update the total ownership units owned
        ds.totalOwnedOwnershipUnits += ownershipUnits;
    }

    /// @notice `account` acquires more ownership units
    /// @dev You must call this with value attached
    function _acquireMoreOwnershipUnits(address account, uint256 ownershipUnits)
        internal
    {
        // Verify that the group is still open
        LibState._stateGuard(StateEnum.OPEN);

        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        // Only existing member can obtain more units
        require(ds.ownershipUnits.contains(account), "Ownership: not a member");

        // Verify ownership deposit is valid
        _depositGuard(ownershipUnits);

        uint256 currentOwnerUnits = ds.ownershipUnits.get(account);
        ds.ownershipUnits.set(account, currentOwnerUnits + ownershipUnits);
        ds.totalOwnedOwnershipUnits += ownershipUnits;
    }

    /// @dev Guard that verifies that the ownership deposit is valid
    /// Can revert:
    ///     - "Ownership: deposit not divisible by smallest unit"
    ///     - "Ownership: deposit exceeds total ownership units"
    ///     - "Ownership: deposit must be bigger than 0"
    function _depositGuard(uint256 ownershipUnits) internal {
        uint256 value = msg.value;
        uint256 smallestUnit = _smallestUnit();

        require(
            value >= ownershipUnits,
            "Ownership: mismatch between units and deposit amount"
        );

        require(ownershipUnits > 0, "Ownership: deposit must be bigger than 0");

        require(
            ownershipUnits % smallestUnit == 0,
            "Ownership: deposit not divisible by smallest unit"
        );

        require(
            ownershipUnits + _totalOwnedOwnershipUnits() <=
                _totalOwnershipUnits(),
            "Ownership: deposit exceeds total ownership units"
        );
    }

    /// @notice Renounce ownership
    /// @dev The caller renounce his ownership
    /// @return refund the amount to refund to the caller
    function _renounceOwnership() internal returns (uint256 refund) {
        // Verify that the group is still open
        require(
            LibState._state() == StateEnum.OPEN,
            "Ownership: group formed or uninitialized"
        );

        // Verify that the caller is a member
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        require(
            ds.ownershipUnits.contains(msg.sender),
            "Ownership: not an owner"
        );

        // Update the member ownership units and the total units owned
        refund = ds.ownershipUnits.get(msg.sender);
        ds.totalOwnedOwnershipUnits -= refund;
        ds.ownershipUnits.remove(msg.sender);
    }

    function _ownershipUnits(address member) internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.get(member);
    }

    function _totalOwnershipUnits() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.totalOwnershipUnits;
    }

    function _smallestUnit() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.smallestOwnershipUnit;
    }

    function _totalOwnedOwnershipUnits() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.totalOwnedOwnershipUnits;
    }

    function _isCompletelyOwned() internal view returns (bool) {
        return _totalOwnedOwnershipUnits() == _totalOwnershipUnits();
    }

    function _isMember(address account) internal view returns (bool) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.contains(account);
    }

    function _memberAt(uint256 index)
        internal
        view
        returns (address member, uint256 units)
    {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        (member, units) = ds.ownershipUnits.at(index);
    }

    function _memberCount() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.length();
    }

    function _members() internal view returns (address[] memory members) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        uint256 length = ds.ownershipUnits.length();
        members = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            (members[i], ) = ds.ownershipUnits.at(i);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageState} from "../storage/StorageState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Contract/Group state
library LibState {
    string public constant INVALID_STATE_ERR = "State: Invalid state";

    event StateChanged(StateEnum from, StateEnum to);

    /// @dev Changes the state of the contract/group
    /// Can revert:
    ///     - "State: same state": When changing the state to the same one
    /// Emits `StateChanged` event
    /// @param state the new state
    function _changeState(StateEnum state) internal {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();
        require(ds.state != state, "State: same state");

        emit StateChanged(ds.state, state);

        ds.state = state;
    }

    function _state() internal view returns (StateEnum) {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();

        return ds.state;
    }

    /// @dev reverts if `state` is not the current contract state
    function _stateGuard(StateEnum state) internal view {
        require(_state() == state, INVALID_STATE_ERR);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

/// @author Amit Molek
/// @dev Transfer helpers
library LibTransfer {
    /// @dev Sends `value` in wei to `recipient`
    /// Reverts on failure
    function _untrustedSendValue(address payable recipient, uint256 value)
        internal
    {
        Address.sendValue(recipient, value);
    }

    /// @dev Performs a function call
    function _untrustedCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool successful, bytes memory returnData) {
        require(
            address(this).balance >= value,
            "Transfer: insufficient balance"
        );

        (successful, returnData) = to.call{value: value}(data);
    }

    /// @dev Extracts and bubbles the revert reason if exist, otherwise reverts with a hard-coded reason.
    function _revertWithReason(bytes memory returnData) internal pure {
        if (returnData.length == 0) {
            revert("Transfer: call reverted without a reason");
        }

        // Bubble the revert reason
        assembly {
            let returnDataSize := mload(returnData)
            revert(add(32, returnData), returnDataSize)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for deployment cost split mechanism
library StorageDeploymentCost {
    struct DiamondStorage {
        /// @dev The account that deployed the contract
        address deployer;
        /// @dev Use to indicate that the deployer has joined the group
        /// (for deployment cost refund calculation)
        bool isDeployerJoined;
        /// @dev Contract deployment cost to refund (minus what the deployer already paid)
        uint256 deploymentCostToRefund;
        /// @dev Deployment cost refund paid so far
        uint256 paid;
        /// @dev Refund amount withdrawn by the deployer
        uint256 withdrawn;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.DeploymentCost");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for ownership units of members
library StorageOwnershipUnits {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct DiamondStorage {
        /// @dev Smallest ownership unit
        uint256 smallestOwnershipUnit;
        /// @dev Total ownership units
        uint256 totalOwnershipUnits;
        /// @dev Amount of ownership units that are owned by members.
        /// join -> adding | leave -> subtracting
        /// This is used in the join process to know when the group is fully funded
        uint256 totalOwnedOwnershipUnits;
        /// @dev Maps between member and their ownership units
        EnumerableMap.AddressToUintMap ownershipUnits;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.OwnershipUnits");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(
        uint256 smallestOwnershipUnit,
        uint256 totalOwnershipUnits
    ) internal {
        require(
            smallestOwnershipUnit > 0,
            "Storage: smallest ownership unit must be bigger than 0"
        );
        require(
            totalOwnershipUnits % smallestOwnershipUnit == 0,
            "Storage: total units not divisible by smallest unit"
        );

        DiamondStorage storage ds = diamondStorage();

        ds.smallestOwnershipUnit = smallestOwnershipUnit;
        ds.totalOwnershipUnits = totalOwnershipUnits;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuardStatus} from "../structs/ReentrancyGuardStatus.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for reentrancy guard
library StorageReentrancyGuard {
    struct DiamondStorage {
        /// @dev
        ReentrancyGuardStatus status;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.ReentrancyGuard");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for group state
library StorageState {
    struct DiamondStorage {
        /// @dev State of the group
        StateEnum state;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.State");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek

/// @dev Status enum for DiamondReentrancyGuard
enum ReentrancyGuardStatus {
    NOT_ENTERED,
    ENTERED
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek

/// @dev State of the contract/group
enum StateEnum {
    UNINITIALIZED,
    OPEN,
    FORMED
}