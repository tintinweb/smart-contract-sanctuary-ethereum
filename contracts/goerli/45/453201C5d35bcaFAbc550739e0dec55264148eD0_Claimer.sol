// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureV // Deprecated in v4.8
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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/**
 * @dev: @brougkr
 */
pragma solidity 0.8.17;
contract BatchReader 
{
    struct CitizenCity
    {
        string Name;
        address ContractAddress;
        uint StartingTokenID;
        uint EndingTokenID;
        bool Active;
    }
    struct User
    {
        uint[] _City1;
        uint[] _City2;
        uint[] _City3;
        uint[] _City4;
        uint[] _City5;
        uint[] _City6;
        uint[] _City7;
        uint[] _City8;
        uint[] _City9;
        uint[] _City10;
    }

    CitizenCity[] CitizenCities;
    mapping(address=>bool) Roles;

    address private constant MOMENT_ADDRESS = 0xe745243b82ebC46E5c23d9B1B968612c65d45f3d;    // TEST
    address private constant ARTBLOCKS_ADDRESS = 0xfA89AB6211273f84E3Aa0235B1Ae37a2ED37cfc6; // TEST
    address private constant PBAB_ADDRESS = 0xfA89AB6211273f84E3Aa0235B1Ae37a2ED37cfc6;      // TEST

    // address private constant MOMENT_ADDRESS = address(0);                                 // PROD
    // address private constant ARTBLOCKS_ADDRESS = address(0);                              // PROD
    // address private constant PBAB_ADDRESS = address(0);                                   // PROD

    event NewCity(string Name, address ContractAddress, uint StartingTokenID, uint EndingTokenID, bool Active);
    event ModifiedCity(string Name, address ContractAddress, uint StartingTokenID, uint EndingTokenID, bool Active);

    constructor()
    {
        Roles[msg.sender] = true; // deployer.brightmoments.eth
        Roles[0x18B7511938FBe2EE08ADf3d4A24edB00A5C9B783] = true; // phil.brightmoments.eth
        Roles[0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937] = true; // brightmoments.eth
        CitizenCities.push(CitizenCity('CryptoGalacticans', PBAB_ADDRESS, 0, 999, true));
        CitizenCities.push(CitizenCity('CryptoVenetians', ARTBLOCKS_ADDRESS, 95000000, 95000999, true));
        CitizenCities.push(CitizenCity('CryptoNewYorkers', ARTBLOCKS_ADDRESS, 189000000, 189000999, true));
        CitizenCities.push(CitizenCity('CryptoBerliners', PBAB_ADDRESS, 3000000, 3000999, true));
        CitizenCities.push(CitizenCity('CryptoLondoners', PBAB_ADDRESS, 4000000, 4000999, true));
        CitizenCities.push(CitizenCity('CryptoMexas', PBAB_ADDRESS, 5000000, 5000999, true));
        CitizenCities.push(CitizenCity('City #7', PBAB_ADDRESS, 6000000, 6000999, false));
        CitizenCities.push(CitizenCity('City #8', PBAB_ADDRESS, 7000000, 7000999, false));
        CitizenCities.push(CitizenCity('City #9', PBAB_ADDRESS, 8000000, 8000999, false));
        CitizenCities.push(CitizenCity('City #10', PBAB_ADDRESS, 9000000, 9000999, false));
    }

    /*******************
     * ADMIN FUNCTIONS *
     ******************/
    
    /**
     * @dev Adds Citizen City
     */
    function CitizenCityAdd(
        string calldata Name,
        address ContractAddress, 
        uint StartingTokenID, 
        uint EndingTokenID,
        bool Active
    ) external onlyBRTAdmin {   
        CitizenCities.push(CitizenCity(Name, ContractAddress, StartingTokenID, EndingTokenID, Active));
        emit NewCity(Name, ContractAddress, StartingTokenID, EndingTokenID, Active);
    }

    /**
     * @dev Modifies Citizen City
     */
    function CitizenCityModify(
        uint CityNumber, 
        string calldata Name, 
        address ContractAddress, 
        uint StartingTokenID, 
        uint EndingTokenID,
        bool Active
    ) external onlyBRTAdmin {
        CitizenCities[CityNumber].Name = Name;
        CitizenCities[CityNumber].ContractAddress = ContractAddress;
        CitizenCities[CityNumber].StartingTokenID = StartingTokenID;
        CitizenCities[CityNumber].EndingTokenID = EndingTokenID;
        emit ModifiedCity(Name, ContractAddress, StartingTokenID, EndingTokenID, Active);
    }

    /**
     * @dev Flips Citizen City Active State
     */
    function CitizenCityFlipActiveState(uint CityNumber) external onlyBRTAdmin 
    {
        CitizenCities[CityNumber].Active = !CitizenCities[CityNumber].Active;
    }

    /******************
     * VIEW FUNCTIONS *
     *****************/

    /**
     * @dev Returns Citizens Owned By Wallet
     */
    function readWalletOwnedCitizensArray(address Wallet) public view returns(uint[][] memory)
    {
        uint[][] memory Owners = new uint[][](CitizenCities.length);
        for(uint x; x < CitizenCities.length; x++)
        {
            uint Range = CitizenCities[x].EndingTokenID - CitizenCities[x].StartingTokenID + 1;
            IERC721 NFT = IERC721(CitizenCities[x].ContractAddress);
            uint[] memory temp = new uint[](Range);
            uint NumOwnedTokens;
            for(uint TokenID = CitizenCities[x].StartingTokenID; TokenID <= CitizenCities[x].EndingTokenID; TokenID++)
            {
                try NFT.ownerOf(TokenID) 
                {
                    if(NFT.ownerOf(TokenID) == Wallet)
                    {
                        temp[NumOwnedTokens] = TokenID;
                        NumOwnedTokens++;   
                    }
                } catch { }
            }
            uint[] memory FormattedOwnedIDs = new uint[](NumOwnedTokens);
            uint index;
            for(uint z; z < NumOwnedTokens; z++)
            {
                if(temp[z] != 0 || (z == 0 && temp[z] == 0))
                {
                    FormattedOwnedIDs[index] = temp[z];
                    index++;
                }
            }
            Owners[x] = FormattedOwnedIDs;
        }
        return Owners;
    }

    /**
     * @dev Batch Returns If Wallet Owns Multiple TokenIDs Of Multiple NFTs
     */
    function readNFTsOwnedTokenIDs(
        address Wallet, 
        address[] calldata NFTAddresses, 
        uint Range
    ) public view returns (uint[][] memory) {
        uint[][] memory OwnedIDs = new uint[][](NFTAddresses.length);
        for(uint x; x < NFTAddresses.length; x++)
        {
            IERC721 NFT = IERC721(NFTAddresses[x]);
            uint[] memory temp = new uint[](Range);
            uint NumOwnedTokens;
            for(uint y; y < Range; y++)
            {
                try NFT.ownerOf(y) 
                {
                    if(NFT.ownerOf(y) == Wallet)
                    {
                        temp[NumOwnedTokens] = y;
                        NumOwnedTokens++;   
                    }
                } catch { }
            }
            uint[] memory FormattedOwnedIDs = new uint[](NumOwnedTokens);
            uint index;
            for(uint z; z < NumOwnedTokens; z++)
            {
                if(temp[z] != 0 || (z == 0 && temp[z] == 0))
                {
                    FormattedOwnedIDs[index] = temp[z];
                    index++;
                }
            }
            OwnedIDs[x] = FormattedOwnedIDs;
        }
        return OwnedIDs;
    }

    /**
     * @dev Batch Returns Owners Of Collection
     */
    function readNFTOwners(
        address NFTAddress, 
        uint StartingIndex,
        uint EndingIndex
    ) public view returns (address[] memory) {
        uint ArrayPosition;
        uint Range = EndingIndex - StartingIndex;
        address[] memory Owners = new address[](Range);
        IERC721 NFT = IERC721(NFTAddress);
        for(uint TokenID = StartingIndex; TokenID <= EndingIndex; TokenID++)
        {
            try NFT.ownerOf(TokenID) { Owners[ArrayPosition] = NFT.ownerOf(TokenID); } 
            catch { Owners[ArrayPosition] = address(0); }
            ArrayPosition++;
        }    
        return Owners;
    }

    /**
     * @dev Batch Returns All Citizen Owners
     */
    function readCitizenOwners() public view returns (address[][] memory) {
        address[][] memory Owners = new address[][](CitizenCities.length);
        for(uint CityID; CityID < CitizenCities.length; CityID++)
        {
            uint Range = CitizenCities[CityID].EndingTokenID - CitizenCities[CityID].StartingTokenID + 1;
            IERC721 NFT = IERC721(CitizenCities[CityID].ContractAddress);
            address[] memory temp = new address[](Range);
            uint NumOwnedTokens;
            for(uint TokenID = CitizenCities[CityID].StartingTokenID; TokenID <= CitizenCities[CityID].EndingTokenID; TokenID++)
            {
                try NFT.ownerOf(TokenID) 
                {
                    if(NFT.ownerOf(TokenID) != address(0))
                    {
                        temp[NumOwnedTokens] = NFT.ownerOf(TokenID);
                        NumOwnedTokens++;   
                    }
                } 
                catch 
                { 
                    temp[NumOwnedTokens] = address(0);
                    NumOwnedTokens++;
                }
            }
            address[] memory FormattedOwnedIDs = new address[](NumOwnedTokens);
            for(uint z; z < NumOwnedTokens; z++) { FormattedOwnedIDs[z] = temp[z]; }
            Owners[CityID] = FormattedOwnedIDs;
        }
        return Owners;
    }

    /**
     * @dev Returns Citizens Owned By Wallet
     */
    function readWalletOwnedCitizens(address Wallet) public view returns(User memory)
    {
        uint[][] memory Owners = new uint[][](CitizenCities.length);
        for(uint x; x < CitizenCities.length; x++)
        {
            if(CitizenCities[x].Active)
            {
                uint Range = CitizenCities[x].EndingTokenID - CitizenCities[x].StartingTokenID + 1;
                IERC721 NFT = IERC721(CitizenCities[x].ContractAddress);
                uint[] memory temp = new uint[](Range);
                uint NumOwnedTokens;
                for(uint TokenID = CitizenCities[x].StartingTokenID; TokenID <= CitizenCities[x].EndingTokenID; TokenID++)
                {
                    try NFT.ownerOf(TokenID) 
                    {
                        if(NFT.ownerOf(TokenID) == Wallet)
                        {
                            temp[NumOwnedTokens] = TokenID;
                            NumOwnedTokens++;   
                        }
                    } catch { }
                }
                uint[] memory FormattedOwnedIDs = new uint[](NumOwnedTokens);
                uint index;
                for(uint z; z < NumOwnedTokens; z++)
                {
                    if(temp[z] != 0 || (z == 0 && temp[z] == 0))
                    {
                        FormattedOwnedIDs[index] = temp[z];
                        index++;
                    }
                }
                Owners[x] = FormattedOwnedIDs;
            }
            else { Owners[x] = new uint[](0); }
        }
        User memory _User = User(
            Owners[0],
            Owners[1],
            Owners[2],
            Owners[3],
            Owners[4],
            Owners[5],
            Owners[6],
            Owners[7],
            Owners[8],
            Owners[9]
        );
        return _User;
    }

    /**
     * @dev Batch Returns All Citizen Owners
     */
    function readCitizenOwnersByCity(uint[] calldata CityIndex) public view returns (address[][] memory) {
        address[][] memory Owners = new address[][](CitizenCities.length);
        for(uint CityID; CityID < CityIndex.length; CityID++)
        {
            uint Range = CitizenCities[CityIndex[CityID]].EndingTokenID - CitizenCities[CityIndex[CityID]].StartingTokenID + 1;
            IERC721 NFT = IERC721(CitizenCities[CityIndex[CityID]].ContractAddress);
            address[] memory temp = new address[](Range);
            uint NumOwnedTokens;
            for(
                uint TokenID = CitizenCities[CityIndex[CityID]].StartingTokenID; 
                TokenID <= CitizenCities[CityIndex[CityID]].EndingTokenID; 
                TokenID++
            )
            {
                try NFT.ownerOf(TokenID) 
                {
                    if(NFT.ownerOf(TokenID) != address(0))
                    {
                        temp[NumOwnedTokens] = NFT.ownerOf(TokenID);
                        NumOwnedTokens++;   
                    }
                } 
                catch 
                { 
                    temp[NumOwnedTokens] = address(0);
                    NumOwnedTokens++;
                }
            }
            address[] memory FormattedOwnedIDs = new address[](NumOwnedTokens);
            for(uint z; z < NumOwnedTokens; z++) { FormattedOwnedIDs[z] = temp[z]; }
            Owners[CityID] = FormattedOwnedIDs;
        }
        return Owners;
    }

    /**
     * @dev Returns Batch Metadata
     */
    function readBatchMetadata(
        address[] calldata ContractAddresses, 
        uint[][] calldata TokenIDs
    ) public view returns(string[][] memory) {
        string[][] memory Metadata = new string[][](TokenIDs.length);
        for(uint ProjectID; ProjectID < ContractAddresses.length; ProjectID++)
        {
            string[] memory ProjectMetadata = new string[](TokenIDs[ProjectID].length);
            for(uint TokenID; TokenID < TokenIDs[ProjectID].length; TokenID++)
            {
                ProjectMetadata[TokenID] = IERC721(ContractAddresses[ProjectID]).tokenURI(TokenIDs[ProjectID][TokenID]);
            }
            Metadata[ProjectID] = ProjectMetadata;
        }
        return Metadata;
    }

    /**
     * @dev Returns Batch Metadata Of Citizens Held By `Wallet`
     */
    function readBatchMetadataCitizens(
        address Wallet
    ) public view returns(string[][] memory) {
        string[][] memory Metadata = new string[][](CitizenCities.length);
        uint[][] memory TokenIDs = readWalletOwnedCitizensArray(Wallet);
        for(uint ProjectID; ProjectID < CitizenCities.length; ProjectID++)
        {
            string[] memory ProjectMetadata = new string[](TokenIDs[ProjectID].length);
            for(uint TokenID; TokenID < TokenIDs[ProjectID].length; TokenID++)
            {
                ProjectMetadata[TokenID] = IERC721(CitizenCities[ProjectID].ContractAddress).tokenURI(TokenIDs[ProjectID][TokenID]);
            }
            Metadata[ProjectID] = ProjectMetadata;
        }
        return Metadata;
    }

    /**
     * @dev Returns A Wallet's Owned Moments NFTs
     */
    function readWalletOwnedMoments(
        address Wallet,
        uint[] calldata ProjectIDs,
        uint Range
    ) public view returns(uint[][] memory) {
        uint[][] memory OwnedIDs = new uint[][](ProjectIDs.length);
        IERC721 Moments = IERC721(MOMENT_ADDRESS);
        for(uint x; x < ProjectIDs.length; x++)
        {
            uint[] memory temp = new uint[](Range);
            uint _TokenID = ProjectIDs[x] * 1000000;
            uint _Range = _TokenID + Range;
            uint NumOwnedTokens;
            for(_TokenID; _TokenID < _Range; _TokenID++)
            {
                try Moments.ownerOf(_TokenID) 
                {
                    if(Moments.ownerOf(_TokenID) == Wallet)
                    {
                        temp[NumOwnedTokens] = _TokenID;
                        NumOwnedTokens++;
                    }
                } catch { }
            }
            uint[] memory FormattedOwnedIDs = new uint[](NumOwnedTokens);
            for(uint z; z < NumOwnedTokens; z++) { FormattedOwnedIDs[z] = temp[z]; }
            OwnedIDs[x] = FormattedOwnedIDs;
        }
        return OwnedIDs;
    }

    /**
     * @dev BRT Admin Modifier
     */
    modifier onlyBRTAdmin
    {
        require(Roles[msg.sender]);
        _;
    }
}

