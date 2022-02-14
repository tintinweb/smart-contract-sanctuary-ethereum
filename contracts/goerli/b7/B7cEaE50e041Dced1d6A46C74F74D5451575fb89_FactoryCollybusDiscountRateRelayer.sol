/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/factory/FactoryCollybusDiscountRateRelayer.sol
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
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant ANY_CALLER =
        address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
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
    function allowCaller(bytes32 sig, address who) public callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view returns (bool) {
        return (_canCall[sig][who] ||
            _canCall[ANY_SIG][who] ||
            _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }
}

////// src/oracle/IOracle.sol
/* pragma solidity ^0.8.0; */

interface IOracle {
    function value() external view returns (int256, bool);

    function update() external;
}

////// src/relayer/IRelayer.sol
/* pragma solidity ^0.8.0; */

interface IRelayer {
    function check() external returns (bool);

    function execute() external;

    function executeWithRevert() external;
}

////// src/relayer/CollybusDiscountRate/ICollybusDiscountRateRelayer.sol
/* pragma solidity ^0.8.0; */
/* import {IRelayer} from "src/relayer/IRelayer.sol"; */

interface ICollybusDiscountRateRelayer is IRelayer {
    function oracleCount() external view returns (uint256);

    function oracleExists(address oracle_) external view returns (bool);

    function oracleAt(uint256 index) external view returns (address);

    function oracleAdd(
        address oracle_,
        uint256 tokenId_,
        uint256 minimumThresholdValue_
    ) external;

    function oracleRemove(address oracle_) external;
}

////// src/relayer/ICollybus.sol
/* pragma solidity ^0.8.0; */

// Lightweight interface for Collybus
// Source: https://github.com/fiatdao/fiat-lux/blob/f49a9457fbcbdac1969c35b4714722f00caa462c/src/interfaces/ICollybus.sol
interface ICollybus {
    function updateDiscountRate(uint256 tokenId, uint256 rate) external;

    function updateSpot(address token, uint256 spot) external;
}

////// src/relayer/CollybusDiscountRate/CollybusDiscountRateRelayer.sol
/* pragma solidity ^0.8.0; */

/* import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; */
/* import {IRelayer} from "src/relayer/IRelayer.sol"; */
/* import {IOracle} from "src/oracle/IOracle.sol"; */
/* import {ICollybus} from "src/relayer/ICollybus.sol"; */
/* import {ICollybusDiscountRateRelayer} from "src/relayer/CollybusDiscountRate/ICollybusDiscountRateRelayer.sol"; */
/* import {Guarded} from "src/guarded/Guarded.sol"; */

