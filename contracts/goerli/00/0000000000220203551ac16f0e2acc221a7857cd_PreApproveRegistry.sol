// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EnumerableAddressSetMap.sol";

/**
 * @title PreApproveRegistry
 * @notice A on-chain registry where listers can create lists
 *         of pre-approved operators, which NFT collectors can subscribe to.
 *         When a collector is subscribed to a list by a lister,
 *         they can use pre-approved operators to manage their NFTs
 *         if the NFT contracts consult this registry on whether the operator
 *         is in the pre-approved list by lister.
 *
 *         For safety, newly added operators will need to wait some time
 *         before they take effect.
 */
contract PreApproveRegistry {
    using EnumerableAddressSetMap for *;

    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when `collector` subscribes to `lister`.
     * @param collector The NFT collector using the registry.
     * @param lister    The maintainer of the pre-approve list.
     */
    event Subscribed(address indexed collector, address indexed lister);

    /**
     * @dev Emitted when `collector` unsubscribes from `lister`.
     * @param collector The NFT collector using the registry.
     * @param lister    The maintainer of the pre-approve list.
     */
    event Unsubscribed(address indexed collector, address indexed lister);

    /**
     * @dev Emitted when `lister` adds `operator` to their pre-approve list.
     * @param lister    The maintainer of the pre-approve list.
     * @param operator  The account that can manage NFTs on behalf of
     *                  collectors subscribed to `lister`.
     * @param startTime The Unix timestamp when the `operator` can begin to manage
     *                  NFTs on on behalf of collectors subscribed to `lister`.
     */
    event OperatorAdded(
        address indexed lister, address indexed operator, uint256 indexed startTime
    );

    /**
     * @dev Emitted when `lister` removes `operator` from their pre-approve list.
     * The `operator` will be immediately removed from the list.
     * @param lister    The maintainer of the pre-approve list.
     * @param operator  The account that can manage NFTs on behalf of
     *                  collectors subscribed to `lister`.
     */
    event OperatorRemoved(address indexed lister, address indexed operator);

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /**
     * @dev The amount of time before a newly added `operator` becomes effective.
     */
    uint256 public constant START_DELAY = 86400 * 7;

    // =============================================================
    //                            STORAGE
    // =============================================================

    /**
     * @dev Mapping of `collector => EnumerableSet.AddressSet(lister => exists)`.
     */
    EnumerableAddressSetMap.Map internal _subscriptions;

    /**
     * @dev Mapping of `lister => EnumerableSet.AddressSet(operator => exists)`.
     */
    EnumerableAddressSetMap.Map internal _operators;

    /**
     * @dev For extra efficiency, we use our own custom mapping for the mapping of
     * (`lister`, `operator`) => `startTime`.
     * If `startTime` is zero, it is disabled.
     * Note: It is not possible for any added `operator` to have a `startTime` of zero,
     * since we are already past the Unix epoch.
     */
    uint256 internal _startTimes;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor() payable {}

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Subscribes the caller (collector) from `lister`.
     * @param lister The maintainer of the pre-approve list.
     */
    function subscribe(address lister) external payable {
        _subscriptions.add(msg.sender, lister);
        emit Subscribed(msg.sender, lister);
    }

    /**
     * @dev Unsubscribes the caller (collector) from `lister`.
     * @param lister The maintainer of the pre-approve list.
     */
    function unsubscribe(address lister) external payable {
        _subscriptions.remove(msg.sender, lister);
        emit Unsubscribed(msg.sender, lister);
    }

    /**
     * @dev Adds the `operator` to the pre-approve list maintained by the caller (lister).
     * @param operator The account that can manage NFTs on behalf of
     *                 collectors subscribed to the caller.
     */
    function addOperator(address operator) external payable {
        _operators.add(msg.sender, operator);
        uint256 begins;
        /// @solidity memory-safe-assembly
        assembly {
            begins := add(timestamp(), START_DELAY)
            // The sequence of overlays automatically cleans the upper bits of `operator`.
            // Equivalent to:
            // `_startTimes[lister][operator] = begins`.
            mstore(0x20, operator)
            mstore(0x0c, _startTimes.slot)
            mstore(returndatasize(), caller())
            sstore(keccak256(0x0c, 0x34), begins)
        }
        emit OperatorAdded(msg.sender, operator, begins);
    }

    /**
     * @dev Removes the `operator` from the pre-approve list maintained by the caller (lister).
     * @param operator The account that can manage NFTs on behalf of
     *                 collectors subscribed to the caller.
     */
    function removeOperator(address operator) external payable {
        _operators.remove(msg.sender, operator);
        /// @solidity memory-safe-assembly
        assembly {
            // The sequence of overlays automatically cleans the upper bits of `operator`.
            // Equivalent to:
            // `_startTimes[lister][operator] = 0`.
            mstore(0x20, operator)
            mstore(0x0c, _startTimes.slot)
            mstore(returndatasize(), caller())
            sstore(keccak256(0x0c, 0x34), returndatasize())
        }
        emit OperatorRemoved(msg.sender, operator);
    }

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Returns whether `collector` is subscribed to `lister`.
     * @param collector The NFT collector using the registry.
     * @param lister    The maintainer of the pre-approve list.
     * @return has Whether the `collector` is subscribed.
     */
    function hasSubscription(address collector, address lister) external view returns (bool has) {
        has = _subscriptions.contains(collector, lister);
    }

    /**
     * @dev Returns an array of all the listers which `collector` is subscribed to.
     * @param collector The NFT collector using the registry.
     * @return list The list of listers.
     */
    function subscriptions(address collector) external view returns (address[] memory list) {
        list = _subscriptions.values(collector);
    }

    /**
     * @dev Returns the total number of listers `collector` is subscribed to.
     * @param collector The NFT collector using the registry.
     * @return total The length of the list of listers subscribed by `collector`.
     */
    function totalSubscriptions(address collector) external view returns (uint256 total) {
        total = _subscriptions.length(collector);
    }

    /**
     * @dev Returns the `lister` which `collector` is subscribed to at `index`.
     * @param collector The NFT collector using the registry.
     * @param index     The index of the enumerable set.
     * @return lister The mainter of the pre-approve list.
     */
    function subscriptionAt(address collector, uint256 index)
        external
        view
        returns (address lister)
    {
        lister = _subscriptions.at(collector, index);
    }

    /**
     * @dev Returns the list of operators in the pre-approve list by `lister`.
     * @param lister The maintainer of the pre-approve list.
     * @return list  The list of operators.
     */
    function operators(address lister) external view returns (address[] memory list) {
        list = _operators.values(lister);
    }

    /**
     * @dev Returns the list of operators in the pre-approve list by `lister`.
     * @param lister The maintainer of the pre-approve list.
     * @return total The length of the list of operators.
     */
    function totalOperators(address lister) external view returns (uint256 total) {
        total = _operators.length(lister);
    }

    /**
     * @dev Returns the operator at `index` of the pre-approve list by `lister`.
     * @param lister The maintainer of the pre-approve list.
     * @param index  The index of the list.
     * @param operator The account that can manage NFTs on behalf of
     *                 collectors subscribed to `lister`.
     */
    function operatorAt(address lister, uint256 index)
        external
        view
        returns (address operator, uint256 begins)
    {
        operator = _operators.at(lister, index);
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to:
            // `begins = _startTimes[lister][operator]`.
            mstore(0x20, operator)
            mstore(0x0c, _startTimes.slot)
            mstore(returndatasize(), lister)
            begins := sload(keccak256(0x0c, 0x34))
        }
    }

    /**
     * @dev Returns the Unix timestamp when `operator` is able to start managing
     *      the NFTs of collectors subscribed to `lister`.
     * @param lister   The maintainer of the pre-approve list.
     * @param operator The account that can manage NFTs on behalf of
     *                 collectors subscribed to `lister`.
     * @return begins The Unix timestamp.
     */
    function startTime(address lister, address operator) external view returns (uint256 begins) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to:
            // `begins = _startTimes[lister][operator]`.
            mstore(0x20, operator)
            mstore(0x0c, _startTimes.slot)
            mstore(returndatasize(), lister)
            begins := sload(keccak256(0x0c, 0x34))
        }
    }

    /**
     * @dev Returns whether the `operator` can manage NFTs on the behalf
     *      of `collector` if `collector` is subscribed to `lister`.
     * @param operator  The account that can manage NFTs on behalf of
     *                  collectors subscribed to `lister`.
     * @param collector The NFT collector using the registry.
     * @param lister    The maintainer of the pre-approve list.
     * @return Whether `operator` is effectively pre-approved.
     */
    function isPreApproved(address operator, address collector, address lister)
        external
        view
        returns (bool)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to:
            // `if (!_subscriptions.contains(collector, lister)) returns false;`.
            mstore(0x20, lister)
            mstore(0x0c, returndatasize())
            mstore(returndatasize(), collector)
            if iszero(sload(keccak256(0x0c, 0x34))) { return(0x60, 0x20) }

            // Equivalent to:
            // `return _startTimes[lister][operator] != 0 &&
            //         _startTimes[lister][operator] >= block.timestamp`.
            mstore(0x20, operator)
            mstore(0x0c, _startTimes.slot)
            mstore(returndatasize(), lister)
            let begins := sload(keccak256(0x0c, 0x34))
            mstore(returndatasize(), iszero(or(iszero(begins), lt(timestamp(), begins))))
            return(returndatasize(), 0x20)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title PreApproveRegistry
 * @notice This library enumlates a `mapping(address => EnumerableSet.AddressSet())`.
 *         For gas savings, we shall use `returndatasize()` as a replacement for 0.
 *         Modified from OpenZeppelin's EnumerableSet (MIT Licensed).
 *         https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol
 */
