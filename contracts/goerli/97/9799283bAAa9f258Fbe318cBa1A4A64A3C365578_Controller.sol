// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERCTokenBase.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


abstract contract ERC20Base is ERC20Upgradeable, ERCTokenBase
{
    // Storage gap to allow adding new members in upgrades.
    uint256[20] private __gap;

    function __ERC20Base_init(
        string memory name,
        string memory symbol,
        address[] memory admins
    )
        internal onlyInitializing
    {
        __ERC20_init(name, symbol);
        __ERCTokenBase_init(admins);
    }

    /// @dev See {ERC20-decimals}.
    function decimals() public view virtual override returns (uint8)
    {
        return 18;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC20Base.sol";

abstract contract ERC20MintableBurnable is ERC20Base
{

    /// @dev AccessControl role that gives access to mint() and burn().
    bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

    // Storage gap to allow adding new members in upgrades.
    uint256[20] private __gap;

    /// @notice Initializer. Call from within child contracts' initializers.
    function __ERC20MintableBurnable_init(
        string memory name,
        string memory symbol,
        address[] memory admins
    ) 
        internal onlyInitializing
    {
        __ERC20Base_init(name, symbol, admins);
    }

    /// @notice Mints `value` to the balance of `account`.
    /// @param account The address to add mint to.
    /// @param value The amount to mint.
    function mint(address account, uint256 value)
        external whenNotPaused onlyRole(MINTER_BURNER_ROLE)
    {
        _mint(account, value);
    }

    /// @notice Burns `value` from the balance of `account`.
    /// @param account The address to add burn.
    /// @param value The amount to burn.
    function burn(address account, uint256 value)
        external whenNotPaused onlyRole(MINTER_BURNER_ROLE)
    {
        _burn(account, value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";
import "./ERC20MintableBurnable.sol";

/// @title ERC20Reward Base Contract.
///
/// Extends the base {ERC20MintableBurnable} contract with the concept of rewards.
/// The reward amount is updated on every operation that changes the
/// balance of an account (transfer, mint and burn). It is calculated
/// by multiplying the total Token balance of the account with the elapsed
/// seconds since the last update (Token * seconds).
/// 
/// The available reward amount for an account can be claimed via
/// {claimReward()}. This amount is in Token * seconds since the last
/// claim.
///
/// @dev The transfer, mint and burn operations are intercepted via
///      the {_beforeTokenTransfer()} hook. This will call the {_reward()}
///      method to update the reward amount for both the `from` and `to`
///      accounts if they are not null.
abstract contract ERC20Reward is ERC20MintableBurnable
{
    
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    
    /// @dev AccessControl role that gives access to mint() and burn().
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    // The timestamp of the last time the _Reward() function was called.
    mapping(address => uint256) private _iLastRewardTimes;

    // Stores the claimable reward per account.
    mapping(address => uint256) private _dClaimableReward;

    // The decay rate for the coin
    uint256 public D_REWARDS_DECAY_RATE;

    // Storage gap to allow adding new members in upgrades.
    uint256[20] private __gap;

    /// @notice Initializer. Call from within child contracts' initializers.
    function __ERC20Reward_init(
        string memory name,
        string memory symbol,
        address[] memory admins,
        uint256 dDecayRate
    ) 
        internal onlyInitializing
    {
        __ERC20MintableBurnable_init(name, symbol, admins);
        D_REWARDS_DECAY_RATE = dDecayRate;
    }

    /// @notice Updates the amount of claimable reward.
    /// @param account The address that's claiming reward.
    function _reward(address account) internal {
        if (_iLastRewardTimes[account] == 0) {
            // This is the first time this is called. Just set the last reward
            // time.
            _iLastRewardTimes[account] = block.timestamp;
            return;
        }

        // Update the unclaimed reward amount
        _dClaimableReward[account] = _calcClaimableReward(account);

        // Update the last reward time
        _iLastRewardTimes[account] = block.timestamp;

        // Emit a Reward event.
        emit Reward(account, _dClaimableReward[account]);
    }

    function _calcClaimableReward(address account) internal view returns (uint256) {
        uint256 iTimeSinceLastReward = block.timestamp - _iLastRewardTimes[account];
        uint256 dNewReward = iTimeSinceLastReward * balanceOf(account);
        uint256 dDecayAmount = iTimeSinceLastReward * _dClaimableReward[account].mul(D_REWARDS_DECAY_RATE);
        dDecayAmount = dDecayAmount.min(_dClaimableReward[account]);
        return _dClaimableReward[account] + dNewReward - dDecayAmount;
    }    

    /// @notice Determines how much total reward is unclaimed by the user
    /// @param account The address to determine the total reward for
    /// @return uint256 Amount of unclaimed reward for the address
    function claimableReward(address account)
        external view
        returns (uint256)
    {
        return _calcClaimableReward(account);
    }

    /// @notice Updates the reward of the accounts involved in a transfer/mint/burn.
    /// @param from The `from` account in a transfer/burn and 0 when minting.
    /// @param to The `to` account in a transfer/minting or 0 when burning.
    /// @param amount The token amount being transferred, minted or burned.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // Uptate the `from` address reward if this is a transfer or burn.
        if (from != address(0) && amount > 0) {
            _reward(from);
        }
        
        // Uptate the `to` address reward if this is a transfer or mint.
        if (to != address(0) && amount > 0) {
            _reward(to);
        }
    }

    /// @notice Determines the current amount of claimable reward to be sent to the user and resets the claimable reward to zero.
    /// @param account The address for which the reward is being claimed and reset.
    /// @return uint256 The amount of claimable reward before the reset.
    function claimReward(address account)
        external whenNotPaused onlyRole(CLAIMER_ROLE)
        returns (uint256)
    {
        // Update the claimable reward.
        _reward(account);

        // Get the claimable reward to be returned.
        uint256 dClaimedAmount = _dClaimableReward[account];

        // Reset the claimable reward.
        _dClaimableReward[account] = 0;

        // Emit a ClaimReward event.
        emit ClaimReward(account, dClaimedAmount);
        
        return dClaimedAmount;
    }

    /// @dev Emitted when _reward() runs.
    /// @param claimableReward The claimable reward, including the new amount.
    event Reward(address indexed account, uint256 claimableReward);

    /// @dev Emitted when claimReward() runs.
    /// @param account The account for which the reward is being claimed.
    /// @param amount The amount of reward being claimed.
    event ClaimReward(address indexed account, uint256 amount);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERCTokenBase.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";


abstract contract ERC721Base is ERC721EnumerableUpgradeable, ERCTokenBase
{
    // Storage gap to allow adding new members in upgrades.
    uint256[20] private __gap;

    function __ERC721Base_init(
        string memory name,
        string memory symbol,
        address[] memory admins
    )
        internal onlyInitializing
    {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERCTokenBase_init(admins);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165
     **/
    function supportsInterface(bytes4 interfaceId)
        public virtual view
        override(ERC721EnumerableUpgradeable, ERCTokenBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


abstract contract ERCTokenBase is
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    uint256[20] private __gap;

    /// @notice Initializer. Call from within child contracts' initializers.
    function __ERCTokenBase_init(address[] memory admins)
        internal onlyInitializing
    {
        __AccessControl_init();
        __AccessControlEnumerable_init();
        __Pausable_init();

        // Give the admin addresses the DEFAULT_ADMIN_ROLE
        for (uint i = 0; i < admins.length; ++i) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    function _authorizeUpgrade(address)
        internal override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // Extend in order to execute upgrade code.
    // TODO come up with a mechanism to allow to run it only once per version?
    function upgrade() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {}

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165
     **/
    function supportsInterface(bytes4 interfaceId)
        public virtual view
        override(AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../lib/FixedPoint.sol";

/** @title Virtual pool contract.
    @notice Creates a virtual pool that behaves like a typical constant product
        pool, but tokens are minted/burned during trades rather than being
        swapped with liquidity providers.
    @dev This is designed to be used inside another contract that should be set
        as its owner.
*/
abstract contract VirtualPool is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    uint256 public poolSizeA;
    uint256 public poolSizeB;
    
    uint256 private initialConstant;

    /**
    @notice Initializer
    @param dPoolSizeA Amount of A tokens in the virtual pool with 18 decimals.
    @param dPoolSizeB Amount of B tokens in the virtual pool with 18 decimals.
    */
    function __VirtualPool_init(
        uint256 dPoolSizeA,
        uint256 dPoolSizeB
    )
        onlyInitializing public
    {
         __ReentrancyGuard_init();
        __Ownable_init();
  
        poolSizeA = dPoolSizeA;
        poolSizeB = dPoolSizeB;
        initialConstant = poolSizeA.mul(poolSizeB);
    }

    // todo comment
    function _authorizeUpgrade(address)
        internal override
        onlyOwner
    {}

    // todo document. Virtual functions. 
    function _takeA(address addr, uint256 amount) public payable virtual;
    function _takeB(address addr, uint256 amount) public payable virtual; 
    function _giveA(address addr, uint256 amount) public payable virtual; 
    function _giveB(address addr, uint256 amount) public payable virtual; 

    /**
    @notice Returns the spot price of A tokens in the virtual pool in terms of B tokens.
    @return uint256 Price of A tokens with 18 decimals.
    */
    function priceA() public view returns(uint256) {
        return poolSizeB.div(poolSizeA);
    }

    /**
    @notice Returns the spot price of B tokens in the virtual pool in terms of A tokens.
    @return uint256 Price of B tokens with 18 decimals.
    */
    function priceB() public view returns(uint256) {
        return poolSizeA.div(poolSizeB);
    }

    // TODO We want to generalize this and override this functionality in concrete implementations.
    /**
    @notice Changes the size of pools (for example to account for changes in the token supplies).
    @param dTargetRatio Multiple by which to scale the pools with 18 decimals.
    */
    function scalePools(uint256 dTargetRatio) public onlyOwner {
        uint256 dTargetConstant = initialConstant.mul(dTargetRatio);

        uint256 dPriceB = priceB();

        poolSizeA = (poolSizeA + dTargetConstant.div(poolSizeB)) / 2;
        poolSizeB = poolSizeA.div(dPriceB);
    }

    /**
    @notice Previews how many tokens would be sent to the user when swapping from A to B using the virtual pool.
    @param dAmountA Amount of token A to be swapped by the user with 18 decimals.
    @return uint256 Amount of token B to be sent to the user from the swap with 18 decimals.
    */
    function previewSwapAB(uint256 dAmountA) public view returns (uint256) {
        return calcSwapAmount(poolSizeA, poolSizeB, dAmountA);
    }

    /**
    @notice Updates pool sizes during a swap of token A for token B using the virtual pool.
    @param dAmountA Amount of token A to be swapped by the user with 18 decimals.
    @return uint256 Amount of token B to be sent to by the user from the swap with 18 decimals.
    */
    function swapAB(address addr, uint256 dAmountA, uint256 dMinAmountB, uint256 deadline)
        public payable nonReentrant onlyOwner
        returns (uint256)
    {
        require(deadline > block.timestamp, "Deadline Expired");

        // Calculate the swap return amount.
        uint256 dAmountB = calcSwapAmount(poolSizeA, poolSizeB, dAmountA);

        require(dMinAmountB <= dAmountB, "Resulting amountB < minAmountB");

        // TODO: run this before or after the swap?
        // Update the pool sizes
        require(dAmountB < poolSizeB, "Resulting swap amount larger than vpool");
        poolSizeA += dAmountA;
        poolSizeB -= dAmountB;

        // Transfer/burn/mint tokens.
        _takeA(addr, dAmountA);
        _giveB(addr, dAmountB);

        return dAmountB;
    }

    /**
    @notice Previews how many tokens would be sent to teh user when swapping from B to A using the virtual pool.
    @param dAmountB Amount of token B to be swapped by the user with 18 decimals.
    @return uint256 Amount of token A to be sent to the user from the swap with 18 decimals.
    */    
    function previewSwapBA(uint256 dAmountB) public view returns (uint256) {
        return calcSwapAmount(poolSizeB, poolSizeA, dAmountB);
    }

    /**
    @notice Updates pool sizes during a swap of token B for token A using the virtual pool.
    @param dAmountB Amount of token B to be swapped by the user with 18 decimals.
    @return uint256 Amount of token A to be sent to the user from the swap with 18 decimals.
    */
    function swapBA(address addr, uint256 dAmountB, uint256 dMinAmountA, uint256 deadline)
        public payable nonReentrant onlyOwner
        returns (uint256)
    {
        require(deadline > block.timestamp, "Deadline Expired");

        // Calculate the swap return amount.
        uint256 dAmountA = calcSwapAmount(poolSizeB, poolSizeA, dAmountB);

        require(dMinAmountA <= dAmountA, "Resulting amountA < minAmountA");

        // TODO: run this before or after the swap?
        // Update the pool sizes
        require(dAmountA < poolSizeA, "Resulting swap amount larged than vpool");
        poolSizeA -= dAmountA;
        poolSizeB += dAmountB;

        // Transfer/burn/mint tokens.
        _takeB(addr, dAmountB);
        _giveA(addr, dAmountA);

        return dAmountA;
    }

    /**
    @notice Calculates how many tokens should be swapped according to a constant product curve.
    @param dPoolX Size of the pool for the token being swapped with 18 decimals.
    @param dPoolY Size of the pool for the token being sent to the user with 18 decimals.
    @param dChangeX Amount of the token to be swapped by the user with 18 decimals.
    @return uint256 Amount of the token to be sent to the user from the swap with 18 decimals.
    */
    function calcSwapAmount(
        uint256 dPoolX,
        uint256 dPoolY,
        uint256 dChangeX
    )
        private
        pure
        returns (uint256)
    {
        // Give up dChangeX in exchange for dChangeY
        //   dChangeY = (dPoolY * dChangeX) / (dPoolX + dChangeX)
        return dPoolY.mul(dChangeX).div(dPoolX + dChangeX);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// *** Generic constants.  *** //

// Seconds in a year.
uint256 constant I_YEAR = uint256(365 days);

// Seconds in a day.
uint256 constant I_DAY = uint256(1 days);

// *** Initial constant values.  *** //

// Token Initial supplies.
uint256 constant D_INITIAL_ICE_SUPPLY = 100000e18; // 100K
uint256 constant D_INITIAL_H2O_SUPPLY = 1000000e18; // 1M
uint256 constant D_INITIAL_STM_SUPPLY = 1000000e18; // 1M

// Initial pool sizes
uint256 constant D_INITIAL_ICE_POOL_H2O_SIZE = 100000e18; // 100K

// *** Default values for adjustable configs.  *** //

// Initial ICE dividend in H2O per second
uint256 constant D_DEFAULT_MELT_RATE = 2e16 / I_YEAR; // .02 H20 per year

// The percentage of ICE that is lost when you make a transfer of ICE
uint256 constant D_DEFAULT_ICE_TRANSFER_TAX = 2e16; // 2% tax

// Tells if the Ice token can be transferred between accounts.
bool constant D_DEFAULT_IS_ICE_TRANSFERABLE = true;

// How often the error
uint256 constant I_DEFAULT_ERROR_UPDATE_PERIOD = 30 * I_DAY; // 30 days

// Scale how fast the target supply updates
int256 constant I_DEFAULT_ERROR_SCALE_FACTOR = 10;

// How long an auction lasts
uint256 constant I_DEFAULT_AUCTION_PERIOD = 30 * I_DAY; // 30 days

// Safety ratio for negative auctions
uint256 constant D_AUCTION_SAFETY_BID_RATIO = 9e17; // 90%

// Safety fee for negative actions
uint256 constant D_AUCTION_SAFETY_FEE_RATIO = 1e17; // 10%

// STM rewards decay
uint256 constant D_DEFAULT_STM_REWARDS_DECAY_RATE = 0;

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


import "./lib/FixedPoint.sol";

import "./Constants.sol";
import "./tokens/IceToken.sol";
import "./tokens/H2OToken.sol";
import "./tokens/IceCube.sol";
import "./H2OIceVirtualPool.sol";

/** @title IceWater Controller to manage tokens and rewards.
    @notice A stable token H2O is managed based on a measurement token ICE.
*/
contract Controller is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    // The different tokens managed by the Controller.
    IceToken internal iceToken;
    IceCube internal iceCube;
    H2OToken internal h2oToken;

    // Virtual poolsfor swapping H2O <-> ICE.
    H2OIceVirtualPool private _icePool;

    // Target supply
    uint256 public dTargetH2OSupply;

    // Target supply update rate
    int256 public dTargetH2OSupplyChangeRate;

    // Amount of H2O per reward per ICE token.
    uint256 public meltRate;

    // pool prices
    uint256 public dLastICEPrice;
    uint256 public dAverageICEPrice;

    // The time of the last error calculation
    uint256 public iLastErrorTime;

    // The time of the last supply change rate update
    uint256 public iLastUpdateTime;

    // The time the last auction started
    uint256 public iLastAuctionTime;

    // H2O auction amount
    uint256 public auctionH2OAmount;

    // whether there is an active H2O auction
    bool public isPositiveAuctionActive;

    // whether there is an active ETH auction
    bool public isNegativeAuctionActive;

    // Flag that defines if it is possible to cancel an auction without having
    // to wait for the auction period to be over.
    bool public ignoreAuctionPeriod;

    // current leading bidder address
    address public leadingBidder;

    // current leading bid
    uint256 public leadingBid;

    // *** Settable Configuration Parameters *** //

    // How often supply change rate is updated
    uint256 public iErrorUpdatePeriod;

    // target supply update error scale
    int256 iErrorScaleFactor;

    // *** Initialization *** //

    /**
    @notice Initializer. At this point the token contracts will not be set yet,
        so most of the external functions will fail until {setTokens()} is
        called. This allows this contract to be deployed before the token
        contracts so that its address can be granted the admin role of those
        tokens.
     */
    function initialize() initializer public
    {
        __Ownable_init();
        __Pausable_init();

        iLastErrorTime = block.timestamp;
        iLastUpdateTime = block.timestamp;
        iLastAuctionTime = block.timestamp;

        // Initialize some member variable initial values.
        dTargetH2OSupply = D_INITIAL_H2O_SUPPLY;
        meltRate = D_DEFAULT_MELT_RATE;
        isPositiveAuctionActive = false;
        isNegativeAuctionActive = false;
        iErrorUpdatePeriod = I_DEFAULT_ERROR_UPDATE_PERIOD;
        iErrorScaleFactor = I_DEFAULT_ERROR_SCALE_FACTOR;

        ignoreAuctionPeriod = false;
    }

    // todo comment
    function _authorizeUpgrade(address)
        internal override
        onlyOwner
    {}

    /**
    @notice Sets the token contracts. This will also initialize all necessary
        internal variables as well all the roles for the internal virtual pools
        to be able to mint/burn tokens. This will only be able to run once.
    @param iceToken_ ERC20 Token for Ice (Token for measuring stability)
    @param h2oToken_ ERC20 Token for H2O (Stable Token)
    */
    function setTokens(
        IceToken iceToken_,
        H2OToken h2oToken_,
        IceCube iceCube_
    )
        external onlyOwner
    {
        // todo Allow re-set tokens? (revoke roles and re-assign them?)
        // Make sure this is only called once.
        require(address(iceToken) == address(0)
                && address(h2oToken) == address(0)
                && address(iceCube) == address(0),
            "TOKENS_ALREADY_SET");

        iceToken = iceToken_;
        h2oToken = h2oToken_;
        iceCube = iceCube_;

        // Initialize the H2O <-> ICE virtual pool.
        _icePool = new H2OIceVirtualPool();
        _icePool.initialize(
            h2oToken,
            iceToken,
            D_INITIAL_ICE_POOL_H2O_SIZE,
            D_INITIAL_ICE_POOL_H2O_SIZE
        );

        // Store target H2O
        // Initially, we want to enable the purchase of ice cubes equal to the value of ICE
        dTargetH2OSupply = D_INITIAL_H2O_SUPPLY;

        // Grant MINTER_BURNER_ROLE to the ice pool tokens.
        iceToken.grantRole(iceToken.MINTER_BURNER_ROLE(), address(_icePool));
        h2oToken.grantRole(h2oToken.MINTER_BURNER_ROLE(), address(_icePool));

        // Grant MINTER_BURNER_ROLE and CLAIMER_ROLE to the Controller itself so 
        // that RewardsManager can claim the rewards and mint H2O tokens.
        h2oToken.grantRole(h2oToken.MINTER_BURNER_ROLE(), address(this));
        iceToken.grantRole(iceToken.MINTER_BURNER_ROLE(), address(this));
        iceToken.grantRole(iceToken.CLAIMER_ROLE(), address(this));
        iceCube.grantRole(iceCube.MINTER_REDEEMER_ROLE(), address(this));
    }

    function setIgnoreAuctionPeriod(bool ignore) external onlyOwner
    {
        ignoreAuctionPeriod = ignore;
    }

    receive() external payable {}

    // *** Pausable *** //

    // todo comments
    function pause(bool pauseTokens) external onlyOwner {
        _pause();
        if (pauseTokens) {
            iceToken.pause();
            h2oToken.pause();
            iceCube.pause();
        }
    }

    // todo comments
    function unpause(bool unpauseTokens) external onlyOwner {
        _unpause();
        if (unpauseTokens) {
            iceToken.unpause();
            h2oToken.unpause();
            iceCube.unpause();
        }
    }


    // *** Getters *** //

    /**
    @notice Getter for the current price in H2O of the ICE token according to the internal virtual pools.
    @return uint256 Price for ICE token in H2O with 18 decimals.
    */
    function getICEPrice() external view returns (uint256) {
        return _icePool.priceB();
    }

    /**
    @notice Getter for the current average price in H2O of the ICE token.
    @return uint256 Price for ICE token in H2O with 18 decimals.
    */
    function getAverageICEPrice() external view returns (uint256) {
        return dAverageICEPrice;
    }

    /**
    @notice Getter for the amount of ICE in the ICE/H2O virtual pool.
    @return uint256 Amount of ICE token with 18 decimals.
    */
    function getICEPoolICESize() external view returns (uint256) {
        return _icePool.poolSizeB();
    }

    /**
    @notice Getter for the amount of H2O in the ICE/H2O virtual pool.
    @return uint256 Amount of H2O token with 18 decimals.
    */
    function getICEPoolH2OSize() external view returns (uint256) {
        return _icePool.poolSizeA();
    }

    // *** Configurable Parameter Setters *** //

    function setMeltRate(uint256 value) external onlyOwner
    {
        meltRate = value;
    }

    // todo comment
    // todo add getter for iErrorUpdatePeriod?
    function setErrorUpdatePeriod(uint256 value) external onlyOwner
    {
        iErrorUpdatePeriod = value;
    }


    //*** Token Swap Functions ***//

    /**
    @notice Previews how much ICE results from swapping H2O to ICE using the ICE/H2O virtual pool.
    @param dH2OAmount Amount of H2O token to be swapped with 18 decimals.
    @return uint256 Amount of ICE token that will be sent to user with 18 decimals.
    */
    function previewSwapH2OForICE(uint256 dH2OAmount)
        external view returns (uint256)
    {
        return _icePool.previewSwapAB(dH2OAmount);
    }

    /**
    @notice Previews how much H2O results from swapping ICE to H2O using the ICE/H2O virtual pool.
    @param dICEAmount Amount of ICE token to be swapped with 18 decimals.
    @return uint256 Amount of H2O token that will be sent to user with 18 decimals.
    */
    function previewSwapICEForH2O(uint256 dICEAmount)
        external view returns (uint256)
    {
        return _icePool.previewSwapBA(dICEAmount);
    }

    /**
    @notice Swaps H2O for ICE using the cold virtual pool (ICE/H2O virtual pool).
    @param dH2OAmount Amount of H2O token to be swapped with 18 decimals.
    @return uint256 Amount of ICE token sent to user with 18 decimals.
    */
    function swapH2OForICE(
        uint256 dH2OAmount,
        uint256 dMinICEAmount,
        uint256 deadline
    ) external whenNotPaused returns (uint256) {
        // Update the target supply
        // Note: At beginning of function to avoid flash loan attack
        _updateTargetSupply();

        uint256 dICEAmount = _icePool.swapAB(
            _msgSender(),
            dH2OAmount,
            dMinICEAmount,
            deadline);

        emit Swap(
            msg.sender,
            address(h2oToken), dH2OAmount,
            address(iceToken), dICEAmount);

        return dICEAmount;
    }

    /**
    @notice Swaps ICE for H2O using the cold virtual pool (ICE/H2O virtual pool).
    @param dICEAmount Amount of ICE token to be swapped with 18 decimals.
    @return uint256 Amount of H2O token sent to user with 18 decimals.
    */
    function swapICEForH2O(
        uint256 dICEAmount,
        uint256 dMinH2OAmount,
        uint256 deadline
    ) external whenNotPaused returns (uint256) {
        // Note: At beginning of function to avoid flash loan attack
        _updateTargetSupply();

        uint256 dH2OAmount = _icePool.swapBA(
            _msgSender(),
            dICEAmount,
            dMinH2OAmount,
            deadline);
        
        emit Swap(
            msg.sender,
            address(iceToken), dICEAmount,
            address(h2oToken), dH2OAmount);

        return dH2OAmount;
    }

    //*** Ice Cubes ***//

    // create an icecube from ice
    function mintIceCube(
        uint256 amount,
        address recipient,
        uint256 endTime
    ) external whenNotPaused returns (uint256) {
        iceToken.burn(msg.sender, amount);
        uint256 tokenId = iceCube.mint(msg.sender, recipient, amount, block.timestamp, endTime);

        emit MintCube(msg.sender, recipient, amount, endTime, tokenId);

        return tokenId;
    }

    // external end point for redeeming cube
    function redeemIceCube(uint256 tokenId) external whenNotPaused returns (uint256) {
        require(msg.sender == iceCube.getRedeemer(tokenId), "Only the redeemer can redeem an Ice Cube.");
        uint256 dAmount = _redeemIceCube(tokenId);

        emit RedeemCube(msg.sender, tokenId, dAmount);

        return dAmount;
    }

    //end an icecube
    function _redeemIceCube(uint256 tokenId) internal returns (uint256) {
        uint256 dAmount = iceCube.getAmount(tokenId);
        iceCube.redeem(tokenId);
        iceToken.mint(iceCube.getRedeemer(tokenId), dAmount);
        return dAmount;
    }

    //*** Rewards Functions ***//

    // todo move to getters area?
    /**
    @notice Returns the rewards rate for ICE at an annual rate (e.g., annual interest rate).
    @return uint256 ICE annual rewards rate with 18 decimals.
    */
    function annualMeltRate() external view returns (uint256) {
        return meltRate * I_YEAR;
    }
    
    /**
    @notice Returns the amount of ICE rewards available for the sender.
    @return uint256 Amount of ICE rewards with 18 decimals.
    */
    function claimableH2OFromICE() external view returns (uint256) {
        return iceToken.claimableReward(msg.sender).mul(meltRate);
    }

    /**
    @notice Sends ICE rewards to msg.sender in H2O.
    @return uint256 Amount of rewards claimed with 18 decimals.
    */
    function claimRewards()
        external whenNotPaused
        returns (uint256)
    {
        uint256 dAmount = iceToken.claimReward(msg.sender).mul(meltRate);

        // Mint H2O amount.
        h2oToken.mint(msg.sender, dAmount);

        // Update the pool sizes
        uint256 dScaleRatio = dTargetH2OSupply.div(D_INITIAL_H2O_SUPPLY);
        _icePool.scalePools(dScaleRatio);

        emit ClaimRewards(msg.sender, dAmount);

        return dAmount;
    }

    // todo document
    function _getRewardsFromCube(uint256 tokenId)
        internal view whenNotPaused
        returns (uint256)
    {
        uint256 iEndTime = iceCube.getEndTime(tokenId);
        uint256 stopTime = block.timestamp.min(iEndTime);
        uint256 iTimeDelta = stopTime - iceCube.getLastRewardTime(tokenId);
        return (iceCube.getAmount(tokenId)*(iTimeDelta)).mul(meltRate);
    }

    // todo document
    function previewRewardsFromCube(uint256 tokenId)
        external view whenNotPaused
        returns (uint256)
    {
        return _getRewardsFromCube(tokenId);
    }

    /**
    @notice Sends ICE rewards to msg.sender in H2O.
    @return uint256 Amount of rewards claimed with 18 decimals.
    */
    function claimRewardsFromCube(uint256 tokenId)
        external whenNotPaused
        returns (uint256)
    {
        require(msg.sender == iceCube.ownerOf(tokenId), "Only owner can claim rewards");
        
        uint256 dAmount = _getRewardsFromCube(tokenId);

        iceCube.claimRewards(tokenId);

        // Mint H2O amount.
        h2oToken.mint(msg.sender, dAmount);

        uint256 iEndTime = iceCube.getEndTime(tokenId);
        if (block.timestamp >= iEndTime && iceCube.isRedeemed(tokenId) == false) {
            _redeemIceCube(tokenId);
        }

        // Update the pool sizes
        uint256 dScaleRatio = dTargetH2OSupply.div(D_INITIAL_H2O_SUPPLY);
        _icePool.scalePools(dScaleRatio);

        emit ClaimRewardsFromCube(msg.sender, tokenId, dAmount);

        return dAmount;
    }

    //*** Update Target Supply ***//

    /**
    @notice Updates the current (proportional) error and accumulated (integral) error and stores the values.
    */
    function _updateTargetSupply() internal {
        uint256 mIErrorUpdatePeriod = iErrorUpdatePeriod;
        uint256 mDTargetH2OSupply = dTargetH2OSupply;

        uint256 iTimeDelta = block.timestamp - iLastErrorTime;

        //Avoid running PID multiple times in a block
        if (iTimeDelta == 0) {
            return;
        }

        iTimeDelta = iTimeDelta.min(mIErrorUpdatePeriod);
        iLastErrorTime = block.timestamp;

        // Calculate the errors.
        uint256 mDLastIcePrice = _icePool.priceB();
        dLastICEPrice = mDLastIcePrice;

        uint256 mDAverageICEPrice = _timeAverage(mDLastIcePrice, iTimeDelta, dAverageICEPrice, mIErrorUpdatePeriod);
        dAverageICEPrice = mDAverageICEPrice;

        uint256 iNextUpdateTime = iLastUpdateTime + mIErrorUpdatePeriod;

        if (block.timestamp >= iNextUpdateTime) {
            int256 dBaseError;

            if (mDLastIcePrice < 1e18) {
                dBaseError = 1e18 - int256(1e18).div(int256(mDAverageICEPrice));
            } else {
                dBaseError = int256(mDAverageICEPrice) - 1e18;
            }

            int256 dScaledError = dBaseError * int256(mDTargetH2OSupply.mul(meltRate)) * iErrorScaleFactor;


            dTargetH2OSupplyChangeRate += dScaledError * int256(mIErrorUpdatePeriod);
            iLastUpdateTime = iNextUpdateTime;
        }

        int256 dTargetH2OSupplyChange = dTargetH2OSupplyChangeRate * int256(iTimeDelta);

        // prevent the target supply from going negative
        dTargetH2OSupplyChange = dTargetH2OSupplyChange.max(1e18 - int256(mDTargetH2OSupply));

        // update the target supply
        dTargetH2OSupply = uint256(int256(mDTargetH2OSupply) + dTargetH2OSupplyChange);
    }

    function _timeAverage(uint256 amount, uint256 time, uint256 prevAvg, uint256 avgPeriod) internal pure returns (uint256) {
        // TODO: this math needs to me reviewed.
        return uint256(int256(prevAvg) + (int256(amount) - int256(prevAvg)).mul(int256(1e18 * time.min(avgPeriod) / avgPeriod)));
    }

    //*** Positive Auctions -- mint H2O***//

    function initiatePositiveAuction() external payable whenNotPaused {
        uint256 mTotalSupply = h2oToken.totalSupply();
        uint256 mDTargetH2OSupply = dTargetH2OSupply;
        
        require (mTotalSupply < mDTargetH2OSupply, "Auction not available.");
        require (isPositiveAuctionActive == false && isNegativeAuctionActive == false,
            "There is already an active auction.");

        isPositiveAuctionActive = true;
        auctionH2OAmount = mDTargetH2OSupply - mTotalSupply;
        leadingBidder = msg.sender;
        leadingBid = msg.value;
        iLastAuctionTime = block.timestamp;

        emit InitiateAuction(msg.sender, true, msg.value, mDTargetH2OSupply - mTotalSupply, block.timestamp);
    }

    function makePositiveAuctionBid() external payable whenNotPaused {
        //Load before require statements for gas optimization
        address previousLeadingBidder = leadingBidder;
        uint256 previousLeadingBid = leadingBid;

        require (isPositiveAuctionActive == true, "There is no active auction.");
        require (msg.value > previousLeadingBid, "New bid must be more than previous bid.");

        leadingBidder = msg.sender;
        leadingBid = msg.value;

        emit AuctionBid(msg.sender, true, msg.value);

        if (block.timestamp > (iLastAuctionTime + I_DEFAULT_AUCTION_PERIOD)) {
            _closePositiveAuction();
        }

        sendETH(previousLeadingBidder, previousLeadingBid, '');
    }

    function terminatePositiveAuction() external whenNotPaused {
        require(isPositiveAuctionActive == true, "There is no active auction.");
        require(ignoreAuctionPeriod || block.timestamp > (iLastAuctionTime + I_DEFAULT_AUCTION_PERIOD + 1 days),
            "There is still time remaining in the Auction.");
        _closePositiveAuction();
    }

    function _closePositiveAuction() internal {
        isPositiveAuctionActive = false;
        h2oToken.mint(leadingBidder, auctionH2OAmount);
        
        emit CloseAuction(leadingBidder, true, leadingBid, auctionH2OAmount);
    }

    //*** Negative Auctions -- burn H2O***//

    function initiateNegativeAuction(uint256 _ETHAmount) external whenNotPaused {
        uint256 mTotalSupply = h2oToken.totalSupply();
        uint256 mDTargetH2OSupply = dTargetH2OSupply;

        require (mTotalSupply > mDTargetH2OSupply, "Auction not available.");
        require (isPositiveAuctionActive == false && isNegativeAuctionActive == false,
            "There is already an active auction.");
        require(address(this).balance >= _ETHAmount, "There is not enough ETH available.");

        uint256 mAuctionH2OAmount = mTotalSupply - mDTargetH2OSupply; //Save an SLOAD for the burn
        auctionH2OAmount = mAuctionH2OAmount;

        // bidder has to put up a fee that disincentivizes huge starting bids
        //uint256 auctionSafetyFee = _ETHAmount.mul(D_AUCTION_SAFETY_FEE_RATIO);
        //transferFrom(msg.sender, address(this), auctionSafetyFee);

        // bidder has to put up the amount they are going to burn if they win
        h2oToken.burn(msg.sender, mAuctionH2OAmount);

        isNegativeAuctionActive = true;
        leadingBidder = msg.sender;
        leadingBid = _ETHAmount;
        iLastAuctionTime = block.timestamp;

        emit InitiateAuction(msg.sender, false, _ETHAmount, mAuctionH2OAmount, block.timestamp);
    }

    function makeNegativeAuctionBid(uint256 _ETHAmount) external whenNotPaused {
        require (isNegativeAuctionActive == true, "There is no active auction.");
        require (_ETHAmount < leadingBid, "New bid must be less than previous bid.");

        uint256 mAuctionH2OAmount = auctionH2OAmount; //Save an SLOAD

        //paySafetyFee(_ETHAmount);
        h2oToken.burn(msg.sender, mAuctionH2OAmount);
        h2oToken.mint(leadingBidder, mAuctionH2OAmount);
        leadingBidder = msg.sender;
        leadingBid = _ETHAmount;

        emit AuctionBid(msg.sender, false, _ETHAmount);

        if (block.timestamp > (iLastAuctionTime + I_DEFAULT_AUCTION_PERIOD)) {
            _closeNegativeAuction();
        }
    }

    // the one day waiting period makes it a bit harder for the original bid to win
    function terminateNegativeAuction() external whenNotPaused {
        require(isNegativeAuctionActive == true, "There is no active auction.");
        require(ignoreAuctionPeriod || block.timestamp > (iLastAuctionTime + I_DEFAULT_AUCTION_PERIOD + 1 days),
            "There is still time remaining in the Auction");
        _closeNegativeAuction();
    }

    /*
    function paySafetyFee(uint256 _ETHAmount) internal {
        uint256 auctionSafetyFee = _ETHAmount.mul(D_AUCTION_SAFETY_FEE_RATIO);
        //transferFrom(msg.sender, address(this), auctionSafetyFee);

        uint256 bidRatio = _ETHAmount.div(leadingBid);
        if (bidRatio > D_AUCTION_SAFETY_BID_RATIO) {
            uint256 previousSafetyFee = leadingBid.mul(D_AUCTION_SAFETY_FEE_RATIO);
            //payable(address(this)).transfer(leadingBidder, previousSafetyFee);
        }
    }
    */

    function _closeNegativeAuction() internal {
        isNegativeAuctionActive = false;

        sendETH(leadingBidder, leadingBid, '');

        emit CloseAuction(leadingBidder, false, leadingBid, auctionH2OAmount);
    }

    function sendETH(
        address to,
        uint256 dETHAmount,
        bytes memory data
    ) internal {
        // Fails if contract balance is less than dETHAmount
        (bool sent, ) = to.call{ value: dETHAmount }(data);
       require(sent, "Failed to send ETH");
    }

    //***Events***//

    event Swap(address indexed account,
        address tokenFrom, uint256 amountFrom,
        address tokenTo, uint256 amountTo);

    event ClaimRewards(address indexed account,
        uint256 h2oAmount);

    event MintCube(address indexed senderAccount,
    address indexed recipient, uint256 amount,
    uint256 endTime, uint256 tokenId);

    event RedeemCube(address indexed redeemer, uint256 tokenId,
    uint256 amount);

    event ClaimRewardsFromCube(address indexed account,
        uint256 tokenId,
        uint256 h2oAmount);

    event InitiateAuction(address indexed leadingBidder,
        bool positiveAuction, uint256 leadingBid,
        uint256 auctionAmount, uint256 auctionTime);
        
    event AuctionBid(address indexed leadingBidder,
    bool positiveAuction, uint256 leadingBid);

    event CloseAuction(address indexed leadingBidder,
    bool positiveAuction, uint256 leadingBid,
    uint256 auctionAmount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./abstract/VirtualPool.sol";

import "./tokens/H2OToken.sol";
import "./tokens/IceToken.sol";

contract H2OIceVirtualPool is VirtualPool
{
    H2OToken public h2o;
    IceToken public ice;

    function initialize(
        H2OToken tokenA,
        IceToken tokenB,
        uint256 dPoolSizeA,
        uint256 dPoolSizeB
    )
        initializer public
    {
        __VirtualPool_init(dPoolSizeA, dPoolSizeB);
        h2o = tokenA;
        ice = tokenB;
    }

    function _takeA(address addr, uint256 amount) public payable override
    {
        h2o.burn(addr, amount);
    }
    
    function _takeB(address addr, uint256 amount) public payable override
    {
        ice.burn(addr, amount);
    }
    
    function _giveA(address addr, uint256 amount) public payable override
    {
        h2o.mint(addr, amount);
    }
    
    function _giveB(address addr, uint256 amount) public payable override
    {
        ice.mint(addr, amount);
    } 


}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/** @title Fixed math library to deal with excess decimals.
    @notice Library includes signed and unsigned math to add or remove decimals as need to get the appropriate result.
*/
// TODO: We should make the 18 (or 1e18) a constant. The decimals set in the token contract should be based on this constant

/// Unsigned Fixed Point.
library UFixedPoint {
    /**
    @notice Multiplication of two 18 decimal numbers with 18 excess decimals removed from product.
    @param dA First factor to be multiplied.
    @param dB Second factor to be multiplied.
    @return uint256 Product.
    */
    function mul(uint256 dA, uint256 dB) internal pure returns (uint256) {
        return dA * dB / 1e18;
    }

    /**
    @notice Division of two 18 decimal numbers with 18 decimals add to quotient.
    @param dA Dividend.
    @param dB Divisor.
    @return uint256 Quotient.
    */
    function div(uint256 dA, uint256 dB) internal pure returns (uint256) {
        return 1e18 * dA / dB;
    }

    /**
    @notice Converts a number with 0 decimals to one with 18 decimals.
    @param iA Number to be converted.
    @return uint256 Result.
    */
    function toDecimal(uint256 iA) internal pure returns (uint256) {
        return iA * 1e18;
    }

    /**
    @notice Converts a number with 18 decimals to one with 0 decimals.
    @param dA Number to be converted.
    @return uint256 Result.
    */
    function toInteger(uint256 dA) internal pure returns (uint256) {
        return dA / 1e18;
    }

    /**
    @notice Returns the larger of two numbers.
    @param dA First number to be compared.
    @param dB Second number to be compared.
    @return uint256 Result.
    */
    function max(uint256 dA, uint256 dB) internal pure returns (uint256) {
       if (dA > dB) {
        return dA;
       }
       else {
        return dB;
       }
    }

    /**
    @notice Returns the smaller of two numbers.
    @param dA First number to be compared.
    @param dB Second number to be compared.
    @return uint256 Result.
    */
    function min(uint256 dA, uint256 dB) internal pure returns (uint256) {
       if (dA > dB) {
        return dB;
       }
       else {
        return dA;
       }
    }
}

/// Signed Fixed Point.
library SFixedPoint {
    /**
    @notice Multiplication of two 18 decimal numbers with 18 excess decimals removed from product.
    @param dA First factor to be multiplied.
    @param dB Second factor to be multiplied.
    @return int256 Product.
    */
    function mul(int256 dA, int256 dB) internal pure returns (int256) {
        return dA * dB / 1e18;
    }

    /**
    @notice Division of two 18 decimal numbers with 18 decimals add to quotient.
    @param dA Dividend.
    @param dB Divisor.
    @return int256 Quotient.
    */
    function div(int256 dA, int256 dB) internal pure returns (int256) {
        return 1e18 * dA / dB;
    }

    /**
    @notice Converts a number with 0 decimals to one with 18 decimals.
    @param iA Number to be converted.
    @return int256 Result.
    */
    function toDecimal(int256 iA) internal pure returns (int256) {
        return iA * 1e18;
    }

    /**
    @notice Converts a number with 18 decimals to one with 0 decimals.
    @param dA Number to be converted.
    @return int256 Result.
    */
    function toInteger(int256 dA) internal pure returns (int256) {
        return dA / 1e18;
    }

    /**
    @notice Returns the larger of two numbers.
    @param dA First number to be compared.
    @param dB Second number to be compared.
    @return int256 Result.
    */
    function max(int256 dA, int256 dB) internal pure returns (int256) {
       if (dA > dB) {
        return dA;
       }
       else {
        return dB;
       }
    }

    /**
    @notice Returns the smaller of two numbers.
    @param dA First number to be compared.
    @param dB Second number to be compared.
    @return int256 Result.
    */
    function min(int256 dA, int256 dB) internal pure returns (int256) {
       if (dA > dB) {
        return dB;
       }
       else {
        return dA;
       }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../Constants.sol";
import "../abstract/ERC20MintableBurnable.sol";

/// @title H2O Token Contract (Stable Token).
/// @notice Extends the {ERC20MintableBurnable} contract.
contract H2OToken is ERC20MintableBurnable
{

    /// @notice Initializer
    /// @param admins Addresses that will be granted the DEFAULT_ADMIN_ROLE.
    /// @param holder Address that will hold the initial supply of this token.
    function initialize(address[] memory admins, address holder) 
        initializer public
    {
        __ERC20MintableBurnable_init("H2O", "H2O", admins);
        _mint(holder, D_INITIAL_H2O_SUPPLY);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";
import "../abstract/ERC721Base.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Ice Cube Contract (NFTs for removing H2O from the system).

contract IceCube is ERC721Base
{
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    /// @dev AccessControl role that gives access to createIceCube()
    bytes32 public constant MINTER_REDEEMER_ROLE = keccak256("MINTER_REDEEMER_ROLE");

    // Keeps track of the number of tokens minted so far.
    using Counters for Counters.Counter;
    Counters.Counter private _idCounter;

    struct Params {
        bool redeemed;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 lastRewardTime;
        address redeemer;
    }

    mapping(uint256 => Params) private params;

    mapping (address => uint256[]) private _creatorBalances;

    modifier onlyExisting(uint256 id) {
        require(_exists(id), "Invalid IceCube ID.");
        _;
    }

    modifier onlyNotRedeemed(uint256 id) {
        require(!params[id].redeemed, "IceCube already redeemed.");
        _;
    }

    /// @notice Initializer
    /// @param admins Addresses that will be granted the DEFAULT_ADMIN_ROLE.
    function initialize(address[] memory admins) 
        initializer public
    {
        __ERC721Base_init("Ice Cube", "ICECUBE", admins);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId)
        external view
        returns (bool)
    {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function isRedeemed(uint256 id)
        public view onlyExisting(id)
        returns (bool)
    {
        return params[id].redeemed;
    }

    function getRedeemer(uint256 id)
        public view onlyExisting(id)
        returns (address)
    {
        return params[id].redeemer;
    }

    function getAmount(uint256 id)
        public view onlyExisting(id)
        returns (uint256)
    {
        return params[id].amount;
    }

    function getStartTime(uint256 id)
        public view onlyExisting(id)
        returns (uint256)
    {
        return params[id].startTime;
    }

    function getEndTime(uint256 id)
        public view onlyExisting(id)
        returns (uint256)
    {
        return params[id].endTime;
    }

    function getLastRewardTime(uint256 id)
        public view onlyExisting(id)
        returns (uint256)
    {
        return params[id].lastRewardTime;
    }

    function getCreatorBalanceOf(address redeemer)
        public view
        returns (uint256)
    {
        return _creatorBalances[redeemer].length;
    }

    function getCreatorCubeIdByIndex(address redeemer, uint256 index)
        public view
        returns (uint256)
    {
        require(index < _creatorBalances[redeemer].length, "Index out of range");
        return _creatorBalances[redeemer][index];
    }

    /// @notice Mints a new ice cube NFT for recipient.
    /// @param recipient The address to mint the NFT to.
    /// @return id An identifier for the NFT.
    function mint(
        address creator,
        address recipient,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    )
        external whenNotPaused onlyRole(MINTER_REDEEMER_ROLE)
        returns (uint256)
    {
        // Mint starting with Id 1.
        _idCounter.increment();
        uint256 id = _idCounter.current();
        _safeMint(recipient, id);

        // Set the parameters for the new cube.
        params[id] = Params(
            false, amount, startTime, endTime, startTime, creator);

        _creatorBalances[creator].push(id);

        return id;
    }

    // todo comment
    function claimRewards(uint256 id)
        external whenNotPaused
        onlyExisting(id) onlyRole(MINTER_REDEEMER_ROLE)
    {
        params[id].lastRewardTime = block.timestamp.min(params[id].endTime);
    }

    function redeem(uint256 id)
        external
        whenNotPaused
        onlyExisting(id) onlyNotRedeemed(id) onlyRole(MINTER_REDEEMER_ROLE)
    {
        require(block.timestamp > params[id].endTime, "Cannot redeem an active Ice Cube.");
        params[id].redeemed = true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";
import "../Constants.sol";
import "../abstract/ERC20Reward.sol";

/// @title ICE Token Contract (Token for measuring stability).
/// Extends the {ERC20Reward} contract
contract IceToken is ERC20Reward {
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    // Transfer tax
    uint256 public D_ICE_TRANSFER_TAX;
    bool public D_IS_ICE_TRANSFERABLE;

    /// @notice Initializer
    /// @param admins Addresses that will be granted the DEFAULT_ADMIN_ROLE.
    /// @param holder Address that will hold the initial supply of this token.
    function initialize(address[] memory admins, address holder) 
        initializer public
    {
        __ERC20Reward_init("ICE", "ICE", admins, 0);

        D_ICE_TRANSFER_TAX = D_DEFAULT_ICE_TRANSFER_TAX;
        D_IS_ICE_TRANSFERABLE = D_DEFAULT_IS_ICE_TRANSFERABLE;
        
        _mint(holder, D_INITIAL_ICE_SUPPLY);
    }

    //todo comment
    function setTransferTax(uint256 dTransferTax_)
        public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        D_ICE_TRANSFER_TAX = dTransferTax_;
    }

    //todo comment
    function setTransferable(bool isTransferable_)
        public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        D_IS_ICE_TRANSFERABLE = isTransferable_;
    }

    // todo comment
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
        require(D_IS_ICE_TRANSFERABLE || from == address(0) || to == address(0), "IceToken is non transferable.");
    }

    /// @notice Applies a transfer tax to ICE to prevent use of ICE as the stable token which could disrupt its measurement function.
    /// @param from The `from` account in a transfer/burn and 0 when minting.
    /// @param to The `to` account in a transfer/minting or 0 when burning.
    /// @param amount The token amount being transferred, minted or burned.
    function _afterTokenTransfer(address from, address to, uint256 amount
    )
        internal override
    {
        // Burn the tax on a transfer (currently from reciever balance)
        if (from != address(0) && to != address(0) && D_ICE_TRANSFER_TAX > 0) {
            uint256 burnAmount = D_ICE_TRANSFER_TAX.mul(amount);
            _burn(to, burnAmount);
        }
    }

}