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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IContractURI.sol";
import "./interfaces/IERC5192.sol";
import "./interfaces/ITokenURI.sol";

/**
 * @title RelicToken
 * @author Theori, Inc.
 * @notice RelicToken is the base contract for all Relic SBTs. It implements
 *         ERC721 (with transfers disables) and ERC5192.
 */
abstract contract RelicToken is Ownable, ERC165, IERC721, IERC721Metadata, IERC5192 {
    mapping(address => bool) public provers;

    /// @notice contract metadata URI provider
    IContractURI contractURIProvider;

    /**
     * @notice determind if the given owner is entitiled to a token with the specific data
     * @param owner the address in question
     * @param data the opaque data in question
     * @return the existence of the given data
     */
    function hasToken(address owner, uint96 data) internal view virtual returns (bool);

    /**
     * @notice updates the set of contracts trusted to create new tokens and
     *         possibly resolve entitlement questions
     * @param prover the address of the prover
     * @param valid whether the prover is trusted
     */
    function setProver(address prover, bool valid) external onlyOwner {
        provers[prover] = valid;
    }

    /**
     * @notice helper function to break a tokenId into its constituent data
     * @param tokenId the tokenId in question
     * @return who the address bound to this token
     * @return data any additional data bound to this token
     */
    function parseTokenId(uint256 tokenId) internal pure returns (address who, uint96 data) {
        who = address(bytes20(bytes32(tokenId << 96)));
        data = uint96(tokenId >> 160);
    }

    /**
     * @notice issue a new Relic
     * @param who the address to which this token should be bound
     * @param data any data to be associated with this token
     * @dev emits ERC-721 Transfer event and ERC-5192 Locked event. Note
     *      that storage is not generally updated by this function.
     */
    function mint(address who, uint96 data) public virtual {
        require(provers[msg.sender], "only a prover can mint");
        require(hasToken(who, data), "cannot mint for invalid token");

        uint256 id = uint256(uint160(who)) | (uint256(data) << 160);
        emit Transfer(address(0), who, id);
        emit Locked(id);
    }

    /* begin ERC-721 spec functions */
    /**
     * @inheritdoc IERC721
     * @dev If the token has not been issued (no transfer event) this function
     *      may still return an owner if there is an account entitled to this
     *      token.
     */
    function ownerOf(uint256 id) public view virtual returns (address who) {
        uint96 data;
        (who, data) = parseTokenId(id);
        if (!hasToken(who, data)) {
            who = address(0);
        }
    }

    /**
     * @inheritdoc IERC721
     * @dev Balance will always be 0 if the address is not entitled to any
     *      tokens, and 1 if they are entitled to a token. If multiple tokens
     *      are minted, this will still return 1.
     */
    function balanceOf(address who) external view override returns (uint256 balance) {
        require(who != address(0), "ERC721: address zero is not a valid owner");
        if (hasToken(who, 0)) {
            balance = 1;
        }
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* _to */
        uint256, /* _tokenId */
        bytes calldata /* data */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256 /* tokenId */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* id */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function approve(
        address, /* to */
        uint256 /* tokenId */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function setApprovalForAll(
        address, /* operator */
        bool /* _approved */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Always returns the null address: Relics are soul-bound/non-transferrable
     */
    function getApproved(
        uint256 /* tokenId */
    ) external pure returns (address operator) {
        operator = address(0);
    }

    /**
     * @inheritdoc IERC721
     * @dev Always returns false: Relics are soul-bound/non-transferrable
     */
    function isApprovedForAll(
        address, /* owner */
        address /* operator */
    ) external pure returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IERC165
     * @dev Supported interfaces: IERC721, IERC721Metadata, IERC5192
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    /// @inheritdoc IERC721Metadata
    function name() external pure virtual returns (string memory);

    /// @inheritdoc IERC721Metadata
    function symbol() external pure virtual returns (string memory);

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenID) external view virtual returns (string memory);

    /* end ERC-721 spec functions */

    /* begin ERC-5192 spec functions */
    /**
     * @inheritdoc IERC5192
     * @dev All valid tokens are locked: Relics are soul-bound/non-transferrable
     */
    function locked(uint256 id) external view returns (bool) {
        return ownerOf(id) != address(0);
    }

    /* end ERC-5192 spec functions */

    /* begin OpenSea metadata functions */
    /**
     * @notice contract metadata URI as defined by OpenSea
     */
    function contractURI() external view returns (string memory) {
        return contractURIProvider.contractURI();
    }

    /**
     * @notice set contract-level metadata URI provider
     * @param provider new metadata URI provider
     */
    function setContractURIProvider(IContractURI provider) external onlyOwner {
        contractURIProvider = provider;
    }
    /* end OpenSea metadata functions */
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IERC5192.sol";
import "./interfaces/ITokenURI.sol";
import "./RelicToken.sol";

/**
 * @title RelicTokenConfigurable
 * @author Theori, Inc.
 * @notice RelicTokenConfigurable augments the RelicToken contract to allow
 *         for configurable tokenURIs.
 */
abstract contract RelicTokenConfigurable is RelicToken {
    mapping(uint64 => ITokenURI[]) TokenURIProviders;

    function addURIProvider(address provider, uint64 bulkId) external onlyOwner {
        TokenURIProviders[bulkId].push(ITokenURI(provider));
    }

    function getLatestProviderIdx(uint64 bulkId) internal view returns (uint256) {
        uint256 length = TokenURIProviders[bulkId].length;
        if (length == 0) {
            return 0;
        }
        return length - 1;
    }

    /**
     * @notice Helper function to break a tokenId into its constituent data
     * @return who the address bound to this token
     * @return data any additional data bound to this token
     * @return idx the index of the URI provider for this token
     * @return bulkId the generic "class" of this Relic
     *         (eg: eventId for AttendanceArtifacts)
     */
    function parseTokenIdData(uint256 tokenId)
        internal
        pure
        returns (
            address who,
            uint96 data,
            uint32 idx,
            uint64 bulkId
        )
    {
        (who, data) = parseTokenId(tokenId);
        idx = uint32(data >> 64);
        bulkId = uint64(data);
    }

    /// @inheritdoc RelicToken
    function mint(address who, uint96 data) public override {
        require(uint32(data >> 64) == 0, "high data bits in use");
        uint64 bulkId = uint64(data);
        uint32 providerIdx = uint32(getLatestProviderIdx(bulkId));
        uint96 newData = uint96(bulkId) | (uint96(providerIdx) << 64);

        return super.mint(who, newData);
    }

    /// @inheritdoc RelicToken
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        (address who, uint96 data, uint32 providerIdx, uint64 bulkId) = parseTokenIdData(tokenId);

        require(hasToken(who, data), "token does not exist");
        require(providerIdx < TokenURIProviders[bulkId].length, "uri provider not set");

        return TokenURIProviders[bulkId][providerIdx].tokenURI(tokenId);
    }

    /**
     * @notice request a token be replaced with another representing the same
     *         data, but with a different URI provider.
     * @param tokenId the existing token to recycle
     * @param newProviderIdx the new URI provider to use
     * @dev emits Unlock and Transfer to 0 for the existing tokenId, and then
     *      Transfer and Lock for the new tokenId.
     * @dev Due to not using storage, this function will not revert so long as
     *      the msg.sender is entitled to the tokenId they originally provide,
     *      even if that tokenId has never been issued. Misuse may cause confusion
     *      for tools attempting to track ERC-721 transfers.
     */
    function exchange(uint256 tokenId, uint32 newProviderIdx) external {
        (address who, uint96 data, , uint64 bulkId) = parseTokenIdData(tokenId);

        require(who == msg.sender, "only token owner may exchange");
        require(hasToken(who, data), "token does not exist");
        require(newProviderIdx < TokenURIProviders[bulkId].length, "invalid URI provider");

        uint256 newTokenId = (uint256(uint160(who)) |
            (uint256(bulkId) << 160) |
            (uint256(newProviderIdx) << 224));

        emit Unlocked(tokenId);
        emit Transfer(who, address(0), tokenId);
        emit Transfer(address(0), who, newTokenId);
        emit Locked(newTokenId);
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IBlockHistory.sol";
import "./interfaces/IFeeDelegate.sol";
import "./lib/Facts.sol";

struct PendingProver {
    uint64 timestamp;
    uint64 version;
}

struct ProverInfo {
    uint64 version;
    FeeInfo feeInfo;
    bool revoked;
}

// It would be nice if these could be stored in ReliquaryWithFee, but we want
// to store fee information in ProverInfo for gas optimization.
enum FeeFlags {
    FeeNone,
    FeeNative,
    FeeCredits,
    FeeExternalDelegate,
    FeeExternalToken
}

struct FeeInfo {
    uint8 flags;
    uint16 feeCredits;
    // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
    uint8 feeWeiMantissa;
    uint8 feeWeiExponent;
    uint32 feeExternalId;
}

/**
 * @title Holder of Relics and Artifacts
 * @author Theori, Inc.
 * @notice The Reliquary is the heart of Relic. All issuers of Relics and Artifacts
 *         must be added to the Reliquary. Queries about Relics and Artifacts should
 *         be made to the Reliquary.
 */
contract Reliquary is AccessControl {
    /// Minimum delay before a new prover can be active
    uint64 public constant DELAY = 2 days;

    bytes32 public constant ADD_PROVER_ROLE = keccak256("ADD_PROVER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    /// Once initialized, new provers can only be added with a delay
    bool public initialized;
    /// Append-only map of added prover addresses to information on them
    mapping(address => ProverInfo) public provers;
    /**
     *  Reverse mapping of version information to the unique prover able
     *  to issue statements with that version
     */
    mapping(uint64 => address) public versions;
    /// List of provers that may be added to the Reliquary, for public scrutiny
    mapping(address => PendingProver) public pendingProvers;

    mapping(address => mapping(FactSignature => bytes)) internal provenFacts;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Issued when a new prover is accepted into the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that will always be associated with the prover
     */
    event NewProver(address prover, uint64 version);

    /**
     * @notice Issued when a new prover is placed under consideration for acceptance
     *         into the Reliquary
     * @param prover the address of the prover contract
     * @param version the proposed identifier to always be associated with the prover
     * @param timestamp the earliest this prover can be brought into the Reliquary
     */
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);

    /**
     * @notice Issued when an existing prover is banished from the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that can never be used again
     * @dev revoked provers may not issue new Relics or Artifacts. The meaning of
     *      any previously introduced Relics or Artifacts is implementation dependent.
     */
    event ProverRevoked(address prover, uint64 version);

    /**
     * @notice Helper function to parse fact storage
     * @param fact The data associated with the proven Relic or Artifact
     * @return version the version identifier of the prover who introduced this item
     * @return data any data associated with this item
     */
    function parseFact(bytes storage fact)
        internal
        pure
        returns (uint64 version, bytes memory data)
    {
        // copy the storage bytes to memory
        data = fact;

        if (data.length > 0) {
            require(data.length >= 8, "fact data length invalid");

            // version is stored in first 8 bytes of the data
            version = uint64(bytes8(data));

            // rather than copy the rest of the data to a new bytes array,
            // just point data to data + 8 and setup length field
            assembly {
                let len := mload(data)
                data := add(data, 8)
                mstore(data, sub(len, 8))
            }
        }
    }

    /**
     * @notice Helper function to query the status of a prover
     * @param prover the ProverInfo associated with the prover in question
     * @dev reverts if the prover is invalid or revoked
     */
    function checkProver(ProverInfo memory prover) public pure {
        require(prover.revoked != true, "revoked prover");
        require(prover.version != 0, "unknown prover");
    }

    /**
     * @notice Deletes the fact from the Reliquary
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being deleted
     * @dev May only be called by non-revoked provers
     */
    function resetFact(address account, FactSignature factSig) external {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        delete provenFacts[account][factSig];
    }

    /**
     * @notice Adds the given information to the Reliquary
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being proven
     * @param data Associated data to store with this item
     * @dev May only be called by non-revoked provers
     */
    function setFact(
        address account,
        FactSignature factSig,
        bytes calldata data
    ) external {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        provenFacts[account][factSig] = abi.encodePacked(prover.version, data);
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        (version, data) = parseFact(provenFacts[account][factSig]);
        exists = version != 0;
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by the Reliquary itself
     */
    function _verifyFact(address account, FactSignature factSig)
        internal
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        (version, data) = parseFact(provenFacts[account][factSig]);
        exists = version != 0;
    }

    /**
     * @notice Query for some information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is only for use by the Reliquary itself
     */
    function _verifyFactVersion(address account, FactSignature factSig)
        internal
        view
        returns (bool exists, uint64 version)
    {
        version = uint64(bytes8(provenFacts[account][factSig]));
        exists = version != 0;
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        require(Facts.toFactClass(factSig) == Facts.NO_FEE);
        return _verifyFact(account, factSig);
    }

    /**
     * @notice Query for some information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version)
    {
        require(Facts.toFactClass(factSig) == Facts.NO_FEE);
        return _verifyFactVersion(account, factSig);
    }

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) public view returns (bool) {
        ProverInfo memory proverInfo = provers[msg.sender];
        checkProver(proverInfo);
        return IBlockHistory(verifier).validBlockHash(hash, num, proof);
    }

    /**
     * @notice Asserts that a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view {
        require(validBlockHashFromProver(verifier, hash, num, proof), "invalid block hash");
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        require(tx.origin == address(0));
        return _verifyFact(account, factSig);
    }

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool) {
        require(tx.origin == address(0));
        return IBlockHistory(verifier).validBlockHash(hash, num, proof);
    }

    /*
     * Allow a new prover to produce facts. Provers must have distinct versions.
     *
     * Once added, a new prover is not usable until it is activated after a short delay. This delay
     * prevents future governance from abusing its powers, and gives downstream users an
     * opportunity to decide if they still trust Reliquary.
     */
    /**
     * @notice Add/propose a new prover to prove facts.
     * @param prover the address of the prover in question
     * @param version the unique version string to associate with this prover
     * @dev Provers and proposed provers must have unique version IDs
     * @dev After the Reliquary is initialized, a review period of 64k blocks
     *      must conclude before a prover may be added. The request must then
     *      be re-submitted to take effect. Before initialization is complete,
     *      the review period is skipped.
     * @dev Pending provers may be removed by submitting a new prover with a
     *      version of 0.
     * @dev Emits PendingProveRemoved when a pending prover proposal is withdrawn
     * @dev Emits NewProver when a prover is added to the reliquary
     * @dev Emits PendingProverAdded when a prover is proposed for inclusion
     */
    function addProver(address prover, uint64 version) external onlyRole(ADD_PROVER_ROLE) {
        require(version != 0, "version must not be zero");
        require(versions[version] == address(0), "duplicate version");
        require(provers[prover].version == 0, "duplicate prover");
        require(pendingProvers[prover].version == 0, "already pending");

        uint256 delay = initialized ? DELAY : 0;
        PendingProver memory pendingProver = PendingProver(
            uint64(block.timestamp + delay),
            version
        );
        pendingProvers[prover] = pendingProver;

        // Pre-initialize ProverInfo so fee can be set before activation
        // As version = 0, the prover will not be usable yet
        provers[prover] = ProverInfo(0, FeeInfo(0, 0, 0, 0, 0), false);

        emit PendingProverAdded(prover, pendingProver.version, pendingProver.timestamp);
    }

    /* Anyone can activate a prover once it has been added and is no longer pending */
    function activateProver(address prover) external {
        require(provers[prover].version == 0, "duplicate prover");

        PendingProver memory pendingProver = pendingProvers[prover];
        require(pendingProver.version != 0, "invalid address");
        require(pendingProver.timestamp <= block.timestamp, "not ready");
        require(versions[pendingProver.version] == address(0), "duplicate version");

        versions[pendingProver.version] = prover;
        provers[prover].version = pendingProver.version;

        emit NewProver(prover, pendingProver.version);
    }

    /**
     * @notice Stop accepting proofs from this prover
     * @param prover The prover to banish from the reliquary
     * @dev Emits ProverRevoked
     * @dev Note: existing facts proved by the prover may still stand
     */
    function revokeProver(address prover) external onlyRole(GOVERNANCE_ROLE) {
        provers[prover].revoked = true;
        emit ProverRevoked(prover, pendingProvers[prover].version);
    }

    /**
     * @notice Initialize the Reliquary, enforcing the time lock for new provers
     */
    function setInitialized() external onlyRole(ADD_PROVER_ROLE) {
        initialized = true;
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Block history provider
 * @author Theori, Inc.
 * @notice IBlockHistory provides a way to verify a blockhash
 */

interface IBlockHistory {
    /**
     * @notice Determine if the given hash corresponds to the given block
     * @param hash the hash if the block in question
     * @param num the number of the block in question
     * @param proof any witness data required to prove the block hash is
     *        correct (such as a Merkle or SNARK proof)
     * @return boolean indicating if the block hash can be verified correct
     */
    function validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title NFT Contract Metadata URI provider
 * @author Theori, Inc.
 * @notice Outsourced contractURI provider for NFT/SBT tokens
 */
interface IContractURI {
    /**
     * @notice Get the contract metadata URI
     * @return the string of the URI
     */
    function contractURI() external view returns (string memory);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

/**
 * @title EIP-5192 specification
 * @author Theori, Inc.
 * @notice EIP-5192 events and functions
 */
interface IERC5192 {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Fee provider
 * @author Theori, Inc.
 * @notice Acceptor of fees for functions requiring payment
 */
interface IFeeDelegate {
    /**
     * @notice Accept any required fee from the sender
     * @param sender the originator of the call that may be paying
     * @param data opaque data to help determine costs
     * @dev reverts if a fee is required and not provided
     */
    function checkFee(address sender, bytes calldata data) external payable;
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title NFT Token URI provider
 * @author Theori, Inc.
 * @notice Outsourced tokenURI provider for NFT/SBT tokens
 */
interface ITokenURI {
    /**
     * @notice Get the URI for the given token
     * @param tokenID the unique ID for the token
     * @return the string of the URI
     * @dev when called with an invalid tokenID, this may revert,
     *      or it may return invalid output
     */
    function tokenURI(uint256 tokenID) external view returns (string memory);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

type FactSignature is bytes32;

library Facts {
    uint8 internal constant NO_FEE = 0;

    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../RelicTokenConfigurable.sol";
import "../Reliquary.sol";

/**
 * @title Birth Certificate Relic Token
 * @author Theori, Inc.
 * @notice Configurable soul-bound tokens issued to show an account's
 *         birth certificate
 */
contract BirthCertificateRelic is RelicTokenConfigurable {
    Reliquary immutable reliquary;
    FactSignature immutable BIRTH_CERTIFICATE_SIG;

    constructor(Reliquary _reliquary) RelicToken() Ownable() {
        BIRTH_CERTIFICATE_SIG = Facts.toFactSignature(Facts.NO_FEE, abi.encode("BirthCertificate"));
        reliquary = _reliquary;
    }

    /**
     * @inheritdoc RelicToken
     * @dev Do not validate data as it may contain URI provider information
     */
    function hasToken(
        address who,
        uint96 /* data */
    ) internal view override returns (bool result) {
        (result, ) = reliquary.verifyFactVersionNoFee(who, BIRTH_CERTIFICATE_SIG);
    }

    /// @inheritdoc IERC721Metadata
    function name() external pure override returns (string memory) {
        return "Birth Certificate Relic";
    }

    /// @inheritdoc IERC721Metadata
    function symbol() external pure override returns (string memory) {
        return "BCR";
    }
}