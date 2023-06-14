// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "../api/errors/IUUPSUpgradeableErrors.sol";
import "../generated/impl/BaseAspenCoreRegistryV1.sol";
import "./config/TieredPricingUpgradeable.sol";
import "./config/OperatorFiltererConfig.sol";
import "./CoreRegistry.sol";

contract AspenCoreRegistry is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    CoreRegistry,
    TieredPricingUpgradeable,
    OperatorFiltererConfig,
    BaseAspenCoreRegistryV1
{
    using ERC165CheckerUpgradeable for address;

    function initialize(address _platformFeeReceiver) public virtual initializer {
        __TieredPricingUpgradeable_init(_platformFeeReceiver);
        super._addOperatorFilterer(
            IOperatorFiltererDataTypesV0.OperatorFilterer(
                keccak256(abi.encodePacked("NO_OPERATOR")),
                "No Operator",
                address(0),
                address(0)
            )
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseAspenCoreRegistryV1, AccessControlUpgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            BaseAspenCoreRegistryV1.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /// ===================================
    /// ========== Tiered Pricing =========
    /// ===================================
    function setPlatformFeeReceiver(address _platformFeeReceiver) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPlatformFeeReceiver(_platformFeeReceiver);
    }

    function setDefaultTier(bytes32 _namespace, bytes32 _tierId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultTier(_namespace, _tierId);
    }

    function addTier(bytes32 _namespace, ITieredPricingDataTypesV0.Tier calldata _tierDetails)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _addTier(_namespace, _tierDetails);
    }

    function updateTier(
        bytes32 _namespace,
        bytes32 _tierId,
        ITieredPricingDataTypesV0.Tier calldata _tierDetails
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTier(_namespace, _tierId, _tierDetails);
    }

    function removeTier(bytes32 _namespace, bytes32 _tierId) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeTier(_namespace, _tierId);
    }

    function addAddressToTier(
        bytes32 _namespace,
        address _account,
        bytes32 _tierId
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _addAddressToTier(_namespace, _account, _tierId);
    }

    function removeAddressFromTier(bytes32 _namespace, address _account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeAddressFromTier(_namespace, _account);
    }

    /// ========================================
    /// ========== Operator Filterers ==========
    /// ========================================
    function addOperatorFilterer(IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer)
        public
        override(IOperatorFiltererConfigV0, OperatorFiltererConfig)
        isValidOperatorConfig(_newOperatorFilterer)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._addOperatorFilterer(_newOperatorFilterer);
    }

    /// ========================================
    /// ============ Core Registry =============
    /// ========================================
    function addContract(bytes32 _nameHash, address _addr)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool result)
    {
        return super.addContract(_nameHash, _addr);
    }

    function addContractForString(string calldata _name, address _addr)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool result)
    {
        return super.addContractForString(_name, _addr);
    }

    function setConfigContract(address _configContract, string calldata _version)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super.setConfigContract(_configContract, _version);
    }

    function setDeployerContract(address _deployerContract, string calldata _version)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super.setDeployerContract(_deployerContract, _version);
    }

    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure virtual override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../config/IPlatformFeeConfig.sol";
import "../config/IOperatorFilterersConfig.sol";
import "../config/ITieredPricing.sol";

interface IGlobalConfigV0 is IOperatorFiltererConfigV0, IPlatformFeeConfigV0 {}

interface IGlobalConfigV1 is IOperatorFiltererConfigV0, ITieredPricingV0 {}

interface IGlobalConfigV2 is ITieredPricingV1 {}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./types/OperatorFiltererDataTypes.sol";

interface IOperatorFiltererConfigV0 {
    event OperatorFiltererAdded(
        bytes32 operatorFiltererId,
        string name,
        address defaultSubscription,
        address operatorFilterRegistry
    );

    function getOperatorFiltererOrDie(bytes32 _operatorFiltererId)
        external
        view
        returns (IOperatorFiltererDataTypesV0.OperatorFilterer memory);

    function getOperatorFilterer(bytes32 _operatorFiltererId)
        external
        view
        returns (IOperatorFiltererDataTypesV0.OperatorFilterer memory);

    function getOperatorFiltererIds() external view returns (bytes32[] memory operatorFiltererIds);

