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

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IFxBridgeLogic {
    event FxOriginatedTokenEvent(
        address indexed _tokenContract,
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _eventNonce
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Paused(address account);
    event SendToFxEvent(
        address indexed _tokenContract,
        address indexed _sender,
        bytes32 indexed _destination,
        bytes32 _targetIBC,
        uint256 _amount,
        uint256 _eventNonce
    );
    event TransactionBatchExecutedEvent(
        uint256 indexed _batchNonce,
        address indexed _token,
        uint256 _eventNonce
    );
    event TransferOwnerEvent(address _token, address _newOwner);
    event Unpaused(address account);
    event ValsetUpdatedEvent(
        uint256 indexed _newValsetNonce,
        uint256 _eventNonce,
        address[] _validators,
        uint256[] _powers
    );

    function addBridgeToken(address _tokenAddr) external returns (bool);

    function bridgeTokens(uint256) external view returns (address);

    function checkAssetStatus(address _tokenAddr) external view returns (bool);

    function checkValidatorSignatures(
        address[] memory _currentValidators,
        uint256[] memory _currentPowers,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s,
        bytes32 _theHash,
        uint256 _powerThreshold
    ) external pure;

    function delBridgeToken(address _tokenAddr) external returns (bool);

    function getBridgeTokenList()
        external
        view
        returns (FxBridgeLogicMigrate.BridgeToken[] memory);

    function init(
        bytes32 _fxBridgeId,
        uint256 _powerThreshold,
        address _fxOriginatedToken,
        uint256 _lastEventNonce,
        bytes32 _lastValsetCheckpoint,
        uint256 _lastValsetNonce,
        address[] memory _bridgeToken,
        uint256[] memory _lastBatchNonce
    ) external;

    function lastBatchNonce(address _erc20Address)
        external
        view
        returns (uint256);

    function makeCheckpoint(
        address[] memory _validators,
        uint256[] memory _powers,
        uint256 _valsetNonce,
        bytes32 _fxBridgeId
    ) external pure returns (bytes32);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function renounceOwnership() external;

    function sendToFx(
        address _tokenContract,
        bytes32 _destination,
        bytes32 _targetIBC,
        uint256 _amount
    ) external;

    function setFxOriginatedToken(address _tokenAddr) external returns (bool);

    function state_fxBridgeId() external view returns (bytes32);

    function state_fxOriginatedToken() external view returns (address);

    function state_lastBatchNonces(address) external view returns (uint256);

    function state_lastEventNonce() external view returns (uint256);

    function state_lastValsetCheckpoint() external view returns (bytes32);

    function state_lastValsetNonce() external view returns (uint256);

    function state_powerThreshold() external view returns (uint256);

    function submitBatch(
        address[] memory _currentValidators,
        uint256[] memory _currentPowers,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s,
        uint256[] memory _amounts,
        address[] memory _destinations,
        uint256[] memory _fees,
        uint256[2] memory _nonceArray,
        address _tokenContract,
        uint256 _batchTimeout,
        address _feeReceive
    ) external;

    function transferOwner(address _token, address _newOwner)
        external
        returns (bool);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function updateValset(
        address[] memory _newValidators,
        uint256[] memory _newPowers,
        uint256 _newValsetNonce,
        address[] memory _currentValidators,
        uint256[] memory _currentPowers,
        uint256 _currentValsetNonce,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    ) external;
}

interface FxBridgeLogicMigrate {
    struct BridgeToken {
        address addr;
        string name;
        string symbol;
        uint8 decimals;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_tokenContract","type":"address"},{"indexed":false,"internalType":"string","name":"_name","type":"string"},{"indexed":false,"internalType":"string","name":"_symbol","type":"string"},{"indexed":false,"internalType":"uint8","name":"_decimals","type":"uint8"},{"indexed":false,"internalType":"uint256","name":"_eventNonce","type":"uint256"}],"name":"FxOriginatedTokenEvent","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_tokenContract","type":"address"},{"indexed":true,"internalType":"address","name":"_sender","type":"address"},{"indexed":true,"internalType":"bytes32","name":"_destination","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"_targetIBC","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_eventNonce","type":"uint256"}],"name":"SendToFxEvent","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"_batchNonce","type":"uint256"},{"indexed":true,"internalType":"address","name":"_token","type":"address"},{"indexed":false,"internalType":"uint256","name":"_eventNonce","type":"uint256"}],"name":"TransactionBatchExecutedEvent","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_token","type":"address"},{"indexed":false,"internalType":"address","name":"_newOwner","type":"address"}],"name":"TransferOwnerEvent","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"_newValsetNonce","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_eventNonce","type":"uint256"},{"indexed":false,"internalType":"address[]","name":"_validators","type":"address[]"},{"indexed":false,"internalType":"uint256[]","name":"_powers","type":"uint256[]"}],"name":"ValsetUpdatedEvent","type":"event"},{"inputs":[{"internalType":"address","name":"_tokenAddr","type":"address"}],"name":"addBridgeToken","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"bridgeTokens","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_tokenAddr","type":"address"}],"name":"checkAssetStatus","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_currentValidators","type":"address[]"},{"internalType":"uint256[]","name":"_currentPowers","type":"uint256[]"},{"internalType":"uint8[]","name":"_v","type":"uint8[]"},{"internalType":"bytes32[]","name":"_r","type":"bytes32[]"},{"internalType":"bytes32[]","name":"_s","type":"bytes32[]"},{"internalType":"bytes32","name":"_theHash","type":"bytes32"},{"internalType":"uint256","name":"_powerThreshold","type":"uint256"}],"name":"checkValidatorSignatures","outputs":[],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"_tokenAddr","type":"address"}],"name":"delBridgeToken","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getBridgeTokenList","outputs":[{"components":[{"internalType":"address","name":"addr","type":"address"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"symbol","type":"string"},{"internalType":"uint8","name":"decimals","type":"uint8"}],"internalType":"struct FxBridgeLogicMigrate.BridgeToken[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"_fxBridgeId","type":"bytes32"},{"internalType":"uint256","name":"_powerThreshold","type":"uint256"},{"internalType":"address","name":"_fxOriginatedToken","type":"address"},{"internalType":"uint256","name":"_lastEventNonce","type":"uint256"},{"internalType":"bytes32","name":"_lastValsetCheckpoint","type":"bytes32"},{"internalType":"uint256","name":"_lastValsetNonce","type":"uint256"},{"internalType":"address[]","name":"_bridgeToken","type":"address[]"},{"internalType":"uint256[]","name":"_lastBatchNonce","type":"uint256[]"}],"name":"init","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_erc20Address","type":"address"}],"name":"lastBatchNonce","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_validators","type":"address[]"},{"internalType":"uint256[]","name":"_powers","type":"uint256[]"},{"internalType":"uint256","name":"_valsetNonce","type":"uint256"},{"internalType":"bytes32","name":"_fxBridgeId","type":"bytes32"}],"name":"makeCheckpoint","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_tokenContract","type":"address"},{"internalType":"bytes32","name":"_destination","type":"bytes32"},{"internalType":"bytes32","name":"_targetIBC","type":"bytes32"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"sendToFx","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_tokenAddr","type":"address"}],"name":"setFxOriginatedToken","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"state_fxBridgeId","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"state_fxOriginatedToken","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"state_lastBatchNonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"state_lastEventNonce","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"state_lastValsetCheckpoint","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"state_lastValsetNonce","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"state_powerThreshold","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_currentValidators","type":"address[]"},{"internalType":"uint256[]","name":"_currentPowers","type":"uint256[]"},{"internalType":"uint8[]","name":"_v","type":"uint8[]"},{"internalType":"bytes32[]","name":"_r","type":"bytes32[]"},{"internalType":"bytes32[]","name":"_s","type":"bytes32[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"},{"internalType":"address[]","name":"_destinations","type":"address[]"},{"internalType":"uint256[]","name":"_fees","type":"uint256[]"},{"internalType":"uint256[2]","name":"_nonceArray","type":"uint256[2]"},{"internalType":"address","name":"_tokenContract","type":"address"},{"internalType":"uint256","name":"_batchTimeout","type":"uint256"},{"internalType":"address","name":"_feeReceive","type":"address"}],"name":"submitBatch","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_newOwner","type":"address"}],"name":"transferOwner","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_newValidators","type":"address[]"},{"internalType":"uint256[]","name":"_newPowers","type":"uint256[]"},{"internalType":"uint256","name":"_newValsetNonce","type":"uint256"},{"internalType":"address[]","name":"_currentValidators","type":"address[]"},{"internalType":"uint256[]","name":"_currentPowers","type":"uint256[]"},{"internalType":"uint256","name":"_currentValsetNonce","type":"uint256"},{"internalType":"uint8[]","name":"_v","type":"uint8[]"},{"internalType":"bytes32[]","name":"_r","type":"bytes32[]"},{"internalType":"bytes32[]","name":"_s","type":"bytes32[]"}],"name":"updateValset","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
pragma abicoder v2;

/**
 * @title ILiquidityStakingV1
 * @author marginX
 *
 * @notice Partial interface for LiquidityStakingV1.
 */
interface ILiquidityStakingV1 {

  function getToken() external view returns (address);

  function getBorrowedBalance(address borrower) external view returns (uint256);

  function getBorrowerDebtBalance(address borrower) external view returns (uint256);

  function isBorrowingRestrictedForBorrower(address borrower) external view returns (bool);

  function getTimeRemainingInEpoch() external view returns (uint256);

  function inBlackoutWindow() external view returns (bool);

  // LS1Borrowing
  function borrow(uint256 amount) external;

  function repayBorrow(address borrower, uint256 amount) external;

  function getAllocatedBalanceCurrentEpoch(address borrower)
    external
    view
    returns (uint256);

  function getAllocatedBalanceNextEpoch(address borrower) external view returns (uint256);

  function getBorrowableAmount(address borrower) external view returns (uint256);

  // LS1DebtAccounting
  function repayDebt(address borrower, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ILiquidityStakingV1 } from '../../interfaces/ILiquidityStakingV1.sol';
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SP1Roles } from './SP1Roles.sol';

/**
 * @title SP1Balances
 * @author marginX
 *
 * @dev Contains common constants and functions related to token balances.
 */
abstract contract SP1Balances is
  SP1Roles
{
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  IERC20Upgradeable public TOKEN;

  ILiquidityStakingV1 public LIQUIDITY_STAKING;

  // ============ Constructor ============

  // ============ Public Functions ============

  function getAllocatedBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    return LIQUIDITY_STAKING.getAllocatedBalanceCurrentEpoch(address(this));
  }

  function getAllocatedBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    return LIQUIDITY_STAKING.getAllocatedBalanceNextEpoch(address(this));
  }

  function getBorrowableAmount()
    public
    view
    returns (uint256)
  {
    if (_IS_BORROWING_RESTRICTED_) {
      return 0;
    }
    return LIQUIDITY_STAKING.getBorrowableAmount(address(this));
  }

  function getBorrowedBalance()
    public
    view
    returns (uint256)
  {
    return LIQUIDITY_STAKING.getBorrowedBalance(address(this));
  }

  function getDebtBalance()
    public
    view
    returns (uint256)
  {
    return LIQUIDITY_STAKING.getBorrowerDebtBalance(address(this));
  }

  function getBorrowedAndDebtBalance()
    public
    view
    returns (uint256)
  {
    return getBorrowedBalance().add(getDebtBalance());
  }

  function getTokenBalance()
    public
    view
    returns (uint256)
  {
    return TOKEN.balanceOf(address(this));
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SP1Balances } from './SP1Balances.sol'; 

