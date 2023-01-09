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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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
// ASCII_ART

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../external/delegate-cash/IDelegationRegistry.sol";

contract Dooplication is Ownable, AccessControl {
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    uint256 private constant _DOOPLICATOR_WORDS = 37; // doop bitmap length

    // Map (tokenContract => (tokenOwner => (tokenId => operatorAddress)).
    // Operator can dooplicate tokenId in tokenContract.
    mapping(address =>
        mapping(address =>
            mapping(uint256 => address))) private _tokenApprovals;

    // Map (tokenContract => approved). Approved contracts for dooplication.
    mapping(address => bool) private _approvedContracts;

    // Map (tokenContract => bitmap). Track dooplicated tokens in each contract.
    mapping(address => uint256[]) private _bitmaps;

    // Map (tokenContract => bitmap). Track dooplicator usage per contract.
    mapping(address => uint256[_DOOPLICATOR_WORDS]) private _bitmapDooplicators; // 9_375 doops

    // Map (tokenContract => active). Track dooplicationActive per contract
    mapping(address => bool) public dooplicationActive;

    address public constant DELEGATION_REGISTRY =
        0x00000000000076A84feF008CDAbe6409d2FE638B;
    IERC721 public immutable dooplicatorContract;

    /**************************************************************************
     * Events
     */

    event Dooplicate(
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 indexed dooplicatorId,
        address operator,
        bytes8 addressOnTheOtherSide
    );

    event ApproveForDooplication(
        address indexed ownerOrApproved,
        address indexed tokenContract,
        address approvedOperator,
        uint256 tokenId
    );

    event RevokeApprovalForDooplication(
        address indexed ownerOrApproved,
        address indexed tokenContract,
        uint256 tokenId
    );

    /**************************************************************************
     * Errors
     */

    error ContractNotApprovedForDooplication();
    error InvalidInputAddress();
    error InvalidInputNotERC721Address();
    error InvalidInputZeroTotalSupply();
    error DooplicationNotActive();
    error DooplicatorHasBeenUsed();
    error TokenHasBeenDooplicated();
    error TokenOutOfRange();
    error TokenNotInVault();
    error UserIsNotDelegateForThisDooplicator();
    error UserIsNotDelegateForThisToken();
    error NotApprovedOrOwnerOfToken();
    error NotApprovedToDooplicateThisToken();
    error NoTokenRecordsForThisContract();
    error NotOwnerOfDooplicator();

    /**************************************************************************
     * Modifiers
     */

    modifier contractIsApproved(address tokenContract) {
        if (!_approvedContracts[tokenContract]) {
            revert ContractNotApprovedForDooplication();
        }
        _;
    }

    /**************************************************************************
     * Constructor
     */

    /**
     * @param dooplicatorContract_ address for the dooplicator token contract
     */
    constructor(address dooplicatorContract_) {
        bytes4 erc721InterfaceId = type(IERC721).interfaceId;

        try
            IERC721(dooplicatorContract_).supportsInterface(erc721InterfaceId)
        returns (bool result) {
            if (!result) revert InvalidInputNotERC721Address();
        } catch {
            revert InvalidInputAddress();
        }

        dooplicatorContract = IERC721(dooplicatorContract_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    /**************************************************************************
     * Functions - external
     */

    /**
     * @notice We doo a little dooplication
     *  Use a dooplicator to dooplicate a token you own or are approved on.
     *  You can be approved by a token owner to dooplicate their token, see
     *  approveForDooplication().
     *
     * @param dooplicatorId a dooplicator you own
     * @param tokenId a token you own, or have been approved to dooplicate
     * @param tokenContract the contract address of the token to dooplicate
     * @param addressOnTheOtherSide an address you control, on the other side...
     */
    function dooplicate(
        uint256 dooplicatorId,
        uint256 tokenId,
        address tokenContract,
        bytes8 addressOnTheOtherSide
    ) external {
        if (dooplicatorContract.ownerOf(dooplicatorId) != msg.sender) {
            revert NotOwnerOfDooplicator();
        }
        if (!isApprovedForDooplication(msg.sender, tokenId, tokenContract)) {
            revert NotApprovedToDooplicateThisToken();
        }

        _dooplicate(
            msg.sender,
            dooplicatorId,
            tokenId,
            tokenContract,
            addressOnTheOtherSide
        );
    }

    /**
     * @notice We doo a little delegated dooplication.
     *  Use a dooplicator to dooplicate a token.
     *  You must own or be delegated to act for both dooplicator and token.
     *  If delegate for both, they must both be in the same vault.
     *
     *  Delegation is via delegate.cash, see https://delegate.cash/
     *
     * @param vault address where the token and/or dooplicator are held
     * @param dooplicatorId a dooplicator you own, in wallet or vault
     * @param tokenId a token you own, in the vault
     * @param tokenContract the contract address of the token to dooplicate
     * @param addressOnTheOtherSide an address you control, on the other side...
     */
    function dooplicateAsDelegate(
        address vault,
        uint256 dooplicatorId,
        uint256 tokenId,
        address tokenContract,
        bytes8 addressOnTheOtherSide
    ) external {
        IDelegationRegistry dr = IDelegationRegistry(DELEGATION_REGISTRY);

        // prove ownership or delegate of both token and dooplicator
        address dooplicatorOwner = dooplicatorContract.ownerOf(dooplicatorId);
        address tokenOwner = _getTrustedOwner(tokenId, tokenContract);

        // check user is owner or delegate for dooplicator
        if (dooplicatorOwner != msg.sender) {
            if (
                dooplicatorOwner != vault ||
                !dr.checkDelegateForToken(
                    msg.sender,
                    vault,
                    address(dooplicatorContract),
                    dooplicatorId
                )
            ) {
                revert UserIsNotDelegateForThisDooplicator();
            }
        }

        // check user is owner or delegate for tokenId
        if (tokenOwner != msg.sender) {
            if (
                tokenOwner != vault ||
                !dr.checkDelegateForToken(
                    msg.sender,
                    vault,
                    tokenContract,
                    tokenId
                )
            ) {
                revert UserIsNotDelegateForThisToken();
            }
        }

        _dooplicate(
            msg.sender,
            dooplicatorId,
            tokenId,
            tokenContract,
            addressOnTheOtherSide
        );
    }

    /**
     * @notice approve another address to dooplicate your token. A token can
     *  only be dooplicated once!
     * @param approvedOperator the address to approve
     * @param tokenId the token to approve
     * @param tokenContract the contract address of the token to approve
     */
    function approveForDooplication(
        address approvedOperator,
        uint256 tokenId,
        address tokenContract
    ) external {
        (bool approved, address tokenOwner) = _isApprovedOrOwnerOfToken(
            msg.sender,
            tokenId,
            tokenContract
        );

        if (!approved) revert NotApprovedOrOwnerOfToken();

        _tokenApprovals[tokenContract][tokenOwner][tokenId] = approvedOperator;
        emit ApproveForDooplication(
            msg.sender,
            tokenContract,
            approvedOperator,
            tokenId
        );
    }

    /**
     * @notice revoke approval for another address to dooplicate your token
     * @param tokenId the token to revoke approvals on
     * @param tokenContract the contract address of the token
     */
    function revokeApprovalForDooplication(
        uint256 tokenId,
        address tokenContract
    ) external {
        (bool approved, address tokenOwner) = _isApprovedOrOwnerOfToken(
            msg.sender,
            tokenId,
            tokenContract
        );

        if (!approved) revert NotApprovedOrOwnerOfToken();

        delete _tokenApprovals[tokenContract][tokenOwner][tokenId];
        emit RevokeApprovalForDooplication(msg.sender, tokenContract, tokenId);
    }

    /**************************************************************************
     * Functions - external - access & info
     */

    /**
     * @notice check if a specific user can dooplicate a specific token using a
     *  specific dooplicator
     * @param userAddress the Ethereum wallet address of the user
     * @param dooplicatorId the dooplicator id to check
     * @param tokenId the tokenId to check
     * @param tokenContract the contract address of the token to check
     * @return canDooplicate true if the user can dooplicate, false otherwise
     */
    function canDooplicate(
        address userAddress,
        uint256 dooplicatorId,
        uint256 tokenId,
        address tokenContract
    ) external view returns (bool) {
        if (
            !dooplicationActive[tokenContract] ||
            dooplicatorContract.ownerOf(dooplicatorId) != userAddress ||
            !isApprovedForDooplication(userAddress, tokenId, tokenContract) ||
            dooplicatorUsed(dooplicatorId, tokenContract) ||
            tokenDooplicated(tokenId, tokenContract)
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice check if a contract address has been approved for its tokens
     *  to be dooplicated
     * @param tokenContract the contract address to check
     * @return approved true if approved, false otherwise
     */
    function contractApproved(address tokenContract)
        external
        view
        returns (bool)
    {
        return _approvedContracts[tokenContract];
    }

    /**
     * @notice get the address approved to dooplicate a token, or return the
     *  zero address if none are approved
     * @param tokenId the token to check
     * @param tokenContract contract address for the token to check
     * @return operator the address with approval to dooplicate tokenId
     */
    function getDooplicationOperator(uint256 tokenId, address tokenContract)
        external
        view
        returns (address)
    {
        address tokenOwner = _getTrustedOwner(tokenId, tokenContract);
        return _tokenApprovals[tokenContract][tokenOwner][tokenId];
    }

    /**
     * @notice check if a dooplicator has been used to dooplicate tokens from a
     *  specific token contract
     * @param dooplicatorId the dooplicator to check
     * @param tokenContract the contract to check against
     * @return used true if used, false otherwise
     */
    function dooplicatorUsed(uint256 dooplicatorId, address tokenContract)
        public
        view
        returns (bool)
    {
        uint256[_DOOPLICATOR_WORDS] storage bitmap = _bitmapDooplicators[
            tokenContract
        ];

        (uint256 wordIndex, uint256 bitIndex) = _wordAndBit(dooplicatorId);
        if (wordIndex >= _DOOPLICATOR_WORDS) revert TokenOutOfRange();

        uint256 word = bitmap[wordIndex];
        uint256 mask = 1 << bitIndex;

        return (word & mask) == mask;
    }

    /**
     * @notice check if an operator is approved to dooplicate a token
     * @param operator the operator address to check
     * @param tokenId the token to check
     * @param tokenContract the contract address of the token to check
     * @return approved true if approved, false otherwise
     */
    function isApprovedForDooplication(
        address operator,
        uint256 tokenId,
        address tokenContract
    ) public view returns (bool) {
        address tokenOwner = _getTrustedOwner(tokenId, tokenContract);

        return (tokenOwner == operator ||
            _tokenApprovals[tokenContract][tokenOwner][tokenId] == operator);
    }

    /**
     * @notice check if a token has been dooplicated
     * @param tokenId the token to check
     * @param tokenContract the contract address of the token to check
     * @return dooplicated true if dooplicated, false otherwise
     */
    function tokenDooplicated(uint256 tokenId, address tokenContract)
        public
        view
        returns (bool)
    {
        uint256[] storage bitmap = _bitmaps[tokenContract];
        uint256 bitmapLength = bitmap.length;
        if (bitmapLength == 0) revert NoTokenRecordsForThisContract();

        (uint256 wordIndex, uint256 bitIndex) = _wordAndBit(tokenId);
        if (wordIndex >= bitmapLength) revert TokenOutOfRange();

        uint256 word = bitmap[wordIndex];
        uint256 mask = 1 << bitIndex;

        return (word & mask) == mask;
    }

    /**************************************************************************
     * Functions - owner/dev
     */

    /**
     * @dev start and stop dooplication
     * @param active true to start dooplication, false to stop
     * @param tokenContract the contract to modify
     */
    function setDooplicationActive(bool active, address tokenContract)
        external
        onlyRole(SUPPORT_ROLE)
    {
        dooplicationActive[tokenContract] = active;
    }

    /**
     * @dev approve a new contract of ERC721 tokens that can be dooplicated.
     *  Calling again with the same contract address will overwrite the
     *  previous approval and clear records of dooplicated tokens.
     * @param approvedContract the ERC721 contract to approve
     * @param highestTokenId the highest tokenId in the approvedContract
     */
    function addApprovedContract(
        address approvedContract,
        uint256 highestTokenId
    ) external onlyRole(SUPPORT_ROLE) {
        bytes4 erc721InterfaceId = type(IERC721).interfaceId;

        try
            IERC721(approvedContract).supportsInterface(erc721InterfaceId)
        returns (bool result) {
            if (!result) revert InvalidInputNotERC721Address();
        } catch {
            revert InvalidInputAddress();
        }

        // compute required bitmap length (tokenIds start at 0)
        uint256 requiredBits = highestTokenId + 1;
        uint256 size = Math.ceilDiv(requiredBits, 256);
        uint256[] memory newBitmap = new uint256[](size);

        // add bitmap and approve address
        _bitmaps[approvedContract] = newBitmap;
        _approvedContracts[approvedContract] = true;
    }

    /**
     * @dev revoke approval for a contract's tokens to be dooplicated.
     *  The record of dooplicated items in the contract will also be reset.
     * @param contractToRevoke revoke approval for this contract address
     */
    function revokeContractApproval(address contractToRevoke)
        external
        contractIsApproved(contractToRevoke)
        onlyRole(SUPPORT_ROLE)
    {
        delete _approvedContracts[contractToRevoke];
        delete _bitmaps[contractToRevoke];
        delete _bitmapDooplicators[contractToRevoke];
    }

    /**************************************************************************
     * Functions - internal
     */

    /**
     * @dev Use a dooplicator to dooplicate a token from an approved contract
     * @param sender address that performed the dooplication
     * @param dooplicatorId dooplicator to use
     * @param tokenId token to dooplicated
     * @param tokenContract the contract address of the token to dooplicate
     * @param addressOnTheOtherSide beneficiary address on the other side
     */
    function _dooplicate(
        address sender,
        uint256 dooplicatorId,
        uint256 tokenId,
        address tokenContract,
        bytes8 addressOnTheOtherSide
    ) internal {
        if (!dooplicationActive[tokenContract]) revert DooplicationNotActive();

        if (dooplicatorUsed(dooplicatorId, tokenContract)) {
            revert DooplicatorHasBeenUsed();
        }
        if (tokenDooplicated(tokenId, tokenContract)) {
            revert TokenHasBeenDooplicated();
        }

        // effects
        _setDooplicatorUsed(dooplicatorId, tokenContract);
        _setTokenDooplicated(tokenId, tokenContract);

        emit Dooplicate(
            tokenId,
            tokenContract,
            dooplicatorId,
            sender,
            addressOnTheOtherSide
        );
    }

    /**
     * @dev check if an address is an approved operator or owner of tokenId,
     *  as defined in ERC721, also returning the owner address
     * @param operator the address to check
     * @param tokenId the token to check
     * @param tokenContract the contract address of the token
     * @return (approved, tokenOwner): approved true if operator is approved,
     *  false otherwise. tokenOwner is the checked owner of tokenId.
     */
    function _isApprovedOrOwnerOfToken(
        address operator,
        uint256 tokenId,
        address tokenContract
    )
        internal
        view
        contractIsApproved(tokenContract)
        returns (bool, address)
    {
        // assume tokenContract can be trusted after approval check modifier
        IERC721 contract_ = IERC721(tokenContract);
        address tokenOwner = contract_.ownerOf(tokenId);

        bool approved = (tokenOwner == operator ||
            contract_.isApprovedForAll(tokenOwner, operator) ||
            contract_.getApproved(tokenId) == operator);

        return (approved, tokenOwner);
    }

    /**
     * @dev mark a dooplicator as used on a specific contract
     * @param dooplicatorId the dooplicator to mark
     * @param tokenContract the contract whose token has been dooplicated
     */
    function _setDooplicatorUsed(uint256 dooplicatorId, address tokenContract)
        internal
    {
        uint256[_DOOPLICATOR_WORDS] storage bitmap = _bitmapDooplicators[
            tokenContract
        ];

        (uint256 wordIndex, uint256 bitIndex) = _wordAndBit(dooplicatorId);
        uint256 word = bitmap[wordIndex];
        uint256 mask = 1 << bitIndex;

        bitmap[wordIndex] = word | mask;
    }

    /**
     * @dev mark a token as dooplicated
     * @param tokenId the token to mark
     * @param tokenContract the contract whose token has been dooplicated
     */
    function _setTokenDooplicated(uint256 tokenId, address tokenContract)
        internal
    {
        uint256[] storage bitmap = _bitmaps[tokenContract];

        (uint256 wordIndex, uint256 bitIndex) = _wordAndBit(tokenId);
        uint256 word = bitmap[wordIndex];
        uint256 mask = 1 << bitIndex;

        bitmap[wordIndex] = word | mask;
    }

    /**
     * @dev check if a tokenContract is trusted, before calling to retrieve a
     *  token owner. We assume tokenContract is trusted because it must be
     *  approved by SUPPORT_ROLE.
     */
    function _getTrustedOwner(uint256 tokenId, address tokenContract)
        internal
        view
        contractIsApproved(tokenContract)
        returns (address)
    {
        // assume tokenContract can be trusted after approval check modifier
        IERC721 contract_ = IERC721(tokenContract);
        address tokenOwner = contract_.ownerOf(tokenId);
        return tokenOwner;
    }

    /**
     * @dev helper for indexing into bitmaps
     */
    function _wordAndBit(uint256 index)
        private
        pure
        returns (uint256, uint256)
    {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;

        return (wordIndex, bitIndex);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}