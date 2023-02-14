// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/access-control/IRBAC.sol";

import "../libs/arrays/ArrayHelper.sol";
import "../libs/arrays/SetHelper.sol";

/**
 *  @notice The Role Based Access Control (RBAC) module
 *
 *  This is advanced module that handles role management for huge systems. One can declare specific permissions
 *  for specific resources (contracts) and aggregate them into roles for further assignment to users.
 *
 *  Each user can have multiple roles and each role can manage multiple resources. Each resource can posses a set of
 *  permissions (CREATE, DELETE) that are only valid for that specific resource.
 *
 *  The RBAC model supports antipermissions as well. One can grant antipermissions to users to restrict their access level.
 *  There also is a special wildcard symbol "*" that means "everything". This symbol can be applied either to the
 *  resources or permissions.
 */
abstract contract RBAC is IRBAC, Initializable {
    using StringSet for StringSet.Set;
    using SetHelper for StringSet.Set;
    using ArrayHelper for string;

    string public constant MASTER_ROLE = "MASTER";

    string public constant ALL_RESOURCE = "*";
    string public constant ALL_PERMISSION = "*";

    string public constant CREATE_PERMISSION = "CREATE";
    string public constant READ_PERMISSION = "READ";
    string public constant UPDATE_PERMISSION = "UPDATE";
    string public constant DELETE_PERMISSION = "DELETE";

    string public constant RBAC_RESOURCE = "RBAC_RESOURCE";

    mapping(string => mapping(bool => mapping(string => StringSet.Set))) private _rolePermissions;
    mapping(string => mapping(bool => StringSet.Set)) private _roleResources;

    mapping(address => StringSet.Set) private _userRoles;

    modifier onlyPermission(string memory resource_, string memory permission_) {
        require(
            hasPermission(msg.sender, resource_, permission_),
            string(
                abi.encodePacked("RBAC: no ", permission_, " permission for resource ", resource_)
            )
        );
        _;
    }

    /**
     *  @notice The init function
     */
    function __RBAC_init() internal onlyInitializing {
        _addPermissionsToRole(MASTER_ROLE, ALL_RESOURCE, ALL_PERMISSION.asArray(), true);
    }

    /**
     *  @notice The function to grant roles to a user
     *  @param to_ the user to grant roles to
     *  @param rolesToGrant_ roles to grant
     */
    function grantRoles(
        address to_,
        string[] memory rolesToGrant_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(rolesToGrant_.length > 0, "RBAC: empty roles");

        _grantRoles(to_, rolesToGrant_);
    }

    /**
     *  @notice The function to revoke roles
     *  @param from_ the user to revoke roles from
     *  @param rolesToRevoke_ the roles to revoke
     */
    function revokeRoles(
        address from_,
        string[] memory rolesToRevoke_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(rolesToRevoke_.length > 0, "RBAC: empty roles");

        _revokeRoles(from_, rolesToRevoke_);
    }

    /**
     *  @notice The function to add resource permission to role
     *  @param role_ the role to add permissions to
     *  @param permissionsToAdd_ the array of resources and permissions to add to the role
     *  @param allowed_ indicates whether to add permissions to an allowlist or disallowlist
     */
    function addPermissionsToRole(
        string memory role_,
        ResourceWithPermissions[] memory permissionsToAdd_,
        bool allowed_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        for (uint256 i = 0; i < permissionsToAdd_.length; i++) {
            _addPermissionsToRole(
                role_,
                permissionsToAdd_[i].resource,
                permissionsToAdd_[i].permissions,
                allowed_
            );
        }
    }

    /**
     *  @notice The function to remove permissions from role
     *  @param role_ the role to remove permissions from
     *  @param permissionsToRemove_ the array of resources and permissions to remove from the role
     *  @param allowed_ indicates whether to remove permissions from the allowlist or disallowlist
     */
    function removePermissionsFromRole(
        string memory role_,
        ResourceWithPermissions[] memory permissionsToRemove_,
        bool allowed_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        for (uint256 i = 0; i < permissionsToRemove_.length; i++) {
            _removePermissionsFromRole(
                role_,
                permissionsToRemove_[i].resource,
                permissionsToRemove_[i].permissions,
                allowed_
            );
        }
    }

    /**
     *  @notice The function to get the list of user roles
     *  @param who_ the user
     *  @return roles_ the roes of the user
     */
    function getUserRoles(address who_) public view override returns (string[] memory roles_) {
        return _userRoles[who_].values();
    }

    /**
     *  @notice The function to get the permissions of the role
     *  @param role_ the role
     *  @return allowed_ the list of allowed permissions of the role
     *  @return disallowed_ the list of disallowed permissions of the role
     */
    function getRolePermissions(
        string memory role_
    )
        public
        view
        override
        returns (
            ResourceWithPermissions[] memory allowed_,
            ResourceWithPermissions[] memory disallowed_
        )
    {
        StringSet.Set storage _allowedResources = _roleResources[role_][true];
        StringSet.Set storage _disallowedResources = _roleResources[role_][false];

        mapping(string => StringSet.Set) storage _allowedPermissions = _rolePermissions[role_][
            true
        ];
        mapping(string => StringSet.Set) storage _disallowedPermissions = _rolePermissions[role_][
            false
        ];

        allowed_ = new ResourceWithPermissions[](_allowedResources.length());
        disallowed_ = new ResourceWithPermissions[](_disallowedResources.length());

        for (uint256 i = 0; i < allowed_.length; i++) {
            allowed_[i].resource = _allowedResources.at(i);
            allowed_[i].permissions = _allowedPermissions[allowed_[i].resource].values();
        }

        for (uint256 i = 0; i < disallowed_.length; i++) {
            disallowed_[i].resource = _disallowedResources.at(i);
            disallowed_[i].permissions = _disallowedPermissions[disallowed_[i].resource].values();
        }
    }

    /**
     *  @notice The function to check the user's possesion of the role
     *  @param who_ the user
     *  @param resource_ the resource the user has to have the permission of
     *  @param permission_ the permission the user has to have
     *  @return true_ if user has the permission, false otherwise
     */
    function hasPermission(
        address who_,
        string memory resource_,
        string memory permission_
    ) public view override returns (bool) {
        StringSet.Set storage _roles = _userRoles[who_];

        uint256 length_ = _roles.length();
        bool isAllowed_;

        for (uint256 i = 0; i < length_; i++) {
            string memory role_ = _roles.at(i);

            StringSet.Set storage _allDisallowed = _rolePermissions[role_][false][ALL_RESOURCE];
            StringSet.Set storage _allAllowed = _rolePermissions[role_][true][ALL_RESOURCE];

            StringSet.Set storage _disallowed = _rolePermissions[role_][false][resource_];
            StringSet.Set storage _allowed = _rolePermissions[role_][true][resource_];

            if (
                _allDisallowed.contains(ALL_PERMISSION) ||
                _allDisallowed.contains(permission_) ||
                _disallowed.contains(ALL_PERMISSION) ||
                _disallowed.contains(permission_)
            ) {
                return false;
            }

            if (
                _allAllowed.contains(ALL_PERMISSION) ||
                _allAllowed.contains(permission_) ||
                _allowed.contains(ALL_PERMISSION) ||
                _allowed.contains(permission_)
            ) {
                isAllowed_ = true;
            }
        }

        return isAllowed_;
    }

    /**
     *  @notice The internal function to grant roles
     *  @param to_ the user to grant roles to
     *  @param rolesToGrant_ the roles to grant
     */
    function _grantRoles(address to_, string[] memory rolesToGrant_) internal {
        _userRoles[to_].add(rolesToGrant_);

        emit GrantedRoles(to_, rolesToGrant_);
    }

    /**
     *  @notice The internal function to revoke roles
     *  @param from_ the user to revoke roles from
     *  @param rolesToRevoke_ the roles to revoke
     */
    function _revokeRoles(address from_, string[] memory rolesToRevoke_) internal {
        _userRoles[from_].remove(rolesToRevoke_);

        emit RevokedRoles(from_, rolesToRevoke_);
    }

    /**
     *  @notice The internal function to add permission to the role
     *  @param role_ the role to add permissions to
     *  @param resourceToAdd_ the resource to which the permissions belong
     *  @param permissionsToAdd_ the permissions of the resource
     *  @param allowed_ whether to add permissions to the allowlist or the disallowlist
     */
    function _addPermissionsToRole(
        string memory role_,
        string memory resourceToAdd_,
        string[] memory permissionsToAdd_,
        bool allowed_
    ) internal {
        StringSet.Set storage _resources = _roleResources[role_][allowed_];
        StringSet.Set storage _permissions = _rolePermissions[role_][allowed_][resourceToAdd_];

        _permissions.add(permissionsToAdd_);
        _resources.add(resourceToAdd_);

        emit AddedPermissions(role_, resourceToAdd_, permissionsToAdd_, allowed_);
    }

    /**
     *  @notice The internal function to remove permissions from the role
     *  @param role_ the role to remove permissions from
     *  @param resourceToRemove_ the resource to which the permissions belong
     *  @param permissionsToRemove_ the permissions of the resource
     *  @param allowed_ whether to remove permissions from the allowlist or the disallowlist
     */
    function _removePermissionsFromRole(
        string memory role_,
        string memory resourceToRemove_,
        string[] memory permissionsToRemove_,
        bool allowed_
    ) internal {
        StringSet.Set storage _resources = _roleResources[role_][allowed_];
        StringSet.Set storage _permissions = _rolePermissions[role_][allowed_][resourceToRemove_];

        _permissions.remove(permissionsToRemove_);

        if (_permissions.length() == 0) {
            _resources.remove(resourceToRemove_);
        }

        emit RemovedPermissions(role_, resourceToRemove_, permissionsToRemove_, allowed_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../libs/data-structures/StringSet.sol";

/**
 *  @notice The RBAC module
 */
interface IRBAC {
    struct ResourceWithPermissions {
        string resource;
        string[] permissions;
    }

    event GrantedRoles(address to, string[] rolesToGrant);
    event RevokedRoles(address from, string[] rolesToRevoke);

    event AddedPermissions(string role, string resource, string[] permissionsToAdd, bool allowed);
    event RemovedPermissions(
        string role,
        string resource,
        string[] permissionsToRemove,
        bool allowed
    );

    function grantRoles(address to_, string[] memory rolesToGrant_) external;

    function revokeRoles(address from_, string[] memory rolesToRevoke_) external;

    function addPermissionsToRole(
        string calldata role_,
        ResourceWithPermissions[] calldata permissionsToAdd_,
        bool allowed_
    ) external;

    function removePermissionsFromRole(
        string calldata role_,
        ResourceWithPermissions[] calldata permissionsToRemove_,
        bool allowed_
    ) external;

    function getUserRoles(address who_) external view returns (string[] memory roles_);

    function getRolePermissions(
        string calldata role_
    )
        external
        view
        returns (
            ResourceWithPermissions[] calldata allowed_,
            ResourceWithPermissions[] calldata disallowed_
        );

    function hasPermission(
        address who_,
        string calldata resource_,
        string calldata permission_
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice A simple library to work with arrays
 */
library ArrayHelper {
    /**
     *  @notice The function to reverse an array
     *  @param arr_ the array to reverse
     *  @return reversed_ the reversed array
     */
    function reverse(uint256[] memory arr_) internal pure returns (uint256[] memory reversed_) {
        reversed_ = new uint256[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(address[] memory arr_) internal pure returns (address[] memory reversed_) {
        reversed_ = new address[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(string[] memory arr_) internal pure returns (string[] memory reversed_) {
        reversed_ = new string[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     *  @notice The function to insert an array into the other array
     *  @param to_ the array to insert into
     *  @param index_ the insertion starting index
     *  @param what_ the array to be inserted
     *  @return the index to start the next insertion from
     */
    function insert(
        uint256[] memory to_,
        uint256 index_,
        uint256[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        address[] memory to_,
        uint256 index_,
        address[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        string[] memory to_,
        uint256 index_,
        string[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     *  @notice The function to transform an element into an array
     *  @param elem_ the element
     *  @return array_ the element as an array
     */
    function asArray(uint256 elem_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = elem_;
    }

    function asArray(address elem_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = elem_;
    }

    function asArray(string memory elem_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = elem_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../data-structures/StringSet.sol";

/**
 *  @notice A simple library to work with sets
 */
library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StringSet for StringSet.Set;

    /**
     *  @notice The function to insert an array of elements into the set
     *  @param set the set to insert the elements into
     *  @param array_ the elements to be inserted
     */
    function add(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    function add(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    function add(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     *  @notice The function to remove an array of elements from the set
     *  @param set the set to remove the elements from
     *  @param array_ the elements to be removed
     */
    function remove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    function remove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    function remove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice Example:
 *
 *  using StringSet for StringSet.Set;
 *
 *  StringSet.Set internal set;
 */
library StringSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     *  @notice The function add value to set
     *  @param set the set object
     *  @param value_ the value to add
     */
    function add(Set storage set, string memory value_) internal returns (bool) {
        if (!contains(set, value_)) {
            set._values.push(value_);
            set._indexes[value_] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function remove value to set
     *  @param set the set object
     *  @param value_ the value to remove
     */
    function remove(Set storage set, string memory value_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[value_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                string memory lastvalue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastvalue_;
                set._indexes[lastvalue_] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[value_];

            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function returns true if value in the set
     *  @param set the set object
     *  @param value_ the value to search in set
     *  @return true if value is in the set, false otherwise
     */
    function contains(Set storage set, string memory value_) internal view returns (bool) {
        return set._indexes[value_] != 0;
    }

    /**
     *  @notice The function returns length of set
     *  @param set the set object
     *  @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     *  @notice The function returns value from set by index
     *  @param set the set object
     *  @param index_ the index of slot in set
     *  @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (string memory) {
        return set._values[index_];
    }

    /**
     *  @notice The function that returns values the set stores, can be very expensive to call
     *  @param set the set object
     *  @return the memory array of values
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant PRECISION = 10 ** 25;
uint256 constant DECIMAL = 10 ** 18;
uint256 constant PERCENTAGE_100 = 10 ** 27;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/utils/Globals.sol";

string constant MASTER_ROLE = "MASTER";

string constant CREATE_PERMISSION = "CREATE";
string constant UPDATE_PERMISSION = "UPDATE";
string constant EXECUTE_PERMISSION = "EXECUTE";
string constant DELETE_PERMISSION = "DELETE";

string constant CREATE_VOTING_PERMISSION = "CREATE";

string constant VOTE_PERMISSION = "VOTE";
string constant VETO_PERMISSION = "VETO";

string constant REGISTRY_RESOURCE = "REGISTRY_RESOURCE";

string constant DAO_MAIN_PANEL_NAME = "DAO_CONSTITUTION";

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/access-control/RBAC.sol";

import "../interfaces/IMasterAccessManagement.sol";

import "./Globals.sol";

contract MasterAccessManagement is IMasterAccessManagement, RBAC {
    using ArrayHelper for string;

    string public constant MASTER_REGISTRY_RESOURCE = "MASTER_REGISTRY_RESOURCE";

    event AddedRoleWithDescription(string role, string description);

    function __MasterAccessManagement_init(address master_) external initializer {
        __RBAC_init();
        _grantRoles(master_, MASTER_ROLE.asArray());
    }

    function addCombinedPermissionsToRole(
        string memory role_,
        string calldata description_,
        ResourceWithPermissions[] memory allowed_,
        ResourceWithPermissions[] memory disallowed_
    ) public override {
        addPermissionsToRole(role_, allowed_, true);
        addPermissionsToRole(role_, disallowed_, false);

        emit AddedRoleWithDescription(role_, description_);
    }

    function removeCombinedPermissionsFromRole(
        string memory role_,
        ResourceWithPermissions[] memory allowed_,
        ResourceWithPermissions[] memory disallowed_
    ) public override {
        removePermissionsFromRole(role_, allowed_, true);
        removePermissionsFromRole(role_, disallowed_, false);
    }

    function updateRolePermissions(
        string memory role_,
        string calldata description_,
        ResourceWithPermissions[] memory allowedToRemove_,
        ResourceWithPermissions[] memory disallowedToRemove_,
        ResourceWithPermissions[] memory allowedToAdd_,
        ResourceWithPermissions[] memory disallowedToAdd_
    ) external override {
        removeCombinedPermissionsFromRole(role_, allowedToRemove_, disallowedToRemove_);
        addCombinedPermissionsToRole(role_, description_, allowedToAdd_, disallowedToAdd_);
    }

    function updateUserRoles(
        address user_,
        string[] memory rolesToRevoke_,
        string[] memory rolesToGrant_
    ) external override {
        revokeRoles(user_, rolesToRevoke_);
        grantRoles(user_, rolesToGrant_);
    }

    function hasMasterContractsRegistryCreatePermission(
        address account_
    ) external view override returns (bool) {
        return hasPermission(account_, MASTER_REGISTRY_RESOURCE, CREATE_PERMISSION);
    }

    function hasMasterContractsRegistryUpdatePermission(
        address account_
    ) external view override returns (bool) {
        return hasPermission(account_, MASTER_REGISTRY_RESOURCE, UPDATE_PERMISSION);
    }

    function hasMasterContractsRegistryDeletePermission(
        address account_
    ) external view override returns (bool) {
        return hasPermission(account_, MASTER_REGISTRY_RESOURCE, DELETE_PERMISSION);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/interfaces/access-control/IRBAC.sol";

interface IMasterAccessManagement is IRBAC {
    function addCombinedPermissionsToRole(
        string memory role_,
        string calldata description_,
        ResourceWithPermissions[] memory allowed_,
        ResourceWithPermissions[] memory disallowed_
    ) external;

    function removeCombinedPermissionsFromRole(
        string memory role_,
        ResourceWithPermissions[] memory allowed_,
        ResourceWithPermissions[] memory disallowed_
    ) external;

    function updateRolePermissions(
        string memory role_,
        string calldata description_,
        ResourceWithPermissions[] memory allowedToRemove_,
        ResourceWithPermissions[] memory disallowedToRemove_,
        ResourceWithPermissions[] memory allowedToAdd_,
        ResourceWithPermissions[] memory disallowedToAdd_
    ) external;

    function updateUserRoles(
        address user_,
        string[] memory rolesToRevoke_,
        string[] memory rolesToGrant_
    ) external;

    function hasMasterContractsRegistryCreatePermission(
        address account_
    ) external view returns (bool);

    function hasMasterContractsRegistryUpdatePermission(
        address account_
    ) external view returns (bool);

    function hasMasterContractsRegistryDeletePermission(
        address account_
    ) external view returns (bool);
}