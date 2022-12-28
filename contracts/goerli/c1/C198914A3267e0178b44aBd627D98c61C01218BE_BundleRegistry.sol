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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IdRegistry} from "./IdRegistry.sol";
import {NameRegistry} from "./NameRegistry.sol";

/**
 * @title BundleRegistry
 * @author varunsrin (@v)
 * @custom:version 2.0.0
 *
 * @notice BundleRegistry allows user to register a Farcaster Name and Farcaster ID in a single
 *         transaction by wrapping around the IdRegistry and NameRegistry contracts, saving gas and
 *         reducing complexity for the caller.
 */
contract BundleRegistry is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Revert when the caller does not have the authority to perform the action
    error Unauthorized();

    /// @dev Revert when excess funds could not be sent back to the caller
    error CallFailed();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Emit when the trustedCaller is changed by the owner after the contract is deployed
    event ChangeTrustedCaller(address indexed trustedCaller, address indexed owner);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The data required to trustedBatchRegister a single user
    struct BatchUser {
        address to;
        bytes16 username;
    }

    /// @dev The only address that can call trustedRegister and partialTrustedRegister
    address internal trustedCaller;

    /// @dev The address of the IdRegistry contract
    IdRegistry internal immutable idRegistry;

    /// @dev The address of the NameRegistry UUPS Proxy contract
    NameRegistry internal immutable nameRegistry;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The default homeUrl value for the IdRegistry call, to be used until Hubs are launched
    string internal constant DEFAULT_URL = "https://www.farcaster.xyz/";

    /**
     * @notice Configure the addresses of the Registry contracts and the trusted caller which is
     *        allowed to register during the invitation phase.
     *
     * @param _idRegistry The address of the IdRegistry contract
     * @param _nameRegistry The address of the NameRegistry UUPS Proxy contract
     * @param _trustedCaller The address that can call trustedRegister and partialTrustedRegister
     */
    constructor(
        address _idRegistry,
        address _nameRegistry,
        address _trustedCaller
    ) Ownable() {
        idRegistry = IdRegistry(_idRegistry);
        nameRegistry = NameRegistry(_nameRegistry);
        trustedCaller = _trustedCaller;
    }

    /**
     * @notice Register an fid and an fname during the final Mainnet phase, where registration is
     *         open to everyone.
     */
    function register(
        address to,
        address recovery,
        string calldata url,
        bytes16 username,
        bytes32 secret
    ) external payable {
        // Audit: is it possible to end up in a state where one passes but the other fails?
        idRegistry.register(to, recovery, url);

        nameRegistry.register{value: msg.value}(username, to, secret, recovery);

        // Return any funds returned by the NameRegistry back to the caller
        if (address(this).balance > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            if (!success) revert CallFailed();
        }
    }

    /**
     * @notice Register an fid and an fname during the first Mainnet phase, where registration of
     *         the fid is available to all, but registration of the fname can only be performed by
     *         the Farcaster Invite Server (trustedCaller)
     */
    function partialTrustedRegister(
        address to,
        address recovery,
        string calldata url,
        bytes16 username,
        uint256 inviter
    ) external payable {
        // Do not allow anyone except the Farcaster Invite Server (trustedCaller) to call this
        if (msg.sender != trustedCaller) revert Unauthorized();

        // Audit: is it possible to end up in a state where one passes but the other fails?
        idRegistry.register(to, recovery, url);
        nameRegistry.trustedRegister(username, to, recovery, inviter, idRegistry.idOf(to));
    }

    /**
     * @notice Register an fid and an fname during the Goerli phase, where registration can only be
     *         performed by the Farcaster Invite Server (trustedCaller)
     */
    function trustedRegister(
        address to,
        address recovery,
        string calldata url,
        bytes16 username,
        uint256 inviter
    ) external payable {
        // Do not allow anyone except the Farcaster Invite Server (trustedCaller) to call this
        if (msg.sender != trustedCaller) revert Unauthorized();

        // Audit: is it possible to end up in a state where one passes but the other fails?
        idRegistry.trustedRegister(to, recovery, url);
        nameRegistry.trustedRegister(username, to, recovery, inviter, idRegistry.idOf(to));
    }

    /**
     * @notice Register multiple fids and fname during a migration to a new network, where
     *         registration can only be performed by the Farcaster Invite Server (trustedCaller).
     *         Recovery address, inviter, invitee and homeUrl are initialized to default values
     *         during this migration.
     */
    function trustedBatchRegister(BatchUser[] calldata users) external {
        // Do not allow anyone except the Farcaster Invite Server (trustedCaller) to call this
        if (msg.sender != trustedCaller) revert Unauthorized();

        for (uint256 i = 0; i < users.length; i++) {
            idRegistry.trustedRegister(users[i].to, address(0), DEFAULT_URL);
            nameRegistry.trustedRegister(users[i].username, users[i].to, address(0), 0, 0);
        }
    }

    /**
     * @notice Change the trusted caller that can call trustedRegister and partialTrustedRegister
     */
    function changeTrustedCaller(address newTrustedCaller) external onlyOwner {
        trustedCaller = newTrustedCaller;
        emit ChangeTrustedCaller(newTrustedCaller, msg.sender);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IdRegistry
 * @author @v
 * @custom:version 2.0.0
 *
 * @notice IdRegistry enables any ETH address to claim a unique Farcaster ID (fid). An address
 *         can only custody one fid at a time and may transfer it to another address. The Registry
 *         starts in a trusted mode where only a trusted caller can register an fid and can move
 *         to an untrusted mode where any address can register an fid. The Registry implements
 *         a recovery system which allows the custody address to nominate a recovery address that
 *         can transfer the fid to a new address after a delay.
 */
contract IdRegistry is ERC2771Context, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Revert when the caller does not have the authority to perform the action
    error Unauthorized();

    /// @dev Revert when the caller is required to have an fid but does not have one.
    error HasNoId();

    /// @dev Revert when the destination is required to be empty, but has an fid.
    error HasId();

    /// @dev Revert if trustedRegister is invoked after trustedCallerOnly is disabled
    error Registrable();

    /// @dev Revert if register is invoked before trustedCallerOnly is disabled
    error Invitable();

    /// @dev Revert if a recovery operation is called when there is no active recovery.
    error NoRecovery();

    /// @dev Revert when completeRecovery() is called before the escrow period has elapsed.
    error Escrow();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emit an event when a new Farcaster ID is registered.
     *
     * @param to       The custody address that owns the fid
     * @param id       The fid that was registered.
     * @param recovery The address that can initiate a recovery request for the fid
     * @param url      The home url of the fid
     */
    event Register(address indexed to, uint256 indexed id, address recovery, string url);

    /**
     * @dev Emit an event when a Farcaster ID is transferred to a new custody address.
     *
     * @param from The custody address that previously owned the fid
     * @param to   The custody address that now owns the fid
     * @param id   The fid that was transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /**
     * @dev Emit an event when a Farcaster ID's home url is updated
     *
     * @param id  The fid whose home url was updated.
     * @param url The new home url.
     */
    event ChangeHome(uint256 indexed id, string url);

    /**
     * @dev Emit an event when a Farcaster ID's recovery address is updated
     *
     * @param id       The fid whose recovery address was updated.
     * @param recovery The new recovery address.
     */
    event ChangeRecoveryAddress(uint256 indexed id, address indexed recovery);

    /**
     * @dev Emit an event when a recovery request is initiated for a Farcaster Id
     *
     * @param from The custody address of the fid being recovered.
     * @param to   The destination address for the fid when the recovery is completed.
     * @param id   The id being recovered.
     */
    event RequestRecovery(address indexed from, address indexed to, uint256 indexed id);

    /**
     * @dev Emit an event when a recovery request is cancelled
     *
     * @param by  The address that cancelled the recovery request
     * @param id  The id being recovered.
     */
    event CancelRecovery(address indexed by, uint256 indexed id);

    /**
     * @dev Emit an event when the trusted caller is modified.
     *
     * @param trustedCaller The address of the new trusted caller.
     */
    event ChangeTrustedCaller(address indexed trustedCaller);

    /**
     * @dev Emit an event when the trusted only state is disabled.
     */
    event DisableTrustedOnly();

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 private constant ESCROW_PERIOD = 3 days;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The last farcaster id that was issued.
     */
    uint256 internal idCounter;

    /**
     * @dev The Farcaster Invite service address that is allowed to call trustedRegister.
     */
    address internal trustedCaller;

    /**
     * @dev The address is allowed to call _completeTransferOwnership() and become the owner. Set to
     *      address(0) when no ownership transfer is pending.
     */
    address internal pendingOwner;

    /**
     * @dev Allows calling trustedRegister() when set 1, and register() when set to 0. The value is
     *      set to 1 and can be changed to 0, but never back to 1.
     */
    uint256 internal trustedOnly = 1;

    /**
     * @notice Maps each address to a fid, or zero if it does not own a fid.
     */
    mapping(address => uint256) public idOf;

    /**
     * @dev Maps each fid to an address that can initiate a recovery.
     */
    mapping(uint256 => address) internal recoveryOf;

    /**
     * @dev Maps each fid to the timestamp at which the recovery request was started. This is set
     *      to zero when there is no active recovery.
     */
    mapping(uint256 => uint256) internal recoveryClockOf;

    /**
     * @dev Maps each fid to the destination for the last recovery attempted. This value is left
     *      dirty to save gas and a non-zero value does not indicate an active recovery.
     */
    mapping(uint256 => address) internal recoveryDestinationOf;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the owner of the contract to the deployer and configure the trusted forwarder.
     *
     * @param _forwarder The address of the ERC2771 forwarder contract that this contract trusts to
     *                  verify the authenticity of signed meta-transaction requests.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address _forwarder) ERC2771Context(_forwarder) Ownable() {}

    /*//////////////////////////////////////////////////////////////
                             REGISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register a new, unique Farcaster ID (fid) for an address that doesn't have one. This
     *        method can be called by anyone when trustedOnly is set to 0.
     *
     * @param to       The address which will control the fid
     * @param recovery The address which can recover the fid
     * @param url      The home url for the fid's off-chain data
     */
    function register(
        address to,
        address recovery,
        string calldata url
    ) external {
        // Perf: Don't check to == address(0) to save 29 gas since 0x0 can only register 1 fid

        if (trustedOnly == 1) revert Invitable();

        _unsafeRegister(to, recovery);

        // Perf: instead of returning the id from _unsafeRegister, fetch the latest value of idCounter
        emit Register(to, idCounter, recovery, url);
    }

    /**
     * @notice Register a new unique Farcaster ID (fid) for an address that does not have one. This
     *         can only be invoked by the trusted caller when trustedOnly is set to 1.
     *
     * @param to       The address which will control the fid
     * @param recovery The address which can recover the fid
     * @param url      The home url for the fid's off-chain data
     */
    function trustedRegister(
        address to,
        address recovery,
        string calldata url
    ) external {
        // Perf: Don't check to == address(0) to save 29 gas since 0x0 can only register 1 fid

        if (trustedOnly == 0) revert Registrable();

        // Perf: Check msg.sender instead of msgSender() because saves 100 gas and trusted caller
        // doesn't need meta transactions
        if (msg.sender != trustedCaller) revert Unauthorized();

        _unsafeRegister(to, recovery);

        // Assumption: the most recent value of the idCounter must equal the id of this user
        emit Register(to, idCounter, recovery, url);
    }

    /**
     * @notice Emit an event with a new home url if the caller owns an fid. This function supports
     *         ERC 2771 meta-transactions and can be called via a relayer.
     *
     * @param url The new home url for the fid
     */
    function changeHome(string calldata url) external {
        uint256 id = idOf[_msgSender()];
        if (id == 0) revert HasNoId();

        emit ChangeHome(id, url);
    }

    /**
     * @dev Registers a new, unique fid and sets up a recovery address for a caller without
     *      checking any invariants or emitting events.
     */
    function _unsafeRegister(address to, address recovery) internal {
        // Perf: inlining this can save ~ 20-40 gas per call at the expense of readability
        if (idOf[to] != 0) revert HasId();

        unchecked {
            idCounter++;
        }

        // Incrementing before assigning ensures that 0 is never issued as a valid ID.
        idOf[to] = idCounter;
        recoveryOf[idCounter] = recovery;
    }

    /*//////////////////////////////////////////////////////////////
                             TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer the fid owned by this address to another address that does not have an fid.
     *         Supports ERC 2771 meta-transactions and can be called via a relayer.
     *
     * @param to The address to transfer the fid to.
     */
    function transfer(address to) external {
        address sender = _msgSender();
        uint256 id = idOf[sender];

        // Ensure that the caller owns an fid and that the destination address does not.
        if (id == 0) revert HasNoId();
        if (idOf[to] != 0) revert HasId();

        _unsafeTransfer(id, sender, to);
    }

    /**
     * @dev Transfer the fid to another address, clear the recovery address and reset active
     *      recovery requests, without checking any invariants.
     */
    function _unsafeTransfer(
        uint256 id,
        address from,
        address to
    ) internal {
        idOf[to] = id;
        delete idOf[from];

        // Perf: clear any active recovery requests, but check if they exist before deleting
        // because this usually already zero
        if (recoveryClockOf[id] != 0) delete recoveryClockOf[id];
        recoveryOf[id] = address(0);

        emit Transfer(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                             RECOVERY LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * INVARIANT 1: If msgSender() is a recovery address for another address, that address
     *              must own an fid
     *
     *  if _msgSender() == recoveryOf[idOf[addr]], then idOf[addr] != 0 during requestRecovery(),
     *  completeRecovery() and cancelRecovery()
     *
     *
     * 1. at the start, idOf[addr] = 0 && recoveryOf[idOf[addr]] == address(0) ∀ addr
     * 2. _msgSender() != address(0) ∀ _msgSender()
     * 3. recoveryOf[addr] becomes non-zero only in register(), trustedRegister() and
     *    changeRecoveryAddress(), which requires idOf[addr] != 0
     * 4. idOf[addr] becomes 0 only in transfer() and completeRecovery(), which requires
     *    recoveryOf[addr] == address(0)
     **/

    /**
     * INVARIANT 2: If an address has a non-zero recoveryClock, it must also have an fid
     *
     * if recoveryClockOf[idOf[address]] != 0 then idOf[addr] != 0
     *
     * 1. at the start, idOf[addr] = 0 and recoveryClockOf[idOf[addr]] == 0 ∀ addr
     * 2. recoveryClockOf[idOf[addr]] becomes non-zero only in requestRecovery(), which
     *    requires idOf[addr] != 0
     * 3. idOf[addr] becomes zero only in transfer() and completeRecovery(), which requires
     *    recoveryClockOf[id[addr]] == 0
     */

    /**
     * @notice Change the recovery address of the fid owned by this address and reset active
     *         recovery requests. Supports ERC 2771 meta-transactions and can be called by a
     *         relayer.
     *
     * @param recovery The address which can recover the fid (set to 0x0 to disable recovery)
     */
    function changeRecoveryAddress(address recovery) external {
        uint256 id = idOf[_msgSender()];
        if (id == 0) revert HasNoId();

        recoveryOf[id] = recovery;

        // Perf: clear any active recovery requests, but check if they exist before deleting
        // because this usually already zero
        if (recoveryClockOf[id] != 0) delete recoveryClockOf[id];

        emit ChangeRecoveryAddress(id, recovery);
    }

    /**
     * @notice Request a recovery of an fid to a new address if the caller is the recovery address.
     *         Supports ERC 2771 meta-transactions and can be called by a relayer.
     *
     * @param from The address that owns the fid
     * @param to   The address where the fid should be sent
     */
    function requestRecovery(address from, address to) external {
        uint256 id = idOf[from];
        if (_msgSender() != recoveryOf[id]) revert Unauthorized();

        // Assumption: id != 0 because of Invariant 1

        // Track when the escrow period started
        recoveryClockOf[id] = block.timestamp;

        // Store the final destination so that it cannot be modified unless completed or cancelled
        recoveryDestinationOf[id] = to;

        emit RequestRecovery(from, to, id);
    }

    /**
     * @notice Complete a recovery request and transfer the fid if the caller is the recovery
     *         address and the escrow period has passed. Supports ERC 2771 meta-transactions and
     *         can be called via a relayer.
     *
     * @param from The address that owns the id.
     */
    function completeRecovery(address from) external {
        uint256 id = idOf[from];

        if (_msgSender() != recoveryOf[id]) revert Unauthorized();

        uint256 _recoveryClock = recoveryClockOf[id];

        if (_recoveryClock == 0) revert NoRecovery();

        // Assumption: we don't need to check that the id still lives in the address because any
        // transfer would have reset this clock to zero causing a revert

        // Revert if the recovery is still in its escrow period
        unchecked {
            // Safety: rhs cannot overflow because _recoveryClock is a block.timestamp
            if (block.timestamp < _recoveryClock + ESCROW_PERIOD) revert Escrow();
        }

        address to = recoveryDestinationOf[id];
        if (idOf[to] != 0) revert HasId();

        // Assumption: id != 0 because of invariant 1 and 2 (either asserts this)
        _unsafeTransfer(id, from, to);
    }

    /**
     * @notice Cancel an active recovery request if the caller is the recovery address or the
     *         custody address. Supports ERC 2771 meta-transactions and can be called by a relayer.
     *
     * @param from The address that owns the id.
     */
    function cancelRecovery(address from) external {
        uint256 id = idOf[from];
        address sender = _msgSender();

        // Allow cancellation only if the sender is the recovery address or the custody address
        if (sender != from && sender != recoveryOf[id]) revert Unauthorized();

        // Assumption: id != 0 because of Invariant 1

        // Check if there is a recovery to avoid emitting incorrect CancelRecovery events
        if (recoveryClockOf[id] == 0) revert NoRecovery();

        // Clear the recovery request so that it cannot be completed
        delete recoveryClockOf[id];

        emit CancelRecovery(sender, id);
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER ACTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Change the trusted caller by calling this from the contract's owner.
     *
     * @param _trustedCaller The address of the new trusted caller
     */
    function changeTrustedCaller(address _trustedCaller) external onlyOwner {
        trustedCaller = _trustedCaller;
        emit ChangeTrustedCaller(_trustedCaller);
    }

    /**
     * @notice Disable trustedRegister() and let anyone get an fid by calling register(). This must
     *         be called by the contract's owner.
     */
    function disableTrustedOnly() external onlyOwner {
        delete trustedOnly;
        emit DisableTrustedOnly();
    }

    /**
     * @notice Override to prevent a single-step transfer of ownership
     */
    function transferOwnership(
        address /*newOwner*/
    ) public view override onlyOwner {
        revert Unauthorized();
    }

    /**
     * @notice Begin a request to transfer ownership to a new address ("pendingOwner"). This must
     *         be called by the contract's owner. A transfer request can be cancelled by calling
     *         this again with address(0).
     */
    function requestTransferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @notice Complete a request to transfer ownership. This must be called by the pendingOwner
     */
    function completeTransferOwnership() external {
        // Safety: burning ownership is not possible since this can never be called by address(0)

        // msg.sender is used instead of _msgSender() to keep surface area for attacks low
        if (msg.sender != pendingOwner) revert Unauthorized();

        _transferOwnership(msg.sender);
        delete pendingOwner;
    }

    /*//////////////////////////////////////////////////////////////
                         OPEN ZEPPELIN OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _msgSender() internal view override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ERC2771ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

/**
 * @title NameRegistry
 * @author varunsrin
 * @custom:version 2.0.0
 *
 * @notice NameRegistry enables any ETH address to claim a Farcaster Name (fname). A name is a
 *         rentable ERC-721 that can be registered for one year by paying a fee. On expiry, the
 *         owner has 30 days to renew the name by paying a fee, or it is placed in a dutch
 *         auction. The NameRegistry starts in a trusted mode where only a trusted caller can
 *         register an fname and can move to an untrusted mode where any address can register an
 *         fname. The Registry implements a recovery system which allows the custody address to
 *         nominate a recovery address that can transfer the fname to a new address after a delay.
 */
contract NameRegistry is
    Initializable,
    ERC721Upgradeable,
    ERC2771ContextUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Revert when there are not enough funds to complete the transaction
    error InsufficientFunds();

    /// @dev Revert when the caller does not have the authority to perform the action
    error Unauthorized();

    /// @dev Revert if the caller does not have ADMIN_ROLE
    error NotAdmin();

    /// @dev Revert if the caller does not have OPERATOR_ROLE
    error NotOperator();

    /// @dev Revert if the caller does not have MODERATOR_ROLE
    error NotModerator();

    /// @dev Revert if the caller does not have TREASURER_ROLE
    error NotTreasurer();

    /// @dev Revert when excess funds could not be sent back to the caller
    error CallFailed();

    /// @dev Revert when the commit hash is not found
    error InvalidCommit();

    /// @dev Revert when a commit is re-submitted before it has expired
    error CommitReplay();

    /// @dev Revert if the fname has invalid characters during registration
    error InvalidName();

    /// @dev Revert if renew() is called on a registered name.
    error Registered();

    /// @dev Revert if an operation is called on a name that hasn't been minted
    error Registrable();

    /// @dev Revert if makeCommit() is invoked before trustedCallerOnly is disabled
    error Invitable();

    /// @dev Revert if trustedRegister() is invoked after trustedCallerOnly is disabled
    error NotInvitable();

    /// @dev Revert if the fname being operated on is renewable or biddable
    error Expired();

    /// @dev Revert if renew() is called after the fname becomes Biddable
    error NotRenewable();

    /// @dev Revert if bid() is called on an fname that has not become Biddable.
    error NotBiddable();

    /// @dev Revert when completeRecovery() is called before the escrow period has elapsed.
    error Escrow();

    /// @dev Revert if a recovery operation is called when there is no active recovery.
    error NoRecovery();

    /// @dev Revert if the recovery address is set to address(0).
    error InvalidRecovery();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emit an event when a Farcaster Name is renewed for another year.
     *
     * @param tokenId The uint256 representation of the fname
     * @param expiry  The timestamp at which the renewal expires
     */
    event Renew(uint256 indexed tokenId, uint256 expiry);

    /**
     * @dev Emit an event when a user invites another user to register a Farcaster Name
     *
     * @param inviterId The fid of the user with the invite
     * @param inviteeId The fid of the user receiving the invite
     * @param fname     The fname that was registered by the invitee
     */
    event Invite(uint256 indexed inviterId, uint256 indexed inviteeId, bytes16 indexed fname);

    /**
     * @dev Emit an event when a Farcaster Name's recovery address is updated
     *
     * @param tokenId  The uint256 representation of the fname being updated
     * @param recovery The new recovery address
     */
    event ChangeRecoveryAddress(uint256 indexed tokenId, address indexed recovery);

    /**
     * @dev Emit an event when a recovery request is initiated for a Farcaster Name
     *
     * @param from     The custody address of the fname being recovered.
     * @param to       The destination address for the fname when the recovery is completed.
     * @param tokenId  The uint256 representation of the fname being recovered
     */
    event RequestRecovery(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emit an event when a recovery request is cancelled
     *
     * @param by      The address that cancelled the recovery request
     * @param tokenId The uint256 representation of the fname
     */
    event CancelRecovery(address indexed by, uint256 indexed tokenId);

    /**
     * @dev Emit an event when the trusted caller is modified
     *
     * @param trustedCaller The address of the new trusted caller.
     */
    event ChangeTrustedCaller(address indexed trustedCaller);

    /**
     * @dev Emit an event when the trusted only state is disabled.
     */
    event DisableTrustedOnly();

    /**
     * @dev Emit an event when the vault address is modified
     *
     * @param vault The address of the new vault.
     */
    event ChangeVault(address indexed vault);

    /**
     * @dev Emit an event when the pool address is modified
     *
     * @param pool The address of the new pool.
     */
    event ChangePool(address indexed pool);

    /**
     * @dev Emit an event when the fee is changed
     *
     * @param fee The new yearly registration fee
     */
    event ChangeFee(uint256 fee);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// WARNING - DO NOT CHANGE THE ORDER OF THESE VARIABLES ONCE DEPLOYED
    /// Changes should be replicated to NameRegistryV2 in NameRegistryUpdate.t.sol

    // Audit: These variables are kept public to make it easier to test the contract, since using
    // the same inherit and extend trick that we used for IdRegistry is harder to pull off here
    //  due to the UUPS structure.

    /**
     * @notice The fee to renew a name for a full calendar year
     * @dev    Occupies slot 0.
     */
    uint256 public fee;

    /**
     * @notice The address controlled by the Farcaster Invite service that is allowed to call
     *         trustedRegister
     * @dev    Occupies slot 1
     */
    address public trustedCaller;

    /**
     * @notice Flag that determines if registration can occur through trustedRegister or register
     * @dev    Occupies slot 2, initialized to 1 and can only be changed to zero
     */
    uint256 public trustedOnly;

    /**
     * @notice Maps each commit to the timestamp at which it was created.
     * @dev    Occupies slot 3
     */
    mapping(bytes32 => uint256) public timestampOf;

    /**
     * @notice Maps each uint256 representation of an fname to the time at which it expires
     * @dev    Occupies slot 4
     */
    mapping(uint256 => uint256) public expiryOf;

    /**
     * @notice The address that funds can be withdrawn to
     * @dev    Occupies slot 5
     */
    address public vault;

    /**
     * @notice The address that names can be reclaimed to
     * @dev    Occupies slot 6
     */
    address public pool;

    /**
     * @notice Maps each uint256 representation of an fname to the address that can recover it
     * @dev    Occupies slot 7
     */
    mapping(uint256 => address) public recoveryOf;

    /**
     * @notice Maps each uint256 representation of an fname to the timestamp of the recovery
     *         attempt or zero if there is no active recovery.
     * @dev    Occupies slot 8
     */
    mapping(uint256 => uint256) public recoveryClockOf;

    /**
     * @notice Maps each uint256 representation of an fname to the destination address of the most
     *         recent recovery attempt.
     * @dev    Occupies slot 9, and the value is left dirty after a recovery to save gas and should
     *         not be relied upon to check if there is an active recovery.
     */
    mapping(uint256 => address) public recoveryDestinationOf;

    /**
     * @dev Added to allow future versions to add new variables in case this contract becomes
     *      inherited. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    string internal constant BASE_URI = "http://www.farcaster.xyz/u/";

    /// @dev enforced delay between makeCommit() and register() to prevent front-running
    uint256 internal constant REVEAL_DELAY = 60 seconds;

    /// @dev enforced delay in makeCommit() to prevent griefing by replaying the commit
    uint256 internal constant COMMIT_REPLAY_DELAY = 10 minutes;

    uint256 internal constant REGISTRATION_PERIOD = 365 days;

    uint256 internal constant RENEWAL_PERIOD = 30 days;

    uint256 internal constant ESCROW_PERIOD = 3 days;

    /// @dev Starting price of every bid during the first period
    uint256 internal constant BID_START_PRICE = 1000 ether;

    /// @dev 60.18-decimal fixed-point that decreases the price by 10% when multiplied
    uint256 internal constant BID_PERIOD_DECREASE_UD60X18 = 0.9 ether;

    /// @dev 60.18-decimal fixed-point that approximates divide by 28,800 when multiplied
    uint256 internal constant DIV_28800_UD60X18 = 3.4722222222222e13;

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 internal constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    bytes32 internal constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    uint256 internal constant INITIAL_FEE = 0.01 ether;

    /*//////////////////////////////////////////////////////////////
                      CONSTRUCTORS AND INITIALIZERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Disable initialization to protect the contract and configure the trusted forwarder.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address _forwarder) ERC2771ContextUpgradeable(_forwarder) {
        // Audit: Is this the safest way to prevent contract initialization attacks?
        // See: https://twitter.com/z0age/status/1551951489354145795
        _disableInitializers();
    }

    /**
     * @notice Initialize default storage values and initialize inherited contracts. This should be
     *         called once after the contract is deployed via the ERC1967 proxy. Slither incorrectly flags
     *         this method as unprotected: https://github.com/crytic/slither/issues/1341
     *
     * @param _tokenName   The ERC-721 name of the fname token
     * @param _tokenSymbol The ERC-721 symbol of the fname token
     * @param _vault       The address that funds can be withdrawn to
     * @param _pool        The address that fnames can be reclaimed to
     */
    function initialize(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        address _vault,
        address _pool
    ) external initializer {
        __ERC721_init(_tokenName, _tokenSymbol);

        __Pausable_init();

        __AccessControl_init();

        __UUPSUpgradeable_init();

        // Grant the DEFAULT_ADMIN_ROLE to the deployer, which can configure other roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        vault = _vault;
        emit ChangeVault(_vault);

        pool = _pool;
        emit ChangePool(_pool);

        fee = INITIAL_FEE;
        emit ChangeFee(INITIAL_FEE);

        trustedOnly = 1;
    }

    /*//////////////////////////////////////////////////////////////
                           REGISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * INVARIANT 1A: If an id is not minted, expiryOf[id] must be 0 and ownerOf(id) and
     *               recoveryOf[id] must also be address(0).
     *
     * INVARIANT 1B: If an id is minted, expiryOf[id] and ownerOf(id) must be non-zero.
     *
     * INVARIANT 2: An fname cannot be transferred to address(0) after it is minted.
     */

    /**
     * @notice Generate a commitment that is used as part of a commit-reveal scheme to register a
     *         an fname while protecting the registration from being front-run.
     *
     * @param fname  The fname to be registered
     * @param to     The address that will own the fname
     * @param secret A secret that is known only to the caller
     */
    function generateCommit(
        bytes16 fname,
        address to,
        bytes32 secret,
        address recovery
    ) public pure returns (bytes32 commit) {
        // Perf: Do not validate to != address(0) because it happens during register/mint

        _validateName(fname);

        commit = keccak256(abi.encode(fname, to, recovery, secret));
    }

    /**
     * @notice Save a commitment on-chain which can be revealed later to register an fname while
     *         protecting the registration from being front-run. This is allowed even when the
     *         contract is paused.
     *
     * @param commit The commitment hash to be persisted on-chain
     */
    function makeCommit(bytes32 commit) external {
        if (trustedOnly == 1) revert Invitable();

        unchecked {
            // Safety: timestampOf is always set to block.timestamp and cannot overflow here

            // Commits cannot be re-submitted immediately to prevent griefing by re-submitting commits
            // to reset the REVEAL_DELAY clock
            if (block.timestamp <= timestampOf[commit] + COMMIT_REPLAY_DELAY) revert CommitReplay();
        }

        // Save the commit and start the REVEAL_DELAY clock
        timestampOf[commit] = block.timestamp;
    }

    /**
     * @notice Mint a new fname if the inputs match a previous commit and if it was called at least
     *         60 seconds after the commit's timestamp to prevent frontrunning within the same block.
     *         It fails when paused because it invokes _mint which in turn invokes beforeTransfer()
     *
     * @param fname    The fname to register
     * @param to       The address that will own the fname
     * @param secret   The secret value in the commitment
     * @param recovery The address which can recovery the fname if the custody address is lost
     */
    function register(
        bytes16 fname,
        address to,
        bytes32 secret,
        address recovery
    ) external payable {
        bytes32 commit = generateCommit(fname, to, secret, recovery);

        uint256 _fee = fee;
        if (msg.value < _fee) revert InsufficientFunds();

        // Perf: do not check if trustedOnly = 1, because timestampOf[commit] will always be zero
        // while trustedOnly = 1 since makeCommit cannot be called.
        uint256 commitTs = timestampOf[commit];
        if (commitTs == 0) revert InvalidCommit();

        unchecked {
            // Audit: verify that 60s is the right duration to use
            // Safety: makeCommit() sets commitTs to block.timestamp which cannot overflow
            if (block.timestamp < commitTs + REVEAL_DELAY) revert InvalidCommit();
        }

        // ERC-721's require a unique token number for each fname token, and we calculate this by
        // converting the byte16 representation into a uint256
        uint256 tokenId = uint256(bytes32(fname));

        // Mint checks that to != address(0) and that the tokenId wasn't previously issued
        _mint(to, tokenId);

        // Clearing unnecessary storage reduces gas consumption
        delete timestampOf[commit];

        unchecked {
            // Safety: expiryOf will not overflow given the expected sizes of block.timestamp
            expiryOf[tokenId] = block.timestamp + REGISTRATION_PERIOD;
        }

        recoveryOf[tokenId] = recovery;

        uint256 overpayment;

        unchecked {
            // Safety: msg.value >= _fee by check above, so this cannot overflow
            overpayment = msg.value - _fee;
        }

        if (overpayment > 0) {
            // Perf: Call msg.sender instead of _msgSender() to save ~100 gas b/c we don't need meta-tx
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: overpayment}("");
            if (!success) revert CallFailed();
        }
    }

    /**
     * @notice Mint a fname during the invitation period from the trusted caller.
     *
     * @dev The function is pauseable since it invokes _transfer by way of _mint.
     *
     * @param to the address that will claim the fname
     * @param fname the fname to register
     * @param recovery address which can recovery the fname if the custody address is lost
     * @param inviter the fid of the user who invited the new user to get an fname
     * @param invitee the fid of the user who was invited to get an fname
     */
    function trustedRegister(
        bytes16 fname,
        address to,
        address recovery,
        uint256 inviter,
        uint256 invitee
    ) external payable {
        // Trusted Register can only be called during the invite period (when trustedOnly = 1)
        if (trustedOnly == 0) revert NotInvitable();

        // Call msg.sender instead of _msgSender() to prevent meta-txns and allow the function
        // to be called by BatchRegistry. This also saves ~100 gas.
        if (msg.sender != trustedCaller) revert Unauthorized();

        // Perf: this can be omitted to save ~3k gas if we believe that the trusted caller will
        // never call this function with an invalid fname.
        _validateName(fname);

        // Mint checks that to != address(0) and that the tokenId wasn't previously issued
        uint256 tokenId = uint256(bytes32(fname));
        _mint(to, tokenId);

        unchecked {
            // Safety: expiryOf will not overflow given the expected sizes of block.timestamp
            expiryOf[tokenId] = block.timestamp + REGISTRATION_PERIOD;
        }

        recoveryOf[tokenId] = recovery;

        emit Invite(inviter, invitee, fname);
    }

    /**
     * @notice Renew a name for another year while it is in the renewable period.
     *
     * @param tokenId The uint256 representation of the fname to renew
     */
    function renew(uint256 tokenId) external payable whenNotPaused {
        uint256 _fee = fee;
        if (msg.value < _fee) revert InsufficientFunds();

        // Check that the tokenID was previously registered
        uint256 expiryTs = expiryOf[tokenId];
        if (expiryTs == 0) revert Registrable();

        // tokenID is not owned by address(0) because of INVARIANT 1B + 2

        // Check that we are still in the renewable period, and have not passed into biddable
        unchecked {
            // Safety: expiryTs is a timestamp of a known calendar year and cannot overflow
            if (block.timestamp >= expiryTs + RENEWAL_PERIOD) revert NotRenewable();
        }

        if (block.timestamp < expiryTs) revert Registered();

        expiryOf[tokenId] = block.timestamp + REGISTRATION_PERIOD;

        emit Renew(tokenId, expiryOf[tokenId]);

        uint256 overpayment;

        unchecked {
            // Safety: msg.value >= _fee by check above, so this cannot overflow
            overpayment = msg.value - _fee;
        }

        if (overpayment > 0) {
            // Perf: Call msg.sender instead of _msgSender() to save ~100 gas b/c we don't need meta-tx
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: overpayment}("");
            if (!success) revert CallFailed();
        }
    }

    /**
     * @notice Bid to purchase an expired fname in a dutch auction and register it through the end
     *         of the calendar year. The winning bid starts at ~1000.01 ETH on Feb 1st and decays
     *         exponentially until it reaches 0 at the end of Dec 31st.
     *
     * @param to       The address where the fname should be transferred
     * @param tokenId  The uint256 representation of the fname to bid on
     * @param recovery The address which can recovery the fname if the custody address is lost
     */
    function bid(
        address to,
        uint256 tokenId,
        address recovery
    ) external payable {
        // Check that the tokenID was previously registered
        uint256 expiryTs = expiryOf[tokenId];
        if (expiryTs == 0) revert Registrable();

        uint256 auctionStartTimestamp;

        unchecked {
            // Safety: expiryTs is a timestamp of a known calendar year and adding it to
            // RENEWAL_PERIOD cannot overflow
            auctionStartTimestamp = expiryTs + RENEWAL_PERIOD;
        }

        if (block.timestamp < auctionStartTimestamp) revert NotBiddable();

        uint256 price;

        /**
         * The price to win a bid is calculated with formula price = dutch_premium + renewal_fee,
         * where the dutch_premium starts at 1,000 ETH and decreases exponentially by 10% every
         * 8 hours after bidding starts.
         *
         * dutch_premium = 1000 ether * (0.9)^(periods), where:
         * periods = (block.timestamp - auctionStartTimestamp) / 28_800
         *
         * Periods are calculated with fixed-point multiplication which causes a slight error
         * that increases the price (DivErr), while dutch_premium is calculated with the identity
         * (x^y = exp(ln(x) * y)) which truncates 3 digits of precision and slightly lowers the
         * price (ExpErr).
         *
         * The two errors interact in different ways keeping the price slightly higher or lower
         * than expected as shown below:
         *
         * +=========+======================+========================+========================+
         * | Periods |        NoErr         |         DivErr         |    PowErr + DivErr     |
         * +=========+======================+========================+========================+
         * |       1 |                900.0 | 900.000000000000606876 | 900.000000000000606000 |
         * +---------+----------------------+------------------------+------------------------+
         * |      10 |          348.6784401 | 348.678440100002351164 | 348.678440100002351000 |
         * +---------+----------------------+------------------------+------------------------+
         * |     100 | 0.026561398887587476 |   0.026561398887589867 |   0.026561398887589000 |
         * +---------+----------------------+------------------------+------------------------+
         * |     393 | 0.000000000000001040 |   0.000000000000001040 |   0.000000000000001000 |
         * +---------+----------------------+------------------------+------------------------+
         * |     394 |                  0.0 |                    0.0 |                    0.0 |
         * +---------+----------------------+------------------------+------------------------+
         *
         */

        unchecked {
            // Safety: cannot underflow because auctionStartTimestamp <= block.timestamp and cannot
            // overflow because block.timestamp - auctionStartTimestamp realistically will stay
            // under 10^10 for the next 50 years, which can be safely multiplied with
            // DIV_28800_UD60X18
            int256 periodsSD59x18 = int256((block.timestamp - auctionStartTimestamp) * DIV_28800_UD60X18);

            // Perf: Precomputing common values might save gas but at the expense of storage which
            // is our biggest constraint and so it was discarded.

            // Safety/Audit: the below cannot intuitively underflow or overflow given the ranges,
            // but needs proof
            // price =
            //     BID_START_PRICE.mulWadDown(
            //         uint256(FixedPointMathLib.powWad(int256(BID_PERIOD_DECREASE_UD60X18), periodsSD59x18))
            //     ) +
            //     fee;
            price = fee;
        }

        if (msg.value < price) revert InsufficientFunds();

        // call super.ownerOf instead of ownerOf, because the latter reverts if name is expired
        _transfer(super.ownerOf(tokenId), to, tokenId);

        unchecked {
            // Safety: expiryOf will not overflow given the expected sizes of block.timestamp
            expiryOf[tokenId] = block.timestamp + REGISTRATION_PERIOD;
        }

        recoveryOf[tokenId] = recovery;

        uint256 overpayment;

        unchecked {
            // Safety: msg.value >= price by check above, so this cannot underflow
            overpayment = msg.value - price;
        }

        if (overpayment > 0) {
            // Perf: Call msg.sender instead of _msgSender() to save ~100 gas b/c we don't need meta-tx
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: overpayment}("");
            if (!success) revert CallFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ERC-721 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Override the ownerOf implementation to throw if an fname is renewable or biddable.
     *
     * @param tokenId The uint256 representation of the fname to check
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        uint256 expiryTs = expiryOf[tokenId];

        if (expiryTs != 0 && block.timestamp >= expiryTs) revert Expired();

        // Assumption: If the token is unregistered, super.ownerOf will revert
        return super.ownerOf(tokenId);
    }

    /**
     * Audit: ERC721 balanceOf will over report the balance of the owner even if the name is expired.
     */

    /**
     * @notice Override transferFrom to throw if the name is renewable or biddable.
     *
     * @param from    The address which currently holds the fname
     * @param to      The address to transfer the fname to
     * @param tokenId The uint256 representation of the fname to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        uint256 expiryTs = expiryOf[tokenId];

        // Expired names should not be transferrable by the previous owner
        if (expiryTs != 0 && block.timestamp >= expiryOf[tokenId]) revert Expired();

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Override safeTransferFrom to throw if the name is renewable or biddable.
     *
     * @param from     The address which currently holds the fname
     * @param to       The address to transfer the fname to
     * @param tokenId  The uint256 representation of the fname to transfer
     * @param data     Additional data with no specified format, sent in call to `to`
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        uint256 expiryTs = expiryOf[tokenId];

        // Expired names should not be transferrable by the previous owner
        if (expiryTs != 0 && block.timestamp >= expiryOf[tokenId]) revert Expired();

        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Return a distinct Uniform Resource Identifier (URI) for a given tokenId even if it
     *         is not registered. Throws if the tokenId cannot be converted to a valid fname.
     *
     * @param tokenId The uint256 representation of the fname
     */
    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        uint256 lastCharIdx;

        // Safety: fnames are byte16's that are cast to uint256 tokenIds, so inverting this is safe
        bytes16 fname = bytes16(bytes32(tokenId));

        _validateName(fname);

        // Step back from the last byte to find the first non-zero byte
        for (uint256 i = 15; ; ) {
            if (uint8(fname[i]) != 0) {
                lastCharIdx = i;
                break;
            }

            unchecked {
                // Safety: i cannot underflow because the loop terminates when i == 0
                --i;
            }
        }

        // Safety: this non-zero byte must exist at some position because of _validateName and
        // therefore lastCharIdx must be > 1

        // Construct a new bytes[] with the valid fname characters.
        bytes memory fnameBytes = new bytes(lastCharIdx + 1);

        for (uint256 j = 0; j <= lastCharIdx; ) {
            fnameBytes[j] = fname[j];

            unchecked {
                // Safety: j cannot overflow because the loop terminates when j > lastCharIdx
                ++j;
            }
        }

        return string(abi.encodePacked(BASE_URI, string(fnameBytes), ".json"));
    }

    /**
     * @dev Hook that ensures that token transfers cannot occur when the contract is paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Hook that ensures that recovery address is reset whenever a transfer occurs.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._afterTokenTransfer(from, to, tokenId);

        // Checking state before clearing is more gas-efficient than always clearing
        if (recoveryClockOf[tokenId] != 0) delete recoveryClockOf[tokenId];
        delete recoveryOf[tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                             RECOVERY LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * The custodyAddress (i.e. owner) can appoint a recoveryAddress which can transfer a
     * specific fname if the custodyAddress is lost. The recovery address must first request the
     * transfer on-chain which moves it into escrow. If the custodyAddress does not cancel
     * the request during escrow, the recoveryAddress can then transfer the fname. The custody
     * address can remove or change the recovery address at any time.
     *
     * INVARIANT 3: Changing ownerOf must set recoveryOf to address(0) and recoveryClockOf[id] to 0
     *
     * INVARIANT 4: If recoveryClockOf is non-zero, then recoveryDestinationOf is a non-zero address.
     */

    /**
     * @notice Change the recovery address of the fname and reset any active recovery requests.
     *         Supports ERC 2771 meta-transactions and can be called by a relayer.
     *
     * @param tokenId  The uint256 representation of the fname
     * @param recovery The address which can recover the fname (set to 0x0 to disable recovery)
     */
    function changeRecoveryAddress(uint256 tokenId, address recovery) external whenNotPaused {
        if (ownerOf(tokenId) != _msgSender()) revert Unauthorized();

        recoveryOf[tokenId] = recovery;

        // Perf: clear any active recovery requests, but check if they exist before deleting
        // because this usually already zero
        if (recoveryClockOf[tokenId] != 0) delete recoveryClockOf[tokenId];

        emit ChangeRecoveryAddress(tokenId, recovery);
    }

    /**
     * @notice Request a recovery of an fid to a new address if the caller is the recovery address.
     *         Supports ERC 2771 meta-transactions and can be called by a relayer. Requests can be
     *         overwritten by making another request.
     *
     * @param tokenId The uint256 representation of the fname
     * @param to      The address to transfer the fname to, which cannot be address(0)
     */
    function requestRecovery(uint256 tokenId, address to) external whenNotPaused {
        if (to == address(0)) revert InvalidRecovery();

        // Invariant 3 ensures that a request cannot be made after ownership change without consent
        if (_msgSender() != recoveryOf[tokenId]) revert Unauthorized();

        // Perf: don't check if in renewable or biddable state since it saves gas and
        // completeRecovery will revert when it runs

        // Track when the escrow period started
        recoveryClockOf[tokenId] = block.timestamp;

        // Store the final destination so that it cannot be modified unless completed or cancelled
        recoveryDestinationOf[tokenId] = to;

        // Perf: Gas costs can be reduced by omitting the from param, at the cost of breaking
        // compatibility with the IdRegistry's RequestRecovery event
        emit RequestRecovery(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @notice Complete a recovery request and transfer the fname if the caller is the recovery
     *         address and the escrow period has passed. Supports ERC 2771 meta-transactions and
     *         can be called by a relayer. Cannot be called when paused because _transfer reverts.
     *
     * @param tokenId The uint256 representation of the fname
     */
    function completeRecovery(uint256 tokenId) external {
        if (block.timestamp >= expiryOf[tokenId]) revert Expired();

        // Invariant 3 ensures that a request cannot be completed after ownership change without consent
        if (_msgSender() != recoveryOf[tokenId]) revert Unauthorized();

        uint256 _recoveryClock = recoveryClockOf[tokenId];
        if (_recoveryClock == 0) revert NoRecovery();

        unchecked {
            // Safety: _recoveryClock is always set to block.timestamp and cannot realistically overflow
            if (block.timestamp < _recoveryClock + ESCROW_PERIOD) revert Escrow();
        }

        // Assumption: Invariant 4 prevents this from going to address(0).
        _transfer(ownerOf(tokenId), recoveryDestinationOf[tokenId], tokenId);
    }

    /**
     * @notice Cancel an active recovery request if the caller is the recovery address or the
     *         custody address. Supports ERC 2771 meta-transactions and can be called by a relayer.
     *         Can be called even if the contract is paused to avoid griefing before a known pause.
     *
     * @param tokenId The uint256 representation of the fname
     */
    function cancelRecovery(uint256 tokenId) external {
        address sender = _msgSender();

        // Perf: super.ownerOf is called instead of ownerOf since cancellation has no undesirable
        // side effects when expired and it saves some gas.
        if (sender != super.ownerOf(tokenId) && sender != recoveryOf[tokenId]) revert Unauthorized();

        // Check if there is a recovery to avoid emitting incorrect CancelRecovery events
        if (recoveryClockOf[tokenId] == 0) revert NoRecovery();

        // Clear the recovery request so that it cannot be completed
        delete recoveryClockOf[tokenId];

        emit CancelRecovery(sender, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            MODERATOR ACTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Move the fname from the current owner to the pool and renew it for another year.
     *         Does not work when paused because it calls _transfer.
     *
     * @param tokenId the uint256 representation of the fname.
     */
    function reclaim(uint256 tokenId) external payable {
        // call msg.sender instead of _msgSender() since we don't need meta-tx for admin actions
        // and it reduces our attack surface area
        if (!hasRole(MODERATOR_ROLE, msg.sender)) revert NotModerator();

        uint256 _expiry = expiryOf[tokenId];

        // If an fname hasn't been minted, it should be minted instead of reclaimed
        if (_expiry == 0) revert Registrable();

        // Call super.ownerOf instead of ownerOf because we want the admin to transfer the name
        // even if is expired and there is no current owner.
        _transfer(super.ownerOf(tokenId), pool, tokenId);

        // If an fname expires in the near future, extend its registration by the renewal period
        if (block.timestamp >= _expiry - RENEWAL_PERIOD) {
            expiryOf[tokenId] = block.timestamp + RENEWAL_PERIOD;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ADMIN ACTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Changes the address from which registerTrusted calls can be made
     *
     * @param _trustedCaller The address of the new trusted caller
     */
    function changeTrustedCaller(address _trustedCaller) external {
        // avoid _msgSender() since meta-tx are unnecessary here and increase attack surface area
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert NotAdmin();
        trustedCaller = _trustedCaller;
        emit ChangeTrustedCaller(_trustedCaller);
    }

    /**
     * @notice Disables registerTrusted and enables register calls from any address.
     */
    function disableTrustedOnly() external {
        // avoid _msgSender() since meta-tx are unnecessary here and increase attack surface area
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert NotAdmin();
        delete trustedOnly;
        emit DisableTrustedOnly();
    }

    /**
     * @notice Changes the address to which funds can be withdrawn
     *
     * @param _vault The address of the new vault
     */
    function changeVault(address _vault) external {
        // avoid _msgSender() since meta-tx are unnecessary here and increase attack surface area
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert NotAdmin();
        vault = _vault;
        emit ChangeVault(_vault);
    }

    /**
     * @notice Changes the address to which names are reclaimed
     *
     * @param _pool The address of the new pool
     */
    function changePool(address _pool) external {
        // avoid _msgSender() since meta-tx are unnecessary here and increase attack surface area
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert NotAdmin();
        pool = _pool;
        emit ChangePool(_pool);
    }

    /*//////////////////////////////////////////////////////////////
                            TREASURER ACTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Change the fee charged to register an fname for a full year
     *
     * @param _fee The new yearly fee
     */
    function changeFee(uint256 _fee) external {
        // avoid _msgSender() since meta-tx are unnecessary here and increase attack surface area
        if (!hasRole(TREASURER_ROLE, msg.sender)) revert NotTreasurer();

        // Audit does fee == 0 cause any problems with other logic?
        fee = _fee;
        emit ChangeFee(_fee);
    }

    /**
     * @notice Withdraw a specified amount of ether to the vault
     *
     * @param amount The amount of ether to withdraw
     */
    function withdraw(uint256 amount) external {
        // avoid _msgSender() since meta-tx are unnecessary here and increase attack surface area
        if (!hasRole(TREASURER_ROLE, msg.sender)) revert NotTreasurer();

        // Audit: this will not revert if the requested amount is zero, will that cause problems?
        if (address(this).balance < amount) revert InsufficientFunds();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = vault.call{value: amount}("");
        if (!success) revert CallFailed();
    }

    /*//////////////////////////////////////////////////////////////
                            OPERATOR ACTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice pause the contract and prevent registrations, renewals, recoveries and transfers of names.
     */
    function pause() external {
        // avoid _msgSender() since meta-tx are unnecessary here and increase attack surface area
        if (!hasRole(OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _pause();
    }

    /**
     * @notice unpause the contract and resume registrations, renewals, recoveries and transfers of names.
     */
    function unpause() external {
        // avoid _msgSender() since meta-tx are unnecessary here and increase attack surface area
        if (!hasRole(OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                         OPEN ZEPPELIN OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        sender = ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal view override {
        if (!hasRole(ADMIN_ROLE, _msgSender())) revert NotAdmin();
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Reverts if the name contains an invalid fname character
     */
    // solhint-disable-next-line code-complexity
    function _validateName(bytes16 fname) internal pure {
        uint256 length = fname.length;
        bool nameEnded;

        /**
         * Iterate over the bytes16 fname one char at a time, ensuring that:
         *   1. The name begins with [a-z 0-9] or the ascii numbers [48-57, 97-122] inclusive
         *   2. The name can contain [a-z 0-9 -] or the ascii numbers [45, 48-57, 97-122] inclusive
         *   3. Once the name is ended with a NULL char (0), the follows character must also be NULLs
         */

        // If the name begins with a hyphen, reject it
        if (uint8(fname[0]) == 45) revert InvalidName();

        for (uint256 i = 0; i < length; ) {
            uint8 charInt = uint8(fname[i]);

            unchecked {
                // Safety: i can never overflow because length is guaranteed to be <= 16
                i++;
            }

            if (nameEnded) {
                // Only NULL characters are allowed after a name has ended
                if (charInt != 0) {
                    revert InvalidName();
                }
            } else {
                // Only valid ASCII characters [45, 48-57, 97-122] are allowed before the name ends

                // Check if the character is a-z
                if ((charInt >= 97 && charInt <= 122)) {
                    continue;
                }

                // Check if the character is 0-9
                if ((charInt >= 48 && charInt <= 57)) {
                    continue;
                }

                // Check if the character is a hyphen
                if ((charInt == 45)) {
                    continue;
                }

                // On seeing the first NULL char in the name, revert if is the first char in the
                // name, otherwise mark the name as ended
                if (charInt == 0) {
                    // We check i==1 instead of i==0 because i is incremented before the check
                    if (i == 1) revert InvalidName();
                    nameEnded = true;
                    continue;
                }

                revert InvalidName();
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}