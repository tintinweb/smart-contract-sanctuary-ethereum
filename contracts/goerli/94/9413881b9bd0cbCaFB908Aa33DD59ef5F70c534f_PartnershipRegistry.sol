//SPDX-License-Identifier: Business Source License 1.1

import "./interfaces/IPartnershipRegistry.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

pragma solidity ^0.8.0;

contract PartnershipRegistry is IPartnershipRegistry, Context {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant DEFAULT_PARTNERSHIP_ADMIN_ROLE = 0x00;
    string internal constant PARTNERHSIP_PREFIX = "PARTNER_";
    string internal constant PARTNERHSIP_ADMIN_PREFIX = "ADMIN_";

    constructor() {
        _roles[DEFAULT_PARTNERSHIP_ADMIN_ROLE]
            .adminRole = DEFAULT_PARTNERSHIP_ADMIN_ROLE;
        _roles[DEFAULT_PARTNERSHIP_ADMIN_ROLE].members[_msgSender()] = true;
    }

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;
    EnumerableSet.Bytes32Set internal _partners;

    modifier _onlyPartnershipAdminRole(string memory _partnerName) {
        require(
            isPartnershipAdmin(_partnerName, _msgSender()),
            "PartnershipRegistry: not admin"
        );
        _;
    }

    modifier _onlyDefaultPartnershipAdminRole() {
        // solhint-disable-next-line reason-string
        require(
            _hasRole(DEFAULT_PARTNERSHIP_ADMIN_ROLE, _msgSender()),
            "PartnershipRegistry: not default admin"
        );
        _;
    }

    modifier _onlyIfPartnershipDoesNotExist(string memory _partnerName) {
        // solhint-disable-next-line reason-string
        require(
            !partnershipExist(_partnerName),
            "PartnershipRegistry: partnership exists"
        );
        _;
    }

    modifier _onlyIfPartnershipExists(string memory _partnerName) {
        // solhint-disable-next-line reason-string
        require(
            partnershipExist(_partnerName),
            "PartnershipRegistry: partnership does not exists"
        );
        _;
    }

    function _hasRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function partnershipExist(string memory _partnerName)
        public
        virtual
        override
        returns (bool)
    {
        return _partners.contains(keccak256(bytes(_partnerName)));
    }

    function addPartnership(string memory _partnerName, address _admin)
        payable
        external
        virtual
        override
        _onlyDefaultPartnershipAdminRole
        _onlyIfPartnershipDoesNotExist(_partnerName)
    {
        bytes32 partner = _partnershipRole(_partnerName);
        bytes32 partnerAdmin = _partnershipAdminRole(_partnerName);

        _roles[partnerAdmin].adminRole = partnerAdmin;
        _roles[partnerAdmin].members[_admin] = true;

        _roles[partner].adminRole = partnerAdmin;
        _roles[partner].members[_admin] = true;

        _partners.add(partner);

        emit PartnerhipRegistered(_partnerName, _admin);
    }

    function removePartnership(string memory _partnerName)
        external
        virtual
        override
        _onlyDefaultPartnershipAdminRole
        _onlyIfPartnershipExists(_partnerName)
    {
        bytes32 partner = _partnershipRole(_partnerName);
        bytes32 partnerAdmin = _partnershipAdminRole(_partnerName);
        delete _roles[partner];
        delete _roles[partnerAdmin];

        emit PartnerhipRemoved(_partnerName);
    }

    function changePartnershipAdmin(
        string memory _partnerName,
        address _newAdmin
    ) external virtual override _onlyPartnershipAdminRole(_partnerName) {
        address currentAdmin = _msgSender();
        bytes32 partnerAdmin = _partnershipAdminRole(_partnerName);
        bytes32 partner = _partnershipRole(_partnerName);

        delete _roles[partnerAdmin].members[currentAdmin];

        _roles[partnerAdmin].members[_newAdmin] = true;
        _roles[partner].members[_newAdmin] = true;

        emit PartnerhipAdminChanged(_partnerName, currentAdmin, _newAdmin);
    }

    function addPartnershipMember(string memory _partnerName, address _addr)
        external
        virtual
        override
        _onlyPartnershipAdminRole(_partnerName)
    {
        bytes32 partner = _partnershipRole(_partnerName);
        _roles[partner].members[_addr] = true;

        emit PartnershipMemberAdded(_partnerName, _addr);
    }

    function grantPartnerDefinedRole(string memory _partnerName, bytes32 _role, address _account) public virtual override _onlyPartnershipAdminRole(_partnerName) {
        bytes32 role_ = _partnerDefinedRole(_partnerName, _role);
        if(!_hasRole(role_, _account)) {
            _roles[role_].members[_account] = true;

            emit PartnerDefinedRoleGranted(_partnerName, _role, _account);
        }
    }

    function revokePartnerDefinedRole(string memory _partnerName, bytes32 _role, address _account) public virtual override _onlyPartnershipAdminRole(_partnerName) {
        bytes32 role_ = _partnerDefinedRole(_partnerName, _role);
        if(_hasRole(role_, _account)) {
            _roles[role_].members[_account] = false;

            emit PartnerDefinedRoleRevoked(_partnerName, _role, _account);
        }
    }

    function grantRole(bytes32 _role, address _account) public virtual _onlyDefaultPartnershipAdminRole {
        if(!_hasRole(_role, _account)) {
            _roles[_role].members[_account] = true;

            emit AdminGrantedRole(_role, _account);
        }
    }

    function revokePartnerDefinedRole(bytes32 _role, address _account) public virtual _onlyDefaultPartnershipAdminRole {
        if(_hasRole(_role, _account)) {
            _roles[_role].members[_account] = false;

            emit AdminRevokedRole(_role, _account);
        }
    }

    function hasPartnerDefinedRole(string memory _partnerName, bytes32 _role, address _account) external view virtual override returns (bool) {
        return _roles[_partnerDefinedRole(_partnerName, _role)].members[_account];
    }

    function isPartnershipAdmin(string memory _partnerName, address _addr)
        public
        view
        virtual
        override
        returns (bool)
    {
        bytes32 partnerAdmin = _partnershipAdminRole(_partnerName);
        return _hasRole(partnerAdmin, _addr);
    }

    function isPartnershipMember(string memory _partnerName, address _addr)
        public
        view
        virtual
        override
        returns (bool)
    {
        bytes32 partner = _partnershipRole(_partnerName);
        return _hasRole(partner, _addr);
    }

    function _partnershipAdminRole(string memory _partnerName)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked(PARTNERHSIP_ADMIN_PREFIX, _partnerName));
    }

    function _partnershipRole(string memory _partnerName)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked(PARTNERHSIP_PREFIX, _partnerName));
    }

    function _partnerDefinedRole(string memory _partnerName, bytes32 role_)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(PARTNERHSIP_PREFIX, _partnerName, role_));
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.0;

