/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
 * Enhanced Strings library by FantomStarter
 * Added concatenation
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
    * @dev
    * Added by FantomStarter
    * Concatenation for string types
    **/
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }

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
    * @dev
    * Convert address to string
    **/
    function addressToAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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
* @dev
* Interface to access the TierFactory FantomStarter
**/
interface ITierFactoryFantomStarter {

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
    * @dev
    * Returns the balance of the number of NFTs based on the NFTId
    **/
    function balanceOf(address _owner, uint256 _nftId) external view returns (uint256);

    /**
    * @dev
    * Returns the balance of a list of addresses
    **/
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
    * @dev
    * Mint the NFT
    **/
    function mint(address _to, uint256 _nftId, uint256 _quantity, bytes calldata _data) external;

    /**
    * @dev
    * Check if the NFT is mintable
    **/
    function isMintable(uint256 _nftId) external view returns (bool);

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
    * Get max supply for token NFT id
    **/
    function maxSupply(uint256 _nftId) external view returns (uint256);

    /**
    * @dev Total amount of tokens in with a given NFT id.
     */
    function totalSupply(uint256 _nftId) external view returns (uint256);

    /**
    * @dev
    * Get the Tier based on the NFT Id
    **/
    function getTierByNFTId(uint256 _nftId) external view returns (uint256);

    /**
    * @dev
    * Burn the NFT
    **/
    function burn(address account, uint256 id, uint256 value) external;
}


