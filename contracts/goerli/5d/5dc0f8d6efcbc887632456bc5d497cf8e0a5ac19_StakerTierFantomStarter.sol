/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * bearer except when using {_setupRole}.
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

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Account is not in the admin list");
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(uint256 id, address receiver) external;
}


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

    function mintToken(address account, uint256 amount) external;

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
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}



/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

/**
* @dev
* Interface to access the TierFactory FantomStarter
**/
interface ITierFactoryFantomStarter {
    /**
    * @dev
    * Returns the balance of the number of NFTs based on the NFTId
    **/
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
    * @dev
    * Returns the balance of a list of addresses
    **/
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
    * @dev
    * Mint the NFT
    **/
    function mint(address _to, uint256 _id, uint256 _quantity, bytes calldata _data) external;

    /**
    * @dev
    * Check if the NFT is mintable
    **/
    function isMintable(uint256 _id) external returns (bool);

    /**
    * @dev
    * Transfer the NFT _from _to
    **/
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

    /**
    * @dev
    * Safe transfer a batch of NFTs _from _to
    **/
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

    /**
    * @dev
    * Get max supply for token id
    **/
    function maxSupply(uint256 _id) external view returns (uint256);

    /**
    * @dev
    * Get the Tier based on the NFT Id
    **/
    function getTierByNFTId(uint256 _nftId) external view returns (uint256);
}

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

