// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./access/Operator.sol";

abstract contract PermissionsController is Operator {
    using EnumerableSet for EnumerableSet.UintSet;

    enum Roles {UNKNOWN, ADMIN, SHIPMENT, CARRIER, DRIVER, THIRDPARTY}

    mapping(Roles => EnumerableSet.UintSet) private _permissions;

    /**
     * @notice Returns boolean value - whether the role is a permission id
     * @param role Role account
     * @param permissionId Permission id
     */
    function permissionsContains(Roles role, uint256 permissionId) public view returns (bool) {
        return _permissions[role].contains(permissionId);
    }

    /**
     * @notice Returns the permissions by index
     * @param role Role account
     * @param index Role index
     */
    function permissionsAt(Roles role, uint256 index) public view returns (uint256) {
        return _permissions[role].at(index);
    }

    /**
     * @notice Returns the roles length
     * @param role Role account
     */
    function permissionsLength(Roles role) public view returns (uint256) {
        return _permissions[role].length();
    }

    /**
     * @notice Returns the permissions values
     * @param role Role account
     */
    function permissionsValues(Roles role) public view returns (uint256[] memory) {
        return _permissions[role].values();
    }

    /**
     * @dev Emmitted when permissions added
     * @param adminPermissions Permission statuses for admin
     * @param shipperPermissions Permission statuses for shippers
     * @param carrierPermissions Permission statuses for carrier
     * @param driverPermissions Permission statuses for driver
     * @param thirdPartyPermissions Permission statuses for thirdParty
     */
    event PermissionsAdded(
        uint256[] adminPermissions,
        uint256[] shipperPermissions,
        uint256[] carrierPermissions,
        uint256[] driverPermissions,
        uint256[] thirdPartyPermissions
    );

    /**
     * @dev Emmitted when permissions removed
     * @param adminPermissions Permission statuses for admin
     * @param shipperPermissions Permission statuses for shippers
     * @param carrierPermissions Permission statuses for carrier
     * @param driverPermissions Permission statuses for driver
     * @param thirdPartyPermissions Permission statuses for thirdParty
     */
    event PermissionsRemoved(
        uint256[] adminPermissions,
        uint256[] shipperPermissions,
        uint256[] carrierPermissions,
        uint256[] driverPermissions,
        uint256[] thirdPartyPermissions
    );

    /**
     * @notice Method for adding permissions
     * Emits a {PermissionsAdded} event
     * @param adminPermissions Admin permissions
     * @param shipperPermissions Shipper permissions
     * @param carrierPermissions Carrier permissions
     * @param driverPermissions Driver permissions
     * @param thirdPartyPermissions Third party permissions
     * @return boolean value indicating whether the operation succeded
     */
    function addPermissions(
        uint256[] memory adminPermissions,
        uint256[] memory shipperPermissions,
        uint256[] memory carrierPermissions,
        uint256[] memory driverPermissions,
        uint256[] memory thirdPartyPermissions
    ) public onlyOperator returns (bool) {
        for (uint256 i; i < adminPermissions.length; i++) _permissions[Roles.ADMIN].add(adminPermissions[i]);
        for (uint256 i; i < shipperPermissions.length; i++) _permissions[Roles.SHIPMENT].add(shipperPermissions[i]);
        for (uint256 i; i < carrierPermissions.length; i++) _permissions[Roles.CARRIER].add(carrierPermissions[i]);
        for (uint256 i; i < driverPermissions.length; i++) _permissions[Roles.DRIVER].add(driverPermissions[i]);
        for (uint256 i; i < thirdPartyPermissions.length; i++) _permissions[Roles.THIRDPARTY].add(thirdPartyPermissions[i]);
        emit PermissionsAdded(
            adminPermissions,
            shipperPermissions,
            carrierPermissions,
            driverPermissions,
            thirdPartyPermissions
        );
        return true;
    }

    /**
     * @notice Method for removed permissions
     * Emits a {PermissionsRemoved} event
     * @param adminPermissions Admin permissions
     * @param shipperPermissions Shipper permissions
     * @param carrierPermissions Carrier permissions
     * @param driverPermissions Driver permissions
     * @param thirdPartyPermissions Third party permissions
     * @return boolean value indicating whether the operation succeded
     */
    function removePermissions(
        uint256[] memory adminPermissions,
        uint256[] memory shipperPermissions,
        uint256[] memory carrierPermissions,
        uint256[] memory driverPermissions,
        uint256[] memory thirdPartyPermissions
    ) public onlyOperator returns (bool) {
        for (uint256 i; i < adminPermissions.length; i++) _permissions[Roles.ADMIN].remove(adminPermissions[i]);
        for (uint256 i; i < shipperPermissions.length; i++) _permissions[Roles.SHIPMENT].remove(shipperPermissions[i]);
        for (uint256 i; i < carrierPermissions.length; i++) _permissions[Roles.CARRIER].remove(carrierPermissions[i]);
        for (uint256 i; i < driverPermissions.length; i++) _permissions[Roles.DRIVER].remove(driverPermissions[i]);
        for (uint256 i; i < thirdPartyPermissions.length; i++) _permissions[Roles.THIRDPARTY].remove(thirdPartyPermissions[i]);
        emit PermissionsRemoved(
            adminPermissions,
            shipperPermissions,
            carrierPermissions,
            driverPermissions,
            thirdPartyPermissions
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IStorage.sol";
import "./PermissionsController.sol";

/**
 * The @title contract implements a mechanism for creating and storing a shipment,
 * managing permissions to set the status;
 */
contract Storage is IStorage, PermissionsController {
    uint256 private _shipmentCount;

    mapping(uint256 => Shipment) private _shipments;
    mapping(uint256 => mapping(address => Roles)) private _shipmentUserRole;

    /**
     * @notice Returns the role for account by shipmentId
     * @param shipmentId Shipment id
     * @param account Account address
     */
    function userRole(uint256 shipmentId, address account) external view returns (Roles) {
        return _shipmentUserRole[shipmentId][account];
    }

    /**
     * @notice Returns shipment data by id
     * @param shipmentId Shipment id
     * @param password Password for access data shipment
     * @param document Pagination params for shipment document
     * @param history Pagination params for trip history
     */
    function shipmentById(
        uint256 shipmentId,
        bytes32 password,
        Pagination memory document,
        Pagination memory history
    ) external view returns (Shipment memory) {
        Shipment storage shipment = _shipments[shipmentId];
        _hasAuth(shipment, password);
        return
            Shipment(
                shipment.members,
                shipment.password,
                shipment.status,
                shipment.dispute,
                _tripHistory(shipment, history),
                _shipmentDocument(shipment, document),
                shipment.data
            );
    }

    /**
     * @notice Returns shipment documents
     * @param password Password for access to shipment document
     * @param shipmentId Shipment id
     * @param pagination Pagination params
     */
    function shipmentDocument(
        bytes32 password,
        uint256 shipmentId,
        Pagination memory pagination
    ) public view returns (ShipmentDocument[] memory document) {
        Shipment storage shipment = _shipments[shipmentId];
        _hasAuth(shipment, password);
        document = _shipmentDocument(shipment, pagination);
    }

    /**
     * @notice Returns shipment documents length
     * @param shipmentId Shipment id
     */
    function shipmentDocumentLength(uint256 shipmentId) public view returns (uint256) {
        return _shipments[shipmentId].document.length;
    }

    /**
     * @notice Returns total created shipments
     */
    function shipmentIds() external view returns (uint256) {
        return _shipmentCount;
    }

    /**
     * @notice Returns trip history
     * @param password Password for access to shipment document
     * @param shipmentId Shipment id
     * @param pagination Pagination params
     */
    function tripHistory(
        bytes32 password,
        uint256 shipmentId,
        Pagination memory pagination
    ) public view returns (TripHistory[] memory history) {
        Shipment storage shipment = _shipments[shipmentId];
        _hasAuth(shipment, password);
        history = _tripHistory(shipment, pagination);
    }

    /**
     * @notice Returns trip history length
     * @param shipmentId Shipment id
     */
    function tripHistoryLength(uint256 shipmentId) public view returns (uint256) {
        return _shipments[shipmentId].history.length;
    }

    constructor() Operator() {}

    /**
     * @notice Method for adding shipment document
     * @dev For success works:
     *  - can be called only by Operator address that stores in contract
     *  - shipment must exist
     * Emits a {ShipmentDocumentAdded} event
     * @param shipmentId ShipmentId
     * @param document Shipment document added
     * @return boolean value indicating whether the operation succeded
     */
    function addShipmentDocument(uint256 shipmentId, ShipmentDocument memory document)
        external
        onlyOperator
        returns (bool)
    {
        require(_shipmentCount >= shipmentId, "Shipment not found");
        _shipments[shipmentId].document.push(document);
        emit ShipmentDocumentAdded(shipmentId, document.id);
        return true;
    }

    /**
     * @notice Method for adding trip history
     * @dev For success works:
     *  - can be called only by Operator address that stores in contract
     *  - shipment must exist
     * Emits a {TripHistoryAdded} event
     * @param shipmentId Shipment id
     * @param history Trip history added
     * @return boolean value indicating whether the operation succeded
     */
    function addTripHistory(uint256 shipmentId, TripHistory memory history) external onlyOperator returns (bool) {
        require(_shipmentCount >= shipmentId, "Shipment not found");
        _shipments[shipmentId].history.push(history);
        emit TripHistoryAdded(shipmentId, history.id);
        return true;
    }

    /**
     * @notice Method for creating shipment
     * @dev For success works:
     *  - can be called only by operator address that stores in contract
     *  - shipment must exist
     * Emits a {ShipmentCreated} event
     * @param members Accounts for setting roles
     * @param password Password for access to shipment document
     * @param status Status dispute
     * @param history History data
     * @param document Shipment document data
     * @param data Shipment data fields
     * @return boolean value indicating whether the operation succeded
     */
    function createShipment(
        Members memory members,
        bytes32 password,
        Status status,
        TripHistory memory history,
        ShipmentDocument memory document,
        ShipmentDataFields memory data
    ) external onlyOperator returns (bool) {
        _shipmentCount++;
        _shipmentUserRole[_shipmentCount][members.admin] = Roles.ADMIN;
        _shipmentUserRole[_shipmentCount][members.shipper] = Roles.SHIPMENT;
        _shipmentUserRole[_shipmentCount][members.carrier] = Roles.CARRIER;
        _shipmentUserRole[_shipmentCount][members.driver] = Roles.DRIVER;
        _shipmentUserRole[_shipmentCount][members.thirdParty] = Roles.THIRDPARTY;
        Shipment storage _shipment = _shipments[_shipmentCount];
        _shipment.members = members;
        _shipment.password = password;
        _shipment.status = status;
        _shipment.history.push(history);
        _shipment.document.push(document);
        _shipment.data = data;
        emit ShipmentCreated(_shipmentCount);
        return true;
    }

    /**
     * @notice Method for update members shipment
     * @dev For success works:
     *  - can be called only operator
     *  - shipment must exist
     * Emits a {ShipmentMembersUpdated} event
     * @param members Accounts for setting roles
     * @return boolean value indicating whether the operation succeded
     */
    function updateShipmentMembers(uint256 shipmentId, Members memory members) external onlyOperator returns (bool) {
        require(_shipmentCount >= shipmentId, "Shipment not found");
        _shipments[shipmentId].members = members;
        emit ShipmentMembersUpdated(shipmentId, members);
        return true;
    }

    /**
     * @notice Method for update password for getting data shipment
     * @dev For success works:
     *  - can be called only operator
     *  - shipment must exist
     * Emits a {ShipmentPasswordUpdated} event
     * @param password Password for access to shipment document
     * @return boolean value indicating whether the operation succeded
     */
    function updateShipmentPassword(uint256 shipmentId, bytes32 password) external onlyOperator returns (bool) {
        require(_shipmentCount >= shipmentId, "Shipment not found");
        _shipments[shipmentId].password = password;
        emit ShipmentPasswordUpdated(shipmentId, password);
        return true;
    }

    /**
     * @notice Method for update shipment data fields
     * @dev For success works:
     *  - can be called only operator
     *  - shipment must exist
     * Emits a {ShipmentDataFieldsUpdated} event
     * @param data Shipment data fields
     * @return boolean value indicating whether the operation succeded
     */
    function updateShipmentDataFields(uint256 shipmentId, ShipmentDataFields memory data)
        external
        onlyOperator
        returns (bool)
    {
        require(_shipmentCount >= shipmentId, "Shipment not found");
        _shipments[shipmentId].data = data;
        emit ShipmentDataFieldsUpdated(shipmentId);
        return true;
    }

    /**
     * @notice Method for update dispute params
     * @dev For success works:
     *  - can be called only operator
     *  - shipment must exist
     * Emits a {DisputeUpdated} event
     * @param dispute Shipment dispute params
     * @return boolean value indicating whether the operation succeded
     */
    function updateDispute(uint256 shipmentId, Dispute memory dispute) external onlyOperator returns (bool) {
        require(_shipmentCount >= shipmentId, "Shipment not found");
        _shipments[shipmentId].dispute = dispute;
        emit DisputeUpdated(shipmentId);
        return true;
    }

    /**
     * @notice Method for update shipment status
     * @dev For success works:
     *  - can be called only when contains role {permissionsContains}
     *  - shipment must exist
     * Emits a {ShipmentStatusUpdated} event
     * @param shipmentId ShipmentId
     * @param status New status shipment
     * @return boolean value indicating whether the operation succeded
     */
    function updateShipmentStatus(uint256 shipmentId, Status status)
        external
        hasPermission(shipmentId, msg.sender, status)
        returns (bool)
    {
        require(_shipmentCount >= shipmentId, "Shipment not found");
        Shipment storage shipment = _shipments[shipmentId];
        shipment.status = status;
        emit ShipmentStatusUpdated(shipmentId, status);
        return true;
    }

    /**
     * @dev Private method to check the password for access to the shipment
     * @param shipment Shipment data
     * @param password Password to Verify
     */
    function _hasAuth(Shipment storage shipment, bytes32 password) private view {
        require(shipment.password == password, "Invalid password");
    }

    /**
     * @dev Private method for get shipments
     * @param shipment Shipment data
     * @param pagination Pagination for shipment document
     */
    function _shipmentDocument(Shipment storage shipment, Pagination memory pagination)
        private
        view
        returns (ShipmentDocument[] memory document)
    {
        uint256 shipmentDocumentDataLength = shipment.document.length;
        if (pagination.offset > shipmentDocumentDataLength) return document;
        uint256 to = pagination.offset + pagination.limit;
        if (shipmentDocumentDataLength < to) to = shipmentDocumentDataLength;
        document = new ShipmentDocument[](to - pagination.offset);
        for (uint256 i = 0; i < document.length; i++) {
            document[i] = shipment.document[pagination.offset + i];
        }
    }

    /**
     * @dev Private method for get trip history
     * @param shipment Shipment data
     * @param pagination Pagination for trip history
     */
    function _tripHistory(Shipment storage shipment, Pagination memory pagination)
        private
        view
        returns (TripHistory[] memory history)
    {
        uint256 historyDataLength = shipment.history.length;
        if (pagination.offset > historyDataLength) return history;
        uint256 to = pagination.offset + pagination.limit;
        if (historyDataLength < to) to = historyDataLength;
        history = new TripHistory[](to - pagination.offset);
        for (uint256 i = 0; i < history.length; i++) {
            history[i] = shipment.history[pagination.offset + i];
        }
    }

    /**
     * @dev Private method for check permission by account
     * @param shipmentId Shipment id
     * @param account Account for check permission
     * @param status_ Access for status
     */
    modifier hasPermission(
        uint256 shipmentId,
        address account,
        Status status_
    ) {
        require(permissionsContains(_shipmentUserRole[shipmentId][account], uint256(status_)), "Not enough rights");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Operator is Ownable {
    address private _operator;

    function operator() public virtual view returns (address) {
        return _operator;
    }

    event OperatorUpdated(address operator_);

    constructor() Ownable() {
        _setOperator(_msgSender());
    }

    function setOperator(address operator_) public virtual onlyOwner returns (bool) {
        _setOperator(operator_);
        return true;
    }

    function _setOperator(address operator_) private {
        require(operator_ != address(0), "Operator is zero address");
        _operator = operator_;
        emit OperatorUpdated(operator_);
    }

    modifier onlyOperator() {
        require(_operator == _msgSender(), "Operator: caller is not operator");
        _;
    }
    modifier onlyOwnerOrOperator() {
        require(_operator == _msgSender() || owner() == _msgSender(), "Operator: caller is not operator or owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IStorage {
    struct Dispute {
        bool exist;
        uint256 penalty;
    }

    struct Members {
        address admin;
        address shipper;
        address carrier;
        address driver;
        address thirdParty;
    }

    struct Pagination {
        uint256 offset;
        uint256 limit;
    }

    struct Shipment {
        Members members;
        bytes32 password;
        Status status;
        Dispute dispute;
        TripHistory[] history;
        ShipmentDocument[] document;
        ShipmentDataFields data;
    }

    struct ShipmentDocument {
        uint256 id;
        uint256 userid;
        string mediaType;
        string medialUrl;
        string timestamp;
        string date;
    }

    struct ShipmentDataFields {
        uint256 pickupLocationLongName;
        string pickupDate;
        string pickupTimesLot;
        uint256 pickupContact;
        string pickupInstructions;
        string dropLocationLongName;
        string dropDate;
        string dropTimeslot;
        uint256 dropContact;
        string dropInstructions;
        string equipmentType;
        uint256 equipmentLength;
        uint256 equipmentHeight;
        uint256 equipmentWidth;
        uint256 equipmentWeight;
        string commodity;
        uint256 quantity;
        uint256 freightRate;
        string paymentMethod;
        string visibility;
        string carrierName;
        string shipperName;
        string driverName;
        string shipmentStatus;
        uint256 organisationId;
    }

    struct TripHistory {
        uint256 id;
        uint256 driverId;
        uint256 carrierId;
        uint256 shipperId;
        string message;
        uint256 actionBy;
        string location;
        uint256 action;
        string timestamp;
        string date;
    }

    enum Status {
        ShipmentCreated,
        ShipmentReadyToBid,
        ShipmentConfirmed,
        ShipmentAssignedToCarrier,
        ShipmentAssignedToDriver,
        DriverIsNavigatingToPickup,
        DriverChanged,
        DriverReachingPickupLocationManual,
        DriverReachingPickupLocationAuto,
        ShipmentStartedLoading,
        PickupSignature,
        ShipmentLoadingImage,
        ProofOfPickup,
        DriverVerifiedPickupDocuments,
        ShipmentLoaded,
        DriverIsInTransitToDropoff,
        DriverReachedDropLocationManual,
        DriverReachedDropLocationAuto,
        ShipmentUnloadingStarted,
        DropoffSignature,
        ShipmentUnloadingImage,
        ProofOfDrop,
        ShipmentUnloadingComplete,
        DriverVerifiedDropoffDocuments,
        DeliveryConfirmed,
        ShipmentDisputed,
        DisputeInProgress,
        DisputeResolved,
        PaymentInitiated,
        ShipmentPaymentReleased,
        Emergency,
        VehicleUnderMaintenance,
        VehicleRefueling,
        OutOfHours
    }

    /**
     * @dev Emmitted when shipment is created
     * @param shipmentId New shipment id
     */
    event ShipmentCreated(uint256 indexed shipmentId);

    /**
     * @dev Emmitted when shipment document is created
     * @param shipmentId Shipment id
     * @param documentId New created shipment document
     */
    event ShipmentDocumentAdded(uint256 indexed shipmentId, uint256 documentId);

    /**
     * @dev Emmitted when shipment status is updated
     * @param shipmentId Shipment id
     * @param status New status shipment
     */
    event ShipmentStatusUpdated(uint256 shipmentId, Status status);

    /**
     * @dev Emmitted when trip history is added
     * @param shipmentId Shipment id
     * @param tripHistoryId New trip history id
     */
    event TripHistoryAdded(uint256 indexed shipmentId, uint256 tripHistoryId);

    /**
     * @dev Emmitted when shipment updated
     * @param shipmentId Shipment id
     */
    event ShipmentUpdated(uint256 indexed shipmentId);

    /**
     * @dev Emmitted when shipment members updated
     * @param shipmentId Shipment id
     * @param accounts New accounts members shipment
     */
    event ShipmentMembersUpdated(uint256 indexed shipmentId, Members accounts);

    /**
     * @dev Emmitted when shipment password updated
     * @param shipmentId Shipment id
     * @param password New password for access data shipment
     */
    event ShipmentPasswordUpdated(uint256 indexed shipmentId, bytes32 password);

    /**
     * @dev Emmitted when shipment data fields updated
     * @param shipmentId Shipment id
     */
    event ShipmentDataFieldsUpdated(uint256 indexed shipmentId);

    /**
     * @dev Emmitted when shipment dispute updated
     * @param shipmentId Shipment id
     */
    event DisputeUpdated(uint256 indexed shipmentId);
}