// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Staking.sol";
import "./StakingStorage.sol";
import "./Converter.sol";
import "./EnergyStorage.sol";
import "./helpers/PermissionControl.sol";
import "./helpers/Util.sol";

/**
 * @dev ASM Genome Mining - Registry contract
 * @notice We use this contract to manage contracts addresses
 * @notice when we need to update some of them.
 */
contract Controller is Util, PermissionControl {
    Controller public controller_;
    Staking public stakingLogic_;
    StakingStorage public astoStorage_;
    StakingStorage public lpStorage_;
    Converter public converterLogic_;
    EnergyStorage public energyStorage_;
    IERC20 public astoToken_;
    IERC20 public lpToken_;

    address public manager; // DAO multisig contract, public for auto getter

    event ContractUpgraded(uint256 timestamp, string contractName, address oldAddress, address newAddress);

    constructor(address multisig) {
        // TODO comment for test contract temp
        //if (!_isContract(multisig)) revert InvalidInput(INVALID_MULTISIG);
        manager = multisig;
        _setupRole(MANAGER_ROLE, multisig); // `RoleGranted` event will be emitted
    }

    function init(
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage
    ) public onlyRole(MANAGER_ROLE) {
        if (!_isContract(astoToken)) revert InvalidInput(INVALID_ASTO_CONTRACT);
        if (!_isContract(astoStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(lpToken)) revert InvalidInput(INVALID_LP_CONTRACT);
        if (!_isContract(lpStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(stakingLogic)) revert InvalidInput(INVALID_STAKING_LOGIC);
        if (!_isContract(converterLogic)) revert InvalidInput(INVALID_CONVERTER_LOGIC);
        if (!_isContract(energyStorage)) revert InvalidInput(INVALID_ENERGY_STORAGE);

        // Saving addresses on init:
        astoToken_ = IERC20(astoToken);
        astoStorage_ = StakingStorage(astoStorage);
        lpToken_ = IERC20(lpToken);
        lpStorage_ = StakingStorage(lpStorage);
        stakingLogic_ = Staking(stakingLogic);
        converterLogic_ = Converter(converterLogic);
        energyStorage_ = EnergyStorage(energyStorage);
        controller_ = Controller(this);

        // Initializing contracts
        _upgradeContracts(
            address(this),
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            converterLogic,
            energyStorage
        );
    }

    /** ----------------------------------
     * ! Internal functions | Setters
     * ----------------------------------- */

    /**
     * @notice Each contract has own params to initialize
     * @notice Contracts with no address specified will be skipped
     * @dev Internal functions, can be called from constructor OR
     * @dev after authentication by the public function `upgradeContracts()`
     */
    function _upgradeContracts(
        address controller,
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage
    ) internal {
        if (_isContract(astoToken)) _setAstoToken(astoToken);
        if (_isContract(astoStorage)) _setAstoStorage(astoStorage);
        if (_isContract(lpToken)) _setLpToken(lpToken);
        if (_isContract(lpStorage)) _setLpStorage(lpStorage);
        if (_isContract(stakingLogic)) _setStakingLogic(stakingLogic);
        if (_isContract(energyStorage)) _setEnergyStorage(energyStorage);
        if (_isContract(converterLogic)) _setConverterLogic(converterLogic);
        if (_isContract(controller)) _setController(controller);
    }

    function _setManager(address multisig) internal {
        manager = multisig;
        _updateRole(MANAGER_ROLE, multisig);
    }

    function _setController(address newContract) internal {
        stakingLogic_.setController(address(controller_));
        astoStorage_.setController(address(controller_));
        lpStorage_.setController(address(controller_));
        converterLogic_.setController(address(controller_));
        energyStorage_.setController(address(controller_));
        emit ContractUpgraded(block.timestamp, "Controller", address(this), newContract);
    }

    function _setStakingLogic(address newContract) internal {
        stakingLogic_ = Staking(newContract);
        stakingLogic_.init(
            address(manager),
            IERC20(astoToken_),
            address(astoStorage_),
            IERC20(lpToken_),
            address(lpStorage_)
        );
        emit ContractUpgraded(block.timestamp, "Staking Logic", address(this), newContract);
    }

    function _setAstoToken(address newContract) internal {
        astoToken_ = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "ASTO Token", address(this), newContract);
    }

    function _setAstoStorage(address newContract) internal {
        astoStorage_ = StakingStorage(newContract);
        astoStorage_.init(address(stakingLogic_));
        emit ContractUpgraded(block.timestamp, "ASTO Staking Storage", address(this), newContract);
    }

    function _setLpToken(address newContract) internal {
        lpToken_ = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "LP Token", address(this), newContract);
    }

    function _setLpStorage(address newContract) internal {
        lpStorage_ = StakingStorage(newContract);
        lpStorage_.init(address(stakingLogic_));
        emit ContractUpgraded(block.timestamp, "LP Staking Storage", address(this), newContract);
    }

    function _setConverterLogic(address newContract) internal {
        converterLogic_ = Converter(newContract);
        converterLogic_.init(address(manager), address(energyStorage_), address(stakingLogic_));
        emit ContractUpgraded(block.timestamp, "Converter Logic", address(this), newContract);
    }

    function _setEnergyStorage(address newContract) internal {
        energyStorage_ = EnergyStorage(newContract);
        energyStorage_.init(address(converterLogic_));
        emit ContractUpgraded(block.timestamp, "Energy Storage", address(this), newContract);
    }

    /** ----------------------------------
     * ! External functions | Manager Role
     * ----------------------------------- */

    /**
     * @notice The way to upgrade contracts
     * @notice Only Manager address (multisig wallet) has access to upgrade
     * @notice All parameters are optional
     */
    function upgradeContracts(
        address controller,
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage
    ) external onlyRole(MANAGER_ROLE) {
        _upgradeContracts(
            controller,
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            converterLogic,
            energyStorage
        );
    }

    function setManager(address multisig) external onlyRole(MANAGER_ROLE) {
        _setManager(multisig);
        stakingLogic_.setManager(multisig);
        converterLogic_.setManager(multisig);
    }

    function setController(address newContract) external onlyRole(MANAGER_ROLE) {
        _setController(newContract);
    }

    function setStakingLogic(address newContract) external onlyRole(MANAGER_ROLE) {
        _setStakingLogic(newContract);
    }

    function setAstoStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setAstoStorage(newContract);
    }

    function setLpStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setLpStorage(newContract);
    }

    function setConverterLogic(address newContract) external onlyRole(MANAGER_ROLE) {
        _setConverterLogic(newContract);
    }

    function setEnergyStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setEnergyStorage(newContract);
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        stakingLogic_.pause();
        converterLogic_.pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        stakingLogic_.unpause();
        converterLogic_.unpause();
    }

    /** ----------------------------------
     * ! Public functions | Getters
     * ----------------------------------- */

    function getController() public view returns (address) {
        return address(this);
    }

    function getManager() public view returns (address) {
        return manager;
    }

    function getStakingLogic() public view returns (address) {
        return address(stakingLogic_);
    }

    function getAstoStorage() public view returns (address) {
        return address(astoStorage_);
    }

    function getLpStorage() public view returns (address) {
        return address(lpStorage_);
    }

    function getConverterLogic() public view returns (address) {
        return address(converterLogic_);
    }

    function getEnergyStorage() public view returns (address) {
        return address(energyStorage_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Staking.sol";
import "./EnergyStorage.sol";
import "./helpers/IConverter.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Converter Logic contract
 *
 * This contracts provides functionality for ASTO Energy calculation and conversion.
 * Energy is calculated based on the token staking history from staking contract and multipliers pre-defined for ASTO and LP tokens.
 * Eenrgy can be consumed on multiple purposes.
 */
contract Converter is IConverter, IStaking, TimeConstants, Util, PermissionControl, Pausable {
    using SafeMath for uint256;

    bool private _initialized = false;

    uint256 public periodIdCounter = 0;
    // PeriodId start from 1
    mapping(uint256 => Period) public periods;

    Staking public stakingLogic_;
    EnergyStorage public energyStorage_;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    event EnergyUsed(address addr, uint256 amount);

    constructor(address controller) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        _grantRole(CONTROLLER_ROLE, controller);
        _grantRole(USER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @dev Get consumed energy amount for address `addr
     *
     * @param addr The wallet address to get consumed energy for
     * @return Consumed energy amount
     */
    function getConsumedEnergy(address addr) public view returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        return energyStorage_.consumedAmount(addr);
    }

    /**
     * @dev Calculate the energy for `addr` based on the staking history  before the endTime of specified period
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount
     */
    function calculateEnergy(address addr, uint256 periodId) public view returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);

        Period memory period = getPeriod(periodId);

        Stake[] memory astoHistory = stakingLogic_.getHistory(ASTO_TOKEN_ID, addr, period.endTime);
        Stake[] memory lpHistory = stakingLogic_.getHistory(LP_TOKEN_ID, addr, period.endTime);

        uint256 astoEnergyAmount = _calculateEnergyForToken(astoHistory, period.astoMultiplier);
        uint256 lpEnergyAmount = _calculateEnergyForToken(lpHistory, period.lpMultiplier);

        return (astoEnergyAmount + lpEnergyAmount);
    }

    /**
     * @dev Calculate the energy for specific staked token
     *
     * @param history The staking history for the staked token
     * @param multiplier The multiplier for staked token
     * @return total energy amount for the token
     */
    function _calculateEnergyForToken(Stake[] memory history, uint256 multiplier) internal view returns (uint256) {
        uint256 total = 0;
        uint256 prevStakedAmount = 0;
        for (uint256 i = 0; i < history.length; i++) {
            if (currentTime() < history[i].time) continue;

            uint256 elapsedTime = currentTime().sub(history[i].time);
            uint256 elapsedDays = elapsedTime.div(SECONDS_PER_DAY);
            total = total.add(elapsedDays.mul(history[i].amount.sub(prevStakedAmount)).mul(multiplier));
            prevStakedAmount = history[i].amount;
        }
        return total;
    }

    /**
     * @dev Get the energy amount available for address `addr`
     *
     * @param addr The wallet address to get energy for
     * @param periodId The period id for energy calculation
     * @return Energy amount available
     */
    function getEnergy(address addr, uint256 periodId) public view returns (uint256) {
        return calculateEnergy(addr, periodId) - getConsumedEnergy(addr);
    }

    /**
     * @dev Consume energy generated before the endTime of period `periodId`
     *
     * @param addr The wallet address to consume from
     * @param periodId The period id for energy consumption
     * @param amount The amount of energy to consume
     */
    function useEnergy(
        address addr,
        uint256 periodId,
        uint256 amount
    ) external whenNotPaused onlyRole(USER_ROLE) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
        if (amount > getEnergy(addr, periodId)) revert InvalidInput(WRONG_AMOUNT);

        energyStorage_.increaseConsumedAmount(addr, amount);

        emit EnergyUsed(addr, amount);
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    /**
     * @dev Get period data by period id `periodId`
     *
     * @param periodId The id of period to get
     * @return a Period struct
     */
    function getPeriod(uint256 periodId) public view returns (Period memory) {
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
        return periods[periodId];
    }

    /**
     * @notice Get the current period based on current timestamp
     *
     * @return current period data
     */
    function getCurrentPeriod() public view returns (Period memory) {
        return periods[getCurrentPeriodId()];
    }

    /**
     * @notice Get the current period id based on current timestamp
     *
     * @return current periodId
     */
    function getCurrentPeriodId() public view returns (uint256) {
        for (uint256 index = 1; index <= periodIdCounter; index++) {
            Period memory p = periods[index];
            if (currentTime() >= uint256(p.startTime) && currentTime() < uint256(p.endTime)) {
                return index;
            }
        }
        return 0;
    }

    /**
     * @notice Get the current periodId based on current timestamp
     * @dev Can be overridden by child contracts
     *
     * @return current timestamp
     */
    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /** ----------------------------------
     * ! Administration          | MANAGER
     * ----------------------------------- */

    function setUser(address addr) external onlyRole(MANAGER_ROLE) {
        _updateRole(USER_ROLE, addr);
    }

    /**
     * @dev Initialize pre-defined periods
     */
    function _initPeriods(Period[] memory _periods) internal {
        for (uint256 i = 0; i < _periods.length; i++) {
            _addPeriod(_periods[i]);
        }
    }

    /**
     * @dev Add a new period
     * @dev This is an internal function
     *
     * @param period The period instance to add
     */
    function _addPeriod(Period memory period) internal {
        periods[++periodIdCounter] = period;
    }

    /**
     * @dev Add a new period
     * @dev Only manager contract has the permission to call this function
     *
     * @param period The period instance to add
     */
    function addPeriod(Period memory period) external onlyRole(MANAGER_ROLE) {
        _addPeriod(period);
    }

    /**
     * @dev Update a period
     * @dev This is an internal function
     *
     * @param periodId The period id to update
     * @param period The period data to update
     */
    function _updatePeriod(uint256 periodId, Period memory period) internal {
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
        periods[periodId] = period;
    }

    /**
     * @dev Update a period
     * @dev Only manager contract has the permission to call this function
     *
     * @param periodId The period id to update
     * @param period The period data to update
     */
    function updatePeriod(uint256 periodId, Period memory period) external whenNotPaused onlyRole(MANAGER_ROLE) {
        _updatePeriod(periodId, period);
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Initialize the contract:
     * @dev only controller is allowed to call this function
     *
     * @param manager The manager contract address
     * @param energyStorage The energy storage contract address
     * @param stakingLogic The staking logic contrct address
     */
    function init(
        address manager,
        address energyStorage,
        address stakingLogic
    ) external onlyRole(CONTROLLER_ROLE) {
        if (_initialized) revert ContractError(ALREADY_INITIALIZED);

        if (!_isContract(energyStorage)) revert ContractError(INVALID_ENERGY_STORAGE);
        if (!_isContract(stakingLogic)) revert ContractError(INVALID_STAKING_LOGIC);

        stakingLogic_ = Staking(stakingLogic);
        energyStorage_ = EnergyStorage(energyStorage);

        _grantRole(MANAGER_ROLE, manager);
        _unpause();
        _initialized = true;
    }

    /**
     * @dev Update the manager contract address
     * @dev only manager is allowed to call this function
     */
    function setManager(address newManager) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(MANAGER_ROLE, newManager);
    }

    /**
     * @dev Update the controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }

    /**
     * @dev Pause the contract
     * @dev only controller is allowed to call this function
     */
    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @dev only controller is allowed to call this function
     */
    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Energy Storage contract
 *
 * Store consumed energy amount for each address.
 * This contract will be called from Converter logic contract (Converter.sol)
 */
contract EnergyStorage is Util, Pausable, PermissionControl {
    bool private _initialized = false;
    mapping(address => uint256) public consumedAmount;

    constructor(address controller) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        _grantRole(CONTROLLER_ROLE, controller);
        _pause();
    }

    /**
     * @dev Increase consumed energy for address `addr`
     * @dev can only be called by Converter
     *
     * @param addr The wallet address which consumed the energy
     * @param amount The amount of consumed energy
     */
    function increaseConsumedAmount(address addr, uint256 amount) external whenNotPaused onlyRole(CONVERTER_ROLE) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        consumedAmount[addr] += amount;
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

    /**
     * @dev Initialize the contract:
     * @dev only controller is allowed to call this function
     *
     * @param converterLogic Converter logic contract address
     */
    function init(address converterLogic) external onlyRole(CONTROLLER_ROLE) {
        if (_initialized) revert ContractError(ALREADY_INITIALIZED);
        if (!_isContract(converterLogic)) revert ContractError(INVALID_CONVERTER_LOGIC);

        _setupRole(CONVERTER_ROLE, converterLogic);
        _unpause();
        _initialized = true;
    }

    /**
     * @dev Pause the contract
     * @dev only controller is allowed to call this function
     */
    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @dev only controller is allowed to call this function
     */
    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }

    /**
     * @dev Update the controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";

import "./Controller.sol";
import "./helpers/Util.sol";
import "./StakingStorage.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Logic contract
 */

contract Staking is IStaking, TimeConstants, Util, PermissionControl, Pausable {
    using SafeERC20 for IERC20;

    bool private _initialized = false;

    /**
     * `_token`:  tokenId => token contract address
     * `_token`:  tokenId => token name
     * `_storage`:  tokenId => storage contract address
     * `_totalStakedAmount`:  tokenId => total staked amount for that tokenId
     *
     * IDs: 0 for ASTO, 1 for LP tokens, see `init()` below
     */
    mapping(uint256 => IERC20) private _token;
    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => StakingStorage) private _storage;
    mapping(uint256 => uint256) private _totalStakedAmount;

    constructor(address controller) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        _setupRole(CONTROLLER_ROLE, controller);
        _setupRole(MANAGER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Administration          | MANAGER
     * ----------------------------------- */

    /**
     * @notice Withdraw tokens left in the contract to specified address
     * @param tokenId - ID of token to stake
     * @param recipient recipient of the transfer
     * @param amount Token amount to withdraw
     */
    function withdraw(
        uint256 tokenId,
        address recipient,
        uint256 amount
    )
        public
        whenPaused // when contract is paused ONLY
        onlyRole(MANAGER_ROLE)
    {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (address(recipient) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (_token[tokenId].balanceOf(address(this)) < amount) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransfer(recipient, amount);
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only Manager is allowed to call admin functions
     * @dev only controller is allowed to update permissions - to reduce amount of DAO votings
     *
     * @param astoToken ASTO Token contract address
     * @param lpToken LP Token contract address
     * @param astoStorage ASTO staking storage contract address
     * @param lpStorage LP staking storage contract address
     */
    function init(
        address manager,
        IERC20 astoToken,
        address astoStorage,
        IERC20 lpToken,
        address lpStorage
    ) public onlyRole(CONTROLLER_ROLE) {
        require(_initialized == false, ALREADY_INITIALIZED);

        _token[0] = astoToken;
        _storage[0] = StakingStorage(astoStorage);

        _token[1] = lpToken;
        _storage[1] = StakingStorage(lpStorage);

        _updateRole(MANAGER_ROLE, manager);
        _unpause();
        _initialized = true;
    }

    /**
     * @dev Update the manager contract address
     * @dev only manager is allowed to call this function
     */
    function setManager(address newManager) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(MANAGER_ROLE, newManager);
    }

    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }

    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @notice Save user's stake
     *
     * @notice Staking is a process of locking your tokens in this contract.
     * @notice Details of the stake are to be stored and used for calculations
     * @notice what time your tokens are stay staked.
     *
     * @dev Prerequisite:
     * @dev - amount of tokens to stake should be approved by user.
     * @dev - this contract should have a `STAKER_ROLE` to call
     * @dev   the storage's `updateHistory()` function.
     *
     * @dev Depending on tokenId passed, it:
     * @dev 1. transfers tokens from user to this contract
     * @dev 2. calls an appropriate token storage and saves time and amount of stake.
     *
     * @dev Emit `UnStaked` event on success: with token name, user address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function stake(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (tokenId > 1) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);
        address user = msg.sender;
        uint256 userBalance = _token[tokenId].balanceOf(user);
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransferFrom(user, address(this), amount);
        _storage[tokenId].updateHistory(user, amount);
        _totalStakedAmount[tokenId] += amount;

        emit Staked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice Unstake user's stake
     *
     * @notice Unstaking is a process of getting back previously staked tokens.
     * @notice Users can unlock their tokens any time.
     *
     * @dev No prerequisites
     * @dev Users can unstake only their own, previously staked  tokens
     * @dev Emit `UnStaked` event on success: with token name, user address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function unstake(uint256 tokenId, uint256 amount) external {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);

        address user = msg.sender;
        uint256 id = _storage[tokenId].getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (_storage[tokenId].getStake(user, id)).amount;
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        uint256 newAmount = userBalance - amount;
        _storage[tokenId].updateHistory(user, newAmount);
        _totalStakedAmount[tokenId] -= amount; // TODO: add tests for checking totalAmount

        _token[tokenId].safeTransfer(user, amount);

        emit UnStaked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice Returns the total amount of tokens staked by all users
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return amount of tokens staked in the contract, uint256
     */
    function getTotalValueLocked(uint256 tokenId) external view returns (uint256) {
        return _totalStakedAmount[tokenId];
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    /**
     * @notice Returns address of the token storage contract
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return address of the token storage contract
     */
    function getStorageAddress(uint256 tokenId) public view returns (address) {
        return address(_storage[tokenId]);
    }

    /**
     * @notice Returns address of the token contract
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return address of the token contract
     */
    function getTokenAddress(uint256 tokenId) public view returns (address) {
        return address(_token[tokenId]);
    }

    /**
     * @notice Returns the staking history of user
     *
     * @param tokenId ASTO - 0, LP - 1
     * @param addr user wallet address
     * @param endTime until what time tokens were staked
     * @return sorted list of stakes, for each stake: { time, amount },
     *         starting with earliest
     */
    function getHistory(
        uint256 tokenId,
        address addr,
        uint256 endTime
    ) public view returns (Stake[] memory) {
        return _storage[tokenId].getHistory(addr, endTime);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./Controller.sol";
import "./Staking.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract StakingStorage is IStaking, PermissionControl, Util, Pausable {
    bool private _initialized = false;

    // Incrementing stake Id used to record history
    mapping(address => uint256) private _stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint256 => Stake)) private _stakeHistory;

    constructor(address controller) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        _setupRole(CONTROLLER_ROLE, controller);
        _setupRole(STAKER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @notice Saving stakes into storage.
     * @notice Function can be called only manager
     *
     * @param addr - user address
     * @param amount - amount of tokens to stake
     * @return stakeID
     */
    function updateHistory(address addr, uint256 amount) public onlyRole(STAKER_ROLE) returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);

        uint128 time = uint128(currentTime());
        Stake memory newStake = Stake(time, amount);
        uint256 userStakeId = ++_stakeIds[addr]; // ++i cheaper than i++, so, _stakeHistory[addr] starts from 1
        _stakeHistory[addr][userStakeId] = newStake;
        return userStakeId;
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getStake(address addr, uint256 id) public view returns (Stake memory) {
        return _stakeHistory[addr][id];
    }

    function getHistory(address addr, uint256 endTime) public view returns (Stake[] memory) {
        uint256 totalStakes = _stakeIds[addr];

        Stake[] memory stakes = new Stake[](totalStakes); // suboptimal - it could be larger than needed, when endTime is lesser than current time

        // _stakeHistory[addr] starts from 1, see `updateHistory`
        for (uint256 i = 1; i < totalStakes + 1; i++) {
            Stake memory stake = _stakeHistory[addr][i];
            if (stake.time <= endTime) stakes[i - 1] = stake;
            else {
                // shortening array before returning
                Stake[] memory res = new Stake[](i - 1);
                for (uint256 j = 0; j < res.length; j++) res[j] = stakes[j];
                return res;
            }
        }
        return stakes;
    }

    function getUserLastStakeId(address addr) public view returns (uint256) {
        return _stakeIds[addr];
    }

    /**
     * @notice Get the current periodId based on current timestamp
     * @dev Can be overridden by child contracts
     *
     * @return current timestamp
     */
    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only Staker is allowed to save into this storage
     * @dev only Controller is allowed to update permissions - to reduce amount of DAO votings
     * @dev
     *
     * @param controller Controller contract address
     * @param stakingLogic Staking contract address
     */
    function init(address stakingLogic) public onlyRole(CONTROLLER_ROLE) {
        require(_initialized == false, ALREADY_INITIALIZED);
        _updateRole(STAKER_ROLE, stakingLogic);
        _unpause();
        _initialized = true;
    }

    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev Interface for Converter
 */
interface IConverter {
    struct Period {
        uint128 startTime;
        uint128 endTime;
        uint128 astoMultiplier;
        uint128 lpMultiplier;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev For testing purpose
 */
interface IStaking {
    event Staked(string tokenName, address indexed staker, uint256 timestamp, uint256 amount);
    event UnStaked(string tokenName, address indexed staker, uint256 timestamp, uint256 amount);

    struct Stake {
        uint256 time; // Time for precise calculations
        uint256 amount; // New amount on every new (un)stake
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev ASM Genome Mining - PermissionControl contract
 */
contract PermissionControl is AccessControl {
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant STAKER_ROLE = keccak256("STAKER_ROLE");
    bytes32 public constant CONVERTER_ROLE = keccak256("CONVERTER_ROLE");

    /**
     * @dev Update `role` from the sender to `_newAddress`.
     *
     * Internal function without access restriction.
     */
    function _updateRole(bytes32 role, address _newAddress) internal {
        _revokeRole(role, msg.sender);
        _grantRole(role, _newAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev ASM Genome Mining - ASTO Time constants we use
 */
contract TimeConstants {
    // all variables are public to make them available in tests
    uint256 public constant DAYS_PER_WEEK = 7;
    uint256 public constant HOURS_PER_DAY = 24;
    uint256 public constant MINUTES_PER_HOUR = 60;
    uint256 public constant SECONDS_PER_MINUTE = 60;
    uint256 public constant SECONDS_PER_HOUR = 3600;
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant SECONDS_PER_WEEK = 604800;
    uint256 public constant DURATION_WEEKS = 40;
    uint256 public constant DURATION_SECONDS = DURATION_WEEKS * SECONDS_PER_WEEK;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev ASM Genome Mining - Utility contract
 */
contract Util {
    error InvalidInput(string errMsg);
    error ContractError(string errMsg);

    string constant ALREADY_INITIALIZED = "The contract has already been initialized";
    string constant INVALID_MULTISIG = "Invalid Multisig contract";
    string constant INVALID_CONTROLLER = "Invalid Controller contract";
    string constant INVALID_STAKING_LOGIC = "Invalid Staking Logic contract";
    string constant INVALID_STAKING_STORAGE = "Invalid Staking Storage contract";
    string constant INVALID_CONVERTER_LOGIC = "Invalid Converter Logic contract";
    string constant INVALID_ENERGY_STORAGE = "Invalid Energy Storage contract";
    string constant INVALID_ASTO_CONTRACT = "Invalid ASTO contract";
    string constant INVALID_LP_CONTRACT = "Invalid LP contract";
    string constant WRONG_ADDRESS = "Wrong or missed wallet address";
    string constant WRONG_AMOUNT = "Wrong or missed amount";
    string constant WRONG_PERIOD_ID = "Wrong periodId";
    string constant WRONG_TOKEN = "Token not allowed for staking";
    string constant INSUFFICIENT_BALANCE = "Insufficient token balance";
    string constant INSUFFICIENT_STAKED_AMOUNT = "Requested amount is greater than a stake";
    string constant NO_STAKES = "No stakes yet";

    /**
     * @notice Among others, `isContract` will return false for the following
     * @notice types of addresses:
     * @notice  - an externally-owned account
     * @notice  - a contract in construction
     * @notice  - an address where a contract will be created
     * @notice  - an address where a contract lived, but was destroyed
     *
     * @dev Attention!
     * @dev if _isContract() called from the constructor,
     * @dev addr.code.length will be equal to 0, and
     * @dev this function will return false.
     *
     */
    function _isContract(address addr) internal view returns (bool) {
        return addr.code.length > 0;
    }
}