/**
 * @title SP1Borrowing
 * @author marginX
 *
 * @dev Handles calls to the LiquidityStaking contract to borrow and repay funds.
 */
abstract contract SP1Borrowing is
  SP1Balances
{
  using SafeMathUpgradeable for uint256;

  // ============ Events ============

  event Borrowed(
    uint256 amount,
    uint256 newBorrowedBalance
  );

  event RepaidBorrow(
    uint256 amount,
    uint256 newBorrowedBalance,
    bool isGuardianAction
  );

  event RepaidDebt(
    uint256 amount,
    uint256 newDebtBalance,
    bool isGuardianAction
  );

  // ============ Constructor ============

  // ============ External Functions ============

  /**
   * @notice Automatically repay or borrow to bring borrowed balance to the next allocated balance.
   *  Must be called during the blackout window, to ensure allocated balance will not change before
   *  the start of the next epoch. Reverts if there are insufficient funds to prevent a shortfall.
   *
   *  Can be called with eth_call to view amounts that will be borrowed or repaid.
   *
   * @return The newly borrowed amount.
   * @return The borrow amount repaid.
   * @return The debt amount repaid.
   */
  function autoPayOrBorrow()
    external
    nonReentrant
    onlyRole(BORROWER_ROLE)
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // Ensure we are in the blackout window.
    require(
      LIQUIDITY_STAKING.inBlackoutWindow(),
      'SP1Borrowing: Auto-pay may only be used during the blackout window'
    );

    // Get the borrowed balance, next allocated balance, and token balance.
    uint256 borrowedBalance = getBorrowedBalance();
    uint256 nextAllocatedBalance = getAllocatedBalanceNextEpoch();
    uint256 tokenBalance = getTokenBalance();

    // Return values.
    uint256 borrowAmount = 0;
    uint256 repayBorrowAmount = 0;
    uint256 repayDebtAmount = 0;

    if (borrowedBalance > nextAllocatedBalance) {
      // Make the necessary repayment due by the end of the current epoch.
      repayBorrowAmount = borrowedBalance.sub(nextAllocatedBalance);
      require(
        tokenBalance >= repayBorrowAmount,
        'SP1Borrowing: Insufficient funds to avoid falling short on repayment'
      );
      _repayBorrow(repayBorrowAmount, false);
    } else {
      // Borrow the max borrowable amount.
      borrowAmount = getBorrowableAmount();
      if (borrowAmount != 0) {
        _borrow(borrowAmount);
      }
    }

    // Finally, use remaining funds to pay any overdue debt.
    uint256 debtBalance = getDebtBalance();
    repayDebtAmount = MathUpgradeable.min(debtBalance, tokenBalance);
    if (repayDebtAmount != 0) {
      _repayDebt(repayDebtAmount, false);
    }

    return (borrowAmount, repayBorrowAmount, repayDebtAmount);
  }

  function borrow(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(BORROWER_ROLE)
  {
    // Disallow if the guardian has restricted borrowing.
    require(
      !_IS_BORROWING_RESTRICTED_,
      'SP1Borrowing: Cannot borrow while Restricted'
    );

    _borrow(amount);
  }

  function repayBorrow(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(BORROWER_ROLE)
  {
    _repayBorrow(amount, false);
  }

  function repayDebt(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(BORROWER_ROLE)
  {
    _repayDebt(amount, false);
  }

  // ============ Internal Functions ============

  function _borrow(
    uint256 amount
  )
    internal
  {
    LIQUIDITY_STAKING.borrow(amount);
    emit Borrowed(amount, getBorrowedBalance());
  }

  function _repayBorrow(
    uint256 amount,
    bool isGovernanceAction
  )
    internal
  {
    LIQUIDITY_STAKING.repayBorrow(address(this), amount);
    emit RepaidBorrow(amount, getBorrowedBalance(), isGovernanceAction);
  }

  function _repayDebt(
    uint256 amount,
    bool isGovernanceAction
  )
    internal
  {
    LIQUIDITY_STAKING.repayDebt(address(this), amount);
    emit RepaidDebt(amount, getDebtBalance(), isGovernanceAction);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SP1Storage } from './SP1Storage.sol';

/**
 * @title SP1Getters
 * @author marginX
 *
 * @dev Simple external getter functions.
 */
abstract contract SP1Getters is
  SP1Storage
{
  using SafeMathUpgradeable for uint256;

  // ============ External Functions ============

  /**
   * @notice Check whether a Target IBC is on the allowlist for exchange operations.
   *
   * @param  targetIBC  The Target IBC to check.
   *
   * @return Boolean `true` if the Target IBC is allowed, otherwise `false`.
   */
  function isTargetIBCAllowed(
    bytes32 targetIBC
  )
    external
    view
    returns (bool)
  {
    return _ALLOWED_TARGET_IBC_[targetIBC];
  }

  /**
   * @notice Check whether a Destination address is on the allowlist for exchange operations.
   *
   * @param  destination  The Destination address to check.
   *
   * @return Boolean `true` if the Destination address is allowed, otherwise `false`.
   */
  function isDestinationAllowed(
    bytes32 destination
  )
    external
    view
    returns (bool)
  {
    return _ALLOWED_DESTINATION_[destination];
  }

  /**
   * @notice Check whether a recipient is on the allowlist to receive withdrawals.
   *
   * @param  recipient  The recipient to check.
   *
   * @return Boolean `true` if the recipient is allowed, otherwise `false`.
   */
  function isRecipientAllowed(
    address recipient
  )
    external
    view
    returns (bool)
  {
    return _ALLOWED_RECIPIENTS_[recipient];
  }

  /**
   * @notice Get the amount approved by the guardian for external withdrawals.
   *  Note that withdrawals are always permitted if the amount is in excess of the borrowed amount.
   *
   * @return The amount approved for external withdrawals.
   */
  function getApprovedAmountForExternalWithdrawal()
    external
    view
    returns (uint256)
  {
    return _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_;
  }

  /**
   * @notice Check whether this borrower contract is restricted from new borrowing, as well as
   *  restricted from depositing borrowed funds to the exchange.
   *
   * @return Boolean `true` if the borrower is restricted, otherwise `false`.
   */
  function isBorrowingRestricted()
    external
    view
    returns (bool)
  {
    return _IS_BORROWING_RESTRICTED_;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SP1Storage } from './SP1Storage.sol';

/**
 * @title SP1Roles
 * @author marginX
 *
 * @dev Defines roles used in the MMProxyV1 contract. The hierarchy and powers of each role
 *  are described below. Not all roles need to be used.
 *
 *  Overview:
 *
 *    During operation of this contract, funds will flow between the following three
 *    contracts:
 *
 *        LiquidityStaking <> MMProxy <> FxBridge <> MarketMaker(FX-EVM)
 *
 *    Actions which move fund from left to right are called “open” actions, whereas actions which
 *    move funds from right to left are called “close” actions.
 *
 *    Also note that the “forced” actions (forced trade and forced withdrawal) require special care
 *    since they directly impact the financial risk of positions held on the exchange.
 *
 *  Roles:
 *
 *    GUARDIAN_ROLE
 *      | -> May perform “close” actions as defined above, but “forced” actions can only be taken
 *      |    if the borrower has an outstanding debt balance.
 *      | -> May restrict “open” actions as defined above, except w.r.t. funds in excess of the
 *      |    borrowed balance.
 *      | -> May approve a token amount to be withdrawn externally by the WITHDRAWAL_OPERATOR_ROLE
 *      |    to an allowed address.
 *      |
 *      +-- VETO_GUARDIAN_ROLE
 *            -> May veto forced trade requests initiated by the owner, during the waiting period.
 *
 *    OWNER_ROLE
 *      | -> May add or remove allowed recipients who may receive excess funds.
 *      | -> May add or remove allowed market maker address for use on the exchange.
 *      | -> May set ERC20 allowances on the LiquidityStakingV1 and FxBridge contracts.
 *      | -> May call the “forced” actions: forcedWithdrawalRequest and forcedTradeRequest.
 *      |
 *      +-- DELEGATION_ADMIN_ROLE
 *            |
 *            +-- BORROWER_ROLE
 *            |     -> May call functions on LiquidityStakingV1: autoPayOrBorrow, borrow, repay,
 *            |        and repayDebt.
 *            |
*            +-- EXCHANGE_OPERATOR_ROLE
 *            |     -> May call functions on StarkPerpetual: depositToExchange and
 *            |        withdrawFromExchange.
 *            |
 *            +-- WITHDRAWAL_OPERATOR_ROLE
 *                  -> May withdraw funds in excess of the borrowed balance to an allowed recipient.
 */
abstract contract SP1Roles is
  SP1Storage
{
  bytes32 public constant GUARDIAN_ROLE = keccak256('GUARDIAN_ROLE');
  bytes32 public constant VETO_GUARDIAN_ROLE = keccak256('VETO_GUARDIAN_ROLE');
  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant DELEGATION_ADMIN_ROLE = keccak256('DELEGATION_ADMIN_ROLE');
  bytes32 public constant BORROWER_ROLE = keccak256('BORROWER_ROLE');
  bytes32 public constant EXCHANGE_OPERATOR_ROLE = keccak256('EXCHANGE_OPERATOR_ROLE');
  bytes32 public constant WITHDRAWAL_OPERATOR_ROLE = keccak256('WITHDRAWAL_OPERATOR_ROLE');

  function __SP1Roles_init(
    address guardian
  )
    internal
  {
    // Assign GUARDIAN_ROLE.
    _setupRole(GUARDIAN_ROLE, guardian);

    // Assign OWNER_ROLE and DELEGATION_ADMIN_ROLE to the sender.
    _setupRole(OWNER_ROLE, msg.sender);
    _setupRole(DELEGATION_ADMIN_ROLE, msg.sender);

    // Set admins for all roles. (Don't use the default admin role.)
    _setRoleAdmin(GUARDIAN_ROLE, GUARDIAN_ROLE);
    _setRoleAdmin(VETO_GUARDIAN_ROLE, GUARDIAN_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(DELEGATION_ADMIN_ROLE, OWNER_ROLE);
    _setRoleAdmin(BORROWER_ROLE, DELEGATION_ADMIN_ROLE);
    _setRoleAdmin(EXCHANGE_OPERATOR_ROLE, DELEGATION_ADMIN_ROLE);
    _setRoleAdmin(WITHDRAWAL_OPERATOR_ROLE, DELEGATION_ADMIN_ROLE);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { AccessControlUpgradeable } from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title SP1Storage
 * @author marginX
 *
 * @dev Storage contract. Contains or inherits from all contracts with storage.
 */
abstract contract SP1Storage is
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  // ============ Modifiers ============

  /**
   * @dev Modifier to ensure the target IBC is allowed.
   */
  modifier onlyAllowedTargetIBC(
    bytes32 targetIBC
  ) {
    require(_ALLOWED_TARGET_IBC_[targetIBC], 'SP1Storage:  Target IBC is not on the allowlist');
    _;
  }

  /**
   * @dev Modifier to ensure the deposit destination is allowed.
   */
  modifier onlyAllowedDestination(
    bytes32 destination
  ) {
    require(_ALLOWED_DESTINATION_[destination], 'SP1Storage:  Destination is not on the allowlist');
    _;
  }

  /**
   * @dev Modifier to ensure the recipient is allowed.
   */
  modifier onlyAllowedRecipient(
    address recipient
  ) {
    require(_ALLOWED_RECIPIENTS_[recipient], 'SP1Storage: Recipient is not on the allowlist');
    _;
  }

  // ============ Storage ============

  mapping(bytes32 => bool) internal _ALLOWED_TARGET_IBC_;

  mapping(bytes32 => bool) internal _ALLOWED_DESTINATION_;

  mapping(address => bool) internal _ALLOWED_RECIPIENTS_;

  /// @dev Note that withdrawals are always permitted if the amount is in excess of the borrowed
  ///  amount. Also, this approval only applies to the primary ERC20 token, `TOKEN`.
  uint256 internal _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_;

  /// @dev Note that this is different from _IS_BORROWING_RESTRICTED_ in LiquidityStakingV1.
  bool internal _IS_BORROWING_RESTRICTED_;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IFxBridgeLogic } from "../../interfaces/IFxBridge.sol";
import { SP1Balances } from "./SP1Balances.sol";

/**
 * @title SP2Exchange
 * @author marginX
 *
 * @dev Handles calls to the FXBridge contract, for interacting with the MarketMaker in FX-EVM.
 *
 *  Standard exchange operation. The “forced” actions can only
 *  be called by the OWNER_ROLE or GUARDIAN_ROLE. Some other functions are also callable by
 *  the GUARDIAN_ROLE.
 *
 *  See SP1Roles, SP2Guardian, SP2Owner, and SP2Withdrawals.
 */
abstract contract SP2Exchange is SP1Balances {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ============ Constants ============

    // @notice Address to bridge usdt to FXCore.
    IFxBridgeLogic public FX_BRIDGE;

    // ============ Events ============

    event DepositedToExchange(
        address mmAddress,
        bytes32 recipient,
        address tokenType,
        bytes32 targetIBC,
        uint256 tokenAmount
    );

    // ============ Constructor ============

    // ============ External Functions ============

    /**
     * @notice Deposit funds to the MarginX Exchange.
     *
     *  IMPORTANT: The caller is responsible for providing `quantizedAmount` in the right units.
     *             Currently, the exchange collateral is USDT, denominated in ERC20 token units, but
     *             this could change.
     *
     * @param  quantizedAmount  The deposit amount denominated in the exchange base units.
     *
     * @return The ERC20 token amount spent.
     */
    function depositToExchange(
        bytes32 destination,
        bytes32 targetIBC,
        uint256 quantizedAmount
    )
        external
        nonReentrant
        onlyAllowedDestination(destination)
        onlyAllowedTargetIBC(targetIBC)
        onlyRole(EXCHANGE_OPERATOR_ROLE)
        returns (uint256)
    {
        // Deposit and get the deposited token amount.
        uint256 startingBalance = getTokenBalance();
        
        // Approved FxBridge contract to transfer token from this contract
        TOKEN.safeApprove(address(FX_BRIDGE), quantizedAmount);

        // Transfer token to the FX Market maker contract.
        FX_BRIDGE.sendToFx(
            address(TOKEN),
            destination,
            targetIBC,
            quantizedAmount
        );

        uint256 endingBalance = getTokenBalance();
        uint256 tokenAmount = startingBalance.sub(endingBalance);

        // Disallow depositing borrowed funds to the exchange if the guardian has restricted borrowing.
        if (_IS_BORROWING_RESTRICTED_) {
            require(
                endingBalance >= getBorrowedAndDebtBalance(),
                "SP2Exchange: Cannot deposit borrowed funds to the exchange while Restricted"
            );
        }

        emit DepositedToExchange(msg.sender, destination, address(TOKEN), targetIBC, tokenAmount);
        return tokenAmount;
    }

    // ============ Internal Functions ============

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IFxBridgeLogic } from '../../interfaces/IFxBridge.sol';
import { SP1Borrowing } from './SP1Borrowing.sol';
import { SP2Exchange } from './SP2Exchange.sol';

/**
 * @title SP2Guardian
 * @author marginX
 *
 * @dev Defines guardian powers, to be owned or delegated by marginX governance.
 */
abstract contract SP2Guardian is
  SP1Borrowing,
  SP2Exchange
{
  using SafeMathUpgradeable for uint256;

  // ============ Events ============

  event BorrowingRestrictionChanged(
    bool isBorrowingRestricted
  );

  // event GuardianVetoedForcedTradeRequest(
  //   bytes32 argsHash
  // );

  event GuardianUpdateApprovedAmountForExternalWithdrawal(
    uint256 amount
  );

  // ============ Constructor ============

  // ============ External Functions ============

  /**
   * @notice Approve an additional amount for external withdrawal by WITHDRAWAL_OPERATOR_ROLE.
   *
   * @param  amount  The additional amount to approve for external withdrawal.
   *
   * @return The new amount approved for external withdrawal.
   */
  function increaseApprovedAmountForExternalWithdrawal(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
    returns (uint256)
  {
    uint256 newApprovedAmount = _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_.add(
      amount
    );
    _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_ = newApprovedAmount;
    emit GuardianUpdateApprovedAmountForExternalWithdrawal(newApprovedAmount);
    return newApprovedAmount;
  }

  /**
   * @notice Set the approved amount for external withdrawal to zero.
   *
   * @return The amount that was previously approved for external withdrawal.
   */
  function resetApprovedAmountForExternalWithdrawal()
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
    returns (uint256)
  {
    uint256 previousApprovedAmount = _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_;
    _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_ = 0;
    emit GuardianUpdateApprovedAmountForExternalWithdrawal(0);
    return previousApprovedAmount;
  }

  /**
   * @notice Guardian method to restrict borrowing or depositing borrowed funds to the exchange.
   */
  function guardianSetBorrowingRestriction(
    bool isBorrowingRestricted
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
  {
    _IS_BORROWING_RESTRICTED_ = isBorrowingRestricted;
    emit BorrowingRestrictionChanged(isBorrowingRestricted);
  }

  /**
   * @notice Guardian method to repay this contract's borrowed balance, using this contract's funds.
   *
   * @param  amount  Amount to repay.
   */
  function guardianRepayBorrow(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
  {
    _repayBorrow(amount, true);
  }

  /**
   * @notice Guardian method to repay a debt balance owed by the borrower.
   *
   * @param  amount  Amount to repay.
   */
  function guardianRepayDebt(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
  {
    _repayDebt(amount, true);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SP1Borrowing } from './SP1Borrowing.sol';
import { SP2Exchange } from './SP2Exchange.sol';

/**
 * @title SP2Owner
 * @author marginX
 *
 * @dev Actions which may be called only by OWNER_ROLE. These include actions with a larger amount
 *  of control over the funds held by the contract.
 */
abstract contract SP2Owner is
  SP1Borrowing,
  SP2Exchange
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  /// @notice Time that must elapse before a queued forced trade request can be submitted.
  // uint256 public constant FORCED_TRADE_WAITING_PERIOD = 7 days;

  /// @notice Max time that may elapse after the waiting period before a queued forced trade
  ///  request expires.
  // uint256 public constant FORCED_TRADE_GRACE_PERIOD = 7 days;

  // ============ Events ============

  event UpdatedTargetIBC(
    bytes32 targetIBC,
    bool isAllowed
  );

  event UpdatedDestination(
    bytes32 destination,
    bool isAllowed
  );

  event UpdatedExternalRecipient(
    address recipient,
    bool isAllowed
  );

  // ============ External Functions ============

  /**
   * @notice Allow exchange functions to be called for a particular Target IBC.
   *
   *  Will revert if the Target IBC is not whitelisted in this contract.
   *
   * @param  targetIBC  The Target IBC to allow.
   */
  function allowTargetIBC(
    bytes32 targetIBC
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(!_ALLOWED_TARGET_IBC_[targetIBC], 'SP2Owner: Target IBC already allowed');
    _ALLOWED_TARGET_IBC_[targetIBC] = true;
    emit UpdatedTargetIBC(targetIBC, true);
  }

  /**
   * @notice Remove a Target IBC from the allowed list.
   *
   * @param  targetIBC  The Target IBC to disallow.
   */
  function disallowTargetIBC(
    bytes32 targetIBC
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(_ALLOWED_TARGET_IBC_[targetIBC], 'SP2Owner: Target IBC already disallowed');
    _ALLOWED_TARGET_IBC_[targetIBC] = false;
    emit UpdatedTargetIBC(targetIBC, false);
  }

    /**
   * @notice Allow exchange functions to be called for a particular Target IBC.
   *
   *  Will revert if the Target IBC is not whitelisted in this contract.
   *
   * @param  destination  The Target IBC to allow.
   */
  function allowDestination(
    bytes32 destination
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(!_ALLOWED_DESTINATION_[destination], 'SP2Owner: Destination already allowed');
    _ALLOWED_DESTINATION_[destination] = true;
    emit UpdatedDestination(destination, true);
  }

  /**
   * @notice Remove a Target IBC from the allowed list.
   *
   * @param  destination  The Target IBC to disallow.
   */
  function disallowDestination(
    bytes32 destination
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(_ALLOWED_DESTINATION_[destination], 'SP2Owner: Destination already disallowed');
    _ALLOWED_DESTINATION_[destination] = false;
    emit UpdatedDestination(destination, false);
  }

  /**
   * @notice Allow withdrawals of excess funds to be made to a particular recipient.
   *
   * @param  recipient  The recipient to allow.
   */
  function allowExternalRecipient(
    address recipient
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(!_ALLOWED_RECIPIENTS_[recipient], 'SP2Owner: Recipient already allowed');
    _ALLOWED_RECIPIENTS_[recipient] = true;
    emit UpdatedExternalRecipient(recipient, true);
  }

  /**
   * @notice Remove a recipient from the allowed list.
   *
   * @param  recipient  The recipient to disallow.
   */
  function disallowExternalRecipient(
    address recipient
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(_ALLOWED_RECIPIENTS_[recipient], 'SP2Owner: Recipient already disallowed');
    _ALLOWED_RECIPIENTS_[recipient] = false;
    emit UpdatedExternalRecipient(recipient, false);
  }



  /**
   * @notice Set ERC20 token allowance for the staking contract.
   *
   * @param  token   The ERC20 token to set the allowance for.
   * @param  amount  The new allowance amount.
   */
  function setStakingContractAllowance(
    address token,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    // SafeERC20 safeApprove requires setting to zero first.
    IERC20Upgradeable(token).safeApprove(address(LIQUIDITY_STAKING), 0);
    IERC20Upgradeable(token).safeApprove(address(LIQUIDITY_STAKING), amount);
  }

  // /**
  //  * @notice Set market maker contract address for the bridging
  //  *
  //  * @param  mmContract   The FX-EVM market maker contract which token will be sent to.
  //  */
  // function setMMContract(
  //     bytes32 mmContract
  // )
  //     external
  //     nonReentrant
  //     onlyRole(OWNER_ROLE)
  // {
  //     require(mmContract != bytes32(0),'Address 0');
  //     _setMMContract(mmContract);
  // }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import { IMerkleDistributorV1 } from '../../interfaces/IMerkleDistributorV1.sol';
import { SP2Exchange } from './SP2Exchange.sol';

/**
 * @title SP2Withdrawals
 * @author marginX
 *
 * @dev Actions which may be called only by WITHDRAWAL_OPERATOR_ROLE. Allows for withdrawing
 *  funds from the contract to external addresses that were approved by OWNER_ROLE.
 */
abstract contract SP2Withdrawals is
  SP2Exchange
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  // ============ Events ============

  event ExternalWithdrewToken(
    address recipient,
    uint256 amount
  );

  event ExternalWithdrewOtherToken(
    address token,
    address recipient,
    uint256 amount
  );

  event ExternalWithdrewEther(
    address recipient,
    uint256 amount
  );

  // ============ Constructor ============

  // ============ External Functions ============

  /**
   * @notice Withdraw a token amount in excess of the borrowed balance, or an amount approved by
   *  the GUARDIAN_ROLE.
   *
   *  The contract may hold an excess balance if, for example, additional funds were added by the
   *  contract owner for use with the same exchange account, or if profits were earned from
   *  activity on the exchange.
   *
   * @param  recipient  The recipient to receive tokens. Must be authorized by OWNER_ROLE.
   */
  function externalWithdrawToken(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(WITHDRAWAL_OPERATOR_ROLE)
    onlyAllowedRecipient(recipient)
  {
    // If we are approved for the full amount, then skip the borrowed balance check.
    uint256 approvedAmount = _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_;
    if (approvedAmount >= amount) {
      _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_ = approvedAmount.sub(amount);
    } else {
      uint256 owedBalance = getBorrowedAndDebtBalance();
      uint256 tokenBalance = getTokenBalance();
      require(tokenBalance > owedBalance, 'SP2Withdrawals: No withdrawable balance');
      uint256 availableBalance = tokenBalance.sub(owedBalance);
      require(amount <= availableBalance, 'SP2Withdrawals: Amount exceeds withdrawable balance');

      // Always decrease the approval amount.
      _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_ = 0;
    }

    TOKEN.safeTransfer(recipient, amount);
    emit ExternalWithdrewToken(recipient, amount);
  }

  /**
   * @notice Withdraw any ERC20 token balance other than the token used for borrowing.
   *
   * @param  recipient  The recipient to receive tokens. Must be authorized by OWNER_ROLE.
   */
  function externalWithdrawOtherToken(
    address token,
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(WITHDRAWAL_OPERATOR_ROLE)
    onlyAllowedRecipient(recipient)
  {
    require(
      token != address(TOKEN),
      'SP2Withdrawals: Cannot use this function to withdraw borrowed token'
    );
    IERC20Upgradeable(token).safeTransfer(recipient, amount);
    emit ExternalWithdrewOtherToken(token, recipient, amount);
  }

  /**
   * @notice Withdraw any ether.
   *
   *  Note: The contract is not expected to hold Ether so this is not normally needed.
   *
   * @param  recipient  The recipient to receive Ether. Must be authorized by OWNER_ROLE.
   */
  function externalWithdrawEther(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(WITHDRAWAL_OPERATOR_ROLE)
    onlyAllowedRecipient(recipient)
  {
    payable(recipient).transfer(amount);
    emit ExternalWithdrewEther(recipient, amount);
  }
}

// Contracts by marginX Foundation. Individual files are released under different licenses.
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {ILiquidityStakingV1} from "../interfaces/ILiquidityStakingV1.sol";
import {IFxBridgeLogic} from "../interfaces/IFxBridge.sol";

import {SP2Withdrawals} from "./impl/SP2Withdrawals.sol";
import {SP1Getters} from "./impl/SP1Getters.sol";
import {SP2Guardian} from "./impl/SP2Guardian.sol";
import {SP2Owner} from "./impl/SP2Owner.sol";

/**
 * @title MMProxyV1
 * @author marginX
 *
 * @notice Proxy contract allowing a LiquidityStaking borrower to use borrowed funds (as well as
 *  their own funds, if desired) on the MarginX L2 exchange. Restrictions are put in place to
 *  prevent borrowed funds being used outside the exchange. Furthermore, a guardian address is
 *  specified which has the ability to restrict borrows and make repayments.
 *
 *  Owner actions may be delegated to various roles as defined in SP1Roles. Other actions are
 *  available to guardian roles, to be nominated by marginX governance.
 */
contract MMProxy is
    Initializable,
    SP2Guardian,
    SP2Owner,
    SP2Withdrawals,
    SP1Getters,
    UUPSUpgradeable
{

    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ============ Constructor ============
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ============ External Functions ============

    function initialize(
        ILiquidityStakingV1 liquidityStaking,
        IERC20Upgradeable token,
        IFxBridgeLogic fxBridge,
        address guardian
    ) external initializer {
        LIQUIDITY_STAKING = liquidityStaking;
        TOKEN = token;
        FX_BRIDGE = fxBridge;
        TOKEN.safeApprove(address(LIQUIDITY_STAKING), type(uint256).max);
        __SP1Roles_init(guardian);
        __UUPSUpgradeable_init();
    }

    // ============ Internal Functions ============

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(OWNER_ROLE)
    {}
}