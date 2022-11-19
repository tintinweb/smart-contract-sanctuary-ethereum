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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "../../mQuarkV5/ParamsLib.sol";

// library ParamsLib {
//   struct CollectionParams {
//     uint256 projectId;
//     uint256[] templateIds;
//     uint256[] collectionIds;
//     uint8[] amounts;
//   }
// }

interface ImQuark {
  function setAuthorizedContract(address contractAddress) external;

  function setRoyalty(address receiver, uint256 royaltyPercentage) external;

  function removeAuthorizedContract(address contractAddress) external;

  function createTemplate(string calldata uri) external;

  function createBatchTemplate(string[] calldata uris) external;

  //Single Token => Single Metaverse
  function addMetadataSlotToNFT(
    address owner,
    uint256 tokenId,
    uint256 projectId,
    string calldata projectDefaultUri
  ) external;

  //Single Token => Multiple Metaverses
  function addBatchURISlotsToNFT(
    address owner,
    uint256 tokenId,
    uint256[] calldata projectIds,
    string[] calldata projectDefaultUris
  ) external;

  //Multiple Tokens => Single Metaverse
  function addBatchURISlotToNFTs(
    address owner,
    uint256[] calldata tokenIds,
    uint256 projectId,
    string calldata projectMetadataTemplate
  ) external;

  function updateURISlot(
    address owner,
    bytes calldata signature,
    address projectWallet,
    uint256 projectId,
    uint256 tokenId,
    string calldata newURI
  ) external;

  function resetMetaverseURI(
    uint256 tokenId,
    uint256 projectId,
    string calldata projectTemplate
  ) external;

  //Single minting with no metadata
  function mint(
    address to,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId
  ) external;

  //Multiple Tokens with no metadata
  // function mintBatch(
  //   address to,
  //   ParamsLib.CollectionParams calldata collectionParams
  // ) external;
  function mintBatch(
    address to,
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts
  ) external;

  //Multiple Token with single metadata slot
  function mintBatchWithURISlot(
    address to,
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts,
    string calldata projectDefaultUri
  ) external;

  //Single Token with multiple Metadata slots
  function mintWithURISlots(
    address to,
    uint256 templateId,
    uint256 collectionId,
    uint256[] calldata projectIds,
    string[] calldata projectDefaultUris
  ) external;

  function createCollections(
    uint256 projectId,
    address _admin,
    uint256[] calldata _templateIds,
    uint16[] calldata amounts,
    bytes[] calldata signatures,
    string[] calldata uris
  ) external;

  function tokenURI(uint256 tokenId) external view returns (string memory);

  // function setMetadataForCollections(
  //   bytes[] calldata signatures,
  //   address admin,
  //   address project,
  //   uint256[] memory templateIds,
  //   uint256[] memory collectionIds,
  //   string[] calldata uris
  // ) external ;

  function getCreatedBaseIds() external view returns (uint256[] memory);

  function royaltyInfo(
    uint256, /*_tokenId*/
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/mQuark/ImQuark.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";

///@notice protect withdrawPayment with nonReentrant modifier in PullPayment
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract mQuarkControl is ReentrancyGuard, PullPayment, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;

  ///=============================================================
  //                        Events
  //==============================================================
  event ProjectRegistered(
    address project,
    address creator,
    uint256 projectId,
    string projectName,
    string creatorName,
    string thumbnail,
    string projectDefaultSlotURI
  );
  event MintBatchSlotFundsDeposit(
    uint256 amount,
    uint256 creatorPercentage,
    uint256[] projectId,
    uint256[] projectsShares
  );
  event BatchSlotFundsDeposit(uint256 amount, uint256 creatorPercentage, uint256[] projectId, uint256[] projectsShares);
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);
  event SlotPriceSet(uint256 projectId, uint256 price);
  event AuthorizedToRegisterWalletSet(address wallet, bool isAuthorized);
  event ProjectRemoved(uint256 projectId);
  event FundsDeposit(uint256 amount, uint256 creatorPercentage, uint256 projectId);
  event FundsWithdrawn(address mquark, uint256 amount);
  event ProjectFundsWithdrawn(uint256 projectId, uint256 amount);
  event MQuarkSet(address mquark);
  event CreatorPercentageSet(uint256 percentage);

  ///=============================================================
  //                        Modifiers
  //==============================================================

  modifier onlyAdmin() {
    require(admin == msg.sender, "not authorized");
    _;
  }

