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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface ITradeCoinBurnerContract {
    struct TradeCoinBurner {
        string product;
        uint256 amount;
        bytes32 unit;
        string defaultTransformation;
    }

    event MintTradeCoinBurner(
        uint256 indexed tokenId,
        address indexed tokenizer,
        string commodity,
        uint256 amount,
        bytes32 unit,
        string defaultTransaction
    );

    function mintToken(
        string memory commodity,
        uint256 amount,
        bytes32 unit,
        string memory defaultTransformation
    ) external;

    function increaseAmount(uint256 tokenId, uint256 amountIncrease) external;

    function decreaseAmount(uint256 tokenId, uint256 amountDecrease) external;

    function updateDefaultTransaction(
        uint256 tokenId,
        string memory defaultTransformation
    ) external;

    function burnToken(uint256 tokenId) external;

    function tradeCoinBurner(uint256 tokenId)
        external
        view
        returns (TradeCoinBurner memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface ITradeCoinContract {
    struct TradeCoin {
        string product;
        uint256 amount; // can be in grams, liters, etc
        bytes32 unit;
        string state;
        address currentHandler;
        string[] transformations;
        bytes32 rootHash;
    }

    struct Documents {
        bytes32[] docHashes;
        bytes32[] docTypes;
        bytes32 rootHash;
    }

    // TODO: Update naming to plural
    struct DynamicFields {
        bytes32 fieldName;
        bytes32 fieldValue;
    }

    struct PendingProductSale {
        address seller;
        address owner;
        address handler;
        bool isPaid;
        uint256 priceInWei;
    }

    event InitialTokenizationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation
    );

    event MintAfterSplitOrBatchEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation
    );

    event ApproveTokenizationEvent(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event InitiateCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed buyer,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash,
        bool payInFiat
    );

    event AddTransformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHashesIndexed,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash,
        int256 weightResult,
        string transformationCode,
        string geoLocation
    );

    event ChangeProductHandlerEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashesIndexed,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash,
        address newCurrentHandler,
        string geoLocation
    );

    event ChangeProductStateEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashesIndexed,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash,
        string newState,
        string geoLocation
    );

    event SplitProductEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] notIndexedTokenIds,
        string geoLocation
    );

    event BatchProductEvent(
        address indexed functionCaller,
        uint256[] notIndexedTokenIds,
        string geoLocation
    );

    event PaymentOfBurnerToken(
        uint256 indexed burnerId,
        address indexed payer,
        uint256 priceInWei
    );

    event WithdrawPayment(
        uint256 indexed burnerId,
        address indexed withdrawer,
        uint256 priceInWei
    );

    event FinishCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32[] dochashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event ServicePaymentEvent(
        uint256 indexed tokenId,
        address indexed receiver,
        address indexed sender,
        bytes32 indexedDocHashes,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash,
        uint256 paymentInWei,
        bool payInFiat
    );

    event BurnEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashesIndexed,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash,
        string geoLocation
    );

    event AddInformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashesIndexed,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event AddValidationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 validationType,
        string description,
        string result,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event UnitConversionEvent(
        uint256 indexed tokenId,
        uint256 indexed amount,
        bytes32 previousAmountUnit,
        bytes32 newAmountUnit
    );

    event InitializeProductSale(
        uint256 indexed burnerId,
        address indexed seller,
        address indexed newOwner,
        address handler,
        uint256 priceInWei,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event MintingProductFromSale(
        uint256 indexed burnerId,
        uint256 indexed productId,
        string product,
        uint256 amount,
        bytes32 unit,
        string firstTransformation,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash,
        string geoLocation
    );

    function initializeProductSale(
        address newOwner,
        address handler,
        uint256 burnerId,
        uint256 priceInWei,
        Documents memory _documents
    ) external;

    function paymentOfToken(uint256 burnerId) external payable;

    function mintingProductFromSale(
        uint256 burnerId,
        string memory _geoLocation,
        Documents memory _documents
    ) external;

    function unitConversion(
        uint256 _tokenId,
        uint256 _amount,
        bytes32 _previousAmountUnit,
        bytes32 _newAmountUnit
    ) external;

    function withdrawPayment(uint256 burnerId) external;

    function initiateCommercialTx(
        uint256 _tokenId,
        uint256 _paymentInWei,
        address _newOwner,
        Documents memory _documents,
        bool _payInFiat
    ) external;

    function addTransformation(
        uint256 _tokenId,
        int256 _weightDifference,
        string memory _transformationCode,
        Documents memory _documents,
        string memory _geoLocation
    ) external;

    function changeProductHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        Documents memory _documents,
        string memory _geoLocation
    ) external;

    function changeProductState(
        uint256 _tokenId,
        string memory _newState,
        Documents memory _documents,
        string memory _geoLocation
    ) external;

    function splitProduct(
        uint256 _tokenId,
        uint256[] memory partitions,
        Documents memory _documents,
        string memory _geoLocation
    ) external;

    function batchProduct(
        uint256[] memory _tokenIds,
        Documents memory _documents,
        string memory _geoLocation
    ) external;

    function finishCommercialTx(uint256 _tokenId, Documents memory _documents)
        external
        payable;

    function servicePayment(
        uint256 _tokenId,
        address _receiver,
        uint256 _paymentInWei,
        bool _payInFiat,
        Documents memory _documents
    ) external payable;

    function addInformation(
        uint256[] memory _tokenIds,
        Documents memory _documents,
        bytes32[] memory _rootHash
    ) external;

    function addValidation(
        uint256 _tokenId,
        bytes32 _type,
        string memory _description,
        string memory _result,
        Documents memory _documents
    ) external;

    function massApproval(uint256[] memory _tokenIds, address to) external;

    function bulkTransferFrom(
        address from,
        address to,
        uint256[] memory _tokenIds
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function getTransformationsByIndex(
        uint256 _tokenId,
        uint256 _transformationIndex
    ) external view returns (string memory);

    function getTransformationsLength(uint256 _tokenId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleControl is AccessControl {
    // We use keccak256 to create a hash that identifies this constant in the contract
    bytes32 public constant TOKENIZER_ROLE = keccak256("TOKENIZER_ROLE"); // hash a MINTER_ROLE as a role constant
    bytes32 public constant PRODUCT_HANDLER_ROLE =
        keccak256("PRODUCT_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant
    bytes32 public constant INFORMATION_HANDLER_ROLE =
        keccak256("INFORMATION_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant

    // Constructor of the RoleControl contract
    constructor(address root) {
        // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
        _setupRole(DEFAULT_ADMIN_ROLE, root); // The creator of the contract is the default admin

        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > MINTER_ROLE > BURNER_ROLE > no role
        _setRoleAdmin(TOKENIZER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCT_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(INFORMATION_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // Create a bool check to see if a account address has the role admin
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender)  is a admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Remove a user as a admin
    function removeAdmin(address account) public virtual onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or Tokenizer
    function isTokenizerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(TOKENIZER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or Tokenizer
    modifier onlyTokenizerOrAdmin() {
        require(
            isTokenizerOrAdmin(msg.sender),
            "Restricted to FTokenizer or admins."
        );
        _;
    }

    // Add a user address as a Tokenizer
    function addTokenizer(address account) public virtual onlyAdmin {
        grantRole(TOKENIZER_ROLE, account);
    }

    // remove a user address as a Tokenizer
    function removeTokenizer(address account) public virtual onlyAdmin {
        revokeRole(TOKENIZER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or ProductHandlers
    function isProductHandlerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(PRODUCT_HANDLER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or ProductHandlers
    modifier onlyProductHandlerOrAdmin() {
        require(
            isProductHandlerOrAdmin(msg.sender),
            "Restricted to ProductHandlers or admins."
        );
        _;
    }

    // Add a user address as a ProductHandlers
    function addProductHandler(address account) public virtual onlyAdmin {
        grantRole(PRODUCT_HANDLER_ROLE, account);
    }

    // remove a user address as a ProductHandlers
    function removeProductHandler(address account) public virtual onlyAdmin {
        revokeRole(PRODUCT_HANDLER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or InformationHandlers
    function isInformationHandlerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(INFORMATION_HANDLER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or InformationHandlers
    modifier onlyInformationHandlerOrAdmin() {
        require(
            isInformationHandlerOrAdmin(msg.sender),
            "Restricted to InformationHandlers or admins."
        );
        _;
    }

    // Add a user address as a InformationHandlers
    function addInformationHandler(address account) public virtual onlyAdmin {
        grantRole(INFORMATION_HANDLER_ROLE, account);
    }

    // remove a user address as a InformationHandlers
    function removeInformationHandler(address account)
        public
        virtual
        onlyAdmin
    {
        revokeRole(INFORMATION_HANDLER_ROLE, account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./interfaces/ITradeCoinContract.sol";
import "./interfaces/ITradeCoinBurnerContract.sol";

import "./RoleControl.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "solmate/src/tokens/ERC721.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

contract TradeCoinContract is
    ERC721,
    RoleControl,
    ReentrancyGuard,
    Multicall,
    ITradeCoinContract
{
    uint256 private _tokenIdCounter;

    modifier onlyLegalOwner(address _sender, uint256 tokenId) {
        require(ownerOf(tokenId) == _sender, "Not Owner");
        _;
    }

    modifier isLegalOwnerOrCurrentHandler(address _sender, uint256 tokenId) {
        require(
            tradeCoin[tokenId].currentHandler == _sender ||
                ownerOf(tokenId) == _sender,
            "Not the Owner nor current Handler."
        );
        _;
    }

    modifier isLegalOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not the Owner.");
        _;
    }

    // Note: contract too big
    // modifier onlyExistingTokens(uint256 tokenId) {
    //     require(tokenId <= _tokenIdCounter, "Token does not exist");
    //     _;
    // }

    address public immutable tradeCoinBurnerContract;

    /// block number in which the contract was deployed.
    uint256 public immutable deployedOn;

    // Mapping for the metadata of the tradecoin
    mapping(uint256 => TradeCoin) public tradeCoin;

    mapping(uint256 => PendingProductSale) public pendingProductSales;
    mapping(uint256 => bool) public pendingWithdrawal;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public paymentInFiat;

    constructor(
        string memory name,
        string memory symbol,
        address _tradeCoinBurnerContract
    ) ERC721(name, symbol) RoleControl(msg.sender) {
        deployedOn = block.number;
        tradeCoinBurnerContract = _tradeCoinBurnerContract;
    }

    function initializeProductSale(
        address newOwner,
        address handler,
        uint256 burnerId,
        uint256 priceInWei,
        Documents memory documents
    ) external override onlyTokenizerOrAdmin {
        require(newOwner != msg.sender, "You can't sell to yourself");
        require(
            IERC721(tradeCoinBurnerContract).ownerOf(burnerId) == msg.sender,
            "You're not the owner of the burner token"
        );

        pendingProductSales[burnerId] = PendingProductSale(
            msg.sender,
            newOwner,
            handler,
            priceInWei == 0,
            priceInWei
        );

        IERC721(tradeCoinBurnerContract).transferFrom(
            msg.sender,
            address(this),
            burnerId
        );

        emit InitializeProductSale(
            burnerId,
            msg.sender,
            newOwner,
            handler,
            priceInWei,
            documents.docHashes,
            documents.docTypes,
            documents.rootHash
        );
    }

    function paymentOfToken(uint256 burnerId) external payable override {
        require(
            pendingProductSales[burnerId].priceInWei == msg.value,
            "Not enough Ether"
        );

        require(
            !pendingProductSales[burnerId].isPaid,
            "Token is already paid for"
        );

        pendingProductSales[burnerId].isPaid = true;

        emit PaymentOfBurnerToken(burnerId, msg.sender, msg.value);
    }

    function mintingProductFromSale(
        uint256 burnerId,
        string memory geoLocation,
        Documents memory documents
    ) external override onlyProductHandlerOrAdmin {
        PendingProductSale memory sale = pendingProductSales[burnerId];
        require(sale.owner != address(0), "Token is not pending for sale");
        require(sale.isPaid, "Token is not payed yet for");
        require(sale.handler == msg.sender, "Not the handler for the sale");

        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;

        ITradeCoinBurnerContract.TradeCoinBurner
            memory burnerToken = ITradeCoinBurnerContract(
                tradeCoinBurnerContract
            ).tradeCoinBurner(burnerId);

        ITradeCoinBurnerContract(tradeCoinBurnerContract).burnToken(burnerId);
        _mint(sale.owner, tokenId);

        string[] memory firstTransformation = new string[](1);
        firstTransformation[0] = burnerToken.defaultTransformation;

        tradeCoin[tokenId] = TradeCoin(
            burnerToken.product,
            burnerToken.amount,
            burnerToken.unit,
            "Storage",
            msg.sender,
            firstTransformation,
            bytes32(0)
        );

        emit MintingProductFromSale(
            burnerId,
            tokenId,
            burnerToken.product,
            burnerToken.amount,
            burnerToken.unit,
            firstTransformation[0],
            documents.docHashes,
            documents.docTypes,
            documents.rootHash,
            geoLocation
        );
    }

    function withdrawPayment(uint256 burnerId) external override {
        uint256 salePrice = pendingProductSales[burnerId].priceInWei;

        require(pendingWithdrawal[burnerId], "Token not minted yet");
        require(
            pendingProductSales[burnerId].seller == msg.sender,
            "Caller is not seller"
        );

        pendingProductSales[burnerId].priceInWei = 0;

        emit WithdrawPayment(burnerId, msg.sender, salePrice);

        payable(msg.sender).transfer(salePrice);
    }

    // Set up sale of token to approve the actual creation of the product
    function initiateCommercialTx(
        uint256 tokenId,
        uint256 paymentInWei,
        address newOwner,
        Documents memory documents,
        bool payInFiat
    ) external override onlyLegalOwner(msg.sender, tokenId) {
        require(msg.sender != newOwner, "You can't sell to yourself");
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );
        if (payInFiat) {
            require(paymentInWei == 0, "Not eth amount");
        } else {
            require(paymentInWei != 0, "Not Fiat amount");
        }
        priceForOwnership[tokenId] = paymentInWei;
        approve(newOwner, tokenId);
        addressOfNewOwner[tokenId] = newOwner;
        paymentInFiat[tokenId] = payInFiat;
        tradeCoin[tokenId].rootHash = documents.rootHash;

        emit InitiateCommercialTxEvent(
            tokenId,
            msg.sender,
            newOwner,
            documents.docHashes,
            documents.docTypes,
            documents.rootHash,
            payInFiat
        );
    }

    function unitConversion(
        uint256 tokenId,
        uint256 newAmount,
        bytes32 previousAmountUnit,
        bytes32 newUnit
    ) external override onlyLegalOwner(msg.sender, tokenId) {
        require(newAmount > 0, "Can't be 0");
        require(previousAmountUnit != newUnit, "Invalid Conversion");
        require(
            previousAmountUnit == tradeCoin[tokenId].unit,
            "Invalid Match: unit"
        );

        tradeCoin[tokenId].amount = newAmount;
        tradeCoin[tokenId].unit = newUnit;

        emit UnitConversionEvent(
            tokenId,
            newAmount,
            previousAmountUnit,
            newUnit
        );
    }

    // Can only be called if Owner or approved account
    function addTransformation(
        uint256 tokenId,
        int256 weightDifference,
        string memory transformationCode,
        Documents memory documents,
        string memory geoLocation
    ) external override isLegalOwnerOrCurrentHandler(msg.sender, tokenId) {
        int256 intValue = int256(tradeCoin[tokenId].amount);

        if (
            keccak256(abi.encodePacked(transformationCode)) ==
            keccak256(abi.encodePacked("Certification"))
        ) {
            require(weightDifference == 0, "Invalid Certification");
        } else {
            require(
                weightDifference != 0 && (intValue + weightDifference) > 0,
                "Invalid weight difference"
            );
        }

        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        tradeCoin[tokenId].transformations.push(transformationCode);
        int256 newAmount = intValue += weightDifference;
        tradeCoin[tokenId].amount = uint256(newAmount);
        tradeCoin[tokenId].rootHash = documents.rootHash;

        emit AddTransformationEvent(
            tokenId,
            msg.sender,
            documents.docHashes[0],
            documents.docHashes,
            documents.docTypes,
            documents.rootHash,
            newAmount,
            transformationCode,
            geoLocation
        );
    }

    function addInformation(
        uint256[] memory tokenIds,
        Documents memory documents,
        bytes32[] memory rootHash
    ) external override onlyInformationHandlerOrAdmin {
        require(tokenIds.length == rootHash.length, "Invalid Length");

        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        for (uint256 tokenId; tokenId < tokenIds.length; tokenId++) {
            tradeCoin[tokenIds[tokenId]].rootHash = rootHash[tokenId];
            emit AddInformationEvent(
                tokenIds[tokenId],
                msg.sender,
                documents.docHashes[0],
                documents.docHashes,
                documents.docTypes,
                rootHash[tokenId]
            );
        }
    }

    function addValidation(
        uint256 tokenId,
        bytes32 validationType,
        string memory description,
        string memory result,
        Documents memory documents
    ) external override {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        emit AddValidationEvent(
            tokenId,
            msg.sender,
            validationType,
            description,
            result,
            documents.docHashes,
            documents.docTypes,
            documents.rootHash
        );
    }

    function changeProductHandler(
        uint256 tokenId,
        address newCurrentHandler,
        Documents memory documents,
        string memory geoLocation
    ) external override isLegalOwner(tokenId) {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        tradeCoin[tokenId].currentHandler = newCurrentHandler;
        tradeCoin[tokenId].rootHash = documents.rootHash;

        emit ChangeProductHandlerEvent(
            tokenId,
            msg.sender,
            documents.docHashes[0],
            documents.docHashes,
            documents.docTypes,
            documents.rootHash,
            newCurrentHandler,
            geoLocation
        );
    }

    function changeProductState(
        uint256 tokenId,
        string memory newState,
        Documents memory documents,
        string memory geoLocation
    ) external override isLegalOwnerOrCurrentHandler(msg.sender, tokenId) {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        tradeCoin[tokenId].state = newState;
        tradeCoin[tokenId].rootHash = documents.rootHash;

        emit ChangeProductStateEvent(
            tokenId,
            msg.sender,
            documents.docHashes[0],
            documents.docHashes,
            documents.docTypes,
            documents.rootHash,
            newState,
            geoLocation
        );
    }

    function splitProduct(
        uint256 tokenId,
        uint256[] memory partitions,
        Documents memory documents,
        string memory geoLocation
    ) external override onlyLegalOwner(msg.sender, tokenId) {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        // create temp list of tokenIds
        uint256[] memory tempArray = new uint256[](partitions.length + 1);
        tempArray[0] = tokenId;
        // create temp struct
        TradeCoin memory temporaryStruct = tradeCoin[tokenId];

        uint256 sumPartitions;
        for (uint256 x; x < partitions.length; x++) {
            require(partitions[x] != 0, "Partitions can't be 0");
            sumPartitions += partitions[x];
        }

        require(
            tradeCoin[tokenId].amount == sumPartitions,
            "Incorrect sum of amount"
        );

        burn(tokenId, documents, geoLocation);
        for (uint256 i; i < partitions.length; i++) {
            mintAfterSplitOrBatch(
                temporaryStruct.product,
                partitions[i],
                temporaryStruct.unit,
                temporaryStruct.state,
                temporaryStruct.currentHandler,
                temporaryStruct.transformations,
                geoLocation
            );
            tempArray[i + 1] = _tokenIdCounter;
        }

        emit SplitProductEvent(tokenId, msg.sender, tempArray, geoLocation);
        delete temporaryStruct;
    }

    function batchProduct(
        uint256[] memory tokenIds,
        Documents memory documents,
        string memory geoLocation
    ) external override {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        bytes32 emptyHash;
        uint256 cummulativeAmount;
        TradeCoin memory short = TradeCoin({
            product: tradeCoin[tokenIds[0]].product,
            state: tradeCoin[tokenIds[0]].state,
            currentHandler: tradeCoin[tokenIds[0]].currentHandler,
            transformations: tradeCoin[tokenIds[0]].transformations,
            amount: 0,
            unit: tradeCoin[tokenIds[0]].unit,
            rootHash: emptyHash
        });

        bytes32 hashed = keccak256(abi.encode(short));

        uint256[] memory tempArray = new uint256[](tokenIds.length + 1);

        for (uint256 tokenId; tokenId < tokenIds.length; tokenId++) {
            require(ownerOf(tokenIds[tokenId]) == msg.sender, "Unauthorized");

            TradeCoin memory short2 = TradeCoin({
                product: tradeCoin[tokenIds[tokenId]].product,
                state: tradeCoin[tokenIds[tokenId]].state,
                currentHandler: tradeCoin[tokenIds[tokenId]].currentHandler,
                transformations: tradeCoin[tokenIds[tokenId]].transformations,
                amount: 0,
                unit: tradeCoin[tokenIds[tokenId]].unit,
                rootHash: emptyHash
            });
            require(hashed == keccak256(abi.encode(short2)), "Invalid PNFT");

            tempArray[tokenId] = tokenIds[tokenId];
            // create temp struct
            cummulativeAmount += tradeCoin[tokenIds[tokenId]].amount;
            burn(tokenIds[tokenId], documents, geoLocation);
        }
        mintAfterSplitOrBatch(
            short.product,
            cummulativeAmount,
            short.unit,
            short.state,
            short.currentHandler,
            short.transformations,
            geoLocation
        );
        tempArray[tokenIds.length] = _tokenIdCounter;

        emit BatchProductEvent(msg.sender, tempArray, geoLocation);
    }

    function finishCommercialTx(uint256 tokenId, Documents memory documents)
        external
        payable
        override
        nonReentrant
    {
        require(addressOfNewOwner[tokenId] == msg.sender, "Unauthorized");

        require(priceForOwnership[tokenId] <= msg.value, "Insufficient funds");

        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        address legalOwner = ownerOf(tokenId);

        // When not paying in Fiat pay but in Eth
        if (!paymentInFiat[tokenId]) {
            require(priceForOwnership[tokenId] != 0, "Not for sale");
            payable(legalOwner).transfer(msg.value);
        }
        // else transfer
        transferFrom(legalOwner, msg.sender, tokenId);

        // Change state and delete memory
        delete priceForOwnership[tokenId];
        delete addressOfNewOwner[tokenId];

        emit FinishCommercialTxEvent(
            tokenId,
            legalOwner,
            msg.sender,
            documents.docHashes,
            documents.docTypes,
            documents.rootHash
        );
    }

    function servicePayment(
        uint256 tokenId,
        address receiver,
        uint256 paymentInWei,
        bool payInFiat,
        Documents memory documents
    ) external payable override nonReentrant {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        // When not paying in Fiat pay but in Eth
        if (!payInFiat) {
            require(
                paymentInWei >= msg.value && paymentInWei > 0,
                "Promised to pay in Fiat"
            );
            payable(receiver).transfer(msg.value);
        }

        emit ServicePaymentEvent(
            tokenId,
            receiver,
            msg.sender,
            documents.docHashes[0],
            documents.docHashes,
            documents.docTypes,
            documents.rootHash,
            paymentInWei,
            payInFiat
        );
    }

    function massApproval(uint256[] memory tokenIds, address to)
        external
        override
    {
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "You are not the owner"
            );
            approve(to, tokenIds[i]);
        }
    }

    function bulkTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external override {
        uint256 lengthOfIds = tokenIds.length;

        for (uint256 i; i < lengthOfIds; ) {
            transferFrom(from, to, tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    function burn(
        uint256 tokenId,
        Documents memory documents,
        string memory geoLocation
    ) public virtual onlyLegalOwner(msg.sender, tokenId) {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        _burn(tokenId);

        emit BurnEvent(
            tokenId,
            msg.sender,
            documents.docHashes[0],
            documents.docHashes,
            documents.docTypes,
            documents.rootHash,
            geoLocation
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, ITradeCoinContract)
        returns (bool)
    {
        return
            type(ITradeCoinContract).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getTransformationsByIndex(
        uint256 tokenId,
        uint256 transformationIndex
    ) public view override returns (string memory) {
        return tradeCoin[tokenId].transformations[transformationIndex];
    }

    function getTransformationsLength(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return tradeCoin[tokenId].transformations.length;
    }

    // This function will mint a token to
    function mintAfterSplitOrBatch(
        string memory product,
        uint256 amount,
        bytes32 unit,
        string memory state,
        address currentHandler,
        string[] memory transformations,
        string memory geoLocation
    ) internal {
        require(amount != 0, "Insufficient Amount");

        _tokenIdCounter++;
        uint256 id = _tokenIdCounter;

        // Mint new token
        _mint(msg.sender, id);
        // Store data on-chain
        tradeCoin[id] = TradeCoin(
            product,
            amount,
            unit,
            state,
            currentHandler,
            transformations,
            bytes32(0)
        );
        // Fire off the event
        emit MintAfterSplitOrBatchEvent(id, msg.sender, geoLocation);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "TradeCoin";
    }
}
// New functionality should be more thought out as we reached maximum capacity

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}