interface IPartnershipRegistry {
    event PartnerhipRegistered(string indexed name, address admin);
    event PartnerhipRemoved(string indexed name);
    event PartnerhipAdminChanged(
        string indexed name,
        address currentAdmin,
        address newAdmin
    );
    event PartnershipMemberAdded(string indexed name, address member);
    event PartnerDefinedRoleGranted(string indexed name, bytes32 role, address member);
    event PartnerDefinedRoleRevoked(string indexed name, bytes32 role, address member);

    event AdminGrantedRole(bytes32 role, address member);
    event AdminRevokedRole(bytes32 role, address member);

    function partnershipExist(string memory _partnerName)
        external
        returns (bool);

    function addPartnership(string memory _partnerName, address _admin) payable
        external;

    function removePartnership(string memory _partnerName) external;

    function changePartnershipAdmin(
        string memory _partnerName,
        address _newAdmin
    ) external;

    function addPartnershipMember(string memory _partnerName, address _member)
        external;

    function grantPartnerDefinedRole(string memory _partnerName, bytes32 _role, address _account) external;
    function revokePartnerDefinedRole(string memory _partnerName, bytes32 _role, address _account) external;
    function hasPartnerDefinedRole(string memory _partnerName, bytes32 _role, address _account) external view returns (bool);

    function isPartnershipMember(string memory _partnerName, address _addr)
        external
        returns (bool);

    function isPartnershipAdmin(string memory _partnerName, address _addr)
        external
        returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}