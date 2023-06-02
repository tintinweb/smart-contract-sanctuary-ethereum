// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWrap } from "./interfaces/IWrap.sol";
import { IWrapDepositRedeem } from "./interfaces/IWrapDepositRedeem.sol";
import { Multisig } from "./libraries/Multisig.sol";
import { Wrap } from "./Wrap.sol";

contract WrapDepositRedeem is IWrapDepositRedeem, Wrap {
    using Multisig for Multisig.DualMultisig;

    using SafeERC20 for IERC20;

    constructor(
        Multisig.Config memory config,
        uint16 _validatorFeeBPS
    ) Wrap(config, _validatorFeeBPS) {}

    /// @inheritdoc Wrap
    function grossDepositAmount(
        uint256 netAmount
    ) internal pure override returns (uint256) {
        return netAmount;
    }

    /// @dev Internal function to calculate the deposit fees.
    function depositFees(uint256) internal pure returns (uint256 fee) {
        return 0;
    }

    /// @inheritdoc Wrap
    function onDeposit(
        address token,
        uint256 amount
    ) internal virtual override returns (uint256) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return depositFees(amount);
    }

    /// @inheritdoc Wrap
    function onExecute(
        address token,
        uint256 amount,
        address to
    )
        internal
        virtual
        override
        returns (uint256 totalFee, uint256 validatorFee)
    {
        totalFee = validatorFee = calculateFee(amount, validatorFeeBPS);
        IERC20(token).safeTransfer(to, amount - totalFee);
    }

    /// @inheritdoc Wrap
    function onMigrate(address _newContract) internal override {
        // Transfer all the token reserves to the new contract.
        // Notice that this will also transfer all the validator fees.
        // Therefore, either the new bridge should respect the existing validator fees or
        // all the validator fees must be claimed before the migration.
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(_newContract, tokenBalance);
        }
    }

    /// @inheritdoc IWrapDepositRedeem
    function addToken(
        address token,
        address mirrorToken,
        TokenInfo calldata tokenInfo
    ) external onlyRole(WEAK_ADMIN_ROLE) {
        _addToken(token, mirrorToken, tokenInfo);
    }
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
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import {
    AccessControlEnumerable
} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWrap } from "./interfaces/IWrap.sol";
import { Multisig } from "./libraries/Multisig.sol";

