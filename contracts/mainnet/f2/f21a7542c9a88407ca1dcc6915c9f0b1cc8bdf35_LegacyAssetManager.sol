// SPDX-License-Identifier: MIT

// File contracts/interfaces/ILegacyVaultFactory.sol

pragma solidity 0.8.15;

interface ILegacyVaultFactory {
    function createVault(string memory userId, address _memberAddress) external;

    function getVault(address _listedAddress) external view returns (address);

    function getMainWallet(address _listedAddress)
        external
        view
        returns (address);

    function addWallet(string memory userId, address _memberAddress) external;

    function removeWallet(string memory userId, address _memberAddress)
        external;

    function setLegacyAssetManagerAddress(address _VaultAddress) external;

    function pauseContract() external;

    function unpauseContract() external;
}

// File contracts/interfaces/ILegacyVault.sol

pragma solidity 0.8.15;

interface ILegacyVault {
    function transferErc20TokensAllowed(
        address _contractAddress,
        address _ownerAddress,
        address _recipientAddress,
        uint256 _amount
    ) external;

    function transferErc721TokensAllowed(
        address _contractAddress,
        address _ownerAddress,
        address _recipientAddress,
        uint256 _tokenId
    ) external;

    function transferErc1155TokensAllowed(
        address _contractAddress,
        address _ownerAddress,
        address _recipientAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function pauseContract() external;

    function unpauseContract() external;
}

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(
                vs,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File contracts/main/LegacyAssetManager.sol

pragma solidity 0.8.15;

contract LegacyAssetManager is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant LEGACY_ADMIN = keccak256("LEGACY_ADMIN");
    bytes32 public constant ASSET_AUTHORIZER = keccak256("ASSET_AUTHORIZER");

    ILegacyVaultFactory public vaultFactory;
    uint16 public minAdminSignature;
    mapping(address => UserAssets) public userAssets;
    mapping(address => bool) public listedMembers;
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public listedAssets;
    mapping(address => address) public backupWallets;
    mapping(uint256 => bool) public burnedNonces;

    event ERC1155AssetAdded(
        string userId,
        address indexed owner,
        address indexed _contract,
        uint256 indexed tokenId,
        uint256 totalAmount,
        address[] beneficiaries,
        uint8[] beneficiaryPercentages
    );
    event ERC721AssetAdded(
        string userId,
        address indexed owner,
        address indexed _contract,
        uint256 indexed tokenId,
        address beneficiary
    );

    event ERC20AssetAdded(
        string userId,
        address indexed owner,
        address indexed _contract,
        uint256 totalAmount,
        address[] beneficiaries,
        uint8[] beneficiaryPercentages
    );

    event ERC1155AssetRemoved(
        string userId,
        address indexed owner,
        address _contract,
        uint256 indexed tokenId
    );

    event ERC721AssetRemoved(
        string userId,
        address indexed owner,
        address _contract,
        uint256 indexed tokenId
    );

    event ERC20AssetRemoved(
        string userId,
        address indexed owner,
        address indexed _contract
    );

    event ERC1155AssetClaimed(
        string userId,
        address indexed owner,
        address claimer,
        address _contract,
        uint256 indexed tokenId,
        uint256 amount,
        address[] signers
    );

    event ERC721AssetClaimed(
        string userId,
        address indexed owner,
        address claimer,
        address _contract,
        uint256 indexed tokenId,
        address[] signers
    );

    event ERC20AssetClaimed(
        string userId,
        address indexed owner,
        address indexed claimer,
        address _contract,
        uint256 amount,
        address[] signers
    );

    event BackupWalletSwitched(
        string userId,
        address indexed owner,
        address indexed backupwallet
    );

    event BeneficiaryChanged(
        string userId,
        address indexed owner,
        address _contract,
        uint256 tokenId,
        address newBeneficiary
    );

    /**
     * `tokenId` will be `0` in case of ERC20
     */
    event BeneficiaryPercentageChanged(
        string userId,
        address indexed owner,
        address _contract,
        uint256 indexed tokenId,
        address beneficiary,
        uint8 newpercentage
    );

    /**
     * Structs
     */
    struct Beneficiary {
        address account;
        uint8 allowedPercentage;
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    struct ERC1155Asset {
        address owner;
        address _contract;
        uint256 tokenId;
        uint256 totalAmount;
        uint256 totalRemainingAmount;
        uint8 totalPercentage;
        Beneficiary[] beneficiaries;
        uint256 remainingBeneficiaries;
    }

    struct ERC721Asset {
        address owner;
        address _contract;
        uint256 tokenId;
        address beneficiary;
        bool transferStatus;
    }

    struct ERC20Asset {
        address owner;
        address _contract;
        uint256 totalAmount;
        uint256 totalRemainingAmount;
        uint8 totalPercentage;
        Beneficiary[] beneficiaries;
        uint256 remainingBeneficiaries;
    }

    struct UserAssets {
        ERC1155Asset[] erc1155Assets;
        ERC721Asset[] erc721Assets;
        ERC20Asset[] erc20Assets;
        bool backupWalletStatus;
    }

    modifier onlyListedUser(address user) {
        require(listedMembers[user], "LegacyAssetManager: User not listed");
        _;
    }

    modifier assetNotListed(
        address user,
        address _contract,
        uint256 tokenId
    ) {
        require(
            !listedAssets[user][_contract][tokenId],
            "LegacyAssetManager: Asset is already listed"
        );
        _;
    }

    constructor(uint16 _minAdminSignature) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(LEGACY_ADMIN, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ASSET_AUTHORIZER, DEFAULT_ADMIN_ROLE);
        _setupRole(LEGACY_ADMIN, _msgSender());
        _setupRole(ASSET_AUTHORIZER, _msgSender());
        minAdminSignature = _minAdminSignature;
    }

    function createUserVault(
        string calldata userId,
        uint256 nonce,
        bytes calldata signature
    ) external whenNotPaused {
        _authorizeUser(_msgSender(), nonce, signature);
        vaultFactory.createVault(userId, _msgSender());
    }

    function addERC1155Assets(
        string calldata userId,
        address[] memory contracts,
        uint256[] memory tokenIds,
        uint256[] calldata totalAmount,
        address[][] calldata beneficiaryAddresses,
        uint8[][] calldata beneficiaryPercentages
    ) external whenNotPaused nonReentrant onlyListedUser(_msgSender()) {
        require(
            contracts.length == tokenIds.length &&
                tokenIds.length == beneficiaryAddresses.length &&
                beneficiaryAddresses.length == totalAmount.length &&
                totalAmount.length == beneficiaryPercentages.length,
            "LegacyAssetManager: Arguments length mismatch"
        );
        for (uint i = 0; i < contracts.length; i++) {
            _addERC1155Single(
                userId,
                contracts[i],
                tokenIds[i],
                totalAmount[i],
                beneficiaryAddresses[i],
                beneficiaryPercentages[i]
            );
        }
    }

    function _addERC1155Single(
        string memory userId,
        address _contract,
        uint256 tokenId,
        uint256 totalAmount,
        address[] calldata beneficiaryAddresses,
        uint8[] calldata beneficiaryPercentages
    ) internal assetNotListed(_msgSender(), _contract, tokenId) {
        require(
            beneficiaryAddresses.length == beneficiaryPercentages.length,
            "LegacyAssetManager: Arguments length mismatch"
        );
        require(
            IERC1155(_contract).supportsInterface(0xd9b67a26),
            "LegacyAssetManager: Contract is not a valid ERC1155 contract"
        );
        require(
            IERC1155(_contract).balanceOf(_msgSender(), tokenId) > 0 &&
                IERC1155(_contract).balanceOf(_msgSender(), tokenId) >=
                totalAmount,
            "LegacyAssetManager: Insufficient token balance"
        );
        require(
            IERC1155(_contract).isApprovedForAll(
                _msgSender(),
                vaultFactory.getVault(_msgSender())
            ),
            "LegacyAssetManager: Asset not approved"
        );
        uint8 totalPercentage;
        Beneficiary[] memory _beneficiaries = new Beneficiary[](
            beneficiaryAddresses.length
        );
        for (uint i = 0; i < beneficiaryAddresses.length; i++) {
            require(
                beneficiaryPercentages[i] > 0,
                "LegacyAssetManager: Beneficiary percentage must be > 0"
            );
            uint256 amount = (totalAmount * beneficiaryPercentages[i]) / 100;
            _beneficiaries[i] = Beneficiary(
                beneficiaryAddresses[i],
                beneficiaryPercentages[i],
                amount,
                0
            );
            totalPercentage += beneficiaryPercentages[i];
            require(
                totalPercentage <= 100,
                "LegacyAssetManager: Beneficiary percentages exceed 100"
            );
        }
        userAssets[_msgSender()].erc1155Assets.push(
            ERC1155Asset(
                _msgSender(),
                _contract,
                tokenId,
                totalAmount,
                totalAmount,
                totalPercentage,
                _beneficiaries,
                beneficiaryAddresses.length
            )
        );
        listedAssets[_msgSender()][_contract][tokenId] = true;

        emit ERC1155AssetAdded(
            userId,
            _msgSender(),
            _contract,
            tokenId,
            totalAmount,
            beneficiaryAddresses,
            beneficiaryPercentages
        );
    }

    function addERC721Assets(
        string calldata userId,
        address[] calldata _contracts,
        uint256[] calldata tokenIds,
        address[] calldata beneficiaries
    ) external whenNotPaused nonReentrant onlyListedUser(_msgSender()) {
        require(
            _contracts.length == tokenIds.length &&
                tokenIds.length == beneficiaries.length,
            "LegacyAssetManager: Arguments length mismatch"
        );
        for (uint i = 0; i < tokenIds.length; i++) {
            _addERC721Single(
                userId,
                _contracts[i],
                tokenIds[i],
                beneficiaries[i]
            );
        }
    }

    function _addERC721Single(
        string memory userId,
        address _contract,
        uint256 tokenId,
        address beneficiary
    ) internal assetNotListed(_msgSender(), _contract, tokenId) {
        require(
            IERC721(_contract).supportsInterface(0x80ac58cd),
            "LegacyAssetManager: Contract is not a valid ERC721 _contract"
        );
        require(
            IERC721(_contract).ownerOf(tokenId) == _msgSender(),
            "LegacyAssetManager: Caller is not the token owner"
        );
        require(
            IERC721(_contract).getApproved(tokenId) ==
                vaultFactory.getVault(_msgSender()) ||
                IERC721(_contract).isApprovedForAll(
                    _msgSender(),
                    vaultFactory.getVault(_msgSender())
                ),
            "LegacyAssetManager: Asset not approved"
        );
        userAssets[_msgSender()].erc721Assets.push(
            ERC721Asset(_msgSender(), _contract, tokenId, beneficiary, false)
        );
        listedAssets[_msgSender()][_contract][tokenId] = true;

        emit ERC721AssetAdded(
            userId,
            _msgSender(),
            _contract,
            tokenId,
            beneficiary
        );
    }

    function addERC20Assets(
        string calldata userId,
        address[] calldata contracts,
        address[][] calldata beneficiaryAddresses,
        uint8[][] calldata beneficiaryPercentages
    ) external whenNotPaused nonReentrant onlyListedUser(_msgSender()) {
        require(
            contracts.length == beneficiaryAddresses.length &&
                beneficiaryAddresses.length == beneficiaryPercentages.length,
            "LegacyAssetManager: Arguments length mismatch"
        );
        for (uint i = 0; i < contracts.length; i++) {
            _addERC20Single(
                userId,
                contracts[i],
                beneficiaryAddresses[i],
                beneficiaryPercentages[i]
            );
        }
    }

    function _addERC20Single(
        string memory userId,
        address _contract,
        address[] calldata beneficiaryAddresses,
        uint8[] calldata beneficiaryPercentages
    ) internal assetNotListed(_msgSender(), _contract, 0) {
        require(
            beneficiaryAddresses.length == beneficiaryPercentages.length,
            "LegacyAssetManager: Arguments length mismatch"
        );

        uint256 totalAmount = IERC20(_contract).allowance(
            _msgSender(),
            vaultFactory.getVault(_msgSender())
        );
        require(
            totalAmount > 0,
            "LegacyAssetManager: Insufficient allowance for the asset"
        );

        uint8 totalPercentage;
        Beneficiary[] memory _erc20Beneficiaries = new Beneficiary[](
            beneficiaryAddresses.length
        );
        for (uint i = 0; i < beneficiaryAddresses.length; i++) {
            require(
                beneficiaryPercentages[i] > 0,
                "LegacyAssetManager: Beneficiary percentage must be > 0"
            );
            uint256 amount = (totalAmount * beneficiaryPercentages[i]) / 100;
            _erc20Beneficiaries[i] = Beneficiary(
                beneficiaryAddresses[i],
                beneficiaryPercentages[i],
                amount,
                0
            );
            totalPercentage += beneficiaryPercentages[i];
            require(
                totalPercentage <= 100,
                "LegacyAssetManager: Beneficiary percentages exceed 100"
            );
        }
        userAssets[_msgSender()].erc20Assets.push(
            ERC20Asset(
                _msgSender(),
                _contract,
                totalAmount,
                totalAmount,
                totalPercentage,
                _erc20Beneficiaries,
                beneficiaryAddresses.length
            )
        );
        listedAssets[_msgSender()][_contract][0] = true;

        emit ERC20AssetAdded(
            userId,
            _msgSender(),
            _contract,
            totalAmount,
            beneficiaryAddresses,
            beneficiaryPercentages
        );
    }

    function removeERC1155Asset(
        string memory userId,
        address _contract,
        uint256 tokenId
    ) external nonReentrant {
        uint256 assetIndex = _findERC1155AssetIndex(
            _msgSender(),
            _contract,
            tokenId
        );
        require(
            userAssets[_msgSender()]
                .erc1155Assets[assetIndex]
                .remainingBeneficiaries > 0,
            "LegacyAssetManager: Asset has been transferred to the beneficiaries"
        );
        userAssets[_msgSender()].erc1155Assets[assetIndex] = userAssets[
            _msgSender()
        ].erc1155Assets[userAssets[_msgSender()].erc1155Assets.length - 1];
        userAssets[_msgSender()].erc1155Assets.pop();
        listedAssets[_msgSender()][_contract][tokenId] = false;
        emit ERC1155AssetRemoved(userId, _msgSender(), _contract, tokenId);
    }

    function removeERC721Asset(
        string memory userId,
        address _contract,
        uint256 tokenId
    ) external nonReentrant {
        uint256 assetIndex = _findERC721AssetIndex(
            _msgSender(),
            _contract,
            tokenId
        );
        require(
            !userAssets[_msgSender()].erc721Assets[assetIndex].transferStatus,
            "LegacyAssetManager: Asset has been transferred to the beneficiary"
        );
        userAssets[_msgSender()].erc721Assets[assetIndex] = userAssets[
            _msgSender()
        ].erc721Assets[userAssets[_msgSender()].erc721Assets.length - 1];
        userAssets[_msgSender()].erc721Assets.pop();
        listedAssets[_msgSender()][_contract][tokenId] = false;
        emit ERC721AssetRemoved(userId, _msgSender(), _contract, tokenId);
    }

    function removeERC20Asset(string memory userId, address _contract)
        external
        nonReentrant
    {
        uint256 assetIndex = _findERC20AssetIndex(_msgSender(), _contract);
        require(
            userAssets[_msgSender()]
                .erc20Assets[assetIndex]
                .remainingBeneficiaries > 0,
            "LegacyAssetManager: Asset has been transferred to the beneficiaries"
        );
        userAssets[_msgSender()].erc20Assets[assetIndex] = userAssets[
            _msgSender()
        ].erc20Assets[userAssets[_msgSender()].erc20Assets.length - 1];
        userAssets[_msgSender()].erc20Assets.pop();
        listedAssets[_msgSender()][_contract][0] = false;
        emit ERC20AssetRemoved(userId, _msgSender(), _contract);
    }

    function setBackupWallet(address _backupWallet)
        external
        onlyListedUser(_msgSender())
    {
        require(
            !userAssets[_msgSender()].backupWalletStatus,
            "LegacyAssetManager: Backup wallet already switched"
        );
        backupWallets[_msgSender()] = _backupWallet;
    }

    function switchBackupWallet(string memory userId, address owner) external {
        require(
            _msgSender() == backupWallets[owner],
            "LegacyAssetManager: Unauthorized backup wallet transfer call"
        );
        ILegacyVault userVault = ILegacyVault(
            ILegacyVaultFactory(vaultFactory).getVault(owner)
        );
        for (uint i = 0; i < userAssets[owner].erc1155Assets.length; i++) {
            IERC1155 _contract = IERC1155(
                userAssets[owner].erc1155Assets[i]._contract
            );
            uint256 userBalance = _contract.balanceOf(
                owner,
                userAssets[owner].erc1155Assets[i].tokenId
            );
            if (
                userBalance > 0 &&
                _contract.isApprovedForAll(owner, address(userVault))
            ) {
                userVault.transferErc1155TokensAllowed(
                    address(_contract),
                    owner,
                    _msgSender(),
                    userAssets[owner].erc1155Assets[i].tokenId,
                    userBalance
                );
            }
        }
        for (uint i = 0; i < userAssets[owner].erc721Assets.length; i++) {
            IERC721 _contract = IERC721(
                userAssets[owner].erc721Assets[i]._contract
            );
            uint256 tokenId = userAssets[owner].erc721Assets[i].tokenId;
            if (_contract.ownerOf(tokenId) == owner) {
                userVault.transferErc721TokensAllowed(
                    address(_contract),
                    owner,
                    _msgSender(),
                    tokenId
                );
            }
        }
        for (uint i = 0; i < userAssets[owner].erc20Assets.length; i++) {
            IERC20 _contract = IERC20(
                userAssets[owner].erc20Assets[i]._contract
            );
            uint256 userBalance = _contract.balanceOf(owner);
            uint256 allowance = _contract.allowance(owner, address(userVault));
            if (userBalance > 0 && userBalance >= allowance) {
                userVault.transferErc20TokensAllowed(
                    address(_contract),
                    owner,
                    _msgSender(),
                    allowance
                );
            } else if (userBalance > 0 && userBalance < allowance) {
                userVault.transferErc20TokensAllowed(
                    address(_contract),
                    owner,
                    _msgSender(),
                    userBalance
                );
            }
        }
        userAssets[owner].backupWalletStatus = true;
        emit BackupWalletSwitched(userId, owner, _msgSender());
    }

    function claimERC1155Asset(
        string memory userId,
        address owner,
        address _contract,
        uint256 tokenId,
        uint256 nonce,
        bytes[] calldata signatures
    ) external whenNotPaused nonReentrant {
        bytes32 hashedMessage = keccak256(
            abi.encodePacked(owner, _msgSender(), _contract, tokenId, nonce)
        );
        address[] memory signers = _verifySigners(
            hashedMessage,
            nonce,
            signatures
        );
        uint256 assetIndex = _findERC1155AssetIndex(owner, _contract, tokenId);
        uint256 beneficiaryIndex = _findERC1155BeneficiaryIndex(
            _msgSender(),
            userAssets[owner].erc1155Assets[assetIndex]
        );

        uint256 remainingAmount = userAssets[owner]
            .erc1155Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .totalAmount -
            userAssets[owner]
                .erc1155Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .claimedAmount;
        require(
            remainingAmount > 0,
            "LegacyAssetManager: Beneficiary has already claimed the asset"
        );

        address vaultAddress = vaultFactory.getVault(owner);
        address currentOwner;
        if (userAssets[owner].backupWalletStatus) {
            currentOwner = backupWallets[owner];
        } else {
            currentOwner = owner;
        }

        uint256 ownerBalance = IERC1155(_contract).balanceOf(
            currentOwner,
            tokenId
        );
        require(
            ownerBalance > 0,
            "LegacyAssetManager: Owner has zero balance for this asset"
        );

        uint8 allowedPercentage = userAssets[owner]
            .erc1155Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .allowedPercentage;

        uint256 dueAmount;
        if (
            ownerBalance >=
            userAssets[owner].erc1155Assets[assetIndex].totalRemainingAmount ||
            ((ownerBalance * allowedPercentage) / 100) > remainingAmount
        ) {
            dueAmount = remainingAmount;
        } else {
            dueAmount = (ownerBalance * allowedPercentage) / 100;
        }

        userAssets[owner]
            .erc1155Assets[assetIndex]
            .totalRemainingAmount -= dueAmount;
        userAssets[owner]
            .erc1155Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .claimedAmount += dueAmount;
        if (
            userAssets[owner]
                .erc1155Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .claimedAmount ==
            userAssets[owner]
                .erc1155Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .totalAmount
        ) {
            userAssets[owner]
                .erc1155Assets[assetIndex]
                .remainingBeneficiaries--;
        }

        ILegacyVault(vaultAddress).transferErc1155TokensAllowed(
            _contract,
            currentOwner,
            _msgSender(),
            tokenId,
            dueAmount
        );

        emit ERC1155AssetClaimed(
            userId,
            owner,
            _msgSender(),
            _contract,
            tokenId,
            dueAmount,
            signers
        );
    }

    function claimERC721Asset(
        string memory userId,
        address owner,
        address _contract,
        uint256 tokenId,
        uint256 nonce,
        bytes[] calldata signatures
    ) external whenNotPaused nonReentrant {
        bytes32 hashedMessage = keccak256(
            abi.encodePacked(owner, _msgSender(), _contract, tokenId, nonce)
        );
        address[] memory signers = _verifySigners(
            hashedMessage,
            nonce,
            signatures
        );
        uint256 assetIndex = _findERC721AssetIndex(owner, _contract, tokenId);

        require(
            !userAssets[owner].erc721Assets[assetIndex].transferStatus,
            "LegacyAssetManager: Beneficiary has already claimed the asset"
        );
        require(
            userAssets[owner].erc721Assets[assetIndex].beneficiary ==
                _msgSender(),
            "LegacyAssetManager: Unauthorized claim call"
        );

        address vaultAddress = vaultFactory.getVault(owner);
        address from;
        if (userAssets[owner].backupWalletStatus) {
            from = backupWallets[owner];
        } else {
            from = owner;
        }

        ILegacyVault(vaultAddress).transferErc721TokensAllowed(
            _contract,
            from,
            _msgSender(),
            tokenId
        );
        userAssets[owner].erc721Assets[assetIndex].transferStatus = true;
        emit ERC721AssetClaimed(
            userId,
            owner,
            _msgSender(),
            _contract,
            tokenId,
            signers
        );
    }

    function claimERC20Asset(
        string memory userId,
        address owner,
        address _contract,
        uint256 nonce,
        bytes[] calldata signatures
    ) external whenNotPaused nonReentrant {
        bytes32 hashedMessage = keccak256(
            abi.encodePacked(owner, _msgSender(), _contract, nonce)
        );
        address[] memory signers = _verifySigners(
            hashedMessage,
            nonce,
            signatures
        );
        uint256 assetIndex = _findERC20AssetIndex(owner, _contract);

        uint256 beneficiaryIndex = _findERC20BeneficiaryIndex(
            _msgSender(),
            userAssets[owner].erc20Assets[assetIndex]
        );

        uint256 remainingAmount = userAssets[owner]
            .erc20Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .totalAmount -
            userAssets[owner]
                .erc20Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .claimedAmount;
        require(
            remainingAmount > 0,
            "LegacyAssetManager: Beneficiary has already claimed the asset"
        );

        address vaultAddress = vaultFactory.getVault(owner);
        address currentOwner;
        if (userAssets[owner].backupWalletStatus) {
            currentOwner = backupWallets[owner];
        } else {
            currentOwner = owner;
        }

        uint256 ownerBalance = IERC20(_contract).balanceOf(currentOwner);
        uint256 allowance = IERC20(_contract).allowance(
            currentOwner,
            vaultAddress
        );
        require(
            ownerBalance > 0 && allowance > 0,
            "LegacyAssetManager: Owner has zero balance or zero allowance for this asset"
        );

        if (
            userAssets[owner].erc20Assets[assetIndex].beneficiaries.length ==
            userAssets[owner].erc20Assets[assetIndex].remainingBeneficiaries &&
            allowance != userAssets[owner].erc20Assets[assetIndex].totalAmount
        ) {
            userAssets[owner].erc20Assets[assetIndex].totalAmount = allowance;
        }

        uint8 allowedPercentage = userAssets[owner]
            .erc20Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .allowedPercentage;

        if (
            userAssets[owner]
                .erc20Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .claimedAmount == 0
        ) {
            uint256 currentAmount = (userAssets[owner]
                .erc20Assets[assetIndex]
                .totalAmount * allowedPercentage) / 100;
            if (
                currentAmount !=
                userAssets[owner]
                    .erc20Assets[assetIndex]
                    .beneficiaries[beneficiaryIndex]
                    .totalAmount
            ) {
                userAssets[owner]
                    .erc20Assets[assetIndex]
                    .beneficiaries[beneficiaryIndex]
                    .totalAmount = currentAmount;
            }
        }

        uint256 dueAmount;
        if (
            ownerBalance >=
            userAssets[owner].erc20Assets[assetIndex].totalRemainingAmount ||
            ((ownerBalance * allowedPercentage) / 100) > remainingAmount
        ) {
            dueAmount = remainingAmount;
        } else {
            dueAmount = (ownerBalance * allowedPercentage) / 100;
        }

        userAssets[owner]
            .erc20Assets[assetIndex]
            .totalRemainingAmount -= dueAmount;
        userAssets[owner]
            .erc20Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .claimedAmount += dueAmount;
        if (
            userAssets[owner]
                .erc20Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .claimedAmount ==
            userAssets[owner]
                .erc20Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .totalAmount
        ) {
            userAssets[owner].erc20Assets[assetIndex].remainingBeneficiaries--;
        }
        ILegacyVault(vaultAddress).transferErc20TokensAllowed(
            _contract,
            currentOwner,
            _msgSender(),
            dueAmount
        );

        emit ERC20AssetClaimed(
            userId,
            owner,
            _msgSender(),
            _contract,
            dueAmount,
            signers
        );
    }

    function _findERC1155AssetIndex(
        address user,
        address _contract,
        uint256 tokenId
    ) internal view returns (uint256) {
        for (uint i = 0; i < userAssets[user].erc1155Assets.length; i++) {
            if (
                userAssets[user].erc1155Assets[i]._contract == _contract &&
                userAssets[user].erc1155Assets[i].tokenId == tokenId
            ) {
                return i;
            }
        }
        revert("LegacyAssetManager: Asset not found");
    }

    function _findERC721AssetIndex(
        address user,
        address _contract,
        uint256 tokenId
    ) internal view returns (uint256) {
        for (uint i = 0; i < userAssets[user].erc721Assets.length; i++) {
            if (
                userAssets[user].erc721Assets[i]._contract == _contract &&
                userAssets[user].erc721Assets[i].tokenId == tokenId
            ) {
                return i;
            }
        }
        revert("LegacyAssetManager: Asset not found");
    }

    function _findERC20AssetIndex(address user, address _contract)
        internal
        view
        returns (uint256)
    {
        for (uint i = 0; i < userAssets[user].erc20Assets.length; i++) {
            if (userAssets[user].erc20Assets[i]._contract == _contract) {
                return i;
            }
        }
        revert("LegacyAssetManager: Asset not found");
    }

    function _findERC1155BeneficiaryIndex(
        address beneficiary,
        ERC1155Asset memory erc1155Asset
    ) internal pure returns (uint256) {
        for (uint i = 0; i < erc1155Asset.beneficiaries.length; i++) {
            if (erc1155Asset.beneficiaries[i].account == beneficiary) {
                return i;
            }
        }
        revert("LegacyAssetManager: Beneficiary not found");
    }

    function _findERC20BeneficiaryIndex(
        address beneficiary,
        ERC20Asset memory erc20Asset
    ) internal pure returns (uint256) {
        for (uint i = 0; i < erc20Asset.beneficiaries.length; i++) {
            if (erc20Asset.beneficiaries[i].account == beneficiary) {
                return i;
            }
        }
        revert("LegacyAssetManager: Beneficiary not found");
    }

    function setERC1155BeneficiaryPercentage(
        string memory userId,
        address _contract,
        uint256 tokenId,
        address beneficiary,
        uint8 newPercentage
    ) external {
        uint256 assetIndex = _findERC1155AssetIndex(
            _msgSender(),
            _contract,
            tokenId
        );
        uint256 beneficiaryIndex = _findERC1155BeneficiaryIndex(
            beneficiary,
            userAssets[_msgSender()].erc1155Assets[assetIndex]
        );
        require(
            userAssets[_msgSender()]
                .erc1155Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .totalAmount -
                userAssets[_msgSender()]
                    .erc1155Assets[assetIndex]
                    .beneficiaries[beneficiaryIndex]
                    .claimedAmount >
                0,
            "LegacyAssetManager: Beneficiary has already claimed the asset"
        );
        uint8 currentPercentage = userAssets[_msgSender()]
            .erc1155Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .allowedPercentage;
        require(
            (userAssets[_msgSender()]
                .erc1155Assets[assetIndex]
                .totalPercentage - currentPercentage) +
                newPercentage <=
                100,
            "LegacyAssetManager: Beneficiary percentage exceeds total of 100"
        );
        userAssets[_msgSender()]
            .erc1155Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .allowedPercentage = newPercentage;
        userAssets[_msgSender()].erc1155Assets[assetIndex].totalPercentage =
            (userAssets[_msgSender()]
                .erc1155Assets[assetIndex]
                .totalPercentage - currentPercentage) +
            newPercentage;
        emit BeneficiaryPercentageChanged(
            userId,
            _msgSender(),
            _contract,
            tokenId,
            beneficiary,
            newPercentage
        );
    }

    function setERC721Beneficiary(
        string memory userId,
        address _contract,
        uint256 tokenId,
        address newBeneficiary
    ) external {
        uint256 assetIndex = _findERC721AssetIndex(
            _msgSender(),
            _contract,
            tokenId
        );
        require(
            !userAssets[_msgSender()].erc721Assets[assetIndex].transferStatus,
            "LegacyAssetManager: Asset has been claimed"
        );
        userAssets[_msgSender()]
            .erc721Assets[assetIndex]
            .beneficiary = newBeneficiary;
        emit BeneficiaryChanged(
            userId,
            _msgSender(),
            _contract,
            tokenId,
            newBeneficiary
        );
    }

    function setERC20BeneficiaryPercentage(
        string memory userId,
        address _contract,
        address beneficiary,
        uint8 newPercentage
    ) external {
        uint256 assetIndex = _findERC20AssetIndex(_msgSender(), _contract);
        uint256 beneficiaryIndex = _findERC20BeneficiaryIndex(
            beneficiary,
            userAssets[_msgSender()].erc20Assets[assetIndex]
        );
        require(
            userAssets[_msgSender()]
                .erc20Assets[assetIndex]
                .beneficiaries[beneficiaryIndex]
                .totalAmount -
                userAssets[_msgSender()]
                    .erc20Assets[assetIndex]
                    .beneficiaries[beneficiaryIndex]
                    .claimedAmount >
                0,
            "LegacyAssetManager: Beneficiary has already claimed the asset"
        );
        uint8 currentPercentage = userAssets[_msgSender()]
            .erc20Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .allowedPercentage;
        require(
            (userAssets[_msgSender()].erc20Assets[assetIndex].totalPercentage -
                currentPercentage) +
                newPercentage <=
                100,
            "LegacyAssetManager: Beneficiary percentage exceeds 100"
        );
        userAssets[_msgSender()]
            .erc20Assets[assetIndex]
            .beneficiaries[beneficiaryIndex]
            .allowedPercentage = newPercentage;
        userAssets[_msgSender()].erc20Assets[assetIndex].totalPercentage =
            (userAssets[_msgSender()].erc20Assets[assetIndex].totalPercentage -
                currentPercentage) +
            newPercentage;
        emit BeneficiaryPercentageChanged(
            userId,
            _msgSender(),
            _contract,
            0,
            beneficiary,
            newPercentage
        );
    }

    function setVaultFactory(address _vaultFactory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vaultFactory = ILegacyVaultFactory(_vaultFactory);
    }

    function setMinAdminSignature(uint16 _minAdminSignature)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minAdminSignature = _minAdminSignature;
    }