contract CollybusDiscountRateRelayer is Guarded, ICollybusDiscountRateRelayer {
    // @notice Emitted when trying to add an oracle that already exists
    error CollybusDiscountRateRelayer__addOracle_oracleAlreadyRegistered(
        address oracle
    );

    // @notice Emitted when trying to add an oracle for a tokenId that already has a registered oracle.
    error CollybusDiscountRateRelayer__addOracle_tokenIdHasOracleRegistered(
        address oracle,
        uint256 tokenId
    );

    // @notice Emitter when trying to remove an oracle that was not registered.
    error CollybusDiscountRateRelayer__removeOracle_oracleNotRegistered(
        address oracle
    );

    // @notice Emitter when check() returns false
    error CollybusDiscountRateRelayer__executeWithRevert_checkFailed();

    struct OracleData {
        bool exists;
        uint256 tokenId;
        int256 lastUpdateValue;
        uint256 minimumThresholdValue;
    }

    /// ======== Events ======== ///

    event OracleAdded(address oracleAddress);
    event OracleRemoved(address oracleAddress);
    event ShouldUpdate(bool shouldUpdate);
    event UpdateOracle(address oracle, int256 value, bool valid);
    event UpdatedCollybus(uint256 tokenId, uint256 rate);

    /// ======== Storage ======== ///

    address public immutable collybus;

    // Mapping that will hold all the oracle params needed by the contract
    mapping(address => OracleData) private _oraclesData;

    // Mapping used tokenId's
    mapping(uint256 => bool) public _tokenIds;

    // Array used for iterating the oracles.
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _oracleList;

    constructor(address collybusAddress_) {
        collybus = collybusAddress_;
    }

    /// @notice Returns the number of registered oracles.
    /// @return the total number of oracles.
    function oracleCount()
        public
        view
        override(ICollybusDiscountRateRelayer)
        returns (uint256)
    {
        return _oracleList.length();
    }

    /// @notice         Returns the address of an oracle at index
    /// @dev            Reverts if the index is out of bounds
    /// @param index_   The internal index of the oracle
    /// @return         Returns the address pf the oracle
    function oracleAt(uint256 index_)
        external
        view
        override(ICollybusDiscountRateRelayer)
        returns (address)
    {
        return _oracleList.at(index_);
    }

    /// @notice         Checks whether an oracle is registered.
    /// @param oracle_  The address of the oracle.
    /// @return         Returns 'true' if the oracle is registered.
    function oracleExists(address oracle_)
        public
        view
        override(ICollybusDiscountRateRelayer)
        returns (bool)
    {
        return _oraclesData[oracle_].exists;
    }

    /// @notice                         Registers an oracle to a token id and set the minimum threshold delta value
    ///                                 calculate the annual rate.
    /// @param oracle_                  The address of the oracle.
    /// @param tokenId_                 The unique token id for which this oracle will update rate values.
    /// @param minimumThresholdValue_   The minimum value delta threshold needed in order to push values to the Collybus
    /// @dev                            Reverts if the oracle is already registered or if the rate id is taken by another oracle.
    function oracleAdd(
        address oracle_,
        uint256 tokenId_,
        uint256 minimumThresholdValue_
    ) public override(ICollybusDiscountRateRelayer) checkCaller {
        // Make sure the oracle was not added previously
        if (oracleExists(oracle_)) {
            revert CollybusDiscountRateRelayer__addOracle_oracleAlreadyRegistered(
                oracle_
            );
        }

        // Make sure there are no existing oracles registered for this rate Id
        if (_tokenIds[tokenId_]) {
            revert CollybusDiscountRateRelayer__addOracle_tokenIdHasOracleRegistered(
                oracle_,
                tokenId_
            );
        }

        // Add oracle in the oracle address array that is used for iterating.
        _oracleList.add(oracle_);

        // Mark the token Id as used
        _tokenIds[tokenId_] = true;

        // Update the oracle address => data mapping with the oracle parameters.
        _oraclesData[oracle_] = OracleData({
            exists: true,
            lastUpdateValue: 0,
            tokenId: tokenId_,
            minimumThresholdValue: minimumThresholdValue_
        });

        emit OracleAdded(oracle_);
    }

    /// @notice         Unregisters an oracle.
    /// @param oracle_  The address of the oracle.
    /// @dev            Reverts if the oracle is not registered
    function oracleRemove(address oracle_)
        public
        override(ICollybusDiscountRateRelayer)
        checkCaller
    {
        // Make sure the oracle is registered
        if (!oracleExists(oracle_)) {
            revert CollybusDiscountRateRelayer__removeOracle_oracleNotRegistered(
                oracle_
            );
        }

        // Reset the tokenId Mapping
        _tokenIds[_oraclesData[oracle_].tokenId] = false;

        // Remove the oracle from the list
        // This returns true/false depending on if the oracle was removed
        _oracleList.remove(oracle_);

        // Reset struct to default values
        delete _oraclesData[oracle_];

        emit OracleRemoved(oracle_);
    }

    /// @notice Returns the oracle data for a given oracle address
    /// @param oracle_ The address of the oracle
    /// @return Returns the oracle data as `OracleData`
    function oraclesData(address oracle_)
        public
        view
        returns (OracleData memory)
    {
        return _oraclesData[oracle_];
    }

    // function oraclesData()

    /// @notice Iterates and updates each oracle until it finds one that should push data
    ///         in the Collybus, more exactly, the delta change in value is bigger than the minimum
    ///         threshold value set for that oracle.
    /// @dev    Oracles that return invalid values are skipped.
    /// @return Returns 'true' if at least one oracle should update data in the Collybus
    function check() public override(IRelayer) returns (bool) {
        uint256 arrayLength = _oracleList.length();
        for (uint256 i = 0; i < arrayLength; i++) {
            // Cache oracle address
            address localOracle = _oracleList.at(i);

            // Trigger the oracle to update its data
            IOracle(localOracle).update();

            (int256 rate, bool isValid) = IOracle(localOracle).value();

            emit UpdateOracle(localOracle, rate, isValid);
            if (!isValid) continue;

            if (
                absDelta(_oraclesData[localOracle].lastUpdateValue, rate) >=
                _oraclesData[localOracle].minimumThresholdValue
            ) {
                emit ShouldUpdate(true);
                return true;
            }
        }

        emit ShouldUpdate(false);
        return false;
    }

    /// @notice Iterates and updates all the oracles and pushes the updated data to Collybus for the
    ///         oracles that have delta changes in value bigger than the minimum threshold values.
    /// @dev    Oracles that return invalid values are skipped.
    function execute() public override(IRelayer) {
        // Update Collybus all tokenIds with the new discount rate
        uint256 arrayLength = _oracleList.length();
        for (uint256 i = 0; i < arrayLength; i++) {
            // Cache oracle address
            address localOracle = _oracleList.at(i);

            // We always update the oracles before retrieving the rates
            IOracle(localOracle).update();
            (int256 rate, bool isValid) = IOracle(localOracle).value();

            if (!isValid) continue;

            OracleData storage oracleData = _oraclesData[localOracle];

            // If the change in delta rate from the last update is bigger than the threshold value push
            // the rates to Collybus
            if (
                absDelta(oracleData.lastUpdateValue, rate) >=
                oracleData.minimumThresholdValue
            ) {
                oracleData.lastUpdateValue = rate;
                ICollybus(collybus).updateDiscountRate(
                    oracleData.tokenId,
                    uint256(rate)
                );

                emit UpdatedCollybus(oracleData.tokenId, uint256(rate));
            }
        }
    }

    /// @notice The function will call `execute()` if `check()` returns `true`, otherwise it will revert
    /// @dev This method is needed for services that try to updates the oracles on each block and only call the method if it doesn't fail
    function executeWithRevert() public override(IRelayer) {
        if (check()) {
            execute();
        } else {
            revert CollybusDiscountRateRelayer__executeWithRevert_checkFailed();
        }
    }

    /// @notice     Computes the positive delta between two signed int256
    /// @param a    First parameter.
    /// @param b    Second parameter.
    /// @return     Returns the positive delta.
    function absDelta(int256 a, int256 b) internal pure returns (uint256) {
        if (a > b) {
            return uint256(a - b);
        }
        return uint256(b - a);
    }
}

////// src/factory/FactoryCollybusDiscountRateRelayer.sol
/* pragma solidity ^0.8.0; */

/* import {CollybusDiscountRateRelayer} from "src/relayer/CollybusDiscountRate/CollybusDiscountRateRelayer.sol"; */

interface IFactoryCollybusDiscountRateRelayer {
    function create(address collybus_) external returns (address);
}

contract FactoryCollybusDiscountRateRelayer is
    IFactoryCollybusDiscountRateRelayer
{
    function create(address collybus_)
        public
        override(IFactoryCollybusDiscountRateRelayer)
        returns (address)
    {
        CollybusDiscountRateRelayer discountRateRelayer = new CollybusDiscountRateRelayer(
                collybus_
            );

        discountRateRelayer.allowCaller(
            discountRateRelayer.ANY_SIG(),
            msg.sender
        );

        return address(discountRateRelayer);
    }
}