// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./extensions/LinearPoolSignature.sol";

contract LinearPool is
    LinearPoolSignature,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeCastUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint32 private constant ONE_YEAR_IN_SECONDS = 365 days;

    // The accepted token
    IERC20 public linearAcceptedToken;
    // The reward distribution address
    address public linearRewardDistributor;
    // Info of each pool
    LinearPoolInfo[] public linearPoolInfo;
    // Info of each user that stakes in pools
    mapping(uint256 => mapping(address => LinearStakingData))
        public linearStakingData;
    // Allow emergency withdraw feature
    bool public linearAllowEmergencyWithdraw;

    event LinearPoolCreated(
        uint256 indexed poolId,
        uint64 APR,
        uint128 capacity,
        uint128 lockDuration,
        uint128 startJoinTime,
        uint128 endJoinTime
    );
    event LinearDeposit(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );
    event LinearWithdraw(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );
    event LinearRewardsHarvested(
        uint256 indexed poolId,
        address indexed account,
        uint256 reward
    );
    event LinearPendingWithdraw(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );
    event LinearEmergencyWithdraw(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );

    struct LinearPoolInfo {
        uint128 cap;
        uint128 totalStaked;
        uint64 APR;
        uint128 lockDuration;
        uint128 startJoinTime;
        uint128 endJoinTime;
    }

    struct LinearStakingData {
        uint128 balance;
        uint128 joinTime;
        uint128 updatedTime;
        uint128 reward;
    }

    // phase 2 - upgradeable - early redeemtion
    uint16 public constant HUNDRED_PERCENT = 100;
    mapping(uint256 => AdditionalPoolInfo) public additionalPoolInfo;

    // Info of pending withdrawals.
    mapping(uint256 => mapping(address => LinearPendingEarlyWithdrawal))
        public linearPendingEarlyWithdrawals;

    // mapping(uint256 => mapping(address => uint128)) public linearRemainReward;

    struct LinearPendingEarlyWithdrawal {
        uint128 reward;
        uint128 amount;
        uint128 applicableAt;
    }

    struct AdditionalPoolInfo {
        mapping(address => bool) isWhitelisted; // isWhitelisted(user_address) allow user for early redeem
        mapping(uint16 => uint16) penaltyRate; // 100% = 100
        mapping(uint16 => bool) isPenaltyEnabled; // isPenaltyEnabled(poolId)
        uint128 delayDuration; // default = 0
    }

    event LinearClaimPendingWithdraw(
        uint256 poolId,
        address account,
        uint128 amount
    );

    event LinearEarlyWithdraw(
        uint256 poolId,
        address account,
        uint128 amount,
        uint128 reward,
        uint128 fee
    );

    event LinearUpdatePool(
        uint256 poolId,
        uint64 APR,
        uint128 capacity,
        uint128 endJoinTime
    );

    event LinearAddWhitelist(uint256 poolId, address account);
    event LinearRemoveWhitelist(uint256 poolId, address account);

    event LinearSetDelayDuration(uint256 poolId, uint128 duration);

    event LinearSetEarlyWithdrawTier(
        uint256 poolId,
        uint16 percentageKey,
        uint16 percentageValue
    );

    event AssignStakingData(uint256 poolId, address from, address to);
    event AdminRecoverFund(address token, address to, uint256 amount);

    event ChangeRewardDistributor(
        address oldDistributor,
        address newDistributor
    );
    event ChangeTreasury(address oldTreasury, address newTreasury);

    address public treasury;
    mapping(address => bool) public isBlacklisted;

    event UserBlacklisted(address user);
    event UnsetUserBlacklisted(address user);

    // NFT Presale
    // this is address get token when user withdraw, and admin will check and manual transfer NFT to user
    address public nftTreasury;
    // The address of signer account
    address public signer;

    event ChangeNftTreasury(address oldTreasury, address newTreasury);
    event ChangeNftSigner(address oldSigner, address newSigner);
    event FundTokenToNftTreasury(address user, uint256 amount, uint256 count);

    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "Airdrop: blacklisted");
        _;
    }

    function setUserBlacklist(address[] calldata _users) external onlyOwner {
        uint256 len = _users.length;
        for (uint256 i = 0; i < len; i++) {
            isBlacklisted[_users[i]] = true;
            emit UserBlacklisted(_users[i]);
        }
    }

    function unsetUserBlacklist(address[] calldata _users) external onlyOwner {
        uint256 len = _users.length;
        for (uint256 i = 0; i < len; i++) {
            isBlacklisted[_users[i]] = false;
            emit UnsetUserBlacklisted(_users[i]);
        }
    }

    /**
     * @notice Initialize the contract, get called in the first time deploy
     * @param _acceptedToken the token that the pools will use as staking and reward token
     */
    function __LinearPool_init(IERC20 _acceptedToken, address _treasury)
        public
        initializer
    {
        require(
            _treasury != address(0) && address(_acceptedToken) != address(0),
            "LinearStakingPool: not allow zero address"
        );

        __Ownable_init();
        __Pausable_init();
        _pause();

        linearAcceptedToken = _acceptedToken;
        treasury = _treasury;
    }

    /**
     * @notice Validate pool by pool ID
     * @param _poolId id of the pool
     */
    modifier linearValidatePoolById(uint256 _poolId) {
        require(
            _poolId < linearPoolInfo.length,
            "LinearStakingPool: Pool are not exist"
        );
        _;
    }

    /**
     * @notice Pause contract
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Set treasury address
     * @param _treasury treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "LinearStakingPool: not allow zero address"
        );

        emit ChangeTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    /**
     * @notice Set treasury address
     * @param _treasury treasury address
     */
    function setNftTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "LinearStakingPool: not allow zero address"
        );

        emit ChangeNftTreasury(treasury, _treasury);
        nftTreasury = _treasury;
    }

    /**
     * @notice Owner can set the new signer.
     * @param _newSigner Address of new signer
     */
    function setNewSigner(address _newSigner) external onlyOwner {
        require(signer != _newSigner, "LinearStakingPool: invalid signer");

        emit ChangeNftSigner(signer, _newSigner);
        signer = _newSigner;
    }

    /**
     * @notice Admin withdraw tokens from a contract
     * @param _token token to withdraw
     * @param _to to user address
     * @param _amount amount to withdraw
     */
    function linearAdminRecoverFund(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "LinearStakingPool: not enough balance"
        );
        IERC20(_token).safeTransfer(_to, _amount);
        emit AdminRecoverFund(_token, _to, _amount);
    }

    /**
     * @notice Admin can change the deposit and rewards from one address to another address
     * @param _from from user address
     * @param _to to user address
     */
    function linearAssignStakedData(
        uint256 _poolId,
        address _from,
        address _to
    ) external onlyOwner linearValidatePoolById(_poolId) {
        require(_from != address(0), "LinearStakingPool: invalid from address");
        require(_to != address(0), "LinearStakingPool: invalid to address");
        require(_from != _to, "LinearStakingPool: require from != to address");

        LinearStakingData storage stakingData = linearStakingData[_poolId][_to];
        LinearPendingEarlyWithdrawal
            storage pendingWithdrawData = linearPendingEarlyWithdrawals[
                _poolId
            ][_to];
        require(
            stakingData.balance == 0 &&
                stakingData.reward == 0 &&
                stakingData.joinTime == 0 &&
                stakingData.updatedTime == 0 &&
                pendingWithdrawData.reward == 0 &&
                pendingWithdrawData.applicableAt == 0 &&
                pendingWithdrawData.amount == 0,
            "LinearStakingPool: user already staked"
        );

        // LinearStakingData
        linearStakingData[_poolId][_to] = linearStakingData[_poolId][_from];
        delete linearStakingData[_poolId][_from];

        // LinearPendingEarlyWithdrawal
        linearPendingEarlyWithdrawals[_poolId][
            _to
        ] = linearPendingEarlyWithdrawals[_poolId][_from];
        delete linearPendingEarlyWithdrawals[_poolId][_from];

        // whitelist
        if (additionalPoolInfo[_poolId].isWhitelisted[_from]) {
            additionalPoolInfo[_poolId].isWhitelisted[_to] = true;
            delete additionalPoolInfo[_poolId].isWhitelisted[_from];
        }

        emit AssignStakingData(_poolId, _from, _to);
    }

    /**
     * @notice Return total number of pools
     */
    function linearPoolLength() external view returns (uint256) {
        return linearPoolInfo.length;
    }

    /**
     * @notice Return total tokens staked in a pool
     * @param _poolId id of the pool
     */
    function linearTotalStaked(uint256 _poolId)
        external
        view
        linearValidatePoolById(_poolId)
        returns (uint256)
    {
        return linearPoolInfo[_poolId].totalStaked;
    }

    /**
     * @notice Add a new pool with different APR and conditions. Can only be called by the owner.
     * @param _cap the maximum number of staking tokens the pool will receive. If this limit is reached, users can not deposit into this pool.
     * @param _APR the APR rate of the pool.
     * @param _lockDuration the duration users need to wait before being able to withdraw and claim the rewards.
     * @param _startJoinTime the time when users can start to join the pool
     * @param _endJoinTime the time when users can no longer join the pool
     */
    function linearAddPool(
        uint128 _cap,
        uint64 _APR,
        uint128 _lockDuration,
        uint128 _startJoinTime,
        uint128 _endJoinTime
    ) external onlyOwner {
        require(
            _endJoinTime >= block.timestamp && _endJoinTime > _startJoinTime,
            "LinearStakingPool: invalid end join time"
        );

        linearPoolInfo.push(
            LinearPoolInfo({
                cap: _cap,
                totalStaked: 0,
                APR: _APR,
                lockDuration: _lockDuration,
                startJoinTime: _startJoinTime,
                endJoinTime: _endJoinTime
            })
        );
        emit LinearPoolCreated(
            linearPoolInfo.length - 1,
            _APR,
            _cap,
            _lockDuration,
            _startJoinTime,
            _endJoinTime
        );
    }

    /**
     * @notice Update the given pool's info. Can only be called by the owner.
     * @param _poolId id of the pool
     * @param _cap the maximum number of staking tokens the pool will receive. If this limit is reached, users can not deposit into this pool.
     * @param _APR the APR rate of the pool.
     * @param _endJoinTime the time when users can no longer join the pool
     */
    function linearSetPool(
        uint128 _poolId,
        uint128 _cap,
        uint64 _APR,
        uint128 _endJoinTime
    ) external onlyOwner linearValidatePoolById(_poolId) {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];

        require(
            _endJoinTime >= block.timestamp &&
                _endJoinTime > pool.startJoinTime,
            "LinearStakingPool: invalid end join time"
        );

        linearPoolInfo[_poolId].cap = _cap;
        linearPoolInfo[_poolId].APR = _APR;
        linearPoolInfo[_poolId].endJoinTime = _endJoinTime;
        emit LinearUpdatePool(_poolId, _APR, _cap, _endJoinTime);
    }

    /**
     * @notice Set the reward distributor. Can only be called by the owner.
     * @param _linearRewardDistributor the reward distributor
     */
    function linearSetRewardDistributor(address _linearRewardDistributor)
        external
        onlyOwner
    {
        require(
            _linearRewardDistributor != address(0),
            "LinearStakingPool: invalid reward distributor"
        );

        emit ChangeRewardDistributor(
            linearRewardDistributor,
            _linearRewardDistributor
        );
        linearRewardDistributor = _linearRewardDistributor;
    }

    /**
     * @notice Deposit token to earn rewards
     * @param _poolId id of the pool
     * @param _amount amount of token to deposit
     */
    function linearDeposit(uint256 _poolId, uint128 _amount)
        external
        nonReentrant
        whenNotPaused
        linearValidatePoolById(_poolId)
    {
        address account = msg.sender;

        _linearDeposit(_poolId, _amount, account);

        linearAcceptedToken.safeTransferFrom(account, address(this), _amount);
        emit LinearDeposit(_poolId, account, _amount);
    }

    /**
     * @notice Deposit token to earn rewards
     * @param _poolId id of the pool
     * @param _amount amount of token to deposit
     * @param _receiver receiver
     */
    function linearDepositSpecifyReceiver(
        uint256 _poolId,
        uint128 _amount,
        address _receiver
    ) external nonReentrant whenNotPaused linearValidatePoolById(_poolId) {
        _linearDeposit(_poolId, _amount, _receiver);

        linearAcceptedToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        emit LinearDeposit(_poolId, _receiver, _amount);
    }

    // /**
    //  * @notice Withdraw token from a pool
    //  * @param _poolId id of the pool
    //  * @param _amount amount to withdraw
    //  */
    // function linearWithdraw(uint256 _poolId, uint128 _amount)
    //     external
    //     nonReentrant
    //     whenNotPaused
    //     linearValidatePoolById(_poolId)
    // {
    //     address account = msg.sender;
    //     LinearPoolInfo storage pool = linearPoolInfo[_poolId];
    //     LinearStakingData storage stakingData = linearStakingData[_poolId][
    //         account
    //     ];

    //     require(
    //         block.timestamp >= stakingData.joinTime + pool.lockDuration,
    //         "LinearStakingPool: still locked"
    //     );

    //     require(
    //         stakingData.balance >= _amount,
    //         "LinearStakingPool: invalid withdraw amount"
    //     );

    //     _linearHarvest(_poolId, account);

    //     if (stakingData.reward > 0) {
    //         require(
    //             linearRewardDistributor != address(0),
    //             "LinearStakingPool: invalid reward distributor"
    //         );

    //         uint128 reward = stakingData.reward;
    //         stakingData.reward = 0;
    //         linearAcceptedToken.safeTransferFrom(
    //             linearRewardDistributor,
    //             account,
    //             reward
    //         );
    //         emit LinearRewardsHarvested(_poolId, account, reward);
    //     }

    //     pool.totalStaked -= _amount;

    //     stakingData.balance -= _amount;
    //     linearAcceptedToken.safeTransfer(account, _amount);

    //     // claim early withdrawal pending rewards
    //     _linearClaimPendingWithdraw(_poolId);
    //     emit LinearWithdraw(_poolId, account, _amount);
    // }

    /**
     * @notice Withdraw token from a pool
     * @param _poolId id of the pool
     */
    function linearWithdrawAll(uint256 _poolId)
        external
        nonReentrant
        whenNotPaused
        linearValidatePoolById(_poolId)
    {
        address account = msg.sender;
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            account
        ];

        require(
            block.timestamp >= stakingData.joinTime + pool.lockDuration,
            "LinearStakingPool: still locked"
        );

        require(
            stakingData.balance >= 0,
            "LinearStakingPool: invalid withdraw amount"
        );

        _linearHarvest(_poolId, account);

        if (stakingData.reward > 0) {
            require(
                linearRewardDistributor != address(0),
                "LinearStakingPool: invalid reward distributor"
            );

            uint128 reward = stakingData.reward;
            stakingData.reward = 0;
            linearAcceptedToken.safeTransferFrom(
                linearRewardDistributor,
                account,
                reward
            );
            emit LinearRewardsHarvested(_poolId, account, reward);
        }

        uint128 withdrawBalance = stakingData.balance;
        pool.totalStaked -= withdrawBalance;
        stakingData.balance = 0;
        linearAcceptedToken.safeTransfer(account, withdrawBalance);

        // claim early withdrawal pending rewards
        _linearClaimPendingWithdraw(_poolId);
        emit LinearWithdraw(_poolId, account, withdrawBalance);
    }

    /**
     * @notice Withdraw token from a pool
     * @param _poolId id of the pool
     */
    function linearWithdrawAllAndBuyNft(
        uint256 _poolId,
        address _buyer,
        uint256 _amount,
        uint256 _count,
        uint256 _deadline,
        bytes memory _signature
    ) external nonReentrant whenNotPaused linearValidatePoolById(_poolId) {
        require(
            block.timestamp <= _deadline,
            "LinearStakingPool: deadline expired"
        );

        address account = msg.sender;
        require(_buyer == account, "LinearStakingPool: invalid buyer");

        require(
            verify(
                signer,
                _poolId,
                _buyer,
                _amount,
                _count,
                _deadline,
                _signature
            ),
            "LinearStakingPool: invalid signature"
        );

        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            account
        ];

        require(
            block.timestamp >= stakingData.joinTime + pool.lockDuration,
            "LinearStakingPool: still locked"
        );

        require(
            stakingData.balance >= 0,
            "LinearStakingPool: invalid withdraw amount"
        );

        require(
            linearRewardDistributor != address(0),
            "LinearStakingPool: invalid reward distributor"
        );

        _linearHarvest(_poolId, account);

        // claim early withdrawal pending rewards
        // _linearClaimPendingWithdraw(_poolId);
        LinearPendingEarlyWithdrawal
            storage pending = linearPendingEarlyWithdrawals[_poolId][account];

        uint128 amount = pending.amount;
        uint128 reward = pending.reward;

        delete linearPendingEarlyWithdrawals[_poolId][account];
        emit LinearClaimPendingWithdraw(_poolId, account, amount);

        if (stakingData.reward > 0) {
            require(
                linearRewardDistributor != address(0),
                "LinearStakingPool: invalid reward distributor"
            );

            reward += stakingData.reward;
            stakingData.reward = 0;

            emit LinearRewardsHarvested(_poolId, account, reward);
        }

        // transfer to contract address to pay nft
        linearAcceptedToken.safeTransferFrom(
            linearRewardDistributor,
            address(this),
            reward
        );

        uint128 withdrawBalance = stakingData.balance;
        pool.totalStaked -= withdrawBalance;
        withdrawBalance += (reward + amount);
        stakingData.balance = 0;

        require(
            withdrawBalance >= _amount,
            "LinearStakingPool: not enought amount to buy nft"
        );

        // transfer to nftTreasury
        linearAcceptedToken.safeTransfer(nftTreasury, _amount);
        // transfer remain amount to user
        linearAcceptedToken.safeTransfer(account, withdrawBalance - _amount);

        emit FundTokenToNftTreasury(account, _amount, _count);
        emit LinearWithdraw(_poolId, account, withdrawBalance);
    }

    // getter function
    function getLinearPendingEarlyWithdrawals(uint256 _poolId, address _user)
        external
        view
        returns (LinearPendingEarlyWithdrawal memory)
    {
        return linearPendingEarlyWithdrawals[_poolId][_user];
    }

    // getter function
    function isWhitelisted(uint256 _poolId, address _user)
        external
        view
        returns (bool)
    {
        return additionalPoolInfo[_poolId].isWhitelisted[_user];
    }

    // getter function
    function penaltyRate(uint256 _poolId, uint16 _percentage)
        external
        view
        returns (uint16)
    {
        return additionalPoolInfo[_poolId].penaltyRate[_percentage];
    }

    function linearSetDelayDuration(uint256 _poolId, uint128 _duration)
        external
        onlyOwner
        linearValidatePoolById(_poolId)
    {
        additionalPoolInfo[_poolId].delayDuration = _duration;
        emit LinearSetDelayDuration(_poolId, _duration);
    }

    function linearSetEarlyWithdrawTier(
        uint256 _poolId,
        uint16 _percentageKey,
        uint16 _percentageValue
    ) external onlyOwner linearValidatePoolById(_poolId) {
        additionalPoolInfo[_poolId].penaltyRate[
            _percentageKey
        ] = _percentageValue;
        additionalPoolInfo[_poolId].isPenaltyEnabled[_percentageKey] = true;

        emit LinearSetEarlyWithdrawTier(
            _poolId,
            _percentageKey,
            _percentageValue
        );
    }

    function linearSetListEarlyWithdrawTier(
        uint256 _poolId,
        uint16[] calldata _percentageKeys,
        uint16[] calldata _percentageValues
    ) external onlyOwner linearValidatePoolById(_poolId) {
        uint256 length = _percentageKeys.length;
        require(
            length == _percentageValues.length,
            "LinearStakingPool: length not match"
        );

        AdditionalPoolInfo storage pool = additionalPoolInfo[_poolId];

        for (uint256 i = 0; i < length; i++) {
            pool.penaltyRate[_percentageKeys[i]] = _percentageValues[i];
            additionalPoolInfo[_poolId].isPenaltyEnabled[
                _percentageKeys[i]
            ] = true;

            emit LinearSetEarlyWithdrawTier(
                _poolId,
                _percentageKeys[i],
                _percentageValues[i]
            );
        }
    }

    function linearAddWhitelist(uint256 _poolId, address _account)
        external
        onlyOwner
        linearValidatePoolById(_poolId)
    {
        if (!additionalPoolInfo[_poolId].isWhitelisted[_account]) {
            additionalPoolInfo[_poolId].isWhitelisted[_account] = true;
        }
        emit LinearAddWhitelist(_poolId, _account);
    }

    function linearRemoveWhitelist(uint256 _poolId, address _account)
        external
        onlyOwner
        linearValidatePoolById(_poolId)
    {
        if (additionalPoolInfo[_poolId].isWhitelisted[_account]) {
            additionalPoolInfo[_poolId].isWhitelisted[_account] = false;
        }
        emit LinearRemoveWhitelist(_poolId, _account);
    }

    function linearAddListWhitelist(
        uint256 _poolId,
        address[] calldata _accounts
    ) external onlyOwner linearValidatePoolById(_poolId) {
        uint256 length = _accounts.length;
        AdditionalPoolInfo storage pool = additionalPoolInfo[_poolId];

        for (uint256 i = 0; i < length; i++) {
            if (!pool.isWhitelisted[_accounts[i]]) {
                pool.isWhitelisted[_accounts[i]] = true;
            }
            emit LinearAddWhitelist(_poolId, _accounts[i]);
        }
    }

    function linearEarlyWithdraw(uint256 _poolId, uint16 _percentage)
        external
        nonReentrant
        whenNotPaused
        linearValidatePoolById(_poolId)
    {
        address account = msg.sender;
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        AdditionalPoolInfo storage poolInfo = additionalPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            account
        ];

        // 1.1. and 1.2. validate
        require(
            poolInfo.isPenaltyEnabled[_percentage] &&
                poolInfo.penaltyRate[_percentage] <= HUNDRED_PERCENT,
            "LinearStakingPool: invalid percentage"
        );
        require(
            poolInfo.isWhitelisted[account],
            "LinearStakingPool: not whitelisted"
        );

        LinearPendingEarlyWithdrawal
            storage pending = linearPendingEarlyWithdrawals[_poolId][account];

        uint128 amount = (_percentage * stakingData.balance) / HUNDRED_PERCENT;
        uint128 penaltyFee = (amount * poolInfo.penaltyRate[_percentage]) /
            HUNDRED_PERCENT;

        // 1.3. calculate new pending reward
        _linearHarvest(_poolId, account);

        uint128 reward;
        uint128 totalReward = stakingData.reward;
        if (totalReward > 0) {
            // claimable reward (cal by _percenteage)
            // update user reward, send % to delay reward
            reward = (_percentage * totalReward) / HUNDRED_PERCENT;

            stakingData.reward = totalReward - reward;
        }

        // penalty only for withdraw amount, not for reward
        pending.amount += (amount - penaltyFee);
        pending.reward += reward;
        stakingData.balance -= amount;
        pending.applicableAt =
            block.timestamp.toUint128() +
            poolInfo.delayDuration;

        pool.totalStaked -= amount;

        // emit event
        emit LinearEarlyWithdraw(_poolId, account, amount, reward, penaltyFee);

        // remove user from whitelist
        delete poolInfo.isWhitelisted[account];

        IERC20(linearAcceptedToken).safeTransfer(treasury, penaltyFee);
    }

    /**
     * @notice Claim pending withdrawal
     * @param _poolId id of the pool
     */
    function linearClaimPendingWithdraw(uint256 _poolId)
        external
        nonReentrant
        linearValidatePoolById(_poolId)
    {
        _linearClaimPendingWithdraw(_poolId);
    }

    /**
     * @notice Claim pending withdrawal
     * @param _poolId id of the pool
     */
    function linearClaimPendingWithdrawAndBuyNft(
        uint256 _poolId,
        address _buyer,
        uint256 _amount,
        uint256 _count,
        uint256 _deadline,
        bytes memory _signature
    ) external nonReentrant linearValidatePoolById(_poolId) {
        require(
            block.timestamp <= _deadline,
            "LinearStakingPool: deadline expired"
        );

        address account = msg.sender;
        require(_buyer == account, "LinearStakingPool: invalid buyer");

        require(
            verify(
                signer,
                _poolId,
                _buyer,
                _amount,
                _count,
                _deadline,
                _signature
            ),
            "LinearStakingPool: invalid signature"
        );

        require(
            linearRewardDistributor != address(0),
            "LinearStakingPool: invalid reward distributor"
        );
        LinearPendingEarlyWithdrawal
            storage pending = linearPendingEarlyWithdrawals[_poolId][account];

        uint128 amount = pending.amount;
        uint128 reward = pending.reward;

        if (amount == 0 && reward == 0) return;
        require(
            (pending.applicableAt <= block.timestamp) ||
                (block.timestamp >=
                    linearStakingData[_poolId][account].joinTime +
                        linearPoolInfo[_poolId].lockDuration),
            "LinearStakingPool: not released yet"
        );
        delete linearPendingEarlyWithdrawals[_poolId][account];

        linearAcceptedToken.safeTransferFrom(
            linearRewardDistributor,
            address(this),
            reward
        );

        amount += reward;
        require(
            amount >= _amount,
            "LinearStakingPool: not enought amount to buy nft"
        );

        // transfer to nftTreasury
        linearAcceptedToken.safeTransfer(nftTreasury, _amount);
        // transfer remain amount to user
        linearAcceptedToken.safeTransfer(account, amount - _amount);

        emit FundTokenToNftTreasury(account, _amount, _count);
        emit LinearClaimPendingWithdraw(_poolId, account, amount);
    }

    /**
     * @notice Claim reward token from a pool
     * @param _poolId id of the pool
     */
    function linearClaimReward(uint256 _poolId)
        external
        nonReentrant
        whenNotPaused
        linearValidatePoolById(_poolId)
    {
        address account = msg.sender;
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            account
        ];
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];

        require(
            block.timestamp >= stakingData.joinTime + pool.lockDuration,
            "LinearStakingPool: still locked"
        );

        _linearHarvest(_poolId, account);

        if (stakingData.reward > 0) {
            require(
                linearRewardDistributor != address(0),
                "LinearStakingPool: invalid reward distributor"
            );
            uint128 reward = stakingData.reward;
            stakingData.reward = 0;
            linearAcceptedToken.safeTransferFrom(
                linearRewardDistributor,
                account,
                reward
            );
            emit LinearRewardsHarvested(_poolId, account, reward);
        }
    }

    /**
     * @notice Gets number of reward tokens of a user from a pool
     * @param _poolId id of the pool
     * @param _account address of a user
     * @return reward earned reward of a user
     */
    function linearPendingReward(uint256 _poolId, address _account)
        public
        view
        linearValidatePoolById(_poolId)
        returns (uint128 reward)
    {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            _account
        ];

        uint128 startTime = stakingData.updatedTime > 0
            ? stakingData.updatedTime
            : block.timestamp.toUint128();

        uint128 endTime = block.timestamp.toUint128();
        if (
            pool.lockDuration > 0 &&
            stakingData.joinTime + pool.lockDuration < block.timestamp
        ) {
            endTime = stakingData.joinTime + pool.lockDuration;
        }

        uint128 stakedTimeInSeconds = endTime > startTime
            ? endTime - startTime
            : 0;

        if (stakedTimeInSeconds > pool.lockDuration)
            stakedTimeInSeconds = pool.lockDuration;

        uint128 pendingReward = ((stakingData.balance *
            stakedTimeInSeconds *
            pool.APR) / ONE_YEAR_IN_SECONDS) / 100;

        reward = stakingData.reward + pendingReward;
    }

    /**
     * @notice Gets number of deposited tokens in a pool
     * @param _poolId id of the pool
     * @param _account address of a user
     * @return total token deposited in a pool by a user
     */
    function linearBalanceOf(uint256 _poolId, address _account)
        external
        view
        linearValidatePoolById(_poolId)
        returns (uint128)
    {
        return linearStakingData[_poolId][_account].balance;
    }

    /**
     * @notice Gets number of deposited tokens in a pool
     * @param _poolId id of the pool
     * @param _account address of a user
     * @return total token deposited in a pool by a user
     */
    function linearUserStakingData(uint256 _poolId, address _account)
        external
        view
        linearValidatePoolById(_poolId)
        returns (LinearStakingData memory)
    {
        return linearStakingData[_poolId][_account];
    }

    function linearUserTotalStaked(address _account)
        external
        view
        returns (uint256)
    {
        uint256 total = 0;

        uint256 poolLength = linearPoolInfo.length;
        for (uint256 i = 0; i < poolLength; i++) {
            total += linearStakingData[i][_account].balance;
        }

        return total;
    }

    /**
     * @notice Update allowance for emergency withdraw
     * @param _shouldAllow should allow emergency withdraw or not
     */
    function linearSetAllowEmergencyWithdraw(bool _shouldAllow)
        external
        onlyOwner
    {
        linearAllowEmergencyWithdraw = _shouldAllow;
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _poolId id of the pool
     */
    function linearEmergencyWithdraw(uint256 _poolId)
        external
        nonReentrant
        whenNotPaused
        linearValidatePoolById(_poolId)
    {
        require(
            linearAllowEmergencyWithdraw,
            "LinearStakingPool: emergency withdrawal is not allowed yet"
        );

        address account = msg.sender;
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            account
        ];

        require(
            stakingData.balance > 0,
            "LinearStakingPool: nothing to withdraw"
        );

        uint128 amount = stakingData.balance;

        stakingData.balance = 0;
        stakingData.reward = 0;
        stakingData.updatedTime = block.timestamp.toUint128();

        linearAcceptedToken.safeTransfer(account, amount);
        emit LinearEmergencyWithdraw(_poolId, account, amount);
    }

    function _linearDeposit(
        uint256 _poolId,
        uint128 _amount,
        address account
    ) internal {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            account
        ];

        require(
            block.timestamp >= pool.startJoinTime,
            "LinearStakingPool: pool is not started yet"
        );

        require(
            block.timestamp <= pool.endJoinTime,
            "LinearStakingPool: pool is already closed"
        );

        if (pool.cap > 0) {
            require(
                pool.totalStaked + _amount <= pool.cap,
                "LinearStakingPool: pool is full"
            );
        }

        _linearHarvest(_poolId, account);

        stakingData.balance += _amount;
        stakingData.joinTime = block.timestamp.toUint128();

        pool.totalStaked += _amount;
    }

    function _linearHarvest(uint256 _poolId, address _account) private {
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            _account
        ];

        stakingData.reward = linearPendingReward(_poolId, _account);
        stakingData.updatedTime = block.timestamp.toUint128();
    }

    function _linearClaimPendingWithdraw(uint256 _poolId) private {
        require(
            linearRewardDistributor != address(0),
            "LinearStakingPool: invalid reward distributor"
        );
        address account = msg.sender;
        LinearPendingEarlyWithdrawal
            storage pending = linearPendingEarlyWithdrawals[_poolId][account];

        uint128 amount = pending.amount;
        uint128 reward = pending.reward;

        if (amount == 0 && reward == 0) return;
        require(
            (pending.applicableAt <= block.timestamp) ||
                (block.timestamp >=
                    linearStakingData[_poolId][account].joinTime +
                        linearPoolInfo[_poolId].lockDuration),
            "LinearStakingPool: not released yet"
        );
        delete linearPendingEarlyWithdrawals[_poolId][account];
        linearAcceptedToken.safeTransfer(account, amount);
        linearAcceptedToken.safeTransferFrom(
            linearRewardDistributor,
            account,
            reward
        );
        emit LinearClaimPendingWithdraw(_poolId, account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Signature Verification
/// @title RedKite Whitelists - Implement off-chain whitelist and on-chain verification
/// @author CuongTran <[email protected]>

contract LinearPoolSignature {
    // Using Openzeppelin ECDSA cryptography library
    function getMessageHash(
        uint256 _poolId,
        address _buyer,
        uint256 _amount,
        uint256 _count,
        uint256 _deadline
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_poolId, _buyer, _amount, _count, _deadline));
    }

    // Verify signature function
    function verify(
        address _signer,
        uint256 _poolId,
        address _buyer,
        uint256 _amount,
        uint256 _count,
        uint256 _deadline,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _poolId,
            _buyer,
            _amount,
            _count,
            _deadline
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return getSignerAddress(ethSignedMessageHash, _signature) == _signer;
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature)
        public
        pure
        returns (address signer)
    {
        return ECDSA.recover(_messageHash, _signature);
    }

    // Split signature to r, s, v
    function splitSignature(bytes memory _signature)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }
}