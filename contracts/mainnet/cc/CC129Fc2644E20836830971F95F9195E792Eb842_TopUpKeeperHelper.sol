/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.6.1 https://hardhat.org

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


// File interfaces/actions/IAction.sol

pragma solidity 0.8.10;

interface IAction {
    event UsableTokenAdded(address token);
    event UsableTokenRemoved(address token);
    event Paused();
    event Unpaused();
    event Shutdown();

    function addUsableToken(address token) external;

    function removeUsableToken(address token) external;

    function updateActionFee(uint256 actionFee) external;

    function updateFeeHandler(address feeHandler) external;

    function shutdownAction() external;

    function pause() external;

    function unpause() external;

    function getEthRequiredForGas(address payer) external view returns (uint256);

    function getUsableTokens() external view returns (address[] memory);

    function isUsable(address token) external view returns (bool);

    function feeHandler() external view returns (address);

    function isShutdown() external view returns (bool);

    function isPaused() external view returns (bool);
}


// File interfaces/actions/topup/ITopUpAction.sol

pragma solidity 0.8.10;

interface ITopUpAction is IAction {
    struct RecordKey {
        address payer;
        bytes32 account;
        bytes32 protocol;
    }

    struct RecordMeta {
        bytes32 account;
        bytes32 protocol;
    }

    struct Record {
        uint64 threshold;
        uint64 priorityFee;
        uint64 maxFee;
        uint64 registeredAt;
        address actionToken;
        address depositToken;
        uint128 singleTopUpAmount; // denominated in action token
        uint128 totalTopUpAmount; // denominated in action token
        uint128 depositTokenBalance;
        bytes extra;
    }

    struct RecordWithMeta {
        bytes32 account;
        bytes32 protocol;
        Record record;
    }

    event Register(
        bytes32 indexed account,
        bytes32 indexed protocol,
        uint256 indexed threshold,
        address payer,
        address depositToken,
        uint256 depositAmount,
        address actionToken,
        uint256 singleTopUpAmount,
        uint256 totalTopUpAmount,
        uint256 maxGasPrice,
        bytes extra
    );

    event Deregister(address indexed payer, bytes32 indexed account, bytes32 indexed protocol);

    event TopUp(
        bytes32 indexed account,
        bytes32 indexed protocol,
        address indexed payer,
        address depositToken,
        uint256 consumedDepositAmount,
        address actionToken,
        uint256 topupAmount
    );

    function register(
        bytes32 account,
        bytes32 protocol,
        uint128 depositAmount,
        Record memory record
    ) external payable;

    function execute(
        address payer,
        bytes32 account,
        address keeper,
        bytes32 protocol
    ) external;

    function execute(
        address payer,
        bytes32 account,
        address keeper,
        bytes32 protocol,
        uint256 maxWeiForGas
    ) external;

    function resetPosition(
        bytes32 account,
        bytes32 protocol,
        bool unstake
    ) external;

    function getSupportedProtocols() external view returns (bytes32[] memory);

    function getPosition(
        address payer,
        bytes32 account,
        bytes32 protocol
    ) external view returns (Record memory);

    function getUserPositions(address payer) external view returns (RecordMeta[] memory);

    function getHandler(bytes32 protocol) external view returns (address);

    function usersWithPositions(uint256 cursor, uint256 howMany)
        external
        view
        returns (address[] memory users, uint256 nextCursor);

    function getHealthFactor(
        bytes32 protocol,
        bytes32 account,
        bytes memory extra
    ) external view returns (uint256);

    function getTopUpHandler(bytes32 protocol) external view returns (address);

    function updateTopUpHandler(bytes32 protocol, address newHandler) external;

    function updateEstimatedGasUsage(uint256 gasUsage) external;
}


// File interfaces/actions/topup/ITopUpKeeperHelper.sol

pragma solidity 0.8.10;

interface ITopUpKeeperHelper {
    struct TopupData {
        address payer;
        bytes32 account;
        bytes32 protocol;
        ITopUpAction.Record record;
    }

    function listPositions(address payer)
        external
        view
        returns (ITopUpAction.RecordWithMeta[] memory);

    function getExecutableTopups(uint256 cursor, uint256 howMany)
        external
        returns (TopupData[] memory topups, uint256 nextCursor);

    function canExecute(ITopUpAction.RecordKey calldata key) external view returns (bool);

    function batchCanExecute(ITopUpAction.RecordKey[] calldata keys)
        external
        returns (bool[] memory);
}


// File interfaces/actions/topup/ITopUpHandler.sol

pragma solidity 0.8.10;

/**
 * This interface should be implemented by protocols integrating with Mero
 * that require topping up a registered position
 */
interface ITopUpHandler {
    /**
     * @notice Tops up the account for the protocol associated with this handler
     * This is designed to be called using delegatecall and should therefore
     * not assume that storage will be available
     *
     * @param account account to be topped up
     * @param underlying underlying currency to be used for top up
     * @param amount amount to be topped up
     * @param extra arbitrary data that can be passed to the handler
     */
    function topUp(
        bytes32 account,
        address underlying,
        uint256 amount,
        bytes memory extra
    ) external payable;

    /**
     * @notice Returns a factor for the user which should always be >= 1 for sufficiently
     *         colletaralized positions and should get closer to 1 when collateralization level decreases
     * This should be an aggregate value including all the collateral of the user
     * @param account account for which to get the factor
     */
    function getUserFactor(bytes32 account, bytes memory extra) external view returns (uint256);
}


// File libraries/UncheckedMath.sol

pragma solidity 0.8.10;

library UncheckedMath {
    function uncheckedInc(uint256 a) internal pure returns (uint256) {
        unchecked {
            return a + 1;
        }
    }

    function uncheckedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }

    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a / b;
        }
    }
}


