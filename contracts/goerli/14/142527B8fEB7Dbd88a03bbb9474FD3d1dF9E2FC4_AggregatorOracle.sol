/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/aggregator/AggregatorOracle.sol
// SPDX-License-Identifier: MIT AND Apache-2.0 AND Unlicensed
pragma solidity >=0.8.0 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

/* pragma solidity ^0.8.0; */

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

////// src/aggregator/IAggregatorOracle.sol
/* pragma solidity ^0.8.0; */

interface IAggregatorOracle {
    function oracleExists(address oracle) external view returns (bool);

    function oracleAdd(address oracle) external;

    function oracleRemove(address oracle) external;

    function oracleCount() external view returns (uint256);

    function oracleAt(uint256 index) external view returns (address);
}

////// src/guarded/Guarded.sol
/* pragma solidity ^0.8.0; */

/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant ANY_SIG = keccak256("ANY_SIG");

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _canCall[ANY_SIG][msg.sender] = true;
        emit AllowCaller(ANY_SIG, msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (canCall(ANY_SIG, msg.sender)) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) external callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) external callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who]);
    }
}

////// src/oracle/IOracle.sol
/* pragma solidity ^0.8.0; */

interface IOracle {
    function value() external view returns (int256, bool);

    function update() external;
}

////// src/pausable/Pausable.sol
/* pragma solidity ^0.8.0; */

/// @notice Emitted when paused
error Pausable__whenNotPaused_paused();

/// @notice Emitted when not paused
error Pausable__whenPaused_notPaused();

/* import {Guarded} from "src/guarded/Guarded.sol"; */

contract Pausable is Guarded {
    event Paused(address who);
    event Unpaused(address who);

    bool private _paused;

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        // If the contract is paused, throw an error
        if (_paused) {
            revert Pausable__whenNotPaused_paused();
        }
        _;
    }

    modifier whenPaused() {
        // If the contract is not paused, throw an error
        if (_paused == false) {
            revert Pausable__whenPaused_notPaused();
        }
        _;
    }

    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

////// src/aggregator/AggregatorOracle.sol
/* pragma solidity ^0.8.0; */

/* import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; */

/* import {Guarded} from "src/guarded/Guarded.sol"; */
/* import {Pausable} from "src/pausable/Pausable.sol"; */

/* import {IOracle} from "src/oracle/IOracle.sol"; */
/* import {IAggregatorOracle} from "src/aggregator/IAggregatorOracle.sol"; */

