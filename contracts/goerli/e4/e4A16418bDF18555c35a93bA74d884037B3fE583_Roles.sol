// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware, ISafe} from "./SafeAware.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

// When the base contract (implementation) that proxies use is created,
// we use this no-op address when an address is needed to make contracts initialized but unusable
address constant IMPL_INIT_NOOP_ADDR = address(1);
ISafe constant IMPL_INIT_NOOP_SAFE = ISafe(payable(IMPL_INIT_NOOP_ADDR));

/**
 * @title EIP1967Upgradeable
 * @dev Minimal implementation of EIP-1967 allowing upgrades of itself by a Safe transaction
 * @dev Note that this contract doesn't have have an initializer as the implementation
 * address must already be set in the correct slot (in our case, the proxy does on creation)
 */
abstract contract EIP1967Upgradeable is SafeAware {
    event Upgraded(IModuleMetadata indexed implementation, string moduleId, uint256 version);

    // EIP1967_IMPL_SLOT = keccak256('eip1967.proxy.implementation') - 1
    bytes32 internal constant EIP1967_IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal constant IMPL_CONTRACT_FLAG = address(0xffff);

    // As the base contract doesn't use the implementation slot,
    // set a flag in that slot so that it is possible to detect it
    constructor() {
        address implFlag = IMPL_CONTRACT_FLAG;
        assembly {
            sstore(EIP1967_IMPL_SLOT, implFlag)
        }
    }

    /**
     * @notice Upgrades the proxy to a new implementation address
     * @dev The new implementation should be a contract that implements a way to perform upgrades as well
     * otherwise the proxy will freeze on that implementation forever, since the proxy doesn't contain logic to change it.
     * It also must conform to the IModuleMetadata interface (this is somewhat of an implicit guard against bad upgrades)
     * @param _newImplementation The address of the new implementation address the proxy will use
     */
    function upgrade(IModuleMetadata _newImplementation) public onlySafe {
        assembly {
            sstore(EIP1967_IMPL_SLOT, _newImplementation)
        }

        emit Upgraded(_newImplementation, _newImplementation.moduleId(), _newImplementation.moduleVersion());
    }

    function _implementation() internal view returns (IModuleMetadata impl) {
        assembly {
            impl := sload(EIP1967_IMPL_SLOT)
        }
    }

    /**
     * @dev Checks whether the context is foreign to the implementation
     * or the proxy by checking the EIP-1967 implementation slot.
     * If we were running in proxy context, the impl address would be stored there
     * If we were running in impl conext, the IMPL_CONTRACT_FLAG would be stored there
     */
    function _isForeignContext() internal view returns (bool) {
        return address(_implementation()) == address(0);
    }

    function _isImplementationContext() internal view returns (bool) {
        return address(_implementation()) == IMPL_CONTRACT_FLAG;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware} from "./SafeAware.sol";

/**
 * @dev Context variant with ERC2771 support.
 * Copied and modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/metatx/ERC2771Context.sol (MIT licensed)
 */
abstract contract ERC2771Context is SafeAware {
    // SAFE_SLOT = keccak256("firm.erc2271context.forwarders") - 1
    bytes32 internal constant ERC2271_TRUSTED_FORWARDERS_BASE_SLOT =
        0xde1482070091aef895249374204bcae0fa9723215fa9357228aa489f9d1bd669;

    event TrustedForwarderSet(address indexed forwarder, bool enabled);

    function setTrustedForwarder(address forwarder, bool enabled) external onlySafe {
        _setTrustedForwarder(forwarder, enabled);
    }

    function _setTrustedForwarder(address forwarder, bool enabled) internal {
        _trustedForwarders()[forwarder] = enabled;

        emit TrustedForwarderSet(forwarder, enabled);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _trustedForwarders()[forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _trustedForwarders() internal pure returns (mapping(address => bool) storage trustedForwarders) {
        assembly {
            trustedForwarders.slot := ERC2271_TRUSTED_FORWARDERS_BASE_SLOT
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";
import {ERC2771Context} from "./ERC2771Context.sol";
import {EIP1967Upgradeable, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "./EIP1967Upgradeable.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

abstract contract FirmBase is EIP1967Upgradeable, ERC2771Context, IModuleMetadata {
    event Initialized(ISafe indexed safe, IModuleMetadata indexed implementation);

    function __init_firmBase(ISafe safe_, address trustedForwarder_) internal {
        // checks-effects-interactions violated so that the init event always fires first
        emit Initialized(safe_, _implementation());

        __init_setSafe(safe_);
        if (trustedForwarder_ != address(0) || trustedForwarder_ != IMPL_INIT_NOOP_ADDR) {
            _setTrustedForwarder(trustedForwarder_, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";

/**
 * @title SafeAware
 * @dev Base contract for Firm components that need to be aware of a Safe
 * as their admin
 */
abstract contract SafeAware {
    // SAFE_SLOT = keccak256("firm.safeaware.safe") - 1
    bytes32 internal constant SAFE_SLOT = 0xb2c095c1a3cccf4bf97d6c0d6a44ba97fddb514f560087d9bf71be2c324b6c44;

    /**
     * @notice Address of the Safe that this module is tied to
     */
    function safe() public view returns (ISafe safeAddr) {
        assembly {
            safeAddr := sload(SAFE_SLOT)
        }
    }

    error SafeAddressZero();
    error AlreadyInitialized();

    /**
     * @dev Contracts that inherit from SafeAware, including derived contracts as
     * EIP1967Upgradeable or Safe, should call this function on initialization
     * Will revert if called twice
     * @param _safe The address of the GnosisSafe to use, won't be modifiable unless
     * implicitly implemented by the derived contract, which is not recommended
     */
    function __init_setSafe(ISafe _safe) internal {
        if (address(_safe) == address(0)) {
            revert SafeAddressZero();
        }
        if (address(safe()) != address(0)) {
            revert AlreadyInitialized();
        }
        assembly {
            sstore(SAFE_SLOT, _safe)
        }
    }

    error UnauthorizedNotSafe();
    /**
     * @dev Modifier to be used by derived contracts to limit access control to priviledged
     * functions so they can only be called by the Safe
     */
    modifier onlySafe() {
        if (_msgSender() != address(safe())) {
            revert UnauthorizedNotSafe();
        }

        _;
    }

    function _msgSender() internal view virtual returns (address sender); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModuleMetadata {
    function moduleId() external pure returns (string memory);
    function moduleVersion() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimum viable interface of a Safe that Firm's protocol needs
interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    receive() external payable;

    /**
     * @dev Allows modules to execute transactions
     * @notice Can only be called by an enabled module.
     * @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
     * @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
     */
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success, bytes memory returnData);

    /**
     * @dev Returns if a certain address is an owner of this Safe
     * @return Whether the address is an owner or not
     */
    function isOwner(address owner) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {FirmBase, IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR} from "../bases/FirmBase.sol";
import {ISafe} from "../bases/SafeAware.sol";

import {
    IRoles,
    ROOT_ROLE_ID,
    ROLE_MANAGER_ROLE_ID,
    ONLY_ROOT_ROLE_AS_ADMIN,
    NO_ROLE_ADMINS,
    SAFE_OWNER_ROLE_ID
} from "./interfaces/IRoles.sol";

/**
 * @title Roles
 * @author Firm ([email protected])
 * @notice Role management module supporting up to 256 roles optimized for batched actions
 * Inspired by Solmate's RolesAuthority and OpenZeppelin's AccessControl
 * https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol
 */
contract Roles is FirmBase, IRoles {
    string public constant moduleId = "org.firm.roles";
    uint256 public constant moduleVersion = 1;

    mapping(address => bytes32) public getUserRoles;
    mapping(uint8 => bytes32) public getRoleAdmins;
    uint256 public roleCount;

    event RoleCreated(uint8 indexed roleId, bytes32 roleAdmins, string name, address indexed actor);
    event RoleNameChanged(uint8 indexed roleId, string name, address indexed actor);
    event RoleAdminsSet(uint8 indexed roleId, bytes32 roleAdmins, address indexed actor);
    event UserRolesChanged(address indexed user, bytes32 oldUserRoles, bytes32 newUserRoles, address indexed actor);

    error UnauthorizedNoRole(uint8 requiredRole);
    error UnauthorizedNotAdmin(uint8 roleId);
    error UnexistentRole(uint8 roleId);
    error RoleLimitReached();
    error InvalidRoleAdmins();

    bytes32 internal constant SAFE_OWNER_ROLE_MASK = ~bytes32(uint256(1) << SAFE_OWNER_ROLE_ID);

    ////////////////////////////////////////////////////////////////////////////////
    // INITIALIZATION
    ////////////////////////////////////////////////////////////////////////////////

    constructor() {
        initialize(IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR);
    }

    function initialize(ISafe safe_, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts if already initialized
        __init_firmBase(safe_, trustedForwarder_);

        assert(_createRole(ONLY_ROOT_ROLE_AS_ADMIN, "Root") == ROOT_ROLE_ID);
        assert(_createRole(ONLY_ROOT_ROLE_AS_ADMIN, "Role Manager") == ROLE_MANAGER_ROLE_ID);

        // Safe given the root role on initialization (which admins for the role can revoke)
        // Addresses with the root role have permission to do anything
        // By assigning just the root role, it also gets the role manager role (and all roles to be created)
        getUserRoles[address(safe_)] = ONLY_ROOT_ROLE_AS_ADMIN;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ROLE CREATION AND MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Creates a new role
     * @dev Requires the sender to hold the Role Manager role
     * @param roleAdmins Bitmap of roles that can perform admin actions on the new role
     * @param name Name of the role
     * @return roleId ID of the new role
     */
    function createRole(bytes32 roleAdmins, string memory name) public returns (uint8 roleId) {
        if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
            revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
        }

        return _createRole(roleAdmins, name);
    }

    function _createRole(bytes32 roleAdmins, string memory name) internal returns (uint8 roleId) {
        uint256 roleId_ = roleCount;
        if (roleId_ == SAFE_OWNER_ROLE_ID) {
            revert RoleLimitReached();
        }

        if (roleAdmins == NO_ROLE_ADMINS || !_allRoleAdminsExist(roleAdmins, roleId_ + 1)) {
            revert InvalidRoleAdmins();
        }

        unchecked {
            roleId = uint8(roleId_);
            roleCount++;
        }

        getRoleAdmins[roleId] = roleAdmins;

        emit RoleCreated(roleId, roleAdmins, name, _msgSender());
    }

    /**
     * @notice Changes the roles that can perform admin actions on a role
     * @dev For the Root role, the sender must be an admin of Root
     * For all other roles, the sender should hold the Role Manager role
     * @param roleId ID of the role
     * @param roleAdmins Bitmap of roles that can perform admin actions on this role
     */
    function setRoleAdmins(uint8 roleId, bytes32 roleAdmins) external {
        if ((roleAdmins == NO_ROLE_ADMINS && roleId != ROOT_ROLE_ID) || !_allRoleAdminsExist(roleAdmins, roleCount)) {
            revert InvalidRoleAdmins();
        }

        if (!roleExists(roleId)) {
            revert UnexistentRole(roleId);
        }

        if (roleId == SAFE_OWNER_ROLE_ID) {
            revert UnauthorizedNotAdmin(SAFE_OWNER_ROLE_ID);
        }

        if (roleId == ROOT_ROLE_ID) {
            // Root role is treated as a special case. Only root role admins can change it
            if (!isRoleAdmin(_msgSender(), ROOT_ROLE_ID)) {
                revert UnauthorizedNotAdmin(ROOT_ROLE_ID);
            }
        } else {
            // For all other roles, the general role manager role can change any roles admins
            if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
                revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
            }
        }

        getRoleAdmins[roleId] = roleAdmins;

        emit RoleAdminsSet(roleId, roleAdmins, _msgSender());
    }

    /**
     * @notice Changes the name of a role
     * @dev Requires the sender to hold the Role Manager role
     * @param roleId ID of the role
     * @param name New name for the role
     */
    function setRoleName(uint8 roleId, string memory name) external {
        if (!roleExists(roleId)) {
            revert UnexistentRole(roleId);
        }

        address sender = _msgSender();
        if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
            revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
        }

        emit RoleNameChanged(roleId, name, sender);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // USER ROLE MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Grants or revokes a role for a user
     * @dev Requires the sender to hold a role that is an admin for the role being set
     * @param user Address being granted or revoked the role
     * @param roleId ID of the role being granted or revoked
     * @param isGrant Whether the role is being granted or revoked
     */
    function setRole(address user, uint8 roleId, bool isGrant) external {
        if (roleId == SAFE_OWNER_ROLE_ID) {
            revert UnauthorizedNotAdmin(SAFE_OWNER_ROLE_ID);
        }

        bytes32 oldUserRoles = getUserRoles[user];
        bytes32 newUserRoles = oldUserRoles;

        address sender = _msgSender();
        // Implicitly checks that roleId had been created
        if (!_isRoleAdmin(sender, getUserRoles[sender], roleId)) {
            revert UnauthorizedNotAdmin(roleId);
        }

        if (isGrant) {
            newUserRoles |= bytes32(1 << roleId);
        } else {
            newUserRoles &= ~bytes32(1 << roleId);
        }

        getUserRoles[user] = newUserRoles;

        emit UserRolesChanged(user, oldUserRoles, newUserRoles, sender);
    }

    /**
     * @notice Grants and revokes a set of role for a user
     * @dev Requires the sender to hold roles that can admin all roles being set
     * @param user Address being granted or revoked the roles
     * @param grantingRoles ID of all roles being granted
     * @param revokingRoles ID of all roles being revoked
     */
    function setRoles(address user, uint8[] memory grantingRoles, uint8[] memory revokingRoles) external {
        address sender = _msgSender();
        bytes32 senderRoles = getUserRoles[sender];
        bytes32 oldUserRoles = getUserRoles[user];
        bytes32 newUserRoles = oldUserRoles;

        uint256 grantsLength = grantingRoles.length;
        for (uint256 i = 0; i < grantsLength;) {
            uint8 roleId = grantingRoles[i];
            if (roleId == SAFE_OWNER_ROLE_ID || !_isRoleAdmin(sender, senderRoles, roleId)) {
                revert UnauthorizedNotAdmin(roleId);
            }

            newUserRoles |= bytes32(1 << roleId);
            unchecked {
                i++;
            }
        }

        uint256 revokesLength = revokingRoles.length;
        for (uint256 i = 0; i < revokesLength;) {
            uint8 roleId = revokingRoles[i];
            if (roleId == SAFE_OWNER_ROLE_ID || !_isRoleAdmin(sender, senderRoles, roleId)) {
                revert UnauthorizedNotAdmin(roleId);
            }

            newUserRoles &= ~(bytes32(1 << roleId));
            unchecked {
                i++;
            }
        }

        getUserRoles[user] = newUserRoles;

        emit UserRolesChanged(user, oldUserRoles, newUserRoles, sender);
    }

    /**
     * @notice Checks whether a user holds a particular role
     * @param user Address being checked for if it holds the role
     * @param roleId ID of the role being checked
     * @return True if the user holds the role or has the root role
     */
    function hasRole(address user, uint8 roleId) public view returns (bool) {
        if (roleId == SAFE_OWNER_ROLE_ID) {
            return safe().isOwner(user) || _hasRootRole(getUserRoles[user]);
        }

        bytes32 userRoles = getUserRoles[user];
        // either user has the specified role or user has root role (whichs gives it permission to do anything)
        // Note: For root it will return true even if the role hasn't been created yet
        return uint256(userRoles >> roleId) & 1 != 0 || isRoleAdmin(user, roleId);
    }

    /**
     * @notice Checks whether a user has a role that can admin a particular role
     * @param user Address being checked for admin rights over the role
     * @param roleId ID of the role being checked
     * @return True if the user has admin rights over the role
     */
    function isRoleAdmin(address user, uint8 roleId) public view returns (bool) {
        // Safe owner role has no admin as it is a dynamic role (assigned and revoked by the Safe)
        return roleId < SAFE_OWNER_ROLE_ID ? _isRoleAdmin(user, getUserRoles[user], roleId) : false;
    }

    /**
     * @notice Checks whether a role exists
     * @param roleId ID of the role being checked
     * @return True if the role has been created
     */
    function roleExists(uint8 roleId) public view returns (bool) {
        return roleId == ROOT_ROLE_ID // Root role is allowed to be left without admins
            || roleId == SAFE_OWNER_ROLE_ID // Safe owner role doesn't have admins as it is a dynamic role
            || getRoleAdmins[roleId] != NO_ROLE_ADMINS; // All other roles must have admins if they exist
    }

    function _isRoleAdmin(address user, bytes32 userRoles, uint8 roleId) internal view returns (bool) {
        bytes32 roleAdmins = getRoleAdmins[roleId];

        // A user is considered an admin of a role if any of the following are true:
        // - User explicitly has a role that is an admin of the role
        // - User has the root role, the role exists, and the role checked is not the root role (allows for root to be left without admins)
        // - User is an owner of the safe and the safe owner role is an admin of the role

        return (userRoles & roleAdmins) != 0
            || (_hasRootRole(userRoles) && roleExists(roleId) && roleId != ROOT_ROLE_ID)
            || (uint256(roleAdmins >> SAFE_OWNER_ROLE_ID) & 1 != 0 && safe().isOwner(user));
    }

    function _hasRootRole(bytes32 userRoles) internal pure returns (bool) {
        // Since root role is always at ID 0, we don't need to shift
        return uint256(userRoles) & 1 != 0;
    }

    function _allRoleAdminsExist(bytes32 roleAdmins, uint256 _roleCount) internal pure returns (bool) {
        // Since the last roleId always exists, we remove that bit from the roleAdmins
        return uint256(roleAdmins & SAFE_OWNER_ROLE_MASK) < (1 << _roleCount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint8 constant ROOT_ROLE_ID = 0;
uint8 constant ROLE_MANAGER_ROLE_ID = 1;
// The last possible role is an unassingable role which is dynamic
// and having it or not depends on whether the user is an owner in the Safe
uint8 constant SAFE_OWNER_ROLE_ID = 255;

bytes32 constant ONLY_ROOT_ROLE_AS_ADMIN = bytes32(uint256(1));
bytes32 constant NO_ROLE_ADMINS = bytes32(0);

interface IRoles {
    function roleExists(uint8 roleId) external view returns (bool);
    function hasRole(address user, uint8 roleId) external view returns (bool);
}