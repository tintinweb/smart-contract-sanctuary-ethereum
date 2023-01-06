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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Borrowing } from './LS1Borrowing.sol';
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @title LS1Admin
 * @author marginX
 *
 * @dev Admin-only functions.
 */
abstract contract LS1Admin is
  LS1Borrowing
{
  using SafeCast for uint256;
  using SafeMathUpgradeable for uint256;

  // ============ External Functions ============

  /**
   * @notice Set the parameters defining the function from timestamp to epoch number.
   *
   *  The formula used is `n = floor((t - b) / a)` where:
   *    - `n` is the epoch number
   *    - `t` is the timestamp (in seconds)
   *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
   *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
   *
   *  Reverts if epoch zero already started, and the new parameters would change the current epoch.
   *  Reverts if epoch zero has not started, but would have had started under the new parameters.
   *  Reverts if the new interval is less than twice the blackout window.
   *
   * @param  interval  The length `a` of an epoch, in seconds.
   * @param  offset    The offset `b`, i.e. the start of epoch zero, in seconds.
   */
  function setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    external
    onlyRole(EPOCH_PARAMETERS_ROLE)
    nonReentrant
  {
    if (!hasEpochZeroStarted()) {
      require(block.timestamp < offset, 'Started epoch 0');
      _setEpochParameters(interval, offset);
      return;
    }

    // Require that we are not currently in a blackout window.
    require(
      !inBlackoutWindow(),
      'B.O window'
    );

    // We must settle the total active balance to ensure the index is recorded at the epoch
    // boundary as needed, before we make any changes to the epoch formula.
    _settleTotalActiveBalance();

    // Update the epoch parameters. Require that the current epoch number is unchanged.
    uint256 originalCurrentEpoch = getCurrentEpoch();
    _setEpochParameters(interval, offset);
    uint256 newCurrentEpoch = getCurrentEpoch();
    require(originalCurrentEpoch == newCurrentEpoch, 'Changed epochs');

    // Require that the new parameters don't put us in a blackout window.
    require(!inBlackoutWindow(), 'End in B.O window');
  }

  /**
   * @notice Set the blackout window, during which one cannot request withdrawals of staked funds.
   */
  function setBlackoutWindow(
    uint256 blackoutWindow
  )
    external
    onlyRole(EPOCH_PARAMETERS_ROLE)
    nonReentrant
  {
    require(
      !inBlackoutWindow(),
      'Blackout window'
    );
    _setBlackoutWindow(blackoutWindow);

    // Require that the new parameters don't put us in a blackout window.
    require(!inBlackoutWindow(), 'End in B.O window');
  }

  /**
   * @notice Set the emission rate of rewards.
   *
   * @param  emissionPerSecond  The new number of rewards tokens given out per second.
   */
  function setRewardsPerSecond(
    uint256 emissionPerSecond
  )
    external
    onlyRole(REWARDS_RATE_ROLE)
    nonReentrant
  {
    uint256 totalStaked = 0;
    if (hasEpochZeroStarted()) {
      // We must settle the total active balance to ensure the index is recorded at the epoch
      // boundary as needed, before we make any changes to the emission rate.
      totalStaked = _settleTotalActiveBalance();
    }
    _setRewardsPerSecond(emissionPerSecond, totalStaked);
  }

  /**
   * @notice Change the allocations of certain borrowers. Can be used to add and remove borrowers.
   *  Increases take effect in the next epoch, but decreases will restrict borrowing immediately.
   *  This function cannot be called during the blackout window.
   *
   * @param  borrowers       Array of borrower addresses.
   * @param  newAllocations  Array of new allocations per borrower, as hundredths of a percent.
   */
  function setBorrowerAllocations(
    address[] calldata borrowers,
    uint256[] calldata newAllocations
  )
    external
    onlyRole(BORROWER_ADMIN_ROLE)
    nonReentrant
  {
    require(borrowers.length == newAllocations.length, 'Length mismatch');
    require(
      !inBlackoutWindow(),
      'B.O window'
    );
    _setBorrowerAllocations(borrowers, newAllocations);
  }

  function setBorrowingRestriction(
    address borrower,
    bool isBorrowingRestricted
  )
    external
    onlyRole(BORROWER_ADMIN_ROLE)
    nonReentrant
  {
    _setBorrowingRestriction(borrower, isBorrowingRestricted);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { LS1Types } from "../lib/LS1Types.sol";
import { SafeCast } from "../lib/SafeCast.sol";
import { LS1StakedBalances } from "./LS1StakedBalances.sol";

/**
 * @title LS1BorrowerAllocations
 * @author MarginX
 *
 * @dev Gives a set of addresses permission to withdraw staked funds.
 *
 *  The amount that can be withdrawn depends on a borrower's allocation percentage and the total
 *  available funds. Both the allocated percentage and total available funds can change, at
 *  predefined times specified by LS1EpochSchedule.
 *
 *  If a borrower's borrowed balance is greater than their allocation at the start of the next epoch
 *  then they are expected and trusted to return the difference before the start of that epoch.
 */
abstract contract LS1BorrowerAllocations is
  LS1StakedBalances
{
  using SafeCast for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  /// @notice The total units to be allocated.
  uint256 public constant TOTAL_ALLOCATION = 1e4;

  // ============ Events ============

  event ScheduledBorrowerAllocationChange(
    address indexed borrower,
    uint256 oldAllocation,
    uint256 newAllocation,
    uint256 epochNumber
  );

  event BorrowingRestrictionChanged(
    address indexed borrower,
    bool isBorrowingRestricted
  );

  // ============ Initializer ============

  function __LS1BorrowerAllocations_init()
    internal
  {
    _BORROWER_ALLOCATIONS_[address(0)] = LS1Types.StoredAllocation({
      currentEpoch: 0,
      currentEpochAllocation: TOTAL_ALLOCATION.toUint128(),
      nextEpochAllocation: TOTAL_ALLOCATION.toUint128()
    });
  }

  // ============ Public Functions ============

  /**
   * @notice Get the borrower allocation for the current epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The borrower's current allocation in hundreds of a percent.
   */
  function getAllocationFractionCurrentEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    return uint256(_loadBorrowerAllocation(borrower).currentEpochAllocation);
  }

  /**
   * @notice Get the borrower allocation for the next epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The borrower's next allocation in hundreds of a percent.
   */
  function getAllocationFractionNextEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    return uint256(_loadBorrowerAllocation(borrower).nextEpochAllocation);
  }

  /**
   * @notice Get the allocated borrowable token balance of a borrower for the current epoch.
   *
   *  This is the amount which a borrower can be penalized for exceeding.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The token amount allocated to the borrower for the current epoch.
   */
  function getAllocatedBalanceCurrentEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    uint256 allocation = getAllocationFractionCurrentEpoch(borrower);
    uint256 availableTokens = getTotalActiveBalanceCurrentEpoch();
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  /**
   * @notice Preview the allocated balance of a borrower for the next epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The anticipated token amount allocated to the borrower for the next epoch.
   */
  function getAllocatedBalanceNextEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    uint256 allocation = getAllocationFractionNextEpoch(borrower);
    uint256 availableTokens = getTotalActiveBalanceNextEpoch();
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  // ============ Internal Functions ============

  /**
   * @dev Change the allocations of certain borrowers.
   */
  function _setBorrowerAllocations(
    address[] calldata borrowers,
    uint256[] calldata newAllocations
  )
    internal
  {
    // These must net out so that the total allocation is unchanged.
    uint256 oldAllocationSum = 0;
    uint256 newAllocationSum = 0;

    for (uint256 i = 0; i < borrowers.length; i++) {
      address borrower = borrowers[i];
      uint256 newAllocation = newAllocations[i];

      // Get the old allocation.
      LS1Types.StoredAllocation memory allocationStruct = _loadBorrowerAllocation(borrower);
      uint256 oldAllocation = uint256(allocationStruct.currentEpochAllocation);

      // Update the borrower's next allocation.
      allocationStruct.nextEpochAllocation = newAllocation.toUint128();

      // If epoch zero hasn't started, update current allocation as well.
      uint256 epochNumber = 0;
      if (hasEpochZeroStarted()) {
        epochNumber = uint256(allocationStruct.currentEpoch).add(1);
      } else {
        allocationStruct.currentEpochAllocation = newAllocation.toUint128();
      }

      // Commit the new allocation.
      _BORROWER_ALLOCATIONS_[borrower] = allocationStruct;
      emit ScheduledBorrowerAllocationChange(borrower, oldAllocation, newAllocation, epochNumber);

      // Record totals.
      oldAllocationSum = oldAllocationSum.add(oldAllocation);
      newAllocationSum = newAllocationSum.add(newAllocation);
    }

    // Require the total allocated units to be unchanged.
    require(
      oldAllocationSum == newAllocationSum,
      'Invalid'
    );
  }

 /**
   * @dev Restrict a borrower from further borrowing.
   */
  function _setBorrowingRestriction(
    address borrower,
    bool isBorrowingRestricted
  )
    internal
  {
    bool oldIsBorrowingRestricted = _BORROWER_RESTRICTIONS_[borrower];
    if (oldIsBorrowingRestricted != isBorrowingRestricted) {
      _BORROWER_RESTRICTIONS_[borrower] = isBorrowingRestricted;
      emit BorrowingRestrictionChanged(borrower, isBorrowingRestricted);
    }
  }

  /**
   * @dev Get the allocated balance that the borrower can make use of for new borrowing.
   *
   * @return The amount that the borrower can borrow up to.
   */
  function _getAllocatedBalanceForNewBorrowing(
    address borrower
  )
    internal
    view
    returns (uint256)
  {
    // Use the smaller of the current and next allocation fractions, since if a borrower's
    // allocation was just decreased, we should take that into account in limiting new borrows.
    uint256 currentAllocation = getAllocationFractionCurrentEpoch(borrower);
    uint256 nextAllocation = getAllocationFractionNextEpoch(borrower);
    uint256 allocation = MathUpgradeable.min(currentAllocation, nextAllocation);

    // If we are in the blackout window, use the next active balance. Otherwise, use current.
    // Note that the next active balance is never greater than the current active balance.
    uint256 availableTokens;
    if (inBlackoutWindow()) {
      availableTokens = getTotalActiveBalanceNextEpoch();
    } else {
      availableTokens = getTotalActiveBalanceCurrentEpoch();
    }
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  // ============ Private Functions ============

  function _loadBorrowerAllocation(
    address borrower
  )
    private
    view
    returns (LS1Types.StoredAllocation memory)
  {
    LS1Types.StoredAllocation memory allocation = _BORROWER_ALLOCATIONS_[borrower];

    // Ignore rollover logic before epoch zero.
    if (hasEpochZeroStarted()) {
      uint256 currentEpoch = getCurrentEpoch();
      if (currentEpoch > uint256(allocation.currentEpoch)) {
        // Roll the allocation forward.
        allocation.currentEpoch = currentEpoch.toUint16();
        allocation.currentEpochAllocation = allocation.nextEpochAllocation;
      }
    }

    return allocation;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {LS1Types} from "../lib/LS1Types.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {LS1BorrowerAllocations} from "./LS1BorrowerAllocations.sol";
import {LS1Staking} from "./LS1Staking.sol";

/**
 * @title LS1Borrowing
 * @author MarginX
 *
 * @dev External functions for borrowers. See LS1BorrowerAllocations for details on
 *  borrower accounting.
 */
abstract contract LS1Borrowing is LS1Staking, LS1BorrowerAllocations {
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // ============ Events ============

    event Borrowed(
        address indexed borrower,
        uint256 amount,
        uint256 newBorrowedBalance
    );

    event RepaidBorrow(
        address indexed borrower,
        address sender,
        uint256 amount,
        uint256 newBorrowedBalance
    );

    event RepaidDebt(
        address indexed borrower,
        address sender,
        uint256 amount,
        uint256 newDebtBalance
    );

    // ============ External Functions ============

    /**
     * @notice Borrow staked funds.
     *
     * @param  amount  The token amount to borrow.
     */
    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot borrow 0");

        address borrower = msg.sender;

        // Revert if the borrower is restricted.
        require(!_BORROWER_RESTRICTIONS_[borrower], "Restricted");

        // Get contract available amount and revert if there is not enough to withdraw.
        uint256 totalAvailableForBorrow = getContractBalanceAvailableToBorrow();
        require(
            amount <= totalAvailableForBorrow,
            "Amount > available"
        );

        // Get new net borrow and revert if it is greater than the allocated balance for new borrowing.
        uint256 newBorrowedBalance = _BORROWED_BALANCES_[borrower].add(amount);
        require(
            newBorrowedBalance <= _getAllocatedBalanceForNewBorrowing(borrower),
            "Amount > allocated"
        );

        // Update storage.
        _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
        _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.add(amount);

        // Transfer token to the Market maker Proxy contract.
        STAKED_TOKEN.safeTransfer(borrower, amount);

        emit Borrowed(borrower, amount, newBorrowedBalance);
    }

    /**
     * @notice Repay borrowed funds for the specified borrower. Reverts if repay amount exceeds
     *  borrowed amount.
     *
     * @param  borrower  The borrower on whose behalf to make a repayment.
     * @param  amount    The amount to repay.
     */
    function repayBorrow(address borrower, uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot repay 0");

        uint256 oldBorrowedBalance = _BORROWED_BALANCES_[borrower];
        require(amount <= oldBorrowedBalance, "Repay > borrowed");
        uint256 newBorrowedBalance = oldBorrowedBalance.sub(amount);

        // Update storage.
        _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
        _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.sub(amount);

        // Transfer token from the sender.
        STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit RepaidBorrow(borrower, msg.sender, amount, newBorrowedBalance);
    }

    /**
     * @notice Repay a debt amount owed by a borrower.
     *
     * @param  borrower  The borrower whose debt to repay.
     * @param  amount    The amount to repay.
     */
    function repayDebt(address borrower, uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot repay 0");

        uint256 oldDebtAmount = _BORROWER_DEBT_BALANCES_[borrower];
        require(amount <= oldDebtAmount, "Repay > debt");
        uint256 newDebtBalance = oldDebtAmount.sub(amount);

        // Update storage.
        _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
        _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.sub(
            amount
        );
        _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_ = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_
            .add(amount);

        // Transfer token from the sender.
        STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit RepaidDebt(borrower, msg.sender, amount, newDebtBalance);
    }

    /**
     * @notice Get the max additional amount that the borrower can borrow.
     *
     * @return The max additional amount that the borrower can borrow right now.
     */
    function getBorrowableAmount(address borrower)
        external
        view
        returns (uint256)
    {
        if (
            _BORROWER_RESTRICTIONS_[borrower]
        ) {
            return 0;
        }

        // Get the remaining unused allocation for the borrower.
        uint256 oldBorrowedBalance = _BORROWED_BALANCES_[borrower];
        uint256 borrowerAllocatedBalance = _getAllocatedBalanceForNewBorrowing(
            borrower
        );
        if (borrowerAllocatedBalance <= oldBorrowedBalance) {
            return 0;
        }
        uint256 borrowerRemainingAllocatedBalance = borrowerAllocatedBalance
            .sub(oldBorrowedBalance);

        // Don't allow new borrowing to take out funds that are reserved for debt or inactive balances.
        // Typically, this will not be the limiting factor, but it can be.
        uint256 totalAvailableForBorrow = getContractBalanceAvailableToBorrow();

        return
            MathUpgradeable.min(
                borrowerRemainingAllocatedBalance,
                totalAvailableForBorrow
            );
    }

    // ============ Public Functions ============

    /**
     * @notice Get the funds currently available in the contract for borrowing.
     *
     * @return The amount of non-debt, non-inactive funds in the contract.
     */
    function getContractBalanceAvailableToBorrow()
        public
        view
        returns (uint256)
    {
        uint256 availableStake = getContractBalanceAvailableToWithdraw();
        uint256 inactiveBalance = getTotalInactiveBalanceCurrentEpoch();
        // Note: The funds available to withdraw may be less than the inactive balance.
        if (availableStake <= inactiveBalance) {
            return 0;
        }
        return availableStake.sub(inactiveBalance);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1BorrowerAllocations } from './LS1BorrowerAllocations.sol';

/**
 * @title LS1DebtAccounting
 * @author MarginX
 *
 * @dev Allows converting an overdue balance into "debt", which is accounted for separately from
 *  the staked and borrowed balances. This allows the system to rebalance/restabilize itself in the
 *  case where a borrower fails to return borrowed funds on time.
 *
 *  The shortfall debt calculation is as follows:
 *
 *    - Let A be the total active balance.
 *    - Let B be the total borrowed balance.
 *    - Let X be the total inactive balance.
 *    - Then, a shortfall occurs if at any point B > A.
 *    - The shortfall debt amount is `D = B - A`
 *    - The borrowed balances are decreased by `B_new = B - D`
 *    - The inactive balances are decreased by `X_new = X - D`
 *    - The shortfall index is recorded as `Y = X_new / X`
 *    - The borrower and staker debt balances are increased by `D`
 *
 *  Note that `A + X >= B` (The active and inactive balances are at least the borrowed balance.)
 *  This implies that `X >= D` (The inactive balance is always at least the shortfall debt.)
 */
abstract contract LS1DebtAccounting is
  LS1BorrowerAllocations
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;
  using MathUpgradeable for uint256;

  // ============ Events ============

  event ConvertedInactiveBalancesToDebt(
    uint256 shortfallAmount,
    uint256 shortfallIndex,
    uint256 newInactiveBalance
  );

  event DebtMarked(
    address indexed borrower,
    uint256 amount,
    uint256 newBorrowedBalance,
    uint256 newDebtBalance
  );

  // ============ External Functions ============

  /**
   * @notice Restrict a borrower from borrowing. The borrower must have exceeded their borrowing
   *  allocation. Can be called by anyone.
   *
   *  Unlike markDebt(), this function can be called even if the contract in TOTAL is not insolvent.
   */
  function restrictBorrower(
    address borrower
  )
    external
    nonReentrant
  {
    require(
      isBorrowerOverdue(borrower),
      'Borrower !overdue'
    );
    _setBorrowingRestriction(borrower, true);
  }

  /**
   * @notice Convert the shortfall amount between the active and borrowed balances into “debt.”
   *
   *  The function determines the size of the debt, and then does the following:
   *   - Assign the debt to borrowers, taking the same amount out of their borrowed balance.
   *   - Impose borrow restrictions on borrowers to whom the debt was assigned.
   *   - Socialize the loss pro-rata across inactive balances. Each balance with a loss receives
   *     an equal amount of debt balance that can be withdrawn as debts are repaid.
   *
   * @param  borrowers  A list of borrowers who are responsible for the full shortfall amount.
   *
   * @return The shortfall debt amount.
   */
  function markDebt(
    address[] calldata borrowers
  )
    external
    nonReentrant
    returns (uint256)
  {
    // The debt is equal to the difference between the total active and total borrowed balances.
    uint256 totalActiveCurrent = getTotalActiveBalanceCurrentEpoch();
    uint256 totalBorrowed = _TOTAL_BORROWED_BALANCE_;
    require(totalBorrowed > totalActiveCurrent, 'No shortfall');
    uint256 shortfallDebt = totalBorrowed.sub(totalActiveCurrent);

    // Attribute debt to borrowers.
    _attributeDebtToBorrowers(shortfallDebt, totalActiveCurrent, borrowers);

    // Apply the debt to inactive balances, moving the same amount into users debt balances.
    _convertInactiveBalanceToDebt(shortfallDebt);

    return shortfallDebt;
  }

  // ============ Public Functions ============

  /**
   * @notice Whether the borrower is overdue on a payment, and is currently subject to having their
   *  borrowing rights revoked.
   *
   * @param  borrower  The borrower to check.
   */
  function isBorrowerOverdue(
    address borrower
  )
    public
    view
    returns (bool)
  {
    uint256 allocatedBalance = getAllocatedBalanceCurrentEpoch(borrower);
    uint256 borrowedBalance = _BORROWED_BALANCES_[borrower];
    return borrowedBalance > allocatedBalance;
  }

  // ============ Private Functions ============

  /**
   * @dev Helper function to partially or fully convert inactive balances to debt.
   *
   * @param  shortfallDebt  The shortfall amount: borrowed balances less active balances.
   */
  function _convertInactiveBalanceToDebt(
    uint256 shortfallDebt
  )
    private
  {
    // Get the total inactive balance.
    uint256 oldInactiveBalance = getTotalInactiveBalanceCurrentEpoch();

    // Calculate the index factor for the shortfall.
    uint256 newInactiveBalance = 0;
    uint256 shortfallIndex = 0;
    if (oldInactiveBalance > shortfallDebt) {
      newInactiveBalance = oldInactiveBalance.sub(shortfallDebt);
      shortfallIndex = SHORTFALL_INDEX_BASE.mul(newInactiveBalance).div(oldInactiveBalance);
    }

    // Get the shortfall amount applied to inactive balances.
    uint256 shortfallAmount = oldInactiveBalance.sub(newInactiveBalance);

    // Apply the loss. This moves the debt from stakers' inactive balances to their debt balances.
    _applyShortfall(shortfallAmount, shortfallIndex);
    emit ConvertedInactiveBalancesToDebt(shortfallAmount, shortfallIndex, newInactiveBalance);
  }

  /**
   * @dev Helper function to attribute debt to borrowers, adding it to their debt balances.
   *
   * @param  shortfallDebt       The shortfall amount: borrowed balances less active balances.
   * @param  totalActiveCurrent  The total active balance for the current epoch.
   * @param  borrowers           A list of borrowers responsible for the full shortfall amount.
   */
  function _attributeDebtToBorrowers(
    uint256 shortfallDebt,
    uint256 totalActiveCurrent,
    address[] calldata borrowers
  ) private {
    // Find borrowers to attribute the total debt amount to. The sum of all borrower shortfalls is
    // always at least equal to the overall shortfall, so it is always possible to specify a list
    // of borrowers whose excess borrows cover the full shortfall amount.
    //
    // Denominate values in “points” scaled by TOTAL_ALLOCATION to avoid rounding.
    uint256 debtToBeAttributedPoints = shortfallDebt.mul(TOTAL_ALLOCATION);
    uint256 shortfallDebtAfterRounding = 0;
    for (uint256 i = 0; i < borrowers.length; i++) {
      address borrower = borrowers[i];
      uint256 borrowedBalanceTokenAmount = _BORROWED_BALANCES_[borrower];
      uint256 borrowedBalancePoints = borrowedBalanceTokenAmount.mul(TOTAL_ALLOCATION);
      uint256 allocationPoints = getAllocationFractionCurrentEpoch(borrower);
      uint256 allocatedBalancePoints = totalActiveCurrent.mul(allocationPoints);

      // Skip this borrower if they have not exceeded their allocation.
      if (borrowedBalancePoints <= allocatedBalancePoints) {
        continue;
      }

      // Calculate the borrower's debt, and limit to the remaining amount to be allocated.
      uint256 borrowerDebtPoints = borrowedBalancePoints.sub(allocatedBalancePoints);
      borrowerDebtPoints = MathUpgradeable.min(borrowerDebtPoints, debtToBeAttributedPoints);

      // Move the debt from the borrowers' borrowed balance to the debt balance. Rounding may occur
      // when converting from “points” to tokens. We round up to ensure the final borrowed balance
      // is not greater than the allocated balance.
      uint256 borrowerDebtTokenAmount = borrowerDebtPoints.ceilDiv(TOTAL_ALLOCATION);
      uint256 newDebtBalance = _BORROWER_DEBT_BALANCES_[borrower].add(borrowerDebtTokenAmount);
      uint256 newBorrowedBalance = borrowedBalanceTokenAmount.sub(borrowerDebtTokenAmount);
      _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
      _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
      emit DebtMarked(borrower, borrowerDebtTokenAmount, newBorrowedBalance, newDebtBalance);
      shortfallDebtAfterRounding = shortfallDebtAfterRounding.add(borrowerDebtTokenAmount);

      // Restrict the borrower from further borrowing.
      _setBorrowingRestriction(borrower, true);

      // Update the remaining amount to allocate.
      debtToBeAttributedPoints = debtToBeAttributedPoints.sub(borrowerDebtPoints);

      // Exit early if all debt was allocated.
      if (debtToBeAttributedPoints == 0) {
        break;
      }
    }

    // Require the borrowers to cover the full debt amount. This should always be possible.
    require(
      debtToBeAttributedPoints == 0,
      'Do not cover the shortfall'
    );

    // Move the debt from the total borrowed balance to the total debt balance.
    _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.sub(shortfallDebtAfterRounding);
    _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.add(shortfallDebtAfterRounding);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Roles } from './LS1Roles.sol';


/**
 * @title LS1EpochSchedule
 * @author MarginX
 *
 * @dev Defines a function from block timestamp to epoch number.
 *
 *  The formula used is `n = floor((t - b) / a)` where:
 *    - `n` is the epoch number
 *    - `t` is the timestamp (in seconds)
 *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
 *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
 *
 *  Note that by restricting `b` to be non-negative, we limit ourselves to functions in which epoch
 *  zero starts at a non-negative timestamp.
 *
 *  The recommended epoch length and blackout window are 28 and 7 days respectively; however, these
 *  are modifiable by the admin, within the specified bounds.
 */
abstract contract LS1EpochSchedule is
  LS1Roles
{
  using SafeCast for uint256;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  /// @dev Minimum blackout window. Note: The min epoch length is twice the current blackout window.
  //uint256 private constant MIN_BLACKOUT_WINDOW = 3 days;
  uint256 private constant MIN_BLACKOUT_WINDOW = 1 minutes;

  /// @dev Maximum epoch length. Note: The max blackout window is half the current epoch length.
  uint256 private constant MAX_EPOCH_LENGTH = 92 days; // Approximately one quarter year.

  // ============ Events ============

  event EpochParametersChanged(
    LS1Types.EpochParameters epochParameters
  );

  event BlackoutWindowChanged(
    uint256 blackoutWindow
  );

  // ============ Initializer ============

  function __LS1EpochSchedule_init(
    uint256 interval,
    uint256 offset,
    uint256 blackoutWindow
  )
    internal
  {
    require(
      block.timestamp < offset,
      'Epoch zero must be in future'
    );

    // Don't use _setBlackoutWindow() since the interval is not set yet and validation would fail.
    _BLACKOUT_WINDOW_ = blackoutWindow;
    emit BlackoutWindowChanged(blackoutWindow);

    _setEpochParameters(interval, offset);
  }

  // ============ Public Functions ============

  /**
   * @notice Get the epoch at the current block timestamp.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The current epoch number.
   */
  function getCurrentEpoch()
    public
    view
    returns (uint256)
  {
    (uint256 interval, uint256 offsetTimestamp) = _getIntervalAndOffsetTimestamp();
    return offsetTimestamp.div(interval);
  }

  /**
   * @notice Get the time remaining in the current epoch.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The number of seconds until the next epoch.
   */
  function getTimeRemainingInCurrentEpoch()
    public
    view
    returns (uint256)
  {
    (uint256 interval, uint256 offsetTimestamp) = _getIntervalAndOffsetTimestamp();
    uint256 timeElapsedInEpoch = offsetTimestamp.mod(interval);
    return interval.sub(timeElapsedInEpoch);
  }

  /**
   * @notice Given an epoch number, get the start of that epoch. Calculated as `t = (n * a) + b`.
   *
   * @return The timestamp in seconds representing the start of that epoch.
   */
  function getStartOfEpoch(
    uint256 epochNumber
  )
    public
    view
    returns (uint256)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);
    return epochNumber.mul(interval).add(offset);
  }

  /**
   * @notice Check whether we are at or past the start of epoch zero.
   *
   * @return Boolean `true` if the current timestamp is at least the start of epoch zero,
   *  otherwise `false`.
   */
  function hasEpochZeroStarted()
    public
    view
    returns (bool)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 offset = uint256(epochParameters.offset);
    return block.timestamp >= offset;
  }

  /**
   * @notice Check whether we are in a blackout window, where withdrawal requests are restricted.
   *  Note that before epoch zero has started, there are no blackout windows.
   *
   * @return Boolean `true` if we are in a blackout window, otherwise `false`.
   */
  function inBlackoutWindow()
    public
    view
    returns (bool)
  {
    return hasEpochZeroStarted() && getTimeRemainingInCurrentEpoch() <= _BLACKOUT_WINDOW_;
  }

  // ============ Internal Functions ============

  function _setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    internal
  {
    _validateParamLengths(interval, _BLACKOUT_WINDOW_);
    LS1Types.EpochParameters memory epochParameters =
      LS1Types.EpochParameters({interval: interval.toUint128(), offset: offset.toUint128()});
    _EPOCH_PARAMETERS_ = epochParameters;
    emit EpochParametersChanged(epochParameters);
  }

  function _setBlackoutWindow(
    uint256 blackoutWindow
  )
    internal
  {
    _validateParamLengths(uint256(_EPOCH_PARAMETERS_.interval), blackoutWindow);
    _BLACKOUT_WINDOW_ = blackoutWindow;
    emit BlackoutWindowChanged(blackoutWindow);
  }

  // ============ Private Functions ============

  /**
   * @dev Helper function to read params from storage and apply offset to the given timestamp.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The length of an epoch, in seconds.
   * @return The start of epoch zero, in seconds.
   */
  function _getIntervalAndOffsetTimestamp()
    private
    view
    returns (uint256, uint256)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);

    require(block.timestamp >= offset, 'Epoch 0 has not started');

    uint256 offsetTimestamp = block.timestamp.sub(offset);
    return (interval, offsetTimestamp);
  }

  /**
   * @dev Helper for common validation: verify that the interval and window lengths are valid.
   */
  function _validateParamLengths(
    uint256 interval,
    uint256 blackoutWindow
  )
    private
    pure
  {
    require(
      blackoutWindow.mul(2) <= interval,
      'Blackout window can be at most half the epoch length'
    );
    require(
      blackoutWindow >= MIN_BLACKOUT_WINDOW,
      'Blackout window too large'
    );
    require(
      interval <= MAX_EPOCH_LENGTH,
      'Epoch length too small'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { LS1Types } from '../lib/LS1Types.sol';
import { LS1StakedBalances } from './LS1StakedBalances.sol';
import { SafeMathUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import { IERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

/**
 * @title LS1ERC20
 * @author MarginX
 *
 * @dev ERC20 interface for staked tokens. Allows a user with an active stake to transfer their
 *  staked tokens to another user, even if they would otherwise be restricted from withdrawing.
 */
abstract contract LS1ERC20 is
IERC20Upgradeable,
  LS1StakedBalances
{
  using SafeMathUpgradeable for uint256;

  // ============ External Functions ============

  function name()
    external
    pure
    returns (string memory)
  {
    return 'MarginX Staked USDT';
  }

  function symbol()
    external
    pure
    returns (string memory)
  {
    return 'stkXUSDT';
  }

  function decimals()
    external
    pure
    returns (uint8)
  {
    return 6;
  }

  /**
   * @notice Get the total supply of `STAKED_TOKEN` staked to the contract.
   *  This value is calculated from adding the active + inactive balances of
   *  this current epoch.
   *
   * @return The total staked balance of this contract.
   */
  function totalSupply()
    external
    view
    override
    returns (uint256)
  {
    return getTotalActiveBalanceCurrentEpoch() + getTotalInactiveBalanceCurrentEpoch();
  }

  /**
   * @notice Get the current balance of `STAKED_TOKEN` the user has staked to the contract.
   *  This value includes the users active + inactive balances, but note that only
   *  their active balance in the next epoch is transferable.
   *
   * @param  account  The account to get the balance of.
   *
   * @return The user's balance.
   */
  function balanceOf(
    address account
  )
    external
    view
    override
    returns (uint256)
  {
    return getActiveBalanceCurrentEpoch(account) + getInactiveBalanceCurrentEpoch(account);
  }

  function transfer(
    address recipient,
    uint256 amount
  )
    external
    override
    nonReentrant
    returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  )
    external
    view
    override
    returns (uint256)
  {
    return _ALLOWANCES_[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  )
    external
    override
    nonReentrant
    returns (bool)
  {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _ALLOWANCES_[sender][msg.sender].sub(amount)
    );
    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    external
    returns (bool)
  {
    _approve(msg.sender, spender, _ALLOWANCES_[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    external
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _ALLOWANCES_[msg.sender][spender].sub(
        subtractedValue
      )
    );
    return true;
  }

  // ============ Internal Functions ============

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  )
    internal
  {
    require(sender != address(0), 'Transfer from address(0)');
    require(recipient != address(0), 'Transfer to address(0)');
    require(
      getTransferableBalance(sender) >= amount,
      'Transfer exceeds next epoch active balance'
    );

    _transferCurrentAndNextActiveBalance(sender, recipient, amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  )
    internal
  {
    require(owner != address(0), 'Approve from address(0)');
    require(spender != address(0), 'Approve to address(0)');

    _ALLOWANCES_[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1Storage } from './LS1Storage.sol';

/**
 * @title LS1Getters
 * @author MarginX
 *
 * @dev Some external getter functions.
 */
abstract contract LS1Getters is
  LS1Storage
{
  using SafeMathUpgradeable for uint256;

  // ============ External Functions ============

  /**
   * @notice The token balance currently borrowed by the borrower.
   *
   * @param  borrower  The borrower whose balance to query.
   *
   * @return The number of tokens borrowed.
   */
  function getBorrowedBalance(
    address borrower
  )
    external
    view
    returns (uint256)
  {
    return _BORROWED_BALANCES_[borrower];
  }

  /**
   * @notice The total token balance borrowed by borrowers.
   *
   * @return The number of tokens borrowed.
   */
  function getTotalBorrowedBalance()
    external
    view
    returns (uint256)
  {
    return _TOTAL_BORROWED_BALANCE_;
  }

  /**
   * @notice The debt balance owed by the borrower.
   *
   * @param  borrower  The borrower whose balance to query.
   *
   * @return The number of tokens owed.
   */
  function getBorrowerDebtBalance(
    address borrower
  )
    external
    view
    returns (uint256)
  {
    return _BORROWER_DEBT_BALANCES_[borrower];
  }

  /**
   * @notice The total debt balance owed by borrowers.
   *
   * @return The number of tokens owed.
   */
  function getTotalBorrowerDebtBalance()
    external
    view
    returns (uint256)
  {
    return _TOTAL_BORROWER_DEBT_BALANCE_;
  }

  /**
   * @notice The total debt repaid by borrowers and available for stakers to withdraw.
   *
   * @return The number of tokens available.
   */
  // function getTotalDebtAvailableToWithdraw()
  //   external
  //   view
  //   returns (uint256)
  // {
  //   return _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
  // }

  /**
   * @notice Check whether a borrower is restricted from new borrowing.
   *
   * @param  borrower  The borrower to check.
   *
   * @return Boolean `true` if the borrower is restricted, otherwise `false`.
   */
  function isBorrowingRestrictedForBorrower(
    address borrower
  )
    external
    view
    returns (bool)
  {
    return _BORROWER_RESTRICTIONS_[borrower];
  }

  /**
   * @notice The parameters specifying the function from timestamp to epoch number.
   *
   * @return The parameters struct with `interval` and `offset` fields.
   */
  // function getEpochParameters()
  //   external
  //   view
  //   returns (LS1Types.EpochParameters memory)
  // {
  //   return _EPOCH_PARAMETERS_;
  // }

  /**
   * @notice The period of time at the end of each epoch in which withdrawals cannot be requested.
   *
   *  Other changes which could affect borrowers' repayment plans are also restricted during
   *  this period.
   */
  // function getBlackoutWindow()
  //   external
  //   view
  //   returns (uint256)
  // {
  //   return _BLACKOUT_WINDOW_;
  // }

  /**
   * @notice Get information about a shortfall that occurred.
   *
   * @param  shortfallCounter  The array index for the shortfall event to look up.
   *
   * @return Struct containing the epoch and shortfall index value.
   */
  // function getShortfall(
  //   uint256 shortfallCounter
  // )
  //   external
  //   view
  //   returns (LS1Types.Shortfall memory)
  // {
  //   return _SHORTFALLS_[shortfallCounter];
  // }

  /**
   * @notice Get the number of shortfalls that have occurred.
   *
   * @return The number of shortfalls that have occurred.
   */
  // function getShortfallCount()
  //   external
  //   view
  //   returns (uint256)
  // {
  //   return _SHORTFALLS_.length;
  // }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import { LS1Staking } from './LS1Staking.sol';

/**
 * @title LS1Operators
 * @author MarginX
 *
 * @dev Actions which may be called by authorized operators, nominated by the contract owner.
 *
 *  There are three types of operators. These should be smart contracts, which can be used to
 *  provide additional functionality to users:
 *
 *  STAKE_OPERATOR_ROLE:
 *
 *    This operator is allowed to request withdrawals and withdraw funds on behalf of stakers. This
 *    role could be used by a smart contract to provide a staking interface with additional
 *    features, for example, optional lock-up periods that pay out additional rewards (from a
 *    separate rewards pool).
 *
 *  CLAIM_OPERATOR_ROLE:
 *
 *    This operator is allowed to claim rewards on behalf of stakers. This role could be used by a
 *    smart contract to provide an interface for claiming rewards from multiple incentive programs
 *    at once.
 *
 *  DEBT_OPERATOR_ROLE:
 *
 *    This operator is allowed to decrease staker and borrower debt balances. Typically, each change
 *    to a staker debt balance should be offset by a corresponding change in a borrower debt
 *    balance, but this is not strictly required. This role could used by a smart contract to
 *    tokenize debt balances or to provide a pro-rata distribution to debt holders, for example.
 */
abstract contract LS1Operators is
  LS1Staking
{
  using SafeMathUpgradeable for uint256;

  // ============ Events ============

  event OperatorStakedFor(
    address indexed staker,
    uint256 amount,
    address operator
  );

  event OperatorWithdrawalRequestedFor(
    address indexed staker,
    uint256 amount,
    address operator
  );

  event OperatorWithdrewStakeFor(
    address indexed staker,
    address recipient,
    uint256 amount,
    address operator
  );

  event OperatorClaimedRewardsFor(
    address indexed staker,
    address recipient,
    uint256 claimedRewards,
    address operator
  );

  event OperatorDecreasedStakerDebt(
    address indexed staker,
    uint256 amount,
    uint256 newDebtBalance,
    address operator
  );

  event OperatorDecreasedBorrowerDebt(
    address indexed borrower,
    uint256 amount,
    uint256 newDebtBalance,
    address operator
  );

  // ============ External Functions ============

  /**
   * @notice Request a withdrawal on behalf of a staker.
   *
   *  Reverts if we are currently in the blackout window.
   *
   * @param  staker  The staker whose stake to request a withdrawal for.
   * @param  amount  The amount to move from the active to the inactive balance.
   */
  function requestWithdrawalFor(
    address staker,
    uint256 amount
  )
    external
    onlyRole(STAKE_OPERATOR_ROLE)
    nonReentrant
  {
    _requestWithdrawal(staker, amount);
    emit OperatorWithdrawalRequestedFor(staker, amount, msg.sender);
  }

  /**
   * @notice Withdraw a staker's stake, and send to the specified recipient.
   *
   * @param  staker     The staker whose stake to withdraw.
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The amount to withdraw from the staker's inactive balance.
   */
  function withdrawStakeFor(
    address staker,
    address recipient,
    uint256 amount
  )
    external
    onlyRole(STAKE_OPERATOR_ROLE)
    nonReentrant
  {
    _withdrawStake(staker, recipient, amount);
    emit OperatorWithdrewStakeFor(staker, recipient, amount, msg.sender);
  }

  /**
   * @notice Claim rewards on behalf of a staker, and send them to the specified recipient.
   *
   * @param  staker     The staker whose rewards to claim.
   * @param  recipient  The address that should receive the funds.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewardsFor(
    address staker,
    address recipient
  )
    external
    onlyRole(CLAIM_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 rewards = _settleAndClaimRewards(staker, recipient); // Emits an event internally.
    emit OperatorClaimedRewardsFor(staker, recipient, rewards, msg.sender);
    return rewards;
  }

  /**
   * @notice Decreased the balance recording debt owed to a staker.
   *
   * @param  staker  The staker whose balance to decrease.
   * @param  amount  The amount to decrease the balance by.
   *
   * @return The new debt balance.
   */
  function decreaseStakerDebt(
    address staker,
    uint256 amount
  )
    external
    onlyRole(DEBT_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 oldDebtBalance = _settleStakerDebtBalance(staker);
    uint256 newDebtBalance = oldDebtBalance.sub(amount);
    _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
    emit OperatorDecreasedStakerDebt(staker, amount, newDebtBalance, msg.sender);
    return newDebtBalance;
  }

  /**
   * @notice Decreased the balance recording debt owed by a borrower.
   *
   * @param  borrower  The borrower whose balance to decrease.
   * @param  amount    The amount to decrease the balance by.
   *
   * @return The new debt balance.
   */
  function decreaseBorrowerDebt(
    address borrower,
    uint256 amount
  )
    external
    onlyRole(DEBT_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 newDebtBalance = _BORROWER_DEBT_BALANCES_[borrower].sub(amount);
    _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
    _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.sub(amount);
    emit OperatorDecreasedBorrowerDebt(borrower, amount, newDebtBalance, msg.sender);
    return newDebtBalance;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeCast } from "../lib/SafeCast.sol";
import { LS1EpochSchedule } from "./LS1EpochSchedule.sol";
import { LS1Types } from '../lib/LS1Types.sol';

/**
 * @title LS1Rewards
 * @author MarginX
 *
 * @dev Manages the distribution of token rewards.
 *
 *  Rewards are distributed continuously. After each second, an account earns rewards `r` according
 *  to the following formula:
 *
 *      r = R * s / S
 *
 *  Where:
 *    - `R` is the rewards distributed globally each second, also called the “emission rate.”
 *    - `s` is the account's staked balance in that second (technically, it is measured at the
 *      end of the second)
 *    - `S` is the sum total of all staked balances in that second (again, measured at the end of
 *      the second)
 *
 *  The parameter `R` can be configured by the contract owner. For every second that elapses,
 *  exactly `R` tokens will accrue to users, save for rounding errors, and with the exception that
 *  while the total staked balance is zero, no tokens will accrue to anyone.
 *
 *  The accounting works as follows: A global index is stored which represents the cumulative
 *  number of rewards tokens earned per staked token since the start of the distribution.
 *  The value of this index increases over time, and there are two factors affecting the rate of
 *  increase:
 *    1) The emission rate (in the numerator)
 *    2) The total number of staked tokens (in the denominator)
 *
 *  Whenever either factor changes, in some timestamp T, we settle the global index up to T by
 *  calculating the increase in the index since the last update using the OLD values of the factors:
 *
 *    indexDelta = timeDelta * emissionPerSecond * INDEX_BASE / totalStaked
 *
 *  Where `INDEX_BASE` is a scaling factor used to allow more precision in the storage of the index.
 *
 *  For each user we store an accrued rewards balance, as well as a user index, which is a cache of
 *  the global index at the time that the user's accrued rewards balance was last updated. Then at
 *  any point in time, a user's claimable rewards are represented by the following:
 *
 *    rewards = _USER_REWARDS_BALANCES_[user] + userStaked * (
 *                settledGlobalIndex - _USER_INDEXES_[user]
 *              ) / INDEX_BASE
 */
abstract contract LS1Rewards is
  LS1EpochSchedule
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeCast for uint256;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  /// @dev Additional precision used to represent the global and user index values.
  uint256 private constant INDEX_BASE = 10**18;

  /// @notice The rewards token.
  IERC20Upgradeable public REWARDS_TOKEN;

  /// @notice Address to pull rewards from. Must have provided an allowance to this contract.
  address public REWARDS_TREASURY;

  /// @notice Start timestamp (inclusive) of the period in which rewards can be earned.
  uint256 public DISTRIBUTION_START;

  /// @notice End timestamp (exclusive) of the period in which rewards can be earned.
  uint256 public DISTRIBUTION_END;

  // ============ Events ============

  event RewardsPerSecondUpdated(
    uint256 emissionPerSecond
  );

  event GlobalIndexUpdated(
    uint256 index
  );

  event UserIndexUpdated(
    address indexed user,
    uint256 index,
    uint256 unclaimedRewards
  );

  event ClaimedRewards(
    address indexed user,
    address recipient,
    uint256 claimedRewards
  );

  // ============ External Functions ============

  /**
   * @notice The current emission rate of rewards.
   *
   * @return The number of rewards tokens issued globally each second.
   */
  function getRewardsPerSecond()
    external
    view
    returns (uint256)
  {
    return _REWARDS_PER_SECOND_;
  }

  // ============ Internal Functions ============

  /**
   * @dev Initialize the contract.
   */
  function __LS1Rewards_init()
    internal
  {
    _GLOBAL_INDEX_TIMESTAMP_ = MathUpgradeable.max(block.timestamp, DISTRIBUTION_START).toUint32();
  }

  /**
   * @dev Set the emission rate of rewards.
   *
   *  IMPORTANT: Do not call this function without settling the total staked balance first, to
   *  ensure that the index is settled up to the epoch boundaries.
   *
   * @param  emissionPerSecond  The new number of rewards tokens to give out each second.
   * @param  totalStaked        The total staked balance.
   */
  function _setRewardsPerSecond(
    uint256 emissionPerSecond,
    uint256 totalStaked
  )
    internal
  {
    _settleGlobalIndexUpToNow(totalStaked);
    _REWARDS_PER_SECOND_ = emissionPerSecond;
    emit RewardsPerSecondUpdated(emissionPerSecond);
  }

  /**
   * @dev Claim tokens, sending them to the specified recipient.
   *
   *  Note: In order to claim all accrued rewards, the total and user staked balances must first be
   *  settled before calling this function.
   *
   * @param  user       The user's address.
   * @param  recipient  The address to send rewards to.
   *
   * @return The number of rewards tokens claimed.
   */
  function _claimRewards(
    address user,
    address recipient
  )
    internal
    returns (uint256)
  {
    uint256 accruedRewards = _USER_REWARDS_BALANCES_[user];
    _USER_REWARDS_BALANCES_[user] = 0;
    REWARDS_TOKEN.safeTransferFrom(REWARDS_TREASURY, recipient, accruedRewards);
    emit ClaimedRewards(user, recipient, accruedRewards);
    return accruedRewards;
  }

  /**
   * @dev Settle a user's rewards up to the latest global index as of `block.timestamp`. Triggers a
   *  settlement of the global index up to `block.timestamp`. Should be called with the OLD user
   *  and total balances.
   *
   * @param  user         The user's address.
   * @param  userStaked   Tokens staked by the user during the period since the last user index
   *                      update.
   * @param  totalStaked  Total tokens staked by all users during the period since the last global
   *                      index update.
   *
   * @return The user's accrued rewards, including past unclaimed rewards.
   */
  function _settleUserRewardsUpToNow(
    address user,
    uint256 userStaked,
    uint256 totalStaked
  )
    internal
    returns (uint256)
  {
    uint256 globalIndex = _settleGlobalIndexUpToNow(totalStaked);
    return _settleUserRewardsUpToIndex(user, userStaked, globalIndex);
  }

  /**
   * @dev Settle a user's rewards up to an epoch boundary. Should be used to partially settle a
   *  user's rewards if their balance was known to have changed on that epoch boundary.
   *
   * @param  user         The user's address.
   * @param  userStaked   Tokens staked by the user. Should be accurate for the time period
   *                      since the last update to this user and up to the end of the
   *                      specified epoch.
   * @param  epochNumber  Settle the user's rewards up to the end of this epoch.
   *
   * @return The user's accrued rewards, including past unclaimed rewards, up to the end of the
   *  specified epoch.
   */
  function _settleUserRewardsUpToEpoch(
    address user,
    uint256 userStaked,
    uint256 epochNumber
  )
    internal
    returns (uint256)
  {
    uint256 globalIndex = _EPOCH_INDEXES_[epochNumber];
    return _settleUserRewardsUpToIndex(user, userStaked, globalIndex);
  }

  /**
   * @dev Settle the global index up to the end of the given epoch.
   *
   *  IMPORTANT: This function should only be called under conditions which ensure the following:
   *    - `epochNumber` < the current epoch number
   *    - `_GLOBAL_INDEX_TIMESTAMP_ < settleUpToTimestamp`
   *    - `_EPOCH_INDEXES_[epochNumber] = 0`
   */
  function _settleGlobalIndexUpToEpoch(
    uint256 totalStaked,
    uint256 epochNumber
  )
    internal
    returns (uint256)
  {
    uint256 settleUpToTimestamp = getStartOfEpoch(epochNumber.add(1));

    uint256 globalIndex = _settleGlobalIndexUpToTimestamp(totalStaked, settleUpToTimestamp);
    _EPOCH_INDEXES_[epochNumber] = globalIndex;
    return globalIndex;
  }

  // ============ Private Functions ============

  function _settleGlobalIndexUpToNow(
    uint256 totalStaked
  )
    private
    returns (uint256)
  {
    return _settleGlobalIndexUpToTimestamp(totalStaked, block.timestamp);
  }

  /**
   * @dev Helper function which settles a user's rewards up to a global index. Should be called
   *  any time a user's staked balance changes, with the OLD user and total balances.
   *
   * @param  user            The user's address.
   * @param  userStaked      Tokens staked by the user during the period since the last user index
   *                         update.
   * @param  newGlobalIndex  The new index value to bring the user index up to.
   *
   * @return The user's accrued rewards, including past unclaimed rewards.
   */
  function _settleUserRewardsUpToIndex(
    address user,
    uint256 userStaked,
    uint256 newGlobalIndex
  )
    private
    returns (uint256)
  {
    uint256 oldAccruedRewards = _USER_REWARDS_BALANCES_[user];
    uint256 oldUserIndex = _USER_INDEXES_[user];

    if (oldUserIndex == newGlobalIndex) {
      return oldAccruedRewards;
    }

    uint256 newAccruedRewards;
    if (userStaked == 0) {
      // Note: Even if the user's staked balance is zero, we still need to update the user index.
      newAccruedRewards = oldAccruedRewards;
    } else {
      // Calculate newly accrued rewards since the last update to the user's index.
      uint256 indexDelta = newGlobalIndex.sub(oldUserIndex);
      uint256 accruedRewardsDelta = userStaked.mul(indexDelta).div(INDEX_BASE);
      newAccruedRewards = oldAccruedRewards.add(accruedRewardsDelta);

      // Update the user's rewards.
      _USER_REWARDS_BALANCES_[user] = newAccruedRewards;
    }

    // Update the user's index.
    _USER_INDEXES_[user] = newGlobalIndex;
    emit UserIndexUpdated(user, newGlobalIndex, newAccruedRewards);
    return newAccruedRewards;
  }

  /**
   * @dev Updates the global index, reflecting cumulative rewards given out per staked token.
   *
   * @param  totalStaked          The total staked balance, which should be constant in the interval
   *                              (_GLOBAL_INDEX_TIMESTAMP_, settleUpToTimestamp).
   * @param  settleUpToTimestamp  The timestamp up to which to settle rewards. It MUST satisfy
   *                              `settleUpToTimestamp <= block.timestamp`.
   *
   * @return The new global index.
   */
  function _settleGlobalIndexUpToTimestamp(
    uint256 totalStaked,
    uint256 settleUpToTimestamp
  )
    private
    returns (uint256)
  {
    uint256 oldGlobalIndex = uint256(_GLOBAL_INDEX_);

    // The goal of this function is to calculate rewards earned since the last global index update.
    // These rewards are earned over the time interval which is the intersection of the intervals
    // [_GLOBAL_INDEX_TIMESTAMP_, settleUpToTimestamp] and [DISTRIBUTION_START, DISTRIBUTION_END].
    //
    // We can simplify a bit based on the assumption:
    //   `_GLOBAL_INDEX_TIMESTAMP_ >= DISTRIBUTION_START`
    //
    // Get the start and end of the time interval under consideration.
    uint256 intervalStart = uint256(_GLOBAL_INDEX_TIMESTAMP_);
    uint256 intervalEnd = MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END);

    // Return early if the interval has length zero (incl. case where intervalEnd < intervalStart).
    if (intervalEnd <= intervalStart) {
      return oldGlobalIndex;
    }

    // Note: If we reach this point, we must update _GLOBAL_INDEX_TIMESTAMP_.

    uint256 emissionPerSecond = _REWARDS_PER_SECOND_;

    if (emissionPerSecond == 0 || totalStaked == 0) {
      // Ensure a log is emitted if the timestamp changed, even if the index does not change.
      _GLOBAL_INDEX_TIMESTAMP_ = intervalEnd.toUint32();
      emit GlobalIndexUpdated(oldGlobalIndex);
      return oldGlobalIndex;
    }

    // Calculate the change in index over the interval.
    uint256 timeDelta = intervalEnd.sub(intervalStart);
    uint256 indexDelta = timeDelta.mul(emissionPerSecond).mul(INDEX_BASE).div(totalStaked);

    // Calculate, update, and return the new global index.
    uint256 newGlobalIndex = oldGlobalIndex.add(indexDelta);

    // Update storage. (Shared storage slot.)
    _GLOBAL_INDEX_TIMESTAMP_ = intervalEnd.toUint32();
    _GLOBAL_INDEX_ = newGlobalIndex.toUint128();

    emit GlobalIndexUpdated(newGlobalIndex);
    return newGlobalIndex;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { LS1Storage } from './LS1Storage.sol';

/**
 * @title LS1Roles
 * @author MarginX
 *
 * @dev Defines roles used in the LiquidityStakingV1 contract. The hierarchy of roles and powers
 *  of each role are described below.
 *
 *  Roles:
 *
 *    OWNER_ROLE
 *      | -> May add or remove users from any of the below roles it manages.
 *      |
 *      +-- EPOCH_PARAMETERS_ROLE
 *      |     -> May set epoch parameters such as the interval, offset, and blackout window.
 *      |
 *      +-- REWARDS_RATE_ROLE
 *      |     -> May set the emission rate of rewards.
 *      |
 *      +-- BORROWER_ADMIN_ROLE
 *      |     -> May set borrower allocations and allow/restrict borrowers from borrowing.
 *      |
 *      +-- CLAIM_OPERATOR_ROLE
 *      |     -> May claim rewards on behalf of a user.
 *      |
 *      +-- STAKE_OPERATOR_ROLE
 *      |     -> May manipulate user's staked funds (e.g. perform withdrawals on behalf of a user).
 *      |
 *      +-- DEBT_OPERATOR_ROLE
 *           -> May decrease borrow debt and decrease staker debt.
 */
abstract contract LS1Roles is
  LS1Storage
{
  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant EPOCH_PARAMETERS_ROLE = keccak256('EPOCH_PARAMETERS_ROLE');
  bytes32 public constant REWARDS_RATE_ROLE = keccak256('REWARDS_RATE_ROLE');
  bytes32 public constant BORROWER_ADMIN_ROLE = keccak256('BORROWER_ADMIN_ROLE');
  bytes32 public constant CLAIM_OPERATOR_ROLE = keccak256('CLAIM_OPERATOR_ROLE');
  bytes32 public constant STAKE_OPERATOR_ROLE = keccak256('STAKE_OPERATOR_ROLE');
  bytes32 public constant DEBT_OPERATOR_ROLE = keccak256('DEBT_OPERATOR_ROLE');

  function __LS1Roles_init() internal {
    // Assign roles to the sender.
    //
    // The DEBT_OPERATOR_ROLE, STAKE_OPERATOR_ROLE, and CLAIM_OPERATOR_ROLE roles are not
    // initially assigned. These can be assigned to other smart contracts to provide additional
    // functionality for users.
    _grantRole(OWNER_ROLE, msg.sender);
    _grantRole(EPOCH_PARAMETERS_ROLE, msg.sender);
    _grantRole(REWARDS_RATE_ROLE, msg.sender);
    _grantRole(BORROWER_ADMIN_ROLE, msg.sender);

    // Set OWNER_ROLE as the admin of all roles.
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(EPOCH_PARAMETERS_ROLE, OWNER_ROLE);
    _setRoleAdmin(REWARDS_RATE_ROLE, OWNER_ROLE);
    _setRoleAdmin(BORROWER_ADMIN_ROLE, OWNER_ROLE);
    _setRoleAdmin(CLAIM_OPERATOR_ROLE, OWNER_ROLE);
    _setRoleAdmin(STAKE_OPERATOR_ROLE, OWNER_ROLE);
    _setRoleAdmin(DEBT_OPERATOR_ROLE, OWNER_ROLE);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
// import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { IERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Rewards } from './LS1Rewards.sol';

/**
 * @title LS1StakedBalances
 * @author MarginX
 *
 * @dev Accounting of staked balances.
 *
 *  NOTE: Internal functions may revert if epoch zero has not started.
 *
 *  STAKED BALANCE ACCOUNTING:
 *
 *   A staked balance is in one of two states:
 *     - active: Available for borrowing; earning staking rewards; cannot be withdrawn by staker.
 *     - inactive: Unavailable for borrowing; does not earn rewards; can be withdrawn by the staker.
 *
 *   A staker may have a combination of active and inactive balances. The following operations
 *   affect staked balances as follows:
 *     - deposit:            Increase active balance.
 *     - request withdrawal: At the end of the current epoch, move some active funds to inactive.
 *     - withdraw:           Decrease inactive balance.
 *     - transfer:           Move some active funds to another staker.
 *
 *   To encode the fact that a balance may be scheduled to change at the end of a certain epoch, we
 *   store each balance as a struct of three fields: currentEpoch, currentEpochBalance, and
 *   nextEpochBalance. Also, inactive user balances make use of the shortfallCounter field as
 *   described below.
 *
 *  INACTIVE BALANCE ACCOUNTING:
 *
 *   Inactive funds may be subject to pro-rata socialized losses in the event of a shortfall where
 *   a borrower is late to pay back funds that have been requested for withdrawal. We track losses
 *   via indexes. Each index represents the fraction of inactive funds that were converted into
 *   debt during a given shortfall event. Each staker inactive balance stores a cached shortfall
 *   counter, representing the number of shortfalls that occurred in the past relative to when the
 *   balance was last updated.
 *
 *   Any losses incurred by an inactive balance translate into an equal credit to that staker's
 *   debt balance. See LS1DebtAccounting for more info about how the index is calculated.
 *
 *  REWARDS ACCOUNTING:
 *
 *   Active funds earn rewards for the period of time that they remain active. This means, after
 *   requesting a withdrawal of some funds, those funds will continue to earn rewards until the end
 *   of the epoch. For example:
 *
 *     epoch: n        n + 1      n + 2      n + 3
 *            |          |          |          |
 *            +----------+----------+----------+-----...
 *               ^ t_0: User makes a deposit.
 *                          ^ t_1: User requests a withdrawal of all funds.
 *                                  ^ t_2: The funds change state from active to inactive.
 *
 *   In the above scenario, the user would earn rewards for the period from t_0 to t_2, varying
 *   with the total staked balance in that period. If the user only request a withdrawal for a part
 *   of their balance, then the remaining balance would continue earning rewards beyond t_2.
 *
 *   User rewards must be settled via LS1Rewards any time a user's active balance changes. Special
 *   attention is paid to the the epoch boundaries, where funds may have transitioned from active
 *   to inactive.
 *
 *  SETTLEMENT DETAILS:
 *
 *   Internally, this module uses the following types of operations on stored balances:
 *     - Load:            Loads a balance, while applying settlement logic internally to get the
 *                        up-to-date result. Returns settlement results without updating state.
 *     - Store:           Stores a balance.
 *     - Load-for-update: Performs a load and applies updates as needed to rewards or debt balances.
 *                        Since this is state-changing, it must be followed by a store operation.
 *     - Settle:          Performs load-for-update and store operations.
 *
 *   This module is responsible for maintaining the following invariants to ensure rewards are
 *   calculated correctly:
 *     - When an active balance is loaded for update, if a rollover occurs from one epoch to the
 *       next, the rewards index must be settled up to the boundary at which the rollover occurs.
 *     - Because the global rewards index is needed to update the user rewards index, the total
 *       active balance must be settled before any staker balances are settled or loaded for update.
 *     - A staker's balance must be settled before their rewards are settled.
 */
abstract contract LS1StakedBalances is
  LS1Rewards
{
  using SafeCast for uint256;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  uint256 internal constant SHORTFALL_INDEX_BASE = 1e36;

  // ============ Events ============

  event ReceivedDebt(
    address indexed staker,
    uint256 amount,
    uint256 newDebtBalance
  );

  // ============ Public Functions ============

  /**
   * @notice Get the current active balance of a staker.
   */
  function getActiveBalanceCurrentEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_ACTIVE_BALANCES_[staker]);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch active balance of a staker.
   */
  function getActiveBalanceNextEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_ACTIVE_BALANCES_[staker]);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current total active balance.
   */
  function getTotalActiveBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_TOTAL_ACTIVE_BALANCE_);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch total active balance.
   */
  function getTotalActiveBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_TOTAL_ACTIVE_BALANCE_);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current inactive balance of a staker.
   * @dev The balance is converted via the index to token units.
   */
  function getInactiveBalanceCurrentEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, ) =
      _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch inactive balance of a staker.
   * @dev The balance is converted via the index to token units.
   */
  function getInactiveBalanceNextEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, ) =
      _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current total inactive balance.
   */
  function getTotalInactiveBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    LS1Types.StoredBalance memory balance = _loadTotalInactiveBalance(_TOTAL_INACTIVE_BALANCE_);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch total inactive balance.
   */
  function getTotalInactiveBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    LS1Types.StoredBalance memory balance = _loadTotalInactiveBalance(_TOTAL_INACTIVE_BALANCE_);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get a staker's debt balance, after accounting for unsettled shortfalls.
   *  Note that this does not modify _STAKER_DEBT_BALANCES_, so the debt balance must still be
   *  settled before it can be withdrawn.
   *
   * @param  staker  The staker to get the balance of.
   *
   * @return The settled debt balance.
   */
  function getStakerDebtBalance(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (, uint256 newDebtAmount) = _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return _STAKER_DEBT_BALANCES_[staker].add(newDebtAmount);
  }

  /**
   * @notice Get the current transferable balance for a user. The user can
   *  only transfer their balance that is not currently inactive or going to be
   *  inactive in the next epoch. Note that this means the user's transferable funds
   *  are their active balance of the next epoch.
   *
   * @param  account  The account to get the transferable balance of.
   *
   * @return The user's transferable balance.
   */
  function getTransferableBalance(
    address account
  )
    public
    view
    returns (uint256)
  {
    return getActiveBalanceNextEpoch(account);
  }


  // ============ External Functions ============




  // /**
  //  * @notice Get the reward of staker.
  //  *
  //  * @return The number of staker reward.
  //  */
  // function getStakerReward(address user)
  //   external
  //   view
  //   returns (uint256)
  // {
  //   uint256 _global_index_timestamp_ =_GLOBAL_INDEX_TIMESTAMP_;
  //   uint256 _global_index_ = _GLOBAL_INDEX_;
  //   // uint256 _before_Rollover_Epoch_;
  //   uint256 _epoch_indexes_beforeRolloverEpoch_;      // _EPOCH_INDEXES_
  //   uint256 _user_rewards_balances_ = _USER_REWARDS_BALANCES_[user];
  //   uint256 _user_index_ = _USER_INDEXES_[user];

  //   // 1) Always settle total active balance before settling a staker active balance.
  //   LS1Types.StoredBalance memory balance = _TOTAL_ACTIVE_BALANCE_;

  //   // Return these as they may be needed for rewards settlement.
  //   bool didRolloverOccur = false;

  //   // Roll the balance forward if needed.
  //   if (getCurrentEpoch() > uint256(balance.currentEpoch)) {
  //     didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

  //     balance.currentEpoch = uint16(getCurrentEpoch());
  //     balance.currentEpochBalance = balance.nextEpochBalance;
  //   }

  //   if (didRolloverOccur) {
  //     uint256 settleUpToTimestamp = getStartOfEpoch(uint256(balance.currentEpoch).add(1));
  //     uint256 oldGlobalIndex = uint256(_global_index_);

  //     // Get the start and end of the time interval under consideration.
  //     uint256 intervalStart = uint256(_global_index_timestamp_);
  //     uint256 intervalEnd = MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END);

  //     // Return early if the interval has length zero (incl. case where intervalEnd < intervalStart).
  //     if (intervalEnd <= intervalStart) {
  //       _global_index_ = oldGlobalIndex;
  //     } else {

  //       if (_REWARDS_PER_SECOND_ == 0 || uint256(balance.currentEpochBalance) == 0) {
  //         // Ensure a log is emitted if the timestamp changed, even if the index does not change.
  //         _global_index_timestamp_ = uint32(intervalEnd);
  //       }

  //       // Calculate the change in index over the interval.
  //       _global_index_ = oldGlobalIndex.add(intervalEnd.sub(intervalStart).mul(_REWARDS_PER_SECOND_).mul(10**18).div(uint256(balance.currentEpochBalance)));

  //       _global_index_timestamp_ = uint32(intervalEnd);
  //       // _global_index_ = uint128(globalIndex);
  //     }

  //     // _EPOCH_INDEXES_[uint256(balance.currentEpoch)] = _global_index_;
  //     _epoch_indexes_beforeRolloverEpoch_ = _global_index_;
  //   }

  //   uint256 totalBalance = uint256(balance.currentEpochBalance);




  //   // 2) Always settle staker active balance before settling staker rewards.
  //   // uint256 userBalance = _settleBalance(staker, true);

  //   balance = _ACTIVE_BALANCES_[user];

  //   // Return these as they may be needed for rewards settlement.
  //   didRolloverOccur = false;

  //   // Roll the balance forward if needed.
  //   if (getCurrentEpoch() > uint256(balance.currentEpoch)) {
  //     didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

  //     balance.currentEpoch = uint16(getCurrentEpoch());
  //     balance.currentEpochBalance = balance.nextEpochBalance;
  //   }

  //   if (didRolloverOccur) {
  //     uint256 globalIndexBeforeRolloverEpoch = _EPOCH_INDEXES_[uint256(balance.currentEpoch)];

  //     uint256 oldAccruedRewards = _user_rewards_balances_;
  //     uint256 oldUserIndex = _user_index_;

  //     if (oldUserIndex == globalIndexBeforeRolloverEpoch) {
  //       return oldAccruedRewards;
  //     }

  //     if (uint256(balance.currentEpochBalance) == 0) {
  //       // Note: Even if the user's staked balance is zero, we still need to update the user index.
  //     } else {
  //       // Calculate newly accrued rewards since the last update to the user's index.
  //       uint256 indexDelta = globalIndexBeforeRolloverEpoch.sub(oldUserIndex);
  //       uint256 accruedRewardsDelta = uint256(balance.currentEpochBalance).mul(indexDelta).div(10**18);

  //       _user_rewards_balances_ = oldAccruedRewards.add(accruedRewardsDelta);
  //     }

  //     // Update the user's index.
  //     _user_index_ = globalIndexBeforeRolloverEpoch;
  //   }

  //   uint256 userBalance = uint256(balance.currentEpochBalance);




  //   // 3）Settle rewards balance since we want to claim the full accrued amount.
  //   uint256 globalIndex = _global_index_;
  //   uint256 intervalStart = _global_index_timestamp_;
  //   uint256 intervalEnd = MathUpgradeable.min(block.timestamp, DISTRIBUTION_END);

  //   // Return early if the interval has length zero (incl. case where intervalEnd < intervalStart).
  //   uint256 timeDelta = 0;
  //   // Calculate the change in index over the interval.
  //   if(intervalEnd > intervalStart) {
  //     timeDelta = intervalEnd.sub(intervalStart);  
  //   }
  //   uint256 indexDelta = timeDelta.mul(_REWARDS_PER_SECOND_).mul(10**18).div(totalBalance);

  //   // Calculate, update, and return the new global index.
  //   globalIndex = globalIndex.add(indexDelta);

  //   indexDelta = globalIndex.sub(_user_index_);
  //   uint256 accruedRewardsDelta = userBalance.mul(indexDelta).div(10**18);

  //   // uint256 rewards = _user_rewards_balances_ + userStaked * (settledGlobalIndex - _user_index_) / 10**18;
  //   return _user_rewards_balances_.add(accruedRewardsDelta);
  //   // return 100;
  // }

  


  // ============ Internal Functions ============

  function _increaseCurrentAndNextActiveBalance(
    address staker,
    uint256 amount
  )
    internal
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 oldTotalBalance = _increaseCurrentAndNextBalances(address(0), true, amount);
    uint256 oldUserBalance = _increaseCurrentAndNextBalances(staker, true, amount);

    // When an active balance changes at current timestamp, settle rewards to the current timestamp.
    _settleUserRewardsUpToNow(staker, oldUserBalance, oldTotalBalance);
  }

  function _moveNextBalanceActiveToInactive(
    address staker,
    uint256 amount
  )
    internal
  {
    // Decrease the active balance for the next epoch.
    // Always settle total active balance before settling a staker active balance.
    _decreaseNextBalance(address(0), true, amount);
    _decreaseNextBalance(staker, true, amount);

    // Increase the inactive balance for the next epoch.
    _increaseNextBalance(address(0), false, amount);
    _increaseNextBalance(staker, false, amount);

    // Note that we don't need to settle rewards since the current active balance did not change.
  }

  function _transferCurrentAndNextActiveBalance(
    address sender,
    address recipient,
    uint256 amount
  )
    internal
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 totalBalance = _settleTotalActiveBalance();

    // Move current and next active balances from sender to recipient.
    uint256 oldSenderBalance = _decreaseCurrentAndNextBalances(sender, true, amount);
    uint256 oldRecipientBalance = _increaseCurrentAndNextBalances(recipient, true, amount);

    // When an active balance changes at current timestamp, settle rewards to the current timestamp.
    _settleUserRewardsUpToNow(sender, oldSenderBalance, totalBalance);
    _settleUserRewardsUpToNow(recipient, oldRecipientBalance, totalBalance);
  }

  function _decreaseCurrentAndNextInactiveBalance(
    address staker,
    uint256 amount
  )
    internal
  {
    // Decrease the inactive balance for the next epoch.
    _decreaseCurrentAndNextBalances(address(0), false, amount);
    _decreaseCurrentAndNextBalances(staker, false, amount);

    // Note that we don't settle rewards since active balances are not affected.
  }

  function _settleTotalActiveBalance()
    internal
    returns (uint256)
  {
    return _settleBalance(address(0), true);
  }

  function _settleStakerDebtBalance(
    address staker
  )
    internal
    returns (uint256)
  {
    // Settle the inactive balance to settle any new debt.
    _settleBalance(staker, false);

    // Return the settled debt balance.
    return _STAKER_DEBT_BALANCES_[staker];
  }

  function _settleAndClaimRewards(
    address staker,
    address recipient
  )
    internal
    returns (uint256)
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 totalBalance = _settleTotalActiveBalance();

    // Always settle staker active balance before settling staker rewards.
    uint256 userBalance = _settleBalance(staker, true);

    // Settle rewards balance since we want to claim the full accrued amount.
    _settleUserRewardsUpToNow(staker, userBalance, totalBalance);

    // Claim rewards balance.
    return _claimRewards(staker, recipient);
  }

  function _applyShortfall(
    uint256 shortfallAmount,
    uint256 shortfallIndex
  )
    internal
  {
    // Decrease the total inactive balance.
    _decreaseCurrentAndNextBalances(address(0), false, shortfallAmount);

    _SHORTFALLS_.push(LS1Types.Shortfall({
      epoch: getCurrentEpoch().toUint16(),
      index: shortfallIndex.toUint128()
    }));
  }

  // /**
  //  * @dev Does the same thing as _settleBalance() for a user inactive balance, but limits
  //  *  the epoch we progress to, in order that we can put an upper bound on the gas expenditure of
  //  *  the function. See LS1Failsafe.
  //  */
  // function _failsafeSettleUserInactiveBalance(
  //   address staker,
  //   uint256 maxEpoch
  // )
  //   internal
  // {
  //   LS1Types.StoredBalance storage balancePtr = _getBalancePtr(staker, false);
  //   LS1Types.StoredBalance memory balance =
  //     _failsafeLoadUserInactiveBalanceForUpdate(balancePtr, staker, maxEpoch);
  //   _storeBalance(balancePtr, balance);
  // }

  // /**
  //  * @dev Sets the user inactive balance to zero. See LS1Failsafe.
  //  *
  //  *  Since the balance will never be settled, the staker loses any debt balance that they would
  //  *  have otherwise been entitled to from shortfall losses.
  //  *
  //  *  Also note that we don't update the total inactive balance, but this is fine.
  //  */
  // function _failsafeDeleteUserInactiveBalance(
  //   address staker
  // )
  //   internal
  // {
  //   LS1Types.StoredBalance storage balancePtr = _getBalancePtr(staker, false);
  //   LS1Types.StoredBalance memory balance =
  //     LS1Types.StoredBalance({
  //       currentEpoch: 0,
  //       currentEpochBalance: 0,
  //       nextEpochBalance: 0,
  //       shortfallCounter: 0
  //     });
  //   _storeBalance(balancePtr, balance);
  // }

  // ============ Private Functions ============

  /**
   * @dev Load a balance for update and then store it.
   */
  function _settleBalance(
    address maybeStaker,
    bool isActiveBalance
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 currentBalance = uint256(balance.currentEpochBalance);

    _storeBalance(balancePtr, balance);
    return currentBalance;
  }

  /**
   * @dev Settle a balance while applying an increase.
   */
  function _increaseCurrentAndNextBalances(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 originalCurrentBalance = uint256(balance.currentEpochBalance);
    balance.currentEpochBalance = originalCurrentBalance.add(amount).toUint128();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).add(amount).toUint128();

    _storeBalance(balancePtr, balance);
    return originalCurrentBalance;
  }

  /**
   * @dev Settle a balance while applying a decrease.
   */
  function _decreaseCurrentAndNextBalances(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 originalCurrentBalance = uint256(balance.currentEpochBalance);
    balance.currentEpochBalance = originalCurrentBalance.sub(amount).toUint128();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(amount).toUint128();

    _storeBalance(balancePtr, balance);
    return originalCurrentBalance;
  }

  /**
   * @dev Settle a balance while applying an increase.
   */
  function _increaseNextBalance(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    balance.nextEpochBalance = uint256(balance.nextEpochBalance).add(amount).toUint128();

    _storeBalance(balancePtr, balance);
  }

  /**
   * @dev Settle a balance while applying a decrease.
   */
  function _decreaseNextBalance(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(amount).toUint128();

    _storeBalance(balancePtr, balance);
  }

  function _getBalancePtr(
    address maybeStaker,
    bool isActiveBalance
  )
    private
    view
    returns (LS1Types.StoredBalance storage)
  {
    // Active.
    if (isActiveBalance) {
      if (maybeStaker != address(0)) {
        return _ACTIVE_BALANCES_[maybeStaker];
      }
      return _TOTAL_ACTIVE_BALANCE_;
    }

    // Inactive.
    if (maybeStaker != address(0)) {
      return _INACTIVE_BALANCES_[maybeStaker];
    }
    return _TOTAL_INACTIVE_BALANCE_;
  }

  /**
   * @dev Load a balance for updating.
   *
   *  IMPORTANT: This function modifies state, and so the balance MUST be stored afterwards.
   *    - For active balances: if a rollover occurs, rewards are settled to the epoch boundary.
   *    - For inactive user balances: if a shortfall occurs, the user's debt balance is increased.
   *
   * @param  balancePtr       A storage pointer to the balance.
   * @param  maybeStaker      The user address, or address(0) to update total balance.
   * @param  isActiveBalance  Whether the balance is an active balance.
   */
  function _loadBalanceForUpdate(
    LS1Types.StoredBalance storage balancePtr,
    address maybeStaker,
    bool isActiveBalance
  )
    private
    returns (LS1Types.StoredBalance memory)
  {
    // Active balance.
    if (isActiveBalance) {
      (
        LS1Types.StoredBalance memory updateBalance,
        uint256 beforeRolloverEpoch,
        uint256 beforeRolloverBalance,
        bool didRolloverOccur
      ) = _loadActiveBalance(balancePtr);
      if (didRolloverOccur) {
        // Handle the effect of the balance rollover on rewards. We must partially settle the index
        // up to the epoch boundary where the change in balance occurred. We pass in the balance
        // from before the boundary.
        if (maybeStaker == address(0)) {
          // If it's the total active balance...
          _settleGlobalIndexUpToEpoch(beforeRolloverBalance, beforeRolloverEpoch);
        } else {
          // If it's a user active balance...
          _settleUserRewardsUpToEpoch(maybeStaker, beforeRolloverBalance, beforeRolloverEpoch);
        }
      }
      return updateBalance;
    }

    // Total inactive balance.
    if (maybeStaker == address(0)) {
      return _loadTotalInactiveBalance(balancePtr);
    }

    // User inactive balance.
    (LS1Types.StoredBalance memory balance, uint256 newStakerDebt) =
      _loadUserInactiveBalance(balancePtr);
    if (newStakerDebt != 0) {
      uint256 newDebtBalance = _STAKER_DEBT_BALANCES_[maybeStaker].add(newStakerDebt);
      _STAKER_DEBT_BALANCES_[maybeStaker] = newDebtBalance;
      emit ReceivedDebt(maybeStaker, newStakerDebt, newDebtBalance);
    }
    return balance;
  }

  function _loadActiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (
      LS1Types.StoredBalance memory,
      uint256,
      uint256,
      bool
    )
  {
    LS1Types.StoredBalance memory balance = balancePtr;

    // Return these as they may be needed for rewards settlement.
    uint256 beforeRolloverEpoch = uint256(balance.currentEpoch);
    uint256 beforeRolloverBalance = uint256(balance.currentEpochBalance);
    bool didRolloverOccur = false;

    // Roll the balance forward if needed.
    uint256 currentEpoch = getCurrentEpoch();
    if (currentEpoch > uint256(balance.currentEpoch)) {
      didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    return (balance, beforeRolloverEpoch, beforeRolloverBalance, didRolloverOccur);
  }

  function _loadTotalInactiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (LS1Types.StoredBalance memory)
  {
    LS1Types.StoredBalance memory balance = balancePtr;

    // Roll the balance forward if needed.
    uint256 currentEpoch = getCurrentEpoch();
    if (currentEpoch > uint256(balance.currentEpoch)) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    return balance;
  }

  function _loadUserInactiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (LS1Types.StoredBalance memory, uint256)
  {
    LS1Types.StoredBalance memory balance = balancePtr;
    uint256 currentEpoch = getCurrentEpoch();

    // If there is no non-zero balance, sync the epoch number and shortfall counter and exit.
    // Note: Next inactive balance is always >= current, so we only need to check next.
    if (balance.nextEpochBalance == 0) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.shortfallCounter = _SHORTFALLS_.length.toUint16();
      return (balance, 0);
    }

    // Apply any pending shortfalls that don't affect the “next epoch” balance.
    uint256 newStakerDebt;
    (balance, newStakerDebt) = _applyShortfallsToBalance(balance);

    // Roll the balance forward if needed.
    if (currentEpoch > uint256(balance.currentEpoch)) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;

      // Check for more shortfalls affecting the “next epoch” and beyond.
      uint256 moreNewStakerDebt;
      (balance, moreNewStakerDebt) = _applyShortfallsToBalance(balance);
      newStakerDebt = newStakerDebt.add(moreNewStakerDebt);
    }

    return (balance, newStakerDebt);
  }

  function _applyShortfallsToBalance(
    LS1Types.StoredBalance memory balance
  )
    private
    view
    returns (LS1Types.StoredBalance memory, uint256)
  {
    // Get the cached and global shortfall counters.
    uint256 shortfallCounter = uint256(balance.shortfallCounter);
    uint256 globalShortfallCounter = _SHORTFALLS_.length;

    // If the counters are in sync, then there is nothing to do.
    if (shortfallCounter == globalShortfallCounter) {
      return (balance, 0);
    }

    // Get the balance params.
    uint16 cachedEpoch = balance.currentEpoch;
    uint256 oldCurrentBalance = uint256(balance.currentEpochBalance);

    // Calculate the new balance after applying shortfalls.
    //
    // Note: In theory, this while-loop may render an account's funds inaccessible if there are
    // too many shortfalls, and too much gas is required to apply them all. This is very unlikely
    // to occur in practice, but we provide _failsafeLoadUserInactiveBalance() just in case to
    // ensure recovery is possible.
    uint256 newCurrentBalance = oldCurrentBalance;
    while (shortfallCounter < globalShortfallCounter) {
      LS1Types.Shortfall memory shortfall = _SHORTFALLS_[shortfallCounter];

      // Stop applying shortfalls if they are in the future relative to the balance current epoch.
      if (shortfall.epoch > cachedEpoch) {
        break;
      }

      // Update the current balance to reflect the shortfall.
      uint256 shortfallIndex = uint256(shortfall.index);
      newCurrentBalance = newCurrentBalance.mul(shortfallIndex).div(SHORTFALL_INDEX_BASE);

      // Increment the staker's shortfall counter.
      shortfallCounter = shortfallCounter.add(1);
    }

    // Calculate the loss.
    // If the loaded balance is stored, this amount must be added to the staker's debt balance.
    uint256 newStakerDebt = oldCurrentBalance.sub(newCurrentBalance);

    // Update the balance.
    balance.currentEpochBalance = newCurrentBalance.toUint128();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(newStakerDebt).toUint128();
    balance.shortfallCounter = shortfallCounter.toUint16();
    return (balance, newStakerDebt);
  }

  /**
   * @dev Store a balance.
   */
  function _storeBalance(
    LS1Types.StoredBalance storage balancePtr,
    LS1Types.StoredBalance memory balance
  )
    private
  {
    // Note: This should use a single `sstore` when compiler optimizations are enabled.
    balancePtr.currentEpoch = balance.currentEpoch;
    balancePtr.currentEpochBalance = balance.currentEpochBalance;
    balancePtr.nextEpochBalance = balance.nextEpochBalance;
    balancePtr.shortfallCounter = balance.shortfallCounter;
  }

  // /**
  //  * @dev Does the same thing as _loadBalanceForUpdate() for a user inactive balance, but limits
  //  *  the epoch we progress to, in order that we can put an upper bound on the gas expenditure of
  //  *  the function. See LS1Failsafe.
  //  */
  // function _failsafeLoadUserInactiveBalanceForUpdate(
  //   LS1Types.StoredBalance storage balancePtr,
  //   address staker,
  //   uint256 maxEpoch
  // )
  //   private
  //   returns (LS1Types.StoredBalance memory)
  // {
  //   LS1Types.StoredBalance memory balance = balancePtr;

  //   // Validate maxEpoch.
  //   uint256 currentEpoch = getCurrentEpoch();
  //   uint256 cachedEpoch = uint256(balance.currentEpoch);
  //   require(
  //     maxEpoch >= cachedEpoch && maxEpoch <= currentEpoch,
  //     'maxEpoch'
  //   );

  //   // Apply any pending shortfalls that don't affect the “next epoch” balance.
  //   uint256 newStakerDebt;
  //   (balance, newStakerDebt) = _applyShortfallsToBalance(balance);

  //   // Roll the balance forward if needed.
  //   if (maxEpoch > cachedEpoch) {
  //     balance.currentEpoch = maxEpoch.toUint16(); // Use maxEpoch instead of currentEpoch.
  //     balance.currentEpochBalance = balance.nextEpochBalance;

  //     // Check for more shortfalls affecting the “next epoch” and beyond.
  //     uint256 moreNewStakerDebt;
  //     (balance, moreNewStakerDebt) = _applyShortfallsToBalance(balance);
  //     newStakerDebt = newStakerDebt.add(moreNewStakerDebt);
  //   }

  //   // Apply debt if needed.
  //   if (newStakerDebt != 0) {
  //     uint256 newDebtBalance = _STAKER_DEBT_BALANCES_[staker].add(newStakerDebt);
  //     _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
  //     emit ReceivedDebt(staker, newStakerDebt, newDebtBalance);
  //   }
  //   return balance;
  // }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1ERC20 } from './LS1ERC20.sol';
import { LS1StakedBalances } from './LS1StakedBalances.sol';

/**
 * @title LS1Staking
 * @author MarginX
 *
 * @dev External functions for stakers. See LS1StakedBalances for details on staker accounting.
 */
abstract contract LS1Staking is
  LS1StakedBalances,
  LS1ERC20
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  // ============ Events ============

  event Staked(
    address indexed staker,
    address spender,
    uint256 amount
  );

  event WithdrawalRequested(
    address indexed staker,
    uint256 amount
  );

  event WithdrewStake(
    address indexed staker,
    address recipient,
    uint256 amount
  );

  event WithdrewDebt(
    address indexed staker,
    address recipient,
    uint256 amount,
    uint256 newDebtBalance
  );

  // ============ Constants ============

  IERC20Upgradeable public STAKED_TOKEN;

  // ============ External Functions ============

  /**
   * @notice Deposit and stake funds. These funds are active and start earning rewards immediately.
   *
   * @param  amount  The amount to stake.
   */
  function stake(
    uint256 amount
  )
    external
    nonReentrant
  {
    _stake(msg.sender, amount);
  }

  /**
   * @notice Request to withdraw funds. Starting in the next epoch, the funds will be “inactive”
   *  and available for withdrawal. Inactive funds do not earn rewards.
   *
   *  Reverts if we are currently in the blackout window.
   *
   * @param  amount  The amount to move from the active to the inactive balance.
   */
  function requestWithdrawal(
    uint256 amount
  )
    external
    nonReentrant
  {
    _requestWithdrawal(msg.sender, amount);
  }

  /**
   * @notice Withdraw the sender's inactive funds, and send to the specified recipient.
   *
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The amount to withdraw from the sender's inactive balance.
   */
  function withdrawStake(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
  {
    _withdrawStake(msg.sender, recipient, amount);
  }

  /**
   * @notice Withdraw the max available inactive funds, and send to the specified recipient.
   *
   *  This is less gas-efficient than querying the max via eth_call and calling withdrawStake().
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The withdrawn amount.
   */
  function withdrawMaxStake(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    uint256 amount = getStakeAvailableToWithdraw(msg.sender);
    _withdrawStake(msg.sender, recipient, amount);
    return amount;
  }

  /**
   * @notice Withdraw a debt amount owed to the sender, and send to the specified recipient.
   *
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The token amount to withdraw from the sender's debt balance.
   */
  function withdrawDebt(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
  {
    _withdrawDebt(msg.sender, recipient, amount);
  }

  /**
   * @notice Withdraw the max available debt amount.
   *
   *  This is less gas-efficient than querying the max via eth_call and calling withdrawDebt().
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The withdrawn amount.
   */
  function withdrawMaxDebt(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    uint256 amount = getDebtAvailableToWithdraw(msg.sender);
    _withdrawDebt(msg.sender, recipient, amount);
    return amount;
  }

  /**
   * @notice Settle and claim all rewards, and send them to the specified recipient.
   *
   *  Call this function with eth_call to query the claimable rewards balance.
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewards(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    return _settleAndClaimRewards(msg.sender, recipient); // Emits an event internally.
  }

  // ============ Public Functions ============

  /**
   * @notice Get the amount of stake available to withdraw taking into account the contract balance.
   *
   * @param  staker  The address whose balance to check.
   *
   * @return The staker's stake amount that is inactive and available to withdraw.
   */
  function getStakeAvailableToWithdraw(
    address staker
  )
    public
    view
    returns (uint256)
  {
    // Note that the next epoch inactive balance is always at least that of the current epoch.
    uint256 stakerBalance = getInactiveBalanceCurrentEpoch(staker);
    uint256 totalStakeAvailable = getContractBalanceAvailableToWithdraw();
    return MathUpgradeable.min(stakerBalance, totalStakeAvailable);
  }

  /**
   * @notice Get the funds currently available in the contract for staker withdrawals.
   *
   * @return The amount of non-debt funds in the contract.
   */
  function getContractBalanceAvailableToWithdraw()
    public
    view
    returns (uint256)
  {
    uint256 contractBalance = STAKED_TOKEN.balanceOf(address(this));
    uint256 availableDebtBalance = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    return contractBalance.sub(availableDebtBalance); // Should never underflow.
  }

  /**
   * @notice Get the amount of debt available to withdraw.
   *
   * @param  staker  The address whose balance to check.
   *
   * @return The debt amount that can be withdrawn.
   */
  function getDebtAvailableToWithdraw(
    address staker
  )
    public
    view
    returns (uint256)
  {
    // Note that `totalDebtAvailable` should never be less than the contract token balance.
    uint256 stakerDebtBalance = getStakerDebtBalance(staker);
    uint256 totalDebtAvailable = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    return MathUpgradeable.min(stakerDebtBalance, totalDebtAvailable);
  }


  /**
   * @notice Get the reward of staker.
   *
   * @return The number of staker reward.
   */
  function getStakerReward(address user)
    external
    view
    returns (uint256)
  {
    uint256 _global_index_timestamp_ =_GLOBAL_INDEX_TIMESTAMP_;
    uint256 _global_index_ = _GLOBAL_INDEX_;
    uint256 _epoch_indexes_beforeRolloverEpoch_;      // _EPOCH_INDEXES_
    uint256 _user_rewards_balances_ = _USER_REWARDS_BALANCES_[user];
    uint256 _user_index_ = _USER_INDEXES_[user];

    // 1) Always settle total active balance before settling a staker active balance.
    LS1Types.StoredBalance memory balance = _TOTAL_ACTIVE_BALANCE_;
    uint256 beforeRolloverEpoch = balance.currentEpoch;
    // Return these as they may be needed for rewards settlement.
    bool didRolloverOccur = false;

    // Roll the balance forward if needed.
    if (getCurrentEpoch() > uint256(balance.currentEpoch)) {
      didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

      balance.currentEpoch = uint16(getCurrentEpoch());
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    if (didRolloverOccur) {
      uint256 settleUpToTimestamp = getStartOfEpoch(uint256(balance.currentEpoch).add(1));
      uint256 oldGlobalIndex = uint256(_global_index_);

      // Get the start and end of the time interval under consideration.
      uint256 intervalStart = uint256(_global_index_timestamp_);
      uint256 intervalEnd = MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END);

      // Return early if the interval has length zero (incl. case where intervalEnd < intervalStart).
      if (intervalEnd <= intervalStart) {
        _global_index_ = oldGlobalIndex;
      } else {

        if (_REWARDS_PER_SECOND_ == 0 || uint256(balance.currentEpochBalance) == 0) {
          _global_index_timestamp_ = uint32(intervalEnd);
        }

        // Calculate the change in index over the interval.
        _global_index_ = oldGlobalIndex.add(intervalEnd.sub(intervalStart).mul(_REWARDS_PER_SECOND_).mul(10**18).div(uint256(balance.currentEpochBalance)));
        _global_index_timestamp_ = uint32(intervalEnd);
      }

      // _EPOCH_INDEXES_[uint256(balance.currentEpoch)] = _global_index_;
      _epoch_indexes_beforeRolloverEpoch_ = _global_index_;
    }

    uint256 totalBalance = uint256(balance.currentEpochBalance);


    // 2) Always settle staker active balance before settling staker rewards.
    balance = _ACTIVE_BALANCES_[user];

    // Return these as they may be needed for rewards settlement.
    didRolloverOccur = false;

    // Roll the balance forward if needed.
    if (getCurrentEpoch() > uint256(balance.currentEpoch)) {
      didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

      balance.currentEpoch = uint16(getCurrentEpoch());
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    if (didRolloverOccur) {
      uint256 globalIndexBeforeRolloverEpoch;
      if(uint256(balance.currentEpoch) == beforeRolloverEpoch) {
        globalIndexBeforeRolloverEpoch = _epoch_indexes_beforeRolloverEpoch_;
      } else {
        globalIndexBeforeRolloverEpoch = _EPOCH_INDEXES_[uint256(balance.currentEpoch)];
      }
      
      uint256 oldAccruedRewards = _user_rewards_balances_;
      uint256 oldUserIndex = _user_index_;

      if (oldUserIndex == globalIndexBeforeRolloverEpoch) {
        return oldAccruedRewards;
      }

      if (uint256(balance.currentEpochBalance) == 0) {
        // Note: Even if the user's staked balance is zero, we still need to update the user index.
      } else {
        // Calculate newly accrued rewards since the last update to the user's index.
        // uint256 indexDelta = globalIndexBeforeRolloverEpoch.sub(oldUserIndex);
        uint256 accruedRewardsDelta2 = uint256(balance.currentEpochBalance).mul(globalIndexBeforeRolloverEpoch.sub(oldUserIndex)).div(10**18);

        _user_rewards_balances_ = oldAccruedRewards.add(accruedRewardsDelta2);
      }

      // Update the user's index.
      _user_index_ = globalIndexBeforeRolloverEpoch;
    }

    uint256 userBalance = uint256(balance.currentEpochBalance);


    // 3）Settle rewards balance since we want to claim the full accrued amount.
    uint256 globalIndex = _global_index_;
    // intervalStart = _global_index_timestamp_;
    // intervalEnd = MathUpgradeable.min(block.timestamp, DISTRIBUTION_END);

    // Return early if the interval has length zero (incl. case where intervalEnd < intervalStart).
    uint256 timeDelta = 0;
    // Calculate the change in index over the interval.
    if(MathUpgradeable.min(block.timestamp, DISTRIBUTION_END) > _global_index_timestamp_) {
      timeDelta = MathUpgradeable.min(block.timestamp, DISTRIBUTION_END).sub(_global_index_timestamp_);  
    }
    uint256 indexDelta = timeDelta.mul(_REWARDS_PER_SECOND_).mul(10**18).div(totalBalance);

    // Calculate, update, and return the new global index.
    globalIndex = globalIndex.add(indexDelta);
    indexDelta = globalIndex.sub(_user_index_);
    uint256 accruedRewardsDelta = userBalance.mul(indexDelta).div(10**18);

    // uint256 rewards = _user_rewards_balances_ + userStaked * (settledGlobalIndex - _user_index_) / 10**18;
    return _user_rewards_balances_.add(accruedRewardsDelta);
    // return 100;
  }


  // ============ Internal Functions ============

  function _stake(
    address staker,
    uint256 amount
  )
    internal
  {
    // Increase current and next active balance.
    _increaseCurrentAndNextActiveBalance(staker, amount);

    // Transfer token from the sender.
    STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

    emit Staked(staker, msg.sender, amount);
    emit Transfer(address(0), msg.sender, amount);
  }

  function _requestWithdrawal(
    address staker,
    uint256 amount
  )
    internal
  {
    require(
      !inBlackoutWindow(),
      'Withdraw requests restricted in the blackout window'
    );

    // Get the staker's requestable amount and revert if there is not enough to request withdrawal.
    uint256 requestableBalance = getActiveBalanceNextEpoch(staker);
    require(
      amount <= requestableBalance,
      'Withdraw request exceeds next active balance'
    );

    // Move amount from active to inactive in the next epoch.
    _moveNextBalanceActiveToInactive(staker, amount);

    emit WithdrawalRequested(staker, amount);
  }

  function _withdrawStake(
    address staker,
    address recipient,
    uint256 amount
  )
    internal
  {
    // Get contract available amount and revert if there is not enough to withdraw.
    uint256 totalStakeAvailable = getContractBalanceAvailableToWithdraw();
    require(
      amount <= totalStakeAvailable,
      'Withdraw exceeds amount available in the contract'
    );

    // Get staker withdrawable balance and revert if there is not enough to withdraw.
    uint256 withdrawableBalance = getInactiveBalanceCurrentEpoch(staker);
    require(
      amount <= withdrawableBalance,
      'Withdraw exceeds inactive balance'
    );

    // Decrease the staker's current and next inactive balance. Reverts if balance is insufficient.
    _decreaseCurrentAndNextInactiveBalance(staker, amount);

    // Transfer token to the recipient.
    STAKED_TOKEN.safeTransfer(recipient, amount);

    emit Transfer(msg.sender, address(0), amount);
    emit WithdrewStake(staker, recipient, amount);
  }

  // ============ Private Functions ============

  function _withdrawDebt(
    address staker,
    address recipient,
    uint256 amount
  )
    private
  {
    // Get old amounts and revert if there is not enough to withdraw.
    uint256 oldDebtBalance = _settleStakerDebtBalance(staker);
    require(
      amount <= oldDebtBalance,
      'Withdraw debt exceeds debt owed'
    );
    uint256 oldDebtAvailable = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    require(
      amount <= oldDebtAvailable,
      'Withdraw debt exceeds amount available'
    );

    // Caculate updated amounts and update storage.
    uint256 newDebtBalance = oldDebtBalance.sub(amount);
    uint256 newDebtAvailable = oldDebtAvailable.sub(amount);
    _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
    _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_ = newDebtAvailable;

    // Transfer token to the recipient.
    STAKED_TOKEN.safeTransfer(recipient, amount);

    emit WithdrewDebt(staker, recipient, amount, newDebtBalance);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { AccessControlUpgradeable } from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';

/**
 * @title LS1Storage
 * @author MarginX
 *
 * @dev Storage contract. Contains or inherits from all contract with storage.
 */
abstract contract LS1Storage is
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  // ============ Epoch Schedule ============

  /// @dev The parameters specifying the function from timestamp to epoch number.
  LS1Types.EpochParameters internal _EPOCH_PARAMETERS_;

  /// @dev The period of time at the end of each epoch in which withdrawals cannot be requested.
  ///  We also restrict other changes which could affect borrowers' repayment plans, such as
  ///  modifications to the epoch schedule, or to borrower allocations.
  uint256 internal _BLACKOUT_WINDOW_;

  // ============ Staked Token ERC20 ============

  mapping(address => mapping(address => uint256)) internal _ALLOWANCES_;

  // ============ Rewards Accounting ============

  /// @dev The emission rate of rewards.
  uint256 internal _REWARDS_PER_SECOND_;

  /// @dev The cumulative rewards earned per staked token. (Shared storage slot.)
  uint224 internal _GLOBAL_INDEX_;

  /// @dev The timestamp at which the global index was last updated. (Shared storage slot.)
  uint32 internal _GLOBAL_INDEX_TIMESTAMP_;

  /// @dev The value of the global index when the user's staked balance was last updated.
  mapping(address => uint256) internal _USER_INDEXES_;

  /// @dev The user's accrued, unclaimed rewards (as of the last update to the user index).
  mapping(address => uint256) internal _USER_REWARDS_BALANCES_;

  /// @dev The value of the global index at the end of a given epoch.
  mapping(uint256 => uint256) internal _EPOCH_INDEXES_;

  // ============ Staker Accounting ============

  /// @dev The active balance by staker.
  mapping(address => LS1Types.StoredBalance) internal _ACTIVE_BALANCES_;

  /// @dev The total active balance of stakers.
  LS1Types.StoredBalance internal _TOTAL_ACTIVE_BALANCE_;

  /// @dev The inactive balance by staker.
  mapping(address => LS1Types.StoredBalance) internal _INACTIVE_BALANCES_;

  /// @dev The total inactive balance of stakers. Note: The shortfallCounter field is unused.
  LS1Types.StoredBalance internal _TOTAL_INACTIVE_BALANCE_;

  /// @dev Information about shortfalls that have occurred.
  LS1Types.Shortfall[] internal _SHORTFALLS_;

  // ============ Borrower Accounting ============

  /// @dev The units allocated to each borrower.
  /// @dev Values are represented relative to total allocation, i.e. as hundredeths of a percent.
  ///  Also, the total of the values contained in the mapping must always equal the total
  ///  allocation (i.e. must sum to 10,000).
  mapping(address => LS1Types.StoredAllocation) internal _BORROWER_ALLOCATIONS_;

  /// @dev The token balance currently borrowed by the borrower.
  mapping(address => uint256) internal _BORROWED_BALANCES_;

  /// @dev The total token balance currently borrowed by borrowers.
  uint256 internal _TOTAL_BORROWED_BALANCE_;

  /// @dev Indicates whether a borrower is restricted from new borrowing.
  mapping(address => bool) internal _BORROWER_RESTRICTIONS_;

  // ============ Debt Accounting ============

  /// @dev The debt balance owed to each staker.
  mapping(address => uint256) internal _STAKER_DEBT_BALANCES_;

  /// @dev The debt balance by borrower.
  mapping(address => uint256) internal _BORROWER_DEBT_BALANCES_;

  /// @dev The total debt balance of borrowers.
  uint256 internal _TOTAL_BORROWER_DEBT_BALANCE_;

  /// @dev The total debt amount repaid and not yet withdrawn.
  uint256 internal _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

/**
 * @title LS1Types
 * @author MarginX
 *
 * @dev Structs used by the LiquidityStaking contract.
 */
library LS1Types {
  /**
   * @dev The parameters used to convert a timestamp to an epoch number.
   */
  struct EpochParameters {
    uint128 interval;
    uint128 offset;
  }

  /**
   * @dev The parameters representing a shortfall event.
   *
   * @param  index  Fraction of inactive funds converted into debt, scaled by SHORTFALL_INDEX_BASE.
   * @param  epoch  The epoch in which the shortfall occurred.
   */
  struct Shortfall {
    uint16 epoch; // Note: Supports at least 1000 years given min epoch length of 6 days.
    uint224 index; // Note: Save on contract bytecode size by reusing uint224 instead of uint240.
  }

  /**
   * @dev A balance, possibly with a change scheduled for the next epoch.
   *  Also includes cached index information for inactive balances.
   *
   * @param  currentEpoch         The epoch in which the balance was last updated.
   * @param  currentEpochBalance  The balance at epoch `currentEpoch`.
   * @param  nextEpochBalance     The balance at epoch `currentEpoch + 1`.
   * @param  shortfallCounter     Incrementing counter of the next shortfall index to be applied.
   */
  struct StoredBalance {
    uint16 currentEpoch; // Supports at least 1000 years given min epoch length of 6 days.
    uint128 currentEpochBalance;
    uint128 nextEpochBalance;
    uint16 shortfallCounter; // Only for staker inactive balances. At most one shortfall per epoch.
  }

  /**
   * @dev A borrower allocation, possibly with a change scheduled for the next epoch.
   */
  struct StoredAllocation {
    uint16 currentEpoch; // Note: Supports at least 1000 years given min epoch length of 6 days.
    uint128 currentEpochAllocation;
    uint128 nextEpochAllocation;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


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
        require(value < 2**128, "value doesn\'t fit in 128 bits");
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
        require(value < 2**64, "value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "value doesn\'t fit in 8 bits");
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
        require(value >= 0, "value must be positive");
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
        require(value >= -2**127 && value < 2**127, "value doesn\'t fit in 128 bits");
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
        require(value >= -2**63 && value < 2**63, "value doesn\'t fit in 64 bits");
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
        require(value >= -2**31 && value < 2**31, "value doesn\'t fit in 32 bits");
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
        require(value >= -2**15 && value < 2**15, "value doesn\'t fit in 16 bits");
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
        require(value >= -2**7 && value < 2**7, "value doesn\'t fit in 8 bits");
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
        require(value < 2**255, "value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { LS1Admin } from "./impl/LS1Admin.sol";
import { LS1Borrowing } from "./impl/LS1Borrowing.sol";
import { LS1DebtAccounting } from "./impl/LS1DebtAccounting.sol";
import { LS1ERC20 } from "./impl/LS1ERC20.sol";
// import { LS1Failsafe } from "./impl/LS1Failsafe.sol";
import { LS1Getters } from './impl/LS1Getters.sol';
import { LS1Operators } from "./impl/LS1Operators.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title LiquidityStakingV1
 * @author MarginX
 *
 * @notice Contract for staking tokens, which may then be borrowed by pre-approved borrowers.
 *
 *  NOTE: Most functions will revert if epoch zero has not started.
 */
contract LiquidityStakingV1 is
    Initializable,
    LS1Borrowing,
    LS1DebtAccounting,
    LS1Admin,
    LS1Operators,
    LS1Getters,
    // LS1Failsafe,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ============ External Functions ============

    function initialize(
        IERC20Upgradeable stakedToken,
        IERC20Upgradeable rewardsToken,
        address rewardsTreasury,
        uint256 distributionStart,
        uint256 distributionEnd,
        uint256 interval,
        uint256 offset,
        uint256 blackoutWindow
    ) external initializer {
        require(distributionEnd >= distributionStart, "Invalid");
        STAKED_TOKEN = stakedToken;
        REWARDS_TOKEN = rewardsToken;
        REWARDS_TREASURY = rewardsTreasury;
        DISTRIBUTION_START = distributionStart;
        DISTRIBUTION_END = distributionEnd;
        __LS1Roles_init();
        __LS1EpochSchedule_init(interval, offset, blackoutWindow);
        __LS1Rewards_init();
        __LS1BorrowerAllocations_init();
        __UUPSUpgradeable_init();
    }

    // ============ Internal Functions ============

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(OWNER_ROLE)
    {}
}