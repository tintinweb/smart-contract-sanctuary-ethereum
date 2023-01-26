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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {PriceAware} from "../utils/redstone/PriceAware.sol";
import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";
import {UMAOracleHelper} from "../utils/uma/UMAOracleHelper.sol";
import {IOptimisticOracleV2} from "../interfaces/uma/IOptimisticOracleV2.sol";

abstract contract OracleHouse is PriceAware {
    /**
     * @dev emitted after activeOracle is changed.
     * @param newOracleNumber uint256 oracle id.
     **/
    event ActiveOracleChanged(uint256 newOracleNumber);

    /// Custom errors

    /** Wrong or invalid input*/
    error OracleHouse_invalidInput();

    /** Not initialized*/
    error OracleHouse_notInitialized();

    /** No valid value returned*/
    error OracleHouse_noValue();

    enum OracleIds {
        redstone,
        uma,
        chainlink
    }

    /** @dev OracleIds: 0 = redstone, 1 = uma, 2 = chainlink */
    uint256 internal _activeOracle;

    /// redstone required state variables
    bytes32 private _tickerUsdFiat;
    bytes32 private _tickerReserveAsset;
    bytes32[] private _tickers;
    address private _trustedSigner;

    /// uma required state variables
    UMAOracleHelper private _umaOracleHelper;

    /// chainlink required state variables
    IAggregatorV3 private _addrUsdFiat;
    IAggregatorV3 private _addrReserveAsset;

    // solhint-disable-next-line func-name-mixedcase
    function _oracleHouse_init() internal {
        _oracle_redstone_init();
    }

    /**
     * @notice Returns the active oracle from House of Reserve.
     * @dev Must be implemented in House Of Reserve ONLY.
     */
    function activeOracle() external view virtual returns (uint256);

    /** @dev Override for House of Coin with called inputs from House Of Reserve. */
    function _getLatestPrice(address)
        internal
        view
        virtual
        returns (uint256 price)
    {
        if (_activeOracle == 0) {
            price = _getLatestPriceRedstone(_tickers);
        } else if (_activeOracle == 1) {
            price = _getLatestPriceUMA();
        } else if (_activeOracle == 2) {
            price = _getLatestPriceChainlink(_addrUsdFiat, _addrReserveAsset);
        }
    }

    /**
     * @dev Must be implemented in House of Reserve ONLY with admin restriction and call _setActiveOracle().
     * Must call _setActiveOracle().
     */
    function setActiveOracle(OracleIds id_) external virtual;

    /**
     * @notice Sets the activeOracle.
     * @dev  Restricted to admin only.
     * @param id_ restricted to enum OracleIds
     * Emits a {ActiveOracleChanged} event.
     */

    function _setActiveOracle(OracleIds id_) internal {
        _activeOracle = uint256(id_);
        emit ActiveOracleChanged(_activeOracle);
    }

    ///////////////////////////////
    /// Redstone oracle methods ///
    ///////////////////////////////

    /**
     * @dev emitted after the owner updates trusted signer
     * @param newSigner the address of the new signer
     **/
    event TrustedSignerChanged(address newSigner);

    /**
     * @dev emitted after tickers for Redstone-evm-connector change.
     * @param newtickerUsdFiat short string
     * @param newtickerReserveAsset short string
     **/
    event TickersChanged(
        bytes32 newtickerUsdFiat,
        bytes32 newtickerReserveAsset
    );

    // solhint-disable-next-line func-name-mixedcase
    function _oracle_redstone_init() private {
        _tickers.push(bytes32(0));
        _tickers.push(bytes32(0));
    }

    /**
     * Returns price in 8 decimal places.
     */
    function _getLatestPriceRedstone(bytes32[] memory tickers_)
        internal
        view
        virtual
        returns (uint256 price)
    {
        uint256[] memory oraclePrices = _getPricesFromMsg(tickers_);
        uint256 usdfiat = oraclePrices[0];
        uint256 usdReserveAsset = oraclePrices[1];
        if (usdfiat == 0 || usdReserveAsset == 0) {
            revert OracleHouse_noValue();
        }
        price = (usdReserveAsset * 1e8) / usdfiat;
    }

    /**
     * @notice Returns the state data of Redstone oracle.
     */
    function getRedstoneData()
        external
        view
        virtual
        returns (
            bytes32 tickerUsdFiat_,
            bytes32 tickerReserveAsset_,
            bytes32[] memory tickers_,
            address trustedSigner_
        )
    {
        tickerUsdFiat_ = _tickerUsdFiat;
        tickerReserveAsset_ = _tickerReserveAsset;
        tickers_ = _tickers;
        trustedSigner_ = _trustedSigner;
    }

    /**
     * @notice Checks that signer is authorized
     * @dev  Required by Redstone-evm-connector.
     * @param _receviedSigner address
     */
    function isSignerAuthorized(address _receviedSigner)
        public
        view
        override
        returns (bool)
    {
        return _receviedSigner == _trustedSigner;
    }

    /**
     * @dev See '_setTickers()'.
     * Must be implemented in House of Reserve ONLY with admin restriction.
     * Must call _setTickers().
     */
    function setTickers(
        string calldata tickerUsdFiat_,
        string calldata tickerReserveAsset_
    ) external virtual;

    /**
     * @notice  Sets the tickers required in '_getLatestPriceRedstone()'.
     * @param tickerUsdFiat_ short string (less than 32 characters)
     * @param tickerReserveAsset_ short string (less than 32 characters)
     * Emits a {TickersChanged} event.
     */
    function _setTickers(
        string memory tickerUsdFiat_,
        string memory tickerReserveAsset_
    ) internal {
        if (_tickers.length != 2) {
            revert OracleHouse_notInitialized();
        }
        bytes32 ticker1;
        bytes32 ticker2;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ticker1 := mload(add(tickerUsdFiat_, 32))
            ticker2 := mload(add(tickerReserveAsset_, 32))
        }
        _tickerUsdFiat = ticker1;
        _tickerReserveAsset = ticker2;

        _tickers[0] = _tickerUsdFiat;
        _tickers[1] = _tickerReserveAsset;

        emit TickersChanged(_tickerUsdFiat, _tickerReserveAsset);
    }

    /**
     * @dev See '_setTickers()'.
     * Must be implemented both in House of Reserve and Coin with admin restriction.
     */
    function authorizeSigner(address _trustedSigner) external virtual;

    /**
     * @notice  Authorize signer for price feed provider.
     * @dev  Restricted to admin only. Function required by Redstone-evm-connector.
     * @param newtrustedSigner address
     * Emits a {TrustedSignerChanged} event.
     */
    function _authorizeSigner(address newtrustedSigner) internal {
        if (newtrustedSigner == address(0)) {
            revert OracleHouse_invalidInput();
        }
        _trustedSigner = newtrustedSigner;
        emit TrustedSignerChanged(_trustedSigner);
    }

    //////////////////////////
    /// UMA oracle methods ///
    //////////////////////////

    /**
     * @dev emitted after the address for UMAHelper changes
     * @param newAddress of UMAHelper
     **/
    event UMAHelperAddressChanged(address newAddress);

    /**
     * Returns price in 8 decimal places.
     */
    function _getLatestPriceUMA() internal view returns (uint256 price) {
        price = _umaOracleHelper.getLastRequest(address(_addrReserveAsset));
    }

    /**
     * @dev See '_setUMAOracleHelper()'.
     * Must be implemented in House of Reserve with admin restriction.
     */
    function setUMAOracleHelper(address newAddress) external virtual;

    /**
     * @notice Sets a new address for the UMAOracleHelper
     * @dev Restricted to admin only.
     * @param newAddress for UMAOracleHelper.
     * Emits a {UMAHelperAddressChanged} event.
     */
    function _setUMAOracleHelper(address newAddress) internal {
        if (newAddress == address(0)) {
            revert OracleHouse_invalidInput();
        }
        _umaOracleHelper = UMAOracleHelper(newAddress);
        emit UMAHelperAddressChanged(newAddress);
    }

    ////////////////////////////////
    /// Chainlink oracle methods ///
    ////////////////////////////////

    /**
     * @dev emitted after chainlink addresses change.
     * @param _newAddrUsdFiat from chainlink.
     * @param _newAddrReserveAsset from chainlink.
     **/
    event ChainlinkAddressChange(
        address _newAddrUsdFiat,
        address _newAddrReserveAsset
    );

    /**
     * Returns price in 8 decimal places.
     */
    function _getLatestPriceChainlink(
        IAggregatorV3 addrUsdFiat_,
        IAggregatorV3 addrReserveAsset_
    ) internal view returns (uint256 price) {
        if (
            address(addrUsdFiat_) == address(0) ||
            address(addrReserveAsset_) == address(0)
        ) {
            revert OracleHouse_notInitialized();
        }
        (, int256 usdfiat, , , ) = addrUsdFiat_.latestRoundData();
        (, int256 usdreserve, , , ) = addrReserveAsset_.latestRoundData();
        if (usdfiat <= 0 || usdreserve <= 0) {
            revert OracleHouse_noValue();
        }
        price = (uint256(usdreserve) * 1e8) / uint256(usdfiat);
    }

    /**
     * @notice Returns the state data of Chainlink oracle.
     */
    function getChainlinkData()
        external
        view
        virtual
        returns (address addrUsdFiat_, address addrReserveAsset_)
    {
        addrUsdFiat_ = address(_addrUsdFiat);
        addrReserveAsset_ = address(_addrReserveAsset);
    }

    /**
     * @dev Must be implemented with admin restriction and call _setChainlinkAddrs().
     */
    function setChainlinkAddrs(address addrUsdFiat_, address addrReserveAsset_)
        external
        virtual;

    /**
     * @notice  Sets the chainlink addresses required in '_getLatestPriceChainlink()'.
     * @param addrUsdFiat_ address from chainlink.
     * @param addrReserveAsset_ address from chainlink.
     * Emits a {ChainlinkAddressChange} event.
     */
    function _setChainlinkAddrs(address addrUsdFiat_, address addrReserveAsset_)
        internal
    {
        if (addrUsdFiat_ == address(0) || addrReserveAsset_ == address(0)) {
            revert OracleHouse_invalidInput();
        }
        _addrUsdFiat = IAggregatorV3(addrUsdFiat_);
        _addrReserveAsset = IAggregatorV3(addrReserveAsset_);
        emit ChainlinkAddressChange(addrUsdFiat_, addrReserveAsset_);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title Account Liquidator
 * @author xocolatl.eth
 * @notice  Allows liquidation of users.
 */

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20Extension} from "./interfaces/IERC20Extension.sol";
import {IAssetsAccountant} from "./interfaces/IAssetsAccountant.sol";
import {IHouseOfCoin} from "./interfaces/IHouseOfCoin.sol";
import {IAggregatorV3} from "./interfaces/chainlink/IAggregatorV3.sol";
import {IHouseOfReserve} from "./interfaces/IHouseOfReserve.sol";
import {OracleHouse} from "./abstract/OracleHouse.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AccountLiquidator is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    OracleHouse
{
    /**
     * @dev Log when a user is in the danger zone of being liquidated.
     * @param user Address of user that is on margin call.
     * @param mintedAsset ERC20 address of user's token debt on margin call.
     * @param reserveAsset ERC20 address of user's backing collateral.
     */
    event MarginCall(
        address indexed user,
        address indexed mintedAsset,
        address indexed reserveAsset
    );

    /**
     * @dev Log when a user is liquidated.
     * @param userLiquidated Address of user that is being liquidated.
     * @param liquidator Address of user that liquidates.
     * @param collateralAmount sold.
     */
    event Liquidation(
        address indexed userLiquidated,
        address indexed liquidator,
        uint256 collateralAmount,
        uint256 debtAmount
    );

    /// Custom errors
    error AccountLiquidator_invalidInput();
    error AccountLiquidator_notApplicable();
    error AccountLiquidator_noBalances();
    error AccountLiquidator_notLiquidatable();

    IAssetsAccountant public assetsAccountant;
    IHouseOfCoin public houseOfCoin;
    IERC20Extension public backedAsset;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address houseOfCoin_, address assetsAccountant_)
        public
        initializer
    {
        if (houseOfCoin_ == address(0) || assetsAccountant_ == address(0)) {
            revert AccountLiquidator_invalidInput();
        }

        houseOfCoin = IHouseOfCoin(houseOfCoin_);
        assetsAccountant = IAssetsAccountant(assetsAccountant_);
        backedAsset = IERC20Extension(houseOfCoin.backedAsset());

        __AccessControl_init();
        __UUPSUpgradeable_init();
        _oracleHouse_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /** @dev See {OracleHouse-activeOracle}. */
    function activeOracle() external pure override returns (uint256) {
        revert AccountLiquidator_notApplicable();
    }

    /** @dev See {OracleHouse-setActiveOracle} */
    function setActiveOracle(OracleIds) external pure override {
        revert AccountLiquidator_notApplicable();
    }

    /** @dev See {OracleHouse-setTickers} */
    function setTickers(string memory, string memory) external pure override {
        revert AccountLiquidator_notApplicable();
    }

    /** @dev See {OracleHouse-getRedstoneData} */
    function getRedstoneData()
        external
        pure
        override
        returns (
            bytes32,
            bytes32,
            bytes32[] memory,
            address
        )
    {
        revert AccountLiquidator_notApplicable();
    }

    /**
     * @notice  See '_authorizeSigner()' in {OracleHouse}
     * @dev  Restricted to admin only.
     */
    function authorizeSigner(address newtrustedSigner)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _authorizeSigner(newtrustedSigner);
    }

    /**
     * @notice  See '_setUMAOracleHelper()' in {OracleHouse}
     * @dev  Should revert.
     */
    function setUMAOracleHelper(address) external pure override {
        revert AccountLiquidator_notApplicable();
    }

    /** @dev See {OracleHouse-getChainlinkData} */
    function getChainlinkData()
        external
        pure
        override
        returns (address, address)
    {
        revert AccountLiquidator_notApplicable();
    }

    /** @dev See {OracleHouse-setChainlinkAddrs} */
    function setChainlinkAddrs(address, address) external pure override {
        revert AccountLiquidator_notApplicable();
    }

    /**
     * @dev Call latest price according to activeOracle
     * @param hOfReserve_ address to get data for price feed.
     */
    function getLatestPrice(address hOfReserve_)
        public
        view
        returns (uint256 price)
    {
        price = _getLatestPrice(hOfReserve_);
    }

    /** @dev  Overriden See '_getLatestPrice()' in {OracleHouse} */
    function _getLatestPrice(address hOfReserve_)
        internal
        view
        override
        returns (uint256 price)
    {
        if (
            hOfReserve_ == address(0) ||
            !IAssetsAccountant(assetsAccountant).isARegisteredHouse(hOfReserve_)
        ) {
            revert AccountLiquidator_invalidInput();
        }
        IHouseOfReserve hOfReserve = IHouseOfReserve(hOfReserve_);
        uint256 activeOracle_ = hOfReserve.activeOracle();
        if (activeOracle_ == 0) {
            (, , bytes32[] memory tickers_, ) = hOfReserve.getRedstoneData();
            price = _getLatestPriceRedstone(tickers_);
        } else if (activeOracle_ == 1) {
            price = hOfReserve.getLatestPrice();
        } else if (activeOracle_ == 2) {
            (address addrUsdFiat_, address addrReserveAsset_) = hOfReserve
                .getChainlinkData();
            price = _getLatestPriceChainlink(
                IAggregatorV3(addrUsdFiat_),
                IAggregatorV3(addrReserveAsset_)
            );
        }
    }

    /**
     * @dev Called to liquidate a user or publish margin call event.
     * @param userToLiquidate address to liquidate.
     * @param houseOfReserve address in where user has collateral backing debt.
     */
    function liquidateUser(address userToLiquidate, address houseOfReserve)
        external
    {
        // Get all the required inputs.
        IHouseOfReserve hOfReserve = IHouseOfReserve(houseOfReserve);
        address reserveAsset = hOfReserve.reserveAsset();

        uint256 reserveTokenID_ = hOfReserve.reserveTokenID();
        uint256 backedTokenID_ = hOfReserve.backedTokenID();

        (uint256 reserveBal, ) = _checkBalances(
            userToLiquidate,
            reserveTokenID_,
            backedTokenID_
        );

        uint256 latestPrice = getLatestPrice(houseOfReserve);

        uint256 reserveAssetDecimals = IERC20Extension(reserveAsset).decimals();

        // Get health ratio
        uint256 healthRatio = houseOfCoin.computeUserHealthRatio(
            userToLiquidate,
            houseOfReserve
        );

        IHouseOfCoin.LiquidationParam memory liqParam = houseOfCoin
            .getLiqParams();
        
        // User on marginCall
        if (healthRatio <= liqParam.marginCallThreshold) {
            emit MarginCall(
                userToLiquidate,
                address(backedAsset),
                reserveAsset
            );
            // User at liquidation level
            if (healthRatio <= liqParam.liquidationThreshold) {
                // check liquidator ERC20 approval
                (
                    uint256 costofLiquidation,
                    uint256 collatPenaltyBal
                ) = _computeCostOfLiquidation(
                        reserveBal,
                        latestPrice,
                        reserveAssetDecimals,
                        liqParam
                    );
                require(
                    backedAsset.allowance(msg.sender, address(this)) >=
                        costofLiquidation,
                    "No allowance!"
                );

                _executeLiquidation(
                    userToLiquidate,
                    reserveTokenID_,
                    backedTokenID_,
                    costofLiquidation,
                    collatPenaltyBal
                );
            }
        } else {
            revert AccountLiquidator_notLiquidatable();
        }
    }

    /**
     * @notice  Function to get the theoretical cost of liquidating a user.
     * @param user address.
     * * @param houseOfReserve address in where user has collateral backing debt.
     */
    function computeCostOfLiquidation(address user, address houseOfReserve)
        public
        view
        returns (uint256 costAmount, uint256 collateralAtPenalty)
    {
        // Get all the required inputs.
        // Get all the required inputs.
        IHouseOfReserve hOfReserve = IHouseOfReserve(houseOfReserve);

        uint256 reserveTokenID_ = hOfReserve.reserveTokenID();
        uint256 backedTokenID_ = hOfReserve.backedTokenID();

        (uint256 reserveBal, ) = _checkBalances(
            user,
            reserveTokenID_,
            backedTokenID_
        );
        if (reserveBal == 0) {
            revert AccountLiquidator_noBalances();
        }

        uint256 latestPrice = getLatestPrice(houseOfReserve);

        uint256 reserveAssetDecimals = IERC20Extension(
            hOfReserve.reserveAsset()
        ).decimals();

        IHouseOfCoin.LiquidationParam memory liqParam = houseOfCoin
            .getLiqParams();

        (costAmount, collateralAtPenalty) = _computeCostOfLiquidation(
            reserveBal,
            latestPrice,
            reserveAssetDecimals,
            liqParam
        );

        return (costAmount, collateralAtPenalty);
    }

    /**
     * @dev  Internal function to query balances in {AssetsAccountant}
     */
    function _checkBalances(
        address user,
        uint256 reservesTokenID_,
        uint256 bAssetRTokenID_
    ) internal view returns (uint256 reserveBal, uint256 mintedCoinBal) {
        reserveBal = assetsAccountant.balanceOf(user, reservesTokenID_);
        mintedCoinBal = assetsAccountant.balanceOf(user, bAssetRTokenID_);
    }

    function _computeCostOfLiquidation(
        uint256 reserveBal,
        uint256 price,
        uint256 reserveAssetDecimals,
        IHouseOfCoin.LiquidationParam memory liqParam_
    )
        internal
        view
        returns (uint256 costofLiquidation, uint256 collatPenaltyBal)
    {
        uint256 discount = 1e18 - liqParam_.liquidationPricePenaltyDiscount;
        uint256 liqDiscountedPrice = (price * discount) / 1e18;

        collatPenaltyBal = (reserveBal * liqParam_.collateralPenalty) / 1e18;

        uint256 amountTemp = (collatPenaltyBal * liqDiscountedPrice) / 10**8;

        uint256 decimalDiff;
        uint256 backedAssetDecimals = backedAsset.decimals();

        if (reserveAssetDecimals > backedAssetDecimals) {
            decimalDiff = reserveAssetDecimals - backedAssetDecimals;
            amountTemp = amountTemp / 10**decimalDiff;
        } else {
            decimalDiff = backedAssetDecimals - reserveAssetDecimals;
            amountTemp = amountTemp * 10**decimalDiff;
        }

        costofLiquidation = amountTemp;
    }

    function _executeLiquidation(
        address user,
        uint256 reserveTokenID,
        uint256 backedTokenID,
        uint256 costofLiquidation,
        uint256 collatPenaltyBal
    ) internal {
        // Transfer of Assets.

        // BackedAsset to this contract.
        backedAsset.transferFrom(
            msg.sender,
            address(this),
            costofLiquidation
        );
        // Penalty collateral from liquidated user to liquidator.
        assetsAccountant.safeTransferFrom(
            user,
            msg.sender,
            reserveTokenID,
            collatPenaltyBal,
            ""
        );

        // Burning tokens and debt.
        // Burn 'costofLiquidation' debt amount from liquidated user in {AssetsAccountant}
        assetsAccountant.burn(user, backedTokenID, costofLiquidation);

        // Burn the received backedAsset tokens.
        IERC20Extension bAsset = IERC20Extension(backedAsset);
        bAsset.burn(address(this), costofLiquidation);

        // Emit event
        emit Liquidation(user, msg.sender, collatPenaltyBal, costofLiquidation);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IAssetsAccountant is IERC1155Upgradeable {
    /**
     * @dev Returns the address of the HouseOfReserve corresponding to reserveAsset.
     */
    function houseOfReserves(uint reserveAssetTokenID)
        external
        view
        returns (address);

    /**
     * @dev Returns the address of the HouseOfCoin corresponding to backedAsset.
     */
    function houseOfCoins(address backedAsset) external view returns (address);

    /**
     * @notice Returns true if house addres is registered.
     */
    function isARegisteredHouse(address house) external view returns (bool);

    /**
     * @dev Returns the reserve Token Ids that correspond to reserveAsset and backedAsset
     */
    function getReserveIds(address reserveAsset, address backedAsset)
        external
        view
        returns (uint[] memory);

    /**
     * @dev Registers a HouseOfReserve or HouseOfCoinMinting contract address in AssetsAccountant.
     * grants MINTER_ROLE and BURNER_ROLE to House
     * Requirements:
     * - the caller must have ADMIN_ROLE.
     */
    function registerHouse(address houseAddress, address asset) external;

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     * See {ERC1155-_mint}.
     * Requirements:
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Burns `amount` of tokens from `to`, of token type `id`.
     * See {ERC1155-_burn}.
     * Requirements:
     * - the caller must have the `BURNER_ROLE`.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IERC20Extension is IERC20Upgradeable, IAccessControlUpgradeable {
    function decimals() external view returns (uint);

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IHouseOfCoin {
    struct LiquidationParam {
        uint256 marginCallThreshold;
        uint256 liquidationThreshold;
        uint256 liquidationPricePenaltyDiscount;
        uint256 collateralPenalty;
    }

    /**
     * @dev Returns the type of House Contract.
     */
    function HOUSE_TYPE() external returns (bytes32);

    /**
     * @dev Returns the backedAsset that is minted by this HouseOfCoin.
     */
    function backedAsset() external view returns (address);

    /**
     * @notice  Function to mint ERC20 'backedAsset' of this HouseOfCoin.
     * @dev  Requires user to have reserves for this backed asset at HouseOfReserves.
     * @param reserveAsset ERC20 address of asset to be used to back the minted coins.
     * @param houseOfReserve Address of the {HouseOfReserves} contract that manages the 'reserveAsset'.
     * @param amount To mint.
     * Emits a {CoinMinted} event.
     */
    function mintCoin(
        address reserveAsset,
        address houseOfReserve,
        uint amount
    ) external;

    /**
     * @notice  Function to payback ERC20 'backedAsset' of this HouseOfCoin.
     * @dev Requires knowledge of the reserve asset used to back the minted coins.
     * @param _backedTokenID Token Id in {AssetsAccountant}, releases the reserve asset used in 'getTokenID'.
     * @param amount To payback.
     * Emits a {CoinPayback} event.
     */
    function paybackCoin(uint _backedTokenID, uint amount) external;

    /**
     * @notice  External function that returns the amount of backed asset coins user can mint with unused reserve asset.
     * @param user to check minting power.
     * @param reserveAsset Address of reserve asset.
     */
    function checkMintingPower(address user, address reserveAsset)
        external
        view
        returns (uint);

    /**
     * @notice  Function to get the health ratio of user.
     * @param user address.
     * @param houseOfReserve address in where user has collateral backing debt.
     */
    function computeUserHealthRatio(address user, address houseOfReserve)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the _liqParams as a struct
     */
    function getLiqParams() external view returns (LiquidationParam memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IOracle} from "./IOracle.sol";

interface IHouseOfReserve is IOracle {
    /**
     * @dev Returns the reserveAsset of this HouseOfReserve.
     */
    function reserveAsset() external view returns (address);

    /**
     * @dev Returns the backedAsset of this HouseOfReserve.
     */
    function backedAsset() external view returns (address);

    /**
     * @dev Returns the reserveTokenID (used in {AssetsAccountant}) for this HouseOfReserve.
     */
    function reserveTokenID() external view returns (uint);

    /**
     * @dev Returns the backedTokenID (used in {AssetsAccountant}) for this HouseOfReserve.
     */
    function backedTokenID() external view returns (uint);

    /**
     * @dev Returns the type of House Contract.
     */
    function HOUSE_TYPE() external returns (bytes32);

    /**
     * @dev Returns the maximum Loan-To-Value of this HouseOfReserve.
     */
    function maxLTVFactor() external view returns (uint256);

    /**
     * @dev Returns the liquidation factor of this HouseOfReserve.
     */
    function liquidationFactor() external view returns (uint256);

    /**
     * @dev Returns the latest price according to activeOracle
     */
    function getLatestPrice() external view returns (uint256 price);

    /**
     * @dev Deposit reserves in this contract on behalf caller.
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Withdraw reserves in this contract on behalf caller.
     */
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IOracle {
    function activeOracle() external view returns (uint256);

    function getRedstoneData()
        external
        view
        returns (
            bytes32 tickerUsdFiat_,
            bytes32 tickerReserveAsset_,
            bytes32[] memory tickers_,
            address trustedSigner_
        );

    function getChainlinkData()
        external
        view
        returns (address addrUsdFiat_, address addrReserveAsset_);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IAddressWhitelist {
    function addToWhitelist(address newElement) external;

    function removeFromWhitelist(address newElement) external;

    function isOnWhitelist(address newElement) external view returns (bool);

    function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUMAFinder} from "./IUMAFinder.sol";

/**
 * @title Simplified interface for UMA Optimistic V2 oracle interface.
 */
interface IOptimisticOracleV2 {
    // Struct representing the state of a price request.
    enum State {
        Invalid, // Never requested.
        Requested, // Requested, no other actions taken.
        Proposed, // Proposed, but not expired or disputed yet.
        Expired, // Proposed, not disputed, past liveness.
        Disputed, // Disputed, but no DVM price returned yet.
        Resolved, // Disputed and DVM price is available.
        Settled // Final price has been set in the contract (can get here from Expired or Resolved).
    }

    struct RequestSettings {
        bool eventBased; // True if the request is set to be event-based.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        bool callbackOnPriceProposed; // True if callbackOnPriceProposed callback is required.
        bool callbackOnPriceDisputed; // True if callbackOnPriceDisputed callback is required.
        bool callbackOnPriceSettled; // True if callbackOnPriceSettled callback is required.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        RequestSettings requestSettings; // Custom settings associated with a request.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    }

    function defaultLiveness() external view returns (uint256);

    function finder() external view returns (IUMAFinder);

    function getCurrentTime() external view returns (uint256);

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external returns (uint256 totalBond);

    /**
     * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
     * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
     * bond, so there is still profit to be made even if the reward is refunded.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setRefundOnDispute(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external;

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external;

    /**
     * @notice Sets the request to be an "event-based" request.
     * @dev Calling this method has a few impacts on the request:
     *
     * 1. The timestamp at which the request is evaluated is the time of the proposal, not the timestamp associated
     *    with the request.
     *
     * 2. The proposer cannot propose the "too early" value (TOO_EARLY_RESPONSE). This is to ensure that a proposer who
     *    prematurely proposes a response loses their bond.
     *
     * 3. RefundoOnDispute is automatically set, meaning disputes trigger the reward to be automatically refunded to
     *    the requesting contract.
     *
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setEventBased(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external;

    /**
     * @notice Sets which callbacks should be enabled for the request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param callbackOnPriceProposed whether to enable the callback onPriceProposed.
     * @param callbackOnPriceDisputed whether to enable the callback onPriceDisputed.
     * @param callbackOnPriceSettled whether to enable the callback onPriceSettled.
     */
    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external;

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param proposer address to set as the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external returns (uint256 totalBond);

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was value (the proposal was incorrect).
     */
    function disputePriceFor(
        address disputer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (uint256 totalBond);

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function settleAndGetPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (int256);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (uint256 payout);

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external view returns (Request memory);

    /**
     * @notice Returns the state of a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the State enum value.
     */
    function getState(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external view returns (State);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return true if price has resolved or settled, false otherwise.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external view returns (bool);

    function stampAncillaryData(bytes memory ancillaryData, address requester)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface IUMAFinder {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(
        bytes32 interfaceName,
        address implementationAddress
    ) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// Contract taken from redstone-evm-connector package;
/// Refer to: https://github.com/redstone-finance/redstone-evm-connector
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract PriceAware {
    using ECDSA for bytes32;

    uint256 internal constant _MAX_DATA_TIMESTAMP_DELAY = 3 * 60; // 3 minutes
    uint256 internal constant _MAX_BLOCK_TIMESTAMP_DELAY = 15; // 15 seconds

    /* ========== VIRTUAL FUNCTIONS (MAY BE OVERRIDEN IN CHILD CONTRACTS) ========== */

    function getMaxDataTimestampDelay() public view virtual returns (uint256) {
        return _MAX_DATA_TIMESTAMP_DELAY;
    }

    function getMaxBlockTimestampDelay() public view virtual returns (uint256) {
        return _MAX_BLOCK_TIMESTAMP_DELAY;
    }

    function isSignerAuthorized(address _receviedSigner)
        public
        view
        virtual
        returns (bool);

    function isTimestampValid(uint256 _receivedTimestamp)
        public
        view
        virtual
        returns (bool)
    {
        // Getting data timestamp from future seems quite unlikely
        // But we've already spent too much time with different cases
        // Where block.timestamp was less than dataPackage.timestamp.
        // Some blockchains may case this problem as well.
        // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
        // and allow data "from future" but with a small delay

        require(
            (block.timestamp + getMaxBlockTimestampDelay()) >
                _receivedTimestamp,
            "Data with future timestamps is not allowed"
        );

        return
            block.timestamp < _receivedTimestamp ||
            block.timestamp - _receivedTimestamp < getMaxDataTimestampDelay();
    }

    /* ========== FUNCTIONS WITH IMPLEMENTATION (CAN NOT BE OVERRIDEN) ========== */

    function _getPriceFromMsg(bytes32 symbol) internal view returns (uint256) {
        bytes32[] memory symbols = new bytes32[](1);
        symbols[0] = symbol;
        return _getPricesFromMsg(symbols)[0];
    }

    function _getPricesFromMsg(bytes32[] memory symbols)
        internal
        view
        returns (uint256[] memory)
    {
        // The structure of calldata witn n - data items:
        // The data that is signed (symbols, values, timestamp) are inside the {} brackets
        // [origina_call_data| ?]{[[symbol | 32][value | 32] | n times][timestamp | 32]}[size | 1][signature | 65]

        // 1. First we extract dataSize - the number of data items (symbol,value pairs) in the message
        uint8 dataSize; //Number of data entries
        // solhint-disable-next-line
        assembly {
            // Calldataload loads slots of 32 bytes
            // The last 65 bytes are for signature
            // We load the previous 32 bytes and automatically take the 2 least significant ones (casting to uint16)
            dataSize := calldataload(sub(calldatasize(), 97))
        }

        // 2. We calculate the size of signable message expressed in bytes
        // ((symbolLen(32) + valueLen(32)) * dataSize + timeStamp length
        uint16 messageLength = uint16(dataSize) * 64 + 32; //Length of data message in bytes

        // 3. We extract the signableMessage

        // (That's the high level equivalent 2k gas more expensive)
        // bytes memory rawData = msg.data.slice(msg.data.length - messageLength - 65, messageLength);

        bytes memory signableMessage;
        // solhint-disable-next-line
        assembly {
            signableMessage := mload(0x40)
            mstore(signableMessage, messageLength)
            // The starting point is callDataSize minus length of data(messageLength), signature(65) and size(1) = 66
            calldatacopy(
                add(signableMessage, 0x20),
                sub(calldatasize(), add(messageLength, 66)),
                messageLength
            )
            mstore(0x40, add(signableMessage, 0x20))
        }

        // 4. We first hash the raw message and then hash it again with the prefix
        // Following the https://github.com/ethereum/eips/issues/191 standard
        bytes32 hash = keccak256(signableMessage);
        bytes32 hashWithPrefix = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        // 5. We extract the off-chain signature from calldata

        // (That's the high level equivalent 2k gas more expensive)
        // bytes memory signature = msg.data.slice(msg.data.length - 65, 65);
        bytes memory signature;
        // solhint-disable-next-line
        assembly {
            signature := mload(0x40)
            mstore(signature, 65)
            calldatacopy(add(signature, 0x20), sub(calldatasize(), 65), 65)
            mstore(0x40, add(signature, 0x20))
        }

        // 6. We verify the off-chain signature against on-chain hashed data

        address signer = hashWithPrefix.recover(signature);
        require(isSignerAuthorized(signer), "Signer not authorized");

        // 7. We extract timestamp from callData

        uint256 dataTimestamp;
        // solhint-disable-next-line
        assembly {
            // Calldataload loads slots of 32 bytes
            // The last 65 bytes are for signature + 1 for data size
            // We load the previous 32 bytes
            dataTimestamp := calldataload(sub(calldatasize(), 98))
        }

        // 8. We validate timestamp
        //require(isTimestampValid(dataTimestamp), "Data timestamp is invalid");

        return _readFromCallData(symbols, uint256(dataSize), messageLength);
    }

    function _readFromCallData(
        bytes32[] memory symbols,
        uint256 dataSize,
        uint16 messageLength
    ) private pure returns (uint256[] memory) {
        uint256[] memory values;
        uint256 i;
        uint256 j;
        uint256 readyAssets;
        bytes32 currentSymbol;

        // We iterate directly through call data to extract the values for symbols
        // solhint-disable-next-line
        assembly {
            let start := sub(calldatasize(), add(messageLength, 66))

            values := msize()
            mstore(values, mload(symbols))
            mstore(0x40, add(add(values, 0x20), mul(mload(symbols), 0x20)))

            for {
                i := 0
            } lt(i, dataSize) {
                i := add(i, 1)
            } {
                currentSymbol := calldataload(add(start, mul(i, 64)))

                for {
                    j := 0
                } lt(j, mload(symbols)) {
                    j := add(j, 1)
                } {
                    if eq(
                        mload(add(add(symbols, 32), mul(j, 32))),
                        currentSymbol
                    ) {
                        mstore(
                            add(add(values, 32), mul(j, 32)),
                            calldataload(add(add(start, mul(i, 64)), 32))
                        )
                        readyAssets := add(readyAssets, 1)
                    }

                    if eq(readyAssets, mload(symbols)) {
                        i := dataSize
                    }
                }
            }
        }

        return (values);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IOptimisticOracleV2} from "../../interfaces/uma/IOptimisticOracleV2.sol";
import {IdentifierWhitelistInterface} from "../../interfaces/uma/IdentifierWhitelistInterface.sol";
import {IUMAFinder} from "../../interfaces/uma/IUMAFinder.sol";
import {IAddressWhitelist} from "../../interfaces/uma/IAddressWhitelist.sol";
import {UMAOracleInterfaces} from "./UMAOracleInterfaces.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAggregatorV3} from "../../interfaces/chainlink/IAggregatorV3.sol";

contract UMAOracleHelper {
    /**
     * @dev emitted after the {acceptableUMAPriceObsolence} changes
     * @param newTime of acceptable UMA price obsolence
     **/
    event AcceptableUMAPriceTimeChange(uint256 newTime);

    struct LastRequest {
        uint256 timestamp;
        IOptimisticOracleV2.State state;
        uint256 resolvedPrice;
        address proposer;
    }

    // Finder for UMA contracts.
    IUMAFinder public finder;

    // Unique identifier for price feed ticker.
    bytes32 private priceIdentifier;

    // The collateral currency used to back the positions in this contract.
    IERC20 public stakeCollateralCurrency;

    uint256 public acceptableUMAPriceObselence;

    LastRequest internal _lastRequest;

    constructor(
        address _stakeCollateralCurrency,
        address _finderAddress,
        bytes32 _priceIdentifier,
        uint256 _acceptableUMAPriceObselence
    ) {
        finder = IUMAFinder(_finderAddress);
        require(
            _getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier),
            "Unsupported price identifier"
        );
        require(
            _getAddressWhitelist().isOnWhitelist(_stakeCollateralCurrency),
            "Unsupported collateral type"
        );
        stakeCollateralCurrency = IERC20(_stakeCollateralCurrency);
        priceIdentifier = _priceIdentifier;
        setAcceptableUMAPriceObsolence(_acceptableUMAPriceObselence);
    }

    /**
     * Returns computed price in 8 decimal places.
     * @dev Requires chainlink price feed address for reserve asset.
     * Requires:
     * - price settled time is not greater than acceptableUMAPriceObselence.
     * - last request proposed price is settled according to UMA process:
     *   https://docs.umaproject.org/protocol-overview/how-does-umas-oracle-work
     */
    function getLastRequest(address addrChainlinkReserveAsset_)
        external
        view
        returns (uint256 computedPrice)
    {
        uint256 priceObsolence = block.timestamp > _lastRequest.timestamp
            ? block.timestamp - _lastRequest.timestamp
            : type(uint256).max;
        require(
            _lastRequest.state == IOptimisticOracleV2.State.Settled,
            "Not settled!"
        );
        require(priceObsolence < acceptableUMAPriceObselence, "Price too old!");
        (, int256 usdreserve, , , ) = IAggregatorV3(addrChainlinkReserveAsset_)
            .latestRoundData();
        computedPrice =
            (uint256(usdreserve) * 1e18) /
            _lastRequest.resolvedPrice;
    }

    // Requests a price for `priceIdentifier` at `requestedTime` from the Optimistic Oracle.
    function requestPrice() external {
        _checkLastRequest();

        uint256 requestedTime = block.timestamp;
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        oracle.requestPrice(
            priceIdentifier,
            requestedTime,
            "",
            IERC20(stakeCollateralCurrency),
            0
        );
        _resetLastRequest(requestedTime, IOptimisticOracleV2.State.Requested);
    }

    function requestPriceWithReward(uint256 rewardAmount) external {
        _checkLastRequest();
        require(
            stakeCollateralCurrency.allowance(msg.sender, address(this)) >=
                rewardAmount,
            "No erc20-approval"
        );
        IOptimisticOracleV2 oracle = _getOptimisticOracle();

        stakeCollateralCurrency.approve(address(oracle), rewardAmount);

        uint256 requestedTime = block.timestamp;

        oracle.requestPrice(
            priceIdentifier,
            requestedTime,
            "",
            IERC20(stakeCollateralCurrency),
            rewardAmount
        );

        _resetLastRequest(requestedTime, IOptimisticOracleV2.State.Requested);
    }

    function setCustomLivenessLastRequest(uint256 time) external {
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        oracle.setCustomLiveness(
            priceIdentifier,
            _lastRequest.timestamp,
            "",
            time
        );
    }

    function changeBondLastPriceRequest(uint256 bond) external {
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        oracle.setBond(priceIdentifier, _lastRequest.timestamp, "", bond);
    }

    function computeTotalBondLastRequest()
        public
        view
        returns (uint256 totalBond)
    {
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        IOptimisticOracleV2.Request memory request = oracle.getRequest(
            address(this),
            priceIdentifier,
            _lastRequest.timestamp,
            ""
        );
        totalBond = request.requestSettings.bond + request.finalFee;
    }

    /**
     * @dev Proposed price should be in 18 decimals per specification:
     * https://github.com/UMAprotocol/UMIPs/blob/master/UMIPs/umip-139.md
     */
    function proposePriceLastRequest(uint256 proposedPrice) external {
        uint256 totalBond = computeTotalBondLastRequest();
        require(
            stakeCollateralCurrency.allowance(msg.sender, address(this)) >=
                totalBond,
            "No allowance for propose bond"
        );
        stakeCollateralCurrency.transferFrom(
            msg.sender,
            address(this),
            totalBond
        );
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        stakeCollateralCurrency.approve(address(oracle), totalBond);
        oracle.proposePrice(
            address(this),
            priceIdentifier,
            _lastRequest.timestamp,
            "",
            int256(proposedPrice)
        );
        _lastRequest.proposer = msg.sender;
        _lastRequest.state = IOptimisticOracleV2.State.Proposed;
    }

    function settleLastRequestAndGetPrice() external returns (uint256 price) {
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        int256 settledPrice = oracle.settleAndGetPrice(
            priceIdentifier,
            _lastRequest.timestamp,
            ""
        );
        require(settledPrice > 0, "Settle Price Error!");
        _lastRequest.resolvedPrice = uint256(settledPrice);
        _lastRequest.state = IOptimisticOracleV2.State.Settled;
        stakeCollateralCurrency.transfer(
            _lastRequest.proposer,
            computeTotalBondLastRequest()
        );
        price = uint256(settledPrice);
    }

    /**
     * @notice Sets a new acceptable UMA price feed obsolence time.
     * @dev Restricted to admin only.
     * @param _newTime for acceptable UMA price feed obsolence.
     * Emits a {AcceptableUMAPriceTimeChange} event.
     */
    function setAcceptableUMAPriceObsolence(uint256 _newTime) public {
        if (_newTime < 10 minutes) {
            // NewTime is too small
            revert("Invalid input");
        }
        acceptableUMAPriceObselence = _newTime;
        emit AcceptableUMAPriceTimeChange(_newTime);
    }

    function _checkLastRequest() internal view {
        if (_lastRequest.timestamp != 0) {
            require(
                _lastRequest.state == IOptimisticOracleV2.State.Settled,
                "Last request not settled!"
            );
        }
    }

    function _resetLastRequest(
        uint256 requestedTime,
        IOptimisticOracleV2.State state
    ) internal {
        _lastRequest.timestamp = requestedTime;
        _lastRequest.state = state;
        _lastRequest.resolvedPrice = 0;
        _lastRequest.proposer = address(0);
    }

    function _getIdentifierWhitelist()
        internal
        view
        returns (IdentifierWhitelistInterface)
    {
        return
            IdentifierWhitelistInterface(
                finder.getImplementationAddress(
                    UMAOracleInterfaces.IdentifierWhitelist
                )
            );
    }

    function _getAddressWhitelist() internal view returns (IAddressWhitelist) {
        return
            IAddressWhitelist(
                finder.getImplementationAddress(
                    UMAOracleInterfaces.CollateralWhitelist
                )
            );
    }

    function _getOptimisticOracle()
        internal
        view
        returns (IOptimisticOracleV2)
    {
        return
            IOptimisticOracleV2(
                finder.getImplementationAddress("OptimisticOracleV2")
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library UMAOracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
    bytes32 public constant ChildMessenger = "ChildMessenger";
    bytes32 public constant OracleHub = "OracleHub";
    bytes32 public constant OracleSpoke = "OracleSpoke";
}