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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

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
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
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
     * @dev Tries to returns the value associated with `key`. O(1).
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
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
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

    // UintToUintMap

    struct UintToUintMap {
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
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
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
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
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
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
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
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IInterchainGasPaymaster} from "../interfaces/IInterchainGasPaymaster.sol";
import {ISpecifiesInterchainSecurityModule, IInterchainSecurityModule} from "../interfaces/IInterchainSecurityModule.sol";
import {IMailbox} from "../interfaces/IMailbox.sol";

// ============ External Imports ============
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract HyperlaneConnectionClient is
    OwnableUpgradeable,
    ISpecifiesInterchainSecurityModule
{
    // ============ Mutable Storage ============

    IMailbox public mailbox;
    // Interchain Gas Paymaster contract. The relayer associated with this contract
    // must be willing to relay messages dispatched from the current Mailbox contract,
    // otherwise payments made to the paymaster will not result in relayed messages.
    IInterchainGasPaymaster public interchainGasPaymaster;

    IInterchainSecurityModule public interchainSecurityModule;

    uint256[48] private __GAP; // gap for upgrade safety

    // ============ Events ============
    /**
     * @notice Emitted when a new mailbox is set.
     * @param mailbox The address of the mailbox contract
     */
    event MailboxSet(address indexed mailbox);

    /**
     * @notice Emitted when a new Interchain Gas Paymaster is set.
     * @param interchainGasPaymaster The address of the Interchain Gas Paymaster.
     */
    event InterchainGasPaymasterSet(address indexed interchainGasPaymaster);

    event InterchainSecurityModuleSet(address indexed module);

    // ============ Modifiers ============

    /**
     * @notice Only accept messages from an Hyperlane Mailbox contract
     */
    modifier onlyMailbox() {
        require(msg.sender == address(mailbox), "!mailbox");
        _;
    }

    /**
     * @notice Only accept addresses that at least have contract code
     */
    modifier onlyContract(address _contract) {
        require(Address.isContract(_contract), "!contract");
        _;
    }

    // ======== Initializer =========

    function __HyperlaneConnectionClient_initialize(address _mailbox)
        internal
        onlyInitializing
    {
        _setMailbox(_mailbox);
        __Ownable_init();
    }

    function __HyperlaneConnectionClient_initialize(
        address _mailbox,
        address _interchainGasPaymaster
    ) internal onlyInitializing {
        _setInterchainGasPaymaster(_interchainGasPaymaster);
        __HyperlaneConnectionClient_initialize(_mailbox);
    }

    function __HyperlaneConnectionClient_initialize(
        address _mailbox,
        address _interchainGasPaymaster,
        address _interchainSecurityModule
    ) internal onlyInitializing {
        _setInterchainSecurityModule(_interchainSecurityModule);
        __HyperlaneConnectionClient_initialize(
            _mailbox,
            _interchainGasPaymaster
        );
    }

    // ============ External functions ============

    /**
     * @notice Sets the address of the application's Mailbox.
     * @param _mailbox The address of the Mailbox contract.
     */
    function setMailbox(address _mailbox) external virtual onlyOwner {
        _setMailbox(_mailbox);
    }

    /**
     * @notice Sets the address of the application's InterchainGasPaymaster.
     * @param _interchainGasPaymaster The address of the InterchainGasPaymaster contract.
     */
    function setInterchainGasPaymaster(address _interchainGasPaymaster)
        external
        virtual
        onlyOwner
    {
        _setInterchainGasPaymaster(_interchainGasPaymaster);
    }

    function setInterchainSecurityModule(address _module)
        external
        virtual
        onlyOwner
    {
        _setInterchainSecurityModule(_module);
    }

    // ============ Internal functions ============

    /**
     * @notice Sets the address of the application's InterchainGasPaymaster.
     * @param _interchainGasPaymaster The address of the InterchainGasPaymaster contract.
     */
    function _setInterchainGasPaymaster(address _interchainGasPaymaster)
        internal
        onlyContract(_interchainGasPaymaster)
    {
        interchainGasPaymaster = IInterchainGasPaymaster(
            _interchainGasPaymaster
        );
        emit InterchainGasPaymasterSet(_interchainGasPaymaster);
    }

    /**
     * @notice Modify the contract the Application uses to validate Mailbox contracts
     * @param _mailbox The address of the mailbox contract
     */
    function _setMailbox(address _mailbox) internal onlyContract(_mailbox) {
        mailbox = IMailbox(_mailbox);
        emit MailboxSet(_mailbox);
    }

    function _setInterchainSecurityModule(address _module)
        internal
        onlyContract(_module)
    {
        interchainSecurityModule = IInterchainSecurityModule(_module);
        emit InterchainSecurityModuleSet(_module);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {HyperlaneConnectionClient} from "./HyperlaneConnectionClient.sol";
import {IInterchainGasPaymaster} from "../interfaces/IInterchainGasPaymaster.sol";
import {IMessageRecipient} from "../interfaces/IMessageRecipient.sol";
import {IMailbox} from "../interfaces/IMailbox.sol";
import {EnumerableMapExtended} from "./libs/EnumerableMapExtended.sol";

abstract contract Router is HyperlaneConnectionClient, IMessageRecipient {
    using EnumerableMapExtended for EnumerableMapExtended.UintToBytes32Map;

    string constant NO_ROUTER_ENROLLED_REVERT_MESSAGE =
        "No router enrolled for domain. Did you specify the right domain ID?";

    // ============ Mutable Storage ============
    EnumerableMapExtended.UintToBytes32Map internal _routers;
    uint256[49] private __GAP; // gap for upgrade safety

    // ============ Events ============

    /**
     * @notice Emitted when a router is set.
     * @param domain The domain of the new router
     * @param router The address of the new router
     */
    event RemoteRouterEnrolled(uint32 indexed domain, bytes32 indexed router);

    // ============ Modifiers ============
    /**
     * @notice Only accept messages from a remote Router contract
     * @param _origin The domain the message is coming from
     * @param _router The address the message is coming from
     */
    modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
        require(
            _isRemoteRouter(_origin, _router),
            NO_ROUTER_ENROLLED_REVERT_MESSAGE
        );
        _;
    }

    // ======== Initializer =========
    function __Router_initialize(address _mailbox) internal onlyInitializing {
        __HyperlaneConnectionClient_initialize(_mailbox);
    }

    function __Router_initialize(
        address _mailbox,
        address _interchainGasPaymaster
    ) internal onlyInitializing {
        __HyperlaneConnectionClient_initialize(
            _mailbox,
            _interchainGasPaymaster
        );
    }

    function __Router_initialize(
        address _mailbox,
        address _interchainGasPaymaster,
        address _interchainSecurityModule
    ) internal onlyInitializing {
        __HyperlaneConnectionClient_initialize(
            _mailbox,
            _interchainGasPaymaster,
            _interchainSecurityModule
        );
    }

    // ============ External functions ============
    function domains() external view returns (uint32[] memory) {
        bytes32[] storage rawKeys = _routers.keys();
        uint32[] memory keys = new uint32[](rawKeys.length);
        for (uint256 i = 0; i < rawKeys.length; i++) {
            keys[i] = uint32(uint256(rawKeys[i]));
        }
        return keys;
    }

    function routers(uint32 _domain) public view returns (bytes32) {
        if (_routers.contains(_domain)) {
            return _routers.get(_domain);
        } else {
            return bytes32(0); // for backwards compatibility with storage mapping
        }
    }

    /**
     * @notice Register the address of a Router contract for the same Application on a remote chain
     * @param _domain The domain of the remote Application Router
     * @param _router The address of the remote Application Router
     */
    function enrollRemoteRouter(uint32 _domain, bytes32 _router)
        external
        virtual
        onlyOwner
    {
        _enrollRemoteRouter(_domain, _router);
    }

    /**
     * @notice Batch version of `enrollRemoteRouter`
     * @param _domains The domaisn of the remote Application Routers
     * @param _addresses The addresses of the remote Application Routers
     */
    function enrollRemoteRouters(
        uint32[] calldata _domains,
        bytes32[] calldata _addresses
    ) external virtual onlyOwner {
        require(_domains.length == _addresses.length, "!length");
        for (uint256 i = 0; i < _domains.length; i += 1) {
            _enrollRemoteRouter(_domains[i], _addresses[i]);
        }
    }

    /**
     * @notice Handles an incoming message
     * @param _origin The origin domain
     * @param _sender The sender address
     * @param _message The message
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external virtual override onlyMailbox onlyRemoteRouter(_origin, _sender) {
        // TODO: callbacks on success/failure
        _handle(_origin, _sender, _message);
    }

    // ============ Virtual functions ============
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) internal virtual;

    // ============ Internal functions ============

    /**
     * @notice Set the router for a given domain
     * @param _domain The domain
     * @param _address The new router
     */
    function _enrollRemoteRouter(uint32 _domain, bytes32 _address) internal {
        _routers.set(_domain, _address);
        emit RemoteRouterEnrolled(_domain, _address);
    }

    /**
     * @notice Return true if the given domain / router is the address of a remote Application Router
     * @param _domain The domain of the potential remote Application Router
     * @param _address The address of the potential remote Application Router
     */
    function _isRemoteRouter(uint32 _domain, bytes32 _address)
        internal
        view
        returns (bool)
    {
        return routers(_domain) == _address;
    }

    /**
     * @notice Assert that the given domain has a Application Router registered and return its address
     * @param _domain The domain of the chain for which to get the Application Router
     * @return _router The address of the remote Application Router on _domain
     */
    function _mustHaveRemoteRouter(uint32 _domain)
        internal
        view
        returns (bytes32 _router)
    {
        _router = routers(_domain);
        require(_router != bytes32(0), NO_ROUTER_ENROLLED_REVERT_MESSAGE);
    }

    /**
     * @notice Dispatches a message to an enrolled router via the local router's Mailbox
     * and pays for it to be relayed to the destination.
     * @dev Reverts if there is no enrolled router for _destinationDomain.
     * @param _destinationDomain The domain of the chain to which to send the message.
     * @param _messageBody Raw bytes content of message.
     * @param _gasAmount The amount of destination gas for the message that is requested via the InterchainGasPaymaster.
     * @param _gasPayment The amount of native tokens to pay for the message to be relayed.
     * @param _gasPaymentRefundAddress The address to refund any gas overpayment to.
     */
    function _dispatchWithGas(
        uint32 _destinationDomain,
        bytes memory _messageBody,
        uint256 _gasAmount,
        uint256 _gasPayment,
        address _gasPaymentRefundAddress
    ) internal returns (bytes32 _messageId) {
        _messageId = _dispatch(_destinationDomain, _messageBody);
        // Call the IGP even if the gas payment is zero. This is to support on-chain
        // fee quoting in IGPs, which should always revert if gas payment is insufficient.
        interchainGasPaymaster.payForGas{value: _gasPayment}(
            _messageId,
            _destinationDomain,
            _gasAmount,
            _gasPaymentRefundAddress
        );
    }

    /**
     * @notice Dispatches a message to an enrolled router via the provided Mailbox.
     * @dev Does not pay interchain gas.
     * @dev Reverts if there is no enrolled router for _destinationDomain.
     * @param _destinationDomain The domain of the chain to which to send the message.
     * @param _messageBody Raw bytes content of message.
     */
    function _dispatch(uint32 _destinationDomain, bytes memory _messageBody)
        internal
        virtual
        returns (bytes32)
    {
        // Ensure that destination chain has an enrolled router.
        bytes32 _router = _mustHaveRemoteRouter(_destinationDomain);
        return mailbox.dispatch(_destinationDomain, _router, _messageBody);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ External Imports ============
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// extends EnumerableMap with uint256 => bytes32 type
// modelled after https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/structs/EnumerableMap.sol
library EnumerableMapExtended {
    using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;

    struct UintToBytes32Map {
        EnumerableMap.Bytes32ToBytes32Map _inner;
    }

    // ============ Library Functions ============
    function keys(UintToBytes32Map storage map)
        internal
        view
        returns (bytes32[] storage)
    {
        return map._inner._keys._inner._values;
    }

    function set(
        UintToBytes32Map storage map,
        uint256 key,
        bytes32 value
    ) internal {
        map._inner.set(bytes32(key), value);
    }

    function get(UintToBytes32Map storage map, uint256 key)
        internal
        view
        returns (bytes32)
    {
        return map._inner.get(bytes32(key));
    }

    function remove(UintToBytes32Map storage map, uint256 key)
        internal
        returns (bool)
    {
        return map._inner.remove(bytes32(key));
    }

    function contains(UintToBytes32Map storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return map._inner.contains(bytes32(key));
    }

    function length(UintToBytes32Map storage map)
        internal
        view
        returns (uint256)
    {
        return map._inner.length();
    }

    function at(UintToBytes32Map storage map, uint256 index)
        internal
        view
        returns (uint256, bytes32)
    {
        (bytes32 key, bytes32 value) = map._inner.at(index);
        return (uint256(key), value);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gas,
        address _refundAddress
    ) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IInterchainSecurityModule {
    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8);

    /**
     * @notice Defines a security model responsible for verifying interchain
     * messages based on the provided metadata.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures)
     * @param _message Hyperlane encoded interchain message
     * @return True if the message was verified
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        external
        returns (bool);
}

interface ISpecifiesInterchainSecurityModule {
    function interchainSecurityModule()
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "./IInterchainSecurityModule.sol";

interface IMailbox {
    function localDomain() external view returns (uint32);

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message)
        external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);

    function recipientIsm(address _recipient)
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hyperlane/Router.sol";

// Hyperchat is a contract that leverages the Hyperlane Messaging API to relay chat messages to users of any chain
contract Hyperchat is Router {

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                EVENTS/ERRORS
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    event ConversationCreated(bytes32 indexed conversationID, bytes32 indexed initiator, bytes indexed name);
    event AdminApprovalAdded(bytes32 indexed conversationID, bytes32 indexed admin, bytes32 indexed candidate);
    event AdminApprovalRemoved(bytes32 indexed conversationID, bytes32 indexed admin, bytes32 indexed candidate);
    event AdminAdded(bytes32 indexed conversationID, bytes32 indexed admin, bytes32 indexed candidate);
    event AdminRemoved(bytes32 indexed conversationID, bytes32 indexed admin, bytes32 indexed candidate);
    event ParticipantAdded(bytes32 indexed conversationID, bytes32 indexed admin, bytes32 indexed participant);
    event ParticipantRemoved(bytes32 indexed conversationID, bytes32 indexed admin, bytes32 indexed participant);
    event GeneralMessage(bytes32 indexed conversationID, bytes32 indexed sender, bytes indexed message);
    event MessageSent(bytes32 indexed conversationID, bytes32 indexed sender, bytes indexed message);
    event MessageReceived(bytes32 indexed conversationID, bytes32 indexed sender, bytes indexed message);

    error InvalidConversation();
    error InvalidParticipant();
    error InvalidApprovals();
    error InvalidMessage();
    error InvalidIndex();
    error InvalidAdmin();
    error InvalidType();

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                STORAGE
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    // Hyperlane data structures
    uint32 private immutable HYPERLANE_DOMAIN_IDENTIFIER;

    // Message Types
    enum MessageType {
        InitiateConversation,
        AddAdminApproval,
        RemoveAdminApproval,
        AddAdmin,
        RemoveAdmin,
        AddParticipant,
        RemoveParticipant,
        GeneralMessage
    }

    // Message data struct
    struct Message {
        uint256 timestamp;
        bytes32 sender;
        bytes32 conversationID;
        bytes32[] participants; // Participant addresses to be utilized in management functions
        uint32[] domainIDs; // Hyperlane domainIDs to add/remove
        bytes message; // Chat message
        MessageType msgType;
    }
    // conversationID => messageNum => Message data struct
    mapping(bytes32 => mapping(uint256 => Message)) private _messages;

    struct Conversation {
        uint256 messageCount;
        bytes32 conversationID;
        uint32[] domainIDs;
        bytes32[] admins;
        bytes name;
        mapping(bytes32 => bool) isAdmin;
        mapping(bytes32 => mapping(bytes32 => bool)) adminApprovals;
        mapping(bytes32 => bool) allowlist;
    }
    // conversationID => Conversation data struct
    mapping(bytes32 => Conversation) private _conversations;
    uint256 public conversationCount;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                MODIFIERS
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    modifier onlyMember(bytes32 _conversationID) {
        if (_conversations[_conversationID].conversationID == 0) {
            revert InvalidConversation();
        }
        if (!_conversations[_conversationID].allowlist[addressToBytes32(msg.sender)]) {
            revert InvalidParticipant();
        }
        _;
    }

    modifier onlyAdmin(bytes32 _conversationID) {
        if (_conversations[_conversationID].conversationID == 0) {
            revert InvalidConversation();
        }
        if (!_conversations[_conversationID].isAdmin[addressToBytes32(msg.sender)]) {
            revert InvalidAdmin();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    constructor(
        uint32 _hyperlaneDomainID,
        address _mailbox,
        address _hyperlaneIGP
    ) payable initializer {        
        // Set to Hyperlane Domain Identifier of local chain
        HYPERLANE_DOMAIN_IDENTIFIER = _hyperlaneDomainID;

        __Router_initialize(_mailbox, _hyperlaneIGP);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                LIBRARY
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    // Converts string to bytes
    function stringToBytes(string memory _string) public pure returns (bytes memory) {
        return bytes(_string);
    }

    // Converts bytes to string
    function bytesToString(bytes memory _message) public pure returns (string memory) {
        return string(_message);
    }

    // Converts address to bytes32 for Hyperlane
    function addressToBytes32(address _address) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    // Retrieves messages in hopefully a more RPC-efficient manner
    function retrieveMessages(
        bytes32 _conversationID,
        uint256 initialMessage,
        uint256 finalMessage
    ) public view returns (Message[] memory) {
        // Ensure finalMessage index isn't below initialMessage index
        require(initialMessage <= finalMessage, "Hyperchat::retrieveMessages::INVALID_RANGE");
        // Block index > msgCount - 1
        require(initialMessage <= _conversations[_conversationID].messageCount - 1, "Hyperchat::retrieveMessages::OUT_OF_BOUNDS");
        require(finalMessage <= _conversations[_conversationID].messageCount - 1, "Hyperchat::retrieveMessages::OUT_OF_BOUNDS");

        // Determine messages array size
        uint256 range = finalMessage - initialMessage + 1;

        // Create messages bytes[] array to store retrieved messages
        Message[] memory messages = new Message[](range);
        
        // Iterate across range and retrieve each message
        for (uint256 i = initialMessage; i <= finalMessage;) {
            messages[i - initialMessage] = _messages[_conversationID][i];
            // Cant overflow as we confirm range bounds before loop
            unchecked { ++i; }
        }

        return messages;
    }

    // Retrieves conversation data
    function retrieveConversation(bytes32 _conversationID) public view returns (uint256, bytes32, bytes memory) {
        uint256 messageCount = _conversations[_conversationID].messageCount;
        bytes32 conversationID = _conversations[_conversationID].conversationID;
        bytes memory name = _conversations[_conversationID].name;
        
        return (messageCount, conversationID, name);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    // Removes admin at admins array _index
    function _removeFromAdminArray(bytes32 _conversationID, uint256 _index) internal {
        // Revert if index out of bounds
        uint256 length = _conversations[_conversationID].admins.length;
        if (_index >= length) {
            revert InvalidIndex();
        }

        for (uint i = _index; i < length - 1;) {
            _conversations[_conversationID].admins[i] = _conversations[_conversationID].admins[i + 1];
            // Shouldn't overflow
            unchecked { ++i; }
        }

        _conversations[_conversationID].admins.pop();
    }

    // Process a received message
    function _processMessage(Message memory _message) internal {
        // Retrieve conversationID
        bytes32 conversationID = _message.conversationID;
        // Retrieve sender
        bytes32 sender = _message.sender;
        // Retrieve candidate address if one exists (GeneralMessage doesn't include one)
        bytes32 candidate;
        if (_message.participants.length > 0) {
            candidate = _message.participants[0];
        }
        // Retrieve MessageType
        MessageType msgType = _message.msgType;

        // Process message logic based off MessageType
        if (msgType == MessageType.InitiateConversation) {
            // Process internal InitiateConversation logic (too much to implement here)
            _processInitiateConversation(_message);
        }
        else if (msgType == MessageType.AddAdminApproval) {
            // Set admin approval
            _conversations[conversationID].adminApprovals[sender][candidate] = true;

            emit AdminApprovalAdded(conversationID, sender, candidate);
        }
        else if (msgType == MessageType.RemoveAdminApproval) {
            // Remove admin approval
            delete _conversations[conversationID].adminApprovals[sender][candidate];

            emit AdminApprovalRemoved(conversationID, sender, candidate);
        }
        else if (msgType == MessageType.AddAdmin) {
            // Populate all admin-related fields and give self-approval
            _conversations[conversationID].admins.push(candidate);
            _conversations[conversationID].isAdmin[candidate] = true;
            _conversations[conversationID].adminApprovals[candidate][candidate] = true;

            emit AdminAdded(conversationID, sender, candidate);
        }
        else if (msgType == MessageType.RemoveAdmin) {
            // Retrieve admin count
            uint256 adminCount = _conversations[conversationID].admins.length;
            // Search through admins array for address and remove it
            for (uint i; i < adminCount;) {
                if (_conversations[conversationID].admins[i] == candidate) {
                    // Internal admin array removal logic
                    _removeFromAdminArray(conversationID, i);
                    break;
                }

                // Shouldn't overflow
                unchecked { ++i; }
            }

            // Remove admin data structures
            delete _conversations[conversationID].isAdmin[candidate];
            delete _conversations[conversationID].adminApprovals[candidate][candidate];

            emit AdminRemoved(conversationID, sender, candidate);
        }
        else if (msgType == MessageType.AddParticipant) {
            // Add to conversation allowed allowlist
            _conversations[conversationID].allowlist[candidate] = true;

            emit ParticipantAdded(conversationID, sender, candidate);
        }
        else if (msgType == MessageType.RemoveParticipant) {
            // Remove from conversation allowed allowlist
            delete _conversations[conversationID].allowlist[candidate];

            emit ParticipantRemoved(conversationID, sender, candidate);
        }
        else if (msgType == MessageType.GeneralMessage) {
            // No logic for general messages beyond being stored in _handle()'s logic
            emit GeneralMessage(conversationID, sender, _message.message);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                CONVERSATION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////////
                INITIATE CONVERSATION
    //////////////////////////////////////////////////////////////////////////////*/

    // Initiate a conversation
    function initiateConversation(
        uint32[] memory _domainIDs,
        bytes32[] memory _participants,
        bytes memory _seed,
        bytes memory _name
    ) public payable returns (bytes32 conversationID) {
        // Require msg.value == 10000000 gwei for current InterchainGasPaymaster integration until on-chain gas estimation is implemented
        require(msg.value >= 10000000 gwei, "Not enough gas for Hyperlane InterchainGasPaymaster");

        // Calculate conversationID
        // Extremely packed to prevent any chance of MEV abuse or collision
        conversationID = bytes32(keccak256(abi.encodePacked(
            msg.sender,
            address(this),
            HYPERLANE_DOMAIN_IDENTIFIER,
            blockhash(1),
            block.number,
            block.difficulty,
            block.timestamp,
            block.chainid,
            block.coinbase,
            conversationCount,
            _seed,
            _name
        )));

        if (_conversations[conversationID].conversationID == conversationID) {
            revert InvalidConversation();
        }

        // Convert msg.sender address
        bytes32 admin = addressToBytes32(msg.sender);

        // Count all participants that aren't the sender
        uint participantCount;
        for (uint i; i < _participants.length;) {
            if (_participants[i] != admin) {
                participantCount += 1;
            }
            // Shouldn't overflow
            unchecked { ++i; }
        }
        // Increment once for admin
        participantCount += 1;

        // Count all domainIDs that aren't the current one
        uint domainCount;
        for (uint i; i < _domainIDs.length;) {
            if (_domainIDs[i] != HYPERLANE_DOMAIN_IDENTIFIER) {
                domainCount += 1;
            }
            // Shouldn't overflow
            unchecked { ++i; }
        }
        // Increment once for current domainID
        domainCount += 1;

        // Prep InitiateConversation Message to duplicate action on other instances
        Message memory message;
        message.timestamp = block.timestamp;
        message.sender = admin;
        message.participants = new bytes32[](participantCount);
        message.domainIDs = new uint32[](domainCount);
        
        
        // Initialize Conversation
        _conversations[conversationID].conversationID = message.conversationID = conversationID;
        conversationCount += 1;
        
        // Set initializer as conversation admin
        _conversations[conversationID].admins.push(admin); // Add to conversation admin array
        _conversations[conversationID].isAdmin[admin] = true; // Set admin status mapping
        _conversations[conversationID].adminApprovals[admin][admin] = true; // Set self-approval for admin status
        
        // Process current Hyperlane domainID
        _conversations[conversationID].domainIDs.push(HYPERLANE_DOMAIN_IDENTIFIER);
        message.domainIDs[0] = HYPERLANE_DOMAIN_IDENTIFIER;

        // Process user-supplied Hyperlane domainIDs
        uint offset;
        for (uint i = 1; i <= _domainIDs.length;) {
            // Skip the domainID for this chain if supplied as that was already added
            if (_domainIDs[i - 1] == HYPERLANE_DOMAIN_IDENTIFIER) {
                // Shouldn't overflow
                unchecked { ++i; ++offset; }
                continue;
            }
            // Save the domain data
            _conversations[conversationID].domainIDs.push(_domainIDs[i - 1]);
            message.domainIDs[i - offset] = _domainIDs[i - 1];
            // Shouldn't overflow
            unchecked { ++i; }
        }

        // Process initializer address
        _conversations[conversationID].allowlist[admin] = true;
        message.participants[0] = admin;
        
        // Process participant addresses
        offset = 0;
        for (uint i = 1; i <= _participants.length;) {
            // Skip sender's address as that was already added
            if (_participants[i - 1] == admin) {
                unchecked { ++i; ++offset; }
                continue;
            }
            _conversations[conversationID].allowlist[_participants[i - 1]] = true;
            message.participants[i - offset] = _participants[i - 1];
            // Shouldn't overflow
            unchecked { ++i; }
        }
        
        // Set conversation name
        if (_name.length > 0) {
            _conversations[conversationID].name = message.message = _name;
        } else {
            _conversations[conversationID].name = message.message = bytes.concat("Hyperlane: ", admin, " initiated ", conversationID, "!");
        }

        // Set message type
        message.msgType = MessageType.InitiateConversation;

        emit ConversationCreated(conversationID, admin, _name);
        
        _sendMessage(conversationID, abi.encode(message));
        
        return conversationID;
    }

    // Internal InitiateConversation Message type processing logic
    function _processInitiateConversation(Message memory _message) internal {
        // Retrieve conversationID
        bytes32 conversationID = _message.conversationID;
        // Retrieve sender address
        bytes32 sender = _message.sender;
        
        // Revert if conversation already exists
        if (_conversations[conversationID].conversationID != bytes32(0)) {
            revert InvalidConversation();
        }

        // Initialize conversation with conversationID
        _conversations[conversationID].conversationID = conversationID;
        conversationCount += 1;

        // Set initializer as conversation admin
        _conversations[conversationID].admins.push(sender); // Add to conversation admin array
        _conversations[conversationID].isAdmin[sender] = true; // Set admin status mapping
        _conversations[conversationID].adminApprovals[sender][sender] = true; // Set self-approval for admin status

        // Process Hyperlane domainIDs
        for (uint i; i < _message.domainIDs.length;) {
            _conversations[conversationID].domainIDs.push(_message.domainIDs[i]);
            // Shouldn't overflow
            unchecked { ++i; }
        }

        // Process participant addresses
        for (uint i; i < _message.participants.length;) {
            _conversations[conversationID].allowlist[_message.participants[i]] = true;
            // Shouldn't overflow
            unchecked { ++i; }
        }

        // Set conversation name
        _conversations[conversationID].name = _message.message;

        emit ConversationCreated(conversationID, sender, _message.message);
    }

    /*//////////////////////////////////////////////////////////////////////////////
                ADMIN APPROVALS
    //////////////////////////////////////////////////////////////////////////////*/

    // Vote for an address to become a conversation admin
    // A message can be included with the vote
    function addAdminApproval(
        bytes32 _conversationID,
        bytes32 _address,
        bytes memory _message
    ) public payable onlyAdmin(_conversationID) {
        // Require msg.value == 10000000 gwei for current InterchainGasPaymaster integration until on-chain gas estimation is implemented
        require(msg.value >= 10000000 gwei, "Not enough gas for Hyperlane InterchainGasPaymaster");

        // Revert if _address isnt a member
        if (!_conversations[_conversationID].allowlist[_address]) {
            revert InvalidParticipant();
        }
        
        // Convert msg.sender address
        bytes32 admin = addressToBytes32(msg.sender);
        
        // Add admin vote for admin rights approval, revert if approval is already true
        if (!_conversations[_conversationID].adminApprovals[admin][_address]) {
            _conversations[_conversationID].adminApprovals[admin][_address] = true;
        } else {
            revert InvalidApprovals();
        }
        
        // Prepare AddAdminApproval Message
        Message memory message;
        message.timestamp = block.timestamp;
        message.sender = admin;
        message.conversationID = _conversationID;
        message.participants = new bytes32[](1);
        message.participants[0] = _address;
        if (_message.length > 0) {
            message.message = _message;
        }
        else {
            message.message = bytes.concat("Hyperchat: ", admin, " gave admin approval for ", _address, "!");
        }
        message.msgType = MessageType.AddAdminApproval;
        
        _sendMessage(_conversationID, abi.encode(message));

        emit AdminApprovalAdded(_conversationID, admin, _address);
    }

    // Vote for an address to lose its conversation admin rights
    // A message can be included with the vote
    function removeAdminApproval(
        bytes32 _conversationID,
        bytes32 _address,
        bytes memory _message
    ) public payable onlyAdmin(_conversationID) {
        // Require msg.value == 10000000 gwei for current InterchainGasPaymaster integration until on-chain gas estimation is implemented
        require(msg.value >= 10000000 gwei, "Not enough gas for Hyperlane InterchainGasPaymaster");

        // Revert if _address isnt a member
        if (!_conversations[_conversationID].allowlist[_address]) {
            revert InvalidParticipant();
        }
        
        // Convert msg.sender address
        bytes32 admin = addressToBytes32(msg.sender);
        
        // Remove admin vote for admin rights approval, revert if approval is already false
        if (_conversations[_conversationID].adminApprovals[admin][_address]) {
            _conversations[_conversationID].adminApprovals[admin][_address] = false;
        } else {
            revert InvalidApprovals();
        }

        // Prepare RemoveAdminApproval Message
        Message memory message;
        message.timestamp = block.timestamp;
        message.sender = admin;
        message.conversationID = _conversationID;
        message.participants = new bytes32[](1);
        message.participants[0] = _address;
        if (_message.length > 0) {
            message.message = _message;
        }
        else {
            message.message = bytes.concat("Hyperchat: ", admin, " revoked admin approval for ", _address, "!");
        }
        message.msgType = MessageType.RemoveAdminApproval;

        _sendMessage(_conversationID, abi.encode(message));

        emit AdminApprovalRemoved(_conversationID, admin, _address);
    }

    /*//////////////////////////////////////////////////////////////////////////////
                ADMIN ADDITIONS/REMOVALS
    //////////////////////////////////////////////////////////////////////////////*/

    // Give an approved address conversation admin rights
    function addAdmin(
        bytes32 _conversationID,
        bytes32 _address,
        bytes memory _message
    ) public payable onlyAdmin(_conversationID) {
        // Require msg.value == 10000000 gwei for current InterchainGasPaymaster integration until on-chain gas estimation is implemented
        require(msg.value >= 10000000 gwei, "Not enough gas for Hyperlane InterchainGasPaymaster");

        // Revert if _address isnt a member
        if (!_conversations[_conversationID].allowlist[_address]) {
            revert InvalidParticipant();
        }
        // Revert if _address is already an admin
        if (_conversations[_conversationID].isAdmin[_address]) {
            revert InvalidAdmin();
        }

        // Convert msg.sender address
        bytes32 admin = addressToBytes32(msg.sender);
        
        // Retrieve admin count
        uint256 adminCount = _conversations[_conversationID].admins.length;
        // Keep track of approval count for following for loop
        uint256 approvals;
        // Check each admin's approval status for _address
        for (uint i; i < adminCount;) {
            // Retrieve admin address at index i
            bytes32 adminAddress = _conversations[_conversationID].admins[i];

            // Count approval (if any)
            if (_conversations[_conversationID].adminApprovals[adminAddress][_address]) {
                approvals += 1;
            }

            // Once 51% approval threshold is met, break loop to save gas
            if (approvals > adminCount / 2) {
                break;
            }

            // Loop shouldn't ever overflow
            unchecked { ++i; }
        }

        // If 51% approval threshold is met, give _address conversation admin rights
        if (approvals > adminCount / 2) {
            // Set admin data structures
            _conversations[_conversationID].admins.push(_address);
            _conversations[_conversationID].isAdmin[_address] = true;
            _conversations[_conversationID].adminApprovals[_address][_address] = true;

            emit AdminAdded(_conversationID, admin, _address);
        } else {
            revert InvalidApprovals();
        }

        // Prepare AddAdminApproval Message
        Message memory message;
        message.timestamp = block.timestamp;
        message.sender = admin;
        message.conversationID = _conversationID;
        message.participants = new bytes32[](1);
        message.participants[0] = _address;
        if (_message.length > 0) {
            message.message = _message;
        }
        else {
            message.message = bytes.concat("Hyperchat: ", admin, " added ", _address, " to conversation as admin!");
        }
        message.msgType = MessageType.AddAdmin;

        _sendMessage(_conversationID, abi.encode(message));
    }

    // Remove an addresss conversation admin rights
    function removeAdmin(
        bytes32 _conversationID,
        bytes32 _address,
        bytes memory _message
    ) public payable onlyAdmin(_conversationID) {
        // Require msg.value == 10000000 gwei for current InterchainGasPaymaster integration until on-chain gas estimation is implemented
        require(msg.value >= 10000000 gwei, "Not enough gas for Hyperlane InterchainGasPaymaster");

        // Revert if _address isnt a member
        if (!_conversations[_conversationID].allowlist[_address]) {
            revert InvalidParticipant();
        }
        // Revert if _address isn't already an admin
        if (!_conversations[_conversationID].isAdmin[_address]) {
            revert InvalidAdmin();
        }
        // Revert if _address is the last admin
        if (_conversations[_conversationID].admins.length == 1) {
            revert InvalidAdmin();
        }

        // Convert msg.sender address
        bytes32 admin = addressToBytes32(msg.sender);
        
        // Retrieve admin count
        uint256 adminCount = _conversations[_conversationID].admins.length;
        // Keep track of approval count for following for loop
        uint256 approvals;
        // Check each admin's approval status for _address
        for (uint i; i < adminCount;) {
            // Retrieve admin address at index i
            bytes32 adminAddress = _conversations[_conversationID].admins[i];

            // Count approval (if any)
            if (_conversations[_conversationID].adminApprovals[adminAddress][_address]) {
                approvals += 1;
            }

            // If above 51% approval threshold, break loop to save gas
            if (approvals > adminCount / 2) {
                break;
            }

            // Loop shouldn't ever overflow
            unchecked { ++i; }
        }

        // If 51% approval threshold isn't met, remove _address' conversation admin rights
        if (approvals <= adminCount / 2) {
            // Search through admins array for _address and remove it
            for (uint i; i < adminCount;) {
                if (_conversations[_conversationID].admins[i] == _address) {
                    _removeFromAdminArray(_conversationID, i);
                    break;
                }

                // Loop shouldn't ever overflow
                unchecked { ++i; }
            }

            // Remove admin data structures
            delete _conversations[_conversationID].isAdmin[_address];
            delete _conversations[_conversationID].adminApprovals[_address][_address];

            emit AdminRemoved(_conversationID, addressToBytes32(msg.sender), _address);
        } else {
            revert InvalidApprovals();
        }

        // Prepare AddAdminApproval Message
        Message memory message;
        message.timestamp = block.timestamp;
        message.sender = admin;
        message.conversationID = _conversationID;
        message.participants = new bytes32[](1);
        message.participants[0] = _address;
        if (_message.length > 0) {
            message.message = _message;
        }
        else {
            message.message = bytes.concat("Hyperchat: ", admin, " removed ", _address, " from conversation as admin!");
        }
        message.msgType = MessageType.RemoveAdmin;

        _sendMessage(_conversationID, abi.encode(message));
    }

    /*//////////////////////////////////////////////////////////////////////////////
                PARTICIPANT ADDITIONS/REMOVALS
    //////////////////////////////////////////////////////////////////////////////*/

    // Add an address to a conversation
    function addParticipant(
        bytes32 _conversationID,
        bytes32 _address,
        bytes memory _message
    ) public payable onlyAdmin(_conversationID) {
        // Require msg.value == 10000000 gwei for current InterchainGasPaymaster integration until on-chain gas estimation is implemented
        require(msg.value >= 10000000 gwei, "Not enough gas for Hyperlane InterchainGasPaymaster");

        // Add if not present, else revert
        if (!_conversations[_conversationID].allowlist[_address]) {
            _conversations[_conversationID].allowlist[_address] = true;
        } else {
            revert InvalidParticipant();
        }

        // Convert msg.sender address
        bytes32 admin = addressToBytes32(msg.sender);

        // Prepare AddParticipant Message
        Message memory message;
        message.timestamp = block.timestamp;
        message.sender = admin;
        message.conversationID = _conversationID;
        message.participants = new bytes32[](1);
        message.participants[0] = _address;
        if (_message.length > 0) {
            message.message = _message;
        }
        else {
            message.message = bytes.concat("Hyperchat: Welcome ", _address, "!");
        }
        message.msgType = MessageType.AddParticipant;

        _sendMessage(_conversationID, abi.encode(message));

        emit ParticipantAdded(_conversationID, admin, _address);
    }

    // Remove an address from a conversation
    function removeParticipant(
        bytes32 _conversationID,
        bytes32 _address,
        bytes memory _message
    ) public payable onlyAdmin(_conversationID) {
        // Require msg.value == 10000000 gwei for current InterchainGasPaymaster integration until on-chain gas estimation is implemented
        require(msg.value >= 10000000 gwei, "Not enough gas for Hyperlane InterchainGasPaymaster");

        // Remove if present and non-admin, else revert
        if (!_conversations[_conversationID].allowlist[_address]) {
            revert InvalidParticipant();
        }
        else if (_conversations[_conversationID].isAdmin[_address]) {
            revert InvalidAdmin();
        }
        else {
            delete _conversations[_conversationID].allowlist[_address];
        }

        // Convert msg.sender address
        bytes32 admin = addressToBytes32(msg.sender);

        // Prepare RemoveParticipant Message
        Message memory message;
        message.timestamp = block.timestamp;
        message.sender = admin;
        message.conversationID = _conversationID;
        message.participants = new bytes32[](1);
        message.participants[0] = _address;
        if (_message.length > 0) {
            message.message = _message;
        }
        else {
            message.message = bytes.concat("Hyperchat: Goodbye ", _address, "!");
        }
        message.msgType = MessageType.RemoveParticipant;

        _sendMessage(_conversationID, abi.encode(message));

        emit ParticipantRemoved(_conversationID, admin, _address);
    }

    /*//////////////////////////////////////////////////////////////////////////////
                GENERAL MESSAGES
    //////////////////////////////////////////////////////////////////////////////*/

    // Send general message
    function generalMessage(bytes32 _conversationID, bytes memory _message) public payable onlyMember(_conversationID) {
        // Require msg.value == 10000000 gwei for current InterchainGasPaymaster integration until on-chain gas estimation is implemented
        require(msg.value >= 10000000 gwei, "Not enough gas for Hyperlane InterchainGasPaymaster");
        
        // Revert if _message is zero bytes
        if (_message.length == 0) {
            revert InvalidMessage();
        }
        
        // Convert msg.sender address
        bytes32 sender = addressToBytes32(msg.sender);
        
        Message memory message;
        message.timestamp = block.timestamp;
        message.sender = sender;
        message.conversationID = _conversationID;
        message.message = _message;
        message.msgType = MessageType.GeneralMessage;

        _sendMessage(_conversationID, abi.encode(message));

        emit GeneralMessage(_conversationID, sender, _message);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                SEND/RECEIVE MESSAGE LOGIC
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    // Send message of any type to conversation
    // Message will be broadcast to all domainIDs in conversation metadata
    function _sendMessage(bytes32 _conversationID, bytes memory _message) internal onlyMember(_conversationID) {
        // Iterate sending via hyperlane to each domainID
        for (uint i; i < _conversations[_conversationID].domainIDs.length;) {
            // Retrieve domainID at index i
            uint32 domainID = _conversations[_conversationID].domainIDs[i];

            // Skip sending to the domainID for this chain as its logic was already processed locally
            if (domainID == HYPERLANE_DOMAIN_IDENTIFIER) {
                // Still append to _messages mapping though
                _messages[_conversationID][_conversations[_conversationID].messageCount] = abi.decode(_message, (Message));
                // Shouldn't overflow
                unchecked { ++i; }
                continue;
            }

            _dispatchWithGas(domainID, _message, 10000000 gwei, 10000000 gwei, msg.sender);
            
            // Shouldn't overflow
            unchecked { ++i; }
        }

        // Increment conversation message count
        _conversations[_conversationID].messageCount += 1;

        emit MessageSent(_conversationID, addressToBytes32(msg.sender), _message);
    }
    
    // Overriding the Hyperlane Router.sol's _handle() function is how receive logic is implemented
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) internal override {
        // Decode message back into Message type
        Message memory message = abi.decode(_message, (Message));
        // Retrieve conversationID
        bytes32 conversationID = message.conversationID;
        // Retrieve sender
        bytes32 sender = message.sender;

        emit MessageReceived(conversationID, sender, _message);

        // Process Message data
        _processMessage(message);

        // Save message in _messages storage
        _messages[conversationID][_conversations[conversationID].messageCount] = message;

        // Increment conversation message count
        _conversations[conversationID].messageCount += 1;
    }
}