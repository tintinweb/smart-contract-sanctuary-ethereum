// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "./AdminPrivileges.sol";
import "./interfaces/IStakingPool.sol";

/**
 * @title StakingPool
 * @author Tim Loh
 * @notice Contains the staking pool configs used by StakingService
 */
contract StakingPool is AdminPrivileges, IStakingPool {
    struct StakingPoolInfo {
        uint256 stakeDurationDays;
        address stakeTokenAddress;
        uint256 stakeTokenDecimals;
        address rewardTokenAddress;
        uint256 rewardTokenDecimals;
        uint256 poolAprWei; // pool APR in Wei
        bool isOpen; // true if staking pool allows staking
        bool isActive; // true if staking pool allows claim rewards and unstake
        bool isInitialized; // true if staking pool has been initialized
    }

    uint256 public constant TOKEN_MAX_DECIMALS = 18;

    mapping(bytes32 => StakingPoolInfo) private _stakingPools;

    /**
     * @inheritdoc IStakingPool
     */
    function closeStakingPool(bytes32 poolId)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");
        require(_stakingPools[poolId].isOpen, "SPool: closed");

        _stakingPools[poolId].isOpen = false;

        emit StakingPoolClosed(poolId, msg.sender);
    }

    /**
     * @inheritdoc IStakingPool
     */
    function createStakingPool(
        bytes32 poolId,
        uint256 stakeDurationDays,
        address stakeTokenAddress,
        uint256 stakeTokenDecimals,
        address rewardTokenAddress,
        uint256 rewardTokenDecimals,
        uint256 poolAprWei
    ) external virtual override onlyRole(CONTRACT_ADMIN_ROLE) {
        require(stakeDurationDays > 0, "SPool: stake duration");
        require(stakeTokenAddress != address(0), "SPool: stake token");
        require(
            stakeTokenDecimals <= TOKEN_MAX_DECIMALS,
            "SPool: stake decimals"
        );
        require(rewardTokenAddress != address(0), "SPool: reward token");
        require(
            rewardTokenDecimals <= TOKEN_MAX_DECIMALS,
            "SPool: reward decimals"
        );
        require(
            stakeTokenAddress != rewardTokenAddress ||
                stakeTokenDecimals == rewardTokenDecimals,
            "SPool: decimals different"
        );
        require(poolAprWei > 0, "SPool: pool APR");

        require(!_stakingPools[poolId].isInitialized, "SPool: exists");

        _stakingPools[poolId] = StakingPoolInfo({
            stakeDurationDays: stakeDurationDays,
            stakeTokenAddress: stakeTokenAddress,
            stakeTokenDecimals: stakeTokenDecimals,
            rewardTokenAddress: rewardTokenAddress,
            rewardTokenDecimals: rewardTokenDecimals,
            poolAprWei: poolAprWei,
            isOpen: true,
            isActive: true,
            isInitialized: true
        });

        emit StakingPoolCreated(
            poolId,
            msg.sender,
            stakeDurationDays,
            stakeTokenAddress,
            stakeTokenDecimals,
            rewardTokenAddress,
            rewardTokenDecimals,
            poolAprWei
        );
    }

    /**
     * @inheritdoc IStakingPool
     */
    function openStakingPool(bytes32 poolId)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");
        require(!_stakingPools[poolId].isOpen, "SPool: opened");

        _stakingPools[poolId].isOpen = true;

        emit StakingPoolOpened(poolId, msg.sender);
    }

    /**
     * @inheritdoc IStakingPool
     */
    function resumeStakingPool(bytes32 poolId)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");
        require(!_stakingPools[poolId].isActive, "SPool: active");

        _stakingPools[poolId].isActive = true;

        emit StakingPoolResumed(poolId, msg.sender);
    }

    /**
     * @inheritdoc IStakingPool
     */
    function suspendStakingPool(bytes32 poolId)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");
        require(_stakingPools[poolId].isActive, "SPool: suspended");

        _stakingPools[poolId].isActive = false;

        emit StakingPoolSuspended(poolId, msg.sender);
    }

    /**
     * @inheritdoc IStakingPool
     */
    function getStakingPoolInfo(bytes32 poolId)
        external
        view
        virtual
        override
        returns (
            uint256 stakeDurationDays,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            uint256 poolAprWei,
            bool isOpen,
            bool isActive
        )
    {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");

        stakeDurationDays = _stakingPools[poolId].stakeDurationDays;
        stakeTokenAddress = _stakingPools[poolId].stakeTokenAddress;
        stakeTokenDecimals = _stakingPools[poolId].stakeTokenDecimals;
        rewardTokenAddress = _stakingPools[poolId].rewardTokenAddress;
        rewardTokenDecimals = _stakingPools[poolId].rewardTokenDecimals;
        poolAprWei = _stakingPools[poolId].poolAprWei;
        isOpen = _stakingPools[poolId].isOpen;
        isActive = _stakingPools[poolId].isActive;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AdminPrivileges
 * @author Tim Loh
 * @notice Provides role definitions that are inherited by other contracts and grants the owner all the defined roles
 */
contract AdminPrivileges is AccessControl {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender);
        _grantRole(CONTRACT_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title StakingPool Interface
 * @author Tim Loh
 * @notice Interface for StakingPool which contains the staking pool configs used by StakingService
 */
interface IStakingPool is IAccessControl {
    /**
     * @notice Emitted when a staking pool has been closed
     * @param poolId The staking pool identifier
     * @param sender The address that closed the staking pool
     */
    event StakingPoolClosed(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been created
     * @param poolId The staking pool identifier
     * @param sender The address that created the staking pool
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @param stakeTokenDecimals The ERC20 stake token decimal places
     * @param rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @param rewardTokenDecimals The ERC20 reward token decimal places
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     */
    event StakingPoolCreated(
        bytes32 indexed poolId,
        address indexed sender,
        uint256 indexed stakeDurationDays,
        address stakeTokenAddress,
        uint256 stakeTokenDecimals,
        address rewardTokenAddress,
        uint256 rewardTokenDecimals,
        uint256 poolAprWei
    );

    /**
     * @notice Emitted when a staking pool has been opened
     * @param poolId The staking pool identifier
     * @param sender The address that opened the staking pool
     */
    event StakingPoolOpened(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been resumed
     * @param poolId The staking pool identifier
     * @param sender The address that resumed the staking pool
     */
    event StakingPoolResumed(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been suspended
     * @param poolId The staking pool identifier
     * @param sender The address that suspended the staking pool
     */
    event StakingPoolSuspended(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Closes the given staking pool to reject user stakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function closeStakingPool(bytes32 poolId) external;

    /**
     * @notice Creates a staking pool for the given pool identifier and config
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @param stakeTokenDecimals The ERC20 stake token decimal places
     * @param rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @param rewardTokenDecimals The ERC20 reward token decimal places
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     */
    function createStakingPool(
        bytes32 poolId,
        uint256 stakeDurationDays,
        address stakeTokenAddress,
        uint256 stakeTokenDecimals,
        address rewardTokenAddress,
        uint256 rewardTokenDecimals,
        uint256 poolAprWei
    ) external;

    /**
     * @notice Opens the given staking pool to accept user stakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function openStakingPool(bytes32 poolId) external;

    /**
     * @notice Resumes the given staking pool to allow user reward claims and unstakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function resumeStakingPool(bytes32 poolId) external;

    /**
     * @notice Suspends the given staking pool to prevent user reward claims and unstakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function suspendStakingPool(bytes32 poolId) external;

    /**
     * @notice Returns the given staking pool info
     * @param poolId The staking pool identifier
     * @return stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @return stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @return stakeTokenDecimals The ERC20 stake token decimal places
     * @return rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @return rewardTokenDecimals The ERC20 reward token decimal places
     * @return poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @return isOpen True if staking pool is open to accept user stakes
     * @return isActive True if user is allowed to claim reward and unstake from staking pool
     */
    function getStakingPoolInfo(bytes32 poolId)
        external
        view
        returns (
            uint256 stakeDurationDays,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            uint256 poolAprWei,
            bool isOpen,
            bool isActive
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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