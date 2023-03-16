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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./CentBaseTimedAuctionBETA.sol";


/// @title CentBaseMarketPlaceBETA.
/// @author @Dadogg80 - Viken Blockchain Solutions.

/// @notice This is the marketplace smartcontract with all the global variables, custom errors, events, 
///         and modifiers derived from the Centaurify TimedAuction and Storage smart contracts.     


contract CentBaseMarketPlaceBETA is CentBaseTimedAuctionBETA, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ERC165Checker for address;
    
    Counters.Counter private _itemsIndex;
    Counters.Counter private _itemsSold;

    Counters.Counter private _orderIds;
    Counters.Counter private _ordersSold;

    /// @notice The constructor will set the serviceWallet address and deploy a escrow contract.
    /// @dev Will emit the event { EscrowDeployed }.
    constructor(address payable _serviceWallet, address _operator) {
        require(_serviceWallet != address(0));

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _operator);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ITEM_CREATOR_ROLE, _operator);

        serviceFee = 200;
        serviceWallet = _serviceWallet;
        escrow = new Escrow();

        emit EscrowDeployed(escrow, address(this));
    }

    /// @notice Creates an new MarketItem on the marketplace.
    /// @dev ATTENTION this function require approvals from `nftContract` to transfer tokenId
    /// @param nftContract Contract address of the nft to add to marketplace. 
    /// @param tokenId The tokenId the token to add on the marketplace.
    /// @param seller The address of the seller of this nft.
    /// @return itemId Will return the bytes32 marketItemId.
    function createMarketItem(address nftContract, uint256 tokenId, address payable seller) 
        public
        onlyRole(ITEM_CREATOR_ROLE)
        returns (bytes32 itemId) 
    {
        //if (seller != IERC721(nftContract).ownerOf(tokenId)) revert NotTokenOwner();
        return _createMarketItem(nftContract, tokenId, seller);
    }

    /// @notice Creates an new MarketOrder of a marketItem.
    /// @param itemId Id of the marketItem to create a market order. 
    /// @param priceInWei The sales price of this order.
    /// @return orderId Will return the bytes32 orderId. 
    function createMarketOrder(bytes32 itemId, uint256 priceInWei) 
        public
        nonReentrant
        isAuthorized(itemId)
        isNotActive(itemId)
        returns (bytes32)
    {
        MarketItem storage _item = itemsMapping[itemId];
        uint256 _priceInWei = priceInWei;
        
        if (_priceInWei <= 0) revert LowValue(_priceInWei);

        _orderIds.increment();
        bytes32 _orderId = bytes32(_orderIds.current());
        
        if (ordersMapping[_orderId].isOrder) revert ActiveOrder(_orderId);

        ordersMapping[_orderId] = MarketOrder(
            _orderId,
            _item.itemId,
            _priceInWei,
            true,
            false
        );

        _item.status = Status(1);
        _item.active = true;

        arrayOfOrderIds.push(_orderId);

        emit MarketOrderCreated(
            _orderId,
            _item.itemId,
            _priceInWei,
            true
        );

        return _orderId;
    }

    /// @notice Method used to purchase a marketOrder.
    /// @param one Requires the param to be bool true.
    /// @param orderId The id of the MarketOrder to purchase.
    function executeOrder(bool one, bytes32 orderId) 
        external 
        payable 
        isActiveOrder(orderId) nonReentrant 
        costs(one, orderId) 
    {
        _executeOrder(one, orderId, _msgSender());
    }

    /// @notice Method used to remove an order from listing on our marketplace.
    /// @dev Restricted to the {seller/tokenOwner} or the marketplace {owner} account.
    /// @dev Will emit the event { MarketOrderRemoved }.
    /// @param orderId The orderId to cancel.
    function cancelOrder(bytes32 orderId) 
        external 
        isActiveOrder(orderId)
        isAuthorized(ordersMapping[orderId].itemId)
    {
        bytes32 _orderId = orderId;
        bytes32 _itemId = ordersMapping[_orderId].itemId;
        MarketItem storage _item = itemsMapping[_itemId];

        ordersMapping[_orderId].isOrder = false;
        ordersMapping[_orderId].sold = false;

        _item.status = Status(0);
        _item.active = false;
        
        _orderRemove(_orderId);
        emit MarketOrderRemoved(_orderId, _msgSender());
    }

    /// @notice Method used to remove an item from our marketplace.
    /// @param itemId The itemId to remove.
    /// @dev Restricted to the {seller/tokenOwner} or the marketplace {owner} account.
    /// @dev Will emit the event { MarketItemRemoved }.
    function removeItem(bytes32 itemId) external isAuthorized(itemId) isNotActive(itemId) {
        _itemRemove(itemId);
        emit MarketItemRemoved(itemId, _msgSender());
    }

    /// @notice Get the market item.
    /// @param itemId The itemId to query .
    /// @return marketItem Returns the MarketItem struct.
    function getMarketItem(bytes32 itemId) external view returns (MarketItem memory) {
        return itemsMapping[itemId];
    }

    /// @notice Get the information regarding a specific orderId.
    /// @param orderId The orderId to query.
    /// @return marketOrder Returns the MarketOrder struct.
    function getMarketOrder(bytes32 orderId) external view returns (MarketOrder memory) {
        return ordersMapping[orderId];
    }

       /// @notice Internal method to fetch all the marketItems.
    /// @return activeMarketItems Returns an bytes32 array of all active marketItemIds.
    function fetchMarketItems() external view returns (bytes32[] memory){
        return activeMarketItems;
    }

    /// @notice Method used to fetch all the marketOrders.
    /// @return marketOrder Returns an array of all the active marketOrders structs.
    function fetchMarketOrders() external view returns (MarketOrder[] memory) {
        uint orderCount = _orderIds.current();
        uint unsoldOrderCount = _orderIds.current() - _ordersSold.current();
        uint currentIndex = 0;

        MarketOrder[] memory _orders = new MarketOrder[](unsoldOrderCount);
        for (uint i = 0; i < orderCount; i++) {
            bytes32 currentId = bytes32(i + 1);
            MarketOrder storage currentOrder = ordersMapping[currentId];
            if (currentOrder.isOrder) {
                _orders[currentIndex] = currentOrder;
                currentIndex += 1;
            }
            if (currentIndex == unsoldOrderCount) break;
        }
        return _orders;
    }

