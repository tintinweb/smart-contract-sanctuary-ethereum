// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BeaconCache} from "../proxy/Beacon.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";

contract VaultFactory is BeaconCache, IVaultFactory {
    bytes32 private constant IMMUNEFI_ROLE = keccak256("IMMUNEFI_ROLE");
    address public WETH;

    /**
     * @param _immunefi the address fees get sent to
     */
    constructor(address _immunefi) BeaconCache(_immunefi) {
        /*
         *  RBAC set up:
         *  Each role has no admin
         *  No default admin role
         *  Only way for roles to changes hands is through transferRole below
         */
        _setupRole(IMMUNEFI_ROLE, _immunefi);
    }

    /**
     * @notice Setup WETH address for wrapping/unwrapping
     * @dev requires IMMUNEFI_ROLE to set. Done this way to preserve create2 addresses
     * @param _WETH WETH or wrapped native gas token address
     */
    function setupWETH(address _WETH) public onlyRole(IMMUNEFI_ROLE) {
        require(WETH == address(0), "WETH already setup");
        WETH = _WETH;
    }

    /**
     * @notice atomically transfers roles
     * @dev only way for roles to change hands since theres no one has default admin role
     * @dev upgradeability can be burnt but not immunefi feeto
     * @param role bytes32 associated with a role
     * @param newAdmin address to transfer role to
     */
    function transferRole(bytes32 role, address newAdmin) public override onlyRole(role) {
        require(role != IMMUNEFI_ROLE || newAdmin != address(0), "cannot burn immunefi feeTo");
        super.transferRole(role, newAdmin);
    }

    /**
     * @notice Getter addr associated with immunefi to send fees to
     * @dev since each role only has 1 addr associated with it, we grab addr at idx0
     * @return address of immunefi
     */
    function immunefi() public view override returns (address) {
        return getRoleMember(IMMUNEFI_ROLE, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IBeaconDetailed, IBeaconImpl} from "../interfaces/proxy/IBeacon.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC165Checker} from "../external/ERC165Checker.sol";
import {SafeCall} from "../lib/SafeCall.sol";
import {BeaconProxy} from "./BeaconProxy.sol";
import {Cache} from "./Cache.sol";

/**
 * @dev This contract implements a beacon proxy factory based on an extremely
 *      gas-optimized beacon proxy factory and deobfuscates the assembly,
 *      with two modes of operation. The highly-optimized and brittle primary
 *      method involves deploying, to a predictable address, a contract whose
 *      bytecode is an exact copy of the implementation's. This is the "cache"
 *      contract. If the cache is present, the proxy will delegate to it. The
 *      fallback method is less gas efficient and is used either in the small
 *      time period between and upgrade and re-caching of the implementation or
 *      if the selfdestruct-redeploy metamorphism technique is broken by a
 *      future hardfork. The fallback simply calls the `implementation()` method
 *      on the factory contract and delegates to the resulting address.
 */
contract BeaconCache is IBeaconDetailed, AccessControlEnumerableUpgradeable {
    using Address for address;
    using ERC165Checker for address;
    using SafeCall for address;

    /// This storage slot is read during the fallback path. It is also read by the
    /// cache contract during its deployment.
    IBeaconImpl internal _implementation;

    /// @return ret the implementation address for all proxies created by this factory
    function implementation() public view virtual override returns (address ret) {
        ret = address(_implementation);
        require(ret.isContract(), "BeaconCache: no implementation");
    }

    /// Because computing the address of the cache contract is somewhat expensive,
    /// we do it once on construction and cache it.
    IBeaconImpl internal immutable _cache;
    /// Used to invalidate the cached cache address.
    address internal immutable _thisCopy;

    bytes32 private constant _CACHE_INITHASH = 0x492778a7a747248a9e3997d11f211dd93c8d8ad131f229a2aa32ec5fed5d2df8;

    bytes32 private constant _PROXY_INITHASH = 0x0137e0335284a211af10b1ad9a1aacd70d76ba75d000da8deb323e592bab3966;

    bytes21 internal immutable _create2Prefix;

    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /**
     * @dev Put in constructor to maintain safe multichain vanity addresses thru create2
     */
    constructor(address _immunefi) {
        _thisCopy = address(this);
        _create2Prefix = bytes21(uint168((0xff << 160) | uint256(uint160(address(this)))));
        _cache = _computeCache();

        assert(_PROXY_INITHASH == keccak256(type(BeaconProxy).creationCode));
        assert(_CACHE_INITHASH == keccak256(type(Cache).creationCode));
        /*
         *  RBAC set up:
         *  Each role has no admin
         *  No default admin role
         *  Only way for roles to changes hands is through transferRole below
         */
        _setupRole(OWNER_ROLE, _immunefi);
    }

    /**
     * @notice Getter for owner addr
     * @return address of contract owner
     */
    function owner() public view returns (address) {
        return getRoleMember(OWNER_ROLE, 0);
    }

    /**
     * @dev Override renounceRole to remove functionality
     * @dev This function + transferRole implementation below enforces: each role has exactly 1 addr at a time
     */
    function renounceRole(bytes32 role, address account)
        public
        view
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {}

    /**
     * @notice Atomically transfers roles
     * @dev Only way for roles to change hands since theres no one has default admin role
     * @param role bytes32 associated with a role
     * @param newAdmin address to transfer role to
     */
    function transferRole(bytes32 role, address newAdmin) public virtual onlyRole(role) {
        _revokeRole(role, _msgSender());
        _grantRole(role, newAdmin);
    }

    /**
     * @notice Set a new implementation for all the proxies created by this factory
     * @dev Can only be called by OWNER_ROLE
     * @dev The system can be effectively paused by upgrading to the zero address
     * @param newImplementation The address of the new implementation contract to use.
     * The new implementation must extend the IBeaconImpl interface and point to this
     * contract as it's beacon
     */
    function upgrade(address newImplementation) public virtual override onlyRole(OWNER_ROLE) {
        require(!address(cache()).isContract(), "BeaconCache: must call cleanUpCache first");
        IBeaconImpl _newImplementation = IBeaconImpl(newImplementation);
        if (newImplementation != address(0)) {
            require(newImplementation.supportsInterface(type(IBeaconImpl).interfaceId), "BeaconCache: not IBeaconImpl");
            require(_newImplementation.beacon() == this, "BeaconCache: wrong beacon");
        }
        IBeaconImpl oldImplementation = _implementation;
        _implementation = _newImplementation;
        emit Upgraded(newImplementation);
        address(oldImplementation).call(abi.encodeCall(oldImplementation.cleanUp, ())); // don't care if this fails or runs out of gas
    }

    /**
     * @notice Compute the determinstic address of the cache implementation using _CACHE_INITHASH
     * @return result the cache address
     */
    function _computeCache() internal view virtual returns (IBeaconImpl result) {
        return IBeaconImpl(_computeAddress(bytes32(0), _CACHE_INITHASH));
    }

    /**
     * @notice Returns the address of the cache contract
     * @dev This contract does not necessarily exist, but can be created any
     *      time the implementation is nonzero by the owner calling `updateCache`.
     * @return IBeaconImpl the address of the cache
     */
    function cache() public view virtual override returns (IBeaconImpl) {
        return address(this) == _thisCopy ? _cache : _computeCache();
    }

    /**
     * @notice Deploys the cache contract
     * @dev This is `onlyOwner` in case a future hardfork creates a DoS opportunity
     *      (e.g. proposals that reprice `selfdestruct` to become very expensive). This
     *      function caches the bytecode contents of `implementation()`.
     * @param selfdestructGas The minimum gas selfdestruct should use
     */
    function updateCache(uint256 selfdestructGas) public virtual override onlyRole(OWNER_ROLE) {
        IBeaconImpl deployed;
        bytes memory bytecode = type(Cache).creationCode;
        assembly ("memory-safe") {
            deployed := create2(0, add(bytecode, 0x20), mload(bytecode), 0)
        }
        require(deployed == cache(), "BeaconCache: cache create2 failed");
        (, bytes memory returnData) = address(this).safeCall(abi.encodeCall(this.checkCleanUpCache, (selfdestructGas)));
        if (returnData.length != 4) {
            assembly ("memory-safe") {
                revert(add(0x20, returnData), mload(returnData))
            }
        }
        require(bytes4(returnData) == CleanUpSuccess.selector, "Beacon: bad custom error");
    }

    /**
     * @notice Function to selfdestruct the cache
     * @dev Can only be called by OWNER_ROLE
     * @dev We cannot call `cleanUpCache` and then `updateCache` in the same
     *      transaction because the `selfdestruct`'d contract isn't actually deleted
     *      until the end of bytecode execution. This behavior is why we require the
     *      fallback logic of the proxy.
     */
    function cleanUpCache() public virtual override onlyRole(OWNER_ROLE) {
        cache().cleanUp();
    }

    error CleanUpSuccess();

    /**
     * @notice Function to check if the cache can be selfdestructed
     * @dev We can't actually check that `cache()` `selfdestruct`s as expected since
     * the important observable effects of selfdestruct don't happen until after
     * the transaction has finished executing bytecode. However, we can at least
     * check to make sure that the call to `cleanUp()` succeeds. This avoids
     * some, but not all, foot-guns in this metamorphic process.
     * @param selfdestructGas The minimum gas selfdestruct should use
     */
    function checkCleanUpCache(uint256 selfdestructGas) external {
        IBeaconImpl cache_ = cache();
        bytes memory callData = abi.encodeCall(cache_.cleanUp, ());
        uint256 beforeGas = gasleft();
        (bool success, bytes memory returnData) = address(cache_).safeCall(callData);
        uint256 afterGas = gasleft();
        if (!success) {
            require(
                returnData.length != 4 || bytes4(returnData) != CleanUpSuccess.selector,
                "Beacon: error selector clash"
            );
            assembly ("memory-safe") {
                revert(add(0x20, returnData), mload(returnData))
            }
        }
        require(beforeGas - afterGas >= selfdestructGas, "BeaconCache: did not selfdestruct");
        revert CleanUpSuccess();
    }

    /**
     * @notice Deploys a new beacon proxy
     * @dev The salt is combined with the message sender to
     *      ensure that two different users cannot deploy proxies to the same
     *      address. The address deployed to does not depend on the current
     *      implementation or on the initializer.
     * @param initializer The encdoded function data and parameters of the intializer
     * @param salt The salt used for deployment
     * @return proxy the address the proxy is deployed to
     * @return returnData return data from calling initializer. Current proxy implementation returns nothing
     */
    function deploy(bytes calldata initializer, bytes32 salt)
        public
        payable
        virtual
        override
        returns (address proxy, bytes memory returnData)
    {
        address msgSender = _msgSender();
        bytes memory bytecode = type(BeaconProxy).creationCode;
        bytes32 proxySalt = keccak256(abi.encodePacked(msgSender, salt));
        {
            assembly ("memory-safe") {
                proxy := create2(0, add(bytecode, 0x20), mload(bytecode), proxySalt)
            }
        }
        require(proxy != address(0), "BeaconCache: create2 failed");

        // Rolling the initialization into the construction of the proxy is either
        // very expensive (if the initializer has to be saved to storage and then
        // retrived by the initializer by a callback) (>200 gas per word as of
        // EIP-2929/Berlin) or creates dependence of the deployed address on the
        // contents of the initializer (if it's supplied as part of the
        // initcode). Therefore, we elect to send the initializer as part of a call
        // to the proxy AFTER deployment.
        returnData = proxy.functionCallWithValue(initializer, msg.value, "BeaconCache: initialize failed");

        emit Deployed(proxy, msgSender, salt);
    }

    /**
     * @notice Compute the create2 deterministic address given a deployer and a salt
     * @param deployer The address calling the deploy function
     * @param salt The salt provided by deployer
     * @return address create2 deterministic computed address
     */
    function predict(address deployer, bytes32 salt) public view virtual override returns (address) {
        bytes32 proxySalt = keccak256(abi.encodePacked(deployer, salt));
        return _computeAddress(proxySalt, _PROXY_INITHASH);
    }

    /**
     * @notice Compute the create2 deterministic address given a salt
     * @param salt The salt determined from provided salt + deployer address
     * @param bytecodeHash The creation code of the contract to be deployed
     * @return address of deployed contract
     */
    function _computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(_create2Prefix, salt, bytecodeHash)))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVaultFactory {
    function immunefi() external view returns (address);

    function WETH() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IBeacon {
    function implementation() external view returns (address);
}

interface IBeaconUpgradeable is IBeacon {
    // This clashes with the event of the same signature specified by EIP1967 to
    // be emitted by the proxy (not the beacon), but it appears to be conventional
    // nonetheless.
    event Upgraded(address indexed implementation);

    function upgrade(address newImplementation) external;
}

interface IBeaconImpl is IERC165 {
    function beacon() external view returns (IBeaconCache);

    function implementation() external view returns (IBeaconImpl);

    function cache() external view returns (IBeaconImpl);

    function cleanUp() external;
}

interface IBeaconCache is IBeaconUpgradeable {
    function cache() external view returns (IBeaconImpl);

    function updateCache(uint256 selfdestructGas) external;

    function cleanUpCache() external;
}

interface IBeaconDetailed is IBeaconCache {
    event Deployed(address indexed proxy, address indexed deployer, bytes32 salt);

    function deploy(bytes calldata initializer, bytes32 salt)
        external
        payable
        returns (address proxy, bytes memory returnData);

    function predict(address deployer, bytes32 salt) external view returns (address);
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {CallWithGas} from "../lib/CallWithGas.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 *
 * This library has been modified for Solidity 0.8.13 and to use CallWithGas to
 * prevent insufficient gas griefing attacks.
 */
library ERC165Checker {
    using CallWithGas for address;

    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
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
        bytes memory data = abi.encodeCall(IERC165(account).supportsInterface, (interfaceId));
        (bool success, bytes memory result) = account.functionStaticCallWithGas(data, 30_000, 32);
        return success && result.length >= 32 && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {FullMath} from "../external/uniswapv3/FullMath.sol";

library SafeCall {
    using Address for address;
    using Address for address payable;

    function safeCall(address target, bytes memory data) internal returns (bool, bytes memory) {
        return safeCall(payable(target), data, 0);
    }

    function safeCall(
        address payable target,
        bytes memory data,
        uint256 value
    ) internal returns (bool, bytes memory) {
        return safeCall(target, data, value, 0);
    }

    function safeCall(
        address payable target,
        bytes memory data,
        uint256 value,
        uint256 depth
    ) internal returns (bool success, bytes memory returndata) {
        require(depth < 42, "SafeCall: overflow");
        if (value > 0 && (address(this).balance < value || !target.isContract())) {
            return (success, returndata);
        }

        uint256 beforeGas;
        uint256 afterGas;

        assembly ("memory-safe") {
            // As of the time this contract was written, `verbatim` doesn't work in
            // inline assembly. Due to how the Yul IR optimizer inlines and optimizes,
            // the amount of gas required to prepare the stack with arguments for call
            // is unpredictable. However, each these operations cost
            // gas. Additionally, `call` has an intrinsic gas cost, which is too
            // complicated for this comment but can be found in the Ethereum
            // yellowpaper, Berlin version fabef25, appendix H.2, page 37. Therefore,
            // `beforeGas` is always above the actual gas available before the
            // all-but-one-64th rule is applied. This makes the following checks too
            // conservative. We do not correct for any of this because the correction
            // would become outdated (possibly too permissive) if the opcodes are
            // repriced.

            let offset := add(data, 0x20)
            let length := mload(data)
            beforeGas := gas()
            success := call(gas(), target, value, offset, length, 0, 0)

            // Assignment of a value to a variable costs gas (although how much is
            // unpredictable because it depends on the optimizer), as does the `GAS`
            // opcode itself. Therefore, the `gas()` below returns less than the
            // actual amount of gas available for computation at the end of the
            // call. Again, that makes the check slightly too conservative. Again, we
            // do not attempt any correction.
            afterGas := gas()
        }

        if (!success) {
            // The arithmetic here iterates the all-but-one-sixty-fourth rule to
            // ensure that the call that's `depth` contexts away received enough
            // gas. See: https://eips.ethereum.org/EIPS/eip-150
            unchecked {
                depth++;
                uint256 powerOf64 = 1 << (depth * 6);
                if (FullMath.mulDivCeil(beforeGas, powerOf64 - 63**depth, powerOf64) >= afterGas) {
                    assembly ("memory-safe") {
                        // The call probably failed due to out-of-gas. We deliberately
                        // consume all remaining gas with `invalid` (instead of `revert`) to
                        // make this failure distinguishable to our caller.
                        invalid()
                    }
                }
            }
        }

        assembly ("memory-safe") {
            switch returndatasize()
            case 0 {
                returndata := 0x60
                if iszero(value) {
                    success := and(success, iszero(iszero(extcodesize(target))))
                }
            }
            default {
                returndata := mload(0x40)
                mstore(returndata, returndatasize())
                let offset := add(returndata, 0x20)
                returndatacopy(offset, 0, returndatasize())
                mstore(0x40, add(offset, returndatasize()))
            }
        }
    }

    function safeStaticCall(address target, bytes memory data) internal view returns (bool, bytes memory) {
        return safeStaticCall(target, data, 0);
    }

    function safeStaticCall(
        address target,
        bytes memory data,
        uint256 depth
    ) internal view returns (bool success, bytes memory returndata) {
        require(depth < 42, "SafeCall: overflow");

        uint256 beforeGas;
        uint256 afterGas;

        assembly ("memory-safe") {
            // As of the time this contract was written, `verbatim` doesn't work in
            // inline assembly. Due to how the Yul IR optimizer inlines and optimizes,
            // the amount of gas required to prepare the stack with arguments for call
            // is unpredictable. However, each these operations cost
            // gas. Additionally, `staticcall` has an intrinsic gas cost, which is too
            // complicated for this comment but can be found in the Ethereum
            // yellowpaper, Berlin version fabef25, appendix H.2, page 37. Therefore,
            // `beforeGas` is always above the actual gas available before the
            // all-but-one-64th rule is applied. This makes the following checks too
            // conservative. We do not correct for any of this because the correction
            // would become outdated (possibly too permissive) if the opcodes are
            // repriced.

            let offset := add(data, 0x20)
            let length := mload(data)
            beforeGas := gas()
            success := staticcall(gas(), target, offset, length, 0, 0)

            // Assignment of a value to a variable costs gas (although how much is
            // unpredictable because it depends on the optimizer), as does the `GAS`
            // opcode itself. Therefore, the `gas()` below returns less than the
            // actual amount of gas available for computation at the end of the
            // call. Again, that makes the check slightly too conservative. Again, we
            // do not attempt any correction.
            afterGas := gas()
        }

        if (!success) {
            // The arithmetic here iterates the all-but-one-sixty-fourth rule to
            // ensure that the call that's `depth` contexts away received enough
            // gas. See: https://eips.ethereum.org/EIPS/eip-150
            unchecked {
                depth++;
                uint256 powerOf64 = 1 << (depth * 6);
                if (FullMath.mulDivCeil(beforeGas, powerOf64 - 63**depth, powerOf64) >= afterGas) {
                    assembly ("memory-safe") {
                        // The call probably failed due to out-of-gas. We deliberately
                        // consume all remaining gas with `invalid` (instead of `revert`) to
                        // make this failure distinguishable to our caller.
                        invalid()
                    }
                }
            }
        }

        assembly ("memory-safe") {
            switch returndatasize()
            case 0 {
                returndata := 0x60
                success := and(success, iszero(iszero(extcodesize(target))))
            }
            default {
                returndata := mload(0x40)
                mstore(returndata, returndatasize())
                let offset := add(returndata, 0x20)
                returndatacopy(offset, 0, returndatasize())
                mstore(0x40, add(offset, returndatasize()))
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IBeacon} from "../interfaces/proxy/IBeacon.sol";
import {Cache} from "./Cache.sol";

contract BeaconProxy is Proxy {
    using Address for address;

    IBeacon immutable beacon;
    address immutable cache;

    constructor() {
        beacon = IBeacon(msg.sender);
        bytes32 cacheHash = keccak256(type(Cache).creationCode);
        cache = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), beacon, uint256(0), cacheHash)))));
    }

    /**
     * @notice Getter for implementation address
     * @dev Gets the cache contract address if its active, else get the implementation address from the beacon
     */
    function _implementation() internal view override returns (address) {
        if (cache.isContract()) {
            return cache;
        }
        return beacon.implementation();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IBeacon} from "../interfaces/proxy/IBeacon.sol";

contract Cache {
    constructor() {
        address implementation = IBeacon(msg.sender).implementation();

        assembly {
            let size := extcodesize(implementation)

            extcodecopy(implementation, 0x0, 0, size)

            return(0, size)
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
pragma solidity 0.8.13;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

library CallWithGas {
    using Address for address;
    using Address for address payable;

    /**
     * @notice `staticcall` another contract forwarding a precomputed amount of
     *         gas.
     * @dev contains protections against EIP-150-induced insufficient gas
     *      griefing
     * @dev reverts iff the target is not a contract or we encounter an
     *      out-of-gas
     * @return success true iff the call succeded and returned no more than
     *                 `maxReturnBytes` of return data
     * @return returnData the return data or revert reason of the call
     * @param target the contract (reverts if non-contract) on which to make the
     *               `staticcall`
     * @param data the calldata to pass
     * @param callGas the gas to pass for the call. If the call requires more than
     *                the specified amount of gas and the caller didn't provide at
     *                least `callGas`, triggers an out-of-gas in the caller.
     * @param maxReturnBytes Only this many bytes of return data are read back
     *                       from the call. This prevents griefing the caller. If
     *                       more bytes are returned or the revert reason is
     *                       longer, success will be false and returnData will be
     *                       `abi.encodeWithSignature("Error(string)", "CallWithGas: returnData too long")`
     */
    function functionStaticCallWithGas(
        address target,
        bytes memory data,
        uint256 callGas,
        uint256 maxReturnBytes
    ) internal view returns (bool success, bytes memory returnData) {
        assembly ("memory-safe") {
            returnData := mload(0x40)
            success := staticcall(callGas, target, add(data, 0x20), mload(data), add(returnData, 0x20), maxReturnBytes)

            // As of the time this contract was written, `verbatim` doesn't work in
            // inline assembly.  Assignment of a value to a variable costs gas
            // (although how much is unpredictable because it depends on the Yul/IR
            // optimizer), as does the `GAS` opcode itself. Also solc tends to reorder
            // the call to `gas()` with preparing the arguments for `div`. Therefore,
            // the `gas()` below returns less than the actual amount of gas available
            // for computation at the end of the call. That makes this check slightly
            // too conservative. However, we do not correct for this because the
            // correction would become outdated (possibly too permissive) if the
            // opcodes are repriced.

            // https://eips.ethereum.org/EIPS/eip-150
            // https://ronan.eth.link/blog/ethereum-gas-dangers/
            if iszero(or(success, or(returndatasize(), lt(div(callGas, 63), gas())))) {
                // The call failed due to not enough gas left. We deliberately consume
                // all remaining gas with `invalid` (instead of `revert`) to make this
                // failure distinguishable to our caller.
                invalid()
            }

            switch gt(returndatasize(), maxReturnBytes)
            case 0 {
                switch returndatasize()
                case 0 {
                    returnData := 0x60
                    success := and(success, iszero(iszero(extcodesize(target))))
                }
                default {
                    mstore(returnData, returndatasize())
                    mstore(0x40, add(returnData, add(0x20, returndatasize())))
                }
            }
            default {
                // returnData = abi.encodeWithSignature("Error(string)", "CallWithGas: returnData too long")
                success := 0
                mstore(returnData, 0) // clear potentially dirty bits
                mstore(add(returnData, 0x04), 0x6408c379a0) // length and selector
                mstore(add(returnData, 0x24), 0x20)
                mstore(add(returnData, 0x44), 0x20)
                mstore(add(returnData, 0x64), "CallWithGas: returnData too long")
                mstore(0x40, add(returnData, 0x84))
            }
        }
    }

    /// See `functionCallWithGasAndValue`
    function functionCallWithGas(
        address target,
        bytes memory data,
        uint256 callGas,
        uint256 maxReturnBytes
    ) internal returns (bool success, bytes memory returnData) {
        return functionCallWithGasAndValue(payable(target), data, callGas, 0, maxReturnBytes);
    }

    /**
     * @notice `call` another contract forwarding a precomputed amount of gas.
     * @notice Unlike `functionStaticCallWithGas`, a failure is not signaled if
     *         there is too much return data. Instead, it is simply truncated.
     * @dev contains protections against EIP-150-induced insufficient gas griefing
     * @dev reverts iff caller doesn't have enough native asset balance, the
     *      target is not a contract, or due to out-of-gas
     * @return success true iff the call succeded
     * @return returnData the return data or revert reason of the call
     * @param target the contract (reverts if non-contract) on which to make the
     *               `call`
     * @param data the calldata to pass
     * @param callGas the gas to pass for the call. If the call requires more than
     *                the specified amount of gas and the caller didn't provide at
     *                least `callGas`, triggers an out-of-gas in the caller.
     * @param value the amount of the native asset in wei to pass to the callee
     *              with the call
     * @param maxReturnBytes Only this many bytes of return data/revert reason are
     *                       read back from the call. This prevents griefing the
     *                       caller. If more bytes are returned or the revert
     *                       reason is longer, returnData will be truncated
     */
    function functionCallWithGasAndValue(
        address payable target,
        bytes memory data,
        uint256 callGas,
        uint256 value,
        uint256 maxReturnBytes
    ) internal returns (bool success, bytes memory returnData) {
        if (value > 0 && (address(this).balance < value || !target.isContract())) {
            return (success, returnData);
        }

        assembly ("memory-safe") {
            returnData := mload(0x40)
            success := call(callGas, target, value, add(data, 0x20), mload(data), add(returnData, 0x20), maxReturnBytes)

            // As of the time this contract was written, `verbatim` doesn't work in
            // inline assembly.  Assignment of a value to a variable costs gas
            // (although how much is unpredictable because it depends on the Yul/IR
            // optimizer), as does the `GAS` opcode itself. Also solc tends to reorder
            // the call to `gas()` with preparing the arguments for `div`. Therefore,
            // the `gas()` below returns less than the actual amount of gas available
            // for computation at the end of the call. That makes this check slightly
            // too conservative. However, we do not correct for this because the
            // correction would become outdated (possibly too permissive) if the
            // opcodes are repriced.

            // https://eips.ethereum.org/EIPS/eip-150
            // https://ronan.eth.link/blog/ethereum-gas-dangers/
            if iszero(or(success, or(returndatasize(), lt(div(callGas, 63), gas())))) {
                // The call failed due to not enough gas left. We deliberately consume
                // all remaining gas with `invalid` (instead of `revert`) to make this
                // failure distinguishable to our caller.
                invalid()
            }

            switch gt(returndatasize(), maxReturnBytes)
            case 0 {
                switch returndatasize()
                case 0 {
                    returnData := 0x60
                    if iszero(value) {
                        success := and(success, iszero(iszero(extcodesize(target))))
                    }
                }
                default {
                    mstore(returnData, returndatasize())
                    mstore(0x40, add(returnData, add(0x20, returndatasize())))
                }
            }
            default {
                mstore(returnData, maxReturnBytes)
                mstore(0x40, add(returnData, add(0x20, maxReturnBytes)))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256) {
        return _mulDiv(a, b, denominator, true);
    }

    function mulDivCeil(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256) {
        return _mulDiv(a, b, denominator, false);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds accorrding to `roundDown`. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @param roundDown if true, round towards negative infinity; if false, round towards positive infinity
    /// @return The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function _mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator,
        bool roundDown
    ) private pure returns (uint256) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        uint256 remainder; // Remainder of full-precision division
        assembly ("memory-safe") {
            // Full-precision multiplication
            {
                let mm := mulmod(a, b, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            remainder := mulmod(a, b, denominator)

            if and(sub(roundDown, 1), remainder) {
                // Make division exact by rounding [prod1 prod0] up to a
                // multiple of denominator
                let addend := sub(denominator, remainder)
                // Add 256 bit number to 512 bit number
                prod0 := add(prod0, addend)
                prod1 := add(prod1, lt(prod0, addend))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            if iszero(gt(denominator, prod1)) {
                // selector for `Panic(uint256)`
                mstore(0x00, 0x4e487b71)
                // 0x11 -> overflow; 0x12 -> division by zero
                mstore(0x20, add(0x11, iszero(denominator)))
                revert(0x1c, 0x24)
            }
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            uint256 result;
            assembly ("memory-safe") {
                result := div(prod0, denominator)
            }
            return result;
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        uint256 inv;
        assembly ("memory-safe") {
            if roundDown {
                // Make division exact by rounding [prod1 prod0] down to a
                // multiple of denominator
                // Subtract 256 bit number from 512 bit number
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            {
                // Compute largest power of two divisor of denominator.
                // Always >= 1.
                let twos := and(sub(0, denominator), denominator)

                // Divide denominator by power of two
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by the factors of two
                prod0 := div(prod0, twos)
                // Shift in bits from prod1 into prod0. For this we need
                // to flip `twos` such that it is 2**256 / twos.
                // If twos is zero, then it becomes one
                twos := add(div(sub(0, twos), twos), 1)
                prod0 := or(prod0, mul(prod1, twos))
            }

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            inv := xor(mul(3, denominator), 2)

            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**8
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**16
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**32
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**64
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**128
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**256
        }

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        unchecked {
            return prod0 * inv;
        }
    }

    // solhint-disable-next-line contract-name-camelcase
    struct uint512 {
        uint256 l;
        uint256 h;
    }

    // Adapted from: https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
    function mulAdd(
        uint512 memory x,
        uint256 y,
        uint256 z
    ) internal pure {
        unchecked {
            uint256 l = y * z;
            uint256 mm = mulmod(y, z, type(uint256).max);
            uint256 h = mm - l;
            x.l += l;
            if (l > x.l) h++;
            if (mm < l) h--;
            x.h += h;
        }
    }

    function _msb(uint256 x) private pure returns (uint256 r) {
        unchecked {
            require(x > 0);
            if (x >= 2**128) {
                x >>= 128;
                r += 128;
            }
            if (x >= 2**64) {
                x >>= 64;
                r += 64;
            }
            if (x >= 2**32) {
                x >>= 32;
                r += 32;
            }
            if (x >= 2**16) {
                x >>= 16;
                r += 16;
            }
            if (x >= 2**8) {
                x >>= 8;
                r += 8;
            }
            if (x >= 2**4) {
                x >>= 4;
                r += 4;
            }
            if (x >= 2**2) {
                x >>= 2;
                r += 2;
            }
            if (x >= 2**1) {
                x >>= 1;
                r += 1;
            }
        }
    }

    function div(uint512 memory x, uint256 y) internal pure returns (uint256 r) {
        uint256 l = x.l;
        uint256 h = x.h;
        require(h < y);
        unchecked {
            uint256 yShift = _msb(y);
            uint256 shiftedY = y;
            if (yShift <= 127) {
                yShift = 0;
            } else {
                yShift -= 127;
                shiftedY = ((shiftedY - 1) >> yShift) + 1;
            }
            while (h > 0) {
                uint256 lShift = _msb(h) + 1;
                uint256 hShift = 256 - lShift;
                uint256 e = ((h << hShift) + (l >> lShift)) / shiftedY;
                if (lShift > yShift) {
                    e <<= (lShift - yShift);
                } else {
                    e >>= (yShift - lShift);
                }
                r += e;

                uint256 tl;
                uint256 th;
                {
                    uint256 mm = mulmod(e, y, type(uint256).max);
                    tl = e * y;
                    th = mm - tl;
                    if (mm < tl) {
                        th -= 1;
                    }
                }

                h -= th;
                if (tl > l) {
                    h -= 1;
                }
                l -= tl;
            }
            r += l / y;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}