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

pragma solidity 0.8.16;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

struct AuthConfig {
	address owner;
	address guardian;
	address manager;
}

contract Auth is AccessControl {
	event OwnershipTransferInitiated(address owner, address pendingOwner);
	event OwnershipTransferred(address oldOwner, address newOwner);

	////////// CONSTANTS //////////

	/// Update vault params, perform time-sensitive operations, set manager
	bytes32 public constant GUARDIAN = keccak256("GUARDIAN");

	/// Hot-wallet bots that route funds between vaults, rebalance and harvest strategies
	bytes32 public constant MANAGER = keccak256("MANAGER");

	/// Add and remove vaults and strategies and other critical operations behind timelock
	/// Default admin role
	/// There should only be one owner, so it is not a role
	address public owner;
	address public pendingOwner;

	modifier onlyOwner() {
		require(msg.sender == owner, "ONLY_OWNER");
		_;
	}

	constructor(AuthConfig memory authConfig) {
		/// Set up the roles
		// owner can manage all roles
		owner = authConfig.owner;
		emit OwnershipTransferred(address(0), authConfig.owner);

		// TODO do we want cascading roles like this?
		_grantRole(DEFAULT_ADMIN_ROLE, authConfig.owner);
		_grantRole(GUARDIAN, owner);
		_grantRole(GUARDIAN, authConfig.guardian);
		_grantRole(MANAGER, authConfig.owner);
		_grantRole(MANAGER, authConfig.guardian);
		_grantRole(MANAGER, authConfig.manager);

		/// Allow the guardian role to manage manager
		_setRoleAdmin(MANAGER, GUARDIAN);
	}

	// ----------- Ownership -----------

	/// @dev Init transfer of ownership of the contract to a new account (`_pendingOwner`).
	/// @param _pendingOwner pending owner of contract
	/// Can only be called by the current owner.
	function transferOwnership(address _pendingOwner) external onlyOwner {
		pendingOwner = _pendingOwner;
		emit OwnershipTransferInitiated(owner, pendingOwner);
	}

	/// @dev Accept transfer of ownership of the contract.
	/// Can only be called by the pendingOwner.
	function acceptOwnership() external {
		require(msg.sender == pendingOwner, "ONLY_PENDING_OWNER");
		address oldOwner = owner;
		owner = pendingOwner;

		// revoke the DEFAULT ADMIN ROLE from prev owner
		_revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
		_revokeRole(GUARDIAN, oldOwner);
		_revokeRole(MANAGER, oldOwner);

		_grantRole(DEFAULT_ADMIN_ROLE, owner);
		_grantRole(GUARDIAN, owner);
		_grantRole(MANAGER, owner);

		emit OwnershipTransferred(oldOwner, owner);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Auth } from "./Auth.sol";
import { EAction } from "../interfaces/Structs.sol";
import { SectorErrors } from "../interfaces/SectorErrors.sol";

// import "hardhat/console.sol";

abstract contract StratAuth is Auth, SectorErrors {
	address public vault;

	modifier onlyVault() {
		if (msg.sender != vault) revert OnlyVault();
		_;
	}

	event EmergencyAction(address indexed target, bytes data);

	/// @notice calls arbitrary function on target contract in case of emergency
	function emergencyAction(EAction[] calldata actions) public payable onlyOwner {
		uint256 l = actions.length;
		for (uint256 i; i < l; ++i) {
			address target = actions[i].target;
			bytes memory data = actions[i].data;
			(bool success, ) = target.call{ value: actions[i].value }(data);
			require(success, "emergencyAction failed");
			emit EmergencyAction(target, data);
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { HarvestSwapParams } from "../../interfaces/Structs.sol";
import { SectorErrors } from "../../interfaces/SectorErrors.sol";

interface ISCYStrategy {
	function underlying() external view returns (IERC20);

	function deposit(uint256 amount) external returns (uint256);

	function redeem(address to, uint256 amount) external returns (uint256 amntOut);

	function closePosition(uint256 slippageParam) external returns (uint256);

	function getAndUpdateTvl() external returns (uint256);

	function getTvl() external view returns (uint256);

	function getMaxTvl() external view returns (uint256);

	function collateralToUnderlying() external view returns (uint256);

	function harvest(
		HarvestSwapParams[] calldata farm1Params,
		HarvestSwapParams[] calldata farm2Parms
	) external returns (uint256[] memory harvest1, uint256[] memory harvest2);

	function getWithdrawAmnt(uint256 lpTokens) external view returns (uint256);

	function getDepositAmnt(uint256 uAmnt) external view returns (uint256);

	function getLpBalance() external view returns (uint256);

	function getLpToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { HarvestSwapParams } from "../Structs.sol";
import { ISCYStrategy } from "./ISCYStrategy.sol";

struct SCYVaultConfig {
	string symbol;
	string name;
	address addr;
	uint16 strategyId; // this is strategy specific token if 1155
	bool acceptsNativeToken;
	address yieldToken;
	IERC20 underlying;
	uint128 maxTvl; // pack all params and balances
	uint128 balance; // strategy balance in underlying
	uint128 uBalance; // underlying balance
	uint128 yBalance; // yield token balance
}

interface ISCYVault {
	// scy deposit
	function deposit(
		address receiver,
		address tokenIn,
		uint256 amountTokenToPull,
		uint256 minSharesOut
	) external payable returns (uint256 amountSharesOut);

	function redeem(
		address receiver,
		uint256 amountSharesToPull,
		address tokenOut,
		uint256 minTokenOut
	) external returns (uint256 amountTokenOut);

	function getAndUpdateTvl() external returns (uint256 tvl);

	function getTvl() external view returns (uint256 tvl);

	function MIN_LIQUIDITY() external view returns (uint256);

	function underlying() external view returns (IERC20);

	function yieldToken() external view returns (address);

	function sendERC20ToStrategy() external view returns (bool);

	function strategy() external view returns (ISCYStrategy);

	function underlyingBalance(address) external view returns (uint256);

	function underlyingToShares(uint256 amnt) external view returns (uint256);

	function exchangeRateUnderlying() external view returns (uint256);

	function sharesToUnderlying(uint256 shares) external view returns (uint256);

	function getUpdatedUnderlyingBalance(address) external returns (uint256);

	function getFloatingAmount(address) external view returns (uint256);

	function getStrategyTvl() external view returns (uint256);

	function acceptsNativeToken() external view returns (bool);

	function underlyingDecimals() external view returns (uint8);

	function getMaxTvl() external view returns (uint256);

	function closePosition(uint256 minAmountOut, uint256 slippageParam) external;

	function initStrategy(address) external;

	function harvest(
		uint256 expectedTvl,
		uint256 maxDelta,
		HarvestSwapParams[] calldata swap1,
		HarvestSwapParams[] calldata swap2
	) external returns (uint256[] memory harvest1, uint256[] memory harvest2);

	function withdrawFromStrategy(uint256 shares, uint256 minAmountOut) external;

	function depositIntoStrategy(uint256 amount, uint256 minSharesOut) external;

	function uBalance() external view returns (uint256);

	function setMaxTvl(uint256) external;

	function getDepositAmnt(uint256 amount) external view returns (uint256);

	function getWithdrawAmnt(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface SectorErrors {
	error NotImplemented();
	error MaxTvlReached();
	error StrategyHasBalance();
	error MinLiquidity();
	error OnlyVault();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

enum CallType {
	ADD_LIQUIDITY_AND_MINT,
	BORROWB,
	REMOVE_LIQ_AND_REPAY
}

enum VaultType {
	Strategy,
	Aggregator
}

enum EpochType {
	None,
	Withdraw,
	Full
}

enum NativeToken {
	None,
	Underlying,
	Short
}

struct CalleeData {
	CallType callType;
	bytes data;
}
struct AddLiquidityAndMintCalldata {
	uint256 uAmnt;
	uint256 sAmnt;
}
struct BorrowBCalldata {
	uint256 borrowAmount;
	bytes data;
}
struct RemoveLiqAndRepayCalldata {
	uint256 removeLpAmnt;
	uint256 repayUnderlying;
	uint256 repayShort;
	uint256 borrowUnderlying;
	// uint256 amountAMin;
	// uint256 amountBMin;
}

struct HarvestSwapParams {
	address[] path; //path that the token takes
	uint256 min; // min price of in token * 1e18 (computed externally based on spot * slippage + fees)
	uint256 deadline;
	bytes pathData; // uniswap3 path data
}

struct IMXConfig {
	address vault;
	address underlying;
	address short;
	address uniPair;
	address poolToken;
	address farmToken;
	address farmRouter;
}

struct HLPConfig {
	string symbol;
	string name;
	address underlying;
	address short;
	address cTokenLend;
	address cTokenBorrow;
	address uniPair;
	address uniFarm;
	address farmToken;
	uint256 farmId;
	address farmRouter;
	address comptroller;
	address lendRewardRouter;
	address lendRewardToken;
	address vault;
	NativeToken nativeToken;
}

struct EAction {
	address target;
	uint256 value;
	bytes data;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

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
	) external returns (uint256);

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

	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { ICreditManagerV2, ICreditManagerV2Exceptions } from "./ICreditManagerV2.sol";
import { IVersion } from "./IVersion.sol";

struct MultiCall {
	address target;
	bytes callData;
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

interface ICreditFacade is ICreditFacadeExceptions, IVersion {
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
	function hasOpenedCreditAccount(address borrower) external view returns (bool);

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
	function transfersAllowed(address from, address to) external view returns (bool);

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
	function limits() external view returns (uint128 minBorrowedAmount, uint128 maxBorrowedAmount);

	/// @dev Address of the DegenNFT that gatekeeps account openings in whitelisted mode
	function degenNFT() external view returns (address);

	/// @dev Address of the underlying asset
	function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IPriceOracleV2 } from "./IPriceOracleV2.sol";
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
interface ICreditManagerV2 is ICreditManagerV2Events, ICreditManagerV2Exceptions, IVersion {
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
	/// @return True if token mask was change otherwise False
	function disableToken(address creditAccount, address token) external returns (bool);

	//
	// GETTERS
	//

	/// @dev Returns the address of a borrower's Credit Account, or reverts if there is none.
	/// @param borrower Borrower's address
	function getCreditAccountOrRevert(address borrower) external view returns (address);

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
	function enabledTokensMap(address creditAccount) external view returns (uint256);

	/// @dev Maps the Credit Account to its current percentage drop across all swaps since
	///      the last full check, in RAY format
	function cumulativeDropAtFastCheckRAY(address creditAccount) external view returns (uint256);

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
	function contractToAdapter(address targetContract) external view returns (address);

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
	function liquidationThresholds(address token) external view returns (uint16);

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

	/// @dev Paused() state
	function checkEmergencyPausable(address caller, bool state) external returns (bool);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
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
interface IPriceOracleV2 is IPriceOracleV2Events, IPriceOracleV2Exceptions, IVersion {
	/// @dev Converts a quantity of an asset to USD (decimals = 8).
	/// @param amount Amount to convert
	/// @param token Address of the token to be converted
	function convertToUSD(uint256 amount, address token) external view returns (uint256);

	/// @dev Converts a quantity of USD (decimals = 8) to an equivalent amount of an asset
	/// @param amount Amount to convert
	/// @param token Address of the token converted to
	function convertFromUSD(uint256 amount, address token) external view returns (uint256);

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
	function priceFeeds(address token) external view returns (address priceFeed);

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

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title IVersion
/// @dev Declares a version function which returns the contract's version
interface IVersion {
	/// @dev Returns contract version
	function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
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

	function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

	function withdrawAllAndUnwrap(bool claim) external;

	function getReward(address _account, bool _claimExtras) external returns (bool);

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

	function userRewardPerTokenPaid(address account) external view returns (uint256);

	function rewards(address account) external view returns (uint256);

	function extraRewards(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// import { IAdapter } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { ICurvePool } from "../../curve/ICurvePool.sol";

interface ICurveV1AdapterExceptions {
	error IncorrectIndexException();
}

interface ICurveV1Adapter is ICurvePool, ICurveV1AdapterExceptions {
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
	function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY) external;

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
	function calc_add_one_coin(uint256 amount, int128 i) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
	/// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
	/// @dev In the implementation you must pay the pool tokens owed for the swap.
	/// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
	/// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
	/// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
	/// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
	/// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
	/// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
	/// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
	function uniswapV3SwapCallback(
		int256 amount0Delta,
		int256 amount1Delta,
		bytes calldata data
	) external;
}

// SPDX-License-Identifier: GPL-2.0
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.16;

library BytesLib {
	function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
		require(_start + 20 >= _start, "toAddress_overflow");
		require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
		address tempAddress;

		assembly {
			tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
		}

		return tempAddress;
	}

	function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
		return address(uint160(uint256(bytesValue)));
	}

	function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
		return bytes32(bytes20(addressValue));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { EAction, HarvestSwapParams } from "../../interfaces/Structs.sol";
// import "hardhat/console.sol";

struct LevConvexConfig {
	address curveAdapter;
	address curveAdapterDeposit;
	address convexRewardPool;
	address creditFacade;
	uint16 coinId;
	address underlying;
	uint16 leverageFactor;
	address convexBooster;
	address farmRouter;
}

interface ILevConvex {
	/// @notice deposits underlying into the strategy
	/// @param amount amount of underlying to deposit
	function deposit(uint256 amount) external returns (uint256);

	/// @notice deposits underlying into the strategy
	/// @param amount amount of lp to withdraw
	function redeem(uint256 amount, address to) external returns (uint256);

	function harvest(HarvestSwapParams[] memory swapParams)
		external
		returns (uint256[] memory amountsOut);

	function closePosition() external returns (uint256);

	/// VIEW METHODS

	function getMaxTvl() external view returns (uint256);

	// this is actually not totally accurate
	function collateralToUnderlying() external view returns (uint256);

	function collateralBalance() external view returns (uint256);

	/// @dev gearbox accounting is overly concervative so we use calc_withdraw_one_coin
	/// to compute totalAsssets
	function getTotalTVL() external view returns (uint256);

	function getAndUpdateTVL() external view returns (uint256);

	function underlying() external view returns (address);

	function convexRewardPool() external view returns (address);

	function getWithdrawAmnt(uint256 amount) external view returns (uint256);

	function getDepositAmnt(uint256 amount) external view returns (uint256);

	event SetVault(address indexed vault);
	event AdjustLeverage(uint256 newLeverage);
	event HarvestedToken(address token, uint256 amount, uint256 amountUnderlying);
	event Deposit(address sender, uint256 amount);
	event Redeem(address sender, uint256 amount);

	error WrongVaultUnderlying();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ICreditFacade, ICreditManagerV2, MultiCall } from "../../interfaces/gearbox/ICreditFacade.sol";
import { AuthConfig } from "../../common/Auth.sol";
import { ISwapRouter } from "../../interfaces/uniswap/ISwapRouter.sol";
import { ICurveV1Adapter } from "../../interfaces/gearbox/adapters/ICurveV1Adapter.sol";
import { IBaseRewardPool } from "../../interfaces/gearbox/adapters/IBaseRewardPool.sol";
import { IBooster } from "../../interfaces/gearbox/adapters/IBooster.sol";
import { LevConvexConfig } from "./ILevConvex.sol";
import { levConvexBase } from "./levConvexBase.sol";

// import "hardhat/console.sol";

contract levConvex is levConvexBase {
	ICurveV1Adapter public curveAdapterDeposit;

	constructor(AuthConfig memory authConfig, LevConvexConfig memory config)
		levConvexBase(authConfig, config)
	{
		if (config.curveAdapterDeposit != address(0)) {
			curveAdapterDeposit = ICurveV1Adapter(config.curveAdapterDeposit);
		}
	}

	//// INTERNAL METHODS

	function _increasePosition(uint256 borrowAmnt, uint256 totalAmount) internal override {
		MultiCall[] memory calls = new MultiCall[](3);
		calls[0] = MultiCall({
			target: address(creditFacade),
			callData: abi.encodeWithSelector(ICreditFacade.increaseDebt.selector, borrowAmnt)
		});
		calls[1] = MultiCall({
			target: address(curveAdapter),
			callData: abi.encodeWithSelector(
				ICurveV1Adapter.add_liquidity_one_coin.selector,
				totalAmount,
				coinId,
				0 // slippage parameter is checked in the vault
			)
		});
		calls[2] = MultiCall({
			target: address(convexBooster),
			callData: abi.encodeWithSelector(IBooster.depositAll.selector, convexPid, true)
		});
		creditFacade.multicall(calls);
	}

	function _decreasePosition(uint256 lpAmount) internal override {
		uint256 repayAmnt = curveAdapter.calc_withdraw_one_coin(lpAmount, int128(uint128(coinId)));
		MultiCall[] memory calls = new MultiCall[](3);
		calls[0] = MultiCall({
			target: address(convexRewardPool),
			callData: abi.encodeWithSelector(
				IBaseRewardPool.withdrawAndUnwrap.selector,
				lpAmount,
				false
			)
		});

		// convert extra eth to underlying
		calls[1] = MultiCall({
			target: address(curveAdapter),
			callData: abi.encodeWithSelector(
				ICurveV1Adapter.remove_all_liquidity_one_coin.selector,
				coinId,
				0 // slippage is checked in the vault
			)
		});

		calls[2] = MultiCall({
			target: address(creditFacade),
			callData: abi.encodeWithSelector(ICreditFacade.decreaseDebt.selector, repayAmnt)
		});

		creditFacade.multicall(calls);
	}

	function _closePosition() internal override {
		MultiCall[] memory calls;
		calls = new MultiCall[](2);
		calls[0] = MultiCall({
			target: address(convexRewardPool),
			callData: abi.encodeWithSelector(IBaseRewardPool.withdrawAllAndUnwrap.selector, true)
		});

		// convert extra eth to underlying
		calls[1] = MultiCall({
			target: address(curveAdapter),
			callData: abi.encodeWithSelector(
				ICurveV1Adapter.remove_all_liquidity_one_coin.selector,
				coinId,
				0 // slippage is checked in the vault
			)
		});

		creditFacade.closeCreditAccount(address(this), 0, false, calls);
	}

	function _openAccount(uint256 amount) internal override {
		// todo oracle conversion from underlying to ETH
		uint256 borrowAmnt = (amount * leverageFactor) / 100;

		MultiCall[] memory calls = new MultiCall[](3);
		calls[0] = MultiCall({
			target: address(creditFacade),
			callData: abi.encodeWithSelector(
				ICreditFacade.addCollateral.selector,
				address(this),
				underlying,
				amount
			)
		});
		calls[1] = MultiCall({
			target: address(curveAdapter),
			callData: abi.encodeWithSelector(
				ICurveV1Adapter.add_liquidity_one_coin.selector,
				borrowAmnt + amount,
				coinId,
				0 // slippage parameter is checked in the vault
			)
		});
		calls[2] = MultiCall({
			target: address(convexBooster),
			callData: abi.encodeWithSelector(IBooster.depositAll.selector, convexPid, true)
		});

		creditFacade.openCreditAccountMulticall(borrowAmnt, address(this), calls, 0);
		credAcc = creditManager.getCreditAccountOrRevert(address(this));
	}

	/// VIEW METHODS

	function collateralToUnderlying() public view returns (uint256) {
		uint256 amountOut = curveAdapter.calc_withdraw_one_coin(1e18, int128(uint128(coinId)));
		uint256 currentLeverage = getLeverage();
		return (100 * amountOut) / currentLeverage;
	}

	function getTotalAssets() public view override returns (uint256 totalAssets) {
		if (credAcc == address(0)) return 0;
		totalAssets = curveAdapter.calc_withdraw_one_coin(
			convexRewardPool.balanceOf(credAcc),
			int128(uint128(coinId))
		);
	}

	/// @dev used to estimate slippage
	function getWithdrawAmnt(uint256 lpAmnt) public view returns (uint256) {
		return
			(100 * curveAdapter.calc_withdraw_one_coin(lpAmnt, int128(uint128(coinId)))) /
			getLeverage();
	}

	/// @dev used to estimate slippage
	function getDepositAmnt(uint256 uAmnt) public view returns (uint256) {
		uint256 amnt = (uAmnt * getLeverage()) / 100;
		if (address(curveAdapterDeposit) != address(0))
			return curveAdapterDeposit.calc_add_one_coin(amnt, int128(uint128(coinId)));
		return curveAdapter.calc_add_one_coin(amnt, int128(uint128(coinId)));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ICreditFacade, ICreditManagerV2 } from "../../interfaces/gearbox/ICreditFacade.sol";
import { IPriceOracleV2 } from "../../interfaces/gearbox/IPriceOracleV2.sol";
import { StratAuth } from "../../common/StratAuth.sol";
import { Auth, AuthConfig } from "../../common/Auth.sol";
import { ISCYVault } from "../../interfaces/ERC5115/ISCYVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICurveV1Adapter } from "../../interfaces/gearbox/adapters/ICurveV1Adapter.sol";
import { IBaseRewardPool } from "../../interfaces/gearbox/adapters/IBaseRewardPool.sol";
import { IBooster } from "../../interfaces/gearbox/adapters/IBooster.sol";
import { HarvestSwapParams } from "../../interfaces/Structs.sol";
import { ISwapRouter } from "../../interfaces/uniswap/ISwapRouter.sol";
import { BytesLib } from "../../libraries/BytesLib.sol";
import { LevConvexConfig } from "./ILevConvex.sol";
import { ISCYStrategy } from "../../interfaces/ERC5115/ISCYStrategy.sol";

// import "hardhat/console.sol";

abstract contract levConvexBase is StratAuth, ISCYStrategy {
	using SafeERC20 for IERC20;

	uint256 constant MIN_LIQUIDITY = 10**3;

	// USDC
	ICreditFacade public creditFacade;

	ICreditManagerV2 public creditManager;

	IPriceOracleV2 public priceOracle = IPriceOracleV2(0x6385892aCB085eaa24b745a712C9e682d80FF681);

	ISwapRouter public uniswapV3Adapter;

	ICurveV1Adapter public curveAdapter;
	ICurveV1Adapter public threePoolAdapter =
		ICurveV1Adapter(0xbd871de345b2408f48C1B249a1dac7E0D7D4F8f9);
	IBaseRewardPool public convexRewardPool;
	IBooster public convexBooster;
	ISwapRouter public farmRouter;

	IERC20 public farmToken;
	IERC20 public immutable underlying;

	uint16 convexPid;
	// leverage factor is how much we borrow in %
	// ex 2x leverage = 100, 3x leverage = 200
	uint16 public leverageFactor;
	uint256 immutable dec;
	uint256 constant shortDec = 1e18;
	address public credAcc; // gearbox credit account // TODO can it expire?
	uint16 coinId;
	bool threePool = true;

	event SetVault(address indexed vault);

	constructor(AuthConfig memory authConfig, LevConvexConfig memory config) Auth(authConfig) {
		underlying = IERC20(config.underlying);
		dec = 10**uint256(IERC20Metadata(address(underlying)).decimals());
		leverageFactor = config.leverageFactor;
		creditFacade = ICreditFacade(config.creditFacade);
		creditManager = ICreditManagerV2(creditFacade.creditManager());
		curveAdapter = ICurveV1Adapter(config.curveAdapter);
		convexRewardPool = IBaseRewardPool(config.convexRewardPool);
		convexBooster = IBooster(config.convexBooster);
		convexPid = uint16(convexRewardPool.pid());
		coinId = config.coinId;
		farmToken = IERC20(convexRewardPool.rewardToken());
		farmRouter = ISwapRouter(config.farmRouter);
		uniswapV3Adapter = ISwapRouter(creditManager.contractToAdapter(address(farmRouter)));
		// do we need granular approvals? or can we just approve once?
		// i.e. what happens after credit account is dilivered to someone else?
		underlying.approve(address(creditManager), type(uint256).max);
	}

	function setVault(address _vault) public onlyOwner {
		if (ISCYVault(_vault).underlying() != underlying) revert WrongVaultUnderlying();
		vault = _vault;
		emit SetVault(vault);
	}

	/// @notice deposits underlying into the strategy
	/// @param amount amount of underlying to deposit
	function deposit(uint256 amount) public onlyVault returns (uint256) {
		// TODO maxTvl check?
		uint256 startBalance = getLpBalance();
		if (credAcc == address(0)) _openAccount(amount);
		else {
			uint256 borrowAmnt = (amount * (leverageFactor)) / 100;
			creditFacade.addCollateral(address(this), address(underlying), amount);
			_increasePosition(borrowAmnt, borrowAmnt + amount);
		}
		emit Deposit(msg.sender, amount);
		// our balance should allays increase on deposits
		// adjust the collateralBalance by leverage amount
		return (getLpBalance() - startBalance);
	}

	/// @notice deposits underlying into the strategy
	/// @param amount amount of lp to withdraw
	function redeem(address to, uint256 amount) public onlyVault returns (uint256) {
		/// there is no way to partially withdraw collateral
		/// we have to close account and re-open it :\
		uint256 startLp = getLpBalance();
		_closePosition();
		uint256 uBalance = underlying.balanceOf(address(this));
		uint256 withdraw = (uBalance * amount) / startLp;

		(uint256 minBorrowed, ) = creditFacade.limits();
		uint256 minUnderlying = leverageFactor == 0
			? minBorrowed
			: (100 * minBorrowed) / leverageFactor;
		uint256 redeposit = uBalance > withdraw ? uBalance - withdraw : 0;

		if (redeposit > minUnderlying) {
			underlying.safeTransfer(to, withdraw);
			_openAccount(redeposit);
		} else {
			// do not re-open account
			credAcc = address(0);
			// send full balance to vault
			underlying.safeTransfer(to, uBalance);
		}

		emit Redeem(msg.sender, amount);
		return withdraw;
	}

	/// @dev manager should be able to lower leverage in case of emergency, but not increase it
	/// increase of leverage can only be done by owner();
	function adjustLeverage(uint16 newLeverage) public onlyRole(MANAGER) {
		if (msg.sender != owner && newLeverage > leverageFactor + 100)
			revert IncreaseLeveragePermissions();

		if (credAcc == address(0)) {
			leverageFactor = newLeverage - 100;
			emit AdjustLeverage(newLeverage);
			return;
		}

		uint256 totalAssets = getTotalAssets();
		(, , uint256 totalOwed) = creditManager.calcCreditAccountAccruedInterest(credAcc);

		if (totalOwed > totalAssets) revert BadLoan();
		uint256 currentLeverageFactor = ((100 * totalAssets) / (totalAssets - totalOwed));

		if (currentLeverageFactor > newLeverage) {
			uint256 lp = convexRewardPool.balanceOf(credAcc);
			uint256 repay = (lp * (currentLeverageFactor - newLeverage)) / currentLeverageFactor;
			_decreasePosition(repay);
		} else if (currentLeverageFactor < newLeverage) {
			// we need to increase leverage -> borrow more
			uint256 borrowAmnt = (getAndUpdateTvl() * (newLeverage - currentLeverageFactor)) / 100;
			_increasePosition(borrowAmnt, borrowAmnt);
		}
		/// leverageFactor used for opening & closing accounts
		leverageFactor = uint16(getLeverage()) - 100;
		emit AdjustLeverage(newLeverage);
	}

	function harvest(HarvestSwapParams[] memory swapParams, HarvestSwapParams[] memory)
		public
		onlyVault
		returns (uint256[] memory amountsOut, uint256[] memory)
	{
		if (credAcc == address(0)) return _harvestOwnTokens(swapParams);

		convexRewardPool.getReward();
		amountsOut = new uint256[](swapParams.length);
		for (uint256 i; i < swapParams.length; ++i) {
			IERC20 token = IERC20(BytesLib.toAddress(swapParams[i].pathData, 0));
			uint256 harvested = token.balanceOf(credAcc);
			if (harvested == 0) continue;
			ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
				path: swapParams[i].pathData,
				recipient: address(this),
				deadline: block.timestamp,
				amountIn: harvested,
				amountOutMinimum: swapParams[i].min
			});
			amountsOut[i] = uniswapV3Adapter.exactInput(params);
			emit HarvestedToken(address(farmToken), harvested, amountsOut[i]);
		}

		uint256 balance = underlying.balanceOf(credAcc);
		if (balance == 0) (amountsOut, new uint256[](0));

		uint256 borrowAmnt = (balance * leverageFactor) / 100;
		_increasePosition(borrowAmnt, borrowAmnt + balance);
		return (amountsOut, new uint256[](0));
	}

	// method to harvest if we have closed the credit account
	function _harvestOwnTokens(HarvestSwapParams[] memory swapParams)
		internal
		returns (uint256[] memory amountsOut, uint256[] memory)
	{
		amountsOut = new uint256[](swapParams.length);
		for (uint256 i; i < swapParams.length; ++i) {
			IERC20 token = IERC20(BytesLib.toAddress(swapParams[i].pathData, 0));
			uint256 harvested = token.balanceOf(address(this));
			if (harvested == 0) continue;
			if (token.allowance(address(this), address(farmRouter)) < harvested)
				token.safeApprove(address(farmRouter), type(uint256).max);
			ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
				path: swapParams[i].pathData,
				recipient: address(this),
				deadline: block.timestamp,
				amountIn: harvested,
				amountOutMinimum: swapParams[i].min
			});
			amountsOut[i] = farmRouter.exactInput(params);
			emit HarvestedToken(address(farmToken), harvested, amountsOut[i]);
		}
		uint256 balance = underlying.balanceOf(address(this));
		underlying.safeTransfer(vault, balance);
		return (amountsOut, new uint256[](0));
	}

	function closePosition(uint256) public onlyVault returns (uint256) {
		// withdraw all rewards
		convexRewardPool.getReward();
		_closePosition();
		credAcc = address(0);
		uint256 balance = underlying.balanceOf(address(this));
		underlying.safeTransfer(vault, balance);
		return balance;
	}

	//// INTERNAL METHODS

	function _increasePosition(uint256 borrowAmnt, uint256 totalAmount) internal virtual;

	function _decreasePosition(uint256 lpAmount) internal virtual;

	function _closePosition() internal virtual;

	function _openAccount(uint256 amount) internal virtual;

	/// VIEW METHODS

	function loanHealth() public view returns (uint256) {
		// if account is closed our health is 1000%
		if (credAcc == address(0)) return 100e18;
		// gearbox returns basis points, we convert it to 10,000 => 100% => 1e18
		return 1e14 * creditFacade.calcCreditAccountHealthFactor(credAcc);
	}

	function getLeverage() public view returns (uint256) {
		if (credAcc == address(0)) return leverageFactor + 100;
		(, , uint256 totalOwed) = creditManager.calcCreditAccountAccruedInterest(credAcc);
		uint256 totalAssets = getTotalAssets();
		/// this means we're in an upredictable state and should revert
		if (totalOwed > totalAssets) revert BadLoan();
		return ((100 * totalAssets) / (totalAssets - totalOwed));
	}

	function getMaxTvl() public view returns (uint256) {
		(, uint256 maxBorrowed) = creditFacade.limits();
		if (leverageFactor == 0) return maxBorrowed;
		return (100 * maxBorrowed) / leverageFactor;
	}

	/// @dev gearbox accounting is overly concervative so we use calc_withdraw_one_coin
	/// to compute totalAsssets
	function getTvl() public view returns (uint256) {
		if (credAcc == address(0)) return 0;
		(, , uint256 totalOwed) = creditManager.calcCreditAccountAccruedInterest(credAcc);
		uint256 totalAssets = getTotalAssets();
		return totalAssets > totalOwed ? totalAssets - totalOwed : 0;
	}

	function getTotalAssets() public view virtual returns (uint256 totalAssets);

	function getAndUpdateTvl() public view returns (uint256) {
		return getTvl();
	}

	function getLpToken() public view returns (address) {
		return address(convexRewardPool);
	}

	function getLpBalance() public view returns (uint256) {
		if (credAcc == address(0)) return 0;
		return convexRewardPool.balanceOf(credAcc);
	}

	event AdjustLeverage(uint256 newLeverage);
	event HarvestedToken(address token, uint256 amount, uint256 amountUnderlying);
	event Deposit(address sender, uint256 amount);
	event Redeem(address sender, uint256 amount);

	error BadLoan();
	error IncreaseLeveragePermissions();
	error WrongVaultUnderlying();
}