/// --------------------------------- PRIVATE METHODS ---------------------------------

    /// @notice Private method to remove/delete an MarketItem from the marketplace.
    /// @param itemId The id of the order to remove.
    function _itemRemove(bytes32 itemId) private {
        if (itemsMapping[itemId].active) revert IsActive(itemId, itemsMapping[itemId].status);
        delete itemsMapping[itemId];
    }
    
    /// @notice Private method to remove/delete an MarketOrder from the marketplace.
    /// @param orderId The id of the order to remove.
    function _orderRemove(bytes32 orderId) private {
        if (ordersMapping[orderId].isOrder) revert ActiveOrder(orderId);
        delete ordersMapping[orderId];
    }

    /// @notice Private helper method used to purchase a marketOrder.
    /// @param one Requires the param to be bool true.
    /// @param orderId The id of the MarketOrder to purchase.
    /// @param buyer The address of the buyer
    function _executeOrder(bool one, bytes32 orderId, address buyer) private {
        if (one != true) revert ErrorMessage("Requires bool value: true");
        MarketOrder storage _order = ordersMapping[orderId];
        if (!_order.isOrder) revert NoListing(_order.orderId);
 
        _order.isOrder = false;
        _order.sold = true;       
        _ordersSold.increment();

        MarketItem storage _item = itemsMapping[_order.itemId];
        _item.status = Status(0);
        _item.active = false;

        (, uint256 _toSellerAmount, uint256 _totalFeeAmount) = _calculateFees(_order.priceInWei);

        _orderRemove(_order.orderId);
        
        (bool success) = IERC165(_item.nftContract).supportsInterface(_INTERFACE_ID_ERC2981);
        
        if (!success) {
            (bool _success,) = serviceWallet.call{value: _totalFeeAmount}("");
            if (!_success) revert FailedTransaction("Fees");
            _sendPaymentToEscrow(_item.tokenOwner, _toSellerAmount);
            emit TransferServiceFee(serviceWallet, _totalFeeAmount);
        
        } else {
            _transferRoyaltiesAndServiceFee(_item, _totalFeeAmount, _toSellerAmount);
        }

        IERC721(_item.nftContract).safeTransferFrom(address(this), buyer, _item.tokenId);
    
        emit MarketOrderSold(orderId, _item.tokenId, _order.priceInWei, _item.nftContract, _item.escrow, _item.tokenOwner, _msgSender());
    }

    /// @notice Restricted method used to create a new market item
    /// @dev Restricted to internal view.
    function _createMarketItem(address nftContract, uint256 tokenId, address payable seller) 
        internal
        returns (bytes32 itemId) 
    {
        if (seller != IERC721(nftContract).ownerOf(tokenId)) revert NotTokenOwner();
        uint256 _index = _itemsIndex.current();
        uint256 _salt = block.timestamp;
        bytes32 _itemId = keccak256(abi.encodePacked(_msgSender(), nftContract, tokenId, _salt));
        
        itemsMapping[_itemId] = MarketItem(
            _itemId,
            _index,
            payable(seller),
            address(this),
            escrow,
            nftContract,
            tokenId,
            Status(0),
            false
        );

        activeMarketItems.push(_itemId);
        _itemsIndex.increment();

        emit MarketItemCreated(_itemId, _index, seller);

        IERC721(nftContract).safeTransferFrom(seller, address(this), tokenId);
        
        return _itemId;
    }