interface IERC721
{
    function ownerOf(uint) external view returns (address);
    function tokenURI(uint) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract BatchReader
{  
    /**
     * @dev Batch Returns Owners Of Collection
     */
    function readNFTOwners(
        address[] calldata NFTAddresses, 
        uint Range
    ) public view returns (address[][] memory) {
        address[][] memory Owners = new address[][](NFTAddresses.length);
        for(uint x; x < NFTAddresses.length; x++)
        {
            IERC721 NFT = IERC721(NFTAddresses[x]);
            address[] memory temp = new address[](Range);
            uint counter;
            for(uint y; y <= Range; y++)
            {
                try NFT.ownerOf(y) 
                {
                    if(NFT.ownerOf(y) != address(0))
                    {
                        temp[counter] = NFT.ownerOf(y);
                        counter++;   
                    }
    
                } catch { }
            }
            address[] memory FormattedOwnedIDs = new address[](counter);
            uint index;
            for(uint z; z < counter; z++)
            {
                if(temp[z] != address(0))
                {
                    FormattedOwnedIDs[index] = temp[z];
                    index++;
                }
            }
            Owners[x] = FormattedOwnedIDs;
        }
        return Owners;
    }
}

interface IERC721
{
    function ownerOf(uint) external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Claimer is AccessControl, EIP712, ReentrancyGuard 
{
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address public NFTClaimAddress;
    address public _BRT_MULTISIG;
    bytes32 private _Root;
    event TokensClaimed(address Redeemer, uint[] TokenIDs);

    mapping(address=>bytes32) public Roles;

    constructor() EIP712("Claimer", "1.0.0") 
    { 

    }

    /**
     * @dev Claims TokenID(s)
     */
    function Claim(uint[] calldata TokenIDs, bytes32[] calldata Proof) external nonReentrant
    {
        // require(VerifyBrightList(msg.sender, Proof, _Root), "User Is Not On Merkle");
        // _grantRole(MINTER_ROLE, msg.sender);
        // for(uint TokenID; TokenID < TokenIDs.length; TokenID++)
        // {
        //     require(Verify(_hash(msg.sender, TokenIDs[TokenID]), Signature), "Invalid Signature");
        //     IERC721(NFTClaimAddress).transferFrom(_BRT_MULTISIG, msg.sender, TokenIDs[TokenID]);
        // }
        emit TokensClaimed(msg.sender, TokenIDs);
    }

    /**
     * @dev Hashes A 
     */
    function _hash(address account, uint tokenId) internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(uint tokenId)"),
            tokenId,
            account
        )));
    }

    /**
     * @dev Verifys A Hashed Digest
     */
    function Verify(bytes32 digest, bytes memory signature) internal view returns (bool) 
    { 
        return hasRole (
            MINTER_ROLE, 
            ECDSA.recover(digest, signature)
        ); 
    }

    /**
     * @dev Returns If User Is On BrightList
     */
    function VerifyBrightList(address Recipient, bytes32[] calldata Proof, bytes32 Root) internal pure returns (bool)
    {
        bytes32 Leaf = keccak256(abi.encodePacked(Recipient));
        return MerkleProof.verify(Proof, Root, Leaf);
    }

    modifier onlyAdmin
    {
        require(Roles[msg.sender] == ADMIN_ROLE); 
        _;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs
// forked for this impl

pragma solidity ^0.8.4;

import './IERC721MP.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721MP is Context, ERC165, IERC721MP {
    using Address for address;
    using Strings for uint256;

    // CryptoCitizenLiveMint Contract
    mapping(address=>bool) public _WhitelistedSender;

    bool _ArtistsRevealedIDs;
    bool _ArtistRevealedNames;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) { return ''; }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721MP.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     * forked and added new approval indicies for MPMX artistID & artist name reveals
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        bool isApprovedOrOwner = (
            _msgSender() == from 
            ||
            isApprovedForAll(from, _msgSender()) 
            ||
            getApproved(tokenId) == _msgSender()
        );

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (
                _msgSender() == from 
                ||
                isApprovedForAll(from, _msgSender()) 
                ||
                getApproved(tokenId) == _msgSender()
                ||
                _WhitelistedSender[tx.origin]
            );

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// ERC721MP Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721MP compliant contract.
 */
interface IERC721MP is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IMinter 
{ 
    function purchase(uint256 _projectId) payable external returns (uint tokenID); 
    function purchaseTo(address _to, uint _projectId) payable external returns (uint tokenID);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
interface IMP 
{ 
    /**
     * @dev { For Instances Where Artists Have A Bespoke Mint Pass Contract }
     */
    function _LiveMintBurn(uint TicketID) external returns(address Recipient); 

