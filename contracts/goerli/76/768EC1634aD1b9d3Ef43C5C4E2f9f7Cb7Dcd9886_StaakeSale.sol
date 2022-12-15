// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

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
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
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

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
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
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Interface Staake Sale
abstract contract EarlySaleReceiver is ERC165 {
    /**
     * @notice Deposits a previous purchase (buy order) of STK
     * @param _investor, address of the investor
     * @param _eth, amount of ETH spent
     * @param _stk, amount of STK reserved
     */
    function earlyDeposit(
        address _investor,
        uint128 _eth,
        uint128 _stk
    ) external virtual;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override virtual returns (bool) {
        return
            interfaceId == type(EarlySaleReceiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {StakingPool} from "abstracts/StakingPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {StakingBonus} from "abstracts/StakingBonus.sol";
import {IStaakeToken} from "interfaces/IStaakeToken.sol";
import {RewardsDistributor} from "abstracts/RewardsDistributor.sol";

/// @title Passive Staking pool with progressive staking and unlock for tokens bought during the StaakeSale
abstract contract PassiveStaking is StakingPool, StakingBonus {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IStaakeToken;
    using SafeERC20 for IERC20;

    uint256 public constant SHARES_PRECISION = 1e36;
    uint256 public constant RATIO_PRECISION = 1e18;
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR");

    IStaakeToken public stakedToken;
    IERC20 public rewardToken;

    uint256 public progressiveStakingRatio;
    uint32 public progressiveStakingDuration;
    uint32 public cliffDuration;
    uint32 public linearVestingDuration;

    struct InvestorInfo {
        uint128 initialAmount;
        uint128 shares;
        uint256 harvestedRewardsPerShare;
    }

    mapping(address => InvestorInfo) private _investorInfo;
    uint128 private _totalInitialAmount;
    uint128 private _totalShares;
    uint256 private _rewardsPerShare;
    uint256 private _totalPendingRewards;

    uint256 public stakingStartBlock;

    /**
     * @notice Stakes tokens on behalf of a user
     * @dev The sender must first approve the amount to deposit before calling this function
     * @param _investor, the address of the investor
     * @param _amount, the amount to be deposited
     * @dev `stakingStartBlock` must be equal 0 (startStaking() not executed yet)
     */
    function deposit(
        address _investor,
        uint128 _amount
    ) external virtual onlyRole(DEPOSITOR_ROLE) {
        require(stakingStartBlock == 0, "deposit phase has ended");
        _deposit(_investor, _amount);
    }

    /**
     * @notice Allows the owner to start the staking period
     * @notice All funds should be deposited before calling startStaking
     * @notice /!\ AFTER CALLING THIS FUNCTION, NOONE WILL BE ABLE TO STAKE ANY FUNDS ANYMORE
     */
    function startStaking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(stakingStartBlock == 0, "staking phase already started");

        stakingStartBlock = block.number;
    }

    /**
     * @notice Withdraws all accumulated rewards (in wETH)
     */
    function harvest() external override {
        require(stakingStartBlock != 0, "staking phase hasn't started");

        uint256 harvestedRewards = _harvest(msg.sender);

        require(harvestedRewards != 0, "no pending rewards");
    }

    /**
     * @notice Withdraws all unlocked staked tokens
     * @notice ALSO withdraws all accumulated rewards (in wETH)
     */
    function withdrawAll() external override {
        require(stakingStartBlock != 0, "staking phase hasn't started");

        // Force harvesting before withdrawing
        // Otherwise, the rewards would be lost
        _harvest(msg.sender);

        uint128 amount = availableBalanceOf(msg.sender);

        require(amount != 0, "no tokens to withdraw");

        _investorInfo[msg.sender].shares -= amount;
        _totalShares -= amount;

        stakedToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Force-fetch accumulated fees from distributors
     * @notice Updates the pending rewards for every investor in the pool
     */
    function updateRewards() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateRewards();
    }

    /**
     * @notice View the sum of staked tokens accross all users
     */
    function totalStakedTokens() external view override returns (uint128) {
        if (_totalShares == 0) return 0;

        // Number of blocks since the progressive staking has started
        uint256 elapsed = stakingStartBlock == 0
            ? 0
            : block.number - stakingStartBlock;

        // If there are no tokens left to progressively stake, everything is already staked
        if (
            progressiveStakingRatio == 0 ||
            elapsed >= progressiveStakingDuration
        ) return _totalShares;

        // Note: The following computation is identical to `balanceOf`,
        // excepted that it is an upper-bound instead of a lower-bound.
        // This guarantees that at least all staked tokens are taken into account.

        // Number of tokens which should be progressively unlocked
        uint128 progressiveTokens = uint128(
            (_totalInitialAmount * progressiveStakingRatio) / RATIO_PRECISION
        );

        // Linear progressive staking
        uint128 progressiveStakedTokens = (progressiveTokens *
            uint128(elapsed)) / progressiveStakingDuration;

        uint128 withdrawedTokens = _totalInitialAmount - _totalShares;

        return _totalInitialAmount + progressiveStakedTokens - withdrawedTokens;
    }

    /**
     * @notice View the total amount of tokens deposited for a user
     * @param _user, the address of the user
     */
    function sharesOf(address _user) external view returns (uint128) {
        return _investorInfo[_user].shares;
    }

    /**
     * @notice View the current amount of staked tokens for a user
     * @param _user, the address of the user
     */
    function balanceOf(
        address _user
    ) public view override(StakingPool, StakingBonus) returns (uint128) {
        if (_investorInfo[_user].shares == 0) return 0;

        // Number of blocks since the progressive staking has started
        uint256 elapsed = stakingStartBlock == 0
            ? 0
            : block.number - stakingStartBlock;

        // If there are no tokens left to progressively stake, everything is already staked
        if (
            progressiveStakingRatio == 0 ||
            elapsed >= progressiveStakingDuration
        ) return _investorInfo[_user].shares;

        // Number of tokens available initially (non-progressively minted)
        uint128 initialTokens = uint128(
            (_investorInfo[_user].initialAmount *
                (RATIO_PRECISION - progressiveStakingRatio)) / RATIO_PRECISION
        );

        // Linear progressive staking
        uint128 progressiveStakedTokens = ((_investorInfo[_user].initialAmount -
            initialTokens) * uint128(elapsed)) / progressiveStakingDuration;

        uint128 withdrawedTokens = _investorInfo[_user].initialAmount -
            _investorInfo[_user].shares;

        return initialTokens + progressiveStakedTokens - withdrawedTokens;
    }

    /**
     * @notice View the amount of unlocked staked tokens for a user
     * @param _user, the address of the user
     */
    function availableBalanceOf(address _user) public view returns (uint128) {
        if (
            _investorInfo[_user].shares == 0 ||
            // During the cliff period, no funds are available
            block.number < stakingStartBlock + cliffDuration
        ) return 0;

        // Number of blocks since the vesting has started, excluding the cliff
        uint256 elapsed = block.number - stakingStartBlock - cliffDuration;

        if (elapsed >= linearVestingDuration)
            return _investorInfo[_user].shares;

        // Linear vesting
        uint128 unlockedTokens = (_investorInfo[_user].initialAmount *
            uint128(elapsed)) / linearVestingDuration;

        uint128 withdrawedTokens = _investorInfo[_user].initialAmount -
            _investorInfo[_user].shares;

        return unlockedTokens - withdrawedTokens;
    }

    /**
     * @notice View the amount of accumulated rewards by a user (in wETH) that can be harvested
     * @param _user, the address of the user
     */
    function rewardsOf(address _user) public view returns (uint256) {
        return
            (_investorInfo[_user].shares *
                (_rewardsPerShare -
                    _investorInfo[_user].harvestedRewardsPerShare)) /
            SHARES_PRECISION;
    }

    /**
     * @notice Adds fees distributors to query before user balance changes
     * @param _distributors, array of new distributors to add
     */
    function addDistributors(
        address[] calldata _distributors
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        // Restricts adding distributors to the owner
        super.addDistributors(_distributors);
    }

    /**
     * @notice Removes fees distributors
     * @param _distributors, array of distributors to remove
     */
    function removeDistributors(
        address[] calldata _distributors
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        // Restricts removing distributors to the owner
        super.removeDistributors(_distributors);
    }

    /**
     * @notice Force-fetch accumulated fees from distributors
     * @notice Updates the pending rewards for every investor in the pool
     */
    function _updateRewards() private {
        // Fetch rewards from distributors
        for (uint256 i; i < distributors.length(); i++) {
            RewardsDistributor distributor = RewardsDistributor(
                distributors.at(i)
            );
            try distributor.harvest() {} catch {}
        }

        uint256 newRewards = rewardToken.balanceOf(address(this)) -
            _totalPendingRewards;

        if (address(rewardToken) == address(stakedToken))
            newRewards -= _totalShares;

        if (newRewards == 0 || _totalShares == 0) return;

        _rewardsPerShare += (newRewards * SHARES_PRECISION) / _totalShares;
        _totalPendingRewards += newRewards;
    }

    /**
     * @notice Withdraws the pending rewards accumulated by a user (in wETH)
     * @param _user, address of the investor
     */
    function _harvest(address _user) private returns (uint256) {
        _updateRewards();

        uint256 rewards = rewardsOf(_user);

        // Register that the rewards have been distributed
        _investorInfo[_user].harvestedRewardsPerShare = _rewardsPerShare;

        if (rewards == 0) return 0;

        // Transfer funds to account
        _totalPendingRewards -= rewards;
        rewardToken.safeTransfer(_user, rewards);

        return rewards;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(StakingPool, StakingBonus) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Stakes tokens on behalf of a user
     * @dev The sender must first approve the amount to deposit before calling this function
     * @param _investor, the address of the investor
     * @param _amount, the amount to be deposited
     */
    function _deposit(address _investor, uint128 _amount) internal virtual {
        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);

        _investorInfo[_investor].initialAmount += _amount;
        _investorInfo[_investor].shares += _amount;
        _totalInitialAmount += _amount;
        _totalShares += _amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Allows to harvest fees (wETH rewards) for a staking pool
abstract contract RewardsDistributor is ERC165 {
    /**
     * @notice Harvest the received fees for a staking pool
     */
    function harvest() external virtual;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(RewardsDistributor).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Interface Passive Staking pool with linear progressive unlock
abstract contract StakingBonus is AccessControl {
    bytes32 public constant BONUS_SOURCE_ROLE = keccak256("BONUS_SOURCE");

    mapping(address => int128) private _bonuses;
    int128 internal _totalBonusAmount;

    function addBonus(
        address _user,
        int128 _bonus
    ) public onlyRole(BONUS_SOURCE_ROLE) {
        int128 previousBonus = _bonuses[_user];
        int128 newBonus = previousBonus + _bonus;
        _bonuses[_user] = newBonus;

        _updateBonusRatio(_user, previousBonus, newBonus);
    }

    function _updateBonusRatio(
        address _user,
        int128 _previousBonus,
        int128 _newBonus
    ) internal virtual {
        int256 balance = int256(uint256(balanceOf(_user)));
        _totalBonusAmount += int128(
            (_newBonus * balance) - (_previousBonus * balance)
        );
    }

    function _updateBonusBalance(
        address _user,
        uint128 _previousBalance,
        uint128 _newBalance
    ) internal virtual {
        int128 bonus = _bonuses[_user];
        _totalBonusAmount += int128(
            (bonus * int256(uint256(_newBalance))) -
                (bonus * int256(uint256(_previousBalance)))
        );
    }

    function bonusOf(address _user) public view returns (int128) {
        return _bonuses[_user];
    }

    /**
     * @notice View the current amount of staked tokens for a user
     * @param _user, the address of the user
     */
    function balanceOf(address _user) public view virtual returns (uint128);

    /**
     * @dev See {IERC165-supportsInterfae}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(StakingBonus).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {RewardsDistributor} from "abstracts/RewardsDistributor.sol";

/// @title Passive Staking pool with linear progressive unlock
abstract contract StakingPool is ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal distributors;

    /**
     * @notice Withdraws all accumulated rewards (in wETH)
     */
    function harvest() external virtual;

    /**
     * @notice Withdraws all unlocked staked tokens
     * @notice ALSO withdraws all accumulated rewards (in wETH)
     */
    function withdrawAll() external virtual;

    /**
     * @notice View the current amount of staked tokens for a user
     * @param _user, the address of the user
     */
    function balanceOf(address _user) external view virtual returns (uint128);

    /**
     * @notice View the sum of staked tokens accross all users
     */
    function totalStakedTokens() external view virtual returns (uint128);

    /**
     * @notice Adds fees distributors to query before user balance changes
     * @param _distributors, array of new distributors to add
     */
    function addDistributors(address[] calldata _distributors) public virtual {
        for (uint256 i; i < _distributors.length; i++) {
            require(
                ERC165Checker.supportsInterface(
                    _distributors[i],
                    type(RewardsDistributor).interfaceId
                ),
                "address is not a compatible distributor"
            );

            distributors.add(_distributors[i]);
        }
    }

    /**
     * @notice Removes fees distributors
     * @param _distributors, array of distributors to remove
     */
    function removeDistributors(
        address[] calldata _distributors
    ) public virtual {
        for (uint256 i; i < _distributors.length; i++) {
            require(
                distributors.contains(_distributors[i]),
                "not a distributor"
            );

            distributors.remove(_distributors[i]);
        }
    }

    /**
     * @notice View the list of fees distributors
     */
    function getDistributors() public view returns (address[] memory) {
        return distributors.values();
    }

    /**
     * @dev See {IERC165-supportsInterfae}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(StakingPool).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Phase is AccessControl {
    uint128 internal stkUsdPrice;

    enum SalePhase {
        Early,
        Private,
        Public,
        Ended
    }

    SalePhase public phase = SalePhase.Early;

    event SalePhaseChanged(SalePhase indexed newPhase);

    /**
     * @notice Defines the current sale phase
     * @param _phase, sale phase
     * @param _stkUsdPrice, the new price for this phase
     */
    function setSalePhase(
        SalePhase _phase,
        uint128 _stkUsdPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(uint8(_phase) > uint8(phase), "cannot move phase backwards");

        setStkUsdPrice(_stkUsdPrice);
        phase = _phase;

        emit SalePhaseChanged(_phase);
    }

    /**
     * @notice allow Admin to set price during the sale regardless Sale phase
     */
    function setStkUsdPrice(
        uint128 _stkUsdPrice
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_stkUsdPrice >= stkUsdPrice, "New price can only increase");
        stkUsdPrice = _stkUsdPrice;
    }

    /**
     * @notice Checks if the current sale phase allows to buy tokens
     */
    modifier saleStarted() {
        require(
            phase != SalePhase.Early,
            "The sale of staake token has not started"
        );
        _;
    }

    /**
     * @notice Checks if the current sale phase allows to buy tokens
     */
    modifier saleNotEnded() {
        require(phase != SalePhase.Ended, "The sale of STK token is over");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract PriceCalculator {
    AggregatorV3Interface public immutable priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice View the price of STK tokens in USD
     */
    function STK_USD_VALUE() public view virtual returns (uint128);

    /**
     * @notice View the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS() public view virtual returns (uint8);

    /**
     * @notice Converts an ETH value to STK
     * @param _eth, the value to convert
     */
    function convertEthToStk(uint128 _eth) internal view returns (uint128) {
        return convertEthToStkAtPrice(_eth, STK_USD_VALUE());
    }

    /**
     * @notice Converts an ETH value to STK
     * @dev /!\ The result has 18 decimals
     * @param _eth, the value to convert
     * @param _stkUsdPrice, the price of stk in USD
     * @return STK amount for _eth at _stkUsdPrice $ per STK (18 decimals)
     */
    function convertEthToStkAtPrice(
        uint128 _eth,
        uint128 _stkUsdPrice
    ) internal view returns (uint128) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            uint128(
                (uint256(price) * _eth * 10 ** STK_USD_DECIMALS()) /
                    _stkUsdPrice /
                    10 ** priceFeed.decimals()
            );
    }

    /**
     * @notice Converts an STK value to ETH
     * @param _stk, the value to convert
     */
    function convertStkToEth(uint128 _stk) internal view returns (uint128) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            uint128(
                (uint256(_stk) * STK_USD_VALUE()) /
                    10 ** STK_USD_DECIMALS() /
                    uint256(price) /
                    10 ** priceFeed.decimals()
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IStaakeToken} from "interfaces/IStaakeToken.sol";
import {IStaakeSale} from "interfaces/IStaakeSale.sol";
import {PassiveStaking} from "abstracts/PassiveStaking.sol";
import {EarlySaleReceiver} from "abstracts/EarlySaleReceiver.sol";
import {ISale} from "interfaces/shared/ISale.sol";
import {Phase} from "contracts/access/Phase.sol";
import {PriceCalculator} from "contracts/sale/PriceCalculator.sol";

/// @title Private/Public Sale of STK TOKEN
contract StaakeSale is
    Phase,
    ISale,
    IStaakeSale,
    PriceCalculator,
    EarlySaleReceiver
{
    bytes32 public constant EARLY_DEPOSITOR_ROLE = keccak256("EARLY_DEPOSITOR");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR");

    uint128 public immutable MIN_INVESTMENT_PRIVATE_SALE;
    uint128 public immutable MIN_INVESTMENT_PUBLIC_SALE;
    uint128 public immutable MAX_INVESTMENT;

    IStaakeToken public immutable stakedToken;
    PassiveStaking public immutable privateSaleStaking;
    PassiveStaking public immutable publicSaleStaking;

    struct Amount {
        uint128 stk;
        uint128 ethSpent;
    }

    mapping(address => mapping(Phase.SalePhase => Amount))
        private investorToAmountPerPhase;

    uint128 public availableTokens;

    event TokenBought(
        address indexed owner,
        uint128 amount,
        uint128 stk,
        SalePhase indexed phase
    );
    event Withdraw(address indexed owner, uint256 amount);
    event WithdrawStk(address indexed owner, uint128 amount);

    constructor(
        address _staakedToken,
        address _priceFeed,
        address _privateSaleStaking,
        address _publicSaleStaking,
        address _earlyDepositor,
        uint128 _availableTokens,
        uint128 _minInvestmentPrivate,
        uint128 _minInvestmentPublic,
        uint128 _maxInvestment
    ) PriceCalculator(_priceFeed) {
        stakedToken = IStaakeToken(_staakedToken);
        privateSaleStaking = PassiveStaking(_privateSaleStaking);
        publicSaleStaking = PassiveStaking(_publicSaleStaking);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EARLY_DEPOSITOR_ROLE, _earlyDepositor);

        availableTokens = _availableTokens;

        MIN_INVESTMENT_PRIVATE_SALE = _minInvestmentPrivate;
        MIN_INVESTMENT_PUBLIC_SALE = _minInvestmentPublic;
        MAX_INVESTMENT = _maxInvestment;

        stakedToken.approve(_privateSaleStaking, _availableTokens);
        stakedToken.approve(_publicSaleStaking, _availableTokens);
    }

    /**
     * @notice Deposits a previous purchase (buy order) of STK
     * @param _investor, address of the investor
     * @param _eth, amount of ETH spent
     * @param _stk, amount of STK reserved
     */
    function earlyDeposit(
        address _investor,
        uint128 _eth,
        uint128 _stk
    ) external override onlyRole(EARLY_DEPOSITOR_ROLE) {
        require(
            phase == SalePhase.Early,
            "Can only be used before private sale"
        );

        _buyStk(_investor, _eth, _stk);
    }

    /**
     * @notice Deposits a purchase (buy order) of STK
     * @param _investor, address of the investor
     * @param _eth, amount of ETH spent
     * @param _stk, amount of STK reserved
     */
    function deposit(
        address _investor,
        uint128 _eth,
        uint128 _stk
    ) external override saleStarted onlyRole(DEPOSITOR_ROLE) {
        _buyStk(_investor, _eth, _stk);
    }

    /**
     * @notice Buys STK tokens
     */
    function buy() external payable saleStarted saleRequirement {
        uint128 stk = convertEthToStk(uint128(msg.value));
        _buyStk(msg.sender, uint128(msg.value), stk);
    }

    /**
     * @notice Withdraws all ETH earned during the sale up until now
     */
    function withdrawAll() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(phase == SalePhase.Ended, "Sale is still in progress");

        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Withdraws unsold Stk earned during the sale up until now
     */
    function withdrawResidualStk() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(phase == SalePhase.Ended, "Sale is still in progress");

        stakedToken.transfer(msg.sender, availableTokens);
        emit WithdrawStk(msg.sender, availableTokens);
    }

    /**
     * @notice View the amount of STK token for a user
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view override returns (uint128) {
        return
            uint128(
                investorToAmountPerPhase[_user][SalePhase.Private].stk +
                    investorToAmountPerPhase[_user][SalePhase.Public].stk
            );
    }

    /**
     * @notice View the STK token quantity of a phase for a user
     * @param _user, address of the user
     * @param _phase, sale phase
     */
    function balanceOfByPhase(
        address _user,
        SalePhase _phase
    ) external view override returns (uint128) {
        return investorToAmountPerPhase[_user][_phase].stk;
    }

    /**
     * @notice View the amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(
        address _user
    ) external view override returns (uint128) {
        return
            uint128(
                investorToAmountPerPhase[_user][SalePhase.Private].ethSpent +
                    investorToAmountPerPhase[_user][SalePhase.Public].ethSpent
            );
    }

    /**
     * @notice View the amount of ETH spent by a user during a phase
     * @param _user, address of the user
     * @param _phase, sale phase
     */
    function getETHSpentByPhase(
        address _user,
        SalePhase _phase
    ) external view override returns (uint128) {
        return investorToAmountPerPhase[_user][_phase].ethSpent;
    }

    /**
     * @notice View the price of STK tokens in USD
     */
    function STK_USD_VALUE()
        public
        view
        override(ISale, PriceCalculator)
        returns (uint128)
    {
        return stkUsdPrice;
    }

    /**
     * @notice View the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS()
        public
        pure
        override(ISale, PriceCalculator)
        returns (uint8)
    {
        return 18;
    }

    /**
     * @notice View the minimum amount of ETH per `deposit` call
     */
    function MIN_INVESTMENT() public view returns (uint128) {
        return
            phase == SalePhase.Private
                ? MIN_INVESTMENT_PRIVATE_SALE
                : MIN_INVESTMENT_PUBLIC_SALE;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(EarlySaleReceiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Buys STK equivalent STK for the given ETH amount
     * @param _ethAmount, ETH amount payed for STK purchase
     * @param _stkAmount, STK amount to buy
     */
    function _buyStk(
        address _investor,
        uint128 _ethAmount,
        uint128 _stkAmount
    ) private saleNotEnded {
        if (_stkAmount <= availableTokens) {
            _registerPurchase(_investor, uint128(_ethAmount), _stkAmount);

            if (availableTokens == 0) phase = SalePhase.Ended;
        } else {
            // clamp stk to availableTokens
            uint128 ethToRefund = convertStkToEth(_stkAmount - availableTokens);
            uint128 ethSpent = uint128(_ethAmount - ethToRefund);

            _registerPurchase(_investor, ethSpent, availableTokens);
            phase = SalePhase.Ended;

            // refund ETH
            payable(_investor).transfer(ethToRefund);
        }
    }

    /**
     * @notice Registers a buy event for an investor
     * @param _investor, address of the investor
     * @param _eth, amount of ETH spent
     * @param _stk, amount of STK reserved
     */
    function _registerPurchase(
        address _investor,
        uint128 _eth,
        uint128 _stk
    ) private {
        investorToAmountPerPhase[_investor][phase].stk += _stk;
        investorToAmountPerPhase[_investor][phase].ethSpent += _eth;
        availableTokens -= _stk;

        _stakingDeposit(_investor, _stk, phase);
        emit TokenBought(_investor, _eth, _stk, phase);
    }

    /**
     * @notice Checks all token purchase requirements for the current sale phase
     */
    modifier saleRequirement() {
        SalePhase currentPhase = phase;

        require(
            investorToAmountPerPhase[msg.sender][currentPhase].ethSpent +
                msg.value <=
                MAX_INVESTMENT,
            "Maximum investment is 50 ETH"
        );

        if (currentPhase == SalePhase.Private) {
            require(
                msg.value >= MIN_INVESTMENT_PRIVATE_SALE,
                "Minimum investment is 5 ETH"
            );
        } else if (currentPhase == SalePhase.Public) {
            require(
                msg.value >= MIN_INVESTMENT_PUBLIC_SALE,
                "Minimum investment is 1 ETH"
            );
        }

        _;
    }

    /**
     * @notice Transfers STK to the Passive Staking contract
     * @param _investor, the address of the investor
     * @param _amount, the amount to be deposited
     * @param _investmentType, the type of investment eg: PrivateSale => 0
     */
    function _stakingDeposit(
        address _investor,
        uint128 _amount,
        SalePhase _investmentType
    ) private {
        if (
            _investmentType == SalePhase.Early ||
            _investmentType == SalePhase.Private
        ) privateSaleStaking.deposit(_investor, _amount);
        else if (_investmentType == SalePhase.Public)
            publicSaleStaking.deposit(_investor, _amount);
        else revert("invalid investment type");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Phase} from "contracts/access/Phase.sol";
import {EarlySaleReceiver} from "abstracts/EarlySaleReceiver.sol";

/// @title Interface Staake Sale
interface IStaakeSale {
    /**
     * @notice View the amount of STK tokens bought by a user during a phase
     * @param _user, address of the user
     * @param _phase, sale phase
     */
    function balanceOfByPhase(
        address _user,
        Phase.SalePhase _phase
    ) external view returns (uint128);

    /**
     * @notice View the amount of ETH spent by a user during a phase
     * @param _user, address of the user
     * @param _phase, sale phase
     */
    function getETHSpentByPhase(
        address _user,
        Phase.SalePhase _phase
    ) external view returns (uint128);

    /**
     * @notice Deposits a purchase (buy order) of STK
     * @param _investor, address of the investor
     * @param _eth, amount of ETH spent
     * @param _stk, amount of STK reserved
     */
    function deposit(address _investor, uint128 _eth, uint128 _stk) external;

    /**
     * @notice Withdraws all ETH earned during the sale up until now
     */
    function withdrawAll() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaakeToken is IERC20 {
    /**
     * @notice Mints tokens
     * @param account address to receive tokens
     * @param amount amount to mint
     * @return status true if mint is successful, false if not
     */
    function mint(address account, uint256 amount) external returns (bool);

    /**
     * @notice View supply cap
     */
    function supplyCap() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Shared interface for EarlySale + StaakeSale
interface ISale {
    /**
     * @notice View the price of STK tokens in USD
     */
    function STK_USD_VALUE() external view returns (uint128);

    /**
     * @notice View the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS() external view returns (uint8);

    /**
     * @notice View the minimum amount of ETH per call
     */
    function MIN_INVESTMENT() external view returns (uint128);

    /**
     * @notice View the maximum total amount of ETH per investor
     */
    function MAX_INVESTMENT() external view returns (uint128);

    /**
     * @notice View the amount of STK still available for sale
     */
    function availableTokens() external view returns (uint128);

    /**
     * @notice Reserves STK tokens at the current ETH/USD exchange rate
     */
    function buy() external payable;

    /**
     * @notice View the total amount of STK tokens a user has bought
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint128);

    /**
     * @notice View the total amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint128);
}