library EnumerableAddressSetMap {
    // =============================================================
    //                            STRUCTS
    // =============================================================

    /**
     * @dev A storage mapping of enumerable address sets.
     */
    struct Map {
        // Mapping of keys to the values of the enumerable address sets.
        mapping(address => address[]) _values;
    }

    // =============================================================
    //                        WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Adds `value` into the enumerable address set at `key` to `map`.
     *      Does not revert if the `value` exists.
     * @param map   The mapping of enumerable address sets.
     * @param key   The key into the mapping.
     * @param value The value to add.
     */
    function add(Map storage map, address key, address value) internal {
        if (!contains(map, key, value)) {
            address[] storage currValues = map._values[key];
            currValues.push(value);

            uint256 n = currValues.length;

            /// @solidity memory-safe-assembly
            assembly {
                // The value is stored at length-1, but we add 1 to all indexes
                // and use 0 as a sentinel value.
                // Equivalent to:
                // `_indexes[key][value] = n`.
                mstore(0x20, value)
                mstore(0x0c, map.slot)
                mstore(returndatasize(), key)
                sstore(keccak256(0x0c, 0x34), n)
            }
        }
    }

    /**
     * @dev Removes `value` into the enumerable address set at `key` to `map`.
     *      Does not revert if the `value` does not exist.
     * @param map   The mapping of enumerable address sets.
     * @param key   The key into the mapping.
     * @param value The value to remove.
     */
    function remove(Map storage map, address key, address value) internal {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex;
        uint256 valueSlot;
        /// @solidity memory-safe-assembly
        assembly {
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value.
            // Equivalent to:
            // `valueIndex = _indexes[key][value]`.
            mstore(0x20, value)
            mstore(0x0c, map.slot)
            mstore(returndatasize(), key)
            valueSlot := keccak256(0x0c, 0x34)
            valueIndex := sload(valueSlot)
        }

        if (valueIndex != 0) {
            // Equivalent to contains(map, value)
            // To delete an element from the _values array in O(1),
            // we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.
            unchecked {
                address[] storage currValues = map._values[key];
                uint256 lastIndex = currValues.length - 1;
                uint256 toDeleteIndex = valueIndex - 1;

                if (lastIndex != toDeleteIndex) {
                    address lastValue = currValues[lastIndex];

                    // Move the last value to the index where the value to delete is.
                    currValues[toDeleteIndex] = lastValue;

                    /// @solidity memory-safe-assembly
                    assembly {
                        // Update the index for the moved value.
                        // Equivalent to:
                        // `_indexes[key][lastValue] = valueIndex`.
                        mstore(0x20, lastValue)
                        mstore(0x0c, map.slot)
                        mstore(returndatasize(), key)
                        // Replace lastValue's index to valueIndex
                        sstore(keccak256(0x0c, 0x34), valueIndex)
                    }
                }
                // Delete the slot where the moved value was stored
                currValues.pop();

                /// @solidity memory-safe-assembly
                assembly {
                    // Delete the index for the deleted slot
                    // Equivalent to:
                    // `_indexes[key][value] = 0`.
                    sstore(valueSlot, 0)
                }
            }
        }
    }

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Returns whether `value` is in the enumerable address set
     *      at `key` in `map`.
     * @param map   The mapping of enumerable address sets.
     * @param key   The key into the mapping.
     * @param value The value to check.
     * @return result The result.
     */
    function contains(Map storage map, address key, address value)
        internal
        view
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value.
            // Equivalent to:
            // `result = _indexes[key][lastValue] != 0`.
            mstore(0x20, value)
            mstore(0x0c, map.slot)
            mstore(returndatasize(), key)
            result := iszero(iszero(sload(keccak256(0x0c, 0x34))))
        }
    }

    /**
     * @dev Returns the length of the enumerable address set
     *      at `key` in `map`.
     * @param map The mapping of enumerable address sets.
     * @param key The key into the mapping.
     * @return The length.
     */
    function length(Map storage map, address key) internal view returns (uint256) {
        return map._values[key].length;
    }

    /**
     * @dev Returns the value at `index` of the enumerable address set
     *      at `key` in `map`.
     * @param map   The mapping of enumerable address sets.
     * @param key   The key into the mapping.
     * @param index The index of the enumerable address set.
     * @return The value.
     */
    function at(Map storage map, address key, uint256 index) internal view returns (address) {
        return map._values[key][index];
    }

    /**
     * @dev Returns all the values of the enumerable address set
     *      at `key` in `map`.
     * @param map The mapping of enumerable address sets.
     * @param key The key into the mapping.
     * @return The values.
     */
    function values(Map storage map, address key) internal view returns (address[] memory) {
        return map._values[key];
    }
}