// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/cryptography/EIP712Upgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 *
 * @custom:storage-size 51
 */
abstract contract ERC20CappedUpgradeable is Initializable, ERC20Upgradeable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    function __ERC20Capped_init(uint256 cap_) internal onlyInitializing {
        __ERC20Capped_init_unchained(cap_);
    }

    function __ERC20Capped_init_unchained(uint256 cap_) internal onlyInitializing {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20Upgradeable.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
library CountersUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = _ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./interfaces/IGrainLGE.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error GrainLGE__WrongInput();
error GrainLGE__UnknownToken();
error GrainLGE__Unauthorized();
error GrainLGE__NotLive();
error GrainLGE__Completed();
error GrainLGE__NotCompleted();
error GrainLGE__DoesNotOwn();
error GrainLGE__BonusAlreadyClaimed();
error GrainLGE__NotWhitelisted();
error GrainLGE__GrainNotSet();
error GrainLGE__Slippage();

/// Grain Liquidity Generation Event contract, tailored for chains with a dominant uniswapV2-style DEX.
contract GrainLGEMetis is IGrainLGE, Ownable {
    using SafeERC20 for IERC20;

    /// Represent the max number of releasePeriod a vest can support
    /// If the longest vesting period is 8 years, and the tokens are
    /// released every 3 months, there should be 32 periods
    uint256 public constant MAX_KINK_RELEASES = 8; // 2 years
    uint256 public constant MAX_RELEASES = 20; // 5 years
    uint256 public constant PERIOD = 91 days; // 3 months
    uint256 public constant maxKinkDiscount = 4e26; // 40% premium for users with kink vesting
    uint256 public constant maxDiscount = 6e26; // 60% premium for users with maximum vesting
    uint256 public constant PERCENT_DIVISOR = 1e27;

    IERC20 public immutable grain;
    address public immutable unirouter;
    address public immutable treasury;
    mapping(address => address[]) public pathToUsdc;
    IERC20 public immutable usdc;
    uint256 public immutable lgeStart;
    uint256 public immutable lgeEnd; // Probably 2 weeks after
    bool public gracePeriodOver;
    address[] public supportedTokens;

    /// Information related to user buying in the LGE
    /// usdcValue - How much user bought with in USDC
    /// numberOfReleases - How long a user is vesting
    /// weight - Numerical value representing the user's contribution
    /// totalClaimed - how much a user has already claimed
    /// nft - nft used for a bouns
    /// nftId - id of nft
    /// bonusWeight - added weight thanks to nft
    struct UserShare {
        uint256 usdcValue;
        uint256 numberOfReleases;
        uint256 weight;
        uint256 totalClaimed;
        address nft;
        uint256 nftId;
        uint256 bonusWeight;
    }
    mapping (address => UserShare) public userShares;

    /// @notice
    /// {whitelistedNfts} - NFTs that users can get a bonus of X% with. Users should only be able to get one of these
    /// {bonusReceiver} - NFT + ID returns user getting a bonus.
    mapping (address => uint256) public whitelistedBonuses;
    mapping (address => mapping(uint => address)) public bonusReceiver;

    /// How much has been raised in USDC
    uint256 public totalRaisedUsdc;
    uint256 public totalWeight;
    uint256 public totalGrain;

    constructor(address _grain, address _usdc, address _unirouter, address _treasury, uint256 _lgeStart) {
        grain = IERC20(_grain);
        usdc = IERC20(_usdc);
        unirouter = _unirouter;
        treasury = _treasury;
        lgeStart = _lgeStart;
        lgeEnd = lgeStart + 2 weeks;
        supportedTokens.push(_usdc);
    }

    ///----- * STOREFRONT * -----///

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    /// Set numberOfReleases to 0 to chose the no-vesting option
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) public returns (uint256 usdcValue, uint256 vestingPremium) {
        /// Check for errors
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (token != address(usdc) && pathToUsdc[token].length < 2) {
            revert GrainLGE__UnknownToken();
        }
        if (numberOfReleases > MAX_RELEASES) {
            revert GrainLGE__WrongInput();
        }

        /// Fetch tokens, turn into USDC if necessary
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (token == address(usdc)) {
            usdcValue = amount;
        } else {
            usdcValue = _swapTokenToUsdc(token, amount);
            if (usdcValue < minUsdcAmountOut) revert GrainLGE__Slippage();
        }

        /// If user has previously bought, we need to recalculate the weight, and remove it from total
        if (userShares[onBehalfOf].usdcValue != 0) {
            totalWeight -= _userTotalWeight(onBehalfOf);
        }

        if (numberOfReleases == 0) {
            vestingPremium = 0;
        } else if (numberOfReleases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% discount
            vestingPremium = maxKinkDiscount * numberOfReleases / MAX_KINK_RELEASES;
        } else if (numberOfReleases <= MAX_RELEASES) {
            // range from 40% to 60% discount
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (numberOfReleases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        /// Store values needed to calculate the user's share after the LGE's end
        userShares[onBehalfOf].usdcValue += usdcValue;
        userShares[onBehalfOf].numberOfReleases = numberOfReleases;

        userShares[onBehalfOf].weight = vestingPremium == 0 ? userShares[onBehalfOf].usdcValue : (userShares[onBehalfOf].usdcValue) * (PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium));
        if (userShares[onBehalfOf].nft != address(0)) {
            userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[userShares[onBehalfOf].nft] / PERCENT_DIVISOR;
        }

        totalRaisedUsdc += usdcValue;
        totalWeight += _userTotalWeight(onBehalfOf);

        /// Transfer usdc to treasury
        /// Sending the whole balance should there be leftovers
        usdc.safeTransfer(treasury, usdc.balanceOf(address(this)));
    }

    /// @notice adds a bonus to the user final weight in the LGE
    /// @dev setting nft to address(0) should remove the bonus
    function addNftBonus(address nft, uint256 nftId, address onBehalfOf) public {
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (whitelistedBonuses[nft] == 0) {
            revert GrainLGE__NotWhitelisted();
        }
        if (IERC721(nft).ownerOf(nftId) != onBehalfOf) {
            revert GrainLGE__DoesNotOwn();
        }
        if (bonusReceiver[nft][nftId] != address(0)) {
            /// Someone has already claimed this nft
            revert GrainLGE__BonusAlreadyClaimed();
        }

        /// Clears onBehalfOf's previous NFT ownership mapping (if any), so others can use previous NFT again
        bonusReceiver[userShares[onBehalfOf].nft][userShares[onBehalfOf].nftId] = address(0);

        totalWeight -= _userTotalWeight(onBehalfOf);

        userShares[onBehalfOf].nft = nft;
        userShares[onBehalfOf].nftId = nftId;
        userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[nft] / PERCENT_DIVISOR;
        bonusReceiver[nft][nftId] = onBehalfOf;

        totalWeight += _userTotalWeight(onBehalfOf);
    }

    /// @dev combines the nft-less buy function and the function to add an nft
    function buy(
        address token,
        uint256 amount,
        uint256 minUsdcAmountOut,
        uint256 numberOfReleases,
        address onBehalfOf,
        address nft,
        uint256 nftId
    ) external returns (uint256 usdcValue, uint256 vestingPremium) {
        if (token != address(0)) {
            (usdcValue, vestingPremium) = buy(token, amount, minUsdcAmountOut, numberOfReleases, onBehalfOf);
        }
        if (nft != address(0)) {
            addNftBonus(nft, nftId, onBehalfOf);
        }
    }

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 claimable) {
        if (gracePeriodOver == false) {
            revert GrainLGE__GrainNotSet();
        }
        claimable = pending(msg.sender);
        if (claimable != 0) {
            userShares[msg.sender].totalClaimed += claimable;
            grain.safeTransfer(msg.sender, claimable);
        }
    }

    ///----- * PUBLIC GARDEN * -----///

    /// @notice Get how much GRAIN a user can claim
    // Will handle differently a user that is vested and one who is not
    function pending(address user) public view returns (uint256 claimable) {
        /// Get how many periods user is claiming
        if (userShares[user].numberOfReleases == 0) {
            // No vest
            claimable = totalOwed(user) - userShares[user].totalClaimed;
        } else {
            // Vest
            uint256 periodsSinceEnd = (block.timestamp - lgeEnd) / PERIOD;
            if(periodsSinceEnd > userShares[user].numberOfReleases){
                periodsSinceEnd = userShares[user].numberOfReleases;
            }
            claimable = (totalOwed(user) * periodsSinceEnd / userShares[user].numberOfReleases) - userShares[user].totalClaimed;
        }
    }

    /// @notice Get how much GRAIN a user is owed by the end of his vesting
    function totalOwed(address user) public view returns (uint256 userTotal) {
        uint256 shareOfLge = _userTotalWeight(user) * PERCENT_DIVISOR / totalWeight;
        userTotal = (shareOfLge * totalGrain) / PERCENT_DIVISOR;
    }

    /// @notice Get how much GRAIN a user has yet to receive
    function userGrainLeft(address user) public view returns (uint256 grainLeft) {
        grainLeft = totalOwed(user) - userShares[user].totalClaimed;
    }

    /// @notice Check if nft collection is whitelisted
    function isNftWhitelisted(address nft) public view returns (bool isWhitelisted) {
        isWhitelisted = whitelistedBonuses[nft] != 0;
    }

    /// @notice Get list of suported tokens to buy with
    function getSupportedTokens() public view returns (address[] memory) {
        return supportedTokens;
    }

    function getSupportedTokensLength() public view returns (uint256 length) {
        length = supportedTokens.length;
    }

    ///----- * PRIVATE GREENHOUSE * -----///

    /// Swap tokens using a uniV2 protocol and router
    function _swapTokenToUsdc(address token, uint256 amount) internal returns (uint256 usdcValue) {
        if (amount == 0) {
            return 0;
        }

        uint256 usdcBalBefore = usdc.balanceOf(address(this));

        IERC20(token).safeIncreaseAllowance(unirouter, amount);
        IUniswapV2Router02(unirouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            pathToUsdc[token],
            address(this),
            block.timestamp
        );
        usdcValue = usdc.balanceOf(address(this)) - usdcBalBefore;
    }

    /// Returns user base weight + his bonus thanks to using an nft
    function _userTotalWeight(address user) internal view returns (uint256 userTotalWeight) {
        userTotalWeight = userShares[user].weight + userShares[user].bonusWeight;
    }

    ///----- * MINISTRY OF GRAINS * -----///

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external onlyOwner {
        if (block.timestamp <= lgeEnd) {
            revert GrainLGE__NotCompleted();
        }

        /// Fetch the tokens to guarantee the amount received
        grain.safeTransferFrom(msg.sender, address(this), grainAmount);
        totalGrain += grainAmount;

        gracePeriodOver = true;
    }

    /// @notice Add a token to the lsit of tokens that can be swapped, or update one's path
    function setPathToUsdc(address[] memory _path) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (_path[_path.length-1] != address(usdc)) {
            revert GrainLGE__WrongInput();
        }
        pathToUsdc[_path[0]] = _path;

        bool containsToken;
        for (uint256 i; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _path[0]) {
                containsToken = true;
            }
        }

        if (containsToken == false) {
            supportedTokens.push(_path[0]);
        }
    }

    /// @notice Set bonus to a nft collection
    /// @dev There is no limit to the bonus, please use responsibly (10000 = 100% and is like a x2 multiplier)
    function setWhitelistedBonus(address nft, uint256 pctBonus) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (pctBonus > 1e26) {
            revert GrainLGE__WrongInput();
        }
        whitelistedBonuses[nft] = pctBonus;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./interfaces/IGrainLGE.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error GrainLGE__WrongInput();
