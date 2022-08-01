// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IUpgradeable } from "../../utility/interfaces/IUpgradeable.sol";

import { Token } from "../../token/Token.sol";

import { IPoolCollection } from "../../pools/interfaces/IPoolCollection.sol";
import { IPoolToken } from "../../pools/interfaces/IPoolToken.sol";

/**
 * @dev Flash-loan recipient interface
 */
interface IFlashLoanRecipient {
    /**
     * @dev a flash-loan recipient callback after each the caller must return the borrowed amount and an additional fee
     */
    function onFlashLoan(
        address caller,
        IERC20 erc20Token,
        uint256 amount,
        uint256 feeAmount,
        bytes memory data
    ) external;
}

/**
 * @dev Bancor Network interface
 */
interface IBancorNetwork is IUpgradeable {
    /**
     * @dev returns the set of all valid pool collections
     */
    function poolCollections() external view returns (IPoolCollection[] memory);

    /**
     * @dev returns the set of all liquidity pools
     */
    function liquidityPools() external view returns (Token[] memory);

    /**
     * @dev returns the respective pool collection for the provided pool
     */
    function collectionByPool(Token pool) external view returns (IPoolCollection);

    /**
     * @dev creates new pools
     *
     * requirements:
     *
     * - none of the pools already exists
     */
    function createPools(Token[] calldata tokens, IPoolCollection poolCollection) external;

    /**
     * @dev migrates a list of pools between pool collections
     *
     * notes:
     *
     * - invalid or incompatible pools will be skipped gracefully
     */
    function migratePools(Token[] calldata pools, IPoolCollection newPoolCollection) external;

    /**
     * @dev deposits liquidity for the specified provider and returns the respective pool token amount
     *
     * requirements:
     *
     * - the caller must have approved the network to transfer the tokens on its behalf (except for in the
     *   native token case)
     */
    function depositFor(
        address provider,
        Token pool,
        uint256 tokenAmount
    ) external payable returns (uint256);

    /**
     * @dev deposits liquidity for the current provider and returns the respective pool token amount
     *
     * requirements:
     *
     * - the caller must have approved the network to transfer the tokens on its behalf (except for in the
     *   native token case)
     */
    function deposit(Token pool, uint256 tokenAmount) external payable returns (uint256);

    /**
     * @dev initiates liquidity withdrawal
     *
     * requirements:
     *
     * - the caller must have approved the contract to transfer the pool token amount on its behalf
     */
    function initWithdrawal(IPoolToken poolToken, uint256 poolTokenAmount) external returns (uint256);

    /**
     * @dev cancels a withdrawal request, and returns the number of pool token amount associated with the withdrawal
     * request
     *
     * requirements:
     *
     * - the caller must have already initiated a withdrawal and received the specified id
     */
    function cancelWithdrawal(uint256 id) external returns (uint256);

    /**
     * @dev withdraws liquidity and returns the withdrawn amount
     *
     * requirements:
     *
     * - the provider must have already initiated a withdrawal and received the specified id
     * - the specified withdrawal request is eligible for completion
     * - the provider must have approved the network to transfer vBNT amount on its behalf, when withdrawing BNT
     * liquidity
     */
    function withdraw(uint256 id) external returns (uint256);

    /**
     * @dev performs a trade by providing the input source amount, sends the proceeds to the optional beneficiary (or
     * to the address of the caller, in case it's not supplied), and returns the trade target amount
     *
     * requirements:
     *
     * - the caller must have approved the network to transfer the source tokens on its behalf (except for in the
     *   native token case)
     */
    function tradeBySourceAmount(
        Token sourceToken,
        Token targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable returns (uint256);

    /**
     * @dev performs a trade by providing the output target amount, sends the proceeds to the optional beneficiary (or
     * to the address of the caller, in case it's not supplied), and returns the trade source amount
     *
     * requirements:
     *
     * - the caller must have approved the network to transfer the source tokens on its behalf (except for in the
     *   native token case)
     */
    function tradeByTargetAmount(
        Token sourceToken,
        Token targetToken,
        uint256 targetAmount,
        uint256 maxSourceAmount,
        uint256 deadline,
        address beneficiary
    ) external payable returns (uint256);

    /**
     * @dev provides a flash-loan
     *
     * requirements:
     *
     * - the recipient's callback must return *at least* the borrowed amount and fee back to the specified return address
     */
    function flashLoan(
        Token token,
        uint256 amount,
        IFlashLoanRecipient recipient,
        bytes calldata data
    ) external;

    /**
     * @dev deposits liquidity during a migration
     */
    function migrateLiquidity(
        Token token,
        address provider,
        uint256 amount,
        uint256 availableAmount,
        uint256 originalAmount
    ) external payable;

    /**
     * @dev withdraws pending network fees, and returns the amount of fees withdrawn
     *
     * requirements:
     *
     * - the caller must have the ROLE_NETWORK_FEE_MANAGER privilege
     */
    function withdrawNetworkFees(address recipient) external returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IUpgradeable } from "../../utility/interfaces/IUpgradeable.sol";

import { Token } from "../../token/Token.sol";

error NotWhitelisted();

struct VortexRewards {
    // the percentage of converted BNT to be sent to the initiator of the burning event (in units of PPM)
    uint32 burnRewardPPM;
    // the maximum burn reward to be sent to the initiator of the burning event
    uint256 burnRewardMaxAmount;
}

/**
 * @dev Network Settings interface
 */
interface INetworkSettings is IUpgradeable {
    /**
     * @dev returns the protected tokens whitelist
     */
    function protectedTokenWhitelist() external view returns (Token[] memory);

    /**
     * @dev checks whether a given token is whitelisted
     */
    function isTokenWhitelisted(Token pool) external view returns (bool);

    /**
     * @dev returns the BNT funding limit for a given pool
     */
    function poolFundingLimit(Token pool) external view returns (uint256);

    /**
     * @dev returns the minimum BNT trading liquidity required before the system enables trading in the relevant pool
     */
    function minLiquidityForTrading() external view returns (uint256);

    /**
     * @dev returns the withdrawal fee (in units of PPM)
     */
    function withdrawalFeePPM() external view returns (uint32);

    /**
     * @dev returns the default flash-loan fee (in units of PPM)
     */
    function defaultFlashLoanFeePPM() external view returns (uint32);

    /**
     * @dev returns the flash-loan fee (in units of PPM) of a pool
     */
    function flashLoanFeePPM(Token pool) external view returns (uint32);

