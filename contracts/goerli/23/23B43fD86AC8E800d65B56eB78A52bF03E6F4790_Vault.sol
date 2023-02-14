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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface ICurve {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function coins(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface CustomErrors {
    //
    // Vault Errors
    //

    // Vault: sender is not the owner of the group id
    error VaultSenderNotOwnerOfGroupId();

    // Vault: invalid investPct
    error VaultInvalidInvestPct();

    // Vault: invalid immediateInvestLimitPct
    error VaultInvalidImmediateInvestLimitPct();

    // Vault: invalid performance fee
    error VaultInvalidPerformanceFee();

    // Vault: no performance fee
    error VaultNoPerformanceFee();

    // Vault: invalid lossTolerance
    error VaultInvalidLossTolerance();

    // Vault: underlying cannot be 0x0
    error VaultUnderlyingCannotBe0Address();

    // Vault: treasury cannot be 0x0
    error VaultTreasuryCannotBe0Address();

    // Vault: admin cannot be 0x0
    error VaultAdminCannotBe0Address();

    // Vault: cannot transfer admin rights to self
    error VaultCannotTransferAdminRightsToSelf();

    // Vault: caller is not admin
    error VaultCallerNotAdmin();

    // Vault: caller is not settings
    error VaultCallerNotSettings();

    // Vault: caller is not keeper
    error VaultCallerNotKeeper();

    // Vault: caller is not sponsor
    error VaultCallerNotSponsor();

    // Vault: destination address is 0x
    error VaultDestinationCannotBe0Address();

    // Vault: strategy is not set
    error VaultStrategyNotSet();

    // Vault: invalid minLockPeriod
    error VaultInvalidMinLockPeriod();

    // Vault: invalid lock period
    error VaultInvalidLockPeriod();

    // Vault: cannot deposit 0
    error VaultCannotDeposit0();

    // Vault: cannot sponsor 0
    error VaultCannotSponsor0();

    // Vault: cannot deposit when yield is negative
    error VaultCannotDepositWhenYieldNegative();

    // Vault: cannot deposit when the claimer is in debt
    error VaultCannotDepositWhenClaimerInDebt();

    // Vault: cannot withdraw when yield is negative
    error VaultCannotWithdrawWhenYieldNegative();

    // Vault: nothing to do
    error VaultNothingToDo();

    // Vault: not enough to rebalance
    error VaultNotEnoughToRebalance();

    // Vault: invalid vault
    error VaultInvalidVault();

    // Vault: strategy has invested funds
    error VaultStrategyHasInvestedFunds();

    // Vault: not enough funds
    error VaultNotEnoughFunds();

    // Vault: you are not allowed
    error VaultNotAllowed();

    // Vault: amount is locked
    error VaultAmountLocked();

    // Vault: deposit is locked
    error VaultDepositLocked();

    // Vault: token id is not a sponsor
    error VaultNotSponsor();

    // Vault: token id is not a deposit
    error VaultNotDeposit();

    // Vault: claim percentage cannot be 0
    error VaultClaimPercentageCannotBe0();

    // Vault: claimer cannot be address 0
    error VaultClaimerCannotBe0();

    // Vault: claims don't add up to 100%
    error VaultClaimsDontAddUp();

    // Vault: you are not the owner of a deposit
    error VaultNotOwnerOfDeposit();

    // Vault: cannot withdraw more than the available amount
    error VaultCannotWithdrawMoreThanAvailable();

    // Vault: must force withdraw to withdraw with a loss
    error VaultMustUseForceWithdrawToAcceptLosses();

    // Vault: amount received does not match params
    error VaultAmountDoesNotMatchParams();

    // Vault: cannot compute shares when there's no principal
    error VaultCannotComputeSharesWithoutPrincipal();

    // Vault: deposit name for MetaVault too short
    error VaultDepositNameTooShort();

    // Vault: no yield to claim
    error VaultNoYieldToClaim();

    //
    // Strategy Errors
    //

    // Strategy: admin is 0x
    error StrategyAdminCannotBe0Address();

    // Strategy: keeper is 0x
    error StrategyKeeperCannotBe0Address();

    // Strategy: cannot transfer admin rights to self
    error StrategyCannotTransferAdminRightsToSelf();

    // Strategy: underlying is 0x
    error StrategyUnderlyingCannotBe0Address();

    // Strategy: not an IVault
    error StrategyNotIVault();

    // Strategy: caller is not manager
    error StrategyCallerNotManager();

    // Strategy: caller has no settings role
    error StrategyCallerNotSettings();

    // Strategy: caller has no keeper role
    error StrategyCallerNotKeeper();

    // Strategy: caller is not admin
    error StrategyCallerNotAdmin();

    // Strategy: amount is 0
    error StrategyAmountZero();

    // Strategy: not running
    error StrategyNotRunning();

    // Not Enough Underlying Balance in Strategy contract
    error StrategyNoUnderlying();

    // Not Enough Shares in Strategy Contract
    error StrategyNotEnoughShares();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an exit stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotExitPaused` and `whenExitPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract ExitPausable is Context {
    /**
     * @dev Emitted when the exitPause is triggered by `account`.
     */
    event ExitPaused(address account);

    /**
     * @dev Emitted when the exitPause is lifted by `account`.
     */
    event ExitUnpaused(address account);

    bool private _exitPaused;

    /**
     * @dev Initializes the contract in exitUnpaused state.
     */
    constructor() {
        _exitPaused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not exitPaused.
     *
     * Requirements:
     *
     * - The contract must not be exitPaused.
     */
    modifier whenNotExitPaused() {
        _requireNotExitPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is exitPaused.
     *
     * Requirements:
     *
     * - The contract must be exitPaused.
     */
    modifier whenExitPaused() {
        _requireExitPaused();
        _;
    }

    /**
     * @dev Returns true if the contract is exitPaused, and false otherwise.
     */
    function exitPaused() public view virtual returns (bool) {
        return _exitPaused;
    }

    /**
     * @dev Throws if the contract is exitPaused.
     */
    function _requireNotExitPaused() internal view virtual {
        require(!exitPaused(), "Pausable: ExitPaused");
    }

    /**
     * @dev Throws if the contract is not exitPaused.
     */
    function _requireExitPaused() internal view virtual {
        require(exitPaused(), "Pausable: not ExitPaused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be exitPaused.
     */
    function _exitPause() internal virtual whenNotExitPaused {
        _exitPaused = true;
        emit ExitPaused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be exitPaused.
     */
    function _exitUnpause() internal virtual whenExitPaused {
        _exitPaused = false;
        emit ExitUnpaused(_msgSender());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

library PercentMath {
    // Divisor used for representing percentages
    uint256 public constant PCT_DIVISOR = 10000;

    /**
     * @dev Returns whether an amount is a valid percentage out of PCT_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPct(uint256 _amount) internal pure returns (bool) {
        return _amount <= PCT_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PCT_DIVISOR as the denominator
     */
    function pctOf(uint256 _amount, uint16 _fracNum)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _fracNum) / PCT_DIVISOR;
    }

    /**
     * @dev Compute percentage that a value represents in relation to the total value
     * @param _amount Amount to calculate the percentage of in relation to the total
     * @param _total Amount to calculate the percentage relative to
     */
    function inPctOf(uint256 _amount, uint256 _total)
        internal
        pure
        returns (uint16)
    {
        return uint16((_amount * PCT_DIVISOR) / _total);
    }

    /**
     * @dev Checks if a given number corresponds to 100%
     * @param _perc Percentage value to check, with PCT_DIVISOR
     */
    function is100Pct(uint256 _perc) internal pure returns (bool) {
        return _perc == PCT_DIVISOR;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * IStrategy defines the interface for pluggable contracts used by vaults to invest funds and generate yield.
 *
 * @notice It's up to the strategy to decide what do to with investable assets provided by a vault.
 *
 * @notice It's up to the vault to decide how much to invest/disinvest from the total pool.
 */
interface IStrategy {
    /**
     * Emmited when funds are invested by the strategy.
     *
     *@param amount amount invested
     */
    event StrategyInvested(uint256 amount);
    /**
     * Emmited when funds are withdrawn (disinvested) by the strategy.
     *
     *@param amount amount withdrawn
     */
    event StrategyWithdrawn(uint256 amount);

    /**
     * Provides information about wether the strategy is synchronous or asynchronous.
     *
     * @notice Synchronous strategies support instant withdrawals,
     * while asynchronous strategies impose a delay before withdrawals can be made.
     *
     * @return true if the strategy is synchronous, false otherwise
     */
    function isSync() external view returns (bool);

    /**
     * The vault linked to this strategy.
     *
     * @return The vault's address
     */
    function vault() external view returns (address);

    /**
     * Withdraws the specified amount back to the vault (disinvests)
     *
     * @param amount Amount to withdraw
     *
     * @return actual amount withdrawn
     */
    function withdrawToVault(uint256 amount) external returns (uint256);

    /**
     * Transfers the @param _amount to @param _to in the more appropriate currency.
     *
     * For instance, for Liquity Yield DCA, the most appropriate currency may
     * be ETH since yield will be kept in ETH.
     *
     * @param _to address that will receive the funds.
     * @param _amount amount to transfer.
     *
     * @return amountTransferred amount in underlying equivalent to amount transferred in other currency.
     */
    function transferYield(address _to, uint256 _amount)
        external
        returns (uint256 amountTransferred);

    /**
     * Amount of the underlying currency currently invested by the strategy.
     *
     * @notice both held and invested amounts are included here, using the
     * latest known exchange rates to the underlying currency
     *
     * @return The total amount of underlying
     */
    function investedAssets() external view returns (uint256);

    /**
     * Indicates if assets are invested into strategy or not.
     *
     * @notice this will be used when removing the strategy from the vault
     * @return true if assets invested, false if nothing invested.
     */
    function hasAssets() external view returns (bool);

    /**
     * Deposits of all the available underlying into the yield generating protocol.
     */
    function invest() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {IVault} from "./vault/IVault.sol";
import {IVaultSponsoring} from "./vault/IVaultSponsoring.sol";
import {IVaultSettings} from "./vault/IVaultSettings.sol";
import {CurveSwapper} from "./vault/CurveSwapper.sol";
import {PercentMath} from "./lib/PercentMath.sol";
import {ExitPausable} from "./lib/ExitPausable.sol";
import {IStrategy} from "./strategy/IStrategy.sol";
import {CustomErrors} from "./interfaces/CustomErrors.sol";

/**
 * A vault where other accounts can deposit an underlying token
 * currency and set distribution params for their principal and yield
 *
 * @notice The underlying token can be automatically swapped from any configured ERC20 token via {CurveSwapper}
 */
contract Vault is
    IVault,
    IVaultSponsoring,
    IVaultSettings,
    CurveSwapper,
    Context,
    ERC165,
    AccessControl,
    ReentrancyGuard,
    Pausable,
    ExitPausable,
    CustomErrors
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using PercentMath for uint256;
    using PercentMath for uint16;
    using Counters for Counters.Counter;

    //
    // Constants
    //

    /// Role allowed to invest/desinvest from strategy
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    /// Role allowed to change settings such as performance fee and investment fee
    bytes32 public constant SETTINGS_ROLE = keccak256("SETTINGS_ROLE");

    /// Role for sponsors allowed to call sponsor/unsponsor
    bytes32 public constant SPONSOR_ROLE = keccak256("SPONSOR_ROLE");

    /// Minimum lock for each sponsor
    uint64 public constant MIN_SPONSOR_LOCK_DURATION = 2 weeks;

    /// Maximum lock for each sponsor
    uint64 public constant MAX_SPONSOR_LOCK_DURATION = 24 weeks;

    /// Maximum lock for each deposit
    uint64 public constant MAX_DEPOSIT_LOCK_DURATION = 24 weeks;

    /// Helper constant for computing shares without losing precision
    uint256 public constant SHARES_MULTIPLIER = 1e18;

    //
    // State
    //

    /// @inheritdoc IVault
    IERC20Metadata public immutable override(IVault) underlying;

    /// @inheritdoc IVault
    uint16 public override(IVault) investPct;

    /// @inheritdoc IVault
    uint64 public override(IVault) minLockPeriod;

    /// @inheritdoc IVaultSponsoring
    uint256 public override(IVaultSponsoring) totalSponsored;

    /// @inheritdoc IVault
    uint256 public override(IVault) totalShares;

    /// @inheritdoc IVault
    uint16 public override(IVault) immediateInvestLimitPct;

    /// The investment strategy
    IStrategy public strategy;

    /// Unique IDs to correlate donations that belong to the same foundation
    uint256 private _depositGroupIds;
    mapping(uint256 => address) public depositGroupIdOwner;

    /// deposit ID => deposit data
    mapping(uint256 => Deposit) public deposits;

    /// Counter for deposit ids
    Counters.Counter private _depositTokenIds;

    /// claimer address => claimer data
    mapping(address => Claimer) public claimers;

    /// The total of principal deposited
    uint256 public override(IVault) totalPrincipal;

    /// Treasury address to collect performance fee
    address public treasury;

    /// Performance fee percentage
    uint16 public perfFeePct;

    /// Current accumulated performance fee;
    uint256 public override(IVault) accumulatedPerfFee;

    /// Loss tolerance pct
    uint16 public lossTolerancePct;

    /// Rebalance minimum
    uint256 private immutable rebalanceMinimum;

    /**
     * @param _underlying Underlying ERC20 token to use.
     * @param _minLockPeriod Minimum lock period to deposit
     * @param _investPct Percentage of the total underlying to invest in the strategy
     * @param _treasury Treasury address to collect performance fee
     * @param _admin Vault admin address
     * @param _perfFeePct Performance fee percentage
     * @param _lossTolerancePct Loss tolerance when investing through the strategy
     * @param _swapPools Swap pools used to automatically convert tokens to underlying
     */
    constructor(
        IERC20Metadata _underlying,
        uint64 _minLockPeriod,
        uint16 _investPct,
        address _treasury,
        address _admin,
        uint16 _perfFeePct,
        uint16 _lossTolerancePct,
        SwapPoolParam[] memory _swapPools,
        uint16 _immediateInvestLimitPct
    ) {
        if (!_immediateInvestLimitPct.validPct())
            revert VaultInvalidImmediateInvestLimitPct();
        if (!_investPct.validPct()) revert VaultInvalidInvestPct();
        if (!_perfFeePct.validPct()) revert VaultInvalidPerformanceFee();
        if (!_lossTolerancePct.validPct()) revert VaultInvalidLossTolerance();
        if (address(_underlying) == address(0x0))
            revert VaultUnderlyingCannotBe0Address();
        if (_treasury == address(0x0)) revert VaultTreasuryCannotBe0Address();
        if (_admin == address(0x0)) revert VaultAdminCannotBe0Address();
        _checkMinLockPeriod(_minLockPeriod);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(KEEPER_ROLE, _admin);
        _grantRole(SETTINGS_ROLE, _admin);
        _grantRole(SPONSOR_ROLE, _admin);

        investPct = _investPct;
        underlying = _underlying;
        treasury = _treasury;
        minLockPeriod = _minLockPeriod;
        perfFeePct = _perfFeePct;
        lossTolerancePct = _lossTolerancePct;
        immediateInvestLimitPct = _immediateInvestLimitPct;

        rebalanceMinimum = 10 * 10**underlying.decimals();

        _addPools(_swapPools);

        emit TreasuryUpdated(_treasury);
    }

    //
    // Modifiers
    //

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert VaultCallerNotAdmin();
        _;
    }

    modifier onlySettings() {
        if (!hasRole(SETTINGS_ROLE, msg.sender))
            revert VaultCallerNotSettings();
        _;
    }

    modifier onlyKeeper() {
        if (!hasRole(KEEPER_ROLE, msg.sender)) revert VaultCallerNotKeeper();
        _;
    }

    modifier onlySponsor() {
        if (!hasRole(SPONSOR_ROLE, msg.sender)) revert VaultCallerNotSponsor();
        _;
    }

    /**
     * Transfers administrator rights for the Vault to another account,
     * revoking all current admin's roles and setting up the roles for the new admin.
     *
     * @notice Can only be called by the admin.
     *
     * @param _newAdmin The new admin account.
     */
    function transferAdminRights(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0x0)) revert VaultAdminCannotBe0Address();
        if (_newAdmin == msg.sender)
            revert VaultCannotTransferAdminRightsToSelf();

        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _grantRole(KEEPER_ROLE, _newAdmin);
        _grantRole(SETTINGS_ROLE, _newAdmin);
        _grantRole(SPONSOR_ROLE, _newAdmin);

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(KEEPER_ROLE, msg.sender);
        _revokeRole(SETTINGS_ROLE, msg.sender);
        _revokeRole(SPONSOR_ROLE, msg.sender);
    }

    //
    // IVault
    //

    /// @inheritdoc IVault
    function totalUnderlying() public view override(IVault) returns (uint256) {
        if (address(strategy) != address(0)) {
            return
                underlying.balanceOf(address(this)) + strategy.investedAssets();
        }

        return underlying.balanceOf(address(this));
    }

    /// @inheritdoc IVault
    function yieldFor(address _to)
        public
        view
        override(IVault)
        returns (
            uint256 claimableYield,
            uint256 shares,
            uint256 perfFee
        )
    {
        uint256 claimerPrincipal = claimers[_to].totalPrincipal;
        uint256 claimerShares = claimers[_to].totalShares;
        uint256 _totalUnderlyingMinusSponsored = totalUnderlyingMinusSponsored();

        uint256 currentClaimerPrincipal = _computeAmount(
            claimerShares,
            totalShares,
            _totalUnderlyingMinusSponsored
        );

        if (currentClaimerPrincipal <= claimerPrincipal) {
            return (0, 0, 0);
        }

        uint256 yieldWithPerfFee = currentClaimerPrincipal - claimerPrincipal;

        shares = _computeShares(
            yieldWithPerfFee,
            totalShares,
            _totalUnderlyingMinusSponsored
        );
        uint256 sharesAmount = _computeAmount(
            shares,
            totalShares,
            _totalUnderlyingMinusSponsored
        );

        perfFee = sharesAmount.pctOf(perfFeePct);
        claimableYield = sharesAmount - perfFee;
    }

    /// @inheritdoc IVault
    function depositForGroupId(uint256 _groupId, DepositParams calldata _params)
        external
        nonReentrant
        whenNotPaused
        returns (uint256[] memory depositIds)
    {
        if (depositGroupIdOwner[_groupId] != msg.sender)
            revert VaultSenderNotOwnerOfGroupId();

        depositIds = _doDeposit(_groupId, _params);
    }

    /// @inheritdoc IVault
    function deposit(DepositParams calldata _params)
        external
        nonReentrant
        whenNotPaused
        returns (uint256[] memory depositIds)
    {
        uint256 depositGroupId = _depositGroupIds;
        _depositGroupIds = depositGroupId + 1;

        depositGroupIdOwner[depositGroupId] = msg.sender;
        depositIds = _doDeposit(depositGroupId, _params);
    }

    function _doDeposit(uint256 _groupId, DepositParams calldata _params)
        internal
        returns (uint256[] memory depositIds)
    {
        if (_params.amount == 0) revert VaultCannotDeposit0();
        if (
            _params.lockDuration < minLockPeriod ||
            _params.lockDuration > MAX_DEPOSIT_LOCK_DURATION
        ) revert VaultInvalidLockPeriod();
        if (bytes(_params.name).length < 3) revert VaultDepositNameTooShort();

        uint256 principalMinusStrategyFee = _applyLossTolerance(totalPrincipal);
        uint256 previousTotalUnderlying = totalUnderlyingMinusSponsored();
        if (principalMinusStrategyFee > previousTotalUnderlying)
            revert VaultCannotDepositWhenYieldNegative();

        _transferAndCheckInputToken(
            msg.sender,
            _params.inputToken,
            _params.amount
        );
        uint256 newUnderlyingAmount = _swapIntoUnderlying(
            _params.inputToken,
            _params.amount,
            _params.amountOutMin
        );

        uint64 lockedUntil = _params.lockDuration + _blockTimestamp();

        depositIds = _createDeposit(
            previousTotalUnderlying,
            newUnderlyingAmount,
            lockedUntil,
            _params.claims,
            _params.name,
            _groupId
        );

        if (immediateInvestLimitPct != 0) _immediateInvestment();
    }

    /// @inheritdoc IVault
    function claimYield(address _to)
        external
        override(IVault)
        nonReentrant
        whenNotExitPaused
    {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        (uint256 yield, uint256 shares, uint256 fee) = yieldFor(msg.sender);

        if (yield == 0) revert VaultNoYieldToClaim();

        uint256 _totalUnderlyingMinusSponsored = totalUnderlyingMinusSponsored();
        uint256 _totalShares = totalShares;

        accumulatedPerfFee += fee;

        claimers[msg.sender].totalShares -= shares;
        totalShares -= shares;

        emit YieldClaimed(
            msg.sender,
            _to,
            yield,
            shares,
            fee,
            _totalUnderlyingMinusSponsored,
            _totalShares
        );

        if (address(strategy) != address(0)) {
            uint256 yieldTransferred = strategy.transferYield(_to, yield);
            if (yieldTransferred >= yield) {
                return;
            }

            yield -= yieldTransferred;
        }

        _rebalanceBeforeWithdrawing(yield);

        underlying.safeTransfer(_to, yield);
    }

    /// @inheritdoc IVault
    function withdraw(address _to, uint256[] calldata _ids)
        external
        override(IVault)
        nonReentrant
        whenNotExitPaused
    {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        if (totalPrincipal > totalUnderlyingMinusSponsored())
            revert VaultCannotWithdrawWhenYieldNegative();

        _withdrawAll(_to, _ids, false);
    }

    /// @inheritdoc IVault
    function forceWithdraw(address _to, uint256[] calldata _ids)
        external
        nonReentrant
        whenNotExitPaused
    {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        _withdrawAll(_to, _ids, true);
    }

    function partialWithdraw(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external nonReentrant whenNotExitPaused {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        _withdrawPartial(_to, _ids, _amounts);
    }

    /// @inheritdoc IVault
    function investState()
        public
        view
        override(IVault)
        returns (uint256 maxInvestableAmount, uint256 alreadyInvested)
    {
        if (address(strategy) == address(0)) {
            return (0, 0);
        }

        maxInvestableAmount = totalUnderlying().pctOf(investPct);
        alreadyInvested = strategy.investedAssets();
    }

    /// @inheritdoc IVault
    function updateInvested() external override(IVault) onlyKeeper {
        if (address(strategy) == address(0)) revert VaultStrategyNotSet();

        (uint256 maxInvestableAmount, uint256 alreadyInvested) = investState();

        if (maxInvestableAmount == alreadyInvested) revert VaultNothingToDo();

        // disinvest
        if (alreadyInvested > maxInvestableAmount) {
            uint256 disinvestAmount = alreadyInvested - maxInvestableAmount;

            if (disinvestAmount < rebalanceMinimum)
                revert VaultNotEnoughToRebalance();

            uint256 amountWithdrawn = strategy.withdrawToVault(disinvestAmount);

            emit Disinvested(amountWithdrawn);

            return;
        }

        // invest
        uint256 investAmount = maxInvestableAmount - alreadyInvested;

        if (investAmount < rebalanceMinimum) revert VaultNotEnoughToRebalance();

        underlying.safeTransfer(address(strategy), investAmount);

        strategy.invest();

        emit Invested(investAmount);
    }

    /// @inheritdoc IVault
    function withdrawPerformanceFee() external override(IVault) onlyKeeper {
        uint256 _perfFee = accumulatedPerfFee;
        if (_perfFee == 0) revert VaultNoPerformanceFee();

        accumulatedPerfFee = 0;
        _rebalanceBeforeWithdrawing(_perfFee);

        emit FeeWithdrawn(_perfFee);
        underlying.safeTransfer(treasury, _perfFee);
    }

    //
    // IVaultSponsoring
    //

    /// @inheritdoc IVaultSponsoring
    function sponsor(
        address _inputToken,
        uint256 _amount,
        uint256 _lockDuration,
        uint256 _amountOutMin
    )
        external
        override(IVaultSponsoring)
        nonReentrant
        onlySponsor
        whenNotPaused
    {
        if (_amount == 0) revert VaultCannotSponsor0();

        if (
            _lockDuration < MIN_SPONSOR_LOCK_DURATION ||
            _lockDuration > MAX_SPONSOR_LOCK_DURATION
        ) revert VaultInvalidLockPeriod();

        uint256 lockedUntil = _lockDuration + block.timestamp;
        _depositTokenIds.increment();
        uint256 tokenId = _depositTokenIds.current();

        _transferAndCheckInputToken(msg.sender, _inputToken, _amount);
        uint256 underlyingAmount = _swapIntoUnderlying(
            _inputToken,
            _amount,
            _amountOutMin
        );

        deposits[tokenId] = Deposit(
            underlyingAmount,
            msg.sender,
            address(0),
            lockedUntil
        );
        totalSponsored += underlyingAmount;

        emit Sponsored(tokenId, underlyingAmount, msg.sender, lockedUntil);
    }

    /// @inheritdoc IVaultSponsoring
    function unsponsor(address _to, uint256[] calldata _ids)
        external
        nonReentrant
        whenNotExitPaused
    {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        _unsponsor(_to, _ids);
    }

    /// @inheritdoc IVaultSponsoring
    function partialUnsponsor(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external nonReentrant whenNotExitPaused {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        _partialUnsponsor(_to, _ids, _amounts);
    }

    //
    // CurveSwapper
    //

    /// @inheritdoc CurveSwapper
    function getUnderlying()
        public
        view
        override(CurveSwapper)
        returns (address)
    {
        return address(underlying);
    }

    /// Adds a new curve swap pool from an input token to {underlying}
    ///
    /// @param _param Swap pool params
    function addPool(SwapPoolParam memory _param) external onlyAdmin {
        _addPool(_param);
    }

    /// Removes an existing swap pool, and the ability to deposit the given token as underlying
    ///
    /// @param _inputToken the token to remove
    function removePool(address _inputToken) external onlyAdmin {
        _removePool(_inputToken);
    }

    //
    // Admin functions
    //

    /// @inheritdoc IVaultSettings
    function setImmediateInvestLimitPct(uint16 _pct) external onlySettings {
        if (!PercentMath.validPct(_pct))
            revert VaultInvalidImmediateInvestLimitPct();

        emit ImmediateInvestLimitPctUpdated(_pct);

        immediateInvestLimitPct = _pct;
    }

    /// @inheritdoc IVaultSettings
    function setInvestPct(uint16 _investPct)
        external
        override(IVaultSettings)
        onlySettings
    {
        if (!PercentMath.validPct(_investPct)) revert VaultInvalidInvestPct();

        emit InvestPctUpdated(_investPct);

        investPct = _investPct;
    }

    /// @inheritdoc IVaultSettings
    function setTreasury(address _treasury)
        external
        override(IVaultSettings)
        onlySettings
    {
        if (address(_treasury) == address(0x0))
            revert VaultTreasuryCannotBe0Address();
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @inheritdoc IVaultSettings
    function setPerfFeePct(uint16 _perfFeePct)
        external
        override(IVaultSettings)
        onlySettings
    {
        if (!PercentMath.validPct(_perfFeePct))
            revert VaultInvalidPerformanceFee();
        perfFeePct = _perfFeePct;
        emit PerfFeePctUpdated(_perfFeePct);
    }

    /// @inheritdoc IVaultSettings
    function setStrategy(address _strategy)
        external
        override(IVaultSettings)
        onlySettings
    {
        if (_strategy == address(0)) revert VaultStrategyNotSet();
        if (IStrategy(_strategy).vault() != address(this))
            revert VaultInvalidVault();
        if (address(strategy) != address(0) && strategy.hasAssets())
            revert VaultStrategyHasInvestedFunds();

        strategy = IStrategy(_strategy);

        emit StrategyUpdated(_strategy);
    }

    /// @inheritdoc IVaultSettings
    function setLossTolerancePct(uint16 _pct)
        external
        override(IVaultSettings)
        onlySettings
    {
        if (!_pct.validPct()) revert VaultInvalidLossTolerance();

        lossTolerancePct = _pct;
        emit LossTolerancePctUpdated(_pct);
    }

    /// @inheritdoc IVaultSettings
    function setMinLockPeriod(uint64 _minLockPeriod)
        external
        override(IVaultSettings)
        onlySettings
    {
        _checkMinLockPeriod(_minLockPeriod);

        minLockPeriod = _minLockPeriod;
        emit MinLockPeriodUpdated(_minLockPeriod);
    }

    /**
     * Checks if the minimum lock period is valid.
     *
     * @param _minLockPeriod Minimum lock period in seconds
     */
    function _checkMinLockPeriod(uint64 _minLockPeriod) internal pure {
        if (_minLockPeriod == 0 || _minLockPeriod > MAX_DEPOSIT_LOCK_DURATION)
            revert VaultInvalidMinLockPeriod();
    }

    //
    // Public API
    //

    /**
     * Computes the total amount of principal + yield currently controlled by the
     * vault and the strategy. The principal + yield is the total amount
     * of underlying that can be claimed or withdrawn, excluding the sponsored amount and performance fee.
     *
     * @return Total amount of principal and yield help by the vault (not including sponsored amount and performance fee).
     */
    function totalUnderlyingMinusSponsored() public view returns (uint256) {
        uint256 _totalUnderlying = totalUnderlying();
        uint256 deductAmount = totalSponsored + accumulatedPerfFee;
        if (deductAmount > _totalUnderlying) {
            return 0;
        }

        return _totalUnderlying - deductAmount;
    }

    //
    // ERC165
    //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IVault).interfaceId ||
            interfaceId == type(IVaultSponsoring).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //
    // Internal API
    //

    function _immediateInvestment() private {
        (uint256 maxInvestableAmount, uint256 alreadyInvested) = investState();

        if (
            alreadyInvested.inPctOf(maxInvestableAmount) >=
            immediateInvestLimitPct
        ) return;

        uint256 investAmount = maxInvestableAmount - alreadyInvested;

        if (investAmount < rebalanceMinimum) return;

        underlying.safeTransfer(address(strategy), investAmount);

        strategy.invest();

        emit Invested(investAmount);
    }

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     * @param _force Boolean to specify if the action should be perfomed when there's loss.
     */
    function _withdrawAll(
        address _to,
        uint256[] calldata _ids,
        bool _force
    ) internal {
        uint256 localTotalShares = totalShares;
        uint256 localTotalPrincipal = totalUnderlyingMinusSponsored();
        uint256 amount;
        uint256 idsLen = _ids.length;

        for (uint256 i = 0; i < idsLen; ++i) {
            uint256 depositAmount = deposits[_ids[i]].amount;

            amount += _withdrawSingle(
                _ids[i],
                localTotalShares,
                localTotalPrincipal,
                _to,
                _force,
                depositAmount
            );
        }

        _rebalanceBeforeWithdrawing(amount);

        underlying.safeTransfer(_to, amount);
    }

    function _withdrawPartial(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) internal {
        uint256 localTotalShares = totalShares;
        uint256 localTotalPrincipal = totalUnderlyingMinusSponsored();
        uint256 amount;
        uint256 idsLen = _ids.length;

        for (uint256 i = 0; i < idsLen; ++i) {
            amount += _withdrawSingle(
                _ids[i],
                localTotalShares,
                localTotalPrincipal,
                _to,
                false,
                _amounts[i]
            );
        }

        _rebalanceBeforeWithdrawing(amount);

        underlying.safeTransfer(_to, amount);
    }

    /**
     * Rebalances the vault's funds to cover the transfer of funds from the vault
     * by disinvesting from the strategy. After the rebalance the vault is left
     * with a set percentage (100% - invest%) of the total underlying as reserves.
     *
     * @notice this will have effect only for sync strategies.
     *
     * @param _amount Funds to be transferred from the vault.
     */
    function _rebalanceBeforeWithdrawing(uint256 _amount) internal {
        uint256 vaultBalance = underlying.balanceOf(address(this));

        if (_amount <= vaultBalance) return;
        if (!strategy.isSync()) revert VaultNotEnoughFunds();

        uint256 expectedReserves = (totalUnderlying() - _amount).pctOf(
            10000 - investPct
        );

        // we want to withdraw the from the strategy only what is needed
        // to cover the transfer and leave the vault with the expected reserves
        uint256 needed = _amount + expectedReserves - vaultBalance;

        uint256 amountWithdrawn = strategy.withdrawToVault(needed);

        emit Disinvested(amountWithdrawn);
    }

    /**
     * Withdraws the sponsored amount for the deposits with the ids provided
     * in @param _ids and sends it to @param _to.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function _unsponsor(address _to, uint256[] calldata _ids) internal {
        uint256 sponsorAmount;
        uint256 idsLen = _ids.length;

        for (uint8 i = 0; i < idsLen; ++i) {
            uint256 tokenId = _ids[i];
            uint256 amount = deposits[tokenId].amount;

            _unsponsorSingle(_to, tokenId, amount);

            sponsorAmount += amount;
        }

        _decreaseTotalSponsoredAndTransfer(_to, sponsorAmount);
    }

    /**
     * Withdraws the specified sponsored amounts @param _amounts for the deposits with the ids provided
     * in @param _ids and sends it to @param _to.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     * @param _amounts Array with the amounts to withdraw.
     */
    function _partialUnsponsor(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) internal {
        uint256 sponsorAmount;
        uint256 idsLen = _ids.length;

        for (uint8 i = 0; i < idsLen; ++i) {
            uint256 depositId = _ids[i];
            uint256 amount = _amounts[i];

            _unsponsorSingle(_to, depositId, amount);

            sponsorAmount += amount;
        }

        _decreaseTotalSponsoredAndTransfer(_to, sponsorAmount);
    }

    /**
     * Validates conditions for unsponsoring amount @param _amount of the deposit with the id @param _id.
     *
     * @param _to Address that will receive the funds.
     * @param _tokenId Id of the deposit.
     * @param _amount Amount to be unsponsored/withdrawn.
     */
    function _unsponsorSingle(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        Deposit memory _deposit = deposits[_tokenId];

        if (_deposit.owner != msg.sender) revert VaultNotAllowed();
        if (_deposit.lockedUntil > block.timestamp) revert VaultAmountLocked();
        if (_deposit.claimerId != address(0)) revert VaultNotSponsor();
        if (_deposit.amount < _amount)
            revert VaultCannotWithdrawMoreThanAvailable();

        bool isFull = _amount == _deposit.amount;

        emit Unsponsored(_tokenId, _amount, _to, isFull);

        if (!isFull) {
            deposits[_tokenId].amount -= _amount;
            return;
        }

        delete deposits[_tokenId];
    }

    /**
     * Updates totalSponsored by subtracting the amount @param _amount and performing a transfer to @param _to.
     *
     * @param _to Adress that will receive the funds.
     * @param _amount Amount being unsponsored.
     */
    function _decreaseTotalSponsoredAndTransfer(address _to, uint256 _amount)
        internal
    {
        if (_amount > totalUnderlying()) revert VaultNotEnoughFunds();

        totalSponsored -= _amount;

        _rebalanceBeforeWithdrawing(_amount);

        underlying.safeTransfer(_to, _amount);
    }

    /**
     * @dev `_createDeposit` declares too many locals
     * We move some of them to this struct to fix the problem
     */
    struct CreateDepositLocals {
        uint256 totalShares;
        uint256 totalUnderlying;
        uint16 accumulatedPct;
        uint256 accumulatedAmount;
        uint256 claimsLen;
    }

    /**
     * Creates a deposit with the given amount of underlying and claim
     * structure. The deposit is locked until the timestamp specified in @param _lockedUntil.
     * @notice This function assumes underlying will be transfered elsewhere in
     * the transaction.
     *
     * @notice Underlying must be transfered *after* this function, in order to
     * correctly calculate shares.
     *
     * @notice claims must add up to 100%.
     *
     * @param _amount Amount of underlying to consider @param claims claim
     * @param _lockedUntil Timestamp at which the deposit unlocks
     * @param claims Claim params
     * params.
     */
    function _createDeposit(
        uint256 _previousTotalUnderlying,
        uint256 _amount,
        uint64 _lockedUntil,
        ClaimParams[] calldata claims,
        string calldata _name,
        uint256 _groupId
    ) internal returns (uint256[] memory) {
        CreateDepositLocals memory locals = CreateDepositLocals({
            totalShares: totalShares,
            totalUnderlying: _previousTotalUnderlying,
            accumulatedPct: 0,
            accumulatedAmount: 0,
            claimsLen: claims.length
        });

        uint256[] memory result = new uint256[](locals.claimsLen);

        for (uint256 i = 0; i < locals.claimsLen; ++i) {
            ClaimParams memory data = claims[i];
            if (data.pct == 0) revert VaultClaimPercentageCannotBe0();
            if (data.beneficiary == address(0)) revert VaultClaimerCannotBe0();
            // if it's the last claim, just grab all remaining amount, instead
            // of relying on percentages
            uint256 localAmount = i == locals.claimsLen - 1
                ? _amount - locals.accumulatedAmount
                : _amount.pctOf(data.pct);

            result[i] = _createClaim(
                _groupId,
                localAmount,
                _lockedUntil,
                data,
                locals.totalShares,
                locals.totalUnderlying,
                _name
            );
            locals.accumulatedPct += data.pct;
            locals.accumulatedAmount += localAmount;
        }

        if (!locals.accumulatedPct.is100Pct()) revert VaultClaimsDontAddUp();

        return result;
    }

    /**
     * @dev `_createClaim` declares too many locals
     * We move some of them to this struct to fix the problem
     */
    struct CreateClaimLocals {
        uint256 newShares;
        address claimerId;
        uint256 tokenId;
    }

    function _createClaim(
        uint256 _depositGroupId,
        uint256 _amount,
        uint64 _lockedUntil,
        ClaimParams memory _claim,
        uint256 _localTotalShares,
        uint256 _localTotalPrincipal,
        string calldata _name
    ) internal returns (uint256) {
        // Checks if the user is not already in debt
        if (
            _computeShares(
                _applyLossTolerance(
                    claimers[_claim.beneficiary].totalPrincipal
                ),
                _localTotalShares,
                _localTotalPrincipal
            ) > claimers[_claim.beneficiary].totalShares
        ) revert VaultCannotDepositWhenClaimerInDebt();

        _depositTokenIds.increment();
        CreateClaimLocals memory locals = CreateClaimLocals({
            newShares: _computeShares(
                _amount,
                _localTotalShares,
                _localTotalPrincipal
            ),
            claimerId: _claim.beneficiary,
            tokenId: _depositTokenIds.current()
        });

        claimers[locals.claimerId].totalShares += locals.newShares;
        claimers[locals.claimerId].totalPrincipal += _amount;

        totalShares += locals.newShares;
        totalPrincipal += _amount;

        deposits[locals.tokenId] = Deposit(
            _amount,
            msg.sender,
            locals.claimerId,
            _lockedUntil
        );

        emit DepositMinted(
            locals.tokenId,
            _depositGroupId,
            _amount,
            locals.newShares,
            msg.sender,
            _claim.beneficiary,
            locals.claimerId,
            _lockedUntil,
            _claim.data,
            _name
        );

        return locals.tokenId;
    }

    /**
     * Reduces the principal and shares of the claimer.
     * If there were any yield to be claimed, the claimer will also keep shares to withdraw later on.
     *
     * @notice This function doesn't transfer any funds, it only updates the state.
     *
     * @notice Only the owner of the deposit may call this function.
     *
     * @param _tokenId The deposit ID to withdraw from.
     * @param _totalShares The total shares to consider for the withdraw.
     * @param _totalUnderlyingMinusSponsored The total underlying to consider for the withdraw.
     * @param _to Where the funds will be sent
     * @param _force If the withdraw should still withdraw if there are not enough funds in the vault.
     *
     * @return the amount to withdraw.
     */
    function _withdrawSingle(
        uint256 _tokenId,
        uint256 _totalShares,
        uint256 _totalUnderlyingMinusSponsored,
        address _to,
        bool _force,
        uint256 _amount
    ) internal returns (uint256) {
        if (deposits[_tokenId].owner != msg.sender)
            revert VaultNotOwnerOfDeposit();

        // memoizing saves warm sloads
        Deposit memory _deposit = deposits[_tokenId];
        Claimer memory _claim = claimers[_deposit.claimerId];

        if (_deposit.lockedUntil > block.timestamp) revert VaultDepositLocked();
        if (_deposit.claimerId == address(0)) revert VaultNotDeposit();
        if (_deposit.amount < _amount)
            revert VaultCannotWithdrawMoreThanAvailable();

        // Amount of shares the _amount is worth
        uint256 amountShares = _computeShares(
            _amount,
            _totalShares,
            _totalUnderlyingMinusSponsored
        );

        // Amount of shares the _amount is worth taking in the claimer's
        // totalShares and totalPrincipal
        uint256 claimerShares = (_amount * _claim.totalShares) /
            _claim.totalPrincipal;

        if (!_force && amountShares > claimerShares)
            revert VaultMustUseForceWithdrawToAcceptLosses();

        uint256 sharesToBurn = amountShares;

        if (_force && amountShares > claimerShares)
            sharesToBurn = claimerShares;

        claimers[_deposit.claimerId].totalShares -= sharesToBurn;
        claimers[_deposit.claimerId].totalPrincipal -= _amount;

        totalShares -= sharesToBurn;
        totalPrincipal -= _amount;

        bool isFull = _deposit.amount == _amount;

        if (isFull) {
            delete deposits[_tokenId];
        } else {
            deposits[_tokenId].amount -= _amount;
        }

        uint256 amount = _computeAmount(
            sharesToBurn,
            _totalShares,
            _totalUnderlyingMinusSponsored
        );

        emit DepositWithdrawn(_tokenId, sharesToBurn, amount, _to, isFull);

        return amount;
    }

    function _transferAndCheckInputToken(
        address _from,
        address _token,
        uint256 _amount
    ) internal {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));

        if (balanceAfter != balanceBefore + _amount)
            revert VaultAmountDoesNotMatchParams();
    }

    function _blockTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }

    /**
     * Computes amount of shares that will be received for a given deposit amount
     *
     * @param _amount Amount of deposit to consider.
     * @param _totalShares Amount of existing shares to consider.
     * @param _totalUnderlyingMinusSponsored Amount of existing underlying to consider.
     * @return Amount of shares the deposit will receive.
     */
    function _computeShares(
        uint256 _amount,
        uint256 _totalShares,
        uint256 _totalUnderlyingMinusSponsored
    ) internal pure returns (uint256) {
        if (_amount == 0) return 0;
        if (_totalShares == 0) return _amount * SHARES_MULTIPLIER;
        if (_totalUnderlyingMinusSponsored == 0)
            revert VaultCannotComputeSharesWithoutPrincipal();

        return (_amount * _totalShares) / _totalUnderlyingMinusSponsored;
    }

    /**
     * Computes the amount of underlying from a given number of shares
     *
     * @param _shares Number of shares.
     * @param _totalShares Amount of existing shares to consider.
     * @param _totalUnderlyingMinusSponsored Amounf of existing underlying to consider.
     * @return Amount that corresponds to the number of shares.
     */
    function _computeAmount(
        uint256 _shares,
        uint256 _totalShares,
        uint256 _totalUnderlyingMinusSponsored
    ) internal pure returns (uint256) {
        if (
            _shares == 0 ||
            _totalShares == 0 ||
            _totalUnderlyingMinusSponsored == 0
        ) {
            return 0;
        }

        return ((_totalUnderlyingMinusSponsored * _shares) / _totalShares);
    }

    /**
     * Applies a loss tolerance to the given @param _amount.
     *
     * This function is used to prevent the vault from entering loss mode when funds are lost due to fees in the strategy.
     * For instance, the fees taken by Anchor.
     *
     * @param _amount Amount to apply the fees to.
     *
     * @return Amount with the fees applied.
     */
    function _applyLossTolerance(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return _amount - _amount.pctOf(lossTolerancePct);
    }

    function sharesOf(address claimerId) external view returns (uint256) {
        return claimers[claimerId].totalShares;
    }

    function principalOf(address claimerId) external view returns (uint256) {
        return claimers[claimerId].totalPrincipal;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function exitPause() external onlyAdmin {
        _exitPause();
    }

    function exitUnpause() external onlyAdmin {
        _exitUnpause();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICurve} from "../interfaces/curve/ICurve.sol";

/// Helper abstract contract to manage curve swaps
abstract contract CurveSwapper {
    using SafeERC20 for IERC20;

    //
    // Structs
    //

    struct Swapper {
        /// Curve pool instance
        ICurve pool;
        /// decimals in token
        uint8 tokenDecimals;
        /// decimals in underlying
        uint8 underlyingDecimals;
        /// index of the deposit token we want to exchange to/from underlying
        int128 tokenI;
        /// index of underlying used by the vault (presumably always UST)
        int128 underlyingI;
    }

    struct SwapPoolParam {
        address token;
        address pool;
        int128 tokenI;
        int128 underlyingI;
    }

    //
    // Events
    //

    /// Emitted when a new swap pool is added
    event CurveSwapPoolAdded(
        address indexed token,
        address indexed pool,
        int128 tokenI,
        int128 underlyingI
    );

    /// Emitted when a swap pool is removed
    event CurveSwapPoolRemoved(address indexed token);

    /// Emitted after every swap
    event Swap(
        address indexed fromToken,
        address indexed toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    error SwapperPoolAlreadyExists(address token);
    error SwapperPoolDoesNotExist(address token);
    error SwapperUnderlyingIndexMismatch(address token, address underlying);

    //
    // State
    //

    /// token => curve pool (for trading token/underlying)
    mapping(address => Swapper) public swappers;

    /// @return The address of the vault's main underlying token
    function getUnderlying() public view virtual returns (address);

    /// Swaps a given amount of
    /// Only works if the pool has previously been inserted into the contract
    ///
    /// @param _token The token we want to swap into
    /// @param _amount The amount of underlying we want to swap
    /// @param _amountOutMin The minimum amount of tokens we want to receive
    function _swapIntoUnderlying(
        address _token,
        uint256 _amount,
        uint256 _amountOutMin
    ) internal returns (uint256 amount) {
        address underlyingToken = getUnderlying();
        if (_token == underlyingToken) {
            // same token, nothing to do
            return _amount;
        }

        Swapper storage swapper = swappers[_token];

        if (address(swapper.pool) == address(0x0)) {
            // pool does not exist
            revert SwapperPoolDoesNotExist(_token);
        }

        amount = swapper.pool.exchange_underlying(
            swapper.tokenI,
            swapper.underlyingI,
            _amount,
            _amountOutMin
        );

        emit Swap(_token, underlyingToken, _amount, amount);
    }

    /// Swaps a given amount of Underlying into a given token
    /// Only works if the pool has previously been inserted into the contract
    ///
    /// @param _token The token we want to swap into
    /// @param _amount The amount of underlying we want to swap
    /// @param _amountOutMin The minimum amount of tokens we want to receive
    function _swapFromUnderlying(
        address _token,
        uint256 _amount,
        uint256 _amountOutMin
    ) internal returns (uint256 amount) {
        // same token, nothing to do
        if (_token == getUnderlying()) return _amount;

        Swapper storage swapper = swappers[_token];

        if (address(swapper.pool) == address(0x0))
            revert SwapperPoolDoesNotExist(_token);

        amount = swapper.pool.exchange_underlying(
            swapper.underlyingI,
            swapper.tokenI,
            _amount,
            _amountOutMin
        );

        emit Swap(getUnderlying(), _token, _amount, amount);
    }

    /// This is necessary because some tokens (USDT) force you to approve(0)
    /// before approving a new amount meaning if we always approved blindly,
    /// then we could get random failures on the second attempt
    function _approveIfNecessary(address _token, address _pool) internal {
        uint256 allowance = IERC20(_token).allowance(address(this), _pool);

        if (allowance == 0) {
            IERC20(_token).safeApprove(_pool, type(uint256).max);
        }
    }

    /// @param _swapPools configs for each swap pool
    function _addPools(SwapPoolParam[] memory _swapPools) internal {
        uint256 length = _swapPools.length;
        for (uint256 i = 0; i < length; ++i) {
            _addPool(_swapPools[i]);
        }
    }

    function _addPool(SwapPoolParam memory _param) internal {
        if (address(swappers[_param.token].pool) != address(0))
            revert SwapperPoolAlreadyExists(_param.token);

        // _underlyingI does not match underlying token
        if (
            getUnderlying() !=
            ICurve(_param.pool).coins(uint256(uint128(_param.underlyingI)))
        ) revert SwapperUnderlyingIndexMismatch(_param.token, getUnderlying());

        uint256 tokenDecimals = IERC20Metadata(_param.token).decimals();
        uint256 underlyingDecimals = IERC20Metadata(getUnderlying()).decimals();

        swappers[_param.token] = Swapper(
            ICurve(_param.pool),
            uint8(tokenDecimals),
            uint8(underlyingDecimals),
            _param.tokenI,
            _param.underlyingI
        );

        _approveIfNecessary(getUnderlying(), address(_param.pool));
        _approveIfNecessary(_param.token, address(_param.pool));

        emit CurveSwapPoolAdded(
            _param.token,
            _param.pool,
            _param.tokenI,
            _param.underlyingI
        );
    }

    function _removePool(address _inputToken) internal {
        if (address(swappers[_inputToken].pool) == address(0))
            revert SwapperPoolDoesNotExist(_inputToken);

        delete swappers[_inputToken];

        emit CurveSwapPoolRemoved(_inputToken);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVault {
    //
    // Structs
    //

    struct ClaimParams {
        uint16 pct;
        address beneficiary;
        bytes data;
    }

    struct DepositParams {
        address inputToken;
        uint64 lockDuration;
        uint256 amount;
        ClaimParams[] claims;
        string name;
        uint256 amountOutMin;
    }

    struct Deposit {
        /// amount of the deposit
        uint256 amount;
        /// wallet of the owner
        address owner;
        /// wallet of the claimer
        address claimerId;
        /// when can the deposit be withdrawn
        uint256 lockedUntil;
    }

    struct Claimer {
        uint256 totalPrincipal;
        uint256 totalShares;
    }

    //
    // Events
    //

    event DepositMinted(
        uint256 indexed id,
        uint256 groupId,
        uint256 amount,
        uint256 shares,
        address indexed depositor,
        address indexed claimer,
        address claimerId,
        uint64 lockedUntil,
        bytes data,
        string name
    );

    event DepositWithdrawn(
        uint256 indexed id,
        uint256 shares,
        uint256 amount,
        address indexed to,
        bool burned
    );

    event Invested(uint256 amount);

    event Disinvested(uint256 amount);

    event YieldClaimed(
        address claimerId,
        address indexed to,
        uint256 amount,
        uint256 burnedShares,
        uint256 perfFee,
        uint256 totalUnderlying,
        uint256 totalShares
    );

    event FeeWithdrawn(uint256 amount);

    event MinLockPeriodUpdated(uint64 newMinLockPeriod);

    //
    // Public API
    //

    /**
     * Total amount of principal.
     */
    function totalPrincipal() external view returns (uint256);

    /**
     * The accumulated performance fee amount.
     */
    function accumulatedPerfFee() external view returns (uint256);

    /**
     * Update the invested amount;
     */
    function updateInvested() external;

    /**
     * Calculate maximum investable amount and already invested amount
     *
     * @return maxInvestableAmount maximum investable amount
     * @return alreadyInvested already invested amount
     */
    function investState()
        external
        view
        returns (uint256 maxInvestableAmount, uint256 alreadyInvested);

    /**
     * Percentage of the max investable amount until which a deposit is
     * immediately invested into the strategy.
     */
    function immediateInvestLimitPct() external view returns (uint16);

    /**
     * Percentage of the total underlying to invest in the strategy
     */
    function investPct() external view returns (uint16);

    /**
     * Underlying ERC20 token accepted by the vault
     */
    function underlying() external view returns (IERC20Metadata);

    /**
     * Minimum lock period for each deposit
     */
    function minLockPeriod() external view returns (uint64);

    /**
     * Total amount of underlying currently controlled by the
     * vault and the its strategy.
     */
    function totalUnderlying() external view returns (uint256);

    /**
     * Total amount of shares
     */
    function totalShares() external view returns (uint256);

    /**
     * Computes the amount of yield available for an an address.
     *
     * @param _to address to consider.
     *
     * @return claimable yield for @param _to, share of generated yield by @param _to,
     *      and performance fee from generated yield
     */
    function yieldFor(address _to)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * Accumulate performance fee and transfers rest yield generated for the caller to
     *
     * @param _to Address that will receive the yield.
     */
    function claimYield(address _to) external;

    /**
     * Creates a new deposit using the specified group id
     *
     * @param _groupId The group id for the new deposit
     * @param _params Deposit params
     */
    function depositForGroupId(uint256 _groupId, DepositParams calldata _params)
        external
        returns (uint256[] memory);

    /**
     * Creates a new deposit
     *
     * @param _params Deposit params
     */
    function deposit(DepositParams calldata _params)
        external
        returns (uint256[] memory);

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * It fails if the vault is underperforming and there are not enough funds
     * to withdraw the expected amount.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function withdraw(address _to, uint256[] calldata _ids) external;

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * When the vault is underperforming it withdraws the funds with a loss.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function forceWithdraw(address _to, uint256[] calldata _ids) external;

    /**
     * Withdraws any pending performance fee amount back to the treasury
     */
    function withdrawPerformanceFee() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IVaultSettings {
    //
    // Events
    //

    event ImmediateInvestLimitPctUpdated(uint256 percentage);
    event InvestPctUpdated(uint256 percentage);
    event TreasuryUpdated(address indexed treasury);
    event PerfFeePctUpdated(uint16 pct);
    event StrategyUpdated(address indexed strategy);
    event LossTolerancePctUpdated(uint16 pct);

    /**
     * Update immediate invest limit percentage
     *
     * Emits {ImmediateInvestLimitPctUpdated} event
     *
     * @param _pct the new immediate invest limit percentage
     */
    function setImmediateInvestLimitPct(uint16 _pct) external;

    /**
     * Update invest percentage
     *
     * Emits {InvestPctUpdated} event
     *
     * @param _investPct the new invest percentage
     */
    function setInvestPct(uint16 _investPct) external;

    /**
     * Changes the treasury used by the vault.
     *
     * @param _treasury the new strategy's address.
     */
    function setTreasury(address _treasury) external;

    /**
     * Changes the performance fee used by the vault.
     *
     * @param _perfFeePct the new performance fee.
     */
    function setPerfFeePct(uint16 _perfFeePct) external;

    /**
     * Changes the strategy used by the vault.
     *
     * @notice if there is invested funds in previous strategy, it is not allowed to set new strategy.
     * @param _strategy the new strategy's address.
     */
    function setStrategy(address _strategy) external;

    /**
     * Changes the estimated investment fee used by the strategy.
     *
     * @param _pct the new investment fee estimated percentage.
     */
    function setLossTolerancePct(uint16 _pct) external;

    /**
     * Sets the minimum lock period for deposits.
     *
     * @param _minLockPeriod Minimum lock period in seconds
     */
    function setMinLockPeriod(uint64 _minLockPeriod) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IVaultSponsoring {
    //
    // Events
    //

    /// Emitted when a new sponsor deposit is created
    event Sponsored(
        uint256 indexed id,
        uint256 amount,
        address indexed depositor,
        uint256 lockedUntil
    );

    /// Emitted when an existing sponsor withdraws
    event Unsponsored(
        uint256 indexed id,
        uint256 amount,
        address indexed to,
        bool burned
    );

    /**
     * Total amount currently sponsored
     */
    function totalSponsored() external view returns (uint256);

    /**
     * Creates a sponsored deposit with the amount provided in @param _amount.
     * Sponsored amounts will be invested like deposits, but unlike deposits
     * there are no claimers and the yield generated is donated to the vault.
     * The amount is locked until the timestamp specified in @param _lockedUntil.
     *
     * @param _inputToken The input token to deposit.
     * @param _amount Amount to sponsor.
     * @param _lockedUntil When the sponsor can unsponsor the amount.
     */
    function sponsor(
        address _inputToken,
        uint256 _amount,
        uint256 _lockedUntil,
        uint256 _slippage
    ) external;

    /**
     * Withdraws the sponsored amount for the deposits with the ids provided
     * in @param _ids and sends it to @param _to.
     *
     * It fails if the vault is underperforming and there are not enough funds
     * to withdraw the sponsored amount.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function unsponsor(address _to, uint256[] calldata _ids) external;

    /**
     * Withdraws the specified sponsored amounts @param _amounts for the deposits with the ids provided
     * in @param _ids and sends it to @param _to.
     *
     * @notice fails if there are not enough funds to withdraw the specified amounts.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     * @param _amounts Array with the amounts to withdraw.
     */
    function partialUnsponsor(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;
}