error GrainLGE__UnknownToken();
error GrainLGE__Unauthorized();
error GrainLGE__NotLive();
error GrainLGE__Completed();
error GrainLGE__NotCompleted();
error GrainLGE__DoesNotOwn();
error GrainLGE__BonusAlreadyClaimed();
error GrainLGE__NotWhitelisted();
error GrainLGE__GrainNotSet();
error GrainLGE__Slippage();

/// Grain Liquidity Generation Event contract, tailored for chains with a dominant uniswapV2-style DEX.
contract GrainLGEUniV2 is IGrainLGE, Ownable {
    using SafeERC20 for IERC20;

    /// Represent the max number of releasePeriod a vest can support
    /// If the longest vesting period is 8 years, and the tokens are
    /// released every 3 months, there should be 32 periods
    uint256 public constant MAX_KINK_RELEASES = 8; // 2 years
    uint256 public constant MAX_RELEASES = 20; // 5 years
    uint256 public constant PERIOD = 91 days; // 3 months
    uint256 public constant maxKinkDiscount = 4e26; // 40% premium for users with kink vesting
    uint256 public constant maxDiscount = 6e26; // 60% premium for users with maximum vesting
    uint256 public constant PERCENT_DIVISOR = 1e27;

    IERC20 public immutable grain;
    address public immutable unirouter;
    address public immutable treasury;
    mapping(address => address[]) public pathToUsdc;
    IERC20 public immutable usdc;
    uint256 public immutable lgeStart;
    uint256 public immutable lgeEnd; // Probably 2 weeks after
    bool public gracePeriodOver;
    address[] public supportedTokens;
    address public nativeTokenGateway;

    /// Information related to user buying in the LGE
    /// usdcValue - How much user bought with in USDC
    /// numberOfReleases - How long a user is vesting
    /// weight - Numerical value representing the user's contribution
    /// totalClaimed - how much a user has already claimed
    /// nft - nft used for a bouns
    /// nftId - id of nft
    /// bonusWeight - added weight thanks to nft
    struct UserShare {
        uint256 usdcValue;
        uint256 numberOfReleases;
        uint256 weight;
        uint256 totalClaimed;
        address nft;
        uint256 nftId;
        uint256 bonusWeight;
    }
    mapping (address => UserShare) public userShares;

    /// @notice
    /// {whitelistedNfts} - NFTs that users can get a bonus of X% with. Users should only be able to get one of these
    /// {bonusReceiver} - NFT + ID returns user getting a bonus.
    mapping (address => uint256) public whitelistedBonuses;
    mapping (address => mapping(uint => address)) public bonusReceiver;

    /// How much has been raised in USDC
    uint256 public totalRaisedUsdc;
    uint256 public totalWeight;
    uint256 public totalGrain;

    constructor(address _grain, address _usdc, address _unirouter, address _treasury, uint256 _lgeStart) {
        grain = IERC20(_grain);
        usdc = IERC20(_usdc);
        unirouter = _unirouter;
        treasury = _treasury;
        lgeStart = _lgeStart;
        lgeEnd = lgeStart + 2 weeks;
        supportedTokens.push(_usdc);
    }

    ///----- * STOREFRONT * -----///

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    /// Set numberOfReleases to 0 to chose the no-vesting option
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) public returns (uint256 usdcValue, uint256 vestingPremium) {
        /// Check for errors
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender && msg.sender != nativeTokenGateway) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (token != address(usdc) && pathToUsdc[token].length < 2) {
            revert GrainLGE__UnknownToken();
        }
        if (numberOfReleases > MAX_RELEASES) {
            revert GrainLGE__WrongInput();
        }

        /// Fetch tokens, turn into USDC if necessary
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (token == address(usdc)) {
            usdcValue = amount;
        } else {
            usdcValue = _swapTokenToUsdc(token, amount);
            if (usdcValue < minUsdcAmountOut) revert GrainLGE__Slippage();
        }

        /// If user has previously bought, we need to recalculate the weight, and remove it from total
        if (userShares[onBehalfOf].usdcValue != 0) {
            totalWeight -= _userTotalWeight(onBehalfOf);
        }

        if (numberOfReleases == 0) {
            vestingPremium = 0;
        } else if (numberOfReleases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% discount
            vestingPremium = maxKinkDiscount * numberOfReleases / MAX_KINK_RELEASES;
        } else if (numberOfReleases <= MAX_RELEASES) {
            // range from 40% to 60% discount
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (numberOfReleases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        /// Store values needed to calculate the user's share after the LGE's end
        userShares[onBehalfOf].usdcValue += usdcValue;
        userShares[onBehalfOf].numberOfReleases = numberOfReleases;

        userShares[onBehalfOf].weight = vestingPremium == 0 ? userShares[onBehalfOf].usdcValue : (userShares[onBehalfOf].usdcValue) * (PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium));
        if (userShares[onBehalfOf].nft != address(0)) {
            userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[userShares[onBehalfOf].nft] / PERCENT_DIVISOR;
        }

        totalRaisedUsdc += usdcValue;
        totalWeight += _userTotalWeight(onBehalfOf);

        /// Transfer usdc to treasury
        /// Sending the whole balance should there be leftovers
        usdc.safeTransfer(treasury, usdc.balanceOf(address(this)));
    }

    /// @notice adds a bonus to the user final weight in the LGE
    /// @dev setting nft to address(0) should remove the bonus
    function addNftBonus(address nft, uint256 nftId, address onBehalfOf) public {
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender && msg.sender != nativeTokenGateway) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (whitelistedBonuses[nft] == 0) {
            revert GrainLGE__NotWhitelisted();
        }
        if (IERC721(nft).ownerOf(nftId) != onBehalfOf) {
            revert GrainLGE__DoesNotOwn();
        }
        if (bonusReceiver[nft][nftId] != address(0)) {
            /// Someone has already claimed this nft
            revert GrainLGE__BonusAlreadyClaimed();
        }

        /// Clears onBehalfOf's previous NFT ownership mapping (if any), so others can use previous NFT again
        bonusReceiver[userShares[onBehalfOf].nft][userShares[onBehalfOf].nftId] = address(0);

        totalWeight -= _userTotalWeight(onBehalfOf);

        userShares[onBehalfOf].nft = nft;
        userShares[onBehalfOf].nftId = nftId;
        userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[nft] / PERCENT_DIVISOR;
        bonusReceiver[nft][nftId] = onBehalfOf;

        totalWeight += _userTotalWeight(onBehalfOf);
    }

    /// @dev combines the nft-less buy function and the function to add an nft
    function buy(
        address token,
        uint256 amount,
        uint256 minUsdcAmountOut,
        uint256 numberOfReleases,
        address onBehalfOf,
        address nft,
        uint256 nftId
    ) external returns (uint256 usdcValue, uint256 vestingPremium) {
        if (token != address(0)) {
            (usdcValue, vestingPremium) = buy(token, amount, minUsdcAmountOut, numberOfReleases, onBehalfOf);
        }
        if (nft != address(0)) {
            /// The weth gateway cannot act as a passthrough for nfts
            addNftBonus(nft, nftId, onBehalfOf);
        }
    }

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 claimable) {
        if (gracePeriodOver == false) {
            revert GrainLGE__GrainNotSet();
        }
        claimable = pending(msg.sender);
        if (claimable != 0) {
            userShares[msg.sender].totalClaimed += claimable;
            grain.safeTransfer(msg.sender, claimable);
        }
    }

    ///----- * PUBLIC GARDEN * -----///

    /// @notice Get how much GRAIN a user can claim
    // Will handle differently a user that is vested and one who is not
    function pending(address user) public view returns (uint256 claimable) {
        /// Get how many periods user is claiming
        if (userShares[user].numberOfReleases == 0) {
            // No vest
            claimable = totalOwed(user) - userShares[user].totalClaimed;
        } else {
            // Vest
            uint256 periodsSinceEnd = (block.timestamp - lgeEnd) / PERIOD;
            if(periodsSinceEnd > userShares[user].numberOfReleases){
                periodsSinceEnd = userShares[user].numberOfReleases;
            }
            claimable = (totalOwed(user) * periodsSinceEnd / userShares[user].numberOfReleases) - userShares[user].totalClaimed;
        }
    }

    /// @notice Get how much GRAIN a user is owed by the end of his vesting
    function totalOwed(address user) public view returns (uint256 userTotal) {
        uint256 shareOfLge = _userTotalWeight(user) * PERCENT_DIVISOR / totalWeight;
        userTotal = (shareOfLge * totalGrain) / PERCENT_DIVISOR;
    }

    /// @notice Get how much GRAIN a user has yet to receive
    function userGrainLeft(address user) public view returns (uint256 grainLeft) {
        grainLeft = totalOwed(user) - userShares[user].totalClaimed;
    }

    /// @notice Check if nft collection is whitelisted
    function isNftWhitelisted(address nft) public view returns (bool isWhitelisted) {
        isWhitelisted = whitelistedBonuses[nft] != 0;
    }

    /// @notice Get list of suported tokens to buy with
    function getSupportedTokens() public view returns (address[] memory) {
        return supportedTokens;
    }

    function getSupportedTokensLength() public view returns (uint256 length) {
        length = supportedTokens.length;
    }

    ///----- * PRIVATE GREENHOUSE * -----///

    /// Swap tokens using a uniV2 protocol and router
    function _swapTokenToUsdc(address token, uint256 amount) internal returns (uint256 usdcValue) {
        if (amount == 0) {
            return 0;
        }

        uint256 usdcBalBefore = usdc.balanceOf(address(this));

        IERC20(token).safeIncreaseAllowance(unirouter, amount);
        IUniswapV2Router02(unirouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            pathToUsdc[token],
            address(this),
            block.timestamp
        );
        usdcValue = usdc.balanceOf(address(this)) - usdcBalBefore;
    }

    /// Returns user base weight + his bonus thanks to using an nft
    function _userTotalWeight(address user) internal view returns (uint256 userTotalWeight) {
        userTotalWeight = userShares[user].weight + userShares[user].bonusWeight;
    }

    ///----- * MINISTRY OF GRAINS * -----///

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external onlyOwner {
        if (block.timestamp <= lgeEnd) {
            revert GrainLGE__NotCompleted();
        }

        /// Fetch the tokens to guarantee the amount received
        grain.safeTransferFrom(msg.sender, address(this), grainAmount);
        totalGrain += grainAmount;

        gracePeriodOver = true;
    }

    /// @notice Add a token to the lsit of tokens that can be swapped, or update one's path
    function setPathToUsdc(address[] memory _path) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (_path[_path.length-1] != address(usdc)) {
            revert GrainLGE__WrongInput();
        }
        pathToUsdc[_path[0]] = _path;

        bool containsToken;
        for (uint256 i; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _path[0]) {
                containsToken = true;
            }
        }

        if (containsToken == false) {
            supportedTokens.push(_path[0]);
        }
    }

    /// @notice Set bonus to a nft collection
    /// @dev There is no limit to the bonus, please use responsibly (10000 = 100% and is like a x2 multiplier)
    function setWhitelistedBonus(address nft, uint256 pctBonus) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (pctBonus > 1e26) {
            revert GrainLGE__WrongInput();
        }
        whitelistedBonuses[nft] = pctBonus;
    }

    function setNativeTokenGateway(address gateway) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (gateway == address(0)) {
            revert GrainLGE__WrongInput();
        }

        nativeTokenGateway = gateway;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./interfaces/IGrainLGE.sol";