    /**
     * @dev returns the vortex settings
     */
    function vortexRewards() external view returns (VortexRewards memory);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Token } from "../token/Token.sol";
import { TokenLibrary } from "../token/TokenLibrary.sol";

import { IMasterVault } from "../vaults/interfaces/IMasterVault.sol";
import { IExternalProtectionVault } from "../vaults/interfaces/IExternalProtectionVault.sol";

import { IVersioned } from "../utility/interfaces/IVersioned.sol";

import { PPM_RESOLUTION } from "../utility/Constants.sol";
import { Owned } from "../utility/Owned.sol";
import { BlockNumber } from "../utility/BlockNumber.sol";
import { Fraction, Fraction112, FractionLibrary, zeroFraction, zeroFraction112 } from "../utility/FractionLibrary.sol";
import { Sint256, MathEx } from "../utility/MathEx.sol";

// prettier-ignore
import {
    Utils,
    AlreadyExists,
    DoesNotExist,
    InvalidParam,
    InvalidPoolCollection,
    InvalidStakedBalance
} from "../utility/Utils.sol";

import { INetworkSettings, NotWhitelisted } from "../network/interfaces/INetworkSettings.sol";
import { IBancorNetwork } from "../network/interfaces/IBancorNetwork.sol";

import { IPoolToken } from "./interfaces/IPoolToken.sol";
import { IPoolTokenFactory } from "./interfaces/IPoolTokenFactory.sol";
import { IPoolMigrator } from "./interfaces/IPoolMigrator.sol";

// prettier-ignore
import {
    AverageRates,
    IPoolCollection,
    PoolLiquidity,
    Pool,
    TRADING_STATUS_UPDATE_DEFAULT,
    TRADING_STATUS_UPDATE_ADMIN,
    TRADING_STATUS_UPDATE_MIN_LIQUIDITY,
    TRADING_STATUS_UPDATE_INVALID_STATE,
    TradeAmountAndFee,
    WithdrawalAmounts
} from "./interfaces/IPoolCollection.sol";

import { IBNTPool } from "./interfaces/IBNTPool.sol";

import { PoolCollectionWithdrawal } from "./PoolCollectionWithdrawal.sol";

// base token withdrawal output amounts
struct InternalWithdrawalAmounts {
    uint256 baseTokensToTransferFromMasterVault; // base token amount to transfer from the master vault to the provider
    uint256 bntToMintForProvider; // BNT amount to mint directly for the provider
    uint256 baseTokensToTransferFromEPV; // base token amount to transfer from the external protection vault to the provider
    Sint256 baseTokensTradingLiquidityDelta; // base token amount to add to the trading liquidity
    Sint256 bntTradingLiquidityDelta; // BNT amount to add to the trading liquidity and to the master vault
    Sint256 bntProtocolHoldingsDelta; // BNT amount add to the protocol equity
    uint256 baseTokensWithdrawalFee; // base token amount to keep in the pool as a withdrawal fee
    uint256 baseTokensWithdrawalAmount; // base token amount equivalent to the base pool token's withdrawal amount
    uint256 poolTokenAmount; // base pool token
    uint256 poolTokenTotalSupply; // base pool token's total supply
    uint256 newBaseTokenTradingLiquidity; // new base token trading liquidity
    uint256 newBNTTradingLiquidity; // new BNT trading liquidity
}

struct TargetTradingLiquidity {
    bool update;
    uint256 bnt;
    uint256 baseToken;
}

enum PoolRateState {
    Uninitialized,
    Unstable,
    Stable
}

/**
 * @dev Pool Collection contract
 *
 * notes:
 *
 * - the address of reserve token serves as the pool unique ID in both contract functions and events
 */
contract PoolCollection is IPoolCollection, Owned, BlockNumber, Utils {
    using TokenLibrary for Token;
    using FractionLibrary for Fraction;
    using FractionLibrary for Fraction112;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeCast for uint256;

    error AlreadyEnabled();
    error DepositingDisabled();
    error InsufficientLiquidity();
    error InsufficientSourceAmount();
    error InsufficientTargetAmount();
    error InvalidRate();
    error RateUnstable();
    error TradingDisabled();
    error FundingLimitTooHigh();

    uint16 private constant POOL_TYPE = 1;
    uint256 private constant LIQUIDITY_GROWTH_FACTOR = 2;
    uint256 private constant BOOTSTRAPPING_LIQUIDITY_BUFFER_FACTOR = 2;
    uint32 private constant DEFAULT_TRADING_FEE_PPM = 2_000; // 0.2%
    uint32 private constant DEFAULT_NETWORK_FEE_PPM = 200_000; // 20%
    uint32 private constant RATE_MAX_DEVIATION_PPM = 10_000; // %1
    uint32 private constant RATE_RESET_BLOCK_THRESHOLD = 100;

    // the average rate is recalculated based on the ratio between the weights of the rates the smaller the weights are,
    // the larger the supported range of each one of the rates is
    uint256 private constant EMA_AVERAGE_RATE_WEIGHT = 4;
    uint256 private constant EMA_SPOT_RATE_WEIGHT = 1;

    struct TradeIntermediateResult {
        uint256 sourceAmount;
        uint256 targetAmount;
        uint256 limit;
        uint256 tradingFeeAmount;
        uint256 networkFeeAmount;
        uint256 sourceBalance;
        uint256 targetBalance;
        uint256 stakedBalance;
        Token pool;
        bool isSourceBNT;
        bool bySourceAmount;
        uint32 tradingFeePPM;
        bytes32 contextId;
    }

    struct TradeAmountAndTradingFee {
        uint256 amount;
        uint256 tradingFeeAmount;
    }

    // the network contract
    IBancorNetwork private immutable _network;

    // the address of the BNT token
    IERC20 private immutable _bnt;

    // the network settings contract
    INetworkSettings private immutable _networkSettings;

    // the master vault contract
    IMasterVault private immutable _masterVault;

    // the BNT pool contract
    IBNTPool internal immutable _bntPool;

    // the address of the external protection vault
    IExternalProtectionVault private immutable _externalProtectionVault;

    // the pool token factory contract
    IPoolTokenFactory private immutable _poolTokenFactory;

    // the pool migrator contract
    IPoolMigrator private immutable _poolMigrator;

    // a mapping between tokens and their pools
    mapping(Token => Pool) internal _poolData;

    // the set of all pools which are managed by this pool collection
    EnumerableSet.AddressSet private _pools;

    // the default trading fee (in units of PPM)
    uint32 private _defaultTradingFeePPM;

    // the global network fee (in units of PPM)
    uint32 private _networkFeePPM;

    // true if protection is enabled, false otherwise
    bool private _protectionEnabled = true;

    /**
     * @dev triggered when the default trading fee is updated
     */
    event DefaultTradingFeePPMUpdated(uint32 prevFeePPM, uint32 newFeePPM);

    /**
     * @dev triggered when the network fee is updated
     */
    event NetworkFeePPMUpdated(uint32 prevFeePPM, uint32 newFeePPM);

    /**
     * @dev triggered when a specific pool's trading fee is updated
     */
    event TradingFeePPMUpdated(Token indexed pool, uint32 prevFeePPM, uint32 newFeePPM);

    /**
     * @dev triggered when trading in a specific pool is enabled/disabled
     */
    event TradingEnabled(Token indexed pool, bool indexed newStatus, uint8 indexed reason);

    /**
     * @dev triggered when depositing into a specific pool is enabled/disabled
     */
    event DepositingEnabled(Token indexed pool, bool indexed newStatus);

    /**
     * @dev triggered when new liquidity is deposited into a pool
     */
    event TokensDeposited(
        bytes32 indexed contextId,
        address indexed provider,
        Token indexed token,
        uint256 baseTokenAmount,
        uint256 poolTokenAmount
    );

    /**
     * @dev triggered when existing liquidity is withdrawn from a pool
     */
    event TokensWithdrawn(
        bytes32 indexed contextId,
        address indexed provider,
        Token indexed token,
        uint256 baseTokenAmount,
        uint256 poolTokenAmount,
        uint256 externalProtectionBaseTokenAmount,
        uint256 bntAmount,
        uint256 withdrawalFeeAmount
    );

    /**
     * @dev triggered when the trading liquidity in a pool is updated
     */
    event TradingLiquidityUpdated(
        bytes32 indexed contextId,
        Token indexed pool,
        Token indexed token,
        uint256 prevLiquidity,
        uint256 newLiquidity
    );

    /**
     * @dev triggered when the total liquidity in a pool is updated
     */
    event TotalLiquidityUpdated(
        bytes32 indexed contextId,
        Token indexed pool,
        uint256 liquidity,
        uint256 stakedBalance,
        uint256 poolTokenSupply
    );

    /**
     * @dev initializes a new PoolCollection contract
     */
    constructor(
        IBancorNetwork initNetwork,
        IERC20 initBNT,
        INetworkSettings initNetworkSettings,
        IMasterVault initMasterVault,
        IBNTPool initBNTPool,
        IExternalProtectionVault initExternalProtectionVault,
        IPoolTokenFactory initPoolTokenFactory,
        IPoolMigrator initPoolMigrator
    ) {
        _validAddress(address(initNetwork));
        _validAddress(address(initBNT));
        _validAddress(address(initNetworkSettings));
        _validAddress(address(initMasterVault));
        _validAddress(address(initBNTPool));
        _validAddress(address(initExternalProtectionVault));
        _validAddress(address(initPoolTokenFactory));
        _validAddress(address(initPoolMigrator));

        _network = initNetwork;
        _bnt = initBNT;
        _networkSettings = initNetworkSettings;
        _masterVault = initMasterVault;
        _bntPool = initBNTPool;
        _externalProtectionVault = initExternalProtectionVault;
        _poolTokenFactory = initPoolTokenFactory;
        _poolMigrator = initPoolMigrator;

        _setDefaultTradingFeePPM(DEFAULT_TRADING_FEE_PPM);
        _setNetworkFeePPM(DEFAULT_NETWORK_FEE_PPM);
    }

    /**
     * @inheritdoc IVersioned
     */
    function version() external view virtual returns (uint16) {
        return 10;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function poolType() external view virtual returns (uint16) {
        return POOL_TYPE;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function defaultTradingFeePPM() external view returns (uint32) {
        return _defaultTradingFeePPM;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function networkFeePPM() external view returns (uint32) {
        return _networkFeePPM;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function pools() external view returns (Token[] memory) {
        uint256 length = _pools.length();
        Token[] memory list = new Token[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = Token(_pools.at(i));
        }
        return list;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function poolCount() external view returns (uint256) {
        return _pools.length();
    }

    /**
     * @dev sets the default trading fee (in units of PPM)
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function setDefaultTradingFeePPM(uint32 newDefaultTradingFeePPM)
        external
        onlyOwner
        validFee(newDefaultTradingFeePPM)
    {
        _setDefaultTradingFeePPM(newDefaultTradingFeePPM);
    }

    /**
     * @dev sets the network fee (in units of PPM)
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function setNetworkFeePPM(uint32 newNetworkFeePPM) external onlyOwner validFee(newNetworkFeePPM) {
        _setNetworkFeePPM(newNetworkFeePPM);
    }

    /**
     * @dev enables/disables protection
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function enableProtection(bool status) external onlyOwner {
        if (_protectionEnabled == status) {
            return;
        }

        _protectionEnabled = status;
    }

    /**
     * @dev returns the status of the protection
     */
    function protectionEnabled() external view returns (bool) {
        return _protectionEnabled;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function createPool(Token token) external only(address(_network)) {
        if (!_networkSettings.isTokenWhitelisted(token)) {
            revert NotWhitelisted();
        }

        IPoolToken newPoolToken = IPoolToken(_poolTokenFactory.createPoolToken(token));

        newPoolToken.acceptOwnership();

        Pool memory newPool = Pool({
            poolToken: newPoolToken,
            tradingFeePPM: _defaultTradingFeePPM,
            tradingEnabled: false,
            depositingEnabled: true,
            averageRates: AverageRates({ blockNumber: 0, rate: zeroFraction112(), invRate: zeroFraction112() }),
            liquidity: PoolLiquidity({ bntTradingLiquidity: 0, baseTokenTradingLiquidity: 0, stakedBalance: 0 })
        });

        _addPool(token, newPool);

        emit TradingEnabled({ pool: token, newStatus: newPool.tradingEnabled, reason: TRADING_STATUS_UPDATE_DEFAULT });
        emit TradingFeePPMUpdated({ pool: token, prevFeePPM: 0, newFeePPM: newPool.tradingFeePPM });
        emit DepositingEnabled({ pool: token, newStatus: newPool.depositingEnabled });
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function isPoolValid(Token pool) external view returns (bool) {
        return address(_poolData[pool].poolToken) != address(0);
    }

    /**
     * @dev returns specific pool's data
     *
     * notes:
     *
     * - there is no guarantee that this function will remain forward compatible,
     *   so relying on it should be avoided and instead, rely on specific getters
     *   from the IPoolCollection interface
     */
    function poolData(Token pool) external view returns (Pool memory) {
        return _poolData[pool];
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function poolLiquidity(Token pool) external view returns (PoolLiquidity memory) {
        return _poolData[pool].liquidity;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function poolToken(Token pool) external view returns (IPoolToken) {
        return _poolData[pool].poolToken;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function tradingFeePPM(Token pool) external view returns (uint32) {
        return _poolData[pool].tradingFeePPM;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function tradingEnabled(Token pool) external view returns (bool) {
        return _poolData[pool].tradingEnabled;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function depositingEnabled(Token pool) external view returns (bool) {
        return _poolData[pool].depositingEnabled;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function poolTokenToUnderlying(Token pool, uint256 poolTokenAmount) external view returns (uint256) {
        Pool storage data = _poolData[pool];

        return _poolTokenToUnderlying(poolTokenAmount, data.poolToken.totalSupply(), data.liquidity.stakedBalance);
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function underlyingToPoolToken(Token pool, uint256 baseTokenAmount) external view returns (uint256) {
        Pool storage data = _poolData[pool];

        return _underlyingToPoolToken(baseTokenAmount, data.poolToken.totalSupply(), data.liquidity.stakedBalance);
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function poolTokenAmountToBurn(
        Token pool,
        uint256 baseTokenAmountToDistribute,
        uint256 protocolPoolTokenAmount
    ) external view returns (uint256) {
        if (baseTokenAmountToDistribute == 0) {
            return 0;
        }

        Pool storage data = _poolData[pool];

        uint256 poolTokenSupply = data.poolToken.totalSupply();
        uint256 val = baseTokenAmountToDistribute * poolTokenSupply;

        return
            MathEx.mulDivF(
                val,
                poolTokenSupply,
                val + data.liquidity.stakedBalance * (poolTokenSupply - protocolPoolTokenAmount)
            );
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function isPoolStable(Token pool) external view returns (bool) {
        Pool storage data = _poolData[pool];

        return _poolRateState(data) == PoolRateState.Stable;
    }

    /**
     * @dev sets the trading fee of a given pool
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function setTradingFeePPM(Token pool, uint32 newTradingFeePPM) external onlyOwner validFee(newTradingFeePPM) {
        Pool storage data = _poolStorage(pool);

        uint32 prevTradingFeePPM = data.tradingFeePPM;
        if (prevTradingFeePPM == newTradingFeePPM) {
            return;
        }

        data.tradingFeePPM = newTradingFeePPM;

        emit TradingFeePPMUpdated({ pool: pool, prevFeePPM: prevTradingFeePPM, newFeePPM: newTradingFeePPM });
    }

    /**
     * @dev enables trading in a given pool, by providing the funding rate as two virtual balances, and updates its
     * trading liquidity
     *
     * note that the virtual balances should be derived from token prices, normalized to the smallest unit of
     * tokens. In other words, the ratio between BNT and TKN virtual balances should be the ratio between the $ value
     * of 1 wei of TKN and 1 wei of BNT, taking both of their decimals into account. For example:
     *
     * - if the price of one (10**18 wei) BNT is $X and the price of one (10**18 wei) TKN is $Y, then the virtual balances
     *   should represent a ratio of X to Y
     * - if the price of one (10**18 wei) BNT is $X and the price of one (10**6 wei) USDC is $Y, then the virtual balances
     *   should represent a ratio of X to Y*10**12
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function enableTrading(
        Token pool,
        uint256 bntVirtualBalance,
        uint256 baseTokenVirtualBalance
    ) external onlyOwner {
        Fraction memory fundingRate = Fraction({ n: bntVirtualBalance, d: baseTokenVirtualBalance });
        _validRate(fundingRate);

        Pool storage data = _poolStorage(pool);

        if (data.tradingEnabled) {
            revert AlreadyEnabled();
        }

        // adjust the trading liquidity based on the base token vault balance and funding limits
        bytes32 contextId = keccak256(abi.encodePacked(msg.sender, pool, bntVirtualBalance, baseTokenVirtualBalance));
        uint256 minLiquidityForTrading = _networkSettings.minLiquidityForTrading();
        _updateTradingLiquidity(contextId, pool, data, fundingRate, minLiquidityForTrading);

        // verify that the BNT trading liquidity is equal or greater than the minimum liquidity for trading
        if (data.liquidity.bntTradingLiquidity < minLiquidityForTrading) {
            revert InsufficientLiquidity();
        }

        Fraction112 memory fundingRate112 = fundingRate.toFraction112();
        data.averageRates = AverageRates({
            blockNumber: _blockNumber(),
            rate: fundingRate112,
            invRate: fundingRate112.inverse()
        });

        data.tradingEnabled = true;

        emit TradingEnabled({ pool: pool, newStatus: true, reason: TRADING_STATUS_UPDATE_ADMIN });
    }

    /**
     * @dev disables trading in a given pool
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function disableTrading(Token pool) external onlyOwner {
        Pool storage data = _poolStorage(pool);
        _resetTradingLiquidity(bytes32(0), pool, data, data.liquidity, TRADING_STATUS_UPDATE_ADMIN);
    }

    /**
     * @dev adjusts the trading liquidity in the given pool based on the base token
     * vault balance/funding limit
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function updateTradingLiquidity(Token pool) external onlyOwner {
        Pool storage data = _poolStorage(pool);
        PoolLiquidity memory liquidity = data.liquidity;

        bytes32 contextId = keccak256(
            abi.encodePacked(msg.sender, pool, liquidity.bntTradingLiquidity, liquidity.baseTokenTradingLiquidity)
        );

        AverageRates memory effectiveAverageRates = _effectiveAverageRates(
            data.averageRates,
            Fraction({ n: liquidity.bntTradingLiquidity, d: liquidity.baseTokenTradingLiquidity })
        );
        uint256 minLiquidityForTrading = _networkSettings.minLiquidityForTrading();
        _updateTradingLiquidity(
            contextId,
            pool,
            data,
            effectiveAverageRates.rate.fromFraction112(),
            minLiquidityForTrading
        );
    }

    /**
     * @dev enables/disables depositing into a given pool
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function enableDepositing(Token pool, bool status) external onlyOwner {
        Pool storage data = _poolStorage(pool);

        if (data.depositingEnabled == status) {
            return;
        }

        data.depositingEnabled = status;

        emit DepositingEnabled({ pool: pool, newStatus: status });
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function depositFor(
        bytes32 contextId,
        address provider,
        Token pool,
        uint256 baseTokenAmount
    ) external only(address(_network)) validAddress(provider) greaterThanZero(baseTokenAmount) returns (uint256) {
        Pool storage data = _poolStorage(pool);

        if (!data.depositingEnabled) {
            revert DepositingDisabled();
        }

        // if there are no pool tokens available to support the staked balance - reset the
        // trading liquidity and the staked balance
        // in addition, get the effective average rates
        uint256 prevPoolTokenTotalSupply = data.poolToken.totalSupply();
        uint256 currentStakedBalance = data.liquidity.stakedBalance;
        AverageRates memory effectiveAverageRates;
        if (prevPoolTokenTotalSupply == 0 && currentStakedBalance != 0) {
            currentStakedBalance = 0;

            PoolLiquidity memory prevLiquidity = data.liquidity;
            _resetTradingLiquidity(contextId, pool, data, prevLiquidity, TRADING_STATUS_UPDATE_INVALID_STATE);
            effectiveAverageRates = AverageRates({
                blockNumber: 0,
                rate: zeroFraction112(),
                invRate: zeroFraction112()
            });
        } else {
            PoolLiquidity memory prevLiquidity = data.liquidity;
            effectiveAverageRates = _effectiveAverageRates(
                data.averageRates,
                Fraction({ n: prevLiquidity.bntTradingLiquidity, d: prevLiquidity.baseTokenTradingLiquidity })
            );
        }

        // calculate the pool token amount to mint
        uint256 poolTokenAmount = _underlyingToPoolToken(
            baseTokenAmount,
            prevPoolTokenTotalSupply,
            currentStakedBalance
        );

        // update the staked balance with the full base token amount
        data.liquidity.stakedBalance = currentStakedBalance + baseTokenAmount;

        // mint pool tokens to the provider
        data.poolToken.mint(provider, poolTokenAmount);

        // should be triggered before the trading liquidity is updated
        emit TokensDeposited({
            contextId: contextId,
            provider: provider,
            token: pool,
            baseTokenAmount: baseTokenAmount,
            poolTokenAmount: poolTokenAmount
        });

        emit TotalLiquidityUpdated({
            contextId: contextId,
            pool: pool,
            liquidity: pool.balanceOf(address(_masterVault)),
            stakedBalance: data.liquidity.stakedBalance,
            poolTokenSupply: prevPoolTokenTotalSupply + poolTokenAmount
        });

        // adjust the trading liquidity based on the base token vault balance and funding limits
        _updateTradingLiquidity(
            contextId,
            pool,
            data,
            effectiveAverageRates.rate.fromFraction112(),
            _networkSettings.minLiquidityForTrading()
        );

        // if trading is enabled, then update the recent average rates
        if (data.tradingEnabled) {
            PoolLiquidity memory liquidity = data.liquidity;
            _updateAverageRates(
                data,
                Fraction({ n: liquidity.bntTradingLiquidity, d: liquidity.baseTokenTradingLiquidity })
            );
        }

        return poolTokenAmount;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function withdraw(
        bytes32 contextId,
        address provider,
        Token pool,
        uint256 poolTokenAmount,
        uint256 baseTokenAmount
    )
        external
        only(address(_network))
        validAddress(provider)
        greaterThanZero(poolTokenAmount)
        greaterThanZero(baseTokenAmount)
        returns (uint256)
    {
        Pool storage data = _poolStorage(pool);
        PoolLiquidity memory liquidity = data.liquidity;

        uint256 poolTokenTotalSupply = data.poolToken.totalSupply();
        uint256 underlyingAmount = _poolTokenToUnderlying(
            poolTokenAmount,
            poolTokenTotalSupply,
            liquidity.stakedBalance
        );

        if (baseTokenAmount > underlyingAmount) {
            revert InvalidParam();
        }

        if (_poolRateState(data) == PoolRateState.Unstable) {
            revert RateUnstable();
        }

        // obtain the withdrawal amounts
        InternalWithdrawalAmounts memory amounts = _poolWithdrawalAmounts(
            pool,
            poolTokenAmount,
            baseTokenAmount,
            liquidity,
            data.tradingFeePPM,
            poolTokenTotalSupply
        );

        // execute the actual withdrawal
        _executeWithdrawal(contextId, provider, pool, data, amounts);

        // if trading is enabled, then update the recent average rates
        if (data.tradingEnabled) {
            _updateAverageRates(
                data,
                Fraction({ n: data.liquidity.bntTradingLiquidity, d: data.liquidity.baseTokenTradingLiquidity })
            );
        }

        return amounts.baseTokensToTransferFromMasterVault;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function withdrawalAmounts(Token pool, uint256 poolTokenAmount)
        external
        view
        validAddress(address(pool))
        greaterThanZero(poolTokenAmount)
        returns (WithdrawalAmounts memory)
    {
        Pool storage data = _poolData[pool];
        PoolLiquidity memory liquidity = data.liquidity;

        uint256 poolTokenTotalSupply = data.poolToken.totalSupply();
        uint256 underlyingAmount = _poolTokenToUnderlying(
            poolTokenAmount,
            poolTokenTotalSupply,
            liquidity.stakedBalance
        );

        InternalWithdrawalAmounts memory amounts = _poolWithdrawalAmounts(
            pool,
            poolTokenAmount,
            underlyingAmount,
            liquidity,
            data.tradingFeePPM,
            poolTokenTotalSupply
        );

        return
            WithdrawalAmounts({
                totalAmount: amounts.baseTokensWithdrawalAmount - amounts.baseTokensWithdrawalFee,
                baseTokenAmount: amounts.baseTokensToTransferFromMasterVault + amounts.baseTokensToTransferFromEPV,
                bntAmount: _protectionEnabled ? amounts.bntToMintForProvider : 0
            });
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function tradeBySourceAmount(
        bytes32 contextId,
        Token sourceToken,
        Token targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount
    )
        external
        only(address(_network))
        greaterThanZero(sourceAmount)
        greaterThanZero(minReturnAmount)
        returns (TradeAmountAndFee memory)
    {
        TradeIntermediateResult memory result = _initTrade(
            contextId,
            sourceToken,
            targetToken,
            sourceAmount,
            minReturnAmount,
            true
        );

        _performTrade(result);

        return
            TradeAmountAndFee({
                amount: result.targetAmount,
                tradingFeeAmount: result.tradingFeeAmount,
                networkFeeAmount: result.networkFeeAmount
            });
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function tradeByTargetAmount(
        bytes32 contextId,
        Token sourceToken,
        Token targetToken,
        uint256 targetAmount,
        uint256 maxSourceAmount
    )
        external
        only(address(_network))
        greaterThanZero(targetAmount)
        greaterThanZero(maxSourceAmount)
        returns (TradeAmountAndFee memory)
    {
        TradeIntermediateResult memory result = _initTrade(
            contextId,
            sourceToken,
            targetToken,
            targetAmount,
            maxSourceAmount,
            false
        );

        _performTrade(result);

        return
            TradeAmountAndFee({
                amount: result.sourceAmount,
                tradingFeeAmount: result.tradingFeeAmount,
                networkFeeAmount: result.networkFeeAmount
            });
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function tradeOutputAndFeeBySourceAmount(
        Token sourceToken,
        Token targetToken,
        uint256 sourceAmount
    ) external view greaterThanZero(sourceAmount) returns (TradeAmountAndFee memory) {
        TradeIntermediateResult memory result = _initTrade(bytes32(0), sourceToken, targetToken, sourceAmount, 1, true);

        _processTrade(result);

        return
            TradeAmountAndFee({
                amount: result.targetAmount,
                tradingFeeAmount: result.tradingFeeAmount,
                networkFeeAmount: result.networkFeeAmount
            });
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function tradeInputAndFeeByTargetAmount(
        Token sourceToken,
        Token targetToken,
        uint256 targetAmount
    ) external view greaterThanZero(targetAmount) returns (TradeAmountAndFee memory) {
        TradeIntermediateResult memory result = _initTrade(
            bytes32(0),
            sourceToken,
            targetToken,
            targetAmount,
            type(uint256).max,
            false
        );

        _processTrade(result);

        return
            TradeAmountAndFee({
                amount: result.sourceAmount,
                tradingFeeAmount: result.tradingFeeAmount,
                networkFeeAmount: result.networkFeeAmount
            });
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function onFeesCollected(Token pool, uint256 feeAmount) external only(address(_network)) {
        if (feeAmount == 0) {
            return;
        }

        Pool storage data = _poolStorage(pool);

        // increase the staked balance by the given amount
        data.liquidity.stakedBalance += feeAmount;
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function migratePoolIn(Token pool, Pool calldata data)
        external
        validAddress(address(pool))
        only(address(_poolMigrator))
    {
        _addPool(pool, data);

        data.poolToken.acceptOwnership();
    }

    /**
     * @inheritdoc IPoolCollection
     */
    function migratePoolOut(Token pool, IPoolCollection targetPoolCollection)
        external
        validAddress(address(targetPoolCollection))
        only(address(_poolMigrator))
    {
        IPoolToken cachedPoolToken = _poolData[pool].poolToken;

        _removePool(pool);

        cachedPoolToken.transferOwnership(address(targetPoolCollection));
    }

    /**
     * @dev adds a pool
     */
    function _addPool(Token pool, Pool memory data) private {
        if (!_pools.add(address(pool))) {
            revert AlreadyExists();
        }

        _poolData[pool] = data;
    }

    /**
     * @dev removes a pool
     */
    function _removePool(Token pool) private {
        if (!_pools.remove(address(pool))) {
            revert DoesNotExist();
        }

        delete _poolData[pool];
    }

    /**
     * @dev returns withdrawal amounts
     */
    function _poolWithdrawalAmounts(
        Token pool,
        uint256 poolTokenAmount,
        uint256 baseTokensWithdrawalAmount,
        PoolLiquidity memory liquidity,
        uint32 poolTradingFeePPM,
        uint256 poolTokenTotalSupply
    ) internal view returns (InternalWithdrawalAmounts memory) {
        // the base token trading liquidity of a given pool can never be higher than the base token balance of the vault
        // whenever the base token trading liquidity is updated, it is set to at most the base token balance of the vault
        uint256 baseTokenExcessAmount = pool.balanceOf(address(_masterVault)) - liquidity.baseTokenTradingLiquidity;

        PoolCollectionWithdrawal.Output memory output = PoolCollectionWithdrawal.calculateWithdrawalAmounts(
            liquidity.bntTradingLiquidity,
            liquidity.baseTokenTradingLiquidity,
            baseTokenExcessAmount,
            liquidity.stakedBalance,
            pool.balanceOf(address(_externalProtectionVault)),
            poolTradingFeePPM,
            _networkSettings.withdrawalFeePPM(),
            baseTokensWithdrawalAmount
        );

        return
            InternalWithdrawalAmounts({
                baseTokensToTransferFromMasterVault: output.s,
                bntToMintForProvider: output.t,
                baseTokensToTransferFromEPV: output.u,
                baseTokensTradingLiquidityDelta: output.r,
                bntTradingLiquidityDelta: output.p,
                bntProtocolHoldingsDelta: output.q,
                baseTokensWithdrawalFee: output.v,
                baseTokensWithdrawalAmount: baseTokensWithdrawalAmount,
                poolTokenAmount: poolTokenAmount,
                poolTokenTotalSupply: poolTokenTotalSupply,
                newBaseTokenTradingLiquidity: output.r.isNeg
                    ? liquidity.baseTokenTradingLiquidity - output.r.value
                    : liquidity.baseTokenTradingLiquidity + output.r.value,
                newBNTTradingLiquidity: output.p.isNeg
                    ? liquidity.bntTradingLiquidity - output.p.value
                    : liquidity.bntTradingLiquidity + output.p.value
            });
    }

    /**
     * @dev executes the following actions:
     *
     * - burn the network's base pool tokens
     * - update the pool's base token staked balance
     * - update the pool's base token trading liquidity
     * - update the pool's BNT trading liquidity
     * - update the pool's trading liquidity product
     * - emit an event if the pool's BNT trading liquidity has crossed the minimum threshold
     *   (either above the threshold or below the threshold)
     */
    function _executeWithdrawal(
        bytes32 contextId,
        address provider,
        Token pool,
        Pool storage data,
        InternalWithdrawalAmounts memory amounts
    ) private {
        PoolLiquidity storage liquidity = data.liquidity;
        PoolLiquidity memory prevLiquidity = liquidity;

        data.poolToken.burn(amounts.poolTokenAmount);

        uint256 newPoolTokenTotalSupply = amounts.poolTokenTotalSupply - amounts.poolTokenAmount;
        uint256 newStakedBalance = MathEx.mulDivF(
            liquidity.stakedBalance,
            newPoolTokenTotalSupply,
            amounts.poolTokenTotalSupply
        );

        liquidity.stakedBalance = newStakedBalance;

        // trading liquidity is assumed to never exceed 128 bits (the cast below will revert otherwise)
        liquidity.baseTokenTradingLiquidity = amounts.newBaseTokenTradingLiquidity.toUint128();
        liquidity.bntTradingLiquidity = amounts.newBNTTradingLiquidity.toUint128();

        if (amounts.bntProtocolHoldingsDelta.value > 0) {
            assert(amounts.bntProtocolHoldingsDelta.isNeg); // currently no support for requesting funding here

            _bntPool.renounceFunding(contextId, pool, amounts.bntProtocolHoldingsDelta.value);
        } else if (amounts.bntTradingLiquidityDelta.value > 0) {
            if (amounts.bntTradingLiquidityDelta.isNeg) {
                _bntPool.burnFromVault(amounts.bntTradingLiquidityDelta.value);
            } else {
                _bntPool.mint(address(_masterVault), amounts.bntTradingLiquidityDelta.value);
            }
        }

        // if the provider should receive some BNT - ask the BNT pool to mint BNT to the provider
        bool isProtectionEnabled = _protectionEnabled;
        if (amounts.bntToMintForProvider > 0 && isProtectionEnabled) {
            _bntPool.mint(address(provider), amounts.bntToMintForProvider);
        }

        // if the provider should receive some base tokens from the external protection vault - remove the tokens from
        // the external protection vault and send them to the master vault
        if (amounts.baseTokensToTransferFromEPV > 0) {
            _externalProtectionVault.withdrawFunds(
                pool,
                payable(address(_masterVault)),
                amounts.baseTokensToTransferFromEPV
            );
            amounts.baseTokensToTransferFromMasterVault += amounts.baseTokensToTransferFromEPV;
        }

        // if the provider should receive some base tokens from the master vault - remove the tokens from the master
        // vault and send them to the provider
        if (amounts.baseTokensToTransferFromMasterVault > 0) {
            _masterVault.withdrawFunds(pool, payable(provider), amounts.baseTokensToTransferFromMasterVault);
        }

        // ensure that the average rate is reset when the pool is being emptied
        if (amounts.newBaseTokenTradingLiquidity == 0) {
            data.averageRates.rate = zeroFraction112();
            data.averageRates.invRate = zeroFraction112();
        }

        // if the new BNT trading liquidity is below the minimum liquidity for trading - reset the liquidity
        if (amounts.newBNTTradingLiquidity < _networkSettings.minLiquidityForTrading()) {
            _resetTradingLiquidity(
                contextId,
                pool,
                data,
                prevLiquidity,
                amounts.newBNTTradingLiquidity,
                TRADING_STATUS_UPDATE_MIN_LIQUIDITY
            );
        } else {
            _dispatchTradingLiquidityEvents(contextId, pool, prevLiquidity, liquidity);
        }

        emit TokensWithdrawn({
            contextId: contextId,
            provider: provider,
            token: pool,
            baseTokenAmount: amounts.baseTokensToTransferFromMasterVault,
            poolTokenAmount: amounts.poolTokenAmount,
            externalProtectionBaseTokenAmount: amounts.baseTokensToTransferFromEPV,
            bntAmount: isProtectionEnabled ? amounts.bntToMintForProvider : 0,
            withdrawalFeeAmount: amounts.baseTokensWithdrawalFee
        });

        emit TotalLiquidityUpdated({
            contextId: contextId,
            pool: pool,
            liquidity: pool.balanceOf(address(_masterVault)),
            stakedBalance: newStakedBalance,
            poolTokenSupply: newPoolTokenTotalSupply
        });
    }

    /**
     * @dev sets the default trading fee (in units of PPM)
     */
    function _setDefaultTradingFeePPM(uint32 newDefaultTradingFeePPM) private {
        uint32 prevDefaultTradingFeePPM = _defaultTradingFeePPM;
        if (prevDefaultTradingFeePPM == newDefaultTradingFeePPM) {
            return;
        }

        _defaultTradingFeePPM = newDefaultTradingFeePPM;

        emit DefaultTradingFeePPMUpdated({ prevFeePPM: prevDefaultTradingFeePPM, newFeePPM: newDefaultTradingFeePPM });
    }

    /**
     * @dev sets the network fee (in units of PPM)
     */
    function _setNetworkFeePPM(uint32 newNetworkFeePPM) private {
        uint32 prevNetworkFeePPM = _networkFeePPM;
        if (prevNetworkFeePPM == newNetworkFeePPM) {
            return;
        }

        _networkFeePPM = newNetworkFeePPM;

        emit NetworkFeePPMUpdated({ prevFeePPM: prevNetworkFeePPM, newFeePPM: newNetworkFeePPM });
    }

    /**
     * @dev returns a storage reference to pool data
     */
    function _poolStorage(Token pool) private view returns (Pool storage) {
        Pool storage data = _poolData[pool];
        if (address(data.poolToken) == address(0)) {
            revert DoesNotExist();
        }

        return data;
    }

    /**
     * @dev calculates base tokens amount
     */
    function _poolTokenToUnderlying(
        uint256 poolTokenAmount,
        uint256 poolTokenSupply,
        uint256 stakedBalance
    ) private pure returns (uint256) {
        if (poolTokenSupply == 0) {
            // if this is the initial liquidity provision - use a one-to-one pool token to base token rate
            if (stakedBalance > 0) {
                revert InvalidStakedBalance();
            }

            return poolTokenAmount;
        }

        return MathEx.mulDivF(poolTokenAmount, stakedBalance, poolTokenSupply);
    }

    /**
     * @dev calculates pool tokens amount
     */
    function _underlyingToPoolToken(
        uint256 baseTokenAmount,
        uint256 poolTokenSupply,
        uint256 stakedBalance
    ) private pure returns (uint256) {
        if (poolTokenSupply == 0) {
            // if this is the initial liquidity provision - use a one-to-one pool token to base token rate
            if (stakedBalance > 0) {
                revert InvalidStakedBalance();
            }

            return baseTokenAmount;
        }

        return MathEx.mulDivC(baseTokenAmount, poolTokenSupply, stakedBalance);
    }

    /**
     * @dev calculates the target trading liquidities, taking into account the total out-of-curve base token liquidity,
     * and the deltas between the new and the previous states
     */
    function _calcTargetTradingLiquidity(
        uint256 baseTokenTotalLiquidity,
        uint256 fundingLimit,
        uint256 currentFunding,
        PoolLiquidity memory liquidity,
        Fraction memory fundingRate,
        uint256 minLiquidityForTrading
    ) private pure returns (TargetTradingLiquidity memory) {
        // calculate the target BNT trading liquidity based on the following:
        // - BNT liquidity required to match the based token unused (off-curve) liquidity
        // - BNT funding limit
        // - current BNT funding
        uint256 targetBNTTradingLiquidity = liquidity.bntTradingLiquidity;
        if (fundingLimit > currentFunding) {
            // increase the trading liquidity
            uint256 availableFunding = fundingLimit - currentFunding;
            uint256 baseTokenUnusedLiquidity = baseTokenTotalLiquidity - liquidity.baseTokenTradingLiquidity;
            uint256 targetBNTTradingLiquidityDelta = Math.min(
                MathEx.mulDivF(baseTokenUnusedLiquidity, fundingRate.n, fundingRate.d),
                availableFunding
            );
            targetBNTTradingLiquidity = liquidity.bntTradingLiquidity + targetBNTTradingLiquidityDelta;
        } else if (fundingLimit < currentFunding) {
            // decrease the trading liquidity
            uint256 excessFunding = currentFunding - fundingLimit;
            targetBNTTradingLiquidity = MathEx.subMax0(liquidity.bntTradingLiquidity, excessFunding);
        }

        // if the target is equal to the current trading liquidity, no update is needed
        if (targetBNTTradingLiquidity == liquidity.bntTradingLiquidity) {
            return TargetTradingLiquidity({ update: false, bnt: 0, baseToken: 0 });
        }

        // ensure that the target is above the minimum liquidity for trading
        if (targetBNTTradingLiquidity < minLiquidityForTrading) {
            return TargetTradingLiquidity({ update: true, bnt: 0, baseToken: 0 });
        }

        // calculate the target base token trading liquidity using the following:
        // - calculate the delta between the current/target BNT trading liquidity
        // - calculate the base token trading liquidity delta based on the BNT trading liquidity delta and the funding rate
        // - apply the base token trading liquidity delta to the current base token trading liquidity
        //
        // note that the effective funding rate is always the rate between BNT and the base token)
        uint256 bntTradingLiquidityDelta;
        uint256 baseTokenTradingLiquidityDelta;

        // liquidity increase
        // note that liquidity increase is capped
        if (targetBNTTradingLiquidity > liquidity.bntTradingLiquidity) {
            uint256 tradingLiquidityCap;
            if (liquidity.bntTradingLiquidity == 0) {
                // the current BNT trading liquidity is 0 - cap the target trading liquidity
                // by the default bootstrap amount, which includes a buffer to reduce the chance
                // for trading to be disabled as a result of trades in the pool
                tradingLiquidityCap = minLiquidityForTrading * BOOTSTRAPPING_LIQUIDITY_BUFFER_FACTOR;
            } else {
                // the current BNT trading liquidity is not 0 - cap the target using the growth factor
                tradingLiquidityCap = liquidity.bntTradingLiquidity * LIQUIDITY_GROWTH_FACTOR;
            }

            // apply the trading liquidity cap
            targetBNTTradingLiquidity = Math.min(targetBNTTradingLiquidity, tradingLiquidityCap);

            // calculate the trading liquidity deltas and return them
            bntTradingLiquidityDelta = targetBNTTradingLiquidity - liquidity.bntTradingLiquidity;
            baseTokenTradingLiquidityDelta = MathEx.mulDivF(bntTradingLiquidityDelta, fundingRate.d, fundingRate.n);

            return
                TargetTradingLiquidity({
                    update: true,
                    bnt: targetBNTTradingLiquidity,
                    baseToken: liquidity.baseTokenTradingLiquidity + baseTokenTradingLiquidityDelta
                });
        }

        // liquidity decrease
        // note that liquidity decrease isn't capped
        // calculate the trading liquidity deltas and return them
        bntTradingLiquidityDelta = liquidity.bntTradingLiquidity - targetBNTTradingLiquidity;
        baseTokenTradingLiquidityDelta = MathEx.mulDivF(bntTradingLiquidityDelta, fundingRate.d, fundingRate.n);

        return
            TargetTradingLiquidity({
                update: true,
                bnt: targetBNTTradingLiquidity,
                baseToken: MathEx.subMax0(liquidity.baseTokenTradingLiquidity, baseTokenTradingLiquidityDelta)
            });
    }

    /**
     * @dev adjusts the trading liquidity based on the newly added tokens delta amount, and funding limits
     */
    function _updateTradingLiquidity(
        bytes32 contextId,
        Token pool,
        Pool storage data,
        Fraction memory fundingRate,
        uint256 minLiquidityForTrading
    ) private {
        // ensure that the base token reserve isn't empty
        uint256 baseTokenTotalLiquidity = pool.balanceOf(address(_masterVault));
        if (baseTokenTotalLiquidity == 0) {
            revert InsufficientLiquidity();
        }

        if (_poolRateState(data) == PoolRateState.Unstable) {
            return;
        }

        PoolLiquidity memory prevLiquidity = data.liquidity;
        if (!fundingRate.isPositive()) {
            _resetTradingLiquidity(contextId, pool, data, prevLiquidity, TRADING_STATUS_UPDATE_MIN_LIQUIDITY);
            return;
        }

        TargetTradingLiquidity memory targetTradingLiquidity = _calcTargetTradingLiquidity(
            baseTokenTotalLiquidity,
            _networkSettings.poolFundingLimit(pool),
            _bntPool.currentPoolFunding(pool),
            prevLiquidity,
            fundingRate,
            minLiquidityForTrading
        );

        if (!targetTradingLiquidity.update) {
            return;
        }

        if (targetTradingLiquidity.bnt == 0 || targetTradingLiquidity.baseToken == 0) {
            _resetTradingLiquidity(contextId, pool, data, prevLiquidity, TRADING_STATUS_UPDATE_MIN_LIQUIDITY);
            return;
        }

        // update funding from the BNT pool
        if (targetTradingLiquidity.bnt > prevLiquidity.bntTradingLiquidity) {
            _bntPool.requestFunding(contextId, pool, targetTradingLiquidity.bnt - prevLiquidity.bntTradingLiquidity);
        } else if (targetTradingLiquidity.bnt < prevLiquidity.bntTradingLiquidity) {
            _bntPool.renounceFunding(contextId, pool, prevLiquidity.bntTradingLiquidity - targetTradingLiquidity.bnt);
        }

        // trading liquidity is assumed to never exceed 128 bits (the cast below will revert otherwise)
        PoolLiquidity memory newLiquidity = PoolLiquidity({
            bntTradingLiquidity: targetTradingLiquidity.bnt.toUint128(),
            baseTokenTradingLiquidity: targetTradingLiquidity.baseToken.toUint128(),
            stakedBalance: prevLiquidity.stakedBalance
        });

        // update the liquidity data of the pool
        data.liquidity = newLiquidity;

        _dispatchTradingLiquidityEvents(contextId, pool, prevLiquidity, newLiquidity);
    }

    function _dispatchTradingLiquidityEvents(
        bytes32 contextId,
        Token pool,
        PoolLiquidity memory prevLiquidity,
        PoolLiquidity memory newLiquidity
    ) private {
        if (newLiquidity.bntTradingLiquidity != prevLiquidity.bntTradingLiquidity) {
            emit TradingLiquidityUpdated({
                contextId: contextId,
                pool: pool,
                token: Token(address(_bnt)),
                prevLiquidity: prevLiquidity.bntTradingLiquidity,
                newLiquidity: newLiquidity.bntTradingLiquidity
            });
        }

        if (newLiquidity.baseTokenTradingLiquidity != prevLiquidity.baseTokenTradingLiquidity) {
            emit TradingLiquidityUpdated({
                contextId: contextId,
                pool: pool,
                token: pool,
                prevLiquidity: prevLiquidity.baseTokenTradingLiquidity,
                newLiquidity: newLiquidity.baseTokenTradingLiquidity
            });
        }
    }

    /**
     * @dev resets trading liquidity and renounces any remaining BNT funding
     */
    function _resetTradingLiquidity(
        bytes32 contextId,
        Token pool,
        Pool storage data,
        PoolLiquidity memory prevLiquidity,
        uint8 reason
    ) private {
        _resetTradingLiquidity(contextId, pool, data, prevLiquidity, data.liquidity.bntTradingLiquidity, reason);
    }

    /**
     * @dev resets trading liquidity and renounces any remaining BNT funding
     */
    function _resetTradingLiquidity(
        bytes32 contextId,
        Token pool,
        Pool storage data,
        PoolLiquidity memory prevLiquidity,
        uint256 currentBNTTradingLiquidity,
        uint8 reason
    ) private {
        // reset the network and base token trading liquidities
        data.liquidity.bntTradingLiquidity = 0;
        data.liquidity.baseTokenTradingLiquidity = 0;

        // reset the recent average rage
        data.averageRates = AverageRates({ blockNumber: 0, rate: zeroFraction112(), invRate: zeroFraction112() });

        // ensure that trading is disabled
        if (data.tradingEnabled) {
            data.tradingEnabled = false;

            emit TradingEnabled({ pool: pool, newStatus: false, reason: reason });
        }

        // renounce all network liquidity
        if (currentBNTTradingLiquidity > 0) {
            _bntPool.renounceFunding(contextId, pool, currentBNTTradingLiquidity);
        }

        _dispatchTradingLiquidityEvents(contextId, pool, prevLiquidity, data.liquidity);
    }

    /**
     * @dev returns initial trading params
     */
    function _initTrade(
        bytes32 contextId,
        Token sourceToken,
        Token targetToken,
        uint256 amount,
        uint256 limit,
        bool bySourceAmount
    ) private view returns (TradeIntermediateResult memory result) {
        // ensure that BNT is either the source or the target token
        bool isSourceBNT = sourceToken.isEqual(_bnt);
        bool isTargetBNT = targetToken.isEqual(_bnt);

        if (isSourceBNT && !isTargetBNT) {
            result.isSourceBNT = true;
            result.pool = targetToken;
        } else if (!isSourceBNT && isTargetBNT) {
            result.isSourceBNT = false;
            result.pool = sourceToken;
        } else {
            // BNT isn't one of the tokens or is both of them
            revert DoesNotExist();
        }

        Pool storage data = _poolStorage(result.pool);

        // verify that trading is enabled
        if (!data.tradingEnabled) {
            revert TradingDisabled();
        }

        result.contextId = contextId;
        result.bySourceAmount = bySourceAmount;

        if (result.bySourceAmount) {
            result.sourceAmount = amount;
        } else {
            result.targetAmount = amount;
        }

        result.limit = limit;
        result.tradingFeePPM = data.tradingFeePPM;

        PoolLiquidity memory liquidity = data.liquidity;
        if (result.isSourceBNT) {
            result.sourceBalance = liquidity.bntTradingLiquidity;
            result.targetBalance = liquidity.baseTokenTradingLiquidity;
        } else {
            result.sourceBalance = liquidity.baseTokenTradingLiquidity;
            result.targetBalance = liquidity.bntTradingLiquidity;
        }

        result.stakedBalance = liquidity.stakedBalance;
    }

    /**
     * @dev returns trade amount and fee by providing the source amount
     */
    function _tradeAmountAndFeeBySourceAmount(
        uint256 sourceBalance,
        uint256 targetBalance,
        uint32 feePPM,
        uint256 sourceAmount
    ) private pure returns (TradeAmountAndTradingFee memory) {
        if (sourceBalance == 0 || targetBalance == 0) {
            revert InsufficientLiquidity();
        }

        uint256 targetAmount = MathEx.mulDivF(targetBalance, sourceAmount, sourceBalance + sourceAmount);
        uint256 tradingFeeAmount = MathEx.mulDivF(targetAmount, feePPM, PPM_RESOLUTION);

        return
            TradeAmountAndTradingFee({ amount: targetAmount - tradingFeeAmount, tradingFeeAmount: tradingFeeAmount });
    }

    /**
     * @dev returns trade amount and fee by providing either the target amount
     */
    function _tradeAmountAndFeeByTargetAmount(
        uint256 sourceBalance,
        uint256 targetBalance,
        uint32 feePPM,
        uint256 targetAmount
    ) private pure returns (TradeAmountAndTradingFee memory) {
        if (sourceBalance == 0) {
            revert InsufficientLiquidity();
        }

        uint256 tradingFeeAmount = MathEx.mulDivF(targetAmount, feePPM, PPM_RESOLUTION - feePPM);
        uint256 fullTargetAmount = targetAmount + tradingFeeAmount;
        uint256 sourceAmount = MathEx.mulDivF(sourceBalance, fullTargetAmount, targetBalance - fullTargetAmount);

        return TradeAmountAndTradingFee({ amount: sourceAmount, tradingFeeAmount: tradingFeeAmount });
    }

    /**
     * @dev processes a trade by providing either the source or the target amount and updates the in-memory intermediate
     * result
     */
    function _processTrade(TradeIntermediateResult memory result) private view {
        TradeAmountAndTradingFee memory tradeAmountAndFee;

        if (result.bySourceAmount) {
            tradeAmountAndFee = _tradeAmountAndFeeBySourceAmount(
                result.sourceBalance,
                result.targetBalance,
                result.tradingFeePPM,
                result.sourceAmount
            );

            result.targetAmount = tradeAmountAndFee.amount;

            // ensure that the target amount is above the requested minimum return amount
            if (result.targetAmount < result.limit) {
                revert InsufficientTargetAmount();
            }
        } else {
            tradeAmountAndFee = _tradeAmountAndFeeByTargetAmount(
                result.sourceBalance,
                result.targetBalance,
                result.tradingFeePPM,
                result.targetAmount
            );

            result.sourceAmount = tradeAmountAndFee.amount;

            // ensure that the user has provided enough tokens to make the trade
            if (result.sourceAmount == 0 || result.sourceAmount > result.limit) {
                revert InsufficientSourceAmount();
            }
        }

        result.tradingFeeAmount = tradeAmountAndFee.tradingFeeAmount;

        // sync the trading and staked balance
        result.sourceBalance += result.sourceAmount;
        result.targetBalance -= result.targetAmount;

        if (result.isSourceBNT) {
            result.stakedBalance += result.tradingFeeAmount;
        }

        _processNetworkFee(result);
    }

    /**
     * @dev processes the network fee and updates the in-memory intermediate result
     */
    function _processNetworkFee(TradeIntermediateResult memory result) private view {
        if (_networkFeePPM == 0) {
            return;
        }

        // calculate the target network fee amount
        uint256 targetNetworkFeeAmount = MathEx.mulDivF(result.tradingFeeAmount, _networkFeePPM, PPM_RESOLUTION);

        // update the target balance (but don't deduct it from the full trading fee amount)
        result.targetBalance -= targetNetworkFeeAmount;

        if (!result.isSourceBNT) {
            result.networkFeeAmount = targetNetworkFeeAmount;

            return;
        }

        // trade the network fee (taken from the base token) to BNT
        result.networkFeeAmount = _tradeAmountAndFeeBySourceAmount(
            result.targetBalance,
            result.sourceBalance,
            0,
            targetNetworkFeeAmount
        ).amount;

        // since we have received the network fee in base tokens and have traded them for BNT (so that the network fee
        // is always kept in BNT), we'd need to adapt the trading liquidity and the staked balance accordingly
        result.targetBalance += targetNetworkFeeAmount;
        result.sourceBalance -= result.networkFeeAmount;
        result.stakedBalance -= targetNetworkFeeAmount;
    }

    /**
     * @dev performs a trade
     */
    function _performTrade(TradeIntermediateResult memory result) private {
        Pool storage data = _poolData[result.pool];
        PoolLiquidity memory prevLiquidity = data.liquidity;

        // update the recent average rate
        _updateAverageRates(
            data,
            Fraction({ n: prevLiquidity.bntTradingLiquidity, d: prevLiquidity.baseTokenTradingLiquidity })
        );

        _processTrade(result);

        // trading liquidity is assumed to never exceed 128 bits (the cast below will revert otherwise)
        PoolLiquidity memory newLiquidity = PoolLiquidity({
            bntTradingLiquidity: (result.isSourceBNT ? result.sourceBalance : result.targetBalance).toUint128(),
            baseTokenTradingLiquidity: (result.isSourceBNT ? result.targetBalance : result.sourceBalance).toUint128(),
            stakedBalance: result.stakedBalance
        });

        _dispatchTradingLiquidityEvents(result.contextId, result.pool, prevLiquidity, newLiquidity);

        // update the liquidity data of the pool
        data.liquidity = newLiquidity;
    }

    /**
     * @dev returns the state of a pool's rate
     */
    function _poolRateState(Pool storage data) internal view returns (PoolRateState) {
        Fraction memory spotRate = Fraction({
            n: data.liquidity.bntTradingLiquidity,
            d: data.liquidity.baseTokenTradingLiquidity
        });

        AverageRates memory averageRates = data.averageRates;
        Fraction112 memory rate = averageRates.rate;
        if (!spotRate.isPositive() || !rate.isPositive()) {
            return PoolRateState.Uninitialized;
        }

        Fraction memory invSpotRate = spotRate.inverse();
        Fraction112 memory invRate = averageRates.invRate;
        if (!invSpotRate.isPositive() || !invRate.isPositive()) {
            return PoolRateState.Uninitialized;
        }

        AverageRates memory effectiveAverageRates = _effectiveAverageRates(averageRates, spotRate);

        if (
            MathEx.isInRange(effectiveAverageRates.rate.fromFraction112(), spotRate, RATE_MAX_DEVIATION_PPM) &&
            MathEx.isInRange(effectiveAverageRates.invRate.fromFraction112(), invSpotRate, RATE_MAX_DEVIATION_PPM)
        ) {
            return PoolRateState.Stable;
        }

        return PoolRateState.Unstable;
    }

    /**
     * @dev updates the average rates
     */
    function _updateAverageRates(Pool storage data, Fraction memory spotRate) private {
        data.averageRates = _effectiveAverageRates(data.averageRates, spotRate);
    }

    /**
     * @dev returns the effective average rates
     */
    function _effectiveAverageRates(AverageRates memory averageRates, Fraction memory spotRate)
        private
        view
        returns (AverageRates memory)
    {
        // if the spot rate is 0, reset the average rates
        if (!spotRate.isPositive()) {
            return AverageRates({ blockNumber: 0, rate: zeroFraction112(), invRate: zeroFraction112() });
        }

        uint32 blockNumber = _blockNumber();

        // can only be updated once in a single block
        uint32 prevUpdateBlock = averageRates.blockNumber;
        if (prevUpdateBlock == blockNumber) {
            return averageRates;
        }

        // if sufficient blocks have passed, or if one of the rates isn't positive,
        // reset the average rates
        if (
            blockNumber - prevUpdateBlock >= RATE_RESET_BLOCK_THRESHOLD ||
            !averageRates.rate.isPositive() ||
            !averageRates.invRate.isPositive()
        ) {
            if (spotRate.isPositive()) {
                return
                    AverageRates({
                        blockNumber: blockNumber,
                        rate: spotRate.toFraction112(),
                        invRate: spotRate.inverse().toFraction112()
                    });
            }

            return AverageRates({ blockNumber: 0, rate: zeroFraction112(), invRate: zeroFraction112() });
        }

        return
            AverageRates({
                blockNumber: blockNumber,
                rate: _calcAverageRate(averageRates.rate, spotRate),
                invRate: _calcAverageRate(averageRates.invRate, spotRate.inverse())
            });
    }

    /**
     * @dev calculates the average rate
     */
    function _calcAverageRate(Fraction112 memory averageRate, Fraction memory rate)
        private
        pure
        returns (Fraction112 memory)
    {
        if (rate.n * averageRate.d == rate.d * averageRate.n) {
            return averageRate;
        }

        return
            MathEx
                .weightedAverage(averageRate.fromFraction112(), rate, EMA_AVERAGE_RATE_WEIGHT, EMA_SPOT_RATE_WEIGHT)
                .toFraction112();
    }

    /**
     * @dev verifies if the provided rate is valid
     */
    function _validRate(Fraction memory rate) internal pure {
        if (!rate.isPositive()) {
            revert InvalidRate();
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { PPM_RESOLUTION as M } from "../utility/Constants.sol";
import { Sint256, Uint512, MathEx } from "../utility/MathEx.sol";

error PoolCollectionWithdrawalInputInvalid();

/**
 * @dev This library implements the mathematics behind base-token withdrawal.
 * It exposes a single function which takes the following input values:
 * `a` - BNT trading liquidity
 * `b` - base token trading liquidity
 * `c` - base token excess amount
 * `e` - base token staked amount
 * `w` - base token external protection vault balance
 * `m` - trading fee in PPM units
 * `n` - withdrawal fee in PPM units
 * `x` - base token withdrawal amount
 * And returns the following output values:
 * `p` - BNT amount to add to the trading liquidity and to the master vault
 * `q` - BNT amount to add to the protocol equity
 * `r` - base token amount to add to the trading liquidity
 * `s` - base token amount to transfer from the master vault to the provider
 * `t` - BNT amount to mint directly for the provider
 * `u` - base token amount to transfer from the external protection vault to the provider
 * `v` - base token amount to keep in the pool as a withdrawal fee
 * The following table depicts the actual formulae based on the current state of the system:
 * +-----------+---------------------------------------------------------+----------------------------------------------------------+
 * |           |                         Deficit                         |                       Surplus                            |
 * +-----------+---------------------------------------------------------+----------------------------------------------------------+
 * |           | p = a*x*(e*(1-n)-b-c)*(1-m)/(b*e-x*(e*(1-n)-b-c)*(1-m)) | p = -a*x*(b+c-e*(1-n))/(b*e*(1-m)+x*(b+c-e*(1-n))*(1-m)) |
 * |           | q = 0                                                   | q = 0                                                    |
 * |           | r = -x*(e*(1-n)-b-c)/e                                  | r = x*(b+c-e*(1-n))/e                                    |
 * | Arbitrage | s = x*(1-n)                                             | s = x*(1-n)                                              |
 * |           | t = 0                                                   | t = 0                                                    |
 * |           | u = 0                                                   | u = 0                                                    |
 * |           | v = x*n                                                 | v = x*n                                                  |
 * +-----------+---------------------------------------------------------+----------------------------------------------------------+
 * |           | p = -a*z/(b*e) where z = max(x*(1-n)*b-c*(e-x*(1-n)),0) | p = -a*z/b where z = max(x*(1-n)-c,0)                    |
 * |           | q = -a*z/(b*e) where z = max(x*(1-n)*b-c*(e-x*(1-n)),0) | q = -a*z/b where z = max(x*(1-n)-c,0)                    |
 * |           | r = -z/e       where z = max(x*(1-n)*b-c*(e-x*(1-n)),0) | r = -z     where z = max(x*(1-n)-c,0)                    |
 * | Default   | s = x*(1-n)*(b+c)/e                                     | s = x*(1-n)                                              |
 * |           | t = see function `externalProtection`                   | t = 0                                                    |
 * |           | u = see function `externalProtection`                   | u = 0                                                    |
 * |           | v = x*n                                                 | v = x*n                                                  |
 * +-----------+---------------------------------------------------------+----------------------------------------------------------+
 * |           | p = 0                                                   | p = 0                                                    |
 * |           | q = 0                                                   | q = 0                                                    |
 * |           | r = 0                                                   | r = 0                                                    |
 * | Bootstrap | s = x*(1-n)*c/e                                         | s = x*(1-n)                                              |
 * |           | t = see function `externalProtection`                   | t = 0                                                    |
 * |           | u = see function `externalProtection`                   | u = 0                                                    |
 * |           | v = x*n                                                 | v = x*n                                                  |
 * +-----------+---------------------------------------------------------+----------------------------------------------------------+
 * Note that for the sake of illustration, both `m` and `n` are assumed normalized (between 0 and 1).
 * During runtime, it is taken into account that they are given in PPM units (between 0 and 1000000).
 */
library PoolCollectionWithdrawal {
    using MathEx for uint256;

    struct Output {
        Sint256 p;
        Sint256 q;
        Sint256 r;
        uint256 s;
        uint256 t;
        uint256 u;
        uint256 v;
    }

    /**
     * @dev returns `p`, `q`, `r`, `s`, `t`, `u` and `v` according to the current state:
     * +-------------------+-----------------------------------------------------------+
     * | `e > (b+c)/(1-n)` | bootstrap deficit or default deficit or arbitrage deficit |
     * +-------------------+-----------------------------------------------------------+
     * | `e < (b+c)`       | bootstrap surplus or default surplus or arbitrage surplus |
     * +-------------------+-----------------------------------------------------------+
     * | otherwise         | bootstrap surplus or default surplus                      |
     * +-------------------+-----------------------------------------------------------+
     */
    function calculateWithdrawalAmounts(
        uint256 a, // <= 2**128-1
        uint256 b, // <= 2**128-1
        uint256 c, // <= 2**128-1
        uint256 e, // <= 2**128-1
        uint256 w, // <= 2**128-1
        uint256 m, // <= M == 1000000
        uint256 n, // <= M == 1000000
        uint256 x /// <= e <= 2**128-1
    ) internal pure returns (Output memory output) {
        if (
            a > type(uint128).max ||
            b > type(uint128).max ||
            c > type(uint128).max ||
            e > type(uint128).max ||
            w > type(uint128).max ||
            m > M ||
            n > M ||
            x > e
        ) {
            revert PoolCollectionWithdrawalInputInvalid();
        }

        uint256 y = (x * (M - n)) / M;

        if ((e * (M - n)) / M > b + c) {
            uint256 f = (e * (M - n)) / M - (b + c);
            uint256 g = e - (b + c);
            if (isStable(b, c, e, x) && affordableDeficit(b, e, f, g, m, n, x)) {
                output = arbitrageDeficit(a, b, e, f, m, x, y);
            } else if (a > 0) {
                output = defaultDeficit(a, b, c, e, y);
                (output.t, output.u) = externalProtection(a, b, e, g, y, w);
            } else {
                output.s = (y * c) / e;
                (output.t, output.u) = externalProtection(a, b, e, g, y, w);
            }
        } else {
            uint256 f = MathEx.subMax0(b + c, e);
            if (f > 0 && isStable(b, c, e, x) && affordableSurplus(b, e, f, m, n, x)) {
                output = arbitrageSurplus(a, b, e, f, m, n, x, y);
            } else if (a > 0) {
                output = defaultSurplus(a, b, c, y);
            } else {
                output.s = y;
            }
        }

        output.v = x - y;
    }

    /**
     * @dev returns `x < e*c/(b+c)`
     */
    function isStable(
        uint256 b, // <= 2**128-1
        uint256 c, // <= 2**128-1
        uint256 e, // <= 2**128-1
        uint256 x /// <= e <= 2**128-1
    ) private pure returns (bool) {
        return b * x < c * (e - x);
    }

    /**
     * @dev returns `b*e*((e*(1-n)-b-c)*m+e*n) > (e*(1-n)-b-c)*x*(e-b-c)*(1-m)`
     */
    function affordableDeficit(
        uint256, /*b*/ // <= 2**128-1
        uint256, /*e*/ // <= 2**128-1
        uint256, /*f*/ // == e*(1-n)-b-c <= e <= 2**128-1
        uint256, /*g*/ // == e-b-c <= e <= 2**128-1
        uint256, /*m*/ // <= M == 1000000
        uint256, /*n*/ // <= M == 1000000
        uint256 /*x*/ /// <  e*c/(b+c) <= e <= 2**128-1
    ) private pure returns (bool) {
        // temporarily disabled
        //Uint512 memory lhs = MathEx.mul512(b * e, f * m + e * n);
        //Uint512 memory rhs = MathEx.mul512(f * x, g * (M - m));
        //return MathEx.gt512(lhs, rhs);
        return false;
    }

    /**
     * @dev returns `b*e*((b+c-e)*m+e*n) > (b+c-e)*x*(b+c-e*(1-n))*(1-m)`
     */
    function affordableSurplus(
        uint256 b, // <= 2**128-1
        uint256 e, // <= 2**128-1
        uint256 f, // == b+c-e <= 2**129-2
        uint256 m, // <= M == 1000000
        uint256 n, // <= M == 1000000
        uint256 x /// <  e*c/(b+c) <= e <= 2**128-1
    ) private pure returns (bool) {
        Uint512 memory lhs = MathEx.mul512(b * e, (f * m + e * n) * M);
        Uint512 memory rhs = MathEx.mul512(f * x, (f * M + e * n) * (M - m));
        return MathEx.gt512(lhs, rhs); // `x < e*c/(b+c)` --> `f*x < e*c*(b+c-e)/(b+c) <= e*c <= 2**256-1`
    }

    /**
     * @dev returns:
     * `p = a*x*(e*(1-n)-b-c)*(1-m)/(b*e-x*(e*(1-n)-b-c)*(1-m))`
     * `q = 0`
     * `r = -x*(e*(1-n)-b-c)/e`
     * `s = x*(1-n)`
     */
    function arbitrageDeficit(
        uint256 a, // <= 2**128-1
        uint256 b, // <= 2**128-1
        uint256 e, // <= 2**128-1
        uint256 f, // == e*(1-n)-b-c <= e <= 2**128-1
        uint256 m, // <= M == 1000000
        uint256 x, // <= e <= 2**128-1
        uint256 y /// == x*(1-n) <= x <= e <= 2**128-1
    ) private pure returns (Output memory output) {
        uint256 i = f * (M - m);
        uint256 j = mulSubMulDivF(b, e * M, x, i, 1);
        output.p = MathEx.mulDivF(a * x, i, j).toPos256();
        output.r = MathEx.mulDivF(x, f, e).toNeg256();
        output.s = y;
    }

    /**
     * @dev returns:
     * `p = -a*x*(b+c-e*(1-n))/(b*e*(1-m)+x*(b+c-e*(1-n))*(1-m))`
     * `q = 0`
     * `r = x*(b+c-e*(1-n))/e`
     * `s = x*(1-n)`
     */
    function arbitrageSurplus(
        uint256 a, // <= 2**128-1
        uint256 b, // <= 2**128-1
        uint256 e, // <= 2**128-1
        uint256 f, // == b+c-e <= 2**129-2
        uint256 m, // <= M == 1000000
        uint256 n, // <= M == 1000000
        uint256 x, // <= e <= 2**128-1
        uint256 y /// == x*(1-n) <= x <= e <= 2**128-1
    ) private pure returns (Output memory output) {
        uint256 i = f * M + e * n;
        uint256 j = mulAddMulDivF(b, e * (M - m), x, i * (M - m), M);
        output.p = MathEx.mulDivF(a * x, i, j).toNeg256();
        output.r = MathEx.mulDivF(x, i, e * M).toPos256();
        output.s = y;
    }

    /**
     * @dev returns:
     * `p = -a*z/(b*e)` where `z = max(x*(1-n)*b-c*(e-x*(1-n)),0)`
     * `q = -a*z/(b*e)` where `z = max(x*(1-n)*b-c*(e-x*(1-n)),0)`
     * `r = -z/e` where `z = max(x*(1-n)*b-c*(e-x*(1-n)),0)`
     * `s = x*(1-n)*(b+c)/e`
     */
    function defaultDeficit(
        uint256 a, // <= 2**128-1
        uint256 b, // <= 2**128-1
        uint256 c, // <= 2**128-1
        uint256 e, // <= 2**128-1
        uint256 y /// == x*(1-n) <= x <= e <= 2**128-1
    ) private pure returns (Output memory output) {
        uint256 z = MathEx.subMax0(y * b, c * (e - y));
        output.p = MathEx.mulDivF(a, z, b * e).toNeg256();
        output.q = output.p;
        output.r = (z / e).toNeg256();
        output.s = MathEx.mulDivF(y, b + c, e);
    }

    /**
     * @dev returns:
     * `p = -a*z/b` where `z = max(x*(1-n)-c,0)`
     * `q = -a*z/b` where `z = max(x*(1-n)-c,0)`
     * `r = -z` where `z = max(x*(1-n)-c,0)`
     * `s = x*(1-n)`
     */
    function defaultSurplus(
        uint256 a, // <= 2**128-1
        uint256 b, // <= 2**128-1
        uint256 c, // <= 2**128-1
        uint256 y /// == x*(1-n) <= x <= e <= 2**128-1
    ) private pure returns (Output memory output) {
        uint256 z = MathEx.subMax0(y, c);
        output.p = MathEx.mulDivF(a, z, b).toNeg256();
        output.q = output.p;
        output.r = z.toNeg256();
        output.s = y;
    }

    /**
     * @dev returns `t` and `u` according to the current state:
     * +-----------------------+-------+---------------------------+-------------------+
     * | x*(1-n)*(e-b-c)/e > w | a > 0 | t                         | u                 |
     * +-----------------------+-------+---------------------------+-------------------+
     * | true                  | true  | a*(x*(1-n)*(e-b-c)/e-w)/b | w                 |
     * +-----------------------+-------+---------------------------+-------------------+
     * | true                  | false | 0                         | w                 |
     * +-----------------------+-------+---------------------------+-------------------+
     * | false                 | true  | 0                         | x*(1-n)*(e-b-c)/e |
     * +-----------------------+-------+---------------------------+-------------------+
     * | false                 | false | 0                         | x*(1-n)*(e-b-c)/e |
     * +-----------------------+-------+---------------------------+-------------------+
     */
    function externalProtection(
        uint256 a, // <= 2**128-1
        uint256 b, // <= 2**128-1
        uint256 e, // <= 2**128-1
        uint256 g, // == e-b-c <= e <= 2**128-1
        uint256 y, // == x*(1-n) <= x <= e <= 2**128-1
        uint256 w /// <= 2**128-1
    ) private pure returns (uint256 t, uint256 u) {
        uint256 yg = y * g;
        uint256 we = w * e;
        if (yg > we) {
            t = a > 0 ? MathEx.mulDivF(a, yg - we, b * e) : 0;
            u = w;
        } else {
            t = 0;
            u = yg / e;
        }
    }

    /**
     * @dev returns `a*b+x*y/z`
     */
    function mulAddMulDivF(
        uint256 a,
        uint256 b,
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        return a * b + MathEx.mulDivF(x, y, z);
    }

    /**
     * @dev returns `a*b-x*y/z`
     */
    function mulSubMulDivF(
        uint256 a,
        uint256 b,
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        return a * b - MathEx.mulDivF(x, y, z);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IPoolToken } from "./IPoolToken.sol";

import { Token } from "../../token/Token.sol";

import { IVault } from "../../vaults/interfaces/IVault.sol";

// the BNT pool token manager role is required to access the BNT pool tokens
bytes32 constant ROLE_BNT_POOL_TOKEN_MANAGER = keccak256("ROLE_BNT_POOL_TOKEN_MANAGER");

// the BNT manager role is required to request the BNT pool to mint BNT
bytes32 constant ROLE_BNT_MANAGER = keccak256("ROLE_BNT_MANAGER");

// the vault manager role is required to request the BNT pool to burn BNT from the master vault
bytes32 constant ROLE_VAULT_MANAGER = keccak256("ROLE_VAULT_MANAGER");

// the funding manager role is required to request or renounce funding from the BNT pool
bytes32 constant ROLE_FUNDING_MANAGER = keccak256("ROLE_FUNDING_MANAGER");

/**
 * @dev BNT Pool interface
 */
interface IBNTPool is IVault {
    /**
     * @dev returns the BNT pool token contract
     */
    function poolToken() external view returns (IPoolToken);

    /**
     * @dev returns the total staked BNT balance in the network
     */
    function stakedBalance() external view returns (uint256);

    /**
     * @dev returns the current funding of given pool
     */
    function currentPoolFunding(Token pool) external view returns (uint256);

    /**
     * @dev returns the available BNT funding for a given pool
     */
    function availableFunding(Token pool) external view returns (uint256);

    /**
     * @dev converts the specified pool token amount to the underlying BNT amount
     */
    function poolTokenToUnderlying(uint256 poolTokenAmount) external view returns (uint256);

    /**
     * @dev converts the specified underlying BNT amount to pool token amount
     */
    function underlyingToPoolToken(uint256 bntAmount) external view returns (uint256);

    /**
     * @dev returns the number of pool token to burn in order to increase everyone's underlying value by the specified
     * amount
     */
    function poolTokenAmountToBurn(uint256 bntAmountToDistribute) external view returns (uint256);

    /**
     * @dev mints BNT to the recipient
     *
     * requirements:
     *
     * - the caller must have the ROLE_BNT_MANAGER role
     */
    function mint(address recipient, uint256 bntAmount) external;

    /**
     * @dev burns BNT from the vault
     *
     * requirements:
     *
     * - the caller must have the ROLE_VAULT_MANAGER role
     */
    function burnFromVault(uint256 bntAmount) external;

    /**
     * @dev deposits BNT liquidity on behalf of a specific provider and returns the respective pool token amount
     *
     * requirements:
     *
     * - the caller must be the network contract
     * - BNT tokens must have been already deposited into the contract
     */
    function depositFor(
        bytes32 contextId,
        address provider,
        uint256 bntAmount,
        bool isMigrating,
        uint256 originalVBNTAmount
    ) external returns (uint256);

    /**
     * @dev withdraws BNT liquidity on behalf of a specific provider and returns the withdrawn BNT amount
     *
     * requirements:
     *
     * - the caller must be the network contract
     * - bnBNT token must have been already deposited into the contract
     * - vBNT token must have been already deposited into the contract
     */
    function withdraw(
        bytes32 contextId,
        address provider,
        uint256 poolTokenAmount,
        uint256 bntAmount
    ) external returns (uint256);

    /**
     * @dev returns the withdrawn BNT amount
     */
    function withdrawalAmount(uint256 poolTokenAmount) external view returns (uint256);

    /**
     * @dev requests BNT funding
     *
     * requirements:
     *
     * - the caller must have the ROLE_FUNDING_MANAGER role
     * - the token must have been whitelisted
     * - the request amount should be below the funding limit for a given pool
     * - the average rate of the pool must not deviate too much from its spot rate
     */
    function requestFunding(
        bytes32 contextId,
        Token pool,
        uint256 bntAmount
    ) external;

    /**
     * @dev renounces BNT funding
     *
     * requirements:
     *
     * - the caller must have the ROLE_FUNDING_MANAGER role
     * - the token must have been whitelisted
     * - the average rate of the pool must not deviate too much from its spot rate
     */
    function renounceFunding(
        bytes32 contextId,
        Token pool,
        uint256 bntAmount
    ) external;

    /**
     * @dev notifies the pool of accrued fees
     *
     * requirements:
     *
     * - the caller must be the network contract
     */
    function onFeesCollected(
        Token pool,
        uint256 feeAmount,
        bool isTradeFee
    ) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IVersioned } from "../../utility/interfaces/IVersioned.sol";
import { Fraction112 } from "../../utility/FractionLibrary.sol";

import { Token } from "../../token/Token.sol";

import { IPoolToken } from "./IPoolToken.sol";

struct PoolLiquidity {
    uint128 bntTradingLiquidity; // the BNT trading liquidity
    uint128 baseTokenTradingLiquidity; // the base token trading liquidity
    uint256 stakedBalance; // the staked balance
}

struct AverageRates {
    uint32 blockNumber;
    Fraction112 rate;
    Fraction112 invRate;
}

struct Pool {
    IPoolToken poolToken; // the pool token of the pool
    uint32 tradingFeePPM; // the trading fee (in units of PPM)
    bool tradingEnabled; // whether trading is enabled
    bool depositingEnabled; // whether depositing is enabled
    AverageRates averageRates; // the recent average rates
    PoolLiquidity liquidity; // the overall liquidity in the pool
}

struct WithdrawalAmounts {
    uint256 totalAmount;
    uint256 baseTokenAmount;
    uint256 bntAmount;
}

// trading enabling/disabling reasons
uint8 constant TRADING_STATUS_UPDATE_DEFAULT = 0;
uint8 constant TRADING_STATUS_UPDATE_ADMIN = 1;
uint8 constant TRADING_STATUS_UPDATE_MIN_LIQUIDITY = 2;
uint8 constant TRADING_STATUS_UPDATE_INVALID_STATE = 3;

struct TradeAmountAndFee {
    uint256 amount; // the source/target amount (depending on the context) resulting from the trade
    uint256 tradingFeeAmount; // the trading fee amount
    uint256 networkFeeAmount; // the network fee amount (always in units of BNT)
}

/**
 * @dev Pool Collection interface
 */
interface IPoolCollection is IVersioned {
    /**
     * @dev returns the type of the pool
     */
    function poolType() external view returns (uint16);

    /**
     * @dev returns the default trading fee (in units of PPM)
     */
    function defaultTradingFeePPM() external view returns (uint32);

    /**
     * @dev returns the network fee (in units of PPM)
     */
    function networkFeePPM() external view returns (uint32);

    /**
     * @dev returns all the pools which are managed by this pool collection
     */
    function pools() external view returns (Token[] memory);

    /**
     * @dev returns the number of all the pools which are managed by this pool collection
     */
    function poolCount() external view returns (uint256);

    /**
     * @dev returns whether a pool is valid
     */
    function isPoolValid(Token pool) external view returns (bool);

    /**
     * @dev returns the overall liquidity in the pool
     */
    function poolLiquidity(Token pool) external view returns (PoolLiquidity memory);

    /**
     * @dev returns the pool token of the pool
     */
    function poolToken(Token pool) external view returns (IPoolToken);

    /**
     * @dev returns the trading fee (in units of PPM)
     */
    function tradingFeePPM(Token pool) external view returns (uint32);

    /**
     * @dev returns whether trading is enabled
     */
    function tradingEnabled(Token pool) external view returns (bool);

    /**
     * @dev returns whether depositing is enabled
     */
    function depositingEnabled(Token pool) external view returns (bool);

    /**
     * @dev returns whether the pool is stable
     */
    function isPoolStable(Token pool) external view returns (bool);

    /**
     * @dev converts the specified pool token amount to the underlying base token amount
     */
    function poolTokenToUnderlying(Token pool, uint256 poolTokenAmount) external view returns (uint256);

    /**
     * @dev converts the specified underlying base token amount to pool token amount
     */
    function underlyingToPoolToken(Token pool, uint256 baseTokenAmount) external view returns (uint256);

    /**
     * @dev returns the number of pool token to burn in order to increase everyone's underlying value by the specified
     * amount
     */
    function poolTokenAmountToBurn(
        Token pool,
        uint256 baseTokenAmountToDistribute,
        uint256 protocolPoolTokenAmount
    ) external view returns (uint256);

    /**
     * @dev creates a new pool
     *
     * requirements:
     *
     * - the caller must be the network contract
     * - the pool should have been whitelisted
     * - the pool isn't already defined in the collection
     */
    function createPool(Token token) external;

    /**
     * @dev deposits base token liquidity on behalf of a specific provider and returns the respective pool token amount
     *
     * requirements:
     *
     * - the caller must be the network contract
     * - assumes that the base token has been already deposited in the vault
     */
    function depositFor(
        bytes32 contextId,
        address provider,
        Token pool,
        uint256 baseTokenAmount
    ) external returns (uint256);

    /**
     * @dev handles some of the withdrawal-related actions and returns the withdrawn base token amount
     *
     * requirements:
     *
     * - the caller must be the network contract
     * - the caller must have approved the collection to transfer/burn the pool token amount on its behalf
     */
    function withdraw(
        bytes32 contextId,
        address provider,
        Token pool,
        uint256 poolTokenAmount,
        uint256 baseTokenAmount
    ) external returns (uint256);

    /**
     * @dev returns the amounts that would be returned if the position is currently withdrawn,
     * along with the breakdown of the base token and the BNT compensation
     */
    function withdrawalAmounts(Token pool, uint256 poolTokenAmount) external view returns (WithdrawalAmounts memory);

    /**
     * @dev performs a trade by providing the source amount and returns the target amount and the associated fee
     *
     * requirements:
     *
     * - the caller must be the network contract
     */
    function tradeBySourceAmount(
        bytes32 contextId,
        Token sourceToken,
        Token targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount
    ) external returns (TradeAmountAndFee memory);

    /**
     * @dev performs a trade by providing the target amount and returns the required source amount and the associated fee
     *
     * requirements:
     *
     * - the caller must be the network contract
     */
    function tradeByTargetAmount(
        bytes32 contextId,
        Token sourceToken,
        Token targetToken,
        uint256 targetAmount,
        uint256 maxSourceAmount
    ) external returns (TradeAmountAndFee memory);

    /**
     * @dev returns the output amount and fee when trading by providing the source amount
     */
    function tradeOutputAndFeeBySourceAmount(
        Token sourceToken,
        Token targetToken,
        uint256 sourceAmount
    ) external view returns (TradeAmountAndFee memory);

    /**
     * @dev returns the input amount and fee when trading by providing the target amount
     */
    function tradeInputAndFeeByTargetAmount(
        Token sourceToken,
        Token targetToken,
        uint256 targetAmount
    ) external view returns (TradeAmountAndFee memory);

    /**
     * @dev notifies the pool of accrued fees
     *
     * requirements:
     *
     * - the caller must be the network contract
     */
    function onFeesCollected(Token pool, uint256 feeAmount) external;

    /**
     * @dev migrates a pool to this pool collection
     *
     * requirements:
     *
     * - the caller must be the pool migrator contract
     */
    function migratePoolIn(Token pool, Pool calldata data) external;

    /**
     * @dev migrates a pool from this pool collection
     *
     * requirements:
     *
     * - the caller must be the pool migrator contract
     */
    function migratePoolOut(Token pool, IPoolCollection targetPoolCollection) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { Token } from "../../token/Token.sol";

import { IVersioned } from "../../utility/interfaces/IVersioned.sol";

import { IPoolCollection } from "./IPoolCollection.sol";

/**
 * @dev Pool Migrator interface
 */
interface IPoolMigrator is IVersioned {
    /**
     * @dev migrates a pool and returns the new pool collection it exists in
     *
     * notes:
     *
     * - invalid or incompatible pools will be skipped gracefully
     *
     * requirements:
     *
     * - the caller must be the network contract
     */
    function migratePool(Token pool, IPoolCollection newPoolCollection) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import { IERC20Burnable } from "../../token/interfaces/IERC20Burnable.sol";
import { Token } from "../../token/Token.sol";

import { IVersioned } from "../../utility/interfaces/IVersioned.sol";
import { IOwned } from "../../utility/interfaces/IOwned.sol";

/**
 * @dev Pool Token interface
 */
interface IPoolToken is IVersioned, IOwned, IERC20, IERC20Permit, IERC20Burnable {
    /**
     * @dev returns the address of the reserve token
     */
    function reserveToken() external view returns (Token);

    /**
     * @dev increases the token supply and sends the new tokens to the given account
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     */
    function mint(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { Token } from "../../token/Token.sol";

import { IUpgradeable } from "../../utility/interfaces/IUpgradeable.sol";

import { IPoolToken } from "./IPoolToken.sol";

/**
 * @dev Pool Token Factory interface
 */
interface IPoolTokenFactory is IUpgradeable {
    /**
     * @dev returns the custom symbol override for a given reserve token
     */
    function tokenSymbolOverride(Token token) external view returns (string memory);

    /**
     * @dev returns the custom decimals override for a given reserve token
     */
    function tokenDecimalsOverride(Token token) external view returns (uint8);

    /**
     * @dev creates a pool token for the specified token
     */
    function createPoolToken(Token token) external returns (IPoolToken);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev extends the SafeERC20 library with additional operations
 */
library SafeERC20Ex {
    using SafeERC20 for IERC20;

    /**
     * @dev ensures that the spender has sufficient allowance
     */
    function ensureApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 allowance = token.allowance(address(this), spender);
        if (allowance >= amount) {
            return;
        }

        if (allowance > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

/**
 * @dev the main purpose of the Token interfaces is to ensure artificially that we won't use ERC20's standard functions,
 * but only their safe versions, which are provided by SafeERC20 and SafeERC20Ex via the TokenLibrary contract
 */
interface Token {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import { SafeERC20Ex } from "./SafeERC20Ex.sol";

import { Token } from "./Token.sol";

/**
 * @dev This library implements ERC20 and SafeERC20 utilities for both the native token and for ERC20 tokens
 */
library TokenLibrary {
    using SafeERC20 for IERC20;
    using SafeERC20Ex for IERC20;

    error PermitUnsupported();

    // the address that represents the native token reserve
    address private constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // the symbol that represents the native token
    string private constant NATIVE_TOKEN_SYMBOL = "ETH";

    // the decimals for the native token
    uint8 private constant NATIVE_TOKEN_DECIMALS = 18;

    // the token representing the native token
    Token public constant NATIVE_TOKEN = Token(NATIVE_TOKEN_ADDRESS);

    /**
     * @dev returns whether the provided token represents an ERC20 or the native token reserve
     */
    function isNative(Token token) internal pure returns (bool) {
        return address(token) == NATIVE_TOKEN_ADDRESS;
    }

    /**
     * @dev returns the symbol of the native token/ERC20 token
     */
    function symbol(Token token) internal view returns (string memory) {
        if (isNative(token)) {
            return NATIVE_TOKEN_SYMBOL;
        }

        return toERC20(token).symbol();
    }

    /**
     * @dev returns the decimals of the native token/ERC20 token
     */
    function decimals(Token token) internal view returns (uint8) {
        if (isNative(token)) {
            return NATIVE_TOKEN_DECIMALS;
        }

        return toERC20(token).decimals();
    }

    /**
     * @dev returns the balance of the native token/ERC20 token
     */
    function balanceOf(Token token, address account) internal view returns (uint256) {
        if (isNative(token)) {
            return account.balance;
        }

        return toIERC20(token).balanceOf(account);
    }

    /**
     * @dev transfers a specific amount of the native token/ERC20 token
     */
    function safeTransfer(
        Token token,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isNative(token)) {
            payable(to).transfer(amount);
        } else {
            toIERC20(token).safeTransfer(to, amount);
        }
    }

    /**
     * @dev transfers a specific amount of the native token/ERC20 token from a specific holder using the allowance mechanism
     *
     * note that the function does not perform any action if the native token is provided
     */
    function safeTransferFrom(
        Token token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || isNative(token)) {
            return;
        }

        toIERC20(token).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev approves a specific amount of the native token/ERC20 token from a specific holder
     *
     * note that the function does not perform any action if the native token is provided
     */
    function safeApprove(
        Token token,
        address spender,
        uint256 amount
    ) internal {
        if (isNative(token)) {
            return;
        }

        toIERC20(token).safeApprove(spender, amount);
    }

    /**
     * @dev ensures that the spender has sufficient allowance
     *
     * note that the function does not perform any action if the native token is provided
     */
    function ensureApprove(
        Token token,
        address spender,
        uint256 amount
    ) internal {
        if (isNative(token)) {
            return;
        }

        toIERC20(token).ensureApprove(spender, amount);
    }

    /**
     * @dev compares between a token and another raw ERC20 token
     */
    function isEqual(Token token, IERC20 erc20Token) internal pure returns (bool) {
        return toIERC20(token) == erc20Token;
    }

    /**
     * @dev utility function that converts a token to an IERC20
     */
    function toIERC20(Token token) internal pure returns (IERC20) {
        return IERC20(address(token));
    }

    /**
     * @dev utility function that converts a token to an ERC20
     */
    function toERC20(Token token) internal pure returns (ERC20) {
        return ERC20(address(token));
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

/**
 * @dev burnable ERC20 interface
 */
interface IERC20Burnable {
    /**
     * @dev Destroys tokens from the caller.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys tokens from a recipient, deducting from the caller's allowance
     *
     * requirements:
     *
     * - the caller must have allowance for recipient's tokens of at least the specified amount
     */
    function burnFrom(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

/**
 * @dev this contract abstracts the block number in order to allow for more flexible control in tests
 */
abstract contract BlockNumber {
    /**
     * @dev returns the current block-number
     */
    function _blockNumber() internal view virtual returns (uint32) {
        return uint32(block.number);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

uint32 constant PPM_RESOLUTION = 1_000_000;

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

struct Fraction {
    uint256 n;
    uint256 d;
}

struct Fraction112 {
    uint112 n;
    uint112 d;
}

error InvalidFraction();

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { Fraction, Fraction112, InvalidFraction } from "./Fraction.sol";
import { MathEx } from "./MathEx.sol";

// solhint-disable-next-line func-visibility
function zeroFraction() pure returns (Fraction memory) {
    return Fraction({ n: 0, d: 1 });
}

// solhint-disable-next-line func-visibility
function zeroFraction112() pure returns (Fraction112 memory) {
    return Fraction112({ n: 0, d: 1 });
}

/**
 * @dev this library provides a set of fraction operations
 */
library FractionLibrary {
    /**
     * @dev returns whether a standard fraction is valid
     */
    function isValid(Fraction memory fraction) internal pure returns (bool) {
        return fraction.d != 0;
    }

    /**
     * @dev returns whether a 112-bit fraction is valid
     */
    function isValid(Fraction112 memory fraction) internal pure returns (bool) {
        return fraction.d != 0;
    }

    /**
     * @dev returns whether a standard fraction is positive
     */
    function isPositive(Fraction memory fraction) internal pure returns (bool) {
        return isValid(fraction) && fraction.n != 0;
    }

    /**
     * @dev returns whether a 112-bit fraction is positive
     */
    function isPositive(Fraction112 memory fraction) internal pure returns (bool) {
        return isValid(fraction) && fraction.n != 0;
    }

    /**
     * @dev returns the inverse of a given fraction
     */
    function inverse(Fraction memory fraction) internal pure returns (Fraction memory) {
        Fraction memory invFraction = Fraction({ n: fraction.d, d: fraction.n });

        if (!isValid(invFraction)) {
            revert InvalidFraction();
        }

        return invFraction;
    }

    /**
     * @dev returns the inverse of a given fraction
     */
    function inverse(Fraction112 memory fraction) internal pure returns (Fraction112 memory) {
        Fraction112 memory invFraction = Fraction112({ n: fraction.d, d: fraction.n });

        if (!isValid(invFraction)) {
            revert InvalidFraction();
        }

        return invFraction;
    }

    /**
     * @dev reduces a standard fraction to a 112-bit fraction
     */
    function toFraction112(Fraction memory fraction) internal pure returns (Fraction112 memory) {
        Fraction memory truncatedFraction = MathEx.truncatedFraction(fraction, type(uint112).max);

        return Fraction112({ n: uint112(truncatedFraction.n), d: uint112(truncatedFraction.d) });
    }

    /**
     * @dev expands a 112-bit fraction to a standard fraction
     */
    function fromFraction112(Fraction112 memory fraction) internal pure returns (Fraction memory) {
        return Fraction({ n: fraction.n, d: fraction.d });
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Fraction, InvalidFraction } from "./Fraction.sol";

import { PPM_RESOLUTION } from "./Constants.sol";

uint256 constant ONE = 0x80000000000000000000000000000000;
uint256 constant LN2 = 0x58b90bfbe8e7bcd5e4f1d9cc01f97b57;

struct Uint512 {
    uint256 hi; // 256 most significant bits
    uint256 lo; // 256 least significant bits
}

struct Sint256 {
    uint256 value;
    bool isNeg;
}

/**
 * @dev this library provides a set of complex math operations
 */
library MathEx {
    error Overflow();

    /**
     * @dev returns `2 ^ f` by calculating `e ^ (f * ln(2))`, where `e` is Euler's number:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function exp2(Fraction memory f) internal pure returns (Fraction memory) {
        uint256 x = MathEx.mulDivF(LN2, f.n, f.d);
        uint256 y;
        uint256 z;
        uint256 n;

        if (x >= (ONE << 4)) {
            revert Overflow();
        }

        unchecked {
            z = y = x % (ONE >> 3); // get the input modulo 2^(-3)
            z = (z * y) / ONE;
            n += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
            z = (z * y) / ONE;
            n += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
            z = (z * y) / ONE;
            n += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
            z = (z * y) / ONE;
            n += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
            z = (z * y) / ONE;
            n += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
            z = (z * y) / ONE;
            n += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
            z = (z * y) / ONE;
            n += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
            z = (z * y) / ONE;
            n += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
            z = (z * y) / ONE;
            n += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
            z = (z * y) / ONE;
            n += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
            z = (z * y) / ONE;
            n += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
            z = (z * y) / ONE;
            n += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
            z = (z * y) / ONE;
            n += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
            z = (z * y) / ONE;
            n += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
            z = (z * y) / ONE;
            n += z * 0x000000000001c638; // add y^16 * (20! / 16!)
            z = (z * y) / ONE;
            n += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
            z = (z * y) / ONE;
            n += z * 0x000000000000017c; // add y^18 * (20! / 18!)
            z = (z * y) / ONE;
            n += z * 0x0000000000000014; // add y^19 * (20! / 19!)
            z = (z * y) / ONE;
            n += z * 0x0000000000000001; // add y^20 * (20! / 20!)
            n = n / 0x21c3677c82b40000 + y + ONE; // divide by 20! and then add y^1 / 1! + y^0 / 0!

            if ((x & (ONE >> 3)) != 0)
                n = (n * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^(2^-3)
            if ((x & (ONE >> 2)) != 0)
                n = (n * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^(2^-2)
            if ((x & (ONE >> 1)) != 0)
                n = (n * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^(2^-1)
            if ((x & (ONE << 0)) != 0)
                n = (n * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^(2^+0)
            if ((x & (ONE << 1)) != 0)
                n = (n * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^(2^+1)
            if ((x & (ONE << 2)) != 0)
                n = (n * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^(2^+2)
            if ((x & (ONE << 3)) != 0)
                n = (n * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^(2^+3)
        }

        return Fraction({ n: n, d: ONE });
    }

    /**
     * @dev returns a fraction with truncated components
     */
    function truncatedFraction(Fraction memory fraction, uint256 max) internal pure returns (Fraction memory) {
        uint256 scale = Math.ceilDiv(Math.max(fraction.n, fraction.d), max);
        Fraction memory truncated = Fraction({ n: fraction.n / scale, d: fraction.d / scale });
        if (truncated.d == 0) {
            revert InvalidFraction();
        }

        return truncated;
    }

    /**
     * @dev returns the weighted average of two fractions
     */
    function weightedAverage(
        Fraction memory fraction1,
        Fraction memory fraction2,
        uint256 weight1,
        uint256 weight2
    ) internal pure returns (Fraction memory) {
        return
            Fraction({
                n: fraction1.n * fraction2.d * weight1 + fraction1.d * fraction2.n * weight2,
                d: fraction1.d * fraction2.d * (weight1 + weight2)
            });
    }

    /**
     * @dev returns whether or not the deviation of an offset sample from a base sample is within a permitted range
     * for example, if the maximum permitted deviation is 5%, then evaluate `95% * base <= offset <= 105% * base`
     */
    function isInRange(
        Fraction memory baseSample,
        Fraction memory offsetSample,
        uint32 maxDeviationPPM
    ) internal pure returns (bool) {
        Uint512 memory min = mul512(baseSample.n, offsetSample.d * (PPM_RESOLUTION - maxDeviationPPM));
        Uint512 memory mid = mul512(baseSample.d, offsetSample.n * PPM_RESOLUTION);
        Uint512 memory max = mul512(baseSample.n, offsetSample.d * (PPM_RESOLUTION + maxDeviationPPM));
        return lte512(min, mid) && lte512(mid, max);
    }

    /**
     * @dev returns an `Sint256` positive representation of an unsigned integer
     */
    function toPos256(uint256 n) internal pure returns (Sint256 memory) {
        return Sint256({ value: n, isNeg: false });
    }

    /**
     * @dev returns an `Sint256` negative representation of an unsigned integer
     */
    function toNeg256(uint256 n) internal pure returns (Sint256 memory) {
        return Sint256({ value: n, isNeg: true });
    }

    /**
     * @dev returns the largest integer smaller than or equal to `x * y / z`
     */
    function mulDivF(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        Uint512 memory xy = mul512(x, y);

        // if `x * y < 2 ^ 256`
        if (xy.hi == 0) {
            return xy.lo / z;
        }

        // assert `x * y / z < 2 ^ 256`
        if (xy.hi >= z) {
            revert Overflow();
        }

        uint256 m = _mulMod(x, y, z); // `m = x * y % z`
        Uint512 memory n = _sub512(xy, m); // `n = x * y - m` hence `n / z = floor(x * y / z)`

        // if `n < 2 ^ 256`
        if (n.hi == 0) {
            return n.lo / z;
        }

        uint256 p = _unsafeSub(0, z) & z; // `p` is the largest power of 2 which `z` is divisible by
        uint256 q = _div512(n, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
        uint256 r = _inv256(z / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
        return _unsafeMul(q, r); // `q * r = (n / p) * inverse(z / p) = n / z`
    }

    /**
     * @dev returns the smallest integer larger than or equal to `x * y / z`
     */
    function mulDivC(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        uint256 w = mulDivF(x, y, z);
        if (_mulMod(x, y, z) > 0) {
            if (w >= type(uint256).max) {
                revert Overflow();
            }

            return w + 1;
        }
        return w;
    }

    /**
     * @dev returns the maximum of `n1 - n2` and 0
     */
    function subMax0(uint256 n1, uint256 n2) internal pure returns (uint256) {
        return n1 > n2 ? n1 - n2 : 0;
    }

    /**
     * @dev returns the value of `x > y`
     */
    function gt512(Uint512 memory x, Uint512 memory y) internal pure returns (bool) {
        return x.hi > y.hi || (x.hi == y.hi && x.lo > y.lo);
    }

    /**
     * @dev returns the value of `x < y`
     */
    function lt512(Uint512 memory x, Uint512 memory y) internal pure returns (bool) {
        return x.hi < y.hi || (x.hi == y.hi && x.lo < y.lo);
    }

    /**
     * @dev returns the value of `x >= y`
     */
    function gte512(Uint512 memory x, Uint512 memory y) internal pure returns (bool) {
        return !lt512(x, y);
    }

    /**
     * @dev returns the value of `x <= y`
     */
    function lte512(Uint512 memory x, Uint512 memory y) internal pure returns (bool) {
        return !gt512(x, y);
    }

    /**
     * @dev returns the value of `x * y`
     */
    function mul512(uint256 x, uint256 y) internal pure returns (Uint512 memory) {
        uint256 p = _mulModMax(x, y);
        uint256 q = _unsafeMul(x, y);
        if (p >= q) {
            return Uint512({ hi: p - q, lo: q });
        }
        return Uint512({ hi: _unsafeSub(p, q) - 1, lo: q });
    }

    /**
     * @dev returns the value of `x - y`, given that `x >= y`
     */
    function _sub512(Uint512 memory x, uint256 y) private pure returns (Uint512 memory) {
        if (x.lo >= y) {
            return Uint512({ hi: x.hi, lo: x.lo - y });
        }
        return Uint512({ hi: x.hi - 1, lo: _unsafeSub(x.lo, y) });
    }

    /**
     * @dev returns the value of `x / pow2n`, given that `x` is divisible by `pow2n`
     */
    function _div512(Uint512 memory x, uint256 pow2n) private pure returns (uint256) {
        uint256 pow2nInv = _unsafeAdd(_unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
        return _unsafeMul(x.hi, pow2nInv) | (x.lo / pow2n); // `(x.hi << (256 - n)) | (x.lo >> n)`
    }

    /**
     * @dev returns the inverse of `d` modulo `2 ^ 256`, given that `d` is congruent to `1` modulo `2`
     */
    function _inv256(uint256 d) private pure returns (uint256) {
        // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
        uint256 x = 1;
        for (uint256 i = 0; i < 8; i++) {
            x = _unsafeMul(x, _unsafeSub(2, _unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
        }
        return x;
    }

    /**
     * @dev returns `(x + y) % 2 ^ 256`
     */
    function _unsafeAdd(uint256 x, uint256 y) private pure returns (uint256) {
        unchecked {
            return x + y;
        }
    }

    /**
     * @dev returns `(x - y) % 2 ^ 256`
     */
    function _unsafeSub(uint256 x, uint256 y) private pure returns (uint256) {
        unchecked {
            return x - y;
        }
    }

    /**
     * @dev returns `(x * y) % 2 ^ 256`
     */
    function _unsafeMul(uint256 x, uint256 y) private pure returns (uint256) {
        unchecked {
            return x * y;
        }
    }

    /**
     * @dev returns `x * y % (2 ^ 256 - 1)`
     */
    function _mulModMax(uint256 x, uint256 y) private pure returns (uint256) {
        return mulmod(x, y, type(uint256).max);
    }

    /**
     * @dev returns `x * y % z`
     */
    function _mulMod(
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        return mulmod(x, y, z);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IOwned } from "./interfaces/IOwned.sol";
import { AccessDenied } from "./Utils.sol";

/**
 * @dev this contract provides support and utilities for contract ownership
 */
abstract contract Owned is IOwned {
    error SameOwner();

    address private _owner;
    address private _newOwner;

    /**
     * @dev triggered when the owner is updated
     */
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    // solhint-disable func-name-mixedcase

    /**
     * @dev initializes the contract
     */
    constructor() {
        _setOwnership(msg.sender);
    }

    // solhint-enable func-name-mixedcase

    // allows execution by the owner only
    modifier onlyOwner() {
        _onlyOwner();

        _;
    }

    // error message binary size optimization
    function _onlyOwner() private view {
        if (msg.sender != _owner) {
            revert AccessDenied();
        }
    }

    /**
     * @inheritdoc IOwned
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @inheritdoc IOwned
     */
    function transferOwnership(address ownerCandidate) public virtual onlyOwner {
        if (ownerCandidate == _owner) {
            revert SameOwner();
        }

        _newOwner = ownerCandidate;
    }

    /**
     * @inheritdoc IOwned
     */
    function acceptOwnership() public virtual {
        if (msg.sender != _newOwner) {
            revert AccessDenied();
        }

        _setOwnership(_newOwner);
    }

    /**
     * @dev returns the address of the new owner candidate
     */
    function newOwner() external view returns (address) {
        return _newOwner;
    }

    /**
     * @dev sets the new owner internally
     */
    function _setOwnership(address ownerCandidate) private {
        address prevOwner = _owner;

        _owner = ownerCandidate;
        _newOwner = address(0);

        emit OwnerUpdate({ prevOwner: prevOwner, newOwner: ownerCandidate });
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { PPM_RESOLUTION } from "./Constants.sol";

error AccessDenied();
error AlreadyExists();
error DoesNotExist();
error InvalidAddress();
error InvalidExternalAddress();
error InvalidFee();
error InvalidPool();
error InvalidPoolCollection();
error InvalidStakedBalance();
error InvalidToken();
error InvalidParam();
error NotEmpty();
error NotPayable();
error ZeroValue();

/**
 * @dev common utilities
 */
abstract contract Utils {
    // allows execution by the caller only
    modifier only(address caller) {
        _only(caller);

        _;
    }

    function _only(address caller) internal view {
        if (msg.sender != caller) {
            revert AccessDenied();
        }
    }

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        if (value == 0) {
            revert ZeroValue();
        }
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert InvalidAddress();
        }
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address addr) {
        _validExternalAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address addr) internal view {
        if (addr == address(0) || addr == address(this)) {
            revert InvalidExternalAddress();
        }
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        if (fee > PPM_RESOLUTION) {
            revert InvalidFee();
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

/**
 * @dev Owned interface
 */
interface IOwned {
    /**
     * @dev returns the address of the current owner
     */
    function owner() external view returns (address);

    /**
     * @dev allows transferring the contract ownership
     *
     * requirements:
     *
     * - the caller must be the owner of the contract
     * - the new owner still needs to accept the transfer
     */
    function transferOwnership(address ownerCandidate) external;

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IVersioned } from "./IVersioned.sol";

import { IAccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

/**
 * @dev this is the common interface for upgradeable contracts
 */
interface IUpgradeable is IAccessControlEnumerableUpgradeable, IVersioned {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

/**
 * @dev an interface for a versioned contract
 */
interface IVersioned {
    function version() external view returns (uint16);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IVault } from "./IVault.sol";

interface IExternalProtectionVault is IVault {}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IVault } from "./IVault.sol";

interface IMasterVault is IVault {}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { IUpgradeable } from "../../utility/interfaces/IUpgradeable.sol";

import { Token } from "../../token/Token.sol";

// the asset manager role is required to access all the funds
bytes32 constant ROLE_ASSET_MANAGER = keccak256("ROLE_ASSET_MANAGER");

interface IVault is IUpgradeable {
    /**
     * @dev triggered when tokens have been withdrawn from the vault
     */
    event FundsWithdrawn(Token indexed token, address indexed caller, address indexed target, uint256 amount);

    /**
     * @dev triggered when tokens have been burned from the vault
     */
    event FundsBurned(Token indexed token, address indexed caller, uint256 amount);

    /**
     * @dev tells whether the vault accepts native token deposits
     */
    function isPayable() external view returns (bool);

    /**
     * @dev withdraws funds held by the contract and sends them to an account
     */
    function withdrawFunds(
        Token token,
        address payable target,
        uint256 amount
    ) external;

    /**
     * @dev burns funds held by the contract
     */
    function burn(Token token, uint256 amount) external;
}