    function addOperatorFilterer(IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IPlatformFeeConfigV0 {
    event PlatformFeesUpdated(address platformFeeReceiver, uint16 platformFeeBPS);

    function getPlatformFees() external view returns (address platformFeeReceiver, uint16 platformFeeBPS);

    function setPlatformFees(address _newPlatformFeeReceiver, uint16 _newPlatformFeeBPS) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./types/TieredPricingDataTypes.sol";

interface ITieredPricingEventsV0 {
    event PlatformFeeReceiverUpdated(address newPlatformFeeReceiver);

    event TierAdded(
        bytes32 indexed namespace,
        bytes32 indexed tierId,
        string indexed tierName,
        uint256 tierPrice,
        address tierCurrency,
        ITieredPricingDataTypesV0.FeeTypes feeType
    );
    event TierUpdated(
        bytes32 indexed namespace,
        bytes32 indexed tierId,
        string indexed tierName,
        uint256 tierPrice,
        address tierCurrency,
        ITieredPricingDataTypesV0.FeeTypes feeType
    );
    event TierRemoved(bytes32 indexed namespace, bytes32 indexed tierId);
    event AddressAddedToTier(bytes32 indexed namespace, address indexed account, bytes32 indexed tierId);
    event AddressRemovedFromTier(bytes32 indexed namespace, address indexed account, bytes32 indexed tierId);
}

interface ITieredPricingGettersV0 {
    function getTiersForNamespace(bytes32 _namespace)
        external
        view
        returns (bytes32[] memory tierIds, ITieredPricingDataTypesV0.Tier[] memory tiers);

    function getDefaultTierForNamespace(bytes32 _namespace)
        external
        view
        returns (bytes32 tierId, ITieredPricingDataTypesV0.Tier memory tier);

    function getDeploymentFee(address _account)
        external
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        );

    function getClaimFee(address _account) external view returns (address feeReceiver, uint256 price);

    function getCollectorFee(address _account)
        external
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        );

    function getFee(bytes32 _namespace, address _account)
        external
        view
        returns (
            address feeReceiver,
            uint256 price,
            ITieredPricingDataTypesV0.FeeTypes feeType,
            address currency
        );

    function getTierDetails(bytes32 _namespace, bytes32 _tierId)
        external
        view
        returns (ITieredPricingDataTypesV0.Tier memory tier);

    function getPlatformFeeReceiver() external view returns (address feeReceiver);
}

interface ITieredPricingV0 is ITieredPricingEventsV0, ITieredPricingGettersV0 {
    function setPlatformFeeReceiver(address _platformFeeReceiver) external;

    function addTier(bytes32 _namespace, ITieredPricingDataTypesV0.Tier calldata _tierDetails) external;

    function updateTier(
        bytes32 _namespace,
        bytes32 _tierId,
        ITieredPricingDataTypesV0.Tier calldata _tierDetails
    ) external;

    function removeTier(bytes32 _namespace, bytes32 _tierId) external;

    function addAddressToTier(
        bytes32 _namespace,
        address _account,
        bytes32 _tierId
    ) external;

