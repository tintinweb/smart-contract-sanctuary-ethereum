// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IOwnableInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenZeppelin Ownable functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IOwnableInitializer is IERC165 {

    /**
     * @notice Initializes the contract owner to the specified address
     */
    function initializeOwner(address owner_) external;

    /**
     * @notice Transfers ownership of the contract to the specified owner
     */
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@limit-break/initializable/IOwnableInitializer.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "src/libraries/access/LibAccessControl.sol";
import "src/libraries/cloner/LibCloner.sol";
import "src/utils/InitializableDiamond.sol";

/**
 * @title ClonerFacet
 * @author Limit Break, Inc.
 * @notice Clone Factory Facet for use in deploying general purpose ERC-1167 Minimal Proxy Clones
 * @notice See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
contract ClonerFacet is Context, InitializableDiamond {

    error ClonerFacet__CallerDoesNotHaveAdminRole();
    error ClonerFacet__CannotTransferAdminRoleToSelf();
    error ClonerFacet__CannotTransferAdminRoleToZeroAddress();
    error ClonerFacet__InitializationArrayLengthMismatch();
    error ClonerFacet__InitializationArgumentInvalid(uint256 arrayIndex);
    error ClonerFacet__ReferenceContractHasNoBytecode();

    ///@notice Value defining the `Cloner Admin Role`.
    bytes32 public constant CLONER_ADMIN_ROLE = keccak256("CLONER_ADMIN_ROLE");

    /// @dev Address of the Cloner facet - used for initialization and set in constructor
    /// @dev Since we're unable to reference the contract in address(this) due to delegate call, we use this constant
    address private immutable CLONER_ADDRESS;

    /// @notice Emitted when a new clone has been created
    event CloneCreated(address indexed referenceContractAddress, address indexed cloneAddress);

    constructor() {
        CLONER_ADDRESS = address(this);
    }

    /**
     * @notice Initializer function to ensure that clones are grant the correct admin role to the deployer
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. `CLONER_ADMIN_ROLE` is granted to the `msg.sender`
     * @dev    2. `_initialized` is set to 1, preventing further initializations in the future.
     */
    function __ClonerFacet_init() public initializer(CLONER_ADDRESS) {
        LibAccessControl._setAdminRole(CLONER_ADMIN_ROLE, CLONER_ADMIN_ROLE);
        LibAccessControl._grantRole(CLONER_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Allows the current contract admin to transfer the `Admin Role` to a new address.
     *
     * @dev    Throws if newAdmin is the zero-address
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the caller is an admin and tries to transfer admin to itself.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The new admin has been granted the `Admin Role`.
     * @dev    2. The caller/former admin has had `Admin Role` revoked.
     *
     * @param  newAdmin Address of the new admin user.
     */
    function transferClonerAdminRole(address newAdmin) external {
        _requireCallerIsAdmin();

        if (newAdmin == address(0)) {
            revert ClonerFacet__CannotTransferAdminRoleToZeroAddress();
        }

        if (newAdmin == _msgSender()) {
            revert ClonerFacet__CannotTransferAdminRoleToSelf();
        }

        LibAccessControl._revokeRole(CLONER_ADMIN_ROLE, _msgSender());
        LibAccessControl._grantRole(CLONER_ADMIN_ROLE, newAdmin);
    }

    /**
     * @notice Allows the current contract admin to revoke the `Admin Role` from a user.
     *
     * @dev    Throws if the caller is not the current admin.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The admin role has been revoked from the specified user.
     *
     * @param  admin Address of the user to revoke admin from.
     */
    function revokeClonerAdminRole(address admin) external {
        _requireCallerIsAdmin();

        LibAccessControl.revokeRole(CLONER_ADMIN_ROLE, admin);
    }

    /**
     * @notice Allows the current contract admin to grant the `Admin Role` to a user.
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the new admin is address zero.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The admin role has been granted to the specified user.
     *
     * @param  admin Address of the user to grant admin to.
     */
    function grantClonerAdminRole(address admin) external {
        _requireCallerIsAdmin();

        if (admin == address(0)) {
            revert ClonerFacet__CannotTransferAdminRoleToZeroAddress();
        }

        LibAccessControl.grantRole(CLONER_ADMIN_ROLE, admin);
    }

    /**
     * @notice Deploys a new ERC-1167 Minimal Proxy Contract based on the provided reference contract.
     * @dev    The optional initialization selectors and arguments should be provided to atomically
     * @dev    initialize the deployed contract.  If no initialization is required, these can be empty arrays.
     *
     * @dev    Throws when the provided initializer selectors and args arrays are different lengths
     * @dev    Throws when invalide initializer arguments or selectors are provided
     * @dev    Throws when the contract does not support the `IOwnableInitializer` interface
     * @dev    Throws when the reference contract is not a whitelisted clonable contract
     * @dev      - This is to prevent phishing attacks using the cloner contract to deploy malicious contracts
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. A new ERC-1167 Proxy has been cloned and initialized
     * @dev    2. The new contract is owned by the specified `contractOwner` value
     * @dev    3. A `CloneCreated` event has been emitted
     *
     * @param  referenceContract       Reference contract to clone
     * @param  contractOwner           Address that should be assigned ownership of the deployed clone contract
     * @param  initializationSelectors An array of 4 byte selectors to be called during initialization
     * @param  initializationArgs      An array of ABI encoded calldata to be used with the provided selectors
     */
    function cloneContract(
        address referenceContract,
        address contractOwner,
        bytes4[] calldata initializationSelectors,
        bytes[] calldata initializationArgs
    ) external returns (address) {
        LibCloner._requireIsWhitelisted(referenceContract);
        _requireArrayLengthsMatch(initializationSelectors.length, initializationArgs.length);

        address clone = Clones.clone(referenceContract);

        emit CloneCreated(referenceContract, clone);

        IOwnableInitializer(clone).initializeOwner(address(this));

        for (uint256 i = 0; i < initializationSelectors.length;) {
            (bool success,) = clone.call(abi.encodePacked(initializationSelectors[i], initializationArgs[i]));

            if (!success) {
                revert ClonerFacet__InitializationArgumentInvalid(i);
            }

            unchecked {
                ++i;
            }
        }

        IOwnableInitializer(clone).transferOwnership(contractOwner);

        return clone;
    }

    /**
     * @notice Whitelists a reference contract as a clonable contract
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the reference contract does not contain code
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The reference contract is now whitelisted as a clonable contract
     *
     * @param  referenceContract Address of the reference contract to whitelist
     */
    function whitelistReferenceContract(address referenceContract) external {
        _requireCallerIsAdmin();
        LibCloner._whitelistReferenceContract(referenceContract);
    }

    /**
     * @notice Deprecates a whitelisted reference contract
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the reference contract is not whitelisted
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The reference contract is no longer whitelisted as a clonable contract
     *
     * @param  referenceContract Address of the reference contract to remove from the whitelist
     */
    function unwhitelistReferenceContract(address referenceContract) external {
        _requireCallerIsAdmin();
        LibCloner._unwhitelistReferenceContract(referenceContract);
    }

    /// @notice Returns if the provided account is assigned the `CLONER_ADMIN_ROLE`
    function isClonerAdmin(address account) external view returns (bool) {
        return LibAccessControl.hasRole(CLONER_ADMIN_ROLE, account);
    }

    /// @notice Returns if the provided reference contract is whitelisted as a clonable contract
    function isWhitelistedReferenceContract(address referenceContract) external view returns (bool) {
        return LibCloner._isWhitelisted(referenceContract);
    }

    /// @dev Validates that the msg.sender has the `CLONER_ADMIN_ROLE` assigned.
    function _requireCallerIsAdmin() internal view {
        if (!LibAccessControl.hasRole(CLONER_ADMIN_ROLE, _msgSender())) {
            revert ClonerFacet__CallerDoesNotHaveAdminRole();
        }
    }

    /// @dev Validates that the provided array lengths are the same.
    function _requireArrayLengthsMatch(uint256 arrayLength1, uint256 arrayLength2) internal pure {
        if (arrayLength1 != arrayLength2) {
            revert ClonerFacet__InitializationArrayLengthMismatch();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

library LibAccessControl {

    error AccessControl__MissingRole(bytes32 role);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessControlStorage {
        mapping(bytes32 => RoleData) _roles;
    }

    /// @dev Storage slot to use for Access Control specific storage
    bytes32 internal constant STORAGE_SLOT = keccak256("adventurehub.storage.AccessControl");

    /// @dev Default admin role identifier
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
    /// @dev `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite {RoleAdminChanged} not being emitted signaling this.
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

     /// @dev Emitted when `account` is granted `role`.
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /// @dev Emitted when `account` is revoked `role`.
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /// @dev Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return accessControlStorage()._roles[role].members[account];
    }

    /// @notice Returns the admin role that controls the provided `role`
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return accessControlStorage()._roles[role].adminRole;
    }

    /**
     * @notice Grants `role` to `account`.
     *
     * @dev    Throws if `msg.sender` is not the admin of `role`.
     * @dev    No-op if `account` already has `role`.
     * 
     * @dev    <h4>Postconditions</h4>
     * @dev    1. If `account` does not have `role`, emits a {RoleGranted} event.
     * @dev    2. If `account` does not have `role`, `account` has `role`.
     */
    function grantRole(bytes32 role, address account) external {
        _checkRole(getRoleAdmin(role));
        _grantRole(role, account);
    }

    /**
     * @notice Revokes `role` from `account`.
     *
     * @dev    Throws if `msg.sender` is not the admin of `role`.
     * @dev    No-op if `account` does not have `role`.
     * 
     * @dev    <h4>Postconditions</h4>
     * @dev    1. If `account` has `role`, emits a {RoleRevoked} event.
     * @dev    2. If `account` has `role`, `role` is removed from `account`.
     */
    function revokeRole(bytes32 role, address account) external {
        _checkRole(getRoleAdmin(role));
        _revokeRole(role, account);
    }

    /**
     * @notice Sets `adminRole` as ``role``'s admin role.
     *
     * @dev   <h4>Postconditions</h4>
     * @dev   1. Emits a {RoleAdminChanged} event.
     * @dev   2. `role`'s admin role is `adminRole`.
     */
    function _setAdminRole(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        accessControlStorage()._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     * @dev Internal function without access restriction.
     *
     * @dev Emits a {RoleGranted} event if the account did not already have the role.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            accessControlStorage()._roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     * @dev Internal function without access restriction.
     *
     * @dev Emits a RoleRevoked event if the account had the role.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            accessControlStorage()._roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /// @dev Revert with a standard message if `msg.sender` is missing `role`.
    function _checkRole(bytes32 role) internal view {
        _checkRole(role, msg.sender);
    }

    /// @dev Revert with a standard message if `account` is missing `role`.
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert AccessControl__MissingRole(role);
        }
    }

    /// @dev Returns the storage data stored at the `STORAGE_SLOT`
    function accessControlStorage() internal pure returns (AccessControlStorage storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibCloner {

    struct ClonerStorage {
        mapping(address => bool) isWhitelisted;
    }

    error ClonerStorage__ReferenceContractAlreadyWhitelisted();
    error ClonerStorage__ReferenceContractMustContainCode();
    error ClonerStorage__ReferenceContractNotWhitelisted();

    /// @dev Storage slot to use for Cloner Facet specific storage
    bytes32 internal constant STORAGE_SLOT = keccak256("adventurehub.storage.Cloner");

    /// @dev Returns if a reference contract is whitelisted
    function _isWhitelisted(address referenceContract) internal view returns (bool) {
        ClonerStorage storage cs = clonerStorage();

        return cs.isWhitelisted[referenceContract];
    }

    /// @dev Whitelists a provided reference contract
    function _whitelistReferenceContract(address referenceContract) internal {
        ClonerStorage storage cs = clonerStorage();

        if(cs.isWhitelisted[referenceContract]) {
            revert ClonerStorage__ReferenceContractAlreadyWhitelisted();
        }

        cs.isWhitelisted[referenceContract] = true;
    }

    /// @dev Deprecates a whitelisted reference contract
    function _unwhitelistReferenceContract(address referenceContract) internal {
        ClonerStorage storage cs = clonerStorage();

        if(!cs.isWhitelisted[referenceContract]) {
            revert ClonerStorage__ReferenceContractNotWhitelisted();
        }

        cs.isWhitelisted[referenceContract] = false;
    }

    /// @dev Enforces a reference contract is whitelisted
    function _requireIsWhitelisted(address referenceContract) internal view {
        ClonerStorage storage cs = clonerStorage();

        if (!cs.isWhitelisted[referenceContract]) {
            revert ClonerStorage__ReferenceContractNotWhitelisted();
        }
    }

    /// @dev Returns the storage data stored at the `STORAGE_SLOT`
    function clonerStorage() internal pure returns (ClonerStorage storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibInitializer {
    
    error Initializable__ContractIsNotInitializing();

    struct InitializerStorage {
        mapping(address => uint8) _initialized;
        mapping(address => bool) _initializing;
    }

    /// @dev Storage slot to use for Access Control specific storage
    bytes32 internal constant STORAGE_SLOT = keccak256("adventurehub.storage.Initializer");

    /// @dev Emitted when the contract has been initialized or reinitialized.
    event Initialized(uint8 version);

    /**
     * @dev Enforces that a function can only be invoked by functions during initialization
     */
    function _requireInitializing(address initContract) internal view {
        if(!initializerStorage()._initializing[initContract]) {
            revert Initializable__ContractIsNotInitializing();
        }
    }

    /// @dev Sets values to protect functions during initialization
    function _beforeInitializer(uint8 version, address initContract) internal {
        require(
            !initializerStorage()._initializing[initContract] && initializerStorage()._initialized[initContract] < version, "Initializable: contract is already initialized"
        );
        initializerStorage()._initialized[initContract] = version;
        initializerStorage()._initializing[initContract] = true;
    }

    /// @dev Unsets values after initialization functions are complete
    function _afterInitializer(uint8 version, address initContract) internal {
        if (initializerStorage()._initializing[initContract]) {
            initializerStorage()._initializing[initContract] = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * @dev Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * @dev to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * @dev through proxies.
     *
     * @dev Throws if the contract is currently initializing.
     * @dev No-op if the contract has already been locked.
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. Emits an Initialized event.
     * @dev 2. The `_initialized` is set to `type(uint8).max`, locking the contract.
     */
    function _disableInitializers(address initContract) internal {
        require(!initializerStorage()._initializing[initContract], "Initializable: contract is initializing");
        if (initializerStorage()._initialized[initContract] < type(uint8).max) {
            initializerStorage()._initialized[initContract] = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /// @dev Returns the highest version that has been initialized
    function _getInitializedVersion(address initContract) internal view returns (uint8) {
        return initializerStorage()._initialized[initContract];
    }

    /// @dev Returns `true` if the contract is currently initializing, false if not.
    function _isInitializing(address initContract) internal view returns (bool) {
        return initializerStorage()._initializing[initContract];
    }

    /// @dev Returns the storage data stored at the `STORAGE_SLOT`
    function initializerStorage() internal pure returns (InitializerStorage storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)
pragma solidity 0.8.9;

import "src/libraries/initialization/LibInitializer.sol";

/**
 * @dev External interface of LibInitializer
 */
abstract contract InitializableDiamond {
    /// @dev Emitted when the contract has been initialized or reinitialized.
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * @dev `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * @dev Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * @dev constructor.
     *
     * @dev Emits an {Initialized} event.
     */
    modifier initializer(address initContract) {
        LibInitializer._beforeInitializer(1, initContract);
        _;
        LibInitializer._afterInitializer(1, initContract);
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * @dev contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * @dev used to initialize parent contracts.
     *
     * @dev A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * @dev are added through upgrades and that require initialization.
     *
     * @dev When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * @dev cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * @dev Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * @dev a contract, executing them in the right order is up to the developer or operator.
     *
     * @dev WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * @dev Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version, address initContract) {
        LibInitializer._beforeInitializer(version, initContract);
        _;
        LibInitializer._afterInitializer(version, initContract);        
    }

    /**
     * @dev A modifier that requires the function to be invoked during initialization. This is useful to prevent
     * @dev initialization functions from being invoked by users or other contracts.
     */
    modifier onlyInitializing(address initContract) {
        LibInitializer._requireInitializing(initContract);
        _;
    }
}