contract StoreNFTFantomStarter is ERC1155Holder, AccessControl  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ITierFactoryFantomStarter public tierNFTFactory;
    IERC20 public fsToken;

    address private devWallet;

    // NFT Price in WEI
    // NFT id -> NFT price
    mapping(uint256 => uint256) public nftPrice;
    // Upgrade the NFT based on old NFT ID => To upgrade NFT ID
    mapping(uint256 => uint256) public nftUpgradeId;
    // Eligible for free upgrades on discount 100%
    mapping(uint256 => bool) public nftIdFreeUpgrade;
    // Discount for NFT
    mapping(uint256 => uint256) public nftDiscountPercentage;

    uint256 public burnedFSTokens;

    event BoughtNFT(address owner, uint256 nftId, uint256 nftPrice);
    event FSTokensBurned(uint256 amount);
    event WithdrawNFT(address admin, address receiver, uint256 nftId, uint256 amount);

    event UpdateNFTUpgradeID(address admin, uint256 nftId, uint256 oldToUpgradeNFTId, uint256 newNFTUpgradeId);
    event UpdateNFTDiscountPercentage(address admin, uint256 nftId, uint256 oldDiscountPercentage, uint256 newDiscountPercentage);
    event UpdateNFTPrice(address admin, uint256 nftId, uint256 oldNFTPrice, uint256 newNFTPrice);
    event UpdateDevWallet(address admin, address oldDevWallet, address newDevWallet);
    event UpdateNFTIdFreeUpgrade(address admin, uint256 nftId, bool oldEligibleForFreeUpgrade, bool newEligibleForFreeUpgrade);
    event UpdateTierNFTFactory(address admin, ITierFactoryFantomStarter oldTierNFTFactory, ITierFactoryFantomStarter newTierNFTFactory);

    constructor(ITierFactoryFantomStarter _tierNFTFactory, IERC20 _fsToken, address _devWallet) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tierNFTFactory = _tierNFTFactory;
        fsToken = _fsToken;
        devWallet = _devWallet;
    }

    // Needed for compiling
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    // Getters and Setters
    /**
    * @dev Update the tierNFTFactory address
    **/
    function setTierNFTFactory(ITierFactoryFantomStarter _tierNFTFactory) external isAdmin {
        ITierFactoryFantomStarter _oldTierNFTFactory = tierNFTFactory;

        tierNFTFactory = _tierNFTFactory;

        emit UpdateTierNFTFactory(msg.sender, _oldTierNFTFactory, tierNFTFactory);
    }

    /**
    * @dev
    * Update or add the free upgrades NFT Ids
    **/
    function setNFTIdFreeUpgrade(uint256 _nftId, bool _eligibleForFreeUpgrade) external isAdmin {
        bool _oldEligibleForFreeUpgrade = nftIdFreeUpgrade[_nftId];

        nftIdFreeUpgrade[_nftId] = _eligibleForFreeUpgrade;

        emit UpdateNFTIdFreeUpgrade(msg.sender, _nftId, _oldEligibleForFreeUpgrade, _eligibleForFreeUpgrade);
    }

    /**
    * @dev Replace the dev wallet
    **/
    function setDevWalletAddress(address _devWallet) external isAdmin {
        address _oldDevWallet = devWallet;

        devWallet = _devWallet;

        emit UpdateDevWallet(msg.sender, _oldDevWallet, _devWallet);
    }

    /**
    * @dev Update or Set the NFT Price
    * Setting the NFT price to 0 will mean that this NFT does not have a price
    **/
    function setNFTPrice(uint256 _nftId, uint256 _nftPrice) external isAdmin {
        uint256 _oldNFTPrice = nftPrice[_nftId];

        nftPrice[_nftId] = _nftPrice;

        emit UpdateNFTPrice(msg.sender, _nftId, _oldNFTPrice, _nftPrice);
    }

    /**
    * @dev Update the Discount percentage on upgrading NFTs
    **/
    function setNFTDiscountOnUpgradeNFT(uint256 _nftId, uint256 _discountPercentage) external isAdmin {
        require(_discountPercentage <= 100, "The discount percentage should be lower or equal to 100%");
        uint256 _oldDiscountPercentage = nftDiscountPercentage[_nftId];

        nftDiscountPercentage[_nftId] = _discountPercentage;

        emit UpdateNFTDiscountPercentage(msg.sender, _nftId, _oldDiscountPercentage,  _discountPercentage);
    }

    /**
    * @dev Update the NFTId with the next NFTID that it can be upgraded to
    **/
    function setNFTUpgradeId(uint256 _currentNFTId, uint256 _toUpgradeNFTId) external isAdmin {
        uint256 _oldToUpgradeNFTId = nftUpgradeId[_currentNFTId];
        uint256 _newNFTUpgradeId = _toUpgradeNFTId;

        // Update or add to the mapping
        nftUpgradeId[_currentNFTId] = _toUpgradeNFTId;

        emit UpdateNFTUpgradeID(msg.sender, _currentNFTId, _oldToUpgradeNFTId, _newNFTUpgradeId);
    }

    /**
    * @dev Check if the NFT is either in the store or is mintable
    **/
    function getTotalAvailableNFTsByNFTId(uint256 _nftId) public view returns (uint256 availableAmount) {
        uint256 result = 0;

        if (isStoreOwnerOfNFT(_nftId) == true) {
            // The Store owns the NFT, add how many
            result = result.add(tierNFTFactory.balanceOf(address(this), _nftId));
        }

        if (tierNFTFactory.isMintable(_nftId) == true) {
            // The NFT is still mintable, calculate how many are left
            uint256 _maxSupplyFromFactory = tierNFTFactory.maxSupply(_nftId);
            uint256 _totalSupplyFromFactory = tierNFTFactory.totalSupply(_nftId);

            uint256 _availableSupplyFromFactory = _maxSupplyFromFactory.sub(_totalSupplyFromFactory);
            result = result.add(_availableSupplyFromFactory);
        }

        return result;
    }

    // Checks
    /**
    * @dev Check if the wallet holder has enough Fantom Starter Tokens
    **/
    function hasWalletEnoughFSTokens(address _wallet, uint256 _requiredTokens) public view returns (bool) {
        bool result = false;

        // Check if the balance of the _wallet has at least the required tokens.
        if (fsToken.balanceOf(_wallet) >= _requiredTokens) {
            result = true;
        }

        return result;
    }

    /**
    * @dev Does the store own the NFT
    **/
    function isStoreOwnerOfNFT(uint256 _nftId) public view returns (bool isOwner) {
        bool result = false;

        if (tierNFTFactory.balanceOf(address(this), _nftId) > 0) {
            result = true;
        }

        return result;
    }

    /**
    * @dev Check if the NFT is either in the store or is mintable
    **/
    function canNFTBeBought(uint256 _nftId) public view returns (bool canBeBought) {
        bool result = false;

        if (isStoreOwnerOfNFT(_nftId) == true) {
            // The Store owns the NFT, no need to mint the NFT
            result = true;
        } else if (tierNFTFactory.isMintable(_nftId) == true) {
            // The store does not own the NFT, but the NFT is mintable from the tierNFTFactory
            result = true;
        }

        return result;
    }

    // BusinessLogic
    /**
    * @dev Buy the Tier NFT, provide the NFT ID.
    **/
    function buyTierNFT(uint256 _nftId) public {
        require(canNFTBeBought(_nftId) == true, "This NFT is can not be bought at this time");
        require(nftPrice[_nftId] > 0, "NFT ID Price does not exist for this NFT ID");

        // Get the price of the NFT ID
        uint256 _nftPrice = nftPrice[_nftId];

        // If the wallet holder has not enough tokens, revert the transaction
        if (hasWalletEnoughFSTokens(msg.sender, _nftPrice) == false) {
            revert("You need more FantomStarter tokens in your wallet");
        }

        // Burn the 100% FantomStarter tokens
        fsToken.burnFrom(msg.sender, _nftPrice);
        burnedFSTokens = burnedFSTokens + _nftPrice;
        emit FSTokensBurned(_nftPrice);

        // Transfer the NFT to the msg.sender
        if (isStoreOwnerOfNFT(_nftId) == true) {
            tierNFTFactory.safeTransferFrom(address(this), msg.sender, _nftId, 1, "");
        } else {
            tierNFTFactory.mint(msg.sender, _nftId, 1, "");
        }

        emit BoughtNFT(msg.sender, _nftId, _nftPrice);
    }

    /**
    * @dev Upgrade the NFT (can only upgrade 1 tier at a time)
    * Pass the NFT ID, not the TierId
    **/
    function upgradeTier(uint256 _nftIdToUpgrade) public {
        require(tierNFTFactory.balanceOf(msg.sender, _nftIdToUpgrade) >= 1, "You do not own this NFT");
        require(nftUpgradeId[_nftIdToUpgrade] > 0, "This NFT cannot be upgraded at this time");

        // First get the upgrade Tier NFT Id
        uint256 _upgradeToNFTId = nftUpgradeId[_nftIdToUpgrade];
        uint256 _oldNFTPrice = nftPrice[_nftIdToUpgrade];
        uint256 _newNFTPrice = nftPrice[_upgradeToNFTId];  // Should be higher than the _oldNFTPrice

        if (_newNFTPrice < _oldNFTPrice) {
            revert("Cannot upgrade because there is a price difference between the NFTs");
        }

        if (canNFTBeBought(_upgradeToNFTId) == false) {
            revert("NFT no longer available");
        }

        // Difference in price between the current NFT and the one to update
        uint256 _differenceInPrice = _newNFTPrice.sub(_oldNFTPrice);

        if (nftIdFreeUpgrade[_upgradeToNFTId] == true) {  // There is a 100% Discount on upgrading to this NFT
            // Transfer the current NFT to the store
            tierNFTFactory.safeTransferFrom(msg.sender, address(this), _nftIdToUpgrade, 1, "");

            // Since we do a free upgrade, do not ask for tokens
            // Transfer the NFT to the msg.sender
            if (isStoreOwnerOfNFT(_upgradeToNFTId) == true) {
                // Transfer the store NFT to the upgrade wallet
                tierNFTFactory.safeTransferFrom(address(this), msg.sender, _upgradeToNFTId, 1, "");
            } else {
                // Mint the new NFT to the wallet
                tierNFTFactory.mint(msg.sender, _upgradeToNFTId, 1, "");
            }

        } else if (nftDiscountPercentage[_upgradeToNFTId] > 0) { // There is some % on upgrading NFTs
            uint256 _discountPercentage = nftDiscountPercentage[_upgradeToNFTId];
            uint256 _discount = _differenceInPrice.div(100).mul(_discountPercentage);
            _differenceInPrice = _differenceInPrice.sub(_discount);

            processNFTUpgrade(_nftIdToUpgrade, _upgradeToNFTId, _differenceInPrice);
        } else { // There is NO discount on upgrading NFTs
            processNFTUpgrade(_nftIdToUpgrade, _upgradeToNFTId, _differenceInPrice);
        }
    }

    /**
    * @dev Transfer NFT from the store to a wallet
    **/
    function withdrawNFTById(uint256 _nftId, address _receiver, uint256 _amount) external isAdmin {
        require(isStoreOwnerOfNFT(_nftId) == true, "Store is not owner of the NFT");

        tierNFTFactory.safeTransferFrom(address(this), _receiver, _nftId, _amount, "");

        emit WithdrawNFT(msg.sender, _receiver, _nftId, _amount);
    }

    // Internal functions
    /**
    * @dev Process upgrade
    **/
    function processNFTUpgrade(uint256 _nftIdToUpgrade, uint256 _upgradeToNFTId, uint256 _differenceInPrice) internal {
        // If the wallet holder has not enough tokens, revert the transaction
        if (hasWalletEnoughFSTokens(msg.sender, _differenceInPrice) == false) {
            revert("You need more FantomStarter tokens in your wallet");
        }

        // SafeTransfer the tokens from msg.sender to the dev wallet
        fsToken.safeTransferFrom(msg.sender, devWallet, _differenceInPrice);

        // Transfer the current NFT to the store
        tierNFTFactory.safeTransferFrom(msg.sender, address(this), _nftIdToUpgrade, 1, "");

        // Transfer the NFT to the msg.sender
        if (isStoreOwnerOfNFT(_upgradeToNFTId) == true) {
            // Transfer the store NFT to the upgrade wallet
            tierNFTFactory.safeTransferFrom(address(this), msg.sender, _upgradeToNFTId, 1, "");
        } else {
            // Mint the new NFT to the wallet
            tierNFTFactory.mint(msg.sender, _upgradeToNFTId, 1, "");
        }
    }
}