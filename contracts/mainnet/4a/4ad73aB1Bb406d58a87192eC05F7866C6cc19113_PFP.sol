/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)


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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)



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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)


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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)


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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)


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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)


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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)





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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)


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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/PFPConfig/IPFPConfig.sol


/// @title IPFPConfig
/// @author github.com/billyzhang663
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


interface IPFPConfig {
    function endowmentAddr() external returns(address);
    function foundationAddr() external returns(address);
    function roleManager() external returns(address);
}


// File contracts/PurposeToken.sol


/// @title PurposeToken Token (a utility token)
/// @author github.com/billyzhang663
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




contract PurposeToken is ERC20, AccessControl {
    /// @notice RBAC: accounts in this role are allowed to mint Purpose Tokens
    bytes32 public constant MINTER_ROLE = keccak256("PFP_MINTER_ROLE");
    /// @notice RBAC: accounts in this role are allowed to burn Purpose Tokens
    bytes32 public constant BURNER_ROLE = keccak256("PFP_BURNER_ROLE");
    IPFPConfig private pfpConfig;

    /**
     * @notice Emitted when Purpose tokens are minted
     * @param _addr address that owns tokens
     * @param _amount amount of tokens minted
     */
    event MintPurpose(address indexed _addr, uint256 _amount);
    /**
     * @notice Emitted when Purpose tokens are burned
     * @param _addr address that tokens we taken out of
     * @param _amount amount of tokens burned
     */
    event BurnPurpose(address indexed _addr, uint256 _amount);
    
    /**
     * @notice ERC20 utility token for PFP Protocol
     * @param _pfpConfigAddr address of pfp config contract
     */
    constructor(
        address _pfpConfigAddr
    ) ERC20("PURPOSE Token", "PURPOSE") {
        require(_pfpConfigAddr != address(0), "PurposeToken: zero address");

        pfpConfig = IPFPConfig(_pfpConfigAddr);

        // only roleManager will be able to grant/deny Minters
        _setupRole(DEFAULT_ADMIN_ROLE, pfpConfig.roleManager());
    }

    /**
     * @notice Function to burn Purpose tokens; used by protocol to manage token supply
     * @dev caller needs BURNER_ROLE
     * @param _addr address of account to burn from
     * @param _amount number of Purpose tokens to burn 
     */
    function burnPurpose(address _addr, uint256 _amount) 
        external 
        onlyRole(BURNER_ROLE)
        returns (bool) 
    {
        require(_amount <= balanceOf(_addr), "PurposeToken: not enough balance");

        _burn(_addr, _amount);
        
        emit BurnPurpose(_addr, _amount);
        return true;
    }

    /**
     * @notice Function to mint Purpose tokens
     * @dev caller needs MINTER_ROLE
     * @param _addr address of account to mint into
     * @param _amount number of Purpose tokens to mint 
     */
    function mintPurpose(address _addr, uint256 _amount)
      external
      onlyRole(MINTER_ROLE)
    {
        _mint(_addr, _amount);

        emit MintPurpose(_addr, _amount);
    }
}


// File contracts/libraries/ABDKMath64x64.sol

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 *
 * Copyright 2022 Google LLC.
 * Author: github.com/billyzhang663
 * 
 */

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }
  
  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }
}


// File contracts/libraries/BokkyPooBahsDateTimeLibrary.sol


// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
//
// Copyright 2022 Google LLC.
// Author: github.com/billyzhang663
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}


// File contracts/GenesisPurposeEscrow.sol


/// @title GenesisPurposeEscrow
/// @author github.com/billyzhang663
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */







contract GenesisPurposeEscrow is AccessControl {
    using SafeERC20 for PurposeToken;

    bytes32 public constant ADMIN_ROLE = keccak256("PFP_ADMIN_ROLE");
    bytes32 public constant STAKER_ROLE = keccak256("GENESIS_STAKER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("GENESIS_WITHDRAWER_ROLE");
    IPFPConfig public pfpConfig;    
    PurposeToken public purposeToken;

    uint64 private interestRate;   // with 8 decimals

    struct VestSchedule {
        // initial balance that contributor deposits into the contract
        uint256 initBalance;
        // total amount of contributor withdrawal
        uint256 withdrawnBalance;
        // total amount of reward that contributor received
        uint256 paidReward;
        // price of purpose at deposit time
        uint256 purposePrice;
        // whether or not vesting is accelerated
        bool isAccelerated;
        // deposit time in sec
        uint64 createdAt;
        // time in sec of the last withdrawal
        uint64 vestStartingDate;
        // interest rate at time of deposit
        uint64 interestRate;
        // symbol of erc20 token or ETH
        string depositTokenSymbol;
    }

    // vest schedule storage variables
    mapping(address => mapping(uint32 => VestSchedule)) public vestSchedules;
    mapping(address => uint32) public numVestSchedules;

    uint8[5] public withdrawablePercents = [
        10,
        25,
        50,
        75,
        100
    ];

    uint8[5] public vestingStepPercents = [
        10,
        15,
        25,
        25,
        25
    ];

    // event definitions
    
    /**
     * @notice Emitted when admin updates interest rate amount
     * @param _amount new interest amount with 8 decimals
     */
    event InterestRateUpdated(uint64 _amount);
    /**
     * @notice Emitted when staker deposits purpose token successfully
     * @param _addr staker's wallet address
     * @param _amount the staked amount of purpose token
     */
    event PurposeStaked(address indexed _addr, uint256 _amount);
    /**
     * @notice Emitted when staker withdraws purpose token successfully
     * @param _addr staker's wallet address
     * @param _amount the withdrawn amount of purpose token
     */
    event PurposeWithdrawn(address indexed _addr, uint256 _amount);
    /**
     * @notice Emitted when staker withdraws reward purpose token successfully
     * @param _addr staker's wallet address
     * @param _amount the claimed reward amount of purpose token
     */
    event PurposeRewardWithdrawn(address indexed _addr, uint256 _amount);

    /**
     * @dev Creates a GenesisPurposeEscrow contract.
     * @param _purposeTokenAddr address of purpose token contract
     * @param _pfpConfigAddr address of IPFPConfig contract
     */
    constructor(address _purposeTokenAddr, address _pfpConfigAddr) {
        require(_purposeTokenAddr != address(0), "Escrow: zero address");
        require(_pfpConfigAddr != address(0), "Escrow: zero address");

        purposeToken = PurposeToken(_purposeTokenAddr);
        pfpConfig = IPFPConfig(_pfpConfigAddr);
        interestRate = 0;

        // only roleManager will be able to grant/deny Admins, Stakers
        _setupRole(DEFAULT_ADMIN_ROLE, pfpConfig.roleManager());
    }

    /**
     * @dev Reverts if vesting schedule index is unavailable
     * @param _owner address of contributor
     * @param _index vesting schedule index
     */
    modifier isIndexAvailable(address _owner, uint32 _index) {
        require(
            numVestSchedules[_owner] > _index,
            "Escrow: Unavailable index"
        );
        _;
    }

    /**
     * @dev Reverts if vesting schedule is unavailable in 6 or 12 months
     * @param _owner address of contributor
     * @param _index vesting schedule index
     */
    modifier isWithdrawable(address _owner, uint32 _index) {
        VestSchedule memory vestSchedule = vestSchedules[_owner][_index];
        require(
            block.timestamp > vestSchedule.vestStartingDate,
            "Escrow: No withdrawable amount"
        );
        _;
    }

    /**
     * @notice Creates a new vesting schedule by staking purpose
     * @param _owner address of the contributor
     * @param _amount total amount of tokens to be released at the end of the vesting
     * @param _isAccelerated whether the vesting is accelerated or not
     * @param _purposePrice the price of purpose token when the staker deposits token 
     */
    function stakePurpose(address _owner, uint256 _amount, bool _isAccelerated, uint256 _purposePrice, string memory _symbol)
      external
      onlyRole(STAKER_ROLE)
    {
        require(_amount > 0, "Escrow: Purpose amount <= 0.");

        uint32 vestScheduleCount = numVestSchedules[_owner];
        uint64 createdAt = uint64(block.timestamp);
        VestSchedule storage vestSchedule = vestSchedules[_owner][vestScheduleCount];
        vestSchedule.initBalance = _amount;
        vestSchedule.createdAt = createdAt;
        vestSchedule.isAccelerated = _isAccelerated;
        vestSchedule.purposePrice = _purposePrice;
        vestSchedule.interestRate = interestRate;
        vestSchedule.depositTokenSymbol = _symbol;

        // The vest schedule will start after 6/12 months
        vestSchedule.vestStartingDate = uint64(_isAccelerated ? BokkyPooBahsDateTimeLibrary.addMonths(block.timestamp, 6) : BokkyPooBahsDateTimeLibrary.addMonths(block.timestamp, 12));

        numVestSchedules[_owner] = vestScheduleCount + 1;
        emit PurposeStaked(_owner, _amount);
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param _owner address of the contributor
     * @param _index vesting schedule index
     * @param _amount the amount to withdraw
     */
    function withdrawPurpose(address _owner, uint32 _index, uint256 _amount)
        external
        onlyRole(WITHDRAWER_ROLE)
        isIndexAvailable(_owner, _index)
        isWithdrawable(_owner, _index)
    {
        uint256 withdrawableAmount = calcWithdrawableAmount(_owner, _index, block.timestamp);
        VestSchedule storage vestSchedule = vestSchedules[_owner][_index];

        require(
            withdrawableAmount >= _amount,
            "Escrow: Insufficient amount"
        );

        // Update the total withdrawn balance
        vestSchedule.withdrawnBalance += _amount;

        // Transfer purpose to the contributor wallet address
        purposeToken.safeTransfer(_owner, _amount);
        emit PurposeWithdrawn(_owner, _amount);
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @dev Should be able to withdraw all purpose staked after 6/12 months. Withdraw should include rewards
     * @param _owner the contributor address
     * @param _index vesting schedule index
     */
    function withdrawPurposeAdmin(address _owner, uint32 _index)
        external
        onlyRole(ADMIN_ROLE)
        isIndexAvailable(_owner, _index)
        isWithdrawable(_owner, _index)
    {
        VestSchedule storage vestSchedule = vestSchedules[_owner][_index];
        uint256 amount = vestSchedule.initBalance - vestSchedule.withdrawnBalance;
        require(
             amount > 0,
            "Escrow: Insufficient amount"
        );

        //  Calculate remaining balance
        uint256 rewardBalance = calcAvailableReward(_owner, _index, block.timestamp);
        
        // Update the total withdrawn balance
        vestSchedule.withdrawnBalance = vestSchedule.initBalance;

        // Transfer staked purpose + rewards to the contributor wallet address
        if (rewardBalance > 0) {
            purposeToken.mintPurpose(address(this), rewardBalance);
        }
        purposeToken.safeTransfer(_owner, amount + rewardBalance);
        
        emit PurposeWithdrawn(_owner, amount + rewardBalance);
    }

    /**
     * @dev Claims reward if possible
     * @param _owner the contributor address
     * @param _index vesting schedule index
     * @param _amount claim reward amount
     */
    function claimReward(address _owner, uint32 _index, uint256 _amount)
        external
        onlyRole(WITHDRAWER_ROLE)
        isIndexAvailable(_owner, _index)
        isWithdrawable(_owner, _index)
    {
        uint256 rewardBalance = calcAvailableReward(_owner, _index, block.timestamp);
        VestSchedule storage vestSchedule = vestSchedules[_owner][_index];

        require(rewardBalance >= _amount, "Escrow: No available reward");

        vestSchedule.paidReward += _amount;

        // Mint purpose to the contributor wallet address
        purposeToken.mintPurpose(_owner, _amount);
        emit PurposeRewardWithdrawn(_owner, _amount);
    }

    /**
     * @notice Updates interest rate for APY
     * @dev caller needs ADMIN_ROLE
     * @dev max interest rate = 100%
     * @param _interestRate new interest rate to use (use 8 decimals)
     */
    function updateInterestRate(uint64 _interestRate)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(interestRate != _interestRate, "Escrow: new value equals current");
        require(_interestRate <= 10000000000, "Escrow: max 100% interest");

        interestRate = _interestRate;
        emit InterestRateUpdated(_interestRate);
    }

    /**
     * @dev Calculates the amount of Purpose that's withdrawable.
     * @return withdrawableAmount available amount
     * @param _owner address of contributor
     * @param _index vesting schedule index
     * @param _timestamp time at which to calculate for
     */
    function calcWithdrawableAmount(address _owner, uint32 _index, uint _timestamp)
        public
        view
        isIndexAvailable(_owner, _index)
        returns (uint256 withdrawableAmount)
    {
        VestSchedule memory vestSchedule = vestSchedules[_owner][_index];
        if (vestSchedule.vestStartingDate > _timestamp) {
          withdrawableAmount = 0;
        }
        else {
          uint256 amount = vestSchedule.initBalance;
        
          // The withdrawable percent will change every 6 months. 
          uint256 halfYearOffset = BokkyPooBahsDateTimeLibrary.diffMonths(vestSchedule.vestStartingDate, _timestamp) / 6;
        
          // Withdrawable percent will always be 100% after vestingScheduleStartingDate + 5 * 6 months
          // So it should be 0 <= WithdrawStepIndex < 5
          uint256 withdrawStepIndex = (halfYearOffset > 4 ? 4 : halfYearOffset);
          uint256 withdrawablePercent = withdrawablePercents[withdrawStepIndex];
          uint256 vestedAmount = (amount * withdrawablePercent) / 100;

          // The previously withdrawn amount should be deducted
          withdrawableAmount = vestSchedule.withdrawnBalance > vestedAmount ? 0 : vestedAmount - vestSchedule.withdrawnBalance;
        }
    }

    /**
     * @dev Returns available reward
     * @return rewardBalance total reward value
     * @param _index vesting schedule index
     * @param _timestamp time at which to calculate for
     */
    function calcAvailableReward(address _owner, uint32 _index, uint _timestamp)
        public
        view
        isIndexAvailable(_owner, _index)
        returns (uint256 rewardBalance)
    {
        VestSchedule storage vestSchedule = vestSchedules[_owner][_index];
        if (vestSchedule.vestStartingDate > _timestamp) {
          rewardBalance = 0;
        }
        else {
          // The previously paid reward amount should be deducted
          uint256 totalReward = calcTotalReward(_owner, _index, _timestamp);
          if(vestSchedule.paidReward > totalReward) {
            rewardBalance = 0;
          }
          else {
            rewardBalance = totalReward - vestSchedule.paidReward; 
          }
        }
    }

    /**
     * @dev Calculates and returns total available reward
     * @return rewardBalance total reward value
     * @param _owner address of contributor
     * @param _index vesting schedule index
     */
    function calcTotalReward(address _owner, uint32 _index, uint _timestamp)
        public
        view
        isIndexAvailable(_owner, _index)
        returns (uint256)
    {
        VestSchedule memory vestSchedule = vestSchedules[_owner][_index];

        if (_timestamp < vestSchedule.vestStartingDate) {
            // Available Reward = Initial Amount * (1 + InterestRate / 365) ** days
            // InterstRate is percent value
            // To use the fixed float of interest rate, it times 1e8
            // So it should be devided by 1e8 * 1e2 = 1e10
            uint256 availableDays = BokkyPooBahsDateTimeLibrary.diffDays(vestSchedule.createdAt, _timestamp);
            uint256 availableReward = ABDKMath64x64.mulu(
                                        ABDKMath64x64.pow(
                                            ABDKMath64x64.add(
                                                ABDKMath64x64.fromUInt(1),
                                                ABDKMath64x64.divu(vestSchedule.interestRate, 365 * 1e10)
                                            ),
                                            availableDays
                                        ),
                                        vestSchedule.initBalance
                                    );
            return availableReward - vestSchedule.initBalance;
        } else {
            uint256 diffMonthsToStartingDate = (vestSchedule.isAccelerated?6:12);
            // The maximum vest schedule steps is 5
            uint256 vestScheduleSteps = (BokkyPooBahsDateTimeLibrary.diffMonths(vestSchedule.createdAt, _timestamp) - diffMonthsToStartingDate) / 6 + 1;
            vestScheduleSteps = (vestScheduleSteps > 5?5:vestScheduleSteps);
            
            uint256 stepIndex = 0;
            uint256 stepLastTime = vestSchedule.vestStartingDate;
            uint256 sumReward = 0;
            uint256 sumStepAmount = 0;
            uint256 remainingPercent = 100;

            while (stepIndex < vestScheduleSteps) {
                uint256 stepPercent = (stepIndex==vestScheduleSteps?remainingPercent:vestingStepPercents[stepIndex]);
                uint256 stepAmount = vestSchedule.initBalance * stepPercent / 100;
                uint256 stepReward = ABDKMath64x64.mulu(
                                            ABDKMath64x64.pow(
                                                ABDKMath64x64.add(
                                                    ABDKMath64x64.fromUInt(1),
                                                    ABDKMath64x64.divu(vestSchedule.interestRate, 365 * 1e10)
                                                ),
                                                BokkyPooBahsDateTimeLibrary.diffDays(vestSchedule.createdAt, stepLastTime)
                                            ),
                                            stepAmount
                                    );
                sumReward += stepReward;
                sumStepAmount += stepAmount;

                remainingPercent -= vestingStepPercents[stepIndex];
                stepIndex++;
                if (BokkyPooBahsDateTimeLibrary.addMonths(stepLastTime, 6) > _timestamp) {
                    stepLastTime = _timestamp;
                } else {
                    stepLastTime = BokkyPooBahsDateTimeLibrary.addMonths(stepLastTime, 6);
                }
            }
            return sumReward - sumStepAmount;
        }
    }

    /**
     * @dev get the list of staker's vest schedules
     * @param _addr staker address
     */
    function getVestSchedules(address _addr)
        external
        view
        returns (VestSchedule[] memory, uint32) 
    {
        require(numVestSchedules[_addr] > 0, "Escrow: Address not found");

        uint32 count = numVestSchedules[_addr];
        VestSchedule[] memory schedules = new VestSchedule[](count);

        for (uint32 i = 0; i < count; i++) {
            schedules[i] = vestSchedules[_addr][i];
        }

        return (schedules, count);
    }
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)


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


// File contracts/PFPAdmin.sol


/// @title PFPAdmin
/// @author github.com/billyzhang663
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */






contract PFPAdmin is AccessControl, Pausable {
    /// @notice RBAC: accounts in this role are allowed to perform PFP Admin functions
    bytes32 public constant ADMIN_ROLE = keccak256("PFP_ADMIN_ROLE");
    /// @notice RBAC: accounts in this role are allowed to perform PFP Break Glass functions
    bytes32 public constant BREAK_GLASS_ROLE = keccak256("PFP_BREAK_GLASS_ROLE");

    mapping(address => bool) private allowedCoinList;
    uint256 internal minimumDepositInUsdNoDecimals;
    bool internal acceleratedVestAllowed;

    /**
     * @notice Emitted when admin adds a new allowed stablecoin
     * @param _coinAddr address of erc20 token/coin added
     */
    event AllowedCoinAdded(address indexed _coinAddr);
    /**
     * @notice Emitted when admin removes stablecoin from allowlist
     * @param _coinAddr address of erc20 token/coin removed
     */
    event AllowedCoinRemoved(address indexed _coinAddr);
    /**
     * @notice Emitted when admin updates minimum deposit amount
     * @param _amount new min deposit amount in USD (no decimals)
     */
    event MinimumDepositUpdated(uint256 _amount);
    /**
     * @notice Emitted when admin updates whether accelerated vest schedules are allowed
     * @param _allowed true to allow accelerated vesting, false to disallow
     */
    event AcceleratedVestAllowedUpdated(bool _allowed);

    /**
     * @notice Inherited by PFP; Used to house privileged admin functions
     * @param _pfpConfigAddr address of pfp config contract
     */
    constructor(address _pfpConfigAddr) {
        require(_pfpConfigAddr != address(0), "PFPAdmin: zero address");

        IPFPConfig pfpConfig = IPFPConfig(_pfpConfigAddr);

        // only roleManager will be able to grant/deny Admins
        _setupRole(DEFAULT_ADMIN_ROLE, pfpConfig.roleManager());

        minimumDepositInUsdNoDecimals = 5;
        acceleratedVestAllowed = false;
    }

    modifier isValidCoin(address _addr) {
        require(allowedCoinList[_addr], "PFPAdmin: invalid coin");
        _;
    }

    modifier isNotZeroAddr(address _addr) {
        require(_addr != address(0), "PFPAdmin: zero address");
        _;
    }

    /**
     * @notice Add USD-based stablecoin to allowlist
     * @dev caller needs ADMIN_ROLE
     * @param _coinAddr address of erc20 token/coin to add
     */
    function addCoinAddr(address _coinAddr)
        external
        onlyRole(ADMIN_ROLE)
        isNotZeroAddr(_coinAddr)
    {
        require(!allowedCoinList[_coinAddr], "PFPAdmin: coin addr registered");

        allowedCoinList[_coinAddr] = true;

        emit AllowedCoinAdded(_coinAddr);
    }

    /**
     * @notice Remove USD-based stablecoin from allowlist
     * @dev caller needs ADMIN_ROLE
     * @param _coinAddr address of erc20 token/coin to remove
     */
    function removeCoinAddr(address _coinAddr)
        external
        onlyRole(ADMIN_ROLE)
        isValidCoin(_coinAddr)
    {
        allowedCoinList[_coinAddr] = false;

        emit AllowedCoinRemoved(_coinAddr);
    }

    /**
     * @notice Update minimum deposit allowed (in USD)
     * @dev caller needs ADMIN_ROLE
     * @param _amountInUsd in usd with no decimals
     */
    function updateMinimumDeposit(uint256 _amountInUsd)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(minimumDepositInUsdNoDecimals != _amountInUsd, "PFPAdmin: value equals current");

        minimumDepositInUsdNoDecimals = _amountInUsd;
        emit MinimumDepositUpdated(_amountInUsd);
    }

    /**
     * @notice Update whether accelerated vest schedules are allowed or not
     * @dev caller needs ADMIN_ROLE
     * @param _allowed true to allow accelerated vesting, false to disallow
     */
    function updateAcceleratedVestAllowed(bool _allowed)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(acceleratedVestAllowed != _allowed, "PFPAdmin: value equals current");

        acceleratedVestAllowed = _allowed;
        emit AcceleratedVestAllowedUpdated(_allowed);
    }

    /**
     * @notice Pause deposit and withdrawal methods
     * @dev caller needs BREAK_GLASS_ROLE
     */
    function pauseProtocol()
        external
        onlyRole(BREAK_GLASS_ROLE)
    {
        _pause();
    }

    /**
     * @notice Unpause protocol, deposit and withdrawals are available
     * @dev caller needs ADMIN_ROLE
     */
    function unpauseProtocol()
        external
        onlyRole(ADMIN_ROLE)
    {
        _unpause();
    }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


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


// File contracts/PriceConsumerV3.sol


/// @title The PriceConsumerV3 contract
/// @notice A wrapper contract for Chainlink Price Feeds
/// @author github.com/valynislives
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


contract PriceConsumerV3 {
    AggregatorV3Interface internal immutable priceFeed;

    /**
     * @notice Wrapper for Chainlink price feeds
     * @param _priceFeed Price feed address
     */
    constructor(address _priceFeed) {
        require(_priceFeed != address(0), "PriceConsumerV3: zero address");

        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice Returns the latest price
     */
    function getLatestPrice()
        external
        view
        returns (uint256)
    {
        (
            /* uint80 roundID */,
            int256 price,
            /* uint256 startedAt */,
            /* uint256 timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();

        require(price > 0, "PriceConsumerV3: price <= 0");
        return uint256(price);
    }

    /**
     * @notice Returns the Price feed address
     */
    function getPriceFeed()
        external
        view 
        returns (AggregatorV3Interface)
    {
        return priceFeed;
    }
}


// File contracts/PFP.sol


/// @title PFP
/// @author github.com/billyzhang663
/// @author github.com/garthbrydon
/// @author github.com/valynislives
/// @author github.com/jpetrich

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */









contract PFP is PFPAdmin {
    using SafeERC20 for IERC20;

    PurposeToken public purposeToken;
    GenesisPurposeEscrow public genesisPurposeEscrow;
    IPFPConfig public pfpConfig;
    PriceConsumerV3 public ethUsdPriceConsumer;

    /// @notice Total contributions made to Endowment Fund (in USD with 6 decimals)
    uint256 public totalEndowmentContributionsInUsd;

    struct AccountState {
        // total Purpose staked in protocol
        uint256 purposeStaked;
        // total Purpose held in account (unstaked)
        uint256 purposeHeld;
        // total Rewards held in account (claimed)
        uint256 rewardsPaid;
        // array of staking transactions made
        AccountTransaction[] transactions;
    }

    struct AccountTransaction {
        // copy of vest schedule created when first staked
        GenesisPurposeEscrow.VestSchedule schedule;
        // reward at current point in time
        uint256 currentReward;
        // purpose withdrawable at current point in time
        uint256 currentAmount;
        // array of tranches that will vest after staking period
        TransactionTranche[] tranches;
    }

    struct TransactionTranche {
        // tranche date
        uint64 dateAvailable;
        // amount of Purpose available
        uint256 amountAvailable;
        // amount of Purpose Rewards available
        uint256 rewardAvailable;
    }

    /**
     * @notice Emitted when staker deposits Ether successfully
     * @param _addr staker's wallet address
     * @param _endowmentAddr the endowment address
     * @param _foundationAddr the foundation address
     * @param _amount the staked amount of ETH
     */
    event EthDepositReceived(address indexed _addr, address indexed _endowmentAddr, address indexed _foundationAddr, uint256 _amount);
    /**
     * @notice Emitted when staker deposits other coin successfully
     * @param _addr staker's wallet address
     * @param _coinAddr the coin address
     * @param _endowmentAddr the endowment address
     * @param _foundationAddr the foundation address
     * @param _amount the staked amount of coin
     */
    event CoinDepositReceived(address indexed _addr, address _coinAddr, address indexed _endowmentAddr, address indexed _foundationAddr, uint256 _amount);
    /**
     * @notice Emitted when total endowment contributions in usd increases
     * @param _addr staker's wallet address
     * @param _endowmentAddr the endowment address
     * @param _totalEndowment the total amount of endowment contributions in usd
     * @param _amount the increased amount of endowment contributions in usd
     * @param _purposePrice the price of purpose token
     */
    event EndowmentIncreased(address indexed _addr, address indexed _endowmentAddr, uint256 _totalEndowment, uint256 _amount, uint256 _purposePrice);

    /**
     * @dev Creates a PFP contract.
     * @param _purposeTokenAddr address of purpose token contract
     * @param _genesisPurposeEscrowAddr address of GenesisPurposeEscrow contract
     * @param _pfpConfigAddr address of IPFPConfig contract
     * @param _ethUsdPriceFeed address of PriceConsumerV3 contract
     */
    constructor(
        address _purposeTokenAddr,
        address _genesisPurposeEscrowAddr,
        address _pfpConfigAddr,
        address _ethUsdPriceFeed
    ) PFPAdmin(_pfpConfigAddr) {
        require(_purposeTokenAddr != address(0), "PFP: zero address");
        require(_genesisPurposeEscrowAddr != address(0), "PFP: zero address");
        require(_ethUsdPriceFeed != address(0), "PFP: zero address");
        
        purposeToken = PurposeToken(_purposeTokenAddr);
        genesisPurposeEscrow = GenesisPurposeEscrow(_genesisPurposeEscrowAddr);
        pfpConfig = IPFPConfig(_pfpConfigAddr);
        ethUsdPriceConsumer = PriceConsumerV3(_ethUsdPriceFeed);
        totalEndowmentContributionsInUsd = 0;
    }

    /**
     * @notice Deposit eth and mint purpose
     * @param _isAccelerated use accelerated vest schedule
     * @param _minPurposeReceived min Purpose that should be received; prevents minting unexpectedly lower purpose amount  
     */
    function depositEth(bool _isAccelerated, uint256 _minPurposeReceived)
        external
        payable
        whenNotPaused
    {
        uint256 ethUsdPrice = ethUsdPriceConsumer.getLatestPrice();
        require(validEthDepositAmount(msg.value, ethUsdPrice, minimumDepositInUsdNoDecimals), "PFP: Deposit value too low");

        address endowmentAddr = pfpConfig.endowmentAddr();
        address foundationAddr = pfpConfig.foundationAddr();
        uint256 purposePrice = getPurposePrice();
        uint256 endowmentAmount = msg.value * 85 / 100;
        // wei => ether, keep 6 decimals of ethUsdprice 
        uint256 amountInUsd = msg.value * ethUsdPrice / 1e20; 
        uint256 endowmentAmountInUsd = endowmentAmount * ethUsdPrice / 1e20; 

        // update total endowment contributions
        totalEndowmentContributionsInUsd += endowmentAmountInUsd;
        emit EndowmentIncreased(msg.sender, endowmentAddr, totalEndowmentContributionsInUsd, endowmentAmountInUsd, purposePrice);

        // transfer to funds
        (bool successEndowment, ) = payable(endowmentAddr).call{value: endowmentAmount}("");
        require(successEndowment, "PFP: Endowment transfer failed");
        (bool successFoundation, ) = payable(foundationAddr).call{value: msg.value - endowmentAmount}("");
        require(successFoundation, "PFP: Foundation transfer failed");
        emit EthDepositReceived(msg.sender, endowmentAddr, foundationAddr, msg.value);

        // mint and stake
        uint256 tokenAmountToMint = calculateTokensToMint(purposePrice, amountInUsd);
        require(tokenAmountToMint > 0, "PFP: Token amount <= 0.");
        require(tokenAmountToMint >= _minPurposeReceived, "PFP: Token amount < min.");
        purposeToken.mintPurpose(address(genesisPurposeEscrow), tokenAmountToMint);
        genesisPurposeEscrow.stakePurpose(
          msg.sender,
          tokenAmountToMint,
          acceleratedVestAllowed ? _isAccelerated : false,
          purposePrice,
          "ETH");
    }

    /**
     * @notice Deposit USD based erc20 stablecoin
     * @param _coinAddr address of allowlisted stablecoin
     * @param _amount amount to deposit and mint Purpose from
     * @param _isAccelerated use accelerated vest schedule
     * @param _minPurposeReceived min Purpose that should be received; prevents minting unexpectedly lower purpose amount  
     */
    function deposit(address _coinAddr, uint256 _amount, bool _isAccelerated, uint256 _minPurposeReceived)
        external
        isValidCoin(_coinAddr)
        whenNotPaused
    {
        uint decimals = ERC20(_coinAddr).decimals();
        string memory symbol = ERC20(_coinAddr).symbol();

        // We assume that the ERC20 coin is a dollar-based stablecoin. Violating this assumption will require new logic.
        require(_amount >= minimumDepositInUsdNoDecimals * 10**decimals, "PFP: Deposit value too low");
        
        uint256 endowmentAmount = _amount * 85 / 100;
        uint256 purposePrice = getPurposePrice();
        // keep 6 decimals of erc20 token
        uint256 amountInUsd = _amount / 10**(decimals - 6);
        uint256 endowmentAmountInUsd = endowmentAmount / 10**(decimals - 6); 

        // update total endowment contributions
        totalEndowmentContributionsInUsd += endowmentAmountInUsd;
        emit EndowmentIncreased(msg.sender, pfpConfig.endowmentAddr(), totalEndowmentContributionsInUsd, endowmentAmountInUsd, purposePrice);

        // transfer to funds
        IERC20(_coinAddr).safeTransferFrom(msg.sender, pfpConfig.endowmentAddr(), endowmentAmount);
        IERC20(_coinAddr).safeTransferFrom(msg.sender, pfpConfig.foundationAddr(), _amount - endowmentAmount);
        emit CoinDepositReceived(msg.sender, _coinAddr, pfpConfig.endowmentAddr(), pfpConfig.foundationAddr(), _amount);

        // mint and stake
        uint256 tokenAmountToMint = calculateTokensToMint(purposePrice, amountInUsd);
        require(tokenAmountToMint > 0, "PFP: Token amount <= 0.");
        require(tokenAmountToMint >= _minPurposeReceived, "PFP: Token amount < min.");
        purposeToken.mintPurpose(address(genesisPurposeEscrow), tokenAmountToMint);
        genesisPurposeEscrow.stakePurpose(
          msg.sender,
          tokenAmountToMint,
          acceleratedVestAllowed ? _isAccelerated : false,
          purposePrice,
          symbol);
    }

    /**
     * @notice Withdraws all available Purpose and any rewards
     * @param _index vesting schedule index
     */
    function withdrawGenesisPurpose(uint32 _index)
        external
        whenNotPaused
    {
      uint256 withdrawableAmount = genesisPurposeEscrow.calcWithdrawableAmount(msg.sender, _index, block.timestamp);
      if(withdrawableAmount > 0) {
          genesisPurposeEscrow.withdrawPurpose(msg.sender, _index, withdrawableAmount);
      }

      uint256 rewardsAmount = genesisPurposeEscrow.calcAvailableReward(msg.sender, _index, block.timestamp);
      if(rewardsAmount > 0) {
          genesisPurposeEscrow.claimReward(msg.sender, _index, rewardsAmount);
      }
    }


    /**
     * @notice Returns current price of Purpose in US dollars with 6 decimals.
     * @dev During bonding curve phase: every $1M contributed increases price by $0.01
     * @dev Price equation represented by line: y = (10^-8)x + (10^4), where x is total endowment contributions (with 6 decimals for x,y)
     * @return purposePrice current purpose price 
     */
    function getPurposePrice()
        public
        view
        returns (uint256 purposePrice)
    {
        // present price equation as y = mx+c with y as price ($) and x as endowment ($M)
        //    2 points on line: ($2M, $0.03) and ($1M, $0.02); y intercept at $0.01
        //    add 6 decimals to price and endowment
        //      m = (0.03*10^6 - 0.02*10^6) / (2M*10^6 - 1M*10^6) = 10^4 / 10^12 = 1/10^8;
        //      c = 0.01^10^6;
        //      y = x/10^8 + 10^4
        //    and multiply terms with denominator to perform division last
        //      y = (x + 10^12) / 10^8;
        purposePrice = (totalEndowmentContributionsInUsd + 1e12)/1e8;
    }

    /**
     * @notice Calculates tokens to mint based on Purpose price and deposit amount
     * @param _purposePrice purpose price in US Dollars with 6 decimals
     * @param _depositAmountUSD purpose price in US Dollars with 6 decimals
     * @return tokensToMint num tokens to mint (with token's 18 decimals)
     */
    function calculateTokensToMint(uint256 _purposePrice, uint256 _depositAmountUSD)
        public
        pure
       returns (uint256 tokensToMint)
    {
        require(_purposePrice > 0, "PFP: price <= 0");
        tokensToMint = _depositAmountUSD * 1e18 / _purposePrice;
    }

    /**
     * @notice Returns contributor account details
     * @param _owner address of the contributor
     */
    function getAccountDetails(address _owner) 
        external
        view
        returns (AccountState memory)
    {
        (GenesisPurposeEscrow.VestSchedule[] memory schedules, uint32 count) = genesisPurposeEscrow.getVestSchedules(_owner);
        AccountState memory accountState;
        accountState.transactions = new AccountTransaction[](count);

        uint256 totalPurposeInEscrow = 0;
        uint256 totalRewardsPaid = 0;
        for (uint32 i = 0; i < count; i++) {
            AccountTransaction memory transaction;
            
            transaction.currentReward = genesisPurposeEscrow.calcTotalReward(_owner, i, block.timestamp);
            transaction.currentAmount = genesisPurposeEscrow.calcWithdrawableAmount(_owner, i, block.timestamp);

            // tally purpose still in escrow
            uint256 initialPurposeStaked = schedules[i].initBalance;
            totalPurposeInEscrow += initialPurposeStaked - schedules[i].withdrawnBalance;
            totalRewardsPaid += schedules[i].paidReward;

            // vest schedule and tranches
            transaction.schedule = schedules[i];
            transaction.tranches = new TransactionTranche[](5);
            uint64 trancheDate = schedules[i].vestStartingDate;
            for (uint32 j = 0; j < 5; j++) {
                TransactionTranche memory tranche;
                tranche.dateAvailable = trancheDate;
                tranche.amountAvailable = genesisPurposeEscrow.calcWithdrawableAmount(_owner, i, trancheDate);
                tranche.rewardAvailable = genesisPurposeEscrow.calcAvailableReward(_owner, i, trancheDate);
                transaction.tranches[j] = tranche;

                trancheDate = uint64(BokkyPooBahsDateTimeLibrary.addMonths(trancheDate, 6));
            }

            accountState.transactions[i] = transaction;
        }

        accountState.purposeHeld = purposeToken.balanceOf(_owner);
        accountState.purposeStaked = totalPurposeInEscrow;
        accountState.rewardsPaid = totalRewardsPaid;

        return accountState;
    }

    function validEthDepositAmount(uint256 _depositValue, uint256 _ethUsdPrice, uint256 _minimumDepositInUsdNoDecimals)
        private
        pure
        returns (bool)
    {
        // 1 ether * 1e8 / ethUsdPrice is equal to 1USD in wei.
	      // Therefore, multiplying it by minimumDepositInUsd gives us the minimum deposit amount in wei.
        return _depositValue >= _minimumDepositInUsdNoDecimals * 1 ether * 1e8 / _ethUsdPrice;
    }
}


// File contracts/PFPConfig/DevPFPConfig.sol


/// @title DevPFPConfig
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


contract DevPFPConfig is IPFPConfig {
    /* solhint-disable const-name-snakecase */
    address override public constant endowmentAddr = 0x4Ef5ab360E1A04ef73C7A2309a605e5caf4BEEcb;
    address override public constant foundationAddr = 0xbc1ddCaC1555224Ee4F141e140ea7AeB58793eF8;
    address override public constant roleManager = 0xAF8285f1b52BfaC89569673A5bC0239CAd88a64F;
    /* solhint-enable const-name-snakecase */
}


// File contracts/PFPConfig/ProdPFPConfig.sol


/// @title ProdPFPConfig
/// @author github.com/billyzhang663
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


contract ProdPFPConfig is IPFPConfig {
    /* solhint-disable const-name-snakecase */
    address override public constant endowmentAddr = 0x354961ecDa3f3b0191fdA48fc90FFb908Db1005d;
    address override public constant foundationAddr = 0x278C8BF12Ab81e1dAC2D771795EB29c66B1b7583;
    address override public constant roleManager = 0xbfbF1dDd4344d85f7D76DE810b4bc69bAe915cC9;
    /* solhint-enable const-name-snakecase */
}


// File contracts/PFPConfig/TestPFPConfig.sol


/// @title TestPFPConfig
/// @author github.com/billyzhang663
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


contract TestPFPConfig is IPFPConfig {
    /* solhint-disable const-name-snakecase */
    address override public constant endowmentAddr = 0xe066D5954A4411E89424dc9Cb73A3Cf2EA2A52B4;
    address override public constant foundationAddr = 0x1e6F4d29eb238af88e68b49CC57719B4AE9379A6;
    address override public constant roleManager = 0x60e31607883D8aE6c108C8e3BEe644C03324472A;
    /* solhint-enable const-name-snakecase */
}


// File contracts/test/MockERC20.sol


/// @title MockERC20
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


contract MockERC20 is ERC20 {
    uint8 private immutable mockDecimals;

    constructor(string memory _name, string memory _symbol,
      uint256 _initialSupply, uint8 _decimals) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply * 10**_decimals);
        mockDecimals = _decimals;
    }

    function decimals() public view override returns (uint8) {
		    return mockDecimals;
	  }
}


// File contracts/test/MockPFPConfig.sol


/// @title MockPFPConfig
/// @author Alexander Remie, Trail of Bits
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


contract MockPFPConfig {
    address public immutable endowmentAddr;
    address public immutable foundationAddr;
    address public immutable roleManager;

    constructor(address _acc) {
        endowmentAddr = 0x549451Db725F91eF47B5f2c365c02980329f1d99;
        foundationAddr = 0x4b187da1d5e1c3cd2b137a094aF89262C0756836;
        roleManager = _acc;
    }
}


// File contracts/test/fuzzing/TestGenesisPurposeEscrow.sol


/// @title Echidna tests for withdrawing and claiming of rewards
/// @author Vara Prasad Bandaru, Trail of Bits
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */






interface HEVMCheatCodes {
    function warp(uint256 x) external;
}

contract EchidnaGenesisPurposeEscrow {
    MockPFPConfig config;
    PurposeToken purpose;
    GenesisPurposeEscrow genesis;
    HEVMCheatCodes hevmCheatCodes;

    // Information about each testcase
    struct StakingInformation {
        uint8 numberOfTermsWithdrawn; // equal to 1 -> 10% has been withdrawn, = 2 -> 10% + 15% has been withdrawn
        bool claimedReward; // total reward has been claimed
        bool isAccelerated; // vest is accelerated
        uint256 depositedAmount; // initial amount deposited
        uint256 totalWithdrawnAmount; // amount withdrawn for this vest
        uint256 timestamp; // unscaled block.timestamp -> vest creation time
        uint32 indexInGenesisVestSchedules; // index of vest schedule in GenesisPurposeEscrow
    }

    // testcases
    mapping(address => StakingInformation[]) testVests;
    // store whether a address has been passed as argument to stakePurpose i.e there are vest schedules for these address.
    // created on the assumption -> it guides echidna to pass addresses for owner that are passed to stakePurpose.
    mapping(address => bool) ownerStaked;
    mapping(address => uint32) ownerStakingIndices;
    // withdraws percentage for each terms
    uint8[5] withdrawablePercentsByTerm = [10, 15, 25, 25, 25];
    uint256 private constant TOTAL_NUMBER_OF_TERMS = 5;
    int128 rewardPercentageAccelerated = ABDKMath64x64.divu(95, 10); // 9.5%
    int128 rewardPercentageUnaccelerated = ABDKMath64x64.divu(199, 10); // 19.9%

    // event InfoEvent(uint, uint, uint);
    // event PercentageEvent(int128, int128);
    constructor() {
        config = new MockPFPConfig(address(this));
        purpose = new PurposeToken(address(config));
        genesis = new GenesisPurposeEscrow(address(purpose), address(config));
        hevmCheatCodes = HEVMCheatCodes(
            address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D)
        );
        purpose.grantRole(purpose.MINTER_ROLE(), address(this));
        purpose.grantRole(purpose.BURNER_ROLE(), address(this));
        purpose.grantRole(purpose.MINTER_ROLE(), address(genesis));
        purpose.grantRole(purpose.BURNER_ROLE(), address(genesis));
        genesis.grantRole(genesis.STAKER_ROLE(), address(this));
        genesis.grantRole(genesis.WITHDRAWER_ROLE(), address(this));
        genesis.grantRole(genesis.ADMIN_ROLE(), address(this));
    }

    function removeTestCaseAtIndex(
        StakingInformation[] storage _ownerTestCases,
        uint256 _index
    ) private {
        _ownerTestCases[_index] = _ownerTestCases[_ownerTestCases.length - 1];
        _ownerTestCases.pop();
    }

    function moveTimestamp(uint256 _depositTimestamp, uint256 _termsToMove)
        private
    {
        // Each term is 6 months. moveTimestamp updates timestamp to _depositTimestamp + _terms * (6 months).
        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(
            _depositTimestamp,
            _termsToMove * 6
        );
        newTimestamp += 3600; // adds a day
        hevmCheatCodes.warp(newTimestamp);
    }

    function checkPercentage(
        uint256 amount,
        uint256 totalAmount,
        int128 percentage
    ) private returns (bool) {
        // verify that amount is greater than percentage % of totalAmount
        // => (amount * 100)/totalAmount > percentage
        int128 amountPercentage = ABDKMath64x64.divu(amount * 100, totalAmount);

        assert(amountPercentage >= percentage);
        return true;
    }

    function stakePurpose(
        address _owner,
        uint72 _amount,
        bool _isAccelerated
    ) public {
        require(_owner != address(0x0));
        require(_amount > type(uint32).max);
        require(_owner != address(genesis));
        StakingInformation memory info;
        info.numberOfTermsWithdrawn = 0;
        info.claimedReward = false;
        info.isAccelerated = _isAccelerated;
        info.depositedAmount = _amount;
        info.totalWithdrawnAmount = 0;
        info.timestamp = block.timestamp;
        info.indexInGenesisVestSchedules = ownerStakingIndices[_owner];
        testVests[_owner].push(info);
        ownerStakingIndices[_owner] += 1;
        if (!ownerStaked[_owner]) {
            ownerStaked[_owner] = true;
        }
        purpose.mintPurpose(address(genesis), _amount);
        genesis.stakePurpose(_owner, _amount, _isAccelerated, 1, "ETH");
    }

    function claimAndVerifyRewards(address _owner, uint32 _index) private {
        StakingInformation storage info = testVests[_owner][_index];
        // check availableReward > expected percentage of total deposit
        uint256 availableReward = genesis.calcAvailableReward(
            _owner,
            info.indexInGenesisVestSchedules,
            block.timestamp
        );
        int128 rewardPercentage = info.isAccelerated
            ? rewardPercentageAccelerated
            : rewardPercentageUnaccelerated;
        uint256 totalAmount = info.depositedAmount;
        uint256 purposeBalBefore = purpose.balanceOf(_owner);
        genesis.claimReward(
            _owner,
            info.indexInGenesisVestSchedules,
            availableReward
        );
        uint256 purposeBalAfter = purpose.balanceOf(_owner);
        assert(purposeBalAfter - purposeBalBefore == availableReward);
        info.claimedReward = true;
        info.totalWithdrawnAmount += availableReward;
    }

    // withdraw amount for **_terms** new terms.
    // e.g if 10% + 15% + 25% has been withdraw for a vest and _terms = 2,
    // then info.numberOfTermsWithdrawn == 3 and tries to withdraw amount for last two terms(4th and 5th).
    function testWithdrawPurpose(
        address _owner,
        uint32 _index,
        uint8 _terms
    ) public {
        require(ownerStaked[_owner]);
        require(testVests[_owner].length > 0);
        require(0 < _terms && _terms <= TOTAL_NUMBER_OF_TERMS);
        _index = uint32(_index % testVests[_owner].length);
        StakingInformation storage info = testVests[_owner][_index];
        if (info.numberOfTermsWithdrawn + _terms > TOTAL_NUMBER_OF_TERMS) {
            _terms = uint8(TOTAL_NUMBER_OF_TERMS - info.numberOfTermsWithdrawn);
        }
        uint256 withdrawAmountPercentage = 0;
        for (uint256 i = 0; i < _terms; i++) {
            withdrawAmountPercentage += withdrawablePercentsByTerm[
                info.numberOfTermsWithdrawn + i
            ];
        }
        uint256 numberOfTermsForFirstVesting = info.isAccelerated ? 0 : 1;
        uint256 numberOfTermsToMove = numberOfTermsForFirstVesting +
            info.numberOfTermsWithdrawn +
            _terms;
        moveTimestamp(info.timestamp, numberOfTermsToMove);
        uint256 withdrawableAmount = genesis.calcWithdrawableAmount(
            _owner,
            info.indexInGenesisVestSchedules,
            block.timestamp
        );
        uint256 totalAmount = info.depositedAmount;
        int128 percentage = ABDKMath64x64.fromUInt(
            withdrawAmountPercentage - 1
        );
        uint256 purposeBalBefore = purpose.balanceOf(_owner);
        genesis.withdrawPurpose(
            _owner,
            info.indexInGenesisVestSchedules,
            withdrawableAmount
        );
        uint256 purposeBalAfter = purpose.balanceOf(_owner);
        assert(purposeBalAfter - purposeBalBefore == withdrawableAmount);
        info.totalWithdrawnAmount += withdrawableAmount;
        info.numberOfTermsWithdrawn += _terms;
        if (!info.claimedReward) {
            claimAndVerifyRewards(_owner, _index);
        }
        if (info.numberOfTermsWithdrawn == TOTAL_NUMBER_OF_TERMS) {
            removeTestCaseAtIndex(testVests[_owner], _index);
        }
    }

    function testWithdrawPurposeAdmin(
        address _owner,
        uint32 _index,
        uint8 _terms
    ) public {
        require(ownerStaked[_owner]);
        require(testVests[_owner].length > 0);
        require(0 < _terms && _terms <= TOTAL_NUMBER_OF_TERMS);
        _index = uint32(_index % testVests[_owner].length);
        StakingInformation storage info = testVests[_owner][_index];
        if (info.numberOfTermsWithdrawn + _terms > TOTAL_NUMBER_OF_TERMS) {
            _terms = uint8(TOTAL_NUMBER_OF_TERMS - info.numberOfTermsWithdrawn);
        }
        uint256 numberOfTermsForFirstVesting = info.isAccelerated ? 0 : 1;
        uint256 numberOfTermsToMove = numberOfTermsForFirstVesting +
            info.numberOfTermsWithdrawn +
            _terms;
        moveTimestamp(info.timestamp, numberOfTermsToMove);
        uint256 purposeBalBefore = purpose.balanceOf(_owner);
        genesis.withdrawPurposeAdmin(_owner, info.indexInGenesisVestSchedules);
        uint256 purposeBalAfter = purpose.balanceOf(_owner);
        info.totalWithdrawnAmount += purposeBalAfter - purposeBalBefore;
        // check that total withdrawn purpose > deposited purpose
        assert(info.totalWithdrawnAmount >= info.depositedAmount);
        uint256 rewardAmount = info.totalWithdrawnAmount - info.depositedAmount;
        assert(rewardAmount >= 0);
        // remove testcase/vestschedule as total amount is withdrawn and verified.
        removeTestCaseAtIndex(testVests[_owner], _index);
    }
}


// File contracts/test/fuzzing/TestPFP.sol


/// @title Echidna tests for withdrawing and claiming of rewards
/// @author Alexander Remie, Trail of Bits
/// @author github.com/garthbrydon

/*
 * Copyright 2022 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */







contract PriceConsumerV3Mock {
    int256 private price;

    function setPrice(int256 _newPrice) public {
        price = _newPrice;
    }

    function getLatestPrice() public view returns (int256) {
        return price;
    }
}

contract EchidnaPFP {
    MockPFPConfig config;
    PriceConsumerV3Mock oracle;
    MockERC20 stable;
    PurposeToken purpose;
    PFP pfp;
    GenesisPurposeEscrow genesis;
    uint256 private constant ORACLE_DECIMALS = 10**8; // chainlink has 8 decimals

    constructor() {
        oracle = new PriceConsumerV3Mock();
        stable = new MockERC20("USDC", "USDC", 100_000, 6);
        config = new MockPFPConfig(address(this));
        purpose = new PurposeToken(address(config));
        genesis = new GenesisPurposeEscrow(address(purpose), address(config));
        pfp = new PFP(
            address(purpose),
            address(genesis),
            address(config),
            address(oracle)
        );
        pfp.grantRole(pfp.ADMIN_ROLE(), address(this));
        pfp.addCoinAddr(address(stable));
        genesis.grantRole(genesis.STAKER_ROLE(), address(pfp));
        stable.approve(address(pfp), type(uint256).max);
        oracle.setPrice(int256(1_000 * ORACLE_DECIMALS)); // $1000 per 1 ETH
    }

    function test_depositEth_leftover(bool _isAccelerated) public payable {
        require(msg.value > 0);
        pfp.depositEth{value: msg.value}(_isAccelerated, 0);
        assert(address(pfp).balance == 0);
    }

    function test_depositEth_zeroOut(bool _isAccelerated) public payable {
        require(msg.value > 0);
        uint256 purposeBalBefore = purpose.balanceOf(address(genesis));
        pfp.depositEth{value: msg.value}(_isAccelerated, 0);
        uint256 purposeBalAfter = purpose.balanceOf(address(genesis));
        assert(purposeBalAfter > purposeBalBefore);
    }

    function test_depositEth_inNotActualIn(bool _isAccelerated) public payable {
        require(msg.value > 0);
        uint256 ethBalBeforeEndowment = config.endowmentAddr().balance;
        uint256 ethBalBeforeFoundation = config.foundationAddr().balance;
        pfp.depositEth{value: msg.value}(_isAccelerated, 0);
        uint256 ethBalAfterEndowment = config.endowmentAddr().balance;
        uint256 ethBalAfterFoundation = config.foundationAddr().balance;
        assert(
            msg.value ==
                (ethBalAfterEndowment -
                    ethBalBeforeEndowment +
                    ethBalAfterFoundation -
                    ethBalBeforeFoundation)
        );
    }

    function test_depositEth_zeroInPositiveOut(bool _isAccelerated) public {
        uint256 purposeBalBefore = purpose.balanceOf(address(genesis));
        pfp.depositEth{value: 0}(_isAccelerated, 0);
        uint256 purposeBalAfter = purpose.balanceOf(address(genesis));
        assert(purposeBalAfter == purposeBalBefore);
    }

    function test_deposit_leftover(bool _isAccelerated, uint256 _amount)
        public
    {
        require(_amount > 0);
        pfp.deposit(address(stable), _amount, _isAccelerated, 0);
        assert(purpose.balanceOf(address(pfp)) == 0);
    }

    function test_deposit_inNotActualIn(bool _isAccelerated, uint256 _amount)
        public
    {
        require(_amount > 0);
        uint256 stableBalBeforeEndowment = stable.balanceOf(
            config.endowmentAddr()
        );
        uint256 stableBalBeforeFoundation = stable.balanceOf(
            config.foundationAddr()
        );
        pfp.deposit(address(stable), _amount, _isAccelerated, 0);
        uint256 stableBalAfterEndowment = stable.balanceOf(
            config.endowmentAddr()
        );
        uint256 stableBalAfterFoundation = stable.balanceOf(
            config.foundationAddr()
        );
        assert(
            _amount ==
                (stableBalAfterEndowment -
                    stableBalBeforeEndowment +
                    stableBalAfterFoundation -
                    stableBalBeforeFoundation)
        );
    }

    function test_deposit_zeroOut(bool _isAccelerated, uint256 _amount) public {
        require(_amount > 0);
        uint256 purposeBalBefore = purpose.balanceOf(address(genesis));
        pfp.deposit(address(stable), _amount, _isAccelerated, 0);
        uint256 purposeBalAfter = purpose.balanceOf(address(genesis));
        assert(purposeBalAfter > purposeBalBefore);
    }

    function test_deposit_zeroInPositiveOut(bool _isAccelerated) public {
        uint256 purposeBalBefore = purpose.balanceOf(address(genesis));
        pfp.deposit(address(stable), 0, _isAccelerated, 0);
        uint256 purposeBalAfter = purpose.balanceOf(address(genesis));
        assert(purposeBalAfter == purposeBalBefore);
    }
}