    /**
     * @dev { For Instances Where Artists Share The Same Mint Pass Contract }
     */
    function _LiveMintBurnShared(uint TicketID) external returns(address Recipient, uint ArtistID);
}

//SPDX-License-Identifier: MIT
/**
 * @dev: @brougkr
 */
pragma solidity 0.8.17;
interface IMPMX // Helper Interface For MPMX Live-Minting
{ 
    function ViewArtistID(uint TokenID) external view returns(uint);
    function _LiveMintBurn(uint TokenID) external returns(address, uint);
    function ViewArtistIDsByTokenIDs(uint[] calldata TokenIDs) external view returns(uint[] memory);
}

// SPDX-License-Identifier: MIT
/**
 * @dev: @brougkr
 */
// Interface For Mint Pass Option
pragma solidity 0.8.17;
interface IMPO 
{ 
    function _TransferOption(address Recipient, uint TokenID) external;
    function _RedeemOption(uint TokenID) external;
}

// SPDX-License-Identifier: MIT
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/**
 * @dev: @brougkr
 */
pragma solidity 0.8.17;
import {IERC721} from '@openzeppelin/contracts/interfaces/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {IMinter} from './IMinter.sol';
import {IMP} from "./IMP.sol";
contract LiveMint is Ownable, ReentrancyGuard
{  
    struct City
    {
        string _Name;
        uint _QRCurrentIndex;
        address _GoldenToken;
        address _ERC20;
        bytes32 _Root;
    } 

    struct Artist
    {
        string _Name;
        uint _ProjectID;
        uint _QRCurrentIndex;
        address _MintPass;
        address _Minter;
        address _ERC20;
        bytes32 _Root;
    }

    struct User
    {
        bool _Eligible;
        uint _Allocation;
    }

    /*-------------------*/
    /*  STATE VARIABLES  */
    /*-------------------*/

    bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");                // Minter Role
    bytes32 private constant _ADMIN_ROLE = keccak256("ADMIN_ROLE_BING_BONG");        // Admin Role
    address private constant _BRT_BURN = 0xcff43A597911a9457071d89d2b2AC3D5b1862b86; // BRT Multisig Burn Address (mint.brightmoments.eth)
    address public _ArtBlocksMinter = 0xDd06d8483868Cd0C5E69C24eEaA2A5F2bEaFd42b;    // ArtBlocks Minter Contract
    address public _BRT_MULTISIG = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937;       // BRT Multisig
    uint public _CurrentCityIndex = 5;                                               // Current City Index

    /*-------------------*/
    /*     MAPPINGS      */
    /*-------------------*/
    
    mapping(uint => Artist) public Artists;                              // [ArtistID] => Artist
    mapping(uint => City) public Cities;                                 // [CityIndex] => City Struct
    mapping(uint => mapping(address => bool)) public _RedeemedQR;        // [CityIndex][Wallet] => If User Has Redeemed QR
    mapping(uint => mapping(address => uint)) public _QRAllocation;      // [CityIndex][Wallet] => Wallet's QR Code Allocation
    mapping(uint => mapping(uint => address)) public _BrightListCitizen; // [CityIndex][TicketID] => Address Of CryptoCitizen Minting Recipient 
    mapping(uint => mapping(uint => address)) public _BrightListArtist;  // [ArtistID][TicketID] => Address Of Artist NFT Recipient
    mapping(uint => mapping(uint => string)) public _DataArtists;        // [ArtistID][TicketID] => Artist Data
    mapping(uint => mapping(uint => string)) public _DataCitizens;       // [CityIndex][TicketID] => Data For Golden Token Checkins
    mapping(uint => mapping(uint => uint)) public _MintedTokenIDCitizen; // [CityIndex][TicketID] => MintedTokenID
    mapping(uint => mapping(uint => uint)) public _MintedTokenIDArtist;  // [ArtistID][TicketID] => MintedTokenID
    mapping(uint => mapping(uint => bool)) public _MintedArtist;         // [ArtistID][TicketID] => If Minted
    mapping(uint => mapping(uint => bool)) public _MintedCitizen;        // [CityIndex][TicketID] => If Golden Ticket ID Has Minted Or Not
    mapping(address => bytes32) public Role;                             // [Wallet] => BRT Minter Role

    /*-------------------*/
    /*      EVENTS       */
    /*-------------------*/

    /**
     * @dev Emitted When `Redeemer` IRL-mints CryptoCitizen Corresponding To Their Redeemed `TicketID`.
     **/
    event LiveMintComplete(address indexed Redeemer, uint TicketID, uint TokenID, string Data);

    /**
     * @dev Emitted When `Redeemer` IRL-mints A Artist NFT Corresponding To Their Redeemed `TicketID`.
     */
    event LiveMintCompleteArtist(address Recipient, uint ArtistID, uint TicketID, uint MintedWorkTokenID);

    /**
     * @dev Emitted When An Artist Mint Pass Is Redeemed
     */
    event ArtistMintPassRedeemed(address Redeemer, uint ArtistIDs, uint TicketIDs, string Data, string Type);

    /**
     * @dev Emitted When `Redeemer` Redeems Golden Token Corresponding To `TicketID` 
     **/
    event GoldenTokenRedeemed(address indexed Redeemer, uint TicketID, string Data, string Type);

    /**
     * @dev Emitted When `Redeemer` Redeems Golden Token Corresponding To `TicketID` 
     **/
    event QRRedeemed(address indexed Redeemer, uint TicketID, string Data, string Type);
    
    /**
     * @dev Emitted When A Reservation Is Wiped
     */
    event ReservationWiped(uint TicketID, address Redeemer, string Data);

    /*-------------------*/
    /*    CONSTRUCTOR    */
    /*-------------------*/

    constructor()
    { 
        Cities[0]._Name = "CryptoGalacticans";
        Cities[1]._Name = "CryptoVenetians";
        Cities[2]._Name = "CryptoNewYorkers";
        Cities[3]._Name = "CryptoBerliners";
        Cities[4]._Name = "CryptoLondoners";
        Cities[5]._Name = "CryptoMexas";
        Cities[6]._Name = "CryptoTokyo";
        Cities[6]._GoldenToken = 0x762F5C8137C445164c53e138da33032C21F44D65;
        Cities[7]._Name = "CryptoCitizen City #8";
        Cities[7]._GoldenToken = 0x0205f9cEb478FC77E2cDB77efD27B414dD31bAE5;
        Cities[8]._Name = "CryptoCitizen City #9";
        Cities[8]._GoldenToken = 0x1b02C7f98e62dDF1aC434C372A282E862b03acC6;
        Cities[9]._Name = "CryptoCitizen City #10";
        Cities[9]._GoldenToken = 0xB8d1611bE514202b60AdfcC8910F5A963E4Eb38D;
        Role[0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700] = _ADMIN_ROLE;  // `operator.brightmoments.eth`
        Role[0x1A0a3E3AE390a0710f8A6d00587082273eA8F6C9] = _MINTER_ROLE; // BRT Minter #1
        Role[0x4d8013b0c264034CBf22De9DF33e22f58D52F207] = _MINTER_ROLE; // BRT Minter #2
        Role[0x4D9A8CF2fE52b8D49C7F7EAA87b2886c2bCB4160] = _MINTER_ROLE; // BRT Minter #3
        Role[0x124fd966A0D83aA020D3C54AE2c9f4800b46F460] = _MINTER_ROLE; // BRT Minter #4
        Role[0x100469feA90Ac1Fe1073E1B2b5c020A8413635c4] = _MINTER_ROLE; // BRT Minter #5
        Role[0x756De4236373fd17652b377315954ca327412bBA] = _MINTER_ROLE; // BRT Minter #6
        Role[0xc5Dfba6ef7803665C1BDE478B51Bd7eB257A2Cb9] = _MINTER_ROLE; // BRT Minter #7
        Role[0xFBF32b29Bcf8fEe32d43a4Bfd3e7249daec457C0] = _MINTER_ROLE; // BRT Minter #8
        Role[0xF2A15A83DEE7f03C70936449037d65a1C100FF27] = _MINTER_ROLE; // BRT Minter #9
        Role[0x1D2BAB965a4bB72f177Cd641C7BacF3d8257230D] = _MINTER_ROLE; // BRT Minter #10
        Role[0x2e51E8b950D72BDf003b58E357C2BA28FB77c7fB] = _MINTER_ROLE; // BRT Minter #11
        Role[0x8a7186dECb91Da854090be8226222eA42c5eeCb6] = _MINTER_ROLE; // BRT Minter #12
        Role[0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700] = _MINTER_ROLE; // BRT Minter #13
        Role[0x7603C5eed8e57Ad795ec5F0081eFB21d1eEBf937] = _MINTER_ROLE; // BRT Minter #14
        // _transferOwnership(address(0));
    }

    /*-------------------*/
    /*  PUBLIC FUNCTIONS */
    /*-------------------*/

    /**
     * @dev Redeems Golden Tokens & BrightLists Address To Receive CryptoCitizen
     **/
    function RedeemGT (
        uint[] calldata TicketIDs, 
        string[] calldata Data,
        string[] calldata Type
    ) external nonReentrant {
        for(uint x; x < TicketIDs.length; x++)
        {
            require(
                IERC721(Cities[_CurrentCityIndex]._GoldenToken).ownerOf(TicketIDs[x]) == msg.sender, 
                "LiveMint: Sender Does Not Own Token With The Input Token ID"
            );
            IERC721(Cities[_CurrentCityIndex]._GoldenToken).transferFrom(msg.sender, _BRT_BURN, TicketIDs[x]);
            _BrightListCitizen[_CurrentCityIndex][TicketIDs[x]] = msg.sender;
            _DataCitizens[_CurrentCityIndex][TicketIDs[x]] = Data[x];
            require(
                IERC721(Cities[_CurrentCityIndex]._GoldenToken).ownerOf(TicketIDs[x]) == _BRT_BURN, 
                "LiveMint: Golden Token Redemption Failed"
            );
            emit GoldenTokenRedeemed(msg.sender, TicketIDs[x], Data[x], Type[x]);
        }
    }

    // NOTE:  will need custom minting logic if we allow artist mint pass redeems rather than just auto-minting, which will require more gas
    /**
     * @dev Redeems Artist Mint Pass & BrightLists Address To Receive A NFT
     **/
    function RedeemAP (
        uint[] calldata ArtistIDs,
        uint[] calldata TicketIDs, 
        string[] calldata Data,
        string[] calldata Type
    ) external nonReentrant {
        for(uint ArtistID; ArtistID < ArtistIDs.length; ArtistID++)
        {
            for(uint TicketID; TicketID < TicketIDs.length; TicketID++)
            {
                require(
                    IERC721(Artists[ArtistIDs[ArtistID]]._MintPass).ownerOf(TicketIDs[TicketID]) == msg.sender, 
                    "LiveMint: Sender Does Not Own Token With The Input Token ID"
                );
                IMP(Artists[ArtistIDs[ArtistID]]._MintPass)._LiveMintBurn(TicketIDs[TicketID]);
                _BrightListArtist[ArtistIDs[ArtistID]][TicketIDs[TicketID]] = msg.sender;
                _DataArtists[ArtistIDs[ArtistID]][TicketIDs[TicketID]] = Data[TicketID];
                emit ArtistMintPassRedeemed(msg.sender, ArtistIDs[TicketID], TicketIDs[TicketID], Data[TicketID], Type[TicketID]);
            }
        }
    } 
    
    /**
     * @dev Redeems Spot For IRL Minting
     */
    function RedeemQR(string calldata Data, string calldata Type, bytes32[] calldata Proof) external nonReentrant 
    {
        require(readQREligibility(msg.sender, Proof), "LiveMint: User Is Not Eligible To Redeem QR");
        unchecked
        {
            if(_QRAllocation[_CurrentCityIndex][msg.sender] == 0) // User Is Able To Redeem Explicitly 1 QR Code
            {
                require(!_RedeemedQR[_CurrentCityIndex][msg.sender], "LiveMint: User Has Already Redeemed");
                _DataCitizens[_CurrentCityIndex][Cities[_CurrentCityIndex]._QRCurrentIndex] = Data;
                _BrightListCitizen[_CurrentCityIndex][Cities[_CurrentCityIndex]._QRCurrentIndex] = msg.sender;
                emit QRRedeemed(msg.sender, Cities[_CurrentCityIndex]._QRCurrentIndex, Data, Type);
                Cities[_CurrentCityIndex]._QRCurrentIndex++; 
            }
            else // User Is Able To Redeem More Than 1 QR Code Because Their Integer Allocation > 0
            {
                uint _Allocation = _QRAllocation[_CurrentCityIndex][msg.sender];
                uint _CurrentQR = Cities[_CurrentCityIndex]._QRCurrentIndex;
                uint _Limit = _Allocation + _CurrentQR;
                _QRAllocation[_CurrentCityIndex][msg.sender] = 0;
                Cities[_CurrentCityIndex]._QRCurrentIndex = _Limit;
                for(_CurrentQR; _CurrentQR < _Limit; _CurrentQR++)
                {
                    _DataCitizens[_CurrentCityIndex][_CurrentQR] = Data;
                    _BrightListCitizen[_CurrentCityIndex][_CurrentQR] = msg.sender;
                    emit QRRedeemed(msg.sender, _CurrentQR, Data, Type);
                }
            }
            _RedeemedQR[_CurrentCityIndex][msg.sender] = true;
        } 
    }

    /*--------------------*/
    /*    LIVE MINTING    */
    /*--------------------*/

    /**
     * @dev Batch Mints Verified Users On The Brightlist CryptoCitizens
     * note: { For CryptoCitizen Cities }
     */
    function _LiveMintCitizen(uint[] calldata TicketIDs) external onlyMinter
    {
        for(uint TicketID; TicketID < TicketIDs.length; TicketID++)
        {
            address Recipient = _BrightListCitizen[_CurrentCityIndex][TicketIDs[TicketID]];
            require(Recipient != address(0), "LiveMint: Golden Token Entered Is Not Brightlisted");
            require(!_MintedCitizen[_CurrentCityIndex][TicketIDs[TicketID]], "LiveMint: Golden Token Already Minted");
            _MintedCitizen[_CurrentCityIndex][TicketIDs[TicketID]] = true;
            uint TokenID = IMinter(_ArtBlocksMinter).purchaseTo(Recipient, _CurrentCityIndex);
            _MintedTokenIDCitizen[_CurrentCityIndex][TicketIDs[TicketID]] = TokenID;
            emit LiveMintComplete(Recipient, TicketIDs[TicketID], TokenID, _DataCitizens[_CurrentCityIndex][TicketIDs[TicketID]]); 
        }
    }

    /**
     * @dev Burns An Artist Mint Pass For An Artist Minted Work
     * note: { For Instances Where An Artist Has a Bespoke Mint Pass }
     */
    function _LiveMintArtist(uint ArtistID, uint[] calldata TicketIDs) external onlyMinter 
    {
        address Recipient;
        uint MintedWorkTokenID;
        uint TicketID;
        for(uint TicketIndex; TicketIndex < TicketIDs.length; TicketIndex++)
        {
            TicketID = TicketIDs[TicketIndex];
            require(!_MintedArtist[ArtistID][TicketID], "LiveMint: Artist Mint Pass Already Minted");
            _MintedArtist[ArtistID][TicketID] = true;
            if(_BrightListArtist[ArtistID][TicketID] != address(0)) { Recipient = _BrightListArtist[ArtistID][TicketID]; }
            else { Recipient = IMP(Artists[ArtistID]._MintPass)._LiveMintBurn(TicketID); }
            MintedWorkTokenID = IMinter(Artists[ArtistID]._Minter).purchaseTo(Recipient, Artists[ArtistID]._ProjectID);
            _MintedTokenIDArtist[ArtistID][TicketID] = MintedWorkTokenID;
            emit LiveMintCompleteArtist(Recipient, ArtistID, TicketID, MintedWorkTokenID);
        }
    }

    /**
     * @dev Burns Artist Mint Pass In Exchange For The Minted Work
     * note: { For Instances Where Multiple Artists Share The Same Mint Pass }
     */
    function _LiveMintArtistCollection(uint ArtistID, uint[] calldata TicketIDs) external onlyMinter
    {
        address Recipient;
        uint ArtistProjectID;
        uint MintedWorkTokenID;
        uint TicketID;
        for(uint x; x < TicketIDs.length; x++)
        {
            TicketID = TicketIDs[x];
            require(!_MintedArtist[ArtistID][TicketID], "LiveMint: Artist Mint Pass Already Minted");
            _MintedArtist[ArtistID][TicketID] = true;
            (Recipient, ArtistProjectID) = IMP(Artists[ArtistID]._MintPass)._LiveMintBurnShared(TicketID);
            MintedWorkTokenID = IMinter(Artists[ArtistID]._Minter).purchaseTo(Recipient, ArtistProjectID);
            _MintedTokenIDArtist[ArtistID][TicketID] = MintedWorkTokenID;
            emit LiveMintCompleteArtist(Recipient, ArtistID, TicketID, MintedWorkTokenID);
        }
    }

    /*-------------------*/
    /*  OWNER FUNCTIONS  */
    /*-------------------*/

    /**
     * @dev Mints To Multisig
     */
    function _SetNoShow(uint[] calldata TicketIDs) external onlyOwner
    {
        unchecked
        {
            for(uint TicketIndex; TicketIndex < TicketIDs.length; TicketIndex++)
            {
                require(!_MintedCitizen[_CurrentCityIndex][TicketIDs[TicketIndex]], "LiveMint: Ticket ID Already Minted");
                _BrightListCitizen[_CurrentCityIndex][TicketIDs[TicketIndex]] = _BRT_MULTISIG;
            }
        }
    }

    /**
     * @dev Grants Address BRT Minter Role
     **/
    function __AddMinter(address Minter) external onlyOwner { Role[Minter] = _MINTER_ROLE; }

    /**
     * @dev Deactivates Address From BRT Minter Role
     **/
    function __RemoveMinter(address Minter) external onlyOwner { Role[Minter] = 0x0; }

    /**
     * @dev Changes Merkle Root For Citizen LiveMints
     */
    function __ChangeRootCitizen(bytes32 NewRoot) external onlyOwner { Cities[_CurrentCityIndex]._Root = NewRoot; }

    /**
     * @dev Changes Merkle Root For Artist LiveMints
     */
    function __ChangeRootArtist(uint ArtistID, bytes32 NewRoot) external onlyOwner { Artists[ArtistID]._Root = NewRoot; }

    /**
     * @dev Overwrites QR Allocation
     */
    function __OverwriteQRAllocations(address[] calldata Addresses, uint[] calldata Amounts) external onlyOwner
    {
        require(Addresses.length == Amounts.length, "LiveMint: Input Arrays Must Match");
        for(uint x; x < Addresses.length; x++) { _QRAllocation[_CurrentCityIndex][Addresses[x]] = Amounts[x]; }
    }

    /**
     * @dev Increments QR Allocations
     */
    function __IncrementQRAllocations(address[] calldata Addresses, uint[] calldata Amounts) external onlyOwner
    {
        require(Addresses.length == Amounts.length, "LiveMint: Input Arrays Must Match");
        for(uint x; x < Addresses.length; x++) { _QRAllocation[_CurrentCityIndex][Addresses[x]] += Amounts[x]; }
    }

    /**
     * @dev Changes ArtBlocks CryptoCitizen Minter Address
     */
    function __ChangeArtBlocksMinterCitizens(address ContractAddress) external onlyOwner { _ArtBlocksMinter = ContractAddress; }

    /**
     * @dev Changes Multisig Address
     */
    function __ChangeMultisigAddress(address Recipient) external onlyOwner { _BRT_MULTISIG = Recipient; }

    /**
     * @dev Changes QR Current Index
     */
    function __ChangeQRIndex(uint NewIndex) external onlyOwner { Cities[_CurrentCityIndex]._QRCurrentIndex = NewIndex; }

    /**
     * @dev Batch Approves BRT For Purchasing
     */
    function __BatchApproveERC20(address[] calldata ERC20s, address[] calldata Operators, uint[] calldata Amounts) external onlyOwner
    {
        require(ERC20s.length == Operators.length && Operators.length == Amounts.length, "LiveMint: Arrays Must Be Equal Length");
        for(uint x; x < ERC20s.length; x++) { IERC20(ERC20s[x]).approve(Operators[x], Amounts[x]); }
    }

    /**
     * @dev Instantiates New City
     * note: CityIndex Always Corresponds To ArtBlocks ProjectID
     * note: QRCurrentIndex Should Typically Always Equal 333 
     */
    function __NewCity (
        string calldata Name,
        uint CityIndex,
        uint QRIndex,
        address ERC20,
        address GoldenToken
    ) external onlyOwner {
        Cities[CityIndex] = City(
            Name,
            QRIndex,
            GoldenToken,
            ERC20,
            0x6942069420694206942069420694206942069420694206942069420694206942
        );
        IERC20(ERC20).approve(
            _ArtBlocksMinter, 
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    /**
     * @dev Instantiates A New Artist
     */
    function __NewArtist ( 
        string calldata Name,
        uint ArtistID,
        uint ProjectID,
        uint QRIndex,
        address MintPass,
        address Minter,
        address ERC20
    ) external onlyOwner {
        Artists[ArtistID] = Artist(
            Name,
            ProjectID,
            QRIndex,
            MintPass,
            Minter,
            ERC20,
            0x6942069420694206942069420694206942069420694206942069420694206942
        );
        IERC20(ERC20).approve(
            Minter,
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    /**
     * @dev Instantiates A New City
     */
    function __NewCityStruct(uint CityIndex, City memory NewCity) external onlyOwner { Cities[CityIndex] = NewCity; }

    /**
     * @dev Returns An Artist Struct
     */
    function __NewArtistStruct(uint ArtistID, Artist memory NewArtist) external onlyOwner { Artists[ArtistID] = NewArtist; }

    /**
     * @dev Withdraws Any Ether Mistakenly Sent to Contract to Multisig
     **/
    function __WithdrawEther() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Withdraws ERC20 Tokens to Multisig
     **/
    function __WithdrawERC20(address TokenAddress) external onlyOwner 
    { 
        IERC20 erc20Token = IERC20(TokenAddress);
        uint balance = erc20Token.balanceOf(address(this));
        require(balance > 0, "0 ERC20 Balance At `TokenAddress`");
        erc20Token.transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraws Any NFT Mistakenly Sent To This Contract.
     */
    function __WithdrawERC721(address ContractAddress, address Recipient, uint TokenID) external onlyOwner
    {
        IERC721(ContractAddress).transferFrom(address(this), Recipient, TokenID);
    }
    
    /*-------------------*/
    /*    PUBLIC VIEW    */
    /*-------------------*/

    /**
     * @dev Returns If User Is Eligible To Redeem QR Code
     */
    function readEligibility(address Recipient, bytes32[] memory Proof) public view returns(User memory)
    {
        bool Eligible = readQREligibility(Recipient, Proof);
        uint Allocation;
        if(Eligible && _QRAllocation[_CurrentCityIndex][Recipient] > 0) { Allocation = _QRAllocation[_CurrentCityIndex][Recipient]; }
        return User(Eligible, Allocation);
    }

    /**
     * @dev Returns If User Is Eligible To Redeem QR Code
     */
    function readQREligibility(address Recipient, bytes32[] memory Proof) public view returns(bool)
    {
        bytes32 Leaf = keccak256(abi.encodePacked(Recipient));
        bool BrightListEligible = MerkleProof.verify(Proof, Cities[_CurrentCityIndex]._Root, Leaf);
        if(
            (BrightListEligible && !_RedeemedQR[_CurrentCityIndex][Recipient])
            || 
            (BrightListEligible && _QRAllocation[_CurrentCityIndex][Recipient] > 0)
            
        ) { return true; }
        else { return false; }
    }

    /**
     * @dev Returns An Array Of Unminted Golden Tokens
     */
    function readUnmintedGoldenTokens() public view returns(uint[] memory)
    {
        uint[] memory UnmintedTokenIDs = new uint[](1000);
        uint Counter;
        for(uint TokenID; TokenID < 1000; TokenID++)
        {
            if(
                !_MintedCitizen[_CurrentCityIndex][TokenID]
                &&
                _BrightListCitizen[_CurrentCityIndex][TokenID] != address(0)
            ) 
            { 
                UnmintedTokenIDs[Counter] = TokenID; 
                Counter++;
            }
        }
        uint[] memory FormattedUnMintedTokenIDs = new uint[](Counter);
        uint Found;
        for(uint FormattedTokenID; FormattedTokenID < Counter; FormattedTokenID++)
        {
            if(UnmintedTokenIDs[FormattedTokenID] != 0 || (UnmintedTokenIDs[FormattedTokenID] == 0 && FormattedTokenID == 0))
            {
                FormattedUnMintedTokenIDs[Found] = UnmintedTokenIDs[FormattedTokenID];
                Found++;
            }
        }
        return FormattedUnMintedTokenIDs;
    }

    /**
     * @dev Returns An Array Of Unminted Golden Tokens
     */
    function readMintedGoldenTokens(uint CityID) public view returns(uint[] memory)
    {
        uint[] memory MintedTokenIDs = new uint[](1000);
        uint Counter;
        for(uint TicketID; TicketID < 1000; TicketID++)
        {
            if(_MintedCitizen[CityID][TicketID]) 
            { 
                MintedTokenIDs[Counter] = TicketID; 
                Counter++;
            }
        }
        uint[] memory FormattedMintedTokenIDs = new uint[](Counter);
        uint Found;
        for(uint FormattedTokenID; FormattedTokenID < Counter; FormattedTokenID++)
        {
            if(MintedTokenIDs[FormattedTokenID] != 0 || (MintedTokenIDs[FormattedTokenID] == 0 && FormattedTokenID == 0))
            {
                FormattedMintedTokenIDs[Found] = MintedTokenIDs[FormattedTokenID];
                Found++;
            }
        }
        return FormattedMintedTokenIDs;
    }

    /**
     * @dev Returns A 2d Array Of Checked In & Unminted TicketIDs
     */
    function readCheckedInTicketIDs() public view returns(uint[] memory TokenIDs)
    {
        uint[] memory _TokenIDs = new uint[](1000);
        uint Counter;
        for(uint TicketID; TicketID < 1000; TicketID++)
        {
            if(_BrightListCitizen[_CurrentCityIndex][TicketID] != address(0)) 
            { 
                _TokenIDs[Counter] = TicketID; 
                Counter++;
            }
        }
        uint[] memory FormattedCheckedInTickets = new uint[](Counter);
        uint Found;
        for(uint x; x < Counter; x++)
        {
            if(_TokenIDs[x] != 0 || (_TokenIDs[x] == 0 && x == 0))
            {
                FormattedCheckedInTickets[Found] = _TokenIDs[x];
                Found++;
            }
        }
        return FormattedCheckedInTickets;
    }

    /**
     * @dev Returns A 2d Array Of Minted ArtistIDs
     */
    function readMintedTicketIDsArtist(uint[] calldata ArtistIDs, uint Range) public view returns(uint[][] memory TokenIDs)
    {
        uint[][] memory _TokenIDs = new uint[][](ArtistIDs.length);
        uint Index;
        for(uint ArtistID; ArtistID < ArtistIDs.length; ArtistID++)
        {
            uint[] memory MintedTokenIDs = new uint[](Range);
            uint Counter;
            for(uint TokenID; TokenID < Range; TokenID++)
            {
                if(_MintedArtist[ArtistIDs[ArtistID]][TokenID])
                { 
                    MintedTokenIDs[Counter] = TokenID; 
                    Counter++;
                }
            }
            uint[] memory FormattedMintedTokenIDs = new uint[](Counter);
            uint Found;
            for(uint x; x < Counter; x++)
            {
                if(MintedTokenIDs[x] != 0 || (MintedTokenIDs[x] == 0 && x == 0))
                {
                    FormattedMintedTokenIDs[Found] = MintedTokenIDs[x];
                    Found++;
                }
            }
            _TokenIDs[Index] = FormattedMintedTokenIDs;
            Index++;
        }
        return (_TokenIDs);
    }

    /**
     * @dev Returns A 2d Array Of Minted ArtistIDs
     */
    function readUnmintedTicketIDs(uint[] calldata ArtistIDs, uint Range) public view returns(uint[][] memory TokenIDs)
    {
        uint[][] memory _TokenIDs = new uint[][](ArtistIDs.length);
        uint Index;
        for(uint ArtistID; ArtistID < ArtistIDs.length; ArtistID++)
        {
            uint[] memory UnmintedArtistTokenIDs = new uint[](Range);
            uint Counter;
            for(uint TokenID; TokenID < Range; TokenID++)
            {
                bool TicketIDBurned;
                try IERC721(Artists[ArtistIDs[ArtistID]]._MintPass).ownerOf(TokenID) { } // checks if token is burned
                catch { TicketIDBurned = true; }
                if(
                    !_MintedArtist[ArtistIDs[ArtistID]][TokenID]
                    &&
                    (
                        _BrightListArtist[ArtistIDs[ArtistID]][TokenID] != address(0)
                        ||
                        TicketIDBurned == false
                    )
                ) 
                { 
                    UnmintedArtistTokenIDs[Counter] = TokenID; 
                    Counter++;
                }
            }
            uint[] memory FormattedUnMintedArtistIDs = new uint[](Counter);
            uint Found;
            for(uint x; x < Counter; x++)
            {
                if(UnmintedArtistTokenIDs[x] != 0 || (UnmintedArtistTokenIDs[x] == 0 && x == 0))
                {
                    FormattedUnMintedArtistIDs[Found] = UnmintedArtistTokenIDs[x];
                    Found++;
                }
            }
            _TokenIDs[Index] = FormattedUnMintedArtistIDs;
            Index++;
        }
        return (_TokenIDs);
    }

    /**
     * @dev Returns Original Recipients Of CryptoCitizens
     */
    function readBrightList(uint CityIndex, uint Range) public view returns(address[] memory Recipients)
    {
        address[] memory _Recipients = new address[](Range);
        for(uint x; x < Range; x++) { _Recipients[x] = _BrightListCitizen[CityIndex][x]; }
        return _Recipients;
    }

    /**
     * @dev Returns Original Recipient Of Artist NFTs
     */
    function readBrightListArtists(uint ArtistID, uint Range) public view returns(address[] memory Recipients)
    {
        address[] memory _Recipients = new address[](Range);
        for(uint x; x < Range; x++) { _Recipients[x] = _BrightListArtist[ArtistID][x]; }
        return _Recipients;    
    }

    /**
     * @dev Returns The City Struct At Index Of `CityIndex`
     */
    function readCity(uint CityIndex) public view returns(City memory) { return Cities[CityIndex]; }

    /**
     * @dev Returns The Artist Struct At Index Of `ArtistID`
     */
    function readArtist(uint ArtistID) public view returns(Artist memory) { return Artists[ArtistID]; }

    /**
     * @dev Returns Minted TokenID
     */
    function readMintedTokenIDArtist(uint ArtistID, uint TicketID) external view returns (uint)
    {
        if(!_MintedArtist[ArtistID][TicketID]) { return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; }
        else { return _MintedTokenIDArtist[ArtistID][TicketID]; }
    }

    /**
     * @dev Returns Minted 
     */
    function readMintedTokenIDCitizen(uint CityIndex, uint TicketID) external view returns(uint)
    {
        if(!_MintedCitizen[CityIndex][TicketID]) { return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; }
        else { return _MintedTokenIDCitizen[CityIndex][TicketID]; }  
    }

    /*-------------------------*/
    /*     ACCESS MODIFIERS    */
    /*-------------------------*/

    /**
     * @dev Access Modifier That Allows Only BrightListed BRT Minters
     **/
    modifier onlyMinter() 
    {
        require(Role[msg.sender] == _MINTER_ROLE, "LiveMint: OnlyMinter Caller Is Not Approved BRT Minter");
        _;
    }
}

// SPDX-License-Identifier: MIT
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/**
 * @dev: @brougkr
 */
pragma solidity 0.8.17;
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMinter} from "./IMinter.sol";
import {IMPMX} from "./IMPMX.sol";
contract LiveMintMPMX is Ownable
{   
    /*----------------------------*/
    /*     MAPPINGS & EVENTS      */
    /*----------------------------*/
    
    mapping(uint => address) public BrightListArtist;  // Returns [TicketID] => Address Of Minting Receiver For Artist Mint 
    mapping(uint => bool) public MintedArtist;         // Returns [TicketID] => Boolean If Artist MintPass ID Has Minted Or Not
    mapping(uint => uint) private _MintedTokenID;      // Returns [ArtistID][TicketID] => Minted Work TokenID
    mapping(address => bool) public Role;              // Returns [Address] => BRT Minter Role Mapping
    event LiveMintCompleteArtist(address indexed Recipient, uint ArtistID, uint TicketID, uint MintedWorkTokenID);

    /*----------------------*/
    /*      CONSTANTS       */
    /*----------------------*/

    address private constant MPMX = 0x51992c5CD2E8A282d5fD21731Af6BFaA0C0B1E57;
    address private constant ArtBlocksMinter = 0x7b9a45E278b5B374bb2d96C65665d4360C97BF01;

    /*-------------------*/
    /*    CONSTRUCTOR    */
    /*-------------------*/

    constructor()
    { 
        Role[0x1A0a3E3AE390a0710f8A6d00587082273eA8F6C9] = true; // BRT Minter #1
        Role[0x4d8013b0c264034CBf22De9DF33e22f58D52F207] = true; // BRT Minter #2
        Role[0x4D9A8CF2fE52b8D49C7F7EAA87b2886c2bCB4160] = true; // BRT Minter #3
        Role[0x124fd966A0D83aA020D3C54AE2c9f4800b46F460] = true; // BRT Minter #4
        Role[0x100469feA90Ac1Fe1073E1B2b5c020A8413635c4] = true; // BRT Minter #5
        Role[0x756De4236373fd17652b377315954ca327412bBA] = true; // BRT Minter #6
        Role[0xc5Dfba6ef7803665C1BDE478B51Bd7eB257A2Cb9] = true; // BRT Minter #7
        Role[0xFBF32b29Bcf8fEe32d43a4Bfd3e7249daec457C0] = true; // BRT Minter #8
        Role[0xF2A15A83DEE7f03C70936449037d65a1C100FF27] = true; // BRT Minter #9
        Role[0x1D2BAB965a4bB72f177Cd641C7BacF3d8257230D] = true; // BRT Minter #10
        Role[0x2e51E8b950D72BDf003b58E357C2BA28FB77c7fB] = true; // BRT Minter #11
        Role[0x8a7186dECb91Da854090be8226222eA42c5eeCb6] = true; // BRT Minter #12
        Role[0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700] = true; // BRT Minter #13
        Role[0x7603C5eed8e57Ad795ec5F0081eFB21d1eEBf937] = true; // BRT Minter #14
        Role[msg.sender] = true;                                 // BRT Minter #15
        IERC20(0x3594E71daeECeaD764b7bf31172acaD10240E014).approve(
            ArtBlocksMinter, 
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // Max Approval
        );
        _transferOwnership(0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700);
    }

    /*---------------------*
     * ARTIST LIVE MINTING *
    -----------------------*/

    /**
     * @dev Burns MPMX For An Artist"s Minted Work
     */
    function _LiveMintArtist(uint[] calldata TicketIDs) external onlyMinter 
    {
        address Recipient;
        uint ArtistID;
        uint MintedWorkTokenID;
        uint TicketID;
        for(uint Index; Index < TicketIDs.length; Index++)
        {
            TicketID = TicketIDs[Index];
            require(!MintedArtist[TicketID], "LiveMintMPMX: Artist Mint Pass Already Minted");
            MintedArtist[TicketID] = true;
            (Recipient, ArtistID) = IMPMX(MPMX)._LiveMintBurn(TicketID);
            MintedWorkTokenID = IMinter(ArtBlocksMinter).purchaseTo(Recipient, ArtistID);
            _MintedTokenID[TicketID] = MintedWorkTokenID;
            emit LiveMintCompleteArtist(Recipient, ArtistID, TicketID, MintedWorkTokenID);
        }
    }

    /*-------------------*/
    /*  OWNER FUNCTIONS  */
    /*-------------------*/

    /**
     * @dev Batch Approves BRT For Purchasing
     */
    function __BatchApproveERC20(address[] calldata ERC20s, address[] calldata Operators, uint[] calldata Amounts) external onlyOwner
    {
        require(ERC20s.length == Operators.length && Operators.length == Amounts.length, "LiveMintMPMX: Arrays Must Be Equal Length");
        for(uint i; i < ERC20s.length; i++)
        {
            IERC20(ERC20s[i]).approve(Operators[i], Amounts[i]);
        }
    }

    /**
     * @dev Grants Address BRT Minter Role
     **/
    function __MinterAdd(address Minter) external onlyOwner { Role[Minter] = true; }

    /**
     * @dev Deactivates Address From BRT Minter Role
     **/
    function __MinterRemove(address Minter) external onlyOwner { Role[Minter] = false; }

    /**
     * @dev Withdraws Any Ether Mistakenly Sent to Contract to Multisig
     **/
    function __WithdrawEther() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Withdraws ERC20 Tokens to Multisig
     **/
    function __WithdrawERC20(address TokenAddress) external onlyOwner 
    { 
        IERC20 erc20Token = IERC20(TokenAddress);
        uint balance = erc20Token.balanceOf(address(this));
        require(balance > 0, "0 ERC20 Balance At `TokenAddress`");
        erc20Token.transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraws Any NFT Mistakenly Sent To This Contract.
     */
    function __WithdrawERC721(address ContractAddress, address Recipient, uint TokenID) external onlyOwner
    {
        IERC721(ContractAddress).transferFrom(address(this), Recipient, TokenID);
    }
    
    /*-------------------*/
    /*    PUBLIC VIEW    */
    /*-------------------*/

    /**
     * @dev Returns BrightListed Address Corresponding to Mint Pass `ArtistID` & `TicketID`
     */
    function readBrightListArtist(uint TicketID) public view returns(address) { return BrightListArtist[TicketID]; }

    /**
     * @dev Returns A Batch Of BrightListed Addresses
     */
    function readBrightListArtistBatch(uint Range) public view returns(address[][] memory)
    {
        address[][] memory Addresses = new address[][](Range);
        for(uint ArtistID; ArtistID < Range; ArtistID++)
        {
            for(uint TokenID; TokenID < Range; TokenID++) 
            { 
                Addresses[ArtistID][TokenID] = BrightListArtist[TokenID]; 
            }
        }
        return Addresses;
    }

    /**
     * @dev Returns Minted Work TokenID
     */
    function readMintedWorkTokenID(uint TicketID) external view returns (uint)
    {
        if(!MintedArtist[TicketID]) { return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; }
        else { return _MintedTokenID[TicketID]; }
    }

    /**
     * @dev Reads Minted Work TokenIDs
     */
    function readMintedWorkTokenIDs() public view returns (uint[] memory)
    {
        uint[] memory _TokenIDs = new uint[](1000);
        for(uint x; x < 1000; x++) 
        {
            if(!MintedArtist[x]) { _TokenIDs[x] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; }
            else { _TokenIDs[x] = _MintedTokenID[x]; } 
        }
        return _TokenIDs;
    }

    /**
     * @dev Returns A 2d Array Of Minted ArtistIDs
     */
    function readMintedTicketIDs(uint[] calldata ArtistIDs, uint Range) public view returns(uint[][] memory TokenIDs)
    {
        uint[][] memory _TokenIDs = new uint[][](ArtistIDs.length);
        uint Index;
        for(uint ArtistID; ArtistID < ArtistIDs.length; ArtistID++)
        {
            uint[] memory MintedTokenIDs = new uint[](Range);
            uint Counter;
            for(uint TokenID; TokenID < Range; TokenID++)
            {
                if(MintedArtist[TokenID])
                { 
                    MintedTokenIDs[Counter] = TokenID; 
                    Counter++;
                }
            }
            uint[] memory FormattedMintedTokenIDs = new uint[](Counter);
            uint Found;
            for(uint x; x < Counter; x++)
            {
                if(MintedTokenIDs[x] != 0 || (MintedTokenIDs[x] == 0 && x == 0))
                {
                    FormattedMintedTokenIDs[Found] = MintedTokenIDs[x];
                    Found++;
                }
            }
            _TokenIDs[Index] = FormattedMintedTokenIDs;
            Index++;
        }
        return (_TokenIDs);
    }

    /**
     * @dev Returns A 2d Array Of Minted ArtistIDs
     */
    function readUnmintedTicketIDs(uint[] calldata ArtistIDs, uint Range) public view returns(uint[][] memory TokenIDs)
    {
        uint[][] memory _TokenIDs = new uint[][](ArtistIDs.length);
        uint Index;
        for(uint ArtistID; ArtistID < ArtistIDs.length; ArtistID++)
        {
            uint[] memory UnmintedArtistTokenIDs = new uint[](Range);
            uint Counter;
            for(uint TokenID; TokenID < Range; TokenID++)
            {
                bool TicketIDBurned;
                try IERC721(MPMX).ownerOf(TokenID) { } // checks if token is burned
                catch { TicketIDBurned = true; }
                if(
                    !MintedArtist[TokenID]
                    &&
                    (
                        BrightListArtist[TokenID] != address(0)
                        ||
                        TicketIDBurned == false
                    )
                ) 
                { 
                    UnmintedArtistTokenIDs[Counter] = TokenID; 
                    Counter++;
                }
            }
            uint[] memory FormattedUnMintedArtistIDs = new uint[](Counter);
            uint Found;
            for(uint x; x < Counter; x++)
            {
                if(UnmintedArtistTokenIDs[x] != 0 || (UnmintedArtistTokenIDs[x] == 0 && x == 0))
                {
                    FormattedUnMintedArtistIDs[Found] = UnmintedArtistTokenIDs[x];
                    Found++;
                }
            }
            _TokenIDs[Index] = FormattedUnMintedArtistIDs;
            Index++;
        }
        return (_TokenIDs);
    }

    /*------------------*/
    /*     MODIFIERS    */
    /*------------------*/

    /**
     * @dev Function Modifier That Allows Only BrightListed BRT Minters To Access
     **/
    modifier onlyMinter() 
    {
        require(Role[msg.sender] == true, "OnlyMinter: Caller Is Not Approved BRT Minter");
        _;
    }
}

//SPDX-License-Identifier: MIT
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/**
 * @dev: @brougkr
 */
pragma solidity 0.8.17;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMPO} from "./IMPO.sol";
import {ERC721MP} from "./ERC721MP.sol";
contract MPMX is ERC721MP, Ownable, ReentrancyGuard
{    
    struct MintPass
    {
        uint _PriceStart;                       // [0] -> _PriceStart
        uint _PriceEnd;                         // [1] -> _PriceEnd
        uint _MaximumAvailableForSale;          // [2] -> _MaximumAvailableForSale
        uint _StartingBlockUnixTimestamp;       // [3] -> _StartingBlockUnixTimestamp
        uint _SecondsBetweenPriceDecay;         // [4] -> _SecondsBetweenPriceDecay
        bool _ActivePublic;                     // [5] -> _ActivePublic
        bool _ActiveBrightList;                 // [6] -> _ActiveBrightList
        bytes32 _Root;                          // [7] -> _Root
    }
    struct MintPack
    {
        uint _PriceStart;                       // [0] => _PriceStart 
        uint _PriceEnd;                         // [1] => _PriceEnd
        uint _MaximumAvailableForSale;          // [2] => _MaximumAvailableForSale
        uint _StartingBlockUnixTimestamp;       // [3] => _StartingBlockUnixTimestamp
        uint _SecondsBetweenPriceDecay;         // [4] => _SecondsBetweenPriceDecay
        bool _ActivePublic;                     // [5] => _ActivePublic
        bool _ActiveBrightList;                 // [6] => _ActiveBrightList
        bytes32 _Root;                          // [7] => _Root
    }
    struct InternalSale
    {
        uint _AmountSold;         // [0] -> _AmountSold
        uint _FinalClearingPrice; // [1] -> _FinalClearingPrice
        uint _UniqueSales;        // [2] -> _UniqueSales
    }
    struct InternalSaleMintPack
    {
        uint _AmountSold;         // [0] -> _AmountSold
        uint _FinalClearingPrice; // [1] -> _FinalClearingPrice
    }
    struct UserSaleInformation
    {
        // Mint Pass Information
        uint _MintPassCurrentPrice;    // [0] -> _MintPassCurrentPrice
        uint _MintPassAmountPurchased; // [1] -> _MintPassAmountPurchased
        uint _MintPassAllocation;      // [2] -> _MintPassAllocation
        uint _MintPassAmountRemaining; // [3] -> _MintPassAmountRemaining
        bool _MintPassEligible;        // [4] -> _MintPassEligible
        bool _MintPassSalePaused;      // [5] -> _MintPassSalePaused

        // Mint Pack Information
        uint _MintPackCurrentPrice;    // [6] -> _MintPackCurrentPrice
        uint _MintPackAmountPurchased; // [7] -> _MintPackAmountPurchased
        uint _MintPackAllocation;      // [8] -> _MintPackAllocation
        uint _MintPackAmountRemaining; // [9] -> _MintPackAmountRemaining
        bool _MintPackEligible;        // [10] -> _MintPackEligible
        bool _MintPackSalePaused;      // [11] -> _MintPackSalePaused
    }
    struct SaleInformation
    {
        // Mint Pass Information
        uint _MintPassCurrentPrice;  // [0] -> _MintPassCurrentPrice
        uint _MintPassRemaining;     // [1] -> _MintPassRemaining
        uint _MintPassSaleStartTime; // [2] -> _MintPassSaleStartTime
        uint _MintPassStartingPrice; // [3] -> _MintPassStartingPrice
        uint _MintPassEndingPrice;   // [4] -> _MintPassEndingPrice

        // Mint Pack Information 
        uint _MintPackCurrentPrice;  // [6] -> _MintPackCurrentPrice
        uint _MintPackRemaining;     // [7] -> _MintPackRemaining
        uint _MintPackSaleStartTime; // [8] -> _MintPackSaleStartTime
        uint _MintPackStartingPrice; // [9] -> _MintPackStartingPrice
        uint _MintPackEndingPrice;   // [10] -> _MintPackEndingPrice
    }
    struct UserHoldings
    {
        uint[] _TokenIDs;         // [0] -> _TokenIDs
        uint[] _ArtistIDs;        // [1] -> _ArtistIDs
        uint _FinalClearingPrice; // [2] -> _FinalClearingPrice
    }
    struct MPMXHoldings
    {
        uint[] _TokenIDs; 
        uint[] _ArtistIDs;
        bool _ArtistRevealedIDs;
        bool _ArtistRevealedNames;
    }
    MintPass public MintPassSale = MintPass(
        20 ether,   // [0] -> _PriceStart    
        0.5 ether,  // [1] -> _PriceEnd   
        417,        // [2] -> _MaximumAvailableForSale
        1663308000, // [3] -> _StartingBlockUnixTimestamp
        677,        // [4] -> _SecondsBetweenPriceDecay
        false,      // [5] -> _ActivePublic
        true,       // [6] -> _ActiveBrightList
        0xc000a33d5d3f892b84e50d56b81cc07e0a4f7ea363e4a2604bb72b39c6926d6d         // [7] -> _Root
    ); 
    MintPack public MintPackSale = MintPack(
        200 ether,  // [0] -> _PriceStart     
        5 ether,    // [1] -> _PriceEnd     
        10,         // [2] -> _MaximumAvailableForSale
        1663308000, // [3] -> _StartingBlockUnixTimestamp
        677,        // [4] -> _SecondsBetweenPriceDecay
        false,      // [5] -> _ActivePublic
        true,       // [6] -> _ActiveBrightList
        0x2ae7b007e7023d92459c40ee2059296989f8691ba44d468001ac195ec0ce0616         // [7] -> _Root
    );
    InternalSale public MintPassInternalSale = InternalSale(
        0,   // [0] -> _AmountSold
        0,   // [1] -> _FinalClearingPrice
        0    // [2] -> _UniqueSales
    );
    InternalSaleMintPack public MintPackInternalSale = InternalSaleMintPack(
        0,   // [0] -> _AmountSold
        0    // [1] -> _FinalClearingPrice
    );

    mapping(uint=>string) public ArtistNames;                  // `ArtistID` => `Artist Name` (Post-Randomized)
    mapping(uint=>uint) public ArtistID;                       // `TokenID` => `ArtistID` (Post-Randomized)
    mapping(uint=>address) public UniqueSaleIndexToAddress;    // `OrderID` => `Recipient`
    mapping(uint=>uint) public UniqueSalePurchaseAmount;       // `OrderID` => `Order Amount`
    mapping(uint=>uint) public UniqueSaleToOrderValue;         // `OrderID` => `Order Value`
    mapping(address=>uint) public _MintPassPurchasedAmt;       // `Wallet` => `Total Purchased Amount`
    mapping(address=>uint) public _MintPackPurchasedAmt;       // `Wallet` => `Total Purchased Amount`
    mapping(address=>uint) public _WalletAllocationsMintPass;  // `Wallet` => `Amount To Purchase`
    mapping(address=>uint) public _WalletAllocationsMintPack;  // `Wallet` => `Allocation`

    string public baseURI = "ipfs://QmUZ9CRbFLtDa8wmCLU3TXUt5WrJM32M9w6RLF717yyeNM/";
    uint[] public MintPackStartingIndexes;
    bool public OptionsActive;
    address public Option = 0x08ebADbc44F0f76CAFC6FD49e53247Cc9798eddD;
    address public _LiveMint = 0x7603C5eed8e57Ad795ec5F0081eFB21d1eEBf937;   
    address public _BRT_MULTISIG = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937;
    
    event MerkleRootsChanged(bytes32 OldRootMintPass, bytes32 OldRootMintPack, bytes32 NewRootMintPass, bytes32 NewRootMintPack);
    event PurchasedMintPack(address Recipient, uint Amount, uint MessageValue, uint PurchaseValue, uint AmountSold);
    event Purchased(address Recipient, uint Amount, uint MessageValue, uint PurchaseValue, uint AmountSold);
    event RandomArtistIDsSeeded(string URL, uint[] NewArtistIDs);
    event MerkleRootChanged(bytes32 OldRoot, bytes32 NewRoot);
    event OptionRedeemed(uint[] TokenIDs, address Recipient);
    event ArtistNamesSeeded(string URL, string[] Names);
    event NewStartingTimestamp(uint Timestamp);
    event ClaimStateSwitched(bool State);
    event Refunded(uint RefundAmount);

    constructor() ERC721MP("Mint Pass Mexico City | MPMX", "MPMX")
    { 
        _mint(msg.sender, 1000);
        // Transfers Ownership 
        // _transferOwnership(0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700); // operator.brightmoments.eth
        // _WhitelistedSender[0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700] = true;

        // Reserves Mint Passes - TokenIDs Are Irrelevant - The Randomized ArtistIDs Will Be Mapped After The Sale Concludes
        // _mint(address(this), 333);  // GTMX Holder Option Reserve:  [TokenIDs: 000 - 332] (333)                            
        // _mint(_BRT_MULTISIG, 150);  // Artist Reservation & BM Dao: [TokenIDs: 333 - 482] (150)
        //                             // Mint Packs:                                        (100)
        //                             // Remaining For Sale:                                (417)
    }

    /*---------------------
     * EXTERNAL FUNCTIONS *
    ----------------------*/

    /**
     * @dev Purchases NFTs
     */
    function PurchasePass(uint Amount, bytes32[] calldata Proof) external payable nonReentrant
    { 
        require(block.timestamp >= MintPassSale._StartingBlockUnixTimestamp, "MPMX: Sale Not Started Yet");
        require(MintPassSale._ActivePublic || MintPassSale._ActiveBrightList, "MPMX: Sale Not Active");
        if(MintPassInternalSale._AmountSold + Amount > MintPassSale._MaximumAvailableForSale)
        {
            Amount = MintPassSale._MaximumAvailableForSale - MintPassInternalSale._AmountSold;
        }
        uint NewAmountSold = MintPassInternalSale._AmountSold + Amount;
        require(NewAmountSold <= MintPassSale._MaximumAvailableForSale, "MPMX: Sold Out");
        uint NewUserPurchasedAmount = _MintPassPurchasedAmt[msg.sender] + Amount;
        require(Amount > 0, "MPMX: Incorrect Amount");
        if(MintPassSale._ActiveBrightList) 
        { 
            require(VerifyBrightList(msg.sender, Proof, MintPassSale._Root), "MPMX: Merkle: User Is Not On BrightList"); 
            require(
                NewUserPurchasedAmount <= _WalletAllocationsMintPass[msg.sender],
                "MPMX: Allocation Overflow"
            );
        }
        uint CurrentPrice = ViewCurrentPriceMintPass();
        uint CurrentPurchaseValue = CurrentPrice * Amount;
        require(msg.value >= CurrentPurchaseValue, "MPMX: Incorrect ETH Amount Sent");
        if(msg.value > CurrentPurchaseValue) { __Refund(msg.sender, (msg.value - CurrentPurchaseValue)); }
        UniqueSaleToOrderValue[MintPassInternalSale._UniqueSales] = CurrentPurchaseValue;
        UniqueSaleIndexToAddress[MintPassInternalSale._UniqueSales] = msg.sender; 
        UniqueSalePurchaseAmount[MintPassInternalSale._UniqueSales] = Amount;
        MintPassInternalSale._UniqueSales = MintPassInternalSale._UniqueSales + 1;
        MintPassInternalSale._AmountSold = NewAmountSold;
        _MintPassPurchasedAmt[msg.sender] = NewUserPurchasedAmount;
        require(MintPassInternalSale._AmountSold <= MintPassSale._MaximumAvailableForSale, "MPMX: Overflow");
        if(MintPassInternalSale._AmountSold == MintPassSale._MaximumAvailableForSale) // End Sales
        { 
            MintPassInternalSale._FinalClearingPrice = CurrentPrice; 
            ___EndMintPassSale();
        }
        _mint(msg.sender, Amount);
        emit Purchased(msg.sender, Amount, msg.value, CurrentPurchaseValue, NewAmountSold);
    }

    /**
     * @dev Purchases Mint Pass
     */
    function PurchasePack(uint Amount, bytes32[] calldata Proof) external payable nonReentrant
    {
        require(block.timestamp >= MintPackSale._StartingBlockUnixTimestamp, "MPMX: Sale Has Not Started");
        require(MintPackSale._ActiveBrightList || MintPackSale._ActivePublic, "MPMX: Sale Not Active");
        if(MintPackInternalSale._AmountSold + Amount > MintPackSale._MaximumAvailableForSale)
        {
            Amount = MintPackSale._MaximumAvailableForSale - MintPackInternalSale._AmountSold;
        }
        uint NewAmountSold = MintPackInternalSale._AmountSold + Amount;
        require(NewAmountSold <= MintPackSale._MaximumAvailableForSale, "MPMX: Sold Out");
        uint NewUserPurchasedAmount = _MintPackPurchasedAmt[msg.sender] + Amount;
        require(Amount > 0, "MPMX: Incorrect Amount");
        if(MintPackSale._ActiveBrightList) 
        { 
            require(VerifyBrightList(msg.sender, Proof, MintPackSale._Root), "Merkle: User Is Not On BrightList"); 
            require(
                NewUserPurchasedAmount <= _WalletAllocationsMintPack[msg.sender],
                "MPMX: User Has Used Up All Allocation For This Sale Index"
            );
        }
        uint CurrentPrice = ViewCurrentPriceMintPack();
        uint CurrentPurchaseValue = CurrentPrice * Amount;
        if(NewAmountSold == MintPackSale._MaximumAvailableForSale) 
        { 
            MintPackInternalSale._FinalClearingPrice = CurrentPrice; 
            __EndMintPackSale();
        }
        require(msg.value >= CurrentPurchaseValue, "MPMX: Invalid `msg.value`");
        if(msg.value > CurrentPurchaseValue) { __Refund(msg.sender, (msg.value - CurrentPurchaseValue)); }
        uint AmountToMint = (10 * Amount);
        uint TotalMinted = _totalMinted();
        for(uint x; x < Amount; x++) { MintPackStartingIndexes.push(TotalMinted + (x*10)); }
        _mint(msg.sender, AmountToMint);
        MintPackInternalSale._AmountSold = NewAmountSold;
        _MintPackPurchasedAmt[msg.sender] = NewUserPurchasedAmount;
        emit PurchasedMintPack(msg.sender, Amount, msg.value, CurrentPurchaseValue, NewAmountSold);
    }

    /**
     * @dev Redeems Option
     */
    function RedeemOption(uint[] calldata TokenIDs) external payable nonReentrant
    {
        require(MintPassInternalSale._FinalClearingPrice > 0, "MPMX: Final Dutch Clearing Price Not Seeded");
        require(OptionsActive, "MPMX: Option Claims Not Active");
        require(msg.value == MintPassInternalSale._FinalClearingPrice * TokenIDs.length, "MPMX: Invalid Message Value");
        for(uint TokenID; TokenID < TokenIDs.length; TokenID++)
        {
            require(IERC721(Option).ownerOf(TokenIDs[TokenID]) == msg.sender, "ERC721: User Does Not Own Option TokenID");
            IMPO(Option)._RedeemOption(TokenIDs[TokenID]); 
            IERC721(address(this)).transferFrom(address(this), msg.sender, TokenIDs[TokenID]);
        }
        emit OptionRedeemed(TokenIDs, msg.sender);
    }
    
    /*------------------
     * ADMIN FUNCTIONS *
    -------------------*/
    
    /**
     * @dev Toggles Active Public Sale State For Mint Pass
     */
    function __ToggleActivePublicMintPass() external onlyOwner { MintPassSale._ActivePublic = !MintPassSale._ActivePublic; }
    
    /**
     * @dev Toggles Active Public Sale State For Mint Pass
     */
    function __ToggleActivePublicMintPack() external onlyOwner { MintPackSale._ActivePublic = !MintPackSale._ActivePublic; }

    /**
     * @dev Toggles Active Public Sale State For Mint Pass
     */
    function __ToggleActiveBrightListMintPass() external onlyOwner { MintPassSale._ActiveBrightList = !MintPassSale._ActiveBrightList; }

    /**
     * @dev Toggles Active Public Sale State For Mint Pass
     */
    function __ToggleActiveBrightListMintPack() external onlyOwner { MintPackSale._ActiveBrightList = !MintPackSale._ActiveBrightList; }

    /**
     * @dev Enables Or Disables Option Claims
     */
    function __ToggleOptionClaims() external onlyOwner { OptionsActive = !OptionsActive; }

    /**
     * @dev Initiates Refunds For Sale
     */
    function __InitiateRefunds() external onlyOwner
    {
        require(MintPassInternalSale._FinalClearingPrice > 0, "Final Clearing Price Not Seeded");
        for(uint OrderIndex; OrderIndex < MintPassInternalSale._UniqueSales; OrderIndex++)
        {
            (bool Confirmed,) = UniqueSaleIndexToAddress[OrderIndex].call{
                value: UniqueSaleToOrderValue[OrderIndex] - (MintPassInternalSale._FinalClearingPrice * UniqueSalePurchaseAmount[OrderIndex])
            } (""); 
            require(Confirmed, "MPMX: Refund failed");
        }
    }

    /**
     * @dev Initiates Withdraw Of Refunds & Sale Proceeds
     */
    function __InitiateRefundsAndProceeds() external onlyOwner
    {
        require(MintPassInternalSale._FinalClearingPrice > 0, "Final Clearing Price Not Seeded");
        for(uint OrderIndex; OrderIndex < MintPassInternalSale._UniqueSales; OrderIndex++)
        {
            (bool ConfirmedRefund,) = UniqueSaleIndexToAddress[OrderIndex].call{
                value: UniqueSaleToOrderValue[OrderIndex] - (MintPassInternalSale._FinalClearingPrice * UniqueSalePurchaseAmount[OrderIndex])
            } (""); 
            require(ConfirmedRefund, "MPMX: Refund failed");
        }
        (bool ConfirmedWithdraw,) = msg.sender.call{ value: address(this).balance } (""); 
        require(ConfirmedWithdraw, "MPMX: Refund failed");
    }

    /**
     * @dev Seeds Wallet Allocations For Mint Passes
     */
    function __SeedWalletAllocationsMintPass(address[] calldata Wallets, uint[] calldata Allocations) external onlyOwner
    {
        for(uint x; x < Wallets.length; x++) { _WalletAllocationsMintPass[Wallets[x]] = Allocations[x]; }
    }

    /**
     * @dev Seeds Wallet Allocations For Mint Packs
     */
    function __SeedWalletAllocationsMintPack(address[] calldata Wallets, uint[] calldata Allocations) external onlyOwner
    {
        for(uint x; x < Wallets.length; x++) { _WalletAllocationsMintPack[Wallets[x]] = Allocations[x]; }
    }

    /**
     * @dev Overrides Approval Index For MPMX 
     */
    function __NewSetApprovalsArtistIDs() external onlyOwner 
    { 
        require(!_ArtistsRevealedIDs, "MPMX: Cannot Instantiate New SetApprovals Twice");
        _ArtistsRevealedIDs = true; 
    }

    /**
     * @dev Overrides Approval Index For MPMX
     */
    function __NewSetApprovalsArtistNames() external onlyOwner
    {
        require(!_ArtistRevealedNames, "MPMX: Cannot Instantiate New SetApprovals Twice");
        _ArtistRevealedNames = true;
    }

    /**
     * @dev Seeds Random ArtistIDs For A Sale
     */
    function __SeedRandomArtistIDs(string calldata URL, uint[] calldata NewArtistIDs) external onlyOwner
    {
        unchecked
        {
            for(uint x; x < NewArtistIDs.length; x++) 
            { 
                ArtistID[x] = NewArtistIDs[x]; 
            }
            _ArtistsRevealedIDs = true;
            emit RandomArtistIDsSeeded(URL, NewArtistIDs);
        }
    }

    /**
     * @dev Seeds Random Artist Names Into Contract
     */
    function __SeedRandomArtistNames(string calldata URL, string[] calldata Names) external onlyOwner
    {
        unchecked
        {
            for(uint x; x < Names.length; x++) { ArtistNames[x] = Names[x]; }
            _ArtistRevealedNames = true;
            emit ArtistNamesSeeded(URL, Names);
        }
    }

    /**
     * @dev Changes Starting Block Timestamps
     */
    function __NewBlockTimestamps(uint Timestamp) external onlyOwner
    {
        MintPackSale._StartingBlockUnixTimestamp = Timestamp;
        MintPassSale._StartingBlockUnixTimestamp = Timestamp;
        emit NewStartingTimestamp(Timestamp);
    }

    /**
     * @dev Changes Ending Price For Mint Pass *** DENOTED IN WEI ***
     */
    function __NewEndingPrice(uint PriceEnd) external onlyOwner 
    { 
        MintPassSale._PriceEnd = PriceEnd; 
    }

    /**
     * @dev Changes Ending Price For Mint Pack *** DENOTED IN WEI ***
     */
    function __NewEndingPriceMintPack(uint PriceEnd) external onlyOwner
    {
        MintPackSale._PriceEnd = PriceEnd;
    }

    /**
     * @dev Changes Merkle Root
     */
    function __NewRootMintPass(bytes32 NewRoot) external onlyOwner
    {
        bytes32 OldRoot = MintPassSale._Root;
        MintPassSale._Root = NewRoot;
        emit MerkleRootChanged(OldRoot, NewRoot);
    }

    /**
     * @dev Changes Merkle Root Mint Pack
     */
    function __NewRootMintPack(bytes32 NewRoot) external onlyOwner
    {
        bytes32 OldRoot = MintPackSale._Root;
        MintPackSale._Root = NewRoot;
        emit MerkleRootChanged(OldRoot, NewRoot);
    }

    /**
     * @dev Instantiates New Merkle Roots
     */
    function __NewRoots(bytes32 NewMintPassRoot, bytes32 NewMintPackRoot) external onlyOwner
    {
        bytes32 OldRootMintPass = MintPassSale._Root;
        bytes32 OldRootMintPack = MintPackSale._Root;
        MintPassSale._Root = NewMintPassRoot;
        MintPackSale._Root = NewMintPackRoot;
        emit MerkleRootsChanged(OldRootMintPass, OldRootMintPack, NewMintPassRoot, NewMintPackRoot);
    }

    /**
     * @dev Changes Final Settlement Price For A Sale *** DENOTED IN WEI ***
     */
    function __NewClearingPrice(uint FinalClearingPrice) external onlyOwner 
    { 
        MintPassInternalSale._FinalClearingPrice = FinalClearingPrice;
    }

    /**
     * @dev Instantiates New Multisig Address
     */
    function __NewMultisigAddress(address NewAddress) external onlyOwner 
    { 
        _BRT_MULTISIG = NewAddress; 
    }

    /**
     * @dev Instantiates New LiveMint Address
     */
    function __NewLiveMintAddress(address NewAddress) external onlyOwner 
    { 
        _LiveMint = NewAddress; 
    }

    /**
     * @dev Instantiates New LiveMint Contract Address
     */
    function __NewWhitelistedSenderAddress(address NewAddress) external onlyOwner 
    { 
        _WhitelistedSender[NewAddress] = !_WhitelistedSender[NewAddress]; 
    }

    /**
     * @dev Instantiates New Golden Token Address
     */
    function __NewOptionAddress(address NewAddress) external onlyOwner { Option = NewAddress; }

    /**
     * @dev Changes The BaseURI For JSON Metadata 
     */
    function __NewBaseURI(string calldata NewURI) external onlyOwner { baseURI = NewURI; }

    /**
     * @dev Ends All Sales
     */
    function __EndAllSales() external onlyOwner 
    {
        MintPackSale._ActiveBrightList = false;
        MintPackSale._ActivePublic = false;
        MintPassSale._ActiveBrightList = false;
        MintPassSale._ActivePublic = false;
    }

    /**
     * @dev Withdraws All Ether From The Contract
     */
    function ___WithdrawEther() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Withdraws Ether From Contract To Address With An Amount
     */
    function ___WithdrawEtherToAddress(address payable Recipient, uint Amount) external onlyOwner
    {
        require(Amount > 0 && Amount <= address(this).balance, "Invalid Amount");
        (bool Success, ) = Recipient.call{value: Amount}("");
        require(Success, "Unable to Withdraw, Recipient May Have Reverted");
    }

    /**
     * @dev Withdraws ERC721s From Contract
     */
    function ___WithdrawERC721(address Contract, address Recipient, uint[] calldata TokenIDs) external onlyOwner 
    { 
        for(uint TokenID; TokenID < TokenIDs.length;)
        {
            IERC721(Contract).transferFrom(address(this), Recipient, TokenIDs[TokenID]);
            unchecked { TokenID++; }
        }
    }

    /*-----------------
     * VIEW FUNCTIONS *
    ------------------*/

    /**
     * @dev Returns An Array Of ArtistIDs Corresponding To Input TokenIDs 
     */
    function ViewArtistIDsByTokenIDs(uint[] calldata TokenIDs) public view returns(uint[] memory)
    {   
        uint[] memory _ArtistIDs = new uint[](TokenIDs.length);
        for(uint TokenID; TokenID < TokenIDs.length; TokenID++)
        {
            _ArtistIDs[TokenID] = ArtistID[TokenIDs[TokenID]];
        }
        return _ArtistIDs;
    }

    /**
     * @dev Returns An Array Of ArtistIDs Corresponding To TokenIDs 0-999
     */
    function ViewAllArtistIDs() public view returns(uint[] memory)
    {
        uint[] memory __ArtistIDs = new uint[](1000);
        for(uint TokenID; TokenID < 1000; TokenID++)
        {
            __ArtistIDs[TokenID] = ArtistID[TokenID];
        }
        return __ArtistIDs;
    }

    /**
     * @dev Returns A Singular ArtistID
     */
    function ViewArtistID(uint TokenID) public view returns(uint) { return ArtistID[TokenID]; }

    /**
     * @dev Returns MintPassPrice & MintPackPrice
     */
    function ViewBothDutchPrices() public view returns(uint MintPassPrice, uint MintPackPrice)
    {
        return(ViewCurrentPriceMintPass(), ViewCurrentPriceMintPack());
    }

    /**
     * @dev Returns Address & Corresponding Refund Amount At `OrderIndex`
     */
    function ViewOrderRefund(uint OrderIndex) public view returns(address Wallet, uint RefundAmount)
    {
        return(
            UniqueSaleIndexToAddress[OrderIndex], 
            UniqueSaleToOrderValue[OrderIndex] - (ViewCurrentPriceMintPass() * UniqueSalePurchaseAmount[OrderIndex])
        );
    }

    /**
     * @dev Returns All Order Information Including Addresses And Corresponding Refund Amounts
     */
    function ViewAllOrderRefunds() public view returns (address[] memory, uint[] memory)
    {
        address[] memory Addresses = new address[](MintPassInternalSale._UniqueSales);
        uint[] memory Refunds = new uint[](MintPassInternalSale._UniqueSales);
        uint CurrentPrice = ViewCurrentPriceMintPass();
        for(uint OrderIndex; OrderIndex < MintPassInternalSale._UniqueSales;)
        {
            Addresses[OrderIndex] = UniqueSaleIndexToAddress[OrderIndex];
            Refunds[OrderIndex] = UniqueSaleToOrderValue[OrderIndex] - (CurrentPrice * UniqueSalePurchaseAmount[OrderIndex]);
            unchecked { OrderIndex++; }
        }
        return(Addresses, Refunds);
    }

    /**
     * @dev Returns Total Refund Amount & Sale Purchase Value
     */
    function ViewTotalRefundAmountAndSaleProceeds() public view returns (uint Refund, uint SaleProceeds)
    {
        unchecked
        {
            uint TotalRefundAmount;
            uint CurrentPrice = ViewCurrentPriceMintPass();
            for(uint OrderIndex; OrderIndex < MintPassInternalSale._UniqueSales; OrderIndex++)
            {
                TotalRefundAmount += UniqueSaleToOrderValue[OrderIndex] - (CurrentPrice * UniqueSalePurchaseAmount[OrderIndex]);
            }
            uint TotalSaleProceeds = address(this).balance - TotalRefundAmount;
            return (TotalRefundAmount, TotalSaleProceeds);
        }
    }

    /**
     * @dev Returns A Wallet's Owned `TokenIDs` & Corresponding `ArtistIDs`
     */
    function ViewWalletMPMXHoldings(address Wallet) public view returns (MPMXHoldings memory _Holdings)
    {
        unchecked
        {
            uint[] memory __TokenIDsOwned = new uint[](1000);
            uint NumOwned;
            for(uint x; x < 1000; x++)
            {
                if(_exists(x))
                {
                    if(IERC721(address(this)).ownerOf(x) == Wallet)
                    {
                        __TokenIDsOwned[NumOwned] = x;
                        NumOwned++;
                    }
                }
            }
            uint[] memory _ArtistIDsOwned = new uint[](NumOwned);
            uint[] memory _TokenIDsOwned = new uint[](NumOwned);
            for(uint x; x < NumOwned; x++)
            {
                _ArtistIDsOwned[x] = ArtistID[__TokenIDsOwned[x]];
                _TokenIDsOwned[x] = __TokenIDsOwned[x];
            }
            return MPMXHoldings(
                _TokenIDsOwned, 
                _ArtistIDsOwned, 
                _ArtistsRevealedIDs, 
                _ArtistRevealedNames
            );
        }
    }

    /**
     * @dev Returns A Wallet's Owned `TokenIDs` & Corresponding `ArtistIDs`
     */
    function ViewWalletOptionHoldings(address Wallet) public view returns (UserHoldings memory _Holdings)
    {
        unchecked
        {
            uint[] memory __TokenIDsOwned = new uint[](333);
            uint NumOwned;
            for(uint x; x < 333; x++)
            {
                try IERC721(Option).ownerOf(x)
                {
                    if(IERC721(Option).ownerOf(x) == Wallet)
                    {
                        __TokenIDsOwned[NumOwned] = x;
                        NumOwned++;
                    }
                } catch { }
            }
            uint[] memory _ArtistIDsOwned = new uint[](NumOwned);
            uint[] memory _TokenIDsOwned = new uint[](NumOwned);
            for(uint x; x < NumOwned; x++)
            {
                _ArtistIDsOwned[x] = ArtistID[__TokenIDsOwned[x]];
                _TokenIDsOwned[x] = __TokenIDsOwned[x];
            }
            return UserHoldings(_TokenIDsOwned, _ArtistIDsOwned, MintPassInternalSale._FinalClearingPrice);
        }
    }

    /**
     * @dev Returns MPMX Sale Information
     */
    function ViewAllMPMXSaleInformation() public view returns (MintPass memory, MintPack memory, SaleInformation memory) 
    {
        return(
            MintPassSale,
            MintPackSale, 
            SaleInformation(
                ViewCurrentPriceMintPass(),
                MintPassSale._MaximumAvailableForSale - MintPassInternalSale._AmountSold,
                MintPassSale._StartingBlockUnixTimestamp,
                MintPassSale._PriceStart,
                MintPassSale._PriceEnd,
                ViewCurrentPriceMintPack(),
                MintPackSale._MaximumAvailableForSale - MintPackInternalSale._AmountSold,
                MintPackSale._StartingBlockUnixTimestamp,
                MintPackSale._PriceStart,
                MintPackSale._PriceEnd
            )
        );
    }

    /**
     * @dev Returns MPMX Sale Information For A Given Wallet
     */
    function ViewWalletSaleInformation(
        address Wallet,
        bytes32[] calldata MintPassProof,
        bytes32[] calldata MintPackProof
    ) external view returns (UserSaleInformation memory) {
        bool MintPassSalePaused;
        bool MintPackSalePaused;
        if(
            !(MintPassSale._ActiveBrightList || MintPassSale._ActivePublic)
            &&
            (MintPassSale._MaximumAvailableForSale - MintPassInternalSale._AmountSold > 0)
        ) { MintPassSalePaused = true; }
        if(
            !(MintPackSale._ActiveBrightList || MintPackSale._ActivePublic)
            &&
            (MintPackSale._MaximumAvailableForSale - MintPackInternalSale._AmountSold > 0)
        ) { MintPackSalePaused = true; }        
        return(
            UserSaleInformation(
                ViewCurrentPriceMintPass(),
                _MintPassPurchasedAmt[Wallet],
                _WalletAllocationsMintPass[Wallet], 
                MintPassSale._MaximumAvailableForSale - MintPassInternalSale._AmountSold,
                VerifyBrightList(Wallet, MintPassProof, MintPassSale._Root),
                MintPassSalePaused,
                ViewCurrentPriceMintPack(),
                _MintPackPurchasedAmt[Wallet],
                _WalletAllocationsMintPack[Wallet],
                MintPackSale._MaximumAvailableForSale - MintPackInternalSale._AmountSold,
                VerifyBrightList(Wallet, MintPackProof, MintPackSale._Root),
                MintPackSalePaused
            )
        );
    }

    /**
     * @dev Returns Mint Pack Starting Indexes
     */
    function ViewMintPackStartingIndexes() public view returns (uint[] memory)
    {
        uint[] memory _MintPackIndexes = new uint[](MintPackStartingIndexes.length);
        for(uint x; x < MintPackStartingIndexes.length; x++)
        {
            _MintPackIndexes[x] = MintPackStartingIndexes[x];
        }
        return _MintPackIndexes;
    }

    /*---------------------
     * INTERNAL FUNCTIONS *
    ----------------------*/

    /**
     * @dev Returns Current Dutch Price For Mint Pass
     */
    function ViewCurrentPriceMintPass() internal view returns (uint Price) 
    {
        if(block.timestamp <= MintPackSale._StartingBlockUnixTimestamp) { return MintPassSale._PriceStart; }  // Sale Not Started
        if(MintPassInternalSale._FinalClearingPrice > 0) { return MintPassInternalSale._FinalClearingPrice; } // Sale Finished
        uint CurrentPrice = MintPassSale._PriceStart;
        uint SecondsElapsed = block.timestamp - MintPassSale._StartingBlockUnixTimestamp;
        CurrentPrice >>= SecondsElapsed / MintPassSale._SecondsBetweenPriceDecay; // Div/2 For Each Half Life Iterated Upon
        CurrentPrice -= (CurrentPrice * (SecondsElapsed % MintPassSale._SecondsBetweenPriceDecay)) / MintPassSale._SecondsBetweenPriceDecay / 2;
        if(CurrentPrice <= MintPassSale._PriceEnd) { return MintPassSale._PriceEnd; } // Sale Ended At Resting Band
        return CurrentPrice; // Sale Currently Active
    }

    /**
     * @dev Returns Current Dutch Price For Mint Pack
     */
    function ViewCurrentPriceMintPack() internal view returns (uint Price) 
    {
        if(block.timestamp <= MintPackSale._StartingBlockUnixTimestamp) { return MintPackSale._PriceStart; }  // Sale Not Started
        if(MintPackInternalSale._FinalClearingPrice > 0) { return MintPackInternalSale._FinalClearingPrice; } // Sale Finished
        uint CurrentPrice = MintPackSale._PriceStart;
        uint SecondsElapsed = block.timestamp - MintPackSale._StartingBlockUnixTimestamp;
        CurrentPrice >>= SecondsElapsed / MintPackSale._SecondsBetweenPriceDecay; // Div/2 For Each Half Life Iterated Upon
        CurrentPrice -= (CurrentPrice * (SecondsElapsed % MintPackSale._SecondsBetweenPriceDecay)) / MintPackSale._SecondsBetweenPriceDecay / 2; 
        if(CurrentPrice <= MintPackSale._PriceEnd) { return MintPackSale._PriceEnd; } // Sale Ended At Resting Band
        return CurrentPrice; // Sale Currently Active
    }

    /**
     * @dev Returns Base URI
     */
    function _baseURI() internal view virtual override returns (string memory) { return baseURI; }

    /**
     * @dev Returns If User Is On BrightList
     */
    function VerifyBrightList(address Recipient, bytes32[] calldata Proof, bytes32 Root) internal pure returns (bool)
    {
        bytes32 Leaf = keccak256(abi.encodePacked(Recipient));
        return MerkleProof.verify(Proof, Root, Leaf);
    }

    /**
     * @dev Ends Mint Pass Sale On Sellout
     */
    function ___EndMintPassSale() internal
    {
        MintPassSale._ActiveBrightList = false;
        MintPassSale._ActivePublic = false;
    }

    /**
     * @dev Ends Mint Pack Sale On Sellout
     */
    function __EndMintPackSale() internal
    {
        MintPackSale._ActivePublic = false;
        MintPackSale._ActiveBrightList = false;
    }

    /**
     * @dev Refunds `Recipient` ETH Amount `Value`
     */
    function __Refund(address Recipient, uint Value) internal
    {
        (bool Confirmed,) = Recipient.call{value: Value}(""); 
        require(Confirmed, "MPMX: Refund failed");
        emit Refunded(Value);
    }

    /*--------------------
     * LIVEMINT FUNCTION *
    ---------------------*/

    /**
     * @dev LiveMint Redeems Mint Pass If Not Already Burned & Sends Minted Work To Owner's Wallet
     */
    function _LiveMintBurn(uint TokenID) external returns (address _Recipient, uint _ArtistID)
    {
        require(msg.sender == _LiveMint, "MPMX: Sender Is Not Live Mint");
        address Recipient = IERC721(address(this)).ownerOf(TokenID);
        require(Recipient != address(0), "MPMX: Invalid Recipient");
        _burn(TokenID, false);
        return (Recipient, ArtistID[TokenID]);
    }
}