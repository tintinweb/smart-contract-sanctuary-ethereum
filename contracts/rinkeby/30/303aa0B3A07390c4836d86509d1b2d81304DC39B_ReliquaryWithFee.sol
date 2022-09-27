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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IBlockHistory.sol";
import "./interfaces/IFeeDelegate.sol";
import "./lib/Facts.sol";

struct PendingProver {
    uint64 timestamp;
    uint64 version;
}

struct ProverInfo {
    uint64 version;
    FeeInfo feeInfo;
    bool revoked;
}

// It would be nice if these could be stored in ReliquaryWithFee, but we want
// to store fee information in ProverInfo for gas optimization.
enum FeeFlags {
    FeeNone,
    FeeNative,
    FeeCredits,
    FeeExternalDelegate,
    FeeExternalToken
}

struct FeeInfo {
    uint8 flags;
    uint16 feeCredits;
    // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
    uint8 feeWeiMantissa;
    uint8 feeWeiExponent;
    uint32 feeExternalId;
}

/**
 * @title Holder of Relics and Artifacts
 * @author Theori, Inc.
 * @notice The Reliquary is the heart of Relic. All issuers of Relics and Artifacts
 *         must be added to the Reliquary. Queries about Relics and Artifacts should
 *         be made to the Reliquary.
 */