/// --------------------------------- ADMIN METHODS ---------------------------------

    /// @notice Restricted method used to withdraw the funds from the marketplace.
    /// @dev Restricted to Admin Role.
    function withdraw() external onlyRole(ADMIN_ROLE) {
        (bool success,) = payable(_msgSender()).call{value: address(this).balance}("");
        if (!success) revert ErrorMessage("Withdraw Failed");
        emit Withdraw();
    }

    /// @notice Restricted method used to withdraw any stuck erc20 in this smart-contract.
    /// @dev Restricted to Admin Role.
    /// @param erc20Token The address of stuck erc20 token to release.
    function releaseStuckTokens(address erc20Token) external onlyRole(ADMIN_ROLE) {
        uint256 balance = IERC20(erc20Token).balanceOf(address(this));
        require(IERC20(erc20Token).transfer(_msgSender(), balance));
    }

    /// @notice Restricted method used to set the serviceWallet.
    /// @dev Restricted to Admin Role.
    /// @param _serviceWallet The new account to receive the service fee.
    /// @dev Emits the event { ServiceWalletUpdated }.
    function updateServiceWallet(address payable _serviceWallet) external onlyRole(ADMIN_ROLE) {
       serviceWallet = _serviceWallet;
       emit ServiceWalletUpdated(serviceWallet);
    }

    /// @notice Updates the service fee of the contract.
    /// @dev Restricted to Admin Role.
    /// @param _serviceFee The updated service fee in percentage to charge for selling and buying on our marketplace.
    function updateServiceFee(uint16 _serviceFee) external onlyRole(ADMIN_ROLE) {
        serviceFee = _serviceFee;
    }

    /// --------------------------------- BUYER SERVICE METHODS ---------------------------------

    /// @notice Method used to purchase a marketOrder on behalf of a buyer.
    /// @param one Requires the param to be bool true.
    /// @param orderId The id of the MarketOrder to purchase.
    /// @param buyer The address of the buyer
    function executeOrderForBuyer(bool one, bytes32 orderId, address buyer) 
        external 
        payable
        onlyRole(BUYER_SERVICE_ROLE)
        isActiveOrder(orderId) nonReentrant 
        costs(one, orderId) 
    {
        _executeOrder(one, orderId, buyer);
    }

    /// @notice Method used to batch { createMarketItem and createMarketOrder } into one transaction.
    /// @dev RESTIRCTED to ITEM_CREATOR_ROLE.
    /// @dev ATTENTION this function require approvals from `collection` to transfer tokenId
    /// @param collection Collection address of the nft to add to marketplace. 
    /// @param tokenId The tokenId the token to add on the marketplace.
    /// @param seller The address of the seller of this nft.
    /// @param priceInWei The sales price of this nft. 
    /// @return itemId orderId Will return the bytes32 itemId and orderId.
    function listAndSellNewCollection(address collection, uint256 tokenId, address payable seller, uint256 priceInWei) 
        external 
        onlyRole(ITEM_CREATOR_ROLE) 
        returns (bytes32 itemId, bytes32 orderId) 
    {
        approvedCollections[collection] = true;
        //if (seller != IERC721(collection).ownerOf(tokenId)) revert NotTokenOwner();
        itemId = _createMarketItem(collection, tokenId, seller);
        orderId = createMarketOrder(itemId, priceInWei);
        emit ListedForSale(collection, seller, tokenId, priceInWei, itemId, orderId);
    }

    /// @notice Method used to batch an pre-approved collection into one transaction.
    /// @dev ATTENTION this function require approvals from `collection` to transfer tokenId
    /// @param collection Collection address of the nft to add to marketplace. 
    /// @param tokenId The tokenId the token to add on the marketplace.
    /// @param priceInWei The sales price of this nft. 
    /// @return itemId orderId Will return the bytes32 itemId and orderId.
    function listAndSellPreApprovedCollection(address collection, uint256 tokenId, uint256 priceInWei) 
        external 
        returns (bytes32 itemId, bytes32 orderId) 
    {
        if(!approvedCollections[collection]) revert CollectionNotApproved();
        //if (msg.sender != IERC721(collection).ownerOf(tokenId)) revert NotTokenOwner();
        itemId = _createMarketItem(collection, tokenId, payable(msg.sender));
        orderId = createMarketOrder(itemId, priceInWei);
        emit ListedForSale(collection, msg.sender, tokenId, priceInWei, itemId, orderId);
    }

    /// @notice Method used to add an pre-approved collection.
    /// @param collection contract address to approve
    /// @param isApproved true to add and false to remove collection.
    function approveCollection(address collection, bool isApproved) external onlyRole(ADMIN_ROLE) {
        approvedCollections[collection] = isApproved;
        emit CollectionApproved(collection, isApproved);
    }


   
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/// @title CentBaseStorageBETA.
/// @author @Dadogg80 - Viken Blockchain Solutions.

/// @notice This is the storage contract containing all the global variables, custom errors, events, 
///         and modifiers inherited by the Centaurify NFT marketplace smart contract.       