contract AggregatorOracle is Guarded, Pausable, IAggregatorOracle, IOracle {
    // @notice Emitted when trying to add an oracle that already exists
    error AggregatorOracle__addOracle_oracleAlreadyRegistered(address oracle);

    // @notice Emitted when trying to remove an oracle that does not exist
    error AggregatorOracle__removeOracle_oracleNotRegistered(address oracle);

    // @notice Emitted when trying to remove an oracle makes a valid value impossible
    error AggregatorOracle__removeOracle_minimumRequiredValidValues_higherThan_oracleCount(
        uint256 requiredValidValues,
        uint256 oracleCount
    );

    // @notice Emitted when one does not have the right permissions to manage _oracles
    error AggregatorOracle__notAuthorized();

    // @notice Emitted when trying to set the minimum number of valid values higher than the oracle count
    error AggregatorOracle__setParam_requiredValidValues_higherThan_oracleCount(
        uint256 requiredValidValues,
        uint256 oracleCount
    );

    // @notice Emitted when trying to set a parameter that does not exist
    error AggregatorOracle__setParam_unrecognizedParam(bytes32 param);
    /// ======== Events ======== ///

    event OracleAdded(address oracleAddress);
    event OracleRemoved(address oracleAddress);
    event OracleUpdated(bool success, address oracleAddress);
    event OracleValue(int256 value, bool valid);
    event OracleValueFailed(address oracleAddress);
    event AggregatedValue(int256 value, uint256 validValues);
    event SetParam(bytes32 param, uint256 value);

    /// ======== Storage ======== ///

    // List of registered oracles
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _oracles;

    // Current aggregated value
    int256 private _aggregatedValue;

    // Minimum number of valid values required
    // from oracles to consider an aggregated value valid
    uint256 public requiredValidValues;

    // Number of valid values from oracles
    uint256 private _aggregatedValidValues;

    /// @notice Returns the number of oracles
    function oracleCount()
        public
        view
        override(IAggregatorOracle)
        returns (uint256)
    {
        return _oracles.length();
    }

    /// @notice Returns `true` if the oracle is registered
    function oracleExists(address oracle)
        public
        view
        override(IAggregatorOracle)
        returns (bool)
    {
        return _oracles.contains(oracle);
    }

    /// @notice         Returns the address of an oracle at index
    /// @param index_   The internal index of the oracle
    /// @return         Returns the address pf the oracle
    function oracleAt(uint256 index_)
        external
        view
        override(IAggregatorOracle)
        returns (address)
    {
        return _oracles.at(index_);
    }

    /// @notice Adds an oracle to the list of oracles
    /// @dev Reverts if the oracle is already registered
    function oracleAdd(address oracle)
        public
        override(IAggregatorOracle)
        checkCaller
    {
        bool added = _oracles.add(oracle);
        if (added == false) {
            revert AggregatorOracle__addOracle_oracleAlreadyRegistered(oracle);
        }

        emit OracleAdded(oracle);
    }

    /// @notice Removes an oracle from the list of oracles
    /// @dev Reverts if removing the oracle would break the minimum required valid values
    /// @dev Reverts if removing the oracle is not registered
    function oracleRemove(address oracle)
        public
        override(IAggregatorOracle)
        checkCaller
    {
        uint256 localOracleCount = oracleCount();

        // Make sure the minimum number of required valid values is not higher than the oracle count
        if (requiredValidValues >= localOracleCount) {
            revert AggregatorOracle__removeOracle_minimumRequiredValidValues_higherThan_oracleCount(
                requiredValidValues,
                localOracleCount
            );
        }

        // Try to remove
        bool removed = _oracles.remove(oracle);
        if (removed == false) {
            revert AggregatorOracle__removeOracle_oracleNotRegistered(oracle);
        }

        emit OracleRemoved(oracle);
    }

    /// @notice Update values from oracles and return aggregated value
    function update() public override(IOracle) {
        // Call all oracles to update and get values
        uint256 oracleLength = _oracles.length();
        int256[] memory values = new int256[](oracleLength);

        // Count how many oracles have a valid value
        uint256 validValues = 0;

        // Update each oracle and get its value
        for (uint256 i = 0; i < oracleLength; i++) {
            IOracle oracle = IOracle(_oracles.at(i));

            try oracle.update() {
                emit OracleUpdated(true, address(oracle));
                try oracle.value() returns (
                    int256 returnedValue,
                    bool isValid
                ) {
                    if (isValid) {
                        // Add the value to the list of valid values
                        values[validValues] = returnedValue;

                        // Increase count of valid values
                        validValues++;
                    }
                    emit OracleValue(returnedValue, isValid);
                } catch {
                    emit OracleValueFailed(address(oracle));
                    continue;
                }
            } catch {
                emit OracleUpdated(false, address(oracle));
                continue;
            }
        }

        // Aggregate the returned values
        _aggregatedValue = _aggregateValues(values, validValues);

        // Update the number of valid values
        _aggregatedValidValues = validValues;

        emit AggregatedValue(_aggregatedValue, validValues);
    }

    /// @notice Returns the aggregated value
    /// @dev The value is considered valid if
    ///      - the number of valid values is higher than the minimum required valid values
    ///      - the number of required valid values is > 0
    function value()
        public
        view
        override(IOracle)
        whenNotPaused
        returns (int256, bool)
    {
        bool isValid = _aggregatedValidValues >= requiredValidValues &&
            _aggregatedValidValues > 0;
        return (_aggregatedValue, isValid);
    }

    /// @notice Pause contract
    function pause() public checkCaller {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public checkCaller {
        _unpause();
    }

    function setParam(bytes32 param, uint256 value) public checkCaller {
        if (param == "requiredValidValues") {
            uint256 localOracleCount = oracleCount();
            // Should not be able to set the minimum number of required valid values higher than the oracle count
            if (value > localOracleCount) {
                revert AggregatorOracle__setParam_requiredValidValues_higherThan_oracleCount(
                    value,
                    localOracleCount
                );
            }
            requiredValidValues = value;
        } else revert AggregatorOracle__setParam_unrecognizedParam(param);

        emit SetParam(param, value);
    }

    /// @notice Aggregates the values
    function _aggregateValues(int256[] memory values, uint256 validValues)
        internal
        pure
        returns (int256)
    {
        // Avoid division by zero
        if (validValues == 0) {
            return 0;
        }

        int256 sum;
        for (uint256 i = 0; i < validValues; i++) {
            sum += values[i];
        }

        return sum / int256(validValues);
    }
}