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

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./AccessControlStorage.sol";
import "./IAccessControlEvents.sol";

abstract contract AccessControlInternal is Context, IAccessControlEvents {
    using AccessControlStorage for AccessControlStorage.Layout;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasRole(bytes32 role, address account) internal view virtual returns (bool) {
        return AccessControlStorage.layout().roles[role].members[account];
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
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
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
    function _getRoleAdmin(bytes32 role) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
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
    function _renounceRole(bytes32 role, address account) internal virtual {
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
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
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
        if (!_hasRole(role, account)) {
            AccessControlStorage.layout().roles[role].members[account] = true;
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
        if (_hasRole(role, account)) {
            AccessControlStorage.layout().roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library AccessControlStorage {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.AccessControl");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlEvents {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * The caller must be the current contract itself.
 */
error ErrSenderIsNotSelf();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721A} that allows other facets from the diamond to mint tokens.
 */
interface IERC721MintableExtension {
    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC721A-_mint}.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function mintByFacet(address to, uint256 amount) external;

    /**
     * @dev Mint new tokens for multiple addresses with different amounts.
     */
    function mintByFacet(address[] memory tos, uint256[] memory amounts) external;

    /**
     * @dev Mint constant amount of new tokens for multiple addresses (e.g. 1 nft for each address).
     */
    function mintByFacet(address[] memory tos, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC721SupplyStorage {
    struct Layout {
        // The next token ID to be minted.
        uint256 currentIndex;
        // The number of tokens burned.
        uint256 burnCounter;
        // Maximum possible supply of tokens.
        uint256 maxSupply;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC721Supply");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../extensions/mintable/IERC721MintableExtension.sol";
import "../../../common/metadata/TokenMetadataAdminInternal.sol";
import "../../../ERC721/extensions/supply/ERC721SupplyStorage.sol";
import "./IERC721MintableRoleBased.sol";

/**
 * @title ERC721 - Mint as role
 * @notice Allow minting for senders with MINTER_ROLE to mint new tokens (supports ERC721A).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721MintableExtension
 * @custom:provides-interfaces IERC721MintableRoleBased
 */
contract ERC721MintableRoleBased is IERC721MintableRoleBased, AccessControlInternal, TokenMetadataAdminInternal {
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @inheritdoc IERC721MintableRoleBased
     */
    function mintByRole(address to, uint256 amount) public virtual onlyRole(MINTER_ROLE) {
        IERC721MintableExtension(address(this)).mintByFacet(to, amount);
    }

    /**
     * @inheritdoc IERC721MintableRoleBased
     */
    function mintByRole(address[] calldata tos, uint256[] calldata amounts) public virtual onlyRole(MINTER_ROLE) {
        IERC721MintableExtension(address(this)).mintByFacet(tos, amounts);
    }

    /**
     * @inheritdoc IERC721MintableRoleBased
     */
    function mintByRole(address[] calldata tos, uint256 amount) public virtual onlyRole(MINTER_ROLE) {
        IERC721MintableExtension(address(this)).mintByFacet(tos, amount);
    }

    /**
     * @inheritdoc IERC721MintableRoleBased
     */
    function mintByRole(
        address to,
        uint256 amount,
        string[] calldata tokenURIs
    ) public virtual onlyRole(MINTER_ROLE) {
        uint256 nextTokenId = ERC721SupplyStorage.layout().currentIndex;

        IERC721MintableExtension(address(this)).mintByFacet(to, amount);

        for (uint256 i = 0; i < amount; i++) {
            _setURI(nextTokenId + i, tokenURIs[i]);
        }
    }

    /**
     * @inheritdoc IERC721MintableRoleBased
     */
    function mintByRole(address[] calldata tos, string[] calldata tokenURIs) public virtual onlyRole(MINTER_ROLE) {
        uint256 nextTokenId = ERC721SupplyStorage.layout().currentIndex;
        uint256 total = tos.length;

        IERC721MintableExtension(address(this)).mintByFacet(tos, 1);

        for (uint256 i = 0; i < total; i++) {
            _setURI(nextTokenId + i, tokenURIs[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721} that allows a specific role to mint tokens.
 */
interface IERC721MintableRoleBased {
    /**
     * @dev Mints `amount` new tokens for `to`.
     */
    function mintByRole(address to, uint256 amount) external;

    /**
     * @dev Mints multiple `amount`s of new tokens for every single address in `tos`.
     */
    function mintByRole(address[] calldata tos, uint256[] calldata amounts) external;

    /**
     * @dev Mint constant amount of new tokens for multiple addresses (e.g. 1 nft for each address).
     */
    function mintByRole(address[] calldata tos, uint256 amount) external;

    /**
     * @dev Mint new tokens for single address with dedicated tokenURIs.
     */
    function mintByRole(
        address to,
        uint256 amount,
        string[] calldata tokenURIs
    ) external;

    /**
     * @dev Mint new tokens for multiple addresses with dedicated tokenURIs.
     */
    function mintByRole(address[] calldata tos, string[] calldata tokenURIs) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITokenMetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITokenMetadataInternal.sol";
import "./TokenMetadataStorage.sol";

abstract contract TokenMetadataAdminInternal is ITokenMetadataInternal {
    function _setBaseURI(string memory baseURI) internal virtual {
        require(!TokenMetadataStorage.layout().baseURILocked, "Metadata: baseURI locked");
        TokenMetadataStorage.layout().baseURI = baseURI;
    }

    function _setFallbackURI(string memory baseURI) internal virtual {
        require(!TokenMetadataStorage.layout().fallbackURILocked, "Metadata: fallbackURI locked");
        TokenMetadataStorage.layout().fallbackURI = baseURI;
    }

    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        require(tokenId >= TokenMetadataStorage.layout().lastUnlockedTokenId, "Metadata: tokenURI locked");
        TokenMetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }

    function _setURISuffix(string memory uriSuffix) internal virtual {
        require(!TokenMetadataStorage.layout().uriSuffixLocked, "Metadata: uriSuffix locked");
        TokenMetadataStorage.layout().uriSuffix = uriSuffix;
    }

    function _lockBaseURI() internal virtual {
        TokenMetadataStorage.layout().baseURILocked = true;
    }

    function _lockFallbackURI() internal virtual {
        TokenMetadataStorage.layout().fallbackURILocked = true;
    }

    function _lockURIUntil(uint256 tokenId) internal virtual {
        TokenMetadataStorage.layout().lastUnlockedTokenId = tokenId;
    }

    function _lockURISuffix() internal virtual {
        TokenMetadataStorage.layout().uriSuffixLocked = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library TokenMetadataStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.TokenMetadata");

    struct Layout {
        string baseURI;
        bool baseURILocked;
        string fallbackURI;
        bool fallbackURILocked;
        string uriSuffix;
        bool uriSuffixLocked;
        uint256 lastUnlockedTokenId;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}