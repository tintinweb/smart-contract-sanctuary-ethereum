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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/MissionStructs.sol";
import "./lib/MissionEvents.sol";
import "./lib/DistributionsUtility.sol";
import "./lib/Signatory.sol";

contract ArcadeMissionPools is AccessControl, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Counters for Counters.Counter;

  /**
   * @notice A Mission Pool Operator (MPO) is responsible
   *      for creating and closing Mission(s)
   * @dev Role ROLE_MISSION_POOL_OPERATOR allows
   *      to create missions (calling 'createMission'
   *      function) and close missions (calling
   *      'closeMission' function)
   */
  bytes32 public constant ROLE_MISSION_POOL_OPERATOR =
    0x0000000000000000000000000000000000000000000000000000000000000008;

  /**
   * @notice BASE_EARLY_FEE is the general contract fee for
   *      early withdrawals from a mission pool that is active
   */
  uint256 public BASE_EARLY_FEE;

  /**
   * @notice The address of the signatory wallet for contract interactions
   */
  address public SIGNATORY;

  /**
   * @notice xArcade is the default token for Mission Pool
   *      funding
   */
  IERC20 public xArcadeToken;

  /**
   * @notice A list of missions created by MPOs
   * @dev This mapping records missions and stores their
   *      data in a Mission struct
   *      missionId => Mission struct
   */
  mapping(uint256 => MissionStructs.Mission) public missions;

  /**
   * @notice A counter for the missionId to reference Missions
   * @dev Incremented up during createMission function
   */
  Counters.Counter public missionIdCounter;

  /**
   * @notice A list of mission distributions created at mission creation
   * @dev This mapping records mission distributions and stores their
   *      data in a Mission Distribution struct
   *      missionId => Mission Distribution struct
   */
  mapping(uint256 => MissionStructs.MissionDistributions)
    public missionDistributions;

  /**
   * @notice A list of mission debriefs created at mission close
   * @dev This mapping records missions and stores their
   *      data in a Mission Debrief struct
   *      missionId => Mission Debrief struct
   */
  mapping(uint256 => MissionStructs.MissionDebrief) public missionDebriefs;

  /**
   * @notice A list of MPCs who invested in a mission
   * @dev This mapping tracks MPC addresses that have invested
   *      in a specific mission
   *      missionId => counter => MPC address
   */
  mapping(uint256 => mapping(uint256 => address)) public investors;

  /**
   * @notice A counter for the total amount of investors
   *      in a specifc mission
   * @dev This mapping counts the MPCs that have invested
   *      in a specific mission
   *      missionId => counter
   */
  mapping(uint256 => Counters.Counter) public investorCount;

  /**
   * @notice A record of if a MPC invested in a mission
   * @dev This mapping keeps a record of MPC addresses that
   *      have invested in a specific mission
   *      missionId => MPC address => true/false
   */
  mapping(uint256 => mapping(address => bool)) public invested;

  /**
   * @notice A record of a MPC's total investments to a mission
   * @dev This mapping keeps a record of all deposits by
   *      a MPC to a specified mission
   *      MPC address => missionId => amountInvested
   */
  mapping(address => mapping(uint256 => uint256)) public investments;

  /**
   * @notice A record of the asset lenders associated to a Mission
   * @dev This mapping keeps a record of all asset lenders
   *      associated to a specified mission
   *     missionId => assetLenderAddress => true/false
   */
  mapping(uint256 => mapping(address => bool)) public assetLenders;

  /**
   * @notice A counter for the total asset lenders for a mission
   * @dev This mapping counts the asset lenders that have
   *      been added to a specific mission
   */
  mapping(uint256 => Counters.Counter) public assetLenderCount;

  /**
   * @notice A list of approved IERC20 tokens for use in
   *      Mission Pools
   * @dev This mapping keeps a record of all approved tokens
   *      for MPOs to use in Mission Pools
   *      IERC20 address => true/false
   */
  mapping(IERC20 => bool) public approvedTokens;

  /**
   * @notice earlyWithdrawalFees is the contract storage fee for
   *      early withdrawals from mission pools
   * @dev This mapping keeps a record of fees collected by token
   *      IERC20 address => total tokens collected
   */
  mapping(IERC20 => uint256) public earlyWithdrawalFees;

  /**
   * @notice Contract Constructor
   * @dev Deploys the smart contract, assigns address of
   *      xArcade ERC20 token, sets msg.sender to the
   *      DEFAULT_ADMIN_ROLE and ROLE_MISSION_POOL_OPERATOR
   * @param _xArcadeToken token address to set for xArcade
   * @param _BASE_EARLY_FEE the standard fee for early withdrawals
   * @param _SIGNATORY the address of the signatory wallet for contract interactions
   */
  constructor(
    address _xArcadeToken,
    uint256 _BASE_EARLY_FEE,
    address _SIGNATORY
  ) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ROLE_MISSION_POOL_OPERATOR, msg.sender);
    xArcadeToken = IERC20(_xArcadeToken);
    BASE_EARLY_FEE = _BASE_EARLY_FEE;
    SIGNATORY = _SIGNATORY;
  }

  /**
   * @notice Allows MPO to create a mission pool
   *
   * @dev Called by address with ROLE_MISSION_POOL_OPERATOR
   * @dev Throws on the following restriction errors:
   *      * mission token provided not approved for mission pools
   *      * max investment cannot be 0
   * @dev Returns no response on success
   *      MissionCreated event emitted
   *
   * @param _token the token for the mission pool to accept for funding
   * @param _poolTarget the target amount of funding for the mission pool
   * @param _fee the fee on early withdrawals from mission pool
   * @param _maxMpcInvestment anti-whale measure to limit funding by any
   *      one account
   * @param _platformFeePoints the basis points for platform fee
   * @param _mpoFeePoints the basis points for MPO fee
   * @param _mpcRewardPoints the basis points for MPC reward
   * @param _lenderRewardPoints the basis points for asset lender rewards
   */
  function createMission(
    IERC20 _token,
    uint256 _poolTarget,
    uint256 _fee,
    uint256 _maxMpcInvestment,
    uint256 _platformFeePoints,
    uint256 _mpoFeePoints,
    uint256 _mpcRewardPoints,
    uint256 _lenderRewardPoints,
    string calldata _hashHex,
    bytes calldata _key
  ) public onlyRole(ROLE_MISSION_POOL_OPERATOR) {
    require(
      Signatory.verifySignatory(
        Signatory.hashHexAddress(_hashHex, address(this), msg.sender),
        _key,
        SIGNATORY
      ),
      "Invalid signature for creating mission"
    );
    if (_token != xArcadeToken) {
      require(
        approvedTokens[_token],
        "Mission token must be an approved token"
      );
    }
    require(_poolTarget > 0, "The pool target cannot be zero");
    require(_maxMpcInvestment > 0, "The max investment cannot be zero");
    require(
      _poolTarget > _maxMpcInvestment,
      "Max investment cannot be greater than pool target"
    );

    missions[missionIdCounter.current()] = MissionStructs.Mission({
      token: _token,
      poolTarget: _poolTarget,
      fee: _fee,
      maxMpcInvestment: _maxMpcInvestment,
      poolAmount: 0,
      feesCollected: 0,
      status: 0,
      missionCreator: msg.sender
    });

    missionDistributions[missionIdCounter.current()] = MissionStructs
      .MissionDistributions({
        platformFeePoints: _platformFeePoints,
        mpoFeePoints: _mpoFeePoints,
        mpcRewardPoints: _mpcRewardPoints,
        lenderRewardPoints: _lenderRewardPoints
      });

    emit MissionEvents.MissionCreated(
      missionIdCounter.current(),
      _token,
      _poolTarget,
      _fee,
      _maxMpcInvestment,
      _platformFeePoints,
      _mpoFeePoints,
      _mpcRewardPoints,
      _lenderRewardPoints
    );

    missionIdCounter.increment();
  }

  /**
   * @notice Allows MPC to fund a mission pool
   *
   * @dev Throws on the following restriction errors:
   *      * mission is not in the funding state
   *      * funding period has ended
   *      * max investment for MPC is exceeded
   *      * max funding for the mission pool is exceeded
   *      * token for funding not approved for transfer
   * @dev Returns no response on success
   *      MissionFunded event emitted
   *
   * @param _missionId the ID of the mission pool to fund
   * @param _value the amount of tokens the MPC is funding the mission pool
   * @param _token the token the MPC sends for funding mission
   */
  function fundMission(
    uint256 _missionId,
    uint256 _value,
    IERC20 _token,
    string calldata _hashHex,
    bytes calldata _key
  ) public payable isMissionFunding(missions[_missionId].status) nonReentrant {
    require(
      Signatory.verifySignatory(
        Signatory.hashHexAddress(_hashHex, address(this), msg.sender),
        _key,
        SIGNATORY
      ),
      "Invalid signature for funding mission"
    );
    require(
      _token.allowance(msg.sender, address(this)) >= _value,
      "Approve tokens for use with Mission Pools first!"
    );
    require(
      investments[msg.sender][_missionId] + _value <=
        missions[_missionId].maxMpcInvestment,
      "Exceeded max investment for Mission Pool"
    );
    require(
      investments[msg.sender][_missionId] + _value <=
        missions[_missionId].poolTarget,
      "Exceeded the pool target"
    );
    _token.safeTransferFrom(msg.sender, address(this), _value);
    if (
      (missions[_missionId].poolAmount + _value) ==
      missions[_missionId].poolTarget
    ) {
      missions[_missionId].status = 1;
    }
    investments[msg.sender][_missionId] += _value;
    investors[_missionId][investorCount[_missionId].current()] = address(
      msg.sender
    );
    invested[_missionId][msg.sender] = true;
    investorCount[_missionId].increment();
    missions[_missionId].poolAmount += _value;
    emit MissionEvents.MissionFunded(_missionId, msg.sender, _value);
  }

  /**
   * @notice Function to end funding status for Mission Pool
   *
   * @dev Throws on the following restriction errors:
   *      * mission is not in the funding state
   *      * funding period has not ended
   *
   * @param _missionId the ID of the mission pool to end
   */
  function endMissionFunding(
    uint256 _missionId,
    string calldata _hashHex,
    bytes calldata _key
  )
    public
    onlyRole(ROLE_MISSION_POOL_OPERATOR)
    isMissionFunding(missions[_missionId].status)
    isMissionMpo(_missionId)
    nonReentrant
  {
    require(
      Signatory.verifySignatory(
        Signatory.hashHexAddress(_hashHex, address(this), msg.sender),
        _key,
        SIGNATORY
      ),
      "Invalid signature for ending mission funding"
    );
    missions[_missionId].status = 2;
    emit MissionEvents.FundingEnded(_missionId, false);
  }

  /**
   * @notice Function to end funding status for Mission Pool
   *
   * @dev Throws on the following restriction errors:
   *      * mission is not in the funding state
   *      * funding period has not ended
   *
   * @param _missionId the ID of the mission pool to end
   */
  function endMissionTopOffFunding(
    uint256 _missionId
  )
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    isMissionFunding(missions[_missionId].status)
    nonReentrant
  {
    uint256 topOffAmount = missions[_missionId].poolTarget -
      missions[_missionId].poolAmount;

    require(
      topOffAmount > 0,
      "Mission Pool is already fully funded, no top off needed"
    );
    require(
      missions[_missionId].token.allowance(msg.sender, address(this)) >=
        topOffAmount,
      "Approve tokens for use with Mission Pools first!"
    );

    missions[_missionId].token.safeTransferFrom(
      msg.sender,
      address(this),
      topOffAmount
    );

    investments[msg.sender][_missionId] += topOffAmount;
    investors[_missionId][investorCount[_missionId].current()] = address(
      msg.sender
    );
    invested[_missionId][msg.sender] = true;
    investorCount[_missionId].increment();
    missions[_missionId].poolAmount += topOffAmount;
    missions[_missionId].status = 1;

    emit MissionEvents.MissionFunded(_missionId, msg.sender, topOffAmount);
    emit MissionEvents.FundingEnded(_missionId, true);
  }

  /**
   * @notice Function called by MPO to end a mission, set its success
   *      or failure, and allocate rewards for a successful mission
   *
   * @dev Throws on the following restriction errors:
   *      * Caller does not have ROLE_MISSION_POOL_OPERATOR
   *      * Mission is not in an active state
   *      * Called before missionEndDate
   *      * Caller is not MPO who created mission or Contract Admin
   *      * If mission is true on _result, _reward cannot be 0
   * @dev Returns silently on completion
   *      Emits MissionClosed event
   *
   * @param _missionId the ID of the mission pool to close
   * @param _result boolean of whether the mission succeeded or failed
   * @param _reward the total reward to be allocated for MPCs who
   *      funded the mission pool
   */
  function closeMission(
    uint256 _missionId,
    bool _result,
    uint256 _reward,
    string calldata _hashHex,
    bytes calldata _key
  )
    public
    payable
    onlyRole(ROLE_MISSION_POOL_OPERATOR)
    isMissionMpo(_missionId)
    isMissionActive(missions[_missionId].status)
    nonReentrant
  {
    require(
      Signatory.verifySignatory(
        Signatory.hashHexAddress(_hashHex, address(this), msg.sender),
        _key,
        SIGNATORY
      ),
      "Invalid signature for closing mission"
    );
    if (_result) {
      require(_reward > 0, "Reward must be greater than zero");

      // Transfers reward tokens to the mission pool
      missions[_missionId].token.safeTransferFrom(
        msg.sender,
        address(this),
        _reward
      );

      missionDebriefs[_missionId] = MissionStructs.MissionDebrief({
        missionPoolCloseAmount: missions[_missionId].poolAmount,
        missionReward: _reward,
        missionSuccess: _result
      });

      // Sets mission to finished successful status
      missions[_missionId].status = 3;
      // Adds _reward to the mission poolAmount
      missions[_missionId].poolAmount += _reward;

      emit MissionEvents.MissionClosed(_missionId, _result, _reward);
    } else {
      missions[_missionId].status = 2;

      missionDebriefs[_missionId] = MissionStructs.MissionDebrief({
        missionPoolCloseAmount: missions[_missionId].poolAmount,
        missionReward: _reward,
        missionSuccess: _result
      });

      emit MissionEvents.MissionClosed(_missionId, _result, _reward);
    }
  }

  /**
   * @notice This is an internal contract function that is called
   *      by Mission Pool contract functions. It authorizes
   *      withdrawal and transfer funds when a Mission is successful.
   *
   *      It contains the calculation of rewards to distribute,
   *      checks to see if mission pool has enough funds to transfer,
   *      transfers total investment and rewards to MPC, decrements
   *      mission pool amount based on amount withdrawn, and marks
   *      MPC as no longer being vested in mission pool.
   *
   * @dev Throws on the following restriction errors:
   *      * missions poolAmount does not have enough funds
   * @dev MPC rewarded token amount calculated with ratio of
   *      an individual MPC contribution to the total of all
   *      MPC contributions
   * @dev Returns silently on completion
   *      Emits WithdrawFunds event
   *
   * @param _missionId the mission ID of the mission to withdraw from
   * @param _contributor the MPC to return funds with rewards to
   * @param _amount the total amount the MPC funded the mission with
   */
  function _withdrawalWithRewards(
    uint256 _missionId,
    address _contributor,
    uint256 _amount
  ) internal {
    // variable to store MPC reward based on ratio of MPC funding
    // to MP closing balance
    uint256 mpcReward = DistributionsUtility.calculateMpcDistribution(
      missionDebriefs[_missionId].missionPoolCloseAmount,
      _amount,
      missionDebriefs[_missionId].missionReward,
      missionDistributions[_missionId].mpcRewardPoints
    );

    // variable to store the MPC investment and rewards to withdraw
    uint256 rewardsWithdrawal = _amount + mpcReward;

    require(
      rewardsWithdrawal <= missions[_missionId].poolAmount,
      "Not enough mission pool funds remaining to withdraw from"
    );

    // transfer tokens from MP to MPC
    missions[_missionId].token.safeTransferFrom(
      address(this),
      _contributor,
      rewardsWithdrawal
    );

    // decrement the poolAmount with the rewards withdrawn
    missions[_missionId].poolAmount -= rewardsWithdrawal;

    // set MPC invested variable to false post withdrawal
    invested[_missionId][_contributor] = false;

    emit MissionEvents.WithdrawFunds(
      _missionId,
      _contributor,
      rewardsWithdrawal,
      mpcReward,
      0
    );
  }

  /**
   * @notice This is an internal contract function that is called
   *      by Mission Pool contract functions. It authorizes
   *      withdrawal and transfer funds when a Mission has failed.
   *
   *      It contains the check to see if mission pool has enough
   *      funds to transfer, transfers total investment back to MPC,
   *      decrements mission pool amount based on amount withdrawn,
   *      and marks MPC as no longer being vested in mission pool.
   *
   * @dev Throws on the following restriction errors:
   *      * missions poolAmount does not have enough funds
   * @dev Returns silently on completion
   *      Emits WithdrawFunds event
   *
   * @param _missionId the mission ID of the mission to withdraw from
   * @param _contributor the MPC to return funds with rewards to
   * @param _amount the total amount the MPC funded the mission with
   */
  function _withdrawalNoRewards(
    uint256 _missionId,
    address _contributor,
    uint256 _amount
  ) internal {
    require(
      _amount <= missions[_missionId].poolAmount,
      "Not enough mission pool funds remaining to withdraw from"
    );

    // transfer tokens from MP to MPC
    missions[_missionId].token.safeTransferFrom(
      address(this),
      _contributor,
      _amount
    );

    // decrement the poolAmount with the investment withdrawn
    missions[_missionId].poolAmount -= _amount;

    // set MPC invested variable to false post withdrawal
    invested[_missionId][_contributor] = false;

    emit MissionEvents.WithdrawFunds(_missionId, _contributor, _amount, 0, 0);
  }

  /**
   * @notice Function for MPC to withdraw funds early from Mission
   *      Pool after funding completes and before mission end date
   *
   * @dev Throws on the following restriction errors:
   *      * MPC has no investment in Mission Pool to withdraw
   *      * MPC has not approved tokens for transfer
   *      * Mission is not in active state to withdraw early
   * @dev Returns silently on completion
   *      Emits WithdrawFunds event
   *
   * @param _missionId the ID of the mission pool to withdraw from
   */
  function earlyWithdrawalFromMission(
    uint256 _missionId
  )
    public
    payable
    nonReentrant
    mpcInvested(_missionId)
    isMissionActive(missions[_missionId].status)
  {
    require(
      missions[_missionId].token.allowance(msg.sender, address(this)) >=
        (investments[msg.sender][_missionId]),
      "Approve tokens first!"
    );

    uint256 investmentToWithdraw = investments[msg.sender][_missionId];

    uint256 earlyWithdrawalFee = DistributionsUtility
      .calculateEarlyWithdrawalPenalty(
        investments[msg.sender][_missionId],
        missions[_missionId].fee
      );

    uint256 taxedWithdrawal = investmentToWithdraw - earlyWithdrawalFee;

    missions[_missionId].poolAmount -= investmentToWithdraw;

    // Store fees by token to contract
    earlyWithdrawalFees[missions[_missionId].token] += earlyWithdrawalFee;

    // Store quantity of early withdrawal fees for mission
    missions[_missionId].feesCollected += earlyWithdrawalFee;

    missions[_missionId].token.safeTransferFrom(
      address(this),
      msg.sender,
      taxedWithdrawal
    );

    investments[msg.sender][_missionId] = 0;

    invested[_missionId][msg.sender] = false;

    emit MissionEvents.WithdrawFunds(
      _missionId,
      msg.sender,
      taxedWithdrawal,
      0,
      earlyWithdrawalFee
    );
  }

  /**
   * @notice Function for MPC to withdraw funds when mission is completed.
   *      If mission failed, returns only contributed funds to MPC.
   *      If mission succeeds, calculate investment reward and return
   *      original investment and reward.
   *      Increments poolAmount and rewardPool for mission with _missionId
   *
   * @dev Throws on the following restriction errors:
   *      * Caller has no funds to withdraw from mission
   *      * Caller has not approved token for transfer
   * @dev Returns silently on completion
   *      Emits WithdrawFunds event
   *
   * @param _missionId the mission ID of the mission to withdraw from
   */
  function withdrawalFromMission(
    uint256 _missionId
  )
    public
    payable
    nonReentrant
    mpcInvested(_missionId)
    isMissionClosed(missions[_missionId].status)
  {
    require(
      missions[_missionId].token.allowance(msg.sender, address(this)) >=
        (investments[msg.sender][_missionId]),
      "Approve tokens first!"
    );

    // variable to store MPC's funding to withdraw
    uint256 investmentToWithdraw = investments[msg.sender][_missionId];

    if (missions[_missionId].status == 3) {
      // Mission Succeeded
      _withdrawalWithRewards(_missionId, msg.sender, investmentToWithdraw);
    } else {
      // Mission Failed
      _withdrawalNoRewards(_missionId, msg.sender, investmentToWithdraw);
    }
  }

  /**
   * @notice Function for Admin or MPO to add an asset lender to a mission
   *
   * @dev Throws on the following restriction errors:
   *     * Caller is not a Contract Admin or MPO
   * @dev Returns silently on completion
   *    Emits AssetLenderAdded event
   *
   * @param _missionId the mission ID of the mission to add asset lender to
   * @param _assetLender the address of the asset lender to add
   */
  function addAssetLender(
    uint256 _missionId,
    address _assetLender
  )
    public
    onlyRole(ROLE_MISSION_POOL_OPERATOR)
    isMissionFunding(missions[_missionId].status)
    nonReentrant
  {
    assetLenders[_missionId][_assetLender] = true;
    assetLenderCount[_missionId].increment();
  }

  /**
   * @notice Function for asset lender to withdraw rewards from a mission
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not an asset lender for the mission
   *      * Mission is not in ended success status
   *
   * @param _missionId the mission ID of the mission to withdraw from
   */
  function assetLenderRewardWithdrawal(
    uint256 _missionId
  )
    public
    payable
    nonReentrant
    isAssetLender(_missionId)
    isMissionSuccessful(missions[_missionId].status)
  {
    uint256 assetLenderReward = DistributionsUtility
      .calculateLenderDistribution(
        missionDebriefs[_missionId].missionReward,
        assetLenderCount[_missionId].current(),
        missionDistributions[_missionId].lenderRewardPoints
      );

    missions[_missionId].token.safeTransferFrom(
      address(this),
      msg.sender,
      assetLenderReward
    );

    emit MissionEvents.WithdrawFunds(
      _missionId,
      msg.sender,
      0,
      assetLenderReward,
      0
    );
  }

  /**
   * @notice Function for MPO to withdraw rewards from a mission
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the MPO for the mission
   *      * Mission is not in ended success status
   *
   * @param _missionId the mission ID of the mission to withdraw from
   */
  function mpoRewardWithdrawal(
    uint256 _missionId
  )
    public
    payable
    nonReentrant
    onlyRole(ROLE_MISSION_POOL_OPERATOR)
    isMissionSuccessful(missions[_missionId].status)
  {
    uint256 mpoReward = DistributionsUtility.calculateMpoDistribution(
      missionDebriefs[_missionId].missionReward,
      missionDistributions[_missionId].mpoFeePoints
    );

    missions[_missionId].token.safeTransferFrom(
      address(this),
      msg.sender,
      mpoReward
    );

    emit MissionEvents.WithdrawFunds(_missionId, msg.sender, 0, mpoReward, 0);
  }

  /**
   * @notice Emergency administrator function to return funds from mission
   *      pool to MPCs based on their investments
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the contract administrator
   *      * Mission is not in ended failed or success status
   * @dev Returns boolean of successful withdrawal
   *      Emits WithdrawFunds event
   *
   * @param _missionId the mission ID of the mission to withdraw from
   */
  function returnMissionPoolFunding(
    uint256 _missionId
  )
    public
    payable
    onlyRole(DEFAULT_ADMIN_ROLE)
    isMissionClosed(missions[_missionId].status)
  {
    // Check to see if mission was successful to determine calling _withdrawalWithRewards
    // or _withdrawalNoRewards
    if (missions[_missionId].status == 3) {
      // Mission Succeeded
      for (uint256 idx = 0; idx < investorCount[_missionId].current(); ) {
        address missionPoolContributor = investors[_missionId][idx];
        if (invested[_missionId][missionPoolContributor]) {
          uint256 fundsToReturn = investments[missionPoolContributor][
            _missionId
          ];
          // call internal function with rewards distribution calculation
          _withdrawalWithRewards(
            _missionId,
            missionPoolContributor,
            fundsToReturn
          );
        }
        unchecked {
          idx++;
        }
      }
    } else {
      // Mission Failed
      for (uint256 idx = 0; idx < investorCount[_missionId].current(); ) {
        address missionPoolContributor = investors[_missionId][idx];
        if (invested[_missionId][missionPoolContributor]) {
          uint256 fundsToReturn = investments[missionPoolContributor][
            _missionId
          ];
          // call internal function with to distribute initial investment
          _withdrawalNoRewards(
            _missionId,
            missionPoolContributor,
            fundsToReturn
          );
        }
        unchecked {
          idx++;
        }
      }
    }
  }

  /**
   * @notice This function allows a Contract Admin to withdraw fees collected
   *      from early withdrawals from the mission pool
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not a Contract Admin
   *      * No fees to collect
   *      * Token is not xArcade or approved token
   * @dev Sets feesCollected to zero (0) after funds transfer
   *
   * @param _tokenAddress the ERC20 token address to withdraw fees in
   * @param _feeReceiver the account address to receive mission fees
   */
  function withdrawEarlyFees(
    address _tokenAddress,
    address _feeReceiver
  ) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
    if (IERC20(_tokenAddress) != xArcadeToken) {
      require(
        approvedTokens[IERC20(_tokenAddress)],
        "Mission token must be an approved token"
      );
    }
    require(
      earlyWithdrawalFees[IERC20(_tokenAddress)] > 0,
      "There are no fees to collect for this token"
    );

    // Store total fees collected into variable for event emission
    uint256 totalFeesCollected = earlyWithdrawalFees[IERC20(_tokenAddress)];

    // Transfer all fees collected to _feeReceiver
    IERC20(_tokenAddress).safeTransferFrom(
      address(this),
      _feeReceiver,
      totalFeesCollected
    );

    earlyWithdrawalFees[IERC20(_tokenAddress)] = 0;

    emit MissionEvents.WithdrawFees(
      _feeReceiver,
      _tokenAddress,
      totalFeesCollected
    );
  }

  /**
   * @notice Function called by Contract Admin to add an address
   *      to the ROLE_MISSION_POOL_OPERATOR
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the Contract Admin
   * @dev Returns silently on completion
   *      Emits RoleGranted event
   *
   * @param _missionPoolOperator the address to add as a MPO
   */
  function addMissionPoolOperator(
    address _missionPoolOperator
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(ROLE_MISSION_POOL_OPERATOR, _missionPoolOperator);
    emit MissionEvents.RoleGranted(
      "Mission Pool Operator",
      _missionPoolOperator
    );
  }

  /**
   * @notice Function called by Contract Admin to remove an address
   *      from the ROLE_MISSION_POOL_OPERATOR
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the Contract Admin
   * @dev Returns silently on completion
   *      Emits RoleRevoked event
   *
   * @param _missionPoolOperator the address to add as a MPO
   */
  function removeMissionPoolOperator(
    address _missionPoolOperator
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(ROLE_MISSION_POOL_OPERATOR, _missionPoolOperator);
    emit MissionEvents.RoleRevoked(
      "Mission Pool Operator",
      _missionPoolOperator
    );
  }

  /**
   * @notice This function approves an ERC20 token for Mission Pool funding
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the Contract Administrator
   *      * Token is already approved for mission pools
   *
   * @param _tokenAddress the address of the token to approve for Mission Pool
   */
  function approveMissionPoolToken(
    address _tokenAddress
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      !approvedTokens[IERC20(_tokenAddress)],
      "Token is already approved for mission pools"
    );
    approvedTokens[IERC20(_tokenAddress)] = true;
    emit MissionEvents.TokenApproved(_tokenAddress);
  }

  /**
   * @notice This function revokes approval of an ERC20 token for
   *      Mission Pool funding
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the Contract Administrator
   *      * Token is does not need to be revoked
   *
   * @param _tokenAddress the address of the token to approve for Mission Pool
   */
  function revokeMissionPoolToken(
    address _tokenAddress
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      approvedTokens[IERC20(_tokenAddress)],
      "Token is not approved for mission pools. Does not need to be revoked."
    );
    approvedTokens[IERC20(_tokenAddress)] = false;
    emit MissionEvents.TokenRevoked(_tokenAddress);
  }

  /**
   * @notice This function revokes approval of an ERC20 token for
   *      Mission Pool funding
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the Contract Administrator
   *
   * @param _newFee the fee to update as the standard contract fee
   */
  function updateStandardFee(
    uint256 _newFee
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    BASE_EARLY_FEE = _newFee;
    emit MissionEvents.StandardFeeUpdated(BASE_EARLY_FEE);
  }

  /**
   * @notice Set a new signing wallet address for contract interactions
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the Contract Administrator
   *
   * @param _signatory A new signatory wallet address
   */
  function setSignatory(
    address _signatory
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    SIGNATORY = _signatory;
  }

  /**
   * @notice This function allows an administrator to update a mission pool
   *      in the event of an emergency issue in mission pool settings.
   *
   * @dev Throws on the following restriction errors:
   *      * Caller is not the Contract Administrator
   *      * max investment cannot be 0
   *
   * @param _token the token for the mission pool to accept for funding
   * @param _poolTarget the target amount of funding for the mission pool
   * @param _fee the fee on early withdrawals from mission pool
   * @param _maxMpcInvestment anti-whale measure to limit funding by any
   *      one account
   * @param _platformFeePoints the basis points for platform fee
   * @param _mpoFeePoints the basis points for MPO fee
   * @param _mpcRewardPoints the basis points for MPC reward
   * @param _lenderRewardPoints the basis points for asset lender rewards
   */
  function updateMissionPool(
    uint256 _missionId,
    IERC20 _token,
    uint256 _poolTarget,
    uint256 _fee,
    uint256 _maxMpcInvestment,
    uint256 _platformFeePoints,
    uint256 _mpoFeePoints,
    uint256 _mpcRewardPoints,
    uint256 _lenderRewardPoints
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_token != xArcadeToken) {
      require(
        approvedTokens[_token],
        "Mission token must be an approved token"
      );
    }
    require(_maxMpcInvestment > 0, "The max investment cannot be zero");
    if (missions[_missionId].token != _token) {
      missions[_missionId].token = _token;
    }
    if (missions[_missionId].poolTarget != _poolTarget) {
      missions[_missionId].poolTarget = _poolTarget;
    }
    if (missions[_missionId].fee != _fee) {
      missions[_missionId].fee = _fee;
    }
    if (missions[_missionId].maxMpcInvestment != _maxMpcInvestment) {
      missions[_missionId].maxMpcInvestment = _maxMpcInvestment;
    }
    if (
      missionDistributions[_missionId].platformFeePoints != _platformFeePoints
    ) {
      missionDistributions[_missionId].platformFeePoints = _platformFeePoints;
    }
    if (missionDistributions[_missionId].mpoFeePoints != _mpoFeePoints) {
      missionDistributions[_missionId].mpoFeePoints = _mpoFeePoints;
    }
    if (missionDistributions[_missionId].mpcRewardPoints != _mpcRewardPoints) {
      missionDistributions[_missionId].mpcRewardPoints = _mpcRewardPoints;
    }
    if (
      missionDistributions[_missionId].lenderRewardPoints != _lenderRewardPoints
    ) {
      missionDistributions[_missionId].lenderRewardPoints = _lenderRewardPoints;
    }

    emit MissionEvents.MissionUpdated(
      _missionId,
      _token,
      _poolTarget,
      _fee,
      _maxMpcInvestment,
      _platformFeePoints,
      _mpoFeePoints,
      _mpcRewardPoints,
      _lenderRewardPoints
    );
  }

  /**
   * @notice Modifier that requires msg.sender to have funded the mission
   *      pool being withdrawn
   * @dev Required in earlyWithdrawalFromMission and withdrawalFromMission
   * @param _missionId the mission to check investments for account
   */
  modifier mpcInvested(uint256 _missionId) {
    require(
      invested[_missionId][msg.sender],
      "No investments to withdraw from mission pool"
    );
    _;
  }

  /**
   * @notice Modifier that requires msg.sender to be a mission pool operator
   * @dev Required in endMissionFunding
   */
  modifier isMissionMpo(uint256 _missionId) {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
      require(
        missions[_missionId].missionCreator == msg.sender,
        "Must be the MPO that created mission or Administrator"
      );
    }
    _;
  }

  /**
   * @notice Modifier that requires msg.sender to be an asset lender for
   *      the mission pool
   * @dev Required in addAssetLender
   * @param _missionId the mission to check asset lenders for account
   */
  modifier isAssetLender(uint256 _missionId) {
    require(
      assetLenders[_missionId][msg.sender],
      "Not an asset lender for mission pool"
    );
    _;
  }

  /**
   * @notice Modifier that requires mission to be in funding state
   * @dev Required in fundMission, endMission, and addAssetLender
   * @param _missionStatus the mission status to check
   */
  modifier isMissionFunding(uint256 _missionStatus) {
    require(_missionStatus == 0, "Mission is not in funding state");
    _;
  }

  /**
   * @notice Modifier that requires mission to be in active state
   * @dev Required in closeMission and earlyWithdrawalFromMission
   * @param _missionStatus the mission status to check
   */
  modifier isMissionActive(uint256 _missionStatus) {
    require(_missionStatus == 1, "Mission not in active state");
    _;
  }

  /**
   * @notice Modifier that requires mission to be in ended state
   * @dev Required in returnMissionPoolFunding and withdrawalFromMission
   * @param _missionStatus the mission status to check
   */
  modifier isMissionClosed(uint256 _missionStatus) {
    require(_missionStatus >= 2, "Mission is not in ended state");
    _;
  }

  /**
   * @notice Modifier that requires mission to be successfully completed
   * @dev Required in mpoRewardWithdrawal and assetLenderRewardWithdrawal
   * @param _missionStatus the mission status to check
   */
  modifier isMissionSuccessful(uint256 _missionStatus) {
    require(_missionStatus == 3, "Mission is not in successful state");
    _;
  }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library DistributionsUtility {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS = 10_000;

    /**
     * @notice Function that calculates the early withdrawal penalty
     * @param _mpcFundedAmount Total amount of tokens funded by MPC
     * @param _missionFeeBasisPoints Basis points of mission fee
     */
    function calculateEarlyWithdrawalPenalty(
        uint256 _mpcFundedAmount,
        uint256 _missionFeeBasisPoints
    ) internal pure returns (uint256) {
        // Calculate the early withdrawal penalty based on mission fee basis points
        uint256 earlyWithdrawalPenalty = (_mpcFundedAmount *
            _missionFeeBasisPoints) / BASIS_POINTS;

        return earlyWithdrawalPenalty;
    }

    /**
     * @notice Function that calculates the amount of tokens to be distributed
     * @param _totalFunded Total funded to a mission
     * @param _mpcFundedAmount Total amount of tokens funded by MPC
     * @param _missionRewardAmount Total amount of reward tokens to be distributed
     * @param _mpcDistributionBasisPoints Basis points of MPC distribution
     */
    function calculateMpcDistribution(
        uint256 _totalFunded,
        uint256 _mpcFundedAmount,
        uint256 _missionRewardAmount,
        uint256 _mpcDistributionBasisPoints
    ) internal pure returns (uint256) {
        // Calculate the MPC percentage shares to 2 decimal places pre basis point division
        uint256 mpcPercentShares = (_mpcFundedAmount * BASIS_POINTS) /
            _totalFunded;

        // The total reward amount based on the MPC percentage shares
        uint256 mpcPredistributionRewardShare = (_missionRewardAmount *
            mpcPercentShares) / BASIS_POINTS;

        // Calculate the MPC distribution based on mission pool distribution basis points
        uint256 mpcDistributionAmount = (mpcPredistributionRewardShare *
            _mpcDistributionBasisPoints) / BASIS_POINTS;

        return mpcDistributionAmount;
    }

    /**
     * @notice Function that calculates the amount of tokens to be distributed to MPO
     * @param _missionRewardAmount Total amount of reward tokens to be distributed
     * @param _mpoDistributionBasisPoints Basis points of MPC distribution
     */
    function calculateMpoDistribution(
        uint256 _missionRewardAmount,
        uint256 _mpoDistributionBasisPoints
    ) internal pure returns (uint256) {
        // Calculate the MPO distribution based on mission pool distribution basis points
        uint256 mpoDistributionAmount = (_missionRewardAmount *
            _mpoDistributionBasisPoints) / BASIS_POINTS;

        return mpoDistributionAmount;
    }

    /**
     * @notice Function that calculates the amount of tokens to be distributed to MPO
     * @param _missionRewardAmount Total amount of reward tokens to be distributed
     * @param _totalLenders Total amount of lenders
     * @param _lenderDistributionBasisPoints Basis points of MPC distribution
     */
    function calculateLenderDistribution(
        uint256 _missionRewardAmount,
        uint256 _totalLenders,
        uint256 _lenderDistributionBasisPoints
    ) internal pure returns (uint256) {
        // Calculate the Lender distribution based on mission pool distribution basis points
        uint256 totalLenderDistributionAmount = (_missionRewardAmount *
            _lenderDistributionBasisPoints) / BASIS_POINTS;

        // Calculate the Lender shares based off the total lenders
        uint256 lenderShares = (totalLenderDistributionAmount * BASIS_POINTS) /
            _totalLenders;

        // Calculate the Lender distribution based on lenderShares
        uint256 lenderDistributionAmount = lenderShares / BASIS_POINTS;

        return lenderDistributionAmount;
    }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library MissionEvents {
    using SafeERC20 for IERC20;
    
    /**
     * @dev Fired in createMission()
     *
     * @param missionId the missionId of the mission
     * @param token the token for funding the mission
     * @param poolTarget the target funding the mission
     * @param fee the early withdrawal fee for the mission
     * @param maxMpcInvestment max investment for any single MPC
     *      on the mission
     * @param platformFeePoints the basis points for platform fee
     * @param mpoFeePoints the basis points for MPO fee
     * @param mpcRewardPoints the basis points for MPC reward
     * @param lenderRewardPoints the basis points for asset lender rewards
     */
    event MissionCreated(
        uint256 indexed missionId,
        IERC20 token,
        uint256 poolTarget,
        uint256 fee,
        uint256 maxMpcInvestment,
        uint256 platformFeePoints,
        uint256 mpoFeePoints,
        uint256 mpcRewardPoints,
        uint256 lenderRewardPoints
    );

    /**
     * @dev Fired in fundMission()
     *
     * @param missionId the missionId of the mission
     * @param investor the MPC that funded the mission
     * @param value the amount that funded to the mission
     */
    event MissionFunded(
        uint256 indexed missionId,
        address indexed investor,
        uint256 value
    );

    /**
     * @dev Fired in endMissionFunding()
     *
     * @param missionId the missionId of the mission funding ended
     * @param fundingSuccess boolean if the funding was successful
     */
    event FundingEnded(uint256 indexed missionId, bool fundingSuccess);

    /**
     * @dev Fired in closeMission()
     *
     * @param missionId the missionId of the mission
     * @param success whether the mission was successful
     * @param reward the amount of reward for the mission
     */
    event MissionClosed(
        uint256 indexed missionId,
        bool success,
        uint256 reward
    );

    /**
     * @dev Fired in earlyWithdrawalFromMission(), _withdrawalWithRewards(),
     *      and _withdrawalNoRewards()
     *
     * @param missionId the missionId of the mission
     * @param investor the MPC that withdrew the mission
     * @param value the amount of withdrawal from the mission
     * @param rewards the amount of rewards, if any
     * @param withdrawFees the amount of withdrawal fees, if any
     */
    event WithdrawFunds(
        uint256 indexed missionId,
        address indexed investor,
        uint256 value,
        uint256 rewards,
        uint256 withdrawFees
    );

    /**
     * @dev Fired in withdrawEarlyFees()
     *
     * @param receiver the receiver of the early withdrawal fees
     * @param tokenReceived the token received
     * @param amountReceived amount of the token received
     */
    event WithdrawFees(
        address indexed receiver,
        address indexed tokenReceived,
        uint256 amountReceived
    );

    /**
     * @dev Fired in addAssetLender()
     *
     * @param missionId the missionId of the mission
     * @param assetLender the asset lender added to the mission
     */
    event AssetLenderAdded(
        uint256 indexed missionId,
        address indexed assetLender
    );

    /**
     * @dev Fired in addMissionPoolOperator() and addContractAdmin()
     *
     * @param roleGranted the role granted by a function
     * @param account address that is granted role
     */
    event RoleGranted(string roleGranted, address indexed account);

    /**
     * @dev Fired in removeMissionPoolOperator() and removeContractAdmin()
     *
     * @param roleRevoked the role revoked by a function
     * @param account address that had role revoked
     */
    event RoleRevoked(string roleRevoked, address indexed account);

    /**
     * @dev Fired in approveMissionPoolToken()
     *
     * @param tokenAdded the token approved for mission pool funding
     */
    event TokenApproved(address indexed tokenAdded);

    /**
     * @dev Fired in revokeMissionPoolToken()
     *
     * @param tokenRemoved the token revoked from mission pool funding
     */
    event TokenRevoked(address indexed tokenRemoved);

    /**
     * @dev Fired in updateStandardFee()
     *
     * @param newFee the new early withdrawal fee set by administrator
     */
    event StandardFeeUpdated(uint256 newFee);

    /**
     * @dev Fired in updateMissionPool()
     *
     * @param missionId the missionId of the mission
     * @param token the token for funding the mission
     * @param poolTarget the target funding the mission
     * @param fee the early withdrawal fee for the mission
     * @param maxMpcInvestment max investment for any single MPC
     *      on the mission
     * @param platformFeePoints the basis points for platform fee
     * @param mpoFeePoints the basis points for MPO fee
     * @param mpcRewardPoints the basis points for MPC reward
     * @param lenderRewardPoints the basis points for asset lender rewards
     */
    event MissionUpdated(
        uint256 indexed missionId,
        IERC20 token,
        uint256 poolTarget,
        uint256 fee,
        uint256 maxMpcInvestment,
        uint256 platformFeePoints,
        uint256 mpoFeePoints,
        uint256 mpcRewardPoints,
        uint256 lenderRewardPoints
    );
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library MissionStructs {
    using SafeERC20 for IERC20;
    
    /**
     * @notice A Mission is an investment goal for a MPO
     *      to perform mission pool contributors (MPC)
     *      desired action set forth by MPO
     */
    struct Mission {
        /**
         * @dev token is an ERC20 token that will be
         *      required by MPO for MPC to fund
         *      mission with
         */
        IERC20 token;
        /**
         * @dev status is the current mission state
         *      * 0: Funding Stage
         *      * 1: Mission Active
         *      * 2: Mission Ended (Failed)
         *      * 3: Mission Ended (Success)
         */
        uint8 status;
        /**
         * @dev poolTarget is the total investment goal
         *      of the specified token for the mission
         */
        uint256 poolTarget;
        /**
         * @dev fee is the tax on MPC withdrawing from
         *      a mission before missionEndDate
         */
        uint256 fee;
        /**
         * @dev feesCollected are the taxes collected from
         *      MPC withdrawing from before missionEndDate
         */
        uint256 feesCollected;
        /**
         * @dev maxMpcInvestment is the maximum amount of
         *      tokens a MPC can fund the mission with
         */
        uint256 maxMpcInvestment;
        /**
         * @dev poolAmount is the currently funded amount
         *      of tokens to the mission
         */
        uint256 poolAmount;
        /** @dev missionCreator is the MPO that created the mission */
        address missionCreator;
    }

    /**
     * @notice A Mission Debrief is a struct containing the closing
     *      details of a mission
     */
    struct MissionDebrief {
        /**
         * @dev missionPoolCloseAmount is the amount of tokens
         *      the mission has on closing. Used for calculating
         *      reward to distribute
         */
        uint256 missionPoolCloseAmount;
        /**
         * @dev missionReward is the amount of tokens the MPO
         *      has provided for the successful mission has on
         *      closing. Used for calculating reward to distribute
         */
        uint256 missionReward;
        /** @dev missionSuccess is a boolean of if the mission succeeded */
        bool missionSuccess;
    }

    /**
     * @notice A Mission Distribution is a struct containing the
     *      distribution points for a mission, should equal 10,000
     */
    struct MissionDistributions {
        /** @dev platformFeePoints is the basis points for platform fee */
        uint256 platformFeePoints;
        /** @dev mpoFeePoints is the basis points for MPO fee */
        uint256 mpoFeePoints;
        /** @dev mpcRewardPoints is the basis points for MPC reward */
        uint256 mpcRewardPoints;
        /** @dev lenderRewardPoints is the basis points for asset lender rewards */
        uint256 lenderRewardPoints;
    }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Signatory {
    using ECDSA for bytes32;

    /**
     * @notice Function that creates hash from randomHex and msgSender
     * @param _randomHex A random hex generated from signature
     * @param _missionPoolContract The address of the mission pool contract
     * @param _msgSender The wallet address of the message sender
     */
    function hashHexAddress(
        string calldata _randomHex,
        address _missionPoolContract,
        address _msgSender
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_randomHex, _missionPoolContract, _msgSender));
    }

    /**
     * @notice Function that verifies hash with signatory
     * @param _hash A hash generated using keccak256
     * @param _key Marker for usage of a hash
     * @param _signatory The wallet address of the message signer
     */
    function verifySignatory(
        bytes32 _hash,
        bytes memory _key,
        address _signatory
    ) internal pure returns (bool) {
        return (recoverSignatory(_hash, _key) == _signatory);
    }

    /**
     * @notice Function that recovers signed message from hash using key
     * @param _hash A hash generated using keccak256
     * @param _key Marker for usage of a hash
     */
    function recoverSignatory(
        bytes32 _hash,
        bytes memory _key
    ) internal pure returns (address) {
        return _hash.toEthSignedMessageHash().recover(_key);
    }
}