  modifier onlyAuthorized() {
    require(authorizedToRegisterProject[msg.sender] == true, "not authorized");
    _;
  }

  ///=============================================================
  //                        State Variables
  //==============================================================

  // struct ProjectParams {
  //   uint256[] projectIds;
  //   address[] projects;
  // }
  /**
   * Struct of Registered Project
   * @param wallet: Wallet address of project
   * @param creator: Creator wallet address
   * @param id: Unique id
   * @param projectSlotDefaultURI: Project default metadata schema
   */
  struct Project {
    address wallet;
    address creator;
    uint256 id;
    uint256 balance;
    string name;
    string thumbnail;
    string projectSlotDefaultURI;
  }

  ///@dev Stores admin address of the contract
  address public admin;

  ///@dev The last registered project id
  uint256 public projectIdIndex;

  ///@dev Percentage of creators from minting or add,ing metadata slot
  uint256 public creatorPercentage;

  ///@dev Percentage of admin from minting or adding metadata slot
  uint256 public adminPercentage;

  ///@dev Limits the select of the templates to the amount to prevent out of gas error
  uint16 constant MAX_SELECTING_LIMIT = 350;

  ///@dev ERC721 contract interface
  ImQuark public mQuark;

  ///@dev Stores projects wallet address that are registered to the project
  EnumerableSet.AddressSet private projectWallets;

  ///@dev Verifier address; see setMetadataForCollections
  address public verifier;

  ///@dev This role will be used to check signatures validity.
  bytes32 public constant SIGNATURE_VERIFIER_ROLE = keccak256("SIGNATURE_VERIFIER");

  ///=============================================================
  //                         Mappings
  //==============================================================

  /**
   *  @dev Mapping from 'admin address' to balance
   **/
  mapping(address => uint256) public adminBalance;

  /**
   *  @dev Mapping from 'Project address' to Project Struct
   **/
  mapping(uint256 => Project) public registeredProjects;

  /**
   *  @dev Returns Projects' Registered ID
   **/
  mapping(address => uint256) public projectIds;

  /**
   *  @dev Mapping from 'Project address' to a boolean
   **/
  ///@dev This approved wallets can register projects
  mapping(address => bool) public authorizedToRegisterProject;

  /**
   *  @dev Mapping from 'Template ID' to Mint Price in Wei
   **/
  mapping(uint256 => uint256) public templateMintPrices;

  /**
   *  @dev Mapping from 'Project Address' to Metadata Add Price
   **/
  mapping(uint256 => uint256) public projectSlotPrices;

  ///=============================================================
  //                        CONSTRUCTOR
  //==============================================================