// File contracts/actions/topup/TopUpKeeperHelper.sol

pragma solidity 0.8.10;




/**
 * This TopUp Keeper Helper.
 * It is a utility contract to help create Mero TopUp Keepers.
 * It exposes a view that allows the user to query a list of TopUp Positions that can be executed.
 */
contract TopUpKeeperHelper is ITopUpKeeperHelper {
    using UncheckedMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    ITopUpAction private immutable _topupAction;

    constructor(address topupAction_) {
        _topupAction = ITopUpAction(topupAction_);
    }

    /**
     * @notice Gets a list of topup positions that can be executed.
     * @dev Uses cursor pagination.
     * @param cursor The cursor for pagination (should start at 0 for first call).
     * @param howMany Maximum number of topups to return in this pagination request.
     * @return topups List of topup positions that can be executed.
     * @return nextCursor The cursor to use for the next pagination request.
     */
    function getExecutableTopups(uint256 cursor, uint256 howMany)
        external
        view
        override
        returns (TopupData[] memory topups, uint256 nextCursor)
    {
        TopupData[] memory executableTopups = new TopupData[](howMany);
        uint256 topupsAdded;
        while (true) {
            (address[] memory users, ) = _topupAction.usersWithPositions(cursor, howMany);
            if (users.length == 0) return (_shortenTopups(executableTopups, topupsAdded), 0);
            for (uint256 i; i < users.length; i = i.uncheckedInc()) {
                address user = users[i];
                ITopUpAction.RecordWithMeta[] memory positions = listPositions(user);
                for (uint256 j; j < positions.length; j = j.uncheckedInc()) {
                    ITopUpAction.RecordWithMeta memory position = positions[j];
                    if (!_canExecute(user, position)) continue;
                    executableTopups[topupsAdded] = _positionToTopup(user, position);
                    topupsAdded = topupsAdded.uncheckedInc();
                    uint256 offset = j == positions.length - 1 ? 1 : 0;
                    if (topupsAdded == howMany) return (executableTopups, cursor + i + offset);
                }
            }
            cursor += howMany;
        }
    }

    /**
     * @notice Check if the action can be executed for the positions
     * of the given `keys`
     * @param keys Unique keys to check for
     * @return an array of boolean containing a result per input
     */
    function batchCanExecute(ITopUpAction.RecordKey[] calldata keys)
        external
        view
        override
        returns (bool[] memory)
    {
        bool[] memory results = new bool[](keys.length);
        for (uint256 i; i < keys.length; i = i.uncheckedInc()) {
            ITopUpAction.RecordKey calldata key = keys[i];
            results[i] = canExecute(key);
        }
        return results;
    }

    /**
     * @notice Get a list of all positions the `payer` has registered.
     * @param payer Address to list position for.
     * @return Records of all registered positions.
     */
    function listPositions(address payer)
        public
        view
        override
        returns (ITopUpAction.RecordWithMeta[] memory)
    {
        ITopUpAction.RecordMeta[] memory userRecordsMeta = _topupAction.getUserPositions(payer);
        uint256 length = userRecordsMeta.length;
        ITopUpAction.RecordWithMeta[] memory result = new ITopUpAction.RecordWithMeta[](length);
        for (uint256 i; i < length; i = i.uncheckedInc()) {
            bytes32 account = userRecordsMeta[i].account;
            bytes32 protocol = userRecordsMeta[i].protocol;
            ITopUpAction.Record memory record = _topupAction.getPosition(payer, account, protocol);
            result[i] = ITopUpAction.RecordWithMeta(account, protocol, record);
        }
        return result;
    }

    /**
     * @notice Check if action can be executed.
     * @param key Unique key of the account to check for
     * the key contains information about the payer, the account and the protocol
     * @return `true` if action can be executed, else `false`.
     */
    function canExecute(ITopUpAction.RecordKey memory key) public view override returns (bool) {
        ITopUpAction.Record memory position = _topupAction.getPosition(
            key.payer,
            key.account,
            key.protocol
        );
        if (position.threshold == 0 || position.totalTopUpAmount == 0) {
            return false;
        }
        uint256 healthFactor = _topupAction.getHealthFactor(
            key.protocol,
            key.account,
            position.extra
        );
        return healthFactor < position.threshold;
    }

    /**
     * @dev Returns if a position can be executed.
     * @param user The user paying for the position.
     * @param position The position record with metadata.
     * @return 'true' if it can be executed, 'false' if not.
     */
    function _canExecute(address user, ITopUpAction.RecordWithMeta memory position)
        private
        view
        returns (bool)
    {
        return canExecute(ITopUpAction.RecordKey(user, position.account, position.protocol));
    }

    /**
     * @dev Converts from RecordWithMeta struct to TopupData struct.
     * @param user The user paying for the position.
     * @param position The position record with metadata.
     * @return The topup positions as a TopupData struct.
     */
    function _positionToTopup(address user, ITopUpAction.RecordWithMeta memory position)
        private
        pure
        returns (TopupData memory)
    {
        return TopupData(user, position.account, position.protocol, position.record);
    }

    /**
     * @dev Shortens a list of topups by truncating it to a given length.
     * @param topups The list of topups to shorten.
     * @param length The length to truncate the list of topups to.
     * @return The shortened list of topups.
     */
    function _shortenTopups(TopupData[] memory topups, uint256 length)
        private
        pure
        returns (TopupData[] memory)
    {
        TopupData[] memory shortened = new TopupData[](length);
        for (uint256 i; i < length; i = i.uncheckedInc()) {
            shortened[i] = topups[i];
        }
        return shortened;
    }
}