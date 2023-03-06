// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "../utils/SomaContract.sol";

import "./ISomaAccessControl.sol";

/**
 * @notice Implementation of the {ISomaAccessControl} interface.
 */
contract SomaAccessControl is ISomaAccessControl, SomaContract, AccessControl {
    /**
     * @notice Checks if SomaAccessControl inherits a given contract interface.
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, SomaContract)
        returns (bool)
    {
        return interfaceId == type(ISomaAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns `true` if `account` has been granted `role`.
     * @param role The role to check if the account has.
     * @param account The account to check the role against.
     * @return True if `account` has `role`, False if `account` does not have `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        // allow the subMaster to take control of the access control
        return super.hasRole(role, account) || SOMA.subMaster() == account;
    }

    /**
     * @inheritdoc ISomaAccessControl
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }
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

pragma solidity =0.8.18;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "../ISOMA.sol";
import "../SOMAlib.sol";

import "./ISomaContract.sol";

contract SomaContract is ISomaContract, Pausable, ERC165, Multicall {
    event Initialized(uint8 version);

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ISOMA public immutable override SOMA = SOMAlib.SOMA;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // matching the openzeppelin reinitializer
        emit Initialized(1);
    }

    modifier onlyMaster() {
        address sender = _msgSender();
        require(SOMA.master() == sender, "SOMA: MASTER");
        _;
    }

    modifier onlyMasterOrSubMaster() {
        address sender = _msgSender();
        require(SOMA.master() == sender || SOMA.subMaster() == sender, "SOMA: MASTER or SUB MASTER only");
        _;
    }

    function pause() external virtual override onlyMasterOrSubMaster {
        _pause();
    }

    function unpause() external virtual override onlyMasterOrSubMaster {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ISomaContract).interfaceId || super.supportsInterface(interfaceId);
    }

    function paused() public view virtual override returns (bool) {
        return Pausable(address(SOMA)).paused() || super.paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title SOMA Access Control Contract.
 * @author SOMA.finance.
 * @notice An access control contract that establishes a hierarchy of accounts and controls
 * function call permissions.
 */
interface ISomaAccessControl {
    /**
     * @notice Sets the admin of a role.
     * @dev Sets the admin for the `role` role.
     * @param role The role to set the admin role of.
     * @param adminRole The admin of `role`.
     * @custom:emits RoleAdminChanged
     * @custom:requirement The function caller must have the DEFAULT_ADMIN_ROLE.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SomaAccessControl/ISomaAccessControl.sol";
import "./SomaSwap/periphery/ISomaSwapRouter.sol";
import "./SomaSwap/core/interfaces/ISomaSwapFactory.sol";
import "./SomaGuard/ISomaGuard.sol";
import "./TemplateFactory/ITemplateFactory.sol";
import "./Lockdrop/ILockdropFactory.sol";

/**
 * @title SOMA Contract.
 * @author SOMA.finance
 * @notice Interface of the SOMA contract.
 */
interface ISOMA {
    /**
     * @notice Emitted when the SOMA snapshot is updated.
     * @param version The version of the new snapshot.
     * @param hash The hash of the new snapshot.
     * @param snapshot The new snapshot.
     */
    event SOMAUpgraded(bytes32 indexed version, bytes32 indexed hash, bytes snapshot);

    /**
     * @notice Emitted when the `seizeTo` address is updated.
     * @param prevSeizeTo The address of the previous `seizeTo`.
     * @param newSeizeTo The address of the new `seizeTo`.
     * @param sender The address of the message sender.
     */
    event SeizeToUpdated(address indexed prevSeizeTo, address indexed newSeizeTo, address indexed sender);

    /**
     * @notice Emitted when the `mintTo` address is updated.
     * @param prevMintTo The address of the previous `mintTo`.
     * @param newMintTo The address of the new `mintTo`.
     * @param sender The address of the message sender.
     */
    event MintToUpdated(address indexed prevMintTo, address indexed newMintTo, address indexed sender);

    /**
     * @notice Snapshot of the SOMA contracts.
     * @param master The master address.
     * @param subMaster The subMaster address.
     * @param access The ISomaAccessControl contract.
     * @param guard The ISomaGuard contract.
     * @param factory The ITemplateFactory contract.
     * @param token The IERC20 contract.
     */
    struct Snapshot {
        address master;
        address subMaster;
        address access;
        address guard;
        address factory;
        address token;
    }

    /**
     * @notice Returns the address that has been assigned the master role.
     */
    function master() external view returns (address);

    /**
     * @notice Returns the address that has been assigned the subMaster role.
     */
    function subMaster() external view returns (address);

    /**
     * @notice Returns the address of the {ISomaAccessControl} contract.
     */
    function access() external view returns (address);

    /**
     * @notice Returns the address of the {ISomaGuard} contract.
     */
    function guard() external view returns (address);

    /**
     * @notice Returns the address of the {ITemplateFactory} contract.
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the address of the {IERC20} contract.
     */
    function token() external view returns (address);

    /**
     * @notice Returns the hash of the latest snapshot.
     */
    function snapshotHash() external view returns (bytes32);

    /**
     * @notice Returns the latest snapshot version.
     */
    function snapshotVersion() external view returns (bytes32);

    /**
     * @notice Returns the snapshot, given a snapshot hash.
     * @param hash The snapshot hash.
     * @return _snapshot The snapshot matching the `hash`.
     */
    function snapshots(bytes32 hash) external view returns (bytes memory _snapshot);

    /**
     * @notice Returns the hash when given a version, returns a version when given a hash.
     * @param versionOrHash The version or hash.
     * @return hashOrVersion The hash or version based on the input.
     */
    function versions(bytes32 versionOrHash) external view returns (bytes32 hashOrVersion);

    /**
     * @notice Returns the address that receives all minted tokens.
     */
    function mintTo() external view returns (address);

    /**
     * @notice Returns the address that receives all seized tokens.
     */
    function seizeTo() external view returns (address);

    /**
     * @notice Updates the current SOMA snapshot and is called after the proxy has been upgraded.
     * @param version The version to upgrade to.
     * @custom:emits SOMAUpgraded
     * @custom:requirement The incoming snapshot hash cannot be equal to the contract's existing snapshot hash.
     */
    function __upgrade(bytes32 version) external;

    /**
     * @notice Triggers the SOMA paused state. Pauses all the SOMA contracts.
     * @custom:emits Paused
     * @custom:requirement SOMA must be already unpaused.
     * @custom:requirement The caller must be the master or subMaster.
     */
    function pause() external;

    /**
     * @notice Triggers the SOMA unpaused state. Unpauses all the SOMA contracts.
     * @custom:emits Unpaused
     * @custom:requirement SOMA must be already paused.
     * @custom:requirement The caller must be the master or subMaster.
     */
    function unpause() external;

    /**
     * @notice Sets the `mintTo` address to `_mintTo`.
     * @param _mintTo The address to be set as the `mintTo` address.
     * @custom:emits MintToUpdated
     * @custom:requirement The caller must be the master.
     */
    function setMintTo(address _mintTo) external;

    /**
     * @notice Sets the `seizeTo` address to `_seizeTo`.
     * @param _seizeTo The address to be set as the `seizeTo` address.
     * @custom:emits SeizeToUpdated
     * @custom:requirement The caller must be the master.
     */
    function setSeizeTo(address _seizeTo) external;

    /**
     * @notice Returns the current snapshot of the SOMA contracts.
     */
    function snapshot() external view returns (Snapshot memory _snapshot);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

import "./ISOMA.sol";

library SOMAlib {
    /**
     * @notice The fixed address where the SOMA contract will be located (this is a proxy).
     */
    ISOMA public constant SOMA = ISOMA(0x65d3afbA3dC9d16eD308257c4D9CABdCAF72Ec99);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ISOMA.sol";

interface ISomaContract {
    function pause() external;
    function unpause() external;

    function SOMA() external view returns (ISOMA);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

pragma solidity >=0.6.2;

/**
 * @title SOMA Swap Router Contract.
 * @author SOMA.finance
 * @notice Interface for the {SomaSwapRouter} contract.
 */
interface ISomaSwapRouter {
    /**
     * @notice Returns the address of the factory contract.
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the address of the WETH token.
     */
    function WETH() external view returns (address);

    /**
     * @notice Adds liquidity to the pool.
     * @param tokenA The token0 of the pair to add liquidity to.
     * @param tokenB The token1 of the pair to add liquidity to.
     * @param amountADesired The amount of token0 to add as liquidity.
     * @param amountBDesired The amount of token1 to add as liquidity.
     * @param amountAMin The bound of the tokenB / tokenA price can go up
     * before transaction reverts.
     * @param amountBMin The bound of the tokenA / tokenB price can go up
     * before transaction reverts.
     * @param to The address to receive the liquidity tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `tokenA` and `tokenB` pair must already exist.
     * @custom:requirement the router's expiration deadline must be greater than the timestamp of the
     * function call
     * @return amountA The amount of tokenA added as liquidity.
     * @return amountB The amount of tokenB added as liquidity.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice Adds liquidity to the pool with ETH.
     * @param token The pool token.
     * @param amountTokenDesired The amount of token to add as liquidity if WETH/token price
     * is less or equal to the value of msg.value/amountTokenDesired (token depreciates).
     * @param amountTokenMin The bound that WETH/token price can go up before the transactions
     * reverts.
     * @param amountETHMin The bound that token/WETH price can go up before the transaction reverts.
     * @param to The recipient of the liquidity tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `tokenA` and `tokenB` pair must already exist.
     * @custom:requirement the router's expiration deadline must be greater than the timestamp of the
     * function call
     * @return amountToken The amount of token sent to the pool.
     * @return amountETH The amount of ETH converted to WETH and sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    /**
     * @notice Removes liquidity from the pool.
     * @param tokenA The pool token.
     * @param tokenB The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountAMin The minimum amount of tokenA that must be received
     * for the transaction not to revert.
     * @param amountBMin The minimum amount of tokenB that must be received
     * for the transaction not to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountA The amount of tokenA received.
     * @return amountB The amount of tokenB received.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Removes liquidity from the pool and the caller receives ETH.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of tokens that must be received
     * for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the
     * transaction not to revert.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountToken The amount of token received.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Removes liquidity from the pool without pre-approval.
     * @param tokenA The pool token0.
     * @param tokenB The pool token1.
     * @param liquidity The amount of liquidity to remove.
     * @param amountAMin The minimum amount of tokenA that must be received for the
     * transaction not to revert.
     * @param amountBMin The minimum amount of tokenB that must be received for the
     * transaction not to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Boolean value indicating if the approval amount in the signature
     * is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountA The amount of tokenA received.
     * @return amountB The amount of tokenB received.
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Removes liquidity from the pool and the caller receives ETH without pre-approval.
     * @param token The pool token.
     * @param liquidity The amount of liquidity to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction
     * not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not
     * to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Boolean value indicating if the approval amount in the signature
     * is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @return amountToken The amount fo token received.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible, along
     * with the route determined by the path.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction
     * not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The value at the last index of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or equal to `amountOutMin`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Caller receives an exact amount of output tokens for as few input input tokens as possible, along
     * with the route determined by the path.
     * @param amountOut The amount of output tokens to receive.
     * @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The value of the first index of `amounts` (from `SomaSwapLibrary.getAmountsIn()`) must be less than or equal to `amountInMax`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Swaps an exact amount of ETH for as many output tokens as possible, along with the route
     * determined by the path.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The last element of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or equal to `amount0Min`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    /**
     * @notice Caller receives an exact amount of ETH for as few input tokens as possible, along with the route
     * determined by the path.
     * @param amountOut The amount of ETH to receive.
     * @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The first element of `amounts` (from `SomaSwapLibrary.getAmountsIn()`) must be less than or equal to `amountInMax`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Swaps an exact amount of tokens for as much ETH as possible, along with the route determined
     * by the path.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The last element of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or
     * equal to `amountOutMin`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Caller receives an exact amount of tokens for as little ETH as possible, along with the route determined
     * by the path.
     * @param amountOut The amount of tokens to receive.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The first element of `amounts` (from `SomaSwapLibrary.getAmountIn()`) must be less than or equal
     * to the `msg.value`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    /**
     * @notice Given some asset amount and reserves, returns the amount of the other asset representing equivalent value.
     * @param amountA The amount of token0.
     * @param reserveA The reserves of token0.
     * @param reserveB The reserves of token1.
     * @custom:requirement `amountA` must be greater than zero.
     * @custom:requirement `reserveA` must be greater than zero.
     * @custom:requirement `reserveB` must be greater than zero.
     * @return amountB The amount of token1.
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    /**
     * @notice Given some asset amount and reserves, returns the maximum output amount of the other asset (accounting for fees).
     * @param amountIn The amount of the input token.
     * @param reserveIn The reserves of the input token.
     * @param reserveOut The reserves of the output token.
     * @custom:requirement `amountIn` must be greater than zero.
     * @custom:requirement `reserveIn` must be greater than zero.
     * @custom:requirement `reserveOut` must be greater than zero.
     * @return amountOut The amount of the output token.
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees).
     * @param amountOut The amount of the output token.
     * @param reserveIn The reserves of the input token.
     * @param reserveOut The reserves of the output token.
     * @custom:requirement `amountOut` must be greater than zero.
     * @custom:requirement `reserveIn` must be greater than zero.
     * @custom:requirement `reserveOut` must be greater than zero.
     * @return amountIn The required input amount of the input asset.
     */
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);

    /**
     * @notice Given an input asset amount and an array of token addresses, calculates all subsequent maximum output token amounts
     * calling `getReserves()` for each pair of token addresses in the path in turn, and using these to call `getAmountOut()`.
     * @param amountIn The amount of the input token.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @custom:requirement `path` length must be greater than or equal to 2.
     * @return amounts The maximum output amounts.
     */
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    /**
     * @notice Given an output asset amount and an array of token addresses, calculates all preceding minimum input token amounts
     * by calling `getReserves()` for each pair of token addresses in the path in turn, and using these to call `getAmountIn()`.
     * @param amountOut The amount of the output token.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @custom:requirement `path` length must be greater than or equal to 2.
     * @return amounts The required input amounts.
     */
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    /**
     * @notice See {ISomaSwapRouter-removeLiquidityETH} - Identical but succeeds for tokens that take a fee on transfer.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @custom:requirement There must be enough liquidity for both token amounts to be removed.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    /**
     * @notice See {ISomaSwapRouter-removeLiquidityETHWithPermit} - Identical but succeeds for tokens that take a fee on transfer.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @custom:requirement There must be enough liquidity for both token amounts to be removed.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    /**
     * @notice See {ISomaSwapRouter-swapExactTokensForTokens} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    /**
     * @notice See {ISomaSwapRouter-swapExactETHForTokens} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The increase in balance of the last element of `path` for the `to` address must be greater than
     * or equal to `amountOutMin`.
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    /**
     * @notice See {ISomaSwapRouter-swapExactTokensForETH} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The WETH balance of the router must be greater than or equal to `amountOutMin`.
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

/**
 * @title SOMA Swap Factory Contract.
 * @author SOMA.finance
 * @notice Interface for the {SomaSwapFactory} contract.
 */
interface ISomaSwapFactory {
    /**
     * @notice Emitted when a pair is created via `createPair()`.
     * @param token0 The address of token0.
     * @param token1 The address of token1.
     * @param pair The address of the created pair.
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    /**
     * @notice Emitted when the `feeTo` address is updated from `prevFeeTo` to `newFeeTo` by `sender`.
     * @param prevFeeTo The address of the previous fee to.
     * @param prevFeeTo The address of the new fee to.
     * @param sender The address of the message sender.
     */
    event FeeToUpdated(address indexed prevFeeTo, address indexed newFeeTo, address indexed sender);

    /**
     * @notice Emitted when a router is added by `sender`.
     * @param router The address of the router added.
     * @param sender The address of the message sender.
     */
    event RouterAdded(address indexed router, address indexed sender);

    /**
     * @notice Emitted when a router is removed by `sender`.
     * @param router The address of the router removed.
     * @param sender The address of the message sender.
     */
    event RouterRemoved(address indexed router, address indexed sender);

    /**
     * @notice Returns SOMA Swap Factory Create Pair Role.
     * @dev Returns `keccak256('SomaSwapFactory.CREATE_PAIR_ROLE')`.
     */
    function CREATE_PAIR_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns SOMA Swap Factory Fee Setter Role.
     * @dev Returns `keccak256('SomaSwapFactory.FEE_SETTER_ROLE')`.
     */
    function FEE_SETTER_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns SOMA Swap Factory Manage Router Role.
     * @dev Returns `keccak256('SomaSwapFactory.MANAGE_ROUTER_ROLE')`.
     */
    function MANAGE_ROUTER_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns the address where fees from the exchange get transferred to.
     */
    function feeTo() external view returns (address);

    /**
     * @notice Returns the address of the pair contract for tokenA and tokenB if it exists, else returns address(0).
     * @dev Returns the address of the pair for `tokenA` and `tokenB` if it exists, else returns `address(0)`.
     * @param tokenA The token0 of the pair.
     * @param tokenB The token1 of the pair.
     * @return pair The address of the pair.
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Returns the nth pair created through the factory, or address(0).
     * @dev Returns the `n-th` pair (0 indexed) created through the factory, or `address(0)`.
     * @return pair The address of the pair.
     */
    function allPairs(uint256) external view returns (address pair);

    /**
     * @notice Returns the total number of pairs created through the factory so far.
     */
    function allPairsLength() external view returns (uint256);

    /**
     * @notice Returns True if an address is an existing router, else returns False.
     * @param target The address to return true if it an existing router, or false if it is not.
     * @return Boolean value indicating if the address is an existing router.
     */
    function isRouter(address target) external view returns (bool);

    /**
     * @notice Adds an address as a new router. A router is able to tell a pair who is swapping.
     * @param router The address to add as a new router.
     * @custom:emits RouterAdded
     * @custom:requirement The function caller must have the MANAGE_ROUTER_ROLE.
     */
    function addRouter(address router) external;

    /**
     * @notice Removes an address from the list of routers. A router is able to tell a pair who is swapping.
     * @param router The address to remove from the list of routers.
     * @custom:emits RouterRemoved
     * @custom:requirement The function caller must have the MANAGE_ROUTER_ROLE.
     */
    function removeRouter(address router) external;

    /**
     * @notice Creates a new pair.
     * @dev Creates a pair for `tokenA` and `tokenB` if one does not exist already.
     * @param tokenA The address of token0 of the pair.
     * @param tokenB The address of token1 of the pair.
     * @custom:emits PairCreated
     * @custom:requirement The function caller must have the CREATE_PAIR_ROLE.
     * @custom:requirement `tokenA` must not be equal to `tokenB`.
     * @custom:requirement `tokenA` must not be equal to `address(0)`.
     * @custom:requirement `tokenA` and `tokenB` must not be an existing pair.
     * @custom:requirement The system must not be paused.
     * @return pair The address of the pair created.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Sets a new `feeTo` address.
     * @param _feeTo The new address to receive the protocol fees.
     * @custom:emits FeeToUpdated
     * @custom:requirement The function caller must have the FEE_SETTER_ROLE.
     * @custom:requirement The system must not be paused.
     */
    function setFeeTo(address _feeTo) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title SOMA Guard Contract.
 * @author SOMA.finance
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 * @notice A contract to batch update account privileges.
 */
interface ISomaGuard {
    /**
     * @notice Emitted when privileges for a 2D array of accounts are updated.
     * @param accounts The 2D array of addresses.
     * @param privileges The array of privileges.
     * @param sender The address of the message sender.
     */
    event BatchUpdate(address[][] accounts, bytes32[] privileges, address indexed sender);

    /**
     * @notice Emitted when privileges for an array of accounts are updated.
     * @param accounts The array of addresses.
     * @param access The array of privileges.
     * @param sender The address of the message sender.
     */
    event BatchUpdateSingle(address[] accounts, bytes32[] access, address indexed sender);

    /**
     * @notice Returns the default privileges of the SomaGuard contract.
     * @dev Returns bytes32(uint256(2 ** 64 - 1)).
     */
    function DEFAULT_PRIVILEGES() external view returns (bytes32);

    /**
     * @notice Returns the operator role of the SomaGuard contract.
     * @dev Returns keccak256('SomaGuard.OPERATOR_ROLE').
     */
    function OPERATOR_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the privilege of an account.
     * @param account The account to return the privilege of.
     */
    function privileges(address account) external view returns (bytes32);

    /**
     * @notice Returns True if an account passes a query, where query is the desired privileges.
     * @param account The account to check the privileges of.
     * @param query The desired privileges to check for.
     */
    function check(address account, bytes32 query) external view returns (bool);

    /**
     * @notice Returns the privileges for each account.
     * @param accounts_ The array of accounts return the privileges of.
     * @return privileges_ The array of privileges.
     */
    function batchFetch(address[] calldata accounts_) external view returns (bytes32[] memory privileges_);

    /**
     * @notice Updates the privileges of an array of accounts.
     * @param accounts_ The array of addresses to accumulate privileges of.
     * @param privileges_ The array of privileges to update the array of accounts with.
     * @custom:emits BatchUpdateSingle
     * @custom:requirement The length of `accounts_` must be equal to the length of `privileges_`.
     * @custom:requirement The length of `accounts_` must be greater than zero.
     * @custom:requirement The function caller must have the OPERATOR_ROLE.
     * @return True if the batch update was successful.
     */
    function batchUpdate(address[] calldata accounts_, bytes32[] calldata privileges_) external returns (bool);

    /**
     * @notice Updates the privileges of a 2D array of accounts, where the child array of accounts are all assigned to the
     * same privileges.
     * @param accounts_ The array of addresses to accumulate privileges of.
     * @param privileges_ The array of privileges to update the 2D array of accounts with.
     * @custom:emits BatchUpdate
     * @custom:requirement The length of `accounts_` must be equal to the length of `privileges_`.
     * @custom:requirement The length of `accounts_` must be greater than zero.
     * @custom:requirement The function caller must have the OPERATOR_ROLE.
     * @return True if the batch update was successful.
     */
    function batchUpdate(address[][] calldata accounts_, bytes32[] calldata privileges_) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title SOMA Template Factory Contract.
 * @author SOMA.finance.
 * @notice Interface of the {TemplateFactory} contract.
 */
interface ITemplateFactory {
    /**
     * @notice Emitted when a template version is created.
     * @param templateId The ID of the template added.
     * @param version The version of the template.
     * @param implementation The address of the implementation of the template.
     * @param sender The address of the message sender.
     */
    event TemplateVersionCreated(
        bytes32 indexed templateId, uint256 indexed version, address implementation, address indexed sender
    );

    /**
     * @notice Emitted when a deploy role is updated.
     * @param templateId The ID of the template with the updated deploy role.
     * @param prevRole The previous role.
     * @param newRole The new role.
     * @param sender The address of the message sender.
     */
    event DeployRoleUpdated(bytes32 indexed templateId, bytes32 prevRole, bytes32 newRole, address indexed sender);

    /**
     * @notice Emitted when a template is enabled.
     * @param templateId The ID of the template.
     * @param sender The address of the message sender.
     */
    event TemplateEnabled(bytes32 indexed templateId, address indexed sender);

    /**
     * @notice Emitted when a template is disabled.
     * @param templateId The ID of the template.
     * @param sender The address of the message sender.
     */
    event TemplateDisabled(bytes32 indexed templateId, address indexed sender);

    /**
     * @notice Emitted when a template version is deprecated.
     * @param templateId The ID of the template.
     * @param version The version of the template deprecated.
     * @param sender The address of the message sender.
     */
    event TemplateVersionDeprecated(bytes32 indexed templateId, uint256 indexed version, address indexed sender);

    /**
     * @notice Emitted when a template version is undeprecated.
     * @param templateId The ID of the template.
     * @param version The version of the template undeprecated.
     * @param sender The address of the message sender.
     */
    event TemplateVersionUndeprecated(bytes32 indexed templateId, uint256 indexed version, address indexed sender);

    /**
     * @notice Emitted when a template is deployed.
     * @param instance The instance of the deployed template.
     * @param templateId The ID of the template.
     * @param version The version of the template.
     * @param args The abi-encoded constructor arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param sender The address of the message sender.
     */
    event TemplateDeployed(
        address indexed instance,
        bytes32 indexed templateId,
        uint256 version,
        bytes args,
        bytes[] functionCalls,
        address indexed sender
    );

    /**
     * @notice Emitted when a template is cloned.
     * @param instance The instance of the deployed template.
     * @param templateId The ID of the template.
     * @param version The version of the template.
     * @param functionCalls The abi-encoded function calls.
     * @param sender The address of the message sender.
     */
    event TemplateCloned(
        address indexed instance,
        bytes32 indexed templateId,
        uint256 version,
        bytes[] functionCalls,
        address indexed sender
    );

    /**
     * @notice Emitted when a template function is called.
     * @param target The address of the target contract.
     * @param data The abi-encoded data.
     * @param result The abi-encoded result.
     * @param sender The address of the message sender.
     */
    event FunctionCalled(address indexed target, bytes data, bytes result, address indexed sender);

    /**
     * @notice Structure of a template version.
     * @param exists True if the version exists, False if it does not.
     * @param deprecated True if the version is deprecated, False if it is not.
     * @param implementation The address of the version's implementation.
     * @param creationCode The abi-encoded creation code.
     * @param totalParts The total number of parts of the version.
     * @param partsUploaded The number of parts uploaded.
     * @param instances The array of instances.
     */
    struct Version {
        bool deprecated;
        address implementation;
        bytes creationCode;
        uint256 totalParts;
        uint256 partsUploaded;
        address[] instances;
    }

    /**
     * @notice Structure of a template.
     * @param disabled Boolean value indicating if the template is enabled.
     * @param latestVersion The latest version of the template.
     * @param deployRole The deployer role of the template.
     * @param version The versions of the template.
     * @param instances The instances of the template.
     */
    struct Template {
        bool disabled;
        bytes32 deployRole;
        Version[] versions;
        address[] instances;
    }

    /**
     * @notice Structure of deployment information.
     * @param exists Boolean value indicating if the deployment information exists.
     * @param templateId The id of the template.
     * @param version The version of the template.
     * @param args The abi-encoded arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param cloned Boolean indicating if the deployment information is cloned.
     */
    struct DeploymentInfo {
        bool exists;
        uint64 block;
        uint64 timestamp;
        address sender;
        bytes32 templateId;
        uint256 version;
        bytes args;
        bytes[] functionCalls;
        bool cloned;
    }

    /**
     * @notice Returns a version of a template.
     * @param templateId The id of the template to return the version of.
     * @param _version The version of the template to be returned.
     * @return The version of the template.
     */
    function version(bytes32 templateId, uint256 _version) external view returns (Version memory);

    /**
     * @notice Returns the latest version of a template.
     * @param templateId The id of the template to return the latest version of.
     * @return The latest version of the template.
     */
    function latestVersion(bytes32 templateId) external view returns (uint256);

    /**
     * @notice Returns the instances of a template.
     * @param templateId The id of the template to return the latest instance of.
     * @return The instances of the template.
     */
    function templateInstances(bytes32 templateId) external view returns (address[] memory);

    /**
     * @notice Returns the deployment information of an instance.
     * @param instance The instance of the template to return deployment information of.
     * @return The deployment information of the template.
     */
    function deploymentInfo(address instance) external view returns (DeploymentInfo memory);

    /**
     * @notice Returns the deploy role of a template.
     * @param templateId The id of the template to return the deploy role of.
     * @return The deploy role of the template.
     */
    function deployRole(bytes32 templateId) external view returns (bytes32);

    /**
     * @notice Returns True if an instance has been deployed by the template factory, else returns False.
     * @dev Returns `true` if `instance` has been deployed by the template factory, else returns `false`.
     * @param instance The instance of the template to return True for, if it has been deployed by the factory, else False.
     * @return Boolean value indicating if the instance has been deployed by the template factory.
     */
    function deployedByFactory(address instance) external view returns (bool);

    /**
     * @notice Uploads a new template and returns True.
     * @param templateId The id of the template to upload.
     * @param initialPart The initial part to upload.
     * @param totalParts The number of total parts of the template.
     * @param implementation The address of the implementation of the template.
     * @custom:emits TemplateVersionCreated
     * @custom:requirement `templateId` must not be equal to bytes32(0).
     * @custom:requirement The length of `initialPart` must be greater than zero.
     * @custom:requirement `totalParts` must be greater than zero.
     */
    function uploadTemplate(bytes32 templateId, bytes memory initialPart, uint256 totalParts, address implementation)
        external
        returns (bool);

    /**
     * @notice Uploads a part of a template.
     * @param templateId The id of the template to upload a part to.
     * @param version The version of the template to upload a part to.
     * @param part The part to upload to the template.
     * @custom:requirement The length of part must be greater than zero.
     * @custom:requirement The version of the template must already exist.
     * @custom:requirement The version's number of parts uploaded must be less than the version's total number of parts.
     * @return Boolean value indicating if the operation was successful.
     */
    function uploadTemplatePart(bytes32 templateId, uint256 version, bytes memory part) external returns (bool);

    /**
     * @notice Updates the deploy role of a template.
     * @param templateId The id of the template to update the deploy role for.
     * @param _deployRole The deploy role to update to.
     * @custom:emits DeployRoleUpdated
     * @custom:requirement The template's existing deploy role cannot be equal to `deployRole`.
     * @return Boolean value indicating if the operation was successful.
     */
    function updateDeployRole(bytes32 templateId, bytes32 _deployRole) external returns (bool);

    /**
     * @notice Disables a template and returns True.
     * @dev Disables a template and returns `true`.
     * @param templateId The id of the template to disable.
     * @custom:emits TemplateDisabled
     * @custom:requirement The template must be enabled when the function call is made.
     * @return Boolean value indicating if the operation was successful.
     */
    function disableTemplate(bytes32 templateId) external returns (bool);

    /**
     * @notice Enables a template and returns True.
     * @dev Enables a template and returns `true`.
     * @param templateId The id of the template to enable.
     * @custom:emits TemplateEnabled
     * @custom:requirement The template must be disabled when the function call is made.
     * @return Boolean value indicating if the operation was successful.
     */
    function enableTemplate(bytes32 templateId) external returns (bool);

    /**
     * @notice Deprecates a version of a template. A deprecated template version cannot be deployed.
     * @param templateId The id of the template to deprecate the version for.
     * @param _version The version of the template to deprecate.
     * @custom:emits TemplateVersionDeprecated
     * @custom:requirement The version must already exist.
     * @custom:requirement The version must not be deprecated already.
     * @return Boolean value indicating if the operation was successful.
     */
    function deprecateVersion(bytes32 templateId, uint256 _version) external returns (bool);

    /**
     * @notice Undeprecates a version of a template and returns True.
     * @param templateId The id of the template to undeprecate a version for.
     * @param _version The version of a template to undeprecate.
     * @custom:emits TemplateVersionUndeprecated
     * @custom:requirement The version must be deprecated already.
     * @return Boolean value indicating if the operation was successful.
     */
    function undeprecateVersion(bytes32 templateId, uint256 _version) external returns (bool);

    /**
     * @notice Returns the Init Code Hash.
     * @dev Returns the keccak256 hash of `templateId`, `version` and `args`.
     * @param templateId The id of the template to return the init code hash of.
     * @param _version The version of the template to return the init code hash of.
     * @param args The abi-encoded constructor arguments.
     * @return The abi-encoded init code hash.
     */
    function initCodeHash(bytes32 templateId, uint256 _version, bytes memory args) external view returns (bytes32);

    /**
     * @notice Overloaded predictDeployAddress function.
     * @dev See {ITemplateFactory-predictDeployAddress}.
     * @param templateId The id of the template to predict the deploy address for.
     * @param _version The version of the template to predict the deploy address for.
     * @param args The abi-encoded constructor arguments.
     * @param salt The unique hash ot identify the contract.
     */
    function predictDeployAddress(bytes32 templateId, uint256 _version, bytes memory args, bytes32 salt)
        external
        view
        returns (address);

    /**
     * @notice Predict the clone address.
     * @param templateId The id of the template to predict the clone address for.
     * @param _version The version of the template to predict the clone address for.
     * @param salt The unique hash ot identify the contract.
     * @return The predicted clone address.
     */
    function predictCloneAddress(bytes32 templateId, uint256 _version, bytes32 salt) external view returns (address);

    /**
     * @notice Deploys a version of a template.
     * @param templateId The id of the template to deploy.
     * @param _version The version of the template to deploy.
     * @param args The abi-encoded constructor arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param salt The unique hash to identify the contract.
     * @custom:emits TemplateDeployed
     * @custom:requirement The version's number of parts must be equal to the version's number of parts uploaded.
     * @custom:requirement The length of the version's creation code must be greater than zero.
     * @return instance The instance of the deployed template.
     */
    function deployTemplate(
        bytes32 templateId,
        uint256 _version,
        bytes memory args,
        bytes[] memory functionCalls,
        bytes32 salt
    ) external returns (address instance);

    /**
     * @notice Clones a version of a template.
     * @param templateId The id of the template to clone.
     * @param _version The version of the template to clone.
     * @param functionCalls The abi-encoded function calls.
     * @param salt The unique hash to identify the contract.
     * @custom:emits TemplateCloned
     * @custom:requirement The version's implementation must not equal `address(0)`.
     * @return instance The address of the cloned template instance.
     */
    function cloneTemplate(bytes32 templateId, uint256 _version, bytes[] memory functionCalls, bytes32 salt)
        external
        returns (address instance);

    /**
     * @notice Calls a function on the target contract.
     * @param target The target address of the function call.
     * @param data Miscalaneous data associated with the transfer.
     * @custom:emits FunctionCalled
     * @return result The result of the function call.
     */
    function functionCall(address target, bytes memory data) external returns (bytes memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ILockdrop.sol";

/**
 * @title SOMA Lockdrop Factory Contract.
 * @author SOMA.finance.
 * @notice A factory that produces Lockdrop contracts.
 */
interface ILockdropFactory {
    /**
     * @notice Emitted when a Lockdrop is created.
     * @param id The ID of the Lockdrop.
     * @param asset The delegation asset of the Lockdrop.
     * @param instance The address of the created Lockdrop.
     */
    event LockdropCreated(uint256 id, address asset, address instance);

    /**
     * @notice The Lockdrop's CREATE_ROLE.
     * @dev Returns keccak256('Lockdrop.CREATE_ROLE').
     */
    function CREATE_ROLE() external pure returns (bytes32);

    /**
     * @notice Creates a Lockdrop instance.
     * @param asset The address of the delegation asset.
     * @param withdrawTo The address that delegated assets will be withdrawn to.
     * @param dateConfig The date configuration of the Lockdrop.
     * @custom:emits LockdropCreated
     * @custom:requirement `asset` must not be equal to address zero.
     * @custom:requirement `withdrawTo` must not be equal to address zero.
     * @custom:requirement The function caller must have the CREATE_ROLE.
     */
    function create(address asset, address withdrawTo, ILockdrop.DateConfig calldata dateConfig) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title SOMA Lockdrop Contract.
 * @author SOMA.finance
 * @notice A fund raising contract for bootstrapping DEX liquidity pools.
 */
interface ILockdrop {
    /**
     * @notice Emitted when the {DelegationConfig} is updated.
     * @param prevConfig The previous delegation configuration.
     * @param newConfig The new delegation configuration.
     * @param sender The message sender that triggered the event.
     */
    event DelegationConfigUpdated(DelegationConfig prevConfig, DelegationConfig newConfig, address indexed sender);

    /**
     * @notice Emitted when the {withdrawTo} address is updated.
     * @param prevTo The previous withdraw to address.
     * @param newTo The new withdraw to address.
     * @param sender The message sender that triggered the event.
     */
    event WithdrawToUpdated(address prevTo, address newTo, address indexed sender);

    /**
     * @notice Emitted when a delegation is added to a pool.
     * @param poolId The pool ID.
     * @param amount The delegation amount denominated in the delegation asset.
     * @param sender The message sender that triggered the event.
     */
    event DelegationAdded(bytes32 indexed poolId, uint256 amount, address indexed sender);

    /**
     * @notice Emitted when someone calls {moveDelegation}, transferring their delegation to a different pool.
     * @param fromPoolId The pool ID of the source pool.
     * @param toPoolId The pool ID of the destination pool.
     * @param amount The amount of the delegation asset to move.
     * @param sender TThe message sender that triggered the event.
     */
    event DelegationMoved(bytes32 indexed fromPoolId, bytes32 indexed toPoolId, uint256 amount, address indexed sender);

    /**
     * @notice Emitted when the {DateConfig} is updated.
     * @param prevDateConfig The previous date configuration.
     * @param newDateConfig The new date configuration.
     * @param sender The message sender that triggered the event.
     */
    event DatesUpdated(DateConfig prevDateConfig, DateConfig newDateConfig, address indexed sender);

    /**
     * @notice Emitted when the {Pool} is updated.
     * @param poolId The pool ID.
     * @param requiredPrivileges The new required privileges.
     * @param enabled Boolean indicating if the pool is enabled.
     * @param sender The message sender that triggered the event.
     */
    event PoolUpdated(bytes32 indexed poolId, bytes32 requiredPrivileges, bool enabled, address indexed sender);

    /**
     * @notice Date Configuration structure. These phases represent the 3 phases that the lockdrop
     * will go through, and will change the functionality of the lockdrop at each phase.
     * @param phase1 The unix timestamp for the start of phase1.
     * @param phase2 The unix timestamp for the start of phase2.
     * @param phase3 The unix timestamp for the start of phase3.
     */
    struct DateConfig {
        uint48 phase1;
        uint48 phase2;
        uint48 phase3;
    }

    /**
     * @notice Pool structure. Each pool will bootstrap liquidity for an upcoming DEX pair.
     * E.g: sTSLA/USDC
     * @param enabled Boolean indicating if the pool is enabled.
     * @param requiredPrivileges The required privileges of the pool.
     * @param balances The mapping of user addresses to delegation balances.
     */
    struct Pool {
        bool enabled;
        bytes32 requiredPrivileges;
        mapping(address => uint256) balances;
    }

    /**
     * @notice Delegation Configuration structure. Each user will specify their own Delegation Configuration.
     * @param percentLocked The percentage of user rewards to delegate to phase2.
     * @param lockDuration The lock duration of the user rewards.
     */
    struct DelegationConfig {
        uint8 percentLocked;
        uint8 lockDuration;
    }

    /**
     * @notice Returns the Lockdrop Global Admin Role.
     * @dev Equivalent to `keccak256('Lockdrop.GLOBAL_ADMIN_ROLE')`.
     */
    function GLOBAL_ADMIN_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns the Lockdrop Local Admin Role.
     * @dev Equivalent to `keccak256(abi.encodePacked(address(this), GLOBAL_ADMIN_ROLE))`.
     */
    function LOCAL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the ID of the Lockdrop.
     */
    function id() external view returns (uint256);

    /**
     * @notice The address of the Lockdrop's delegation asset.
     */
    function asset() external view returns (address);

    /**
     * @notice The date configuration of the Lockdrop.
     */
    function dateConfig() external view returns (DateConfig memory);

    /**
     * @notice The address where the delegated funds will be withdrawn to.
     */
    function withdrawTo() external view returns (address);

    /**
     * @notice Initialize function for the Lockdrop contract.
     * @param _id The ID of the Lockdrop.
     * @param _asset The address of the delegation asset.
     * @param _withdrawTo The address that receives withdrawn assets.
     * @param _initDateConfig The initial date configuration.
     */
    function initialize(uint256 _id, address _asset, address _withdrawTo, DateConfig calldata _initDateConfig)
        external;

    /**
     * @notice Updates the Lockdrop's date configuration.
     * @param newConfig The updated date configuration.
     * @custom:emits DatesUpdated
     * @custom:requirement The function caller must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function updateDateConfig(DateConfig calldata newConfig) external;

    /**
     * @notice Sets the `withdrawTo` address.
     * @param account The updated address to receive withdrawn funds.
     * @custom:emits WithdrawToUpdated
     * @custom:requirement The function caller must be the master or subMaster.
     * @custom:requirement `account` must not be equal to address zero.
     */
    function setWithdrawTo(address account) external;

    /**
     * @notice Returns the delegation balance of an account, given a pool ID.
     * @param poolId The pool ID to return the account's balance of.
     * @param account The account to return the balance of.
     * @return The delegation balance of `account` for the `poolId` pool.
     */
    function balanceOf(bytes32 poolId, address account) external view returns (uint256);

    /**
     * @notice Returns the delegation configuration of an account.
     * @param account The account to return the delegation configuration of.
     * @return The delegation configuration of the Lockdrop.
     */
    function delegationConfig(address account) external view returns (DelegationConfig memory);

    /**
     * @notice Returns a boolean indicating if a pool is enabled.
     * @param poolId The pool ID to check the enabled status of.
     * @return True if the pool is enabled, False if the pool is disabled.
     */
    function enabled(bytes32 poolId) external view returns (bool);

    /**
     * @notice Returns the required privileges of the pool. These privileges are required in order to
     * delegate.
     * @param poolId The pool ID to check the enabled status of.
     * @custom:requirement The pool must be enabled.
     * @return The required privileges of the pool.
     */
    function requiredPrivileges(bytes32 poolId) external view returns (bytes32);

    /**
     * @notice Updates the lockdrop pool parameters.
     * @param _poolId The ID of the pool to update.
     * @param _requiredPrivileges The updated required privileges of the pool.
     * @param _enabled The updated enabled or disabled state of the pool.
     * @custom:emits PoolUpdated
     * @custom:requirement The function caller must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function updatePool(bytes32 _poolId, bytes32 _requiredPrivileges, bool _enabled) external;

    /**
     * @notice Withdraws tokens from the Lockdrop contract to the `withdrawTo` address.
     * @param amount The amount of tokens to be withdrawn.
     * @custom:requirement The function caller must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Moves the accounts' delegated tokens from one pool to another.
     * @param fromPoolId The ID of the pool that the delegation will be moved from.
     * @param toPoolId The ID of the pool that the delegation will be moved to.
     * @param amount The amount of tokens to be moved.
     * @custom:emits DelegationMoved
     * @custom:requirement `fromPoolId` must not be equal to `toPoolId`.
     * @custom:requirement The Lockdrop's `phase1` must have started already.
     * @custom:requirement The Lockdrop's `phase2` must not have ended yet.
     * @custom:requirement `amount` must be greater than zero.
     * @custom:requirement The `fromPoolId` pool must be enabled.
     * @custom:requirement The `toPoolId` pool must be enabled.
     * @custom:requirement The delegation balance of the caller for the `fromPoolId` pool must be greater than
     * or equal to `amount`.
     * @custom:requirement The function caller must have the required privileges of the `fromPoolId` pool.
     * @custom:requirement The function caller must have the required privileges of the `toPoolId` pool.
     * @custom:requirement The contracts must not be paused.
     */
    function moveDelegation(bytes32 fromPoolId, bytes32 toPoolId, uint256 amount) external;

    /**
     * @notice Delegates tokens to the a specific pool.
     * @param poolId The ID of the pool to receive the delegation.
     * @param amount The amount of tokens to be delegated.
     * @custom:emits DelegationAdded
     * @custom:requirement `amount` must be greater than zero.
     * @custom:requirement The `poolId` pool must be enabled.
     * @custom:requirement The `poolId` pool's phase1 must have started already.
     * @custom:requirement The `poolId` pool's phase2 must not have ended yet.
     * @custom:requirement The function caller must have the `poolId` pool's required privileges.
     * @custom:requirement The contracts must not be paused.
     */
    function delegate(bytes32 poolId, uint256 amount) external;

    /**
     * @notice Updates the delegation configuration of an account.
     * @param newConfig The updated delegation configuration of the account.
     * @custom:emits DelegationConfigUpdated
     * @custom:requirement The ``newConfig``'s percent locked must be a valid percentage.
     * @custom:requirement The Lockdrop's phase1 must have started already.
     * @custom:requirement Given the Lockdrop's phase2 has ended, ``newConfig``'s percent locked must be
     * greater than the existing percent locked for the account.
     * @custom:requirement Given the Lockdrop's phase2 has ended, ``newConfig``'s lock duration must be equal
     * to the existing lock duration for the account.
     * @custom:requirement The contracts must not be paused.
     * @custom:requirement ``newConfig``'s phase1 must be less than or equal to phase2.
     * @custom:requirement ``newConfig``'s phase2 must be less than or equal to phase3.
     */
    function updateDelegationConfig(DelegationConfig calldata newConfig) external;
}