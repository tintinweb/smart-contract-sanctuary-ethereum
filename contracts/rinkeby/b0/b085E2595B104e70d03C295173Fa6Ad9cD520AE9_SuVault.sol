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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
     * - input must fit into 8 bits.
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
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

import "./access-control/SuAccessControlSingleton.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SuUSD is ERC20, SuAuthenticated {
    constructor(address _authControl) ERC20("StableUnit USD", "SuUSD") SuAuthenticated(_authControl) {}

    /**
      * @notice Only Vault can mint SuUSD
      * @dev Mints 'amount' of tokens to address 'to', and MUST fire the
      * Transfer event
      * @param to The address of the recipient
      * @param amount The amount of token to be minted
     **/

     // dollars can be minted by vault (once user deposited collateral)
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    // dollars can be burned by manager but only his own dollars
    // which managers will be using this feature? burning protocol fees?
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

     // also vault is allowed to burn dollars of any account
     // when user repays his loan and takes back his collateral
    function burn(address from, uint256 amount) external onlyMinter {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: BSL 1.1

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./SuAuthenticated.sol";

pragma solidity ^0.8.0;

/**
 * @title SuAccessControl
 * @dev Access control for contracts. SuVaultParameters can be inherited from it.
 */
// TODO: refactor by https://en.wikipedia.org/wiki/Principle_of_least_privilege
contract SuAccessControlSingleton is AccessControl, SuAuthenticated {
    /**
     * @dev Initialize the contract with initial owner to be deployer
     */
    constructor() SuAuthenticated(address(this)) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) external {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ownable: caller is not the owner");

        if (hasRole(MINTER_ROLE, msg.sender)) {
            grantRole(MINTER_ROLE, newOwner);
            revokeRole(MINTER_ROLE, msg.sender);
        }

        if (hasRole(VAULT_ACCESS_ROLE, msg.sender)) {
            grantRole(VAULT_ACCESS_ROLE, newOwner);
            revokeRole(VAULT_ACCESS_ROLE, msg.sender);
        }

        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: BSL 1.1

pragma solidity >=0.7.6;

import "../interfaces/ISuAccessControl.sol";

/**
 * @title SuAuthenticated
 * @dev other contracts should inherit to be authenticated
 */
abstract contract SuAuthenticated {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant VAULT_ACCESS_ROLE = keccak256("VAULT_ACCESS_ROLE");
    bytes32 public constant LIQUIDATION_ACCESS_ROLE = keccak256("LIQUIDATION_ACCESS_ROLE");
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev the address of SuAccessControlSingleton - it should be one for all contract that inherits SuAuthenticated
    ISuAccessControl public immutable ACCESS_CONTROL_SINGLETON;

    /// @dev should be passed in constructor
    constructor(address _accessControlSingleton) {
        ACCESS_CONTROL_SINGLETON = ISuAccessControl(_accessControlSingleton);
        // TODO: check that _accessControlSingleton points to ISuAccessControl instance
        // require(ISuAccessControl(_accessControlSingleton).supportsInterface(ISuAccessControl.hasRole.selector), "bad dependency");
    }

    /// @dev check DEFAULT_ADMIN_ROLE
    modifier onlyOwner() {
        require(ACCESS_CONTROL_SINGLETON.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SuAuth: onlyOwner AUTH_FAILED");
        _;
    }

    /// @dev check VAULT_ACCESS_ROLE
    modifier onlyVaultAccess() {
        require(ACCESS_CONTROL_SINGLETON.hasRole(VAULT_ACCESS_ROLE, msg.sender), "SuAuth: onlyVaultAccess AUTH_FAILED");
        _;
    }

    /// @dev check VAULT_ACCESS_ROLE
    modifier onlyLiquidationAccess() {
        require(ACCESS_CONTROL_SINGLETON.hasRole(LIQUIDATION_ACCESS_ROLE, msg.sender), "SuAuth: onlyLiquidationAccess AUTH_FAILED");
        _;
    }

    /// @dev check MINTER_ROLE
    modifier onlyMinter() {
        require(ACCESS_CONTROL_SINGLETON.hasRole(MINTER_ROLE, msg.sender), "SuAuth: onlyMinter AUTH_FAILED");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardChefV2 {
    /// @notice Info of each reward pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of REWARD_TOKEN to distribute per block.
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
        uint256 lpSupply;
    }

    /// @notice Info of each user.
    /// `amount` token amount the user has provided.
    /// `rewardDebt` The amount of rewards entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    // Public variables that are declared in RewardChefV2.sol
    //  function userInfo(address asset, address user) external returns ( UserInfo );
    //  function poolInfo(address asset) external returns ( PoolInfo );

    function REWARD_TOKEN() external view returns ( IERC20 );
    function add(uint256 allocPoint, address _asset) external;
    function decreaseAmount(address asset, address to, uint256 amountEDecimal) external;
    function harvest(address asset, address to) external;
    function increaseAmount(address asset, address to, uint256 amountEDecimal) external;
    function pendingSushi(address _asset, address _user) external view returns ( uint256 );
    function refillReward(uint256 amount, uint64 endBlock) external;
    function rewardsBetweenBlocks(uint256 startBlock, uint256 endBlock) external returns ( uint256 );
    function rewardEndBlock() external view returns ( uint256 );
    function set(address _asset, uint256 _allocPoint) external;
    function totalAllocPoint() external view returns ( uint256 );
    function updateAllPools() external;
    function updatePool(address asset) external returns ( PoolInfo memory );
    function resetAmount(address asset, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface ISuAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // TODO: remove legacy functionality
    function setVault(address _vault, bool _isVault) external;
    function setCdpManager(address _cdpManager, bool _isCdpManager) external;
    function setDAO(address _dao, bool _isDAO) external;
    function setManagerParameters(address _address, bool _permit) external;
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.6;

interface ISuOracle {
    /**
     * @notice WARNING! Read this description very carefully!
     *      function getUsdPrice1e18(address asset) returns (uint256) that:
     *          basicAmountOfAsset * getUsdPrice1e18(asset) / 1e18 === $$ * 1e18
     *      in other words, it doesn't matter what's the erc20.decimals is,
     *      you just multiply token balance in basic units on value from oracle and get dollar amount multiplied on 1e18.
     *
     * different assets have different deviation threshold (errors)
     *      for wBTC it's <= 0.5%, read more https://data.chain.link/ethereum/mainnet/crypto-usd/btc-usd
     *      for other asset is can be larger based on particular oracle implementation.
     *
     * examples:
     *      assume market price of wBTC = $31,503.77, oracle error = $158
     *
     *       case #1: small amount of wBTC
     *           we have 0.0,000,001 wBTC that is worth v = $0.00315 ± $0.00001 = 0.00315*1e18 = 315*1e13 ± 1*1e13
     *           actual balance on the asset b = wBTC.balanceOf() =  0.0000001*1e18 = 1e11
     *           oracle should return or = oracle.getUsdPrice1e18(wBTC) <=>
     *           <=> b*or = v => v/b = 315*1e13 / 1e11 = 315*1e2 ± 1e2
     *           error = or.error * b = 1e2 * 1e11 = 1e13 => 1e13/1e18 usd = 1e-5 = 0.00001 usd
     *
     *       case #2: large amount of wBTC
     *           v = 2,000,000 wBTC = $31,503.77 * 2m ± 158*2m = $63,007,540,000 ± $316,000,000 = 63,007*1e24 ± 316*1e24
     *           for calc convenience we increase error on 0.05 and have v = 63,000*24 ± 300*1e24 = (630 ± 3)*1e26
     *           b = 2*1e6 * 1e18 = 2*1e24
     *           or = v/b = (630 ± 3)*1e26 / 2*1e24 = 315*1e2 ± 1.5*1e2
     *           error = or.error * b = 1.5*100 * 2*1e24 = 3*1e26 = 3*1e8*1e18 = $300,000,000 ~ $316,000,000
     *
     *      assume the market price of USDT = $0.97 ± $0.00485,
     *
     *       case #3: little amount of USDT
     *           v = USDT amount 0.005 = 0.005*(0.97 ± 0.00485) = 0.00485*1e18 ± 0.00002425*1e18 = 485*1e13 ± 3*1e13
     *           we rounded error up on (3000-2425)/2425 ~= +24% for calculation convenience.
     *           b = USDT.balanceOf() = 0.005*1e6 = 5*1e3
     *           b*or = v => or = v/b = (485*1e13 ± 3*1e13) / 5*1e3 = 970*1e9 ± 6*1e9
     *           error = 6*1e9 * 5*1e3 / 1e18 = 30*1e12/1e18 = 3*1e-5 = $0,00005
     *
     *       case #4: lot of USDT
     *           v = we have 100,000,000,000 USDT = $97B = 97*1e9*1e18 ± 0.5*1e9*1e18
     *           b = USDT.balanceOf() = 1e11*1e6 = 1e17
     *           or = v/b = (97*1e9*1e18 ± 0.5*1e9*1e18) / 1e17 = 970*1e9 ± 5*1e9
     *           error = 5*1e9 * 1e17 = 5*1e26 = 0.5 * 1e8*1e18
     *
     * @param asset - address of erc20 token contract
     * @return usdPrice1e18 such that asset.balanceOf() * getUsdPrice1e18(asset) / 1e18 == $$ * 1e18
     **/
    function getUsdPrice1e18(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SuVaultParameters.sol";
import "../SuUSD.sol";
import "../access-control/SuAccessControlSingleton.sol";
import "../reward/RewardChefV2.sol";

contract SuVault is SuVaultParameters {
    // token itself - will be unit stable coin
    address public immutable STABLECOIN;

    // which tokens are allowed as collateral; what's the int value - min threshold or rate?
    /// No, it's how much user had stacked collaterael asset == collaterals[asset][user], i.e deposits
    // EDecimal means that this value is like x * 10^{asset decimal}
    mapping(address => mapping(address => uint)) public collateralsEDecimal;

    // mapping of user address to integer value; which is the amount of debt represented by what?
    /// Yes, in stablecoin amount, == debts[asset][user]
    // or might be it mapping fro token address into total debt amount?
    mapping(address => mapping(address => uint)) public debtsE18;

    // mapping of address to integer for token debts;
    // what'is the units of measurement?
    /// How much stablecoin was borrowed against particular asset == tokenDebts[asset]
    mapping(address => uint) public tokenDebtsE18;

    // double mapping probably from collateral to each user to debt
    // how is stability fee calculated and where is it paid and when?
    /// current interest that user pay for stabilityFee[asset][user]
    mapping(address => mapping(address => uint)) public stabilityFeeE18;

    // mapping for timestamps;
    // why do we need timestamps? how do we calculate medium price when merging positions?
    /// everything before lastUpdates is already calced in the debt. all data such as fees are from lastUpdate only
    mapping(address => mapping(address => uint)) public lastUpdate;

    // asset => user => block number
    mapping(address => mapping(address => uint)) public liquidationBlock;

    SuVaultParameters public immutable VAULT_PARAMETERS;

    event PositionLiquidated(address asset, address owner, address repayer, uint assetAmountEDecimal, uint repaymentE18);
    event PositionRepaid(address repayer, uint repaymentE18, uint excessAndFeeE18);

    // check if liquidation process not started for asset of user
    /// YES
    modifier notLiquidating(address asset, address user) {
        require(liquidationBlock[asset][user] == 0, "Unit Protocol: LIQUIDATING_POSITION");
        _;
    }

    RewardChefV2 public rewardChef;

    // vault is initialize with parameters for auth (we are using OZ instead)
    // and it accept address for wrapped eth, main stable coin, and probably governance token
    /// YES
    constructor(address _authControl, address _stablecoin, address _foundation, address _rewardChef)
        SuVaultParameters(_authControl, payable(this), _foundation) {
        STABLECOIN = _stablecoin;
        VAULT_PARAMETERS = SuVaultParameters(address(this));
        rewardChef = RewardChefV2(_rewardChef);
    }

    // do not accept direct payments from users because they will be stuck on contract address
    /// YES, does work for erc20
    receive() external payable {
        revert("Unit Protocol: RESTRICTED");
    }

     // who does have vault access?
     /// anyone from canModifyVault
     // why position is not allowed to be modified during liquidation?
     /// because when it's launched - liquidators want to be sure they can participate
     // how often update can be triggered?
     /// when user borrows more
    function update(address asset, address user) public onlyVaultAccess notLiquidating(asset, user) {

        // probably should be checked if zero then skip
        ///
        uint debtWithFeeE18 = getTotalDebtE18(asset, user);

        // we decrease token debt by current debt and increase by new debt
        // can we just set new value instead?
        tokenDebtsE18[asset] = tokenDebtsE18[asset] - debtsE18[asset][user] + debtWithFeeE18;

        // we set new debt for asset of user
        debtsE18[asset][user] = debtWithFeeE18;

        // we also set new fee
        stabilityFeeE18[asset][user] = VAULT_PARAMETERS.protocolStabilityFeeE18(asset);

        // and update timestamp
        lastUpdate[asset][user] = block.timestamp;
    }

    // does it help to restore gas fees? what's the purpose of cleanup?
    /// Not clear for after London hardfork
    // how do ensure its not being called unexpectedly? very dangerous function
    /// only destroy debt info, exit -> _repay -> destroy if debt == 0
    function destroy(address asset, address user) public onlyVaultAccess {
        delete stabilityFeeE18[asset][user];
        delete lastUpdate[asset][user];
        delete liquidationBlock[asset][user];
    }

     // collateral deposit
    function deposit(address asset, address user, uint amountEDecimal) external onlyVaultAccess notLiquidating(asset, user) {
        SafeERC20.safeTransferFrom(IERC20(asset), user, address(this), amountEDecimal);
        collateralsEDecimal[asset][user] = collateralsEDecimal[asset][user] + amountEDecimal;
        rewardChef.increaseAmount(asset, user, amountEDecimal);
    }

     // collateral withdraw
     // why being called by privileged account and not by user?
    function withdraw(address asset, address user, address recipient, uint amountEDecimal) public onlyVaultAccess {
        require(amountEDecimal <= collateralsEDecimal[asset][user], "Unit protocol: WRONG_WITHDRAW");
        collateralsEDecimal[asset][user] = collateralsEDecimal[asset][user] - amountEDecimal;
        SafeERC20.safeTransfer(IERC20(asset), recipient, amountEDecimal);
        rewardChef.decreaseAmount(asset, user, amountEDecimal);
    }

    function emergencyWithdraw(address asset, address user, uint amountEDecimal) external onlyVaultAccess {
        collateralsEDecimal[asset][user] = collateralsEDecimal[asset][user] - amountEDecimal;
        SafeERC20.safeTransfer(IERC20(asset), user, amountEDecimal);

        try rewardChef.resetAmount(asset, user) {} catch {}
    }

     // BORROW == takeUnit
     /// yes, fro cdpManager01
     // user expected previously to deposit collateral and then being able to take stablecoin
     // but where do we check current user collateral and amount??
     /// in CDPManager01
     // can user create single position with multiple collaterals?
     /// no, one debt for [asset][user]
    function borrow(
        address asset,
        address user,
        uint amountE18
    )
    external
    onlyVaultAccess
    notLiquidating(asset, user)
    returns(uint)
    {
        // update debts and fees of user for collateral
        /// I think better name is needed
        update(asset, user);

        // why we update it again after update already called?
        /// because update doesn't use amount, only calc curr fees
        debtsE18[asset][user] = debtsE18[asset][user] + amountE18;
        tokenDebtsE18[asset] = tokenDebtsE18[asset] + amountE18;

        // there is a limit of total debt for each collateral
        // why that limit is needed?
        /// because of risk profile
        require(tokenDebtsE18[asset] <= VAULT_PARAMETERS.tokenDebtLimitE18(asset), "Unit Protocol: ASSET_DEBT_LIMIT");

        // here stablecoin is created for user
        SuUSD(STABLECOIN).mint(user, amountE18);

        // we return value of previous debt plus new debt
        // how this can be accessed and used by client?
        // should consider to emit events instead
        return debtsE18[asset][user];
    }

    function _cutDebt(
        address asset,
        address user,
        uint stablecoinAmountE18
    ) internal onlyVaultAccess {
        require(stablecoinAmountE18 <= debtsE18[asset][user], "Unit protocol: WRONG_DEBT");
        require(stablecoinAmountE18 <= tokenDebtsE18[asset], "Unit protocol: WRONG_TOTAL_DEBT");

        // current debt of user by given collateral
        // is being decreased by chosen amount
        debtsE18[asset][user] = debtsE18[asset][user] - stablecoinAmountE18;

        // total debt by asset is being decreased too
        // this value is used to limit total collateral allowed debt
        tokenDebtsE18[asset] = tokenDebtsE18[asset] - stablecoinAmountE18;
    }

    function liquidate(
        address asset,
        address user,
        address recipient,
        uint assetAmountEDecimal,
        uint stablecoinAmountE18
    ) external onlyVaultAccess returns (bool) {
        // what the case when stablecoinAmount allowed to be zero?
        require(assetAmountEDecimal != 0 || stablecoinAmountE18 != 0, "Unit Protocol: USELESS_TX");

        // how could stablecoinAmount be zero? then debt is zero too
        /// Yes, if you returned debt in other tx but now want to take your collateral

        // why pay stablecoin but not withdrawing collateral?
        /// To stop pay interest but have ability to loan in the future

        // reduce debt and don't repay
        if (stablecoinAmountE18 != 0) {
            _cutDebt(asset, user, stablecoinAmountE18);
        }

        // vault will transfer collateral to the user
        if (assetAmountEDecimal != 0) {
            withdraw(asset, user, recipient, assetAmountEDecimal);
        }

        // TODO: rename "partial"
        emit PositionLiquidated(asset, user, recipient, assetAmountEDecimal, stablecoinAmountE18);

        // clean state
        uint debtE18 = debtsE18[asset][user];
        if (debtE18 == 0) {
            destroy(asset, user);
            return true;
        }
        return false;
    }

    /// @notice Marks a position as to be liquidated
    /// @param asset The address of the main collateral token of a position
    /// @param positionOwner The owner of a position
    /** @dev
    Sets the current block as liquidationBlock for the position.
    Can be triggered only once for the position.
    */
    function triggerLiquidation(
        address asset,
        address positionOwner
    )
    external
    onlyVaultAccess
    notLiquidating(asset, positionOwner)
    {
        liquidationBlock[asset][positionOwner] = block.number;
    }

    // total dept is calculated as current debt with added calculated fee
    /// they don't use it in practice
    function getTotalDebtE18(address asset, address user) public view returns (uint) {
        uint debtE18 = debtsE18[asset][user];
        uint feeE18 = calculateFeeE18(asset, user, debtE18);
        return debtE18 + feeE18;
    }

     // fee is increased with time and
     /// YES
     // decreased when partial repayment is made
     /// No, any call of vault.update would calc fee in debt and restart fee timer
    function calculateFeeE18(address asset, address user, uint amountE18) public view returns (uint) {
        uint sFeePercentE18 = stabilityFeeE18[asset][user];
        uint timePast = block.timestamp - lastUpdate[asset][user];

        return amountE18 * sFeePercentE18 * timePast / (365 days) / 1e18;
    }

    // transferring chosen amount chosen asset from user to foundation address
    // can foundation address be changed?
    /// Yes, setFoundation.
    // why its being transferred from user? instead should be from this vault
    /// TODO: he doesn't have his vault with stablecoin
    // why amount is chosen manually? should be always the same value as in fees mapping
    /// this is just transfer function, manager calc fees
    /// @notice Burns a debt repayment and transfers fees to the foundation
    /// @param repayer The person who repaies by debt and transfers stablecoins to the foundation
    /// @param stablecoinsToRepaymentE18 The amount of stablecoins which will be burned as a debt repayment
    /// @param stablecoinsToFoundationE18 The amount of stablecoins which will be transfered to the foundation(e.g fees)
    function repay(
        address repayer,
        uint stablecoinsToRepaymentE18,
        uint stablecoinsToFoundationE18
    ) external onlyVaultAccess {
        emit PositionRepaid(repayer, stablecoinsToRepaymentE18, stablecoinsToFoundationE18);

        // the repayer transfers fees and excesses over the repayment
        if (stablecoinsToFoundationE18 != 0) {
            SafeERC20.safeTransferFrom(
                IERC20(STABLECOIN),
                repayer,
                VAULT_PARAMETERS.foundation(),
                stablecoinsToFoundationE18
            );
        }

        // we burn stablecoin from user
        // vault should have corresponding permission
        SuUSD(STABLECOIN).burn(repayer, stablecoinsToRepaymentE18);
    }

    function setRewardChef(address _rewardChef) public onlyVaultAccess {
        rewardChef = RewardChefV2(_rewardChef);
    }
}

// SPDX-License-Identifier: BSL 1.1

import "../access-control/SuAccessControlSingleton.sol";
import "../access-control/SuAuthenticated.sol";

pragma solidity ^0.8.0;

// VaultParameters is Singleton for Access Control
// this looks like configuration contract
// what are the rules to determine these configs for each new allowed collateral?
/// yes, and for all collaterals
// is DAO allowed to choose parameters for existing collaterals?
///
// are there any limits to be enforced? i.e. fee cannot be over 100% percent
/// No, but it's a good idea to have it
abstract contract SuVaultParameters is SuAuthenticated {
    // stability fee can be different for each collateral
    /// yes
    mapping(address => uint) public protocolStabilityFeeE18;

    // map token to USDP mint limit
    /// yes, limit for each collateral-assert
    mapping(address => uint) public tokenDebtLimitE18;

    // what is foundation, DAO?
    /// Beneficiaty as VotingEscrow.vy
    address public foundation;

    address public immutable vault;

    // creator of contract is manager, can it be the same as DAO or can it be removed later?
    /// YES
    // how can vault address be known at this moment?
    /// Precult based on CREATE spec
    // can be created another function to set vault address once deployed?
    /// Yes, possibly with some logic change
    constructor(address _authControl, address payable _vault, address _foundation)
        SuAuthenticated(_authControl)
    {
        require(_vault != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(_foundation != address(0), "Unit Protocol: ZERO_ADDRESS");

        vault = _vault;

//        ISuAccessControl(_authControl).setVault(_vault, true);
//        ISuAccessControl(_authControl).setDAO(msg.sender, true);

        foundation = _foundation;
    }

    // similar function can be added to setVault
    function setFoundation(address newFoundation) external onlyOwner {
        require(newFoundation != address(0), "Unit Protocol: ZERO_ADDRESS");
        foundation = newFoundation;
    }

    // manager is allowed to add new collaterals and modify existing ones
    // I think creating new collaterals and modifying existing ones should be separate functions
    /// Yes, for sercurity reason, it's possible to add events for creating and edititing
    // also different event should be emitted NewCollateral UpdatedCollateral accordingly
    // those events can be handled on frontend to notify user about any changes in rules
    /// Not sure it makes sense to split into create/edit functions
    function setCollateral(
        address asset,
        uint stabilityFeeValueE18,
        uint stablecoinLimitE18
    ) external onlyOwner {
        // stability fee should be validated in range, what is stability fee should be described here?
        setStabilityFeeE18(asset, stabilityFeeValueE18);
        // why debt limit for collateral is necessary? to manage risks in case of collateral failure?
        setTokenDebtLimitE18(asset, stablecoinLimitE18);
    }

    // stability fee is measured as the number of coins per year or percentage?
    // this should be clarified in argument name i.e. stabilityFeePercentageYearly
    /// No, it's APR ( per year, see calculateFee) percentrage, fee percentage.
    /// YES, self-documented code-style is the best practice.
    function setStabilityFeeE18(address asset, uint newValue) public onlyOwner {
        protocolStabilityFeeE18[asset] = newValue;
    }


    // debt limit can be changed for any collateral along with liquidation and stability fees
    // seems like managers have too much power - that can be dangerous given multiple managers?
    /// Yes, application of  principle of least priviledge needed
    function setTokenDebtLimitE18(address asset, uint limit) public onlyOwner {
        tokenDebtLimitE18[asset] = limit;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../access-control/SuAuthenticated.sol";
import "../interfaces/IRewardChefV2.sol";
import "../interfaces/ISuOracle.sol";


// fork of MasterChefV2(May-13-2021) https://etherscan.io/address/0xef0881ec094552b2e128cf945ef17a6752b4ec5d#code

/// This contract is based on MVC2, but uses "virtual" balances instead of storing real ERC20 tokens
/// and uses address of this assets instead of pid.
/// Rewards that are distributed have to be deposited using refillReward(uint256 amount, uint64 endBlock)
contract RewardChefV2 is IRewardChefV2, SuAuthenticated {
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for uint64;
    using SafeCast for int256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // SuDAO: instead of pool Ids (pid) we use address of the asset directly.
    //        Also, there aren't just LPs but regular assets as well
    /// @notice Info of each MCV2 pool. PoolInfo memory pool = poolInfo[_pid]
    //    PoolInfo[] public poolInfo;
    mapping (address => PoolInfo) public poolInfo;
    /// @notice Address of the LP token for each MCV2 pool.
    //    IERC20[] public lpTokens;
    /// @notice Set of reward-able assets
    EnumerableSet.AddressSet private assetSet;

    /// @notice Info of each user that stakes tokens. userInfo[_asset][_user]
    mapping (address => mapping (address => UserInfo)) public userInfo;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    /// The good practice, to always keep this variable is equal 1000.
    uint256 public override totalAllocPoint;

    uint256 private constant ACC_REWARD_TOKEN_PRECISION = 1e12; // TODO*: make it 1e18? check values overflow

//    // we would use just "lpToken to poolId" but because mapper is init with zeros by default
//    // that would create a edge case for the first pool with pID 0, so we store pID + 1 instead
//    mapping (address => uint256) private _lpTokenToPoolIdPlus1;

    // ==========================REWARDER================================
    /// @notice Address of REWARD_TOKEN contract.
    IERC20 public immutable override REWARD_TOKEN;
    ISuOracle public immutable ORACLE;

    uint256 public rewardPerBlock;
    uint256 public override rewardEndBlock;

    function refillReward(uint256 amount, uint64 endBlock) public onlyOwner override {
        require(endBlock > block.number, "EndBlock should be greater than current block");
        // TODO: gas optimization
        updateAllPools();

        REWARD_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        uint256 rewardLeftAmount;
        // if there are active rewards leftovers
        if (rewardEndBlock > 0) {
            // if we call refillReward before old endBlock ends
            if (block.number < rewardEndBlock) {
                rewardLeftAmount = rewardPerBlock * (rewardEndBlock - block.number);
            } else {
                // if we start the new reward interval that has nothing in common with the old noe
                rewardLeftAmount = 0;
            }
        }
        rewardPerBlock = (rewardLeftAmount + amount) / (endBlock - block.number);
        rewardEndBlock = endBlock;
    }

    /**
     *  @dev returns total amount of rewards allocated to the all pools on the rage (startBlock, endBlock]
     *      i.e. excluding startBlock but including endBlock
     */
    function rewardsBetweenBlocks(uint256 startBlock, uint256 endBlock) public view override returns (uint256) {
        // if all rewards were allocation before our rage - then answer is 0
        if (rewardEndBlock <= startBlock) {
            return 0;
        } else {
            // if rewards allocates on the whole range, than just calc rectangle area
            if (endBlock < rewardEndBlock) {
                return (endBlock - startBlock) * rewardPerBlock;
            } else {
                // other-vice, rewards end its allocation during our rage, so we have to calc only until rewardEndBlock
                return (rewardEndBlock - startBlock) * rewardPerBlock;
            }
        }
    }

    //===================================================================

//    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event VirtualDeposit(address indexed user, address indexed asset, uint256 amount);
//    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event VirtualWithdraw(address indexed user, address indexed asset, uint256 amount);
    event ResetAmount(address indexed user, address indexed asset, uint256 amount, address indexed to);
    event Harvest(address indexed user, address indexed asset, uint256 amount);
//    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event LogPoolAddition(address indexed asset, uint256 allocPoint);
    event LogSetPool(address indexed asset, uint256 allocPoint);
    event LogUpdatePool(address indexed asset, uint64 lastRewardBlock, uint256 lpSupply, uint256 accSushiPerShare);


    /// @param _rewardToken The REWARD_TOKEN token contract address.
    constructor(address _authControl, IERC20 _rewardToken, ISuOracle _oracle) SuAuthenticated(_authControl) {
        REWARD_TOKEN = _rewardToken;
        ORACLE = _oracle;
    }
//
//    /// @notice Returns the number of MCV2 pools.
//    function poolLength() public view returns (uint256 pools) {
//        pools = poolInfo.length;
//    }
//
//    function lpTokenToPoolId(address _lpToken) view public returns (uint256) {
//        uint256 pIdPlus1 = _lpTokenToPoolIdPlus1[_lpToken];
//        require(pIdPlus1 > 0, "pool for this lpToken doesn't exist");
//        return  pIdPlus1 - 1;
//    }

    /// @notice Add a new reward  pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once.
    /// @param allocPoint AP of the new pool.
    /// @param _asset Address of the ERC-20 token.
    function add(uint256 allocPoint, address _asset) public onlyOwner override {
        // check for possible duplications
        require(poolInfo[_asset].lastRewardBlock == 0, "Pool already exist");

        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint + allocPoint;
//        lpTokens.push(_lpToken);
        assetSet.add(_asset);

        poolInfo[_asset] = PoolInfo({
            allocPoint: allocPoint.toUint64(),
            lastRewardBlock: lastRewardBlock.toUint64(),
            accSushiPerShare: 0,
            lpSupply: 0
        });

//        _lpTokenToPoolIdPlus1[address(_lpToken)] = poolInfo.length;
        emit LogPoolAddition(_asset, allocPoint);
    }

    /// @notice Update the given pool's REWARD_TOKEN allocation point. Can only be called by the owner.
    /// @param _asset The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(address _asset, uint256 _allocPoint) public onlyOwner override {
        require(poolInfo[_asset].lastRewardBlock != 0, "Pool doesn't exist");
        // TODO: why was it in legal in MVC2 to call this function without mandatory update method?
        updatePool(_asset);
        totalAllocPoint = totalAllocPoint - poolInfo[_asset].allocPoint + _allocPoint;
        poolInfo[_asset].allocPoint = _allocPoint.toUint64();
        if (_allocPoint == 0) {
            // updatePool(_asset); // TODO: does we need that?
            assetSet.remove(_asset);
        }
        emit LogSetPool(_asset, _allocPoint);
    }

    /// @notice View function to see pending REWARD_TOKEN on frontend.
    /// @param _asset The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending REWARD_TOKEN reward for a given user.
    function pendingSushi(address _asset, address _user) external view override returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_asset];
        UserInfo storage user = userInfo[_asset][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        // we don't have real balances anymore, so instead of
        //        uint256 lpSupply = lpTokens[_pid].balanceOf(address(this));
        // we use virtual total balance
        uint256 lpSupply = poolInfo[_asset].lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && totalAllocPoint != 0) {
            /// how much reward were minted since last update pool.lastRewardBlock
            uint256 totalSushiReward = rewardsBetweenBlocks(pool.lastRewardBlock, block.number);
            uint256 poolSushiReward = totalSushiReward * pool.allocPoint / totalAllocPoint;
            // account it into share value
            accSushiPerShare = accSushiPerShare + (poolSushiReward * ACC_REWARD_TOKEN_PRECISION / lpSupply);
        }
        pending = ((user.amount * accSushiPerShare / ACC_REWARD_TOKEN_PRECISION).toInt256() - user.rewardDebt).toUint256();
    }

    /// @notice Update reward variables of the given pool.
    /// @param asset Asset address
    /// @return pool Returns the pool that was updated.
    function updatePool(address asset) public override returns (PoolInfo memory pool) {
        pool = poolInfo[asset];
        if (block.number > pool.lastRewardBlock) {
            //            uint256 lpSupply = lpTokens[pid].balanceOf(address(this));
            uint256 lpSupply = pool.lpSupply;
            if (lpSupply > 0 && pool.allocPoint > 0) {
                /// calc how much rewards are minted since pool.lastRewardBlock for the pool
                uint256 totalSushiReward = rewardsBetweenBlocks(pool.lastRewardBlock, block.number);
                uint256 poolSushiReward = totalSushiReward * pool.allocPoint / totalAllocPoint;
                ///
                pool.accSushiPerShare = pool.accSushiPerShare + (poolSushiReward * ACC_REWARD_TOKEN_PRECISION / lpSupply).toUint128();
            }
            pool.lastRewardBlock = block.number.toUint64();
            poolInfo[asset] = pool;
            emit LogUpdatePool(asset, pool.lastRewardBlock, lpSupply, pool.accSushiPerShare);
        }
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function updateAllPools() public override {
        address[] memory assets = assetSet.values();
        uint256 len = assets.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(assets[i]);
        }
    }

    /// @notice analogues to MCV2 Deposit method, but can be called only by trusted address
    // that is trusted to honestly calc how many "virtual" tokens have to be allocated for each user.
    function increaseAmount(address asset, address to, uint256 amountEDecimal) public onlyOwner override {
        PoolInfo memory pool = updatePool(asset);
        UserInfo storage user = userInfo[asset][to];

        // Effects
        user.amount = user.amount + amountEDecimal;
        user.rewardDebt = user.rewardDebt + (amountEDecimal * pool.accSushiPerShare / ACC_REWARD_TOKEN_PRECISION).toInt256();

        // we don't need, since the balances are virtual
        // lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);
        // but we need to calc total supply of virtual tokens
        pool.lpSupply = pool.lpSupply + amountEDecimal;
        poolInfo[asset] = pool;

        emit VirtualDeposit(to, asset, amountEDecimal);
    }

    /// @notice Analogues to MVC2 Withdraw method, that can be called only by trusted address
    /// that is trusted to honestly calc how many "virtual" tokens have to be allocated for each user.
    function decreaseAmount(address asset, address to, uint256 amountEDecimal) public onlyOwner override {
        PoolInfo memory pool = updatePool(asset);
        UserInfo storage user = userInfo[asset][to];

        // Effects
        user.rewardDebt = user.rewardDebt - (amountEDecimal * pool.accSushiPerShare / ACC_REWARD_TOKEN_PRECISION).toInt256();
        user.amount = user.amount - amountEDecimal;

        //        lpTokens[pid].safeTransfer(to, amount);
        pool.lpSupply = pool.lpSupply - amountEDecimal;
        poolInfo[asset] = pool;

        emit VirtualWithdraw(to, asset, amountEDecimal);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param asset Asset address
    /// @param to Receiver of REWARD_TOKEN rewards.
    function harvest(address asset, address to) public override {
        PoolInfo memory pool = updatePool(asset);
        UserInfo storage user = userInfo[asset][msg.sender];

        int256 accumulatedSushi = (user.amount * pool.accSushiPerShare / ACC_REWARD_TOKEN_PRECISION).toInt256();
        uint256 _pendingSushi = (accumulatedSushi - user.rewardDebt).toUint256();

        // Effects
        user.rewardDebt = accumulatedSushi;

        // Interactions
        if (_pendingSushi != 0) {
            REWARD_TOKEN.safeTransfer(to, _pendingSushi);
        }

        emit Harvest(msg.sender, asset, _pendingSushi);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param asset Asset address
    /// @param to The address of the user whose information will be cleared
    function resetAmount(address asset, address to) public override {
        updatePool(asset);
        UserInfo storage user = userInfo[asset][msg.sender];
        emit ResetAmount(msg.sender, asset, user.amount, to);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function getPoolApr(address asset) public view returns (uint256) {
        require(poolInfo[asset].lastRewardBlock != 0, "RewardChef: Pool doesn't exist");
        require(totalAllocPoint != 0, 'RewardChef: Total allocation point is 0');

        uint256 rewardPerBlockForPool = rewardPerBlock * poolInfo[asset].allocPoint / totalAllocPoint;
        uint256 rewardTokenPrice = ORACLE.getUsdPrice1e18(address(REWARD_TOKEN));
        uint256 usdRewardYearForPool = rewardPerBlockForPool * 4 * 60 * 24 * 366 * rewardTokenPrice;
        uint256 usdValuePool = poolInfo[asset].lpSupply * ORACLE.getUsdPrice1e18(asset);
        return usdRewardYearForPool * 1e18 / usdValuePool;
    }
}