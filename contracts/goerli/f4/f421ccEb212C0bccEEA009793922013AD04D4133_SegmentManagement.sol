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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IAuth.sol";

pragma solidity ^0.8.4;

abstract contract Auth is AccessControlUpgradeable, PausableUpgradeable, IAuth {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant BLACKLISTED_ROLE = keccak256("VALIDATOR_ROLE");

    function __Auth_init(address manager_, address pauser_) internal onlyInitializing {
        if (manager_ == address(0) || pauser_ == address(0)) revert ZeroAddress();
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, manager_);
        _setupRole(PAUSER_ROLE, pauser_);

        _setRoleAdmin(BLACKLISTED_ROLE, MANAGER_ROLE);
    }

    modifier validUser(address account) {
        if (hasRole(BLACKLISTED_ROLE, account)) revert BlacklistedUser(account);
        _;
    }

    function isValidUser(address account) external view returns (bool) {
        return !hasRole(BLACKLISTED_ROLE, account);
    }

    function isAdmin(address user) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, user);
    }

    function setPause(bool newState) external onlyRole(PAUSER_ROLE) {
        newState ? _pause() : _unpause();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Constants {
    // gNFT constants
    uint8 internal constant VOTE_WEIGHT_TOPAZ = 1;
    uint8 internal constant VOTE_WEIGHT_EMERALD = 11;
    uint8 internal constant VOTE_WEIGHT_DIAMOND = 121;

    uint8 internal constant REWARD_WEIGHT_TOPAZ = 1;
    uint8 internal constant REWARD_WEIGHT_EMERALD = 11;
    uint8 internal constant REWARD_WEIGHT_DIAMOND = 121;

    uint8 internal constant LIQUIDITY_FOR_MINTING_TOPAZ = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_MINTING_EMERALD = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_MINTING_DIAMOND = 1; // mul by EXP_1E20

    uint8 internal constant ACTIVATION_TOPAZ_NOMINATOR = 1;
    uint8 internal constant ACTIVATION_EMERALD_NOMINATOR = 10;
    uint8 internal constant ACTIVATION_DIAMOND_NOMINATOR = 100;

    uint8 internal constant LIQUIDITY_FOR_REWARDS_TOPAZ = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_REWARDS_EMERALD = 0; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_REWARDS_DIAMOND = 0; // mul by EXP_1E20

    uint8 internal constant REQUIRE_TOPAZES_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_TOPAZES_FOR_EMERALD = 10;
    uint8 internal constant REQUIRE_TOPAZES_FOR_DIAMOND = 10;

    uint8 internal constant REQUIRE_EMERALDS_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_EMERALDS_FOR_EMERALD = 0;
    uint8 internal constant REQUIRE_EMERALDS_FOR_DIAMOND = 1;

    uint8 internal constant REQUIRE_DIAMONDS_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_DIAMONDS_FOR_EMERALD = 0;
    uint8 internal constant REQUIRE_DIAMONDS_FOR_DIAMOND = 0;

    uint8 internal constant SEGMENTS_NUMBER = 12;
    uint256 internal constant REWARD_ACCUMULATING_PERIOD = 365 days;
    uint256 internal constant ACTIVATION_MIN_PRICE = 1000e18;
    uint256 internal constant ACTIVATION_DENOMINATOR = 1e3;
    uint256 internal constant AIRDROP_DISCOUNT_NOMINATOR = 0;
    uint256 internal constant AIRDROP_DISCOUNT_DENOMINATOR = 1e6;
    uint256 internal constant EXP_ORACLE = 1e18;
    uint256 internal constant EXP_LIQUIDITY = 1e20;
    string internal constant BASE_URI = "Not supported";

    //@notice uint8 parameters packed into bytes constant
    bytes internal constant M = hex"010b79010b79010101010a64010000000a0a000001000000";

    // Treasury constants
    uint256 internal constant EXP_REWARD_PER_SHARE = 1e12;
    uint256 internal constant REWARD_PER_SHARE_MULTIPLIER = 1e12;
    uint256 internal constant MAX_RESERVE_BPS = 5e3;
    uint256 internal constant DENOM_BPS = 1e4;

    // Common constants
    uint256 internal constant DEFAULT_DECIMALS = 18;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    function TYPE_PARAMETERS(uint256 col, uint256 row) internal pure returns (uint8) {
        unchecked {
            return uint8(M[row * 3 + col]);
        }
    }

    enum ParameterType {
        VoteWeight,
        RewardWeight,
        MintingLiquidity,
        ActivationNominator,
        RewardsLiquidity,
        RequiredTopazes,
        RequiredEmeralds,
        RequiredDiamonds
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Interface for Auth contract, which is a part of gNFT token
/// @notice Authorization model is based on AccessControl and Pausable contracts from OpenZeppelin:
///         (https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl) and
///         (https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
///         Blacklisting implemented with BLACKLISTED_ROLE, managed by MANAGER_ROLE
interface IAuth {
    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice Revert reason for protected functions being called by blacklisted address
    error BlacklistedUser(address account);

    /// @notice             Check for admin role
    /// @param user         User to check for role bearing
    /// @return             True if user has the DEFAULT_ADMIN_ROLE role
    function isAdmin(address user) external view returns (bool);

    /// @notice             Check for not being in blacklist
    /// @param user         User to check for
    /// @return             True if user is not blacklisted
    function isValidUser(address user) external view returns (bool);

    /// @notice             Control function of OpenZeppelin's Pausable contract
    ///                     Restricted to PAUSER_ROLE bearers only
    /// @param newState     New boolean status for affected whenPaused/whenNotPaused functions
    function setPause(bool newState) external;
}

// SPDX-License-Identifier: UNLICENSED

import "./ICToken.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound Comptroller contract
/// @notice Based on Comptroller from Compound Finance with different governance model
///         (https://docs.compound.finance/v2/comptroller/)
///         Modified Comptroller stores gNFT and Treasury addresses
///         Unmodified descriptions are copied from Compound Finance GitHub repo:
///         (https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/Comptroller.sol)
interface IComptroller {
    /// @notice         Returns whether the given account is entered in the given asset
    /// @param account  The address of the account to check
    /// @param market   The market(cToken) to check
    /// @return         True if the account is in the asset, otherwise false
    function checkMembership(address account, address market) external view returns (bool);

    /// @notice         Claim all rewards accrued by the holders
    /// @param holders  The addresses to claim for
    /// @param markets  The list of markets to claim in
    /// @param bor      Whether or not to claim rewards earned by borrowing
    /// @param sup      Whether or not to claim rewards earned by supplying
    function claimComp(
        address[] memory holders,
        address[] memory markets,
        bool bor,
        bool sup
    ) external;

    /// @notice         Returns rewards accrued but not yet transferred to the user
    /// @param account  User address to get accrued rewards for
    /// @return         Value stored in compAccrued[account] mapping
    function compAccrued(address account) external view returns (uint256);

    /// @notice         Add assets to be included in account liquidity calculation
    /// @param markets  The list of addresses of the markets to be enabled
    /// @return         Success indicator for whether each corresponding market was entered
    function enterMarkets(address[] memory markets) external returns (uint256[] memory);

    /// @notice             Determine the current account liquidity wrt collateral requirements
    /// @return err         (possible error code (semi-opaque)
    ///         liquidity   account liquidity in excess of collateral requirements
    ///         shortfall   account shortfall below collateral requirements)
    function getAccountLiquidity(
        address account
    ) external view returns (uint256 err, uint256 liquidity, uint256 shortfall);

    /// @notice Return all of the markets
    /// @dev    The automatic getter may be used to access an individual market.
    /// @return The list of market addresses
    function getAllMarkets() external view returns (address[] memory);

    /// @notice         Returns the assets an account has entered
    /// @param  account The address of the account to pull assets for
    /// @return         A dynamic list with the assets the account has entered
    function getAssetsIn(address account) external view returns (address[] memory);

    /// @notice Return the address of the TPI token
    /// @return The address of TPI
    function getCompAddress() external view returns (address);

    /// @notice Return the address of the governance gNFT token
    /// @return The address of gNFT
    function gNFT() external view returns (address);

    /// @notice View function to read 'markets' mapping separately
    /// @return Market structure without nested 'accountMembership'
    function markets(address market) external view returns (Market calldata);

    /// @notice Return the address of the system Oracle
    /// @return The address of Oracle
    function oracle() external view returns (address);

    /// @notice Return the address of the Treasury
    /// @return The address of Treasury
    function treasury() external view returns (address);

    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
        bool isComped;
    }
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound cToken market
/// @notice Extension of IERC20 standard interface from OpenZeppelin
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20)
interface ICToken is IERC20MetadataUpgradeable {
    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves() external returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ISegmentManagement.sol";

/// @title  gNFT governance token for Tonpound protocol
/// @notice Built on ERC721Votes extension from OpenZeppelin Upgradeable library
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Votes)
///         Supports Permit approvals (see IERC721Permit.sol) and Multicall
///         (https://docs.openzeppelin.com/contracts/4.x/api/utils#Multicall)
interface IgNFT {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason for protected functions being called by blacklisted address
    error BlacklistedUser(address account);

    /// @notice Revert reason for accessing protected functions during pause
    error Paused();

    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice              View method to read Tonpound Comptroller address
    /// @return              Address of Tonpound Comptroller contract
    function SEGMENT_MANAGEMENT() external view returns (ISegmentManagement);

    /// @notice               View method to get total vote weight of minted tokens,
    ///                       only gNFTs with fully activated segments participates in the voting
    /// @return               Value of Votes._getTotalSupply(), i.e. latest total checkpoints
    function getTotalVotePower() external view returns (uint256);

    /// @notice               View method to read 'tokenDataById' mapping of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId]' of TokenData type
    function getTokenData(uint256 tokenId) external view returns (TokenData memory);

    /// @notice               View method to read 'tokenDataById' mapping of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId]' of TokenData type
    function getTokenSlot0(uint256 tokenId) external view returns (Slot0 memory);

    /// @notice               View method to read 'tokenDataById' mapping of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId]' of TokenData type
    function getTokenSlot1(uint256 tokenId) external view returns (Slot1 memory);

    /// @notice               Minting new gNFT token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param to             Address of recipient
    /// @param data           Parameters of new token to be minted
    function mint(address to, TokenData memory data) external;

    /// @notice               Update Slot0 parameters of tokenData of a token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param tokenId        Token to be updated
    /// @param data           Slot0 structure to update existed
    function updateTokenDataSlot0(uint256 tokenId, Slot0 memory data) external;

    /// @notice               Update Slot1 parameters of tokenData of a token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param tokenId        Token to be updated
    /// @param data           Slot1 structure to update existed
    function updateTokenDataSlot1(uint256 tokenId, Slot1 memory data) external;

    struct TokenData {
        Slot0 slot0;
        Slot1 slot1;
    }

    struct Slot0 {
        TokenType tokenType;
        uint8 activeSegment;
        uint8 voteWeight;
        uint8 rewardWeight;
        bool usedForMint;
        uint48 completionTimestamp;
        address lockedMarket;
    }

    struct Slot1 {
        uint256 lockedVaultShares;
    }

    enum TokenType {
        Topaz,
        Emerald,
        Diamond
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Partial interface for Oracle contract
/// @notice Based on PriceOracle from Compound Finance
///         (https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/PriceOracle.sol)
interface IOracle {
    /// @notice         Get the underlying price of a market(cToken) asset
    /// @param market   The market to get the underlying price of
    /// @return         The underlying asset price mantissa (scaled by 1e18).
    ///                 Zero means the price is unavailable.
    function getUnderlyingPrice(address market) external view returns (uint256);

    /// @notice         Evaluates input amount according to stored price, accrues interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken'
    ///                     true - return cTokens equal to 'amount' of USD
    function getEvaluation(address cToken, uint256 amount, bool reverse) external returns (uint256);

    /// @notice         Evaluates input amount according to stored price, doesn't accrue interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken'
    ///                     true - return cTokens equal to 'amount' of USD
    function getEvaluationStored(
        address cToken,
        uint256 amount,
        bool reverse
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./IgNFT.sol";
import "./IComptroller.sol";
import "./ITPIToken.sol";
import "./ITreasury.sol";
import "./IOracle.sol";

/// @title  Segment management contract for gNFT governance token for Tonpound protocol
interface ISegmentManagement {
    /// @notice Revert reason for activating segments for a fully activated token
    error AlreadyFullyActivated();

    /// @notice Revert reason for repeating discount activation
    error DiscountUsed();

    /// @notice Revert reason for minting over the max segment number
    error ExceedingMaxSegments();

    /// @notice Revert reason for minting without liquidity in Tonpound protocol
    error FailedLiquidityCheck();

    /// @notice Revert reason for minting token with a market without membership
    error InvalidMarket();

    /// @notice Revert reason for activating segment with invalid Merkle proof for given account
    error InvalidProof();

    /// @notice Revert reason for activating more segments than available
    error InvalidSegmentsNumber();

    /// @notice Revert reason for operating tokens without ownership
    error InvalidTokenOwnership(uint256 tokenId);

    /// @notice Revert reason for activating last segment without specified liquidity for lock
    error MarketForLockNotSpecified();

    /// @notice Revert reason for minting high tier gNFT without providing proof of ownership
    error MintingRequirementsNotMet();

    /// @notice Revert reason for zero returned price from Oracle contract
    error OracleFailed();

    /// @notice Revert reason for trying to lock already locked token
    error TokenAlreadyLocked();

    /// @notice              Emitted during NFT segments activation
    /// @param tokenId       tokenId of activated token
    /// @param segments      Number of activated segments
    event ActivatedSegments(uint256 indexed tokenId, uint8 segments);

    /// @notice              Emitted after the last segment of gNFT token is activated
    /// @param tokenId       tokenId of completed token
    /// @param user          Address of the user who completed the token
    event TokenCompleted(uint256 indexed tokenId, address indexed user);

    /// @notice              Emitted when whitelisted users activate their segments with discount
    /// @param leaf          Leaf of Merkle tree being used in activation
    /// @param root          Root of Merkle tree being used in activation
    event Discounted(bytes32 leaf, bytes32 root);

    /// @notice             Emitted to notify about airdrop Merkle root change
    /// @param oldRoot      Old root
    /// @param newRoot      New updated root to be used after this tx
    event AirdropMerkleRootChanged(bytes32 oldRoot, bytes32 newRoot);

    /// @notice              View method to read Tonpound Comptroller address
    /// @return              Address of Tonpound Comptroller contract
    function TONPOUND_COMPTROLLER() external view returns (IComptroller);

    /// @notice View method to read gNFT
    /// @return Address of gNFT contract
    function gNFT() external view returns (IgNFT);

    /// @notice View method to read Tonpound TPI token
    /// @return Address of TPI token contract
    function TPI() external view returns (ITPIToken);

    /// @notice               View method to get price in TPI tokens to activate segments of gNFT token
    /// @param tokenId        tokenId of the token to activate segments of
    /// @param segmentsToOpen Number of segments to activate, fails if this number exceeds available segments
    /// @param discounted     Whether the user is eligible for activation discount
    /// @return               Price in TPI tokens to be burned from caller to activate specified number of segments
    function getActivationPrice(
        uint256 tokenId,
        uint8 segmentsToOpen,
        bool discounted
    ) external view returns (uint256);

    /// @notice              View method to get amount of liquidity to be provided for lock in order to
    ///                      complete last segment and make gNFT eligible for reward distribution in Treasury
    /// @param market        Tonpound Comptroller market (cToken) to be locked
    /// @param tokenType     Type of token to quote lock for
    /// @return              Amount of specified market tokens to be provided for lock
    function quoteLiquidityForLock(
        address market,
        IgNFT.TokenType tokenType
    ) external view returns (uint256);

    /// @notice              Minting new gNFT token with zero active segments and no voting power
    ///                      Minter must have total assets in Tonpound protocol over the threshold nominated in USD
    /// @param markets       User provided markets of Tonpound Comptroller to be checked for liquidity
    function mint(address[] memory markets) external;

    /// @notice              Minting new gNFT token of given type with zero active segments and no voting power
    ///                      Minter must have assets in given markets of Tonpound protocol over the threshold in USD
    ///                      Minter must own number of fully activated lower tier gNFTs to mint Emerald or Diamond
    /// @param markets       User provided markets of Tonpound Comptroller to be checked for liquidity
    /// @param tokenType     Token type to mint: Topaz, Emerald, or Diamond
    /// @param proofIds      List of tokenIds to be checked for ownership, activation, and type
    function mint(
        address[] memory markets,
        IgNFT.TokenType tokenType,
        uint256[] calldata proofIds
    ) external;

    /// @notice              Activating number of segments of given gNFT token
    ///                      Caller must be the owner, token may be completed with this function if
    ///                      caller provides enough liquidity for lock in specified Tonpound 'market'
    /// @param tokenId       tokenId to be activated for number of segments
    /// @param segments      Number of segments to be activated, must not exceed available segments of tokenId
    /// @param market        Optional address of Tonpound market to lock liquidity in order to complete gNFT
    function activateSegments(uint256 tokenId, uint8 segments, address market) external;

    /// @notice              Activating 1 segment of given gNFT token
    ///                      Caller must provide valid Merkle proof, token may be completed with this function if
    ///                      'account' provides enough liquidity for lock in specified Tonpound 'market'
    /// @param tokenId       tokenId to be activated for a single segment
    /// @param account       Address of whitelisted account, which is included in leaf of Merkle tree
    /// @param nonce         Nonce parameter included in leaf of Merkle tree
    /// @param proof         bytes32[] array of Merkle tree proof for whitelisted account
    /// @param market        Optional address of Tonpound market to lock liquidity in order to complete gNFT
    function activateSegmentWithProof(
        uint256 tokenId,
        address account,
        uint256 nonce,
        bytes32[] memory proof,
        address market
    ) external;

    /// @notice              Unlocking liquidity of a fully activated gNFT
    ///                      Caller must be the owner. If function is called before start of reward claiming,
    ///                      the given tokenId is de-registered in Treasury contract and stops acquiring rewards
    ///                      Any rewards acquired before unlocking will be available once claiming starts
    /// @param tokenId       tokenId to unlock liquidity for
    function unlockLiquidity(uint256 tokenId) external;

    /// @notice              Locking liquidity of a fully activated gNFT (reverting result of unlockLiquidity())
    ///                      Caller must be the owner. If function is called before start of reward claiming,
    ///                      the given tokenId is registered in Treasury contract and starts acquiring rewards
    ///                      Any rewards acquired before remains accounted and will be available once claiming starts
    /// @param tokenId       tokenId to lock liquidity for
    /// @param market        Address of Tonpound market to lock liquidity in
    function lockLiquidity(uint256 tokenId, address market) external;

    /// @notice             Updating Merkle root for whitelisting airdropped accounts
    ///                     Restricted to MANAGER_ROLE bearers only
    /// @param root         New root of Merkle tree of whitelisted addresses
    function setMerkleRoot(bytes32 root) external;
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound TPI token
/// @notice Extension of IERC20 standard interface from OpenZeppelin
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20)
interface ITPIToken is IERC20Upgradeable {
    /// @notice View function to get current active circulating supply,
    ///         used to calculate price of gNFT segment activation
    /// @return Total supply without specific TPI storing address, e.g. vesting
    function getCirculatingSupply() external view returns (uint256);

    /// @notice         Function to be used for gNFT segment activation
    /// @param account  Address, whose token to be burned
    /// @param amount   Amount to be burned
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

import "./IComptroller.sol";
import "./IgNFT.sol";
import "./IAuth.sol";

pragma solidity ^0.8.4;

/// @title  Interface for Tonpound Treasury contract, which is a part of gNFT token
/// @notice Authorization model is based on AccessControl and Pausable contracts from OpenZeppelin:
///         (https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl) and
///         (https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
///         Blacklisting implemented with BLACKLISTED_ROLE, managed by MANAGER_ROLE
interface ITreasury {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason claiming rewards before start of claiming period
    error ClaimingNotStarted();

    /// @notice Revert reason claiming unregistered reward token
    error InvalidRewardToken();

    /// @notice Revert reason for distributing rewards in unsupported reward token
    error InvalidMarket();

    /// @notice Revert reason for setting too high parameter value
    error InvalidParameter();

    /// @notice Revert reason for claiming reward for not-owned gNFT token
    error InvalidTokenOwnership();

    /// @notice Revert reason for accessing protected functions during pause
    error Paused();

    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice Emitted in governance function when reserveBPS variable is updated
    event ReserveFactorUpdated(uint256 oldValue, uint256 newValue);

    /// @notice Emitted in governance function when reserveFund variable is updated
    event ReserveFundUpdated(address oldValue, address newValue);

    /// @notice             View method to read all supported reward tokens
    /// @return             Array of addresses of registered reward tokens
    function getRewardTokens() external view returns (address[] memory);

    /// @notice             View method to read number of supported reward tokens
    /// @return             Number of registered reward tokens
    function getRewardTokensLength() external view returns (uint256);

    /// @notice             View method to read a single reward token address
    /// @param index        Index of reward token in array to return
    /// @return             Address of reward token at given index in array
    function getRewardTokensAtIndex(uint256 index) external view returns (address);

    /// @notice             View method to read 'lastClaimForTokenId' mapping
    ///                     storing 'rewardPerShare' parameter for 'tokenId'
    ///                     from time of registration or last claiming event
    /// @param rewardToken  Address of reward token to read mapping for
    /// @param tokenId      gNFT tokenId to read mapping for
    /// @return             Stored value of 'lastClaimForTokenId[rewardToken][tokenId]',
    ///                     last claim value of reward per share multiplied by REWARD_PER_SHARE_MULTIPLIER = 1e12
    function lastClaimForTokenId(
        address rewardToken,
        uint256 tokenId
    ) external view returns (uint256);

    /// @notice             View method to get pending rewards for given
    ///                     reward token and gNFT token, contains fixed part for
    ///                     de-registered tokens and calculated part of distributed rewards
    /// @param rewardToken  Address of reward token to calculate pending rewards
    /// @param tokenId      gNFT tokenId to calculate pending rewards for
    /// @return             Value of rewards in rewardToken that would be claimed if claim is available
    function pendingReward(address rewardToken, uint256 tokenId) external view returns (uint256);

    /// @notice             View method to read 'registeredTokenIds' mapping of
    ///                     tracked registered gNFT tokens
    /// @param tokenId      tokenId of gNFT token to read
    /// @return             Stored bool value of 'registeredTokenIds[tokenId]', true if registered
    function registeredTokenIds(uint256 tokenId) external view returns (bool);

    /// @notice             View method to read 'rewardPerShare' mapping of
    ///                     tracked balances of Treasury contract to properly distribute rewards
    /// @param rewardToken  Address of reward token to read mapping for
    /// @return             Stored value of 'rewardPerShare[rewardToken]',
    ///                     reward per share multiplied by REWARD_PER_SHARE_MULTIPLIER = 1e12
    function rewardPerShare(address rewardToken) external view returns (uint256);

    /// @notice             View method to read 'rewardBalance' mapping of distributed rewards
    ///                     in specified rewardToken stored to properly account fresh rewards
    /// @param rewardToken  Address of reward token to read mapping for
    /// @return             Stored value of 'rewardBalance[rewardToken]'
    function rewardBalance(address rewardToken) external view returns (uint256);

    /// @notice             View method to get the remaining time until start of claiming period
    /// @return             Seconds until claiming is available, zero if claiming has started
    function rewardsClaimRemaining() external view returns (uint256);

    /// @notice             View method to read Tonpound Comptroller address
    /// @return             Address of Tonpound Comptroller contract
    function TONPOUND_COMPTROLLER() external view returns (IComptroller);

    /// @notice             View method to read total weight of registered gNFT tokens,
    ///                     eligible for rewards distribution
    /// @return             Stored value of 'totalRegisteredWeight'
    function totalRegisteredWeight() external view returns (uint256);

    /// @notice             Register and distribute incoming rewards in form of all tokens
    ///                     supported by the Tonpound Comptroller contract
    ///                     Rewards must be re-distributed if there's no users to receive at the moment
    function distributeRewards() external;

    /// @notice             Register and distribute incoming rewards in form of underlying of 'market'
    ///                     Market address must be listed in the Tonpound Comptroller
    ///                     Rewards must be re-distributed if there's no users to receive at the moment
    /// @param market       Address of market cToken to try to distribute
    function distributeReward(address market) external;

    /// @notice             Claim all supported pending rewards for given gNFT token
    ///                     Claimable only after rewardsClaimRemaining() == 0 and
    ///                     only by the owner of given tokenId
    /// @param tokenId      gNFT tokenId to claim rewards for
    function claimRewards(uint256 tokenId) external;

    /// @notice             Claim pending rewards for given gNFT token in form of single 'rewardToken'
    ///                     Claimable only after rewardsClaimRemaining() == 0 and
    ///                     only by the owner of given tokenId
    /// @param tokenId      gNFT tokenId to claim rewards for
    /// @param rewardToken  Address of reward token to claim rewards in
    function claimReward(uint256 tokenId, address rewardToken) external;

    /// @notice             Register or de-register tokenId for rewards distribution
    ///                     De-registering saves acquired rewards in fixed part for claiming when available
    ///                     Restricted for gNFT contract only
    /// @param tokenId      gNFT tokenId to update registration status for
    /// @param state        New boolean registration status
    function registerTokenId(uint256 tokenId, bool state) external;

    /// @notice             Updating reserveBPS factor for reserve fund part of rewards
    /// @param newFactor    New value to be less than 5000
    function setReserveFactor(uint256 newFactor) external;

    /// @notice             Updating reserve fund address
    /// @param newFund      New address to receive future reserve rewards
    function setReserveFund(address newFund) external;

    struct RewardInfo {
        address market;
        uint256 amount;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./ISegmentManagement.sol";

/// @title  Interface for Tonpound gNFT Vault contract, which is a part of gNFT token
/// @notice VaultFactory is called by VaultFactory contract to store underlying Tonpound liquidity tokens
///         Vault contract is based on ERC4626 Vault from OpenZeppelin's library:
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC4626)
interface IVault {
    /// @notice         Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice         Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice         Emitted when problem in TPI calculation arises
    event NotEnoughTPI();

    /// @notice         Emitted with each deposit act
    /// @param tokenId  Deposit is linked to gNFT tokenId
    /// @param assets   Tonpound market cToken amount being deposited
    /// @param shares   Equivalent amount of shares calculated at the moment
    event Deposited(uint256 tokenId, uint256 assets, uint256 shares);

    /// @notice         Emitted with each withdraw act
    /// @param tokenId  Withdraw is linked to gNFT tokenId
    /// @param shares   Amount of shares to be withdrawn
    /// @param assets   Market cToken amount calculated at the moment
    event Withdrawn(uint256 tokenId, uint256 shares, uint256 assets);

    /// @notice         Method to be called by VaultFactory when locking is requested by gNFT
    /// @param tokenId  gNFT tokenId to deposit for
    /// @param assets   Amount of Tonpound market tokens to be deposited
    /// @return shares  Amount of shares acquired from 'assets' amount
    function deposit(uint256 tokenId, uint256 assets) external returns (uint256 shares);

    /// @notice         Method to be called by VaultFactory when unlocking is requested by gNFT
    /// @param tokenId  gNFT tokenId to withdraw for
    /// @param shares   Amount of Vault shares to be redeemed
    /// @return assets  Amount of assets acquired from 'shares' amount
    function withdraw(
        uint256 tokenId,
        uint256 shares,
        address receiver
    ) external returns (uint256 assets);

    /// @notice         View method to get shares from assets
    /// @param assets   Amount of underlying asset tokens
    /// @return shares  Amount of shares to be acquired from 'assets'
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice         View method to get assets from shares
    /// @param shares   Amount of Vault shares
    /// @return assets  Amount of underlying assets to be acquired from 'shares'
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice         View method to get total stored assets
    /// @return         Underlying assets balance of Vault contract
    function totalAssets() external view returns (uint256);

    /// @notice         View method to get total shares
    /// @return         Total amount of minted Vault shares
    function totalShares() external view returns (uint256);

    /// @notice         View method to get underlying asset address
    /// @return         Address of Tonpound market used as storing asset
    function market() external view returns (IERC20Upgradeable);

    /// @notice         View method to get Tonpound gNFT SegmentManagement contract
    /// @return         Address of SegmentManagement contract, which has access to restricted functions
    function factory() external view returns (ISegmentManagement);

    /// @notice         View method to get TPI reward per share
    /// @return         Stored accumulated TPI reward per share
    function accRewardPerShare() external view returns (uint256);

    /// @notice         View method to get stored TPI rewards
    /// @return         Total amount of TPI rewards stored with the last update
    function totalTPIStored() external view returns (uint256);

    /// @notice         View method to get already paid TPI
    /// @return         Total amount of TPI rewards paid to unlocked gNFTs
    function rewardPaid() external view returns (uint256);

    /// @notice         View method to get Vault shares by gNFT tokenID
    /// @return         Amount of shares in the Vault
    function sharesByID(uint256) external view returns (uint256);

    /// @notice         View method to get reward debt by gNFT tokenID,
    ///                 i.e. accRewardPerShare at the moment of balance update
    ///                 Can be negative, so rewards are claimable even after shares withdrawal
    /// @return         rewardDebt = SUM_OF (sharesDiff * accRewardPerShare)_i
    function rewardDebtByID(uint256) external view returns (int256);

    /// @notice         Restricted initializer to be called right after Vault creation
    /// @param market   Address of Tonpound market used as storing asset
    function initialize(address market) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./IgNFT.sol";
import "./ITPIToken.sol";
import "./IVault.sol";

/// @title  Interface for VaultFactory contract, which is a part of SegmentManagement of Tonpound gNFT token
/// @notice VaultFactory is a factory contract to store liquidity tokens in individual Vaults,
///         since Tonpound market tokens are rebasing ERC20 and TPI rewards are accrued per holder
///         Based on EIP-1167 Minimal Proxy implementation from OpenZeppelin: 
///         (https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones)
interface IVaultFactory {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason for trying to lock not supported Tonpound market
    error NotSupported();

    /// @notice Revert reason for updating implementation for address without bytecode
    error WrongImplementation();

    /// @notice Emitted with a creation of a new Vault contract to store Tonpound liquidity tokens
    /// @param market         Address of Tonpound liquidity token
    /// @param instance       Address of Vault contract to store 'market' tokens
    /// @param implementation Address of used implementation of Vault contract
    event MarketAdded(address market, address instance, address implementation);

    /// @notice Emitted when gNFT contract requests a lock of liquidity
    /// @param tokenId        gNFT tokenId to lock for
    /// @param market         Address of Tonpound market locked
    /// @param assets         Amount of Tonpound market tokens locked
    /// @param shares         Amount of shares acquired in corresponding Vault
    event Locked(uint256 indexed tokenId, address market, uint256 assets, uint256 shares);

    /// @notice Emitted when gNFT contract requests an unlock of liquidity
    /// @param tokenId        gNFT tokenId to unlock for
    /// @param market         Address of Tonpound market unlocked
    /// @param assets         Amount of Tonpound market tokens unlocked
    /// @param shares         Amount of Vault shares unlocked
    /// @param receiver       Address of receiver of unlocked liquidity
    event Unlocked(
        uint256 indexed tokenId,
        address market,
        uint256 assets,
        uint256 shares,
        address indexed receiver
    );

    /// @notice         View method to read Vault by Tonpound market
    /// @param market   Address of Tonpound market to be get Vault for
    /// @return         Vault address storing 'market' tokens (zero if not created yet)
    function vaultsByMarket(address market) external view returns (IVault);

    /// @notice         View method to get all supported markets
    /// @return         Array of supported markets, which have deployed Vaults
    function allMarkets() external view returns (address[] memory);

    /// @notice         View method to get supported market at index
    /// @return         Address of supported market at index in all markets array
    function marketAt(uint256 index) external view returns (address);

    /// @notice         View method to get number of supported numbers
    /// @return         Length of supported markets array
    function marketsLength() external view returns (uint256);

    /// @notice         View method to check if market is supported
    /// @return         True if market is supported and has Vault, False - if not
    function marketSupported(address market) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./Auth.sol";
import "./Constants.sol";
import "./VaultFactory.sol";
import "./interfaces/ISegmentManagement.sol";

pragma solidity 0.8.17;

contract SegmentManagement is
    Auth,
    VaultFactory,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    ISegmentManagement
{
    IgNFT public immutable gNFT;
    IComptroller public immutable TONPOUND_COMPTROLLER;

    uint256 private _totalInactiveSegments;
    bytes32 private _airdropMerkleRoot;

    mapping(bytes32 => bool) private _discountUsed;

    function initialize(address vault_, address manager_, address pauser_) external initializer {
        if (vault_ == address(0)) revert ZeroAddress();
        __Auth_init(manager_, pauser_);
        __VaultFactory_init(vault_);
        __UUPSUpgradeable_init();
    }

    function mint(address[] memory markets) external whenNotPaused nonReentrant {
        _checkLiquidity(markets, IgNFT.TokenType.Topaz);
        _mintInternal(msg.sender, IgNFT.TokenType.Topaz, 0, 0);
    }

    function mint(
        address[] memory markets,
        IgNFT.TokenType tokenType,
        uint256[] calldata proofIds
    ) external whenNotPaused nonReentrant {
        _checkTokenType(tokenType, proofIds);
        _checkLiquidity(markets, tokenType);
        _mintInternal(msg.sender, tokenType, 0, 0);
    }

    function _mintInternal(
        address to,
        IgNFT.TokenType tokenType,
        uint48 completionTimestamp,
        uint8 segments
    ) internal {
        IgNFT.TokenData memory tokenData = IgNFT.TokenData({
            slot0: IgNFT.Slot0({
                tokenType: tokenType,
                activeSegment: segments,
                voteWeight: uint8(_getTypeParameter(tokenType, Constants.ParameterType.VoteWeight)),
                rewardWeight: uint8(
                    _getTypeParameter(tokenType, Constants.ParameterType.RewardWeight)
                ),
                usedForMint: false,
                completionTimestamp: completionTimestamp,
                lockedMarket: address(0)
            }),
            slot1: IgNFT.Slot1({lockedVaultShares: 0})
        });
        _totalInactiveSegments += Constants.SEGMENTS_NUMBER - segments;
        gNFT.mint(to, tokenData);
    }

    function _checkTokenType(IgNFT.TokenType tokenType, uint256[] calldata proofIds) internal {
        IgNFT.Slot0 memory data0;
        uint256 numTopaz;
        uint256 numEmerald;
        uint256 numDiamond;
        uint256 len = proofIds.length;
        uint256 proofId;
        uint256 requiredTopazes = _getTypeParameter(
            tokenType,
            Constants.ParameterType.RequiredTopazes
        );
        uint256 requiredEmeralds = _getTypeParameter(
            tokenType,
            Constants.ParameterType.RequiredEmeralds
        );
        uint256 requiredDiamonds = _getTypeParameter(
            tokenType,
            Constants.ParameterType.RequiredDiamonds
        );

        for (uint256 i; i < len; ) {
            proofId = proofIds[i];
            _requireOwnership(proofId);
            data0 = _getSlot0(proofId);
            if (data0.activeSegment != Constants.SEGMENTS_NUMBER) {
                revert InvalidSegmentsNumber();
            }
            unchecked {
                if (!data0.usedForMint) {
                    bool used = false;
                    if (data0.tokenType == IgNFT.TokenType.Topaz && numTopaz < requiredTopazes) {
                        numTopaz++;
                        used = true;
                    } else if (
                        data0.tokenType == IgNFT.TokenType.Emerald && numEmerald < requiredEmeralds
                    ) {
                        numEmerald++;
                        used = true;
                    } else if (numDiamond < requiredDiamonds) {
                        numDiamond++;
                        used = true;
                    }
                    if (used) {
                        data0.usedForMint = true;
                        _updateSlot0(proofId, data0);
                    }
                }
                i++;
            }
        }
        if (
            numTopaz < requiredTopazes ||
            numEmerald < requiredEmeralds ||
            numDiamond < requiredDiamonds
        ) revert MintingRequirementsNotMet();
    }

    function _checkLiquidity(address[] memory markets, IgNFT.TokenType tokenType) internal {
        IOracle oracle = _getOracle();
        IComptroller comptroller = TONPOUND_COMPTROLLER;
        uint256 liquidityValue = _getTypeParameter(
            tokenType,
            Constants.ParameterType.MintingLiquidity
        );
        uint256 len = markets.length;
        uint256 totalValue;
        address market;
        for (uint256 i; i < len; ) {
            market = markets[i];
            _checkMarketListed(market, comptroller);
            totalValue += _quoteLiquiditySingle(
                market,
                oracle,
                ICToken(market).balanceOf(msg.sender),
                false
            );
            if (totalValue >= liquidityValue) {
                return;
            }
            unchecked {
                i++;
            }
        }
        revert FailedLiquidityCheck();
    }

    function _checkMarketListed(address market, IComptroller comptroller) internal view {
        if (!comptroller.markets(market).isListed) {
            revert InvalidMarket();
        }
    }

    function _quoteLiquiditySingle(
        address market,
        IOracle oracle,
        uint256 amount,
        bool reverse
    ) internal returns (uint256) {
        uint256 eval = oracle.getEvaluation(market, amount, reverse);
        if (eval == 0) revert OracleFailed();
        return eval;
    }

    function getActivationPrice(
        uint256 tokenId,
        uint8 segmentsToOpen,
        bool discounted
    ) external view returns (uint256) {
        IgNFT.Slot0 memory data0 = _getSlot0(tokenId);
        if (Constants.SEGMENTS_NUMBER - data0.activeSegment < segmentsToOpen)
            revert InvalidSegmentsNumber();
        return _getActivationPrice(data0, segmentsToOpen, _totalInactiveSegments, discounted);
    }

    function _getActivationPrice(
        IgNFT.Slot0 memory data0,
        uint8 numberOfSegments,
        uint256 totalInactiveSegments,
        bool discounted
    ) internal view returns (uint256) {
        uint256 avgPrice;
        if (totalInactiveSegments > 0) {
            try TPI().getCirculatingSupply() returns (uint256 supply) {
                avgPrice = supply / totalInactiveSegments;
            } catch {}
        }
        avgPrice = MathUpgradeable.max(avgPrice, Constants.ACTIVATION_MIN_PRICE) * numberOfSegments;
        if (discounted) {
            avgPrice =
                (avgPrice * Constants.AIRDROP_DISCOUNT_NOMINATOR) /
                Constants.AIRDROP_DISCOUNT_DENOMINATOR;
        }
        uint256 typeNominator = _getTypeParameter(
            data0.tokenType,
            Constants.ParameterType.ActivationNominator
        );
        return (avgPrice * typeNominator) / Constants.ACTIVATION_DENOMINATOR;
    }

    function activateSegments(
        uint256 tokenId,
        uint8 segments,
        address market
    ) external whenNotPaused validUser(msg.sender) nonReentrant {
        _requireOwnership(tokenId);
        _activateSegmentsInternal(tokenId, segments, market, msg.sender, false);
    }

    function activateSegmentWithProof(
        uint256 tokenId,
        address account,
        uint256 nonce,
        bytes32[] memory proof,
        address market
    ) external whenNotPaused validUser(account) nonReentrant {
        (bytes32 leaf, bytes32 root) = _validateProof(account, nonce, proof);
        _activateSegmentsInternal(tokenId, 1, market, account, true);
        emit Discounted(leaf, root);
    }

    function _activateSegmentsInternal(
        uint256 tokenId,
        uint8 segments,
        address market,
        address account,
        bool discounted
    ) internal {
        IgNFT.Slot0 memory data0 = _getSlot0(tokenId);
        uint8 availableSegments = Constants.SEGMENTS_NUMBER - data0.activeSegment;
        if (availableSegments == 0) {
            revert AlreadyFullyActivated();
        } else if (segments > availableSegments) {
            revert ExceedingMaxSegments();
        } else if (segments == availableSegments) {
            data0 = _completeSegments(tokenId, data0, market, account);
        }
        uint256 totalInactive = _totalInactiveSegments;
        uint256 activationPrice = _getActivationPrice(data0, segments, totalInactive, discounted);
        unchecked {
            data0.activeSegment += segments;
            _totalInactiveSegments = totalInactive - segments;
        }
        _updateSlot0(tokenId, data0);
        TPI().burnFrom(msg.sender, activationPrice);
        emit ActivatedSegments(tokenId, segments);
    }

    function _validateProof(
        address account,
        uint256 nonce,
        bytes32[] memory proof
    ) internal returns (bytes32, bytes32) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, nonce))));
        if (_discountUsed[leaf]) revert DiscountUsed();
        _discountUsed[leaf] = true;
        bytes32 root = _airdropMerkleRoot;
        if (!MerkleProofUpgradeable.verify(proof, root, leaf)) revert InvalidProof();
        return (leaf, root);
    }

    function _completeSegments(
        uint256 tokenId,
        IgNFT.Slot0 memory data0,
        address market,
        address account
    ) internal returns (IgNFT.Slot0 memory) {
        if (!_treasuryReleased()) {
            if (market == address(0)) revert MarketForLockNotSpecified();
            uint256 liquidity = _getTypeParameter(
                data0.tokenType,
                Constants.ParameterType.RewardsLiquidity
            );
            IgNFT.Slot1 memory data1;
            (data0, data1) = _lockLiquidityInternal(tokenId, data0, market, account, liquidity);
            _updateSlot1(tokenId, data1);
        }
        _getTreasury().registerTokenId(tokenId, true);
        data0.completionTimestamp = uint48(block.timestamp);
        emit TokenCompleted(tokenId, msg.sender);
        return data0;
    }

    function _treasuryReleased() internal view returns (bool) {
        return _getTreasury().rewardsClaimRemaining() == 0;
    }

    function _lockLiquidityInternal(
        uint256 tokenId,
        IgNFT.Slot0 memory data0,
        address market,
        address account,
        uint256 value
    ) internal returns (IgNFT.Slot0 memory, IgNFT.Slot1 memory) {
        uint256 amountToLock = _quoteLiquiditySingle(market, _getOracle(), value, true);
        uint256 vaultShares = _vaultLock(tokenId, market, amountToLock, account);
        data0.lockedMarket = market;
        IgNFT.Slot1 memory data1 = _getSlot1(tokenId);
        data1.lockedVaultShares = vaultShares;
        _getTreasury().registerTokenId(tokenId, true);
        return (data0, data1);
    }

    function lockLiquidity(uint256 tokenId, address market) external whenNotPaused nonReentrant {
        _requireOwnership(tokenId);
        if (!_treasuryReleased()) {
            IgNFT.TokenData memory data = _getTokenData(tokenId);
            if (data.slot1.lockedVaultShares > 0) revert TokenAlreadyLocked();
            if (market == address(0)) revert MarketForLockNotSpecified();
            uint256 liquidity = _getTypeParameter(
                data.slot0.tokenType,
                Constants.ParameterType.RewardsLiquidity
            );
            _lockLiquidityInternal(tokenId, data.slot0, market, msg.sender, liquidity);
        }
        _getTreasury().registerTokenId(tokenId, true);
    }

    function unlockLiquidity(uint256 tokenId) external whenNotPaused nonReentrant {
        _requireOwnership(tokenId);
        ITreasury treasury = _getTreasury();
        if (treasury.rewardsClaimRemaining() > 0) {
            treasury.registerTokenId(tokenId, false);
        }
        _unlockLiquidityInternal(tokenId, msg.sender);
    }

    function _unlockLiquidityInternal(uint256 tokenId, address account) internal {
        IgNFT.Slot0 memory data0 = _getSlot0(tokenId);
        IgNFT.Slot1 memory data1 = _getSlot1(tokenId);
        _vaultUnlock(tokenId, data0.lockedMarket, data1.lockedVaultShares, account);
        data0.lockedMarket = address(0);
        data1.lockedVaultShares = 0;
        _updateSlot0(tokenId, data0);
        _updateSlot1(tokenId, data1);
    }

    function quoteLiquidityForLock(
        address market,
        IgNFT.TokenType tokenType
    ) external view returns (uint256) {
        uint256 liquidity = _getTypeParameter(tokenType, Constants.ParameterType.RewardsLiquidity);
        return _getOracle().getEvaluationStored(market, liquidity, true);
    }

    function _getTokenData(uint256 tokenId) internal view returns (IgNFT.TokenData memory) {
        return gNFT.getTokenData(tokenId);
    }

    function _getSlot0(uint256 tokenId) internal view returns (IgNFT.Slot0 memory) {
        return gNFT.getTokenSlot0(tokenId);
    }

    function _getSlot1(uint256 tokenId) internal view returns (IgNFT.Slot1 memory) {
        return gNFT.getTokenSlot1(tokenId);
    }

    function _updateSlot0(uint256 tokenId, IgNFT.Slot0 memory data) internal {
        gNFT.updateTokenDataSlot0(tokenId, data);
    }

    function _updateSlot1(uint256 tokenId, IgNFT.Slot1 memory data) internal {
        gNFT.updateTokenDataSlot1(tokenId, data);
    }

    function _requireOwnership(uint256 tokenId) internal view {
        if (IERC721Upgradeable(address(gNFT)).ownerOf(tokenId) != msg.sender)
            revert InvalidTokenOwnership(tokenId);
    }

    function _getTypeParameter(
        IgNFT.TokenType col,
        Constants.ParameterType row
    ) internal pure returns (uint256) {
        uint256 param = Constants.TYPE_PARAMETERS(uint256(col), uint256(row));
        if (
            row == Constants.ParameterType.RewardsLiquidity ||
            row == Constants.ParameterType.MintingLiquidity
        ) {
            unchecked {
                param *= Constants.EXP_LIQUIDITY;
            }
        }
        return param;
    }

    function _getOracle() internal view returns (IOracle) {
        return IOracle(TONPOUND_COMPTROLLER.oracle());
    }

    function _getTreasury() internal view returns (ITreasury) {
        return ITreasury(TONPOUND_COMPTROLLER.treasury());
    }

    function TPI() public view override returns (ITPIToken) {
        return ITPIToken(TONPOUND_COMPTROLLER.getCompAddress());
    }

    function setMerkleRoot(bytes32 root) external onlyRole(MANAGER_ROLE) {
        emit AirdropMerkleRootChanged(_airdropMerkleRoot, root);
        _airdropMerkleRoot = root;
    }

    function updateVaultImplementation(
        address implementation
    ) external onlyRole(Constants.DEFAULT_ADMIN_ROLE) {
        _updateImplementation(implementation);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(Constants.DEFAULT_ADMIN_ROLE) {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address gnft_, address comptroller_) VaultFactory() {
        if (gnft_ == address(0) || comptroller_ == address(0))
            revert ZeroAddress();
        TONPOUND_COMPTROLLER = IComptroller(comptroller_);
        gNFT = IgNFT(gnft_);
        _disableInitializers();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Constants.sol";
import "./interfaces/IVaultFactory.sol";

abstract contract VaultFactory is Initializable, IVaultFactory {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    IVault public vaultImplementation;

    EnumerableSetUpgradeable.AddressSet private _markets;
    mapping(address => IVault) public vaultsByMarket;

    function __VaultFactory_init(address vault_) internal onlyInitializing {
        vaultImplementation = IVault(vault_);
    }

    function _getVault(address market) internal returns (IVault) {
        IVault vault;
        if (market == _getTPIAddress()) revert NotSupported();
        if (_markets.add(market)) {
            address implementation = address(vaultImplementation);
            vault = IVault(ClonesUpgradeable.clone(implementation));
            vault.initialize(market);
            vaultsByMarket[market] = vault;

            emit MarketAdded(market, address(vault), implementation);
        } else {
            vault = vaultsByMarket[market];
        }
        return vault;
    }

    function _vaultLock(
        uint256 tokenId,
        address market,
        uint256 assets,
        address sender
    ) internal returns (uint256) {
        IVault vault = _getVault(market);
        uint256 shares = vault.deposit(tokenId, assets);
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(market),
            sender,
            address(vault),
            assets
        );

        emit Locked(tokenId, market, assets, shares);
        return shares;
    }

    function _vaultUnlock(
        uint256 tokenId,
        address market,
        uint256 shares,
        address receiver
    ) internal returns (uint256) {
        IVault vault = _getVault(market);
        uint256 assets = vault.withdraw(tokenId, shares, receiver);

        emit Unlocked(tokenId, market, assets, shares, receiver);
        return assets;
    }

    function allMarkets() external view returns (address[] memory) {
        return _markets.values();
    }

    function marketAt(uint256 index) external view returns (address) {
        return _markets.at(index);
    }

    function marketsLength() external view returns (uint256) {
        return _markets.length();
    }

    function marketSupported(address market) external view returns (bool) {
        return _markets.contains(market);
    }

    function _getTPIAddress() internal view virtual returns (address) {}

    function _updateImplementation(address implementation) internal {
        if (!AddressUpgradeable.isContract(implementation)) revert WrongImplementation();
        vaultImplementation = IVault(implementation);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}