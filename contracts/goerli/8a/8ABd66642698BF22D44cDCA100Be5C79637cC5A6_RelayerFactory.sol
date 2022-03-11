/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/factory/RelayerFactory.sol
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

////// src/relayer/IRelayer.sol
/* pragma solidity ^0.8.0; */

interface IRelayer {
    enum RelayerType {
        DiscountRate,
        SpotPrice
    }

    function execute() external returns (bool);

    function executeWithRevert() external;

    function oracleCount() external view returns (uint256);

    function oracleAdd(
        address oracle_,
        bytes32 encodedToken_,
        uint256 minimumPercentageDeltaValue_
    ) external;

    function oracleRemove(address oracle_) external;

    function oracleExists(address oracle_) external view returns (bool);

    function oracleAt(uint256 index_) external view returns (address);
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
    /// @param sig_ Method signature (4Byte)
    /// @param who_ Address of who should be able to call `sig`
    function allowCaller(bytes32 sig_, address who_) public callerIsRoot {
        _canCall[sig_][who_] = true;
        emit AllowCaller(sig_, who_);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig_ Method signature (4Byte)
    /// @param who_ Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig_, address who_) public callerIsRoot {
        _canCall[sig_][who_] = false;
        emit BlockCaller(sig_, who_);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig_ Method signature (4Byte)
    /// @param who_ Address of who should be able to call `sig`
    function canCall(bytes32 sig_, address who_) public view returns (bool) {
        return (_canCall[sig_][who_] ||
            _canCall[ANY_SIG][who_] ||
            _canCall[sig_][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root_ Address of who should be set as root
    function _setRoot(address root_) internal {
        _canCall[ANY_SIG][root_] = true;
        emit AllowCaller(ANY_SIG, root_);
    }
}

////// src/oracle/IOracle.sol
/* pragma solidity ^0.8.0; */

interface IOracle {
    function value() external view returns (int256, bool);

    function update() external returns (bool);
}

////// src/relayer/ICollybus.sol
/* pragma solidity ^0.8.0; */

// Lightweight interface for Collybus
// Source: https://github.com/fiatdao/fiat-lux/blob/f49a9457fbcbdac1969c35b4714722f00caa462c/src/interfaces/ICollybus.sol
interface ICollybus {
    function updateDiscountRate(uint256 tokenId_, uint256 rate_) external;

    function updateSpot(address token_, uint256 spot_) external;
}

////// src/relayer/Relayer.sol
/* pragma solidity ^0.8.0; */

/* import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; */
/* import {IRelayer} from "./IRelayer.sol"; */
/* import {IOracle} from "../oracle/IOracle.sol"; */
/* import {ICollybus} from "./ICollybus.sol"; */
/* import {Guarded} from "../guarded/Guarded.sol"; */

contract Relayer is Guarded, IRelayer {
    // @notice Emitted when trying to add an oracle that already exists
    error Relayer__addOracle_oracleAlreadyRegistered(
        address oracle,
        RelayerType relayerType
    );

    // @notice Emitted when trying to add an oracle for a tokenId that already has a registered oracle.
    error Relayer__addOracle_tokenIdHasOracleRegistered(
        address oracle,
        bytes32 tokenId,
        RelayerType relayerType
    );

    // @notice Emitter when trying to remove an oracle that was not registered.
    error Relayer__removeOracle_oracleNotRegistered(
        address oracle,
        RelayerType relayerType
    );

    // @notice Emitter when execute() does not update any oracle
    error Relayer__executeWithRevert_noUpdates(RelayerType relayerType);

    // @notice Emitted when trying to add a Oracle to the Relayer but the Relayer is not whitelisted in the Oracle
    //         The Relayer needs to be able to call Update on all Oracles
    error Relayer__unauthorizedToCallUpdateOracle(address oracleAddress);

    struct OracleData {
        bool exists;
        bytes32 tokenId;
        int256 lastUpdateValue;
        uint256 minimumPercentageDeltaValue;
    }

    /// ======== Events ======== ///

    event OracleAdded(address oracleAddress);
    event OracleRemoved(address oracleAddress);
    event ShouldUpdate(bool shouldUpdate);
    event UpdateOracle(address oracle, int256 value, bool valid);
    event UpdatedCollybus(bytes32 tokenId, uint256 rate, RelayerType);

    /// ======== Storage ======== ///

    address public immutable collybus;

    RelayerType public immutable relayerType;

    // Mapping that will hold all the oracle params needed by the contract
    mapping(address => OracleData) private _oraclesData;

    // Mapping used tokenId's
    mapping(bytes32 => bool) public encodedTokenIds;

    // Array used for iterating the oracles.
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _oracleList;

    constructor(address collybusAddress_, RelayerType type_) {
        collybus = collybusAddress_;
        relayerType = type_;
    }

    /// @notice Returns the number of registered oracles.
    /// @return the total number of oracles.
    function oracleCount() external view override(IRelayer) returns (uint256) {
        return _oracleList.length();
    }

    /// @notice Returns the address of an oracle at index
    /// @dev Reverts if the index is out of bounds
    /// @param index_ The internal index of the oracle
    /// @return Returns the address pf the oracle
    function oracleAt(uint256 index_)
        external
        view
        override(IRelayer)
        returns (address)
    {
        return _oracleList.at(index_);
    }

    /// @notice Checks whether an oracle is registered.
    /// @param oracle_ The address of the oracle.
    /// @return Returns 'true' if the oracle is registered.
    function oracleExists(address oracle_)
        public
        view
        override(IRelayer)
        returns (bool)
    {
        return _oraclesData[oracle_].exists;
    }

    /// @notice Registers an oracle to a token id and set the minimum threshold delta value
    /// calculate the annual rate.
    /// @param oracle_ The address of the oracle.
    /// @param encodedTokenId_ The unique token id for which this oracle will update rate values.
    /// @param minimumPercentageDeltaValue_ The minimum value delta threshold needed in order to push values to the Collybus
    /// @dev Reverts if the oracle is already registered or if the rate id is taken by another oracle.
    function oracleAdd(
        address oracle_,
        bytes32 encodedTokenId_,
        uint256 minimumPercentageDeltaValue_
    ) public override(IRelayer) checkCaller {
        if (!Guarded(oracle_).canCall(IOracle.update.selector, address(this))) {
            revert Relayer__unauthorizedToCallUpdateOracle(oracle_);
        }

        // Make sure the oracle was not added previously
        if (oracleExists(oracle_)) {
            revert Relayer__addOracle_oracleAlreadyRegistered(
                oracle_,
                relayerType
            );
        }

        // Make sure there are no existing oracles registered for this rate Id
        if (encodedTokenIds[encodedTokenId_]) {
            revert Relayer__addOracle_tokenIdHasOracleRegistered(
                oracle_,
                encodedTokenId_,
                relayerType
            );
        }

        // Add oracle in the oracle address array that is used for iterating.
        _oracleList.add(oracle_);

        // Mark the token Id as used
        encodedTokenIds[encodedTokenId_] = true;

        // Update the oracle address => data mapping with the oracle parameters.
        _oraclesData[oracle_] = OracleData({
            exists: true,
            lastUpdateValue: 0,
            tokenId: encodedTokenId_,
            minimumPercentageDeltaValue: minimumPercentageDeltaValue_
        });

        emit OracleAdded(oracle_);
    }

    /// @notice Unregisters an oracle.
    /// @param oracle_ The address of the oracle.
    /// @dev Reverts if the oracle is not registered
    function oracleRemove(address oracle_)
        public
        override(IRelayer)
        checkCaller
    {
        // Make sure the oracle is registered
        if (!oracleExists(oracle_)) {
            revert Relayer__removeOracle_oracleNotRegistered(
                oracle_,
                relayerType
            );
        }

        // Reset the tokenId Mapping
        encodedTokenIds[_oraclesData[oracle_].tokenId] = false;

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

    /// @notice Iterates and updates all the oracles and pushes the updated data to Collybus for the
    /// oracles that have delta changes in value bigger than the minimum threshold values.
    /// @dev Oracles that return invalid values are skipped.
    function execute() public override(IRelayer) checkCaller returns (bool) {
        bool updated;

        // Update Collybus all tokenIds with the new discount rate
        uint256 arrayLength = _oracleList.length();
        for (uint256 i = 0; i < arrayLength; i++) {
            // Cache oracle address
            address localOracle = _oracleList.at(i);

            // We always update the oracles before retrieving the rates
            bool oracleUpdated = IOracle(localOracle).update();
            if (oracleUpdated) {
                updated = true;
            }
            (int256 oracleValue, bool isValid) = IOracle(localOracle).value();

            if (!isValid) continue;

            OracleData storage oracleData = _oraclesData[localOracle];

            // If the change in delta rate from the last update is bigger than the threshold value push
            // the rates to Collybus
            if (
                checkDeviation(
                    oracleData.lastUpdateValue,
                    oracleValue,
                    oracleData.minimumPercentageDeltaValue
                )
            ) {
                oracleData.lastUpdateValue = oracleValue;

                if (relayerType == RelayerType.DiscountRate) {
                    ICollybus(collybus).updateDiscountRate(
                        uint256(oracleData.tokenId),
                        uint256(oracleValue)
                    );
                } else if (relayerType == RelayerType.SpotPrice) {
                    ICollybus(collybus).updateSpot(
                        address(uint160(uint256(oracleData.tokenId))),
                        uint256(oracleValue)
                    );
                }

                emit UpdatedCollybus(
                    oracleData.tokenId,
                    uint256(oracleValue),
                    relayerType
                );
            }
        }

        return updated;
    }

    /// @notice The function will call `execute()` and will revert if no oracle was updated
    /// @dev This method is needed for services that try to updates the oracles on each block and only call the method if it doesn't fail
    function executeWithRevert() public override(IRelayer) checkCaller {
        if (!execute()) {
            revert Relayer__executeWithRevert_noUpdates(relayerType);
        }
    }

    /// @notice Returns true if the percentage difference between the two values is bigger than the `percentage`
    /// @param baseValue_ The value that the percentage is based on
    /// @param newValue_ The new value
    /// @param percentage_ The percentage threshold value (100% = 100_00, 50% = 50_00, etc)
    function checkDeviation(
        int256 baseValue_,
        int256 newValue_,
        uint256 percentage_
    ) public pure returns (bool) {
        int256 deviation = (baseValue_ * int256(percentage_)) / 100_00;

        if (
            baseValue_ + deviation <= newValue_ ||
            baseValue_ - deviation >= newValue_
        ) return true;

        return false;
    }
}

////// src/relayer/StaticRelayer.sol
/* pragma solidity ^0.8.0; */

/* import {ICollybus} from "./ICollybus.sol"; */
/* import {IRelayer} from "./IRelayer.sol"; */
/* import {Guarded} from "../guarded/Guarded.sol"; */

contract StaticRelayer is Guarded {
    /// ======== Events ======== ///

    event UpdatedCollybus(
        bytes32 tokenId,
        uint256 rate,
        IRelayer.RelayerType relayerType
    );

    /// ======== Storage ======== ///

    address public immutable collybus;
    IRelayer.RelayerType public immutable relayerType;
    bytes32 public immutable encodedTokenId;
    uint256 public immutable value;

    constructor(
        address collybusAddress_,
        IRelayer.RelayerType type_,
        bytes32 encodedTokenId_,
        uint256 value_
    ) {
        collybus = collybusAddress_;
        relayerType = type_;
        encodedTokenId = encodedTokenId_;
        value = value_;
    }

    /// @notice Pushes the hardcoded value to Collybus for the hardcoded token id
    /// After the rate is pushed the contract self-destructs
    function execute() public checkCaller {
        if (relayerType == IRelayer.RelayerType.DiscountRate) {
            ICollybus(collybus).updateDiscountRate(
                uint256(encodedTokenId),
                value
            );
        } else if (relayerType == IRelayer.RelayerType.SpotPrice) {
            ICollybus(collybus).updateSpot(
                address(uint160(uint256(encodedTokenId))),
                value
            );
        }

        emit UpdatedCollybus(encodedTokenId, value, relayerType);

        selfdestruct(payable(address(0)));
    }
}

////// src/factory/RelayerFactory.sol
/* pragma solidity ^0.8.0; */

/* import {Relayer} from "../relayer/Relayer.sol"; */
/* import {StaticRelayer} from "../relayer/StaticRelayer.sol"; */
/* import {IRelayer} from "../relayer/IRelayer.sol"; */

interface IRelayerFactory {
    function create(address collybus_, IRelayer.RelayerType relayerType_)
        external
        returns (address);

    function createStatic(
        address collybus_,
        IRelayer.RelayerType relayerType_,
        bytes32 encodedTokenId_,
        uint256 value_
    ) external returns (address);
}

contract RelayerFactory is IRelayerFactory {
    // Emitted when a Relayer is created
    event RelayerDeployed(
        address relayerAddress,
        IRelayer.RelayerType relayerType
    );
    // Emitted when a Static Relayer is created
    event StaticRelayerDeployed(
        address relayerAddress,
        IRelayer.RelayerType relayerType
    );

    function create(address collybus_, Relayer.RelayerType relayerType_)
        public
        override(IRelayerFactory)
        returns (address)
    {
        Relayer relayer = new Relayer(collybus_, relayerType_);
        relayer.allowCaller(relayer.ANY_SIG(), msg.sender);

        emit RelayerDeployed(address(relayer), relayerType_);
        return address(relayer);
    }

    function createStatic(
        address collybus_,
        Relayer.RelayerType relayerType_,
        bytes32 encodedTokenId_,
        uint256 value_
    ) public override(IRelayerFactory) returns (address) {
        // Create the Static Relayer contract
        StaticRelayer staticRelayer = new StaticRelayer(
            collybus_,
            relayerType_,
            encodedTokenId_,
            value_
        );

        // Pass permissions to the intended contract owner
        staticRelayer.allowCaller(staticRelayer.ANY_SIG(), msg.sender);
        staticRelayer.blockCaller(staticRelayer.ANY_SIG(), address(this));

        emit StaticRelayerDeployed(address(staticRelayer), relayerType_);
        return address(staticRelayer);
    }
}