contract Reliquary is AccessControl {
    /// Minimum delay before a new prover can be active
    uint64 public constant DELAY = 2 days;

    bytes32 public constant ADD_PROVER_ROLE = keccak256("ADD_PROVER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    /// Once initialized, new provers can only be added with a delay
    bool public initialized;
    /// Append-only map of added prover addresses to information on them
    mapping(address => ProverInfo) public provers;
    /**
     *  Reverse mapping of version information to the unique prover able
     *  to issue statements with that version
     */
    mapping(uint64 => address) public versions;
    /// List of provers that may be added to the Reliquary, for public scrutiny
    mapping(address => PendingProver) public pendingProvers;

    mapping(address => mapping(FactSignature => bytes)) internal provenFacts;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Issued when a new prover is accepted into the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that will always be associated with the prover
     */
    event NewProver(address prover, uint64 version);

    /**
     * @notice Issued when a new prover is placed under consideration for acceptance
     *         into the Reliquary
     * @param prover the address of the prover contract
     * @param version the proposed identifier to always be associated with the prover
     * @param timestamp the earliest this prover can be brought into the Reliquary
     */
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);

    /**
     * @notice Issued when an existing prover is banished from the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that can never be used again
     * @dev revoked provers may not issue new Relics or Artifacts. The meaning of
     *      any previously introduced Relics or Artifacts is implementation dependent.
     */
    event ProverRevoked(address prover, uint64 version);

    /**
     * @notice Helper function to parse fact storage
     * @param fact The data associated with the proven Relic or Artifact
     * @return version the version identifier of the prover who introduced this item
     * @return data any data associated with this item
     */
    function parseFact(bytes storage fact)
        internal
        pure
        returns (uint64 version, bytes memory data)
    {
        // copy the storage bytes to memory
        data = fact;

        if (data.length > 0) {
            require(data.length >= 8, "fact data length invalid");

            // version is stored in first 8 bytes of the data
            version = uint64(bytes8(data));

            // rather than copy the rest of the data to a new bytes array,
            // just point data to data + 8 and setup length field
            assembly {
                let len := mload(data)
                data := add(data, 8)
                mstore(data, sub(len, 8))
            }
        }
    }

    /**
     * @notice Helper function to query the status of a prover
     * @param prover the ProverInfo associated with the prover in question
     * @dev reverts if the prover is invalid or revoked
     */
    function checkProver(ProverInfo memory prover) public pure {
        require(prover.revoked != true, "revoked prover");
        require(prover.version != 0, "unknown prover");
    }

    /**
     * @notice Deletes the fact from the Reliquary
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being deleted
     * @dev May only be called by non-revoked provers
     */
    function resetFact(address account, FactSignature factSig) external {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        delete provenFacts[account][factSig];
    }

    /**
     * @notice Adds the given information to the Reliquary
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being proven
     * @param data Associated data to store with this item
     * @dev May only be called by non-revoked provers
     */
    function setFact(
        address account,
        FactSignature factSig,
        bytes calldata data
    ) external {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        provenFacts[account][factSig] = abi.encodePacked(prover.version, data);
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        (version, data) = parseFact(provenFacts[account][factSig]);
        exists = version != 0;
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by the Reliquary itself
     */
    function _verifyFact(address account, FactSignature factSig)
        internal
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        (version, data) = parseFact(provenFacts[account][factSig]);
        exists = version != 0;
    }

    /**
     * @notice Query for some information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is only for use by the Reliquary itself
     */
    function _verifyFactVersion(address account, FactSignature factSig)
        internal
        view
        returns (bool exists, uint64 version)
    {
        version = uint64(bytes8(provenFacts[account][factSig]));
        exists = version != 0;
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        require(Facts.toFactClass(factSig) == Facts.NO_FEE);
        return _verifyFact(account, factSig);
    }

    /**
     * @notice Query for some information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version)
    {
        require(Facts.toFactClass(factSig) == Facts.NO_FEE);
        return _verifyFactVersion(account, factSig);
    }

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) public view returns (bool) {
        ProverInfo memory proverInfo = provers[msg.sender];
        checkProver(proverInfo);
        return IBlockHistory(verifier).validBlockHash(hash, num, proof);
    }

    /**
     * @notice Asserts that a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view {
        require(validBlockHashFromProver(verifier, hash, num, proof), "invalid block hash");
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        require(tx.origin == address(0));
        return _verifyFact(account, factSig);
    }

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool) {
        require(tx.origin == address(0));
        return IBlockHistory(verifier).validBlockHash(hash, num, proof);
    }

    /*
     * Allow a new prover to produce facts. Provers must have distinct versions.
     *
     * Once added, a new prover is not usable until it is activated after a short delay. This delay
     * prevents future governance from abusing its powers, and gives downstream users an
     * opportunity to decide if they still trust Reliquary.
     */
    /**
     * @notice Add/propose a new prover to prove facts.
     * @param prover the address of the prover in question
     * @param version the unique version string to associate with this prover
     * @dev Provers and proposed provers must have unique version IDs
     * @dev After the Reliquary is initialized, a review period of 64k blocks
     *      must conclude before a prover may be added. The request must then
     *      be re-submitted to take effect. Before initialization is complete,
     *      the review period is skipped.
     * @dev Pending provers may be removed by submitting a new prover with a
     *      version of 0.
     * @dev Emits PendingProveRemoved when a pending prover proposal is withdrawn
     * @dev Emits NewProver when a prover is added to the reliquary
     * @dev Emits PendingProverAdded when a prover is proposed for inclusion
     */
    function addProver(address prover, uint64 version) external onlyRole(ADD_PROVER_ROLE) {
        require(version != 0, "version must not be zero");
        require(versions[version] == address(0), "duplicate version");
        require(provers[prover].version == 0, "duplicate prover");
        require(pendingProvers[prover].version == 0, "already pending");

        uint256 delay = initialized ? DELAY : 0;
        PendingProver memory pendingProver = PendingProver(
            uint64(block.timestamp + delay),
            version
        );
        pendingProvers[prover] = pendingProver;

        // Pre-initialize ProverInfo so fee can be set before activation
        // As version = 0, the prover will not be usable yet
        provers[prover] = ProverInfo(0, FeeInfo(0, 0, 0, 0, 0), false);

        emit PendingProverAdded(prover, pendingProver.version, pendingProver.timestamp);
    }

    /* Anyone can activate a prover once it has been added and is no longer pending */
    function activateProver(address prover) external {
        require(provers[prover].version == 0, "duplicate prover");

        PendingProver memory pendingProver = pendingProvers[prover];
        require(pendingProver.version != 0, "invalid address");
        require(pendingProver.timestamp <= block.timestamp, "not ready");
        require(versions[pendingProver.version] == address(0), "duplicate version");

        versions[pendingProver.version] = prover;
        provers[prover].version = pendingProver.version;

        emit NewProver(prover, pendingProver.version);
    }

    /**
     * @notice Stop accepting proofs from this prover
     * @param prover The prover to banish from the reliquary
     * @dev Emits ProverRevoked
     * @dev Note: existing facts proved by the prover may still stand
     */
    function revokeProver(address prover) external onlyRole(GOVERNANCE_ROLE) {
        provers[prover].revoked = true;
        emit ProverRevoked(prover, pendingProvers[prover].version);
    }

    /**
     * @notice Initialize the Reliquary, enforcing the time lock for new provers
     */
    function setInitialized() external onlyRole(ADD_PROVER_ROLE) {
        initialized = true;
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Reliquary.sol";

struct FeeAccount {
    uint64 subscriberUntilTime;
    uint192 credits;
}

/**
 * @title Holder of Relics and Artifacts with fees
 * @author Theori, Inc.
 * @notice The Reliquary is the heart of Relic. All issuers of Relics and Artifacts
 *         must be added to the Reliquary. Queries about Relics and Artifacts should
 *         be made to the Reliquary. This Reliquary may charge fees for proving or
 *         accessing facts.
 */
contract ReliquaryWithFee is Reliquary {
    using SafeERC20 for IERC20;

    bytes32 public constant CREDITS_ROLE = keccak256("CREDITS_ROLE");
    bytes32 public constant SUBSCRIPTION_ROLE = keccak256("SUBSCRIPTION_ROLE");

    /// Mapping of fact classes to fee infos about them
    mapping(uint8 => FeeInfo) public factFees;
    /// Information about fee accounts (credits & subscriptions)
    mapping(address => FeeAccount) public feeAccounts;
    /// External tokens and fee delegates for use by
    mapping(uint256 => address) public feeExternals;
    uint32 internal feeExternalsCount;
    /// FeeInfo struct for block queries
    FeeInfo public verifyBlockFeeInfo;

    constructor() Reliquary() {}

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev A fee may be required based on the factSig
     */
    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        checkVerifyFactFee(factSig);
        return _verifyFact(account, factSig);
    }

    /**
     * @notice Query for some information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev A fee may be required based on the factSig
     */
    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version)
    {
        checkVerifyFactFee(factSig);
        return _verifyFactVersion(account, factSig);
    }

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) public payable returns (bool) {
        checkValidBlockFee(num);

        // validBlockHash is a view function, so it cannot modify state and is safe to call
        return IBlockHistory(verifier).validBlockHash(hash, num, proof);
    }

    /**
     * @notice Asserts that a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external payable {
        require(validBlockHash(verifier, hash, num, proof), "invalid block hash");
    }

    /**
     * @notice Helper function to calculate fee for a given feeInfo struct
     * @param feeInfo The FeeInfo struct in question
     * @return The associated fee in wei
     */
    function getFeeWei(FeeInfo memory feeInfo) internal pure returns (uint256) {
        return feeInfo.feeWeiMantissa * (10**feeInfo.feeWeiExponent);
    }

    /**
     * @notice Require that an appropriate fee is paid for queries
     * @param sender The initiator of the query
     * @param feeInfo The FeeInfo struct associated with the query
     * @param data Opaque data that may be needed by downstream fee functions
     * @dev Reverts if the fee is not sufficient
     */
    function checkFeeInfo(
        address sender,
        FeeInfo memory feeInfo,
        bytes memory data
    ) internal {
        uint256 feeWei = getFeeWei(feeInfo);

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeNone)) != 0) {
            return;
        }

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeNative)) != 0) {
            if (msg.value >= feeWei) {
                return;
            }
        }

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeCredits)) != 0) {
            FeeAccount memory feeAccount = feeAccounts[sender];
            // check if sender has a valid subscription
            if (feeAccount.subscriberUntilTime > block.timestamp) {
                return;
            }
            // otherwise subtract credits
            if (feeAccount.credits >= feeInfo.feeCredits) {
                feeAccount.credits -= feeInfo.feeCredits;
                feeAccounts[sender] = feeAccount;
                return;
            }
        }

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeExternalDelegate)) != 0) {
            require(feeInfo.feeExternalId != 0);
            address delegate = feeExternals[feeInfo.feeExternalId];
            require(delegate != address(0));
            IFeeDelegate(delegate).checkFee{value: msg.value}(sender, data);
            return;
        }

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeExternalToken)) != 0) {
            require(feeInfo.feeExternalId != 0);
            address token = feeExternals[feeInfo.feeExternalId];
            require(token != address(0));
            IERC20(token).safeTransferFrom(sender, address(this), feeWei);
            return;
        }

        revert("insufficient fee");
    }

    /**
     * @notice Require that an appropriate fee is paid for verify fact queries
     * @param factSig The signature of the desired fact
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be used internally
     */
    function checkVerifyFactFee(FactSignature factSig) internal {
        uint8 cls = Facts.toFactClass(factSig);
        if (cls != Facts.NO_FEE) {
            checkFeeInfo(msg.sender, factFees[cls], abi.encode("verifyFact", factSig));
        }
    }

    /**
     * @notice Require that an appropriate fee is paid for proving a fact
     * @param sender The account wanting to prove a fact
     * @dev The fee is derived from the prover which calls this  function
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be called by a prover
     */
    function checkProveFactFee(address sender) external payable {
        address prover = msg.sender;
        ProverInfo memory proverInfo = provers[prover];
        checkProver(proverInfo);

        checkFeeInfo(sender, proverInfo.feeInfo, abi.encode("proveFact", prover));
    }

    /**
     * @notice Require that an appropriate fee is paid for verify block queries
     * @param blockNum The block number to verify
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be used internally
     */
    function checkValidBlockFee(uint256 blockNum) internal {
        checkFeeInfo(msg.sender, verifyBlockFeeInfo, abi.encode("verifyBlock", blockNum));
    }

    // Functions to help callers determine how much fee they need to pay
    /**
     * @notice Determine the appropriate ETH fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256) {
        uint8 cls = Facts.toFactClass(factSig);
        if (cls == Facts.NO_FEE) {
            return 0;
        }
        FeeInfo memory feeInfo = factFees[cls];
        require(feeInfo.flags & (1 << uint256(FeeFlags.FeeNative)) != 0);
        return getFeeWei(feeInfo);
    }

    /**
     * @notice Determine the appropriate token fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256) {
        uint8 cls = Facts.toFactClass(factSig);
        if (cls == Facts.NO_FEE) {
            return 0;
        }
        FeeInfo memory feeInfo = factFees[cls];
        require(feeInfo.flags & (1 << uint256(FeeFlags.FeeExternalToken)) != 0);
        return getFeeWei(feeInfo);
    }

    /**
     * @notice Determine the appropriate ETH fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getProveFactNativeFee(address prover) external view returns (uint256) {
        ProverInfo memory proverInfo = provers[prover];
        checkProver(proverInfo);

        require(proverInfo.feeInfo.flags & (1 << uint256(FeeFlags.FeeNative)) != 0);
        return getFeeWei(proverInfo.feeInfo);
    }

    /**
     * @notice Determine the appropriate token fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getProveFactTokenFee(address prover) external view returns (uint256) {
        ProverInfo memory proverInfo = provers[prover];
        checkProver(proverInfo);

        require(proverInfo.feeInfo.flags & (1 << uint256(FeeFlags.FeeExternalToken)) != 0);
        return getFeeWei(proverInfo.feeInfo);
    }

    /**
     * @notice Check how many credits a given account possesses
     * @param user The account in question
     * @return The number of credits
     */
    function credits(address user) public view returns (uint192) {
        return feeAccounts[user].credits;
    }

    /**
     * @notice Check if an account has an active subscription
     * @param user The account in question
     * @return True if the account is active, otherwise false
     */
    function isSubscriber(address user) public view returns (bool) {
        return feeAccounts[user].subscriberUntilTime > block.timestamp;
    }

    /**
     * @notice Adds a new external fee provider (token or delegate) to a feeInfo
     * @param feeInfo The feeInfo to update with this provider
     * @dev Always appends to the global feeExternals
     */
    function _setFeeExternalId(FeeInfo memory feeInfo, address feeExternal)
        internal
        returns (FeeInfo memory)
    {
        uint32 feeExternalId = 0;
        if (feeExternal != address(0)) {
            feeExternalsCount++;
            feeExternalId = feeExternalsCount;
            feeExternals[feeExternalId] = feeExternal;
        }
        feeInfo.feeExternalId = feeExternalId;
        return feeInfo;
    }

    /**
     * @notice Sets the FeeInfo for a particular fee class
     * @param cls The fee class
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external onlyRole(GOVERNANCE_ROLE) {
        feeInfo = _setFeeExternalId(feeInfo, feeExternal);
        factFees[cls] = feeInfo;
    }

    /**
     * @notice Sets the FeeInfo for a particular prover
     * @param prover The prover in question
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external onlyRole(GOVERNANCE_ROLE) {
        ProverInfo memory proverInfo = provers[prover];
        checkProver(proverInfo);

        feeInfo = _setFeeExternalId(feeInfo, feeExternal);
        proverInfo.feeInfo = feeInfo;
        provers[prover] = proverInfo;
    }

    /**
     * @notice Sets the FeeInfo for block verification
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        feeInfo = _setFeeExternalId(feeInfo, feeExternal);
        verifyBlockFeeInfo = feeInfo;
    }

    /**
     * @notice Add/update a subscription
     * @param user The subscriber account to modify
     * @param ts The new block timestamp at which the subscription expires
     */
    function addSubscriber(address user, uint64 ts) external onlyRole(SUBSCRIPTION_ROLE) {
        require(feeAccounts[user].subscriberUntilTime < ts);
        feeAccounts[user].subscriberUntilTime = ts;
    }

    /**
     * @notice Remove a subscription
     * @param user The subscriber account to modify
     */
    function removeSubscriber(address user) external onlyRole(SUBSCRIPTION_ROLE) {
        feeAccounts[user].subscriberUntilTime = 0;
    }

    /**
     * @notice Set credits for an account
     * @param user The account for which credits should be set
     * @param amount The credits that the account should be updated to hold
     */
    function setCredits(address user, uint192 amount) external onlyRole(CREDITS_ROLE) {
        feeAccounts[user].credits = amount;
    }

    /**
     * @notice Add credits to an account
     * @param user The account to which more credits should be granted
     * @param amount The number of credits to be added
     */
    function addCredits(address user, uint192 amount) external onlyRole(CREDITS_ROLE) {
        feeAccounts[user].credits += amount;
    }

    /**
     * @notice Remove credits from an account
     * @param user The account from which credits should be removed
     * @param amount The number of credits to be removed
     */
    function removeCredits(address user, uint192 amount) external onlyRole(CREDITS_ROLE) {
        feeAccounts[user].credits -= amount;
    }

    /**
     * @notice Extract accumulated fees
     * @param token The ERC20 token from which to extract fees. Or the 0 address for
     *        native ETH
     * @param dest The address to which fees should be transferred
     */
    function withdrawFees(address token, address payable dest) external onlyRole(GOVERNANCE_ROLE) {
        require(dest != address(0));

        if (token == address(0)) {
            dest.transfer(address(this).balance);
        } else {
            IERC20(token).transfer(dest, IERC20(token).balanceOf(address(this)));
        }
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Block history provider
 * @author Theori, Inc.
 * @notice IBlockHistory provides a way to verify a blockhash
 */

interface IBlockHistory {
    /**
     * @notice Determine if the given hash corresponds to the given block
     * @param hash the hash if the block in question
     * @param num the number of the block in question
     * @param proof any witness data required to prove the block hash is
     *        correct (such as a Merkle or SNARK proof)
     * @return boolean indicating if the block hash can be verified correct
     */
    function validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Fee provider
 * @author Theori, Inc.
 * @notice Acceptor of fees for functions requiring payment
 */
interface IFeeDelegate {
    /**
     * @notice Accept any required fee from the sender
     * @param sender the originator of the call that may be paying
     * @param data opaque data to help determine costs
     * @dev reverts if a fee is required and not provided
     */
    function checkFee(address sender, bytes calldata data) external payable;
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

type FactSignature is bytes32;

library Facts {
    uint8 internal constant NO_FEE = 0;

    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}