/**
* @dev Staking Tier Fantom Starter contract.
* Staking NFT:
* Every wallet can stake only one NFT at a time.
* Staking FS Tokens:
* Every wallet can stake only x tokens
*
* Staking only per wallet at a time, either for NFT or FS Tokens
**/
contract StakerTierFantomStarter is ERC1155Holder, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ITierFactoryFantomStarter public tierFactory;
    IERC20 public fsToken;

    // The period of lockup days before you can unstake NFT or FS tokens.
    uint256 public lockupDays = 7;

    // Cooldown days used after staking to calculate lockup period
    uint256 public coolDownDays = 0;

    // When unstaking FS tokens before lockup period, we keep 10% as a penalty
    uint256 public withholdUnstakingPercentage = 10;


    // The dev wallet address that penalty FS tokens are sent to
    address private devWallet;

    // Struct for the staked NFT
    struct StakedTierNFT {
        bool currentlyStaked;
        uint256 nftId;
        uint256 tierId;
        uint256 creationTimestamp;   // EPOCH timestamp
        uint256 stakingLockupDays;
        uint256 cancelStackingCoolDownDays;
    }

    // Tier for FS Tokens in staked contract within a certain range
    struct TierFSTokens {
        bool initialized;
        uint256 tierId;
        uint256 minFSTokens;
        uint256 maxFSTokens;
    }

    // Struct for the staked FS tokens
    struct StakedTierFSToken {
        bool currentlyStaked;
        uint256 tokenAmount;
        uint256 tierId;
        uint256 withholdUnstakingPercentage;
        uint256 creationTimestamp;   // EPOCH timestamp
        uint256 stakingLockupDays;
        uint256 cancelStackingCoolDownDays;
    }

    // Contains the list of Tiers based on the FS Tokens min max range
    TierFSTokens[] public tierFSTokensList;

    // Each wallet can only stake either NFT or FS token and also only once.
    mapping(address => StakedTierNFT) public walletStakedTierNFTMapping;
    mapping(address => StakedTierFSToken) public walletStakedTierFSTokenMapping;

    // Events
    event AddToStakedTierNFT(address staker, uint256 nftId);
    event AddToStakedTierFSToken(address staker, uint256 fsTokensStaked);
    event RemovedFromStakedTierNFT(address staker, uint256 nftId);
    event RemovedFromStakedTierFSToken(address staker, uint256 fsTokensStaked);
    event UnstakedBeforeLockupPeriodFSToken(address staker, uint256 fsTokensStakedReturned, uint256 withheldFSTokens);

    // Loggers for admin only
    event ChangedTierFactoryAddress(address admin, ITierFactoryFantomStarter oldTierFactoryAddress, ITierFactoryFantomStarter newTierFactoryAddress);
    event ChangedLockupDays(address admin, uint256 oldLockupFactoryDays, uint256 newLockupFactoryDays);
    event ChangedCoolDownDays(address admin, uint256 oldCoolDownDays, uint256 newCoolDownDays);
    event ChangedDevWalletAddress(address admin, address oldDevWalletAddress, address newDevWalletAddress);
    event ChangedWithholdUnstakingPercentage(address admin, uint256 oldUnstakingPercentage, uint256 newUnstakingPercentage);
    event UpdateOrCreateFSTierTokenRange(address admin, uint256 tierId, uint256 minFSTokens, uint256 maxFSTokens);

    constructor(ITierFactoryFantomStarter _tierFactory, IERC20 _fsToken, address _devWallet) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);  // Add contract publisher to the admin users
        tierFactory = _tierFactory;
        fsToken = _fsToken;
        devWallet = _devWallet;
    }

    // Needed for compiling
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    // Getters and Setters
    /**
    * @dev
    * Update or create a Tier FS token range
    **/
    function setTierFSTokenRange(uint256 _tierId, uint256 _minFSTokens, uint256 _maxFSTokens) public isAdmin {
        // First check if the tier already exists and if so, update the current tier.

        bool _tierExists = false;
        uint256 _tierIndex = 0;

        for (uint256 i = 0; i < tierFSTokensList.length; i++) {
            if (tierFSTokensList[i].tierId == _tierId) {
                _tierIndex = i;
                _tierExists = true;
                break;
            }
        }

        if (_tierExists) {
            // The tier already exists, update the existing Tier
            tierFSTokensList[_tierIndex].minFSTokens = _minFSTokens;
            tierFSTokensList[_tierIndex].maxFSTokens = _maxFSTokens;
        } else {
            // The tier does not exist, create a new entry
            tierFSTokensList.push(TierFSTokens(true, _tierId, _minFSTokens, _maxFSTokens));
        }

        emit UpdateOrCreateFSTierTokenRange(msg.sender, _tierId, _minFSTokens, _maxFSTokens);
    }

    /**
    * @dev
    * Returns back the entire list of FS Tier tokens
    **/
    function getTierFSTokens() public view returns (TierFSTokens[] memory tierFSTokens) {
        return tierFSTokensList;
    }

    /**
    * @dev Replace the existing TierFactory address with a new one, only admins.
    **/
    function setTierFactoryAddress(ITierFactoryFantomStarter _tierFactory) public isAdmin {
        ITierFactoryFantomStarter _oldTierFactoryAddress = tierFactory;

        tierFactory = _tierFactory;

        emit ChangedTierFactoryAddress(msg.sender, _oldTierFactoryAddress, _tierFactory);
    }

    /**
    * @dev Replace the lockup_days period, only admins.
    **/
    function setLockupDays(uint256 _days) public isAdmin {
        uint256 _oldLockupDays = lockupDays;

        lockupDays = _days;

        emit ChangedLockupDays(msg.sender, _oldLockupDays, _days);
    }

    /**
    * @dev Replace the cooldowndays period, only admins.
    **/
    function setCoolDownDays(uint256 _days) public isAdmin {
        uint256 _oldCoolDownDays = coolDownDays;

        coolDownDays = _days;

        emit ChangedCoolDownDays(msg.sender, _oldCoolDownDays, _days);
    }

    /**
    * @dev Replace the dev wallet
    **/
    function setDevWalletAddress(address _devWallet) public isAdmin {
        address _oldDevWallet = devWallet;

        devWallet = _devWallet;

        emit ChangedDevWalletAddress(msg.sender, _oldDevWallet, _devWallet);
    }

    /**
    * @dev Replace the withhold unstaking percentage
    **/
    function setWithholdUnstakingPercentage(uint256 _withholdUnstakingPercentage) public isAdmin {
        require(_withholdUnstakingPercentage < 100, "You cannot withhold more than 99 percent");
        require(_withholdUnstakingPercentage >= 1, "You need to withhold at least 1 percent");

        uint256 _oldWithholdUnstakingPercentage = withholdUnstakingPercentage;

        withholdUnstakingPercentage = _withholdUnstakingPercentage;

        emit ChangedWithholdUnstakingPercentage(msg.sender, _oldWithholdUnstakingPercentage, _withholdUnstakingPercentage);
    }

    /**
    * @dev
    * Returns the NFT ID currently staked
    **/
    function getNFTIdStaked(address _wallet) public view returns (uint256 nftIdStaked) {
        require(hasWalletCurrentlyStakedNFT(_wallet) == true, "Wallet has currently no NFT staked");
        require(hasWalletCurrentlyStakedFSTokens(_wallet) == false, "Wallet has staked FS Tokens and not NFTs");

        return walletStakedTierNFTMapping[_wallet].nftId;
    }

    /**
    * @dev
    * Returns the token amount staked
    **/
    function getTokensAmountStaked(address _wallet) public view returns (uint256 tokenAmountStaked) {
        require(hasWalletCurrentlyStakedNFT(_wallet) == false, "Wallet has staked NFTs and not FS tokens");
        require(hasWalletCurrentlyStakedFSTokens(_wallet) == true, "Wallet has currently no FS Tokens staked");

        return walletStakedTierFSTokenMapping[_wallet].tokenAmount;
    }

    /**
    * @dev
    * Returns back the Tier for staked benefits, either the token staked or NFT staked
    **/
    function getTierBenefitForStaker(address _wallet) public view returns (uint256 tierId) {
        uint256 result = 0;

        if (hasWalletCurrentlyStakedNFT(_wallet)) {
            // If the wallet has staked NFT, get back the Tier for that NFT and return it.
            result = tierFactory.getTierByNFTId(getNFTIdStaked(_wallet));
        } else if (hasWalletCurrentlyStakedFSTokens(_wallet)) {
            // If the wallet has staked FS tokens, calculate the TierID for the tokens staked
            uint256 _fsTokenAmountToStake = walletStakedTierFSTokenMapping[_wallet].tokenAmount;
            result = getTierIdFromTokensStaked(_fsTokenAmountToStake);
        }

        return result;
    }

    /**
    * @dev
    * Returns back the Tier for the Tokens staked
    **/
    function getTierIdFromTokensStaked(uint256 _tokensStaked) public view returns (uint256 tierId) {
        uint256 result = 0;

        for (uint256 i = 0; i < tierFSTokensList.length; i++) {
            if (_tokensStaked >= tierFSTokensList[i].minFSTokens && _tokensStaked <= tierFSTokensList[i].maxFSTokens) {
                result = tierFSTokensList[i].tierId;
                break;
            }
        }

        return result;
    }

    /**
    * @dev Returns uint256 lockupTime left for staked address for NFT Staked
    **/
    function getLockupTimeLeftStakedNFT(address _wallet) public view returns (uint256 lockupTimeLeft) {
        require(hasWalletCurrentlyStakedNFT(_wallet) == true, "Wallet has currently no NFT staked");
        require(hasWalletCurrentlyStakedFSTokens(_wallet) == false, "Wallet has staked FS Tokens and not NFTs");

        StakedTierNFT memory _stakedTierNFT = walletStakedTierNFTMapping[_wallet];
        uint256 result = 0;

        if ((_stakedTierNFT.creationTimestamp + (_stakedTierNFT.stakingLockupDays * 1 days) - block.timestamp) > 0) {
            result = _stakedTierNFT.creationTimestamp + (_stakedTierNFT.stakingLockupDays * 1 days) - block.timestamp;
        }

        return result;
    }

    /**
    * @dev Returns uint256 lockupTime left for staked address for Tokens Stakend
    **/
    function getLockupTimeLeftStakedFSTokens(address _wallet) public view returns (uint256 lockupTimeLeft) {
        require(hasWalletCurrentlyStakedNFT(_wallet) == false, "Wallet has staked NFTs and not FS tokens");
        require(hasWalletCurrentlyStakedFSTokens(_wallet) == true, "Wallet has currently no FS Tokens staked");

        StakedTierFSToken memory _stakedTierFSToken = walletStakedTierFSTokenMapping[_wallet];
        uint256 result = 0;

        if ((_stakedTierFSToken.creationTimestamp + (_stakedTierFSToken.stakingLockupDays * 1 days) - block.timestamp) > 0) {
            result = _stakedTierFSToken.creationTimestamp + (_stakedTierFSToken.stakingLockupDays * 1 days) - block.timestamp;
        }

        return result;
    }

    // Checks
    /**
    * @dev Check if account has any Completed staked NFTs for Tier
    **/
    function hasWalletCompletedStakingNFT(address _wallet) public view returns (bool hasCompletedStakingNFT) {
        bool result = true;

        // 1. get the staked NFT object
        StakedTierNFT memory _stakedTierNFT = walletStakedTierNFTMapping[_wallet];

        // 2. Check if the lockup period is still counting
        // If the creationTimestamp with added lockupDays is equal or bigger than now, then the auction has expired
        if (_stakedTierNFT.creationTimestamp + _stakedTierNFT.stakingLockupDays * 1 days >= block.timestamp) {
            result = false;
        }

        return result;
    }

    /**
    * @dev Check if account has any Completed staked FS Tokens for Tier
    **/
    function hasWalletCompletedStakingFSTokens(address _wallet) public view returns (bool hasCompletedStakingFSTokens) {
        bool result = true;

        // 1. get the staked NFT object
        StakedTierFSToken memory _stakedTierFSToken = walletStakedTierFSTokenMapping[_wallet];

        // 2. Check if the lockup period is still counting
        // If the creationTimestamp with added lockupDays is equal or bigger than now, then the auction has expired
        if (_stakedTierFSToken.creationTimestamp + _stakedTierFSToken.stakingLockupDays * 1 days >= block.timestamp) {
            result = false;
        }

        return result;
    }

    /**
    * @dev Check if address has already staked for another NFT Tier
    **/
    function hasWalletCurrentlyStakedNFT(address _wallet) public view returns (bool hasStakedNFT) {
        bool result = false;

        if (walletStakedTierNFTMapping[_wallet].currentlyStaked == true) {
            result = true;
        }

        return result;
    }

    /**
    * @dev Check if address has already staked for Tokens
    **/
    function hasWalletCurrentlyStakedFSTokens(address _wallet) public view returns (bool hasStakedFSTokens) {
        bool result = false;

        if (walletStakedTierFSTokenMapping[_wallet].currentlyStaked == true) {
            result = true;
        }

        return result;
    }

    /**
    * @dev Returns true if address can cancel staked NFT
    **/
    function hasCancelCoolDownDaysExpiredForStakedNFT(address _wallet) public view returns (bool expired) {
        require(hasWalletCurrentlyStakedNFT(_wallet) == true, "You have currently no NFT staked");
        require(hasWalletCompletedStakingNFT(_wallet) == true, "Lockup period still pending");

        bool result = true;

        // 1. get the staked NFT object
        StakedTierNFT memory _stakedTierNFT = walletStakedTierNFTMapping[_wallet];

        // 2. Check if the cool down period has expired
        // If the creationTimestamp with added lockupDays is equal or bigger than now, then the auction has expired
        if (_stakedTierNFT.creationTimestamp + (_stakedTierNFT.stakingLockupDays * 1 days) + (_stakedTierNFT.cancelStackingCoolDownDays * 1 days) >= block.timestamp) {
            result = false;
        }

        return result;
    }

    // BusinessLogic
    /**
     * @dev Transfers the NFT of the msg.sender to this contract to be staked
     * You can only stake once per wallet
     */
    function stakeTierNFT(uint256 _nftId) public {
        require(tierFactory.balanceOf(msg.sender, _nftId) > 0, "You do not own this NFT");
        require(hasWalletCurrentlyStakedNFT(msg.sender) == false, "You have already staked NFTs");
        require(hasWalletCurrentlyStakedFSTokens(msg.sender) == false, "You have already staked FSTokens");

        // SafeTransfer the NFT from the msg.sender to the contract
        tierFactory.safeTransferFrom(msg.sender, address(this), _nftId, 1, "");

        // Create a new staking NFT object and add them to the mapping
        uint256 _tierId = tierFactory.getTierByNFTId(_nftId);
        walletStakedTierNFTMapping[msg.sender] = StakedTierNFT(true, _nftId, _tierId, block.timestamp, lockupDays, coolDownDays);

        // Emit event
        emit AddToStakedTierNFT(msg.sender, _nftId);
    }

    /**
    * @dev Transfers the FSTokens of the msg.sender to this contract to be staked.
    * Wallet can only stake once per wallet
    **/
    function stakeTierFSTokens(uint256 _fsTokenAmountToStake) public {
        require(fsToken.balanceOf(msg.sender) >= _fsTokenAmountToStake, "You do not own enough tokens to stake");
        require(hasWalletCurrentlyStakedNFT(msg.sender) == false, "You have already staked NFTs");
        require(hasWalletCurrentlyStakedFSTokens(msg.sender) == false, "You have already staked FSTokens");

        // SafeTransfer the tokens from msg.sender to this contract
        fsToken.safeTransferFrom(msg.sender, address(this), _fsTokenAmountToStake);

        // Get the Tier Id from the amount of _fsTokenAmountToStake
        uint256 _tierId = getTierIdFromTokensStaked(_fsTokenAmountToStake);

        // Create a new staking FSToken object and add them to the mapping
        walletStakedTierFSTokenMapping[msg.sender] = StakedTierFSToken(true, _fsTokenAmountToStake, _tierId, withholdUnstakingPercentage, block.timestamp, lockupDays, coolDownDays);

        // Emit event
        emit AddToStakedTierFSToken(msg.sender, _fsTokenAmountToStake);
    }

    /**
    * @dev Add more tokens to Staked FS Tokens
    **/
    function updateCurrentStakedFSTokens(uint256 _fsTokenAmountToStake) public {
        require(fsToken.balanceOf(msg.sender) >= _fsTokenAmountToStake, "You do not own enough tokens to stake");
        require(hasWalletCurrentlyStakedNFT(msg.sender) == false, "You have already staked NFTs");
        require(hasWalletCurrentlyStakedFSTokens(msg.sender) == true, "You do not have staked FSTokens");

        // SafeTransfer the tokens from msg.sender to this contract
        fsToken.safeTransferFrom(msg.sender, address(this), _fsTokenAmountToStake);

        // Create a new staking FSToken object and add them to the mapping
        walletStakedTierFSTokenMapping[msg.sender].tokenAmount = walletStakedTierFSTokenMapping[msg.sender].tokenAmount + _fsTokenAmountToStake;

        // Update the Tier id
        uint256 _tierId = getTierIdFromTokensStaked(walletStakedTierFSTokenMapping[msg.sender].tokenAmount);
        walletStakedTierFSTokenMapping[msg.sender].tierId = _tierId;

        // Reset the lockup period in days
        walletStakedTierFSTokenMapping[msg.sender].creationTimestamp = block.timestamp;


        // Emit event
        emit AddToStakedTierFSToken(msg.sender, _fsTokenAmountToStake);
    }

    /**
     * @dev Cancels the staked NFT and returns it to the owner
     */
    function unstakeTierNFT() public {
        require(hasWalletCurrentlyStakedNFT(msg.sender) == true, "You have currently no NFT staked");
        require(hasWalletCompletedStakingNFT(msg.sender) == true, "Lockup period still pending");
        require(hasCancelCoolDownDaysExpiredForStakedNFT(msg.sender) == true, "You need to wait for the cool down period to expire");

        // 1. get the staked NFT object
        StakedTierNFT memory _stakedTierNFT = walletStakedTierNFTMapping[msg.sender];

        // 2. Since the staking lockup period has expired, transfer the NFT back to the owner
        // SafeTransfer the NFT from the msg.sender to the contract
        tierFactory.safeTransferFrom(address(this), msg.sender, _stakedTierNFT.nftId, 1, "");

        // 3. Remove the StakedTierNFT Object from the mapping
        delete walletStakedTierNFTMapping[msg.sender];

        // Emit event
        emit RemovedFromStakedTierNFT(msg.sender, _stakedTierNFT.nftId);
    }

    /**
     * @dev Unstake FS Tokens after lockup period
     */
    function unstakeTierFSTokensAfterLockupPeriod() public {
        require(hasWalletCurrentlyStakedFSTokens(msg.sender) == true, "You have no FSTokens staked");
        require(hasWalletCompletedStakingFSTokens(msg.sender) == true, "Lockup period still pending");

        // 1. get the staked NFT object
        StakedTierFSToken memory _stakedTierFSToken = walletStakedTierFSTokenMapping[msg.sender];

        // 2. Since the staking lockup period has expired, transfer the FS Tokens back to the owner
        // SafeTransfer the FSTokens from the contract to the msg.sender
        fsToken.safeTransfer(msg.sender, _stakedTierFSToken.tokenAmount);

        // 3. Remove the StakedTierFSToken Object from the mapping
        delete walletStakedTierFSTokenMapping[msg.sender];

        // Emit event
        emit RemovedFromStakedTierFSToken(msg.sender, _stakedTierFSToken.tokenAmount);
    }

    /**
    * @dev Unstake FS Token while lockup period still pending
    **/
    function unstakeTierFSTokensBeforeLockupPeriod() public {
        require(hasWalletCurrentlyStakedFSTokens(msg.sender) == true, "You have no FSTokens staked");
        require(hasWalletCompletedStakingFSTokens(msg.sender) == false, "Lockup period has expired");

        // 1. get the staked NFT object
        StakedTierFSToken memory _stakedTierFSToken = walletStakedTierFSTokenMapping[msg.sender];

        uint256 _fsTokensToReturnToStaker = 0;
        uint256 _fsTokensPenaltyToDevWallet = 0;

        // 2. Set the tokens that need to be returned
        _fsTokensPenaltyToDevWallet = _stakedTierFSToken.tokenAmount * _stakedTierFSToken.withholdUnstakingPercentage / 100;
        _fsTokensToReturnToStaker = _stakedTierFSToken.tokenAmount - _fsTokensPenaltyToDevWallet;

        // 3. Safe transfer the tokens to the dev wallet and the staker
        fsToken.safeTransfer(msg.sender, _fsTokensToReturnToStaker);
        fsToken.safeTransfer(devWallet, _fsTokensPenaltyToDevWallet);

        // 4. Remove the StakedTierFSToken Object from the mapping
        delete walletStakedTierFSTokenMapping[msg.sender];

        // Emit event
        emit UnstakedBeforeLockupPeriodFSToken(msg.sender, _fsTokensToReturnToStaker, _fsTokensPenaltyToDevWallet);
    }
}