abstract contract Wrap is IWrap, AccessControlEnumerable {
    using Multisig for Multisig.DualMultisig;

    using SafeERC20 for IERC20;

    /// @dev The role ID for addresses that can pause the contract.
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE");

    /// @dev The role ID for addresses that has weak admin power.
    /// Weak admin can perform administrative tasks that don't risk user's funds.
    bytes32 public constant WEAK_ADMIN_ROLE = keccak256("WEAK_ADMIN");

    /// @dev Max protocol/validator fee that can be set by the owner.
    uint16 constant maxFeeBPS = 500; // should be less than 10,000

    /// @dev True if the contracts are paused, false otherwise.
    bool public paused;

    /// @dev Map token address to token info.
    mapping(address => TokenInfoStore) public tokenInfos;

    /// @dev Map mirror token address to token address.
    mapping(address => address) public mirrorTokens;

    /// @dev Map validator to its fee recipient.
    mapping(address => address) public validatorFeeRecipients;

    /// @dev Map tokens to validator index to fee that can be collected.
    mapping(address => mapping(uint256 => uint256)) public feeBalance;

    /// @dev Array of all the tokens added.
    /// @notice A token in the list might not be active.
    address[] public tokens;

    /// @dev Dual multisig to manage validators,
    /// attestations and request quorum.
    Multisig.DualMultisig internal multisig;

    /// @dev The number of deposits.
    uint256 public depositIndex;

    /// @dev Validator fee basis points.
    uint16 public validatorFeeBPS;

    /// @dev Address of the migrated contract.
    address public migratedContract;

    constructor(Multisig.Config memory config, uint16 _validatorFeeBPS) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WEAK_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(PAUSE_ROLE, WEAK_ADMIN_ROLE);
        multisig.configure(config);
        configureValidatorFees(_validatorFeeBPS);
    }

    /// @dev Hook to execute on deposit.
    /// @param token Address of the token being deposited.
    /// @param amount The amount being deposited.
    /// @return fee The fee charged to the depositor.
    function onDeposit(
        address token,
        uint256 amount
    ) internal virtual returns (uint256 fee);

    /// @dev Returns the gross deposit amount for the given net amount.
    /// @param netAmount The net amount expected after fee is subtracted from gross amount.
    /// @return grossAmount The gross amount for the given net amount.
    function grossDepositAmount(
        uint256 netAmount
    ) internal view virtual returns (uint256 grossAmount);

    /// @dev Hook to execute on successful bridging.
    /// @param token Address of the token being bridged.
    /// @param amount The amount being bridged.
    /// @param to The address where the bridged are being sent to.
    /// @return totalFee Total fee charged to the user.
    /// @return validatorFee Total fee minus the protocol fees.
    function onExecute(
        address token,
        uint256 amount,
        address to
    ) internal virtual returns (uint256 totalFee, uint256 validatorFee);

    /// @dev Hook executed before the bridge migration.
    /// @param _newContract Address of the new contract.
    function onMigrate(address _newContract) internal virtual;

    /// @dev Modifier to check if the contract is not paused.
    modifier isNotPaused() {
        if (paused == true) {
            revert ContractPaused();
        }
        _;
    }

    /// @dev Modifier to check if the contract is paused.
    modifier isPaused() {
        if (paused == false) {
            revert ContractNotPaused();
        }
        _;
    }

    /// @dev Modifier to check that contract is not already migrated.
    modifier notMigrated() {
        if (migratedContract != address(0)) {
            revert ContractMigrated();
        }
        _;
    }

    /// @dev Modifier to make a function callable only when the token and amount is correct.
    modifier isValidTokenAmount(address token, uint256 amount) {
        TokenInfoStore storage t = tokenInfos[token];

        // Notice that amount should be greater than minAmountWithFees.
        // This is required as amount after the fees should be greater
        // than minAmount so that when this is approved it passes the
        // isValidMirrorTokenAmount check.
        // Notice that t.maxAmount is 0 for non existent and disabled tokens.
        // Therefore, this check also ensures txs of such tokens are reverted.
        if (t.maxAmount <= amount || t.minAmountWithFees > amount) {
            revert InvalidTokenAmount();
        }

        if (t.dailyLimit != 0) {
            // Reset daily limit if the day is passed after last update.
            if (block.timestamp > t.lastUpdated + 1 days) {
                t.lastUpdated = block.timestamp;
                t.consumedLimit = 0;
            }

            if (t.consumedLimit + amount > t.dailyLimit) {
                revert DailyLimitExhausted();
            }
            t.consumedLimit += amount;
        }
        _;
    }

    /// @dev Modifier to make a function callable only when the token and amount is correct.
    modifier isValidMirrorTokenAmount(address mirrorToken, uint256 amount) {
        TokenInfoStore memory t = tokenInfos[mirrorTokens[mirrorToken]];
        if (t.maxAmount <= amount || t.minAmount > amount) {
            revert InvalidTokenAmount();
        }
        _;
    }

    /// @dev Modifier to make a function callable only when the recent block hash is valid.
    modifier withValidRecentBlockHash(
        bytes32 recentBlockHash,
        uint256 recentBlockNumber
    ) {
        // Prevent malicious validators from pre-producing attestation signatures.
        // This is helpful in case validators are temporarily compromised.
        // `blockhash(recentBlockNumber)` yields `0x0` when `recentBlockNumber < block.number - 256`.
        if (
            recentBlockHash == bytes32(0) ||
            blockhash(recentBlockNumber) != recentBlockHash
        ) {
            revert InvalidBlockHash();
        }
        _;
    }

    /// @inheritdoc IWrap
    function nextExecutionIndex() external view returns (uint256) {
        return multisig.nextExecutionIndex;
    }

    /// @inheritdoc IWrap
    function validatorInfo(
        address validator
    ) external view returns (Multisig.SignerInfo memory) {
        return multisig.signers[validator];
    }

    /// @inheritdoc IWrap
    function attesters(
        bytes32 hash
    ) external view returns (uint16[] memory attesterIndexes, uint16 count) {
        return multisig.getApprovers(hash);
    }

    /// @dev Internal function to calculate fees by amount and BPS.
    function calculateFee(
        uint256 amount,
        uint16 feeBPS
    ) internal pure returns (uint256) {
        // 10,000 is 100%
        return (amount * feeBPS) / 10000;
    }

    /// @inheritdoc IWrap
    function deposit(
        address token,
        uint256 amount,
        address to
    )
        external
        isNotPaused
        isValidTokenAmount(token, amount)
        returns (uint256 id)
    {
        if (to == address(0)) revert InvalidToAddress();
        id = depositIndex;
        depositIndex++;
        uint256 fee = onDeposit(token, amount);
        emit Deposit(id, token, amount - fee, to, fee);
    }

    /// @dev Internal function to calculate the hash of the request.
    function hashRequest(
        uint256 id,
        address token,
        uint256 amount,
        address to
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(id, token, amount, to));
    }

    /// @dev Internal function to approve and/or execute a given request.
    function _approveExecute(
        uint256 id,
        address mirrorToken,
        uint256 amount,
        address to
    ) private isNotPaused isValidMirrorTokenAmount(mirrorToken, amount) {
        // If the request ID is lower than the last executed ID then simply ignore the request.
        if (id < multisig.nextExecutionIndex) {
            return;
        }

        bytes32 hash = hashRequest(id, mirrorToken, amount, to);
        Multisig.RequestStatusTransition transition = multisig.tryApprove(
            msg.sender,
            hash,
            id
        );
        if (transition == Multisig.RequestStatusTransition.NULLToUndecided) {
            emit Requested(id, mirrorToken, amount, to);
        }

        if (multisig.tryExecute(hash, id)) {
            address token = mirrorTokens[mirrorToken];
            (uint256 totalFee, uint256 validatorFee) = onExecute(
                token,
                amount,
                to
            );
            {
                (uint16[] memory approvers, uint16 approverCount) = multisig
                    .getApprovers(hash);
                uint256 feeToIndividualValidator = validatorFee / approverCount;
                mapping(uint256 => uint256)
                    storage tokenFeeBalance = feeBalance[token];
                for (uint16 i = 0; i < approverCount; i++) {
                    tokenFeeBalance[approvers[i]] += feeToIndividualValidator;
                }
            }
            emit Executed(
                id,
                mirrorToken,
                token,
                amount - totalFee,
                to,
                totalFee
            );
        }
    }

    /// @inheritdoc IWrap
    function approveExecute(
        uint256 id,
        address mirrorToken,
        uint256 amount,
        address to,
        bytes32 recentBlockHash,
        uint256 recentBlockNumber
    ) external withValidRecentBlockHash(recentBlockHash, recentBlockNumber) {
        _approveExecute(id, mirrorToken, amount, to);
    }

    /// @inheritdoc IWrap
    function batchApproveExecute(
        RequestInfo[] calldata requests,
        bytes32 recentBlockHash,
        uint256 recentBlockNumber
    ) external withValidRecentBlockHash(recentBlockHash, recentBlockNumber) {
        for (uint256 i = 0; i < requests.length; i++) {
            _approveExecute(
                requests[i].id,
                requests[i].token,
                requests[i].amount,
                requests[i].to
            );
        }
    }

    function _configureTokenInfo(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 dailyLimit,
        bool newToken
    ) internal {
        uint256 currMinAmount = tokenInfos[token].minAmount;
        if (
            minAmount == 0 ||
            (newToken ? currMinAmount != 0 : currMinAmount == 0)
        ) {
            revert InvalidTokenConfig();
        }

        // configuring token also resets the daily volume limit
        TokenInfoStore memory tokenInfoStore = TokenInfoStore(
            maxAmount,
            minAmount,
            grossDepositAmount(minAmount),
            dailyLimit,
            0,
            block.timestamp
        );
        tokenInfos[token] = tokenInfoStore;
    }

    /// @inheritdoc IWrap
    function configureToken(
        address token,
        TokenInfo calldata tokenInfo
    ) external onlyRole(WEAK_ADMIN_ROLE) {
        _configureTokenInfo(
            token,
            tokenInfo.minAmount,
            tokenInfo.maxAmount,
            tokenInfo.dailyLimit,
            false
        );
    }

    /// @inheritdoc IWrap
    function configureValidatorFees(
        uint16 _validatorFeeBPS
    ) public onlyRole(WEAK_ADMIN_ROLE) {
        if (_validatorFeeBPS > maxFeeBPS) {
            revert FeeExceedsMaxFee();
        }
        validatorFeeBPS = _validatorFeeBPS;
    }

    /// @dev Internal function to add a new token.
    /// @param token Token that will be deposited in the contract.
    /// @param mirrorToken Token that will be deposited in the mirror contract.
    /// @param tokenInfo Token info associated with the token.
    function _addToken(
        address token,
        address mirrorToken,
        TokenInfo calldata tokenInfo
    ) internal {
        if (mirrorTokens[mirrorToken] != address(0)) {
            revert InvalidTokenConfig();
        }

        _configureTokenInfo(
            token,
            tokenInfo.minAmount,
            tokenInfo.maxAmount,
            tokenInfo.dailyLimit,
            true
        );
        tokens.push(token);
        mirrorTokens[mirrorToken] = token;
    }

    /// @inheritdoc IWrap
    function configureMultisig(
        Multisig.Config calldata config
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        multisig.configure(config);
    }

    /// @inheritdoc IWrap
    function pause() external onlyRole(PAUSE_ROLE) {
        paused = true;
    }

    /// @inheritdoc IWrap
    function unpause() external notMigrated onlyRole(WEAK_ADMIN_ROLE) {
        paused = false;
    }

    /// @inheritdoc IWrap
    function addValidator(
        address validator,
        bool isFirstCommittee,
        address feeRecipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        multisig.addSigner(validator, isFirstCommittee);
        validatorFeeRecipients[validator] = feeRecipient;
    }

    /// @inheritdoc IWrap
    function removeValidator(
        address validator
    ) external onlyRole(WEAK_ADMIN_ROLE) {
        multisig.removeSigner(validator);
    }

    /// @inheritdoc IWrap
    function configureValidatorFeeRecipient(
        address validator,
        address feeRecipient
    ) external onlyRole(WEAK_ADMIN_ROLE) {
        validatorFeeRecipients[validator] = feeRecipient;
    }

    /// @inheritdoc IWrap
    function claimValidatorFees(address validator) public {
        address feeRecipient = validatorFeeRecipients[validator];

        if (feeRecipient == address(0)) {
            revert InvalidFeeRecipient();
        }

        uint16 index = multisig.signers[validator].index;
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenValidatorFee = feeBalance[token][index];
            feeBalance[token][index] = 0;
            IERC20(token).safeTransfer(feeRecipient, tokenValidatorFee);
        }
    }

    /// @inheritdoc IWrap
    function forceSetNextExecutionIndex(
        uint256 index
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        multisig.forceSetNextExecutionIndex(index);
    }

    /// @inheritdoc IWrap
    function migrate(
        address _newContract
    ) public isPaused notMigrated onlyRole(DEFAULT_ADMIN_ROLE) {
        onMigrate(_newContract);
        migratedContract = _newContract;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import {
    IAccessControlEnumerable
} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { Multisig } from "../libraries/Multisig.sol";

/// @title Common interface for Wrap contracts on FLR and EVM chains.
interface IWrap is IAccessControlEnumerable {
    /// @dev Thrown when an operation is performed on a paused Wrap contract.
    error ContractPaused();

    /// @dev Thrown when the contract is not paused.
    error ContractNotPaused();

    /// @dev Thrown when the contract is already migrated.
    error ContractMigrated();

    /// @dev Thrown when the token is not allowlisted or the amount
    /// being deposited/approved is not in the range of min/maxAmount.
    error InvalidTokenAmount();

    /// @dev Thrown when the token config is invalid.
    error InvalidTokenConfig();

    /// @dev Thrown when the fee being set is higher than the maximum
    /// fee allowed.
    error FeeExceedsMaxFee();

    /// @dev Thrown when the recipient address is the zero address.
    error InvalidToAddress();

    /// @dev Thrown when the provided blocknumber is not of the most recent 256 blocks.
    error InvalidBlockHash();

    /// @dev Thrown when the daily volume exceeds the dailyLimit.
    error DailyLimitExhausted();

    /// @dev Thrown when the fee recipient address is the zero address.
    error InvalidFeeRecipient();

    /// @dev Emitted when a user deposits.
    /// @param id ID associated with the request.
    /// @param token Token deposited.
    /// @param amount Amount of tokens deposited, minus the fee.
    /// @param to Address to release the funds to.
    /// @param fee Fee subtracted from the original deposited amount.
    event Deposit(
        uint256 indexed id,
        address indexed token,
        uint256 amount,
        address to,
        uint256 fee
    );

    /// @dev Emitted when a new request is created.
    /// @param id ID associated with the request.
    /// @param mirrorToken Mirror token requested.
    /// @param amount Amount of tokens requested.
    /// @param to Address to release the funds to.
    event Requested(
        uint256 indexed id,
        address indexed mirrorToken,
        uint256 amount,
        address to
    );

    /// @dev Emitted when a request gets executed.
    /// @param id ID associated with the request.
    /// @param mirrorToken Mirror token requested.
    /// @param token Token approved.
    /// @param amount Amount approved, minus the fee.
    /// @param to Address to release the funds to.
    /// @param fee Fee charged on top of the approved amount.
    event Executed(
        uint256 indexed id,
        address indexed mirrorToken,
        address indexed token,
        uint256 amount,
        address to,
        uint256 fee
    );

    /// @dev Token information.
    /// @param maxAmount Maximum amount to deposit/approve.
    /// @param minAmount Minimum amount to deposit/approve.
    /// @notice Set max amount to zero to disable the token.
    /// @param dailyLimit Daily volume limit.
    struct TokenInfo {
        uint256 maxAmount;
        uint256 minAmount;
        uint256 dailyLimit;
    }

    /// @dev Token info that is stored in the contact storage.
    /// @param maxAmount Maximum amount to deposit/approve.
    /// @param minAmount Minimum amount to approve.
    /// @param minAmountWithFees Minimum amount to deposit, with fees included.
    /// @param dailyLimit Daily volume limit.
    /// @param consumedLimit Consumed daily volume limit.
    /// @param lastUpdated Last timestamp when the consumed limit was set to 0.
    /// @notice Set max amount to zero to disable the token.
    /// @notice Set daily limit to 0 to disable the daily limit. Consumed limit should
    /// always be less than equal to dailyLimit.
    /// @notice The minAmountWithFees is minAmount + depositFees(minAmount).
    /// On deposit, the amount should be greater than minAmountWithFees such that,
    /// after fee deduction, it is still greater equal than minAmount.
    struct TokenInfoStore {
        uint256 maxAmount;
        uint256 minAmount;
        uint256 minAmountWithFees;
        uint256 dailyLimit;
        uint256 consumedLimit;
        uint256 lastUpdated;
    }

    /// @dev Request information.
    /// @param id ID associated with the request.
    /// @param token Token requested.
    /// @param amount Amount of tokens requested.
    /// @param to Address to release the funds to.
    struct RequestInfo {
        uint256 id;
        address token;
        uint256 amount;
        address to;
    }

    /// @dev Returns whether or not the contract has been paused.
    /// @return paused True if the contract is paused, false otherwise.
    function paused() external view returns (bool paused);

    /// @dev Returns the number of deposits.
    function depositIndex() external view returns (uint256);

    /// @dev Returns the index of the request that will be executed next.
    function nextExecutionIndex() external view returns (uint256);

    /// @dev Returns info about a given validator.
    function validatorInfo(
        address validator
    ) external view returns (Multisig.SignerInfo memory);

    /// @dev Returns the number of attesters and their indeces for a given request hash.
    function attesters(
        bytes32 hash
    ) external view returns (uint16[] memory attesters, uint16 count);

    /// @dev Returns the validator fee basis points.
    function validatorFeeBPS() external view returns (uint16);

    /// @dev Update a token's configuration information.
    /// @param tokenInfo The token's new configuration info.
    /// @notice Set maxAmount to zero to disable the token.
    /// @notice Can only be called by the weak-admin.
    function configureToken(
        address token,
        TokenInfo calldata tokenInfo
    ) external;

    /// @dev Set the multisig configuration.
    /// @param config Multisig config.
    /// @notice Can only be called by the admin.
    function configureMultisig(Multisig.Config calldata config) external;

    /// @dev Configure validator fees.
    /// @param validatorFeeBPS Validator fee in basis points.
    /// @notice Can only be called by the weak-admin.
    function configureValidatorFees(uint16 validatorFeeBPS) external;

    /// @dev Deposit tokens to bridge to the other side.
    /// @param token Token being deposited.
    /// @param amount Amount of tokens being deposited.
    /// @param to Address to release the tokens to on the other side.
    /// @return The ID associated to the request.
    function deposit(
        address token,
        uint256 amount,
        address to
    ) external returns (uint256);

    /// @dev Approve and/or execute a given request.
    /// @param id ID associated with the request.
    /// @param token Token requested.
    /// @param amount Amount of tokens requested.
    /// @param to Address to release the funds to.
    /// @param recentBlockhash Block hash of `recentBlocknumber`
    /// @param recentBlocknumber Recent block number
    function approveExecute(
        uint256 id,
        address token,
        uint256 amount,
        address to,
        bytes32 recentBlockhash,
        uint256 recentBlocknumber
    ) external;

    /// @dev Approve and/or execute requests.
    /// @param requests Requests to approve and/or execute.
    function batchApproveExecute(
        RequestInfo[] calldata requests,
        bytes32 recentBlockhash,
        uint256 recentBlocknumber
    ) external;

    /// @dev Pauses the contract.
    /// @notice The contract can be paused by all addresses
    /// with pause role but can only be unpaused by the weak-admin.
    function pause() external;

    /// @dev Unpauses the contract.
    /// @notice The contract can be paused by all addresses
    /// with pause role but can only be unpaused by the weak-admin.
    function unpause() external;

    /// @dev Add a new validator to the contract.
    /// @param validator Address of the validator.
    /// @param isFirstCommittee True when adding the validator to the first committee.
    /// @param feeRecipient Address of the fee recipient.
    /// false when adding the validator to the second committee.
    /// @notice Can only be called by the admin.
    function addValidator(
        address validator,
        bool isFirstCommittee,
        address feeRecipient
    ) external;

    /// @dev Change fee recipient for a validator.
    /// @param validator Address of the validator.
    /// @param feeRecipient Address of the new fee recipient.
    function configureValidatorFeeRecipient(
        address validator,
        address feeRecipient
    ) external;

    /// @dev Remove existing validator from the contract.
    /// @param validator Address of the validator.
    /// @notice Can only be called by the weak-admin.
    /// @notice The fees accumulated by the validator are distributed before being removed.
    function removeValidator(address validator) external;

    /// @dev Allows to claim accumulated fees for a validator.
    /// @param validator Address of the validator.
    /// @notice Can be triggered by anyone but the fee is transfered to the
    /// set feeRecepient for the validator.
    function claimValidatorFees(address validator) external;

    /// @dev Forcefully set next next execution index.
    /// @param index The new next execution index.
    /// @notice Can only be called by the admin of the contract.
    function forceSetNextExecutionIndex(uint256 index) external;

    /// @dev Migrates the contract to a new address.
    /// @param _newContract Address of the new contract.
    /// @notice This function can only be called once in the lifetime of this
    /// contract by the admin.
    function migrate(address _newContract) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import { IWrap } from "./IWrap.sol";

/// @title Interface for the side of Wraps where tokens are deposited and
/// redeemed.
interface IWrapDepositRedeem is IWrap {
    /// @dev Allowlist a new token.
    /// @param token Address of the token that will be allowlisted.
    /// @param mirrorToken Address of the token that will be minted
    /// on the other side.
    /// @param tokenInfo Information associated with the token.
    /// @notice Set maxAmount to zero to disable the token.
    /// @notice Can only be called by the weak-admin.
    function addToken(
        address token,
        address mirrorToken,
        TokenInfo calldata tokenInfo
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

/// @title Two committee multisig library.
/// @dev Implements a multisig with two committees.
/// A separate quorum must be reached in both committees
/// to approve a given request. A request is rejected if
/// either of the two committees rejects it. Each committee
/// cannot have more than 128 members.
library Multisig {
    /// @dev Thrown when an already existing signer is added.
    error SignerAlreadyExists(address signer);

    /// @dev Thrown when an account that is performing some
    /// signer-only action is not an active signer.
    error SignerNotActive(address signer);

    /// @dev Thrown when attempting to add a new signer
    /// after the max committee size has been reached.
    error MaxCommitteeSizeReached();

    /// @dev Thrown when the configuration parmeters that are
    /// being set are not valid.
    error InvalidConfiguration();

    /// @dev Thrown when a given ID has already been assigned
    /// to an apprroved request.
    error InvalidId();

    /// @dev Thrown when the current next execution index is
    /// greater equal to the new next execution index.
    error InvalidNextExecutionIndex();

    /// @dev Emitted when a new signer is added.
    /// @param signer Address of signer that was added.
    /// @param isFirstCommittee True if the signer was
    /// added to the first committee and false if they were
    /// added to the second committee.
    event AddSigner(address indexed signer, bool indexed isFirstCommittee);

    /// @dev Emitted when an existing signer is removed.
    /// @param signer Address of signer that was removed.
    event RemoveSigner(address indexed signer);

    /// @dev Maximum number of members in each committee.
    /// @notice This number cannot be increased further
    /// with the current implementation. Our implementation
    /// uses bitmasks and the uint8 data type to optimize gas.
    /// These data structures will overflow if maxCommitteeSize
    /// is greater than 128.
    uint8 constant maxCommitteeSize = 128;

    /// @dev Maximum number of members in both committees
    /// combined.
    /// @notice Similarly to maxCommitteeSize, maxSignersSize
    /// also cannot be further increased to more than 256.
    uint16 constant maxSignersSize = 256; // maxCommitteeSize * 2

    /// @dev Request statuses.
    /// @notice `NULL` should be the first element as the first value is used
    /// as the default value in Solidity. The sequence of the other
    /// elements also shouldn't be changed.
    enum RequestStatus {
        NULL, // request which doesn't exist
        Undecided, // request hasn't reached quorum
        Accepted // request has been approved
    }

    /// @notice `Unchanged` should be the first element as the first value is used
    /// as the default value in Solidity. The sequence of the other
    /// elements also shouldn't be changed.
    enum RequestStatusTransition {
        Unchanged,
        NULLToUndecided,
        UndecidedToAccepted
    }

    /// @dev Signer statuses.
    /// @notice `Uninitialized` should be the first element as the first value is used
    /// as the default value in Solidity. The sequence of the other
    /// elements also shouldn't be changed.
    enum SignerStatus {
        Uninitialized,
        Removed,
        FirstCommittee,
        SecondCommittee
    }

    /// @dev Request info.
    /// @param approvalsFirstCommittee Number of approvals
    /// by the first committee.
    /// @param approvalsSecondCommittee Number of approvals
    /// by the second committee.
    /// @param status Status of the request.
    /// @param approvers Bitmask for signers from the two
    /// committees who have accepted the request.
    /// @notice Approvers is a bitmask. For example, a set bit at
    /// position 2 in the approvers bitmask indicates that the
    /// signer with index 2 has approved the request.
    struct Request {
        uint8 approvalsFirstCommittee; // slot 1 (0 - 7 bits)
        uint8 approvalsSecondCommittee; // slot 1 (8 - 15 bits)
        RequestStatus status; // slot 1 (16 - 23 bits)
        // slot 1 (23 - 255 spare bits)
        uint256 approvers; // slot 2
    }

    /// @dev Signer information.
    /// @param status Status of the signer.
    /// @param index Index of the signer.
    struct SignerInfo {
        SignerStatus status;
        uint8 index;
    }

    /// @dev DualMultisig
    /// @param firstCommitteeAcceptanceQuorum Number of acceptances
    /// required to reach quorum in the first committee.
    /// @param secondCommitteeAcceptanceQuorum Number of acceptances
    /// required to reach quorum in the second committee.
    /// @param firstCommitteeSize Size of the first committee.
    /// @param secondCommitteeSize Size of the second committee.
    /// @param nextExecutionIndex Index of the request that will be executed next.
    /// @param signers Mapping from signer address to signer info.
    /// @param requests Mapping from request hash to request info.
    /// @param approvedRequests Mapping request ID to request hash.
    struct DualMultisig {
        uint8 firstCommitteeAcceptanceQuorum; // slot 1 (0 - 7bits)
        uint8 secondCommitteeAcceptanceQuorum; // slot 1 (8 - 15bits)
        uint8 firstCommitteeSize; // slot 1 (16 - 23bits)
        uint8 secondCommitteeSize; // slot 1 (24 - 31bits)
        // slot1 (32 - 255 spare bits)
        uint256 nextExecutionIndex;
        mapping(address => SignerInfo) signers;
        mapping(bytes32 => Request) requests;
        mapping(uint256 => bytes32) approvedRequests;
    }

    /// @param firstCommitteeAcceptanceQuorum Number of acceptances
    /// required to reach quorum in the first committee.
    /// @param secondCommitteeAcceptanceQuorum Number of acceptances
    /// required to reach quorum in the second committee.
    /// @notice Both acceptance quorums should be greater than zero
    /// and less than or equal to maxCommitteeSize.
    struct Config {
        uint8 firstCommitteeAcceptanceQuorum;
        uint8 secondCommitteeAcceptanceQuorum;
    }

    /// @dev Returns a request status for a given request hash.
    /// @param s The relevant multisig to check.
    /// @param hash The hash of the request being checked.
    /// @return The status of the request with the given hash.
    function status(
        DualMultisig storage s,
        bytes32 hash
    ) internal view returns (RequestStatus) {
        return s.requests[hash].status;
    }

    /// @dev Returns whether or not a given address is a signer
    /// in the multisig.
    /// @param s The relevant multisig to check.
    /// @param signer The address of the potential signer.
    /// @return True if the provided address is a signer.
    function isSigner(
        DualMultisig storage s,
        address signer
    ) internal view returns (bool) {
        return s.signers[signer].status >= SignerStatus.FirstCommittee;
    }

    /// @dev Updates a multisig's configuration.
    function configure(DualMultisig storage s, Config memory c) internal {
        if (
            c.firstCommitteeAcceptanceQuorum == 0 ||
            c.firstCommitteeAcceptanceQuorum > maxCommitteeSize ||
            c.secondCommitteeAcceptanceQuorum == 0 ||
            c.secondCommitteeAcceptanceQuorum > maxCommitteeSize
        ) {
            revert InvalidConfiguration();
        }
        s.firstCommitteeAcceptanceQuorum = c.firstCommitteeAcceptanceQuorum;
        s.secondCommitteeAcceptanceQuorum = c.secondCommitteeAcceptanceQuorum;
    }

    /// @dev Adds a new signer.
    /// @param s The multisig to add the signer to.
    /// @param signer The address of the signer to add.
    /// @param isFirstCommittee True if the signer is to be
    /// added to the first committee and false if they are
    /// to be added to the second committee.
    function addSigner(
        DualMultisig storage s,
        address signer,
        bool isFirstCommittee
    ) internal {
        uint8 committeeSize = (
            isFirstCommittee ? s.firstCommitteeSize : s.secondCommitteeSize
        );
        if (committeeSize == maxCommitteeSize) {
            revert MaxCommitteeSizeReached();
        }

        SignerInfo storage signerInfo = s.signers[signer];
        if (signerInfo.status != SignerStatus.Uninitialized) {
            revert SignerAlreadyExists(signer);
        }

        signerInfo.index = s.firstCommitteeSize + s.secondCommitteeSize;
        if (isFirstCommittee) {
            s.firstCommitteeSize++;
            signerInfo.status = SignerStatus.FirstCommittee;
        } else {
            s.secondCommitteeSize++;
            signerInfo.status = SignerStatus.SecondCommittee;
        }

        emit AddSigner(signer, isFirstCommittee);
    }

    /// @dev Removes a signer.
    /// @param s The multisig to remove the signer from.
    /// @param signer The signer to be removed.
    function removeSigner(DualMultisig storage s, address signer) internal {
        SignerInfo storage signerInfo = s.signers[signer];
        if (signerInfo.status < SignerStatus.FirstCommittee) {
            revert SignerNotActive(signer);
        }
        signerInfo.status = SignerStatus.Removed;
        emit RemoveSigner(signer);
    }

    /// @dev Approve a request if its has not already been approved.
    /// @param s The multisig for which to approve the given request.
    /// @param signer The signer approving the request.
    /// @param hash The hash of the request being approved.
    /// @return The request's status transition.
    /// @dev Notice that this code assumes that the hash is generated from
    /// the ID and other data outside of this function. It is important to include
    /// the ID in the hash.
    function tryApprove(
        DualMultisig storage s,
        address signer,
        bytes32 hash,
        uint256 id
    ) internal returns (RequestStatusTransition) {
        Request storage request = s.requests[hash];
        // If the request has already been accepted
        // then simply return.
        if (request.status == RequestStatus.Accepted) {
            return RequestStatusTransition.Unchanged;
        }

        SignerInfo memory signerInfo = s.signers[signer];
        // Make sure that the signer is valid.
        if (signerInfo.status < SignerStatus.FirstCommittee) {
            revert SignerNotActive(signer);
        }

        // Revert if another request with the same ID has
        // already been approved.
        if (s.approvedRequests[id] != bytes32(0)) {
            revert InvalidId();
        }

        uint256 signerMask = 1 << signerInfo.index;
        // Check if the signer has already signed.
        if ((signerMask & request.approvers) != 0) {
            return RequestStatusTransition.Unchanged;
        }

        // Add the signer to the bitmask of approvers.
        request.approvers |= signerMask;
        if (signerInfo.status == SignerStatus.FirstCommittee) {
            ++request.approvalsFirstCommittee;
        } else {
            ++request.approvalsSecondCommittee;
        }

        if (
            request.approvalsFirstCommittee >=
            s.firstCommitteeAcceptanceQuorum &&
            request.approvalsSecondCommittee >=
            s.secondCommitteeAcceptanceQuorum
        ) {
            request.status = RequestStatus.Accepted;
            s.approvedRequests[id] = hash;
            return RequestStatusTransition.UndecidedToAccepted;
        } else if (request.status == RequestStatus.NULL) {
            // If this is the first approval, change the request status
            // to undecided.
            request.status = RequestStatus.Undecided;
            return RequestStatusTransition.NULLToUndecided;
        }
        return RequestStatusTransition.Unchanged;
    }

    /// @dev Get approvers for a given request.
    /// @param s The multisig to get the approvers for.
    /// @param hash The hash of the request.
    /// @return approvers List of approvers.
    /// @return count Count of approvers.
    function getApprovers(
        DualMultisig storage s,
        bytes32 hash
    ) internal view returns (uint16[] memory approvers, uint16 count) {
        uint256 mask = s.requests[hash].approvers;
        uint16 signersCount = s.firstCommitteeSize + s.secondCommitteeSize;
        approvers = new uint16[](signersCount);
        count = 0;
        for (uint16 i = 0; i < signersCount; i++) {
            if ((mask & (1 << i)) != 0) {
                approvers[count] = i;
                count++;
            }
        }

        return (approvers, count);
    }

    /// @dev Forcefully set next next execution index.
    /// @param s The multisig to set the next execution index for.
    /// @param index The new next execution index.
    function forceSetNextExecutionIndex(
        DualMultisig storage s,
        uint256 index
    ) internal {
        if (s.nextExecutionIndex >= index) {
            revert InvalidNextExecutionIndex();
        }
        s.nextExecutionIndex = index;
    }

    /// @dev Try to execute the next approved request.
    /// @param s The multisig whose next request should
    /// be executed.
    /// @param hash The hash of the request being executed.
    /// @param id The ID of the request being executed.
    /// @return True if the execution was successful.
    function tryExecute(
        DualMultisig storage s,
        bytes32 hash,
        uint256 id
    ) internal returns (bool) {
        if (id == s.nextExecutionIndex && s.approvedRequests[id] == hash) {
            s.nextExecutionIndex++;
            return true;
        }
        return false;
    }
}