    function _authorizeUser(
        address user,
        uint256 nonce,
        bytes calldata signature
    ) internal {
        if (!listedMembers[user]) {
            require(
                !burnedNonces[nonce],
                "LegacyAssetManger: Nonce already used"
            );
            bytes32 hashedMessage = keccak256(abi.encodePacked(user, nonce));
            address signer = _verifySignature(hashedMessage, signature);
            require(
                hasRole(ASSET_AUTHORIZER, signer),
                "LegacyAssetManager: Unauthorized signature"
            );
            burnedNonces[nonce] = true;
            listedMembers[user] = true;
        }
    }

    function _verifySigners(
        bytes32 hashedMessage,
        uint256 nonce,
        bytes[] calldata signatures
    ) internal returns (address[] memory) {
        require(
            signatures.length >= minAdminSignature,
            "LegacyAssetManger: Signatures are less than minimum required"
        );
        require(!burnedNonces[nonce], "LegacyAssetManger: Nonce already used");
        address[] memory signers = new address[](signatures.length);
        for (uint i = 0; i < signatures.length; i++) {
            address signer = _verifySignature(hashedMessage, signatures[i]);
            require(
                hasRole(LEGACY_ADMIN, signer),
                "LegacyAssetManager: Unauthorized signature"
            );
            signers[i] = signer;
            for (uint j = signers.length - 1; j != 0; j--) {
                require(
                    signers[j] != signers[j - 1],
                    "LegacyAssetManager: Duplicate signature not allowed"
                );
            }
        }
        burnedNonces[nonce] = true;
        return signers;
    }

    function _verifySignature(bytes32 _hashedMessage, bytes calldata signature)
        internal
        pure
        returns (address)
    {
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            _hashedMessage
        );
        return ECDSA.recover(ethSignedMessageHash, signature);
    }

    function pauseContract()
        external
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _pause();
    }

    function unpauseContract()
        external
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _unpause();
    }

    function withdrawEther(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(to).transfer(address(this).balance);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}