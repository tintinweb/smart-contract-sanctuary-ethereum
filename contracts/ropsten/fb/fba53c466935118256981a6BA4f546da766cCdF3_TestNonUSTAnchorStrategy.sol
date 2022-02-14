// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

library PercentMath {
    // Divisor used for representing percentages
    uint256 public constant PERC_DIVISOR = 10000;

    /**
     * @dev Returns whether an amount is a valid percentage out of PERC_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage
     * @param _fracDenom Denominator of fraction representing the percentage
     */
    function percOf(
        uint256 _amount,
        uint256 _fracNum,
        uint256 _fracDenom
    ) internal pure returns (uint256) {
        return (_amount * percPoints(_fracNum, _fracDenom)) / PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator
     */
    function percOf(uint256 _amount, uint256 _fracNum)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _fracNum) / PERC_DIVISOR;
    }

    /**
     * @dev Checks if a given number corresponds to 100%
     * @param _perc Percentage value to check, with PERC_DIVISOR
     */
    function is100Perc(uint256 _perc) internal pure returns (bool) {
        return _perc == PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage representation of a fraction
     * @param _fracNum Numerator of fraction represeting the percentage
     * @param _fracDenom Denominator of fraction represeting the percentage
     */
    function percPoints(uint256 _fracNum, uint256 _fracDenom)
        internal
        pure
        returns (uint256)
    {
        return (_fracNum * PERC_DIVISOR) / _fracDenom;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IStrategy.sol";
import "../lib/PercentMath.sol";
import "../vault/IVault.sol";
import "./anchor/IEthAnchorRouter.sol";

/**
 * Base eth anchor strategy that handles UST tokens and invests them via the EthAnchor
 * protocol (https://docs.anchorprotocol.com/ethanchor/ethanchor)
 */
abstract contract BaseStrategy is IStrategy, AccessControl {
    using SafeERC20 for IERC20;
    using PercentMath for uint256;

    event PerfFeeClaimed(uint256 amount);
    event PerfFeePctUpdated(uint256 pct);
    event InitDepositStable(
        address indexed operator,
        uint256 indexed idx,
        uint256 underlyingAmount,
        uint256 ustAmount
    );
    event FinishDepositStable(
        address indexed operator,
        uint256 ustAmount,
        uint256 aUstAmount
    );
    event InitRedeemStable(address indexed operator, uint256 aUstAmount);
    event FinishRedeemStable(
        address indexed operator,
        uint256 aUstAmount,
        uint256 ustAmount,
        uint256 underlyingAmount
    );

    struct Operation {
        address operator;
        uint256 amount;
    }

    bytes32 public constant MANAGER_ROLE =
        0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08; // keccak256("MANAGER_ROLE");

    // Underlying token address
    IERC20 public override(IStrategy) underlying;

    // Vault address
    address public override(IStrategy) vault;

    // Treasury address
    address public treasury;

    // UST token address
    IERC20 public ustToken;

    // aUST token address (wrapped Anchor UST, received to accrue interest for an Anchor deposit)
    IERC20 public aUstToken;

    // performance fee taken by the treasury on profits
    uint16 public perfFeePct;

    // Router contract to interact with EthAnchor
    IEthAnchorRouter public ethAnchorRouter;

    // Chainlink aUST / UST price feed
    AggregatorV3Interface public aUstToUstFeed;

    // amount currently pending in deposits to EthAnchor
    uint256 public pendingDeposits;

    // amount currently pending redeemption from EthAnchor
    uint256 public pendingRedeems;

    // deposit operations history
    Operation[] public depositOperations;

    // redeem operations history
    Operation[] public redeemOperations;

    // amount of UST converted (used to calculate yield)
    uint256 public convertedUst;

    // Decimals of aUST / UST feed
    uint256 internal _aUstToUstFeedDecimals;

    modifier onlyManager() {
        require(
            hasRole(MANAGER_ROLE, msg.sender),
            "BaseStrategy: caller is not manager"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "BaseStrategy: caller is not admin"
        );
        _;
    }

    /**
     * Constructor of Base Strategy - Initialize required addresses and params
     *
     * @notice Vault will be automatically set to Manager Role to handle underlyings
     *
     * @param _vault Vault address
     * @param _treasury Treasury address
     * @param _ethAnchorRouter EthAnchorRouter address
     * @param _aUstToUstFeed aUST / UST chainlink feed address
     * @param _ustToken UST token address
     * @param _aUstToken aUST token address
     * @param _perfFeePct Performance fee percentage
     * @param _owner Owner address
     */
    constructor(
        address _vault,
        address _treasury,
        address _ethAnchorRouter,
        AggregatorV3Interface _aUstToUstFeed,
        IERC20 _ustToken,
        IERC20 _aUstToken,
        uint16 _perfFeePct,
        address _owner
    ) {
        require(_owner != address(0), "BaseStrategy: owner is 0x");
        require(_ethAnchorRouter != address(0), "BaseStrategy: router is 0x");
        require(_treasury != address(0), "BaseStrategy: treasury is 0x");
        require(
            PercentMath.validPerc(_perfFeePct),
            "BaseStrategy: invalid performance fee"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MANAGER_ROLE, _vault);

        treasury = _treasury;
        vault = _vault;
        underlying = IVault(_vault).underlying();
        ethAnchorRouter = IEthAnchorRouter(_ethAnchorRouter);
        aUstToUstFeed = _aUstToUstFeed;
        ustToken = _ustToken;
        aUstToken = _aUstToken;
        perfFeePct = _perfFeePct;

        _aUstToUstFeedDecimals = 10**_aUstToUstFeed.decimals();
    }

    /**
     * Invest underlying assets to EthAnchor contract.
     */
    function doHardWork() external virtual;

    /**
     * Initiates available UST to EthAnchor
     *
     * @notice since EthAnchor uses an asynchronous model, this function
     * only starts the deposit process, but does not finish it.
     * Each EthAnchor deposits are handled by different operator, so we store
     * operator address to finish later.
     * We need to increase pendingDeposits to track correct underlying assets.
     */
    function _initDepositStable() internal returns (address, uint256) {
        uint256 ustBalance = _getUstBalance();
        require(ustBalance > 0, "BaseStrategy: no ust exist");
        pendingDeposits += ustBalance;

        ustToken.safeIncreaseAllowance(address(ethAnchorRouter), ustBalance);
        address operator = ethAnchorRouter.initDepositStable(ustBalance);
        depositOperations.push(
            Operation({operator: operator, amount: ustBalance})
        );

        return (operator, ustBalance);
    }

    /**
     * Calls EthAnchor with a pending deposit ID, and attempts to finish it.
     *
     * @notice Must be called some time after `_initDepositStable()`. Will only work if
     * the EthAnchor bridge has finished processing the deposit.
     *
     * @param idx Id of the pending deposit operation
     */
    function finishDepositStable(uint256 idx) external onlyManager {
        require(depositOperations.length > idx, "BaseStrategy: not running");
        Operation storage operation = depositOperations[idx];
        address operator = operation.operator;

        uint256 aUstBalanceBefore = _getAUstBalance();

        ethAnchorRouter.finishDepositStable(operator);
        uint256 newAUst = _getAUstBalance() - aUstBalanceBefore;
        require(newAUst > 0, "BaseStrategy: no aUST returned");

        uint256 ustAmount = operation.amount;
        pendingDeposits -= ustAmount;
        convertedUst += ustAmount;

        emit FinishDepositStable(operator, ustAmount, newAUst);

        if (idx < depositOperations.length - 1) {
            Operation memory lastOperation = depositOperations[
                depositOperations.length - 1
            ];
            operation.operator = lastOperation.operator;
            operation.amount = lastOperation.amount;
        }

        depositOperations.pop();
    }

    /**
     * Initiates a withdrawal of UST from EthAnchor
     *
     * @notice since EthAnchor uses an asynchronous model, this function
     * only starts the redeem process, but does not finish it.
     *
     * @param amount Amount of aUST to redeem
     */
    function initRedeemStable(uint256 amount) public onlyManager {
        uint256 aUstBalance = _getAUstBalance();
        require(amount > 0, "BaseStrategy: amount 0");
        pendingRedeems += amount;

        aUstToken.safeIncreaseAllowance(address(ethAnchorRouter), amount);
        address operator = ethAnchorRouter.initRedeemStable(amount);

        redeemOperations.push(Operation({operator: operator, amount: amount}));

        emit InitRedeemStable(operator, amount);
    }

    /**
     * Request withdrawal from EthAnchor
     *
     * @notice since EthAnchor uses an asynchronous model, we can only request withdrawal for whole aUST
     */
    function withdrawAllToVault() external override(IStrategy) onlyManager {
        uint256 aUstBalance = _getAUstBalance();
        if (aUstBalance != 0) {
            initRedeemStable(aUstBalance);
        }
    }

    /**
     * Withdraws a specified amount back to the vault
     *
     * @notice since EthAnchor uses an asynchronous model, and there is no underlying amount
     * in the strategy, this function do nothing at all, However override interface of IStrategy.
     */
    function withdrawToVault(uint256 amount)
        external
        override(IStrategy)
        onlyManager
    {}

    /**
     * Updates the performance fee
     *
     * @notice Can only be called by governance
     *
     * @param _perfFeePct The new performance fee %
     */
    function setPerfFeePct(uint16 _perfFeePct) external onlyAdmin {
        require(
            PercentMath.validPerc(_perfFeePct),
            "BaseStrategy: invalid performance fee"
        );
        perfFeePct = _perfFeePct;
        emit PerfFeePctUpdated(_perfFeePct);
    }

    /// See {IStrategy}
    function applyInvestmentFee(uint256 _amount)
        external
        view
        virtual
        override(IStrategy)
        returns (uint256)
    {
        return _amount.percOf(9800);
    }

    /**
     * Amount, expressed in the underlying currency, currently in the strategy
     *
     * @notice both held and invested amounts are included here, using the
     * latest known exchange rates to the underlying currency.
     * This will return value without performance fee.
     *
     * @return The total amount of underlying
     */
    function investedAssets()
        external
        view
        virtual
        override(IStrategy)
        returns (uint256);

    /**
     * Calls EthAnchor with a pending redeem ID, and attempts to finish it.
     *
     * @notice Must be called some time after `initRedeemStable()`. Will only work if
     * the EthAnchor bridge has finished processing the deposit.
     * Will take performance fee if some yield generated.
     *
     * @param idx Id of the pending redeem operation
     *
     * @return Redeemed UST amount without performance fee.
     */
    function _finishRedeemStable(uint256 idx)
        internal
        returns (
            address,
            uint256,
            uint256
        )
    {
        require(redeemOperations.length > idx, "BaseStrategy: not running");
        Operation storage operation = redeemOperations[idx];
        uint256 aUstBalance = _getAUstBalance() + pendingRedeems;

        uint256 operationAmount = operation.amount;
        address operator = operation.operator;
        uint256 originalUst = (convertedUst * operationAmount) / aUstBalance;

        ethAnchorRouter.finishRedeemStable(operator);

        uint256 redeemedAmount = _getUstBalance();
        require(redeemedAmount > 0, "BaseStrategy: nothing redeemed");

        uint256 perfFee = redeemedAmount > originalUst
            ? (redeemedAmount - originalUst).percOf(perfFeePct)
            : 0;
        if (perfFee != 0) {
            ustToken.safeTransfer(treasury, perfFee);
            emit PerfFeeClaimed(perfFee);
        }
        convertedUst -= originalUst;
        pendingRedeems -= operationAmount;

        if (idx < redeemOperations.length - 1) {
            Operation memory lastOperation = redeemOperations[
                redeemOperations.length - 1
            ];
            operation.operator = lastOperation.operator;
            operation.amount = lastOperation.amount;
        }
        redeemOperations.pop();

        return (operator, operationAmount, redeemedAmount - perfFee);
    }

    /**
     * @return underlying balance of strategy
     */
    function _getUnderlyingBalance() internal view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * @return UST balance of strategy
     */
    function _getUstBalance() internal view returns (uint256) {
        return ustToken.balanceOf(address(this));
    }

    /**
     * @return aUST balance of strategy
     */
    function _getAUstBalance() internal view returns (uint256) {
        return aUstToken.balanceOf(address(this));
    }

    /**
     * @return Length of pending deposit operations
     */
    function depositOperationLength() external view returns (uint256) {
        return depositOperations.length;
    }

    /**
     * @return Length of pending redeem operations
     */
    function redeemOperationLength() external view returns (uint256) {
        return redeemOperations.length;
    }

    /**
     * Calculate performance fee for known aUST balance and aUST / UST exchange rate.
     *
     * @return Length of pending redeem operations
     */
    function _performanceUstFeeWithInfo(uint256 aUstBalance, uint256 price)
        private
        view
        returns (uint256)
    {
        // aUST and UST decimals are same, so we only care about aUST / UST feed decimals
        uint256 estimatedUstAmount = (price * aUstBalance) /
            _aUstToUstFeedDecimals;
        if (estimatedUstAmount > convertedUst) {
            return (estimatedUstAmount - convertedUst).percOf(perfFeePct);
        }
        return 0;
    }

    /**
     * Calculate current performance fee amount
     *
     * @notice Performance fee is in UST
     *
     * @return current performance fee
     */
    function currentPerformanceFee() external view returns (uint256) {
        if (convertedUst == 0) {
            return 0;
        }

        uint256 aUstBalance = _getAUstBalance() + pendingRedeems;

        return _performanceUstFeeWithInfo(aUstBalance, _aUstExchangeRate());
    }

    /**
     * @return UST value of current aUST balance (+ pending redeems) without performance fee
     */
    function _estimateAUstBalanceInUstMinusFee()
        internal
        view
        returns (uint256)
    {
        uint256 aUstBalance = _getAUstBalance() + pendingRedeems;

        if (aUstBalance == 0) {
            return 0;
        }

        uint256 aUstPrice = _aUstExchangeRate();

        return
            ((aUstPrice * aUstBalance) / _aUstToUstFeedDecimals) -
            _performanceUstFeeWithInfo(aUstBalance, aUstPrice);
    }

    /**
     * @return aUST / UST exchange rate from chainlink
     */
    function _aUstExchangeRate() internal view virtual returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 updateTime,
            uint80 answeredInRound
        ) = aUstToUstFeed.latestRoundData();

        require(
            price > 0 && updateTime != 0 && answeredInRound >= roundID,
            "invalid price"
        );

        return uint256(price);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * ERC20 token interface with decimals
 */
interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Strategies can be plugged into vaults to invest and manage their underlying funds
 *
 * @notice It's up to the strategy to decide what do to with investable assets provided by a vault
 *
 * @notice It's up to the vault to decide how much to invest from the total pool
 */
interface IStrategy {
    /**
     * The underlying ERC20 token stored by the vault
     *
     * @return The ERC20 token address
     */
    function underlying() external view returns (IERC20);

    /**
     * The vault linked to this stragegy
     *
     * @return The vault's address
     */
    function vault() external view returns (address);

    /**
     * Withdraws all underlying back to vault.
     *
     * @notice If underlying is currently invested, this also starts the
     * cross-chain process to redeem it. After that is done, this function
     * should be called a second time to finish the withdrawal of that portion.
     */
    function withdrawAllToVault() external;

    /**
     * Withdraws a specified amount back to the vault
     *
     * @notice Unlike `withdrawToVault`, this function only considers the
     * amount currently not invested, but only what is currently held by the
     * strategy
     *
     * @param amount Amount to withdraw
     */
    function withdrawToVault(uint256 amount) external;

    /**
     * Amount, expressed in the underlying currency, currently in the strategy
     *
     * @notice both held and invested amounts are included here, using the
     * latest known exchange rates to the underlying currency
     *
     * @return The total amount of underlying
     */
    function investedAssets() external view returns (uint256);

    /**
     * Applies an estimated fee to the given @param _amount.
     *
     * This function should be used to estimate how much underlying will be
     * left after the strategy invests. For instance, the fees taken by Anchor
     * and Curve.
     *
     * @param _amount Amount to apply the fees to.
     *
     * @return Amount with the fees applied.
     */
    function applyInvestmentFee(uint256 _amount) external view returns (uint256);

    /**
     * Initiates the process of investing the underlying currency
     */
    function doHardWork() external;

    /**
     * Calls EthAnchor with a pending redeem ID, and attempts to finish it.
     *
     * @notice Must be called some time after `initRedeemStable()`. Will only work if
     * the EthAnchor bridge has finished processing the deposit.
     *
     * @param idx Id of the pending redeem operation
     */
    function finishRedeemStable(uint256 idx) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./curve/ICurve.sol";
import "./BaseStrategy.sol";
import "./IERC20Detailed.sol";

/**
 * EthAnchor Strategy that handles non-UST tokens, by first converting them to UST via
 * Curve (https://curve.fi/), and only then depositing into EthAnchor
 */
contract NonUSTStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    event Initialized();

    // UST / USDC / USDT / DAI curve pool address
    ICurve public curvePool;

    // index of the underlying token in the curve pool
    int128 public underlyingI;

    // index of the UST token in the curve pool
    int128 public ustI;

    // flag to indicate initialization status
    bool public initialized;

    // Chainlink UST / USD feed
    AggregatorV3Interface public ustFeed;

    // Chainlink underlying / USD feed - ex. USDT / USD
    AggregatorV3Interface public underlyingFeed;

    // Underlying decimals multiplier to calculate UST -> Underlying amount
    uint256 internal _underlyingDecimalsMultiplier;

    // UST decimals multiplier to calculate UST -> Underlying amount
    uint256 internal _ustDecimalsMultiplier;

    /**
     * Constructor of Non-UST Strategy
     *
     * @notice The underlying token must be different from UST token.
     */
    constructor(
        address _vault,
        address _treasury,
        address _ethAnchorRouter,
        AggregatorV3Interface _aUstToUstFeed,
        IERC20 _ustToken,
        IERC20 _aUstToken,
        uint16 _perfFeePct,
        address _owner,
        address _curvePool,
        int128 _underlyingI,
        int128 _ustI
    )
        BaseStrategy(
            _vault,
            _treasury,
            _ethAnchorRouter,
            _aUstToUstFeed,
            _ustToken,
            _aUstToken,
            _perfFeePct,
            _owner
        )
    {
        require(underlying != _ustToken, "NonUSTStrategy: invalid underlying");
        require(_curvePool != address(0), "NonUSTStrategy: curve pool is 0x");
        curvePool = ICurve(_curvePool);
        underlyingI = _underlyingI;
        ustI = _ustI;

        ustToken.safeIncreaseAllowance(_curvePool, type(uint256).max);
        underlying.safeIncreaseAllowance(_curvePool, type(uint256).max);
    }

    /**
     * Initialize UST / USD, and Underlying / USD chainlink feed
     *
     * @notice Since constructor has too many variables, we initialize these feed
     * in different function
     */
    function initializeStrategy(
        AggregatorV3Interface _ustFeed,
        AggregatorV3Interface _underlyingFeed
    ) external onlyAdmin {
        require(!initialized, "NonUSTStrategy: already initialized");

        initialized = true;

        ustFeed = _ustFeed;
        underlyingFeed = _underlyingFeed;

        uint8 _underlyingDecimals = _underlyingFeed.decimals() +
            IERC20Detailed(address(underlying)).decimals();
        uint8 _ustDecimals = _ustFeed.decimals() +
            IERC20Detailed(address(ustToken)).decimals();

        // Set underlying decimals multiplier and UST decimals multiplier based on
        // feeds and token decimals
        if (_underlyingDecimals > _ustDecimals) {
            _underlyingDecimalsMultiplier =
                10**(_underlyingDecimals - _ustDecimals);
            _ustDecimalsMultiplier = 1;
        } else if (_underlyingDecimals < _ustDecimals) {
            _underlyingDecimalsMultiplier = 1;
            _ustDecimalsMultiplier = 10**(_ustDecimals - _underlyingDecimals);
        } else {
            _underlyingDecimalsMultiplier = 1;
            _ustDecimalsMultiplier = 1;
        }

        emit Initialized();
    }

    /**
     * Swaps the underlying currency for UST, and initiates a deposit of all
     * the converted UST into EthAnchor
     *
     * @notice since EthAnchor uses an asynchronous model, this function
     * only starts the deposit process, but does not finish it.
     */
    function doHardWork() external override(BaseStrategy) onlyManager {
        require(initialized, "NonUSTStrategy: not initialized");
        uint256 underlyingAmount = _swapUnderlyingToUst();

        (address operator, uint256 ustAmount) = _initDepositStable();

        emit InitDepositStable(
            operator,
            depositOperations.length - 1,
            underlyingAmount,
            ustAmount
        );
    }

    /**
     * Calls Curve to convert the existing underlying balance into UST
     *
     * @return swapped underlying amount
     */
    function _swapUnderlyingToUst() internal virtual returns (uint256) {
        uint256 underlyingBalance = _getUnderlyingBalance();
        require(underlyingBalance > 0, "NonUSTStrategy: no underlying exist");
        // slither-disable-next-line unused-return
        curvePool.exchange_underlying(underlyingI, ustI, underlyingBalance, 0);

        return underlyingBalance;
    }

    /**
     * Calls Curve to convert the existing UST back into the underlying token
     *
     * @return swapped underlying amount
     */
    function _swapUstToUnderlying() internal virtual returns (uint256) {
        uint256 ustBalance = _getUstBalance();
        if (ustBalance > 0) {
            // slither-disable-next-line unused-return
            return
                curvePool.exchange_underlying(ustI, underlyingI, ustBalance, 0);
        }

        return 0;
    }

    /**
     * Calls EthAnchor with a pending redeem ID, and attempts to finish it.
     * Once UST is retrieved, convert it back to underlying via Curve
     * Then transfer underlying to vault.
     *
     * @notice Must be called some time after `initRedeemStable()`. Will only work if
     * the EthAnchor bridge has finished processing the deposit.
     *
     * @param idx Id of the pending redeem operation
     */
    function finishRedeemStable(uint256 idx) public onlyManager {
        (
            address operator,
            uint256 aUstAmount,
            uint256 ustAmount
        ) = _finishRedeemStable(idx);

        _swapUstToUnderlying();
        uint256 underlyingAmount = _getUnderlyingBalance();
        underlying.safeTransfer(vault, underlyingAmount);

        emit FinishRedeemStable(
            operator,
            aUstAmount,
            ustAmount,
            underlyingAmount
        );
    }

    /**
     * Amount, expressed in the underlying currency, currently in the strategy
     *
     * @notice both held and invested amounts are included here, using the
     * latest known exchange rates to the underlying currency
     * This will return value without performance fee.
     *
     * @return The total amount of underlying
     */
    function investedAssets()
        external
        view
        override(BaseStrategy)
        returns (uint256)
    {
        return
            _estimateUstAmountInUnderlying(
                pendingDeposits + _estimateAUstBalanceInUstMinusFee()
            );
    }

    /**
     * @return Underlying value of UST amount
     */
    function _estimateUstAmountInUnderlying(uint256 ustAmount)
        internal
        view
        virtual
        returns (uint256)
    {
        (
            uint80 ustRoundID,
            int256 ustPrice,
            ,
            uint256 ustUpdateTime,
            uint80 ustAnsweredInRound
        ) = ustFeed.latestRoundData();
        (
            uint80 underlyingRoundID,
            int256 underlyingPrice,
            ,
            uint256 underlyingUpdateTime,
            uint80 underlyingAnsweredInRound
        ) = underlyingFeed.latestRoundData();
        require(
            ustPrice > 0 &&
                underlyingPrice > 0 &&
                ustUpdateTime != 0 &&
                underlyingUpdateTime != 0 &&
                ustAnsweredInRound >= ustRoundID &&
                underlyingAnsweredInRound >= underlyingRoundID,
            "NonUSTStrategy: invalid price"
        );
        return
            (ustAmount * uint256(ustPrice) * _underlyingDecimalsMultiplier) /
            (uint256(underlyingPrice) * _ustDecimalsMultiplier);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IEthAnchorRouter {
    function initDepositStable(uint256 _amount) external returns (address);

    function finishDepositStable(address _operation) external;

    function initRedeemStable(uint256 _amount) external returns (address);

    function finishRedeemStable(address _operation) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IExchangeRateFeeder {
    function exchangeRateOf(address _token, bool _simulate)
        external
        view
        returns (uint256);
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../strategy/NonUSTStrategy.sol";
import "../../strategy/anchor/IExchangeRateFeeder.sol";
import "./IUniswapV2Router01.sol";

/**
 * NonUSTAnchorStrategy for testnet.
 * Since aUST/UST chainlink does not exist on testnet, we use EthAnchorExchangeRateFeeder
 * to get aUST/UST exchange rate.
 * And we use uniswap V2 to swap underlying to UST and vice versa.
 */
contract TestNonUSTAnchorStrategy is NonUSTStrategy {
    using SafeERC20 for IERC20;

    IExchangeRateFeeder public exchangeRateFeeder;
    IUniswapV2Router01 public uniV2Router;

    constructor(
        address _vault,
        address _treasury,
        address _ethAnchorRouter,
        AggregatorV3Interface _aUstToUstFeed,
        IExchangeRateFeeder _exchangeRateFeeder,
        IERC20 _ustToken,
        IERC20 _aUstToken,
        uint16 _perfFeePct,
        address _owner,
        address _uniV2Router
    )
        NonUSTStrategy(
            _vault,
            _treasury,
            _ethAnchorRouter,
            _aUstToUstFeed,
            _ustToken,
            _aUstToken,
            _perfFeePct,
            _owner,
            address(0x1),
            0,
            1
        )
    {
        exchangeRateFeeder = _exchangeRateFeeder;

        _aUstToUstFeedDecimals = 1e18;

        uniV2Router = IUniswapV2Router01(_uniV2Router);

        ustToken.safeIncreaseAllowance(_uniV2Router, type(uint256).max);
        underlying.safeIncreaseAllowance(_uniV2Router, type(uint256).max);

        // No need to initialize chainlink feed, because they don't exist on testnet
        initialized = true;
    }

    /**
     * Swap Underlying to UST through uniswap V2
     *
     * @return swapped underlying amount
     */
    function _swapUnderlyingToUst() internal override returns (uint256) {
        uint256 underlyingBalance = _getUnderlyingBalance();
        require(underlyingBalance > 0, "NonUSTStrategy: no underlying exist");

        address[] memory path = new address[](2);
        path[0] = address(underlying);
        path[1] = address(ustToken);
        uniV2Router.swapExactTokensForTokens(
            underlyingBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        return underlyingBalance;
    }

    /**
     * Swap UST to Underlying through uniswap V2
     *
     * @return swapped underlying amount
     */
    function _swapUstToUnderlying() internal override returns (uint256) {
        uint256 ustBalance = _getUstBalance();
        if (ustBalance > 0) {
            address[] memory path = new address[](2);
            path[0] = address(ustToken);
            path[1] = address(underlying);
            uniV2Router.swapExactTokensForTokens(
                ustBalance,
                0,
                path,
                address(this),
                block.timestamp
            );
            return _getUnderlyingBalance();
        }

        return 0;
    }

    // get aUST/UST exchange rate from eth anchor ExchangeRateFeeder contract
    function _aUstExchangeRate() internal view override returns (uint256) {
        return exchangeRateFeeder.exchangeRateOf(address(ustToken), true);
    }

    /**
     * @return Underlying value of UST amount
     *
     * @notice This uses spot price on Uniswap V2, and this could lead an attack,
     * however, since this is for testnet version, it is fine.
     */
    function _estimateUstAmountInUnderlying(uint256 ustAmount)
        internal
        view
        override
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = address(ustToken);
        path[1] = address(underlying);

        uint256[] memory amountsOut = uniV2Router.getAmountsOut(
            ustAmount,
            path
        );
        return amountsOut[1];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        uint256 amount;
        ClaimParams[] claims;
        uint256 lockedUntil;
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
        uint256 claimerId,
        uint256 lockedUntil
    );

    event DepositBurned(uint256 indexed id, uint256 shares, address indexed to);

    event InvestPercentageUpdated(uint256 percentage);

    event Invested(uint256 amount);

    event StrategyUpdated(address indexed strategy);

    event YieldClaimed(
        uint256 claimerId,
        address indexed to,
        uint256 amount,
        uint256 burnedShares
    );

    //
    // Public API
    //

    /**
     * Update the invested amount;
     */
    function updateInvested() external;

    /**
     * Calculates underlying investable amount.
     *
     * @return the investable amount
     */
    function investableAmount() external view returns (uint256);

    /**
     * Update invest percentage
     *
     * Emits {InvestPercentageUpdated} event
     *
     * @param _investPct the new invest percentage
     */
    function setInvestPerc(uint16 _investPct) external;

    /**
     * Percentage of the total underlying to invest in the strategy
     */
    function investPerc() external view returns (uint256);

    /**
     * Underlying ERC20 token accepted by the vault
     */
    function underlying() external view returns (IERC20);

    /**
     * Minimum lock period for each deposit
     */
    function minLockPeriod() external view returns (uint256);

    /**
     * Total amount of underlying currently controlled by the
     * vault and the its strategy.
     */
    function totalUnderlyingWithSponsor() external view returns (uint256);

    /**
     * Computes the amount of yield available for an an address.
     *
     * @param _to address to consider.
     *
     * @return amount of yield for @param _to.
     */
    function yieldFor(address _to) external view returns (uint256);

    /**
     * Transfers all the yield generated for the caller to
     *
     * @param _to Address that will receive the yield.
     */
    function claimYield(address _to) external;

    /**
     * Creates a new deposit
     *
     * @param _params Deposit params
     */
    function deposit(DepositParams calldata _params) external;

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * It fails if the vault is underperforming and there are not enough funds
     * to withdraw the expected amount.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function withdraw(address _to, uint256[] memory _ids) external;

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * When the vault is underperforming it withdraws the funds with a loss.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function forceWithdraw(address _to, uint256[] memory _ids) external;

    /**
     * Changes the strategy used by the vault.
     *
     * @param _strategy the new strategy's address.
     */
    function setStrategy(address _strategy) external;
}