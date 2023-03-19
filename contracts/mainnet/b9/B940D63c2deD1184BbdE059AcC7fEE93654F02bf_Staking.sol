// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
pragma solidity 0.8.17;

// interfaces
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFarmingRange {
    /**
     * @notice Info of each user.
     * @param amount How many Staking tokens the user has provided.
     * @param rewardDebt We do some fancy math here. Basically, any point in time, the amount of reward
     *  entitled to a user but is pending to be distributed is:
     *
     *    pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
     *
     *  Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
     *    1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
     *    2. User receives the pending reward sent to his/her address.
     *    3. User's `amount` gets updated.
     *    4. User's `rewardDebt` gets updated.
     *
     * from: https://github.com/jazz-defi/contracts/blob/master/MasterChefV2.sol
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /**
     * @notice Info of each reward distribution campaign.
     * @param stakingToken address of Staking token contract.
     * @param rewardToken address of Reward token contract
     * @param startBlock start block of the campaign
     * @param lastRewardBlock last block number that Reward Token distribution occurs.
     * @param accRewardPerShare accumulated Reward Token per share, times 1e20.
     * @param totalStaked total staked amount each campaign's stake token, typically,
     * @param totalRewards total amount of reward to be distributed until the end of the last phase
     *
     * @dev each campaign has the same stake token, so no need to track it separetely
     */
    struct CampaignInfo {
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 totalStaked;
        uint256 totalRewards;
    }

    /**
     * @notice Info about a reward-phase
     * @param endBlock block number of the end of the phase
     * @param rewardPerBlock amount of reward to be distributed per block in this phase
     */
    struct RewardInfo {
        uint256 endBlock;
        uint256 rewardPerBlock;
    }

    /**
     * @notice emitted at each deposit
     * @param user address that deposit its funds
     * @param amount amount deposited
     * @param campaign campaingId on which the user has deposited funds
     */
    event Deposit(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each withdraw
     * @param user address that withdrawn its funds
     * @param amount amount withdrawn
     * @param campaign campaingId on which the user has withdrawn funds
     */
    event Withdraw(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each emergency withdraw
     * @param user address that emergency-withdrawn its funds
     * @param amount amount emergency-withdrawn
     * @param campaign campaingId on which the user has emergency-withdrawn funds
     */
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each campaign added
     * @param campaignID new campaign id
     * @param stakingToken token address to be staked in this campaign
     * @param rewardToken token address of the rewards in this campaign
     * @param startBlock starting block of this campaign
     */
    event AddCampaignInfo(uint256 indexed campaignID, IERC20 stakingToken, IERC20 rewardToken, uint256 startBlock);

    /**
     * @notice emitted at each phase of reward added
     * @param campaignID campaign id on which rewards were added
     * @param phase number of the new phase added (latest at the moment of add)
     * @param endBlock number of the block that the phase stops (phase starts at the endblock of the previous phase's
     * endblock, and if it's the phase 0, it start at the startBlock of the campaign struct)
     * @param rewardPerBlock amount of reward distributed per block in this phase
     */
    event AddRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);

    /**
     * @notice emitted when a reward phase is updated
     * @param campaignID campaign id on which the rewards-phase is updated
     * @param phase id of phase updated
     * @param endBlock new endblock of the phase
     * @param rewardPerBlock new rewardPerBlock of the phase
     */
    event UpdateRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);

    /**
     * @notice emitted when a reward phase is removed
     * @param campaignID campaign id on which the rewards-phase is removed
     * @param phase id of phase removed (only the latest phase can be removed)
     */
    event RemoveRewardInfo(uint256 indexed campaignID, uint256 indexed phase);

    /**
     * @notice emitted when the rewardInfoLimit is updated
     * @param rewardInfoLimit new max phase amount per campaign
     */
    event SetRewardInfoLimit(uint256 rewardInfoLimit);

    /**
     * @notice emitted when the rewardManager is changed
     * @param rewardManager address of the new rewardManager
     */
    event SetRewardManager(address rewardManager);

    /**
     * @notice increase precision of accRewardPerShare in all campaign
     */
    function upgradePrecision() external;

    /**
     * @notice set the reward manager, responsible for adding rewards
     * @param _rewardManager address of the reward manager
     */
    function setRewardManager(address _rewardManager) external;

    /**
     * @notice set new reward info limit, defining how many phases are allowed
     * @param _updatedRewardInfoLimit new reward info limit
     */
    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit) external;

    /**
     * @notice reward campaign, one campaign represent a pair of staking and reward token,
     * last reward Block and acc reward Per Share
     * @param _stakingToken staking token address
     * @param _rewardToken reward token address
     * @param _startBlock block number when the campaign will start
     */
    function addCampaignInfo(IERC20 _stakingToken, IERC20 _rewardToken, uint256 _startBlock) external;

    /**
     * @notice add a nex reward info, when a new reward info is added, the reward
     * & its end block will be extended by the newly pushed reward info.
     * @param _campaignID id of the campaign
     * @param _endBlock end block of this reward info
     * @param _rewardPerBlock reward per block to distribute until the end
     */
    function addRewardInfo(uint256 _campaignID, uint256 _endBlock, uint256 _rewardPerBlock) external;

    /**
     * @notice add multiple reward Info into a campaign in one tx.
     * @param _campaignID id of the campaign
     * @param _endBlock array of end blocks
     * @param _rewardPerBlock array of reward per block
     */
    function addRewardInfoMultiple(
        uint256 _campaignID,
        uint256[] calldata _endBlock,
        uint256[] calldata _rewardPerBlock
    ) external;

    /**
     * @notice update one campaign reward info for a specified range index.
     * @param _campaignID id of the campaign
     * @param _rewardIndex index of the reward info
     * @param _endBlock end block of this reward info
     * @param _rewardPerBlock reward per block to distribute until the end
     */
    function updateRewardInfo(
        uint256 _campaignID,
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) external;

    /**
     * @notice update multiple campaign rewards info for all range index.
     * @param _campaignID id of the campaign
     * @param _rewardIndex array of reward info index
     * @param _endBlock array of end block
     * @param _rewardPerBlock array of rewardPerBlock
     */
    function updateRewardMultiple(
        uint256 _campaignID,
        uint256[] memory _rewardIndex,
        uint256[] memory _endBlock,
        uint256[] memory _rewardPerBlock
    ) external;

    /**
     * @notice update multiple campaigns and rewards info for all range index.
     * @param _campaignID array of campaign id
     * @param _rewardIndex multi dimensional array of reward info index
     * @param _endBlock multi dimensional array of end block
     * @param _rewardPerBlock multi dimensional array of rewardPerBlock
     */
    function updateCampaignsRewards(
        uint256[] calldata _campaignID,
        uint256[][] calldata _rewardIndex,
        uint256[][] calldata _endBlock,
        uint256[][] calldata _rewardPerBlock
    ) external;

    /**
     * @notice remove last reward info for specified campaign.
     * @param _campaignID campaign id
     */
    function removeLastRewardInfo(uint256 _campaignID) external;

    /**
     * @notice return the entries amount of reward info for one campaign.
     * @param _campaignID campaign id
     * @return reward info quantity
     */
    function rewardInfoLen(uint256 _campaignID) external view returns (uint256);

    /**
     * @notice return the number of campaigns.
     * @return campaign quantity
     */
    function campaignInfoLen() external view returns (uint256);

    /**
     * @notice return the end block of the current reward info for a given campaign.
     * @param _campaignID campaign id
     * @return reward info end block number
     */
    function currentEndBlock(uint256 _campaignID) external view returns (uint256);

    /**
     * @notice return the reward per block of the current reward info for a given campaign.
     * @param _campaignID campaign id
     * @return current reward per block
     */
    function currentRewardPerBlock(uint256 _campaignID) external view returns (uint256);

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * Reward multiplier is the amount of blocks between from and to
     * @param _from start block number
     * @param _to end block number
     * @param _endBlock end block number of the reward info
     * @return block distance
     */
    function getMultiplier(uint256 _from, uint256 _to, uint256 _endBlock) external returns (uint256);

    /**
     * @notice View function to retrieve pending Reward.
     * @param _campaignID pending reward of campaign id
     * @param _user address to retrieve pending reward
     * @return current pending reward
     */
    function pendingReward(uint256 _campaignID, address _user) external view returns (uint256);

    /**
     * @notice Update reward variables of the given campaign to be up-to-date.
     * @param _campaignID campaign id
     */
    function updateCampaign(uint256 _campaignID) external;

    /**
     * @notice Update reward variables for all campaigns. gas spending is HIGH in this method call, BE CAREFUL.
     */
    function massUpdateCampaigns() external;

    /**
     * @notice Deposit staking token in a campaign.
     * @param _campaignID campaign id
     * @param _amount amount to deposit
     */
    function deposit(uint256 _campaignID, uint256 _amount) external;

    /**
     * @notice Deposit staking token in a campaign with the EIP-2612 signature off chain
     * @param _campaignID campaign id
     * @param _amount amount to deposit
     * @param _approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @param _v The v component of the permit signature.
     * @param _r The r component of the permit signature.
     * @param _s The s component of the permit signature.
     */
    function depositWithPermit(
        uint256 _campaignID,
        uint256 _amount,
        bool _approveMax,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Withdraw staking token in a campaign. Also withdraw the current pending reward
     * @param _campaignID campaign id
     * @param _amount amount to withdraw
     */
    function withdraw(uint256 _campaignID, uint256 _amount) external;

    /**
     * @notice Harvest campaigns, will claim rewards token of every campaign ids in the array
     * @param _campaignIDs array of campaign id
     */
    function harvest(uint256[] calldata _campaignIDs) external;

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _campaignID campaign id
     */
    function emergencyWithdraw(uint256 _campaignID) external;

    /**
     * @notice get Reward info for a campaign ID and index, that is a set of {endBlock, rewardPerBlock}
     *  indexed by campaign ID
     * @param _campaignID campaign id
     * @param _rewardIndex index of the reward info
     * @return endBlock_ end block of this reward info
     * @return rewardPerBlock_ reward per block to distribute
     */
    function campaignRewardInfo(
        uint256 _campaignID,
        uint256 _rewardIndex
    ) external view returns (uint256 endBlock_, uint256 rewardPerBlock_);

    /**
     * @notice get a Campaign Reward info for a campaign ID
     * @param _campaignID campaign id
     * @return all params from CampaignInfo struct
     */
    function campaignInfo(
        uint256 _campaignID
    ) external view returns (IERC20, IERC20, uint256, uint256, uint256, uint256, uint256);

    /**
     * @notice get a User Reward info for a campaign ID and user address
     * @param _campaignID campaign id
     * @param _user user address
     * @return all params from UserInfo struct
     */
    function userInfo(uint256 _campaignID, address _user) external view returns (uint256, uint256);

    /**
     * @notice how many reward phases can be set for a campaign
     * @return rewards phases size limit
     */
    function rewardInfoLimit() external view returns (uint256);

    /**
     * @notice get reward Manager address holding rewards to distribute
     * @return address of reward manager
     */
    function rewardManager() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFarmingRange.sol";

interface IStaking is IERC20 {
    /**
     * @notice iunfo of each user
     * @param shares shares owned in the staking
     * @param lastBlockUpdate last block the user called deposit or withdraw
     */
    struct UserInfo {
        uint256 shares;
        uint256 lastBlockUpdate;
    }

    /**
     * @notice emitted at each deposit
     * @param from address that deposit its funds
     * @param depositAmount amount deposited
     * @param shares shares corresponding to the token amount deposited
     */
    event Deposit(address indexed from, uint256 depositAmount, uint256 shares);

    /**
     * @notice emitted at each withdraw
     * @param from address that calls the withdraw function, and of which the shares are withdrawn
     * @param to address that receives the funds
     * @param tokenReceived amount of token received by to
     * @param shares shares corresponding to the token amount withdrawn
     */
    event Withdraw(address indexed from, address indexed to, uint256 tokenReceived, uint256 shares);

    /**
     * @notice Initialize staking connection with farming
     * Mint one token of stSDEX and then deposit in the staking farming pool
     * This contract should be the only participant of the staking farming pool
     */
    function initializeFarming() external;

    /**
     * @notice Send SDEX to get shares in the staking pool
     * @param _depositAmount The amount of SDEX to send
     */
    function deposit(uint256 _depositAmount) external;

    /**
     * @notice Send SDEX to get shares in the staking pool with the EIP-2612 signature off chain
     * @param _depositAmount The amount of SDEX to send
     * @param _approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @param _v The v component of the permit signature.
     * @param _r The r component of the permit signature.
     * @param _s The s component of the permit signature.
     */
    function depositWithPermit(
        uint256 _depositAmount,
        bool _approveMax,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Harvest and withdraw SDEX for the amount of shares defined
     * @param _to The address who will receive SDEX
     * @param _sharesAmount The amount of shares to use
     */
    function withdraw(address _to, uint256 _sharesAmount) external;

    /**
     * @notice Harvest the farming pool for the staking, will increase the SDEX
     */
    function harvestFarming() external;

    /**
     * @notice Calculate shares qty for an amount of sdex tokens
     * @param _tokens user qty of sdex to be converted to shares
     * @return shares_ shares equivalent to the token amount. _shares <= totalShares
     */
    function tokensToShares(uint256 _tokens) external view returns (uint256 shares_);

    /**
     * @notice Calculate shares values in sdex tokens
     * @param _shares amount of shares. _shares <= totalShares
     * @return tokens_ qty of sdex token equivalent to the _shares. tokens_ <= _currentBalance
     */
    function sharesToTokens(uint256 _shares) external view returns (uint256 tokens_);

    /**
     * @notice Campaign id for staking in the farming contract
     * @return ID of the campaign
     */
    function CAMPAIGN_ID() external view returns (uint256);

    /**
     * @notice get farming initialized status
     * @return boolean inititalized or not
     */
    function farmingInitialized() external view returns (bool);

    /**
     * @notice get smardex Token contract address
     * @return smardex contract (address or type for Solidity)
     */
    function smardexToken() external view returns (IERC20);

    /**
     * @notice get farming contract address
     * @return farming contract (address or type for Solidity)
     */
    function farming() external view returns (IFarmingRange);

    /**
     * @notice get user info for staking status
     * @param _user user address
     * @return shares amount for user
     * @return lastBlockUpdate last block the user called deposit or withdraw
     */
    function userInfo(address _user) external view returns (uint256, uint256);

    /**
     * @notice get total shares in the staking
     * @return total shares amount
     */
    function totalShares() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Staking
 * @notice Implementation of an APY staking pool. Users can deposit SDEX for a share in the pool. New shares depend of
 * current shares supply and SDEX in the pool. Pool will receive SDEX rewards fees by external transfer from admin or
 * contract but also from farming pool. Each deposit/withdraw will harvest the user funds in the farming pool as well.
 */
contract Staking is IStaking, ERC20 {
    using SafeERC20 for IERC20;

    uint256 public constant CAMPAIGN_ID = 0;
    uint256 internal constant SHARES_FACTOR = 1e18;

    IERC20 public immutable smardexToken;
    IFarmingRange public immutable farming;

    mapping(address => UserInfo) public userInfo;
    uint256 public totalShares;
    bool public farmingInitialized = false;

    modifier isFarmingInitialized() {
        require(farmingInitialized == true, "Staking::isFarmingInitialized::Farming campaign not initialized");
        _;
    }

    modifier checkUserBlock() {
        require(
            userInfo[msg.sender].lastBlockUpdate < block.number,
            "Staking::checkUserBlock::User already called deposit or withdraw this block"
        );
        userInfo[msg.sender].lastBlockUpdate = block.number;
        _;
    }

    constructor(IERC20 _smardexToken, IFarmingRange _farming) ERC20("Staked SmarDex Token", "stSDEX") {
        smardexToken = _smardexToken;
        farming = _farming;
    }

    /// @inheritdoc IStaking
    function initializeFarming() external {
        require(farmingInitialized == false, "Staking::initializeFarming::Farming campaign already initialized");
        _approve(address(this), address(farming), 1 wei);
        _mint(address(this), 1 wei);
        farming.deposit(CAMPAIGN_ID, 1 wei);

        farmingInitialized = true;
    }

    /// @inheritdoc IStaking
    function deposit(uint256 _depositAmount) public isFarmingInitialized checkUserBlock {
        require(_depositAmount > 0, "Staking::deposit::can't deposit zero token");

        harvestFarming();

        uint256 _currentBalance = smardexToken.balanceOf(address(this));
        uint256 _newShares = _tokensToShares(_depositAmount, _currentBalance);

        smardexToken.safeTransferFrom(msg.sender, address(this), _depositAmount);

        totalShares += _newShares;
        userInfo[msg.sender].shares += _newShares;

        emit Deposit(msg.sender, _depositAmount, _newShares);
    }

    /// @inheritdoc IStaking
    function depositWithPermit(
        uint256 _depositAmount,
        bool _approveMax,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        SafeERC20.safePermit(
            IERC20Permit(address(smardexToken)),
            msg.sender,
            address(this),
            _approveMax ? type(uint256).max : _depositAmount,
            _deadline,
            _v,
            _r,
            _s
        );

        deposit(_depositAmount);
    }

    /// @inheritdoc IStaking
    function withdraw(address _to, uint256 _sharesAmount) external isFarmingInitialized checkUserBlock {
        require(
            _sharesAmount > 0 && userInfo[msg.sender].shares >= _sharesAmount,
            "Staking::withdraw::can't withdraw more than user shares or zero"
        );

        harvestFarming();

        uint256 _currentBalance = smardexToken.balanceOf(address(this));
        uint256 _tokensToWithdraw = _sharesToTokens(_sharesAmount, _currentBalance);

        userInfo[msg.sender].shares -= _sharesAmount;
        totalShares -= _sharesAmount;
        smardexToken.safeTransfer(_to, _tokensToWithdraw);

        emit Withdraw(msg.sender, _to, _tokensToWithdraw, _sharesAmount);
    }

    /// @inheritdoc IStaking
    function harvestFarming() public {
        farming.withdraw(CAMPAIGN_ID, 0);
    }

    /// @inheritdoc IStaking
    function tokensToShares(uint256 _tokens) external view returns (uint256 shares_) {
        uint256 _currentBalance = smardexToken.balanceOf(address(this));
        _currentBalance += farming.pendingReward(CAMPAIGN_ID, address(this));

        shares_ = _tokensToShares(_tokens, _currentBalance);
    }

    /// @inheritdoc IStaking
    function sharesToTokens(uint256 _shares) external view returns (uint256 tokens_) {
        uint256 _currentBalance = smardexToken.balanceOf(address(this));
        _currentBalance += farming.pendingReward(CAMPAIGN_ID, address(this));

        tokens_ = _sharesToTokens(_shares, _currentBalance);
    }

    /**
     * @notice Calculate shares qty for an amount of sdex tokens
     * @param _tokens user qty of sdex to be converted to shares
     * @param _currentBalance contract balance sdex. _tokens <= _currentBalance
     * @return shares_ shares equivalent to the token amount. _shares <= totalShares
     */
    function _tokensToShares(uint256 _tokens, uint256 _currentBalance) internal view returns (uint256 shares_) {
        shares_ = totalShares > 0 ? (_tokens * totalShares) / _currentBalance : _tokens * SHARES_FACTOR;
    }

    /**
     * @notice Calculate shares values in sdex tokens
     * @param _shares amount of shares. _shares <= totalShares
     * @param _currentBalance contract balance in sdex
     * @return tokens_ qty of sdex token equivalent to the _shares. tokens_ <= _currentBalance
     */
    function _sharesToTokens(uint256 _shares, uint256 _currentBalance) internal view returns (uint256 tokens_) {
        tokens_ = totalShares > 0 ? (_shares * _currentBalance) / totalShares : _shares / SHARES_FACTOR;
    }
}