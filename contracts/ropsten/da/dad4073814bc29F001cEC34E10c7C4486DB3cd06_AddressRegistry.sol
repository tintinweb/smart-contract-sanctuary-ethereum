//SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AddressRegistry is IAddressRegistry, Initializable, AccessControl {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (AddressTypes => EnumerableSet.AddressSet) private addressSets;

    // solhint-disable-next-line var-name-mixedcase 
    bytes32 public immutable REGISTERED_ADDRESS = keccak256("REGISTERED_ROLE");

    modifier onlyRegistered () {
        require(hasRole(REGISTERED_ADDRESS, msg.sender), "NOT_REGISTERED");
        _;
    }

    function initialize() public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REGISTERED_ADDRESS, _msgSender());
    }

    function addRegistrar(address _addr) external override {
        require(_addr != address(0), "INVALID_ADDRESS");
        grantRole(REGISTERED_ADDRESS, _addr);

        emit RegisteredAddressAdded(_addr);
    }

    function removeRegistrar(address _addr) external override {
        require(_addr != address(0), "INVALID_ADDRESS");
        revokeRole(REGISTERED_ADDRESS, _addr);

        emit RegisteredAddressRemoved(_addr);
    }

    function addToRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
        uint256 arrayLength = _addresses.length;
        require(arrayLength > 0, "NO_ADDRESSES");
        EnumerableSet.AddressSet storage structToAddTo = addressSets[_index];

        for (uint256 i = 0; i < arrayLength; i++) {
            require(_addresses[i] != address(0), "INVALID_ADDRESS");
            require(structToAddTo.add(_addresses[i]), "ADD_FAIL");
        }

        emit AddedToRegistry(_addresses, _index);
    }

    function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
        EnumerableSet.AddressSet storage structToRemoveFrom = addressSets[_index];
        uint256 arrayLength = _addresses.length;
        require(arrayLength > 0, "NO_ADDRESSES");
        require(arrayLength <= structToRemoveFrom.length(), "TOO_MANY_ADDRESSES");

        for (uint256 i = 0; i < arrayLength; i++) {
            address currentAddress = _addresses[i];
            require(structToRemoveFrom.remove(currentAddress), "REMOVE_FAIL");
        }

        emit RemovedFromRegistry(_addresses, _index);
    }

    function getAddressForType(AddressTypes _index) external view override returns (address[] memory) {
        EnumerableSet.AddressSet storage structToReturn = addressSets[_index];
        uint256 arrayLength = structToReturn.length();

        address[] memory registryAddresses = new address[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            registryAddresses[i] = structToReturn.at(i);
        }
        return registryAddresses;
    }

    function checkAddress(address _addr, uint256 _index) external view override returns (bool) {
        EnumerableSet.AddressSet storage structToCheck = addressSets[AddressTypes(_index)];
        return structToCheck.contains(_addr);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *   @title Track addresses to be used in liquidity deployment
 *   Any controller used, asset deployed, or pool tracked within the
 *   system should be registered here
 */
interface IAddressRegistry {
    enum AddressTypes {
        Token,
        Controller,
        Pool
    }

    event RegisteredAddressAdded(address added);
    event RegisteredAddressRemoved(address removed);
    event AddedToRegistry(address[] addresses, AddressTypes);
    event RemovedFromRegistry(address[] addresses, AddressTypes);

    /// @notice Allows address with REGISTERED_ROLE to add a registered address
    /// @param _addr address to be added
    function addRegistrar(address _addr) external;

    /// @notice Allows address with REGISTERED_ROLE to remove a registered address
    /// @param _addr address to be removed
    function removeRegistrar(address _addr) external;

    /// @notice Allows array of addresses to be added to registry for certain index
    /// @param _addresses calldata array of addresses to be added to registry
    /// @param _index AddressTypes enum of index to add addresses to
    function addToRegistry(address[] calldata _addresses, AddressTypes _index) external;

    /// @notice Allows array of addresses to be removed from registry for certain index
    /// @param _addresses calldata array of addresses to be removed from registry
    /// @param _index AddressTypes enum of index to remove addresses from
    function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external;

    /// @notice Allows array of all addresses for certain index to be returned
    /// @param _index AddressTypes enum of index to be returned
    /// @return address[] memory of addresses from index
    function getAddressForType(AddressTypes _index) external view returns (address[] memory);

    /// @notice Allows checking that one address exists in certain index
    /// @param _addr address to be checked
    /// @param _index AddressTypes index to check address against
    /// @return bool tells whether address exists or not
    function checkAddress(address _addr, uint256 _index) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
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
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
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
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
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
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
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
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IManager.sol";
import "../interfaces/ILiquidityPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/events/CycleRolloverEvent.sol";
import "../interfaces/events/IEventSender.sol";
import "../interfaces/IEventProxy.sol";

//solhint-disable not-rely-on-time
contract Manager is IManager, Initializable, AccessControl, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
    bytes32 public constant MID_CYCLE_ROLE = keccak256("MID_CYCLE_ROLE");
    bytes32 public constant START_ROLLOVER_ROLE = keccak256("START_ROLLOVER_ROLE");

    uint256 public currentCycle; // Start timestamp of current cycle
    uint256 public currentCycleIndex; // Uint representing current cycle
    uint256 public cycleDuration; // Cycle duration in seconds

    bool public rolloverStarted;

    // Bytes32 controller id => controller address
    mapping(bytes32 => address) public registeredControllers;
    // Cycle index => ipfs rewards hash
    mapping(uint256 => string) public override cycleRewardsHashes;
    EnumerableSet.AddressSet private pools;
    EnumerableSet.Bytes32Set private controllerIds;

    // Reentrancy Guard
    bool private _entered;

    bool public _eventSend;

    uint256 public nextCycleStartTime;

    bool private isLogicContract;
    IEventProxy public eventProxy;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN_ROLE");
        _;
    }

    modifier onlyRollover() {
        require(hasRole(ROLLOVER_ROLE, _msgSender()), "NOT_ROLLOVER_ROLE");
        _;
    }

    modifier onlyMidCycle() {
        require(hasRole(MID_CYCLE_ROLE, _msgSender()), "NOT_MID_CYCLE_ROLE");
        _;
    }

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier onlyStartRollover() {
        require(hasRole(START_ROLLOVER_ROLE, _msgSender()), "NOT_START_ROLLOVER_ROLE");
        _;
    }

    constructor() public {
        isLogicContract = true;
    }

    function initialize(uint256 _cycleDuration, uint256 _nextCycleStartTime) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();

        cycleDuration = _cycleDuration;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ROLLOVER_ROLE, _msgSender());
        _setupRole(MID_CYCLE_ROLE, _msgSender());
        _setupRole(START_ROLLOVER_ROLE, _msgSender());

        setNextCycleStartTime(_nextCycleStartTime);
    }

    function registerController(bytes32 id, address controller) external override onlyAdmin {
        registeredControllers[id] = controller;
        require(controllerIds.add(id), "ADD_FAIL");
        emit ControllerRegistered(id, controller);
    }

    function unRegisterController(bytes32 id) external override onlyAdmin {
        emit ControllerUnregistered(id, registeredControllers[id]);
        delete registeredControllers[id];
        require(controllerIds.remove(id), "REMOVE_FAIL");
    }

    function registerPool(address pool) external override onlyAdmin {
        require(pools.add(pool), "ADD_FAIL");
        emit PoolRegistered(pool);
    }

    function unRegisterPool(address pool) external override onlyAdmin {
        require(pools.remove(pool), "REMOVE_FAIL");
        emit PoolUnregistered(pool);
    }

    function setCycleDuration(uint256 duration) external override onlyAdmin {
        require(duration > 60, "CYCLE_TOO_SHORT");
        cycleDuration = duration;
        emit CycleDurationSet(duration);
    }

    function setNextCycleStartTime(uint256 _nextCycleStartTime) public override onlyAdmin {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(_nextCycleStartTime > block.timestamp, "MUST_BE_FUTURE");
        nextCycleStartTime = _nextCycleStartTime;
        emit NextCycleStartSet(_nextCycleStartTime);
    }

    function getPools() external view override returns (address[] memory) {
        uint256 poolsLength = pools.length();
        address[] memory returnData = new address[](poolsLength);
        for (uint256 i = 0; i < poolsLength; i++) {
            returnData[i] = pools.at(i);
        }
        return returnData;
    }

    function getControllers() external view override returns (bytes32[] memory) {
        uint256 controllerIdsLength = controllerIds.length();
        bytes32[] memory returnData = new bytes32[](controllerIdsLength);
        for (uint256 i = 0; i < controllerIdsLength; i++) {
            returnData[i] = controllerIds.at(i);
        }
        return returnData;
    }

    function completeRollover(string calldata rewardsIpfsHash) external override onlyRollover {
        // Can't be hit via test cases, going to leave in anyways in case we ever change code
        require(nextCycleStartTime > 0, "SET_BEFORE_ROLLOVER");
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");
        _completeRollover(rewardsIpfsHash);
    }

    /// @notice Used for mid-cycle adjustments
    function executeMaintenance(MaintenanceExecution calldata params)
        external
        override
        onlyMidCycle
        nonReentrant
    {
        for (uint256 x = 0; x < params.cycleSteps.length; x++) {
            _executeControllerCommand(params.cycleSteps[x]);
        }
    }

    function executeRollover(RolloverExecution calldata params) external override onlyRollover nonReentrant {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");

        // Transfer deployable liquidity out of the pools and into the manager
        for (uint256 i = 0; i < params.poolData.length; i++) {
            require(pools.contains(params.poolData[i].pool), "INVALID_POOL");
            ILiquidityPool pool = ILiquidityPool(params.poolData[i].pool);
            IERC20 underlyingToken = pool.underlyer();
            underlyingToken.safeTransferFrom(
                address(pool),
                address(this),
                params.poolData[i].amount
            );
            emit LiquidityMovedToManager(params.poolData[i].pool, params.poolData[i].amount);
        }

        // Deploy or withdraw liquidity
        for (uint256 x = 0; x < params.cycleSteps.length; x++) {
            _executeControllerCommand(params.cycleSteps[x]);
        }

        // Transfer recovered liquidity back into the pools; leave no funds in the manager
        for (uint256 y = 0; y < params.poolsForWithdraw.length; y++) {
            require(pools.contains(params.poolsForWithdraw[y]), "INVALID_POOL");
            ILiquidityPool pool = ILiquidityPool(params.poolsForWithdraw[y]);
            IERC20 underlyingToken = pool.underlyer();

            uint256 managerBalance = underlyingToken.balanceOf(address(this));

            // transfer funds back to the pool if there are funds
            if (managerBalance > 0) {
                underlyingToken.safeTransfer(address(pool), managerBalance);
            }
            emit LiquidityMovedToPool(params.poolsForWithdraw[y], managerBalance);
        }

        if (params.complete) {
            _completeRollover(params.rewardsIpfsHash);
        }
    }

    function sweep(address[] calldata poolAddresses) external override onlyRollover {

        uint256 length = poolAddresses.length;
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address currentPoolAddress = poolAddresses[i];
            require(pools.contains(currentPoolAddress), "INVALID_ADDRESS");
            IERC20 underlyer = IERC20(ILiquidityPool(currentPoolAddress).underlyer());
            uint256 amount = underlyer.balanceOf(address(this));
            amounts[i] = amount;
            
            if (amount > 0) {
                underlyer.safeTransfer(currentPoolAddress, amount);
            }
        }
        emit ManagerSwept(poolAddresses, amounts);
    }

    function _executeControllerCommand(ControllerTransferData calldata transfer) private {
        require(!isLogicContract, "FORBIDDEN_CALL");

        address controllerAddress = registeredControllers[transfer.controllerId];
        require(controllerAddress != address(0), "INVALID_CONTROLLER");
        controllerAddress.functionDelegateCall(transfer.data, "CYCLE_STEP_EXECUTE_FAILED");
        emit DeploymentStepExecuted(transfer.controllerId, controllerAddress, transfer.data);
    }

    function startCycleRollover() external override onlyStartRollover {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");
        rolloverStarted = true;
        emit CycleRolloverStarted(block.timestamp);
    }

    function _completeRollover(string calldata rewardsIpfsHash) private {
        currentCycle = nextCycleStartTime;
        nextCycleStartTime = nextCycleStartTime.add(cycleDuration);
        cycleRewardsHashes[currentCycleIndex] = rewardsIpfsHash;
        currentCycleIndex = currentCycleIndex.add(1);
        rolloverStarted = false;

        bytes32 eventSig = "Cycle Complete";
        encodeAndSendData(eventSig);

        emit CycleRolloverComplete(block.timestamp);
    }

    function getCurrentCycle() external view override returns (uint256) {
        return currentCycle;
    }

    function getCycleDuration() external view override returns (uint256) {
        return cycleDuration;
    }

    function getCurrentCycleIndex() external view override returns (uint256) {
        return currentCycleIndex;
    }

    function getRolloverStatus() external view override returns (bool) {
        return rolloverStarted;
    }

    function setEventSend(bool _eventSendSet) external override onlyAdmin {
        require(address(eventProxy) != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function setupRole(bytes32 role) external override onlyAdmin {
        _setupRole(role, _msgSender());
    }

    function encodeAndSendData(bytes32 _eventSig) private onEventSend {
        require(address(eventProxy) != address(0), "ADDRESS_NOT_SET");

        bytes memory data = abi.encode(CycleRolloverEvent({
            eventSig: _eventSig,
            cycleIndex: currentCycleIndex,
            timestamp: currentCycle
        }));

       
        eventProxy.processMessageFromRoot(address(this), data);
    }
    function setEventProxy(address _eventProxy) external override onlyAdmin {
        require(_eventProxy != address(0), "ADDRESS INVALID");
        eventProxy = IEventProxy(_eventProxy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Controls the transition and execution of liquidity deployment cycles.
 *  Accepts instructions that can move assets from the Pools to the Exchanges
 *  and back. Can also move assets to the treasury when appropriate.
 */
interface IManager {
    // bytes can take on the form of deploying or recovering liquidity
    struct ControllerTransferData {
        bytes32 controllerId; // controller to target
        bytes data; // data the controller will pass
    }

    struct PoolTransferData {
        address pool; // pool to target
        uint256 amount; // amount to transfer
    }

    struct MaintenanceExecution {
        ControllerTransferData[] cycleSteps;
    }

    struct RolloverExecution {
        PoolTransferData[] poolData;
        ControllerTransferData[] cycleSteps;
        address[] poolsForWithdraw; //Pools to target for manager -> pool transfer
        bool complete; //Whether to mark the rollover complete
        string rewardsIpfsHash;
    }

    event ControllerRegistered(bytes32 id, address controller);
    event ControllerUnregistered(bytes32 id, address controller);
    event PoolRegistered(address pool);
    event PoolUnregistered(address pool);
    event CycleDurationSet(uint256 duration);
    event LiquidityMovedToManager(address pool, uint256 amount);
    event DeploymentStepExecuted(bytes32 controller, address adapaterAddress, bytes data);
    event LiquidityMovedToPool(address pool, uint256 amount);
    event CycleRolloverStarted(uint256 timestamp);
    event CycleRolloverComplete(uint256 timestamp);
    event NextCycleStartSet(uint256 nextCycleStartTime);
    event ManagerSwept(address[] addresses, uint256[] amounts);

    /// @notice Registers controller
    /// @param id Bytes32 id of controller
    /// @param controller Address of controller
    function registerController(bytes32 id, address controller) external;

    /// @notice Registers pool
    /// @param pool Address of pool
    function registerPool(address pool) external;

    /// @notice Unregisters controller
    /// @param id Bytes32 controller id
    function unRegisterController(bytes32 id) external;

    /// @notice Unregisters pool
    /// @param pool Address of pool
    function unRegisterPool(address pool) external;

    ///@notice Gets addresses of all pools registered
    ///@return Memory array of pool addresses
    function getPools() external view returns (address[] memory);

    ///@notice Gets ids of all controllers registered
    ///@return Memory array of Bytes32 controller ids
    function getControllers() external view returns (bytes32[] memory);

    ///@notice Allows for owner to set cycle duration
    ///@param duration Block durtation of cycle
    function setCycleDuration(uint256 duration) external;

    ///@notice Starts cycle rollover
    ///@dev Sets rolloverStarted state boolean to true
    function startCycleRollover() external;

    ///@notice Allows for controller commands to be executed midcycle
    ///@param params Contains data for controllers and params
    function executeMaintenance(MaintenanceExecution calldata params) external;

    ///@notice Allows for withdrawals and deposits for pools along with liq deployment
    ///@param params Contains various data for executing against pools and controllers
    function executeRollover(RolloverExecution calldata params) external;

    ///@notice Completes cycle rollover, publishes rewards hash to ipfs
    ///@param rewardsIpfsHash rewards hash uploaded to ipfs
    function completeRollover(string calldata rewardsIpfsHash) external;

    ///@notice Gets reward hash by cycle index
    ///@param index Cycle index to retrieve rewards hash
    ///@return String memory hash
    function cycleRewardsHashes(uint256 index) external view returns (string memory);

    ///@notice Gets current starting block
    ///@return uint256 with block number
    function getCurrentCycle() external view returns (uint256);

    ///@notice Gets current cycle index
    ///@return uint256 current cycle number
    function getCurrentCycleIndex() external view returns (uint256);

    ///@notice Gets current cycle duration
    ///@return uint256 in block of cycle duration
    function getCycleDuration() external view returns (uint256);

    ///@notice Gets cycle rollover status, true for rolling false for not
    ///@return Bool representing whether cycle is rolling over or not
    function getRolloverStatus() external view returns (bool);

    /// @notice Sets next cycle start time manually
    /// @param nextCycleStartTime uint256 that represents start of next cycle
    function setNextCycleStartTime(uint256 nextCycleStartTime) external;

    /// @notice Sweeps amanager contract for any leftover funds
    /// @param addresses array of addresses of pools to sweep funds into
    function sweep(address[] calldata addresses) external;

    /// @notice Setup a role using internal function _setupRole
    /// @param role keccak256 of the role keccak256("MY_ROLE");
    function setupRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../interfaces/IManager.sol";

/// @title Interface for Pool
/// @notice Allows users to deposit ERC-20 tokens to be deployed to market makers.
/// @notice Mints 1:1 tAsset on deposit, represeting an IOU for the undelrying token that is freely transferable.
/// @notice Holders of tAsset earn rewards based on duration their tokens were deployed and the demand for that asset.
/// @notice Holders of tAsset can redeem for underlying asset after issuing requestWithdrawal and waiting for the next cycle.
interface ILiquidityPool {
    struct WithdrawalInfo {
        uint256 minCycle;
        uint256 amount;
    }

    event WithdrawalRequested(address requestor, uint256 amount);
    event DepositsPaused();
    event DepositsUnpaused();

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the msg.sender.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function deposit(uint256 amount) external;

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the account.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function depositFor(address account, uint256 amount) external;

    /// @notice Requests that the manager prepare funds for withdrawal next cycle
    /// @notice Invoking this function when sender already has a currently pending request will overwrite that requested amount and reset the cycle timer
    /// @param amount Amount of fTokens requested to be redeemed
    function requestWithdrawal(uint256 amount) external;

    function approveManager(uint256 amount) external;

    /// @notice Sender must first invoke requestWithdrawal in a previous cycle
    /// @notice This function will burn the fAsset and transfers underlying asset back to sender
    /// @notice Will execute a partial withdrawal if either available liquidity or previously requested amount is insufficient
    /// @param amount Amount of fTokens to redeem, value can be in excess of available tokens, operation will be reduced to maximum permissible
    function withdraw(uint256 amount) external;

    /// @return Reference to the underlying ERC-20 contract
    function underlyer() external view returns (ERC20Upgradeable);

    /// @return Amount of liquidity that should not be deployed for market making (this liquidity will be used for completing requested withdrawals)
    function withheldLiquidity() external view returns (uint256);

    /// @notice Get withdraw requests for an account
    /// @param account User account to check
    /// @return minCycle Cycle - block number - that must be active before withdraw is allowed, amount Token amount requested
    function requestedWithdrawals(address account) external view returns (uint256, uint256);

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;

    // @notice Pause deposits only on the pool.
    function pauseDeposit() external;

    // @notice Unpause deposits only on the pool.
    function unpauseDeposit() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a cycle rollover is complete
struct CycleRolloverEvent {
    bytes32 eventSig;
    uint256 cycleIndex;
    uint256 timestamp;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;


interface IEventSender {
    event EventSendSet(bool eventSendSet);
    
    /// @notice Enables or disables the sending of events
    function setEventSend(bool eventSendSet) external;

    /// @notice Enables or disables the sending of events
    function setEventProxy(address _eventProxy) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

import "../fxPortal/IFxMessageProcessor.sol";

/**
 *  @title Used to route events coming from the State Sender system.
 *  An event has a “type” and the contract can determine where it needs to be forwarded/copied for processing.
 */
interface IEventProxy is IFxMessageProcessor {
    struct DestinationsBySenderAndEventType {
        address sender;
        bytes32 eventType;
        address[] destinations;
    }

    event SenderRegistrationChanged(address sender, bool allowed);
    event DestinationRegistered(address sender, address destination);
    event DestinationUnregistered(address sender, address destination);
    event SenderRegistered(address sender, bool allowed);
    event RegisterDestinations(DestinationsBySenderAndEventType[]);
    event UnregisterDestination(address sender, address l2Endpoint, bytes32 eventType);
    event EventSent(bytes32 eventType, address sender, address destination, bytes data);
    event SetGateway(bytes32 name, address gateway);

    /// @notice Toggles a senders ability to send an event through the contract
    /// @param sender Address of sender
    /// @param allowed Allowed to send event
    /// @dev Contracts should call as themselves, and so it will be the contract addresses registered here
    function setSenderRegistration(address sender, bool allowed) external;

    /// @notice For a sender/eventType, register destination contracts that should receive events
    /// @param destinationsBySenderAndEventType Destinations specifies all the destinations for a given sender/eventType combination
    /// @dev this COMPLETELY REPLACES all destinations for the sender/eventType
    function registerDestinations(
        DestinationsBySenderAndEventType[] memory destinationsBySenderAndEventType
    ) external;

    /// @notice retrieves all the registered destinations for a sender/eventType key
    function getRegisteredDestinations(address sender, bytes32 eventType)
        external
        view
        returns (address[] memory);

    /// @notice For a sender, unregister destination contracts on Polygon
    /// @param sender Address of sender
    function unregisterDestination(
        address sender,
        address l2Endpoint,
        bytes32 eventType
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(address rootMessageSender, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// solhint-disable max-states-count

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IStaking.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/IDelegateFunction.sol";
import "../interfaces/events/IEventSender.sol";
import "../interfaces/IEventProxy.sol";

contract Staking is IStaking, Initializable, Ownable, Pausable, ReentrancyGuard, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public tokeToken;
    IManager public manager;
    IEventProxy public eventProxy;

    address public treasury;

    uint256 public withheldLiquidity; // DEPRECATED
    //userAddress -> withdrawalInfo
    mapping(address => WithdrawalInfo) public requestedWithdrawals; // DEPRECATED

    //userAddress -> -> scheduleIndex -> staking detail
    mapping(address => mapping(uint256 => StakingDetails)) public userStakings;

    //userAddress -> scheduleIdx[]
    mapping(address => uint256[]) public userStakingSchedules;

    //Schedule id/index counter
    uint256 public nextScheduleIndex;
    //scheduleIndex/id -> schedule
    mapping(uint256 => StakingSchedule) public schedules;
    //scheduleIndex/id[]
    EnumerableSet.UintSet private scheduleIdxs;

    //Can deposit into a non-public schedule
    mapping(address => bool) public override permissionedDepositors;

    bool public _eventSend;

    IDelegateFunction public delegateFunction; //DEPRECATED

    // ScheduleIdx => notional address
    mapping(uint256 => address) public notionalAddresses;
    // address -> scheduleIdx -> WithdrawalInfo
    mapping(address => mapping(uint256 => WithdrawalInfo)) public withdrawalRequestsByIndex;

    modifier onlyPermissionedDepositors() {
        require(_isAllowedPermissionedDeposit(), "CALLER_NOT_PERMISSIONED");
        _;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    function initialize(
        IERC20 _tokeToken,
        IManager _manager,
        address _treasury,
        address _scheduleZeroNotional
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        require(address(_tokeToken) != address(0), "INVALID_TOKETOKEN");
        require(address(_manager) != address(0), "INVALID_MANAGER");
        require(_treasury != address(0), "INVALID_TREASURY");

        tokeToken = _tokeToken;
        manager = _manager;
        treasury = _treasury;

        //We want to be sure the schedule used for LP staking is first
        //because the order in which withdraws happen need to start with LP stakes
        _addSchedule(
            StakingSchedule({
                cliff: 0,
                duration: 1,
                interval: 1,
                setup: true,
                isActive: true,
                hardStart: 0,
                isPublic: true
            }),
            _scheduleZeroNotional
        );
    }

    function addSchedule(StakingSchedule memory schedule, address notional)
        external
        override
        onlyOwner
    {
        _addSchedule(schedule, notional);
    }

    function setPermissionedDepositor(address account, bool canDeposit)
        external
        override
        onlyOwner
    {
        permissionedDepositors[account] = canDeposit;

        emit PermissionedDepositorSet(account, canDeposit);
    }

    function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs)
        external
        override
        onlyOwner
    {
        userStakingSchedules[account] = userSchedulesIdxs;

        emit UserSchedulesSet(account, userSchedulesIdxs);
    }

    function getSchedules()
        external
        view
        override
        returns (StakingScheduleInfo[] memory retSchedules)
    {
        uint256 length = scheduleIdxs.length();
        retSchedules = new StakingScheduleInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            retSchedules[i] = StakingScheduleInfo(
                schedules[scheduleIdxs.at(i)],
                scheduleIdxs.at(i)
            );
        }
    }

    function getStakes(address account)
        external
        view
        override
        returns (StakingDetails[] memory stakes)
    {
        stakes = _getStakes(account);
    }

    function setNotionalAddresses(uint256[] calldata scheduleIdxArr, address[] calldata addresses)
        external
        override
        onlyOwner
    {
        require(scheduleIdxArr.length == addresses.length, "MISMATCH_LENGTH");
        for (uint256 i = 0; i < scheduleIdxArr.length; i++) {
            uint256 currentScheduleIdx = scheduleIdxArr[i];
            address currentAddress = addresses[i];
            require(scheduleIdxs.contains(currentScheduleIdx), "INDEX_DOESNT_EXIST");
            require(currentAddress != address(0), "INVALID_ADDRESS");

            notionalAddresses[currentScheduleIdx] = currentAddress;
        }
        emit NotionalAddressesSet(scheduleIdxArr, addresses);
    }

    function balanceOf(address account) public view override returns (uint256 value) {
        value = 0;
        uint256 scheduleCount = userStakingSchedules[account].length;
        for (uint256 i = 0; i < scheduleCount; i++) {
            uint256 remaining = userStakings[account][userStakingSchedules[account][i]].initial.sub(
                userStakings[account][userStakingSchedules[account][i]].withdrawn
            );
            uint256 slashed = userStakings[account][userStakingSchedules[account][i]].slashed;
            if (remaining > slashed) {
                value = value.add(remaining.sub(slashed));
            }
        }
    }

    function availableForWithdrawal(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256)
    {
        return _availableForWithdrawal(account, scheduleIndex);
    }

    function unvested(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256 value)
    {
        value = 0;
        StakingDetails memory stake = userStakings[account][scheduleIndex];

        value = stake.initial.sub(_vested(account, scheduleIndex));
    }

    function vested(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256 value)
    {
        return _vested(account, scheduleIndex);
    }

    function deposit(uint256 amount, uint256 scheduleIndex) external override {
        _depositFor(msg.sender, amount, scheduleIndex);
    }

    function deposit(uint256 amount) external override {
        _depositFor(msg.sender, amount, 0);
    }

    function depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) external override onlyPermissionedDepositors {
        _depositFor(account, amount, scheduleIndex);
    }

    function depositWithSchedule(
        address account,
        uint256 amount,
        StakingSchedule calldata schedule,
        address notional
    ) external override onlyPermissionedDepositors {
        uint256 scheduleIx = nextScheduleIndex;
        _addSchedule(schedule, notional);
        _depositFor(account, amount, scheduleIx);
    }

    function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");
        uint256 availableAmount = _availableForWithdrawal(msg.sender, scheduleIdx);
        require(availableAmount >= amount, "INSUFFICIENT_AVAILABLE");

        withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount = amount;
        if (manager.getRolloverStatus()) {
            withdrawalRequestsByIndex[msg.sender][scheduleIdx].minCycleIndex = manager
                .getCurrentCycleIndex()
                .add(2);
        } else {
            withdrawalRequestsByIndex[msg.sender][scheduleIdx].minCycleIndex = manager
                .getCurrentCycleIndex()
                .add(1);
        }

        bytes32 eventSig = "Withdrawal Request";
        StakingDetails memory userStake = userStakings[msg.sender][scheduleIdx];
        uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(
            amount
        );
        encodeAndSendData(eventSig, msg.sender, scheduleIdx, voteTotal);

        emit WithdrawalRequested(msg.sender, scheduleIdx, amount);
    }

    function withdraw(uint256 amount, uint256 scheduleIdx)
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(amount > 0, "NO_WITHDRAWAL");
        require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");
        _withdraw(amount, scheduleIdx);
    }

    function withdraw(uint256 amount) external override whenNotPaused nonReentrant {
        require(amount > 0, "INVALID_AMOUNT");
        _withdraw(amount, 0);
    }

    function slash(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 scheduleIndex
    ) external override onlyOwner whenNotPaused {
        require(accounts.length == amounts.length, "LENGTH_MISMATCH");
        StakingSchedule storage schedule = schedules[scheduleIndex];
        require(schedule.setup, "INVALID_SCHEDULE");

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 amount = amounts[i];

            require(amount > 0, "INVALID_AMOUNT");
            require(account != address(0), "INVALID_ADDRESS");

            StakingDetails memory userStake = userStakings[account][scheduleIndex];
            require(userStake.initial > 0, "NO_VESTING");

            uint256 availableToSlash = 0;
            uint256 remaining = userStake.initial.sub(userStake.withdrawn);
            if (remaining > userStake.slashed) {
                availableToSlash = remaining.sub(userStake.slashed);
            }

            require(availableToSlash >= amount, "INSUFFICIENT_AVAILABLE");

            userStake.slashed = userStake.slashed.add(amount);
            userStakings[account][scheduleIndex] = userStake;

            uint256 totalLeft = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn)));

            if (withdrawalRequestsByIndex[account][scheduleIndex].amount > totalLeft) {
                withdrawalRequestsByIndex[account][scheduleIndex].amount = totalLeft;
            }

            uint256 voteAmount = totalLeft.sub(
                withdrawalRequestsByIndex[account][scheduleIndex].amount
            );
            bytes32 eventSig = "Slashed";

            encodeAndSendData(eventSig, account, scheduleIndex, voteAmount);

            tokeToken.safeTransfer(treasury, amount);

            emit Slashed(account, amount, scheduleIndex);
        }
    }

    function setScheduleStatus(uint256 scheduleId, bool activeBool) external override onlyOwner {
        StakingSchedule storage schedule = schedules[scheduleId];
        schedule.isActive = activeBool;

        emit ScheduleStatusSet(scheduleId, activeBool);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }


    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(address(eventProxy) != address(0), "DESTINATIONS_NOT_SET");

        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _availableForWithdrawal(address account, uint256 scheduleIndex)
        private
        view
        returns (uint256)
    {
        StakingDetails memory stake = userStakings[account][scheduleIndex];
        uint256 vestedWoWithdrawn = _vested(account, scheduleIndex).sub(stake.withdrawn);
        if (stake.slashed > vestedWoWithdrawn) return 0;

        return vestedWoWithdrawn.sub(stake.slashed);
    }

    function _depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) private nonReentrant whenNotPaused {
        StakingSchedule memory schedule = schedules[scheduleIndex];
        require(amount > 0, "INVALID_AMOUNT");
        require(schedule.setup, "INVALID_SCHEDULE");
        require(schedule.isActive, "INACTIVE_SCHEDULE");
        require(account != address(0), "INVALID_ADDRESS");
        require(schedule.isPublic || _isAllowedPermissionedDeposit(), "PERMISSIONED_SCHEDULE");

        StakingDetails memory userStake = _updateStakingDetails(scheduleIndex, account, amount);

        bytes32 eventSig = "Deposit";
        uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(
            withdrawalRequestsByIndex[account][scheduleIndex].amount
        );
        encodeAndSendData(eventSig, account, scheduleIndex, voteTotal);

        tokeToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(account, amount, scheduleIndex);
    }

    function _withdraw(uint256 amount, uint256 scheduleIdx) private {
        WithdrawalInfo memory request = withdrawalRequestsByIndex[msg.sender][scheduleIdx];
        require(amount <= request.amount, "INSUFFICIENT_AVAILABLE");
        require(request.minCycleIndex <= manager.getCurrentCycleIndex(), "INVALID_CYCLE");

        StakingDetails memory userStake = userStakings[msg.sender][scheduleIdx];
        userStake.withdrawn = userStake.withdrawn.add(amount);
        userStakings[msg.sender][scheduleIdx] = userStake;

        request.amount = request.amount.sub(amount);
        withdrawalRequestsByIndex[msg.sender][scheduleIdx] = request;

        if (request.amount == 0) {
            delete withdrawalRequestsByIndex[msg.sender][scheduleIdx];
        }

        tokeToken.safeTransfer(msg.sender, amount);

        emit WithdrawCompleted(msg.sender, scheduleIdx, amount);
    }

    function _vested(address account, uint256 scheduleIndex) private view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        uint256 value = 0;
        StakingDetails memory stake = userStakings[account][scheduleIndex];
        StakingSchedule memory schedule = schedules[scheduleIndex];

        uint256 cliffTimestamp = stake.started.add(schedule.cliff);
        if (cliffTimestamp <= timestamp) {
            if (cliffTimestamp.add(schedule.duration) <= timestamp) {
                value = stake.initial;
            } else {
                uint256 secondsStaked = Math.max(timestamp.sub(cliffTimestamp), 1);
                //Precision loss is intentional. Enables the interval buckets
                uint256 effectiveSecondsStaked = (secondsStaked.div(schedule.interval)).mul(
                    schedule.interval
                );
                value = stake.initial.mul(effectiveSecondsStaked).div(schedule.duration);
            }
        }

        return value;
    }

    function _addSchedule(StakingSchedule memory schedule, address notional) private {
        require(schedule.duration > 0, "INVALID_DURATION");
        require(schedule.interval > 0, "INVALID_INTERVAL");
        require(notional != address(0), "INVALID_ADDRESS");

        schedule.setup = true;
        uint256 index = nextScheduleIndex;
        schedules[index] = schedule;
        notionalAddresses[index] = notional;
        require(scheduleIdxs.add(index), "ADD_FAIL");
        nextScheduleIndex = nextScheduleIndex.add(1);

        emit ScheduleAdded(
            index,
            schedule.cliff,
            schedule.duration,
            schedule.interval,
            schedule.setup,
            schedule.isActive,
            schedule.hardStart,
            notional
        );
    }

    function _getStakes(address account) private view returns (StakingDetails[] memory stakes) {
        uint256 stakeCnt = userStakingSchedules[account].length;
        stakes = new StakingDetails[](stakeCnt);

        for (uint256 i = 0; i < stakeCnt; i++) {
            stakes[i] = userStakings[account][userStakingSchedules[account][i]];
        }
    }

    function _isAllowedPermissionedDeposit() private view returns (bool) {
        return permissionedDepositors[msg.sender] || msg.sender == owner();
    }

    function encodeAndSendData(
        bytes32 _eventSig,
        address _user,
        uint256 _scheduleIdx,
        uint256 _userBalance
    ) private onEventSend {
        require(address(eventProxy) != address(0), "ADDRESS_NOT_SET");
        address notionalAddress = notionalAddresses[_scheduleIdx];

        bytes memory data = abi.encode(
            BalanceUpdateEvent({
                eventSig: _eventSig,
                account: _user,
                token: notionalAddress,
                amount: _userBalance
            })
        );

        eventProxy.processMessageFromRoot(address(this), data);
    }
    function setEventProxy(address _eventProxy) external override onEventSend {
        require(_eventProxy != address(0), "ADDRESS INVALID");
        eventProxy = IEventProxy(_eventProxy);
    }

    function _updateStakingDetails(
        uint256 scheduleIdx,
        address account,
        uint256 amount
    ) private returns (StakingDetails memory) {
        StakingDetails memory stake = userStakings[account][scheduleIdx];
        if (stake.started == 0) {
            userStakingSchedules[account].push(scheduleIdx);
            StakingSchedule memory schedule = schedules[scheduleIdx];
            if (schedule.hardStart > 0) {
                stake.started = schedule.hardStart;
            } else {
                //solhint-disable-next-line not-rely-on-time
                stake.started = block.timestamp;
            }
        }
        stake.initial = stake.initial.add(amount);
        stake.scheduleIx = scheduleIdx;
        userStakings[account][scheduleIdx] = stake;

        return stake;
    }

    function depositWithdrawEvent(
        address withdrawUser,
        uint256 withdrawAmount,
        uint256 withdrawScheduleIdx,
        address depositUser,
        uint256 depositAmount,
        uint256 depositScheduleIdx
    ) private {
        bytes32 withdrawEvent = "Withdraw";
        bytes32 depositEvent = "Deposit";
        encodeAndSendData(withdrawEvent, withdrawUser, withdrawScheduleIdx, withdrawAmount);
        encodeAndSendData(depositEvent, depositUser, depositScheduleIdx, depositAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Allows for the staking and vesting of TOKE for
 *  liquidity directors. Schedules can be added to enable various
 *  cliff+duration/interval unlock periods for vesting tokens.
 */
interface IStaking {
    struct StakingSchedule {
        uint256 cliff; // Duration in seconds before staking starts
        uint256 duration; // Seconds it takes for entire amount to stake
        uint256 interval; // Seconds it takes for a chunk to stake
        bool setup; //Just so we know its there
        bool isActive; //Whether we can setup new stakes with the schedule
        uint256 hardStart; //Stakings will always start at this timestamp if set
        bool isPublic; //Schedule can be written to by any account
    }

    struct StakingScheduleInfo {
        StakingSchedule schedule;
        uint256 index;
    }

    struct StakingDetails {
        uint256 initial; //Initial amount of asset when stake was created, total amount to be staked before slashing
        uint256 withdrawn; //Amount that was staked and subsequently withdrawn
        uint256 slashed; //Amount that has been slashed
        uint256 started; //Timestamp at which the stake started
        uint256 scheduleIx;
    }

    struct WithdrawalInfo {
        uint256 minCycleIndex;
        uint256 amount;
    }

    struct QueuedTransfer {
        address from;
        uint256 scheduleIdxFrom;
        uint256 scheduleIdxTo;
        uint256 amount;
        address to;
    }

    event ScheduleAdded(
        uint256 scheduleIndex,
        uint256 cliff,
        uint256 duration,
        uint256 interval,
        bool setup,
        bool isActive,
        uint256 hardStart,
        address notional
    );
    event ScheduleRemoved(uint256 scheduleIndex);
    event WithdrawalRequested(address account, uint256 scheduleIdx, uint256 amount);
    event WithdrawCompleted(address account, uint256 scheduleIdx, uint256 amount);
    event Deposited(address account, uint256 amount, uint256 scheduleIx);
    event Slashed(address account, uint256 amount, uint256 scheduleIx);
    event PermissionedDepositorSet(address depositor, bool allowed);
    event UserSchedulesSet(address account, uint256[] userSchedulesIdxs);
    event NotionalAddressesSet(uint256[] scheduleIdxs, address[] addresses);
    event ScheduleStatusSet(uint256 scheduleId, bool isActive);
    event StakeTransferred(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event ZeroSweep(address user, uint256 amount, uint256 scheduleFrom);
    event TransferApproverSet(address approverAddress);
    event TransferQueued(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event QueuedTransferRemoved(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event QueuedTransferRejected(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );

    ///@notice Allows for checking of user address in permissionedDepositors mapping
    ///@param account Address of account being checked
    ///@return Boolean, true if address exists in mapping
    function permissionedDepositors(address account) external returns (bool);

    ///@notice Allows owner to set a multitude of schedules that an address has access to
    ///@param account User address
    ///@param userSchedulesIdxs Array of schedule indexes
    function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs) external;

    ///@notice Allows owner to add schedule
    ///@param schedule A StakingSchedule struct that contains all info needed to make a schedule
    ///@param notional Notional addrss for schedule, used to send balances to L2 for voting purposes
    function addSchedule(StakingSchedule memory schedule, address notional) external;

    ///@notice Gets all info on all schedules
    ///@return retSchedules An array of StakingScheduleInfo struct
    function getSchedules() external view returns (StakingScheduleInfo[] memory retSchedules);

    ///@notice Allows owner to set a permissioned depositor
    ///@param account User address
    ///@param canDeposit Boolean representing whether user can deposit
    function setPermissionedDepositor(address account, bool canDeposit) external;

    ///@notice Allows a user to get the stakes of an account
    ///@param account Address that is being checked for stakes
    ///@return stakes StakingDetails array containing info about account's stakes
    function getStakes(address account) external view returns (StakingDetails[] memory stakes);

    ///@notice Gets total value staked for an address across all schedules
    ///@param account Address for which total stake is being calculated
    ///@return value uint256 total of account
    function balanceOf(address account) external view returns (uint256 value);

    ///@notice Returns amount available to withdraw for an account and schedule Index
    ///@param account Address that is being checked for withdrawals
    ///@param scheduleIndex Index of schedule that is being checked for withdrawals
    function availableForWithdrawal(address account, uint256 scheduleIndex)
        external
        view
        returns (uint256);

    ///@notice Returns unvested amount for certain address and schedule index
    ///@param account Address being checked for unvested amount
    ///@param scheduleIndex Schedule index being checked for unvested amount
    ///@return value Uint256 representing unvested amount
    function unvested(address account, uint256 scheduleIndex) external view returns (uint256 value);

    ///@notice Returns vested amount for address and schedule index
    ///@param account Address being checked for vested amount
    ///@param scheduleIndex Schedule index being checked for vested amount
    ///@return value Uint256 vested
    function vested(address account, uint256 scheduleIndex) external view returns (uint256 value);

    ///@notice Allows user to deposit token to specific vesting / staking schedule
    ///@param amount Uint256 amount to be deposited
    ///@param scheduleIndex Uint256 representing schedule to user
    function deposit(uint256 amount, uint256 scheduleIndex) external;

    /// @notice Allows users to deposit into 0 schedule
    /// @param amount Deposit amount
    function deposit(uint256 amount) external;

    ///@notice Allows account to deposit on behalf of other account
    ///@param account Account to be deposited for
    ///@param amount Amount to be deposited
    ///@param scheduleIndex Index of schedule to be used for deposit
    function depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) external;

    ///@notice Allows permissioned depositors to deposit into custom schedule
    ///@param account Address of account being deposited for
    ///@param amount Uint256 amount being deposited
    ///@param schedule StakingSchedule struct containing details needed for new schedule
    ///@param notional Notional address attached to schedule, allows for different voting weights on L2
    function depositWithSchedule(
        address account,
        uint256 amount,
        StakingSchedule calldata schedule,
        address notional
    ) external;

    ///@notice User can request withdrawal from staking contract at end of cycle
    ///@notice Performs checks to make sure amount <= amount available
    ///@param amount Amount to withdraw
    ///@param scheduleIdx Schedule index for withdrawal Request
    function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external;

    ///@notice Allows for withdrawal after successful withdraw request and proper amount of cycles passed
    ///@param amount Amount to withdraw
    ///@param scheduleIdx Schedule to withdraw from
    function withdraw(uint256 amount, uint256 scheduleIdx) external;

    /// @notice Allows owner to set schedule to active or not
    /// @param scheduleIndex Schedule index to set isActive boolean
    /// @param activeBoolean Bool to set schedule active or not
    function setScheduleStatus(uint256 scheduleIndex, bool activeBoolean) external;

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;

    /// @notice Used to slash user funds when needed
    /// @notice accounts and amounts arrays must be same length
    /// @notice Only one scheduleIndex can be slashed at a time
    /// @dev Implementation must be restructed to owner account
    /// @param accounts Array of accounts to slash
    /// @param amounts Array of amounts that corresponds with accounts
    /// @param scheduleIndex scheduleIndex of users that are being slashed
    function slash(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 scheduleIndex
    ) external;

    /// @notice Set the address used to denote the token amount for a particular schedule
    /// @dev Relates to the Balance Tracker tracking of tokens and balances. Each schedule is tracked separately
    function setNotionalAddresses(uint256[] calldata scheduleIdxArr, address[] calldata addresses)
        external;

    /// @notice Withdraw from the default schedule. Must have a request in previously
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a users balance changes
struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./structs/DelegateMapView.sol";
import "./structs/Signature.sol";

/**
 *   @title Manages the state of an accounts delegation settings.
 *   Allows for various methods of validation as well as enabling
 *   different system functions to be delegated to different accounts
 */
interface IDelegateFunction {
    struct AllowedFunctionSet {
        bytes32 id;
    }

    struct FunctionsListPayload {
        bytes32[] sets;
        uint256 nonce;
    }

    struct DelegatePayload {
        DelegateMap[] sets;
        uint256 nonce;
    }

    struct DelegateMap {
        bytes32 functionId;
        address otherParty;
        bool mustRelinquish;
    }

    struct Destination {
        address otherParty;
        bool mustRelinquish;
        bool pending;
    }

    struct DelegatedTo {
        address originalParty;
        bytes32 functionId;
    }

    event AllowedFunctionsSet(AllowedFunctionSet[] functions);
    event PendingDelegationAdded(address from, address to, bytes32 functionId, bool mustRelinquish);
    event PendingDelegationRemoved(
        address from,
        address to,
        bytes32 functionId,
        bool mustRelinquish
    );
    event DelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRelinquished(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationAccepted(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRejected(address from, address to, bytes32 functionId, bool mustRelinquish);

    /// @notice Get the current nonce a contract wallet should use
    /// @param account Account to query
    /// @return nonce Nonce that should be used for next call
    function contractWalletNonces(address account) external returns (uint256 nonce);

    /// @notice Get an accounts current delegations
    /// @dev These may be in a pending state
    /// @param from Account that is delegating functions away
    /// @return maps List of delegations in various states of approval
    function getDelegations(address from) external view returns (DelegateMapView[] memory maps);

    /// @notice Get an accounts delegation of a specific function
    /// @dev These may be in a pending state
    /// @param from Account that is the delegation functions away
    /// @return map Delegation info
    function getDelegation(address from, bytes32 functionId)
        external
        view
        returns (DelegateMapView memory map);

    /// @notice Initiate delegation of one or more system functions to different account(s)
    /// @param sets Delegation instructions for the contract to initiate
    function delegate(DelegateMap[] memory sets) external;

    /// @notice Initiate delegation on behalf of a contract that supports ERC1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param delegatePayload Sets of DelegateMap objects
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function delegateWithEIP1271(
        address contractAddress,
        DelegatePayload memory delegatePayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Accept one or more delegations from another account
    /// @param incoming Delegation details being accepted
    function acceptDelegation(DelegatedTo[] calldata incoming) external;

    /// @notice Remove one or more delegation that you have previously setup
    function removeDelegation(bytes32[] calldata functionIds) external;

    /// @notice Remove one or more delegations that you have previously setup on behalf of a contract supporting EIP1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function removeDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Reject one or more delegations being sent to you
    /// @param rejections Delegations to reject
    function rejectDelegation(DelegatedTo[] calldata rejections) external;

    /// @notice Remove one or more delegations that you have previously accepted
    function relinquishDelegation(DelegatedTo[] calldata relinquish) external;

    /// @notice Cancel one or more delegations you have setup but that has not yet been accepted
    /// @param functionIds System functions you wish to retain control of
    function cancelPendingDelegation(bytes32[] calldata functionIds) external;

    /// @notice Cancel one or more delegations you have setup on behalf of a contract that supported EIP1271, but that has not yet been accepted
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function cancelPendingDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Add to the list of system functions that are allowed to be delegated
    /// @param functions New system function ids
    function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/// @notice Stores votes and rewards delegation mapping in DelegateFunction
struct DelegateMapView {
    bytes32 functionId;
    address otherParty;
    bool mustRelinquish;
    bool pending;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/// @notice Denotes the type of signature being submitted to contracts that support multiple
enum SignatureType {
    INVALID,
    // Specifically signTypedData_v4
    EIP712,
    // Specifically personal_sign
    ETHSIGN
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/IEventSender.sol";
import "../interfaces/IEventProxy.sol";

/**
 * @title Specialized implementation of the Pool contract that allows the
 * same rules as Staking when it comes to withdrawal requests. That is,
 * voting balances are updated on request instead of completion of withdrawal
 *
 */
contract TokeVotePool is ILiquidityPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public override underlyer; // Underlying ERC20 token
    IManager public manager;
    IEventProxy public eventProxy;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

    // NonReentrant
    bool private _entered;
    bool public _eventSend;

    bool public depositsPaused;

    event BalanceEventUpdated(address[] addresses);

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier whenDepositsNotPaused() {
        require(!paused(), "Pausable: paused");
        require(!depositsPaused, "DEPOSITS_PAUSED");
        _;
    }

    function initialize(
        ERC20 _underlyer,
        IManager _manager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        require(address(_underlyer) != address(0), "ZERO_ADDRESS");
        require(address(_manager) != address(0), "ZERO_ADDRESS");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        underlyer = _underlyer;
        manager = _manager;
    }

    ///@notice Gets decimals of underlyer so that tAsset decimals will match
    function decimals() public view override returns (uint8) {
        return underlyer.decimals();
    }

    function deposit(uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, account, amount);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev No withdrawal permitted unless currentCycle >= minCycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    function withdraw(uint256 requestedAmount) external override whenNotPaused nonReentrant {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(underlyer.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        // Checks for manager cycle and if user is allowed to withdraw based on their minimum withdrawal cycle
        require(
            requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        // If full amount withdrawn delete from mapping
        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);

        _burn(msg.sender, requestedAmount);
        underlyer.safeTransfer(msg.sender, requestedAmount);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);
    }

    /// @dev Adjusts the withheldLiquidity as necessary
    /// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

        //adjust withheld liquidity by removing the original withheld amount and adding the new amount
        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        if (manager.getRolloverStatus()) {
            // If manger is currently rolling over add two to min withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
        } else {
            // If manager is not rolling over add one to minimum withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
        }

        address[] memory senderAddress = new address[](1);
        senderAddress[0] = msg.sender;
        triggerBalanceUpdateEvent(senderAddress);

        emit WithdrawalRequested(msg.sender, amount);
    }

    function triggerBalanceUpdateEvent(address[] memory _addresses) public {
        bytes32 eventSig = "Withdrawal Request";
        for (uint256 i = 0; i < _addresses.length; i++) {
            encodeAndSendData(eventSig, _addresses[i]);
        }

        emit BalanceEventUpdated(_addresses);
    }

    function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
        if (requestedWithdrawals[sender].amount > 0) {
            //reduce requested withdraw amount by transferred amount;
            uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
                Math.min(amount, requestedWithdrawals[sender].amount)
            );

            //subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
            withheldLiquidity = withheldLiquidity.sub(
                requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl)
            );

            //update the requested withdraw for user
            requestedWithdrawals[sender].amount = newRequestedWithdrawl;

            //if the withdraw request is 0, empty it out
            if (requestedWithdrawals[sender].amount == 0) {
                delete requestedWithdrawals[sender];
            }
        }
    }

    function approveManager(uint256 amount) public override onlyOwner {
        uint256 currentAllowance = underlyer.allowance(address(this), address(manager));
        if (currentAllowance < amount) {
            uint256 delta = amount.sub(currentAllowance);
            underlyer.safeIncreaseAllowance(address(manager), delta);
        } else {
            uint256 delta = currentAllowance.sub(amount);
            underlyer.safeDecreaseAllowance(address(manager), delta);
        }
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        bool success = super.transfer(recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, msg.sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        bool success = super.transferFrom(sender, recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function pauseDeposit() external override onlyOwner {
        depositsPaused = true;

        emit DepositsPaused();
    }

    function unpauseDeposit() external override onlyOwner {
        depositsPaused = false;

        emit DepositsUnpaused();
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(address(eventProxy) != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _deposit(
        address fromAccount,
        address toAccount,
        uint256 amount
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(toAccount != address(0), "INVALID_ADDRESS");

        _mint(toAccount, amount);
        underlyer.safeTransferFrom(fromAccount, address(this), amount);

        bytes32 eventSig = "Deposit";
        encodeAndSendData(eventSig, toAccount);
    }

    function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
        require(address(eventProxy) != address(0), "ADDRESS_NOT_SET");

        uint256 userBalance = balanceOf(_user).sub(requestedWithdrawals[_user].amount);
        bytes memory data = abi.encode(
            BalanceUpdateEvent({
                eventSig: _eventSig,
                account: _user,
                token: address(this),
                amount: userBalance
            })
        );

        eventProxy.processMessageFromRoot(address(this), data);
    }
    function setEventProxy(address _eventProxy) external override onEventSend {
        require(_eventProxy != address(0), "ADDRESS INVALID");
        eventProxy = IEventProxy(_eventProxy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/IEventSender.sol";
import "../interfaces/IEventProxy.sol";

contract Pool is ILiquidityPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public override underlyer; // Underlying ERC20 token
    IManager public manager;
    IEventProxy public eventProxy;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

    // NonReentrant
    bool private _entered;
    bool public _eventSend;

    bool public depositsPaused;

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier whenDepositsNotPaused() {
        require(!paused(), "Pausable: paused");
        require(!depositsPaused, "DEPOSITS_PAUSED");
        _;
    }

    function initialize(
        ERC20 _underlyer,
        IManager _manager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        require(address(_underlyer) != address(0), "ZERO_ADDRESS");
        require(address(_manager) != address(0), "ZERO_ADDRESS");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        underlyer = _underlyer;
        manager = _manager;
    }

    ///@notice Gets decimals of underlyer so that tAsset decimals will match
    function decimals() public view override returns (uint8) {
        return underlyer.decimals();
    }

    function deposit(uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, account, amount);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev No withdrawal permitted unless currentCycle >= minCycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    function withdraw(uint256 requestedAmount) external override whenNotPaused nonReentrant {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(underlyer.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        // Checks for manager cycle and if user is allowed to withdraw based on their minimum withdrawal cycle
        require(
            requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        // If full amount withdrawn delete from mapping
        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);

        _burn(msg.sender, requestedAmount);
        underlyer.safeTransfer(msg.sender, requestedAmount);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);
    }

    /// @dev Adjusts the withheldLiquidity as necessary
    /// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

        //adjust withheld liquidity by removing the original withheld amount and adding the new amount
        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        if (manager.getRolloverStatus()) {
            // If manger is currently rolling over add two to min withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
        } else {
            // If manager is not rolling over add one to minimum withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
        }

        emit WithdrawalRequested(msg.sender, amount);
    }

    function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
        if (requestedWithdrawals[sender].amount > 0) {
            //reduce requested withdraw amount by transferred amount;
            uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
                Math.min(amount, requestedWithdrawals[sender].amount)
            );

            //subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
            withheldLiquidity = withheldLiquidity.sub(
                requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl)
            );

            //update the requested withdraw for user
            requestedWithdrawals[sender].amount = newRequestedWithdrawl;

            //if the withdraw request is 0, empty it out
            if (requestedWithdrawals[sender].amount == 0) {
                delete requestedWithdrawals[sender];
            }
        }
    }

    function approveManager(uint256 amount) public override onlyOwner {
        uint256 currentAllowance = underlyer.allowance(address(this), address(manager));
        if (currentAllowance < amount) {
            uint256 delta = amount.sub(currentAllowance);
            underlyer.safeIncreaseAllowance(address(manager), delta);
        } else {
            uint256 delta = currentAllowance.sub(amount);
            underlyer.safeDecreaseAllowance(address(manager), delta);
        }
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        bool success = super.transfer(recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, msg.sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        bool success = super.transferFrom(sender, recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    function pauseDeposit() external override onlyOwner {
        depositsPaused = true;

        emit DepositsPaused();
    }

    function unpauseDeposit() external override onlyOwner {
        depositsPaused = false;

        emit DepositsUnpaused();
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

   
    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(address(eventProxy) != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _deposit(
        address fromAccount,
        address toAccount,
        uint256 amount
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(toAccount != address(0), "INVALID_ADDRESS");

        _mint(toAccount, amount);
        underlyer.safeTransferFrom(fromAccount, address(this), amount);

        bytes32 eventSig = "Deposit";
        encodeAndSendData(eventSig, toAccount);
    }

    function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
        require(address(eventProxy) != address(0), "ADDRESS_NOT_SET");

        uint256 userBalance = balanceOf(_user);
        bytes memory data = abi.encode(
            BalanceUpdateEvent({
                eventSig: _eventSig,
                account: _user,
                token: address(this),
                amount: userBalance
            })
        );

        eventProxy.processMessageFromRoot(address(this), data);
    }
    function setEventProxy(address _eventProxy) external override onEventSend {
        require(_eventProxy != address(0), "ADDRESS INVALID");
        eventProxy = IEventProxy(_eventProxy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityEthPool.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {AddressUpgradeable as Address} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/IEventSender.sol";
import "../interfaces/IEventProxy.sol";

contract EthPool is ILiquidityEthPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    /// @dev TODO: Hardcode addresses, make immuatable, remove from initializer
    IWETH public override weth;
    IManager public manager;
    IEventProxy public eventProxy;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

    // NonReentrant
    bool private _entered;

    bool public _eventSend;

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    /// @dev necessary to receive ETH
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function initialize(
        IWETH _weth,
        IManager _manager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        require(address(_weth) != address(0), "ZERO_ADDRESS");
        require(address(_manager) != address(0), "ZERO_ADDRESS");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
        weth = _weth;
        manager = _manager;
        withheldLiquidity = 0;
    }

    function deposit(uint256 amount) external payable override whenNotPaused {
        _deposit(msg.sender, msg.sender, amount, msg.value);
    }

    function depositFor(address account, uint256 amount) external payable override whenNotPaused {
        _deposit(msg.sender, account, amount, msg.value);
    }

    function underlyer() external view override returns (address) {
        return address(weth);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev No withdrawal permitted unless currentCycle >= minCycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    function withdraw(uint256 requestedAmount, bool asEth) external override whenNotPaused nonReentrant {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(weth.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        require(
            requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        // Delete if all assets withdrawn
        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);
        _burn(msg.sender, requestedAmount);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);

        if (asEth) { // Convert to eth
            weth.withdraw(requestedAmount);
            address payable to = payable(msg.sender);
            to.transfer(requestedAmount);
        } else { // Send as WETH
            IERC20(weth).safeTransfer(msg.sender, requestedAmount);
        }
    }

    /// @dev Adjusts the withheldLiquidity as necessary
    /// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

        //adjust withheld liquidity by removing the original withheld amount and adding the new amount
        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        if (manager.getRolloverStatus()) {  // If manager is in the middle of a cycle rollover, add two cycles
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
        } else {  // If the manager is not in the middle of a rollover, add one cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
        }

        emit WithdrawalRequested(msg.sender, amount);
    }

    function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
        if (requestedWithdrawals[sender].amount > 0) {
            //reduce requested withdraw amount by transferred amount;
            uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
                Math.min(amount, requestedWithdrawals[sender].amount)
            );

            //subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
            withheldLiquidity = withheldLiquidity.sub(
                requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl)
            );

            //update the requested withdraw for user
            requestedWithdrawals[sender].amount = newRequestedWithdrawl;

            //if the withdraw request is 0, empty it out
            if (requestedWithdrawals[sender].amount == 0) {
                delete requestedWithdrawals[sender];
            }
        }
    }

    function approveManager(uint256 amount) public override onlyOwner {
        uint256 currentAllowance = IERC20(weth).allowance(address(this), address(manager));
        if (currentAllowance < amount) {
            uint256 delta = amount.sub(currentAllowance);
            IERC20(weth).safeIncreaseAllowance(address(manager), delta);
        } else {
            uint256 delta = currentAllowance.sub(amount);
            IERC20(weth).safeDecreaseAllowance(address(manager), delta);
        }
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transfer(address recipient, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        (bool success) = super.transfer(recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, msg.sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        (bool success) = super.transferFrom(sender, recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(address(eventProxy) != address(0), "DESTINATIONS_NOT_SET");

        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _deposit(
        address fromAccount,
        address toAccount,
        uint256 amount,
        uint256 msgValue
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(toAccount != address(0), "INVALID_ADDRESS");

        _mint(toAccount, amount);
        if (msgValue > 0) { // If ether get weth
            require(msgValue == amount, "AMT_VALUE_MISMATCH");
            weth.deposit{value: amount}();
        } else { // Else go ahead and transfer weth from account to pool
            IERC20(weth).safeTransferFrom(fromAccount, address(this), amount);
        }

        bytes32 eventSig = "Deposit";
        encodeAndSendData(eventSig, toAccount);
    }

    function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
        require(address(eventProxy) != address(0), "ADDRESS_NOT_SET");

        uint256 userBalance = balanceOf(_user);
        bytes memory data = abi.encode(BalanceUpdateEvent({
            eventSig: _eventSig,
            account: _user, 
            token: address(this), 
            amount: userBalance
        }));

         eventProxy.processMessageFromRoot(address(this), data);
    }
    function setEventProxy(address _eventProxy) external override onEventSend {
        require(_eventProxy != address(0), "ADDRESS INVALID");
        eventProxy = IEventProxy(_eventProxy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../interfaces/IWETH.sol";
import "../interfaces/IManager.sol";

/// @title Interface for Pool
/// @notice Allows users to deposit ERC-20 tokens to be deployed to market makers.
/// @notice Mints 1:1 fToken on deposit, represeting an IOU for the undelrying token that is freely transferable.
/// @notice Holders of fTokens earn rewards based on duration their tokens were deployed and the demand for that asset.
/// @notice Holders of fTokens can redeem for underlying asset after issuing requestWithdrawal and waiting for the next cycle.
interface ILiquidityEthPool {
    struct WithdrawalInfo {
        uint256 minCycle;
        uint256 amount;
    }

    event WithdrawalRequested(address requestor, uint256 amount);

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the msg.sender.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function deposit(uint256 amount) external payable;

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the account.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function depositFor(address account, uint256 amount) external payable;

    /// @notice Requests that the manager prepare funds for withdrawal next cycle
    /// @notice Invoking this function when sender already has a currently pending request will overwrite that requested amount and reset the cycle timer
    /// @param amount Amount of fTokens requested to be redeemed
    function requestWithdrawal(uint256 amount) external;

    function approveManager(uint256 amount) external;

    /// @notice Sender must first invoke requestWithdrawal in a previous cycle
    /// @notice This function will burn the fAsset and transfers underlying asset back to sender
    /// @notice Will execute a partial withdrawal if either available liquidity or previously requested amount is insufficient
    /// @param amount Amount of fTokens to redeem, value can be in excess of available tokens, operation will be reduced to maximum permissible
    function withdraw(uint256 amount, bool asEth) external;

    /// @return Reference to the underlying ERC-20 contract
    function weth() external view returns (IWETH);

    /// @return Reference to the underlying ERC-20 contract
    function underlyer() external view returns (address);

    /// @return Amount of liquidity that should not be deployed for market making (this liquidity will be used for completing requested withdrawals)
    function withheldLiquidity() external view returns (uint256);

    /// @notice Get withdraw requests for an account
    /// @param account User account to check
    /// @return minCycle Cycle - block number - that must be active before withdraw is allowed, amount Token amount requested
    function requestedWithdrawals(address account) external view returns (uint256, uint256);

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 *  @title Interface for the WETH token
 */
interface IWETH is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IDefiRound.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract DefiRound is IDefiRound, Ownable {
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    // solhint-disable-next-line
    address public immutable WETH;
    address public override immutable treasury;
    OversubscriptionRate public overSubscriptionRate;    
    mapping(address => uint256) public override totalSupply;
    // account -> accountData
    mapping(address => AccountData) private accountData;
    mapping(address => RateData) private tokenRates;
    
    //Token -> oracle, genesis
    mapping(address => SupportedTokenData) private tokenSettings;
    
    EnumerableSet.AddressSet private supportedTokens;
    EnumerableSet.AddressSet private configuredTokenRates;
    STAGES public override currentStage;

    WhitelistSettings public whitelistSettings;
    uint256 public lastLookExpiration  = type(uint256).max;
    uint256 private immutable maxTotalValue;
    bool private stage1Locked;

    constructor(
        // solhint-disable-next-line
        address _WETH,
        address _treasury,
        uint256 _maxTotalValue
    ) public {
        require(_WETH != address(0), "INVALID_WETH");
        require(_treasury != address(0), "INVALID_TREASURY");
        require(_maxTotalValue > 0, "INVALID_MAXTOTAL");

        WETH = _WETH;
        treasury = _treasury;
        currentStage = STAGES.STAGE_1;
        
        maxTotalValue = _maxTotalValue;
    }

    function deposit(TokenData calldata tokenInfo, bytes32[] memory proof) external payable override {
        require(currentStage == STAGES.STAGE_1, "DEPOSITS_NOT_ACCEPTED");
        require(!stage1Locked, "DEPOSITS_LOCKED");

        if (whitelistSettings.enabled) {            
            require(verifyDepositor(msg.sender, whitelistSettings.root, proof), "PROOF_INVALID");
        }

        TokenData memory data = tokenInfo;
        address token = data.token;
        uint256 tokenAmount = data.amount;
        require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
        require(tokenAmount > 0, "INVALID_AMOUNT");

        // Convert ETH to WETH if ETH is passed in, otherwise treat WETH as a regular ERC20
        if (token == WETH && msg.value > 0) {
            require(tokenAmount == msg.value, "INVALID_MSG_VALUE"); 
            IWETH(WETH).deposit{value: tokenAmount}();
        } else {
            require(msg.value == 0, "NO_ETH");
        }

        AccountData storage tokenAccountData = accountData[msg.sender];
    
        if (tokenAccountData.token == address(0)) {
            tokenAccountData.token = token;
        }
        
        require(tokenAccountData.token == token, "SINGLE_ASSET_DEPOSITS");

        tokenAccountData.initialDeposit = tokenAccountData.initialDeposit.add(tokenAmount);
        tokenAccountData.currentBalance = tokenAccountData.currentBalance.add(tokenAmount);
        
        require(tokenAccountData.currentBalance <= tokenSettings[token].maxLimit, "MAX_LIMIT_EXCEEDED");       

        // No need to transfer from msg.sender since is ETH was converted to WETH
        if (!(token == WETH && msg.value > 0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);    
        }
        
        if(_totalValue() > maxTotalValue) {
            stage1Locked = true;
        }

        emit Deposited(msg.sender, tokenInfo);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable 
    { 
        require(msg.sender == WETH);
    }

    function withdraw(TokenData calldata tokenInfo, bool asETH) external override {
        require(currentStage == STAGES.STAGE_2, "WITHDRAWS_NOT_ACCEPTED");
        require(!_isLastLookComplete(), "WITHDRAWS_EXPIRED");

        TokenData memory data = tokenInfo;
        address token = data.token;
        uint256 tokenAmount = data.amount;
        require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
        require(tokenAmount > 0, "INVALID_AMOUNT");        
        AccountData storage tokenAccountData = accountData[msg.sender];
        require(token == tokenAccountData.token, "INVALID_TOKEN");
        tokenAccountData.currentBalance = tokenAccountData.currentBalance.sub(tokenAmount);
        // set the data back in the mapping, otherwise updates are not saved
        accountData[msg.sender] = tokenAccountData;

        // Don't transfer WETH, WETH is converted to ETH and sent to the recipient
        if (token == WETH && asETH) {
            IWETH(WETH).withdraw(tokenAmount);
            address payable to = payable(msg.sender);
            to.transfer(tokenAmount);
        }  else {
            IERC20(token).safeTransfer(msg.sender, tokenAmount);
        }
        
        emit Withdrawn(msg.sender, tokenInfo, asETH);
    }

    function configureWhitelist(WhitelistSettings memory settings) external override onlyOwner {
        whitelistSettings = settings;
        emit WhitelistConfigured(settings);
    }

    function addSupportedTokens(SupportedTokenData[] calldata tokensToSupport)
        external
        override
        onlyOwner
    {
        uint256 tokensLength = tokensToSupport.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            SupportedTokenData memory data = tokensToSupport[i];
            require(supportedTokens.add(data.token), "TOKEN_EXISTS");
            
            tokenSettings[data.token] = data;
        }
        emit SupportedTokensAdded(tokensToSupport);
    }

    function getSupportedTokens() external view override returns (address[] memory tokens) {
        uint256 tokensLength = supportedTokens.length();
        tokens = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            tokens[i] = supportedTokens.at(i);
        }
    }

    function publishRates(RateData[] calldata ratesData, OversubscriptionRate memory oversubRate, uint256 lastLookDuration) external override onlyOwner {
        // check rates havent been published before
        require(currentStage == STAGES.STAGE_1, "RATES_ALREADY_SET");
        require(lastLookDuration > 0, "INVALID_DURATION");
        require(oversubRate.overDenominator > 0, "INVALID_DENOMINATOR");
        require(oversubRate.overNumerator > 0, "INVALID_NUMERATOR");        
        
        uint256 ratesLength = ratesData.length;
        for (uint256 i = 0; i < ratesLength; i++) {
            RateData memory data = ratesData[i];
            require(data.numerator > 0, "INVALID_NUMERATOR");
            require(data.denominator > 0, "INVALID_DENOMINATOR");
            require(tokenRates[data.token].token == address(0), "RATE_ALREADY_SET");
            require(configuredTokenRates.add(data.token), "ALREADY_CONFIGURED");
            tokenRates[data.token] = data;            
        }

        require(configuredTokenRates.length() == supportedTokens.length(), "MISSING_RATE");

        // Stage only moves forward when prices are published
        currentStage = STAGES.STAGE_2;
        lastLookExpiration = block.number + lastLookDuration;
        overSubscriptionRate = oversubRate;

        emit RatesPublished(ratesData);
    }

    function getRates(address[] calldata tokens) external view override returns (RateData[] memory rates) {
        uint256 tokensLength = tokens.length;
        rates = new RateData[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            rates[i] = tokenRates[tokens[i]];
        }
    }

    function getTokenValue(address token, uint256 balance) internal view returns (uint256 value) {
        uint256 tokenDecimals = ERC20(token).decimals();
        (, int256 tokenRate, , , ) = AggregatorV3Interface(tokenSettings[token].oracle).latestRoundData();       
        uint256 rate = tokenRate.toUint256();        
        value = (balance.mul(rate)).div(10**tokenDecimals); //Chainlink USD prices are always to 8            
    }

    function totalValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256 value) {
        uint256 tokensLength = supportedTokens.length();
        for (uint256 i = 0; i < tokensLength; i++) {
            address token = supportedTokens.at(i);
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            value = value.add(getTokenValue(token, tokenBalance));
        }
    }

    function accountBalance(address account) external view override returns (uint256 value) {
        uint256 tokenBalance = accountData[account].currentBalance;
        value = value.add(getTokenValue(accountData[account].token, tokenBalance));   
    }

    function finalizeAssets(bool depositToGenesis) external override {
        require(currentStage == STAGES.STAGE_3, "NOT_SYSTEM_FINAL");
         
        AccountData storage data = accountData[msg.sender];
        address token = data.token;

        require(token != address(0), "NO_DATA");

        ( , uint256 ineffective, ) = _getRateAdjustedAmounts(data.currentBalance, token);
        
        require(ineffective > 0, "NOTHING_TO_MOVE");

        // zero out balance
        data.currentBalance = 0;
        accountData[msg.sender] = data;

        if (depositToGenesis) {  
            address pool = tokenSettings[token].genesis;         
            uint256 currentAllowance = IERC20(token).allowance(address(this), pool);
            if (currentAllowance < ineffective) {
                IERC20(token).safeIncreaseAllowance(pool, ineffective.sub(currentAllowance));    
            }            
            ILiquidityPool(pool).depositFor(msg.sender, ineffective);
            emit GenesisTransfer(msg.sender, ineffective);
        } else {
            // transfer ineffectiveTokenBalance back to user
            IERC20(token).safeTransfer(msg.sender, ineffective);
        }    

        emit AssetsFinalized(msg.sender, token, ineffective);        
    }

    function getGenesisPools(address[] calldata tokens)
        external
        view
        override
        returns (address[] memory genesisAddresses)
    {
        uint256 tokensLength = tokens.length;
        genesisAddresses = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
            genesisAddresses[i] = tokenSettings[supportedTokens.at(i)].genesis;            
        }
    }

    function getTokenOracles(address[] calldata tokens)
        external
        view
        override
        returns (address[] memory oracleAddresses)
    {
        uint256 tokensLength = tokens.length;
        oracleAddresses = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
            oracleAddresses[i] = tokenSettings[tokens[i]].oracle;
        }
    }

    function getAccountData(address account) external view override returns (AccountDataDetails[] memory data) {
        uint256 supportedTokensLength = supportedTokens.length();
        data = new AccountDataDetails[](supportedTokensLength);
        for (uint256 i = 0; i < supportedTokensLength; i++) {
            address token = supportedTokens.at(i);
            AccountData memory accountTokenInfo = accountData[account];
            if (currentStage >= STAGES.STAGE_2 && accountTokenInfo.token != address(0)) {
                (uint256 effective, uint256 ineffective, uint256 actual) = _getRateAdjustedAmounts(accountTokenInfo.currentBalance, token);
                AccountDataDetails memory details = AccountDataDetails(
                    token, 
                    accountTokenInfo.initialDeposit, 
                    accountTokenInfo.currentBalance, 
                    effective, 
                    ineffective, 
                    actual
                );
                data[i] = details;
            } else {
                data[i] = AccountDataDetails(token, accountTokenInfo.initialDeposit, accountTokenInfo.currentBalance, 0, 0, 0);
            }          
        }
    }

    function transferToTreasury() external override onlyOwner {
        require(_isLastLookComplete(), "CURRENT_STAGE_INVALID");
        require(currentStage == STAGES.STAGE_2, "ONLY_TRANSFER_ONCE");

        uint256 supportedTokensLength = supportedTokens.length();
        TokenData[] memory tokens = new TokenData[](supportedTokensLength);
        for (uint256 i = 0; i < supportedTokensLength; i++) {       
            address token = supportedTokens.at(i);  
            uint256 balance = IERC20(token).balanceOf(address(this));
            (uint256 effective, , ) = _getRateAdjustedAmounts(balance, token);
            tokens[i].token = token;
            tokens[i].amount = effective;
            IERC20(token).safeTransfer(treasury, effective);
        }

        currentStage = STAGES.STAGE_3;

        emit TreasuryTransfer(tokens);
    }
    
   function getRateAdjustedAmounts(uint256 balance, address token) external override view returns (uint256,uint256,uint256) {
        return _getRateAdjustedAmounts(balance, token);
    }

    function getMaxTotalValue() external view override returns (uint256) {
        return maxTotalValue;
    }

    function _getRateAdjustedAmounts(uint256 balance, address token) internal view returns (uint256,uint256,uint256) {
        require(currentStage >= STAGES.STAGE_2, "RATES_NOT_PUBLISHED");

        RateData memory rateInfo = tokenRates[token];
        uint256 effectiveTokenBalance = 
            balance.mul(overSubscriptionRate.overNumerator).div(overSubscriptionRate.overDenominator);
        uint256 ineffectiveTokenBalance =
            balance.mul(overSubscriptionRate.overDenominator.sub(overSubscriptionRate.overNumerator))
            .div(overSubscriptionRate.overDenominator);
        
        uint256 actualReceived =
            effectiveTokenBalance.mul(rateInfo.denominator).div(rateInfo.numerator);

        return (effectiveTokenBalance, ineffectiveTokenBalance, actualReceived);
    }

    function verifyDepositor(address participant, bytes32 root, bytes32[] memory proof) internal pure returns (bool) {
        bytes32 leaf = keccak256((abi.encodePacked((participant))));
        return MerkleProof.verify(proof, root, leaf);
    }

    function _isLastLookComplete() internal view returns (bool) {
        return block.number >= lastLookExpiration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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
library SafeCast {

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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IDefiRound {
    enum STAGES {STAGE_1, STAGE_2, STAGE_3}

    struct AccountData {
        address token; // address of the allowed token deposited
        uint256 initialDeposit; // initial amount deposited of the token
        uint256 currentBalance; // current balance of the token that can be used to claim TOKE
    }

    struct AccountDataDetails {
        address token; // address of the allowed token deposited
        uint256 initialDeposit; // initial amount deposited of the token
        uint256 currentBalance; // current balance of the token that can be used to claim TOKE
        uint256 effectiveAmt; //Amount deposited that will be used towards TOKE
        uint256 ineffectiveAmt; //Amount deposited that will be either refunded or go to farming
        uint256 actualTokeReceived; //Amount of TOKE that will be received
    }

    struct TokenData {
        address token;
        uint256 amount;
    }

    struct SupportedTokenData {
        address token;
        address oracle;
        address genesis;
        uint256 maxLimit;
    }

    struct RateData {
        address token;
        uint256 numerator;
        uint256 denominator;
    }

    struct OversubscriptionRate {
        uint256 overNumerator;
        uint256 overDenominator;
    }

    event Deposited(address depositor, TokenData tokenInfo);
    event Withdrawn(address withdrawer, TokenData tokenInfo, bool asETH);
    event SupportedTokensAdded(SupportedTokenData[] tokenData);
    event RatesPublished(RateData[] ratesData);
    event GenesisTransfer(address user, uint256 amountTransferred);
    event AssetsFinalized(address claimer, address token, uint256 assetsMoved);
    event WhitelistConfigured(WhitelistSettings settings); 
    event TreasuryTransfer(TokenData[] tokens);

    struct TokenValues {
        uint256 effectiveTokenValue;
        uint256 ineffectiveTokenValue;
    }

    struct WhitelistSettings {
        bool enabled;
        bytes32 root;
    }

    /// @notice Enable or disable the whitelist
    /// @param settings The root to use and whether to check the whitelist at all
    function configureWhitelist(WhitelistSettings calldata settings) external;

    /// @notice returns the current stage the contract is in
    /// @return stage the current stage the round contract is in
    function currentStage() external returns (STAGES stage);

    /// @notice deposits tokens into the round contract
    /// @param tokenData an array of token structs
    function deposit(TokenData calldata tokenData, bytes32[] memory proof) external payable;

    /// @notice total value held in the entire contract amongst all the assets
    /// @return value the value of all assets held
    function totalValue() external view returns (uint256 value);

    /// @notice Current Max Total Value
    /// @return value the max total value
    function getMaxTotalValue() external view returns (uint256 value);

    /// @notice returns the address of the treasury, when users claim this is where funds that are <= maxClaimableValue go
    /// @return treasuryAddress address of the treasury
    function treasury() external returns (address treasuryAddress);

    /// @notice the total supply held for a given token
    /// @param token the token to get the supply for
    /// @return amount the total supply for a given token
    function totalSupply(address token) external returns (uint256 amount);

    /// @notice withdraws tokens from the round contract. only callable when round 2 starts
    /// @param tokenData an array of token structs
    /// @param asEth flag to determine if provided WETH, that it should be withdrawn as ETH
    function withdraw(TokenData calldata tokenData, bool asEth) external;

    // /// @notice adds tokens to support
    // /// @param tokensToSupport an array of supported token structs
    function addSupportedTokens(SupportedTokenData[] calldata tokensToSupport) external;

    // /// @notice returns which tokens can be deposited
    // /// @return tokens tokens that are supported for deposit
    function getSupportedTokens() external view returns (address[] calldata tokens);

    /// @notice the oracle that will be used to denote how much the amounts deposited are worth in USD
    /// @param tokens an array of tokens
    /// @return oracleAddresses the an array of oracles corresponding to supported tokens
    function getTokenOracles(address[] calldata tokens)
        external
        view
        returns (address[] calldata oracleAddresses);

    /// @notice publishes rates for the tokens. Rates are always relative to 1 TOKE. Can only be called once within Stage 1
    // prices can be published at any time
    /// @param ratesData an array of rate info structs
    function publishRates(
        RateData[] calldata ratesData,
        OversubscriptionRate memory overSubRate,
        uint256 lastLookDuration
    ) external;

    /// @notice return the published rates for the tokens
    /// @param tokens an array of tokens to get rates for
    /// @return rates an array of rates for the provided tokens
    function getRates(address[] calldata tokens) external view returns (RateData[] calldata rates);

    /// @notice determines the account value in USD amongst all the assets the user is invovled in
    /// @param account the account to look up
    /// @return value the value of the account in USD
    function accountBalance(address account) external view returns (uint256 value);

    /// @notice Moves excess assets to private farming or refunds them
    /// @dev uses the publishedRates, selected tokens, and amounts to determine what amount of TOKE is claimed
    /// @param depositToGenesis applies only if oversubscribedMultiplier < 1;
    /// when true oversubscribed amount will deposit to genesis, else oversubscribed amount is sent back to user
    function finalizeAssets(bool depositToGenesis) external;

    //// @notice returns what gensis pool a supported token is mapped to
    /// @param tokens array of addresses of supported tokens
    /// @return genesisAddresses array of genesis pools corresponding to supported tokens
    function getGenesisPools(address[] calldata tokens)
        external
        view
        returns (address[] memory genesisAddresses);

    /// @notice returns a list of AccountData for a provided account
    /// @param account the address of the account
    /// @return data an array of AccountData denoting what the status is for each of the tokens deposited (if any)
    function getAccountData(address account)
        external
        view
        returns (AccountDataDetails[] calldata data);

    /// @notice Allows the owner to transfer all swapped assets to the treasury
    /// @dev only callable by owner and if last look period is complete
    function transferToTreasury() external;

    /// @notice Given a balance, calculates how the the amount will be allocated between TOKE and Farming
    /// @dev Only allowed at stage 3
    /// @param balance balance to divy up
    /// @param token token to pull the rates for
    function getRateAdjustedAmounts(uint256 balance, address token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IRewards.sol";

contract Rewards is Ownable, IRewards {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public override claimedAmounts;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant RECIPIENT_TYPEHASH =
        keccak256("Recipient(uint256 chainId,uint256 cycle,address wallet,uint256 amount)");

    bytes32 private immutable domainSeparator;

    IERC20 public immutable override tokeToken;
    address public override rewardsSigner;

    constructor(address token, address signerAddress) public {
        require(address(token) != address(0), "Invalid TOKE Address");
        require(signerAddress != address(0), "Invalid Signer Address");
        tokeToken = IERC20(token);
        rewardsSigner = signerAddress;

        domainSeparator = _hashDomain(
            EIP712Domain({
                name: "TOKE Distribution",
                version: "1",
                chainId: _getChainID(),
                verifyingContract: address(this)
            })
        );
    }

    function _hashDomain(EIP712Domain memory eip712Domain) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function _hashRecipient(Recipient memory recipient) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    RECIPIENT_TYPEHASH,
                    recipient.chainId,
                    recipient.cycle,
                    recipient.wallet,
                    recipient.amount
                )
            );
    }

    function _hash(Recipient memory recipient) private view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, _hashRecipient(recipient)));
    }

    function _getChainID() private view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function setSigner(address newSigner) external override onlyOwner {
        require(newSigner != address(0), "Invalid Signer Address");
        rewardsSigner = newSigner;

        emit SignerSet(newSigner);
    }

    function getClaimableAmount(address recipient, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        return amount.sub(claimedAmounts[recipient]);
    }

    function claim(
        uint256 cycle,
        uint256 amount
    ) external override {

        uint256 claimableAmount = amount.sub(claimedAmounts[msg.sender]);

        require(claimableAmount > 0, "Invalid claimable amount");
        require(tokeToken.balanceOf(address(this)) >= claimableAmount, "Insufficient Funds");

        claimedAmounts[msg.sender] = claimedAmounts[msg.sender].add(claimableAmount);

        tokeToken.safeTransfer(msg.sender, claimableAmount);

        emit Claimed(cycle, msg.sender, claimableAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *  @title Validates and distributes TOKE rewards based on the
 *  the signed and submitted payloads
 */
interface IRewards {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Recipient {
        uint256 chainId;
        uint256 cycle;
        address wallet;
        uint256 amount;
    }

    event SignerSet(address newSigner);
    event Claimed(uint256 cycle, address recipient, uint256 amount);

    /// @notice Get the underlying token rewards are paid in
    /// @return Token address
    function tokeToken() external view returns (IERC20);

    /// @notice Get the current payload signer;
    /// @return Signer address
    function rewardsSigner() external view returns (address);

    /// @notice Check the amount an account has already claimed
    /// @param account Account to check
    /// @return Amount already claimed
    function claimedAmounts(address account) external view returns (uint256);

    /// @notice Get the amount that is claimable based on the provided payload
    /// @param recipient Published rewards payload
    /// @param amount Account to check
    /// @return Amount claimable if the payload is signed
    function getClaimableAmount(address recipient, uint256 amount) external view returns (uint256);

    /// @notice Change the signer used to validate payloads
    /// @param newSigner The new address that will be signing rewards payloads
    function setSigner(address newSigner) external;

    /// @notice Claim your rewards
    /// @param cycle cycle number
    /// @param amount claimable amount
    function claim(
        uint256 cycle,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./BaseController.sol";

contract UniswapController is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable UNISWAP_ROUTER;
    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Factory public immutable UNISWAP_FACTORY;

    constructor(
        IUniswapV2Router02 router,
        IUniswapV2Factory factory,
        address manager,
        address _addressRegistry
    ) public BaseController(manager, _addressRegistry) {
        require(address(router) != address(0), "INVALID_ROUTER");
        require(address(factory) != address(0), "INVALID_FACTORY");
        UNISWAP_ROUTER = router;
        UNISWAP_FACTORY = factory;
    }

    /// @notice Deploys liq to Uniswap LP pool
    /// @dev Calls to external contract
    /// @param data Bytes containing token addrs, amounts, pool addr, dealine to interact with Uni router
    function deploy(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(
                data,
                (address, address, uint256, uint256, uint256, uint256, address, uint256)
            );

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        _approve(IERC20(tokenA), amountADesired);
        _approve(IERC20(tokenB), amountBDesired);

        IERC20 pair = IERC20(UNISWAP_FACTORY.getPair(tokenA, tokenB));
        uint256 balanceBefore = pair.balanceOf(address(this));

        //(uint256 amountA, uint256 amountB, uint256 liquidity) =
        UNISWAP_ROUTER.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        uint256 balanceAfter = pair.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "MUST_INCREASE");
    }

    /// @notice Withdraws liq from Uni LP pool
    /// @dev Calls to external contract
    /// @param data Bytes contains tokens addrs, amounts, liq, pool addr, dealine for Uni router
    function withdraw(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(data, (address, address, uint256, uint256, uint256, address, uint256));

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        address pair = UNISWAP_FACTORY.getPair(tokenA, tokenB);
        require(pair != address(0), "pair doesn't exist");
        _approve(IERC20(pair), liquidity);

        IERC20 tokenAInterface = IERC20(tokenA);
        IERC20 tokenBInterface = IERC20(tokenB);
        uint256 tokenABalanceBefore = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceBefore = tokenBInterface.balanceOf(address(this));

        //(uint256 amountA, uint256 amountB) =
        UNISWAP_ROUTER.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
        
        uint256 tokenABalanceAfter = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceAfter = tokenBInterface.balanceOf(address(this));
        require(tokenABalanceAfter > tokenABalanceBefore, "MUST_INCREASE");
        require(tokenBBalanceAfter > tokenBBalanceBefore, "MUST_INCREASE");
    }

    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), address(UNISWAP_ROUTER));
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(address(UNISWAP_ROUTER), currentAllowance);
        }
        token.safeIncreaseAllowance(address(UNISWAP_ROUTER), amount);
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;

import "../interfaces/IAddressRegistry.sol";

contract BaseController {

    address public immutable manager;
    IAddressRegistry public immutable addressRegistry;

    constructor(address _manager, address _addressRegistry) public {
        require(_manager != address(0), "INVALID_ADDRESS");
        require(_addressRegistry != address(0), "INVALID_ADDRESS");

        manager = _manager;
        addressRegistry = IAddressRegistry(_addressRegistry);
    }

    modifier onlyManager() {
        require(address(this) == manager, "NOT_MANAGER_ADDRESS");
        _;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BaseController.sol";

contract TransferController is BaseController {
    using SafeERC20 for IERC20;

    address public immutable treasuryAddress;

    constructor(
        address manager,
        address addressRegistry,
        address treasury
    ) public BaseController(manager, addressRegistry) {
        require(treasury != address(0), "INVALID_TREASURY_ADDRESS");
        treasuryAddress = treasury;
    }

    /// @notice Used to transfer funds to our treasury
    /// @dev Calls into external contract
    /// @param tokenAddress Address of IERC20 token
    /// @param amount amount of funds to transfer
    function transferFunds(address tokenAddress, uint256 amount) external onlyManager {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(amount > 0, "INVALID_AMOUNT");
        require(addressRegistry.checkAddress(tokenAddress, 0), "INVALID_TOKEN");
                
        IERC20(tokenAddress).safeTransfer(treasuryAddress, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IRewardHash.sol";

contract RewardHash is IRewardHash, Ownable {
    using SafeMath for uint256;

    mapping(uint256 => CycleHashTuple) public override cycleHashes;
    uint256 public latestCycleIndex;

    function setCycleHashes(uint256 index, string calldata latestClaimableIpfsHash, string calldata cycleIpfsHash) external override onlyOwner {
        require(bytes(latestClaimableIpfsHash).length > 0, "Invalid latestClaimableIpfsHash");
        require(bytes(cycleIpfsHash).length > 0, "Invalid cycleIpfsHash");

        cycleHashes[index] = CycleHashTuple(latestClaimableIpfsHash, cycleIpfsHash);

        if (index >= latestCycleIndex) {
            latestCycleIndex = index;
        }

        emit CycleHashAdded(index, latestClaimableIpfsHash, cycleIpfsHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Tracks the IPFS hashes that are generated for rewards
 */
interface IRewardHash {
    struct CycleHashTuple {
        string latestClaimable; // hash of last claimable cycle before/including this cycle
        string cycle; // cycleHash of this cycle
    }

    event CycleHashAdded(uint256 cycleIndex, string latestClaimableHash, string cycleHash);

    /// @notice Sets a new (claimable, cycle) hash tuple for the specified cycle
    /// @param index Cycle index to set. If index >= LatestCycleIndex, CycleHashAdded is emitted
    /// @param latestClaimableIpfsHash IPFS hash of last claimable cycle before/including this cycle
    /// @param cycleIpfsHash IPFS hash of this cycle
    function setCycleHashes(
        uint256 index,
        string calldata latestClaimableIpfsHash,
        string calldata cycleIpfsHash
    ) external;

    ///@notice Gets hashes for the specified cycle
    ///@return latestClaimable lastest claimable hash for specified cycle, cycle latest hash (possibly non-claimable) for specified cycle
    function cycleHashes(uint256 index)
        external
        view
        returns (string memory latestClaimable, string memory cycle);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Toke is ERC20Pausable, Ownable  {
    uint256 private constant SUPPLY = 100_000_000e18;
    constructor() public ERC20("Tokemak", "TOKE")  {        
        _mint(msg.sender, SUPPLY); // 100M
    }

    function pause() external onlyOwner {        
        _pause();
    }

    function unpause() external onlyOwner {        
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestOracle is Ownable  {
    
    //solhint-disable-next-line no-empty-blocks
    constructor() public Ownable() { }

    uint80 public _roundId = 92233720368547768165;
    int256 public  _answer = 344698605527;
    uint256 public  _startedAt = 1631220008;
    uint256 public  _updatedAt = 1631220008;
    uint80 public  _answeredInRound = 92233720368547768165;

    function setLatestRoundData(uint80 roundId, 
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound) external onlyOwner {
          _roundId = roundId;
          _answer = answer;
          _startedAt = startedAt;
          _updatedAt = updatedAt;
          _answeredInRound = answeredInRound;
      }

    function latestRoundData()
        public
        view
    returns (
      uint80 roundId, 
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestnetToken is ERC20Pausable, Ownable  {
    
    //solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory symbol, uint8 decimals) public ERC20(name, symbol)  {
        // _setupDecimals(decimals);
     }

    function mint(address to, uint256 amount) external onlyOwner {        
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {        
        _burn(from, amount);
    }

    function pause() external onlyOwner {        
        _pause();
    }

    function unpause() external onlyOwner {        
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// SushiToken with Governance.
contract SushiToken is ERC20("SushiToken", "SUSHI"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SUSHI::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SUSHI::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "SUSHI::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "SUSHI::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SUSHIs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld-amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "SUSHI::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() view internal returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SushiToken.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to SushiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }
    // The SUSHI TOKEN!
    SushiToken public sushi;
    // Dev address.
    address public devaddr;
    // Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;
    // SUSHI tokens created per block.
    uint256 public sushiPerBlock;
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        SushiToken _sushi,
        address _devaddr,
        uint256 _sushiPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        sushi = _sushi;
        devaddr = _devaddr;
        sushiPerBlock = _sushiPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSushiPerShare: 0
            })
        );
    }

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending SUSHIs on frontend.
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward =
                multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accSushiPerShare = accSushiPerShare.add(
                sushiReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sushiReward =
            multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        sushi.mint(devaddr, sushiReward.div(10));
        sushi.mint(address(this), sushiReward);
        pool.accSushiPerShare = pool.accSushiPerShare.add(
            sushiReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeSushiTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeSushiTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeSushiTransfer(address _to, uint256 _amount) internal {
        uint256 sushiBal = sushi.balanceOf(address(this));
        if (_amount > sushiBal) {
            sushi.transfer(_to, sushiBal);
        } else {
            sushi.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./SushiswapMasterChef.sol";
import "./BaseController.sol";

contract SushiswapControllerV1 is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable SUSHISWAP_ROUTER;
    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Factory public immutable SUSHISWAP_FACTORY;
    // solhint-disable-next-line var-name-mixedcase
    MasterChef public immutable MASTERCHEF;

    constructor(
        IUniswapV2Router02 router,
        IUniswapV2Factory factory,
        MasterChef masterchef,
        address manager,
        address _addressRegistry
    ) public BaseController(manager, _addressRegistry) {
        require(address(router) != address(0), "INVALID_ROUTER");
        require(address(factory) != address(0), "INVALID_FACTORY");
        require(address(masterchef) != address(0), "INVALID_MASTERCHEF");
        SUSHISWAP_ROUTER = router;
        SUSHISWAP_FACTORY = factory;
        MASTERCHEF = masterchef;
    }

    /// @notice deploy liquidity to Sushiswap pool
    /// @dev Calls to external contract
    /// @param data Bytes passed from manager.  Contains token addresses, minimum amounts, desired amounts.  Passed to Sushi router
    function deploy(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline,
            uint256 poolId,
            bool toDeposit
        ) = abi.decode(
                data,
                (address, address, uint256, uint256, uint256, uint256, address, uint256, uint256, bool)
            );

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        _approve(address(SUSHISWAP_ROUTER), IERC20(tokenA), amountADesired);
        _approve(address(SUSHISWAP_ROUTER), IERC20(tokenB), amountBDesired);

        IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
        uint256 balanceBefore = pair.balanceOf(address(this));

        ( , , uint256 liquidity) = SUSHISWAP_ROUTER.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        uint256 balanceAfter = pair.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "MUST_INCREASE");

        if (toDeposit) {
            _approve(address(MASTERCHEF), pair, liquidity);
            depositLPTokensToMasterChef(poolId, liquidity);
        }
    }

    /// @notice Withdraw liquidity from a sushiswap LP pool
    /// @dev Calls an external contract
    /// @param data Bytes data, contains token addrs, amounts, deadline for sushi router interaction
    function withdraw(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline,
            uint256 poolId,
            bool toWithdraw
        ) = abi.decode(data, (address, address, uint256, uint256, uint256, address, uint256, uint256, bool));

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        if (toWithdraw) withdrawLPTokensFromMasterChef(poolId);
        
        IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
        require(address(pair) != address(0), "pair doesn't exist");
        require(pair.balanceOf(address(this)) >= liquidity, "INSUFFICIENT_LIQUIDITY");
        _approve(address(SUSHISWAP_ROUTER), pair, liquidity);

        IERC20 tokenAInterface = IERC20(tokenA);
        IERC20 tokenBInterface = IERC20(tokenB);
        uint256 tokenABalanceBefore = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceBefore = tokenBInterface.balanceOf(address(this));

        SUSHISWAP_ROUTER.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        uint256 tokenABalanceAfter = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceAfter = tokenBInterface.balanceOf(address(this));
        require(tokenABalanceAfter > tokenABalanceBefore, "MUST_INCREASE");
        require(tokenBBalanceAfter > tokenBBalanceBefore, "MUST_INCREASE");
    }

    function depositLPTokensToMasterChef(uint256 _poolId, uint256 amount) private {
        MASTERCHEF.deposit(_poolId, amount);
    }

    function withdrawLPTokensFromMasterChef(uint256 _poolId) private {
        (uint256 amount, ) = MASTERCHEF.userInfo(_poolId, address(this));
        MASTERCHEF.withdraw(_poolId, amount);
    }

    function _approve(address spender, IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(spender, currentAllowance);
        }
        token.safeIncreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "../interfaces/IMasterChefV2.sol";
import "./BaseController.sol";

contract SushiswapControllerV2 is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable SUSHISWAP_ROUTER;
    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Factory public immutable SUSHISWAP_FACTORY;
    // solhint-disable-next-line var-name-mixedcase
    IMasterChefV2 public immutable MASTERCHEF;

    constructor(
        IUniswapV2Router02 router,
        IUniswapV2Factory factory,
        IMasterChefV2 masterchef,
        address manager,
        address _addressRegistry
    ) public BaseController(manager, _addressRegistry) {
        require(address(router) != address(0), "INVALID_ROUTER");
        require(address(factory) != address(0), "INVALID_FACTORY");
        require(address(masterchef) != address(0), "INVALID_MASTERCHEF");
        SUSHISWAP_ROUTER = router;
        SUSHISWAP_FACTORY = factory;
        MASTERCHEF = masterchef;
    }

    /// @notice deploy liquidity to Sushiswap pool
    /// @dev Calls to external contract
    /// @param data Bytes passed from manager.  Contains token addresses, minimum amounts, desired amounts.  Passed to Sushi router
    function deploy(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline,
            uint256 poolId,
            bool toDeposit
        ) = abi.decode(
                data,
                (address, address, uint256, uint256, uint256, uint256, address, uint256, uint256, bool)
            );

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        _approve(address(SUSHISWAP_ROUTER), IERC20(tokenA), amountADesired);
        _approve(address(SUSHISWAP_ROUTER), IERC20(tokenB), amountBDesired);

        IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
        uint256 balanceBefore = pair.balanceOf(address(this));

        ( , , uint256 liquidity) = SUSHISWAP_ROUTER.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        uint256 balanceAfter = pair.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "MUST_INCREASE");

        if (toDeposit) {
            _approve(address(MASTERCHEF), pair, liquidity);
            depositLPTokensToMasterChef(poolId, liquidity);
        }
    }

    /// @notice Withdraw liquidity from a sushiswap LP pool
    /// @dev Calls an external contract
    /// @param data Bytes data, contains token addrs, amounts, deadline for sushi router interaction
    function withdraw(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline,
            uint256 poolId,
            bool toWithdraw
        ) = abi.decode(data, (address, address, uint256, uint256, uint256, address, uint256, uint256, bool));

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        if (toWithdraw) withdrawLPTokensFromMasterChef(poolId);
        
        IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
        require(address(pair) != address(0), "pair doesn't exist");
        require(pair.balanceOf(address(this)) >= liquidity, "INSUFFICIENT_LIQUIDITY");
        _approve(address(SUSHISWAP_ROUTER), pair, liquidity);

        IERC20 tokenAInterface = IERC20(tokenA);
        IERC20 tokenBInterface = IERC20(tokenB);
        uint256 tokenABalanceBefore = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceBefore = tokenBInterface.balanceOf(address(this));

        SUSHISWAP_ROUTER.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        uint256 tokenABalanceAfter = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceAfter = tokenBInterface.balanceOf(address(this));
        require(tokenABalanceAfter > tokenABalanceBefore, "MUST_INCREASE");
        require(tokenBBalanceAfter > tokenBBalanceBefore, "MUST_INCREASE");
    }

    function depositLPTokensToMasterChef(uint256 _poolId, uint256 amount) private {
        MASTERCHEF.deposit(_poolId, amount, address(this));
    }

    function withdrawLPTokensFromMasterChef(uint256 _poolId) private {
        (uint256 amount, ) = MASTERCHEF.userInfo(_poolId, address(this));
        MASTERCHEF.withdraw(_poolId, amount, address(this));
    }

    function _approve(address spender, IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(spender, currentAllowance);
        }
        token.safeIncreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
}

struct PoolInfo {
    uint128 accSushiPerShare;
    uint64 lastRewardBlock;
    uint64 allocPoint;
}

/// @title Interface for the SushiSwap MasterChef V2 contract
interface IMasterChefV2 {
    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function userInfo(uint256 pid, address user) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@sphynxswap/swap-core/contracts/interfaces/ISphynxFactory.sol";
import "./BaseController.sol";

contract SphynxswapController is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable UNISWAP_ROUTER;
    // solhint-disable-next-line var-name-mixedcase
    ISphynxFactory public immutable UNISWAP_FACTORY;

    constructor(
        IUniswapV2Router02 router,
        ISphynxFactory factory,
        address manager,
        address _addressRegistry
    ) public BaseController(manager, _addressRegistry) {
        require(address(router) != address(0), "INVALID_ROUTER");
        require(address(factory) != address(0), "INVALID_FACTORY");
        UNISWAP_ROUTER = router;
        UNISWAP_FACTORY = factory;
    }

    /// @notice Deploys liq to Uniswap LP pool
    /// @dev Calls to external contract
    /// @param data Bytes containing token addrs, amounts, pool addr, dealine to interact with Uni router
    function deploy(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(
                data,
                (address, address, uint256, uint256, uint256, uint256, address, uint256)
            );

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        _approve(IERC20(tokenA), amountADesired);
        _approve(IERC20(tokenB), amountBDesired);

        IERC20 pair = IERC20(UNISWAP_FACTORY.getPair(tokenA, tokenB));
        uint256 balanceBefore = pair.balanceOf(address(this));

        //(uint256 amountA, uint256 amountB, uint256 liquidity) =
        UNISWAP_ROUTER.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        uint256 balanceAfter = pair.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "MUST_INCREASE");
    }

    /// @notice Withdraws liq from Uni LP pool
    /// @dev Calls to external contract
    /// @param data Bytes contains tokens addrs, amounts, liq, pool addr, dealine for Uni router
    function withdraw(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(data, (address, address, uint256, uint256, uint256, address, uint256));

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        address pair = UNISWAP_FACTORY.getPair(tokenA, tokenB);
        require(pair != address(0), "pair doesn't exist");
        _approve(IERC20(pair), liquidity);

        IERC20 tokenAInterface = IERC20(tokenA);
        IERC20 tokenBInterface = IERC20(tokenB);
        uint256 tokenABalanceBefore = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceBefore = tokenBInterface.balanceOf(address(this));

        //(uint256 amountA, uint256 amountB) =
        UNISWAP_ROUTER.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
        
        uint256 tokenABalanceAfter = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceAfter = tokenBInterface.balanceOf(address(this));
        require(tokenABalanceAfter > tokenABalanceBefore, "MUST_INCREASE");
        require(tokenBBalanceAfter > tokenBBalanceBefore, "MUST_INCREASE");
    }

    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), address(UNISWAP_ROUTER));
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(address(UNISWAP_ROUTER), currentAllowance);
        }
        token.safeIncreaseAllowance(address(UNISWAP_ROUTER), amount);
    }
}

pragma solidity >=0.5.0;

interface ISphynxFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setSwapFee(address _pair, uint32 _swapFee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/curve/IStableSwapPool.sol";
import "../interfaces/curve/IRegistry.sol";
import "../interfaces/curve/IAddressProvider.sol";
import "./BaseController.sol";

contract CurveControllerTemplate is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IAddressProvider public immutable addressProvider;

    uint256 public constant N_COINS = 2;

    constructor(
        address manager,
        address addressRegistry,
        address curveAddressProvider
    ) public BaseController(manager, addressRegistry) {
        require(curveAddressProvider != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
        addressProvider = IAddressProvider(curveAddressProvider);
    }

    /// @notice Deploy liquidity to Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param poolAddress Token addresses
    /// @param amounts List of amounts of coins to deposit
    /// @param poolAddress Minimum amount of LP tokens to mint from the deposit
    function deploy(
        address poolAddress,
        uint256[N_COINS] memory amounts,
        uint256 minMintAmount
    ) external onlyManager {
        address lpTokenAddress = _getLPToken(poolAddress);
        uint256 amountsLength = amounts.length;

        for (uint256 i = 0; i < amountsLength; i++) {
            if (amounts[i] > 0) {
                address coin = IStableSwapPool(poolAddress).coins(i);

                require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

                uint256 balance = IERC20(coin).balanceOf(address(this));

                require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

                _approve(IERC20(coin), poolAddress, amounts[i]);
            }
        }

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

        require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
    }

    /// @notice Withdraw liquidity from Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param poolAddress Token addresses
    /// @param amounts List of amounts of underlying coins to withdraw
    /// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
    function withdrawImbalance(
        address poolAddress,
        uint256[N_COINS] memory amounts,
        uint256 maxBurnAmount
    ) external onlyManager {
        address lpTokenAddress = _getLPTokenAndApprove(poolAddress, maxBurnAmount);

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

        IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

        require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
    }

    /// @notice Withdraw liquidity from Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param poolAddress Token addresses
    /// @param amount Quantity of LP tokens to burn in the withdrawal
    /// @param minAmounts Minimum amounts of underlying coins to receive
    function withdraw(
        address poolAddress,
        uint256 amount,
        uint256[N_COINS] memory minAmounts
    ) external onlyManager {
        address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

        IStableSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

        require(lpTokenBalanceBefore - amount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
    }

    /// @notice Withdraw liquidity from Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param poolAddress token addresses
    /// @param tokenAmount Amount of LP tokens to burn in the withdrawal
    /// @param i Index value of the coin to withdraw
    /// @param minAmount Minimum amount of coin to receive
    function withdrawOneCoin(
        address poolAddress,
        uint256 tokenAmount,
        int128 i,
        uint256 minAmount
    ) external onlyManager {
        address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
        address coin = IStableSwapPool(poolAddress).coins(uint128(i));

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

        IStableSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

        require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
        require(lpTokenBalanceBefore - tokenAmount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
    }

    function _getLPToken(address poolAddress) internal returns (address) {
        require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

        address registryAddress = addressProvider.get_registry();
        address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

        // If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
        // https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
        if (lpTokenAddress == address(0)) {
            lpTokenAddress = poolAddress;
        }

        require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

        return lpTokenAddress;
    }

    function _getCoinsBalances(address poolAddress)
        internal
        returns (uint256[N_COINS] memory coinsBalances)
    {
        for (uint256 i = 0; i < N_COINS; i++) {
            address coin = IStableSwapPool(poolAddress).coins(i);
            uint256 balance = IERC20(coin).balanceOf(address(this));
            coinsBalances[i] = balance;
        }
        return coinsBalances;
    }

    function _compareCoinsBalances(
        uint256[N_COINS] memory balancesBefore,
        uint256[N_COINS] memory balancesAfter,
        uint256[N_COINS] memory amounts
    ) internal pure {
        for (uint256 i = 0; i < N_COINS; i++) {
            if (amounts[i] > 0) {
                require(balancesBefore[i] < balancesAfter[i], "BALANCE_MUST_INCREASE");
            }
        }
    }

    function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
        address lpTokenAddress = _getLPToken(poolAddress);
        if (lpTokenAddress != poolAddress) {
            _approve(IERC20(lpTokenAddress), poolAddress, amount);
        }
        return lpTokenAddress;
    }

    function _approve(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(spender, currentAllowance);
        }
        token.safeIncreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IStableSwapPool {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(uint256[4] memory amounts, uint256 max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity(uint256 amount, uint256[3] memory min_amounts)
        external
        returns (uint256[3] memory);

    function remove_liquidity(uint256 amount, uint256[4] memory min_amounts)
        external
        returns (uint256[4] memory);

    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount)
        external
        returns (uint256);

    function coins(uint256 i) external returns (address);

    function balanceOf(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IRegistry {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */
    function get_lp_token(address pool) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IAddressProvider {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */
    function get_registry() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/balancer/IBalancerPool.sol";
import "./BaseController.sol";

contract BalancerController is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line no-empty-blocks
    constructor(address manager, address _addressRegistry) public BaseController(manager, _addressRegistry) {}

    /// @notice Used to deploy liquidity to a Balancer pool
    /// @dev Calls into external contract
    /// @param poolAddress Address of pool to have liquidity added
    /// @param tokens Array of ERC20 tokens to be added to pool
    /// @param amounts Corresponding array of amounts of tokens to be added to a pool
    /// @param data Bytes data passed from manager containing information to be passed to the balancer pool
    function deploy(
        address poolAddress,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyManager {
        require(tokens.length == amounts.length, "TOKEN_AMOUNTS_COUNT_MISMATCH");
        require(tokens.length > 0, "TOKENS_AMOUNTS_NOT_PROVIDED");

        for (uint256 i = 0; i < tokens.length; i++) {
            require(addressRegistry.checkAddress(address(tokens[i]), 0), "INVALID_TOKEN");
            _approve(tokens[i], poolAddress, amounts[i]);
        }

        IBalancerPool pool = IBalancerPool(poolAddress);
        uint256 balanceBefore = pool.balanceOf(address(this));

        //Notes:
        // - If your pool is eligible for weekly BAL rewards, they will be distributed to your LPs automatically
        // - If you contribute significant long-term liquidity to the platform, you can apply to have smart contract deployment gas costs reimbursed from the Balancer Ecosystem fund
        // - The pool is the LP token, All pools in Balancer are also ERC20 tokens known as BPTs \(Balancer Pool Tokens\)
        (uint256 poolAmountOut, uint256[] memory maxAmountsIn) = abi.decode(
            data,
            (uint256, uint256[])
        );
        pool.joinPool(poolAmountOut, maxAmountsIn);
        
        uint256 balanceAfter = pool.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "MUST_INCREASE");
    }

    /// @notice Used to withdraw liquidity from balancer pools
    /// @dev Calls into external contract
    /// @param poolAddress Address of pool to have liquidity withdrawn
    /// @param data Data to be decoded and passed to pool
    function withdraw(address poolAddress, bytes calldata data) external onlyManager {
        (uint256 poolAmountIn, uint256[] memory minAmountsOut) = abi.decode(
            data,
            (uint256, uint256[])
        );

        IBalancerPool pool = IBalancerPool(poolAddress);
        address[] memory tokens = pool.getFinalTokens();
        uint256[] memory balancesBefore = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            balancesBefore[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        _approve(IERC20(poolAddress), poolAddress, poolAmountIn);
        pool.exitPool(poolAmountIn, minAmountsOut);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balanceAfter = IERC20(tokens[i]).balanceOf(address(this));
            require(balanceAfter > balancesBefore[i], "MUST_INCREASE");
        }
    }

    function _approve(
        IERC20 token,
        address poolAddress,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), poolAddress);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(poolAddress, currentAllowance);
        }
        token.safeIncreaseAllowance(poolAddress, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/// @title Interface for a Balancer Labs BPool
/// @dev https://docs.balancer.fi/v/v1/smart-contracts/interfaces
interface IBalancerPool {
    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function getBalance(address token) external view returns (uint256);

    function decimals() external view returns (uint8);

    function isFinalized() external view returns (bool);

    function getFinalTokens() external view returns (address[] memory tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./BaseController.sol";
import "../interfaces/convex/IConvexBooster.sol";
import "../interfaces/convex/IConvexBaseReward.sol";
import "../interfaces/convex/ConvexPoolInfo.sol";

contract ConvexController is BaseController {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IConvexBooster public immutable BOOSTER;

    struct ExpectedReward {
        address token;
        uint256 minAmount;
    }

    constructor(
        address _manager,
        address _addressRegistry,
        address _convexBooster
    ) public BaseController(_manager, _addressRegistry) {
        require(_convexBooster != address(0), "INVALID_BOOSTER_ADDRESS");

        BOOSTER = IConvexBooster(_convexBooster);
    }

    /// @notice deposits and stakes Curve LP tokens to Convex
    /// @param lpToken Curve LP token to deposit
    /// @param staking Convex reward contract associated with the Curve LP token
    /// @param poolId Convex poolId for the associated Curve LP token
    /// @param amount Quantity of Curve LP token to deposit and stake
    function depositAndStake(
        address lpToken,
        address staking,
        uint256 poolId,
        uint256 amount
    ) external onlyManager {
        require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
        require(staking != address(0), "INVALID_STAKING_ADDRESS");
        require(amount > 0, "INVALID_AMOUNT");
        ConvexPoolInfo memory itemInfo =  BOOSTER.poolInfo(poolId);
        address lptoken = itemInfo.lptoken;
        address crvRewards = itemInfo.crvRewards;
        require(lpToken == lptoken, "POOL_ID_LP_TOKEN_MISMATCH");
        require(staking == crvRewards, "POOL_ID_STAKING_MISMATCH");

        _approve(IERC20(lpToken), amount);

        uint256 beforeBalance = IConvexBaseRewards(staking).balanceOf(address(this));

        bool success = BOOSTER.deposit(poolId, amount, true);
        require(success, "DEPOSIT_AND_STAKE_FAILED");

        uint256 balanceChange = IConvexBaseRewards(staking).balanceOf(address(this)).sub(
            beforeBalance
        );
        require(balanceChange == amount, "BALANCE_MUST_INCREASE");
    }

    /// @notice withdraws a Curve LP token from Convex
    /// @dev does not claim available rewards
    /// @param lpToken Curve LP token to withdraw
    /// @param staking Convex reward contract associated with the Curve LP token
    /// @param amount Quantity of Curve LP token to withdraw
    function withdrawStake(
        address lpToken,
        address staking,
        uint256 amount
    ) external onlyManager {
        require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
        require(staking != address(0), "INVALID_STAKING_ADDRESS");
        require(amount > 0, "INVALID_AMOUNT");

        uint256 beforeBalance = IERC20(lpToken).balanceOf(address(this));

        bool success = IConvexBaseRewards(staking).withdrawAndUnwrap(amount, false);
        require(success, "WITHDRAW_STAKE_FAILED");

        uint256 balanceChange = IERC20(lpToken).balanceOf(address(this)).sub(beforeBalance);
        require(balanceChange == amount, "BALANCE_MUST_INCREASE");
    }

    /// @notice claims all Convex rewards associated with the target Curve LP token
    /// @param staking Convex reward contract associated with the Curve LP token
    /// @param expectedRewards List of expected reward tokens and min amounts to receive on claim
    function claimRewards(address staking, ExpectedReward[] memory expectedRewards)
        external
        onlyManager
    {
        require(staking != address(0), "INVALID_STAKING_ADDRESS");
        require(expectedRewards.length > 0, "INVALID_EXPECTED_REWARDS");

        uint256[] memory beforeBalances = new uint256[](expectedRewards.length);

        for (uint256 i = 0; i < expectedRewards.length; i++) {
            require(expectedRewards[i].token != address(0), "INVALID_REWARD_TOKEN_ADDRESS");
            require(expectedRewards[i].minAmount > 0, "INVALID_MIN_REWARD_AMOUNT");
            beforeBalances[i] = IERC20(expectedRewards[i].token).balanceOf(address(this));
        }

        bool success = IConvexBaseRewards(staking).getReward();
        require(success, "CLAIM_REWARD_FAILED");

        for (uint256 i = 0; i < expectedRewards.length; i++) {
            uint256 balanceChange = IERC20(expectedRewards[i].token).balanceOf(address(this)).sub(
                beforeBalances[i]
            );
            require(balanceChange > expectedRewards[i].minAmount, "BALANCE_MUST_INCREASE");
        }
    }

    function _approve(IERC20 token, uint256 amount) internal {
        address spender = address(BOOSTER);
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(spender, currentAllowance);
        }
        token.safeIncreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./ConvexPoolInfo.sol";

//main Convex contract(booster.sol) basic interface
interface IConvexBooster {
    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    //get poolInfo for a poolId
    function poolInfo(uint256 _pid) external returns (ConvexPoolInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IConvexBaseRewards {
    //get balance of an address
    function balanceOf(address _account) external returns (uint256);

    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

    //claim rewards
    function getReward() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

struct ConvexPoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./IEventSender.sol";
import "../IEventProxy.sol";
/// @title Base contract for sending events to our Governance layer
abstract contract EventSender is IEventSender {
    bool public eventSend;
    IEventProxy public eventProxy;
    modifier onEventSend() {
        // Only send the event when enabled
        if (eventSend) {
            _;
        }
    }

    modifier onlyEventSendControl() {
        // Give the implementing contract control over permissioning
        require(canControlEventSend(), "CANNOT_CONTROL_EVENTS");
        _;
    }

    /// @notice Enables or disables the sending of events
    function setEventSend(bool eventSendSet) external virtual override onlyEventSendControl {
        eventSend = eventSendSet;

        emit EventSendSet(eventSendSet);
    }

    /// @notice Determine permissions for controlling event sending
    /// @dev Should not revert, just return false
    function canControlEventSend() internal view virtual returns (bool);

    /// @notice Send event data to Governance layer
    function sendEvent(bytes memory data) internal virtual {
        require(address(eventProxy) != address(0), "ADDRESS_NOT_SET");
        eventProxy.processMessageFromRoot(address(this), data);
    }
    function setEventProxy(address _eventProxy) external override onlyEventSendControl {
        require(_eventProxy != address(0), "ADDRESS INVALID");
        eventProxy = IEventProxy(_eventProxy);
    }

}