import "./interfaces/IUniswapV3Router.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";
import "./interfaces/IUniswapV3Factory.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error GrainLGE__WrongInput();
error GrainLGE__UnknownToken();
error GrainLGE__Unauthorized();
error GrainLGE__NotLive();
error GrainLGE__Completed();
error GrainLGE__NotCompleted();
error GrainLGE__DoesNotOwn();
error GrainLGE__BonusAlreadyClaimed();
error GrainLGE__NotWhitelisted();
error GrainLGE__GrainNotSet();
error GrainLGE__Slippage();

/// Grain Liquidity Generation Event contract, tailored for chains with a dominant uniswapV3-style DEX.
contract GrainLGEUniV3 is IGrainLGE, Ownable {
    using SafeERC20 for IERC20;

    /// Represent the max number of releasePeriod a vest can support
    /// If the longest vesting period is 10 years, and the tokeans are
    /// released every 6 moths, there should be 20 periods
    uint256 public constant MAX_KINK_RELEASES = 8; // 2 years
    uint256 public constant MAX_RELEASES = 20; // 5 years
    uint256 public constant PERIOD = 91 days; // 3 months
    uint256 public constant maxKinkDiscount = 4e26; // 40% premium for users with kink vesting
    uint256 public constant maxDiscount = 6e26; // 60% premium for users with maximum vesting
    uint256 public constant PERCENT_DIVISOR = 1e27;

    IERC20 public immutable grain;
    ISwapRouter public immutable unirouter; // ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Factory public immutable unifactory; // IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address public immutable treasury;
    mapping(address => address[]) public pathToUsdc;
    IERC20 public immutable usdc;
    uint256 public immutable lgeStart;
    uint256 public immutable lgeEnd; // Probably 2 weeks after
    bool public gracePeriodOver;
    address[] public supportedTokens;
    address public nativeTokenGateway;

    /// Information related to user buying in the LGE
    /// usdcValue - How much user bought with in USDC
    /// numberOfReleases - How long a user is vesting
    /// weight - Numerical value representing the user's contribution
    /// totalClaimed - how much a user has already claimed
    /// nft - nft used for a bouns
    /// nftId - id of nft
    /// bonusWeight - added weight thanks to nft
    struct UserShare {
        uint256 usdcValue;
        uint256 numberOfReleases;
        uint256 weight;
        uint256 totalClaimed;
        address nft;
        uint256 nftId;
        uint256 bonusWeight;
    }
    mapping (address => UserShare) public userShares;

    /// @notice
    /// {whitelistedNfts} - NFTs that users can get a bonus of X% with. Users should only be able to get one of these
    /// {bonusReceiver} - NFT + ID returns user getting a bonus.
    mapping (address => uint256) public whitelistedBonuses;
    mapping (address => mapping(uint => address)) public bonusReceiver;

    /// How much has been raised in USDC
    uint256 public totalRaisedUsdc;
    uint256 public totalWeight;
    uint256 public totalGrain;

    constructor(address _grain, address _usdc, address _unirouter, address _unifactory, address _treasury, uint256 _lgeStart) {
        grain = IERC20(_grain);
        usdc = IERC20(_usdc);
        unirouter = ISwapRouter(_unirouter);
        unifactory = IUniswapV3Factory(_unifactory);
        treasury = _treasury;
        lgeStart = _lgeStart;
        lgeEnd = lgeStart + 2 weeks;
        supportedTokens.push(_usdc);
    }

    ///----- * STOREFRONT * -----///

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    /// Set numberOfReleases to 0 to chose the no-vesting option
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) public returns (uint256 usdcValue, uint256 vestingPremium) {
        /// Check for errors
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender && msg.sender != nativeTokenGateway) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (token != address(usdc) && pathToUsdc[token].length < 2) {
            revert GrainLGE__UnknownToken();
        }
        if (numberOfReleases > MAX_RELEASES) {
            revert GrainLGE__WrongInput();
        }

        /// Fetch tokens, turn into USDC if necessary
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (token == address(usdc)) {
            usdcValue = amount;
        } else {
            usdcValue = _swapTokenToUsdc(token, amount);
            if (usdcValue < minUsdcAmountOut) revert GrainLGE__Slippage();
        }

        /// If user has previously bought, we need to recalculate the weight, and remove it from total
        if (userShares[onBehalfOf].usdcValue != 0) {
            totalWeight -= _userTotalWeight(onBehalfOf);
        }

        if (numberOfReleases == 0) {
            vestingPremium = 0;
        } else if (numberOfReleases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% bonus
            vestingPremium = maxKinkDiscount * numberOfReleases / MAX_KINK_RELEASES;
        } else if (numberOfReleases <= MAX_RELEASES) {
            // range from 40% to 60% bonus
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (numberOfReleases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        /// Store values needed to calculate the user's share after the LGE's end
        userShares[onBehalfOf].usdcValue += usdcValue;
        userShares[onBehalfOf].numberOfReleases = numberOfReleases;

        userShares[onBehalfOf].weight = vestingPremium == 0 ? userShares[onBehalfOf].usdcValue : (userShares[onBehalfOf].usdcValue) * (PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium));
        if (userShares[onBehalfOf].nft != address(0)) {
            userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[userShares[onBehalfOf].nft] / PERCENT_DIVISOR;
        }

        totalRaisedUsdc += usdcValue;
        totalWeight += _userTotalWeight(onBehalfOf);

        /// Transfer usdc to treasury
        /// Sending the whole balance should there be leftovers
        usdc.safeTransfer(treasury, usdc.balanceOf(address(this)));
    }

    /// @notice adds a bonus to the user final weight in the LGE
    /// @dev setting nft to address(0) should remove the bonus
    function addNftBonus(address nft, uint256 nftId, address onBehalfOf) public {
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender && msg.sender != nativeTokenGateway) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (whitelistedBonuses[nft] == 0) {
            revert GrainLGE__NotWhitelisted();
        }
        if (IERC721(nft).ownerOf(nftId) != onBehalfOf) {
            revert GrainLGE__DoesNotOwn();
        }
        if (bonusReceiver[nft][nftId] != address(0)) {
            /// Someone has already claimed this nft
            revert GrainLGE__BonusAlreadyClaimed();
        }

        /// Clears onBehalfOf's previous NFT ownership mapping (if any), so others can use previous NFT again
        bonusReceiver[userShares[onBehalfOf].nft][userShares[onBehalfOf].nftId] = address(0);

        totalWeight -= _userTotalWeight(onBehalfOf);

        userShares[onBehalfOf].nft = nft;
        userShares[onBehalfOf].nftId = nftId;
        userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[nft] / PERCENT_DIVISOR;
        bonusReceiver[nft][nftId] = onBehalfOf;

        totalWeight += _userTotalWeight(onBehalfOf);
    }

    /// @dev combines the nft-less buy function and the function to add an nft
    function buy(
        address token,
        uint256 amount,
        uint256 minUsdcAmountOut,
        uint256 numberOfReleases,
        address onBehalfOf,
        address nft,
        uint256 nftId
    ) external returns (uint256 usdcValue, uint256 vestingPremium) {
        if (token != address(0)) {
            (usdcValue, vestingPremium) = buy(token, amount, minUsdcAmountOut, numberOfReleases, onBehalfOf);
        }
        if (nft != address(0)) {
            /// The weth gateway cannot act as a passthrough for nfts
            addNftBonus(nft, nftId, onBehalfOf);
        }
    }

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 claimable) {
        if (gracePeriodOver == false) {
            revert GrainLGE__GrainNotSet();
        }
        claimable = pending(msg.sender);
        if (claimable != 0) {
            userShares[msg.sender].totalClaimed += claimable;
            grain.safeTransfer(msg.sender, claimable);
        }
    }

    ///----- * PUBLIC GARDEN * -----///

    /// @notice Get how much GRAIN a user can claim
    // Will handle differently a user that is vested and one who is not
    function pending(address user) public view returns (uint256 claimable) {
        /// Get how many periods user is claiming
        if (userShares[user].numberOfReleases == 0) {
            // No vest
            claimable = totalOwed(user) - userShares[user].totalClaimed;
        } else {
            // Vest
            uint256 periodsSinceEnd = (block.timestamp - lgeEnd) / PERIOD;
            if(periodsSinceEnd > userShares[user].numberOfReleases){
                periodsSinceEnd = userShares[user].numberOfReleases;
            }
            claimable = (totalOwed(user) * periodsSinceEnd / userShares[user].numberOfReleases) - userShares[user].totalClaimed;
        }
    }

    /// @notice Get how much GRAIN a user is owed by the end of his vesting
    function totalOwed(address user) public view returns (uint256 userTotal) {
        uint256 shareOfLge = _userTotalWeight(user) * PERCENT_DIVISOR / totalWeight;
        userTotal = (shareOfLge * totalGrain) / PERCENT_DIVISOR;
    }

    /// @notice Get how much GRAIN a user has yet to receive
    function userGrainLeft(address user) public view returns (uint256 grainLeft) {
        grainLeft = totalOwed(user) - userShares[user].totalClaimed;
    }

    /// @notice Check if nft collection is whitelisted
    function isNftWhitelisted(address nft) public view returns (bool isWhitelisted) {
        isWhitelisted = whitelistedBonuses[nft] != 0;
    }

    /// @notice Get list of suported tokens to buy with
    function getSupportedTokens() public view returns (address[] memory) {
        return supportedTokens;
    }

    function getSupportedTokensLength() public view returns (uint256 length) {
        length = supportedTokens.length;
    }

    ///----- * PRIVATE GREENHOUSE * -----///

    /// Swap tokens using a uniV2 protocol and router
    function _swapTokenToUsdc(address token, uint256 amount) internal returns (uint256 usdcValue) {
        if (amount == 0) {
            return 0;
        }

        uint256 usdcBalBefore = usdc.balanceOf(address(this));

        uint24 fees;

        if (pathToUsdc[token].length == 2) {
            /// If path to usdc is of length 2 -> single swap
            (, fees) = _uniswapV3PoolExists(token, address(usdc));
            IERC20(token).safeIncreaseAllowance(address(unirouter), amount);
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token,
                tokenOut: address(usdc),
                fee: fees,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            unirouter.exactInputSingle(params);
        } else if (pathToUsdc[token].length > 2) {
            /// If not -> multihop
            uint256 prevAmount = amount;
            for (uint256 i; i < pathToUsdc[token].length - 1; i++) {
                IERC20(pathToUsdc[token][i]).safeIncreaseAllowance(address(unirouter), prevAmount);
                (, fees) = _uniswapV3PoolExists(pathToUsdc[token][i], address(usdc));
                    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                    tokenIn: pathToUsdc[token][i],
                    tokenOut: pathToUsdc[token][i+1],
                    fee: fees,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: prevAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                prevAmount = unirouter.exactInputSingle(params);
            }
        }

        usdcValue = usdc.balanceOf(address(this)) - usdcBalBefore;
    }



    function _uniswapV3PoolExists(address _tokenIn, address _tokenOut) internal view returns (bool poolExists, uint24 poolFee) {
        /// Uniswap allows 3 different pool fees
        uint24 poolFee1 = 500;
        uint24 poolFee2 = 3000;
        uint24 poolFee3 = 10000;

        if (unifactory.getPool(_tokenIn, _tokenOut, poolFee1) != address(0)) {
            poolFee = poolFee1;
            poolExists = true;
        } else if (unifactory.getPool(_tokenIn, _tokenOut, poolFee2) != address(0)) {
            poolFee = poolFee2;
            poolExists = true;
        } else if (unifactory.getPool(_tokenIn, _tokenOut, poolFee3) != address(0)) {
            poolFee = poolFee3;
            poolExists = true;
        }
    }

    /// Returns user base weight + his bonus thanks to using an nft
    function _userTotalWeight(address user) internal view returns (uint256 userTotalWeight) {
        userTotalWeight = userShares[user].weight + userShares[user].bonusWeight;
    }

    ///----- * MINISTRY OF GRAINS * -----///

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external onlyOwner {
        if (block.timestamp <= lgeEnd) {
            revert GrainLGE__NotCompleted();
        }

        /// Fetch the tokens to guarantee the amount received
        grain.safeTransferFrom(msg.sender, address(this), grainAmount);
        totalGrain += grainAmount;

        gracePeriodOver = true;
    }

    /// @notice Add a token to the list of tokens that can be swapped, or update one's path
    function setPathToUsdc(address[] memory _path) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (_path[_path.length-1] != address(usdc)) {
            revert GrainLGE__WrongInput();
        }
        pathToUsdc[_path[0]] = _path;

        bool containsToken;
        for (uint256 i; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _path[0]) {
                containsToken = true;
            }
        }

        if (containsToken == false) {
            supportedTokens.push(_path[0]);
        }
    }

    /// @notice Set bonus to a nft collection
    /// @dev There is no limit to the bonus, please use responsibly (10000 = 100% and is like a x2 multiplier)
    function setWhitelistedBonus(address nft, uint256 pctBonus) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (pctBonus > 1e26) {
            revert GrainLGE__WrongInput();
        }
        whitelistedBonuses[nft] = pctBonus;
    }

    function setNativeTokenGateway(address gateway) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (gateway == address(0)) {
            revert GrainLGE__WrongInput();
        }

        nativeTokenGateway = gateway;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IGrain {

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IGrainLGE {

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) external returns (uint256 usdcValue, uint256 vestingPremium);

    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf, address nft, uint256 nftId) external returns (uint256 usdcValue,uint256 vp);

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 amountReleased);

    /// @notice Get how much GRAIN a user can claim
    // We may be able to get rid of this one as claim() and a static call can return the same value
    function pending(address user) external view returns (uint256 claimableAmount);

    /// @notice Get how much GRAIN a user is still owed by the end of his vesting
    function totalOwed(address user) external view returns (uint256 userTotal);

    /// @notice Get how much USDC has been raised
    function totalRaisedUsdc() external view returns (uint256 total);

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IMagicats {

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IWETHGateway {
  function depositETH(
    uint256 minUsdcAmountOut,
    uint256 numberOfReleases
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MockERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Mock ERC721", "mockNFT") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract MockGRAIN is Initializable, ERC20Upgradeable, ERC20CappedUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");
    uint256 public constant MAX_SUPPLY = 800_000_000 ether;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 public constant UPGRADE_TIMELOCK = 48 hours;
    uint256 public upgradeProposalTime;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // @param lge: granting minting rights to the Liquidity Generation Event contract for initial distribution  
    function initialize(address admin) initializer public { 
        __ERC20_init("Granary Token", "GRAIN");
        __ERC20Capped_init(MAX_SUPPLY); 
        __AccessControl_init(); 
        __Pausable_init();  
        __ERC20Permit_init("Granary Token");   
        __UUPSUpgradeable_init();   
        _grantRole(DEFAULT_ADMIN_ROLE, admin);  
        _grantRole(PAUSER_ROLE, admin); 
        _grantRole(MINTER_ROLE, admin); 
        _grantRole(UPGRADER_ROLE, admin);   
        _grantRole(RESCUER_ROLE, admin);    
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) returns (bool) {
        _mint(to, amount);
        return true;
    }
    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function rescueLostTokens(address token, address to, uint256 amount) public onlyRole(RESCUER_ROLE){
    	IERC20Upgradeable(token).transfer(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) returns (bool) {
        _burn(from, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20Upgradeable){
        super._burn(account, amount);
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE must call this function prior to upgrading the implementation
     *      and wait UPGRADE_TIMELOCK seconds before executing the upgrade.
     */
    function initiateUpgradeCooldown() external onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeProposalTime = block.timestamp;
    }

    /**
     * @dev This function is called:
     *      - as part of a successful upgrade
     *      - manually by DEFAULT_ADMIN_ROLE to clear the upgrade cooldown.a
     */
    function clearUpgradeCooldown() public onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeProposalTime = block.timestamp + (100 * 365 days);
    }

    /**
     * @dev This function must be overriden simply for access control purposes.
     *      Only DEFAULT_ADMIN_ROLE can upgrade the implementation once the timelock
     *      has passed.
     */
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(upgradeProposalTime + UPGRADE_TIMELOCK < block.timestamp, "cooldown not initiated or still active");
        clearUpgradeCooldown();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IGrainLGE.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error GrainLGE__WrongInput();
error GrainLGE__UnknownToken();
error GrainLGE__Unauthorized();
error GrainLGE__NotLive();
error GrainLGE__Completed();
error GrainLGE__NotCompleted();
error GrainLGE__DoesNotOwn();
error GrainLGE__BonusAlreadyClaimed();
error GrainLGE__NotWhitelisted();
error GrainLGE__GrainNotSet();
error GrainLGE__Slippage();

/// Grain Liquidity Generation Event contract, tailored for chains with a dominant uniswapV2-style DEX.
contract TestGrainLGEMetis is IGrainLGE, Ownable {
    using SafeERC20 for IERC20;

    /// Represent the max number of releasePeriod a vest can support
    /// If the longest vesting period is 8 years, and the tokens are
    /// released every 3 months, there should be 32 periods
    uint256 public constant MAX_KINK_RELEASES = 8; // 2 years
    uint256 public constant MAX_RELEASES = 20; // 5 years
    uint256 public constant PERIOD = 91 days; // 3 months
    uint256 public constant maxKinkDiscount = 4e26; // 40% premium for users with kink vesting
    uint256 public constant maxDiscount = 6e26; // 60% premium for users with maximum vesting
    uint256 public constant PERCENT_DIVISOR = 1e27;

    IERC20 public immutable grain;
    address public immutable unirouter;
    address public immutable treasury;
    mapping(address => address[]) public pathToUsdc;
    IERC20 public immutable usdc;
    uint256 public immutable lgeStart;
    uint256 public lgeEnd; // Probably 2 weeks after
    bool public gracePeriodOver;
    address[] public supportedTokens;

    /// Information related to user buying in the LGE
    /// usdcValue - How much user bought with in USDC
    /// numberOfReleases - How long a user is vesting
    /// weight - Numerical value representing the user's contribution
    /// totalClaimed - how much a user has already claimed
    /// nft - nft used for a bouns
    /// nftId - id of nft
    /// bonusWeight - added weight thanks to nft
    struct UserShare {
        uint256 usdcValue;
        uint256 numberOfReleases;
        uint256 weight;
        uint256 totalClaimed;
        address nft;
        uint256 nftId;
        uint256 bonusWeight;
    }
    mapping (address => UserShare) public userShares;

    /// @notice
    /// {whitelistedNfts} - NFTs that users can get a bonus of X% with. Users should only be able to get one of these
    /// {bonusReceiver} - NFT + ID returns user getting a bonus.
    mapping (address => uint256) public whitelistedBonuses;
    mapping (address => mapping(uint => address)) public bonusReceiver;

    /// How much has been raised in USDC
    uint256 public totalRaisedUsdc;
    uint256 public totalWeight;
    uint256 public totalGrain;

    constructor(address _grain, address _usdc, address _unirouter, address _treasury, uint256 _lgeStart) {
        grain = IERC20(_grain);
        usdc = IERC20(_usdc);
        unirouter = _unirouter;
        treasury = _treasury;
        lgeStart = _lgeStart;
        lgeEnd = lgeStart + 2 weeks;
        supportedTokens.push(_usdc);
    }

    ///----- * STOREFRONT * -----///

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    /// Set numberOfReleases to 0 to chose the no-vesting option
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) public returns (uint256 usdcValue, uint256 vestingPremium) {
        /// Check for errors
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (token != address(usdc) && pathToUsdc[token].length < 2) {
            revert GrainLGE__UnknownToken();
        }
        if (numberOfReleases > MAX_RELEASES) {
            revert GrainLGE__WrongInput();
        }

        /// Fetch tokens, turn into USDC if necessary
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (token == address(usdc)) {
            usdcValue = amount;
        } else {
            usdcValue = _swapTokenToUsdc(token, amount);
            if (usdcValue < minUsdcAmountOut) revert GrainLGE__Slippage();
        }

        /// If user has previously bought, we need to recalculate the weight, and remove it from total
        if (userShares[onBehalfOf].usdcValue != 0) {
            totalWeight -= _userTotalWeight(onBehalfOf);
        }

        if (numberOfReleases == 0) {
            vestingPremium = 0;
        } else if (numberOfReleases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% discount
            vestingPremium = maxKinkDiscount * numberOfReleases / MAX_KINK_RELEASES;
        } else if (numberOfReleases <= MAX_RELEASES) {
            // range from 40% to 60% discount
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (numberOfReleases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        /// Store values needed to calculate the user's share after the LGE's end
        userShares[onBehalfOf].usdcValue += usdcValue;
        userShares[onBehalfOf].numberOfReleases = numberOfReleases;

        userShares[onBehalfOf].weight = vestingPremium == 0 ? userShares[onBehalfOf].usdcValue : (userShares[onBehalfOf].usdcValue) * (PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium));
        if (userShares[onBehalfOf].nft != address(0)) {
            userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[userShares[onBehalfOf].nft] / PERCENT_DIVISOR;
        }

        totalRaisedUsdc += usdcValue;
        totalWeight += _userTotalWeight(onBehalfOf);

        /// Transfer usdc to treasury
        /// Sending the whole balance should there be leftovers
        usdc.safeTransfer(treasury, usdc.balanceOf(address(this)));
    }

    /// @notice adds a bonus to the user final weight in the LGE
    /// @dev setting nft to address(0) should remove the bonus
    function addNftBonus(address nft, uint256 nftId, address onBehalfOf) public {
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (whitelistedBonuses[nft] == 0) {
            revert GrainLGE__NotWhitelisted();
        }
        if (IERC721(nft).ownerOf(nftId) != onBehalfOf) {
            revert GrainLGE__DoesNotOwn();
        }
        if (bonusReceiver[nft][nftId] != address(0)) {
            /// Someone has already claimed this nft
            revert GrainLGE__BonusAlreadyClaimed();
        }

        /// Clears onBehalfOf's previous NFT ownership mapping (if any), so others can use previous NFT again
        bonusReceiver[userShares[onBehalfOf].nft][userShares[onBehalfOf].nftId] = address(0);

        totalWeight -= _userTotalWeight(onBehalfOf);

        userShares[onBehalfOf].nft = nft;
        userShares[onBehalfOf].nftId = nftId;
        userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[nft] / PERCENT_DIVISOR;
        bonusReceiver[nft][nftId] = onBehalfOf;

        totalWeight += _userTotalWeight(onBehalfOf);
    }

    /// @dev combines the nft-less buy function and the function to add an nft
    function buy(
        address token,
        uint256 amount,
        uint256 minUsdcAmountOut,
        uint256 numberOfReleases,
        address onBehalfOf,
        address nft,
        uint256 nftId
    ) external returns (uint256 usdcValue, uint256 vestingPremium) {
        if (token != address(0)) {
            (usdcValue, vestingPremium) = buy(token, amount, minUsdcAmountOut, numberOfReleases, onBehalfOf);
        }
        if (nft != address(0)) {
            addNftBonus(nft, nftId, onBehalfOf);
        }
    }

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 claimable) {
        if (gracePeriodOver == false) {
            revert GrainLGE__GrainNotSet();
        }
        claimable = pending(msg.sender);
        if (claimable != 0) {
            userShares[msg.sender].totalClaimed += claimable;
            grain.safeTransfer(msg.sender, claimable);
        }
    }

    ///----- * PUBLIC GARDEN * -----///

    /// @notice Get how much GRAIN a user can claim
    // Will handle differently a user that is vested and one who is not
    function pending(address user) public view returns (uint256 claimable) {
        /// Get how many periods user is claiming
        if (userShares[user].numberOfReleases == 0) {
            // No vest
            claimable = totalOwed(user) - userShares[user].totalClaimed;
        } else {
            // Vest
            uint256 periodsSinceEnd = (block.timestamp - lgeEnd) / PERIOD;
            if(periodsSinceEnd > userShares[user].numberOfReleases){
                periodsSinceEnd = userShares[user].numberOfReleases;
            }
            claimable = (totalOwed(user) * periodsSinceEnd / userShares[user].numberOfReleases) - userShares[user].totalClaimed;
        }
    }

    /// @notice Get how much GRAIN a user is owed by the end of his vesting
    function totalOwed(address user) public view returns (uint256 userTotal) {
        uint256 shareOfLge = _userTotalWeight(user) * PERCENT_DIVISOR / totalWeight;
        userTotal = (shareOfLge * totalGrain) / PERCENT_DIVISOR;
    }

    /// @notice Get how much GRAIN a user has yet to receive
    function userGrainLeft(address user) public view returns (uint256 grainLeft) {
        grainLeft = totalOwed(user) - userShares[user].totalClaimed;
    }

    /// @notice Check if nft collection is whitelisted
    function isNftWhitelisted(address nft) public view returns (bool isWhitelisted) {
        isWhitelisted = whitelistedBonuses[nft] != 0;
    }

    /// @notice Get list of suported tokens to buy with
    function getSupportedTokens() public view returns (address[] memory) {
        return supportedTokens;
    }

    function getSupportedTokensLength() public view returns (uint256 length) {
        length = supportedTokens.length;
    }

    ///----- * PRIVATE GREENHOUSE * -----///

    /// Swap tokens using a uniV2 protocol and router
    function _swapTokenToUsdc(address token, uint256 amount) internal returns (uint256 usdcValue) {
        if (amount == 0) {
            return 0;
        }

        uint256 usdcBalBefore = usdc.balanceOf(address(this));

        IERC20(token).safeIncreaseAllowance(unirouter, amount);
        IUniswapV2Router02(unirouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            pathToUsdc[token],
            address(this),
            block.timestamp
        );
        usdcValue = usdc.balanceOf(address(this)) - usdcBalBefore;
    }

    /// Returns user base weight + his bonus thanks to using an nft
    function _userTotalWeight(address user) internal view returns (uint256 userTotalWeight) {
        userTotalWeight = userShares[user].weight + userShares[user].bonusWeight;
    }

    ///----- * MINISTRY OF GRAINS * -----///

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external onlyOwner {
        if (block.timestamp <= lgeEnd) {
            revert GrainLGE__NotCompleted();
        }

        /// Fetch the tokens to guarantee the amount received
        grain.safeTransferFrom(msg.sender, address(this), grainAmount);
        totalGrain += grainAmount;

        gracePeriodOver = true;
    }

    /// @notice Add a token to the lsit of tokens that can be swapped, or update one's path
    function setPathToUsdc(address[] memory _path) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (_path[_path.length-1] != address(usdc)) {
            revert GrainLGE__WrongInput();
        }
        pathToUsdc[_path[0]] = _path;

        bool containsToken;
        for (uint256 i; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _path[0]) {
                containsToken = true;
            }
        }

        if (containsToken == false) {
            supportedTokens.push(_path[0]);
        }
    }

    /// @notice Set bonus to a nft collection
    /// @dev There is no limit to the bonus, please use responsibly (10000 = 100% and is like a x2 multiplier)
    function setWhitelistedBonus(address nft, uint256 pctBonus) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (pctBonus > 1e26) {
            revert GrainLGE__WrongInput();
        }
        whitelistedBonuses[nft] = pctBonus;
    }

    function setLgeEnd(uint256 timestamp) external onlyOwner {
        lgeEnd = timestamp;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IGrainLGE.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error GrainLGE__WrongInput();
error GrainLGE__UnknownToken();
error GrainLGE__Unauthorized();
error GrainLGE__NotLive();
error GrainLGE__Completed();
error GrainLGE__NotCompleted();
error GrainLGE__DoesNotOwn();
error GrainLGE__BonusAlreadyClaimed();
error GrainLGE__NotWhitelisted();
error GrainLGE__GrainNotSet();
error GrainLGE__Slippage();

/// Grain Liquidity Generation Event contract, tailored for chains with a dominant uniswapV2-style DEX.
contract TestGrainLGEUniV2 is IGrainLGE, Ownable {
    using SafeERC20 for IERC20;

    /// Represent the max number of releasePeriod a vest can support
    /// If the longest vesting period is 8 years, and the tokens are
    /// released every 3 months, there should be 32 periods
    uint256 public constant MAX_KINK_RELEASES = 8; // 2 years
    uint256 public constant MAX_RELEASES = 20; // 5 years
    uint256 public constant PERIOD = 91 days; // 3 months
    uint256 public constant maxKinkDiscount = 4e26; // 40% premium for users with kink vesting
    uint256 public constant maxDiscount = 6e26; // 60% premium for users with maximum vesting
    uint256 public constant PERCENT_DIVISOR = 1e27;

    IERC20 public immutable grain;
    address public immutable unirouter;
    address public immutable treasury;
    mapping(address => address[]) public pathToUsdc;
    IERC20 public immutable usdc;
    uint256 public immutable lgeStart;
    uint256 public lgeEnd; // Probably 2 weeks after
    bool public gracePeriodOver;
    address[] public supportedTokens;
    address public nativeTokenGateway;

    /// Information related to user buying in the LGE
    /// usdcValue - How much user bought with in USDC
    /// numberOfReleases - How long a user is vesting
    /// weight - Numerical value representing the user's contribution
    /// totalClaimed - how much a user has already claimed
    /// nft - nft used for a bouns
    /// nftId - id of nft
    /// bonusWeight - added weight thanks to nft
    struct UserShare {
        uint256 usdcValue;
        uint256 numberOfReleases;
        uint256 weight;
        uint256 totalClaimed;
        address nft;
        uint256 nftId;
        uint256 bonusWeight;
    }
    mapping (address => UserShare) public userShares;

    /// @notice
    /// {whitelistedNfts} - NFTs that users can get a bonus of X% with. Users should only be able to get one of these
    /// {bonusReceiver} - NFT + ID returns user getting a bonus.
    mapping (address => uint256) public whitelistedBonuses;
    mapping (address => mapping(uint => address)) public bonusReceiver;

    /// How much has been raised in USDC
    uint256 public totalRaisedUsdc;
    uint256 public totalWeight;
    uint256 public totalGrain;

    constructor(address _grain, address _usdc, address _unirouter, address _treasury, uint256 _lgeStart) {
        grain = IERC20(_grain);
        usdc = IERC20(_usdc);
        unirouter = _unirouter;
        treasury = _treasury;
        lgeStart = _lgeStart;
        lgeEnd = lgeStart + 2 weeks;
        supportedTokens.push(_usdc);
    }

    ///----- * STOREFRONT * -----///

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    /// Set numberOfReleases to 0 to chose the no-vesting option
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) public returns (uint256 usdcValue, uint256 vestingPremium) {
        /// Check for errors
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender && msg.sender != nativeTokenGateway) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (token != address(usdc) && pathToUsdc[token].length < 2) {
            revert GrainLGE__UnknownToken();
        }
        if (numberOfReleases > MAX_RELEASES) {
            revert GrainLGE__WrongInput();
        }

        /// Fetch tokens, turn into USDC if necessary
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (token == address(usdc)) {
            usdcValue = amount;
        } else {
            usdcValue = _swapTokenToUsdc(token, amount);
            if (usdcValue < minUsdcAmountOut) revert GrainLGE__Slippage();
        }

        /// If user has previously bought, we need to recalculate the weight, and remove it from total
        if (userShares[onBehalfOf].usdcValue != 0) {
            totalWeight -= _userTotalWeight(onBehalfOf);
        }

        if (numberOfReleases == 0) {
            vestingPremium = 0;
        } else if (numberOfReleases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% discount
            vestingPremium = maxKinkDiscount * numberOfReleases / MAX_KINK_RELEASES;
        } else if (numberOfReleases <= MAX_RELEASES) {
            // range from 40% to 60% discount
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (numberOfReleases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        /// Store values needed to calculate the user's share after the LGE's end
        userShares[onBehalfOf].usdcValue += usdcValue;
        userShares[onBehalfOf].numberOfReleases = numberOfReleases;

        userShares[onBehalfOf].weight = vestingPremium == 0 ? userShares[onBehalfOf].usdcValue : (userShares[onBehalfOf].usdcValue) * (PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium));
        if (userShares[onBehalfOf].nft != address(0)) {
            userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[userShares[onBehalfOf].nft] / PERCENT_DIVISOR;
        }

        totalRaisedUsdc += usdcValue;
        totalWeight += _userTotalWeight(onBehalfOf);

        /// Transfer usdc to treasury
        /// Sending the whole balance should there be leftovers
        usdc.safeTransfer(treasury, usdc.balanceOf(address(this)));
    }

    /// @notice adds a bonus to the user final weight in the LGE
    /// @dev setting nft to address(0) should remove the bonus
    function addNftBonus(address nft, uint256 nftId, address onBehalfOf) public {
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender && msg.sender != nativeTokenGateway) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (whitelistedBonuses[nft] == 0) {
            revert GrainLGE__NotWhitelisted();
        }
        if (IERC721(nft).ownerOf(nftId) != onBehalfOf) {
            revert GrainLGE__DoesNotOwn();
        }
        if (bonusReceiver[nft][nftId] != address(0)) {
            /// Someone has already claimed this nft
            revert GrainLGE__BonusAlreadyClaimed();
        }

        /// Clears onBehalfOf's previous NFT ownership mapping (if any), so others can use previous NFT again
        bonusReceiver[userShares[onBehalfOf].nft][userShares[onBehalfOf].nftId] = address(0);

        totalWeight -= _userTotalWeight(onBehalfOf);

        userShares[onBehalfOf].nft = nft;
        userShares[onBehalfOf].nftId = nftId;
        userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[nft] / PERCENT_DIVISOR;
        bonusReceiver[nft][nftId] = onBehalfOf;

        totalWeight += _userTotalWeight(onBehalfOf);
    }

    /// @dev combines the nft-less buy function and the function to add an nft
    function buy(
        address token,
        uint256 amount,
        uint256 minUsdcAmountOut,
        uint256 numberOfReleases,
        address onBehalfOf,
        address nft,
        uint256 nftId
    ) external returns (uint256 usdcValue, uint256 vestingPremium) {
        if (token != address(0)) {
            (usdcValue, vestingPremium) = buy(token, amount, minUsdcAmountOut, numberOfReleases, onBehalfOf);
        }
        if (nft != address(0)) {
            /// The weth gateway cannot act as a passthrough for nfts
            addNftBonus(nft, nftId, onBehalfOf);
        }
    }

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 claimable) {
        if (gracePeriodOver == false) {
            revert GrainLGE__GrainNotSet();
        }
        claimable = pending(msg.sender);
        if (claimable != 0) {
            userShares[msg.sender].totalClaimed += claimable;
            grain.safeTransfer(msg.sender, claimable);
        }
    }

    ///----- * PUBLIC GARDEN * -----///

    /// @notice Get how much GRAIN a user can claim
    // Will handle differently a user that is vested and one who is not
    function pending(address user) public view returns (uint256 claimable) {
        /// Get how many periods user is claiming
        if (userShares[user].numberOfReleases == 0) {
            // No vest
            claimable = totalOwed(user) - userShares[user].totalClaimed;
        } else {
            // Vest
            uint256 periodsSinceEnd = (block.timestamp - lgeEnd) / PERIOD;
            if(periodsSinceEnd > userShares[user].numberOfReleases){
                periodsSinceEnd = userShares[user].numberOfReleases;
            }
            claimable = (totalOwed(user) * periodsSinceEnd / userShares[user].numberOfReleases) - userShares[user].totalClaimed;
        }
    }

    /// @notice Get how much GRAIN a user is owed by the end of his vesting
    function totalOwed(address user) public view returns (uint256 userTotal) {
        uint256 shareOfLge = _userTotalWeight(user) * PERCENT_DIVISOR / totalWeight;
        userTotal = (shareOfLge * totalGrain) / PERCENT_DIVISOR;
    }

    /// @notice Get how much GRAIN a user has yet to receive
    function userGrainLeft(address user) public view returns (uint256 grainLeft) {
        grainLeft = totalOwed(user) - userShares[user].totalClaimed;
    }

    /// @notice Check if nft collection is whitelisted
    function isNftWhitelisted(address nft) public view returns (bool isWhitelisted) {
        isWhitelisted = whitelistedBonuses[nft] != 0;
    }

    /// @notice Get list of suported tokens to buy with
    function getSupportedTokens() public view returns (address[] memory) {
        return supportedTokens;
    }

    function getSupportedTokensLength() public view returns (uint256 length) {
        length = supportedTokens.length;
    }

    ///----- * PRIVATE GREENHOUSE * -----///

    /// Swap tokens using a uniV2 protocol and router
    function _swapTokenToUsdc(address token, uint256 amount) internal returns (uint256 usdcValue) {
        if (amount == 0) {
            return 0;
        }

        uint256 usdcBalBefore = usdc.balanceOf(address(this));

        IERC20(token).safeIncreaseAllowance(unirouter, amount);
        IUniswapV2Router02(unirouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            pathToUsdc[token],
            address(this),
            block.timestamp
        );
        usdcValue = usdc.balanceOf(address(this)) - usdcBalBefore;
    }

    /// Returns user base weight + his bonus thanks to using an nft
    function _userTotalWeight(address user) internal view returns (uint256 userTotalWeight) {
        userTotalWeight = userShares[user].weight + userShares[user].bonusWeight;
    }

    ///----- * MINISTRY OF GRAINS * -----///

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external onlyOwner {
        if (block.timestamp <= lgeEnd) {
            revert GrainLGE__NotCompleted();
        }

        /// Fetch the tokens to guarantee the amount received
        grain.safeTransferFrom(msg.sender, address(this), grainAmount);
        totalGrain += grainAmount;

        gracePeriodOver = true;
    }

    /// @notice Add a token to the lsit of tokens that can be swapped, or update one's path
    function setPathToUsdc(address[] memory _path) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (_path[_path.length-1] != address(usdc)) {
            revert GrainLGE__WrongInput();
        }
        pathToUsdc[_path[0]] = _path;

        bool containsToken;
        for (uint256 i; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _path[0]) {
                containsToken = true;
            }
        }

        if (containsToken == false) {
            supportedTokens.push(_path[0]);
        }
    }

    /// @notice Set bonus to a nft collection
    /// @dev There is no limit to the bonus, please use responsibly (10000 = 100% and is like a x2 multiplier)
    function setWhitelistedBonus(address nft, uint256 pctBonus) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (pctBonus > 1e26) {
            revert GrainLGE__WrongInput();
        }
        whitelistedBonuses[nft] = pctBonus;
    }

    function setNativeTokenGateway(address gateway) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (gateway == address(0)) {
            revert GrainLGE__WrongInput();
        }

        nativeTokenGateway = gateway;
    }

    function setLgeEnd(uint256 timestamp) external onlyOwner {
        lgeEnd = timestamp;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IGrainLGE.sol";
import "../interfaces/IUniswapV3Router.sol";
import "../interfaces/IUniswapV3SwapCallback.sol";
import "../interfaces/IUniswapV3Factory.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error GrainLGE__WrongInput();
error GrainLGE__UnknownToken();
error GrainLGE__Unauthorized();
error GrainLGE__NotLive();
error GrainLGE__Completed();
error GrainLGE__NotCompleted();
error GrainLGE__DoesNotOwn();
error GrainLGE__BonusAlreadyClaimed();
error GrainLGE__NotWhitelisted();
error GrainLGE__GrainNotSet();
error GrainLGE__Slippage();

/// Grain Liquidity Generation Event contract, tailored for chains with a dominant uniswapV3-style DEX.
contract TestGrainLGEUniV3 is IGrainLGE, Ownable {
    using SafeERC20 for IERC20;

    /// Represent the max number of releasePeriod a vest can support
    /// If the longest vesting period is 10 years, and the tokeans are
    /// released every 6 moths, there should be 20 periods
    uint256 public constant MAX_KINK_RELEASES = 8; // 2 years
    uint256 public constant MAX_RELEASES = 20; // 5 years
    uint256 public constant PERIOD = 91 days; // 3 months
    uint256 public constant maxKinkDiscount = 4e26; // 40% premium for users with kink vesting
    uint256 public constant maxDiscount = 6e26; // 60% premium for users with maximum vesting
    uint256 public constant PERCENT_DIVISOR = 1e27;

    IERC20 public immutable grain;
    ISwapRouter public immutable unirouter; // ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Factory public immutable unifactory; // IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address public immutable treasury;
    mapping(address => address[]) public pathToUsdc;
    IERC20 public immutable usdc;
    uint256 public immutable lgeStart;
    uint256 public lgeEnd; // Probably 2 weeks after
    bool public gracePeriodOver;
    address[] public supportedTokens;
    address public nativeTokenGateway;

    /// Information related to user buying in the LGE
    /// usdcValue - How much user bought with in USDC
    /// numberOfReleases - How long a user is vesting
    /// weight - Numerical value representing the user's contribution
    /// totalClaimed - how much a user has already claimed
    /// nft - nft used for a bouns
    /// nftId - id of nft
    /// bonusWeight - added weight thanks to nft
    struct UserShare {
        uint256 usdcValue;
        uint256 numberOfReleases;
        uint256 weight;
        uint256 totalClaimed;
        address nft;
        uint256 nftId;
        uint256 bonusWeight;
    }
    mapping (address => UserShare) public userShares;

    /// @notice
    /// {whitelistedNfts} - NFTs that users can get a bonus of X% with. Users should only be able to get one of these
    /// {bonusReceiver} - NFT + ID returns user getting a bonus.
    mapping (address => uint256) public whitelistedBonuses;
    mapping (address => mapping(uint => address)) public bonusReceiver;

    /// How much has been raised in USDC
    uint256 public totalRaisedUsdc;
    uint256 public totalWeight;
    uint256 public totalGrain;

    constructor(address _grain, address _usdc, address _unirouter, address _unifactory, address _treasury, uint256 _lgeStart) {
        grain = IERC20(_grain);
        usdc = IERC20(_usdc);
        unirouter = ISwapRouter(_unirouter);
        unifactory = IUniswapV3Factory(_unifactory);
        treasury = _treasury;
        lgeStart = _lgeStart;
        lgeEnd = lgeStart + 2 weeks;
        supportedTokens.push(_usdc);
    }

    ///----- * STOREFRONT * -----///

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    /// Set numberOfReleases to 0 to chose the no-vesting option
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) public returns (uint256 usdcValue, uint256 vestingPremium) {
        /// Check for errors
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender && msg.sender != nativeTokenGateway) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (token != address(usdc) && pathToUsdc[token].length < 2) {
            revert GrainLGE__UnknownToken();
        }
        if (numberOfReleases > MAX_RELEASES) {
            revert GrainLGE__WrongInput();
        }

        /// Fetch tokens, turn into USDC if necessary
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (token == address(usdc)) {
            usdcValue = amount;
        } else {
            usdcValue = _swapTokenToUsdc(token, amount);
            if (usdcValue < minUsdcAmountOut) revert GrainLGE__Slippage();
        }

        /// If user has previously bought, we need to recalculate the weight, and remove it from total
        if (userShares[onBehalfOf].usdcValue != 0) {
            totalWeight -= _userTotalWeight(onBehalfOf);
        }

        if (numberOfReleases == 0) {
            vestingPremium = 0;
        } else if (numberOfReleases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% bonus
            vestingPremium = maxKinkDiscount * numberOfReleases / MAX_KINK_RELEASES;
        } else if (numberOfReleases <= MAX_RELEASES) {
            // range from 40% to 60% bonus
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (numberOfReleases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        /// Store values needed to calculate the user's share after the LGE's end
        userShares[onBehalfOf].usdcValue += usdcValue;
        userShares[onBehalfOf].numberOfReleases = numberOfReleases;

        userShares[onBehalfOf].weight = vestingPremium == 0 ? userShares[onBehalfOf].usdcValue : (userShares[onBehalfOf].usdcValue) * (PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium));
        if (userShares[onBehalfOf].nft != address(0)) {
            userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[userShares[onBehalfOf].nft] / PERCENT_DIVISOR;
        }

        totalRaisedUsdc += usdcValue;
        totalWeight += _userTotalWeight(onBehalfOf);

        /// Transfer usdc to treasury
        /// Sending the whole balance should there be leftovers
        usdc.safeTransfer(treasury, usdc.balanceOf(address(this)));
    }

    /// @notice adds a bonus to the user final weight in the LGE
    /// @dev setting nft to address(0) should remove the bonus
    function addNftBonus(address nft, uint256 nftId, address onBehalfOf) public {
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender && msg.sender != nativeTokenGateway) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (whitelistedBonuses[nft] == 0) {
            revert GrainLGE__NotWhitelisted();
        }
        if (IERC721(nft).ownerOf(nftId) != onBehalfOf) {
            revert GrainLGE__DoesNotOwn();
        }
        if (bonusReceiver[nft][nftId] != address(0)) {
            /// Someone has already claimed this nft
            revert GrainLGE__BonusAlreadyClaimed();
        }

        /// Clears onBehalfOf's previous NFT ownership mapping (if any), so others can use previous NFT again
        bonusReceiver[userShares[onBehalfOf].nft][userShares[onBehalfOf].nftId] = address(0);

        totalWeight -= _userTotalWeight(onBehalfOf);

        userShares[onBehalfOf].nft = nft;
        userShares[onBehalfOf].nftId = nftId;
        userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[nft] / PERCENT_DIVISOR;
        bonusReceiver[nft][nftId] = onBehalfOf;

        totalWeight += _userTotalWeight(onBehalfOf);
    }

    /// @dev combines the nft-less buy function and the function to add an nft
    function buy(
        address token,
        uint256 amount,
        uint256 minUsdcAmountOut,
        uint256 numberOfReleases,
        address onBehalfOf,
        address nft,
        uint256 nftId
    ) external returns (uint256 usdcValue, uint256 vestingPremium) {
        if (token != address(0)) {
            (usdcValue, vestingPremium) = buy(token, amount, minUsdcAmountOut, numberOfReleases, onBehalfOf);
        }
        if (nft != address(0)) {
            /// The weth gateway cannot act as a passthrough for nfts
            addNftBonus(nft, nftId, onBehalfOf);
        }
    }

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 claimable) {
        if (gracePeriodOver == false) {
            revert GrainLGE__GrainNotSet();
        }
        claimable = pending(msg.sender);
        if (claimable != 0) {
            userShares[msg.sender].totalClaimed += claimable;
            grain.safeTransfer(msg.sender, claimable);
        }
    }

    ///----- * PUBLIC GARDEN * -----///

    /// @notice Get how much GRAIN a user can claim
    // Will handle differently a user that is vested and one who is not
    function pending(address user) public view returns (uint256 claimable) {
        /// Get how many periods user is claiming
        if (userShares[user].numberOfReleases == 0) {
            // No vest
            claimable = totalOwed(user) - userShares[user].totalClaimed;
        } else {
            // Vest
            uint256 periodsSinceEnd = (block.timestamp - lgeEnd) / PERIOD;
            if(periodsSinceEnd > userShares[user].numberOfReleases){
                periodsSinceEnd = userShares[user].numberOfReleases;
            }
            claimable = (totalOwed(user) * periodsSinceEnd / userShares[user].numberOfReleases) - userShares[user].totalClaimed;
        }
    }

    /// @notice Get how much GRAIN a user is owed by the end of his vesting
    function totalOwed(address user) public view returns (uint256 userTotal) {
        uint256 shareOfLge = _userTotalWeight(user) * PERCENT_DIVISOR / totalWeight;
        userTotal = (shareOfLge * totalGrain) / PERCENT_DIVISOR;
    }

    /// @notice Get how much GRAIN a user has yet to receive
    function userGrainLeft(address user) public view returns (uint256 grainLeft) {
        grainLeft = totalOwed(user) - userShares[user].totalClaimed;
    }

    /// @notice Check if nft collection is whitelisted
    function isNftWhitelisted(address nft) public view returns (bool isWhitelisted) {
        isWhitelisted = whitelistedBonuses[nft] != 0;
    }

    /// @notice Get list of suported tokens to buy with
    function getSupportedTokens() public view returns (address[] memory) {
        return supportedTokens;
    }

    function getSupportedTokensLength() public view returns (uint256 length) {
        length = supportedTokens.length;
    }

    ///----- * PRIVATE GREENHOUSE * -----///

    /// Swap tokens using a uniV2 protocol and router
    function _swapTokenToUsdc(address token, uint256 amount) internal returns (uint256 usdcValue) {
        if (amount == 0) {
            return 0;
        }

        uint256 usdcBalBefore = usdc.balanceOf(address(this));

        uint24 fees;

        if (pathToUsdc[token].length == 2) {
            /// If path to usdc is of length 2 -> single swap
            (, fees) = _uniswapV3PoolExists(token, address(usdc));
            IERC20(token).safeIncreaseAllowance(address(unirouter), amount);
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token,
                tokenOut: address(usdc),
                fee: fees,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            unirouter.exactInputSingle(params);
        } else if (pathToUsdc[token].length > 2) {
            /// If not -> multihop
            uint256 prevAmount = amount;
            for (uint256 i; i < pathToUsdc[token].length - 1; i++) {
                IERC20(pathToUsdc[token][i]).safeIncreaseAllowance(address(unirouter), prevAmount);
                (, fees) = _uniswapV3PoolExists(pathToUsdc[token][i], address(usdc));
                    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                    tokenIn: pathToUsdc[token][i],
                    tokenOut: pathToUsdc[token][i+1],
                    fee: fees,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: prevAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                prevAmount = unirouter.exactInputSingle(params);
            }
        }

        usdcValue = usdc.balanceOf(address(this)) - usdcBalBefore;
    }



    function _uniswapV3PoolExists(address _tokenIn, address _tokenOut) internal view returns (bool poolExists, uint24 poolFee) {
        /// Uniswap allows 3 different pool fees
        uint24 poolFee1 = 500;
        uint24 poolFee2 = 3000;
        uint24 poolFee3 = 10000;

        if (unifactory.getPool(_tokenIn, _tokenOut, poolFee1) != address(0)) {
            poolFee = poolFee1;
            poolExists = true;
        } else if (unifactory.getPool(_tokenIn, _tokenOut, poolFee2) != address(0)) {
            poolFee = poolFee2;
            poolExists = true;
        } else if (unifactory.getPool(_tokenIn, _tokenOut, poolFee3) != address(0)) {
            poolFee = poolFee3;
            poolExists = true;
        }
    }

    /// Returns user base weight + his bonus thanks to using an nft
    function _userTotalWeight(address user) internal view returns (uint256 userTotalWeight) {
        userTotalWeight = userShares[user].weight + userShares[user].bonusWeight;
    }

    ///----- * MINISTRY OF GRAINS * -----///

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external onlyOwner {
        if (block.timestamp <= lgeEnd) {
            revert GrainLGE__NotCompleted();
        }

        /// Fetch the tokens to guarantee the amount received
        grain.safeTransferFrom(msg.sender, address(this), grainAmount);
        totalGrain += grainAmount;

        gracePeriodOver = true;
    }

    /// @notice Add a token to the list of tokens that can be swapped, or update one's path
    function setPathToUsdc(address[] memory _path) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (_path[_path.length-1] != address(usdc)) {
            revert GrainLGE__WrongInput();
        }
        pathToUsdc[_path[0]] = _path;

        bool containsToken;
        for (uint256 i; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _path[0]) {
                containsToken = true;
            }
        }

        if (containsToken == false) {
            supportedTokens.push(_path[0]);
        }
    }

    /// @notice Set bonus to a nft collection
    /// @dev There is no limit to the bonus, please use responsibly (10000 = 100% and is like a x2 multiplier)
    function setWhitelistedBonus(address nft, uint256 pctBonus) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (pctBonus > 1e26) {
            revert GrainLGE__WrongInput();
        }
        whitelistedBonuses[nft] = pctBonus;
    }

    function setNativeTokenGateway(address gateway) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (gateway == address(0)) {
            revert GrainLGE__WrongInput();
        }

        nativeTokenGateway = gateway;
    }

    function setLgeEnd(uint256 timestamp) external onlyOwner {
        lgeEnd = timestamp;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWETHGateway.sol";
import "./interfaces/IGrainLGE.sol";

contract WETHGateway is IWETHGateway, Ownable {
  using SafeERC20 for IERC20;

  IWETH public immutable WETH;
  address public immutable grainLge;

  /**
   * @dev Sets the WETH address and the lge address and
   * grants max approval to lge contract
   * @param weth Address of the Wrapped Ether contract
   * @param _grainLge Address of the grain lge contract
   **/
  constructor(address weth, address _grainLge) {
    WETH = IWETH(weth);
    grainLge = _grainLge;
    WETH.approve(grainLge, type(uint256).max);
  }

  /**
   * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
   * is minted.
   * @param numberOfReleases how many trimesters of vesting for this user (0 -> 32)
   **/
  function depositETH(
    uint256 minUsdcAmountOut,
    uint256 numberOfReleases
  ) external payable override {
    WETH.deposit{value: msg.value}();
    IGrainLGE(grainLge).buy(address(WETH), msg.value, minUsdcAmountOut, numberOfReleases, msg.sender, address(0), 0);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  /**
   * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
   * direct transfers to the contract address.
   * @param token token to transfer
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyTokenTransfer(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).safeTransfer(to, amount);
  }

  /**
   * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
   * due selfdestructs or transfer ether to pre-computated contract address before deployment.
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyEtherTransfer(address to, uint256 amount) external onlyOwner {
    _safeTransferETH(to, amount);
  }

  /**
   * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    require(msg.sender == address(WETH), 'Receive not allowed');
  }

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert('Fallback not allowed');
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
interface IERC165 {
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