contract CentBaseStorageBETA is ERC721Holder, Context, AccessControlEnumerable {

    /// @notice Enum Status is the different statuses.
    /// @param Listed means token is in our marketplace contract.
    /// @param Order means that a market order is live. 
    /// @param TimedAuction means that a timed auction is live.
    enum Status { Listed, Order, TimedAuction }

    /// @notice Escrow contract that holds the seller funds and pendingReturns.
    /// @return escrow The Escrow contract address.
    Escrow public escrow;

    /// @notice The account that will receive the service fee.
    /// @return serviceWallet The serivce wallet address.
    address payable public serviceWallet;

    /// @notice The service fee cost of listing in BIPS.
    /// @dev 200 BIPS is 2 percent. 
    uint16 public serviceFee; 

    /// @dev Array containing liveMarketItem id's.
    bytes32[] internal activeMarketItems; 

    /// @dev Array containing order ids.
    bytes32[] internal arrayOfOrderIds;

    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ITEM_CREATOR_ROLE = keccak256("ITEM_CREATOR_ROLE");
    bytes32 public constant BUYER_SERVICE_ROLE = keccak256("BUYER_SERVICE_ROLE");

    /// ------------------------------- STRUCTS -------------------------------

    /// @notice A marketItem is a listed token.
    /// @param itemId The uniqe id of this marketItem.
    /// @param tokenOwner The owner of this marketItem.
    /// @param operator The operator is this marketplace contract.
    /// @param escrow The escrow contract address. 
    /// @param nftContract The contract address of this marketItem.
    /// @param TokenId The tokenId of this marketItem.
    /// @param status The current status of this marketItem.
    struct MarketItem {
        bytes32 itemId;
        uint256 index;
        address payable tokenOwner;
        address operator;   
        Escrow escrow; 
        address nftContract;
        uint256 tokenId;
        Status status;
        bool active;
    }

    /// @notice A MarketOrder is a struct with info of a listed NFT token.
    /// @param orderId The id of this marketOrder.
    /// @param itemId The marketItem to sell as this MarketOrder.
    /// @param priceInWei The salesPrice of this MarketOrder.
    /// @param isOrder Is true if this MarketOrder is listed.
    /// @param sold Is true if this MarketOrder is sold.
    struct MarketOrder {
        bytes32 orderId;
        bytes32 itemId;           
        uint256 priceInWei;            
        bool isOrder;
        bool sold;
    }

    /// @notice A marketAuction struct is a marketItem that is in an ongoing timed auction.
    /// @param auctionId The id of the timed auction.
    /// @param itemId The id of the marketitem to sell on timed auction.
    /// @param auctionEndTime The timestamp to end the timed auction.
    /// @param highestBid The current highest bid.
    /// @param ended Is true if ended, false if ongoing.
    /// @param status The current status of this marketItem.
    struct MarketAuction {
        bytes32 auctionId; 
        bytes32 itemId; 
        uint256 auctionEndTime;
        uint256 highestBid;
        address highestBidder;
        bool ended;
    }

    /// ------------------------------- MAPPINGS -------------------------------

    /// @notice Mapping is used to store the MarketItems.
    mapping(bytes32 => MarketItem) public itemsMapping;

    /// @notice From ERC721 registry assetId to MarketOrder (to avoid asset collision).
    mapping(bytes32 => MarketOrder) public ordersMapping;
    
    /// @notice Mapping is used to store the MarketAuctions.
    /// @dev auctionId Pass a auctionId and get the MarketAuction in return. 
    mapping(bytes32 => MarketAuction) public auctionsMapping;

    /// @notice Maps token address to bool for either true (token is accepted as payment).
    mapping(address => bool) public acceptedTokenMap;

    /// @notice Maps user address to amount in pendingReturns.
    mapping(address => uint256) public pendingReturns;

    /// @notice mapping with approved collection addresses.
    mapping(address => bool) public approvedCollections;

    /// ------------------------------- MODIFIERS -------------------------------

    /// @notice Modifier will validate if the itemId is an active marketItem.
    /// @param itemId The itemId of the nft to validate. 
    modifier isActiveItem(bytes32 itemId) {
        MarketItem memory _item = itemsMapping[itemId];
        if (!_item.active) revert NotActive(_item.itemId);
        _;
    }

    /// @notice Modifier will validate if the orderId is an active market order.
    /// @param orderId The orderId of the order to validate. 
    modifier isActiveOrder(bytes32 orderId) {
        MarketOrder memory _order = ordersMapping[orderId];
        if (!_order.isOrder) revert NotActive(_order.orderId);
        _;
    } 

    /// @dev Modifier will validate that the marketItem is not already a live item.
    /// @param itemId The id of the marketItem.
    modifier isNotActive(bytes32 itemId) {
        MarketItem memory _item = itemsMapping[itemId];
        if (_item.active) revert IsActive(_item.itemId, _item.status);
        _;
    }

    /// @dev Modifier will validate if the caller is authorized.
    /// @param itemId The tokenId of the nft to validate.
    modifier isAuthorized(bytes32 itemId) {
        MarketItem memory _item = itemsMapping[itemId];
        if (_item.tokenOwner != _msgSender()) revert NotAuth();
        _;
    }

    /// @dev Modifier will validate if the caller is the seller.
    /// @param seller The account to validate.
    modifier isAuth(address payable seller) {
        if (seller != _msgSender()) revert NotAuth();
        _;
    }

    /// @notice Modifier will validate that the auctionId is a live auction.
    /// @param auctionId The id of the auction to bid on.
    modifier isLiveAuction(bytes32 auctionId) {
        MarketAuction memory _a = auctionsMapping[auctionId];
            if (_a.ended) revert NotActive(_a.auctionId);
        _;
    }

    /// @dev Modifier will validate that the bid is above current highest bid.
    /// @param auctionId The id of the auction to bid on.
    modifier minBid(bytes32 auctionId) {
        MarketAuction memory a = auctionsMapping[auctionId];
        if (msg.value <= a.highestBid) revert LowValue(a.highestBid);
        _;
    }

    /// @dev Modifier will validate that the costs are covered.
    /// @param status The item status, true if ORDER, false if AUCTION.
    /// @param id The id to identify the order/auction.
    modifier costs(bool status, bytes32 id) {
        if (status) {
            MarketOrder memory _order = ordersMapping[id];
            (uint256 serviceAmount, uint256 sellerAmount, ) = _calculateFees(
                _order.priceInWei
            );
            uint256 sum = (_order.priceInWei + serviceAmount);
            if (msg.value < sum) revert LowValue(sum);
        } else {
            MarketAuction memory _auction = auctionsMapping[id];
            (uint256 serviceAmount, uint256 sellerAmount, ) = _calculateFees(
                _auction.highestBid
            );
            uint256 sum = (_auction.highestBid + serviceAmount);
            if (msg.value < sum) revert LowValue(sum);
        }
    _;
    }

    /// ------------------------------- CUSTOM ERRORS -------------------------------

    /// @notice Thrown if 0 is passed as a value.
    error NoZeroValues();

    /// @notice Thrown if caller is not authorized.
    error NotAuth();
   
    /// @notice Thrown if caller is not authorized Role.
    error NotAuthorizedRole();
 
    /// @notice Thrown if caller is not authorized or owner of the token.
    error NotTokenOwner();

    /// @notice Thrown if the msg.value is to low to transact.
    /// @param expected The expected value.
    error LowValue(uint256 expected);

    /// @notice Thrown if the marketItem is not an active market item.
    /// @param id The Id of the market Item.
    error NotActive(bytes32 id);

    /// @notice Thrown if the market item is already a active order or auction.
    /// @param itemId The Id of the market Item.
    /// @param status The status of the market Item.
    error IsActive(bytes32 itemId, Status status);

    /// @notice Thrown if the NFT is already listed as market order.
    /// @param orderId The Id of the market order.
    error ActiveOrder(bytes32 orderId);
 
    /// @notice Thrown if the NFT is not listed as market order.
    /// @param orderId The Id of the market order.
    error NoListing(bytes32 orderId);

    /// @notice Thrown with a string message.
    /// @param message Error message string.
    error ErrorMessage(string message);

    /// @notice Thrown with a string message.
    /// @param failed Error message string describes what transaction failed.
    error FailedTransaction(string failed);

    /// @notice Thrown if the collection is not pre-approved.
    error CollectionNotApproved();

   /// ------------------------------- EVENTS -------------------------------

    /// @notice Emitted when a new marketItem is created.
    /// @param collection Indexed - The address of the collection.
    /// @param isApproved Indexed - The status of the collection.
    event CollectionApproved(
        address indexed collection,
        bool indexed isApproved
    );

    /// @notice Emitted when the serviceWallet is updated.
    /// @param serviceWallet Indexed - The new account to serve as service wallet.
    event ServiceWalletUpdated(
        address indexed serviceWallet
    );

    /// @notice Emitted when the serviceFee transaction is completed.
    /// @param serviceWallet Indexed - The account to receive the fee amount.
    /// @param amount The transacted fee amount.
    event TransferServiceFee(
        address indexed serviceWallet, 
        uint256 amount
    );

    /// @notice Emitted when the serviceFee transaction is completed.
    /// @param receiver Indexed - The account to receive the royalty amount.
    /// @param amount The transacted royalty amount.
    event TransferRoyalty(
        address indexed receiver, 
        uint256 amount
    );

    /// @notice Emitted when a new marketItem is created.
    /// @param itemId Indexed - The Id of this marketItem. 
    /// @param index Indexed - The index position of this marketItem in the "liveMarketItems" array.
    /// @param tokenOwner Indexed - The owner of this marketItem. 
    event MarketItemCreated(
        bytes32 indexed itemId,
        uint256 indexed index,
        address indexed tokenOwner
    );

    /// @notice Emitted when a new marketItem is removed.
    /// @param itemId Indexed - The Id of this marketItem. 
    /// @param tokenOwner Indexed - The owner of this marketItem. 
    event MarketItemRemoved(
        bytes32 indexed itemId,
        address indexed tokenOwner
    );

    /// @notice Emitted when a new marketOrder is created.
    /// @param orderId Indexed - The Id of this marketOrder.
    /// @param itemId Indexed - The marketItemId in this marketOrder. 
    /// @param priceInWei The salesprice nominated in wei.
    /// @param isOrder Indexed - Indicates if this an order or not. 
    event MarketOrderCreated(
        bytes32 indexed orderId,
        bytes32 indexed itemId,                
        uint256 priceInWei,              
        bool indexed isOrder
    );

    /// @notice Emitted when a marketOrder is sold.
    /// @param orderId The Id of this marketOrder.
    /// @param tokenId The tokenId of this marketOrder.
    /// @param priceInWei The salesprice nominated in wei.
    /// @param nftContract Indexed - The smartcontact of this nft.
    /// @param escrow The escrow contract containing the payment.
    /// @param seller Indexed - The seller of this marketOrder.
    /// @param buyer Indexed - The buyer of this marketOrder.
    event MarketOrderSold(
        bytes32 orderId,
        uint256 tokenId,
        uint256 priceInWei,
        address indexed nftContract,
        Escrow escrow,
        address indexed seller,
        address indexed buyer
    );

    /// @notice Emitted when a marketOrder is removed.
    /// @param orderId Indexed - The Id of this marketOrder.
    /// @param tokenOwner Indexed - The tokenOwner of this marketOrder.
    event MarketOrderRemoved(
        bytes32 indexed orderId, 
        address indexed tokenOwner
    );
    
    /// @notice Emitted on marketplace deployment, escrow is deployed by the constructor .
    /// @param escrow Indexed - The contract address of the escrow.
    /// @param operator Indexed - The account authorized to interact with the escrow contract.
    event EscrowDeployed(
        Escrow indexed escrow, 
        address indexed operator
    );

    /// @notice Emitted when a market item has been sold and funds are deposited into escrow.
    /// @param seller Indexed - The receiver of the funds.
    /// @param value The salesprice of the nft, minus the servicefee and royalty amount.
    event DepositToEscrow(
        address indexed seller, 
        uint256 value
    );

    /// @notice Emitted on withdrawals from the escrow contract.
    /// @param seller Indexed - The receiver of the funds.
    event WithdrawFromEscrow(
        address indexed seller
    );
    
    /// @notice Emitted when a new timed auction is created.
    /// @param auctionId Indexed - The auction Id.
    /// @param itemId Indexed - The marketItemId in this auction. 
    /// @param seller Indexed - The seller of this nft.
    event MarketAuctionCreated(
        bytes32 indexed auctionId, 
        bytes32 indexed itemId, 
        address indexed seller
    );
    
    /// @notice Emitted when an auction is claimed.
    /// @param auctionId Indexed - The auctionId.
    /// @param itemId Indexed - The itemId of this auction.
    /// @param winner Indexed - The winner of the auction.
    /// @param amount The amount of the bid.
    event AuctionClaimed(
        bytes32 indexed auctionId, 
        bytes32 indexed itemId, 
        address indexed winner, 
        uint256 amount
    );
    
    
    /// @notice Emitted when an auction is not sold.
    /// @param auctionId Indexed - The auctionId.
    /// @param itemId Indexed - The itemId of this auction.
    event NoBuyer(
        bytes32 indexed auctionId, 
        bytes32 indexed itemId
    );

    /// @notice Emitted when an auction is removed.
    /// @param auctionId Indexed - The auctionId.
    /// @param itemId Indexed - The itemId of this auction.
    /// @param highestBidder Indexed - The winner of the auction.
    /// @param highestBid The highestBid of this auction.
    /// @param timestamp The timestamp when this event was emitted.
    event AuctionRemoved(
        bytes32 indexed auctionId, 
        bytes32 indexed itemId, 
        address indexed highestBidder,
        uint256 highestBid,
        uint256 timestamp
    );

    /// @notice Emitted when a higher bid is registered for an auction.
    /// @param auctionId Indexed - The auctionId.
    /// @param bidder Indexed - The receiver of the funds.
    /// @param amount The amount of the bid.
    event HighestBidIncrease(
        bytes32 indexed auctionId, 
        address indexed bidder, 
        uint256 amount
    );

    /// @notice Emitted on withdrawals from the marketplace contract.
    event Withdraw();

    /// @notice Emitted on withdrawals from the pending returns in escrow.
    /// @param to Indexed - The receiver of the funds.
    /// @param amount The withdraw amount.
    event WithdrawPendingReturns(
        address indexed to, 
        uint256 amount
    );

    /// @notice Emitted after an asset has been purchased and transfered to the new owner
    /// @param to Indexed - The receiver of the ntf.
    /// @param collection Indexed - The NFT smart contract address.
    /// @param tokenId Indexed - The tokenId.
    event AssetSent(
        address indexed to,
        address indexed collection,
        uint256 indexed tokenId
    );

    /// @notice Emitted when an item and order has been batch ready for sale.
    /// @param collection Indexed - The smartcontact address of this nft.
    /// @param seller Indexed - The seller of this marketOrder.
    /// @param tokenId The tokenId of this marketOrder.
    /// @param priceInWei The salesprice nominated in wei.
    /// @param itemId The Id of this marketItem.
    /// @param orderId Indexed - The Id of this marketOrder.
    event ListedForSale(
        address indexed collection, 
        address indexed seller, 
        uint256 tokenId, 
        uint256 priceInWei, 
        bytes32 itemId, 
        bytes32 indexed orderId
    );

    /// @notice Method used to check if the user is a HODLER of a specific nft collection.
    /// @param account The user account.
    /// @param collection The nft contract address to check.
    /// @return balance The amount of nft the user is HODLING.
    function isHodler(address account, address collection) external view returns (uint256 balance){
        return IERC721(collection).balanceOf(account);
    }

    /// @notice Method used to calculate the serviceFee to transfer.
    /// @param _priceInWei the salesPrice.
    /// @return serviceFeeAmount The amount to send to the service wallet.
    /// @return sellerAmount The amount to send to the seller.
    /// @return totalFeeAmount Includes service fee seller side, and service fee buyer side.
    function _calculateFees(uint _priceInWei)
        internal
        view
        returns 
    (
        uint serviceFeeAmount, 
        uint sellerAmount,
        uint totalFeeAmount
    )
    {
        serviceFeeAmount = (serviceFee * _priceInWei) / 10000;
        totalFeeAmount = (serviceFeeAmount * 2);
        sellerAmount = (_priceInWei - totalFeeAmount);
        return (serviceFeeAmount, sellerAmount, totalFeeAmount);
    }

    /// @notice Internal method used to deposit the salesAmount into the Escrow contract.
    /// @param tokenOwner The address of the seller of the MarketOrder.
    /// @param value The priceInWei of the listed order.
    function _sendPaymentToEscrow(address payable tokenOwner, uint256 value)
        internal
    {
        escrow.deposit{value: value}(tokenOwner);
        emit DepositToEscrow(tokenOwner, value);
    }


    /// @notice Internal method used to transfer the royalties and service fee.
    /// @param _item The MarketItem struct.
    /// @param _totalFeeAmount The _totalFeeAmount to transfer.
    /// @param _toSellerAmount The amount to transfer to escrow.
    function _transferRoyaltiesAndServiceFee(
        MarketItem memory _item, 
        uint256 _totalFeeAmount, 
        uint256 _toSellerAmount
    ) 
        internal 
    {

        (address _royaltyReceiver, uint256 _royaltyAmount) = 
            IERC2981(_item.nftContract)
                .royaltyInfo(_item.tokenId, _toSellerAmount);

        uint256 _toEscrow = (_toSellerAmount - _royaltyAmount); 

        (bool success,) = serviceWallet.call{value: _totalFeeAmount}(""); 
        if (!success) revert FailedTransaction("Fees");
        emit TransferServiceFee(serviceWallet, _totalFeeAmount);
        
        (bool _success,) = _royaltyReceiver.call{value: _royaltyAmount}(""); 
        if (!_success) revert FailedTransaction("Royalty");
        
        _sendPaymentToEscrow(_item.tokenOwner, _toEscrow);
        emit TransferRoyalty(_royaltyReceiver, _royaltyAmount);
    }

    /// @notice Allows a seller to withdraw their sales revenue from the escrow contract.
    /// @param seller The seller of the market item.
    /// @dev Only the seller can check their own escrowed balance.
    function withdrawSellerRevenue(address payable seller) public isAuth(seller) {
        _withdrawFromEscrow(seller);
    }

    /// --------------------------------- ESCROW METHODS ---------------------------------

    /// @notice Get the escrowed balance of a token seller.
    /// @dev Only the seller can check their own escrowed balance.
    /// @param seller The seller of a market item.
    /// @return balance The sellers balance in escrow. 
    function balanceInEscrow(address payable seller)external view returns (uint256 balance) {
        return escrow.depositsOf(seller);
    }

    /// @notice Internal method used to withdraw the salesAmount from the Escrow contract.
    /// @param seller The address of the seller of the MarketOrder.
    /// @dev Will also reset pendingReturn to 0.
    function _withdrawFromEscrow(address payable seller) internal {
        pendingReturns[seller] = 0;
        escrow.withdraw(seller);
        emit WithdrawFromEscrow(seller);
    }

    /// @notice Internal method used to send the nft asset to the new token Owner.
    /// @param itemId The itemId of to transfer.
    /// @param receiver The address to receiver the nft.
    function _sendAsset(bytes32 itemId, address receiver) internal {
        IERC721(itemsMapping[itemId].nftContract).safeTransferFrom(
            itemsMapping[itemId].operator,
            receiver,
            itemsMapping[itemId].tokenId
        );

        emit AssetSent(receiver, itemsMapping[itemId].nftContract, itemsMapping[itemId].tokenId);
    }

    function rescue(address collection, uint256[] calldata tokenIds, address receiver) external onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(collection).safeTransferFrom(address(this), receiver, tokenIds[i]);
        }
    }
        
}

///SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CentBaseStorageBETA.sol";
import "./CentBaseMarketPlaceBETA.sol";

contract CentBaseTimedAuctionBETA is CentBaseStorageBETA {
    uint256 internal _currentAuctionId;
    uint256 internal _currentAuctionsSold;

    receive() external payable {
        revert ErrorMessage("Not payable receive");
    }

    /// @notice Creates a new Auction from a given market item.
    /// @param itemId The Id of the MarketItem to list for auction.
    /// @param biddingTime The timespan in seconds to collect bids for this auction.
    /// @param minimumBid The minimum bid amount for this auction.
    /// @dev Restricted to only owner account.
    /// @dev Restricted by modifiers { isAuthorized, isNotActive }.
    function createMarketAuction(
        bytes32 itemId,
        uint256 biddingTime,
        uint256 minimumBid
    )
        external
        isAuthorized(itemId)
        isNotActive(itemId)
    {
        if (itemId == 0x0 || biddingTime == 0 || minimumBid == 0) {
            revert NoZeroValues();
        }

        bytes32 _auctionId = bytes32(_currentAuctionId += 1);
        bytes32 _itemId = itemId;
        uint256 _auctionEndTime = block.timestamp + biddingTime;
        uint256 _minBid = minimumBid;

        MarketAuction storage _a = auctionsMapping[_auctionId];
        _a.auctionId = _auctionId;
        _a.itemId = _itemId;
        _a.auctionEndTime= _auctionEndTime;
        _a.highestBid = _minBid;
        _a.highestBidder;
        _a.ended = false;

        itemsMapping[_itemId].status = Status(2);
        itemsMapping[_itemId].active = true;

        emit MarketAuctionCreated(
            _auctionId,
            _itemId,
            itemsMapping[_itemId].tokenOwner
        );
    }

    /// @notice Executes a new bid on a auctionId.
    /// @param two Requires a bool false.
    /// @param auctionId The auctionId to bid on.
    /// @dev Restricted by modifiers { costs, isLiveAuction, minBid }.
    function bid(bool two, bytes32 auctionId)
        public
        payable
        costs(two, auctionId)
        isLiveAuction(auctionId)
        minBid(auctionId)
    {
        MarketAuction storage _a = auctionsMapping[auctionId];
        uint256 _bid = msg.value;
        address payable _bidder = payable(_msgSender());

        if (_msgSender() == _a.highestBidder) revert ErrorMessage("Already highest bidder!");
        if (two != false) revert ErrorMessage("Requires uint value: 2");

        if (_a.highestBidder != address(0)) {
            pendingReturns[_a.highestBidder] += _a.highestBid;
            _sendPaymentToEscrow(payable(_a.highestBidder), _a.highestBid);
        }

        _a.highestBid = _bid;
        _a.highestBidder = _bidder;

        emit HighestBidIncrease(_a.auctionId, _a.highestBidder, _a.highestBid);
    }

    /// @notice For users who lost an auction.This will allow them to withdraw their pending returns from the escrow. 
    /// @dev This method will withdraw all the users funds from the escrow contract.
    /// @return success if transaction is completed succewssfully.
    function withdrawPendingReturns() external returns (bool success) {
        if (pendingReturns[_msgSender()] == 0)
            revert ErrorMessage("No pending Returns!");

        uint256 _amount = pendingReturns[_msgSender()];

        if (_amount > 0) {
            pendingReturns[_msgSender()] = 0;

            withdrawSellerRevenue(payable(_msgSender()));
            emit WithdrawPendingReturns(_msgSender(), _amount);
        }
        return true;
    }



    /// @notice Method used to fetch all current live timed auctions on the marketplace.
    /// @return MarketAuction Returns an bytes32 array of all the current active auctions.
    function fetchMarketAuctions()
        external
        view
        returns (MarketAuction[] memory)
    {
        uint256 auctionCount = _currentAuctionId;
        uint256 unsoldAuctionCount = _currentAuctionId - _currentAuctionsSold;
        uint256 currentIndex = 0;

        MarketAuction[] memory _auctions = new MarketAuction[](
            unsoldAuctionCount
        );
        for (uint256 i = 0; i < auctionCount; i++) {
            bytes32 currentId = bytes32(i + 1);
            MarketAuction memory currentAuction = auctionsMapping[currentId];
            _auctions[currentIndex] = currentAuction;
            currentIndex += 1;
        }
        return _auctions;
    }

    /// @notice Public method to finalise an auction.
    /// @param auctionId The auctionId to claim.
    /// @dev The winner of an auction is able to end the auction they won, by claiming the auction,
    ///      the winner will receive their nft and the payment is transfered to the escrow contract. 
    /// @return bool Returns true is auction has a highest bidder, returns false if the auction had no bids. 
    function claimAuction(bytes32 auctionId) public isLiveAuction(auctionId) returns (bool) {
        MarketAuction storage _a = auctionsMapping[auctionId];
        MarketItem storage _item = itemsMapping[_a.itemId];

        if (block.timestamp < _a.auctionEndTime) revert ErrorMessage("To soon!");
        if (_a.ended) revert NotActive(_a.auctionId);

        _a.ended = true;
        _item.status = Status(0);
        _item.active = false;
        
        if (_a.highestBidder == address(0)) {
            _removeAuction(_a.auctionId);
            emit NoBuyer(_a.auctionId, _item.itemId);
            
            return false;
        }
        
        _currentAuctionsSold += 1;

        ( , uint _toSellerAmount, uint _totalFeeAmount) = _calculateFees(_a.highestBid);

        (bool success) = IERC165(_item.nftContract).supportsInterface(_INTERFACE_ID_ERC2981);
        
        if (!success) {
            if (!payable(serviceWallet).send(_totalFeeAmount)) {
                revert FailedTransaction("Fees");
            }

            _sendPaymentToEscrow(_item.tokenOwner, _toSellerAmount);       
            _sendAsset(_item.itemId, _a.highestBidder);

            emit TransferServiceFee(serviceWallet, _totalFeeAmount);
        
        } else {
            _transferRoyaltiesAndServiceFee(_item, _totalFeeAmount, _toSellerAmount);

            _sendAsset(_item.itemId, _a.highestBidder);
        }

        emit AuctionClaimed(_a.auctionId, _a.itemId, _a.highestBidder, _a.highestBid);
        
        _removeAuction(_a.auctionId);
        
        return true;
    }

    /// @notice Method to get an marketAuction.
    /// @param auctionId The bytes32 auctionId to query.
    /// @return marketAuction Returns the MarketAuction.
    function getMarketAuction(bytes32 auctionId)
        external
        view
        onlyRole(ADMIN_ROLE)
        returns (MarketAuction memory marketAuction)
    {
        MarketAuction memory a = auctionsMapping[auctionId];
        return a;
    }

   
    /// @notice Private method to remove a auction from the auctionsMapping.
    /// @param auctionId The auctionId to remove.
    function _removeAuction(bytes32 auctionId) private {
        MarketAuction memory _a = auctionsMapping[auctionId];
        if (_a.ended) {

            emit AuctionRemoved(
                _a.auctionId,
                _a.itemId,
                _a.highestBidder,
                _a.highestBid,
                block.timestamp
            );

            delete (auctionsMapping[auctionId]);
        }
    }
}