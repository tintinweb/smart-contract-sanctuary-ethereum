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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import { IDegenNFT } from "./IDegenNft.sol";

interface IDegenDistributorEvents {
    /// @dev Emits when a user claims tokens
    event Claimed(
        address indexed account,
        uint256 amount
    );

    /// @dev Emits when the owner replaces the merkle root
    event RootUpdated(bytes32 oldRoot, bytes32 indexed newRoot);
}

interface IDegenDistributor is IDegenDistributorEvents {
    // Returns the address of the token distributed by this contract.
    function degenNFT() external view returns (IDegenNFT);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    /// @dev Returns the total amount of token claimed by the user
    function claimed(address user) external view returns (uint256);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    /// @dev Claims the remaining unclaimed amount of the token for the account. Reverts if the inputs are not a leaf in the tree
    ///      or the total claimed amount for the account is more than the leaf amount.
    function claim(
        uint256 index,
        address account,
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.9;
import { IVersion } from "./external/gearbox/helpers/IVersion.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IDegenNFTExceptions {
    /// @dev Thrown if an access-restricted function was called by non-CreditFacade
    error CreditFacadeOrConfiguratorOnlyException();

    /// @dev Thrown if an access-restricted function was called by non-minter
    error MinterOnlyException();

    /// @dev Thrown if trying to add a burner address that is not a correct Credit Facade
    error InvalidCreditFacadeException();

    /// @dev Thrown if the account's balance is not sufficient for an action (usually a burn)
    error InsufficientBalanceException();
}

interface IDegenNFTEvents {
    /// @dev Minted when new minter set
    event NewMinterSet(address indexed);

    /// @dev Minted each time when new credit facade added
    event NewCreditFacadeAdded(address indexed);

