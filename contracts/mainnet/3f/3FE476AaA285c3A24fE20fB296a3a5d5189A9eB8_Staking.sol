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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    Staking private _stakingLogic;
    StakingStorage private _astoStorage;
    StakingStorage private _lpStorage;
    Converter private _converterLogic;
    EnergyStorage private _energyStorage;
    EnergyStorage private _lbaEnergyStorage;
    IERC20 private _astoToken;
    IERC20 private _lpToken;
    address private _dao;
    address private _multisig;

    bool private _initialized;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    event ContractUpgraded(uint256 timestamp, string contractName, address oldAddress, address newAddress);

    constructor(address multisig) {
        if (!_isContract(multisig)) revert InvalidInput(INVALID_MULTISIG);
        /**
         * MULTISIG_ROLE is ONLY used for:
         * - initalisation controller
         * - setting periods (mining cycles) for the Converter contract
         */
        _grantRole(MULTISIG_ROLE, multisig);
        _grantRole(DAO_ROLE, multisig);
        _multisig = multisig;
    }

    function init(
        address dao,
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) external onlyRole(MULTISIG_ROLE) {
        if (!_initialized) {
            if (!_isContract(dao)) revert InvalidInput(INVALID_DAO);
            if (!_isContract(astoToken)) revert InvalidInput(INVALID_ASTO_CONTRACT);
            if (!_isContract(astoStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
            if (!_isContract(lpToken)) revert InvalidInput(INVALID_LP_CONTRACT);
            if (!_isContract(lpStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
            if (!_isContract(stakingLogic)) revert InvalidInput(INVALID_STAKING_LOGIC);
            if (!_isContract(converterLogic)) revert InvalidInput(INVALID_CONVERTER_LOGIC);
            if (!_isContract(energyStorage)) revert InvalidInput(INVALID_ENERGY_STORAGE);
            if (!_isContract(lbaEnergyStorage)) revert InvalidInput(INVALID_ENERGY_STORAGE);
            _clearRole(DAO_ROLE);
            _grantRole(DAO_ROLE, dao);

            // Saving addresses on init:
            _dao = dao;
            _astoToken = IERC20(astoToken);
            _astoStorage = StakingStorage(astoStorage);
            _lpToken = IERC20(lpToken);
            _lpStorage = StakingStorage(lpStorage);
            _stakingLogic = Staking(stakingLogic);
            _converterLogic = Converter(converterLogic);
            _energyStorage = EnergyStorage(energyStorage);
            _lbaEnergyStorage = EnergyStorage(lbaEnergyStorage);

            // Initializing contracts
            _upgradeContracts(
                astoToken,
                astoStorage,
                lpToken,
                lpStorage,
                stakingLogic,
                converterLogic,
                energyStorage,
                lbaEnergyStorage
            );
            _initialized = true;
        }
    }

    /** ----------------------------------
     * ! Private functions | Setters
     * ----------------------------------- */

    /**
     * @notice Each contract has own params to initialize
     * @notice Contracts with no address specified will be skipped
     * @dev Internal functions, can be called from constructor OR
     * @dev after authentication by the public function `upgradeContracts()`
     */
    function _upgradeContracts(
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) internal {
        if (_isContract(astoToken)) _setAstoToken(astoToken);
        if (_isContract(astoStorage)) _setAstoStorage(astoStorage);
        if (_isContract(lpToken)) _setLpToken(lpToken);
        if (_isContract(lpStorage)) _setLpStorage(lpStorage);
        if (_isContract(stakingLogic)) _setStakingLogic(stakingLogic);
        if (_isContract(energyStorage)) _setEnergyStorage(energyStorage);
        if (_isContract(lbaEnergyStorage)) _setLBAEnergyStorage(lbaEnergyStorage);
        if (_isContract(converterLogic)) _setConverterLogic(converterLogic);
        _setController(address(this));
    }

    function _setDao(address dao) internal {
        _dao = dao;
        _clearRole(DAO_ROLE);
        _grantRole(DAO_ROLE, dao);
        _grantRole(MULTISIG_ROLE, dao);
        _stakingLogic.setDao(dao);
        _converterLogic.setDao(dao);
    }

    function _setMultisig(address multisig) internal {
        _multisig = multisig;
        _clearRole(MULTISIG_ROLE);
        _grantRole(MULTISIG_ROLE, multisig);
        _grantRole(MULTISIG_ROLE, _dao);
        _converterLogic.setMultisig(multisig, _dao);
    }

    function _setController(address newContract) internal {
        _stakingLogic.setController(newContract);
        _astoStorage.setController(newContract);
        _lpStorage.setController(newContract);
        _converterLogic.setController(newContract);
        _energyStorage.setController(newContract);
        _lbaEnergyStorage.setController(newContract);
        emit ContractUpgraded(block.timestamp, "Controller", address(this), newContract);
    }

    function _setStakingLogic(address newContract) internal {
        // revoke consumer role to old staking storage contract
        if (_isContract(address(_stakingLogic))) {
            _astoStorage.removeConsumer(address(_stakingLogic));
            _lpStorage.removeConsumer(address(_stakingLogic));
        }

        uint256 lockedAsto = _stakingLogic.totalStakedAmount(ASTO_TOKEN_ID);
        uint256 lockedLp = _stakingLogic.totalStakedAmount(LP_TOKEN_ID);

        _stakingLogic = Staking(newContract);
        _stakingLogic.init(
            address(_dao),
            IERC20(_astoToken),
            address(_astoStorage),
            IERC20(_lpToken),
            address(_lpStorage),
            lockedAsto,
            lockedLp
        );
        _astoStorage.addConsumer(newContract);
        _lpStorage.addConsumer(newContract);
        emit ContractUpgraded(block.timestamp, "Staking Logic", address(this), newContract);
    }

    function _setAstoToken(address newContract) internal {
        _astoToken = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "ASTO Token", address(this), newContract);
    }

    function _setAstoStorage(address newContract) internal {
        _astoStorage = StakingStorage(newContract);
        _astoStorage.init(address(_stakingLogic));
        emit ContractUpgraded(block.timestamp, "ASTO Staking Storage", address(this), newContract);
    }

    function _setLpToken(address newContract) internal {
        _lpToken = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "LP Token", address(this), newContract);
    }

    function _setLpStorage(address newContract) internal {
        _lpStorage = StakingStorage(newContract);
        _lpStorage.init(address(_stakingLogic));
        emit ContractUpgraded(block.timestamp, "LP Staking Storage", address(this), newContract);
    }

    function _setConverterLogic(address newContract) internal {
        // revoke consumer role to old energy storage contract
        if (_isContract(address(_converterLogic))) {
            _lbaEnergyStorage.removeConsumer(address(_converterLogic));
            _energyStorage.removeConsumer(address(_converterLogic));
        }

        _converterLogic = Converter(newContract);
        _converterLogic.init(
            address(_dao),
            address(_multisig),
            address(_energyStorage),
            address(_lbaEnergyStorage),
            address(_stakingLogic)
        );
        _lbaEnergyStorage.addConsumer(newContract);
        _energyStorage.addConsumer(newContract);
        emit ContractUpgraded(block.timestamp, "Converter Logic", address(this), newContract);
    }

    function _setEnergyStorage(address newContract) internal {
        _energyStorage = EnergyStorage(newContract);
        _energyStorage.init(address(_converterLogic));
        emit ContractUpgraded(block.timestamp, "Energy Storage", address(this), newContract);
    }

    function _setLBAEnergyStorage(address newContract) internal {
        _lbaEnergyStorage = EnergyStorage(newContract);
        _lbaEnergyStorage.init(address(_converterLogic));
        emit ContractUpgraded(block.timestamp, "LBA Energy Storage", address(this), newContract);
    }

    /** ----------------------------------
     * ! External functions | Manager Role
     * ----------------------------------- */

    /**
     * @notice The way to upgrade contracts
     * @notice Only Manager address (_dao wallet) has access to upgrade
     * @notice All parameters are optional
     */
    function upgradeContracts(
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) external onlyRole(DAO_ROLE) {
        _upgradeContracts(
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            converterLogic,
            energyStorage,
            lbaEnergyStorage
        );
    }

    function setDao(address dao) external onlyRole(DAO_ROLE) {
        _setDao(dao);
    }

    function setMultisig(address multisig) external onlyRole(DAO_ROLE) {
        _setMultisig(multisig);
    }

    function setController(address newContract) external onlyRole(DAO_ROLE) {
        _setController(newContract);
    }

    function setStakingLogic(address newContract) external onlyRole(DAO_ROLE) {
        _setStakingLogic(newContract);
    }

    function setAstoStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setAstoStorage(newContract);
    }

    function setLpStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setLpStorage(newContract);
    }

    function setConverterLogic(address newContract) external onlyRole(DAO_ROLE) {
        _setConverterLogic(newContract);
    }

    function setEnergyStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setEnergyStorage(newContract);
    }

    function setLBAEnergyStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setLBAEnergyStorage(newContract);
    }

    // DAO and MULTISIG can call this function
    function pause() external onlyRole(MULTISIG_ROLE) {
        if (!_stakingLogic.paused()) {
            _stakingLogic.pause();
        }

        if (!_converterLogic.paused()) {
            _converterLogic.pause();
        }
    }

    // DAO and MULTISIG can call this function
    function unpause() external onlyRole(MULTISIG_ROLE) {
        if (_stakingLogic.paused()) {
            _stakingLogic.unpause();
        }

        if (_converterLogic.paused()) {
            _converterLogic.unpause();
        }
    }

    /** ----------------------------------
     * ! Public functions | Getters
     * ----------------------------------- */

    function getController() external view returns (address) {
        return address(this);
    }

    function getDao() external view returns (address) {
        return _dao;
    }

    function getMultisig() external view returns (address) {
        return _multisig;
    }

    function getStakingLogic() external view returns (address) {
        return address(_stakingLogic);
    }

    function getAstoStorage() external view returns (address) {
        return address(_astoStorage);
    }

    function getLpStorage() external view returns (address) {
        return address(_lpStorage);
    }

    function getConverterLogic() external view returns (address) {
        return address(_converterLogic);
    }

    function getEnergyStorage() external view returns (address) {
        return address(_energyStorage);
    }

    function getLBAEnergyStorage() external view returns (address) {
        return address(_lbaEnergyStorage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Staking.sol";
import "./EnergyStorage.sol";
import "./helpers/IConverter.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";
import "./interfaces/ILiquidityBootstrapAuction.sol";

/**
 * @dev ASM Genome Mining - Converter Logic contract
 *
 * This contracts provides functionality for ASTO Energy calculation and conversion.
 * Energy is calculated based on the token staking history from staking contract and multipliers pre-defined for ASTO and LP tokens.
 * Eenrgy can be consumed on multiple purposes.
 */
contract Converter is IConverter, IStaking, Util, PermissionControl, Pausable {
    using SafeMath for uint256;

    bool private _initialized = false;

    uint256 public periodIdCounter = 0;
    // PeriodId start from 1
    mapping(uint256 => Period) public periods;

    Staking public stakingLogic_;
    ILiquidityBootstrapAuction public lba_;
    EnergyStorage public energyStorage_;
    EnergyStorage public lbaEnergyStorage_;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    uint256 private _lbaEnergyStartTime;
    uint256 public lbaEnergyFinishTime;

    event EnergyUsed(address indexed addr, uint256 amount);
    event LBAEnergyUsed(address indexed addr, uint256 amount);
    event PeriodAdded(uint256 time, uint256 indexed periodId, Period period);
    event PeriodUpdated(uint256 time, uint256 indexed periodId, Period period);

    constructor(
        address controller,
        address lba,
        Period[] memory _periods,
        uint256 lbaEnergyStartTime,
        uint256 _lbaEnergyFinishTime
    ) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        if (!_isContract(lba)) revert ContractError(INVALID_LBA_CONTRACT);
        lba_ = ILiquidityBootstrapAuction(lba);
        _grantRole(CONTROLLER_ROLE, controller);
        _addPeriods(_periods);
        _lbaEnergyStartTime = lbaEnergyStartTime;
        lbaEnergyFinishTime = _lbaEnergyFinishTime;
        _pause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @dev Get consumed energy amount for address `addr`
     *
     * @param addr The wallet address to get consumed energy for
     * @return Consumed energy amount
     */
    function getConsumedEnergy(address addr) public view nonZero(addr) returns (uint256) {
        return energyStorage_.consumedAmount(addr);
    }

    /**
     * @dev Get consumed LBA energy amount for address `addr`
     *
     * @param addr The wallet address to get consumed energy for
     * @return Consumed energy amount
     */
    function getConsumedLBAEnergy(address addr) public view nonZero(addr) returns (uint256) {
        return lbaEnergyStorage_.consumedAmount(addr);
    }

    /**
     * @dev Calculate the energy for `addr` based on the staking history  before the endTime of specified period
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount
     */
    function calculateEnergy(address addr, uint256 periodId) public view returns (uint256) {
        uint256 astoEnergyAmount = calculateAstoEnergy(addr, periodId);
        uint256 lpEnergyAmount = calculateLpEnergy(addr, periodId);

        return (astoEnergyAmount + lpEnergyAmount);
    }

    /**
     * @dev Calculate the energy for `addr` based on the staking history  before the endTime of specified period
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount
     */
    function calculateAstoEnergy(address addr, uint256 periodId)
        public
        view
        nonZero(addr)
        validPeriodId(periodId)
        returns (uint256)
    {
        Period memory period = getPeriod(periodId);
        Stake[] memory astoHistory = stakingLogic_.getHistory(ASTO_TOKEN_ID, addr, period.endTime);

        return _calculateEnergyForToken(astoHistory, period.astoMultiplier, period.endTime);
    }

    /**
     * @dev Calculate the energy for `addr` based on the staking history  before the endTime of specified period
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount
     */
    function calculateLpEnergy(address addr, uint256 periodId)
        public
        view
        nonZero(addr)
        validPeriodId(periodId)
        returns (uint256)
    {
        Period memory period = getPeriod(periodId);
        Stake[] memory lpHistory = stakingLogic_.getHistory(LP_TOKEN_ID, addr, period.endTime);

        return _calculateEnergyForToken(lpHistory, period.lpMultiplier, period.endTime);
    }

    /**
     * @dev Calculate the energy for specific staked token
     *
     * @param history The staking history for the staked token
     * @param multiplier The multiplier for staked token
     * @param periodEndTime Only calculate energy generated before periodEndTime
     * @return total energy amount for the token
     */
    function _calculateEnergyForToken(
        Stake[] memory history,
        uint256 multiplier,
        uint256 periodEndTime
    ) internal view returns (uint256) {
        uint256 total = 0;

        uint256 _time = currentTime() < periodEndTime ? currentTime() : periodEndTime;
        for (uint256 i = history.length; i > 0; --i) {
            Stake memory stake = history[i - 1];
            if (_time < stake.time) continue;

            bool lastIndex = i == history.length;
            uint256 elapsedTime = lastIndex ? _time.sub(stake.time) : history[i].time.sub(stake.time);

            total = total.add(elapsedTime.mul(stake.amount).mul(multiplier));
        }
        return total.div(SECONDS_PER_DAY);
    }

    /**
     * @dev Calculate available energy generated by keeping LP tokens in LBA contract
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount
     */
    function calculateAvailableLBAEnergy(address addr, uint256 periodId) public view returns (uint256) {
        uint256 lbaEnergyStartTime = getLBAEnergyStartTime();
        if (currentTime() < lbaEnergyStartTime) return 0;

        Period memory period = getPeriod(periodId);
        uint256 elapsedTimeInPeriod = currentTime() < period.endTime ? currentTime() : period.endTime;
        uint256 finishTime = elapsedTimeInPeriod < lbaEnergyFinishTime ? elapsedTimeInPeriod : lbaEnergyFinishTime;
        uint256 elapsedTime = finishTime - lbaEnergyStartTime;
        uint256 dailyLbaEnergyAmount = getDailyLBAEnergyProduction(addr, periodId);

        return elapsedTime.mul(dailyLbaEnergyAmount).div(SECONDS_PER_DAY);
    }

    function isLBAEnergyFinished() public view returns (bool) {
        return currentTime() > lbaEnergyFinishTime;
    }

    /**
     * @dev Get a daily estimation of energy production for ASTO
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount (per day)
     */
    function getDailyASTOEnergyProduction(address addr, uint256 periodId) public view nonZero(addr) returns (uint256) {
        Period memory period = getPeriod(periodId);
        Stake[] memory history = stakingLogic_.getHistory(ASTO_TOKEN_ID, addr, period.endTime);
        return history.length > 0 ? history[history.length - 1].amount.mul(period.astoMultiplier) : 0;
    }

    /**
     * @dev Get a daily estimation of energy production for ASTO-USDC Uniswap LP token
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount (per day)
     */
    function getDailyLPEnergyProduction(address addr, uint256 periodId) public view nonZero(addr) returns (uint256) {
        Period memory period = getPeriod(periodId);
        Stake[] memory history = stakingLogic_.getHistory(LP_TOKEN_ID, addr, period.endTime);
        return history.length > 0 ? history[history.length - 1].amount.mul(period.lpMultiplier) : 0;
    }

    /**
     * @dev Get a daily estimate of LBA energy production
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount (per day)
     */
    function getDailyLBAEnergyProduction(address addr, uint256 periodId) public view nonZero(addr) returns (uint256) {
        Period memory period = getPeriod(periodId);
        return lba_.claimableLPAmount(addr).mul(period.lbaLPMultiplier);
    }

    /**
     * @dev Get the energy amount available for address `addr`
     *
     * @param addr The wallet address to get energy for
     * @param periodId The period id for energy calculation
     * @return Energy amount available
     */
    function getEnergy(address addr, uint256 periodId) public view virtual returns (uint256) {
        if (stakingLogic_.lbaMigrated(addr)) {
            uint256 generatedEnergy = calculateEnergy(addr, periodId);
            uint256 consumedEnergy = getConsumedEnergy(addr) + getConsumedLBAEnergy(addr);
            uint256 remainingEnergy = generatedEnergy > consumedEnergy ? generatedEnergy - consumedEnergy : 0;
            return remainingEnergy;
        } else {
            // for LBA participants who didn't migrate LP, still use the old calculation logic that
            // totalAE = AE remaing from staking + AE remaining from LBA LP
            uint256 generatedEnergy = calculateEnergy(addr, periodId);
            uint256 consumedEnergy = getConsumedEnergy(addr);
            uint256 remainingEnergy = generatedEnergy > consumedEnergy ? generatedEnergy - consumedEnergy : 0;
            return remainingEnergy + getRemainingLBAEnergy(addr, periodId);
        }
    }

    /**
     * @dev Get the energy amount available for address `addr` within current period
     *
     * @param addr The wallet address to get energy for
     * @return Energy amount available
     */
    function getEnergyForCurrentPeriod(address addr) public view returns (uint256) {
        uint256 periodId = getCurrentPeriodId();
        return periodId > 0 ? getEnergy(addr, periodId) : 0;
    }

    /**
     * @dev Get remaining LBA energy amount available for address `addr` to spend
     *
     * @param addr The wallet address to get energy for
     * @param periodId The period id for energy calculation
     * @return Energy amount remaining
     */
    function getRemainingLBAEnergy(address addr, uint256 periodId) public view returns (uint256) {
        uint256 availableEnergy = calculateAvailableLBAEnergy(addr, periodId);
        uint256 consumedEnergy = getConsumedLBAEnergy(addr);
        if (availableEnergy > 0 && availableEnergy > consumedEnergy) return availableEnergy - consumedEnergy;
        return 0;
    }

    /**
     * @dev Consume energy generated before the endTime of period `periodId`
     * @dev Energy accumulated by keeping LP tokens in LBA contract will be consumed first
     *
     * @param addr The wallet address to consume from
     * @param periodId The period id for energy consumption
     * @param amount The amount of energy to consume
     */
    function useEnergy(
        address addr,
        uint256 periodId,
        uint256 amount
    ) external whenNotPaused onlyRole(CONSUMER_ROLE) validPeriodId(periodId) nonZero(addr) {
        if (amount > getEnergy(addr, periodId)) revert InvalidInput(WRONG_AMOUNT);

        uint256 remainingLBAEnergy = getRemainingLBAEnergy(addr, periodId);
        uint256 lbaEnergyToSpend = Math.min(amount, remainingLBAEnergy);

        // use LBA energy first
        if (lbaEnergyToSpend > 0) {
            lbaEnergyStorage_.increaseConsumedAmount(addr, lbaEnergyToSpend);
            emit LBAEnergyUsed(addr, lbaEnergyToSpend);
        }

        uint256 energyToSpend = amount - lbaEnergyToSpend;
        if (energyToSpend > 0) {
            energyStorage_.increaseConsumedAmount(addr, energyToSpend);
            emit EnergyUsed(addr, energyToSpend);
        }
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
    function getPeriod(uint256 periodId) public view validPeriodId(periodId) returns (Period memory) {
        return periods[periodId];
    }

    /**
     * @notice Get the current period based on current timestamp
     *
     * @return current period data
     */
    function getCurrentPeriod() external view returns (Period memory) {
        return periods[getCurrentPeriodId()];
    }

    /**
     * @notice Get the current period id based on current timestamp
     *
     * @return current periodId
     */
    function getCurrentPeriodId() public view returns (uint256) {
        for (uint256 index = 1; index <= periodIdCounter; ++index) {
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

    function getLBAEnergyStartTime() public view returns (uint256) {
        return _lbaEnergyStartTime > 0 ? _lbaEnergyStartTime : lba_.lpTokenReleaseTime();
    }

    /** ----------------------------------
     * ! Administration         | Manager
     * ----------------------------------- */

    /**
     * @dev Add new periods
     * @dev Only dao contract has the permission to call this function
     *
     * @param _periods The list of periods to be added
     */
    function addPeriods(Period[] memory _periods) external onlyRole(MANAGER_ROLE) {
        _addPeriods(_periods);
    }

    /**
     * @notice Update LBA energy finish time. Stop generating AE if curremt time > `finishTime`.
     * @param finishTime The finish time to be set
     */
    function setLBAEnergyFinishTime(uint256 finishTime) external onlyRole(MANAGER_ROLE) {
        lbaEnergyFinishTime = finishTime;
    }

    /**
     * @notice Update staking logic contract address
     * @param newContract The new staking logic contract address.
     */
    function setStakingLogic(address newContract) external onlyRole(MANAGER_ROLE) {
        stakingLogic_ = Staking(newContract);
    }

    /**
     * @dev Add a new period
     * @dev Only dao contract has the permission to call this function
     *
     * @param period The period instance to add
     */
    function addPeriod(Period memory period) external onlyRole(MANAGER_ROLE) {
        _addPeriod(period);
    }

    /**
     * @dev Update a period
     * @dev Only dao contract has the permission to call this function
     *
     * @param periodId The period id to update
     * @param period The period data to update
     */
    function updatePeriod(uint256 periodId, Period memory period) external onlyRole(MANAGER_ROLE) {
        _updatePeriod(periodId, period);
    }

    /**
     * @dev Add new periods
     * @dev This is a private function, can only be called in this contract
     *
     * @param _periods The list of periods to be added
     */
    function _addPeriods(Period[] memory _periods) internal {
        for (uint256 i = 0; i < _periods.length; ++i) {
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
        emit PeriodAdded(currentTime(), periodIdCounter, period);
    }

    /**
     * @dev Update a period
     * @dev This is an internal function
     *
     * @param periodId The period id to update
     * @param period The period data to update
     */
    function _updatePeriod(uint256 periodId, Period memory period) internal validPeriodId(periodId) {
        periods[periodId] = period;
        emit PeriodUpdated(currentTime(), periodId, period);
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Initialize the contract:
     * @dev only controller is allowed to call this function
     *
     * @param dao The dao contract address
     * @param energyStorage The energy storage contract address
     * @param stakingLogic The staking logic contrct address
     */
    function init(
        address dao,
        address multisig,
        address energyStorage,
        address lbaEnergyStorage,
        address stakingLogic
    ) external onlyRole(CONTROLLER_ROLE) {
        if (!_initialized) {
            if (!_isContract(energyStorage)) revert ContractError(INVALID_ENERGY_STORAGE);
            if (!_isContract(lbaEnergyStorage)) revert ContractError(INVALID_LBA_ENERGY_STORAGE);
            if (!_isContract(stakingLogic)) revert ContractError(INVALID_STAKING_LOGIC);

            stakingLogic_ = Staking(stakingLogic);
            energyStorage_ = EnergyStorage(energyStorage);
            lbaEnergyStorage_ = EnergyStorage(lbaEnergyStorage);

            _grantRole(DAO_ROLE, dao);
            _grantRole(MULTISIG_ROLE, multisig);
            _grantRole(MANAGER_ROLE, multisig);

            _initialized = true;
        }
    }

    /**
     * @dev Update the DAO contract address
     * @dev only Controller is allowed to change the address of DAO contract
     */
    function setDao(address newDao) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(DAO_ROLE);
        _grantRole(DAO_ROLE, newDao);
    }

    /**
     * @dev Update the Multisig contract address
     * @dev only Controller is allowed to change the address of Multisig contract
     */
    function setMultisig(address newMultisig, address dao) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(MULTISIG_ROLE);
        _grantRole(MULTISIG_ROLE, newMultisig);
        _grantRole(MULTISIG_ROLE, dao);
    }

    /**
     * @dev Update the Controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(CONTROLLER_ROLE);
        _grantRole(CONTROLLER_ROLE, newController);
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

    modifier nonZero(address addr) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        _;
    }
    modifier validPeriodId(uint256 periodId) {
        if (periodId == 0 || periodId > periodIdCounter) revert InvalidInput(WRONG_PERIOD_ID);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Energy Storage contract
 *
 * Store consumed energy amount for each address.
 * This contract will be called from Converter logic contract (Converter.sol)
 */
contract EnergyStorage is Util, PermissionControl {
    bool private _initialized = false;
    mapping(address => uint256) public consumedAmount;

    constructor(address controller) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        _grantRole(CONTROLLER_ROLE, controller);
    }

    /**
     * @dev Increase consumed energy for address `addr`
     * @dev can only be called by Converter
     *
     * @param addr The wallet address which consumed the energy
     * @param amount The amount of consumed energy
     */
    function increaseConsumedAmount(address addr, uint256 amount) external onlyRole(CONSUMER_ROLE) {
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
        if (!_initialized) {
            if (!_isContract(converterLogic)) revert ContractError(INVALID_CONVERTER_LOGIC);

            _grantRole(CONSUMER_ROLE, converterLogic);
            _initialized = true;
        }
    }

    /**
     * @dev Update the Controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(CONTROLLER_ROLE);
        _grantRole(CONTROLLER_ROLE, newController);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
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

contract Staking is IStaking, Util, PermissionControl, Pausable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    bool private _initialized = false;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    uint256 public lbaStakeTime;
    address private _signer;

    /**
     * `_token`:  tokenId => token contract address
     * `_token`:  tokenId => token name
     * `_storage`:  tokenId => storage contract address
     *
     * IDs: 0 for ASTO, 1 for LP tokens, see `init()` below
     */
    mapping(uint256 => IERC20) private _token;
    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => StakingStorage) private _storage;
    mapping(uint256 => uint256) public totalStakedAmount;
    mapping(address => bool) public lbaMigrated;

    constructor(
        address controller,
        address signer,
        uint256 _lbaStakeTime
    ) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        _signer = signer;
        lbaStakeTime = _lbaStakeTime;
        _grantRole(CONTROLLER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Administration          | dao
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
    ) external onlyRole(DAO_ROLE) {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (address(recipient) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (_token[tokenId].balanceOf(address(this)) < amount) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransfer(recipient, amount);
    }

    /**
     * @notice Update LP stake time used for LBA migration
     * @dev This function can only to called from contracts or wallets with DAO_ROLE
     * @param _time LBA LP stake time, it should be the same as lpTokenReleaseTime in LBA contract
     */
    function setLBAStakeTime(uint256 _time) external onlyRole(DAO_ROLE) {
        lbaStakeTime = _time;
    }

    /**
     * @notice Update token contract address
     * @dev This function can only to called from contracts or wallets with DAO_ROLE
     * @param tokenId The token id to update
     * @param tokenAddress New contract address for the token
     */
    function setTokenAddress(uint256 tokenId, address tokenAddress) external onlyRole(DAO_ROLE) {
        if (!_isContract(tokenAddress)) revert InvalidInput(WRONG_TOKEN);
        _token[tokenId] = IERC20(tokenAddress);
    }

    /**
     * @notice Set signer to `signer`
     * @dev This function can only to called from contracts or wallets with DAO_ROLE
     * @param signer The new signer address to update
     */
    function setSigner(address signer) external onlyRole(DAO_ROLE) {
        _signer = signer;
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only DAO contract is allowed to call admin functions
     * @dev only controller is allowed to update permissions - to reduce amount of DAO votings
     *
     * @param astoToken ASTO Token contract address
     * @param lpToken LP Token contract address
     * @param astoStorage ASTO staking storage contract address
     * @param lpStorage LP staking storage contract address
     */
    function init(
        address dao,
        IERC20 astoToken,
        address astoStorage,
        IERC20 lpToken,
        address lpStorage,
        uint256 totalStakedAsto,
        uint256 totalStakedLp
    ) external onlyRole(CONTROLLER_ROLE) {
        if (!_initialized) {
            _token[0] = astoToken;
            _storage[0] = StakingStorage(astoStorage);
            _tokenName[0] = "ASTO";

            _token[1] = lpToken;
            _storage[1] = StakingStorage(lpStorage);
            _tokenName[1] = "ASTO/USDC Uniswap V2 LP";

            _clearRole(DAO_ROLE);
            _grantRole(DAO_ROLE, dao);

            _clearRole(MULTISIG_ROLE);
            _grantRole(MULTISIG_ROLE, dao);

            totalStakedAmount[ASTO_TOKEN_ID] = totalStakedAsto;
            totalStakedAmount[LP_TOKEN_ID] = totalStakedLp;

            _initialized = true;
        }
    }

    /**
     * @dev Update the DAO contract address
     * @dev only controller is allowed to set new DAO contract
     */
    function setDao(address newDao) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(DAO_ROLE);
        _grantRole(DAO_ROLE, newDao);
    }

    /**
     * @dev Update the Controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(CONTROLLER_ROLE);
        _grantRole(CONTROLLER_ROLE, newController);
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
     * @dev - this contract should have a `CONSUMER_ROLE` to call
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
        uint256 tokenBalance = _token[tokenId].balanceOf(user);
        if (amount > tokenBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransferFrom(user, address(this), amount);

        uint256 lastStakeId = _storage[tokenId].getUserLastStakeId(user);
        uint256 stakeBalance = (_storage[tokenId].getStake(user, lastStakeId)).amount;
        uint256 newAmount = stakeBalance + amount;
        _storage[tokenId].updateHistory(user, newAmount);
        totalStakedAmount[tokenId] += amount;

        emit Staked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice Stake on behalf of `staker`.
     * @notice This function can be used for auto-staking from consumer contracts on behalf of users
     * @param staker - User wallet address. It should be the wallet which a consumer contract or account stake tokens for
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function stakeFor(
        address staker,
        uint256 tokenId,
        uint256 amount
    ) external whenNotPaused onlyRole(CONSUMER_ROLE) {
        if (tokenId > 1) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);

        uint256 tokenBalance = _token[tokenId].balanceOf(msg.sender);
        if (amount > tokenBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransferFrom(msg.sender, address(this), amount);

        uint256 lastStakeId = _storage[tokenId].getUserLastStakeId(staker);
        uint256 stakeBalance = (_storage[tokenId].getStake(staker, lastStakeId)).amount;
        uint256 newAmount = stakeBalance + amount;
        _storage[tokenId].updateHistory(staker, newAmount);
        totalStakedAmount[tokenId] += amount;

        emit Staked(_tokenName[tokenId], staker, block.timestamp, amount);
    }

    /**
     * @notice Migrate user's LBA LP tokens to staking contract
     * @param amount The LP token amount to be migrated, it should be the same amount with claimed LP tokens from LBA contract
     * @param signature Signature will be used for user and amount verification.
              It should be generated from backend with correct LP token amount from Transfer event.
     */
    function migrateAuctionLP(uint256 amount, bytes calldata signature) external whenNotPaused {
        address user = msg.sender;
        if (lbaMigrated[user]) revert InvalidInput(ALREADY_MIGRATED);
        if (!validateSignature(_hash(msg.sender, amount), signature)) revert InvalidInput(INVALID_SIGNATURE);

        _token[LP_TOKEN_ID].safeTransferFrom(user, address(this), amount);
        _storage[LP_TOKEN_ID].migrateLBAHistory(user, amount, lbaStakeTime);

        lbaMigrated[user] = true;
        totalStakedAmount[LP_TOKEN_ID] += amount;

        emit Staked(_tokenName[LP_TOKEN_ID], user, lbaStakeTime, amount);
    }

    /**
     * @notice Migrate users' stake history from the old contract after upgrading the Staking contract to a new version
     * @dev This function can only to called from contracts or wallets with DAO_ROLE
     * @param tokenId The token id for migration. `0` for ASTO and `1` for LP token.
     * @param addresses The list of user wallet address to be migrated.
     */
    function migrateHistory(uint256 tokenId, address[] calldata addresses) external onlyRole(DAO_ROLE) {
        _storage[tokenId].migrateStakeHistory(addresses);
    }

    /**
     * @notice Encode arguments to generate a hash, which will be used for validating signatures
     * @dev This function can only be called inside the contract
     * @param user The user wallet address, to verify the signature can only be used by the wallet
     * @param amount The LP token amount to be migrated
     * @return Encoded hash
     */
    function _hash(address user, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encode(user, amount));
    }

    /**
     * @notice Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     * @dev This function can only be called inside the contract
     * @param hash The encoded hash used for signature
     * @param token The signature passed from the caller
     * @return The recovered address
     */
    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    /**
     * @notice To validate the `signature` is signed by the _signer
     * @param hash The encoded hash used for signature
     * @param token The signature passed from the caller
     * @return Verification result
     */
    function validateSignature(bytes32 hash, bytes memory token) public view returns (bool) {
        return (_recover(hash, token) == _signer);
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
    function unstake(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);

        address user = msg.sender;
        uint256 id = _storage[tokenId].getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (_storage[tokenId].getStake(user, id)).amount;
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        uint256 newAmount = userBalance - amount;
        _storage[tokenId].updateHistory(user, newAmount);
        totalStakedAmount[tokenId] -= amount;

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
        return totalStakedAmount[tokenId];
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
    function getStorageAddress(uint256 tokenId) external view returns (address) {
        return address(_storage[tokenId]);
    }

    /**
     * @notice Returns address of the token contract
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return address of the token contract
     */
    function getTokenAddress(uint256 tokenId) external view returns (address) {
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
    ) external view returns (Stake[] memory) {
        return _storage[tokenId].getHistory(addr, endTime);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./Controller.sol";
import "./Staking.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract StakingStorage is IStaking, ReentrancyGuard, PermissionControl, Util, Pausable {
    bool private _initialized = false;

    // Incrementing stake Id used to record history
    mapping(address => uint256) public stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint256 => Stake)) public stakeHistory;

    StakingStorage public oldContract;

    constructor(address controller, address _oldContract) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        if (_isContract(_oldContract)) oldContract = StakingStorage(_oldContract);
        _grantRole(CONTROLLER_ROLE, controller);
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
    function updateHistory(address addr, uint256 amount) external onlyRole(CONSUMER_ROLE) returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);

        uint128 time = uint128(currentTime());
        Stake memory newStake = Stake(time, amount);
        uint256 userStakeId = ++stakeIds[addr]; // ++i cheaper than i++, so, stakeHistory[addr] starts from 1
        stakeHistory[addr][userStakeId] = newStake;
        return userStakeId;
    }

    /**
     * @notice Migrate LBA LP staking history for `addr`
     * @dev This function can only to called from contracts or wallets with CONSUMER_ROLE
     * @param addr The user wallet address for the migration.
     * @param amount The LP token amount to be migrated. It should be verified in caller contract with CONSUMER_ROLE.
     * @param stakeTime The stake time for LBA LP tokens.
     */
    function migrateLBAHistory(
        address addr,
        uint256 amount,
        uint256 stakeTime
    ) external onlyRole(CONSUMER_ROLE) {
        uint256 lastStakeId = stakeIds[addr];

        for (uint256 i = lastStakeId; i > 0; --i) {
            Stake memory existingStake = stakeHistory[addr][i];
            Stake memory newStake = Stake(existingStake.time, existingStake.amount + amount);
            stakeHistory[addr][i + 1] = newStake;
        }

        // LBA LP staking should be the first one in staking history
        stakeHistory[addr][1] = Stake(stakeTime, amount);
        ++stakeIds[addr];
    }

    /**
     * @notice Migrate user's stake history from old contract after upgrading Staking contract to a new version
     * @dev This function can only to called from contracts or wallets with CONSUMER_ROLE
     * @param addresses The list of user wallet address to be migrated.
     */
    function migrateStakeHistory(address[] calldata addresses) external nonReentrant onlyRole(CONSUMER_ROLE) {
        for (uint256 i = 0; i < addresses.length; ++i) {
            address addr = addresses[i];
            if (stakeIds[addr] > 0) {
                continue; // already migrated
            }

            uint256 lastStakeId = oldContract.getUserLastStakeId(addr);
            if (lastStakeId == 0) {
                continue;
            }

            for (uint256 j = 1; j < lastStakeId + 1; ++j) {
                stakeHistory[addr][j] = oldContract.getStake(addr, j);
            }
            stakeIds[addr] = lastStakeId;
        }
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getHistory(address addr, uint256 endTime) external view returns (Stake[] memory) {
        uint256 totalStakes = stakeIds[addr];

        Stake[] memory stakes = new Stake[](totalStakes); // suboptimal - it could be larger than needed, when endTime is lesser than current time

        // stakeHistory[addr] starts from 1, see `updateHistory`
        for (uint256 i = 1; i < totalStakes + 1; i++) {
            Stake memory stake = stakeHistory[addr][i];
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

    function getStake(address addr, uint256 id) external view returns (Stake memory) {
        return stakeHistory[addr][id];
    }

    function getUserLastStakeId(address addr) external view returns (uint256) {
        return stakeIds[addr];
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
     * @dev only Consumer is allowed to save into this storage
     * @dev only Controller is allowed to update permissions - to reduce amount of DAO votings
     * @dev
     *
     * @param controller Controller contract address
     * @param stakingLogic Staking contract address
     */
    function init(address stakingLogic) external onlyRole(CONTROLLER_ROLE) {
        if (!_initialized) {
            _grantRole(CONSUMER_ROLE, stakingLogic);
            _initialized = true;
        }
    }

    /**
     * @dev Update the Controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(CONTROLLER_ROLE);
        _grantRole(CONTROLLER_ROLE, newController);
    }

    function setOldContract(address _oldContract) external onlyRole(CONTROLLER_ROLE) {
        oldContract = StakingStorage(_oldContract);
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
        uint128 lbaLPMultiplier;
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

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @dev ASM Genome Mining - PermissionControl contract
 */

bytes32 constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
bytes32 constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");
bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
bytes32 constant DAO_ROLE = keccak256("DAO_ROLE");
bytes32 constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

string constant MISSING_ROLE = "Missing required role";

contract PermissionControl is AccessControlEnumerable {
    error AccessDenied(string errMsg);

    /**
     * @dev Modifier that checks that an account has at least one role in `roles`.
     * Reverts with a standardized message.
     */
    modifier eitherRole(bytes32[2] memory roles) {
        if (!hasRole(roles[0], _msgSender()) && !hasRole(roles[1], _msgSender())) {
            revert AccessDenied(MISSING_ROLE);
        }
        _;
    }

    /**
     * @dev Revoke all members to `role`
     * @dev Internal function without access restriction.
     */
    function _clearRole(bytes32 role) internal {
        uint256 count = getRoleMemberCount(role);
        for (uint256 i = count; i > 0; i--) {
            _revokeRole(role, getRoleMember(role, i - 1));
        }
    }

    /**
     * @dev Grant CONSUMER_ROLE to `addr`.
     * @dev Can only be called from Controller or Multisig
     */
    function addConsumer(address addr) public eitherRole([CONTROLLER_ROLE, MULTISIG_ROLE]) {
        _grantRole(CONSUMER_ROLE, addr);
    }

    /**
     * @dev Revoke CONSUMER_ROLE to `addr`.
     * @dev Can only be called from Controller or Multisig
     */
    function removeConsumer(address addr) public eitherRole([CONTROLLER_ROLE, MULTISIG_ROLE]) {
        _revokeRole(CONSUMER_ROLE, addr);
    }

    /**
     * @dev Grant MANAGER_ROLE to `addr`.
     * @dev Can only be called from Controller or Multisig
     */
    function addManager(address addr) public eitherRole([CONTROLLER_ROLE, MULTISIG_ROLE]) {
        _grantRole(MANAGER_ROLE, addr);
    }

    /**
     * @dev Revoke MANAGER_ROLE to `addr`.
     * @dev Can only be called from Controller or Multisig
     */
    function removeManager(address addr) public eitherRole([CONTROLLER_ROLE, MULTISIG_ROLE]) {
        _revokeRole(MANAGER_ROLE, addr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev ASM Genome Mining - Time constants we use
 */

uint256 constant DAYS_PER_WEEK = 7;
uint256 constant HOURS_PER_DAY = 24;
uint256 constant MINUTES_PER_HOUR = 60;
uint256 constant SECONDS_PER_MINUTE = 60;
uint256 constant SECONDS_PER_HOUR = 3600;
uint256 constant SECONDS_PER_DAY = 86400;
uint256 constant SECONDS_PER_WEEK = 604800;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev ASM Genome Mining - Utility contract
 */
contract Util {
    error InvalidInput(string errMsg);
    error ContractError(string errMsg);

    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string constant ALREADY_INITIALIZED = "Already initialized";
    string constant ALREADY_MIGRATED = "Already migrated";
    string constant INVALID_MULTISIG = "Invalid multisig";
    string constant INVALID_SIGNATURE = "Invalid signature";
    string constant INVALID_SIGNER = "Invalid signer";
    string constant INVALID_DAO = "Invalid DAO";
    string constant INVALID_CONTROLLER = "Invalid Controller";
    string constant INVALID_STAKING_LOGIC = "Invalid Staking Logic";
    string constant INVALID_STAKING_STORAGE = "Invalid Staking Storage";
    string constant INVALID_CONVERTER_LOGIC = "Invalid Converter Logic";
    string constant INVALID_ENERGY_STORAGE = "Invalid Energy Storage";
    string constant INVALID_LBA_ENERGY_STORAGE = "Invalid LBA Energy Storage";
    string constant INVALID_ASTO_CONTRACT = "Invalid ASTO";
    string constant INVALID_LP_CONTRACT = "Invalid LP";
    string constant INVALID_LBA_CONTRACT = "Invalid LBA";
    string constant WRONG_ADDRESS = "Wrong or missed wallet address";
    string constant WRONG_AMOUNT = "Wrong or missed amount";
    string constant WRONG_PERIOD_ID = "Wrong periodId";
    string constant WRONG_TOKEN = "Token not allowed for staking";
    string constant INSUFFICIENT_BALANCE = "Insufficient balance";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILiquidityBootstrapAuction {
    function claimableLPAmount(address) external view returns (uint256);

    function lpTokenReleaseTime() external view returns (uint256);
}