    function removeAddressFromTier(bytes32 _namespace, address _account) external;
}

interface ITieredPricingEventsV1 {
    event DefaultTierUpdated(bytes32 indexed namespace, bytes32 indexed tierId);
}

interface ITieredPricingV1 is ITieredPricingEventsV1 {
    function setDefaultTier(bytes32 _namespace, bytes32 _tierId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IOperatorFiltererDataTypesV0 {
    struct OperatorFilterer {
        bytes32 operatorFiltererId;
        string name;
        address defaultSubscription;
        address operatorFilterRegistry;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ITieredPricingDataTypesV0 {
    enum FeeTypes {
        FlatFee,
        Percentage
    }

    struct Tier {
        string name;
        uint256 price;
        address currency;
        FeeTypes feeType;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRegistryErrorsV0 {
    error ContractNotFound();
    error ZeroAddressError();
    error FailedToSetCoreRegistry();
    error CoreRegistryInterfaceNotSupported();
    error AddressNotContract();
}

interface ICoreRegistryErrorsV0 {
    error FailedToSetCoreRegistry();
    error FailedToSetConfigContract();
    error FailedTosetDeployerContract();
}

interface IOperatorFiltererConfigErrorsV0 {
    error OperatorFiltererNotFound();
    error InvalidOperatorFiltererDetails();
}

interface ICoreRegistryEnabledErrorsV0 {
    error CoreRegistryNotSet();
}

interface ITieredPricingErrorsV0 {
    error PlatformFeeReceiverAlreadySet();
    error InvalidAccount();
    error TierNameAlreadyExist();
    error InvalidTierId();
    error InvalidFeeType();
    error SingleTieredNamespace();
    error InvalidPercentageFee();
    error AccountAlreadyOnTier();
    error AccountAlreadyOnDefaultTier();
    error InvalidTierName();
    error InvalidFeeTypeForDeploymentFees();
    error InvalidFeeTypeForClaimFees();
    error InvalidFeeTypeForCollectorFees();
    error InvalidCurrencyAddress();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IUUPSUpgradeableErrorsV0 {
    error IllegalVersionUpgrade(
        uint256 existingMajorVersion,
        uint256 existingMinorVersion,
        uint256 existingPatchVersion,
        uint256 newMajorVersion,
        uint256 newMinorVersion,
        uint256 newPatchVersion
    );

    error ImplementationNotVersioned(address implementation);
}

interface IUUPSUpgradeableErrorsV1 is IUUPSUpgradeableErrorsV0 {
    error BackwardsCompatibilityBroken(address implementation);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IAspenFeaturesV1 is IERC165Upgradeable {
    // Marker interface to make an ERC165 clash less likely
    function isIAspenFeaturesV1() external pure returns (bool);

    // List of codes for features this contract supports
    function supportedFeatureCodes() external pure returns (uint256[] memory codes);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICedarMinorVersionedV0 {
    function minorVersion() external view returns (uint256 minor, uint256 patch);
}

interface ICedarImplementationVersionedV0 {
    /// @dev Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function implementationVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );
}

interface ICedarImplementationVersionedV1 is ICedarImplementationVersionedV0 {
    /// @dev returns the name of the implementation interface such as IAspenERC721DropV3
    /// allows us to reliably emit the correct events
    function implementationInterfaceName() external view returns (string memory interfaceName);
}

interface ICedarImplementationVersionedV2 is ICedarImplementationVersionedV0 {
    /// @dev returns the name of the implementation interface such as impl/IAspenERC721Drop.sol:IAspenERC721DropV3
    function implementationInterfaceId() external view returns (string memory interfaceId);
}

interface ICedarVersionedV0 is ICedarImplementationVersionedV0, ICedarMinorVersionedV0, IERC165Upgradeable {}

interface ICedarVersionedV1 is ICedarImplementationVersionedV1, ICedarMinorVersionedV0, IERC165Upgradeable {}

interface ICedarVersionedV2 is ICedarImplementationVersionedV2, ICedarMinorVersionedV0, IERC165Upgradeable {}

interface IAspenVersionedV2 is IERC165Upgradeable {
    function minorVersion() external view returns (uint256 minor, uint256 patch);

    /// @dev Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function implementationVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    /// @dev returns the name of the implementation interface such as impl/IAspenERC721Drop.sol:IAspenERC721DropV3
    function implementationInterfaceId() external view returns (string memory interfaceId);
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.0;

import "../IAspenFeatures.sol";
import "../IAspenVersioned.sol";
import "../config/IGlobalConfig.sol";

interface IAspenCoreRegistryV1 is IAspenFeaturesV1, IAspenVersionedV2, IGlobalConfigV1, IGlobalConfigV2 {}

// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

import "../../api/config/ITieredPricing.sol";
import "../../api/errors/ICoreErrors.sol";

/// @title BaseTieredPricing
/// @notice Handles tha fees for the platform.
///         It allows the update and retrieval of platform feeBPS and receiver address
contract BaseTieredPricing is ITieredPricingEventsV0, ITieredPricingGettersV0, ITieredPricingEventsV1 {
    /// @dev Max basis points (bps) in Aspen platform.
    uint256 public constant MAX_BPS = 10_000;
    /// @dev Max percentage fee (bps) allowed
    uint256 public constant MAX_PERCENTAGE_FEE = 7500;
    /// @dev Receiver address for the platform fees
    address private __platformFeeReceiver;

    bytes32 private constant DEPLOYMENT_FEES_NAMESPACE = bytes32(abi.encodePacked("DEPLOYMENT_FEES"));
    bytes32 private constant CLAIM_FEES_NAMESPACE = bytes32(abi.encodePacked("CLAIM_FEES"));
    bytes32 private constant COLLECTOR_FEES_NAMESPACE = bytes32(abi.encodePacked("COLLECTOR_FEES"));

    /// @dev Namespace => Tier identifier
    mapping(bytes32 => bytes32[]) private _tierIds;
    /// @dev Namespace => Tier identifier => Tier price (BPS or Flat Amount)
    mapping(bytes32 => mapping(bytes32 => ITieredPricingDataTypesV0.Tier)) private _tiers;
    /// @dev Namespace => address => Tier identifier
    mapping(bytes32 => mapping(address => bytes32)) private _addressToTier;
    /// @dev Namespace => Tier identifier
    mapping(bytes32 => bytes32) private _defaultTier;

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================
    /// @dev Returns the platform fee receiver address
    function getPlatformFeeReceiver() public view returns (address) {
        return __platformFeeReceiver;
    }

    /// @dev Returns all the tiers for a namespace
    /// @param _namespace - namespace for which tiers are requested
    /// @return tierIds - an array with all the tierIds for a namespace
    /// @return tiers - an array with all the tier details for a namespace
    function getTiersForNamespace(bytes32 _namespace)
        public
        view
        returns (bytes32[] memory tierIds, ITieredPricingDataTypesV0.Tier[] memory tiers)
    {
        // We get the latest tier id added to the ids array
        uint256 noOfTierIds = _tierIds[_namespace].length;
        bytes32[] memory __tierIds = new bytes32[](noOfTierIds);
        ITieredPricingDataTypesV0.Tier[] memory __tiers = new ITieredPricingDataTypesV0.Tier[](noOfTierIds);
        for (uint256 i = 0; i < noOfTierIds; i++) {
            bytes32 tierId_ = _tierIds[_namespace][i];
            // empty name means that the tier does not exist, i.e. was deleted
            if (bytes(_tiers[_namespace][tierId_].name).length > 0) {
                __tiers[i] = _tiers[_namespace][tierId_];
                __tierIds[i] = tierId_;
            }
        }
        tierIds = __tierIds;
        tiers = __tiers;
    }

    /// @dev Returns the default tier for a namespace
    /// @param _namespace - namespace for which default tier is requested
    /// @return tierId - id of the default tier for a namespace
    /// @return tier - tier details of the default tier for a namespace
    function getDefaultTierForNamespace(bytes32 _namespace)
        public
        view
        returns (bytes32 tierId, ITieredPricingDataTypesV0.Tier memory tier)
    {
        tierId = _defaultTier[_namespace];
        tier = _tiers[_namespace][_defaultTier[_namespace]];
    }

    /// @dev Returns the fee for the deployment_fee namespace
    function getDeploymentFee(address _account)
        public
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        )
    {
        (
            address _feeReceiver,
            uint256 _price,
            ITieredPricingDataTypesV0.FeeTypes _feeType,
            address _currency
        ) = _getFee(DEPLOYMENT_FEES_NAMESPACE, _account);
        if (_feeType != ITieredPricingDataTypesV0.FeeTypes.FlatFee)
            revert ITieredPricingErrorsV0.InvalidFeeTypeForDeploymentFees();
        feeReceiver = _feeReceiver;
        price = _price;
        currency = _currency;
    }

    /// @dev Returns the fee for the claim_fee namespace
    function getClaimFee(address _account) public view returns (address feeReceiver, uint256 price) {
        (
            address _feeReceiver,
            uint256 _price,
            ITieredPricingDataTypesV0.FeeTypes _feeType,
            address _currency
        ) = _getFee(CLAIM_FEES_NAMESPACE, _account);
        if (_feeType != ITieredPricingDataTypesV0.FeeTypes.Percentage)
            revert ITieredPricingErrorsV0.InvalidFeeTypeForClaimFees();
        feeReceiver = _feeReceiver;
        price = _price;
    }

    /// @dev Returns the fee for the collector_fee namespace
    function getCollectorFee(address _account)
        public
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        )
    {
        (
            address _feeReceiver,
            uint256 _price,
            ITieredPricingDataTypesV0.FeeTypes _feeType,
            address _currency
        ) = _getFee(COLLECTOR_FEES_NAMESPACE, _account);
        if (_feeType != ITieredPricingDataTypesV0.FeeTypes.FlatFee)
            revert ITieredPricingErrorsV0.InvalidFeeTypeForCollectorFees();
        feeReceiver = _feeReceiver;
        price = _price;
        currency = _currency;
    }

    /// @dev Returns the fee details for a namespace and an account
    /// @param _namespace - namespace for which fee details are requested
    /// @param _account - address for which fee details are requested
    /// @return feeReceiver - The fee receiver address
    /// @return price - The price
    /// @return feeType - The type of the fee
    function getFee(bytes32 _namespace, address _account)
        public
        view
        returns (
            address feeReceiver,
            uint256 price,
            ITieredPricingDataTypesV0.FeeTypes feeType,
            address currency
        )
    {
        return _getFee(_namespace, _account);
    }

    /// @dev Returns the Tier details for a specific tier based on namespace and tier id
    /// @return tier - Tier details for the namespace and tier id
    function getTierDetails(bytes32 _namespace, bytes32 _tierId)
        public
        view
        returns (ITieredPricingDataTypesV0.Tier memory tier)
    {
        tier = _getTierById(_namespace, _tierId);
    }

    /// ======================================
    /// ========= Internal functions =========
    /// ======================================

    /// @dev Sets a new platform fee receiver. Reverts if the receiver address is the same
    function _setPlatformFeeReceiver(address _platformFeeReceiver) internal virtual {
        if (_platformFeeReceiver == __platformFeeReceiver)
            revert ITieredPricingErrorsV0.PlatformFeeReceiverAlreadySet();
        __platformFeeReceiver = _platformFeeReceiver;
        emit PlatformFeeReceiverUpdated(_platformFeeReceiver);
    }

    function _setDefaultTier(bytes32 _namespace, bytes32 _tierId) internal virtual {
        // We make sure that the tier exists
        if (bytes(_getTierById(_namespace, _tierId).name).length == 0) revert ITieredPricingErrorsV0.InvalidTierId();
        _defaultTier[_namespace] = _tierId;

        emit DefaultTierUpdated(_namespace, _tierId);
    }

    /// @dev Adds a new tier for a namespace, if the new tier price is higher than the default one
    ///     we set the new one as the default tier.
    /// @param _namespace - namespace for which tier is added
    /// @param _tierDetails - Details of the tier (name, price, fee type)
    function _addTier(bytes32 _namespace, ITieredPricingDataTypesV0.Tier calldata _tierDetails) internal virtual {
        // Collector fees and deployment fees must be of type flat fee
        if (
            (_namespace == COLLECTOR_FEES_NAMESPACE || _namespace == DEPLOYMENT_FEES_NAMESPACE) &&
            _tierDetails.feeType != ITieredPricingDataTypesV0.FeeTypes.FlatFee
        ) revert ITieredPricingErrorsV0.InvalidFeeType();
        // Claim fees must be of type percentage
        if (
            (_namespace == CLAIM_FEES_NAMESPACE) &&
            _tierDetails.feeType != ITieredPricingDataTypesV0.FeeTypes.Percentage
        ) revert ITieredPricingErrorsV0.InvalidFeeType();
        if (
            // we don't allow zero address for flat fees
            (_tierDetails.feeType == ITieredPricingDataTypesV0.FeeTypes.FlatFee &&
                _tierDetails.currency == address(0)) ||
            // and we also don't allow a namespace to have dfferent currency than the default
            (_tiers[_namespace][_defaultTier[_namespace]].currency != address(0) &&
                _tierDetails.currency != _tiers[_namespace][_defaultTier[_namespace]].currency)
        ) revert ITieredPricingErrorsV0.InvalidCurrencyAddress();
        // we don't allow empty tier name
        if (bytes(_tierDetails.name).length == 0) revert ITieredPricingErrorsV0.InvalidTierName();
        // we dont allow the same tier name for a namespace
        if (_getTierIdForName(_namespace, _tierDetails.name) != 0) revert ITieredPricingErrorsV0.TierNameAlreadyExist();
        if (
            _tierDetails.feeType == ITieredPricingDataTypesV0.FeeTypes.Percentage &&
            _tierDetails.price > MAX_PERCENTAGE_FEE
        ) revert ITieredPricingErrorsV0.InvalidPercentageFee();

        bytes32 newTierId = bytes32(abi.encodePacked(_tierDetails.name));
        _tiers[_namespace][newTierId] = _tierDetails;
        // if it's the first tier added to the namespace, also set it as the default one
        if (_tierIds[_namespace].length == 0) {
            _setDefaultTier((_namespace), newTierId);
        }
        _tierIds[_namespace].push(newTierId);

        emit TierAdded(
            _namespace,
            newTierId,
            _tierDetails.name,
            _tierDetails.price,
            _tierDetails.currency,
            _tierDetails.feeType
        );
    }

    /// @dev Updates an already existing tier. If the default is updated with lower price, then we find the one with
    ///     highest price and set that one as the default
    /// @param _namespace - namespace for which tier is added
    /// @param _tierId - the id of the tier to be updated
    /// @param _tierDetails - Details of the tier (name, price, fee type)
    function _updateTier(
        bytes32 _namespace,
        bytes32 _tierId,
        ITieredPricingDataTypesV0.Tier calldata _tierDetails
    ) internal virtual {
        // We make sure tier exists
        if (bytes(_getTierById(_namespace, _tierId).name).length == 0) revert ITieredPricingErrorsV0.InvalidTierId();
        // we don't allow empty tier name
        if (bytes(_tierDetails.name).length == 0) revert ITieredPricingErrorsV0.InvalidTierName();
        // We don't allow the fee type to change
        if (_tierDetails.feeType != _tiers[_namespace][_tierId].feeType) revert ITieredPricingErrorsV0.InvalidFeeType();
        // we don't allow the currency to change
        if (_tierDetails.currency != _tiers[_namespace][_tierId].currency)
            revert ITieredPricingErrorsV0.InvalidCurrencyAddress();
        // we dont allow the same tier name for a namespace
        if (
            _getTierIdForName(_namespace, _tierDetails.name) != 0 &&
            _getTierIdForName(_namespace, _tierDetails.name) != _tierId
        ) revert ITieredPricingErrorsV0.TierNameAlreadyExist();

        _tiers[_namespace][_tierId] = _tierDetails;

        emit TierUpdated(
            _namespace,
            _tierId,
            _tierDetails.name,
            _tierDetails.price,
            _tierDetails.currency,
            _tierDetails.feeType
        );
    }

    /// @dev Removes a tier from a namespace, if the default tier is removed, then the tier with the
    ///     highest price is set as the default one.
    /// @param _namespace - namespace from which the tier is removed
    /// @param _tierId - id of the tier to be removed
    function _removeTier(bytes32 _namespace, bytes32 _tierId) internal virtual {
        if (_tierIds[_namespace].length == 1) revert ITieredPricingErrorsV0.SingleTieredNamespace();
        if (bytes(_getTierById(_namespace, _tierId).name).length == 0) revert ITieredPricingErrorsV0.InvalidTierId();
        delete _tiers[_namespace][_tierId];

        uint256 noOfTierIds = _tierIds[_namespace].length;
        for (uint256 i = 0; i < noOfTierIds; i++) {
            if (_tierIds[_namespace][i] == _tierId) {
                _tierIds[_namespace][i] = 0;
            }
        }

        if (_defaultTier[_namespace] == _tierId) {
            // We need to find the next tier with highest price and
            // we set the new default tier
            bytes32 newTierId = _getTierIdWithHighestPrice(_namespace);
            _setDefaultTier(_namespace, newTierId);
        }
        emit TierRemoved(_namespace, _tierId);
    }

    /// @dev Adds an account to a specific tier
    /// @param _namespace - namespace for which the account's tier must be added to
    /// @param _account - address which must be added to a tier
    /// @param _tierId - tier id which the account must be added to
    function _addAddressToTier(
        bytes32 _namespace,
        address _account,
        bytes32 _tierId
    ) internal virtual {
        if (_account == address(0)) revert ITieredPricingErrorsV0.InvalidAccount();
        if (bytes(_getTierById(_namespace, _tierId).name).length == 0) revert ITieredPricingErrorsV0.InvalidTierId();
        if (_addressToTier[_namespace][_account] == _tierId) revert ITieredPricingErrorsV0.AccountAlreadyOnTier();

        _addressToTier[_namespace][_account] = _tierId;

        emit AddressAddedToTier(_namespace, _account, _tierId);
    }

    /// @dev Removes an account from a tier, i.e. it's now part of the default tier
    /// @param _namespace - namespace for which the account's tier must be removed
    /// @param _account - address which must be removed from a tier
    function _removeAddressFromTier(bytes32 _namespace, address _account) internal virtual {
        if (_account == address(0)) revert ITieredPricingErrorsV0.InvalidAccount();
        bytes32 tierId = _addressToTier[_namespace][_account];
        if (tierId == _defaultTier[_namespace]) revert ITieredPricingErrorsV0.AccountAlreadyOnDefaultTier();
        delete _addressToTier[_namespace][_account];

        emit AddressRemovedFromTier(_namespace, _account, tierId);
    }

    /// @dev Returns the fee details for a namespace and an account
    /// @return feeReceiver - the address that will receive the fees
    /// @return price - the fee price
    /// @return feeType - the fee type (percentage / flat fee)
    function _getFee(bytes32 _namespace, address _account)
        internal
        view
        returns (
            address feeReceiver,
            uint256 price,
            ITieredPricingDataTypesV0.FeeTypes feeType,
            address currency
        )
    {
        bytes32 tierIdForAddress = _addressToTier[_namespace][_account];
        // If the address does not belong to a tier OR if the tier it belongs to it was deleted
        // we return the default price
        if (tierIdForAddress == 0 || bytes(_tiers[_namespace][tierIdForAddress].name).length == 0) {
            return (
                __platformFeeReceiver,
                _tiers[_namespace][_defaultTier[_namespace]].price,
                _tiers[_namespace][_defaultTier[_namespace]].feeType,
                _tiers[_namespace][_defaultTier[_namespace]].currency
            );
        }
        return (
            __platformFeeReceiver,
            _tiers[_namespace][tierIdForAddress].price,
            _tiers[_namespace][tierIdForAddress].feeType,
            _tiers[_namespace][tierIdForAddress].currency
        );
    }

    /// @dev Returns the Tier details for a specific tier based on namespace and tier id
    function _getTierById(bytes32 _namespace, bytes32 _tierId)
        internal
        view
        returns (ITieredPricingDataTypesV0.Tier memory)
    {
        return _tiers[_namespace][_tierId];
    }

    /// @dev Returns the Tier details for a specific tier based on namespace and tier name
    function _getTierIdForName(bytes32 _namespace, string calldata _tierName) internal view returns (bytes32) {
        uint256 noOfTierIds = _tierIds[_namespace].length;
        bytes32 tierId = 0;
        if (_tierIds[_namespace].length == 0) return tierId;
        for (uint256 i = 0; i < noOfTierIds; i++) {
            bytes32 tierId_ = _tierIds[_namespace][i];
            if (
                keccak256(abi.encodePacked(_tiers[_namespace][tierId_].name)) == keccak256(abi.encodePacked(_tierName))
            ) {
                tierId = tierId_;
                break;
            }
        }
        return tierId;
    }

    /// @dev Returns the Tier Id with highest price for a specific namespace
    function _getTierIdWithHighestPrice(bytes32 _namespace) internal view returns (bytes32) {
        uint256 highestPrice = 0;
        bytes32 tierIdWithHighestPrice = 0;
        uint256 noOfTierIds = _tierIds[_namespace].length;
        for (uint256 i = 0; i < noOfTierIds; i++) {
            bytes32 tierId_ = _tierIds[_namespace][i];
            if (highestPrice < _tiers[_namespace][tierId_].price) {
                highestPrice = _tiers[_namespace][tierId_].price;
                tierIdWithHighestPrice = tierId_;
            }
        }

        return tierIdWithHighestPrice;
    }
}

// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

import "../../api/config/IOperatorFilterersConfig.sol";
import "../../api/config/types/OperatorFiltererDataTypes.sol";
import "../../api/errors/ICoreErrors.sol";

/// @title OperatorFiltererConfig
/// @notice Handles the operator filteres enabled in Aspen Platform.
///         It allows the update and retrieval of platform's operator filters.
contract OperatorFiltererConfig is IOperatorFiltererConfigV0 {
    mapping(bytes32 => IOperatorFiltererDataTypesV0.OperatorFilterer) private _operatorFilterers;
    bytes32[] private _operatorFiltererIds;

    modifier isValidOperatorConfig(IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer) {
        if (
            _newOperatorFilterer.operatorFiltererId == "" ||
            bytes(_newOperatorFilterer.name).length == 0 ||
            _newOperatorFilterer.defaultSubscription == address(0) ||
            _newOperatorFilterer.operatorFilterRegistry == address(0)
        ) revert IOperatorFiltererConfigErrorsV0.InvalidOperatorFiltererDetails();
        _;
    }

    function getOperatorFiltererOrDie(bytes32 _operatorFiltererId)
        public
        view
        returns (IOperatorFiltererDataTypesV0.OperatorFilterer memory)
    {
        if (_operatorFilterers[_operatorFiltererId].defaultSubscription == address(0))
            revert IOperatorFiltererConfigErrorsV0.OperatorFiltererNotFound();
        return _operatorFilterers[_operatorFiltererId];
    }

    function getOperatorFilterer(bytes32 _operatorFiltererId)
        public
        view
        returns (IOperatorFiltererDataTypesV0.OperatorFilterer memory)
    {
        return _operatorFilterers[_operatorFiltererId];
    }

    function getOperatorFiltererIds() public view returns (bytes32[] memory operatorFiltererIds) {
        operatorFiltererIds = _operatorFiltererIds;
    }

    function addOperatorFilterer(IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer)
        public
        virtual
        isValidOperatorConfig(_newOperatorFilterer)
    {
        _addOperatorFilterer(_newOperatorFilterer);
    }

    function _addOperatorFilterer(IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer) internal {
        _operatorFiltererIds.push(_newOperatorFilterer.operatorFiltererId);
        _operatorFilterers[_newOperatorFilterer.operatorFiltererId] = _newOperatorFilterer;

        emit OperatorFiltererAdded(
            _newOperatorFilterer.operatorFiltererId,
            _newOperatorFilterer.name,
            _newOperatorFilterer.defaultSubscription,
            _newOperatorFilterer.operatorFilterRegistry
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

import "./BaseTieredPricing.sol";

/// @title TieredPricingUpgradeable
/// @notice Handles tha fees for the platform. - Optimized for upgradeable contracts
///         It allows the update and retrieval of platform feeBPS and receiver address
contract TieredPricingUpgradeable is BaseTieredPricing {
    function __TieredPricingUpgradeable_init(address _platformFeeReceiver) internal {
        _setPlatformFeeReceiver(_platformFeeReceiver);
    }
}

// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./interfaces/ICoreRegistry.sol";
import "./interfaces/IContractProvider.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/ICoreRegistryEnabled.sol";
import "../api/errors/ICoreErrors.sol";

contract CoreRegistry is IRegistry, IContractProvider, ICoreRegistry {
    bytes4 public constant CORE_REGISTRY_ENABLED_INTERFACE_ID = 0x242e06bd;

    mapping(bytes32 => address) private _contracts;

    modifier isValidContactAddress(address addr) {
        if (addr == address(0)) revert IRegistryErrorsV0.ZeroAddressError();
        if (address(addr).code.length == 0) revert IRegistryErrorsV0.AddressNotContract();
        if (!IERC165(addr).supportsInterface(CORE_REGISTRY_ENABLED_INTERFACE_ID))
            revert IRegistryErrorsV0.CoreRegistryInterfaceNotSupported();
        _;
    }

    modifier canSetCoreRegistry(address addr) {
        ICoreRegistryEnabled coreRegistryEnabled = ICoreRegistryEnabled(addr);
        // Don't add the contract if this does not work.
        if (!coreRegistryEnabled.setCoreRegistryAddress(address(this)))
            revert IRegistryErrorsV0.FailedToSetCoreRegistry();
        _;
    }

    function getConfig(string calldata _version) public view returns (address) {
        return getContractForOrDie(keccak256(abi.encodePacked("AspenConfig_V", _version)));
    }

    function setConfigContract(address _configContract, string calldata _version) public virtual {
        if (!addContract(keccak256(abi.encodePacked("AspenConfig_V", _version)), _configContract)) {
            revert ICoreRegistryErrorsV0.FailedToSetConfigContract();
        }
    }

    function getDeployer(string calldata _version) public view returns (address) {
        return getContractForOrDie(keccak256(abi.encodePacked("AspenDeployer_V", _version)));
    }

    function setDeployerContract(address _deployerContract, string calldata _version) public virtual {
        if (!addContract(keccak256(abi.encodePacked("AspenDeployer_V", _version)), _deployerContract)) {
            revert ICoreRegistryErrorsV0.FailedTosetDeployerContract();
        }
    }

    /// @notice Associates the given address with the given name.
    /// @param _nameHash - Name hash of contract whose address we want to set.
    /// @param _addr - Address of the contract
    function addContract(bytes32 _nameHash, address _addr)
        public
        virtual
        isValidContactAddress(_addr)
        canSetCoreRegistry(_addr)
        returns (bool result)
    {
        _contracts[_nameHash] = _addr;
        return true;
    }

    /// @notice Associates the given address with the given name.
    /// @param _name - Name of contract whose address we want to set.
    /// @param _addr - Address of the contract
    function addContractForString(string calldata _name, address _addr)
        public
        virtual
        isValidContactAddress(_addr)
        canSetCoreRegistry(_addr)
        returns (bool result)
    {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        _contracts[nameHash] = _addr;
        return true;
    }

    /// @notice Gets address associated with the given nameHash.
    /// @param _nameHash - Name hash of contract whose address we want to look up.
    /// @return address of the contract
    /// @dev Throws if address not set.
    function getContractForOrDie(bytes32 _nameHash) public view virtual override returns (address) {
        if (_contracts[_nameHash] == address(0)) revert IRegistryErrorsV0.ContractNotFound();
        return _contracts[_nameHash];
    }

    /// @notice Gets address associated with the given nameHash.
    /// @param _nameHash - Identifier hash of contract whose address we want to look up.
    /// @return address of the contract
    function getContractFor(bytes32 _nameHash) public view virtual override returns (address) {
        return _contracts[_nameHash];
    }

    /// @notice Gets address associated with the given name.
    /// @param _name - Identifier of contract whose address we want to look up.
    /// @return address of the contract
    /// @dev Throws if address not set.
    function getContractForStringOrDie(string calldata _name) public view virtual override returns (address) {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        if (_contracts[nameHash] == address(0)) revert IRegistryErrorsV0.ContractNotFound();
        return _contracts[nameHash];
    }

    /// @notice Gets address associated with the given name.
    /// @param _name - Identifier of contract whose address we want to look up.
    /// @return address of the contract
    function getContractForString(string calldata _name) public view virtual override returns (address) {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        return _contracts[nameHash];
    }
}

// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

interface IContractProvider {
    function getContractForOrDie(bytes32 _nameHash) external view returns (address);

    function getContractFor(bytes32 _nameHash) external view returns (address);

    function getContractForStringOrDie(string calldata _name) external view returns (address);

    function getContractForString(string calldata _name) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

interface ICoreRegistry {
    function getConfig(string calldata _version) external view returns (address);

    function setConfigContract(address configContract, string calldata _version) external;

    function getDeployer(string calldata _version) external view returns (address);

    function setDeployerContract(address _deployerContract, string calldata _version) external;
}

// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

interface ICoreRegistryEnabled {
    function setCoreRegistryAddress(address coreRegistryAddr) external returns (bool result);
}

// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

interface IRegistry {
    function addContract(bytes32 _nameHash, address _addr) external returns (bool result);

    function addContractForString(string calldata _name, address _addr) external returns (bool result);
}

// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseAspenCoreRegistryV1.sol'

pragma solidity ^0.8.4;

import "../../api/impl/IAspenCoreRegistry.sol";
import "../../api/IAspenFeatures.sol";
import "../../api/IAspenVersioned.sol";
import "../../api/config/IGlobalConfig.sol";
import "../../api/config/IGlobalConfig.sol";

/// Inherit from this base to implement introspection
abstract contract BaseAspenCoreRegistryV1 is IAspenFeaturesV1, IAspenVersionedV2, IGlobalConfigV1, IGlobalConfigV2 {
    function supportedFeatureCodes() override public pure returns (uint256[] memory features) {
        features = new uint256[](4);
        /// IAspenFeatures.sol:IAspenFeaturesV1
        features[0] = 0x6efbb19b;
        /// IAspenVersioned.sol:IAspenVersionedV2
        features[1] = 0xe4144b09;
        /// config/IGlobalConfig.sol:IGlobalConfigV1
        features[2] = 0x360da4d8;
        /// config/IGlobalConfig.sol:IGlobalConfigV2
        features[3] = 0x1622fdaf;
    }

    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 1;
    }

    function implementationInterfaceId() virtual override public pure returns (string memory interfaceId) {
        interfaceId = "impl/IAspenCoreRegistry.sol:IAspenCoreRegistryV1";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        return (interfaceID != 0x0) && ((interfaceID != 0xffffffff) && ((interfaceID == 0x01ffc9a7) || ((interfaceID == type(IAspenFeaturesV1).interfaceId) || ((interfaceID == type(IAspenVersionedV2).interfaceId) || ((interfaceID == type(IGlobalConfigV1).interfaceId) || ((interfaceID == type(IGlobalConfigV2).interfaceId) || (interfaceID == type(IAspenCoreRegistryV1).interfaceId)))))));
    }

    function isIAspenFeaturesV1() override public pure returns (bool) {
        return true;
    }
}