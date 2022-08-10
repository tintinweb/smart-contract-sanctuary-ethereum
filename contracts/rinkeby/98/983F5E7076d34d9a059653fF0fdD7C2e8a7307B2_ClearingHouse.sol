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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// contracts
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IncreAccessControl} from "./utils/IncreAccessControl.sol";

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IClearingHouse} from "./interfaces/IClearingHouse.sol";
import {IPerpetual} from "./interfaces/IPerpetual.sol";
import {IInsurance} from "./interfaces/IInsurance.sol";
import {IVault} from "./interfaces/IVault.sol";
import {ICryptoSwap} from "./interfaces/ICryptoSwap.sol";
import {IStakingContract} from "./interfaces/IStakingContract.sol";

// libraries
import {LibMath} from "./lib/LibMath.sol";
import {LibPerpetual} from "./lib/LibPerpetual.sol";
import {LibReserve} from "./lib/LibReserve.sol";

/// @notice Entry point for users to vault and perpetual markets
contract ClearingHouse is IClearingHouse, IncreAccessControl, Pausable, ReentrancyGuard {
    using LibMath for int256;
    using LibMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // constants
    uint256 internal constant VQUOTE_INDEX = 0; // index of quote asset in curve pool
    uint256 internal constant VBASE_INDEX = 1; // index of base asset in curve pool

    // parameterization

    /// @notice minimum maintenance margin
    int256 public override minMargin;

    /// @notice minimum margin when opening a position
    int256 public override minMarginAtCreation;

    /// @notice minimum positive open notional when opening a position
    uint256 public override minPositiveOpenNotional;

    /// @notice liquidation reward payed to liquidators
    /// @dev Paid on dollar value of an trader position. important: liquidationReward < minMargin or liquidations will result in protocol losses
    uint256 public override liquidationReward;

    /// @notice Insurance ratio
    /// @dev Once the insurance reserve exceed this ratio of the tvl, governance can withdraw exceeding insurance fee
    uint256 public override insuranceRatio;

    /// @notice Portion of the liquidation reward that the insurance gets
    uint256 public override liquidationRewardInsuranceShare;

    /// @notice Discount on the collateral price for the liquidator
    uint256 public override liquidationDiscount;

    /// @notice Discount ratio to be applied on non-UA collaterals before seizing said collaterals for some UA
    /// @dev Must be lower than liquidationDiscount to ensure liquidation don't generate bad debt
    int256 public override nonUACollSeizureDiscount;

    /// @notice UA debt amount at which non-UA collaterals can be seized to pay back the UA debt
    int256 public override uaDebtSeizureThreshold;

    // dependencies

    /// @notice Vault contract
    IVault public override vault;

    /// @notice Insurance contract
    IInsurance public override insurance;

    /// @notice Staking contract
    IStakingContract public override stakingContract;

    /// @notice Allowlisted Perpetual contracts
    IPerpetual[] public override perpetuals;

    constructor(
        IVault _vault,
        IInsurance _insurance,
        ClearingHouseParams memory _params
    ) {
        if (address(_vault) == address(0)) revert ClearingHouse_ZeroAddress();
        if (address(_insurance) == address(0)) revert ClearingHouse_ZeroAddress();

        vault = _vault;
        insurance = _insurance;

        setParameters(
            ClearingHouseParams({
                minMargin: _params.minMargin,
                minMarginAtCreation: _params.minMarginAtCreation,
                minPositiveOpenNotional: _params.minPositiveOpenNotional,
                liquidationReward: _params.liquidationReward,
                insuranceRatio: _params.insuranceRatio,
                liquidationRewardInsuranceShare: _params.liquidationRewardInsuranceShare,
                liquidationDiscount: _params.liquidationDiscount,
                nonUACollSeizureDiscount: _params.nonUACollSeizureDiscount,
                uaDebtSeizureThreshold: _params.uaDebtSeizureThreshold
            })
        );
    }

    /* **************************** */
    /*   Collateral operations      */
    /* **************************** */

    /// @notice Deposit tokens into the vault
    /// @param amount Amount to be used as collateral. Might not be 18 decimals
    /// @param token Token to be used for the collateral
    function deposit(uint256 amount, IERC20Metadata token) external override nonReentrant whenNotPaused {
        _deposit(amount, token);
    }

    /// @notice Withdraw tokens from the vault
    /// @param amount Amount of collateral to withdraw. Might not be 18 decimals (decimals of `token`)
    /// @param token Token of the collateral
    function withdraw(uint256 amount, IERC20Metadata token) external override nonReentrant whenNotPaused {
        vault.withdraw(msg.sender, amount, token);

        if (!_isPositionValid(msg.sender, minMarginAtCreation)) revert ClearingHouse_WithdrawInsufficientMargin();
    }

    /// @notice Withdraw all tokens from the vault
    /// @dev Should only be called by the trader
    /// @param token Token of the collateral
    function withdrawAll(IERC20Metadata token) external override nonReentrant whenNotPaused {
        vault.withdrawAll(msg.sender, token);

        if (!_isPositionValid(msg.sender, minMarginAtCreation)) revert ClearingHouse_WithdrawInsufficientMargin();
    }

    /* ****************** */
    /*   Trader flow      */
    /* ****************** */

    /// @notice Open or increase or reduce a position, either long or short
    /// @param idx Index of the perpetual market
    /// @param amount Represent amount in vQuote (if long) or vBase (if short) to sell. 18 decimals
    /// @param direction Whether the trade should buy or sell vBase (LONG) or sell vBase(SHORT)
    /// @param minAmount Minimum amount that the user is willing to accept. 18 decimals
    /// @dev No number for the leverage is given but the amount in the vault must be bigger than minMarginAtCreation
    /// @dev No checks are done if bought amount exceeds allowance
    function changePosition(
        uint256 idx,
        uint256 amount,
        uint256 minAmount,
        LibPerpetual.Side direction
    ) external override nonReentrant whenNotPaused {
        _changePosition(idx, amount, minAmount, direction);
    }

    function openReversePosition(
        uint256 idx,
        uint256 closeProposedAmount,
        uint256 closeMinAmount,
        uint256 openProposedAmount,
        uint256 openMinAmount,
        LibPerpetual.Side direction
    ) external override nonReentrant whenNotPaused {
        _changePosition(idx, closeProposedAmount, closeMinAmount, direction);
        if (perpetuals[idx].isTraderPositionOpen(msg.sender)) revert ClearingHouse_ClosePositionStillOpen();
        _changePosition(idx, openProposedAmount, openMinAmount, direction);
    }

    /// @notice Single open position function, group collateral deposit and extend position
    /// @param idx Index of the perpetual market
    /// @param collateralAmount Amount to be used as the collateral of the position. Might not be 18 decimals
    /// @param token Token to be used for the collateral of the position
    /// @param positionAmount Amount to be sold, in vQuote (if long) or vBase (if short). Must be 18 decimals
    /// @param direction Whether the position is LONG or SHORT
    /// @param minAmount Minimum amount that the user is willing to accept. 18 decimals
    function extendPositionWithCollateral(
        uint256 idx,
        uint256 collateralAmount,
        IERC20Metadata token,
        uint256 positionAmount,
        LibPerpetual.Side direction,
        uint256 minAmount
    ) external override nonReentrant whenNotPaused {
        _deposit(collateralAmount, token);
        _changePosition(idx, positionAmount, minAmount, direction);
    }

    /// @notice Single close position function, groups close position and withdraw collateral
    /// @notice Important: `proposedAmount` must be large enough to close the entire position else the function call will fail
    /// @param idx Index of the perpetual market
    /// @param proposedAmount Amount of tokens to be sold, in vBase if LONG, in vQuote if SHORT. 18 decimals
    /// @param minAmount Minimum amount that the user is willing to accept, in vQuote if LONG, in vBase if SHORT. 18 decimals
    /// @param token Token used for the collateral
    function closePositionWithdrawCollateral(
        uint256 idx,
        uint256 proposedAmount,
        uint256 minAmount,
        IERC20Metadata token
    ) external override nonReentrant whenNotPaused {
        int256 traderPositionSize = _getTraderPosition(idx, msg.sender).positionSize;

        LibPerpetual.Side closeDirection = traderPositionSize > 0 ? LibPerpetual.Side.Short : LibPerpetual.Side.Long;

        _changePosition(idx, proposedAmount, minAmount, closeDirection);

        if (perpetuals[idx].isTraderPositionOpen(msg.sender)) revert ClearingHouse_ClosePositionStillOpen();

        // tentatively remove all liquidity of user
        // If user had just one position (trading or LP) in one market, it'll pass, else not
        vault.withdrawAll(msg.sender, token);

        if (!_isPositionValid(msg.sender, minMarginAtCreation)) revert ClearingHouse_WithdrawInsufficientMargin();
    }

    /* ****************** */
    /*  Liquidation flow  */
    /* ****************** */

    /// @notice Submit the address of an user whose position is worth liquidating for a reward
    /// @param idx Index of the perpetual market
    /// @param liquidatee Address of the account to liquidate
    /// @param proposedAmount Amount of tokens to be sold, in vBase if LONG, in vQuote if SHORT. 18 decimals
    /// @param isTrader Whether or not the position to liquidate is a trading position
    function liquidate(
        uint256 idx,
        address liquidatee,
        uint256 proposedAmount,
        bool isTrader
    ) external override nonReentrant whenNotPaused {
        address liquidator = msg.sender;

        int256 positiveOpenNotional;
        if (isTrader) {
            (positiveOpenNotional) = _getTraderPosition(idx, liquidatee).openNotional.abs();
            if (positiveOpenNotional == 0) revert ClearingHouse_LiquidateInvalidPosition();
        } else {
            if (!(perpetuals[idx].isLpPositionOpen(liquidatee))) revert ClearingHouse_LiquidateInvalidPosition();

            positiveOpenNotional = _getLpOpenNotional(idx, liquidatee).abs();
        }

        _settleUserFundingPayments(liquidatee);

        if (_isPositionValid(liquidatee, minMargin)) revert ClearingHouse_LiquidateValidMargin();

        int256 pnl = isTrader
            ? _liquidateTrader(idx, liquidatee, proposedAmount)
            : _liquidateLp(idx, liquidatee, proposedAmount);

        // take fee from liquidatee for liquidator and insurance
        uint256 liquidationRewardAmount = positiveOpenNotional.toUint256().wadMul(liquidationReward);
        uint256 insuranceLiquidationReward = liquidationRewardAmount.wadMul(liquidationRewardInsuranceShare);
        uint256 liquidatorLiquidationReward = liquidationRewardAmount - insuranceLiquidationReward;

        vault.settlePnL(liquidatee, pnl - liquidationRewardAmount.toInt256());
        vault.settlePnL(liquidator, liquidatorLiquidationReward.toInt256());
        insurance.fundInsurance(insuranceLiquidationReward);

        emit LiquidationCall(idx, liquidatee, liquidator, positiveOpenNotional.toUint256());
    }

    /// @notice Buy the non-UA collateral of a user at a discounted UA price to settle the debt of said user.
    /// @param liquidatee Address of the account to liquidate
    function seizeCollateral(address liquidatee) external override nonReentrant whenNotPaused {
        address liquidator = msg.sender;

        // all positions must be closed
        for (uint256 i = 0; i < perpetuals.length; i++) {
            if (perpetuals[i].isTraderPositionOpen(liquidatee) || perpetuals[i].isLpPositionOpen(liquidatee))
                revert ClearingHouse_SeizeCollateralStillOpen();
        }

        int256 uaBalance = vault.getBalance(liquidatee, 0);
        int256 discountedCollateralsBalance = vault.getReserveValue(liquidatee, true);
        int256 discountedCollateralsBalanceExUA = discountedCollateralsBalance - uaBalance;

        // user must have UA debt
        if (uaBalance >= 0) revert ClearingHouse_LiquidationDebtSizeZero();

        // for a user to have his non-UA collaterals seized, one of the following 2 conditions must be met:
        // 1) the aggregate value of non-UA collaterals discounted by their weights and the nonUACollSeizureDiscount
        //    ratio must be larger than his UA debt
        // 2) UA debt must be larger than the threshold defined by uaDebtSeizureThreshold
        if (
            -uaBalance > discountedCollateralsBalanceExUA.wadMul(nonUACollSeizureDiscount) ||
            -uaBalance > uaDebtSeizureThreshold
        ) {
            vault.settleLiquidationOnCollaterals(liquidator, liquidatee);

            emit SeizeCollateral(liquidatee, liquidator);
        } else {
            revert ClearingHouse_SufficientUserCollateral();
        }
    }

    /* ****************** */
    /*   Liquidity flow   */
    /* ****************** */

    /// @notice Provide liquidity to the pool, without depositing new capital in the vault
    /// @param idx Index of the perpetual market
    /// @param amounts Amount of virtual tokens ([vQuote, vBase]) provided. 18 decimals
    /// @param minLpAmount Minimum amount of Lp tokens minted. 18 decimals
    function provideLiquidity(
        uint256 idx,
        uint256[2] calldata amounts,
        uint256 minLpAmount
    ) external override nonReentrant whenNotPaused {
        _provideLiquidity(idx, amounts, minLpAmount);
    }

    /// @notice Remove liquidity from the pool and account profit/loss in UA
    /// @param idx Index of the perpetual market
    /// @param liquidityAmountToRemove Amount of liquidity (in LP tokens) to be removed from the pool. 18 decimals
    /// @param minVTokenAmounts Minimum amount of virtual tokens [vQuote, vBase] withdrawn from the curve pool. 18 decimals
    /// @param proposedAmount Amount at which to get the LP position (in vBase if LONG, in vQuote if SHORT). 18 decimals
    /// @param minAmount Minimum amount that the user is willing to accept, in vQuote if LONG, in vBase if SHORT. 18 decimals
    function removeLiquidity(
        uint256 idx,
        uint256 liquidityAmountToRemove,
        uint256[2] calldata minVTokenAmounts,
        uint256 proposedAmount,
        uint256 minAmount
    ) external override nonReentrant whenNotPaused {
        _settleUserFundingPayments(msg.sender);

        (int256 profit, uint256 reductionRatio, int256 quoteProceeds) = perpetuals[idx].removeLiquidity(
            msg.sender,
            liquidityAmountToRemove,
            minVTokenAmounts,
            proposedAmount,
            minAmount,
            false
        );

        // pay insurance fee on traded amount
        int256 insuranceFeeAmount = quoteProceeds.abs().wadMul(perpetuals[idx].insuranceFee());
        insurance.fundInsurance(insuranceFeeAmount.toUint256());

        vault.settlePnL(msg.sender, profit + insuranceFeeAmount);

        _isOpenNotionalRequirementValid(idx, msg.sender, false);
        emit LiquidityRemoved(idx, msg.sender, reductionRatio);
    }

    /* ****************** */
    /*     Governance     */
    /* ****************** */

    /// @notice Add one perpetual market to the list of markets
    /// @param perp Market to add to the list of supported market
    function allowListPerpetual(IPerpetual perp) external override onlyRole(GOVERNANCE) {
        if (address(perp) == address(0)) revert ClearingHouse_ZeroAddress();

        for (uint256 i = 0; i < getNumMarkets(); i++) {
            if (perpetuals[i] == perp) revert ClearingHouse_PerpetualMarketAlreadyAssigned();
        }

        perpetuals.push(perp);
        emit MarketAdded(perp, perpetuals.length);
    }

    /// @notice Add a staking contract
    /// @param staking Staking Contract
    function addStakingContract(IStakingContract staking) external override onlyRole(GOVERNANCE) {
        if (address(staking) == address(0)) revert ClearingHouse_ZeroAddress();
        stakingContract = staking;

        emit StakingContractChanged(staking);
    }

    /// @notice Pause the contract
    function pause() external override onlyRole(MANAGER) {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external override onlyRole(MANAGER) {
        _unpause();
    }

    /// @notice Sell dust in market idx
    /// @param idx Index of the perpetual market
    /// @param proposedAmount Amount of tokens to be sold, in vBase if LONG, in vQuote if SHORT. 18 decimals
    /// @param minAmount Minimum amount that the user is willing to accept, in vQuote if LONG, in vBase if SHORT. 18 decimals
    function sellDust(
        uint256 idx,
        uint256 proposedAmount,
        uint256 minAmount
    ) external override onlyRole(MANAGER) nonReentrant {
        (, , int256 profit, ) = perpetuals[idx].changePosition(
            address(this),
            proposedAmount,
            minAmount,
            LibPerpetual.Side.Short,
            false
        );

        // apply changes to collateral
        vault.settlePnL(address(this), profit);

        // withdraw
        vault.withdrawAll(address(this), vault.UA());
        IERC20Metadata(vault.UA()).safeTransfer(
            address(insurance),
            IERC20Metadata(vault.UA()).balanceOf(address(this))
        );

        emit DustSold(idx, profit);
    }

    function setParameters(ClearingHouseParams memory params) public override onlyRole(GOVERNANCE) {
        _setMinMarginAtCreation(params.minMarginAtCreation);
        _setMinMargin(params.minMargin);
        _setMinPositiveOpenNotional(params.minPositiveOpenNotional);
        _setLiquidationReward(params.liquidationReward);
        _setInsuranceRatio(params.insuranceRatio);
        _setLiquidationRewardInsuranceShare(params.liquidationRewardInsuranceShare);
        _setLiquidationDiscount(params.liquidationDiscount);
        _setNonUACollSeizureDiscount(params.nonUACollSeizureDiscount);
        _setUaDebtSeizureThreshold(params.uaDebtSeizureThreshold);

        emit ClearingHouseParametersChanged(
            params.minMargin,
            params.minMarginAtCreation,
            params.minPositiveOpenNotional,
            params.liquidationReward,
            params.insuranceRatio,
            params.liquidationRewardInsuranceShare,
            params.liquidationDiscount,
            params.nonUACollSeizureDiscount,
            params.uaDebtSeizureThreshold
        );
    }

    /* ****************** */
    /*   Market viewer    */
    /* ****************** */

    /// @notice Return the number of active markets
    /// @return Number of active markets
    function getNumMarkets() public view override returns (uint256) {
        return perpetuals.length;
    }

    /* ****************** */
    /*   User viewer      */
    /* ****************** */

    /* ****************** */
    /*   Internal user    */
    /* ****************** */

    /// @dev Liquidate a trader account
    function _liquidateTrader(
        uint256 idx,
        address liquidatee,
        uint256 proposedAmount
    ) internal returns (int256) {
        LibPerpetual.Side closeDirection = _getTraderPosition(idx, liquidatee).positionSize >= 0
            ? LibPerpetual.Side.Short
            : LibPerpetual.Side.Long;

        // (liquidatee, proposedAmount)
        (, , int256 pnL, ) = perpetuals[idx].changePosition(liquidatee, proposedAmount, 0, closeDirection, true);

        // traders are allowed to reduce their positions partially, but liquidators have to close positions in full
        if (perpetuals[idx].isTraderPositionOpen(liquidatee))
            revert ClearingHouse_LiquidateInsufficientProposedAmount();

        return pnL;
    }

    /// @dev Liquidate a lp account
    function _liquidateLp(
        uint256 idx,
        address liquidatee,
        uint256 proposedAmount
    ) internal returns (int256) {
        // close lp
        (int256 pnL, , ) = perpetuals[idx].removeLiquidity(
            liquidatee,
            _getLpLiquidity(idx, liquidatee),
            [uint256(0), uint256(0)],
            proposedAmount,
            0,
            true
        );
        _distributeLpRewards(idx, liquidatee);

        return pnL;
    }

    /// @dev sub-function of deposit()
    function _deposit(uint256 amount, IERC20Metadata token) internal {
        vault.deposit(msg.sender, amount, token);
    }

    /// @dev sub-function of changePosition()
    function _changePosition(
        uint256 idx,
        uint256 amount,
        uint256 minAmount,
        LibPerpetual.Side direction
    ) internal {
        if (amount == 0) revert ClearingHouse_ChangePositionZeroAmount();

        _settleUserFundingPayments(msg.sender);

        (int256 quoteProceeds, int256 baseProceeds, int256 profit, bool isPositionIncreased) = perpetuals[idx]
            .changePosition(msg.sender, amount, minAmount, direction, false);

        // pay insurance fee
        int256 insuranceFeeAmount = 0;
        if (isPositionIncreased) {
            insuranceFeeAmount = quoteProceeds.abs().wadMul(perpetuals[idx].insuranceFee());
            insurance.fundInsurance(insuranceFeeAmount.toUint256());
        }

        int256 traderVaultDiff = profit - insuranceFeeAmount;
        vault.settlePnL(msg.sender, traderVaultDiff);

        if (!_isPositionValid(msg.sender, minMarginAtCreation)) revert ClearingHouse_ExtendPositionInsufficientMargin();
        if (!_isOpenNotionalRequirementValid(idx, msg.sender, true))
            revert ClearingHouse_UnderOpenNotionalAmountRequired();

        emit ChangePosition(
            idx,
            msg.sender,
            direction,
            quoteProceeds,
            baseProceeds,
            traderVaultDiff,
            isPositionIncreased
        );
    }

    /// @notice Provide liquidity to the pool. Will fail if token isn't supported as collateral
    /// @dev Amount is in USD, might come from the balance of multiple collaterals
    /// @param idx Index of the perpetual market
    /// @param amounts Amount of virtual tokens ([vQuote, vBase]) provided. 18 decimals
    /// @param minLpAmount Minimum amount of Lp tokens minted. 18 decimals
    function _provideLiquidity(
        uint256 idx,
        uint256[2] calldata amounts,
        uint256 minLpAmount
    ) internal {
        if (amounts[VQUOTE_INDEX] == 0 && amounts[VBASE_INDEX] == 0) revert ClearingHouse_ProvideLiquidityZeroAmount();

        _settleUserFundingPayments(msg.sender);

        // Check enough free collateral
        int256 freeCollateralUSD = getFreeCollateralByRatio(msg.sender, minMarginAtCreation);

        // compare the dollar value of quantities q1 & q2 with the free collateral
        // @dev allow to provide liquidity with 2x leverage
        if (
            amounts[VQUOTE_INDEX].toInt256() + amounts[VBASE_INDEX].toInt256().wadMul(perpetuals[idx].indexPrice()) >
            2 * freeCollateralUSD
        ) revert ClearingHouse_AmountProvidedTooLarge();

        int256 tradingFees = perpetuals[idx].provideLiquidity(msg.sender, amounts, minLpAmount);
        if (tradingFees != 0) vault.settlePnL(msg.sender, tradingFees);

        _distributeLpRewards(idx, msg.sender);

        _isOpenNotionalRequirementValid(idx, msg.sender, false);
        _isPositionValid(msg.sender, minMarginAtCreation);

        emit LiquidityProvided(idx, msg.sender, amounts[VQUOTE_INDEX], amounts[VBASE_INDEX]);
    }

    /// @notice Settle funding payments of a user across all markets, on trading and liquidity positions
    /// @param account Address of the user to be settled
    function _settleUserFundingPayments(address account) internal {
        int256 fundingPayments;
        for (uint256 i = 0; i < getNumMarkets(); i++) {
            fundingPayments += perpetuals[i].settleTrader(account) + perpetuals[i].settleLp(account);
        }

        if (fundingPayments != 0) {
            vault.settlePnL(account, fundingPayments);
        }
    }

    function _distributeLpRewards(uint256 idx, address liquidatee) internal {
        if (address(stakingContract) != address(0)) stakingContract.updateStakingPosition(idx, liquidatee);
    }

    /* ********************** */
    /*   internal governance  */
    /* ********************** */

    function _setMinMargin(int256 newMinMargin) internal {
        if (newMinMargin < 25e15) revert ClearingHouse_InsufficientMinMargin();
        if (newMinMargin > 3e17) revert ClearingHouse_ExcessiveMinMargin();
        if (minMarginAtCreation <= newMinMargin) revert ClearingHouse_InsufficientMinMargin();

        minMargin = newMinMargin;
    }

    function _setMinMarginAtCreation(int256 newMinMarginAtCreation) internal {
        if (newMinMarginAtCreation <= minMargin) revert ClearingHouse_InsufficientMinMarginAtCreation();
        if (newMinMarginAtCreation > 5e17) revert ClearingHouse_ExcessiveMinMarginAtCreation();

        minMarginAtCreation = newMinMarginAtCreation;
    }

    /// @notice Goal make sure that liquiditors always get a minimum liquidation reward amount
    ///         because liquidationRewardAmount = liquidationReward * openNotional
    function _setMinPositiveOpenNotional(uint256 newMinPositiveOpenNotional) internal {
        if (newMinPositiveOpenNotional > 10000 * 1e18) revert ClearingHouse_ExcessivePositiveOpenNotional();

        minPositiveOpenNotional = newMinPositiveOpenNotional;
    }

    function _setLiquidationReward(uint256 newLiquidationReward) internal {
        if (newLiquidationReward < 1e16) revert ClearingHouse_InsufficientLiquidationReward();
        if (newLiquidationReward >= minMargin.toUint256()) revert ClearingHouse_ExcessiveLiquidationReward();

        liquidationReward = newLiquidationReward;
    }

    function _setLiquidationDiscount(uint256 newLiquidationDiscount) internal {
        if (nonUACollSeizureDiscount + 2e17 > newLiquidationDiscount.toInt256())
            revert ClearingHouse_InsufficientDiffBtwLiquidationDiscountAndNonUACollSeizureDiscount();

        liquidationDiscount = newLiquidationDiscount;
    }

    function _setNonUACollSeizureDiscount(int256 newNonUACollSeizureDiscount) internal {
        if (newNonUACollSeizureDiscount + 2e17 > liquidationDiscount.toInt256())
            revert ClearingHouse_InsufficientDiffBtwLiquidationDiscountAndNonUACollSeizureDiscount();

        nonUACollSeizureDiscount = newNonUACollSeizureDiscount;
    }

    function _setUaDebtSeizureThreshold(int256 newUaDebtSeizureThreshold) internal {
        if (newUaDebtSeizureThreshold < 1e20) revert ClearingHouse_InsufficientUaDebtSeizureThreshold();

        uaDebtSeizureThreshold = newUaDebtSeizureThreshold;
    }

    function _setInsuranceRatio(uint256 newInsuranceRatio) internal {
        if (newInsuranceRatio < 1e17) revert ClearingHouse_InsufficientInsuranceRatio();
        if (newInsuranceRatio > 5e17) revert ClearingHouse_ExcessiveInsuranceRatio();

        insuranceRatio = newInsuranceRatio;
    }

    function _setLiquidationRewardInsuranceShare(uint256 newLiquidationRewardInsuranceShare) internal {
        if (newLiquidationRewardInsuranceShare > 1e18) revert ClearingHouse_ExcessiveLiquidationRewardInsuranceShare();

        liquidationRewardInsuranceShare = newLiquidationRewardInsuranceShare;
    }

    /* ****************** */
    /*   internal getter  */
    /* ****************** */

    function _isOpenNotionalRequirementValid(
        uint256 idx,
        address account,
        bool isTrader
    ) internal view returns (bool) {
        int256 openNotional = isTrader
            ? _getTraderPosition(idx, account).openNotional
            : _getLpOpenNotional(idx, account);
        uint256 absOpenNotional = openNotional.abs().toUint256();

        // we don't want the check to fail if the position has been closed (e.g. in `reducePosition`)
        if (absOpenNotional > 0) {
            return absOpenNotional > minPositiveOpenNotional;
        }

        return true;
    }

    function getPnLAcrossMarkets(address account) public view override returns (int256 unrealizedPositionPnl) {
        for (uint256 i = 0; i < getNumMarkets(); i++) {
            unrealizedPositionPnl += perpetuals[i].getPendingPnL(account);
        }
    }

    function getDebtAcrossMarkets(address account) public view override returns (int256 userDebt) {
        for (uint256 i = 0; i < getNumMarkets(); i++) {
            uint256 weight = perpetuals[i].riskWeight();
            userDebt += perpetuals[i].getUserDebt(account).wadMul(weight.toInt256());
        }
    }

    /// @notice Determines whether or not a position is valid for a given margin ratio
    /// @param account Account of the position to get the margin ratio from
    /// @param ratio Proposed ratio to compare the position against
    /// @return True if the position exceeds margin ratio, false otherwise
    function _isPositionValid(address account, int256 ratio) internal view returns (bool) {
        return getFreeCollateralByRatio(account, ratio) >= 0;
    }

    function getTotalMarginRequirement(address account, int256 ratio) public view returns (int256 requiredMargin) {
        int256 userDebt = getDebtAcrossMarkets(account);

        return userDebt.wadMul(ratio);
    }

    function getFreeCollateralByRatio(address account, int256 ratio) public view returns (int256 freeCollateral) {
        int256 pnl = getPnLAcrossMarkets(account);
        int256 reserveValue = _getReserveValue(account, true);

        int256 marginRequired = getTotalMarginRequirement(account, ratio);

        return reserveValue.min(reserveValue + pnl) - marginRequired;
    }

    function _getReserveValue(address account, bool isDiscounted) internal view returns (int256) {
        return vault.getReserveValue(account, isDiscounted);
    }

    function _getTraderPosition(uint256 idx, address account)
        internal
        view
        returns (LibPerpetual.TraderPosition memory)
    {
        return perpetuals[idx].getTraderPosition(account);
    }

    function _getLpLiquidity(uint256 idx, address account) internal view returns (uint256) {
        return perpetuals[idx].getLpLiquidity(account);
    }

    function _getLpOpenNotional(uint256 idx, address account) internal view returns (int256) {
        return perpetuals[idx].getLpOpenNotional(account);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IClearingHouse} from "./IClearingHouse.sol";
import {IPerpetual} from "./IPerpetual.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IVault} from "./IVault.sol";
import {IInsurance} from "./IInsurance.sol";
import {ICryptoSwap} from "./ICryptoSwap.sol";
import {IStakingContract} from "./IStakingContract.sol";

// libraries
import {LibPerpetual} from "../lib/LibPerpetual.sol";

interface IClearingHouse {
    struct ClearingHouseParams {
        int256 minMargin;
        int256 minMarginAtCreation;
        uint256 minPositiveOpenNotional;
        uint256 liquidationReward;
        uint256 insuranceRatio;
        uint256 liquidationRewardInsuranceShare;
        uint256 liquidationDiscount;
        int256 nonUACollSeizureDiscount;
        int256 uaDebtSeizureThreshold;
    }

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the zero address is provided
    error ClearingHouse_ZeroAddress();

    /// @notice Emitted when passing the address of a perpetual market which has already been added
    error ClearingHouse_PerpetualMarketAlreadyAssigned();

    /// @notice Emitted when there is not enough margin to withdraw the requested amount
    error ClearingHouse_WithdrawInsufficientMargin();

    /// @notice Emitted when the position is not reduced entirely using closePositionWithdrawCollateral
    error ClearingHouse_ClosePositionStillOpen();

    /// @notice Emitted when the liquidatee does not have an open position
    error ClearingHouse_LiquidateInvalidPosition();

    /// @notice Emitted when the margin of the liquidatee's position is still valid
    error ClearingHouse_LiquidateValidMargin();

    /// @notice Emitted when the attempted liquidation does not close the full position
    error ClearingHouse_LiquidateInsufficientProposedAmount();

    /// @notice Emitted when attempting to seize collateral of a user with an open position
    error ClearingHouse_SeizeCollateralStillOpen();

    /// @notice Emitted when a user attempts to provide liquidity with amount equal to 0
    error ClearingHouse_ProvideLiquidityZeroAmount();

    /// @notice Emitted when a user attempts to provide liquidity with amount larger than his free collateral or collateral balance
    error ClearingHouse_AmountProvidedTooLarge();

    /// @notice Emitted when a user attempts to withdraw more liquidity than they have
    error ClearingHouse_RemoveLiquidityInsufficientFunds();

    /// @notice Emitted when vault withdrawal is unsuccessful
    error ClearingHouse_VaultWithdrawUnsuccessful();

    /// @notice Emitted when the proposed minMargin is too low
    error ClearingHouse_InsufficientMinMargin();

    /// @notice Emitted when the proposed minMargin is too high
    error ClearingHouse_ExcessiveMinMargin();

    error ClearingHouse_ExcessivePositiveOpenNotional();

    /// @notice Emitted when the proposed minMarginAtCreation is too low
    error ClearingHouse_InsufficientMinMarginAtCreation();

    /// @notice Emitted when the proposed minMarginAtCreation is too low
    error ClearingHouse_ExcessiveMinMarginAtCreation();

    /// @notice Emitted when the proposed liquidation reward is too low
    error ClearingHouse_InsufficientLiquidationReward();

    /// @notice Emitted when the proposed liquidation reward is too high
    error ClearingHouse_ExcessiveLiquidationReward();

    /// @notice Emitted when the proposed insurance ratio is too low
    error ClearingHouse_InsufficientInsuranceRatio();

    /// @notice Emitted when the proposed insurance ratio is too high
    error ClearingHouse_ExcessiveInsuranceRatio();

    /// @notice Emitted when the proposed share of the liquidation reward for the insurance is too high
    error ClearingHouse_ExcessiveLiquidationRewardInsuranceShare();

    /// @notice Emitted when the difference between liquidationDiscount and nonUACollSeizureDiscount isn't large enough
    error ClearingHouse_InsufficientDiffBtwLiquidationDiscountAndNonUACollSeizureDiscount();

    /// @notice Emitted when the proposed UA debt limit is lower than the minimum acceptable value
    error ClearingHouse_InsufficientUaDebtSeizureThreshold();

    /// @notice Emitted when a user attempts to extend their position with amount equal to 0
    error ClearingHouse_ExtendPositionZeroAmount();

    /// @notice Emitted when there is not enough margin to extend to the proposed position amount
    error ClearingHouse_ExtendPositionInsufficientMargin();

    /// @notice Emitted when a user attempts to reduce their position with amount equal to 0
    error ClearingHouse_ReducePositionZeroAmount();

    error ClearingHouse_ChangePositionZeroAmount();

    /// @notice Emitted when a user tries to open a position with an incorrect open notional amount
    error ClearingHouse_UnderOpenNotionalAmountRequired();

    /// @notice Emitted when a collateral liquidation for a user with no UA debt is tried
    error ClearingHouse_LiquidationDebtSizeZero();

    /// @notice Emitted when a liquidator tries seizing collateral of user with sufficient collaterals level
    error ClearingHouse_SufficientUserCollateral();

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when new perpetual market is added
    /// @param perpetual New perpetual market
    /// @param numPerpetuals Number of perpetual markets
    event MarketAdded(IPerpetual indexed perpetual, uint256 numPerpetuals);

    /// @notice Emitted when a position is extended/opened
    /// @param idx Index of the perpetual market
    /// @param user User who deposited collateral
    /// @param direction Whether the position is LONG or SHORT
    /// @param addedOpenNotional Notional (USD assets/debt) added to the position
    /// @param addedPositionSize positionSize (Base assets/debt) added to the position
    /// @param profit Sum of pnL + tradingFeesPayed + fundingPaymentsPaid
    /// @param isPositionIncreased Whether the position was extended or reduced / reversed
    event ChangePosition(
        uint256 indexed idx,
        address indexed user,
        LibPerpetual.Side direction,
        int256 addedOpenNotional,
        int256 addedPositionSize,
        int256 profit,
        bool isPositionIncreased
    );

    /// @notice Emitted when a trader position is liquidated
    /// @param idx Index of the perpetual market
    /// @param liquidatee User who gets liquidated
    /// @param liquidator User who is liquidating
    /// @param notional Notional amount of the liquidatee
    event LiquidationCall(
        uint256 indexed idx,
        address indexed liquidatee,
        address indexed liquidator,
        uint256 notional
    );

    /// @notice Emitted when a trader position is liquidated
    /// @param liquidatee User who gets liquidated
    /// @param liquidator User who is liquidating
    event SeizeCollateral(address indexed liquidatee, address indexed liquidator);

    /// @notice Emitted when (additional) liquidity is provided
    /// @param idx Index of the perpetual market
    /// @param liquidityProvider User who provides liquidity
    /// @param quoteAmount vQuote amount (i.e. USD amount) to be added to the targeted market
    /// @param baseAmount vBase amount (i.e. Base amount) to be added to the targeted market
    event LiquidityProvided(
        uint256 indexed idx,
        address indexed liquidityProvider,
        uint256 quoteAmount,
        uint256 baseAmount
    );

    /// @notice Emitted when liquidity is removed
    /// @param idx Index of the perpetual market
    /// @param liquidityProvider User who provides liquidity
    /// @param reductionRatio Pourcentage of previous position reduced
    event LiquidityRemoved(uint256 indexed idx, address indexed liquidityProvider, uint256 reductionRatio);

    /// @notice Emitted when dust is sold by governance
    /// @param idx Index of the perpetual market
    /// @param profit Amount of profit generated by the dust sale. 18 decimals
    event DustSold(uint256 indexed idx, int256 profit);

    /// @notice Emitted when parameters are changed
    event ClearingHouseParametersChanged(
        int256 newMinMargin,
        int256 newMinMarginAtCreation,
        uint256 newMinPositiveOpenNotional,
        uint256 newLiquidationReward,
        uint256 newInsuranceRatio,
        uint256 newLiquidationRewardInsuranceShare,
        uint256 newLiquidationDiscount,
        int256 nonUACollSeizureDiscount,
        int256 uaDebtSeizureThreshold
    );

    event StakingContractChanged(IStakingContract newStakingContract);

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function vault() external view returns (IVault);

    function insurance() external view returns (IInsurance);

    function perpetuals(uint256 idx) external view returns (IPerpetual);

    function stakingContract() external view returns (IStakingContract);

    function getNumMarkets() external view returns (uint256);

    function minMargin() external view returns (int256);

    function minMarginAtCreation() external view returns (int256);

    function minPositiveOpenNotional() external view returns (uint256);

    function liquidationReward() external view returns (uint256);

    function insuranceRatio() external view returns (uint256);

    function liquidationRewardInsuranceShare() external view returns (uint256);

    function liquidationDiscount() external view returns (uint256);

    function nonUACollSeizureDiscount() external view returns (int256);

    function uaDebtSeizureThreshold() external view returns (int256);

    function getPnLAcrossMarkets(address account) external view returns (int256);

    function getDebtAcrossMarkets(address account) external view returns (int256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function allowListPerpetual(IPerpetual perp) external;

    function pause() external;

    function unpause() external;

    function sellDust(
        uint256 idx,
        uint256 proposedAmount,
        uint256 minAmount
    ) external;

    function setParameters(ClearingHouseParams memory params) external;

    function addStakingContract(IStakingContract staking) external;

    function deposit(uint256 amount, IERC20Metadata token) external;

    function withdraw(uint256 amount, IERC20Metadata token) external;

    function withdrawAll(IERC20Metadata token) external;

    function changePosition(
        uint256 idx,
        uint256 amount,
        uint256 minAmount,
        LibPerpetual.Side direction
    ) external;

    function extendPositionWithCollateral(
        uint256 idx,
        uint256 collateralAmount,
        IERC20Metadata token,
        uint256 positionAmount,
        LibPerpetual.Side direction,
        uint256 minAmount
    ) external;

    function closePositionWithdrawCollateral(
        uint256 idx,
        uint256 proposedAmount,
        uint256 minAmount,
        IERC20Metadata token
    ) external;

    function openReversePosition(
        uint256 idx,
        uint256 closeProposedAmount,
        uint256 closeMinAmount,
        uint256 openProposedAmount,
        uint256 openMinAmount,
        LibPerpetual.Side direction
    ) external;

    function liquidate(
        uint256 idx,
        address liquidatee,
        uint256 proposedAmount,
        bool isTrader
    ) external;

    function seizeCollateral(address liquidatee) external;

    function provideLiquidity(
        uint256 idx,
        uint256[2] calldata amounts,
        uint256 minLpAmount
    ) external;

    function removeLiquidity(
        uint256 idx,
        uint256 liquidityAmountToRemove,
        uint256[2] calldata minVTokenAmounts,
        uint256 proposedAmount,
        uint256 minAmount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

/// @dev Contract https://github.com/curvefi/curve-crypto-contract/blob/master/deployment-logs/2021-11-01.%20EURS%20on%20mainnet/CryptoSwap.vy
interface ICryptoSwap {
    function get_virtual_price() external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function mid_fee() external view returns (uint256);

    function out_fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    // Swap token i to j with amount dx and min amount min_dy
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256); // WARNING: Has to be memory to be called within the perpetual contract, but you should use calldata

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external; // WARNING: Has to be memory to be called within the perpetual contract, but you should use calldata

    function last_prices() external view returns (uint256);

    function token() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IIncreAccessControl is IAccessControl {
    /* ****************** */
    /*     Events         */
    /* ****************** */

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function isGovernor(address account) external view returns (bool);

    function isManager(address account) external view returns (bool);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

import {IClearingHouse} from "./IClearingHouse.sol";

interface IInsurance {
    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the zero address is provided as a parameter in the constructor
    error Insurance_ZeroAddressConstructor(uint8 paramIndex);

    /// @notice Emitted when the sender is not the vault address
    error Insurance_SenderNotVault();

    /// @notice Emitted when the sender is not the clearingHouse address
    error Insurance_SenderNotClearingHouse();

    /// @notice Emitted when the balance of the vault is less than the amount to be settled
    error Insurance_InsufficientBalance();

    /// @notice Emitted when locked insurance falls below insurance ratio
    error Insurance_InsufficientInsurance();

    /// @notice Emitted when the proposed clearingHouse address is equal to the zero address
    error Insurance_ClearingHouseZeroAddress();

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when a new ClearingHouse is connected to the issuer
    /// @param newClearingHouse New ClearingHouse contract address
    event ClearingHouseChanged(IClearingHouse newClearingHouse);

    /// @notice Emitted when (exceeding) insurance reserves are withdrawn by governance
    /// @param amount Amount of insurance reserves withdrawn. 18 decimals
    event InsuranceRemoved(uint256 amount);

    /// @notice Emitted when a bail out cant be fully served
    /// @param newSystemDebt New amount of system debt. 18 decimals (accounted for in UA)
    event SystemDebtChanged(uint256 newSystemDebt);

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function fundInsurance(uint256 amount) external;

    function settleDebt(uint256 amount) external;

    function removeInsurance(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @notice Oracle interface created to ease oracle contract switch
interface IOracle {
    struct AssetOracle {
        uint24 heartBeat;
        AggregatorV3Interface aggregator; // aggregator of the ERC20 token for ERC4626 tokens
        bool isVaultAsset;
        int256 fixedPrice;
    }

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when oracle heart beat is updated
    /// @param asset Asset that got linked to an oracle
    /// @param aggregator Chainlink aggregator used as the asset oracle
    /// @param isVault True if the asset is a ERC-4626 vault asset
    event OracleUpdated(address asset, AggregatorV3Interface aggregator, bool isVault);

    /// @notice Emitted when an asset got a fixed price when requesting an oracle
    /// @param asset Asset which got a fixed price
    /// @param fixedPrice Fixed price that the asset got
    event AssetGotFixedPrice(address asset, int256 fixedPrice);

    /// @notice Emitted when oracle heart beat is updated
    /// @param asset Asset whose heartBeat is updated
    /// @param newHeartBeat New heart beat value
    event HeartBeatUpdated(address asset, uint24 newHeartBeat);

    /// @notice Emitted when sequencer uptime feed is updated
    /// @param newSequencerUptimeFeed New sequencer uptime feed
    event SequencerUptimeFeedUpdated(AggregatorV3Interface newSequencerUptimeFeed);

    /// @notice Emitted when grace period is updated
    /// @param newGracePeriod New grace period
    event GracePeriodUpdated(uint256 newGracePeriod);

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the latest round is incomplete
    error Oracle_InvalidRoundTimestamp();

    /// @notice Emitted when the latest round's price is invalid
    error Oracle_InvalidRoundPrice();

    /// @notice Emitted when the latest round's data is older than the oracle's max refresh time
    error Oracle_DataNotFresh();

    /// @notice Emitted when the proposed asset address is equal to the zero address
    error Oracle_AssetZeroAddress();

    /// @notice Emitted when the proposed aggregator address is equal to the zero address
    error Oracle_AggregatorZeroAddress();

    /// @notice Emitted when the proposed sequencer uptime feed address is equal to the zero address
    error Oracle_SequencerUptimeFeedZeroAddress();

    /// @notice Emitted when owner tries to set fixed price to an unsupported asset
    error Oracle_UnsupportedAsset();

    /// @notice Emitted when Zksync sequencer is down
    error Oracle_SequencerDown();

    /// @notice Emitted when Zksync sequencer hasn't been back up for long enough
    error Oracle_GracePeriodNotOver();

    /// @notice Emitted when proposed grace period doesn't fit in the defined bounds
    error Oracle_IncorrectGracePeriod();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function gracePeriod() external view returns (uint256);

    function sequencerUptimeFeed() external view returns (AggregatorV3Interface);

    function getPrice(address asset, int256 erc4626Shares) external view returns (int256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function setOracle(
        address asset,
        AggregatorV3Interface aggregator,
        uint24 heartBeat,
        bool isVault
    ) external;

    function setFixedPrice(address asset, int256 fixedPrice) external;

    function setHeartBeat(address asset, uint24 newHeartBeat) external;

    function setSequencerUptimeFeed(AggregatorV3Interface newSequencerUptimeFeed) external;

    function setGracePeriod(uint256 newGracePeriod) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {ICryptoSwap} from "./ICryptoSwap.sol";
import {IVault} from "./IVault.sol";
import {ICryptoSwap} from "./ICryptoSwap.sol";
import {IVBase} from "./IVBase.sol";
import {IVQuote} from "./IVQuote.sol";
import {IInsurance} from "./IInsurance.sol";
import {IClearingHouse} from "./IClearingHouse.sol";

// libraries
import {LibPerpetual} from "../lib/LibPerpetual.sol";

interface IPerpetual {
    struct PerpetualParams {
        uint256 riskWeight;
        uint256 maxLiquidityProvided;
        uint256 twapFrequency;
        int256 sensitivity;
        uint256 maxBlockTradeAmount;
        int256 insuranceFee;
        int256 tradingFee;
        int256 lpDebtCoef;
        uint256 lockPeriod;
    }

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the zero address is provided as a parameter in the constructor
    error Perpetual_ZeroAddressConstructor(uint256 paramIndex);

    /// @notice Emitted when the constructor fails to give approval of a virtual token to the market
    error Perpetual_VirtualTokenApprovalConstructor(uint256 tokenIndex);

    /// @notice Emitted when market mid fee does not equal out fee
    error Perpetual_MarketEqualFees();

    /// @notice Emitted when the curve admin fee is invalid
    error Perpetual_InvalidAdminFee();

    /// @notice Emitted when the sender is not the clearing house
    error Perpetual_SenderNotClearingHouse();

    /// @notice Emitted when the sender is not the clearing house owner
    error Perpetual_SenderNotClearingHouseOwner();

    /// @notice Emitted when the user attempts to reduce their position using extendPosition
    error Perpetual_AttemptReducePosition();

    /// @notice Emitted when the user attempts to reverse their position using changePosition
    error Perpetual_AttemptReversePosition();

    /// @notice Emitted when the price impact of a position is too high
    error Perpetual_ExcessiveBlockTradeAmount();

    /// @notice Emitted when the user does not have an open position
    error Perpetual_NoOpenPosition();

    /// @notice Emitted when the user attempts to withdraw more liquidity than they have deposited
    error Perpetual_LPWithdrawExceedsBalance();

    /// @notice Emitted when the proposed twap frequency is insufficient/excessive
    error Perpetual_TwapFrequencyInvalid(uint256 twapFrequency);

    /// @notice Emitted when the proposed funding rate sensitivity is insufficient/excessive
    error Perpetual_SensitivityInvalid(int256 sensitivity);

    /// @notice Emitted when the proposed maximum block trade amount is insufficient
    error Perpetual_MaxBlockAmountInvalid(uint256 maxBlockTradeAmount);

    /// @notice Emitted when the proposed insurance fee is insufficient/excessive
    error Perpetual_InsuranceFeeInvalid(int256 fee);

    /// @notice Emitted when the proposed trading fee is insufficient/excessive
    error Perpetual_TradingFeeInvalid(int256 fee);

    /// @notice Emitted when the proposed lp debt coefficient is insufficient/excessive
    error Perpetual_LpDebtCoefInvalid(int256 lpDebtCoef);

    /// @notice Emitted when the proposed lp lock period is insufficient/excessive
    error Perpetual_LockPeriodInvalid(uint256 lockPeriod);

    /// @notice Emitted when a token balance of the market is lte 1
    error Perpetual_MarketBalanceTooLow();

    /// @notice Emitted when the liquidity provider has an open position
    error Perpetual_LPOpenPosition();

    /// @notice Emitted when proposed amount is greater than position size
    error Perpetual_ProposedAmountExceedsPositionSize();

    /// @notice Emitted when proposed amount is greater than maxVQuoteAmount
    error Perpetual_ProposedAmountExceedsMaxMarketPrice();

    /// @notice Emitted when the max tvl is reached
    error Perpetual_MaxLiquidityProvided();

    /// @notice Emitted when the position exceeds the max position size
    error Perpetual_MaxPositionSize();

    /// @notice Emitted when the user attempts provide liquidity with skewed ratios
    error Perpetual_LpAmountDeviation();

    /// @notice Emitted when the user attempts remove liquidity too early
    error Perpetual_LockPeriodNotReached(uint256 withdrawTime);

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when twap is updated
    /// @param newOracleTwap Latest oracle Time-weighted-average-price
    /// @param newMarketTwap Latest market Time-weighted-average-price
    event TwapUpdated(int256 newOracleTwap, int256 newMarketTwap);

    /// @notice Emitted when funding rate is updated
    /// @param cumulativeFundingRate Cumulative sum of all funding rate updates
    /// @param fundingRate Latest fundingRate update
    event FundingRateUpdated(int256 cumulativeFundingRate, int256 fundingRate);

    /// @notice Emitted when swap with cryptoswap pool fails
    /// @param errorMessage Return error message
    event Log(string errorMessage);

    /// @notice Emitted when (base) dust is generated
    /// @param vBaseAmount Amount of dust
    event DustGenerated(uint256 vBaseAmount);

    /// @notice Emitted when parameters are changed
    event PerpetualParametersChanged(
        uint256 newRiskWeight,
        uint256 newMaxLiquidityProvided,
        uint256 newTwapFrequency,
        int256 newSensitivity,
        uint256 newMaxBlockTradeAmount,
        int256 newInsuranceFee,
        int256 newTradingFee,
        int256 newLpDebtCoef,
        uint256 lockPeriod
    );

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function market() external view returns (ICryptoSwap);

    function vBase() external view returns (IVBase);

    function vQuote() external view returns (IVQuote);

    function clearingHouse() external view returns (IClearingHouse);

    function maxLiquidityProvided() external view returns (uint256);

    function riskWeight() external view returns (uint256);

    function twapFrequency() external view returns (uint256);

    function sensitivity() external view returns (int256);

    function maxBlockTradeAmount() external view returns (uint256);

    function maxPosition() external view returns (uint256);

    function tradingFee() external view returns (int256);

    function insuranceFee() external view returns (int256);

    function lpDebtCoef() external view returns (int256);

    function lockPeriod() external view returns (uint256);

    function oracleTwap() external view returns (int256);

    function marketTwap() external view returns (int256);

    function getTraderPosition(address account) external view returns (LibPerpetual.TraderPosition memory);

    function getLpPositionAfterWithdrawal(address account) external view returns (LibPerpetual.TraderPosition memory);

    function getLpLiquidity(address account) external view returns (uint256);

    function getLpPosition(address account) external view returns (LibPerpetual.LiquidityProviderPosition memory);

    function getGlobalPosition() external view returns (LibPerpetual.GlobalPosition memory);

    function getTraderUnrealizedPnL(address account) external view returns (int256);

    function getTraderFundingPayments(address account) external view returns (int256);

    function getLpUnrealizedPnL(address account) external view returns (int256);

    function getLpFundingPayments(address account) external view returns (int256);

    function getLpTradingFees(address account) external view returns (uint256);

    function marketPrice() external view returns (uint256);

    function indexPrice() external view returns (int256);

    function getTotalLiquidityProvided() external view returns (uint256);

    function getPendingPnL(address account) external view returns (int256 pnL);

    function getUserDebt(address account) external view returns (int256 debt);

    function isTraderPositionOpen(address account) external view returns (bool);

    function isLpPositionOpen(address account) external view returns (bool);

    function getLpOpenNotional(address account) external view returns (int256);

    /* ************* */
    /*    Helpers    */
    /* ************* */

    function removeLiquiditySwap(
        address user,
        uint256 liquidityAmountToRemove,
        uint256[2] calldata minVTokenAmounts,
        uint256 proposedAmount
    ) external;

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function changePosition(
        address account,
        uint256 amount,
        uint256 minAmount,
        LibPerpetual.Side direction,
        bool isLiquidation
    )
        external
        returns (
            int256 openNotional,
            int256 positionSize,
            int256 profit,
            bool isPositionIncreased
        );

    function provideLiquidity(
        address account,
        uint256[2] calldata amounts,
        uint256 minLpAmount
    ) external returns (int256 tradingFees);

    function removeLiquidity(
        address account,
        uint256 liquidityAmountToRemove,
        uint256[2] calldata minVTokenAmounts,
        uint256 proposedAmount,
        uint256 minAmount,
        bool isLiquidation
    )
        external
        returns (
            int256 profit,
            uint256 reductionRatio,
            int256 quoteProceeds
        );

    function settleTrader(address account) external returns (int256 fundingPayments);

    function settleLp(address account) external returns (int256 fundingPayments);

    function pause() external;

    function unpause() external;

    function setParameters(PerpetualParams memory params) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

interface IStakingContract {
    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function updateStakingPosition(uint256 idx, address lp) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IVirtualToken} from "../interfaces/IVirtualToken.sol";

interface IVBase is IVirtualToken {
    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when oracle heart beat is updated
    /// @param newHeartBeat New heart beat value
    event HeartBeatUpdated(uint256 newHeartBeat);

    /// @notice Emitted when sequencer uptime feed is updated
    /// @param newSequencerUptimeFeed New sequencer uptime feed
    event SequencerUptimeFeedUpdated(AggregatorV3Interface newSequencerUptimeFeed);

    /// @notice Emitted when grace period is updated
    /// @param newGracePeriod New grace period
    event GracePeriodUpdated(uint256 newGracePeriod);

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the proposed aggregators decimals are less than PRECISION
    error VBase_InsufficientPrecision();

    /// @notice Emitted when the latest round is incomplete
    error VBase_InvalidRoundTimestamp();

    /// @notice Emitted when the latest round's price is invalid
    error VBase_InvalidRoundPrice();

    /// @notice Emitted when the latest round's data is older than the oracle's max refresh time
    error VBase_DataNotFresh();

    /// @notice Emitted when proposed sequencer uptime feed address is equal to the zero address
    error VBase_SequencerUptimeFeedZeroAddress();

    /// @notice Emitted when proposed grace period is outside of the bounds
    error VBase_IncorrectGracePeriod();

    /// @notice Emitted when Zksync sequencer is down
    error VBase_SequencerDown();

    /// @notice Emitted when Zksync sequencer hasn't been back up for long enough
    error VBase_GracePeriodNotOver();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function getIndexPrice() external view returns (int256);

    function heartBeat() external view returns (uint256);

    function sequencerUptimeFeed() external view returns (AggregatorV3Interface);

    function gracePeriod() external view returns (uint256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function setHeartBeat(uint256 newHeartBeat) external;

    function setSequencerUptimeFeed(AggregatorV3Interface newSequencerUptimeFeed) external;

    function setGracePeriod(uint256 newGracePeriod) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IVirtualToken} from "../interfaces/IVirtualToken.sol";

interface IVQuote is IVirtualToken {}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IInsurance} from "./IInsurance.sol";
import {IOracle} from "./IOracle.sol";
import {IClearingHouse} from "./IClearingHouse.sol";

// @dev: deposit uint and withdraw int
// @author: The interface used in other contracts
interface IVault {
    struct Collateral {
        IERC20Metadata asset;
        uint256 weight;
        uint8 decimals;
        uint256 currentAmount;
        uint256 maxAmount;
    }

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the zero address is provided as a parameter in the constructor
    error Vault_ZeroAddressConstructor(uint8 paramIndex);

    /// @notice Emitted when user tries to withdraw collateral while having a UA debt
    error Vault_UADebt();

    /// @notice Emitted when the sender is not the clearing house
    error Vault_SenderNotClearingHouse();

    /// @notice Emitted when the sender is not the clearing house, nor the insurance
    error Vault_SenderNotClearingHouseNorInsurance();

    /// @notice Emitted when a user attempts to use a token which is not whitelisted as collateral
    error Vault_UnsupportedCollateral();

    /// @notice Emitted when owner tries to whitelist a collateral already whitelisted
    error Vault_CollateralAlreadyWhiteListed();

    /// @notice Emitted when a user attempts to withdraw with a reduction ratio above 1e18
    error Vault_WithdrawReductionRatioTooHigh();

    /// @notice Emitted when a user attempts to withdraw more than their balance
    error Vault_WithdrawExcessiveAmount();

    /// @notice Emitted when the proposed clearingHouse address is equal to the zero address
    error Vault_ClearingHouseZeroAddress();

    /// @notice Emitted when the proposed insurance address is equal to the zero address
    error Vault_InsuranceZeroAddress();

    /// @notice Emitted when the proposed oracle address is equal to the zero address
    error Vault_OracleZeroAddress();

    /// @notice Emitted when the proposed collateral weight is under the limit
    error Vault_InsufficientCollateralWeight();

    /// @notice Emitted when the proposed collateral weight is above the limit
    error Vault_ExcessiveCollateralWeight();

    /// @notice Emitted when a user attempts to withdraw more collateral than available in vault
    error Vault_InsufficientBalance();

    /// @notice Emitted when a user attempts to withdraw more collateral than available in vault
    error Vault_MaxCollateralAmountExceeded();

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when collateral is deposited into the vault
    /// @param user User who deposited collateral
    /// @param asset Token to be used for the collateral
    /// @param amount Amount to be used as collateral. Might not be 18 decimals
    event Deposit(address indexed user, address indexed asset, uint256 amount);

    /// @notice Emitted when collateral is withdrawn from the vault
    /// @param user User who deposited collateral
    /// @param asset Token to be used for the collateral
    /// @param amount Amount to be used as collateral. Might not be 18 decimals
    event Withdraw(address indexed user, address indexed asset, uint256 amount);

    /// @notice Emitted when bad debt is settled for by the insurance reserve
    /// @param beneficiary Beneficiary of the insurance payment
    /// @param amount Amount of bad insurance requested
    event TraderBadDebtGenerated(address beneficiary, uint256 amount);

    /// @notice Emitted when a new ClearingHouse is connected to the vault
    /// @param newClearingHouse New ClearingHouse contract address
    event ClearingHouseChanged(IClearingHouse newClearingHouse);

    /// @notice Emitted when a new Insurance is connected to the vault
    /// @param newInsurance New Insurance contract address
    event InsuranceChanged(IInsurance newInsurance);

    /// @notice Emitted when a new Oracle is connected to the vault
    /// @param newOracle New Oracle contract address
    event OracleChanged(IOracle newOracle);

    /// @notice Emitted when a new Oracle is connected to the vault
    /// @param asset Asset added as collateral
    /// @param weight Volatility measure of the asset
    /// @param maxAmount weight for the collateral
    event CollateralAdded(IERC20Metadata asset, uint256 weight, uint256 maxAmount);

    /// @notice Emitted when a collateral weight changed
    /// @param asset Asset targeted by the change
    /// @param newWeight New volatility measure for the collateral
    event CollateralWeightChanged(IERC20Metadata asset, uint256 newWeight);

    /// @notice Emitted when a collateral max amount changed
    /// @param asset Asset targeted by the change
    /// @param newMaxAmount New weight for the collateral
    event CollateralMaxAmountChanged(IERC20Metadata asset, uint256 newMaxAmount);

    /* ****************** */
    /*     Viewer         */
    /* ****************** */
    function insurance() external view returns (IInsurance);

    function oracle() external view returns (IOracle);

    function clearingHouse() external view returns (IClearingHouse);

    // slither-disable-next-line naming-convention
    function UA() external view returns (IERC20Metadata);

    function tokenToCollateralIdx(IERC20Metadata token) external view returns (uint256);

    function getTotalValueLocked() external view returns (int256);

    function getWhiteListedCollateral(uint256 idx) external view returns (Collateral memory);

    function getNumberOfCollaterals() external view returns (uint256);

    function getReserveValue(address trader, bool isDiscounted) external view returns (int256);

    function getBalance(address user, uint256 tokenIdx) external view returns (int256);

    function getDiscountedCollateralUSDValue(uint256 tokenIdx, int256 collateralBalance) external view returns (int256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function deposit(
        address user,
        uint256 amount,
        IERC20Metadata token
    ) external;

    function settlePnL(address user, int256 amount) external;

    function withdraw(
        address user,
        uint256 amount,
        IERC20Metadata token
    ) external;

    function withdrawAll(address user, IERC20Metadata withdrawToken) external;

    function settleLiquidationOnCollaterals(address liquidator, address liquidatee) external;

    function transferUa(address user, uint256 amount) external;

    /* ****************** */
    /*     Governance     */
    /* ****************** */

    function setClearingHouse(IClearingHouse newClearingHouse) external;

    function setInsurance(IInsurance newInsurance) external;

    function setOracle(IOracle newOracle) external;

    function addWhiteListedCollateral(
        IERC20Metadata asset,
        uint256 weight,
        uint256 maxAmount
    ) external;

    function changeCollateralWeight(IERC20Metadata asset, uint256 newWeight) external;

    function changeCollateralMaxAmount(IERC20Metadata asset, uint256 newMaxAmount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVirtualToken is IERC20Metadata {
    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function mint(uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// libraries
import {PRBMathUD60x18} from "prb-math/contracts/PRBMathUD60x18.sol";
import {PRBMathSD59x18} from "prb-math/contracts/PRBMathSD59x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";

/*
 * To be used if `b` decimals make `b` larger than what it would be otherwise.
 * Especially useful for fixed point numbers, i.e. a way to represent decimal
 * values without using decimals. E.g. 25e2 with 3 decimals represents 2.5%
 *
 * In our case, we get exchange rates with a 18 decimal precision
 * (Solidity doesn't support decimal values natively).
 * So if we have a EUR positions and want to get the equivalent USD amount
 * we have to do: EUR_position * EUR_USD / 1e18 else the value would be way too high.
 * To move from USD to EUR: (USD_position * 1e18) / EUR_USD else the value would
 * be way too low.
 *
 * In essence,
 * wadMul: a.mul(b).div(WAY)
 * wadDiv: a.mul(WAY).div(b)
 * where `WAY` represents the number of decimals
 */
library LibMath {
    // safe casting
    function toInt256(uint256 x) internal pure returns (int256) {
        return SafeCast.toInt256(x);
    }

    function toUint256(int256 x) internal pure returns (uint256) {
        return SafeCast.toUint256(x);
    }

    // absolute value
    function abs(int256 x) internal pure returns (int256) {
        return PRBMathSD59x18.abs(x);
    }

    // min value
    function min(int256 x, int256 y) internal pure returns (int256) {
        return SignedMath.min(x, y);
    }

    // int256: wad division / multiplication
    function wadDiv(int256 x, int256 y) internal pure returns (int256) {
        return PRBMathSD59x18.div(x, y);
    }

    function wadMul(int256 x, int256 y) internal pure returns (int256) {
        return PRBMathSD59x18.mul(x, y);
    }

    // uint256: wad division / multiplication
    function wadMul(uint256 x, uint256 y) internal pure returns (uint256) {
        return PRBMathUD60x18.mul(x, y);
    }

    function wadDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return PRBMathUD60x18.div(x, y);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// libraries
import {LibMath} from "./LibMath.sol";

library LibPerpetual {
    using LibMath for int256;
    using LibMath for uint256;

    enum Side {
        // long position
        Long,
        // short position
        Short
    }

    struct LiquidityProviderPosition {
        // quote assets or liabilities
        int256 openNotional;
        // base assets or liabilities
        int256 positionSize;
        // user cumulative funding rate (updated when open/close position)
        int256 cumFundingRate;
        // lp token owned (is zero for traders)
        uint256 liquidityBalance;

        // last time when liquidity was provided
        uint256 depositTime;


        // total percentage return of liquidity providers index
        uint256 totalTradingFeesGrowth;
        // total base fees paid in cryptoswap pool
        uint256 totalBaseFeesGrowth;
        // total quote fees paid in cryptoswap pool
        uint256 totalQuoteFeesGrowth;
    }

    struct TraderPosition {
        // quote assets or liabilities
        int256 openNotional;
        // base assets or liabilities
        int256 positionSize;
        // user cumulative funding rate (updated when open/close position)
        int256 cumFundingRate;
    }

    struct GlobalPosition {
        /* twap state */

        // timestamp of last trade
        uint128 timeOfLastTrade;
        // timestamp of last TWAP update
        uint128 timeOfLastTwapUpdate;
        // global cumulative funding rate (updated every trade)
        int256 cumFundingRate;
        // current trade amount in the block
        uint256 currentBlockTradeAmount;
        /* fees state */

        // total percentage return of liquidity providers index
        uint256 totalTradingFeesGrowth;
        // total liquidity provided (in vQuote)
        uint256 totalLiquidityProvided;
        // total base fees paid in cryptoswap pool
        uint256 totalBaseFeesGrowth;
        // total quote fees paid in cryptoswap pool
        uint256 totalQuoteFeesGrowth;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// libraries
import {LibMath} from "./LibMath.sol";

library LibReserve {
    using LibMath for uint256;

    uint8 internal constant PROTOCOL_DECIMALS = 18;

    /// @notice Convert amount from 'tokenDecimals' to 18 decimals precision
    /// @param tokenDecimals Decimals of the token. 8 decimals uint like in the ERC20 standard
    /// @param tokenAmount Amount with tokenDecimals precision
    /// @return wadAmount Scaled amount to the proper number of decimals
    function tokenToWad(uint8 tokenDecimals, uint256 tokenAmount) internal pure returns (uint256) {
        if (tokenDecimals == PROTOCOL_DECIMALS) {
            return tokenAmount;
        } else if (tokenDecimals < PROTOCOL_DECIMALS) {
            return tokenAmount * (10**(PROTOCOL_DECIMALS - tokenDecimals));
        }

        return tokenAmount / (10**(tokenDecimals - PROTOCOL_DECIMALS));
    }

    /// @notice Convert amount from 'tokenDecimals' decimals to 18 decimals precision
    /// @param tokenDecimals Decimals of the token. 8 decimals uint like in the ERC20 standard
    /// @param wadAmount Amount with 18 decimals precision
    /// @return amount Amount scaled back to the initial amount of decimals
    function wadToToken(uint8 tokenDecimals, uint256 wadAmount) internal pure returns (uint256) {
        if (tokenDecimals == PROTOCOL_DECIMALS) {
            return wadAmount;
        } else if (tokenDecimals < PROTOCOL_DECIMALS) {
            return wadAmount / (10**(PROTOCOL_DECIMALS - tokenDecimals));
        }

        return wadAmount * 10**(tokenDecimals - PROTOCOL_DECIMALS);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// interfaces
import {IIncreAccessControl} from "../interfaces/IIncreAccessControl.sol";

/// @notice Increment access control contract.
contract IncreAccessControl is AccessControl {
    bytes32 public constant GOVERNANCE = keccak256("GOVERNANCE");
    bytes32 public constant MANAGER = keccak256("MANAGER");

    constructor() {
        _setupRole(GOVERNANCE, msg.sender);
        _setRoleAdmin(GOVERNANCE, GOVERNANCE);

        _setupRole(MANAGER, msg.sender);
        _setRoleAdmin(MANAGER, GOVERNANCE);
    }

    // utils
    function isGovernor(address account) external view returns (bool) {
        return hasRole(GOVERNANCE, account);
    }

    function isManager(address account) external view returns (bool) {
        return hasRole(MANAGER, account);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}