    /// @dev Minted each time when new credit facade added
    event NewCreditFacadeRemoved(address indexed);
}

interface IDegenNFT is
    IDegenNFTExceptions,
    IDegenNFTEvents,
    IVersion,
    IERC721Metadata
{
    /// @dev address of the current minter
    function minter() external view returns (address);

    /// @dev Stores the total number of tokens on holder accounts
    function totalSupply() external view returns (uint256);

    /// @dev Stores the base URI for NFT metadata
    function baseURI() external view returns (string memory);

    /// @dev Mints a specified amount of tokens to the address
    /// @param to Address the tokens are minted to
    /// @param amount The number of tokens to mint
    function mint(address to, uint256 amount) external;

    /// @dev Burns a number of tokens from a specified address
    /// @param from The address a token will be burnt from
    /// @param amount The number of tokens to burn
    function burn(address from, uint256 amount) external;

    function setMinter(address minter_)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./utils/IDefaultAccessControl.sol";
import "./IUnitPricesGovernance.sol";

interface IProtocolGovernance is IDefaultAccessControl, IUnitPricesGovernance {
    /// @notice CommonLibrary protocol params.
    /// @param maxTokensPerVault Max different token addresses that could be managed by the vault
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param protocolTreasury The address that collects protocolFees, if protocolFee is not zero
    /// @param forceAllowMask If a permission bit is set in this mask it forces all addresses to have this permission as true
    /// @param withdrawLimit Withdraw limit (in unit prices, i.e. usd)
    struct Params {
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
        uint256 forceAllowMask;
        uint256 withdrawLimit;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedPermissionGrantsTimestamps(address target) external view returns (uint256);

    /// @notice Staged granted permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function stagedPermissionGrantsMasks(address target) external view returns (uint256);

    /// @notice Permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function permissionMasks(address target) external view returns (uint256);

    /// @notice Timestamp after which staged pending protocol parameters can be committed
    /// @return Zero if there are no staged parameters, timestamp otherwise.
    function stagedParamsTimestamp() external view returns (uint256);

    /// @notice Staged pending protocol parameters.
    function stagedParams() external view returns (Params memory);

    /// @notice Current protocol parameters.
    function params() external view returns (Params memory);

    /// @notice Addresses for which non-zero permissions are set.
    function permissionAddresses() external view returns (address[] memory);

    /// @notice Permission addresses staged for commit.
    function stagedPermissionGrantsAddresses() external view returns (address[] memory);

    /// @notice Return all addresses where rawPermissionMask bit for permissionId is set to 1.
    /// @param permissionId Id of the permission to check.
    /// @return A list of dirty addresses.
    function addressesByPermission(uint8 permissionId) external view returns (address[] memory);

    /// @notice Checks if address has permission or given permission is force allowed for any address.
    /// @param addr Address to check
    /// @param permissionId Permission to check
    function hasPermission(address addr, uint8 permissionId) external view returns (bool);

    /// @notice Checks if address has all permissions.
    /// @param target Address to check
    /// @param permissionIds A list of permissions to check
    function hasAllPermissions(address target, uint8[] calldata permissionIds) external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    /// @notice Permissions mask which defines if ordinary permission should be reverted.
    /// This bitmask is xored with ordinary mask.
    function forceAllowMask() external view returns (uint256);

    /// @notice Withdraw limit per token per block.
    /// @param token Address of the token
    /// @return Withdraw limit per token per block
    function withdrawLimit(address token) external view returns (uint256);

    /// @notice Addresses that has staged validators.
    function stagedValidatorsAddresses() external view returns (address[] memory);

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedValidatorsTimestamps(address target) external view returns (uint256);

    /// @notice Staged validator for the given address.
    /// @param target The given address
    /// @return Validator
    function stagedValidators(address target) external view returns (address);

    /// @notice Addresses that has validators.
    function validatorsAddresses() external view returns (address[] memory);

    /// @notice Address that has validators.
    /// @param i The number of address
    /// @return Validator address
    function validatorsAddress(uint256 i) external view returns (address);

    /// @notice Validator for the given address.
    /// @param target The given address
    /// @return Validator
    function validators(address target) external view returns (address);

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Rollback all staged validators.
    function rollbackStagedValidators() external;

    /// @notice Revoke validator instantly from the given address.
    /// @param target The given address
    function revokeValidator(address target) external;

    /// @notice Stages a new validator for the given address
    /// @param target The given address
    /// @param validator The validator for the given address
    function stageValidator(address target, address validator) external;

    /// @notice Commits validator for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitValidator(address target) external;

    /// @notice Commites all staged validators for which governance delay passed
    /// @return Addresses for which validators were committed
    function commitAllValidatorsSurpassedDelay() external returns (address[] memory);

    /// @notice Rollback all staged granted permission grant.
    function rollbackStagedPermissionGrants() external;

    /// @notice Commits permission grants for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitPermissionGrants(address target) external;

    /// @notice Commites all staged permission grants for which governance delay passed.
    /// @return An array of addresses for which permission grants were committed.
    function commitAllPermissionGrantsSurpassedDelay() external returns (address[] memory);

    /// @notice Revoke permission instantly from the given address.
    /// @param target The given address.
    /// @param permissionIds A list of permission ids to revoke.
    function revokePermissions(address target, uint8[] memory permissionIds) external;

    /// @notice Commits staged protocol params.
    /// Reverts if governance delay has not passed yet.
    function commitParams() external;

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Sets new pending params that could have been committed after governance delay expires.
    /// @param newParams New protocol parameters to set.
    function stageParams(Params memory newParams) external;

    /// @notice Stage granted permissions that could have been committed after governance delay expires.
    /// Resets commit delay and permissions if there are already staged permissions for this address.
    /// @param target Target address
    /// @param permissionIds A list of permission ids to grant
    function stagePermissionGrants(address target, uint8[] memory permissionIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./utils/IDefaultAccessControl.sol";

interface IUnitPricesGovernance is IDefaultAccessControl, IERC165 {
    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @return The amount of token
    function stagedUnitPrices(address token) external view returns (uint256);

    /// @notice Timestamp after which staged unit prices for the given token can be committed.
    /// @param token Address of the token
    /// @return Timestamp
    function stagedUnitPricesTimestamps(address token) external view returns (uint256);

    /// @notice Estimated amount of token worth 1 USD.
    /// @param token Address of the token
    /// @return The amount of token
    function unitPrices(address token) external view returns (uint256);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @param value The amount of token
    function stageUnitPrice(address token, uint256 value) external;

    /// @notice Reset staged value
    /// @param token Address of the token
    function rollbackUnitPrice(address token) external;

    /// @notice Commit staged unit price
    /// @param token Address of the token
    function commitUnitPrice(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";

interface IVaultRegistry is IERC721 {
    /// @notice Get Vault for the giver NFT ID.
    /// @param nftId NFT ID
    /// @return vault Address of the Vault contract
    function vaultForNft(uint256 nftId) external view returns (address vault);

    /// @notice Get NFT ID for given Vault contract address.
    /// @param vault Address of the Vault contract
    /// @return nftId NFT ID
    function nftForVault(address vault) external view returns (uint256 nftId);

    /// @notice Checks if the nft is locked for all transfers
    /// @param nft NFT to check for lock
    /// @return `true` if locked, false otherwise
    function isLocked(uint256 nft) external view returns (bool);

    /// @notice Register new Vault and mint NFT.
    /// @param vault address of the vault
    /// @param owner owner of the NFT
    /// @return nft Nft minted for the given Vault
    function registerVault(address vault, address owner) external returns (uint256 nft);

    /// @notice Number of Vaults registered.
    function vaultsCount() external view returns (uint256);

    /// @notice All Vaults registered.
    function vaults() external view returns (address[] memory);

    /// @notice Address of the ProtocolGovernance.
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Address of the staged ProtocolGovernance.
    function stagedProtocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Minimal timestamp when staged ProtocolGovernance can be applied.
    function stagedProtocolGovernanceTimestamp() external view returns (uint256);

    /// @notice Stage new ProtocolGovernance.
    /// @param newProtocolGovernance new ProtocolGovernance
    function stageProtocolGovernance(IProtocolGovernance newProtocolGovernance) external;

    /// @notice Commit new ProtocolGovernance.
    function commitStagedProtocolGovernance() external;

    /// @notice Lock NFT for transfers
    /// @dev Use this method when vault structure is set up and should become immutable. Can be called by owner.
    /// @param nft - NFT to lock
    function lockNft(uint256 nft) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IConvexToken {
    function totalSupply() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function totalCliffs() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICurveGauge {
  function deposit(uint256) external;

  function balanceOf(address) external view returns (uint256);

  function withdraw(uint256) external;

  function claim_rewards() external;

  function reward_tokens(uint256) external view returns (address); //v2

  function rewarded_token() external view returns (address); //v1

  function lp_token() external view returns (address);
}

interface ICurveVoteEscrow {
  function create_lock(uint256, uint256) external;

  function increase_amount(uint256) external;

  function increase_unlock_time(uint256) external;

  function withdraw() external;

  function smart_wallet_checker() external view returns (address);
}

interface IWalletChecker {
  function check(address) external view returns (bool);
}

interface IVoting {
  function vote(
    uint256,
    bool,
    bool
  ) external; //voteId, support, executeIfDecided

  function getVote(uint256)
    external
    view
    returns (
      bool,
      bool,
      uint64,
      uint64,
      uint64,
      uint64,
      uint256,
      uint256,
      uint256,
      bytes memory
    );

  function vote_for_gauge_weights(address, uint256) external;
}

interface IMinter {
  function mint(address) external;
}

interface IRegistry {
  function get_registry() external view returns (address);

  function get_address(uint256 _id) external view returns (address);

  function gauge_controller() external view returns (address);

  function get_lp_token(address) external view returns (address);

  function get_gauges(address)
    external
    view
    returns (address[10] memory, uint128[10] memory);
}

interface IStaker {
  function deposit(address, address) external;

  function withdraw(address) external;

  function withdraw(
    address,
    address,
    uint256
  ) external;

  function withdrawAll(address, address) external;

  function createLock(uint256, uint256) external;

  function increaseAmount(uint256) external;

  function increaseTime(uint256) external;

  function release() external;

  function claimCrv(address) external returns (uint256);

  function claimRewards(address) external;

  function claimFees(address, address) external;

  function setStashAccess(address, bool) external;

  function vote(
    uint256,
    address,
    bool
  ) external;

  function voteGaugeWeight(address, uint256) external;

  function balanceOfPool(address) external view returns (uint256);

  function operator() external view returns (address);

  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external returns (bool, bytes memory);
}

interface IRewards {
  function stake(address, uint256) external;

  function stakeFor(address, uint256) external;

  function withdraw(address, uint256) external;

  function exit(address) external;

  function getReward(address) external;

  function queueNewRewards(uint256) external;

  function notifyRewardAmount(uint256) external;

  function addExtraReward(address) external;

  function stakingToken() external view returns (address);

  function rewardToken() external view returns (address);

  function earned(address account) external view returns (uint256);
}

interface IStash {
  function stashRewards() external returns (bool);

  function processStash() external returns (bool);

  function claimRewards() external returns (bool);

  function initialize(
    uint256 _pid,
    address _operator,
    address _staker,
    address _gauge,
    address _rewardFactory
  ) external;
}

interface IFeeDistro {
  function claim() external;

  function token() external view returns (address);
}

interface ITokenMinter {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

interface IDeposit {
  function isShutdown() external view returns (bool);

  function balanceOf(address _account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function poolInfo(uint256)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      address,
      bool
    );

  function rewardClaimed(
    uint256,
    address,
    uint256
  ) external;

  function withdrawTo(
    uint256,
    uint256,
    address
  ) external;

  function claimRewards(uint256, address) external returns (bool);

  function rewardArbitrator() external returns (address);

  function setGaugeRedirect(uint256 _pid) external returns (bool);

  function owner() external returns (address);
}

interface ICrvDeposit {
  function deposit(uint256, bool) external;

  function lockIncentive() external view returns (uint256);
}

interface IRewardFactory {
  function setAccess(address, bool) external;

  function CreateCrvRewards(uint256, address) external returns (address);

  function CreateTokenRewards(
    address,
    address,
    address
  ) external returns (address);

  function activeRewardCount(address) external view returns (uint256);

  function addActiveReward(address, uint256) external returns (bool);

  function removeActiveReward(address, uint256) external returns (bool);
}

interface IStashFactory {
  function CreateStash(
    uint256,
    address,
    address,
    uint256
  ) external returns (address);
}

interface ITokenFactory {
  function CreateDepositToken(address) external returns (address);
}

interface IPools {
  function addPool(
    address _lptoken,
    address _gauge,
    uint256 _stashVersion
  ) external returns (bool);

  function forceAddPool(
    address _lptoken,
    address _gauge,
    uint256 _stashVersion
  ) external returns (bool);

  function shutdownPool(uint256 _pid) external returns (bool);

  function poolInfo(uint256)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      address,
      bool
    );

  function poolLength() external view returns (uint256);

  function gaugeMap(address) external view returns (bool);

  function setPoolManager(address _poolM) external;
}

interface IVestedEscrow {
  function fund(address[] calldata _recipient, uint256[] calldata _amount)
    external
    returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC1271 {
    /// @notice Verifies offchain signature.
    /// @dev Should return whether the signature provided is valid for the provided hash
    ///
    /// MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    ///
    /// MUST allow external calls
    /// @param _hash Hash of the data to be signed
    /// @param _signature Signature byte array associated with _hash
    /// @return magicValue 0x1626ba7e if valid, 0xffffffff otherwise
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;

import { IAdapter } from "./helpers/IAdapter.sol";
import { IBaseRewardPool } from "./helpers/convex/IBaseRewardPool.sol";

interface IConvexV1BaseRewardPoolAdapterErrors {
    /// @dev Thrown when the adapter attempts to use a token not
    ///      allowed in its corresponding Credit Manager
    error TokenIsNotAddedToCreditManagerException(address token);
}

interface IConvexV1BaseRewardPoolAdapter is
    IAdapter,
    IBaseRewardPool,
    IConvexV1BaseRewardPoolAdapterErrors
{
    /// @dev Returns the address of a Curve pool LP token
    ///      staked in the adapter's targer Convex pool
    function curveLPtoken() external view returns (address);

    /// @dev Returns the address of a phantom token tracking
    ///      a Credit Account's staked balance in a Convex
    ///      pool
    function stakedPhantomToken() external view returns (address);

    /// @dev Returns the address of the first extra reward token
    /// @notice address(0) if the Convex pool has no extra reward tokens
    function extraReward1() external view returns (address);

    /// @dev Returns the address of the second extra reward token
    /// @notice address(0) if the Convex pool has less than 2 extra reward tokens
    function extraReward2() external view returns (address);

    /// @dev Returns the address of CVX
    function cvx() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;

import { IVersion } from "./helpers/IVersion.sol";
import { ICreditManagerV2, ICreditManagerV2Exceptions } from "./helpers/ICreditManagerV2.sol";
import { Balance } from "./helpers/libraries/Balances.sol";
import { MultiCall } from "./helpers/libraries/MultiCall.sol";

interface ICreditFacadeExtended {
    /// @dev Stores expected balances (computed as current balance + passed delta)
    ///      and compare with actual balances at the end of a multicall, reverts
    ///      if at least one is less than expected
    /// @param expected Array of expected balance changes
    /// @notice This is an extenstion function that does not exist in the Credit Facade
    ///         itself and can only be used within a multicall
    function revertIfReceivedLessThan(Balance[] memory expected) external;

    /// @dev Disables a token on the caller's Credit Account
    /// @param token Token to disable
    /// @notice This is an extenstion function that does not exist in the Credit Facade
    ///         itself and can only be used within a multicall
    function disableToken(address token) external;
}

interface ICreditFacadeEvents {
    /// @dev Emits when a new Credit Account is opened through the
    ///      Credit Facade
    event OpenCreditAccount(
        address indexed onBehalfOf,
        address indexed creditAccount,
        uint256 borrowAmount,
        uint16 referralCode
    );

    /// @dev Emits when the account owner closes their CA normally
    event CloseCreditAccount(address indexed owner, address indexed to);

    /// @dev Emits when a Credit Account is liquidated due to low health factor
    event LiquidateCreditAccount(
        address indexed owner,
        address indexed liquidator,
        address indexed to,
        uint256 remainingFunds
    );

    /// @dev Emits when a Credit Account is liquidated due to expiry
    event LiquidateExpiredCreditAccount(
        address indexed owner,
        address indexed liquidator,
        address indexed to,
        uint256 remainingFunds
    );

    /// @dev Emits when the account owner increases CA's debt
    event IncreaseBorrowedAmount(address indexed borrower, uint256 amount);

    /// @dev Emits when the account owner reduces CA's debt
    event DecreaseBorrowedAmount(address indexed borrower, uint256 amount);

    /// @dev Emits when the account owner add new collateral to a CA
    event AddCollateral(
        address indexed onBehalfOf,
        address indexed token,
        uint256 value
    );

    /// @dev Emits when a multicall is started
    event MultiCallStarted(address indexed borrower);

    /// @dev Emits when a multicall is finished
    event MultiCallFinished();

    /// @dev Emits when Credit Account ownership is transferred
    event TransferAccount(address indexed oldOwner, address indexed newOwner);

    /// @dev Emits when the user changes approval for account transfers to itself from another address
    event TransferAccountAllowed(
        address indexed from,
        address indexed to,
        bool state
    );

    /// @dev Emits when the account owner enables a token on their CA
    event TokenEnabled(address creditAccount, address token);

    /// @dev Emits when the account owner disables a token on their CA
    event TokenDisabled(address creditAccount, address token);
}

interface ICreditFacadeExceptions is ICreditManagerV2Exceptions {
    /// @dev Thrown if the CreditFacade is not expirable, and an aciton is attempted that
    ///      requires expirability
    error NotAllowedWhenNotExpirableException();

    /// @dev Thrown if whitelisted mode is enabled, and an action is attempted that is
    ///      not allowed in whitelisted mode
    error NotAllowedInWhitelistedMode();

    /// @dev Thrown if a user attempts to transfer a CA to an address that didn't allow it
    error AccountTransferNotAllowedException();

    /// @dev Thrown if a liquidator tries to liquidate an account with a health factor above 1
    error CantLiquidateWithSuchHealthFactorException();

    /// @dev Thrown if a liquidator tries to liquidate an account by expiry while a Credit Facade is not expired
    error CantLiquidateNonExpiredException();

    /// @dev Thrown if call data passed to a multicall is too short
    error IncorrectCallDataException();

    /// @dev Thrown inside account closure multicall if the borrower attempts an action that is forbidden on closing
    ///      an account
    error ForbiddenDuringClosureException();

    /// @dev Thrown if debt increase and decrease are subsequently attempted in one multicall
    error IncreaseAndDecreaseForbiddenInOneCallException();

    /// @dev Thrown if a selector that doesn't match any allowed function is passed to the Credit Facade
    ///      during a multicall
    error UnknownMethodException();

    /// @dev Thrown if a user tries to open an account or increase debt with increaseDebtForbidden mode on
    error IncreaseDebtForbiddenException();

    /// @dev Thrown if the account owner tries to transfer an unhealthy account
    error CantTransferLiquidatableAccountException();

    /// @dev Thrown if too much new debt was taken within a single block
    error BorrowedBlockLimitException();

    /// @dev Thrown if the new debt principal for a CA falls outside of borrowing limits
    error BorrowAmountOutOfLimitsException();

    /// @dev Thrown if one of the balances on a Credit Account is less than expected
    ///      at the end of a multicall, if revertIfReceivedLessThan was called
    error BalanceLessThanMinimumDesiredException(address);

    /// @dev Thrown if a user attempts to open an account on a Credit Facade that has expired
    error OpenAccountNotAllowedAfterExpirationException();

    /// @dev Thrown if expected balances are attempted to be set through revertIfReceivedLessThan twice
    error ExpectedBalancesAlreadySetException();

    /// @dev Thrown if a Credit Account has enabled forbidden tokens and the owner attempts to perform an action
    ///      that is not allowed with any forbidden tokens enabled
    error ActionProhibitedWithForbiddenTokensException();
}

interface ICreditFacade is
    ICreditFacadeEvents,
    ICreditFacadeExceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    /// @dev Opens credit account, borrows funds from the pool and pulls collateral
    /// without any additional action.
    /// @param amount The amount of collateral provided by the borrower
    /// @param onBehalfOf The address to open an account for. Transfers to it have to be allowed if
    /// msg.sender != obBehalfOf
    /// @param leverageFactor Percentage of the user's own funds to borrow. 100 is equal to 100% - borrows the same amount
    /// as the user's own collateral, equivalent to 2x leverage.
    /// @param referralCode Referral code that is used for potential rewards. 0 if no referral code provided.
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint16 leverageFactor,
        uint16 referralCode
    ) external payable;

    /// @dev Opens a Credit Account and runs a batch of operations in a multicall
    /// @param borrowedAmount Debt size
    /// @param onBehalfOf The address to open an account for. Transfers to it have to be allowed if
    /// msg.sender != obBehalfOf
    /// @param calls The array of MultiCall structs encoding the required operations. Generally must have
    /// at least a call to addCollateral, as otherwise the health check at the end will fail.
    /// @param referralCode Referral code which is used for potential rewards. 0 if no referral code provided
    function openCreditAccountMulticall(
        uint256 borrowedAmount,
        address onBehalfOf,
        MultiCall[] calldata calls,
        uint16 referralCode
    ) external payable;

    /// @dev Runs a batch of transactions within a multicall and closes the account
    /// - Wraps ETH to WETH and sends it msg.sender if value > 0
    /// - Executes the multicall - the main purpose of a multicall when closing is to convert all assets to underlying
    /// in order to pay the debt.
    /// - Closes credit account:
    ///    + Checks the underlying balance: if it is greater than the amount paid to the pool, transfers the underlying
    ///      from the Credit Account and proceeds. If not, tries to transfer the shortfall from msg.sender.
    ///    + Transfers all enabled assets with non-zero balances to the "to" address, unless they are marked
    ///      to be skipped in skipTokenMask
    ///    + If convertWETH is true, converts WETH into ETH before sending to the recipient
    /// - Emits a CloseCreditAccount event
    ///
    /// @param to Address to send funds to during account closing
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param convertWETH If true, converts WETH into ETH before sending to "to"
    /// @param calls The array of MultiCall structs encoding the operations to execute before closing the account.
    function closeCreditAccount(
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    /// @dev Runs a batch of transactions within a multicall and liquidates the account
    /// - Computes the total value and checks that hf < 1. An account can't be liquidated when hf >= 1.
    ///   Total value has to be computed before the multicall, otherwise the liquidator would be able
    ///   to manipulate it.
    /// - Wraps ETH to WETH and sends it to msg.sender (liquidator) if value > 0
    /// - Executes the multicall - the main purpose of a multicall when liquidating is to convert all assets to underlying
    ///   in order to pay the debt.
    /// - Liquidate credit account:
    ///    + Computes the amount that needs to be paid to the pool. If totalValue * liquidationDiscount < borrow + interest + fees,
    ///      only totalValue * liquidationDiscount has to be paid. Since liquidationDiscount < 1, the liquidator can take
    ///      totalValue * (1 - liquidationDiscount) as premium. Also computes the remaining funds to be sent to borrower
    ///      as totalValue * liquidationDiscount - amountToPool.
    ///    + Checks the underlying balance: if it is greater than amountToPool + remainingFunds, transfers the underlying
    ///      from the Credit Account and proceeds. If not, tries to transfer the shortfall from the liquidator.
    ///    + Transfers all enabled assets with non-zero balances to the "to" address, unless they are marked
    ///      to be skipped in skipTokenMask. If the liquidator is confident that all assets were converted
    ///      during the multicall, they can set the mask to uint256.max - 1, to only transfer the underlying
    ///    + If convertWETH is true, converts WETH into ETH before sending
    /// - Emits LiquidateCreditAccount event
    ///
    /// @param to Address to send funds to after liquidation
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param convertWETH If true, converts WETH into ETH before sending to "to"
    /// @param calls The array of MultiCall structs encoding the operations to execute before liquidating the account.
    function liquidateCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    /// @dev Runs a batch of transactions within a multicall and liquidates the account when
    /// this Credit Facade is expired
    /// The general flow of liquidation is nearly the same as normal liquidations, with two main differences:
    ///     - An account can be liquidated on an expired Credit Facade even with hf > 1. However,
    ///       no accounts can be liquidated through this function if the Credit Facade is not expired.
    ///     - Liquidation premiums and fees for liquidating expired accounts are reduced.
    /// It is still possible to normally liquidate an underwater Credit Account, even when the Credit Facade
    /// is expired.
    /// @param to Address to send funds to after liquidation
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param convertWETH If true, converts WETH into ETH before sending to "to"
    /// @param calls The array of MultiCall structs encoding the operations to execute before liquidating the account.
    /// @notice See more at https://dev.gearbox.fi/docs/documentation/credit/liquidation#liquidating-accounts-by-expiration
    function liquidateExpiredCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    /// @dev Increases debt for msg.sender's Credit Account
    /// - Borrows the requested amount from the pool
    /// - Updates the CA's borrowAmount / cumulativeIndexOpen
    ///   to correctly compute interest going forward
    /// - Performs a full collateral check
    ///
    /// @param amount Amount to borrow
    function increaseDebt(uint256 amount) external;

    /// @dev Decrease debt
    /// - Decreases the debt by paying the requested amount + accrued interest + fees back to the pool
    /// - It's also include to this payment interest accrued at the moment and fees
    /// - Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param amount Amount to increase borrowed amount
    function decreaseDebt(uint256 amount) external;

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of the borrower whose account is funded
    /// @param token Address of a collateral token
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external payable;

    /// @dev Executes a batch of transactions within a Multicall, to manage an existing account
    ///  - Wraps ETH and sends it back to msg.sender, if value > 0
    ///  - Executes the Multicall
    ///  - Performs a fullCollateralCheck to verify that hf > 1 after all actions
    /// @param calls The array of MultiCall structs encoding the operations to execute.
    function multicall(MultiCall[] calldata calls) external payable;

    /// @dev Returns true if the borrower has an open Credit Account
    /// @param borrower Borrower address
    function hasOpenedCreditAccount(address borrower)
        external
        view
        returns (bool);

    /// @dev Sets token allowance from msg.sender's Credit Account to a connected target contract
    /// @param targetContract Contract to set allowance to. Cannot be in the list of upgradeable contracts
    /// @param token Token address
    /// @param amount Allowance amount
    function approve(
        address targetContract,
        address token,
        uint256 amount
    ) external;

    /// @dev Approves account transfer from another user to msg.sender
    /// @param from Address for which account transfers are allowed/forbidden
    /// @param state True is transfer is allowed, false if forbidden
    function approveAccountTransfer(address from, bool state) external;

    /// @dev Enables token in enabledTokenMask for the Credit Account of msg.sender
    /// @param token Address of token to enable
    function enableToken(address token) external;

    /// @dev Transfers credit account to another user
    /// By default, this action is forbidden, and the user has to approve transfers from sender to itself
    /// by calling approveAccountTransfer.
    /// This is done to prevent malicious actors from transferring compromised accounts to other users.
    /// @param to Address to transfer the account to
    function transferAccountOwnership(address to) external;

    //
    // GETTERS
    //

    /// @dev Calculates total value for provided Credit Account in underlying
    ///
    /// @param creditAccount Credit Account address
    /// @return total Total value in underlying
    /// @return twv Total weighted (discounted by liquidation thresholds) value in underlying
    function calcTotalValue(address creditAccount)
        external
        view
        returns (uint256 total, uint256 twv);

    /**
     * @dev Calculates health factor for the credit account
     *
     *          sum(asset[i] * liquidation threshold[i])
     *   Hf = --------------------------------------------
     *         borrowed amount + interest accrued + fees
     *
     *
     * More info: https://dev.gearbox.fi/developers/credit/economy#health-factor
     *
     * @param creditAccount Credit account address
     * @return hf = Health factor in bp (see PERCENTAGE FACTOR in PercentageMath.sol)
     */
    function calcCreditAccountHealthFactor(address creditAccount)
        external
        view
        returns (uint256 hf);

    /// @dev Returns true if token is a collateral token and is not forbidden,
    /// otherwise returns false
    /// @param token Token to check
    function isTokenAllowed(address token) external view returns (bool);

    /// @dev Returns the CreditManager connected to this Credit Facade
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev Returns true if 'from' is allowed to transfer Credit Accounts to 'to'
    /// @param from Sender address to check allowance for
    /// @param to Receiver address to check allowance for
    function transfersAllowed(address from, address to)
        external
        view
        returns (bool);

    /// @return maxBorrowedAmountPerBlock Maximal amount of new debt that can be taken per block
    /// @return isIncreaseDebtForbidden True if increasing debt is forbidden
    /// @return expirationDate Timestamp of the next expiration (for expirable Credit Facades only)
    function params()
        external
        view
        returns (
            uint128 maxBorrowedAmountPerBlock,
            bool isIncreaseDebtForbidden,
            uint40 expirationDate
        );

    /// @return minBorrowedAmount Minimal borrowed amount per credit account
    /// @return maxBorrowedAmount Maximal borrowed amount per credit account
    function limits()
        external
        view
        returns (uint128 minBorrowedAmount, uint128 maxBorrowedAmount);

    /// @dev Address of the DegenNFT that gatekeeps account openings in whitelisted mode
    function degenNFT() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;

import { IAdapter } from "./helpers/IAdapter.sol";
import { ICurvePool } from "./helpers/curve/ICurvePool.sol";

interface ICurveV1AdapterExceptions {
    error IncorrectIndexException();
}

interface ICurveV1Adapter is IAdapter, ICurvePool, ICurveV1AdapterExceptions {
    /// @dev Sends an order to exchange the entire balance of one asset to another
    /// @param i Index for the coin sent
    /// @param j Index for the coin received
    /// @param rateMinRAY Minimum exchange rate between coins i and j
    function exchange_all(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external;

    /// @dev Sends an order to exchange the entire balance of one underlying asset to another
    /// @param i Index for the underlying coin sent
    /// @param j Index for the underlying coin received
    /// @param rateMinRAY Minimum exchange rate between underlyings i and j
    function exchange_all_underlying(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external;

    /// @dev Sends an order to add liquidity with only 1 input asset
    /// @param amount Amount of asset to deposit
    /// @param i Index of the asset to deposit
    /// @param minAmount Minimal number of LP tokens to receive
    function add_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 minAmount
    ) external;

    /// @dev Sends an order to add liquidity with only 1 input asset, using the entire balance
    /// @param i Index of the asset to deposit
    /// @param rateMinRAY Minimal exchange rate between the deposited asset and the LP token
    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) external;

    /// @dev Sends an order to remove all liquidity from the pool in a single asset
    /// @param i Index of the asset to withdraw
    /// @param minRateRAY Minimal exchange rate between the LP token and the received token
    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external;

    //
    // GETTERS
    //

    /// @dev The pool LP token
    function lp_token() external view returns (address);

    /// @dev Address of the base pool (for metapools only)
    function metapoolBase() external view returns (address);

    /// @dev Number of coins in the pool
    function nCoins() external view returns (uint256);

    /// @dev Token in the pool under index 0
    function token0() external view returns (address);

    /// @dev Token in the pool under index 1
    function token1() external view returns (address);

    /// @dev Token in the pool under index 2
    function token2() external view returns (address);

    /// @dev Token in the pool under index 3
    function token3() external view returns (address);

    /// @dev Underlying in the pool under index 0
    function underlying0() external view returns (address);

    /// @dev Underlying in the pool under index 1
    function underlying1() external view returns (address);

    /// @dev Underlying in the pool under index 2
    function underlying2() external view returns (address);

    /// @dev Underlying in the pool under index 3
    function underlying3() external view returns (address);

    /// @dev Returns the amount of lp token received when adding a single coin to the pool
    /// @param amount Amount of coin to be deposited
    /// @param i Index of a coin to be deposited
    function calc_add_one_coin(uint256 amount, int128 i)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;

import { IAdapter } from "./helpers/IAdapter.sol";
import { ISwapRouter } from "./helpers/uniswap/IUniswapV3.sol";

interface IUniswapV3AdapterExceptions {
    error IncorrectPathLengthException();
}

interface IUniswapV3Adapter is
    IAdapter,
    ISwapRouter,
    IUniswapV3AdapterExceptions
{
    /// @dev A struct encoding parameters for exactAllInputSingle,
    ///      which is unique to the Gearbox adapter
    /// @param tokenIn Token that is spent by the swap
    /// @param tokenOut Token that is received from the swap
    /// @param fee The fee category to use
    /// @param deadline The timestamp, after which the swap will revert
    /// @param rateMinRAY The minimal exhange rate between tokenIn and tokenOut
    ///                   used to calculate amountOutMin on the spot, since the input amount
    ///                   may not always be known in advance
    /// @param sqrtPriceLimitX96 The max execution price. Will be ignored if set to 0.
    struct ExactAllInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 deadline;
        uint256 rateMinRAY;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Sends an order to swap the entire balance of one token for as much as possible of another token
    /// - Fills the `ExactInputSingleParams` struct
    /// - Makes a max allowance fast check call, passing the new struct as params
    /// @param params The parameters necessary for the swap, encoded as `ExactAllInputSingleParams` in calldata
    function exactAllInputSingle(ExactAllInputSingleParams calldata params)
        external
        returns (uint256 amountOut);

    /// @dev A struct encoding parameters for exactAllInput,
    ///      which is unique to the Gearbox adapter
    /// @param path Bytes array encoding the sequence of swaps to perform,
    ///             in the format TOKEN_FEE_TOKEN_FEE_TOKEN...
    /// @param deadline The timestamp, after which the swap will revert
    /// @param rateMinRAY The minimal exhange rate between tokenIn and tokenOut
    ///                   used to calculate amountOutMin on the spot, since the input amount
    ///                   may not always be known in advance
    struct ExactAllInputParams {
        bytes path;
        uint256 deadline;
        uint256 rateMinRAY;
    }

    /// @notice Swaps the entire balance of one token for as much as possible of another along the specified path
    /// - Fills the `ExactAllInputParams` struct
    /// - Makes a max allowance fast check call, passing the new struct as `params`
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactAllInputParams` in calldata
    function exactAllInput(ExactAllInputParams calldata params)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;
import { ICreditManagerV2 } from "./ICreditManagerV2.sol";

enum AdapterType {
    ABSTRACT,
    UNISWAP_V2_ROUTER,
    UNISWAP_V3_ROUTER,
    CURVE_V1_EXCHANGE_ONLY,
    YEARN_V2,
    CURVE_V1_2ASSETS,
    CURVE_V1_3ASSETS,
    CURVE_V1_4ASSETS,
    CURVE_V1_STECRV_POOL,
    CURVE_V1_WRAPPER,
    CONVEX_V1_BASE_REWARD_POOL,
    CONVEX_V1_BOOSTER,
    CONVEX_V1_CLAIM_ZAP,
    LIDO_V1,
    UNIVERSAL
}

interface IAdapterExceptions {
    /// @dev Thrown when the adapter attempts to use a token
    ///      that is not recognized as collateral in the connected
    ///      Credit Manager
    error TokenIsNotInAllowedList(address);
}

interface IAdapter is IAdapterExceptions {
    /// @dev Returns the Credit Manager connected to the adapter
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev Returns the Credit Facade connected to the adapter's Credit Manager
    function creditFacade() external view returns (address);

    /// @dev Returns the address of the contract the adapter is interacting with
    function targetContract() external view returns (address);

    /// @dev Returns the adapter type
    function _gearboxAdapterType() external pure returns (AdapterType);

    /// @dev Returns the adapter version
    function _gearboxAdapterVersion() external pure returns (uint16);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;

import { IPriceOracleV2 } from "./IPriceOracle.sol";
import { IVersion } from "./IVersion.sol";

enum ClosureAction {
    CLOSE_ACCOUNT,
    LIQUIDATE_ACCOUNT,
    LIQUIDATE_EXPIRED_ACCOUNT,
    LIQUIDATE_PAUSED
}

interface ICreditManagerV2Events {
    /// @dev Emits when a call to an external contract is made through the Credit Manager
    event ExecuteOrder(address indexed borrower, address indexed target);

    /// @dev Emits when a configurator is upgraded
    event NewConfigurator(address indexed newConfigurator);
}

interface ICreditManagerV2Exceptions {
    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Facade, or an allowed adapter
    error AdaptersOrCreditFacadeOnlyException();

    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Facade
    error CreditFacadeOnlyException();

    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Configurator
    error CreditConfiguratorOnlyException();

    /// @dev Thrown on attempting to open a Credit Account for or transfer a Credit Account
    ///      to the zero address or an address that already owns a Credit Account
    error ZeroAddressOrUserAlreadyHasAccountException();

    /// @dev Thrown on attempting to execute an order to an address that is not an allowed
    ///      target contract
    error TargetContractNotAllowedException();

    /// @dev Thrown on failing a full collateral check after an operation
    error NotEnoughCollateralException();

    /// @dev Thrown on attempting to receive a token that is not a collateral token
    ///      or was forbidden
    error TokenNotAllowedException();

    /// @dev Thrown if an attempt to approve a collateral token to a target contract failed
    error AllowanceFailedException();

    /// @dev Thrown on attempting to perform an action for an address that owns no Credit Account
    error HasNoOpenedAccountException();

    /// @dev Thrown on attempting to add a token that is already in a collateral list
    error TokenAlreadyAddedException();

    /// @dev Thrown on configurator attempting to add more than 256 collateral tokens
    error TooManyTokensException();

    /// @dev Thrown if more than the maximal number of tokens were enabled on a Credit Account,
    ///      and there are not enough unused token to disable
    error TooManyEnabledTokensException();

    /// @dev Thrown when a reentrancy into the contract is attempted
    error ReentrancyLockException();
}

/// @notice All Credit Manager functions are access-restricted and can only be called
///         by the Credit Facade or allowed adapters. Users are not allowed to
///         interact with the Credit Manager directly
interface ICreditManagerV2 is
    ICreditManagerV2Events,
    ICreditManagerV2Exceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///  @dev Opens credit account and borrows funds from the pool.
    /// - Takes Credit Account from the factory;
    /// - Requests the pool to lend underlying to the Credit Account
    ///
    /// @param borrowedAmount Amount to be borrowed by the Credit Account
    /// @param onBehalfOf The owner of the newly opened Credit Account
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        returns (address);

    ///  @dev Closes a Credit Account - covers both normal closure and liquidation
    /// - Checks whether the contract is paused, and, if so, if the payer is an emergency liquidator.
    ///   Only emergency liquidators are able to liquidate account while the CM is paused.
    ///   Emergency liquidations do not pay a liquidator premium or liquidation fees.
    /// - Calculates payments to various recipients on closure:
    ///    + Computes amountToPool, which is the amount to be sent back to the pool.
    ///      This includes the principal, interest and fees, but can't be more than
    ///      total position value
    ///    + Computes remainingFunds during liquidations - these are leftover funds
    ///      after paying the pool and the liquidator, and are sent to the borrower
    ///    + Computes protocol profit, which includes interest and liquidation fees
    ///    + Computes loss if the totalValue is less than borrow amount + interest
    /// - Checks the underlying token balance:
    ///    + if it is larger than amountToPool, then the pool is paid fully from funds on the Credit Account
    ///    + else tries to transfer the shortfall from the payer - either the borrower during closure, or liquidator during liquidation
    /// - Send assets to the "to" address, as long as they are not included into skipTokenMask
    /// - If convertWETH is true, the function converts WETH into ETH before sending
    /// - Returns the Credit Account back to factory
    ///
    /// @param borrower Borrower address
    /// @param closureActionType Whether the account is closed, liquidated or liquidated due to expiry
    /// @param totalValue Portfolio value for liqution, 0 for ordinary closure
    /// @param payer Address which would be charged if credit account has not enough funds to cover amountToPool
    /// @param to Address to which the leftover funds will be sent
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH
    function closeCreditAccount(
        address borrower,
        ClosureAction closureActionType,
        uint256 totalValue,
        address payer,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    ) external returns (uint256 remainingFunds);

    /// @dev Manages debt size for borrower:
    ///
    /// - Increase debt:
    ///   + Increases debt by transferring funds from the pool to the credit account
    ///   + Updates the cumulative index to keep interest the same. Since interest
    ///     is always computed dynamically as borrowedAmount * (cumulativeIndexNew / cumulativeIndexOpen - 1),
    ///     cumulativeIndexOpen needs to be updated, as the borrow amount has changed
    ///
    /// - Decrease debt:
    ///   + Repays debt partially + all interest and fees accrued thus far
    ///   + Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param creditAccount Address of the Credit Account to change debt for
    /// @param amount Amount to increase / decrease the principal by
    /// @param increase True to increase principal, false to decrease
    /// @return newBorrowedAmount The new debt principal
    function manageDebt(
        address creditAccount,
        uint256 amount,
        bool increase
    ) external returns (uint256 newBorrowedAmount);

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of the account which will be charged to provide additional collateral
    /// @param creditAccount Address of the Credit Account
    /// @param token Collateral token to add
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address creditAccount,
        address token,
        uint256 amount
    ) external;

    /// @dev Transfers Credit Account ownership to another address
    /// @param from Address of previous owner
    /// @param to Address of new owner
    function transferAccountOwnership(address from, address to) external;

    /// @dev Requests the Credit Account to approve a collateral token to another contract.
    /// @param borrower Borrower's address
    /// @param targetContract Spender to change allowance for
    /// @param token Collateral token to approve
    /// @param amount New allowance amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    ) external;

    /// @dev Requests a Credit Account to make a low-level call with provided data
    /// This is the intended pathway for state-changing interactions with 3rd-party protocols
    /// @param borrower Borrower's address
    /// @param targetContract Contract to be called
    /// @param data Data to pass with the call
    function executeOrder(
        address borrower,
        address targetContract,
        bytes memory data
    ) external returns (bytes memory);

    //
    // COLLATERAL VALIDITY AND ACCOUNT HEALTH CHECKS
    //

    /// @dev Enables a token on a Credit Account, including it
    /// into account health and total value calculations
    /// @param creditAccount Address of a Credit Account to enable the token for
    /// @param token Address of the token to be enabled
    function checkAndEnableToken(address creditAccount, address token) external;

    /// @dev Optimized health check for individual swap-like operations.
    /// @notice Fast health check assumes that only two tokens (input and output)
    ///         participate in the operation and computes a % change in weighted value between
    ///         inbound and outbound collateral. The cumulative negative change across several
    ///         swaps in sequence cannot be larger than feeLiquidation (a fee that the
    ///         protocol is ready to waive if needed). Since this records a % change
    ///         between just two tokens, the corresponding % change in TWV will always be smaller,
    ///         which makes this check safe.
    ///         More details at https://dev.gearbox.fi/docs/documentation/risk/fast-collateral-check#fast-check-protection
    /// @param creditAccount Address of the Credit Account
    /// @param tokenIn Address of the token spent by the swap
    /// @param tokenOut Address of the token received from the swap
    /// @param balanceInBefore Balance of tokenIn before the operation
    /// @param balanceOutBefore Balance of tokenOut before the operation
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    ) external;

    /// @dev Performs a full health check on an account, summing up
    /// value of all enabled collateral tokens
    /// @param creditAccount Address of the Credit Account to check
    function fullCollateralCheck(address creditAccount) external;

    /// @dev Checks that the number of enabled tokens on a Credit Account
    ///      does not violate the maximal enabled token limit and tries
    ///      to disable unused tokens if it does
    /// @param creditAccount Account to check enabled tokens for
    function checkAndOptimizeEnabledTokens(address creditAccount) external;

    /// @dev Disables a token on a credit account
    /// @notice Usually called by adapters to disable spent tokens during a multicall,
    ///         but can also be called separately from the Credit Facade to remove
    ///         unwanted tokens
    function disableToken(address creditAccount, address token) external;

    //
    // GETTERS
    //

    /// @dev Returns the address of a borrower's Credit Account, or reverts if there is none.
    /// @param borrower Borrower's address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    /// @dev Computes amounts that must be sent to various addresses before closing an account
    /// @param totalValue Credit Accounts total value in underlying
    /// @param closureActionType Type of account closure
    ///        * CLOSE_ACCOUNT: The account is healthy and is closed normally
    ///        * LIQUIDATE_ACCOUNT: The account is unhealthy and is being liquidated to avoid bad debt
    ///        * LIQUIDATE_EXPIRED_ACCOUNT: The account has expired and is being liquidated (lowered liquidation premium)
    ///        * LIQUIDATE_PAUSED: The account is liquidated while the system is paused due to emergency (no liquidation premium)
    /// @param borrowedAmount Credit Account's debt principal
    /// @param borrowedAmountWithInterest Credit Account's debt principal + interest
    /// @return amountToPool Amount of underlying to be sent to the pool
    /// @return remainingFunds Amount of underlying to be sent to the borrower (only applicable to liquidations)
    /// @return profit Protocol's profit from fees (if any)
    /// @return loss Protocol's loss from bad debt (if any)
    function calcClosePayments(
        uint256 totalValue,
        ClosureAction closureActionType,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        external
        view
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        );

    /// @dev Calculates the debt accrued by a Credit Account
    /// @param creditAccount Address of the Credit Account
    /// @return borrowedAmount The debt principal
    /// @return borrowedAmountWithInterest The debt principal + accrued interest
    /// @return borrowedAmountWithInterestAndFees The debt principal + accrued interest and protocol fees
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (
            uint256 borrowedAmount,
            uint256 borrowedAmountWithInterest,
            uint256 borrowedAmountWithInterestAndFees
        );

    /// @dev Maps Credit Accounts to bit masks encoding their enabled token sets
    /// Only enabled tokens are counted as collateral for the Credit Account
    /// @notice An enabled token mask encodes an enabled token by setting
    ///         the bit at the position equal to token's index to 1
    function enabledTokensMap(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Maps the Credit Account to its current percentage drop across all swaps since
    ///      the last full check, in RAY format
    function cumulativeDropAtFastCheckRAY(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Returns the collateral token at requested index and its liquidation threshold
    /// @param id The index of token to return
    function collateralTokens(uint256 id)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Returns the collateral token with requested mask and its liquidationThreshold
    /// @param tokenMask Token mask corresponding to the token
    function collateralTokensByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Total number of known collateral tokens.
    function collateralTokensCount() external view returns (uint256);

    /// @dev Returns the mask for the provided token
    /// @param token Token to returns the mask for
    function tokenMasksMap(address token) external view returns (uint256);

    /// @dev Bit mask encoding a set of forbidden tokens
    function forbiddenTokenMask() external view returns (uint256);

    /// @dev Maps allowed adapters to their respective target contracts.
    function adapterToContract(address adapter) external view returns (address);

    /// @dev Maps 3rd party contracts to their respective adapters
    function contractToAdapter(address targetContract)
        external
        view
        returns (address);

    /// @dev Address of the underlying asset
    function underlying() external view returns (address);

    /// @dev Address of the connected pool
    function pool() external view returns (address);

    /// @dev Address of the connected pool
    /// @notice [DEPRECATED]: use pool() instead.
    function poolService() external view returns (address);

    /// @dev A map from borrower addresses to Credit Account addresses
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Address of the connected Credit Configurator
    function creditConfigurator() external view returns (address);

    /// @dev Address of WETH
    function wethAddress() external view returns (address);

    /// @dev Returns the liquidation threshold for the provided token
    /// @param token Token to retrieve the LT for
    function liquidationThresholds(address token)
        external
        view
        returns (uint16);

    /// @dev The maximal number of enabled tokens on a single Credit Account
    function maxAllowedEnabledTokenLength() external view returns (uint8);

    /// @dev Maps addresses to their status as emergency liquidator.
    /// @notice Emergency liquidators are trusted addresses
    /// that are able to liquidate positions while the contracts are paused,
    /// e.g. when there is a risk of bad debt while an exploit is being patched.
    /// In the interest of fairness, emergency liquidators do not receive a premium
    /// And are compensated by the Gearbox DAO separately.
    function canLiquidateWhilePaused(address) external view returns (bool);

    /// @dev Returns the fee parameters of the Credit Manager
    /// @return feeInterest Percentage of interest taken by the protocol as profit
    /// @return feeLiquidation Percentage of account value taken by the protocol as profit
    ///         during unhealthy account liquidations
    /// @return liquidationDiscount Multiplier that reduces the effective totalValue during unhealthy account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremium)
    /// @return feeLiquidationExpired Percentage of account value taken by the protocol as profit
    ///         during expired account liquidations
    /// @return liquidationDiscountExpired Multiplier that reduces the effective totalValue during expired account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremiumExpired)
    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        );

    /// @dev Address of the connected Credit Facade
    function creditFacade() external view returns (address);

    /// @dev Address of the connected Price Oracle
    function priceOracle() external view returns (IPriceOracleV2);

    /// @dev Address of the universal adapter
    function universalAdapter() external view returns (address);

    /// @dev Contract's version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;

import { IVersion } from "./IVersion.sol";

interface IPriceOracleV2Events {
    /// @dev Emits when a new price feed is added
    event NewPriceFeed(address indexed token, address indexed priceFeed);
}

interface IPriceOracleV2Exceptions {
    /// @dev Thrown if a price feed returns 0
    error ZeroPriceException();

    /// @dev Thrown if the last recorded result was not updated in the last round
    error ChainPriceStaleException();

    /// @dev Thrown on attempting to get a result for a token that does not have a price feed
    error PriceOracleNotExistsException();
}

/// @title Price oracle interface
interface IPriceOracleV2 is
    IPriceOracleV2Events,
    IPriceOracleV2Exceptions,
    IVersion
{
    /// @dev Converts a quantity of an asset to USD (decimals = 8).
    /// @param amount Amount to convert
    /// @param token Address of the token to be converted
    function convertToUSD(uint256 amount, address token)
        external
        view
        returns (uint256);

    /// @dev Converts a quantity of USD (decimals = 8) to an equivalent amount of an asset
    /// @param amount Amount to convert
    /// @param token Address of the token converted to
    function convertFromUSD(uint256 amount, address token)
        external
        view
        returns (uint256);

    /// @dev Converts one asset into another
    ///
    /// @param amount Amount to convert
    /// @param tokenFrom Address of the token to convert from
    /// @param tokenTo Address of the token to convert to
    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    /// @dev Returns collateral values for two tokens, required for a fast check
    /// @param amountFrom Amount of the outbound token
    /// @param tokenFrom Address of the outbound token
    /// @param amountTo Amount of the inbound token
    /// @param tokenTo Address of the inbound token
    /// @return collateralFrom Value of the outbound token amount in USD
    /// @return collateralTo Value of the inbound token amount in USD
    function fastCheck(
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) external view returns (uint256 collateralFrom, uint256 collateralTo);

    /// @dev Returns token's price in USD (8 decimals)
    /// @param token The token to compute the price for
    function getPrice(address token) external view returns (uint256);

    /// @dev Returns the price feed address for the passed token
    /// @param token Token to get the price feed for
    function priceFeeds(address token)
        external
        view
        returns (address priceFeed);

    /// @dev Returns the price feed for the passed token,
    ///      with additional parameters
    /// @param token Token to get the price feed for
    function priceFeedsWithFlags(address token)
        external
        view
        returns (
            address priceFeed,
            bool skipCheck,
            uint256 decimals
        );
}

interface IPriceOracleV2Ext is IPriceOracleV2 {
    /// @dev Sets a price feed if it doesn't exist, or updates an existing one
    /// @param token Address of the token to set the price feed for
    /// @param priceFeed Address of a USD price feed adhering to Chainlink's interface
    function addPriceFeed(address token, address priceFeed) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;

/// @title IVersion
/// @dev Declares a version function which returns the contract's version
interface IVersion {
    /// @dev Returns contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBaseRewardPool {
    //
    // STATE CHANGING FUNCTIONS
    //

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    function getReward() external returns (bool);

    function donate(uint256 _amount) external returns (bool);

    //
    // GETTERS
    //

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function extraRewardsLength() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardToken() external view returns (IERC20);

    function stakingToken() external view returns (IERC20);

    function duration() external view returns (uint256);

    function operator() external view returns (address);

    function rewardManager() external view returns (address);

    function pid() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function queuedRewards() external view returns (uint256);

    function currentRewards() external view returns (uint256);

    function historicalRewards() external view returns (uint256);

    function newRewardRatio() external view returns (uint256);

    function userRewardPerTokenPaid(address account)
        external
        view
        returns (uint256);

    function rewards(address account) external view returns (uint256);

    function extraRewards(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    // function earmarkRewards(uint256 _pid) external returns (bool);

    // function earmarkFees() external returns (bool);

    //
    // GETTERS
    //

    function poolInfo(uint256 i) external view returns (PoolInfo memory);

    function poolLength() external view returns (uint256);

    function staker() external view returns (address);

    function minter() external view returns (address);

    function crv() external view returns (address);

    function registry() external view returns (address);

    function stakerRewards() external view returns (address);

    function lockRewards() external view returns (address);

    function lockFees() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function underlying_coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function coins(int128) external view returns (address);

    function underlying_coins(int128) external view returns (address);

    function balances(int128) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function token() external view returns (address);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);

    function admin_balances(uint256 i) external view returns (uint256);

    function admin() external view returns (address);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    // Some pools implement ERC20

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.9;

struct Balance {
    address token;
    uint256 balance;
}

library BalanceOps {
    error UnknownToken(address);

    function copyBalance(Balance memory b)
        internal
        pure
        returns (Balance memory)
    {
        return Balance({ token: b.token, balance: b.balance });
    }

    function addBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance += amount;
    }

    function subBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance -= amount;
    }

    function getBalance(Balance[] memory b, address token)
        internal
        pure
        returns (uint256 amount)
    {
        return b[getIndex(b, token)].balance;
    }

    function setBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance = amount;
    }

    function getIndex(Balance[] memory b, address token)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i; i < b.length; ) {
            if (b[i].token == token) {
                return i;
            }

            unchecked {
                ++i;
            }
        }
        revert UnknownToken(token);
    }

    function copy(Balance[] memory b, uint256 len)
        internal
        pure
        returns (Balance[] memory res)
    {
        res = new Balance[](len);
        for (uint256 i; i < len; ) {
            res[i] = copyBalance(b[i]);
            unchecked {
                ++i;
            }
        }
    }

    function clone(Balance[] memory b)
        internal
        pure
        returns (Balance[] memory)
    {
        return copy(b, b.length);
    }

    function getModifiedAfterSwap(
        Balance[] memory b,
        address tokenFrom,
        uint256 amountFrom,
        address tokenTo,
        uint256 amountTo
    ) internal pure returns (Balance[] memory res) {
        res = copy(b, b.length);
        setBalance(res, tokenFrom, getBalance(b, tokenFrom) - amountFrom);
        setBalance(res, tokenTo, getBalance(b, tokenTo) + amountTo);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

struct MultiCall {
    address target;
    bytes callData;
}

library MultiCallOps {
    function copyMulticall(MultiCall memory call)
        internal
        pure
        returns (MultiCall memory)
    {
        return MultiCall({ target: call.target, callData: call.callData });
    }

    function trim(MultiCall[] memory calls)
        internal
        pure
        returns (MultiCall[] memory trimmed)
    {
        uint256 len = calls.length;

        if (len == 0) return calls;

        uint256 foundLen;
        while (calls[foundLen].target != address(0)) {
            unchecked {
                ++foundLen;
                if (foundLen == len) return calls;
            }
        }

        if (foundLen > 0) return copy(calls, foundLen);
    }

    function copy(MultiCall[] memory calls, uint256 len)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        res = new MultiCall[](len);
        for (uint256 i; i < len; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function clone(MultiCall[] memory calls)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        return copy(calls, calls.length);
    }

    function append(MultiCall[] memory calls, MultiCall memory newCall)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len = calls.length;
        res = new MultiCall[](len + 1);
        for (uint256 i; i < len; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
        res[len] = copyMulticall(newCall);
    }

    function prepend(MultiCall[] memory calls, MultiCall memory newCall)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len = calls.length;
        res = new MultiCall[](len + 1);
        res[0] = copyMulticall(newCall);

        for (uint256 i = 1; i < len + 1; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function concat(MultiCall[] memory calls1, MultiCall[] memory calls2)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len1 = calls1.length;
        uint256 lenTotal = len1 + calls2.length;

        if (lenTotal == calls1.length) return clone(calls1);
        if (lenTotal == calls2.length) return clone(calls2);

        res = new MultiCall[](lenTotal);

        for (uint256 i; i < lenTotal; ) {
            res[i] = (i < len1)
                ? copyMulticall(calls1[i])
                : copyMulticall(calls2[i - len1]);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);

    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is operator, `false` otherwise
    function isOperator(address who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IProtocolGovernance.sol";

interface IBaseValidator {
    /// @notice Validator parameters
    /// @param protocolGovernance Reference to Protocol Governance
    struct ValidatorParams {
        IProtocolGovernance protocolGovernance;
    }

    /// @notice Validator params staged to commit.
    function stagedValidatorParams() external view returns (ValidatorParams memory);

    /// @notice Timestamp after which validator params can be committed.
    function stagedValidatorParamsTimestamp() external view returns (uint256);

    /// @notice Current validator params.
    function validatorParams() external view returns (ValidatorParams memory);

    /// @notice Stage new validator params for commit.
    /// @param newParams New params for commit
    function stageValidatorParams(ValidatorParams calldata newParams) external;

    /// @notice Commit new validator params.
    function commitValidatorParams() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IBaseValidator.sol";

interface IValidator is IBaseValidator, IERC165 {
    // @notice Validate if call can be made to external contract.
    // @dev Reverts if validation failed. Returns nothing if validation is ok
    // @param sender Sender of the externalCall method
    // @param addr Address of the called contract
    // @param value Ether value for the call
    // @param selector Selector of the called method
    // @param data Call data after selector
    function validate(
        address sender,
        address addr,
        uint256 value,
        bytes4 selector,
        bytes calldata data
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IIntegrationVault.sol";
import "../external/gearbox/ICreditFacade.sol";
import "../external/gearbox/IUniswapV3Adapter.sol";
import "../../utils/GearboxHelper.sol";

interface IGearboxVault is IIntegrationVault {

    /// @notice Reference to the Gearbox creditFacade contract for the primary token of this vault.
    function creditFacade() external view returns (ICreditFacade);

    /// @notice Reference to the Gearbox creditManager contract for the primary token of this vault.
    function creditManager() external view returns (ICreditManagerV2);

    /// @notice Primary token of the vault, for this token a credit account is opened in Gearbox.
    function primaryToken() external view returns (address);

    /// @notice Deposit token of the vault, deposits/withdawals are made in this token (might be the same or different with primaryToken)
    function depositToken() external view returns (address);

    /// @notice Gearbox vault helper
    function helper() external view returns (GearboxHelper);

    /// @notice The leverage factor of the vault, multiplied by 10^9
    /// For a vault with X usd of collateral and marginal factor T >= 1, total assets (collateral + debt) should be equal to X * T 
    function marginalFactorD9() external view returns (uint256);

    /// @notice Index used for claiming in Gearbox V2 Degen contract
    function merkleIndex() external view returns (uint256);

    /// @notice NFTs amount used for claiming in Gearbox V2 Degen contract
    function merkleTotalAmount() external view returns (uint256);

    /// @notice Proof used for claiming in Gearbox V2 Degen contract
    function getMerkleProof() external view returns (bytes32[] memory);

    /// @notice The index of the curve pool the vault invests into
    function poolId() external view returns (uint256);

    /// @notice The index of the primary token in the used curve pool
    function primaryIndex() external view returns (int128);

    /// @notice The address of the convex token we receive after staking Convex LPs
    function convexOutputToken() external view returns (address);

    /// @notice Adds an array of pools into the set of approved pools (opening a credit account is allowed by our protocol only for operations in such pools)
    /// @param pools List of pools
    function addPoolsToAllowList(uint256[] calldata pools) external;

    /// @notice Remove an array of pools from the set of approved pools (opening a credit account is allowed by our protocol only for operations in such pools)
    /// @param pools List of pools
    function removePoolsFromAllowlist(uint256[] calldata pools) external;
    
    /// @notice Initialized a new contract.
    /// @dev Can only be initialized by vault governance
    /// @param nft_ NFT of the vault in the VaultRegistry
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param helper_ Address of helper
    function initialize(uint256 nft_, address[] memory vaultTokens_, address helper_) external;

    /// @notice Updates marginalFactorD9 (can be successfully called only by an admin or a strategist)
    /// @param marginalFactorD_ New marginalFactorD9
    function updateTargetMarginalFactor(uint256 marginalFactorD_) external;

    /// @notice Sets merkle tree parameters for claiming Gearbox V2 Degen NFT (can be successfully called only by an admin or a strategist)
    /// @param merkleIndex_ Required index
    /// @param merkleTotalAmount_ Total amount of NFTs we have in Gearbox Degen Contract
    /// @param merkleProof_ Proof in Merkle tree
    function setMerkleParameters(uint256 merkleIndex_, uint256 merkleTotalAmount_, bytes32[] memory merkleProof_) external;

    /// @notice Adjust a position (takes more debt or repays some, depending on the past performance) to achieve the required marginalFactorD9
    function adjustPosition() external;

    /// @notice Opens a new credit account on the address of the vault
    function openCreditAccount(address curveAdapter, address convexAdapter) external;

    /// @notice Closes existing credit account (only possible to be successfully called by the root vault)
    function closeCreditAccount() external;

    /// @notice A helper function to be able to call Gearbox multicalls from the helper, but on behalf of the vault
    /// Can be successfully called only by the helper
    function openCreditAccountInManager(uint256 currentPrimaryTokenAmount, uint16 referralCode) external;

    /// @notice Returns an address of the credit account connected to the address of the vault
    function getCreditAccount() external view returns (address);

    /// @notice Returns value of all assets located on the vault, including taken with leverage (nominated in primary tokens)
    function getAllAssetsOnCreditAccountValue() external view returns (uint256 currentAllAssetsValue);

    /// @notice Returns value of rewards (CRV, CVX) we can obtain from Convex (nominated in primary tokens)
    function getClaimableRewardsValue() external view returns (uint256);

    /// @notice A helper function to be able to call Gearbox multicalls from the helper, but on behalf of the vault
    /// Can be successfully called only by the helper
    function multicall(MultiCall[] memory calls) external;

    /// @notice A helper function to be able to call Gearbox multicalls from the helper, but on behalf of the vault
    /// Can be successfully called only by the helper
    function swapExactOutput(ISwapRouter router, ISwapRouter.ExactOutputParams memory uniParams, address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IGearboxVault.sol";
import "./IVaultGovernance.sol";

interface IGearboxVaultGovernance is IVaultGovernance {

    /// @notice Params that could be changed by Strategy or Protocol Governance with Protocol Governance delay.
    /// @param crv3Pool 3CRV token address
    /// @param crv CRV token address
    /// @param cvx CVX token address
    /// @param maxSlippageD9 Maximal admissible slippage for swaps between primary/deposit tokes
    /// @param maxSmallPoolsSlippageD9 Maximal admissible slippage for swaps crv-weth and cvx-weth
    /// @param maxCurveSlippageD9 Maximal admissible slippage for add/remove liquidity in Curve pool
    /// @param uniswapRouter Address of the Uniswap V3 router
    struct DelayedProtocolParams {
        address crv3Pool;
        address crv;
        address cvx;
        uint256 maxSlippageD9;
        uint256 maxSmallPoolsSlippageD9;
        uint256 maxCurveSlippageD9;
        address uniswapRouter;
    }

    /// @notice Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param primaryToken Primary token of the vault (i.e. the token of the Gearbox Credit Account)
    /// @param univ3Adapter Address of the Uniswap V3 Adapter by Gearbox used by the system
    /// @param facade Address of the Gearbox CreditFacade contract used by the vault
    /// @param withdrawDelay The minimal time to pass between two consecutive withdrawal orders execution
    /// @param initialMarginalValueD9 Initial value of marginal factor of the vault
    /// @param referralCode The referral code to be used when depositing to Gearbox
    struct DelayedProtocolPerVaultParams {
        address primaryToken;
        address univ3Adapter;
        address facade;
        uint256 withdrawDelay;
        uint256 initialMarginalValueD9;
        uint16 referralCode;
    }

    /// @notice Params that could be changed by Strategy or Protocol Governance.
    /// @param largePoolFeeUsed Fee for the primary/deposit pool we want to use
    struct StrategyParams {
        uint24 largePoolFeeUsed;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function delayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Delayed Protocol Params staged for commit after delay.
    function stagedDelayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Delayed Protocol Per Vault Params staged for commit after delay.
    /// @param nft VaultRegistry NFT of the vault
    function stagedDelayedProtocolPerVaultParams(uint256 nft)
        external
        view
        returns (DelayedProtocolPerVaultParams memory);

    /// @notice Delayed Protocol Per Vault Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param nft VaultRegistry NFT of the vault
    function delayedProtocolPerVaultParams(uint256 nft) external view returns (DelayedProtocolPerVaultParams memory);

    /// @notice Strategy Params.
    function strategyParams(uint256 nft) external view returns (StrategyParams memory);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @dev Can only be called after delayedProtocolParamsTimestamp.
    /// @param params New params
    function stageDelayedProtocolParams(DelayedProtocolParams memory params) external;

    /// @notice Commit Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function commitDelayedProtocolParams() external;

    /// @notice Stage Delayed Protocol Per Vault Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param nft VaultRegistry NFT of the vault
    /// @param params New params
    function stageDelayedProtocolPerVaultParams(uint256 nft, DelayedProtocolPerVaultParams calldata params) external;

    /// @notice Commit Delayed Protocol Per Vault Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @dev Can only be called after delayedProtocolPerVaultParamsTimestamp
    /// @param nft VaultRegistry NFT of the vault
    function commitDelayedProtocolPerVaultParams(uint256 nft) external;

    /// @notice Set Strategy params, i.e. Params that could be changed by Strategy or Protocol Governance immediately.
    /// @param params New params
    function setStrategyParams(uint256 nft, StrategyParams calldata params) external;

    /// @notice Deploys a new vault.
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param owner_ Owner of the vault NFT
    /// @param helper_ Gearbox helper contract address
    function createVault(address[] memory vaultTokens_, address owner_, address helper_)
        external
        returns (IGearboxVault vault, uint256 nft);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../external/erc/IERC1271.sol";
import "./IVault.sol";

interface IIntegrationVault is IVault, IERC1271 {
    /// @notice Pushes tokens on the vault balance to the underlying protocol. For example, for Yearn this operation will take USDC from
    /// the contract balance and convert it to yUSDC.
    /// @dev Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function push(
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The same as `push` method above but transfers tokens to vault balance prior to calling push.
    /// After the `push` it returns all the leftover tokens back (`push` method doesn't guarantee that tokenAmounts will be invested in full).
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function transferAndPush(
        address from,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Pulls tokens from the underlying protocol to the `to` address.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    /// When called by vault owner this method just pulls the tokens from the protocol to the `to` address
    /// When called by strategy on vault other than zero vault it pulls the tokens to zero vault (required `to` == zero vault)
    /// When called by strategy on zero vault it pulls the tokens to zero vault, pushes tokens on the `to` vault, and reclaims everything that's left.
    /// Thus any vault other than zero vault cannot have any tokens on it
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Pull is fulfilled on the best effort basis, i.e. if the tokenAmounts overflows available funds it withdraws all the funds.
    /// @param to Address to receive the tokens
    /// @param tokens Tokens to pull
    /// @param tokenAmounts Amounts of tokens to pull
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually withdrawn. It could be less than tokenAmounts (but not higher)
    function pull(
        address to,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Claim ERC20 tokens from vault balance to zero vault.
    /// @dev Cannot be called from zero vault.
    /// @param tokens Tokens to claim
    /// @return actualTokenAmounts Amounts reclaimed
    function reclaimTokens(address[] memory tokens) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Execute one of whitelisted calls.
    /// @dev Can only be called by Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Since this method allows sending arbitrary transactions, the destinations of the calls
    /// are whitelisted by Protocol Governance.
    /// @param to Address of the reward pool
    /// @param selector Selector of the call
    /// @param data Abi encoded parameters to `to::selector`
    /// @return result Result of execution of the call
    function externalCall(
        address to,
        bytes4 selector,
        bytes memory data
    ) external payable returns (bytes memory result);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IVaultGovernance.sol";

interface IVault is IERC165 {
    /// @notice Checks if the vault is initialized

    function initialized() external view returns (bool);

    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Checks if a token is vault token
    /// @param token Address of the token to check
    /// @return `true` if this token is managed by Vault
    function isVaultToken(address token) external view returns (bool);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// The tvl itself is estimated in some range. Sometimes the range is exact, sometimes it's not
    /// @return minTokenAmounts Lower bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    /// @return maxTokenAmounts Upper bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    /// @notice Existential amounts for each token
    function pullExistentials() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IProtocolGovernance.sol";
import "../IVaultRegistry.sol";
import "./IVault.sol";

interface IVaultGovernance {
    /// @notice Internal references of the contract.
    /// @param protocolGovernance Reference to Protocol Governance
    /// @param registry Reference to Vault Registry
    struct InternalParams {
        IProtocolGovernance protocolGovernance;
        IVaultRegistry registry;
        IVault singleton;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params Per Vault could be committed.
    /// @param nft Nft of the vault
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);

    /// @notice Internal Params of the contract.
    function internalParams() external view returns (InternalParams memory);

    /// @notice Staged new Internal Params.
    /// @dev The Internal Params could be committed after internalParamsTimestamp
    function stagedInternalParams() external view returns (InternalParams memory);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage new Internal Params.
    /// @param newParams New Internal Params
    function stageInternalParams(InternalParams memory newParams) external;

    /// @notice Commit staged Internal Params.
    function commitInternalParams() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVaultRoot {
    /// @notice Checks if subvault is present
    /// @param nft_ index of subvault for check
    /// @return `true` if subvault present, `false` otherwise
    function hasSubvault(uint256 nft_) external view returns (bool);

    /// @notice Get subvault by index
    /// @param index Index of subvault
    /// @return address Address of the contract
    function subvaultAt(uint256 index) external view returns (address);

    /// @notice Get index of subvault by nft
    /// @param nft_ Nft for getting subvault
    /// @return index Index of subvault
    function subvaultOneBasedIndex(uint256 nft_) external view returns (uint256);

    /// @notice Get all subvalutNfts in the current Vault
    /// @return subvaultNfts Subvaults of NTFs
    function subvaultNfts() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./external/FullMath.sol";
import "./ExceptionsLibrary.sol";

/// @notice CommonLibrary shared utilities
library CommonLibrary {
    uint256 constant DENOMINATOR = 10**9;
    uint256 constant D18 = 10**18;
    uint256 constant YEAR = 365 * 24 * 3600;
    uint256 constant Q128 = 2**128;
    uint256 constant Q96 = 2**96;
    uint256 constant Q48 = 2**48;
    uint256 constant Q160 = 2**160;
    uint256 constant UNI_FEE_DENOMINATOR = 10**6;

    /// @notice Sort uint256 using bubble sort. The sorting is done in-place.
    /// @param arr Array of uint256
    function sortUint(uint256[] memory arr) internal pure {
        uint256 l = arr.length;
        for (uint256 i = 0; i < l; ++i) {
            for (uint256 j = i + 1; j < l; ++j) {
                if (arr[i] > arr[j]) {
                    uint256 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

    /// @notice Checks if array of addresses is sorted and all adresses are unique
    /// @param tokens A set of addresses to check
    /// @return `true` if all addresses are sorted and unique, `false` otherwise
    function isSortedAndUnique(address[] memory tokens) internal pure returns (bool) {
        if (tokens.length < 2) {
            return true;
        }
        for (uint256 i = 0; i < tokens.length - 1; ++i) {
            if (tokens[i] >= tokens[i + 1]) {
                return false;
            }
        }
        return true;
    }

    /// @notice Projects tokenAmounts onto subset or superset of tokens
    /// @dev
    /// Requires both sets of tokens to be sorted. When tokens are not sorted, it's undefined behavior.
    /// If there is a token in tokensToProject that is not part of tokens and corresponding tokenAmountsToProject > 0, reverts.
    /// Zero token amount is eqiuvalent to missing token
    function projectTokenAmounts(
        address[] memory tokens,
        address[] memory tokensToProject,
        uint256[] memory tokenAmountsToProject
    ) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tokens.length);
        uint256 t = 0;
        uint256 tp = 0;
        while ((t < tokens.length) && (tp < tokensToProject.length)) {
            if (tokens[t] < tokensToProject[tp]) {
                res[t] = 0;
                t++;
            } else if (tokens[t] > tokensToProject[tp]) {
                if (tokenAmountsToProject[tp] == 0) {
                    tp++;
                } else {
                    revert("TPS");
                }
            } else {
                res[t] = tokenAmountsToProject[tp];
                t++;
                tp++;
            }
        }
        while (t < tokens.length) {
            res[t] = 0;
            t++;
        }
        return res;
    }

    /// @notice Calculated sqrt of uint in X96 format
    /// @param xX96 input number in X96 format
    /// @return sqrt of xX96 in X96 format
    function sqrtX96(uint256 xX96) internal pure returns (uint256) {
        uint256 sqX96 = sqrt(xX96);
        return sqX96 << 48;
    }

    /// @notice Calculated sqrt of uint
    /// @param x input number
    /// @return sqrt of x
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

    /// @notice Recovers signer address from signed message hash
    /// @param _ethSignedMessageHash signed message
    /// @param _signature contatenated ECDSA r, s, v (65 bytes)
    /// @return Recovered address if the signature is valid, address(0) otherwise
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// @notice Get ECDSA r, s, v from signature
    /// @param sig signature (65 bytes)
    /// @return r ECDSA r
    /// @return s ECDSA s
    /// @return v ECDSA v
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, ExceptionsLibrary.INVALID_LENGTH);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Exceptions stores project`s smart-contracts exceptions
library ExceptionsLibrary {
    string constant ADDRESS_ZERO = "AZ";
    string constant VALUE_ZERO = "VZ";
    string constant EMPTY_LIST = "EMPL";
    string constant NOT_FOUND = "NF";
    string constant INIT = "INIT";
    string constant DUPLICATE = "DUP";
    string constant NULL = "NULL";
    string constant TIMESTAMP = "TS";
    string constant FORBIDDEN = "FRB";
    string constant ALLOWLIST = "ALL";
    string constant LIMIT_OVERFLOW = "LIMO";
    string constant LIMIT_UNDERFLOW = "LIMU";
    string constant INVALID_VALUE = "INV";
    string constant INVARIANT = "INVA";
    string constant INVALID_TARGET = "INVTR";
    string constant INVALID_TOKEN = "INVTO";
    string constant INVALID_INTERFACE = "INVI";
    string constant INVALID_SELECTOR = "INVS";
    string constant INVALID_STATE = "INVST";
    string constant INVALID_LENGTH = "INVL";
    string constant LOCK = "LCKD";
    string constant DISABLED = "DIS";
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Stores permission ids for addresses
library PermissionIdsLibrary {
    // The msg.sender is allowed to register vault
    uint8 constant REGISTER_VAULT = 0;
    // The msg.sender is allowed to create vaults
    uint8 constant CREATE_VAULT = 1;
    // The token is allowed to be transfered by vault
    uint8 constant ERC20_TRANSFER = 2;
    // The token is allowed to be added to vault
    uint8 constant ERC20_VAULT_TOKEN = 3;
    // Trusted protocols that are allowed to be approved of vault ERC20 tokens by any strategy
    uint8 constant ERC20_APPROVE = 4;
    // Trusted protocols that are allowed to be approved of vault ERC20 tokens by trusted strategy
    uint8 constant ERC20_APPROVE_RESTRICTED = 5;
    // Strategy allowed using restricted API
    uint8 constant TRUSTED_STRATEGY = 6;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // diff: original uint256 twos = -denominator & denominator;
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/external/convex/ICvx.sol";
import "../interfaces/external/convex/Interfaces.sol";
import "../interfaces/external/gearbox/helpers/IPriceOracle.sol";
import "../libraries/external/FullMath.sol";
import "../interfaces/external/gearbox/ICreditFacade.sol";
import "../interfaces/external/gearbox/ICurveV1Adapter.sol";
import "../interfaces/external/gearbox/IConvexV1BaseRewardPoolAdapter.sol";
import "../interfaces/external/gearbox/IUniswapV3Adapter.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/vaults/IGearboxVaultGovernance.sol";
import "../interfaces/external/gearbox/helpers/convex/IBooster.sol";

contract GearboxHelper {
    using SafeERC20 for IERC20;

    uint256 public constant D9 = 10**9;
    uint256 public constant D27 = 10**27;
    bytes4 public constant GET_REWARD_SELECTOR = 0x7050ccd9;

    ICreditFacade public creditFacade;
    ICreditManagerV2 public creditManager;

    address public curveAdapter;
    address public convexAdapter;
    address public primaryToken;
    address public depositToken;

    bool public parametersSet;
    bool public is3crv;
    int128 crv3Index;

    IGearboxVault public gearboxVault;

    uint256 public vaultNft;

    function setParameters(
        ICreditFacade creditFacade_,
        ICreditManagerV2 creditManager_,
        address primaryToken_,
        address depositToken_,
        uint256 nft_
    ) external {
        require(!parametersSet, ExceptionsLibrary.FORBIDDEN);
        creditFacade = creditFacade_;
        creditManager = creditManager_;
        primaryToken = primaryToken_;
        depositToken = depositToken_;
        vaultNft = nft_;

        parametersSet = true;
        gearboxVault = IGearboxVault(msg.sender);
    }

    function setAdapters(address curveAdapter_, address convexAdapter_) external {
        require(msg.sender == address(gearboxVault), ExceptionsLibrary.FORBIDDEN);
        curveAdapter = curveAdapter_;
        convexAdapter = convexAdapter_;
    }

    function calcTvl(address creditAccount, address vaultGovernance) external view returns (uint256) {
        address depositToken_ = depositToken;
        address primaryToken_ = primaryToken;
        ICreditManagerV2 creditManager_ = creditManager;

        uint256 primaryTokenAmount = calculateClaimableRewards(creditAccount, vaultGovernance);

        if (primaryToken_ != depositToken_) {
            primaryTokenAmount += IERC20(primaryToken_).balanceOf(address(gearboxVault));
        }

        if (creditAccount != address(0)) {
            (uint256 currentAllAssetsValue, ) = creditFacade.calcTotalValue(creditAccount);
            (, , uint256 borrowAmountWithInterestAndFees) = creditManager_.calcCreditAccountAccruedInterest(
                creditAccount
            );

            if (currentAllAssetsValue >= borrowAmountWithInterestAndFees) {
                primaryTokenAmount += currentAllAssetsValue - borrowAmountWithInterestAndFees;
            }
        }

        if (primaryToken_ == depositToken_) {
            return primaryTokenAmount + IERC20(depositToken_).balanceOf(address(gearboxVault));
        } else {
            IPriceOracleV2 oracle = IPriceOracleV2(creditManager_.priceOracle());
            return
                oracle.convert(primaryTokenAmount, primaryToken_, depositToken_) +
                IERC20(depositToken_).balanceOf(address(gearboxVault));
        }
    }

    function verifyInstances(address vaultGovernance)
        external
        returns (
            int128 primaryIndex,
            address convexOutputToken,
            uint256 poolId
        )
    {
        require(msg.sender == address(gearboxVault), ExceptionsLibrary.FORBIDDEN);
        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams = IGearboxVaultGovernance(vaultGovernance)
            .delayedProtocolParams();

        ICurveV1Adapter curveAdapter_ = ICurveV1Adapter(curveAdapter);
        IConvexV1BaseRewardPoolAdapter convexAdapter_ = IConvexV1BaseRewardPoolAdapter(convexAdapter);

        poolId = convexAdapter_.pid();
        address primaryToken_ = primaryToken;

        require(creditFacade.isTokenAllowed(primaryToken_), ExceptionsLibrary.INVALID_TOKEN);

        bool havePrimaryTokenInCurve = false;
        is3crv = false;

        for (uint256 i = 0; i < curveAdapter_.nCoins(); ++i) {
            address tokenI = curveAdapter_.coins(i);
            if (tokenI == primaryToken_) {
                primaryIndex = int128(int256(i));
                havePrimaryTokenInCurve = true;
            }
        }

        if (!havePrimaryTokenInCurve) {
            ICurveV1Adapter crv3Adapter = ICurveV1Adapter(creditManager.contractToAdapter(protocolParams.crv3Pool));
            address crv3Token = crv3Adapter.lp_token();

            for (uint256 i = 0; i < curveAdapter_.nCoins(); ++i) {
                address tokenI = curveAdapter_.coins(i);
                if (tokenI == crv3Token) {
                    crv3Index = int128(uint128(i));
                    is3crv = true;
                    for (uint256 j = 0; j < 3; ++j) {
                        address tokenJ = crv3Adapter.coins(j);
                        if (tokenJ == primaryToken_) {
                            primaryIndex = int128(int256(j));
                            havePrimaryTokenInCurve = true;
                        }
                    }
                }
            }
        }

        require(havePrimaryTokenInCurve, ExceptionsLibrary.INVALID_TOKEN);

        convexOutputToken = address(convexAdapter_.stakedPhantomToken());
        require(curveAdapter_.lp_token() == convexAdapter_.curveLPtoken(), ExceptionsLibrary.INVALID_TARGET);
    }

    function calculateEarnedCvxAmountByEarnedCrvAmount(uint256 crvAmount, address cvxTokenAddress)
        public
        view
        returns (uint256)
    {
        IConvexToken cvxToken = IConvexToken(cvxTokenAddress);

        unchecked {
            uint256 supply = cvxToken.totalSupply();

            uint256 cliff = supply / cvxToken.reductionPerCliff();
            uint256 totalCliffs = cvxToken.totalCliffs();

            if (cliff < totalCliffs) {
                uint256 reduction = totalCliffs - cliff;
                uint256 cvxAmount = FullMath.mulDiv(crvAmount, reduction, totalCliffs);

                uint256 amtTillMax = cvxToken.maxSupply() - supply;
                if (cvxAmount > amtTillMax) {
                    cvxAmount = amtTillMax;
                }

                return cvxAmount;
            }

            return 0;
        }
    }

    function calculateClaimableRewards(address creditAccount, address vaultGovernance) public view returns (uint256) {
        if (creditAccount == address(0)) {
            return 0;
        }

        uint256 earnedCrvAmount = IConvexV1BaseRewardPoolAdapter(convexAdapter).earned(creditAccount);
        IPriceOracleV2 oracle = IPriceOracleV2(creditManager.priceOracle());

        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams = IGearboxVaultGovernance(vaultGovernance)
            .delayedProtocolParams();

        uint256 valueCrvToUsd = oracle.convertToUSD(earnedCrvAmount, protocolParams.crv);
        uint256 valueCvxToUsd = oracle.convertToUSD(
            calculateEarnedCvxAmountByEarnedCrvAmount(earnedCrvAmount, protocolParams.cvx),
            protocolParams.cvx
        );

        uint256 valueExtraToUsd = 0;

        IBaseRewardPool underlyingContract = IBaseRewardPool(creditManager.adapterToContract(convexAdapter));
        for (uint256 i = 0; i < underlyingContract.extraRewardsLength(); ++i) {
            IRewards rewardsContract = IRewards(underlyingContract.extraRewards(i));
            uint256 valueEarned = rewardsContract.earned(creditAccount);
            valueExtraToUsd += oracle.convertToUSD(valueEarned, rewardsContract.rewardToken());
        }

        return oracle.convertFromUSD(valueCrvToUsd + valueCvxToUsd + valueExtraToUsd, primaryToken);
    }

    function calculateDesiredTotalValue(
        address creditAccount,
        address vaultGovernance,
        uint256 marginalFactorD9
    ) external view returns (uint256 expectedAllAssetsValue, uint256 currentAllAssetsValue) {
        (currentAllAssetsValue, ) = creditFacade.calcTotalValue(creditAccount);
        currentAllAssetsValue += calculateClaimableRewards(creditAccount, vaultGovernance);

        (, , uint256 borrowAmountWithInterestAndFees) = creditManager.calcCreditAccountAccruedInterest(creditAccount);

        uint256 currentTvl = currentAllAssetsValue - borrowAmountWithInterestAndFees;
        expectedAllAssetsValue = FullMath.mulDiv(currentTvl, marginalFactorD9, D9);
    }

    function calcConvexTokensToWithdraw(
        uint256 desiredValueNominatedUnderlying,
        address creditAccount,
        address convexOutputToken
    ) public view returns (uint256) {
        uint256 currentConvexTokensAmount = IERC20(convexOutputToken).balanceOf(creditAccount);

        IPriceOracleV2 oracle = IPriceOracleV2(creditManager.priceOracle());
        uint256 valueInConvexNominatedUnderlying = oracle.convert(
            currentConvexTokensAmount,
            convexOutputToken,
            primaryToken
        );

        if (desiredValueNominatedUnderlying >= valueInConvexNominatedUnderlying) {
            return currentConvexTokensAmount;
        }

        return
            FullMath.mulDiv(
                currentConvexTokensAmount,
                desiredValueNominatedUnderlying,
                valueInConvexNominatedUnderlying
            );
    }

    function calcRateRAY(address tokenFrom, address tokenTo) public view returns (uint256) {
        IPriceOracleV2 oracle = IPriceOracleV2(creditManager.priceOracle());
        return oracle.convert(D27, tokenFrom, tokenTo);
    }

    function calculateAmountInMaximum(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 maxSlippageD9
    ) public view returns (uint256) {
        uint256 rateRAY = calcRateRAY(toToken, fromToken);
        uint256 amountInExpected = FullMath.mulDiv(amount, rateRAY, D27) + 1;
        return FullMath.mulDiv(amountInExpected, D9 + maxSlippageD9, D9) + 1;
    }

    function createUniswapMulticall(
        address tokenFrom,
        address tokenTo,
        uint256 fee,
        address adapter,
        uint256 slippage
    ) public view returns (MultiCall memory) {
        uint256 rateRAY = calcRateRAY(tokenFrom, tokenTo);

        IUniswapV3Adapter.ExactAllInputParams memory params = IUniswapV3Adapter.ExactAllInputParams({
            path: abi.encodePacked(tokenFrom, uint24(fee), tokenTo),
            deadline: block.timestamp + 1,
            rateMinRAY: FullMath.mulDiv(rateRAY, D9 - slippage, D9)
        });

        return
            MultiCall({
                target: adapter,
                callData: abi.encodeWithSelector(IUniswapV3Adapter.exactAllInput.selector, params)
            });
    }

    function checkNecessaryDepositExchange(
        uint256 expectedMaximalDepositTokenValueNominatedUnderlying,
        address vaultGovernance,
        address creditAccount
    ) public {
        require(msg.sender == address(gearboxVault), ExceptionsLibrary.FORBIDDEN);

        address depositToken_ = depositToken;
        address primaryToken_ = primaryToken;

        if (depositToken_ == primaryToken_) {
            return;
        }

        uint256 currentDepositTokenAmount = IERC20(depositToken_).balanceOf(creditAccount);
        IPriceOracleV2 oracle = IPriceOracleV2(creditManager.priceOracle());

        uint256 currentValueDepositTokenNominatedUnderlying = oracle.convert(
            currentDepositTokenAmount,
            depositToken_,
            primaryToken_
        );

        if (currentValueDepositTokenNominatedUnderlying > expectedMaximalDepositTokenValueNominatedUnderlying) {
            uint256 toSwap = FullMath.mulDiv(
                currentDepositTokenAmount,
                currentValueDepositTokenNominatedUnderlying - expectedMaximalDepositTokenValueNominatedUnderlying,
                currentValueDepositTokenNominatedUnderlying
            );
            swapExactInput(depositToken_, primaryToken_, toSwap, vaultGovernance, creditAccount);
        }
    }

    function claimRewards(
        address vaultGovernance,
        address creditAccount,
        address convexOutputToken
    ) public {
        IGearboxVault gearboxVault_ = gearboxVault;
        address primaryToken_ = primaryToken;

        require(msg.sender == address(gearboxVault_), ExceptionsLibrary.FORBIDDEN);

        uint256 balance = IERC20(convexOutputToken).balanceOf(creditAccount);
        if (balance == 0) {
            return;
        }

        IBaseRewardPool underlyingContract = IBaseRewardPool(creditManager.adapterToContract(convexAdapter));

        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams = IGearboxVaultGovernance(vaultGovernance)
            .delayedProtocolParams();

        IGearboxVaultGovernance.StrategyParams memory strategyParams = IGearboxVaultGovernance(vaultGovernance)
            .strategyParams(vaultNft);

        IGearboxVaultGovernance.DelayedProtocolPerVaultParams memory vaultParams = IGearboxVaultGovernance(
            vaultGovernance
        ).delayedProtocolPerVaultParams(vaultNft);

        address weth = creditManager.wethAddress();

        uint256 callsCount = 4;
        if (weth == primaryToken_ || weth == depositToken) {
            callsCount -= 1;
        }

        for (uint256 i = 0; i < underlyingContract.extraRewardsLength(); ++i) {
            address rewardToken = address(IRewards(underlyingContract.extraRewards(i)).rewardToken());
            if (rewardToken != depositToken && rewardToken != primaryToken_ && rewardToken != weth) {
                callsCount += 1;
            }
        }

        MultiCall[] memory calls = new MultiCall[](callsCount);

        calls[0] = MultiCall({ // taking crv and cvx
            target: convexAdapter,
            callData: abi.encodeWithSelector(GET_REWARD_SELECTOR, creditAccount, true)
        });

        calls[1] = createUniswapMulticall(
            protocolParams.crv,
            weth,
            10000,
            vaultParams.univ3Adapter,
            protocolParams.maxSmallPoolsSlippageD9
        );

        calls[2] = createUniswapMulticall(
            protocolParams.cvx,
            weth,
            10000,
            vaultParams.univ3Adapter,
            protocolParams.maxSmallPoolsSlippageD9
        );

        uint256 pointer = 3;

        for (uint256 i = 2; i < 2 + underlyingContract.extraRewardsLength(); ++i) {
            address rewardToken = address(IRewards(underlyingContract.extraRewards(i - 2)).rewardToken());
            if (rewardToken != depositToken && rewardToken != primaryToken_ && rewardToken != weth) {
                calls[pointer] = createUniswapMulticall(
                    rewardToken,
                    weth,
                    10000,
                    vaultParams.univ3Adapter,
                    protocolParams.maxSmallPoolsSlippageD9
                );
                pointer += 1;
            }
        }

        if (weth != primaryToken_ && weth != depositToken) {
            calls[callsCount - 1] = createUniswapMulticall(
                weth,
                primaryToken_,
                strategyParams.largePoolFeeUsed,
                vaultParams.univ3Adapter,
                protocolParams.maxSlippageD9
            );
        }

        gearboxVault_.multicall(calls);
    }

    function withdrawFromConvex(
        uint256 amount,
        address vaultGovernance,
        int128 primaryIndex
    ) public {
        if (amount == 0) {
            return;
        }

        IGearboxVault gearboxVault_ = gearboxVault;

        require(msg.sender == address(gearboxVault_), ExceptionsLibrary.FORBIDDEN);

        address curveLpToken = ICurveV1Adapter(curveAdapter).lp_token();
        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams = IGearboxVaultGovernance(vaultGovernance)
            .delayedProtocolParams();

        if (!is3crv) {
            uint256 rateRAY = calcRateRAY(curveLpToken, primaryToken);

            MultiCall[] memory calls = new MultiCall[](2);

            calls[0] = MultiCall({
                target: convexAdapter,
                callData: abi.encodeWithSelector(IBaseRewardPool.withdrawAndUnwrap.selector, amount, false)
            });

            calls[1] = MultiCall({
                target: curveAdapter,
                callData: abi.encodeWithSelector(
                    ICurveV1Adapter.remove_all_liquidity_one_coin.selector,
                    primaryIndex,
                    FullMath.mulDiv(rateRAY, D9 - protocolParams.maxCurveSlippageD9, D9)
                )
            });

            gearboxVault_.multicall(calls);
        } else {
            ICurveV1Adapter crv3Adapter = ICurveV1Adapter(creditManager.contractToAdapter(protocolParams.crv3Pool));
            address crv3Token = crv3Adapter.lp_token();

            uint256 rateRAY1 = calcRateRAY(curveLpToken, crv3Token);
            uint256 rateRAY2 = calcRateRAY(crv3Token, primaryToken);

            MultiCall[] memory calls = new MultiCall[](3);

            calls[0] = MultiCall({
                target: convexAdapter,
                callData: abi.encodeWithSelector(IBaseRewardPool.withdrawAndUnwrap.selector, amount, false)
            });

            calls[1] = MultiCall({
                target: curveAdapter,
                callData: abi.encodeWithSelector(
                    ICurveV1Adapter.remove_all_liquidity_one_coin.selector,
                    crv3Index,
                    FullMath.mulDiv(rateRAY1, D9 - protocolParams.maxCurveSlippageD9, D9)
                )
            });

            calls[2] = MultiCall({
                target: address(crv3Adapter),
                callData: abi.encodeWithSelector(
                    ICurveV1Adapter.remove_all_liquidity_one_coin.selector,
                    primaryIndex,
                    FullMath.mulDiv(rateRAY2, D9 - protocolParams.maxCurveSlippageD9, D9)
                )
            });

            gearboxVault_.multicall(calls);
        }
    }

    function depositToConvex(
        MultiCall memory debtManagementCall,
        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams,
        uint256 poolId,
        int128 primaryIndex
    ) public {
        IGearboxVault gearboxVault_ = gearboxVault;

        require(msg.sender == address(gearboxVault_), ExceptionsLibrary.FORBIDDEN);
        address curveLpToken = ICurveV1Adapter(curveAdapter).lp_token();

        if (!is3crv) {
            uint256 rateRAY = calcRateRAY(primaryToken, curveLpToken);

            MultiCall[] memory calls = new MultiCall[](3);

            calls[0] = debtManagementCall;

            calls[1] = MultiCall({
                target: curveAdapter,
                callData: abi.encodeWithSelector(
                    ICurveV1Adapter.add_all_liquidity_one_coin.selector,
                    primaryIndex,
                    FullMath.mulDiv(rateRAY, D9 - protocolParams.maxCurveSlippageD9, D9)
                )
            });

            calls[2] = MultiCall({
                target: creditManager.contractToAdapter(IConvexV1BaseRewardPoolAdapter(convexAdapter).operator()),
                callData: abi.encodeWithSelector(IBooster.depositAll.selector, poolId, true)
            });

            gearboxVault_.multicall(calls);
        } else {
            ICurveV1Adapter crv3Adapter = ICurveV1Adapter(creditManager.contractToAdapter(protocolParams.crv3Pool));
            address crv3Token = crv3Adapter.lp_token();

            uint256 rateRAY1 = calcRateRAY(primaryToken, crv3Token);
            uint256 rateRAY2 = calcRateRAY(crv3Token, curveLpToken);

            MultiCall[] memory calls = new MultiCall[](4);

            calls[0] = debtManagementCall;

            calls[1] = MultiCall({
                target: address(crv3Adapter),
                callData: abi.encodeWithSelector(
                    ICurveV1Adapter.add_all_liquidity_one_coin.selector,
                    primaryIndex,
                    FullMath.mulDiv(rateRAY1, D9 - protocolParams.maxCurveSlippageD9, D9)
                )
            });

            calls[2] = MultiCall({
                target: curveAdapter,
                callData: abi.encodeWithSelector(
                    ICurveV1Adapter.add_all_liquidity_one_coin.selector,
                    crv3Index,
                    FullMath.mulDiv(rateRAY2, D9 - protocolParams.maxCurveSlippageD9, D9)
                )
            });

            calls[3] = MultiCall({
                target: creditManager.contractToAdapter(IConvexV1BaseRewardPoolAdapter(convexAdapter).operator()),
                callData: abi.encodeWithSelector(IBooster.depositAll.selector, poolId, true)
            });

            gearboxVault_.multicall(calls);
        }
    }

    function adjustPosition(
        uint256 expectedAllAssetsValue,
        uint256 currentAllAssetsValue,
        address vaultGovernance,
        uint256 marginalFactorD9,
        int128 primaryIndex,
        uint256 poolId,
        address convexOutputToken,
        address creditAccount_
    ) external {
        require(msg.sender == address(gearboxVault), ExceptionsLibrary.FORBIDDEN);

        claimRewards(vaultGovernance, creditAccount_, convexOutputToken);

        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams = IGearboxVaultGovernance(vaultGovernance)
            .delayedProtocolParams();
        ICreditFacade creditFacade_ = creditFacade;

        checkNecessaryDepositExchange(
            FullMath.mulDiv(expectedAllAssetsValue, D9, marginalFactorD9),
            vaultGovernance,
            creditAccount_
        );

        if (expectedAllAssetsValue >= currentAllAssetsValue) {
            uint256 delta = expectedAllAssetsValue - currentAllAssetsValue;

            MultiCall memory increaseDebtCall = MultiCall({
                target: address(creditFacade_),
                callData: abi.encodeWithSelector(ICreditFacade.increaseDebt.selector, delta)
            });

            depositToConvex(increaseDebtCall, protocolParams, poolId, primaryIndex);
        } else {
            uint256 delta = currentAllAssetsValue - expectedAllAssetsValue;

            uint256 currentPrimaryTokenAmount = IERC20(primaryToken).balanceOf(creditAccount_);

            if (currentPrimaryTokenAmount >= delta) {
                MultiCall memory decreaseDebtCall = MultiCall({
                    target: address(creditFacade_),
                    callData: abi.encodeWithSelector(ICreditFacade.decreaseDebt.selector, delta)
                });

                depositToConvex(decreaseDebtCall, protocolParams, poolId, primaryIndex);
            } else {
                uint256 convexAmountToWithdraw = calcConvexTokensToWithdraw(
                    delta - currentPrimaryTokenAmount,
                    creditAccount_,
                    convexOutputToken
                );
                withdrawFromConvex(convexAmountToWithdraw, vaultGovernance, primaryIndex);

                currentPrimaryTokenAmount = IERC20(primaryToken).balanceOf(creditAccount_);
                if (currentPrimaryTokenAmount < delta) {
                    delta = currentPrimaryTokenAmount;
                }

                MultiCall[] memory decreaseCall = new MultiCall[](1);
                decreaseCall[0] = MultiCall({
                    target: address(creditFacade_),
                    callData: abi.encodeWithSelector(ICreditFacade.decreaseDebt.selector, delta)
                });

                gearboxVault.multicall(decreaseCall);
            }
        }

        emit PositionAdjusted(tx.origin, msg.sender, expectedAllAssetsValue);
    }

    function swapExactOutput(
        address fromToken,
        address toToken,
        uint256 amount,
        address vaultGovernance,
        address creditAccount
    ) external {
        require(msg.sender == address(gearboxVault), ExceptionsLibrary.FORBIDDEN);

        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams = IGearboxVaultGovernance(vaultGovernance)
            .delayedProtocolParams();

        IGearboxVaultGovernance.StrategyParams memory strategyParams = IGearboxVaultGovernance(vaultGovernance)
            .strategyParams(vaultNft);

        IGearboxVaultGovernance.DelayedProtocolPerVaultParams memory vaultParams = IGearboxVaultGovernance(
            vaultGovernance
        ).delayedProtocolPerVaultParams(vaultNft);

        uint256 amountInMaximum = calculateAmountInMaximum(fromToken, toToken, amount, protocolParams.maxSlippageD9);

        ISwapRouter.ExactOutputParams memory uniParams = ISwapRouter.ExactOutputParams({
            path: abi.encodePacked(toToken, strategyParams.largePoolFeeUsed, fromToken), // exactOutput arguments are in reversed order
            recipient: creditAccount,
            deadline: block.timestamp + 1,
            amountOut: amount,
            amountInMaximum: amountInMaximum
        });

        MultiCall[] memory calls = new MultiCall[](1);

        calls[0] = MultiCall({
            target: vaultParams.univ3Adapter,
            callData: abi.encodeWithSelector(ISwapRouter.exactOutput.selector, uniParams)
        });

        gearboxVault.multicall(calls);
    }

    function swapExactInput(
        address fromToken,
        address toToken,
        uint256 amount,
        address vaultGovernance,
        address creditAccount
    ) public {
        require(msg.sender == address(gearboxVault), ExceptionsLibrary.FORBIDDEN);

        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams = IGearboxVaultGovernance(vaultGovernance)
            .delayedProtocolParams();

        IGearboxVaultGovernance.StrategyParams memory strategyParams = IGearboxVaultGovernance(vaultGovernance)
            .strategyParams(vaultNft);

        IGearboxVaultGovernance.DelayedProtocolPerVaultParams memory vaultParams = IGearboxVaultGovernance(
            vaultGovernance
        ).delayedProtocolPerVaultParams(vaultNft);

        MultiCall[] memory calls = new MultiCall[](1);

        IPriceOracleV2 oracle = IPriceOracleV2(creditManager.priceOracle());
        uint256 expectedOutput = oracle.convert(amount, fromToken, toToken);

        ISwapRouter.ExactInputParams memory inputParams = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(fromToken, strategyParams.largePoolFeeUsed, toToken),
            recipient: creditAccount,
            deadline: block.timestamp + 1,
            amountIn: amount,
            amountOutMinimum: FullMath.mulDiv(expectedOutput, D9 - protocolParams.maxSlippageD9, D9)
        });

        calls[0] = MultiCall({ // swap deposit to primary token
            target: vaultParams.univ3Adapter,
            callData: abi.encodeWithSelector(ISwapRouter.exactInput.selector, inputParams)
        });

        gearboxVault.multicall(calls);
    }

    function openCreditAccount(address vaultGovernance, uint256 marginalFactorD9) external {
        IGearboxVault gearboxVault_ = gearboxVault;

        require(msg.sender == address(gearboxVault_), ExceptionsLibrary.FORBIDDEN);

        ICreditFacade creditFacade_ = creditFacade;
        address primaryToken_ = primaryToken;
        address depositToken_ = depositToken;

        uint256 minimalNecessaryAmount;

        {
            (uint256 minBorrowingLimit, ) = creditFacade_.limits();
            minimalNecessaryAmount = FullMath.mulDiv(minBorrowingLimit, D9, (marginalFactorD9 - D9)) + 1;
        }

        uint256 currentPrimaryTokenAmount = IERC20(primaryToken_).balanceOf(address(gearboxVault_));

        IGearboxVaultGovernance vaultGovernance_ = IGearboxVaultGovernance(vaultGovernance);
        uint256 vaultNft_ = vaultNft;

        IGearboxVaultGovernance.DelayedProtocolParams memory protocolParams = vaultGovernance_.delayedProtocolParams();
        IGearboxVaultGovernance.StrategyParams memory strategyParams = vaultGovernance_.strategyParams(vaultNft_);
        IGearboxVaultGovernance.DelayedProtocolPerVaultParams memory vaultParams = vaultGovernance_
            .delayedProtocolPerVaultParams(vaultNft_);

        if (depositToken_ != primaryToken_ && currentPrimaryTokenAmount < minimalNecessaryAmount) {
            ISwapRouter router = ISwapRouter(protocolParams.uniswapRouter);
            uint256 amountInMaximum = calculateAmountInMaximum(
                depositToken_,
                primaryToken_,
                minimalNecessaryAmount - currentPrimaryTokenAmount,
                protocolParams.maxSlippageD9
            );
            require(IERC20(depositToken_).balanceOf(address(gearboxVault_)) >= amountInMaximum, ExceptionsLibrary.INVARIANT);

            ISwapRouter.ExactOutputParams memory uniParams = ISwapRouter.ExactOutputParams({
                path: abi.encodePacked(primaryToken_, strategyParams.largePoolFeeUsed, depositToken_), // exactOutput arguments are in reversed order
                recipient: address(gearboxVault_),
                deadline: block.timestamp + 1,
                amountOut: minimalNecessaryAmount - currentPrimaryTokenAmount,
                amountInMaximum: amountInMaximum
            });

            gearboxVault_.swapExactOutput(router, uniParams, depositToken_, amountInMaximum);

            currentPrimaryTokenAmount = IERC20(primaryToken_).balanceOf(address(gearboxVault_));
        }

        require(currentPrimaryTokenAmount >= minimalNecessaryAmount, ExceptionsLibrary.LIMIT_UNDERFLOW);
        gearboxVault_.openCreditAccountInManager(currentPrimaryTokenAmount, vaultParams.referralCode);
        emit CreditAccountOpened(tx.origin, msg.sender, creditManager.creditAccounts(address(gearboxVault_)));
    }

    /// @notice Emitted when a credit account linked to this vault is opened in Gearbox
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param creditAccount Address of the opened credit account
    event CreditAccountOpened(address indexed origin, address indexed sender, address creditAccount);

    /// @notice Emitted when an adjusment of the position made in Gearbox
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param newTotalAssetsValue New value of all assets (debt + real assets) of the vault
    event PositionAdjusted(address indexed origin, address indexed sender, uint256 newTotalAssetsValue);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./IntegrationVault.sol";
import "../utils/GearboxHelper.sol";
import "../interfaces/IDegenDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GearboxVault is IGearboxVault, IntegrationVault {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant D9 = 10**9;
    uint256 public constant D7 = 10**7;

    bytes32[] private _merkleProof;

    EnumerableSet.UintSet private _poolsAllowList;

    /// @inheritdoc IGearboxVault
    GearboxHelper public helper;

    /// @inheritdoc IGearboxVault
    ICreditFacade public creditFacade;

    /// @inheritdoc IGearboxVault
    ICreditManagerV2 public creditManager;

    /// @inheritdoc IGearboxVault
    address public primaryToken;
    /// @inheritdoc IGearboxVault
    address public depositToken;

    /// @inheritdoc IGearboxVault
    int128 public primaryIndex;
    /// @inheritdoc IGearboxVault
    uint256 public poolId;
    /// @inheritdoc IGearboxVault
    address public convexOutputToken;

    /// @inheritdoc IGearboxVault
    uint256 public marginalFactorD9;

    /// @inheritdoc IGearboxVault
    uint256 public merkleIndex;

    /// @inheritdoc IGearboxVault
    uint256 public merkleTotalAmount;

    // -------------------  EXTERNAL, VIEW  -------------------

    function approvedPools() external view returns (uint256[] memory) {
        return _poolsAllowList.values();
    }

    /// @inheritdoc IVault
    function tvl() public view override returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts) {
        uint256 amount = helper.calcTvl(getCreditAccount(), address(_vaultGovernance));
        minTokenAmounts = new uint256[](1);

        minTokenAmounts[0] = amount;
        maxTokenAmounts = minTokenAmounts;
    }

    /// @inheritdoc IntegrationVault
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, IntegrationVault) returns (bool) {
        return IntegrationVault.supportsInterface(interfaceId) || interfaceId == type(IGearboxVault).interfaceId;
    }

    /// @inheritdoc IGearboxVault
    function getCreditAccount() public view returns (address) {
        return creditManager.creditAccounts(address(this));
    }

    /// @inheritdoc IGearboxVault
    function getAllAssetsOnCreditAccountValue() external view returns (uint256 currentAllAssetsValue) {
        address creditAccount = getCreditAccount();
        if (creditAccount == address(0)) {
            return 0;
        }
        (currentAllAssetsValue, ) = creditFacade.calcTotalValue(creditAccount);
    }

    /// @inheritdoc IGearboxVault
    function getClaimableRewardsValue() external view returns (uint256) {
        address creditAccount = getCreditAccount();
        if (creditAccount == address(0)) {
            return 0;
        }
        return helper.calculateClaimableRewards(creditAccount, address(_vaultGovernance));
    }

    function getMerkleProof() external view returns (bytes32[] memory) {
        return _merkleProof;
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @inheritdoc IGearboxVault
    function addPoolsToAllowList(uint256[] calldata pools) external {
        require(_isApprovedOrOwner(msg.sender), ExceptionsLibrary.FORBIDDEN);
        for (uint256 i = 0; i < pools.length; i++) {
            _poolsAllowList.add(pools[i]);
        }
    }

    /// @inheritdoc IGearboxVault
    function removePoolsFromAllowlist(uint256[] calldata pools) external {
        require(_isApprovedOrOwner(msg.sender), ExceptionsLibrary.FORBIDDEN);
        for (uint256 i = 0; i < pools.length; i++) {
            _poolsAllowList.remove(pools[i]);
        }
    }

    /// @inheritdoc IGearboxVault
    function initialize(
        uint256 nft_,
        address[] memory vaultTokens_,
        address helper_
    ) external {
        require(vaultTokens_.length == 1, ExceptionsLibrary.INVALID_LENGTH);

        _initialize(vaultTokens_, nft_);

        IGearboxVaultGovernance.DelayedProtocolPerVaultParams memory params = IGearboxVaultGovernance(
            address(_vaultGovernance)
        ).delayedProtocolPerVaultParams(nft_);
        primaryToken = params.primaryToken;
        depositToken = vaultTokens_[0];
        marginalFactorD9 = params.initialMarginalValueD9;

        creditFacade = ICreditFacade(params.facade);
        creditManager = ICreditManagerV2(creditFacade.creditManager());

        helper = GearboxHelper(helper_);
        helper.setParameters(creditFacade, creditManager, params.primaryToken, vaultTokens_[0], _nft);
    }

    /// @inheritdoc IGearboxVault
    function openCreditAccount(address curveAdapter, address convexAdapter) external {
        require(_isApprovedOrOwner(msg.sender), ExceptionsLibrary.FORBIDDEN);
        address creditAccount = getCreditAccount();
        require(creditAccount == address(0), ExceptionsLibrary.DUPLICATE);

        address degenNft = creditFacade.degenNFT();

        if (degenNft != address(0)) {
            IDegenNFT degenContract = IDegenNFT(degenNft);
            IDegenDistributor distributor = IDegenDistributor(degenContract.minter());
            if (distributor.claimed(address(this)) < merkleTotalAmount) {
                distributor.claim(merkleIndex, address(this), merkleTotalAmount, _merkleProof);
            }
        }

        helper.setAdapters(curveAdapter, convexAdapter);
        (primaryIndex, convexOutputToken, poolId) = helper.verifyInstances(address(_vaultGovernance));
        require(_poolsAllowList.contains(poolId), ExceptionsLibrary.FORBIDDEN);
        helper.openCreditAccount(address(_vaultGovernance), marginalFactorD9);

        if (depositToken != primaryToken) {
            creditFacade.enableToken(depositToken);
            _addDepositTokenAsCollateral();
        }
    }

    /// @inheritdoc IGearboxVault
    function closeCreditAccount() external {
        GearboxHelper helper_ = helper;

        IVaultRegistry registry = _vaultGovernance.internalParams().registry;
        require(registry.ownerOf(_nft) == msg.sender, ExceptionsLibrary.FORBIDDEN);

        address depositToken_ = depositToken;
        address primaryToken_ = primaryToken;
        address creditAccount_ = getCreditAccount();

        if (creditAccount_ == address(0)) {
            return;
        }

        helper_.claimRewards(address(_vaultGovernance), creditAccount_, convexOutputToken);
        helper_.withdrawFromConvex(
            IERC20(convexOutputToken).balanceOf(creditAccount_),
            address(_vaultGovernance),
            primaryIndex
        );

        (, , uint256 debtAmount) = creditManager.calcCreditAccountAccruedInterest(creditAccount_);
        uint256 underlyingBalance = IERC20(primaryToken_).balanceOf(creditAccount_);

        if (underlyingBalance < debtAmount + 1) {
            helper_.swapExactOutput(
                depositToken_,
                primaryToken_,
                debtAmount + 1 - underlyingBalance,
                address(_vaultGovernance),
                creditAccount_
            );
        } else if (primaryToken_ != depositToken_) {
            helper_.swapExactInput(
                primaryToken_,
                depositToken_,
                underlyingBalance - (debtAmount + 1),
                address(_vaultGovernance),
                creditAccount_
            );
        }

        MultiCall[] memory noCalls = new MultiCall[](0);
        creditFacade.closeCreditAccount(address(this), 0, false, noCalls);
    }

    /// @inheritdoc IGearboxVault
    function adjustPosition() public {
        require(_isApprovedOrOwner(msg.sender), ExceptionsLibrary.FORBIDDEN);
        address creditAccount = getCreditAccount();

        if (creditAccount == address(0)) {
            return;
        }

        uint256 marginalFactorD9_ = marginalFactorD9;
        GearboxHelper helper_ = helper;

        (uint256 expectedAllAssetsValue, uint256 currentAllAssetsValue) = helper_.calculateDesiredTotalValue(
            creditAccount,
            address(_vaultGovernance),
            marginalFactorD9_
        );
        helper_.adjustPosition(
            expectedAllAssetsValue,
            currentAllAssetsValue,
            address(_vaultGovernance),
            marginalFactorD9_,
            primaryIndex,
            poolId,
            convexOutputToken,
            creditAccount
        );
    }

    /// @inheritdoc IGearboxVault
    function setMerkleParameters(
        uint256 merkleIndex_,
        uint256 merkleTotalAmount_,
        bytes32[] memory merkleProof_
    ) public {
        require(_isApprovedOrOwner(msg.sender));
        merkleIndex = merkleIndex_;
        merkleTotalAmount = merkleTotalAmount_;
        _merkleProof = merkleProof_;
    }

    /// @inheritdoc IGearboxVault
    function updateTargetMarginalFactor(uint256 marginalFactorD9_) external {
        require(marginalFactorD9_ > D9, ExceptionsLibrary.INVALID_VALUE);

        marginalFactorD9 = marginalFactorD9_;
        adjustPosition();

        emit TargetMarginalFactorUpdated(tx.origin, msg.sender, marginalFactorD9_);
    }

    /// @inheritdoc IGearboxVault
    function multicall(MultiCall[] memory calls) external {
        require(msg.sender == address(helper), ExceptionsLibrary.FORBIDDEN);
        creditFacade.multicall(calls);
    }

    /// @inheritdoc IGearboxVault
    function swapExactOutput(
        ISwapRouter router,
        ISwapRouter.ExactOutputParams memory uniParams,
        address token,
        uint256 amount
    ) external {
        require(msg.sender == address(helper), ExceptionsLibrary.FORBIDDEN);
        IERC20(token).safeIncreaseAllowance(address(router), amount);
        router.exactOutput(uniParams);
        IERC20(token).safeApprove(address(router), 0);
    }

    /// @inheritdoc IGearboxVault
    function openCreditAccountInManager(uint256 currentPrimaryTokenAmount, uint16 referralCode) external {
        require(msg.sender == address(helper), ExceptionsLibrary.FORBIDDEN);

        address creditManagerAddress = address(creditManager);
        IERC20 primaryToken_ = IERC20(primaryToken);

        primaryToken_.safeIncreaseAllowance(creditManagerAddress, currentPrimaryTokenAmount);
        creditFacade.openCreditAccount(
            currentPrimaryTokenAmount,
            address(this),
            uint16((marginalFactorD9 - D9) / D7),
            referralCode
        );
        primaryToken_.safeApprove(creditManagerAddress, 0);
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _isReclaimForbidden(address) internal pure override returns (bool) {
        return false;
    }

    // -------------------  INTERNAL, MUTATING  -------------------

    function _push(uint256[] memory tokenAmounts, bytes memory) internal override returns (uint256[] memory) {
        require(tokenAmounts.length == 1, ExceptionsLibrary.INVALID_LENGTH);
        address creditAccount = getCreditAccount();

        if (creditAccount != address(0)) {
            _addDepositTokenAsCollateral();
        }

        return tokenAmounts;
    }

    function _pull(
        address to,
        uint256[] memory tokenAmounts,
        bytes memory
    ) internal override returns (uint256[] memory actualTokenAmounts) {
        require(tokenAmounts.length == 1, ExceptionsLibrary.INVALID_LENGTH);

        IERC20(depositToken).safeTransfer(to, tokenAmounts[0]);
        actualTokenAmounts = tokenAmounts;
    }

    /// @notice Deposits all deposit tokens which are on the address of the vault into the credit account
    function _addDepositTokenAsCollateral() internal {
        ICreditFacade creditFacade_ = creditFacade;
        MultiCall[] memory calls = new MultiCall[](1);
        address creditManagerAddress = address(creditManager);

        IERC20 token = IERC20(depositToken);
        uint256 amount = token.balanceOf(address(this));

        token.safeIncreaseAllowance(creditManagerAddress, amount);

        calls[0] = MultiCall({
            target: address(creditFacade_),
            callData: abi.encodeWithSelector(
                ICreditFacade.addCollateral.selector,
                address(this),
                address(token),
                amount
            )
        });

        creditFacade_.multicall(calls);
        token.safeApprove(creditManagerAddress, 0);
    }

    // --------------------------  EVENTS  --------------------------

    /// @notice Emitted when target marginal factor is updated
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param newMarginalFactorD9 New marginal factor
    event TargetMarginalFactorUpdated(address indexed origin, address indexed sender, uint256 newMarginalFactorD9);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/external/erc/IERC1271.sol";
import "../interfaces/vaults/IVaultRoot.sol";
import "../interfaces/vaults/IIntegrationVault.sol";
import "../interfaces/validators/IValidator.sol";
import "../libraries/CommonLibrary.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../libraries/PermissionIdsLibrary.sol";
import "./VaultGovernance.sol";
import "./Vault.sol";

/// @notice Abstract contract that has logic common for every Vault.
/// @dev Notes:
/// ### ERC-721
///
/// Each Vault should be registered in VaultRegistry and get corresponding VaultRegistry NFT.
///
/// ### Access control
///
/// `push` and `pull` methods are only allowed for owner / approved person of the NFT. However,
/// `pull` for approved person also checks that pull destination is another vault of the Vault System.
///
/// The semantics is: NFT owner owns all Vault liquidity, Approved person is liquidity manager.
/// ApprovedForAll person cannot do anything except ERC-721 token transfers.
///
/// Both NFT owner and approved person can call externalCall method which claims liquidity mining rewards (if any)
///
/// `reclaimTokens` for claiming rewards given by an underlying protocol to erc20Vault in order to sell them there
abstract contract IntegrationVault is IIntegrationVault, ReentrancyGuard, Vault {
    using SafeERC20 for IERC20;

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Vault) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            (interfaceId == type(IIntegrationVault).interfaceId) ||
            (interfaceId == type(IERC1271).interfaceId);
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @inheritdoc IIntegrationVault
    function push(
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) public nonReentrant returns (uint256[] memory actualTokenAmounts) {
        uint256 nft_ = _nft;
        require(nft_ != 0, ExceptionsLibrary.INIT);
        IVaultRegistry vaultRegistry = _vaultGovernance.internalParams().registry;
        IVault ownerVault = IVault(vaultRegistry.ownerOf(nft_)); // Also checks that the token exists
        uint256 ownerNft = vaultRegistry.nftForVault(address(ownerVault));
        require(ownerNft != 0, ExceptionsLibrary.NOT_FOUND); // require deposits only through Vault
        uint256[] memory pTokenAmounts = _validateAndProjectTokens(tokens, tokenAmounts);
        uint256[] memory pActualTokenAmounts = _push(pTokenAmounts, options);
        actualTokenAmounts = CommonLibrary.projectTokenAmounts(tokens, _vaultTokens, pActualTokenAmounts);
        emit Push(pActualTokenAmounts);
    }

    /// @inheritdoc IIntegrationVault
    function transferAndPush(
        address from,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts) {
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; ++i)
            if (tokenAmounts[i] != 0) {
                IERC20(tokens[i]).safeTransferFrom(from, address(this), tokenAmounts[i]);
            }

        actualTokenAmounts = push(tokens, tokenAmounts, options);
        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 leftover = actualTokenAmounts[i] < tokenAmounts[i] ? tokenAmounts[i] - actualTokenAmounts[i] : 0;
            if (leftover != 0) IERC20(tokens[i]).safeTransfer(from, leftover);
        }
    }

    /// @inheritdoc IIntegrationVault
    function pull(
        address to,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external nonReentrant returns (uint256[] memory actualTokenAmounts) {
        uint256 nft_ = _nft;
        require(nft_ != 0, ExceptionsLibrary.INIT);
        require(_isApprovedOrOwner(msg.sender), ExceptionsLibrary.FORBIDDEN); // Also checks that the token exists
        IVaultRegistry registry = _vaultGovernance.internalParams().registry;
        address owner = registry.ownerOf(nft_);
        IVaultRoot root = _root(registry, nft_, owner);
        if (owner != msg.sender) {
            address zeroVault = root.subvaultAt(0);
            if (zeroVault == address(this)) {
                // If we pull from zero vault
                require(
                    root.hasSubvault(registry.nftForVault(to)) && to != address(this),
                    ExceptionsLibrary.INVALID_TARGET
                );
            } else {
                // If we pull from other vault
                require(zeroVault == to, ExceptionsLibrary.INVALID_TARGET);
            }
        }
        uint256[] memory pTokenAmounts = _validateAndProjectTokens(tokens, tokenAmounts);
        uint256[] memory pActualTokenAmounts = _pull(to, pTokenAmounts, options);
        actualTokenAmounts = CommonLibrary.projectTokenAmounts(tokens, _vaultTokens, pActualTokenAmounts);
        emit Pull(to, actualTokenAmounts);
    }

    /// @inheritdoc IIntegrationVault
    function reclaimTokens(address[] memory tokens)
        external
        virtual
        nonReentrant
        returns (uint256[] memory actualTokenAmounts)
    {
        uint256 nft_ = _nft;
        require(nft_ != 0, ExceptionsLibrary.INIT);
        IVaultGovernance.InternalParams memory params = _vaultGovernance.internalParams();
        IProtocolGovernance governance = params.protocolGovernance;
        IVaultRegistry registry = params.registry;
        address owner = registry.ownerOf(nft_);
        address to = _root(registry, nft_, owner).subvaultAt(0);
        actualTokenAmounts = new uint256[](tokens.length);
        if (to == address(this)) {
            return actualTokenAmounts;
        }
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (
                _isReclaimForbidden(tokens[i]) ||
                !governance.hasPermission(tokens[i], PermissionIdsLibrary.ERC20_TRANSFER)
            ) {
                continue;
            }
            IERC20 token = IERC20(tokens[i]);
            actualTokenAmounts[i] = token.balanceOf(address(this));

            token.safeTransfer(to, actualTokenAmounts[i]);
        }
        emit ReclaimTokens(to, tokens, actualTokenAmounts);
    }

    /// @inheritdoc IERC1271
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue) {
        IVaultGovernance.InternalParams memory params = _vaultGovernance.internalParams();
        IVaultRegistry registry = params.registry;
        IProtocolGovernance protocolGovernance = params.protocolGovernance;
        uint256 nft_ = _nft;
        if (nft_ == 0) {
            return 0xffffffff;
        }
        address strategy = registry.getApproved(nft_);
        if (!protocolGovernance.hasPermission(strategy, PermissionIdsLibrary.TRUSTED_STRATEGY)) {
            return 0xffffffff;
        }
        uint32 size;
        assembly {
            size := extcodesize(strategy)
        }
        if (size > 0) {
            if (IERC165(strategy).supportsInterface(type(IERC1271).interfaceId)) {
                return IERC1271(strategy).isValidSignature(_hash, _signature);
            } else {
                return 0xffffffff;
            }
        }
        if (CommonLibrary.recoverSigner(_hash, _signature) == strategy) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
    }

    /// @inheritdoc IIntegrationVault
    function externalCall(
        address to,
        bytes4 selector,
        bytes calldata data
    ) external payable nonReentrant returns (bytes memory result) {
        require(_nft != 0, ExceptionsLibrary.INIT);
        require(_isApprovedOrOwner(msg.sender), ExceptionsLibrary.FORBIDDEN);
        IProtocolGovernance protocolGovernance = _vaultGovernance.internalParams().protocolGovernance;
        IValidator validator = IValidator(protocolGovernance.validators(to));
        require(address(validator) != address(0), ExceptionsLibrary.FORBIDDEN);
        validator.validate(msg.sender, to, msg.value, selector, data);
        (bool res, bytes memory returndata) = to.call{value: msg.value}(abi.encodePacked(selector, data));
        if (!res) {
            assembly {
                let returndata_size := mload(returndata)
                // Bubble up revert reason
                revert(add(32, returndata), returndata_size)
            }
        }
        result = returndata;
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _validateAndProjectTokens(address[] memory tokens, uint256[] memory tokenAmounts)
        internal
        view
        returns (uint256[] memory pTokenAmounts)
    {
        require(CommonLibrary.isSortedAndUnique(tokens), ExceptionsLibrary.INVARIANT);
        require(tokens.length == tokenAmounts.length, ExceptionsLibrary.INVALID_VALUE);
        pTokenAmounts = CommonLibrary.projectTokenAmounts(_vaultTokens, tokens, tokenAmounts);
    }

    function _root(
        IVaultRegistry registry,
        uint256 thisNft,
        address thisOwner
    ) internal view returns (IVaultRoot) {
        uint256 thisOwnerNft = registry.nftForVault(thisOwner);
        require((thisNft != 0) && (thisOwnerNft != 0), ExceptionsLibrary.INIT);

        return IVaultRoot(thisOwner);
    }

    function _isApprovedOrOwner(address sender) internal view returns (bool) {
        IVaultRegistry registry = _vaultGovernance.internalParams().registry;
        uint256 nft_ = _nft;
        if (nft_ == 0) {
            return false;
        }
        return registry.getApproved(nft_) == sender || registry.ownerOf(nft_) == sender;
    }

    /// @notice check if token is forbidden to transfer under reclaim
    /// @dev it is done in order to prevent reclaiming internal protocol tokens
    ///      for example to prevent YEarn tokens to reclaimed
    ///      if our vault is managing tokens, depositing it in YEarn
    /// @param token The address of token to check
    /// @return if token is forbidden
    function _isReclaimForbidden(address token) internal view virtual returns (bool);

    // -------------------  INTERNAL, MUTATING  -------------------

    /// Guaranteed to have exact signature matchinn vault tokens
    function _push(uint256[] memory tokenAmounts, bytes memory options)
        internal
        virtual
        returns (uint256[] memory actualTokenAmounts);

    /// Guaranteed to have exact signature matchinn vault tokens
    function _pull(
        address to,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) internal virtual returns (uint256[] memory actualTokenAmounts);

    // --------------------------  EVENTS  --------------------------

    /// @notice Emitted on successful push
    /// @param tokenAmounts The amounts of tokens to pushed
    event Push(uint256[] tokenAmounts);

    /// @notice Emitted on successful pull
    /// @param to The target address for pulled tokens
    /// @param tokenAmounts The amounts of tokens to pull
    event Pull(address to, uint256[] tokenAmounts);

    /// @notice Emitted when tokens are reclaimed
    /// @param to The target address for pulled tokens
    /// @param tokens ERC20 tokens to be reclaimed
    /// @param tokenAmounts The amounts of reclaims
    event ReclaimTokens(address to, address[] tokens, uint256[] tokenAmounts);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../libraries/CommonLibrary.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/vaults/IVault.sol";
import "./VaultGovernance.sol";

/// @notice Abstract contract that has logic common for every Vault.
/// @dev Notes:
/// ### ERC-721
///
/// Each Vault should be registered in VaultRegistry and get corresponding VaultRegistry NFT.
///
/// ### Access control
///
/// `push` and `pull` methods are only allowed for owner / approved person of the NFT. However,
/// `pull` for approved person also checks that pull destination is another vault of the Vault System.
///
/// The semantics is: NFT owner owns all Vault liquidity, Approved person is liquidity manager.
/// ApprovedForAll person cannot do anything except ERC-721 token transfers.
///
/// Both NFT owner and approved person can call externalCall method which claims liquidity mining rewards (if any)
///
/// `reclaimTokens` for mistakenly transfered tokens (not included into vaultTokens) additionally can be withdrawn by
/// the protocol admin
abstract contract Vault is IVault, ERC165 {
    using SafeERC20 for IERC20;

    IVaultGovernance internal _vaultGovernance;
    address[] internal _vaultTokens;
    mapping(address => int256) internal _vaultTokensIndex;
    uint256 internal _nft;
    uint256[] internal _pullExistentials;

    constructor() {
        // lock initialization and thus all mutations for any deployed Vault
        _nft = type(uint256).max;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @inheritdoc IVault
    function initialized() external view returns (bool) {
        return _nft != 0;
    }

    /// @inheritdoc IVault
    function isVaultToken(address token) public view returns (bool) {
        return _vaultTokensIndex[token] != 0;
    }

    /// @inheritdoc IVault
    function vaultGovernance() external view returns (IVaultGovernance) {
        return _vaultGovernance;
    }

    /// @inheritdoc IVault
    function vaultTokens() external view returns (address[] memory) {
        return _vaultTokens;
    }

    /// @inheritdoc IVault
    function nft() external view returns (uint256) {
        return _nft;
    }

    /// @inheritdoc IVault
    function tvl() public view virtual returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    /// @inheritdoc IVault
    function pullExistentials() external view returns (uint256[] memory) {
        return _pullExistentials;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || (interfaceId == type(IVault).interfaceId);
    }

    // -------------------  INTERNAL, MUTATING  -------------------

    function _initialize(address[] memory vaultTokens_, uint256 nft_) internal virtual {
        require(_nft == 0, ExceptionsLibrary.INIT);
        require(CommonLibrary.isSortedAndUnique(vaultTokens_), ExceptionsLibrary.INVARIANT);
        require(nft_ != 0, ExceptionsLibrary.VALUE_ZERO); // guarantees that this method can only be called once
        IProtocolGovernance governance = IVaultGovernance(msg.sender).internalParams().protocolGovernance;
        require(
            vaultTokens_.length > 0 && vaultTokens_.length <= governance.maxTokensPerVault(),
            ExceptionsLibrary.INVALID_VALUE
        );
        for (uint256 i = 0; i < vaultTokens_.length; i++) {
            require(
                governance.hasPermission(vaultTokens_[i], PermissionIdsLibrary.ERC20_VAULT_TOKEN),
                ExceptionsLibrary.FORBIDDEN
            );
        }
        _vaultGovernance = IVaultGovernance(msg.sender);
        _vaultTokens = vaultTokens_;
        _nft = nft_;
        uint256 len = _vaultTokens.length;
        for (uint256 i = 0; i < len; ++i) {
            _vaultTokensIndex[vaultTokens_[i]] = int256(i + 1);

            IERC20Metadata token = IERC20Metadata(vaultTokens_[i]);
            _pullExistentials.push(10**(token.decimals() / 2));
        }
        emit Initialized(tx.origin, msg.sender, vaultTokens_, nft_);
    }

    // --------------------------  EVENTS  --------------------------

    /// @notice Emitted when Vault is intialized
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param vaultTokens_ ERC20 tokens under the vault management
    /// @param nft_ VaultRegistry NFT assigned to the vault
    event Initialized(address indexed origin, address indexed sender, address[] vaultTokens_, uint256 nft_);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IProtocolGovernance.sol";
import "../interfaces/vaults/IVaultGovernance.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../libraries/PermissionIdsLibrary.sol";

/// @notice Internal contract for managing different params.
/// @dev The contract should be overriden by the concrete VaultGovernance,
/// define different params structs and use abi.decode / abi.encode to serialize
/// to bytes in this contract. It also should emit events on params change.
abstract contract VaultGovernance is IVaultGovernance, ERC165 {
    InternalParams internal _internalParams;
    InternalParams private _stagedInternalParams;
    uint256 internal _internalParamsTimestamp;

    mapping(uint256 => bytes) internal _delayedStrategyParams;
    mapping(uint256 => bytes) internal _stagedDelayedStrategyParams;
    mapping(uint256 => uint256) internal _delayedStrategyParamsTimestamp;

    mapping(uint256 => bytes) internal _delayedProtocolPerVaultParams;
    mapping(uint256 => bytes) internal _stagedDelayedProtocolPerVaultParams;
    mapping(uint256 => uint256) internal _delayedProtocolPerVaultParamsTimestamp;

    bytes internal _delayedProtocolParams;
    bytes internal _stagedDelayedProtocolParams;
    uint256 internal _delayedProtocolParamsTimestamp;

    mapping(uint256 => bytes) internal _strategyParams;
    bytes internal _protocolParams;
    bytes internal _operatorParams;

    /// @notice Creates a new contract.
    /// @param internalParams_ Initial Internal Params
    constructor(InternalParams memory internalParams_) {
        require(address(internalParams_.protocolGovernance) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(internalParams_.registry) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(internalParams_.singleton) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _internalParams = internalParams_;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @inheritdoc IVaultGovernance
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256) {
        return _delayedStrategyParamsTimestamp[nft];
    }

    /// @inheritdoc IVaultGovernance
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256) {
        return _delayedProtocolPerVaultParamsTimestamp[nft];
    }

    /// @inheritdoc IVaultGovernance
    function delayedProtocolParamsTimestamp() external view returns (uint256) {
        return _delayedProtocolParamsTimestamp;
    }

    /// @inheritdoc IVaultGovernance
    function internalParamsTimestamp() external view returns (uint256) {
        return _internalParamsTimestamp;
    }

    /// @inheritdoc IVaultGovernance
    function internalParams() external view returns (InternalParams memory) {
        return _internalParams;
    }

    /// @inheritdoc IVaultGovernance
    function stagedInternalParams() external view returns (InternalParams memory) {
        return _stagedInternalParams;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165) returns (bool) {
        return super.supportsInterface(interfaceID) || interfaceID == type(IVaultGovernance).interfaceId;
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @inheritdoc IVaultGovernance
    function stageInternalParams(InternalParams memory newParams) external {
        _requireProtocolAdmin();
        require(address(newParams.protocolGovernance) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(newParams.registry) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(newParams.singleton) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _stagedInternalParams = newParams;
        _internalParamsTimestamp = block.timestamp + _internalParams.protocolGovernance.governanceDelay();
        emit StagedInternalParams(tx.origin, msg.sender, newParams, _internalParamsTimestamp);
    }

    /// @inheritdoc IVaultGovernance
    function commitInternalParams() external {
        _requireProtocolAdmin();
        require(_internalParamsTimestamp != 0, ExceptionsLibrary.NULL);
        require(block.timestamp >= _internalParamsTimestamp, ExceptionsLibrary.TIMESTAMP);
        _internalParams = _stagedInternalParams;
        delete _internalParamsTimestamp;
        delete _stagedInternalParams;
        emit CommitedInternalParams(tx.origin, msg.sender, _internalParams);
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _requireAtLeastStrategy(uint256 nft) internal view {
        require(
            (_internalParams.protocolGovernance.isAdmin(msg.sender) ||
                _internalParams.registry.getApproved(nft) == msg.sender ||
                (_internalParams.registry.ownerOf(nft) == msg.sender)),
            ExceptionsLibrary.FORBIDDEN
        );
    }

    function _requireProtocolAdmin() internal view {
        require(_internalParams.protocolGovernance.isAdmin(msg.sender), ExceptionsLibrary.FORBIDDEN);
    }

    function _requireAtLeastOperator() internal view {
        IProtocolGovernance governance = _internalParams.protocolGovernance;
        require(governance.isAdmin(msg.sender) || governance.isOperator(msg.sender), ExceptionsLibrary.FORBIDDEN);
    }

    // -------------------  INTERNAL, MUTATING  -------------------

    function _createVault(address owner) internal returns (address vault, uint256 nft) {
        IProtocolGovernance protocolGovernance = IProtocolGovernance(_internalParams.protocolGovernance);
        require(
            protocolGovernance.hasPermission(msg.sender, PermissionIdsLibrary.CREATE_VAULT),
            ExceptionsLibrary.FORBIDDEN
        );
        IVaultRegistry vaultRegistry = _internalParams.registry;
        nft = vaultRegistry.vaultsCount() + 1;
        vault = Clones.cloneDeterministic(address(_internalParams.singleton), bytes32(nft));
        vaultRegistry.registerVault(address(vault), owner);
    }

    /// @notice Set Delayed Strategy Params
    /// @param nft Nft of the vault
    /// @param params New params
    function _stageDelayedStrategyParams(uint256 nft, bytes memory params) internal {
        _requireAtLeastStrategy(nft);
        _stagedDelayedStrategyParams[nft] = params;
        uint256 delayFactor = _delayedStrategyParams[nft].length == 0 ? 0 : 1;
        _delayedStrategyParamsTimestamp[nft] =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Strategy Params
    function _commitDelayedStrategyParams(uint256 nft) internal {
        _requireAtLeastStrategy(nft);
        uint256 thisDelayedStrategyParamsTimestamp = _delayedStrategyParamsTimestamp[nft];
        require(thisDelayedStrategyParamsTimestamp != 0, ExceptionsLibrary.NULL);
        require(block.timestamp >= thisDelayedStrategyParamsTimestamp, ExceptionsLibrary.TIMESTAMP);
        _delayedStrategyParams[nft] = _stagedDelayedStrategyParams[nft];
        delete _stagedDelayedStrategyParams[nft];
        delete _delayedStrategyParamsTimestamp[nft];
    }

    /// @notice Set Delayed Protocol Per Vault Params
    /// @param nft Nft of the vault
    /// @param params New params
    function _stageDelayedProtocolPerVaultParams(uint256 nft, bytes memory params) internal {
        _requireProtocolAdmin();
        _stagedDelayedProtocolPerVaultParams[nft] = params;
        uint256 delayFactor = _delayedProtocolPerVaultParams[nft].length == 0 ? 0 : 1;
        _delayedProtocolPerVaultParamsTimestamp[nft] =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Protocol Per Vault Params
    function _commitDelayedProtocolPerVaultParams(uint256 nft) internal {
        _requireProtocolAdmin();
        uint256 thisDelayedProtocolPerVaultParamsTimestamp = _delayedProtocolPerVaultParamsTimestamp[nft];
        require(thisDelayedProtocolPerVaultParamsTimestamp != 0, ExceptionsLibrary.NULL);
        require(block.timestamp >= thisDelayedProtocolPerVaultParamsTimestamp, ExceptionsLibrary.TIMESTAMP);
        _delayedProtocolPerVaultParams[nft] = _stagedDelayedProtocolPerVaultParams[nft];
        delete _stagedDelayedProtocolPerVaultParams[nft];
        delete _delayedProtocolPerVaultParamsTimestamp[nft];
    }

    /// @notice Set Delayed Protocol Params
    /// @param params New params
    function _stageDelayedProtocolParams(bytes memory params) internal {
        _requireProtocolAdmin();
        uint256 delayFactor = _delayedProtocolParams.length == 0 ? 0 : 1;
        _stagedDelayedProtocolParams = params;
        _delayedProtocolParamsTimestamp =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Protocol Params
    function _commitDelayedProtocolParams() internal {
        _requireProtocolAdmin();
        require(_delayedProtocolParamsTimestamp != 0, ExceptionsLibrary.NULL);
        require(block.timestamp >= _delayedProtocolParamsTimestamp, ExceptionsLibrary.TIMESTAMP);
        _delayedProtocolParams = _stagedDelayedProtocolParams;
        delete _stagedDelayedProtocolParams;
        delete _delayedProtocolParamsTimestamp;
    }

    /// @notice Set immediate strategy params
    /// @dev Should require nft > 0
    /// @param nft Nft of the vault
    /// @param params New params
    function _setStrategyParams(uint256 nft, bytes memory params) internal {
        _requireAtLeastStrategy(nft);
        _strategyParams[nft] = params;
    }

    /// @notice Set immediate operator params
    /// @param params New params
    function _setOperatorParams(bytes memory params) internal {
        _requireAtLeastOperator();
        _operatorParams = params;
    }

    /// @notice Set immediate protocol params
    /// @param params New params
    function _setProtocolParams(bytes memory params) internal {
        _requireProtocolAdmin();
        _protocolParams = params;
    }

    // --------------------------  EVENTS  --------------------------

    /// @notice Emitted when InternalParams are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that were staged for commit
    /// @param when When the params could be committed
    event StagedInternalParams(address indexed origin, address indexed sender, InternalParams params, uint256 when);

    /// @notice Emitted when InternalParams are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that were staged for commit
    event CommitedInternalParams(address indexed origin, address indexed sender, InternalParams params);

    /// @notice Emitted when New Vault is deployed
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param vaultTokens Vault tokens for this vault
    /// @param options Options for deploy. The details of the options structure are specified in subcontracts
    /// @param owner Owner of the VaultRegistry NFT for this vault
    /// @param vaultAddress Address of the new Vault
    /// @param vaultNft VaultRegistry NFT for the new Vault
    event DeployedVault(
        address indexed origin,
        address indexed sender,
        address[] vaultTokens,
        bytes options,
        address owner,
        address vaultAddress,
        uint256 vaultNft
    );
}