  constructor() {
    admin = msg.sender;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  ///=============================================================
  //                        EXTERNALS
  //==============================================================

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to mint single NFT.
   *@param projectId: Pproject ID which is given during registration
   *@param templateId: Template ID of selected collection
   *@param collectionId: Index of selected collection
   */
  function mint(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId
  ) external payable nonReentrant {
    //* require(templateId != 0, "invalid template id"); ****
    require(registeredProjects[projectId].id != 0, "unregistered project");
    require(msg.value == templateMintPrices[templateId], "sent value is wrong");
    require(msg.value != 0, "sent value is zero");
    mQuark.mint(msg.sender, projectId, templateId, collectionId);

    registeredProjects[projectId].balance += (msg.value * creatorPercentage) / 100;
    adminBalance[admin] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, creatorPercentage, projectId);
  }

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to mint multiple NFT.
   *
   *@ collectionParams:  struct MintParams {
   *                       uint256   projectId: Project wallet address
   *                       uint256[] templateIds : Selected Template IDs
   *                       uint256[] collectionIds : IDs of selected Template IDs in the project;
   *                       uint8[] amounts: Selected Amount for each Template;
   *                     }
   *@dev Each index will be matched to each other in given arrays, thus order of array indexes matters.
   */
  // function mintBatch(ParamsLib.CollectionParams calldata collectionParams)
  function mintBatch(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts
  ) external payable nonReentrant {
    require(registeredProjects[projectId].id != 0, "unregistered project");
    require(templateIds.length == amounts.length, "amount mismatch");
    require(templateIds.length <= 20, "minting more than limit");
    require(this.calculateMintBatchTotalPrice(templateIds, amounts) == msg.value, "sent value is wrong");
    require(msg.value != 0, "sent value is zero");

    // mQuark.mintBatch(msg.sender, mintParams.project, mintParams);
    mQuark.mintBatch(msg.sender, projectId, templateIds, collectionIds, amounts);
    registeredProjects[projectId].balance += (msg.value * creatorPercentage) / 100;
    adminBalance[admin] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, creatorPercentage, projectId);
  }

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to mint multiple NFTs with a single specified metadata slot
   *@ collectionParams:  struct MintParams {
   *                       uint256   projectId: Project wallet address
   *                       uint256[] templateIds : Selected Template IDs
   *                       uint256[] collectionIds : IDs of selected Template IDs in the project;
   *                       uint8[] amounts: Selected Amount for each Template;
   *                     }
   *@dev Each index will be matched to each other in given arrays, thus order of array indexes matters.
   */
  function mintBatchWithURISlot(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts
  ) external payable nonReentrant {
    require(templateIds.length == collectionIds.length, "collection mismatch");
    require(templateIds.length == amounts.length, "amount mismatch");
    require(registeredProjects[projectId].id != 0, "unregistered project");
    // require(registeredProjects[projectId].id == _projectId, "project id mismatch");
    // require(registeredProjects[projectId].wallet == projectId, "wallet mismatch");
    
    // require(
    //   (this.calculateMintBatchTotalPrice(templateIds, amounts) + this.calculateBatchSlotPrice(projectId, amounts)) ==
    //     msg.value,
    //   "sent value is wrong"
    // );
    require(this.calculateMintBatchWithSlotPrice(projectId,templateIds,amounts) == msg.value, "sent value is wrong");

    mQuark.mintBatchWithURISlot(
      msg.sender,
      projectId,
      templateIds,
      collectionIds,
      amounts,
      registeredProjects[projectId].projectSlotDefaultURI
    );

    registeredProjects[projectId].balance += (msg.value * creatorPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;
    emit FundsDeposit(msg.value, creatorPercentage, projectId);
  }

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to mint single NFT with multiple specified metadata slots.
   *@param templateId: IDs of Templates which are categorized NFTs.
   *@param collectionId: ID for the created collection.
   *@param _projectIds:   struct ProjectParams {
   *                                uint256[] projectIds: The number of mints for each IDs.
   *                                address[] projects: Project wallet addresses(Address at index zero, gets the mint price).
   *                          }
   */
  function mintWithURISlots(
    uint256 templateId,
    uint256 collectionId,
    uint256[] calldata _projectIds
  ) external payable nonReentrant {
    require(_projectIds.length < 256, "minting more than limit");
    require(templateMintPrices[templateId] > 0, "minting zero value NFT");

    string[] memory _projectMetadataTemplate = new string[](_projectIds.length);
    uint256 _totalMetadataSlotPriceAmount;
    uint256 _metadataSlotPrice;
    uint256[] memory _projectsMetedataPriceShares = new uint256[](_projectIds.length);

    uint256 projectCount = _projectIds.length;
    for (uint8 i; i < projectCount; ) {
      require(registeredProjects[_projectIds[i]].id == _projectIds[i], "unregistered project");
      require(projectSlotPrices[_projectIds[i]] > 0, "slot value is zero");
      _metadataSlotPrice = projectSlotPrices[_projectIds[i]];
      _projectMetadataTemplate[i] = (registeredProjects[_projectIds[i]].projectSlotDefaultURI);
      _totalMetadataSlotPriceAmount += _metadataSlotPrice;
      registeredProjects[_projectIds[i]].balance += (_metadataSlotPrice * creatorPercentage) / 100;
      _projectsMetedataPriceShares[i] = _metadataSlotPrice;

      unchecked {
        ++i;
      }
    }
    uint256 _templateMintPrice = templateMintPrices[templateId];
    require(msg.value == (_totalMetadataSlotPriceAmount + _templateMintPrice), "sent value is wrong");

    mQuark.mintWithURISlots(msg.sender, templateId, collectionId, _projectIds, _projectMetadataTemplate);
    registeredProjects[_projectIds[0]].balance += ((_templateMintPrice * creatorPercentage) / 100);
    adminBalance[admin] += ((msg.value * adminPercentage) / 100);

    /** @notice Base mint price should be considered at zero index! */
    emit MintBatchSlotFundsDeposit(msg.value, creatorPercentage, _projectIds, _projectsMetedataPriceShares);
  }

  ///=============================================================
  //                        METADATA
  //==============================================================

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to add single NFT metadata slot to single NFT
   *@param tokenId: Token ID of the NFT
   *@param projectId: Number of mint from each ID
   */
  function addURISlotToNFT(uint256 tokenId, uint256 projectId) external payable nonReentrant {
    require(registeredProjects[projectId].id == projectId, "unregistered project");
    require(projectSlotPrices[projectId] == msg.value, "sent value is wrong");
    require(msg.value != 0, "sent value is zero");

    mQuark.addMetadataSlotToNFT(msg.sender, tokenId, projectId, registeredProjects[projectId].projectSlotDefaultURI);
    registeredProjects[projectId].balance += (msg.value * creatorPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;

    emit FundsDeposit(msg.value, creatorPercentage, projectId);
  }

  /** Single Token => Multiple Projects
   *Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to add multiple metadata slots to single NFT
   *@param tokenId: Token ID of the NFT
   *@param _projectIds:
   *@notice If reverts, costs gas!
   */
  function addBatchURISlotsToNFT(uint256 tokenId, uint256[] calldata _projectIds) external payable nonReentrant {
    string[] memory _projectMetadataTemplate = new string[](_projectIds.length);
    uint256 _price;
    uint256 _totalAmount;
    uint256[] memory _projectsShares = new uint256[](_projectIds.length);
    uint256 _projects = _projectIds.length;

    for (uint256 i; i < _projects; ) {
      require(registeredProjects[_projectIds[i]].id == _projectIds[i], "unregistered project");
      require(projectSlotPrices[_projectIds[i]] > 0, "slot value is zero");
      _price = projectSlotPrices[_projectIds[i]];
      _projectMetadataTemplate[i] = (registeredProjects[_projectIds[i]].projectSlotDefaultURI);
      _totalAmount += _price;
      registeredProjects[_projectIds[i]].balance += (_price * creatorPercentage) / 100;
      _projectsShares[i] = _price;
      unchecked {
        ++i;
      }
    }

    require(msg.value == _totalAmount, "sent value is wrong");

    adminBalance[admin] += (msg.value * adminPercentage) / 100;
    mQuark.addBatchURISlotsToNFT(msg.sender, tokenId, _projectIds, _projectMetadataTemplate);
    emit BatchSlotFundsDeposit(msg.value, creatorPercentage, _projectIds, _projectsShares);
  }

  /**Multiple Tokens => Single Project
   *Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to add the same single metadata slot to multiple NFTs
   *@param tokenIds: Token IDs of NFTs
   *@param projectId: Number of mint from each IDs
   */
  function addBatchURISlotToNFTs(uint256[] calldata tokenIds, uint256 projectId) external payable nonReentrant {
    require(registeredProjects[projectId].id == projectId, "unregistered project");
    require((projectSlotPrices[projectId] * tokenIds.length) == msg.value, "sent value is wrong");
    require(msg.value != 0, "sent value is zero");

    mQuark.addBatchURISlotToNFTs(msg.sender, tokenIds, projectId, registeredProjects[projectId].projectSlotDefaultURI);

    registeredProjects[projectId].balance += (msg.value * creatorPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;

    emit FundsDeposit(msg.value, creatorPercentage, projectId);
  }

  /*============================================================================================================*/

  /**
   *
   *
   *@param signature: IDs of Templates which are categorized NFTs
   *@param projectWallet: Project wallet addresses
   *@param projectId: Number of mint from each IDs
   *@param tokenId: Token ID of the NFT
   *@param newURI: New URI which will be replaced with old URI
   */
  function updateURISlot(
    bytes calldata signature,
    address projectWallet,
    uint256 projectId,
    uint256 tokenId,
    string calldata newURI
  ) external {
    Project memory _registeredProject = registeredProjects[projectId];

    require(_registeredProject.wallet == projectWallet, "wrong project wallet");
    require(_registeredProject.id == projectId, "wrong project id");
    require(_registeredProject.wallet != address(0), "unregistered project");

    mQuark.updateURISlot(msg.sender, signature, projectWallet, projectId, tokenId, newURI);
  }

  /**
   *Resets NFT's project metadata URI to default
   *@notice This function is not completed yet!
   */
  function resetProjectURISlot(
    uint256, /* tokenId */
    address, /* project */
    uint256 projectId
  ) external view {
    require(msg.sender == registeredProjects[projectId].wallet, "unauthorized access");
    require(registeredProjects[projectId].id == projectId, "unregistered project");

    // mQuark.resetProjectURI(tokenId, projectId, registeredProjects[project].projectSlotDefaultURI);
  }

  /**
   *Via this function Projects can be registered to the contract.
   *@param project: Project Wallet
   *@param creator: Creator wallet of the project
   *@param projectName: Project Name
   *@param creatorName: Company name of the project
   *@param thumbnail: Image URL
   *@param projectSlotDefaultURI: Project default metadata.
   */
  function registerProject(
    address project,
    address creator,
    string calldata projectName,
    string calldata creatorName,
    string calldata thumbnail,
    string calldata projectSlotDefaultURI
  ) external onlyAuthorized {
    require(!projectWallets.contains(project), "already registered");

    unchecked {
      uint256 _projectId = ++projectIdIndex;
      registeredProjects[_projectId] = Project(
        project,
        creator,
        _projectId,
        registeredProjects[_projectId].balance,
        projectName,
        thumbnail,
        projectSlotDefaultURI
      );
      projectWallets.add(project);
      projectIds[project] = _projectId;
      emit ProjectRegistered(project, creator, _projectId, projectName, creatorName, thumbnail, projectSlotDefaultURI);
    }
  }

  /**
   *Removes registered project from the contract
   *@param prjectId: Wallet address of registered project
   */
  function removeProject(uint256 prjectId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(registeredProjects[prjectId].id != 0, "deleting unregistered project");

    registeredProjects[prjectId].wallet = address(0);
    registeredProjects[prjectId].creator = address(0);
    registeredProjects[prjectId].id = 0;
    registeredProjects[prjectId].name = "";
    registeredProjects[prjectId].thumbnail = "";
    registeredProjects[prjectId].projectSlotDefaultURI = "";
    projectWallets.remove(registeredProjects[prjectId].wallet);

    emit ProjectRemoved(prjectId);
  }

  ///=============================================================
  //                        SET-SELECT
  //==============================================================

  /**
   *Sets the address of deployed NFT contract
   *@param _mQuarkAddress: Contract address of NFT Contract
   */
  function setmQuark(address _mQuarkAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    mQuark = ImQuark(_mQuarkAddress);
    emit MQuarkSet(_mQuarkAddress);
  }

  /**
    Sets a wallet as authorized or unauthorized to register projects
    *@param wallet: Wallet address that will be set
    *@param isAuthorized: Boolean value
  */
  function setAuthorizedToRegister(address wallet, bool isAuthorized) external onlyRole(DEFAULT_ADMIN_ROLE) {
    authorizedToRegisterProject[wallet] = isAuthorized;
    emit AuthorizedToRegisterWalletSet(wallet, isAuthorized);
  }

  /**
   *Sets Templates mint prices for projects
   *@param templateIds: IDs of Templates which are categorized NFTs
   *@param prices: Prices of each given templates in wei unit
   */
  function setTemplatePrices(uint256[] calldata templateIds, uint256[] calldata prices)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(templateIds.length == prices.length, "ids and prices mismatch");
    uint256 _templateIdsLength = templateIds.length;
    for (uint256 i; i < _templateIdsLength; ) {
      templateMintPrices[templateIds[i]] = prices[i];
      unchecked {
        ++i;
      }
    }
    emit TemplatePricesSet(templateIds, prices);
  }

  // function setMetadataForCollections(
  //   bytes[] calldata signatures,
  //   address wallet,
  //   uint256[] memory templateIds,
  //   uint256[] memory collectionIds,
  //   string[] calldata uris
  // ) external nonReentrant {
  //   require(registeredProjects[wallet].creator == msg.sender || registeredProjects[msg.sender].wallet == msg.sender, "unauthorized access");
  //   mQuark.setMetadataForCollections(signatures, verifier, wallet, templateIds, collectionIds, uris);
  // }

  /**
   *Sets Templates mint prices for projects
   *@param templateIds: IDs of Templates which are categorized NFTs
   *@param amounts: Amount of selected templates
   */
  function createCollections(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint16[] calldata amounts,
    bytes[] calldata signatures,
    string[] calldata uris
  ) external {
    require(
      registeredProjects[projectId].creator == msg.sender || registeredProjects[projectId].wallet == msg.sender,
      "unauthorized access"
    );
    uint256 _templatesLength = templateIds.length;
    require(_templatesLength < 50, "templates selected more than limit");
    require(_templatesLength == amounts.length, "length mismatch");

    uint16 _maxSelectingLimit = MAX_SELECTING_LIMIT;
    for (uint256 i; i < _templatesLength; ) {
      require(templateMintPrices[templateIds[i]] > 0, "selected invalid template");
      require(amounts[i] < _maxSelectingLimit, "amount selected more than limit");
      unchecked {
        ++i;
      }
    }

    mQuark.createCollections(projectId, verifier, templateIds, amounts, signatures, uris);
  }

  /**
   *Sets projects percantage from minting and metadata slot purchases
   *@param percentage: Percantage amount
   *@notice Amount should be between 0-100
   */
  function setCreatorPercentage(uint256 percentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(percentage <= 100, "invalid value");
    creatorPercentage = percentage;
    adminPercentage = (100 - percentage);
    emit CreatorPercentageSet(percentage);
  }

  /**
   *Sets a project's metadata slot adding price for each template
   *@param price: Price in wei unit
   *@notice Amount should be between 0-100
   */
  function setProjectURISlotPrice(uint256 projectId, uint256 price) external {
    require(
      registeredProjects[projectId].creator == msg.sender || registeredProjects[projectId].wallet == msg.sender,
      "unauthorized access"
    );
    projectSlotPrices[projectId] = price;
    emit SlotPriceSet(projectId, price);
  }

  function setVerifierAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
    verifier = _address;
  }

  ///=============================================================
  //                        TRANSFERS
  //==============================================================

  /**
   *@dev Admin of this contract transfers the amount. Uses {PullPayment} method of Oppenzeppelin.
   *@param amount: Amount of funds that will be withdrawn in wei
   */
  function transferFunds(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(amount <= adminBalance[msg.sender], "insufficient balance");
    adminBalance[msg.sender] -= amount;
    _asyncTransfer(msg.sender, amount);
    emit FundsWithdrawn(msg.sender, amount);
  }

  /**
   *Projects can withdraw their balance using this function
   *@param project: Project registered wallet address
   *@param amount: Amount of funds that will be withdrawn in wei
   */
  function projectTransferFunds(
    address payable project,
    uint256 projectId,
    uint256 amount
  ) external {
    require(
      registeredProjects[projectId].creator == msg.sender || registeredProjects[projectId].wallet == msg.sender,
      "unauthorized access"
    );
    require(amount <= registeredProjects[projectId].balance, "insufficient balance");
    registeredProjects[projectId].balance -= amount;
    _asyncTransfer(project, amount);
    emit ProjectFundsWithdrawn(projectId, amount);
  }

  ///=============================================================
  //                        VIEWS
  //==============================================================

  /**
   *Calculates and returns templates batch mint price
   *@param templateIds: IDs of Templates which are categorized NFTs
   *@param amounts: Amount of each IDs
   *@return totalAmount Calculated total amount of IDs for a project
   */
  function calculateMintBatchTotalPrice(uint256[] calldata templateIds, uint8[] calldata amounts)
    external
    view
    returns (uint256 totalAmount)
  {
    uint256 _templateIdsLength = templateIds.length;
    for (uint8 i; i < _templateIdsLength; ) {
      require(templateIds[i] != 0 && amounts[i] != 0, "invalid id/amount");
      totalAmount += (templateMintPrices[templateIds[i]] * amounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   *Calculates and returns project matadata slots
   *@param amounts: Amounts of tokens
   *@param projectId: Project Id
  */
  function calculateBatchSlotPrice(uint256 projectId, uint8[] calldata amounts)
    external
    view
    returns (uint256 totalAmount)
  {
    require(projectSlotPrices[projectId] > 0, "slot value is zero");
    uint256 _amountsLength = amounts.length;
    for (uint8 i; i < _amountsLength; ) {
      totalAmount += (projectSlotPrices[projectId] * amounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  function calculateMintBatchWithSlotPrice(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint8[] calldata amounts
  ) external view returns (uint256) {
    uint256 _slotPrice = this.calculateBatchSlotPrice(projectId,amounts);
    uint256 _mintPrices = this.calculateMintBatchTotalPrice(templateIds, amounts);
    return (_slotPrice + _mintPrices);
  }

  function calculateMintWithURISlotsPrice(uint256 templateId, uint256[] calldata _projectIds)
    public
    view
    returns (uint256)
  {
    uint256 _mintPrice = templateMintPrices[templateId];
    uint256 _slotPrices;
    for (uint256 i = 0; i < _projectIds.length; i++) _slotPrices += projectSlotPrices[_projectIds[i]];
    return (_mintPrice + _slotPrices);
  }

}