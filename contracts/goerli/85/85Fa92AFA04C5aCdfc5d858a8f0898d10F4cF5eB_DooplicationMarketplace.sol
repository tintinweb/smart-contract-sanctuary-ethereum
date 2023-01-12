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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IDooplication.sol";

contract DooplicationMarketplace is ReentrancyGuard, AccessControl {
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");

    // Map (dooplicationContract => tokenContract => Listing).
    // Track listings per dooplication and token contracts
    mapping(address => mapping(address => mapping(uint256 => Listing)))
        private _listings;

    // Map (dooplicationContract => active). Track active dooplication contracts
    mapping(address => bool) private _activeDooplications;

    // Map (tokenContract => TokenRoyalty). Track royalties per token contract
    mapping(address => TokenRoyalty) private _tokenRoyalties;

    struct Listing {
        uint256 price;
        uint256 postDate;
        address seller;
    }

    struct TokenRoyalty {
        bool enabled;
        address receiver;
        uint88 royaltyFraction;
    }

    event ItemListed(
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address dooplicationAddress,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address dooplicationAddress
    );

    event ItemDooplicated(
        address indexed buyer,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address dooplicationAddress,
        uint256 price
    );

    error PriceNotMet(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    );
    error NotListed(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    );
    error AlreadyListed(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    );
    error NotOwner();
    error PriceMustBeAboveZero();
    error IsOwner();
    error DooplicationContractNotActive(address dooplicationContract);
    error TokenContractNotApproved(
        address dooplicationContract,
        address tokenAddress
    );
    error TokenContractNotActive(
        address dooplicationContract,
        address tokenAddress
    );
    error InvalidRoyaltyFraction();
    error InvalidRoyaltyReceiver();

    modifier notListed(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) {
        if (_listings[dooplicationAddress][tokenAddress][tokenId].price > 0) {
            revert AlreadyListed(dooplicationAddress, tokenAddress, tokenId);
        }
        _;
    }

    modifier isListed(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) {
        if (_listings[dooplicationAddress][tokenAddress][tokenId].price == 0) {
            revert NotListed(dooplicationAddress, tokenAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address tokenAddress,
        uint256 tokenId,
        address spender
    ) {
        address owner = IERC721(tokenAddress).ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier isNotOwner(
        address tokenAddress,
        uint256 tokenId,
        address spender
    ) {
        address owner = IERC721(tokenAddress).ownerOf(tokenId);
        if (spender == owner) {
            revert IsOwner();
        }
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    /**
     * @notice Method for listing token
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param tokenId Token Id
     * @param price sale price for each item
     */
    function listItem(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(dooplicationAddress, tokenAddress, tokenId)
        isOwner(tokenAddress, tokenId, msg.sender)
    {
        if (!_activeDooplications[dooplicationAddress]) {
            revert DooplicationContractNotActive(dooplicationAddress);
        }
        if (
            !IDooplication(dooplicationAddress).contractApproved(tokenAddress)
        ) {
            revert TokenContractNotApproved(dooplicationAddress, tokenAddress);
        }
        if (
            !IDooplication(dooplicationAddress).dooplicationActive(tokenAddress)
        ) {
            revert TokenContractNotActive(dooplicationAddress, tokenAddress);
        }
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
        _listings[dooplicationAddress][tokenAddress][tokenId] = Listing(
            price,
            block.timestamp,
            msg.sender
        );
        emit ItemListed(
            msg.sender,
            tokenAddress,
            tokenId,
            dooplicationAddress,
            price
        );
    }

    /**
     * @notice Method for cancelling listing
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param tokenId Token Id
     */
    function cancelListing(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    )
        external
        isOwner(tokenAddress, tokenId, msg.sender)
        isListed(dooplicationAddress, tokenAddress, tokenId)
    {
        delete (_listings[dooplicationAddress][tokenAddress][tokenId]);
        emit ItemCanceled(
            msg.sender,
            tokenAddress,
            tokenId,
            dooplicationAddress
        );
    }

    /**
     * @notice Method for dooplicating listing
     * The owner of a token could unapprove the marketplace or transfer the token to another address,
     * which would cause this function to fail.
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param dooplicatorId Dooplicator Id
     * @param tokenId Token Id
     * @param addressOnTheOtherSide An address you control, on the other side...
     * @param data Additional data to send in the transaction
     */
    function dooplicateItem(
        address dooplicationAddress,
        address tokenAddress,
        uint256 dooplicatorId,
        uint256 tokenId,
        bytes8 addressOnTheOtherSide,
        bytes calldata data
    )
        external
        payable
        isListed(dooplicationAddress, tokenAddress, tokenId)
        isNotOwner(tokenAddress, tokenId, msg.sender)
        nonReentrant
    {
        _validateDooplication(dooplicationAddress, tokenAddress, tokenId);
        _dooplicate(
            dooplicationAddress,
            tokenAddress,
            dooplicatorId,
            tokenId,
            addressOnTheOtherSide,
            data
        );
        _sendDooplicationPayments(dooplicationAddress, tokenAddress, tokenId);
        delete _listings[dooplicationAddress][tokenAddress][tokenId];
    }

    /**
     * @notice Method for updating listing
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param tokenId Token Id
     * @param newPrice Price in Wei of the item
     */
    function updateListing(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(dooplicationAddress, tokenAddress, tokenId)
        isOwner(tokenAddress, tokenId, msg.sender)
    {
        if (newPrice == 0) {
            revert PriceMustBeAboveZero();
        }
        _listings[dooplicationAddress][tokenAddress][tokenId].price = newPrice;
        emit ItemListed(
            msg.sender,
            tokenAddress,
            tokenId,
            dooplicationAddress,
            newPrice
        );
    }

    /**
     * @notice Set dooplication contract as active or inactive
     * @param dooplicationContract the contract to modify
     * @param active true to start dooplication, false to stop
     */
    function setActiveValidDooplication(
        address dooplicationContract,
        bool active
    ) external onlyRole(SUPPORT_ROLE) {
        _activeDooplications[dooplicationContract] = active;
    }

    /**
     * @notice Set token contract royalty.
     * This function set the receiver and the royalty fraction, and enable the royalties.
     * @param tokenAddress Address of token contract
     * @param receiver Address of receiver
     * @param royaltyFraction Royalty fraction in 1/10000
     */
    function setTokenRoyalty(
        address tokenAddress,
        address receiver,
        uint88 royaltyFraction
    ) external onlyRole(SUPPORT_ROLE) {
        if (receiver == address(0)) {
            revert InvalidRoyaltyReceiver();
        }
        if (royaltyFraction == 0 || royaltyFraction > 10000) {
            revert InvalidRoyaltyFraction();
        }
        _tokenRoyalties[tokenAddress] = TokenRoyalty(
            true,
            receiver,
            royaltyFraction
        );
    }

    /**
     * @notice Set token contract royalty as enabled or disabled.
     * To be enabled, the receiver and royalty fraction must be set.
     * @param tokenAddress Address of token contract
     * @param enabled True to enable, false to disable
     */
    function setTokenRoyaltyEnabled(
        address tokenAddress,
        bool enabled
    ) external onlyRole(SUPPORT_ROLE) {
        if (_tokenRoyalties[tokenAddress].receiver == address(0)) {
            revert InvalidRoyaltyReceiver();
        }
        if (
            _tokenRoyalties[tokenAddress].royaltyFraction == 0 ||
            _tokenRoyalties[tokenAddress].royaltyFraction > 10000
        ) {
            revert InvalidRoyaltyFraction();
        }
        _tokenRoyalties[tokenAddress].enabled = enabled;
    }

    /**
     * @notice Set token contract royalty receiver
     * @param tokenAddress Address of token contract
     * @param receiver Address of receiver
     */
    function setTokenRoyaltyReceiver(
        address tokenAddress,
        address receiver
    ) external onlyRole(SUPPORT_ROLE) {
        if (receiver == address(0)) {
            revert InvalidRoyaltyReceiver();
        }
        _tokenRoyalties[tokenAddress].receiver = receiver;
    }

    /**
     * @notice Set token contract royalty fraction
     * @param tokenAddress Address of token contract
     * @param royaltyFraction Royalty fraction in 1/10000
     */
    function setTokenRoyaltyFraction(
        address tokenAddress,
        uint88 royaltyFraction
    ) external onlyRole(SUPPORT_ROLE) {
        if (royaltyFraction == 0 || royaltyFraction > 10000) {
            revert InvalidRoyaltyFraction();
        }
        _tokenRoyalties[tokenAddress].royaltyFraction = royaltyFraction;
    }

    /**
     * @notice Check if a dooplication address is active to be used
     * @param dooplicationAddress Address of dooplication contract
     * @return True if active, false if not
     */
    function dooplicationContractActivated(
        address dooplicationAddress
    ) external view returns (bool) {
        return _activeDooplications[dooplicationAddress];
    }

    /**
     * @notice Get listing of a token on a dooplication contract
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param tokenId Token Id
     * @return Listing data
     */
    function getListing(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return _listings[dooplicationAddress][tokenAddress][tokenId];
    }

    /**
     * @notice Get royalty data of a token contract
     * @param tokenAddress Address of token contract
     * @return Token Royalty data
     */
    function getTokenRoyalty(
        address tokenAddress
    ) external view returns (TokenRoyalty memory) {
        return _tokenRoyalties[tokenAddress];
    }

    // TODO optimize me
    function getActiveListings(
        address dooplicationAddress,
        address tokenAddress
    ) external view returns (uint256[] memory, Listing[] memory) {
        IERC721Enumerable token = IERC721Enumerable(tokenAddress);
        uint256 totalSupply = token.totalSupply();
        uint256 totalActiveListings = 0;
        for (uint256 i = 0; i <= totalSupply; i++) {
            Listing memory listing = _listings[dooplicationAddress][
                tokenAddress
            ][i];
            if (listing.price > 0) {
                totalActiveListings++;
            }
        }
        uint256[] memory activeTokenIds = new uint256[](totalActiveListings);
        Listing[] memory activeListings = new Listing[](totalActiveListings);
        uint256 counter = 0;
        for (uint256 i = 0; i <= token.totalSupply(); i++) {
            Listing memory listing = _listings[dooplicationAddress][
                tokenAddress
            ][i];
            if (listing.price > 0) {
                activeTokenIds[counter] = i;
                activeListings[counter] = listing;
                counter++;
            }
            if (counter == totalActiveListings) break;
        }
        return (activeTokenIds, activeListings);
    }

    function _validateDooplication(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) internal {
        uint256 price = _listings[dooplicationAddress][tokenAddress][tokenId]
            .price;
        if (msg.value != price) {
            revert PriceNotMet(
                dooplicationAddress,
                tokenAddress,
                tokenId,
                price
            );
        }
    }

    function _dooplicate(
        address dooplicationAddress,
        address tokenAddress,
        uint256 dooplicatorId,
        uint256 tokenId,
        bytes8 addressOnTheOtherSide,
        bytes calldata data
    ) internal {
        Listing memory listedItem = _listings[dooplicationAddress][
            tokenAddress
        ][tokenId];
        emit ItemDooplicated(
            msg.sender,
            tokenAddress,
            tokenId,
            dooplicationAddress,
            listedItem.price
        );
        IDooplication(dooplicationAddress).dooplicate(
            dooplicatorId,
            tokenId,
            tokenAddress,
            addressOnTheOtherSide,
            listedItem.seller,
            msg.sender,
            data
        );
    }

    function _sendDooplicationPayments(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) internal {
        address seller = _listings[dooplicationAddress][tokenAddress][tokenId]
            .seller;

        if (_tokenRoyalties[tokenAddress].enabled) {
            uint256 royaltyAmount = (msg.value *
                _tokenRoyalties[tokenAddress].royaltyFraction) / 10000;

            (bool success, ) = payable(seller).call{
                value: msg.value - royaltyAmount
            }("");
            require(success, "Seller transfer failed");

            (bool royaltySuccess, ) = payable(
                _tokenRoyalties[tokenAddress].receiver
            ).call{value: royaltyAmount}("");
            require(royaltySuccess, "Royalty transfer failed");
        } else {
            (bool success, ) = payable(seller).call{value: msg.value}("");
            require(success, "Transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IDooplication {
    function dooplicate(
        uint256 dooplicatorId,
        uint256 tokenId,
        address tokenContract,
        bytes8 addressOnTheOtherSide,
        address tokenVault,
        address dooplicatorVault,
        bytes calldata data
    ) external;

    function dooplicationActive(address) external view returns (bool);

    function contractApproved(
        address tokenContract
    ) external view returns (bool);
}