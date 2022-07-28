// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";
import "./interfaces/IAuthProvider.sol";
import "./factory/ContractsFactory.sol";

/**
 * @dev This contract stores information about system contract names
 * and Registry Contract address. This contract should be inherited by
 * any contract in our network, which should call other contracts by their
 * identifiers
 *
 * Provides shared context for all contracts in our network
 */

contract System is ContractsFactory, IAuthProvider {
    // system contracts
    bytes32 public constant AUTH_CONTRACT = keccak256("AUTH_CONTRACT");

    IRegistry public registry;
    System public parentSystem;
    IAccessControl public contractControlList;

    constructor(IRegistry registry_, IAccessControl contractControlList_, System parentSystem_) {
        registry = registry_;
        contractControlList = contractControlList_;
        parentSystem = parentSystem_;
        registry.setRecord(AUTH_CONTRACT, address(this), address(contractControlList));
    }

    modifier onlyGameOwner() {
        require(isGameOwner(msg.sender) || isSystemOwner(msg.sender), "ContractsFactory: Only game owner");
        _;
    }

    modifier onlySystemOwner() {
        require(isSystemOwner(msg.sender), "ContractsFactory: Only SYSTEM owner");
        _;
    }

    function isGameOwner(address account) public view override returns (bool) {
        return contractControlList.hasRole(0x0, account);
    }

    function isSystemOwner(address account) public view override returns (bool) {
        if (address(parentSystem) == address(0x0)) {
            return contractControlList.hasRole(0x0, account);
        }

        return parentSystem.isSystemOwner(account);
    }

    function getContractAddress(bytes32 node_)
        public
        view
        returns (address)
    {
        return registry.resolver(node_);
    }

    function getAuthContract() public view returns (IAuthProvider) {
        return IAuthProvider(getContractAddress(AUTH_CONTRACT));
    }

    function getRegistryContract() public view returns (IRegistry) {
        return registry;
    }

    function whitelistContractChecksum(bytes32 checksum) external override onlyGameOwner {
        return _addToWhitelist(checksum);
    }

    function removeWhitelistedContractChecksum(bytes32 checksum) external override onlyGameOwner {
        return _removeFromWhitelist(checksum);
    }

    function setContractControlList(ContractControlList contractControlList_) external onlyGameOwner {
        contractControlList = contractControlList_;
        registry.setResolver(AUTH_CONTRACT, address(contractControlList));
    }

    function setParentSystem(System parentFactory_) external onlySystemOwner {
        parentSystem = parentFactory_;
    }

    /**
    * @dev Returns true if contract checksum is whitelisted
     * @param checksum The user address
     */
    function isChecksumWhitelisted(bytes32 checksum) public view override returns (bool) {
        if (address(parentSystem) == address(0)) {
            return super.isChecksumWhitelisted(checksum);
        }

        return
        super.isChecksumWhitelisted(checksum) ||
        parentSystem.isChecksumWhitelisted(checksum);
    }

    function createContractInstance(
        string memory contractName,
        bytes memory bytecode,
        bytes memory constructorParams,
        bool register
    ) external override returns (address) {
        address newContractAddr = _createContractInstance(contractName, bytecode, constructorParams);
        if (register) {
            registry.setRecordByName(contractName, msg.sender, newContractAddr);
        }

        return newContractAddr;
    }

    function create2ContractInstance(
        string memory contractName,
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes memory salt,
        bool register
    ) external override returns(address) {
        address newContractAddr = _create2ContractInstance(contractName, bytecode, constructorParams, salt);
        if (register) {
            registry.setRecordByName(contractName, msg.sender, newContractAddr);
        }

        return newContractAddr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRegistry {
    // Logged when new record is created.
    event NewRecord(bytes32 indexed node, address owner, address resolver);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    function setRecord(
        bytes32 node_,
        address owner_,
        address resolver_
    ) external;
    function setRecordByName(
        string memory nodeName_,
        address owner_,
        address resolver_
    ) external;

    function setResolver(bytes32 node_, address resolver_) external;
    function setResolverByName(string memory nodeName_, address resolver_) external;

    function setOwner(bytes32 node_, address owner_) external;
    function setOwnerByName(string memory nodeName_, address owner_) external;

    function owner(bytes32 node_) external view returns (address);
    function ownerByName(string memory nodeName_) external view returns (address);

    function resolver(bytes32 node_) external view returns (address);
    function resolverByName(string memory nodeName_) external view returns (address);

    function recordExists(bytes32 node_) external view returns (bool);
    function recordExistsByName(string memory nodeName_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthProvider {
    function isGameOwner(address account) external returns (bool);

    function isSystemOwner(address account) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRegistry.sol";
import "./Whitelist.sol";
import "../System.sol";
import "../ContractControlList.sol";

/**
 * @dev This contract enables creation of assets smart contract instances
 */
abstract contract ContractsFactory is Whitelist {
    event CreatedContractInstance(
        string contractName,
        address contractAddress
    );

    modifier onlyWhitelisted(bytes memory bytecode_) {
        bytes32 _checksum = keccak256(bytecode_);
        require(
            isChecksumWhitelisted(_checksum),
            "Contract is not whitelisted. Check contract bytecode"
        );
        _;
    }

    function createContractInstance(
        string memory contractName,
        bytes memory bytecode,
        bytes memory constructorParams,
        bool register
    ) external virtual returns (address);

    /**
     * @dev Creates contract instance for whitelisted byteCode
     * @param contractName contract name
     * @param bytecode contract bytecode
     * @param constructorParams encoded constructor params
     */
    function _createContractInstance(
        string memory contractName,
        bytes memory bytecode,
        bytes memory constructorParams
    ) internal onlyWhitelisted(bytecode) returns (address) {
        bytes memory creationBytecode = abi.encodePacked(
            bytecode,
            constructorParams
        );

        address addr;
        assembly {
            addr := create(
                0,
                add(creationBytecode, 0x20),
                mload(creationBytecode)
            )
        }

        require(
            isContract(addr),
            "Contract was not been deployed. Check contract bytecode and contract params"
        );
        emit CreatedContractInstance(contractName, addr);

        return addr;
    }

    function create2ContractInstance(
        string memory contractName,
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes memory salt,
        bool register
    ) external virtual returns(address);

    function _create2ContractInstance(
        string memory contractName,
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes memory salt
    ) internal onlyWhitelisted(bytecode) returns (address) {
        bytes memory creationBytecode = abi.encodePacked(
            bytecode,
            constructorParams
        );

        address addr;
        assembly {
            addr := create2(
                0,
                add(creationBytecode, 0x20),
                mload(creationBytecode),
                salt
            )
        }

        require(
            isContract(addr),
            "Contract was not been deployed. Check contract bytecode and contract params"
        );
        emit CreatedContractInstance(contractName, addr);

        return addr;
    }

    /**
     * @dev Returns True if provided address is a contract
     * @param account Prospective contract address
     * @return True if there is a contract behind the provided address
     */
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Whitelist {
    /**
     * @dev Emitted when a contract checksum is added to the whitelist
     */
    event Whitelisted(bytes32 checksum);

    /**
     * @dev Emitted when a smart contract checksum is removed from the whitelist
     */
    event RemovedFromWhitelist(bytes32 checksum);

    mapping(bytes32 => bool) private whitelisted;

    /**
     * @dev Adds contract checksum to the whitelist.
     * @param checksum Checksum of the smart contract
     */
    function _addToWhitelist(bytes32 checksum) internal {
        require(
            !whitelisted[checksum],
            "Contract checksum is already whitelisted"
        );
        whitelisted[checksum] = true;

        emit Whitelisted(checksum);
    }

    /**
     * @dev Removes contract from the whitelist.
     * @param checksum of the smart contract
     */
    function _removeFromWhitelist(bytes32 checksum) internal {
        require(
            whitelisted[checksum],
            "Contract checksum not found in whitelist"
        );
        whitelisted[checksum] = false;

        emit RemovedFromWhitelist(checksum);
    }

    /**
     * @dev Returns true if contract checksum is whitelisted
     * @param checksum The user address
     */
    function isChecksumWhitelisted(bytes32 checksum)
        public
        view
        virtual
        returns (bool)
    {
        return whitelisted[checksum];
    }

    function whitelistContractChecksum(bytes32 checksum) external virtual;
    function removeWhitelistedContractChecksum(bytes32 checksum) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract ContractControlList is AccessControl {
    bytes32 public constant CONTROL_LIST_ADMIN_ROLE = keccak256("CONTROL_LIST_ADMIN_ROLE");

    bytes32 public constant LAND_ADMIN_ROLE = keccak256("LAND_ADMIN_ROLE");
    bytes32 public constant PIONEER_ADMIN_ROLE = keccak256("PIONEER_ADMIN_ROLE");
    bytes32 public constant ROYALTY_ADMIN_ROLE = keccak256("ROYALTY_ADMIN_ROLE");
    bytes32 public constant FACTORY_ADMIN_ROLE = keccak256("FACTORY_ADMIN_ROLE");

    bytes32 public constant LAND_MINTER_ROLE = keccak256("LAND_MINTER_ROLE");
    bytes32 public constant PIONEER_MINTER_ROLE = keccak256("PIONEER_MINTER_ROLE");
    bytes32 public constant ROYALTY_INFO_CHANGER_ROLE = keccak256("ROYALTY_INFO_CHANGER_ROLE");

    // Land, Pioneer and Founder contracts should have this role assigned for acl-s checks between them
    bytes32 public constant LAND_ROLE = keccak256("LAND_ROLE");
    bytes32 public constant PIONEER_ROLE = keccak256("PIONEER_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("PIONEER_ROLE");

    constructor(address admin_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTROL_LIST_ADMIN_ROLE, msg.sender);

        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
        _setupRole(LAND_ADMIN_ROLE, admin_);
        _setupRole(PIONEER_ADMIN_ROLE, admin_);
        _setupRole(ROYALTY_ADMIN_ROLE, admin_);
        _setupRole(FACTORY_ADMIN_ROLE, admin_);

        _setRoleAdmin(LAND_MINTER_ROLE, LAND_ADMIN_ROLE);
        _setRoleAdmin(LAND_ROLE, LAND_ADMIN_ROLE);
        _setRoleAdmin(PIONEER_MINTER_ROLE, PIONEER_ADMIN_ROLE);
        _setRoleAdmin(PIONEER_ROLE, PIONEER_ADMIN_ROLE);
        _setRoleAdmin(FOUNDER_ROLE, PIONEER_ADMIN_ROLE);
        _setRoleAdmin(ROYALTY_INFO_CHANGER_ROLE, ROYALTY_ADMIN_ROLE);
    }

    function checkRole(bytes32 role_, address account_) external view {
        return _checkRole(role_, account_);
    }

    function grantLandMinterRole(address addr_) external {
        grantRole(LAND_MINTER_ROLE, addr_);
    }

    function grantPioneerMinterRole(address addr_) external {
        grantRole(PIONEER_MINTER_ROLE, addr_);
    }

    function grantPioneerAdminRole(address addr_) external {
        grantRole(PIONEER_ADMIN_ROLE, addr_);
    }

    function grantLandAdminRole(address addr_) external {
        grantRole(LAND_ADMIN_ROLE, addr_);
    }

    function grantLandRole(address addr_) external {
        grantRole(LAND_ROLE, addr_);
    }

    function grantPioneerRole(address addr_) external {
        grantRole(PIONEER_ROLE, addr_);
    }

    function grantFounderRole(address addr_) external {
        grantRole(FOUNDER_ROLE, addr_);
    }

    function checkPioneerMinterRole(address addr_) external view {
        _checkRole(PIONEER_MINTER_ROLE, addr_);
    }

    function checkPioneerAdminRole(address addr_) external view {
        _checkRole(PIONEER_ADMIN_ROLE, addr_);
    }

    function checkLandMinterRole(address addr_) external view {
        _checkRole(LAND_MINTER_ROLE, addr_);
    }

    function checkLandAdminRole(address addr_) external view {
        _checkRole(LAND_ADMIN_ROLE, addr_);
    }

    function checkLandRole(address addr_) external view {
        _checkRole(LAND_ROLE, addr_);
    }

    function checkPioneerRole(address addr_) external view {
        _checkRole(PIONEER_ROLE, addr_);
    }

    function checkFounderRole(address addr_) external view {
        _checkRole(FOUNDER_ROLE, addr_);
    }

    function checkRoyaltyMinterChangerRole(address addr_) external view {
        _checkRole(ROYALTY_INFO_CHANGER_ROLE, addr_);
    }

    function checkAclAdminRole(address addr_) external view {
        _checkRole(CONTROL_LIST_ADMIN_ROLE, addr_);
    }

    function hasPioneerMinterRole(address addr) external view returns (bool) {
        return hasRole(PIONEER_MINTER_ROLE, addr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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