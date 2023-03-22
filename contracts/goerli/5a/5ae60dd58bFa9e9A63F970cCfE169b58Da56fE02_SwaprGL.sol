// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271Upgradeable.isValidSignature.selector));
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BaseGovernanceUpgradeable is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant PAUSE_MANAGER_ROLE = keccak256("PAUSE_MANAGER_ROLE");
    bytes32 public constant UPGRADE_MANAGER_ROLE = keccak256("UPGRADE_MANAGER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERROR: ONLY_ADMIN");
        _;
    }

    function __BaseGovernance_init() internal onlyInitializing {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSE_MANAGER_ROLE, _msgSender());
        _setupRole(UPGRADE_MANAGER_ROLE, _msgSender());
    }

    function pause() public onlyRole(PAUSE_MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSE_MANAGER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADE_MANAGER_ROLE)
        override
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ILock is IERC721Upgradeable {

    function splitManager() external view returns (address);

    /**
     * @notice Get all the information about a NFT with specific ID
     * @param id NFT ID of the NFT for which the information is required
     * @return Owner or beneficiary of the NFT
     * @return The actual balance of amount locked
     * @return The actual amount that the owner can claim
     * @return The time when the lock start
     * @return The time when the lock will end
     */
    function getInfoBySingleID(uint id) view external returns(address, uint, uint, uint, uint);

    /**
     * @notice Get all the information about a set of IDs
     * @param ids List of NFT IDs which the information is required
     * @return List of owners or beneficiaries
     * @return List of actual balance of amount locked
     * @return List of actual amount that is claimable
     */
    function getInfoByManyIDs(uint[] memory ids) view external returns(address[] memory, uint[] memory, uint[] memory);

    /**
     * @notice Split a NFT
     * @param originId NFT ID to be split
     * @param splitParts List of proportions normalized to be used in the split
     * @param addresses List of addresses of beneficiaries
     * @return newIDs of minted NFTs in order
     */
    function split(uint originId, uint[] memory splitParts, address[] memory addresses) external returns(uint256[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ISplitManager {

    function getLockedPart(uint ID) view external returns(uint);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./common/BaseGovernanceUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Manages NFT listings and user funds
/// @author swapr
/// @notice Allows only signature based listings
/// @dev Can only be interacted from a recognised marketplace EOA
contract SwaprFee is BaseGovernanceUpgradeable {

    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint constant EXP = 1e18;

    uint constant BPS = 1000;
    uint constant DPS = BPS*BPS;

    /// @notice Struct type to encapsulate FeePricing data
    /// @dev depositType is to detect the listing type as proposed listing type
    /// @dev activeDepositType is to check if asset is already listed as current listing type
    struct FeePricing {
        uint fixedBaseFee;
        bool isFixedBaseFee;
        uint percentBaseFee;
        bool isPercentBaseFee;
        uint finalFeePercentage;
        bool isFinalFeePercentage;
        uint priceCap;
    }

    address public feeReceiver;
    FeePricing public AuctionFee;
    FeePricing public OrderFee;
    IERC20MetadataUpgradeable[] public paymentTokens;
    AggregatorV3Interface[] internal tokenPriceFeeds;
    AggregatorV3Interface internal cryptoPriceFeed;

    mapping(address => mapping(address => uint)) public paymentRecords;
    mapping(address => uint256) internal discountAmount;

    mapping(address => AggregatorV3Interface) public oracleFeedForToken;

    bytes32 public constant SWAPRGL_ROLE = keccak256("SWAPRGL_ROLE");
    modifier onlySwapr() {
        require(hasRole(SWAPRGL_ROLE, _msgSender()), "ERROR: ONLY_SWAPR_ROLE");
        _;
    }
    
    function initialize(address swaprGLAddress) public initializer {

        __BaseGovernance_init();

        //You can setup custom roles here in addition to the default gevernance roles
        _setupRole(SWAPRGL_ROLE, swaprGLAddress);
        //All state variables must be initialized here in sequence to prevent upgrade conflicts
        feeReceiver = _msgSender();

    }

    /// @notice set new account as fee receiver
    function setFeeReceiver(address _feeReceiver) external onlyAdmin {
        require(_feeReceiver != address(0), "Cant set address 0");
        feeReceiver = _feeReceiver;
    }

    /// @notice add new payment accepted tokens
    /// @param _paymentTokens token used to pay the fee
    function addPaymentToken(
        address[] memory _paymentTokens,
        address[] memory _tokenPriceFeeds
    ) external onlyAdmin {
        require(
            _paymentTokens.length == _tokenPriceFeeds.length,
            "INVALID_TOKEN-FEED_LENGTH"
        );
        for (uint256 i; i < _paymentTokens.length;) {
            if(_paymentTokens[i] == address(0)){
                cryptoPriceFeed = AggregatorV3Interface(_tokenPriceFeeds[i]);
            }else{
                if (!isTokenSupported(_paymentTokens[i])) {
                    paymentTokens.push(IERC20MetadataUpgradeable(_paymentTokens[i]));
                    tokenPriceFeeds.push(
                        AggregatorV3Interface(_tokenPriceFeeds[i])
                    );
                    oracleFeedForToken[_paymentTokens[i]] = AggregatorV3Interface(
                    _tokenPriceFeeds[i]
                    );
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function castInterface(address token) public pure returns(AggregatorV3Interface){
        return AggregatorV3Interface(token);
    }
    
    /// @notice remove existing payment accepted token
    /// @param _paymentToken token used to pay the fee
    function removePaymentToken(address _paymentToken) external onlyAdmin {
        (bool exists, uint idx) = _exists(_paymentToken);
        if(exists){
            delete paymentTokens[idx];
        }
    }
    /// @notice remove all existing payment accepted tokens
    function removeAllPaymentTokens() external onlyAdmin {
        delete paymentTokens;
    }

    /// @notice get account of the beneficiary who will receive all the fee paid
    function getPaymentTokens() public view returns(IERC20MetadataUpgradeable[] memory) {
        return paymentTokens;
    }

    function getTokenFeed(address token) public view returns(AggregatorV3Interface priceFeed){
        if(token == address(0)){
            priceFeed = cryptoPriceFeed;
        }else{
            priceFeed = oracleFeedForToken[token];
        }
    }

    /// @notice check if the token is accepted as payment currency
    function isTokenSupported(address _paymentToken) public view returns(bool exists) {
        if(_paymentToken == address(0)){
            exists = true;
        }else{
            (exists,) = _exists(_paymentToken);
        }
    }

    // function addDiscountTokens(
    //     address[] _discountToken,
    //     uint256[] _discountAmount
    // ) external onlyAdmin {
    //     require(_discountToken.length == _discountAmount.length, "Invalid input");
    //     for(uint256 i; i < _discountToken.length; i++){
    //         addDiscountToken(_discountToken[i], _discountAmount[i]);
    //     }
    // }

    // function addDiscountToken(
    //     address _discountToken,
    //     uint256 _discountAmount
    // ) external onlyAdmin {
    //     require(_discountToken != address(0), "Cant set address 0");
    //     require(_discountAmount <= EXP_VALUE, "Discount cant be more than 100%");
    //     require(_exists(_discountToken), "This is not a payment token");
    //     discountAmount[_discountToken] = _discountAmount;
    // }

    // function removeDiscountTokens(
    //     address[] _discountToken
    // ) external onlyAdmin {
    //     for(uint256 i; i < _discountToken.length; i++){
    //         removeDiscountToken(_discountToken[i]);
    //     }
    // }

    // function removeDiscountToken(
    //     address _discountToken
    // ) external onlyAdmin {
    //     require(_exists(_discountToken), "This is not a payment token");
    //     require(_discountAmount > 0, "Discount not set");
    //     delete discountAmount[_discountToken];
    // }

    /// @notice configure fee params for auction type listing
    /// @param data should contain FeePricing type data
    function configAuctionFee(bytes calldata data) external onlyAdmin {
        AuctionFee = _extractFeePricingInfo(data);
    }

    /// @notice configure fee params for order type listing
    /// @param data should contain FeePricing type data
    function configOrderFee(bytes calldata data) external onlyAdmin {
        OrderFee = _extractFeePricingInfo(data);
    }

    /// @notice get account of the beneficiary who will receive all the fee paid
    function getFeeReceiver() public view returns(address) {
        return feeReceiver;
    }

    /// @notice get applied base fee for the order type listing
    /// @param subjectAmount The amount to be priced for listing subject to the fee in percentage
    /// @param token supported payment token
    /// @return totalBaseFee base calculated fee
    function getBaseOrderFee(uint subjectAmount, address token) public view returns(uint totalBaseFee, uint percentBaseFee, uint fixedBaseFee) {
        (totalBaseFee,percentBaseFee,fixedBaseFee) = _getBaseFee(OrderFee, subjectAmount, token);
        if(OrderFee.priceCap > 0){
            uint priceCapTokens = _calculatePriceCap(OrderFee, token);
            if(totalBaseFee > priceCapTokens){
                totalBaseFee = priceCapTokens;
            }
        }
    }

    /// @notice set new fixed base fee for the order type listing
    /// @dev the input must be in EXP format
    /// @param fixedBaseFee value to be charged in USD
    function setFixedBaseOrderFee(uint fixedBaseFee) external onlyAdmin {
        OrderFee.fixedBaseFee = fixedBaseFee;
    }

    /// @notice activate or deactivate fixedBaseFee
    /// @param active bool as true or false
    function switchFixedBaseOrderFee(bool active) external onlyAdmin {
        OrderFee.isFixedBaseFee = active;
    }

    /// @notice set new percent base fee for the order type listing
    /// @dev the input must be in EXP format max 1e18
    /// @param percentBaseFee value to be charged in Percentage
    function setPercentBaseOrderFee(uint percentBaseFee) external onlyAdmin {
        OrderFee.percentBaseFee = percentBaseFee;
    }

    /// @notice activate or deactivate percentBaseFee
    /// @param active bool as true or false
    function switchPercentBaseOrderFee(bool active) external onlyAdmin {
        OrderFee.isPercentBaseFee = active;
    }

    /// @notice get applied base fee for the auction type listing
    /// @param subjectAmount The amount to be priced for listing subject to the fee in percentage
    /// @param token supported payment token
    /// @return baseFee base calculated fee
    function getBaseAuctionFee(uint subjectAmount, address token) public view returns(uint baseFee, uint percentBaseFee, uint fixedBaseFee) {
        (baseFee,percentBaseFee,fixedBaseFee) = _getBaseFee(AuctionFee, subjectAmount, token);
        if(AuctionFee.priceCap > 0){
            uint priceCapTokens = _calculatePriceCap(AuctionFee, token);
            if(baseFee > priceCapTokens){
                baseFee = priceCapTokens;
            }
        }
    }

    /// @notice set new fixed base fee for the auction type listing
    /// @dev the input must be in EXP format
    /// @param fixedBaseFee value to be charged in USD
    function setFixedBaseAuctionFee(uint fixedBaseFee) external onlyAdmin {
        AuctionFee.fixedBaseFee = fixedBaseFee;
    }

    /// @notice activate or deactivate fixedBaseFee
    /// @param active bool as true or false
    function switchFixedBaseAuctionFee(bool active) external onlyAdmin {
        AuctionFee.isFixedBaseFee = active;
    }

    /// @notice set new percent base fee for the auction type listing
    /// @dev the input must be in EXP format max 1e18
    /// @param percentBaseFee value to be charged in Percentage
    function setPercentBaseAuctionFee(uint percentBaseFee) external onlyAdmin {
        AuctionFee.percentBaseFee = percentBaseFee;
    }

    /// @notice activate or deactivate percentBaseFee
    /// @param active bool as true or false
    function switchPercentBaseAuctionFee(bool active) external onlyAdmin {
        AuctionFee.isPercentBaseFee = active;
    }

    /// @notice get applied base fee for the auction type listing
    /// @param subjectAmount The amount to be priced for listing subject to the fee in percentage
    /// @return finalFee final calculated fee
    function getFinalOrderFee(uint subjectAmount, address token) public view returns(uint finalFee) {
        finalFee = _getFinalFee(OrderFee, subjectAmount);
        if(OrderFee.priceCap > 0){
            uint priceCapTokens = _calculatePriceCap(OrderFee, token);
            if(finalFee > priceCapTokens){
                finalFee = priceCapTokens;
            }
        }
    }

    /// @notice set new final fee for the order type listing
    /// @dev the input must be in EXP format max 1e18
    /// @dev charged only when a sale completed successfully
    /// @param finalFeePercentage value to be charged in Percentage
    function setFinalOrderFee(uint finalFeePercentage) external onlyAdmin {
        OrderFee.finalFeePercentage = finalFeePercentage;
    }

    /// @notice activate or deactivate finalFeePercentage
    /// @param active bool as true or false
    function switchFinalOrderFee(bool active) external onlyAdmin {
        OrderFee.isFinalFeePercentage = active;
    }

    /// @notice get applied base fee for the auction type listing
    /// @param subjectAmount The amount to be priced for listing subject to the fee in percentage
    /// @return finalFee final calculated fee
    function getFinalAuctionFee(uint subjectAmount, address token) public view returns(uint finalFee) {
        finalFee = _getFinalFee(AuctionFee, subjectAmount);
        if(AuctionFee.priceCap > 0){
            uint priceCapTokens = _calculatePriceCap(AuctionFee, token);
            if(finalFee > priceCapTokens){
                finalFee = priceCapTokens;
            }
        }
    }
    
    /// @notice set new final fee for the order type listing
    /// @dev the input must be in EXP format max 1e18
    /// @dev charged only when a sale completed successfully
    /// @param finalFeePercentage value to be charged in Percentage
    function setFinalAuctionFee(uint finalFeePercentage) external onlyAdmin {
        AuctionFee.finalFeePercentage = finalFeePercentage;
    }

    /// @notice activate or deactivate finalFeePercentage
    /// @param active bool as true or false
    function switchFinalAuctionFee(bool active) external onlyAdmin {
        AuctionFee.isFinalFeePercentage = active;
    }

    /// @notice set new final fee for the order type listing
    function getOrderPriceCap() public view returns(uint priceCap) {
        priceCap = OrderFee.priceCap;
    }
    /// @notice set new final fee for the order type listing
    /// @dev the input must be in EXP format max 1e18
    /// @dev charged only when a sale completed successfully
    /// @param priceCap value to be charged in Percentage
    function setOrderPriceCap(uint priceCap) external onlyAdmin {
        OrderFee.priceCap = priceCap;
    }

    /// @notice set new final fee for the order type listing
    function getAuctionPriceCap() public view returns(uint priceCap) {
        priceCap = AuctionFee.priceCap;
    }
    /// @notice set new final fee for the order type listing
    /// @dev the input must be in EXP format max 1e18
    /// @dev charged only when a sale completed successfully
    /// @param priceCap value to be charged in Percentage
    function setAuctionPriceCap(uint priceCap) external onlyAdmin {
        AuctionFee.priceCap = priceCap;
    }

    /// @notice get total deposit of the given user for fee payment
    /// @param user The fee depositor
    /// @param token token address for balance
    /// @return balance balance of user against provided token, native balance incase of 0 address
    function getFeePaid(address user, address token) public view returns(uint balance) {
        balance = paymentRecords[user][token];
    }

    /// @notice To deposit funds for fee payment, can be used with combination of other functions or directly
    /// @param fee fee to be disposed
    /// @param paymentToken token used to pay the fee
    function payNow(uint fee, address paymentToken) payable public {
        if(isTokenSupported(paymentToken)){
            if(fee > 0){
                if(paymentToken == address(0)){
                    require(msg.value >= fee, "ERROR: LOW_VALUE_OBSERVED");
                    payable(feeReceiver).transfer(fee);
                }else{
                    uint256 feeToPay = fee;
                    if(discountAmount[paymentToken] > 0){
                        feeToPay = fee * discountAmount[paymentToken] / 1e18;
                    }
                    IERC20MetadataUpgradeable fundToken = IERC20MetadataUpgradeable(paymentToken);
                    uint allowance = fundToken.allowance(_msgSender(), address(this));
                    require(allowance >= fee, "ERROR: INSUFFICIENT_ALLOWANCE");
                    fundToken.safeTransferFrom(_msgSender(), feeReceiver, feeToPay);
                }
                paymentRecords[_msgSender()][paymentToken] += fee;
            }
        }
    }

    /// @notice Only for swapr to dispose or remove the fee deposits after listing or sale
    /// @param data should contain fee, user and paymentToken as encoded data
    function disposeFeeRecord(bytes calldata data) external onlySwapr {
        (uint fee, address user, address paymentToken) = abi.decode(data, (uint, address, address));
        if(paymentRecords[user][paymentToken] > fee){
            paymentRecords[user][paymentToken] -= fee;
        }else{
            delete paymentRecords[user][paymentToken];
        }
    }

    /// @notice decodes the FeePricing type encoded data
    function _extractFeePricingInfo(bytes memory data) internal pure returns(FeePricing memory feePricing) {
        feePricing = abi.decode(data, (FeePricing));
    }

    /// @notice Internal function to help calculate the base fee from percentage
    /// @param feePricing refer to type FeePricing type
    /// @return totalBaseFee total base calculated fee
    function _getBaseFee(FeePricing memory feePricing, uint subjectAmount, address token) internal view returns(uint totalBaseFee, uint percentBaseFee, uint fixedBaseFee) {
        
        require(feePricing.percentBaseFee <= EXP, "BIGGER_THAN_MAX");
        require(isTokenSupported(token), "TOKEN_NOT_SUPPORTED");

        percentBaseFee = subjectAmount * feePricing.percentBaseFee / EXP;

        uint baseRecount = (feePricing.fixedBaseFee * BPS / _getPrice(oracleFeedForToken[token]) * BPS);
        fixedBaseFee = baseRecount * _getFeedDecimals(oracleFeedForToken[token]) / DPS;

        if(feePricing.isFixedBaseFee && feePricing.isPercentBaseFee){
            totalBaseFee = fixedBaseFee + percentBaseFee;
        }
        if(feePricing.isFixedBaseFee && !feePricing.isPercentBaseFee){
            totalBaseFee = fixedBaseFee;
        }
        if(!feePricing.isFixedBaseFee && feePricing.isPercentBaseFee){
            totalBaseFee = percentBaseFee;
        }

    }

    /// @notice Internal function to help calculate the final fee from percentage
    /// @param feePricing refer to type FeePricing type
    /// @return finalFee final calculated fee
    function _getFinalFee(FeePricing memory feePricing, uint subjectAmount) internal pure returns(uint finalFee) {
        require(feePricing.finalFeePercentage <= EXP, "BIGGER_THAN_MAX");
        if(feePricing.isFinalFeePercentage){
            finalFee = subjectAmount * feePricing.finalFeePercentage / EXP;
        }
    }

    function _exists(address _paymentToken) internal view returns(bool exists, uint idx) {
        for (uint i = 0; i < paymentTokens.length; i++) {
            if (paymentTokens[i] == IERC20MetadataUpgradeable(_paymentToken)) {
                idx = i;
                exists = true;
            }
        }
    }

    function _calculatePriceCap(FeePricing memory feePricing, address token) internal view returns (uint priceCapTokens) {
        uint capRecount = (feePricing.priceCap * BPS / _getPrice(getTokenFeed(token)) * BPS);
        priceCapTokens = capRecount * _getFeedDecimals(getTokenFeed(token)) / DPS;
    }

    function _getPrice(AggregatorV3Interface priceFeed) internal view returns (uint) {
        (
            ,int price,,uint timeStamp,
        ) = priceFeed.latestRoundData();
        require(timeStamp > 0, "Round not complete");
        return uint(price);
    }
    
    function _getFeedDecimals(AggregatorV3Interface priceFeed) internal view returns(uint priceFeedDecimals) {
        priceFeedDecimals = 10**uint(priceFeed.decimals());
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./common/BaseGovernanceUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./utils/ListingHelper.sol";
import "./SwaprFee.sol";

/// @title Manages NFT listings and user funds
/// @author swapr
/// @notice Allows only signature based listings
/// @dev Can only be interacted from a recognised marketplace EOA
contract SwaprGL is BaseGovernanceUpgradeable, ListingHelper {

    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    event Purchased(bool isSplit, Order order, uint[] splitParts);
    event Claimed(bool success, string res);

    uint constant SPLIT_LIMIT = 1e15;
    uint constant BPS = 1000;
    uint constant DPS = BPS*BPS;
    
    uint public listingModTimeLimit;

    SwaprFee private swaprFee;

    function initialize(bytes calldata data) public initializer {
        (
            address walletAddress,
            address marketplaceAddress,
            address swaprFeeAddress
        ) = abi.decode(
            data,
            (
                address,
                address,
                address
            )
        );
        __BaseGovernance_init();

        //You can setup custom roles here in addition to the default gevernance roles
        //e.g _setupRole(MARKETPLACE_ROLE, marketplaceAddress);

        //All state variables must be initialized here in sequence to prevent upgrade conflicts
        swaprWallet = SwaprWallet(payable(walletAddress));
        swaprFee = SwaprFee(payable(swaprFeeAddress));
        theMarketplace = marketplaceAddress;
        timeOffset = 5*60;//15 minutes
        listingModTimeLimit = 60*60;//1 hour
    }

    /// @notice Get active swapr wallet address
    /// @return Address of the wallet contract
    function getWallet() public view returns(address){
        return address(swaprWallet);
    }

    /// @notice Only admin role can attach a new swapr wallet incase
    function attachNewWallet(address wallet) external onlyAdmin {
        //requires a decision in case
        swaprWallet = SwaprWallet(payable(wallet));
    }

    /// @notice Only admin role can attach a new swapr fee contract incase
    function attachNewFeeContract(address feeContract) external onlyAdmin {
        //requires a decision in case
        swaprFee = SwaprFee(feeContract);
    }

    /// @notice To update the marketplace account incase
    function attachNewMarketplace(address marketplace) external onlyAdmin {
        theMarketplace = marketplace;
    }

    /// @notice To update the offset time incase
    function updateTimeOffset(uint timeInSecs) external onlyAdmin {
        timeOffset = timeInSecs;
    }
    
    /// @notice sets the max time in which a listing can be modified
    function setListingUpdateTime(uint timeInSecs) external onlyAdmin {
        listingModTimeLimit = timeInSecs;
    }

    /// @notice Triggers the payment process for any valid purchase on listing
    /// @dev Can handle Native or ERC payments of any kind
    /// @param payOps refer to type PayNow
    /// @return paid true if payment succeeds
    function payNow(PayNow memory payOps) public payable returns(bool paid) {
        if(payOps.fromBalance >= payOps.amount){
            paid = _payFromWallet(payOps);
        }else{
            paid = _payUpfront(payOps, msg.value);
        }
    }

    /// @notice performs a payment from buyer to seller for Native/ERC20 tokens
    /// @dev can use if buyer do have funds within swapr wallet
    /// @param _payOps refer to PayNow struct for details
    /// @return true if payment succeeds
    function _payFromWallet(PayNow memory _payOps) internal returns(bool) {
        if(_payOps.acceptedToken == address(0)){
            swaprWallet.swapNative(_payOps.from, _payOps.receiver, _payOps.amount);
            if(_payOps.toEOA){swaprWallet.releaseNative(_payOps.receiver, _payOps.receiver, _payOps.amount);}
        }else{
            swaprWallet.swapERC(_payOps.acceptedToken, _payOps.from, _payOps.receiver, _payOps.amount);
            if(_payOps.toEOA){swaprWallet.releaseERC(_payOps.acceptedToken, _payOps.receiver, _payOps.receiver, _payOps.amount);}
        }
        return true;
    }

    /// @notice performs an upfront payment from buyer to seller for Native/ERC20 tokens
    /// @dev can use if buyer do not have any funds within swapr wallet
    /// @param _payOps refer to PayNow struct for details
    /// @param value value attached to payable in case of Native currency
    /// @return true if payment succeeds
    function _payUpfront(PayNow memory _payOps, uint value) internal returns(bool) {

        address receiver = _payOps.toEOA ? _payOps.receiver : address(swaprWallet);

        if(_payOps.acceptedToken == address(0)){
            require(value >= _payOps.amount, "LOW_VALUE_OBSERVED");
            payable(receiver).transfer(_payOps.amount);
            if(!_payOps.toEOA){
                swaprWallet.depositNativeSwapr(_payOps.receiver, _payOps.amount);
            }
        }else{
            IERC20MetadataUpgradeable paymentToken = IERC20MetadataUpgradeable(_payOps.acceptedToken);
            require(paymentToken.allowance(_payOps.from, address(this)) >= _payOps.amount, "INSUFFICIENT_ALWNC");
            paymentToken.safeTransferFrom(_payOps.from, receiver, _payOps.amount);
            if(!_payOps.toEOA){
                swaprWallet.depositERCSwapr(_payOps.acceptedToken, _payOps.receiver, _payOps.amount);
            }
        }
        return true;
    }

    /// @notice Deposit NFTs to be listed only ERC721 ILock proxies are accepted
    /// @dev depositType == 3 means deposit to list for sale in future
    /// @param data should be signed by the depositor of NFT
    function depositNFTs(bytes calldata data) external {

        require(_verify(_msgSender(), data), "INCORRECT_SIG");
        (bytes memory message, bytes memory sig) = abi.decode(data, (bytes, bytes));
        (uint depositType, address lock, uint nftId) = abi.decode(message, (uint, address, uint));
        require(depositType == 3, "INVALID_CMD");
        swaprWallet.lockNFT(sig, lock, nftId, _msgSender());

    }

    /// @notice Creates a new listing for Auction or Order type based on data provided
    /// @dev Only proceeds with valid marketplace signature
    /// @param listingType 1 equals Auction, 2 equals Order
    /// @param data contains the encoded string
    function createListing(uint listingType, uint fee, bytes calldata data) external onlyMarketplace(data) {

        address sender = _msgSender();
        (bytes memory listingData,) = abi.decode(data, (bytes, bytes));
        (bool isValid, address lock, uint nftId, address paymentToken, bytes memory sig, string memory res) = _validateListing(sender, listingType, listingData);
        require(isValid, res);
        require(swaprFee.getFeePaid(sender, paymentToken) >= fee, "LOWER_FEE_PAID");
        swaprWallet.lockNFT(sig, lock, nftId, sender);
        swaprFee.disposeFeeRecord(abi.encode(fee, sender, paymentToken));

    }

    /// @notice Updates a new listing for Auction or Order type based on data provided
    /// @dev Only proceeds with valid marketplace signature
    /// @param listingType 1 equals Auction, 2 equals Order
    /// @param data contains the encoded string
    function updateListing(uint listingType, bytes calldata data) external onlyMarketplace(data) {
        address sender = _msgSender();
        (bytes memory activeListingData, bytes memory proposedListingData,) = abi.decode(data, (bytes, bytes, bytes));
        require(_verify(sender, activeListingData) && _verify(sender, proposedListingData), "SNDR_MUST_BE_FIRST_SLR");
        uint createdOn;
        if(listingType == 1){
            //Auction
            Auction memory auction = _extractAuctionInfo(activeListingData);
            createdOn = auction.createdOn;
        }else if(listingType == 2){
            //Order
            Order memory order = _extractOrderInfo(activeListingData);
            createdOn = order.createdOn;
        }
        require(block.timestamp - createdOn <= listingModTimeLimit, "MODIFY_TIME_EXD");
        (bool isValid, address lock, uint nftId,, bytes memory sig, string memory res) = _validateListing(sender, listingType, proposedListingData);
        require(isValid, res);
        swaprWallet.updateLockedNFT(sig, lock, nftId);
    }

    /// @notice Buyer's function to proceed purchase of Order type listing
    /// @dev automatically detects if buyer have wallet deposits or provoke for approval
    /// @dev you can check the deposits by getBalance() or else get approval for funds
    /// @dev does not require buyer's signature since its direct purchase but requires sellers signature
    /// @dev it also requires the marketplace signature to make sure the Order type data is not forged
    /// @param buyerPurchasedAmount front end dev should maintain the amount purchased by each wallet and send in
    /// @param data must be Order type provided with marketplace signature
    /// @param split SHould not be zero or more than EXP
    function buyNowOrder(uint buyerPurchasedAmount, bytes memory data, uint split) external onlyMarketplace(data) {

        (bytes memory listingData,) = abi.decode(data, (bytes, bytes));
        (, bytes memory sig) = abi.decode(listingData, (bytes, bytes));
        bool isSplit;
        Order memory order = _extractOrderInfo(listingData);
        require(swaprWallet.isNFTLocked(order.lock, order.nftId), "ORD_NOT_EXIST");
        require(order.depositType == 2, "INVALID_DEPOSIT_TYPE");
        require(split > 0 && split <= EXP && split <= order.remainingPart && split <= order.maxBuyPerWallet, "INCORRECT_SPLIT_AMT");
        //require(split >= SPLIT_LIMIT, "SPLIT_TOO_LOW");

        address buyer = _msgSender();
        require(buyerPurchasedAmount < order.maxBuyPerWallet, "PURCHASE_LMT_EXCEEDED");

        //MakePayment
        uint price = order.fixedPrice * split / EXP;
        
        PayNow memory payOps = PayNow(order.toEOA, order.acceptedToken, buyer, order.seller, swaprWallet.getBalance(buyer,order.acceptedToken), price);
        require(payNow(payOps), "PMT_FAILED");

        if(split < order.remainingPart){
            uint[] memory splitParts = new uint[](2);
            address[] memory addresses = new address[](2);
            //seller's part
            uint splitRecount = (split * BPS / order.remainingPart * BPS);
            uint splitAdjust = splitRecount * EXP / DPS;
            splitParts[0] = EXP - splitAdjust;
            addresses[0] = getWallet();
            //buyer's part
            splitParts[1] = splitAdjust;
            addresses[1] = buyer;
            uint[] memory newIDs = swaprWallet.splitReleaseNFT(order.lock, order.nftId, splitParts, addresses);
            order.nftId = newIDs[0];
            order.remainingPart = order.remainingPart - split;//where remainingPart should be unsold part of the NFT
            if(order.remainingPart > 0){
                isSplit = true;
            }
            swaprWallet.lockNFT(sig, order.lock, order.nftId, getWallet());
            emit Purchased(isSplit, order, splitParts);
        }else{
            swaprWallet.releaseNFT(order.lock, order.nftId, buyer);
            swaprWallet.disposeNFT(order.lock, order.nftId);
        }

    }

    /// @notice Buyer's function to proceed purchase of Auction type listing
    /// @dev automatically detects if buyer have wallet deposits or provoke for approval
    /// @dev you can check the deposits by getBalance() or else get approval for funds
    /// @param data must be Auction & Bid type provided with marketplace signature
    function buyNowAuction(bytes memory data) external onlyMarketplace(data) {

        (bytes memory message,) = abi.decode(data, (bytes, bytes));
        (
            bool isActiveBid,
            bytes memory listingData, 
            bytes memory lastBid
        ) = abi.decode(message, (bool, bytes, bytes));

        Auction memory auction = _extractAuctionInfo(listingData);
        require(swaprWallet.isNFTLocked(auction.lock, auction.nftId), "AUC_NOT_EXIST");
        require(auction.depositType == 1, "INVALID_DPST_TYPE");

        if(isActiveBid){
            Bid memory bid = _extractBid(lastBid);
            require(block.timestamp < bid.listingEndTime, "AUC_ENDED");
            require(auction.buyNowPrice > bid.offerPrice, "HIGHER_BID_PLACED");
        }

        address buyer = _msgSender();

        PayNow memory payOps = PayNow(auction.toEOA, auction.acceptedToken, buyer, auction.seller, swaprWallet.getBalance(buyer,auction.acceptedToken), auction.buyNowPrice);
        require(payNow(payOps), "PMT_FAILED");

        swaprWallet.releaseNFT(auction.lock, auction.nftId, buyer);
        swaprWallet.disposeNFT(auction.lock, auction.nftId);

    }

    /// @notice is for Auction type only so that seller or buyer can claim their rightful assets/funds
    /// @dev automatically detects if buyer have wallet deposits or provoke for approval
    /// @dev you can check the deposits by getBalance() or else get approval for funds
    /// @param data must be Auction & Bid type provided with marketplace signature
    function claim(bytes calldata data) external onlyMarketplace(data) {

        (bytes memory message,) = abi.decode(data, (bytes, bytes));
        (
            bytes memory listingData, 
            bytes memory lastBid
        ) = abi.decode(message, (bytes, bytes));

        
        address claimant = _msgSender();
        (bool success, string memory res) = _validateClaim(claimant, listingData, lastBid);

        Bid memory bid = _extractBid(lastBid);
        Auction memory auction = _extractAuctionInfo(listingData);

        if(_verify(claimant, listingData)){
            //for seller
            PayNow memory payOps = PayNow(auction.toEOA, auction.acceptedToken, bid.bidder, claimant, swaprWallet.getBalance(bid.bidder,auction.acceptedToken), bid.offerPrice);
            require(payNow(payOps), "PMT_FAILED");
        }else if(_verify(claimant, lastBid)){
            //for buyer
            swaprWallet.releaseNFT(auction.lock, auction.nftId, claimant);
            swaprWallet.disposeNFT(auction.lock, auction.nftId);
        }else{
            success = false;
            res = "INCORRECT_CLAIMANT";
        }

        require(success, res);
        emit Claimed(success, res);

    }

    /// @notice withdraws deposited NFTs if needed
    /// @dev only for marketplace to prevent listed NFTs being withdrawn
    /// @param data must be provided with marketplace signature
    function withdrawNFT(bytes calldata data) external onlyMarketplace(data) {
        (bytes memory info,) = abi.decode(data, (bytes, bytes));
        (address lock, uint nftId) = abi.decode(info, (address, uint));
        address sender = _msgSender();
        //if(_verify(sender, abi.encode(info, swaprWallet.getNFT(lock, nftId)))){
        _withdraw(sender, lock, nftId);
        //}
    }

    /// @notice withdraws native/erc20 deposited funds
    /// @dev anyone can withdraw deposited funds because getBalance() only returns unlocked funds
    /// @param data must be provided with marketplace signature
    function withdrawFunds(bytes calldata data) external onlyMarketplace(data) {
        (bytes memory info,) = abi.decode(data, (bytes, bytes));
        (address token, uint withdrawable, address receiver) = abi.decode(info, (address, uint, address));
        _withdraw(token, withdrawable, receiver, _msgSender());
    }

    /// @notice internal implementation for NFT withdraw
    function _withdraw(address claimant, address lock, uint nftId) internal {
        require(swaprWallet.isNFTLocked(lock, nftId), "ASSET_NOT_AVAILABLE");
        swaprWallet.releaseNFT(lock, nftId, claimant);
    }

    /// @notice internal implementation for Native/ERC20 withdraw
    function _withdraw(address token, uint withdrawable, address receiver, address claimant) internal {
        if(withdrawable > 0){
            if(token == address(0)){
                swaprWallet.releaseNative(receiver, claimant, withdrawable);
            }else{
                swaprWallet.releaseERC(token, receiver, claimant, withdrawable);
            }
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./common/BaseGovernanceUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./interfaces/ILock.sol";
import "./interfaces/ISplitManager.sol";

/// @title Deals with user funds and assets only
/// @author swapr
/// @notice Only deals with ILock ERC721 proxy, ETH,BNB,MATIC or ERC20 funds
/// @dev Can only be interacted from an identified Swapr contract
contract SwaprWallet is BaseGovernanceUpgradeable, ERC721HolderUpgradeable {

    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint constant EXP = 1e18;

    mapping(address => mapping(uint => bytes)) private lockedNFTs;// for sig based nft deposits

    mapping(address => mapping(address => uint)) private ercBank;//erc deposits
    
    mapping(address => uint) private nativeBank;//native deposits

    event Splitted(uint256[] newIDs);

    bytes32 public constant SWAPRGL_ROLE = keccak256("SWAPRGL_ROLE");

    /// @notice only allows calls from Swapr on-chin or Swapr Signature based contracts
    modifier onlySwapr() {
        require(hasRole(SWAPRGL_ROLE, _msgSender()), "ERROR: ONLY_SWAPR_ROLE");
        _;
    }

    function initialize(bytes calldata data) public initializer {
        (
            address swaprGLAddress
        ) = abi.decode(
            data, 
            (
                address
            )
        );
        __BaseGovernance_init();
        // //You can setup custom roles here in addition to the default gevernance roles
        _setupRole(SWAPRGL_ROLE, swaprGLAddress);

        // //All variables must be initialized below this comment in sequence to prevent upgrade conflicts
    }

    /// @notice transfers the asset to self
    /// @dev requires NFT to be approved by depositor prior to call
    /// @param lock address of ERC721 proxy
    /// @param nftId tokenId
    /// @param owner owner of the asset
    function _transferToSelfNFT(address lock, uint nftId, address owner) internal {
        ILock lockContract = ILock(lock);
        require(_getNFTOwner(lock, nftId) == owner , "ERROR: NO_NFT_OWNERSHIP");
        //requires approval for transfer
        lockContract.safeTransferFrom(owner, address(this), nftId);
    }

    /// @notice locks the NFT within wallet bound by owner signature
    /// @dev sig can be used anywhere to refer to this nft along with the offchain data
    /// @param sig user's sign with purpose of deposit as message
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @param owner address of the owner to verify the ownership
    function lockNFT(bytes calldata sig, address lock, uint nftId, address owner) external onlySwapr {
        require(getLockedPart(lock, nftId) < EXP, "LOCKED_PART_IS_100");
        if(!_isNFT(lock, nftId)){
            _transferToSelfNFT(lock, nftId, owner);
        }
        lockedNFTs[lock][nftId] = sig;
    }
    function updateLockedNFT(bytes calldata sig, address lock, uint nftId) external onlySwapr {
        require(_getNFTOwner(lock,nftId) == address(this), "WALLET_IS_NOT_OWNER");
        lockedNFTs[lock][nftId] = sig;
    }

    /// @notice splits the NFT from lock if it has locked part
    /// @dev this function is experimental and the dev may perform splitting directly through lock proxy
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @param addresses array of addresses of new owners
    function splitLockedPart(address lock, uint nftId, address[] memory addresses) external returns(uint256[] memory newIDs) {
        uint256 lockedPart = getLockedPart(lock, nftId);
        uint256 splitablePart = EXP - lockedPart;

        uint256[] memory splitParts = new uint[](2);
        splitParts[0] = lockedPart;
        splitParts[1] = splitablePart;

        //requires approval
        newIDs = ILock(lock).split(nftId, splitParts, addresses);
        emit Splitted(newIDs);
    }
    function getLockedPart(address lock, uint nftId) public view returns(uint256 lockedPart) {
        ILock lockContract = ILock(lock);
        ISplitManager splitManager = ISplitManager(lockContract.splitManager());
        lockedPart = splitManager.getLockedPart(nftId);
    }

    /// @notice removes the NFT record from within SwaprWallet
    /// @dev only for SwaprGL sig based deposits
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    function disposeNFT(address lock, uint nftId) external onlySwapr {
        if(_isNFT(lock, nftId)){
            delete lockedNFTs[lock][nftId];
        }
    }

    /// @notice transfers the ownership from itself to some EOA
    /// @dev only for SwaprGL sig based deposits
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @param receiver address of the new owner
    function releaseNFT(address lock, uint nftId, address receiver) external onlySwapr {//claim outside swapr wallet - withdraw
        ILock lockContract = ILock(lock);
        delete lockedNFTs[lock][nftId];
        lockContract.safeTransferFrom(address(this), receiver, nftId);
    }

    /// @notice splits the NFT before release on buy now
    /// @dev only for splitable purchase
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @param splitParts parts to be splitted in percentage
    /// @param addresses array of addresses of new owners sequentially as splitParts
    function splitReleaseNFT(address lock, uint nftId, uint[] calldata splitParts, address[] calldata addresses) external returns(uint256[] memory newIDs) {
        newIDs = ILock(lock).split(nftId, splitParts, addresses);
    }

    /// @notice Public function for user to deposit funds as ETH, BNB or MATIC etc
    function depositNative() public payable {
        require(msg.value > 0, "ERROR: LOW_VALUE_OBSERVED");
        nativeBank[_msgSender()] += msg.value;
    }

    /// @notice used when deposit occurs from swaprGL
    function depositNativeSwapr(address depositor, uint amount) external onlySwapr {
        nativeBank[depositor] += amount;
    }

    /// @notice swaps native ETH funds only within swapr wallet
    function swapNative(address from, address to, uint amount) external onlySwapr {
        require(nativeBank[from] >= amount, "ERROR: LOW_VALUE_RELEASE");
        nativeBank[from] -= amount;
        nativeBank[to] += amount;
    }

    /// @notice sends the held ETH funds from itself to some EOA
    function releaseNative(address receiver, address owner, uint amount) external onlySwapr {
        require(nativeBank[owner] >= amount, "ERROR: LOW_VALUE_RELEASE");
        nativeBank[owner] -= amount;
        payable(receiver).transfer(amount);
    }
    
    /// @notice deposits ERC20 funds first transfer to self and then within swapr wallet
    /// @dev approval for relevant token required for transfer to happen
    function depositERC(address token) external {
        IERC20MetadataUpgradeable fundToken = IERC20MetadataUpgradeable(token);
        uint allowance = fundToken.allowance(_msgSender(), address(this));
        require(allowance > 0, "ERROR: ZERO_ALLOWANCE");
        fundToken.safeTransferFrom(_msgSender(), address(this), allowance);
        ercBank[_msgSender()][token] += allowance;
    }

    /// @notice used when deposit occurs from swaprGL
    function depositERCSwapr(address token, address depositor, uint amount) external onlySwapr {
        ercBank[depositor][token] += amount;
    }

    /// @notice swaps ERC20 funds only within swapr wallet
    function swapERC(address token, address from, address to, uint amount) external onlySwapr {
        //unlock should be performed before swaping
        require(ercBank[from][token] >= amount, "ERROR: LOW_VALUE_RELEASE");
        ercBank[from][token] -= amount;
        ercBank[to][token] += amount;
    }

    /// @notice sends the held ERC20 funds from itself to some EOA
    function releaseERC(address token, address receiver, address owner, uint amount) external onlySwapr {
        require(ercBank[owner][token] >= amount, "ERROR: LOW_VALUE_RELEASE");
        IERC20MetadataUpgradeable paymentToken = IERC20MetadataUpgradeable(token);
        ercBank[owner][token] -= amount;
        paymentToken.transfer(receiver, amount);
    }

    /// @notice get available balance ETH / ERC20
    /// @dev balance excludes the locked balance
    /// @param owner address of the holder
    /// @param token address(0) means ETH balance
    /// @return balance funds that can be used
    function getBalance(address owner, address token) external view returns(uint balance) {
        if(token == address(0)){
            balance = _getNativeBalance(owner);
        }else{
            balance = _getErcBalance(owner, token);
        }
    }
    function _getNativeBalance(address _owner) internal view returns(uint) {
        return nativeBank[_owner];
    }
    function _getErcBalance(address _owner, address _token) internal view returns(uint) {
        return ercBank[_owner][_token];
    }

    /// @notice check if nft is locked within swapr
    function isNFTLocked(address lock, uint nftId) external view returns(bool) {
        return _isNFT(lock, nftId);
    }
    function _isNFT(address _lock, uint _nftId) internal view returns(bool){
        return abi.encodePacked(lockedNFTs[_lock][_nftId]).length > 0;
    }

    /// @notice get locked nft signature
    function getNFT(address lock, uint nftId) external view returns(bytes memory sig) {
        sig = lockedNFTs[lock][nftId];
    }

    /// @notice get owner of nft from lock proxy
    function _getNFTOwner(address lock, uint nftId) internal view returns(address) {
        ILock lockContract = ILock(lock);
        return lockContract.ownerOf(nftId);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "./../interfaces/ILock.sol";
import "./../SwaprWallet.sol";

contract ListingHelper {

    using ECDSAUpgradeable for bytes;

    uint constant EXP = 1e18;

    uint public timeOffset;
    address internal theMarketplace;
    SwaprWallet internal swaprWallet;

    /// @notice Struct type to encapsulate auction data
    /// @dev depositType is to detect the listing type as proposed listing type
    /// @dev activeDepositType is to check if asset is already listed as current listing type
    struct Auction {
        uint depositType;
        address lock;           //address of lock proxy erc721
        uint nftId;             //tokenId owned by seller
        bool toEOA;             //either seller want funds to external account or within swapr wallet
        address acceptedToken;  //accepted token for payment
        uint startingPrice;     //starting price for auction
        uint buyNowPrice;       //price to instantly buy asset from auction
        uint startTime;         //auction starting time
        uint endTime;           //auction ending time
        address seller;         //address of the seller
        uint activeDepositType;
        uint createdOn;
    }

    /// @notice Struct type to encapsulate order data
    /// @dev depositType is to detect the listing type as proposed listing type
    /// @dev activeDepositType is to check if asset is already listed as current listing type
    struct Order {
        uint depositType;
        address lock;
        uint nftId;
        bool toEOA;
        address acceptedToken;
        uint fixedPrice;        //price demand for asset
        uint maxTokenSell;      //maximum percentage of nft a buyer can buy in one go if set to 1 means no splitting allowed
        uint maxBuyPerWallet;   //maximum amount in percentage a wallet can buy from this listing
        uint remainingPart;     //internal record to maintaing the remaining splitted asset
        address seller;
        uint activeDepositType;
        uint createdOn;
    }

    /// @notice Struct type to accept the specific bidding info
    struct Bid{
        uint offerPrice;     //bidder's offered price
        uint lockedBalance;  //bidder's total locked balance within swapr wallet
        uint listingEndTime; //updated listing endtime (with added timeOffset) incase the bid was made in last minute
        address bidder;      //address of bidder
        address lock;        //lock address the bid is being validated for
        uint nftId;          //nftId the bid is being made for
    }

    /// @notice Struct type to encapsulate payment info
    struct PayNow{
        bool toEOA;             //if the seller wants payment in Externally Owned Account it should be true
        address acceptedToken;
        address from;           //address the payment is being made from
        address receiver;       //the payment should be sent to
        uint fromBalance;       //current balance of the buyer
        uint amount;            //amount to be paid
    }

    modifier onlyMarketplace(bytes memory data) {
        require(_verify(getMarketplace(), data), "ERROR: UNAUTHORIZED_SENDER");
        _;
    }
    
    /// @notice The marketplace public address for signing purposes
    function getMarketplace() public view returns(address) {
        return theMarketplace;
    }

    /// @notice Validates provided listing data if its acceptable to be listed for sale
    /// @dev Can use this before calling createListing to quickly validate
    /// @param listingData must be provided with sellers signature
    /// @return isValid true if succeeds
    /// @return res reason of failure
    function isListableAuction(bytes memory listingData) external view returns(bool isValid, string memory res) {
        
        Auction memory auction = _extractAuctionInfo(listingData);
        ILock lockContract = ILock(auction.lock);
        if(lockContract.ownerOf(auction.nftId) == auction.seller){
            (isValid,,,,,res) = _validateListing(auction.seller, auction.depositType, listingData);
        }

    }

    /// @notice Validates provided listing data if its acceptable to be listed for sale
    /// @dev Can use this before calling createListing to quickly validate
    /// @param listingData must be provided with sellers signature
    /// @return isValid true if succeeds
    /// @return res reason of failure
    function isListableOrder(bytes memory listingData) external view returns(bool isValid, string memory res) {
        
        Order memory order = _extractOrderInfo(listingData);
        ILock lockContract = ILock(order.lock);
        if(lockContract.ownerOf(order.nftId) == order.seller){
            (isValid,,,,,res) = _validateListing(order.seller, order.depositType, listingData);
        }
    }

    /// @notice Underlying actual implementation to validate listing
    /// @dev Can validate both the Auction type and Order type
    /// @param listingType must be either 1 or 2 any other will not be accepted
    /// @param listingData must be provided with sellers signature
    /// @return isValid if true can proceed else get failure reason from res
    function _validateListing(address sender, uint listingType, bytes memory listingData) internal view returns(bool isValid, address lock, uint nftId, address paymentToken, bytes memory sig, string memory res) {

        if(_verify(sender, listingData)){
            (, bytes memory _sig) = abi.decode(listingData, (bytes, bytes));

            sig = _sig;

            if(listingType == 1){
                //Auction
                (isValid, lock, nftId, paymentToken, res) = _validateAuctionCapability(listingData);
            }else if(listingType == 2){
                //Order
                (isValid, lock, nftId, paymentToken, res) = _validateOrderCapability(listingData);
            }else{
                res = "INVALID_LISTING_TYPE";
            }
        }else{
            res = "INVALID_SIGNATURE";
        }

    }

    /// @notice internal implementation to validate only Auction type data
    /// @notice all inputs same as validateListing
    function _validateAuctionCapability(bytes memory _listingData) private view 
    returns(
        bool isValid, address lockAddr, 
        uint tokenId, address paymentToken, string memory err
    ){

        Auction memory auction = _extractAuctionInfo(_listingData);

        if(swaprWallet.isNFTLocked(auction.lock, auction.nftId)){
            if(auction.activeDepositType == 0 || auction.activeDepositType == 3){
                isValid = true;
            }else{
                err = "ALREADY_LISTED";
            }
        }else{
            err = "INVALID_DEPOSIT_TYPE";
            if(auction.depositType == 1){
                err = "SLR_IS_0_ADR";
                if(auction.seller != address(0)){
                    err = "0_STARTING_PRICE";
                    if(auction.startingPrice > 0){
                        err = "BUY_NOW_PRICE_LOWER";
                        if(auction.buyNowPrice > auction.startingPrice){
                            err = "START_TIME_PAST_LIMIT";
                            if(auction.startTime + timeOffset <= auction.endTime){
                                err = "END_TIME_UNDER_LIMIT";
                                if(auction.endTime >= block.timestamp + timeOffset){
                                    isValid = true;
                                }
                            }
                        }
                    }
                }
            }
        }
        if(isValid){err = ""; lockAddr = auction.lock; tokenId = auction.nftId; paymentToken = auction.acceptedToken;}

    }

    /// @notice internal implementation to validate only Order type data
    /// @notice all inputs same as validateListing
    function _validateOrderCapability(bytes memory _orderData) private view 
    returns(
        bool isValid, address lockAddr, 
        uint tokenId, address paymentToken, string memory res
    ){

        Order memory order = _extractOrderInfo(_orderData);

        res = "INCORRECT_ORDER_DATA";
        if(
            order.maxTokenSell > 0 && order.maxTokenSell <= EXP &&
            order.maxBuyPerWallet > 0 && order.maxBuyPerWallet <= EXP
        ){
            if(swaprWallet.isNFTLocked(order.lock, order.nftId)){
                if(order.activeDepositType == 0 || order.activeDepositType == 3){
                    isValid = true;
                }else{
                    res = "ALREADY_LISTED";
                }
            }else{
                res = "INVALID_DEPOSIT_TYPE";
                if(order.depositType == 2){
                    res = "SLR_IS_0_ADDR";
                    if(order.seller != address(0)){
                        res = "ZERO_STARTING_PRICE";
                        if(order.fixedPrice > 0){
                            res = "INCORRECT_MAX_BUY_PER_WALLET";
                            if(order.maxBuyPerWallet > 0 && order.maxBuyPerWallet <= EXP){
                                isValid = true;
                            }
                        }
                    }
                }
            }
        }
        if(isValid){res = ""; lockAddr = order.lock; tokenId = order.nftId; paymentToken = order.acceptedToken;}

    }

    /// @notice Validates the  proposedBid data against the currently activeBid bid
    /// @dev Only marketplace can call this function to provide security
    /// @dev once a bid is validated old bid must be disabled on front-end
    /// @param data must be provided with marketplace signature
    /// @dev isActiveBid => If set to false then only validates proposedBid
    /// @return isValid true means bid is valid to be registered
    /// @return res in case of failure returns reason of failure
    /// @return validatedBid validated bid date with addtional time details for future validation
    function validateBid(bytes calldata data) external view onlyMarketplace(data) 
    returns(bool isValid, string memory res, Bid memory validatedBid){

        (bytes memory message,) = abi.decode(data, (bytes, bytes));
        (
            bool isActiveBid, bytes memory listingData, 
            bytes memory activeBidData, bytes memory proposedBidData
        ) = abi.decode(message, (bool, bytes, bytes, bytes));

        Auction memory auction = _extractAuctionInfo(listingData);
        Bid memory proposedBid = _extractBid(proposedBidData);

        res = "INCORRECT_PROPOSAL";
        if(auction.depositType == 1){
            res = "BIDDER_NOT_SIGNER";
            if(_verify(proposedBid.bidder, proposedBidData)){
                if(!isActiveBid){
                    (isValid, proposedBid.listingEndTime, res) = _validateAsFirstBid(listingData, proposedBid);
                }else{
                    Bid memory activeBid = _extractBid(activeBidData);
                    (isValid, proposedBid.listingEndTime, res) = _validateAsLastBid(message, activeBid, proposedBid);
                }
                uint bidderTotalBalance = swaprWallet.getBalance(proposedBid.bidder, auction.acceptedToken);
                res = "LOWER_BLNC_THAN_OFR";
                if(bidderTotalBalance >= proposedBid.lockedBalance){
                    if(bidderTotalBalance - proposedBid.lockedBalance >= proposedBid.offerPrice){
                        isValid = true;
                    }else{
                        isValid = false;
                    }
                }else{
                    isValid = false;
                }
            }
        }
        if(isValid){
            res = "";
            validatedBid = proposedBid;
        }

    }

    /// @notice part of validateBid which validates only if the bid is being placed for the first time
    function _validateAsFirstBid(bytes memory listingData, Bid memory bid) internal view 
    returns(
        bool isValid, uint proposedEndTime, string memory res
    ){

        (bytes memory listingInfo,) = abi.decode(listingData, (bytes, bytes));
        Auction memory auction = _extractAuctionInfo(listingData);
        
        res = "SIG_CROSS_CHECK_FAILED";
        if(_verify(auction.seller, abi.encode(listingInfo, swaprWallet.getNFT(bid.lock, bid.nftId)))){
            res = "AUCTION_CLOSED";
            if(auction.endTime > block.timestamp){
                if(auction.endTime - block.timestamp <= 60){
                    proposedEndTime = auction.endTime + timeOffset;
                }else{
                    proposedEndTime = auction.endTime;
                }
                res = "OFFER_LOWER_THAN_START_PRICE";
                if(bid.offerPrice >= auction.startingPrice){
                    isValid = true;
                }
            }
        }
        if(isValid){
            res="";
        }

    }

    /// @notice part of validateBid which validates every time after the first bid is placed
    function _validateAsLastBid(bytes memory message, Bid memory activeBid, Bid memory proposedBid) internal view 
    returns(
        bool isValid, uint proposedEndTime, string memory res
    ){

        (
            , bytes memory listingData, 
            bytes memory activeBidData,
        ) = abi.decode(message, (bool, bytes, bytes, bytes));
        (bytes memory listingInfo,) = abi.decode(listingData, (bytes, bytes));

        Auction memory auction = _extractAuctionInfo(listingData);

        res = "SIG_CROSS_CHECK_FAILED";
        if(_verify(auction.seller, abi.encode(listingInfo, swaprWallet.getNFT(activeBid.lock, activeBid.nftId)))){
            res = "UNRELATED_ACTIVE_BID";
            if(_verify(activeBid.bidder, activeBidData)){
                (isValid, proposedEndTime, res) = _bidsCrossValidate(auction, activeBid, proposedBid);
            }
        }
        if(isValid){
            res="";
        }
    }
    
    /// @notice Validates provided listing data if its acceptable to claimed by claimant
    /// @dev Can use this before calling claim to quickly validate
    /// @param listingData must be provided with sellers signature
    /// @param lastBid must be provided with bidders signature
    /// @return isValid true if succeeds
    /// @return res reason of failure
    function isClaimable(address claimant, bytes memory listingData, bytes memory lastBid) external view returns(bool isValid, string memory res) {
        (isValid, res) = _validateClaim(claimant, listingData, lastBid);
    }

    /// @notice Internal implementation for the claim validation wrapped to deal with msg.sender
    /// @dev Can use this before calling claim to quickly validate
    /// @param claimant is the user who's claim is being validated
    /// @param listingData must be provided with sellers signature
    /// @param bidData must be provided with bidders signature
    /// @return isValid true if succeeds
    /// @return res reason of failure
    function _validateClaim(address claimant, bytes memory listingData, bytes memory bidData) internal view returns(bool isValid, string memory res) {
        
        Auction memory auction = _extractAuctionInfo(listingData);
        Bid memory lastBid = _extractBid(bidData);
            
        res = "INVALID_LST_SIG";
        if(_verify(auction.seller, listingData)){
            res = "INVALID_BID_SIG";
            if(_verify(lastBid.bidder, bidData)){
                res = "AUCTION_NOT_ENDED";
                if(block.timestamp >= lastBid.listingEndTime){
                    res = "";
                    if(_verify(claimant, listingData)){
                        //for seller
                        uint bidderTotalBalance = swaprWallet.getBalance(lastBid.bidder, auction.acceptedToken);
                        if(bidderTotalBalance - lastBid.lockedBalance >= lastBid.offerPrice){
                            isValid = true;
                        }else{
                            res = "LOWER_BLNC_THAN_OFR";
                        }
                    }else if(_verify(claimant, bidData)){
                        //for bidder/buyer
                        if(swaprWallet.isNFTLocked(auction.lock, auction.nftId)){
                            isValid = true;
                        }else{
                            res = "ASSET_NO_LONGER_EXIST";
                        }
                    }else{
                        res = "INVALID_CLAIMANT";
                    }
                }
            }
        }

    }
    
    /// @notice decodes the Auction type encoded data
    function _extractAuctionInfo(bytes memory auctionData) internal pure returns(Auction memory auction) {

        (bytes memory auctionInfo,) = abi.decode(auctionData, (bytes, bytes));
        auction = abi.decode(auctionInfo, (Auction));

    }

    /// @notice decodes the Order type encoded data
    function _extractOrderInfo(bytes memory orderData) internal pure returns(Order memory order) {

        (bytes memory orderInfo,) = abi.decode(orderData, (bytes, bytes));
        order = abi.decode(orderInfo, (Order));

    }

    /// @notice decodes the Bid type encoded data
    function _extractBid(bytes memory bidData) internal pure returns(Bid memory bid) {

        (bytes memory bidInfo,) = abi.decode(bidData, (bytes, bytes));
        bid = abi.decode(bidInfo, (Bid));

    }

    function _bidsCrossValidate(Auction memory auction, Bid memory activeBid, Bid memory proposedBid) internal view returns(bool isValid, uint proposedEndTime, string memory res) {
        res = "INVALID_END_TIME";
        if(activeBid.listingEndTime >= auction.endTime){
            res = "AUCTION_CLOSED";
            if(activeBid.listingEndTime > block.timestamp){
                proposedEndTime = _getProposedEndTime(activeBid.listingEndTime);
                res = "OFFER_LOWER_THAN_START_PRICE";
                if(proposedBid.offerPrice >= auction.startingPrice){
                    res = "OFFER_LOWER_THAN_ACTIVE_BID";
                    if(activeBid.offerPrice < proposedBid.offerPrice){
                        isValid = true;
                    }
                }
            }
        }
    }
    function _getProposedEndTime(uint listingEndTime) internal view returns(uint proposedEndTime) {
        if(listingEndTime - block.timestamp <= 60){
            proposedEndTime = listingEndTime + timeOffset;
        }else{
            proposedEndTime = listingEndTime;
        }
    }

    function getSigner(bytes32 dataHash, bytes memory signature) public pure returns (address) {
        return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(dataHash), signature);
    }

    function _verify(address signer, bytes memory _data) public view returns(bool) {

        (
            bytes memory message,
            bytes memory signature
        ) = abi.decode(
            _data,
            (
                bytes,
                bytes
            )
        );
        return SignatureCheckerUpgradeable.isValidSignatureNow(signer, ECDSAUpgradeable.toEthSignedMessageHash(toMessageHash(message)), signature);
    }
    function toMessageHash(bytes memory message) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(message));
    }

}