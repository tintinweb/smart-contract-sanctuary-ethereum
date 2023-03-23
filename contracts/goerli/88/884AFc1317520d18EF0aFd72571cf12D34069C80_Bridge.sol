// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;
import "./utils/SafeCast.sol";
import "./utils/AccessControlEnumerableUpgradeable.sol";
import "./interfaces/IDepositExecute.sol";
import "./interfaces/IERCHandler.sol";
import "./interfaces/IGenericHandler.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
    @title Facilitates deposits, creation and voting of deposit proposals, and deposit executions.
    @author ChainSafe Systems.
 */
contract Bridge is Initializable,PausableUpgradeable,AccessControlEnumerableUpgradeable{
  using SafeCast for *;

  // Limit relayers number because proposal can fit only so much votes
  uint256 public constant MAX_RELAYERS = 200;

  uint64 public _domainID;
  uint8 public _relayerThreshold;
  uint128 public _fee;
  uint40 public _expiry;

  enum ProposalStatus {
    Inactive,
    Active,
    Passed,
    Executed,
    Cancelled
  }

  struct Proposal {
    ProposalStatus _status;
    uint200 _yesVotes; // bitmap, 200 maximum votes
    uint8 _yesVotesTotal;
    uint40 _proposedBlock; // 1099511627775 maximum block
  }

  // destinationDomainID => number of deposits
  mapping(uint64 => uint64) public _depositCounts;
  // resourceID => handler address
  mapping(bytes32 => address) public _resourceIDToHandlerAddress;
  // forwarder address => is Valid
  mapping(address => bool) public isValidForwarder;
  // destinationDomainID + depositNonce => dataHash => Proposal
  mapping(uint72 => mapping(bytes32 => Proposal)) private _proposals;

  event RelayerThresholdChanged(uint256 newThreshold);
  event RelayerAdded(address relayer);
  event RelayerRemoved(address relayer);
  event Deposit(
    uint64 destinationDomainID,
    bytes32 resourceID,
    uint64 depositNonce,
    address indexed user,
    bytes data,
    bytes handlerResponse
  );
  event ProposalEvent(
    uint64 originDomainID,
    uint64 depositNonce,
    ProposalStatus status,
    bytes32 dataHash
  );
  event ProposalVote(
    uint64 originDomainID,
    uint64 depositNonce,
    ProposalStatus status,
    bytes32 dataHash
  );
  event FailedHandlerExecution(bytes lowLevelData);

  bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

  /**
        @notice Initializes Bridge, creates and grants {_msgSender()} the admin role,
        creates and grants {initialRelayers} the relayer role.
        @param domainID ID of chain the Bridge contract exists on.
        @param initialRelayers Addresses that should be initially granted the relayer role.
        @param initialRelayerThreshold Number of votes needed for a deposit proposal to be considered passed.
     */

  function initialize(
    uint64 domainID,
    address[] memory initialRelayers,
    uint256 initialRelayerThreshold,
    uint256 fee,
    uint256 expiry
  ) public initializer {
    _domainID = domainID;
    _relayerThreshold = initialRelayerThreshold.toUint8();
    _fee = fee.toUint128();
    _expiry = expiry.toUint40();

    __Pausable_init();
    __AccessControlEnumerableUpgradeable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    for (uint256 i; i < initialRelayers.length; i++) {
      grantRole(RELAYER_ROLE, initialRelayers[i]);
    }
  }

  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }

  modifier onlyAdminOrRelayer() {
    _onlyAdminOrRelayer();
    _;
  }

  modifier onlyRelayers() {
    _onlyRelayers();
    _;
  }

  function _onlyAdminOrRelayer() private view {
    address sender = _msgSender();
    require(
      hasRole(DEFAULT_ADMIN_ROLE, sender) || hasRole(RELAYER_ROLE, sender),
      "sender is not relayer or admin"
    );
  }

  function _onlyAdmin() private view {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "sender doesn't have admin role"
    );
  }

  function _onlyRelayers() private view {
    require(
      hasRole(RELAYER_ROLE, _msgSender()),
      "sender doesn't have relayer role"
    );
  }

  function _relayerBit(address relayer) private view returns (uint) {
    return
      uint(1) << (AccessControlEnumerableUpgradeable.getRoleMemberIndex(RELAYER_ROLE, relayer) - 1);
  }

  function _hasVoted(
    Proposal memory proposal,
    address relayer
  ) private view returns (bool) {
    return (_relayerBit(relayer) & uint(proposal._yesVotes)) > 0;
  }

  function _msgSender() internal view override returns (address) {
    address signer = msg.sender;
    if (msg.data.length >= 20 && isValidForwarder[signer]) {
      assembly {
        signer := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }
    return signer;
  }

  /**
        @notice Returns true if {relayer} has voted on {destNonce} {dataHash} proposal.
        @notice Naming left unchanged for backward compatibility.
        @param destNonce destinationDomainID + depositNonce of the proposal.
        @param dataHash Hash of data to be provided when deposit proposal is executed.
        @param relayer Address to check.
     */
  function _hasVotedOnProposal(
    uint72 destNonce,
    bytes32 dataHash,
    address relayer
  ) public view returns (bool) {
    return _hasVoted(_proposals[destNonce][dataHash], relayer);
  }

  /**
        @notice Returns true if {relayer} has the relayer role.
        @param relayer Address to check.
     */
  function isRelayer(address relayer) external view returns (bool) {
    return hasRole(RELAYER_ROLE, relayer);
  }

  /**
        @notice Removes admin role from {_msgSender()} and grants it to {newAdmin}.
        @notice Only callable by an address that currently has the admin role.
        @param newAdmin Address that admin role will be granted to.
     */
  function renounceAdmin(address newAdmin) external onlyAdmin {
    address sender = _msgSender();
    require(sender != newAdmin, "Cannot renounce oneself");
    grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    renounceRole(DEFAULT_ADMIN_ROLE, sender);
  }

  /**
        @notice Pauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
  function adminPauseTransfers() external onlyAdmin {
    _pause();
  }

  /**
        @notice Unpauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
  function adminUnpauseTransfers() external onlyAdmin {
    _unpause();
  }

  /**
        @notice Modifies the number of votes required for a proposal to be considered passed.
        @notice Only callable by an address that currently has the admin role.
        @param newThreshold Value {_relayerThreshold} will be changed to.
        @notice Emits {RelayerThresholdChanged} event.
     */
  function adminChangeRelayerThreshold(
    uint256 newThreshold
  ) external onlyAdmin {
    _relayerThreshold = newThreshold.toUint8();
    emit RelayerThresholdChanged(newThreshold);
  }

  /**
        @notice Grants {relayerAddress} the relayer role.
        @notice Only callable by an address that currently has the admin role, which is
                checked in grantRole().
        @param relayerAddress Address of relayer to be added.
        @notice Emits {RelayerAdded} event.
     */
  function adminAddRelayer(address relayerAddress) external {
    require(
      !hasRole(RELAYER_ROLE, relayerAddress),
      "addr already has relayer role!"
    );
    require(_totalRelayers() < MAX_RELAYERS, "relayers limit reached");
    grantRole(RELAYER_ROLE, relayerAddress);
    emit RelayerAdded(relayerAddress);
  }

  /**
        @notice Removes relayer role for {relayerAddress}.
        @notice Only callable by an address that currently has the admin role, which is
                checked in revokeRole().
        @param relayerAddress Address of relayer to be removed.
        @notice Emits {RelayerRemoved} event.
     */
  function adminRemoveRelayer(address relayerAddress) external {
    require(
      hasRole(RELAYER_ROLE, relayerAddress),
      "addr doesn't have relayer role!"
    );
    revokeRole(RELAYER_ROLE, relayerAddress);
    emit RelayerRemoved(relayerAddress);
  }

  /**
        @notice Sets a new resource for handler contracts that use the IERCHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
  function adminSetResource(
    address handlerAddress,
    bytes32 resourceID,
    address tokenAddress
  ) external onlyAdmin {
    _resourceIDToHandlerAddress[resourceID] = handlerAddress;
    IERCHandler handler = IERCHandler(handlerAddress);
    handler.setResource(resourceID, tokenAddress);
  }

  /**
        @notice Sets a new resource for handler contracts that use the IGenericHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
  function adminSetGenericResource(
    address handlerAddress,
    bytes32 resourceID,
    address contractAddress,
    bytes4 depositFunctionSig,
    uint256 depositFunctionDepositerOffset,
    bytes4 executeFunctionSig
  ) external onlyAdmin {
    _resourceIDToHandlerAddress[resourceID] = handlerAddress;
    IGenericHandler handler = IGenericHandler(handlerAddress);
    handler.setResource(
      resourceID,
      contractAddress,
      depositFunctionSig,
      depositFunctionDepositerOffset,
      executeFunctionSig
    );
  }

  /**
        @notice Sets a resource as burnable for handler contracts that use the IERCHandler interface.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
  function adminSetBurnable(
    address handlerAddress,
    address tokenAddress
  ) external onlyAdmin {
    IERCHandler handler = IERCHandler(handlerAddress);
    handler.setBurnable(tokenAddress);
  }

  /**
        @notice Sets the nonce for the specific domainID.
        @notice Only callable by an address that currently has the admin role.
        @param domainID Domain ID for increasing nonce.
        @param nonce The nonce value to be set.
     */
  function adminSetDepositNonce(
    uint64 domainID,
    uint64 nonce
  ) external onlyAdmin {
    require(
      nonce > _depositCounts[domainID],
      "Does not allow decrements of the nonce"
    );
    _depositCounts[domainID] = nonce;
  }

  /**
        @notice Set a forwarder to be used.
        @notice Only callable by an address that currently has the admin role.
        @param forwarder Forwarder address to be added.
        @param valid Decision for the specific forwarder.
     */
  function adminSetForwarder(address forwarder, bool valid) external onlyAdmin {
    isValidForwarder[forwarder] = valid;
  }

  /**
        @notice Returns a proposal.
        @param originDomainID Chain ID deposit originated from.
        @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
        @param dataHash Hash of data to be provided when deposit proposal is executed.
        @return Proposal which consists of:
        - _dataHash Hash of data to be provided when deposit proposal is executed.
        - _yesVotes Number of votes in favor of proposal.
        - _noVotes Number of votes against proposal.
        - _status Current status of proposal.
     */
  function getProposal(
    uint64 originDomainID,
    uint64 depositNonce,
    bytes32 dataHash
  ) external view returns (Proposal memory) {
    uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(originDomainID);
    return _proposals[nonceAndID][dataHash];
  }

  /**
        @notice Returns total relayers number.
        @notice Added for backwards compatibility.
     */
  function _totalRelayers() public view returns (uint) {
    return AccessControlEnumerableUpgradeable.getRoleMemberCount(RELAYER_ROLE);
  }

  /**
        @notice Changes deposit fee.
        @notice Only callable by admin.
        @param newFee Value {_fee} will be updated to.
     */
  function adminChangeFee(uint256 newFee) external onlyAdmin {
    require(_fee != newFee, "Current fee is equal to new fee");
    _fee = newFee.toUint128();
  }

  /**
        @notice Used to manually withdraw funds from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param data ABI-encoded withdrawal params relevant to the specified handler.
     */
  function adminWithdraw(
    address handlerAddress,
    bytes memory data
  ) external onlyAdmin {
    IERCHandler handler = IERCHandler(handlerAddress);
    handler.withdraw(data);
  }

  /**
        @notice Initiates a transfer using a specified handler contract.
        @notice Only callable when Bridge is not paused.
        @param destinationDomainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
        @param data Additional data to be passed to specified handler.
        @notice Emits {Deposit} event with all necessary parameters and a handler response.
        - ERC20Handler: responds with an empty data.
        - ERC721Handler: responds with the deposited token metadata acquired by calling a tokenURI method in the token contract.
        - GenericHandler: responds with the raw bytes returned from the call to the target contract.
     */
  function deposit(
    uint64 destinationDomainID,
    bytes32 resourceID,
    bytes calldata data
  ) external payable whenNotPaused {
    // Disable fee
    // require(msg.value == _fee, "Incorrect fee supplied");

    address handler = _resourceIDToHandlerAddress[resourceID];
    require(handler != address(0), "resourceID not mapped to handler");

    uint64 depositNonce = ++_depositCounts[destinationDomainID];
    address sender = _msgSender();

    IDepositExecute depositHandler = IDepositExecute(handler);
    bytes memory handlerResponse = depositHandler.deposit{ value: msg.value }(
      resourceID,
      sender,
      data
    );

    emit Deposit(
      destinationDomainID,
      resourceID,
      depositNonce,
      sender,
      data,
      handlerResponse
    );
  }

  /**
        @notice When called, {_msgSender()} will be marked as voting in favor of proposal.
        @notice Only callable by relayers when Bridge is not paused.
        @param domainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param data Data originally provided when deposit was made.
        @notice Proposal must not have already been passed or executed.
        @notice {_msgSender()} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
  function voteProposal(
    uint64 domainID,
    uint64 depositNonce,
    bytes32 resourceID,
    bytes calldata data
  ) external onlyRelayers whenNotPaused {
    address handler = _resourceIDToHandlerAddress[resourceID];
    uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(domainID);
    bytes32 dataHash = keccak256(abi.encodePacked(handler, data));
    Proposal memory proposal = _proposals[nonceAndID][dataHash];

    require(
      _resourceIDToHandlerAddress[resourceID] != address(0),
      "no handler for resourceID"
    );

    if (proposal._status == ProposalStatus.Passed) {
      executeProposal(domainID, depositNonce, data, resourceID, true);
      return;
    }

    address sender = _msgSender();

    require(uint(proposal._status) <= 1, "proposal already executed/cancelled");
    require(!_hasVoted(proposal, sender), "relayer already voted");

    if (proposal._status == ProposalStatus.Inactive) {
      proposal = Proposal({
        _status: ProposalStatus.Active,
        _yesVotes: 0,
        _yesVotesTotal: 0,
        _proposedBlock: uint40(block.number) // Overflow is desired.
      });

      emit ProposalEvent(
        domainID,
        depositNonce,
        ProposalStatus.Active,
        dataHash
      );
    } else if (uint40(block.number - proposal._proposedBlock) > _expiry) {
      // if the number of blocks that has passed since this proposal was
      // submitted exceeds the expiry threshold set, cancel the proposal
      proposal._status = ProposalStatus.Cancelled;

      emit ProposalEvent(
        domainID,
        depositNonce,
        ProposalStatus.Cancelled,
        dataHash
      );
    }

    if (proposal._status != ProposalStatus.Cancelled) {
      proposal._yesVotes = (proposal._yesVotes | _relayerBit(sender))
        .toUint200();
      proposal._yesVotesTotal++; // TODO: check if bit counting is cheaper.

      emit ProposalVote(domainID, depositNonce, proposal._status, dataHash);

      // Finalize if _relayerThreshold has been reached
      if (proposal._yesVotesTotal >= _relayerThreshold) {
        proposal._status = ProposalStatus.Passed;
        emit ProposalEvent(
          domainID,
          depositNonce,
          ProposalStatus.Passed,
          dataHash
        );
      }
    }
    _proposals[nonceAndID][dataHash] = proposal;

    if (proposal._status == ProposalStatus.Passed) {
      executeProposal(domainID, depositNonce, data, resourceID, false);
    }
  }

  /**
        @notice Cancels a deposit proposal that has not been executed yet.
        @notice Only callable by relayers when Bridge is not paused.
        @param domainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data originally provided when deposit was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
  function cancelProposal(
    uint64 domainID,
    uint64 depositNonce,
    bytes32 dataHash
  ) public onlyAdminOrRelayer {
    uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(domainID);
    Proposal memory proposal = _proposals[nonceAndID][dataHash];
    ProposalStatus currentStatus = proposal._status;

    require(
      currentStatus == ProposalStatus.Active ||
        currentStatus == ProposalStatus.Passed,
      "Proposal cannot be cancelled"
    );
    require(
      uint40(block.number - proposal._proposedBlock) > _expiry,
      "Proposal not at expiry threshold"
    );

    proposal._status = ProposalStatus.Cancelled;
    _proposals[nonceAndID][dataHash] = proposal;

    emit ProposalEvent(
      domainID,
      depositNonce,
      ProposalStatus.Cancelled,
      dataHash
    );
  }

  /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param domainID ID of chain deposit originated from.
        @param resourceID ResourceID to be used when making deposits.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param data Data originally provided when deposit was made.
        @param revertOnFail Decision if the transaction should be reverted in case of handler's executeProposal is reverted or not.
        @notice Proposal must have Passed status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
        @notice Emits {FailedExecution} event with the failed reason.
     */
  function executeProposal(
    uint64 domainID,
    uint64 depositNonce,
    bytes calldata data,
    bytes32 resourceID,
    bool revertOnFail
  ) public onlyRelayers whenNotPaused {
    address handler = _resourceIDToHandlerAddress[resourceID];
    uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(domainID);
    bytes32 dataHash = keccak256(abi.encodePacked(handler, data));
    Proposal storage proposal = _proposals[nonceAndID][dataHash];

    require(
      proposal._status == ProposalStatus.Passed,
      "Proposal must have Passed status"
    );

    proposal._status = ProposalStatus.Executed;
    IDepositExecute depositHandler = IDepositExecute(handler);

    if (revertOnFail) {
      depositHandler.executeProposal(resourceID, data);
    } else {
      try depositHandler.executeProposal(resourceID, data) {} catch (
        bytes memory lowLevelData
      ) {
        proposal._status = ProposalStatus.Passed;
        emit FailedHandlerExecution(lowLevelData);
        return;
      }
    }

    emit ProposalEvent(
      domainID,
      depositNonce,
      ProposalStatus.Executed,
      dataHash
    );
  }

  /**
        @notice Transfers eth in the contract to the specified addresses. The parameters addrs and amounts are mapped 1-1.
        This means that the address at index 0 for addrs will receive the amount (in WEI) from amounts at index 0.
        @param addrs Array of addresses to transfer {amounts} to.
        @param amounts Array of amounts to transfer to {addrs}.
     */
  function transferFunds(
    address[] calldata addrs,
    uint[] calldata amounts
  ) external onlyAdmin {
    require(addrs.length == amounts.length, "Wrong lengths");

    for (uint256 i = 0; i < addrs.length; i++) {
      (bool success, ) = addrs[i].call{ value: amounts[i] }("");
      require(success, "Transfer failed");
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IDepositExecute {
    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data Consists of additional data needed for a specific deposit.
     */
    function deposit(
        bytes32 resourceID,
        address depositer,
        bytes calldata data
    ) external payable returns (bytes memory);

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
        @param data Consists of additional data needed for a specific deposit execution.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author ChainSafe Systems.
 */
interface IERCHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external;

    /**
        @notice Marks {contractAddress} as mintable/burnable.
        @param contractAddress Address of contract to be used when making or executing deposits.
     */
    function setBurnable(address contractAddress) external;

    /**
        @notice Withdraw funds from ERC safes.
        @param data ABI-encoded withdrawal params relevant to the handler.
     */
    function withdraw(bytes memory data) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;

/**
    @title Interface for handler that handles generic deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IGenericHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}, {depositFunctionSig}, and {executeFunctionSig}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param depositFunctionSig Function signature of method to be called in {contractAddress} when a deposit is made.
        @param depositFunctionDepositerOffset Depositer address position offset in the metadata, in bytes.
        @param executeFunctionSig Function signature of method to be called in {contractAddress} when a deposit is executed.
     */
    function setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint depositFunctionDepositerOffset,
        bytes4 executeFunctionSig
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, ContextUpgradeable{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roleMembers;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

       /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function __AccessControlEnumerableUpgradeable_init() internal onlyInitializing {
    }

     function __AccessControlEnumerableUpgradeable_init_unchained() internal onlyInitializing {
    }

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );


    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roleMembers[role].members.contains(account);
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
        return _roleMembers[role].members.at(index);
    }
     /**
     * @dev Returns the index of the account that have `role`.
     */
    function getRoleMemberIndex(
        bytes32 role,
        address account
    ) public view returns (uint256) {
        return
            _roleMembers[role].members._inner._indexes[
                bytes32(uint256(uint160(account)))
            ];
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
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

/**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleMembers[role].adminRole;
    }

  
    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roleMembers[role].members.length();
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
        require(
            hasRole(_roleMembers[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

        _grantRole(role, account);
    }

   function _grantRole(bytes32 role, address account) private {
        if (_roleMembers[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
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
        _roleMembers[role].adminRole = adminRole;
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
        require(
            hasRole(_roleMembers[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

        _revokeRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roleMembers[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

library SafeCast {
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value < 2 ** 200, "value does not fit in 200 bits");
        return uint200(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2 ** 128, "value does not fit in 128 bits");
        return uint128(value);
    }

    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2 ** 40, "value does not fit in 40 bits");
        return uint40(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2 ** 8, "value does not fit in 8 bits");
        return uint8(value);
    }
}