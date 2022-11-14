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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface ILPToken is IERC20 {
    function mint(address to, uint amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/// @title IOracle
/// @notice Read price of various token
interface IOracle {
    function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {SignedInt} from "../lib/SignedInt.sol";

enum Side {
    LONG,
    SHORT
}

struct TokenWeight {
    address token;
    uint256 weight;
}

interface IPool {
    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeChanged,
        Side _side
    )
        external;

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        Side _side,
        address _receiver
    )
        external;

    function liquidatePosition(address _account, address _indexToken, address _collateralToken, Side _side) external;

    function validateToken(address indexToken, address collateralToken, Side side, bool isIncrease)
        external
        view
        returns (bool);

    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to) external;

    function addLiquidity(address _tranche, address _token, uint256 _amountIn, uint256 _minLpAmount, address _to)
        external
        payable;

    // =========== EVENTS ===========
    event SetOrderManager(address orderManager);
    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralValue,
        uint256 sizeChanged,
        Side side,
        uint256 indexPrice,
        uint256 feeValue
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount,
        uint256 indexPrice
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralChanged,
        uint256 sizeChanged,
        Side side,
        uint256 indexPrice,
        SignedInt pnl,
        uint256 feeValue
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        Side side,
        uint256 size,
        uint256 collateralValue,
        uint256 reserveAmount,
        uint256 indexPrice,
        SignedInt pnl,
        uint256 feeValue
    );
    event DaoFeeWithdrawn(address token, address recipient, uint256 amount);
    event DaoFeeReduced(address token, uint256 amount);
    event FeeDistributorSet(address feeDistributor);
    event LiquidityAdded(
        address indexed tranche, address indexed sender, address token, uint256 amount, uint256 lpAmount, uint256 fee
    );
    event LiquidityRemoved(
        address indexed tranche, address indexed sender, address token, uint256 lpAmount, uint256 amountOut, uint256 fee
    );
    event TokenWeightSet(TokenWeight[]);
    event Swap(address sender, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 fee);
    event PositionFeeSet(uint256 positionFee, uint256 liquidationFee);
    event DaoFeeSet(uint256 value);
    event SwapFeeSet(
        uint256 baseSwapFee, uint256 taxBasisPoint, uint256 stableCoinBaseSwapFee, uint256 stableCoinTaxBasisPoint
    );
    event InterestAccrued(address token, uint256 borrowIndex);
    event MaxLeverageChanged(uint256 maxLeverage);
    event TokenWhitelisted(address token);
    event OracleChanged(address oldOracle, address newOracle);
    event InterestRateSet(uint256 interestRate, uint256);
    event MaxPositionSizeSet(uint256 maxPositionSize);
    event PositionHookChanged(address hook);
    event TrancheAdded(address lpToken);
    event TokenRiskFactorUpdated(address token);
    event PnLDistributed(address indexed asset, address indexed tranche, uint256 amount, bool hasProfit);
}

pragma solidity 0.8.15;

import {Side, IPool} from "./IPool.sol";

interface IPositionHook {
    function preIncreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes calldata extradata
    ) external;

    function postIncreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes calldata extradata
    ) external;

    function preDecreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes calldata extradata
    ) external;

    function postDecreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes calldata extradata
    ) external;

    event PreIncreasePositionExecuted(
        address pool,
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes extradata
    );
    event PostIncreasePositionExecuted(
        address pool,
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes extradata
    );
    event PreDecreasePositionExecuted(
        address pool,
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes extradata
    );
    event PostDecreasePositionExecuted(
        address pool,
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes extradata
    );
}

pragma solidity >=0.8.0;

library MathUtils {
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function zeroCapSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    function frac(uint256 amount, uint256 num, uint256 denom) internal pure returns (uint256) {
        return amount * num / denom;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: UNLCIENSED

pragma solidity >=0.8.0;

import {Side} from "../interfaces/IPool.sol";
import {SignedInt, SignedIntOps} from "./SignedInt.sol";

library PositionUtils {
    using SignedIntOps for SignedInt;

    function calcPnl(Side _side, uint256 _positionSize, uint256 _entryPrice, uint256 _indexPrice)
        internal
        pure
        returns (SignedInt memory)
    {
        if (_positionSize == 0) {
            return SignedIntOps.wrap(uint256(0));
        }
        if (_side == Side.LONG) {
            return SignedIntOps.wrap(_indexPrice).sub(_entryPrice).mul(_positionSize).div(_entryPrice);
        } else {
            return SignedIntOps.wrap(_entryPrice).sub(_indexPrice).mul(_positionSize).div(_entryPrice);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

uint256 constant POS = 1;
uint256 constant NEG = 0;

/// SignedInt is integer number with sign. It value range is -(2 ^ 256 - 1) to (2 ^ 256 - 1)
struct SignedInt {
    /// @dev sig = 1 -> positive, sig = 0 is negative
    /// using uint256 which take up full word to optimize gas and contract size
    uint256 sig;
    uint256 abs;
}

library SignedIntOps {
    function add(SignedInt memory a, SignedInt memory b) internal pure returns (SignedInt memory) {
        if (a.sig == b.sig) {
            return SignedInt({sig: a.sig, abs: a.abs + b.abs});
        }

        if (a.abs == b.abs) {
            return SignedInt(0, 0); // always return positive zero
        }

        (uint256 sig, uint256 abs) = a.abs > b.abs ? (a.sig, a.abs - b.abs) : (b.sig, b.abs - a.abs);
        return SignedInt(sig, abs);
    }

    function inv(SignedInt memory a) internal pure returns (SignedInt memory) {
        return a.abs == 0 ? a : (SignedInt({sig: 1 - a.sig, abs: a.abs}));
    }

    function sub(SignedInt memory a, SignedInt memory b) internal pure returns (SignedInt memory) {
        return add(a, inv(b));
    }

    function mul(SignedInt memory a, SignedInt memory b) internal pure returns (SignedInt memory) {
        uint256 sig = (a.sig + b.sig + 1) % 2;
        uint256 abs = a.abs * b.abs;
        return SignedInt(abs == 0 ? POS : sig, abs); // zero is alway positive
    }

    function div(SignedInt memory a, SignedInt memory b) internal pure returns (SignedInt memory) {
        uint256 sig = (a.sig + b.sig + 1) % 2;
        uint256 abs = a.abs / b.abs;
        return SignedInt(sig, abs);
    }

    function add(SignedInt memory a, uint256 b) internal pure returns (SignedInt memory) {
        return add(a, wrap(b));
    }

    function sub(SignedInt memory a, uint256 b) internal pure returns (SignedInt memory) {
        return sub(a, wrap(b));
    }

    function add(SignedInt memory a, int256 b) internal pure returns (SignedInt memory) {
        return add(a, wrap(b));
    }

    function sub(SignedInt memory a, int256 b) internal pure returns (SignedInt memory) {
        return sub(a, wrap(b));
    }

    function mul(SignedInt memory a, uint256 b) internal pure returns (SignedInt memory) {
        return mul(a, wrap(b));
    }

    function mul(SignedInt memory a, int256 b) internal pure returns (SignedInt memory) {
        return mul(a, wrap(b));
    }

    function div(SignedInt memory a, uint256 b) internal pure returns (SignedInt memory) {
        return div(a, wrap(b));
    }

    function div(SignedInt memory a, int256 b) internal pure returns (SignedInt memory) {
        return div(a, wrap(b));
    }

    function wrap(int256 a) internal pure returns (SignedInt memory) {
        return a >= 0 ? SignedInt(POS, uint256(a)) : SignedInt(NEG, uint256(-a));
    }

    function wrap(uint256 a) internal pure returns (SignedInt memory) {
        return SignedInt(POS, a);
    }

    function toUint(SignedInt memory a) internal pure returns (uint256) {
        require(a.sig == POS, "SignedInt: below zero");
        return a.abs;
    }

    function lt(SignedInt memory a, SignedInt memory b) internal pure returns (bool) {
        return a.sig > b.sig || a.abs < b.abs;
    }

    function lt(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return a.sig == NEG || a.abs < b;
    }

    function lt(SignedInt memory a, int256 b) internal pure returns (bool) {
        return lt(a, wrap(b));
    }

    function gt(SignedInt memory a, SignedInt memory b) internal pure returns (bool) {
        return a.sig < b.sig || a.abs > b.abs;
    }

    function gt(SignedInt memory a, int256 b) internal pure returns (bool) {
        return b < 0 || a.abs > uint256(b);
    }

    function gt(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return lt(a, wrap(b));
    }

    function isNeg(SignedInt memory a) internal pure returns (bool) {
        return a.sig == NEG;
    }

    function isPos(SignedInt memory a) internal pure returns (bool) {
        return a.sig == POS;
    }

    function eq(SignedInt memory a, SignedInt memory b) internal pure returns (bool) {
        return a.abs == b.abs && a.sig == b.sig;
    }

    function eq(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return eq(a, wrap(b));
    }

    function eq(SignedInt memory a, int256 b) internal pure returns (bool) {
        return eq(a, wrap(b));
    }

    function frac(SignedInt memory a, uint256 num, uint256 denom) internal pure returns (SignedInt memory) {
        return div(mul(a, num), denom);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

library UniERC20 {
    using SafeERC20 for IERC20;
    /// @notice pseudo address to use inplace of native token
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalance(IERC20 token, address holder)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return holder.balance;
        }
        return token.balanceOf(holder);
    }

    function transferTo(
        IERC20 token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        if (isETH(token)) {
            safeTransferETH(receiver, amount);
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return address(token) == ETH;
    }

    function safeTransferETH(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {SignedInt, SignedIntOps} from "../lib/SignedInt.sol";
import {UniERC20} from "../lib/UniERC20.sol";
import {MathUtils} from "../lib/MathUtils.sol";
import {PositionUtils} from "../lib/PositionUtils.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {IPool, Side, TokenWeight} from "../interfaces/IPool.sol";
import {
    PoolStorage,
    Position,
    PoolTokenInfo,
    Fee,
    AssetInfo,
    INTEREST_RATE_PRECISION,
    FEE_PRECISION,
    LP_INITIAL_PRICE,
    MAX_BASE_SWAP_FEE,
    MAX_TAX_BASIS_POINT,
    MAX_POSITION_FEE
} from "./PoolStorage.sol";
import {PoolErrors} from "./PoolErrors.sol";
import {IPositionHook} from "../interfaces/IPositionHook.sol";

struct IncreasePositionVars {
    uint256 reserveAdded;
    uint256 collateralAmount;
    uint256 collateralValueAdded;
    uint256 feeValue;
    uint256 daoFee;
    uint256 indexPrice;
    uint256 sizeChanged;
}

/// @notice common variable used accross decrease process
struct DecreasePositionVars {
    /// @notice santinized input: collateral value able to be withdraw
    uint256 collateralReduced;
    /// @notice santinized input: position size to decrease, caped to position's size
    uint256 sizeChanged;
    /// @notice current price of index
    uint256 indexPrice;
    /// @notice current price of collateral
    uint256 collateralPrice;
    /// @notice postion's remaining collateral value in USD after decrease position
    uint256 remainingCollateral;
    /// @notice reserve reduced due to reducion process
    uint256 reserveReduced;
    /// @notice total value of fee to be collect (include dao fee and LP fee)
    uint256 feeValue;
    /// @notice amount of collateral taken as fee
    uint256 daoFee;
    /// @notice real transfer out amount to user
    uint256 payout;
    SignedInt pnl;
    SignedInt poolAmountReduced;
}

contract Pool is Initializable, PoolStorage, OwnableUpgradeable, ReentrancyGuardUpgradeable, IPool {
    using SignedIntOps for SignedInt;
    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    /* =========== MODIFIERS ========== */
    modifier onlyOrderManager() {
        _requireOrderManager();
        _;
    }

    modifier onlyAsset(address _token) {
        _validateAsset(_token);
        _;
    }

    modifier onlyListedToken(address _token) {
        _requireListedToken(_token);
        _;
    }

    /* ======== INITIALIZERS ========= */
    function initialize(
        uint256 _maxLeverage,
        uint256 _positionFee,
        uint256 _liquidationFee,
        uint256 _interestRate,
        uint256 _accrualInterval
    )
        external
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        if (_accrualInterval == 0) {
            revert PoolErrors.InvalidInterval();
        }
        if (_maxLeverage == 0) {
            revert PoolErrors.InvalidMaxLeverage();
        }
        maxLeverage = _maxLeverage;
        fee.positionFee = _positionFee;
        fee.liquidationFee = _liquidationFee;
        interestRate = _interestRate;
        accrualInterval = _accrualInterval;
        fee.daoFee = FEE_PRECISION;
    }

    // ========= View functions =========

    function validateToken(address _indexToken, address _collateralToken, Side _side, bool _isIncrease)
        external
        view
        returns (bool)
    {
        return _validateToken(_indexToken, _collateralToken, _side, _isIncrease);
    }

    function getPoolAsset(address _token) external view returns (AssetInfo memory) {
        return _getPoolAsset(_token);
    }

    function getAllTranchesLength() external view returns (uint256) {
        return allTranches.length;
    }

    function getPoolValue() external view returns (uint256) {
        return _getPoolValue();
    }

    function getTrancheValue(address _tranche) external view returns (uint256 sum) {
        if (!isTranche[_tranche]) {
            revert PoolErrors.InvalidTranche(_tranche);
        }
        return _getTrancheValue(_tranche);
    }

    // ============= Mutative functions =============
    function addLiquidity(address _tranche, address _token, uint256 _amountIn, uint256 _minLpAmount, address _to)
        external
        payable
        nonReentrant
        onlyListedToken(_token)
    {
        if (!isTranche[_tranche]) {
            revert PoolErrors.InvalidTranche(_tranche);
        }
        _accrueInterest(_token);
        _amountIn = _transferIn(_token, _amountIn);
        if (_amountIn == 0) {
            revert PoolErrors.ZeroAmount();
        }

        (uint256 amountInAfterFee, uint256 feeAmount, uint256 lpAmount) = _calcAddLiquidity(_tranche, _token, _amountIn);
        if (lpAmount < _minLpAmount) {
            revert PoolErrors.SlippageExceeded();
        }

        poolTokens[_token].feeReserve += feeAmount;
        trancheAssets[_tranche][_token].poolAmount += amountInAfterFee;

        ILPToken(_tranche).mint(_to, lpAmount);
        emit LiquidityAdded(_tranche, msg.sender, _token, _amountIn, lpAmount, feeAmount);
    }

    function removeLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount, uint256 _minOut, address _to)
        external
        nonReentrant
        onlyAsset(_tokenOut)
    {
        if (!isTranche[_tranche]) {
            revert PoolErrors.InvalidTranche(_tranche);
        }
        _accrueInterest(_tokenOut);
        ILPToken lpToken = ILPToken(_tranche);
        if (_lpAmount == 0) {
            revert PoolErrors.ZeroAmount();
        }

        (uint256 outAmount, uint256 outAmountAfterFee, uint256 feeAmount) =
            _calcRemoveLiquidity(_tranche, _tokenOut, _lpAmount);
        if (outAmountAfterFee < _minOut) {
            revert PoolErrors.SlippageExceeded();
        }

        uint256 trancheBalance = trancheAssets[_tranche][_tokenOut].poolAmount;
        if (trancheBalance < outAmount) {
            revert PoolErrors.RemoveLiquidityTooMuch(_tranche, outAmount, trancheBalance);
        }

        poolTokens[_tokenOut].feeReserve += feeAmount;
        _decreaseTranchePoolAmount(_tranche, _tokenOut, outAmountAfterFee);

        lpToken.burnFrom(msg.sender, _lpAmount);
        _doTransferOut(_tokenOut, _to, outAmountAfterFee);
        emit LiquidityRemoved(_tranche, msg.sender, _tokenOut, _lpAmount, outAmountAfterFee, feeAmount);
    }

    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to)
        external
        nonReentrant
        onlyListedToken(_tokenIn)
        onlyListedToken(_tokenOut)
    {
        if (_tokenIn == _tokenOut) {
            revert PoolErrors.SameTokenSwap(_tokenIn);
        }
        _accrueInterest(_tokenIn);
        _accrueInterest(_tokenOut);
        uint256 amountIn = _getAmountIn(_tokenIn);
        if (amountIn == 0) {
            revert PoolErrors.ZeroAmount();
        }
        (uint256 amountOut, uint256 swapFee) = _calcSwapOutput(_tokenIn, _tokenOut, amountIn);
        uint256 amountOutAfterFee = amountOut - swapFee;
        if (amountOutAfterFee < _minOut) {
            revert PoolErrors.SlippageExceeded();
        }
        poolTokens[_tokenOut].feeReserve += swapFee;
        _rebalanceTranches(_tokenIn, amountIn, _tokenOut, amountOutAfterFee);
        _doTransferOut(_tokenOut, _to, amountOutAfterFee);
        emit Swap(msg.sender, _tokenIn, _tokenOut, amountIn, amountOutAfterFee, swapFee);
    }

    function increasePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeChanged,
        Side _side
    )
        external
        onlyOrderManager
    {
        _requireValidTokenPair(_indexToken, _collateralToken, _side, true);
        if (address(positionHook) != address(0)) {
            positionHook.preIncreasePosition(_owner, _indexToken, _collateralToken, _side, _sizeChanged, bytes(""));
        }
        uint256 borrowIndex = _accrueInterest(_collateralToken);
        IncreasePositionVars memory vars;
        bytes32 key = _getPositionKey(_owner, _indexToken, _collateralToken, _side);
        Position memory position = positions[key];
        uint256 collateralPrice = _getPrice(_collateralToken);
        vars.indexPrice = _getPrice(_indexToken);
        vars.collateralAmount = _getAmountIn(_collateralToken);
        if (vars.collateralAmount == 0) {
            revert PoolErrors.ZeroAmount();
        }
        vars.collateralValueAdded = collateralPrice * vars.collateralAmount;
        vars.sizeChanged = _sizeChanged;

        // update position
        vars.feeValue = _calcPositionFee(position, vars.sizeChanged, borrowIndex);
        vars.daoFee = vars.feeValue * fee.daoFee / collateralPrice / FEE_PRECISION;
        vars.reserveAdded = vars.sizeChanged / collateralPrice;
        position.entryPrice =
            _calcAveragePrice(_side, position.size, vars.sizeChanged, position.entryPrice, vars.indexPrice);
        position.collateralValue =
            MathUtils.zeroCapSub(position.collateralValue + vars.collateralValueAdded, vars.feeValue);
        position.size = position.size + vars.sizeChanged;
        position.borrowIndex = borrowIndex;
        position.reserveAmount += vars.reserveAdded;

        _validatePosition(position, _collateralToken, _side, true, vars.indexPrice);

        // upate pool assets
        _reservePoolAsset(key, vars, _indexToken, _collateralToken, _side);
        positions[key] = position;

        emit IncreasePosition(
            key,
            _owner,
            _collateralToken,
            _indexToken,
            vars.collateralAmount,
            vars.sizeChanged,
            _side,
            vars.indexPrice,
            vars.feeValue
            );

        emit UpdatePosition(
            key,
            position.size,
            position.collateralValue,
            position.entryPrice,
            position.borrowIndex,
            position.reserveAmount,
            vars.indexPrice
            );

        if (address(positionHook) != address(0)) {
            positionHook.postIncreasePosition(_owner, _indexToken, _collateralToken, _side, _sizeChanged, bytes(""));
        }
    }

    function decreasePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        uint256 _collateralChanged,
        uint256 _sizeChanged,
        Side _side,
        address _receiver
    )
        external
        onlyOrderManager
    {
        _requireValidTokenPair(_indexToken, _collateralToken, _side, false);
        uint256 borrowIndex = _accrueInterest(_collateralToken);
        bytes32 key = _getPositionKey(_owner, _indexToken, _collateralToken, _side);
        Position memory position = positions[key];

        if (address(positionHook) != address(0)) {
            positionHook.preDecreasePosition(_owner, _indexToken, _collateralToken, _side, _sizeChanged, bytes(""));
        }

        DecreasePositionVars memory vars =
            _calcDecreasePayout(position, _indexToken, _collateralToken, _side, _sizeChanged, _collateralChanged);

        _releasePoolAsset(key, vars, _indexToken, _collateralToken, _side);
        position.size = position.size - vars.sizeChanged;
        position.borrowIndex = borrowIndex;
        position.reserveAmount = position.reserveAmount - vars.reserveReduced;
        // reset to actual reduced value instead of user input
        vars.collateralReduced = position.collateralValue - vars.remainingCollateral;
        position.collateralValue = vars.remainingCollateral;

        _validatePosition(position, _collateralToken, _side, false, vars.indexPrice);

        emit DecreasePosition(
            key,
            _owner,
            _collateralToken,
            _indexToken,
            vars.collateralReduced,
            vars.sizeChanged,
            _side,
            vars.indexPrice,
            vars.pnl,
            vars.feeValue
            );
        if (position.size == 0) {
            emit ClosePosition(
                key,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.borrowIndex,
                position.reserveAmount
                );
            // delete position when closed
            delete positions[key];
        } else {
            emit UpdatePosition(
                key,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.borrowIndex,
                position.reserveAmount,
                vars.indexPrice
                );
            positions[key] = position;
        }
        _doTransferOut(_collateralToken, _receiver, vars.payout);

        if (address(positionHook) != address(0)) {
            positionHook.postDecreasePosition(_owner, _indexToken, _collateralToken, _side, _sizeChanged, bytes(""));
        }
    }

    function liquidatePosition(address _account, address _indexToken, address _collateralToken, Side _side) external {
        _requireValidTokenPair(_indexToken, _collateralToken, _side, false);
        _accrueInterest(_collateralToken);
        bytes32 key = _getPositionKey(_account, _indexToken, _collateralToken, _side);
        Position memory position = positions[key];
        if (address(positionHook) != address(0)) {
            positionHook.preDecreasePosition(_account, _indexToken, _collateralToken, _side, position.size, bytes(""));
        }
        DecreasePositionVars memory vars =
            _calcDecreasePayout(position, _indexToken, _collateralToken, _side, position.size, position.collateralValue);

        if (vars.remainingCollateral > fee.liquidationFee) {
            revert PoolErrors.PositionNotLiquidated(key);
        }
        uint256 liquidationFee = fee.liquidationFee / vars.collateralPrice;
        vars.poolAmountReduced = vars.poolAmountReduced.add(liquidationFee);
        _releasePoolAsset(key, vars, _indexToken, _collateralToken, _side);

        emit LiquidatePosition(
            key,
            _account,
            _collateralToken,
            _indexToken,
            _side,
            position.size,
            position.collateralValue - vars.remainingCollateral,
            position.reserveAmount,
            vars.indexPrice,
            vars.pnl,
            vars.feeValue
            );

        delete positions[key];
        _doTransferOut(_collateralToken, msg.sender, liquidationFee);

        if (address(positionHook) != address(0)) {
            positionHook.postDecreasePosition(_account, _indexToken, _collateralToken, _side, position.size, bytes(""));
        }
    }

    // ========= ADMIN FUNCTIONS ========
    function addTranche(address _tranche) external onlyOwner {
        if (_tranche == address(0)) {
            revert PoolErrors.ZeroAddress();
        }
        if (isTranche[_tranche]) {
            revert PoolErrors.TrancheAlreadyAdded(_tranche);
        }
        isTranche[_tranche] = true;
        allTranches.push(_tranche);
        emit TrancheAdded(_tranche);
    }

    struct RiskConfig {
        address tranche;
        uint256 riskFactor;
    }

    function setRiskFactor(address _token, RiskConfig[] memory _config) external onlyOwner onlyAsset(_token) {
        uint256 total = totalRiskFactor[_token];
        for (uint256 i = 0; i < _config.length; i++) {
            (address tranche, uint256 factor) = (_config[i].tranche, _config[i].riskFactor);
            if (!isTranche[tranche]) {
                revert PoolErrors.InvalidTranche(tranche);
            }
            total = total + factor - riskFactor[_token][tranche];
            riskFactor[_token][tranche] = factor;
        }
        totalRiskFactor[_token] = total;
        emit TokenRiskFactorUpdated(_token);
    }

    function addToken(address _token, bool _isStableCoin) external onlyOwner {
        if (isAsset[_token]) {
            revert PoolErrors.DuplicateToken(_token);
        }
        isAsset[_token] = true;
        isListed[_token] = true;
        allAssets.push(_token);
        isStableCoin[_token] = _isStableCoin;
        emit TokenWhitelisted(_token);
    }

    function delistToken(address _token) external onlyOwner {
        if (!isListed[_token]) {
            revert PoolErrors.TokenNotListed(_token);
        }
        isListed[_token] = false;
        uint256 weight = targetWeights[_token];
        totalWeight -= weight;
        targetWeights[_token] = 0;
        emit TokenWhitelisted(_token);
    }

    function setMaxLeverage(uint256 _maxLeverage) external onlyOwner {
        if (_maxLeverage == 0) {
            revert PoolErrors.InvalidMaxLeverage();
        }
        maxLeverage = _maxLeverage;
        emit MaxLeverageChanged(_maxLeverage);
    }

    function setOracle(address _oracle) external onlyOwner {
        if (_oracle == address(0)) {
            revert PoolErrors.ZeroAddress();
        }
        address oldOracle = address(oracle);
        oracle = IOracle(_oracle);
        emit OracleChanged(oldOracle, _oracle);
    }

    function setSwapFee(
        uint256 _baseSwapFee,
        uint256 _taxBasisPoint,
        uint256 _stableCoinBaseSwapFee,
        uint256 _stableCoinTaxBasisPoint
    )
        external
        onlyOwner
    {
        _validateMaxValue(_baseSwapFee, MAX_BASE_SWAP_FEE);
        _validateMaxValue(_stableCoinBaseSwapFee, MAX_BASE_SWAP_FEE);
        _validateMaxValue(_taxBasisPoint, MAX_TAX_BASIS_POINT);
        _validateMaxValue(_stableCoinTaxBasisPoint, MAX_TAX_BASIS_POINT);
        fee.baseSwapFee = _baseSwapFee;
        fee.taxBasisPoint = _taxBasisPoint;
        fee.stableCoinBaseSwapFee = _stableCoinBaseSwapFee;
        fee.stableCoinTaxBasisPoint = _stableCoinTaxBasisPoint;
        emit SwapFeeSet(_baseSwapFee, _taxBasisPoint, _stableCoinBaseSwapFee, _stableCoinTaxBasisPoint);
    }

    function setPositionFee(uint256 _positionFee, uint256 _liquidationFee) external onlyOwner {
        _validateMaxValue(_positionFee, MAX_POSITION_FEE);
        fee.positionFee = _positionFee;
        fee.liquidationFee = _liquidationFee;
        emit PositionFeeSet(_positionFee, _liquidationFee);
    }

    function setDaoFee(uint256 _daoFee) external onlyOwner {
        _validateMaxValue(_daoFee, FEE_PRECISION);
        fee.daoFee = _daoFee;
        emit DaoFeeSet(_daoFee);
    }

    function setInterestRate(uint256 _interestRate, uint256 _accrualInterval) external onlyOwner {
        if (_accrualInterval == 0) {
            revert PoolErrors.InvalidInterval();
        }
        interestRate = _interestRate;
        accrualInterval = _accrualInterval;
        emit InterestRateSet(_interestRate, _accrualInterval);
    }

    function setOrderManager(address _orderManager) external onlyOwner {
        if (_orderManager == address(0)) {
            revert PoolErrors.ZeroAddress();
        }
        orderManager = _orderManager;
        emit SetOrderManager(_orderManager);
    }

    function withdrawFee(address _token, address _recipient) external onlyAsset(_token) {
        _validateFeeDistributor();
        uint256 amount = poolTokens[_token].feeReserve;
        poolTokens[_token].feeReserve = 0;
        _doTransferOut(_token, _recipient, amount);
        emit DaoFeeWithdrawn(_token, _recipient, amount);
    }

    /// @notice reduce DAO fee by distributing to pool amount;
    function reduceDaoFee(address _token, uint256 _amount) public onlyAsset(_token) {
        _validateFeeDistributor();
        _amount = MathUtils.min(_amount, poolTokens[_token].feeReserve);
        uint256[] memory shares = _calcTrancheSharesAmount(_token, _amount, false);
        for (uint256 i = 0; i < shares.length; i++) {
            address tranche = allTranches[i];
            trancheAssets[tranche][_token].poolAmount += shares[i];
        }
        poolTokens[_token].feeReserve -= _amount;
        emit DaoFeeReduced(_token, _amount);
    }

    function setFeeDistributor(address _feeDistributor) external onlyOwner {
        if (_feeDistributor == address(0)) {
            revert PoolErrors.ZeroAddress();
        }
        feeDistributor = _feeDistributor;
        emit FeeDistributorSet(feeDistributor);
    }

    function setTargetWeight(TokenWeight[] memory tokens) external onlyOwner {
        if (tokens.length != allAssets.length) {
            revert PoolErrors.RequireAllTokens();
        }
        uint256 total = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            TokenWeight memory item = tokens[i];
            assert(isAsset[item.token]);
            // unlisted token always has zero weight
            uint256 weight = isListed[item.token] ? item.weight : 0;
            targetWeights[item.token] = weight;
            total += weight;
        }
        totalWeight = total;
        emit TokenWeightSet(tokens);
    }

    function setMaxPositionSize(uint256 _maxSize) external onlyOwner {
        maxPositionSize = _maxSize;
        emit MaxPositionSizeSet(_maxSize);
    }

    function setPositionHook(address _hook) external onlyOwner {
        positionHook = IPositionHook(_hook);
        emit PositionHookChanged(_hook);
    }

    receive() external payable onlyOrderManager {}

    // ======== internal functions =========
    function _validateToken(address _indexToken, address _collateralToken, Side _side, bool _isIncrease)
        internal
        view
        returns (bool)
    {
        if (!isAsset[_indexToken] || !isAsset[_collateralToken]) {
            return false;
        }

        if (_isIncrease && !isListed[_indexToken]) {
            return false;
        }

        if (_side == Side.LONG) {
            return _indexToken == _collateralToken;
        }
        return isStableCoin[_collateralToken];
    }

    function _calcAddLiquidity(address _tranche, address _token, uint256 _amountIn)
        internal
        view
        returns (uint256 amountInAfterFee, uint256 feeAmount, uint256 lpAmount)
    {
        uint256 tokenPrice = _getPrice(_token);
        uint256 poolValue = _getTrancheValue(_tranche);
        uint256 valueChange = _amountIn * tokenPrice;
        uint256 _fee = _calcAdjustedFee(poolValue, _token, tokenPrice, valueChange, true);
        amountInAfterFee = (_amountIn * (FEE_PRECISION - _fee)) / FEE_PRECISION;
        feeAmount = _amountIn - amountInAfterFee;

        uint256 lpSupply = ILPToken(_tranche).totalSupply();
        if (lpSupply == 0 || poolValue == 0) {
            lpAmount = (_amountIn * tokenPrice) / LP_INITIAL_PRICE;
        } else {
            lpAmount = (amountInAfterFee * tokenPrice * lpSupply) / poolValue;
        }
    }

    function _calcRemoveLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount)
        internal
        view
        returns (uint256 outAmount, uint256 outAmountAfterFee, uint256 feeAmount)
    {
        uint256 tokenPrice = _getPrice(_tokenOut);
        uint256 poolValue = _getTrancheValue(_tranche);
        uint256 totalSupply = ILPToken(_tranche).totalSupply();
        uint256 valueChange = (_lpAmount * poolValue) / totalSupply;
        uint256 _fee = _calcAdjustedFee(poolValue, _tokenOut, tokenPrice, valueChange, false);
        outAmount = (_lpAmount * poolValue) / totalSupply / tokenPrice;
        outAmountAfterFee = ((FEE_PRECISION - _fee) * outAmount) / FEE_PRECISION;
        feeAmount = outAmount - outAmountAfterFee;
    }

    function _transferIn(address _token, uint256 _amount) internal returns (uint256) {
        if (_token != UniERC20.ETH) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        } else if (msg.value != _amount) {
            revert PoolErrors.InvalidTransferInAmount(_amount, msg.value);
        }
        return _getAmountIn(_token);
    }

    function _calcSwapOutput(address _tokenIn, address _tokenOut, uint256 _amountIn)
        internal
        view
        returns (uint256 amountOut, uint256 feeAmount)
    {
        uint256 priceIn = _getPrice(_tokenIn);
        uint256 priceOut = _getPrice(_tokenOut);
        uint256 valueChange = _amountIn * priceIn;
        uint256 poolValue = _getPoolValue();
        uint256 feeIn = _calcAdjustedFee(poolValue, _tokenIn, priceIn, valueChange, true);
        uint256 feeOut = _calcAdjustedFee(poolValue, _tokenOut, priceOut, valueChange, false);
        uint256 _fee = feeIn > feeOut ? feeIn : feeOut;

        amountOut = valueChange / priceOut;
        feeAmount = (valueChange * _fee) / priceOut / FEE_PRECISION;
    }

    function _getPositionKey(address _owner, address _indexToken, address _collateralToken, Side _side)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_owner, _indexToken, _collateralToken, _side));
    }

    function _validatePosition(
        Position memory _position,
        address _collateralToken,
        Side _side,
        bool _isIncrease,
        uint256 _indexPrice
    )
        internal
        view
    {
        if ((_isIncrease && _position.size == 0) || (maxPositionSize > 0 && _position.size > maxPositionSize)) {
            revert PoolErrors.InvalidPositionSize();
        }

        uint256 borrowIndex = poolTokens[_collateralToken].borrowIndex;
        if (_position.size < _position.collateralValue || _position.size > _position.collateralValue * maxLeverage) {
            revert PoolErrors.InvalidLeverage(_position.size, _position.collateralValue, maxLeverage);
        }
        if (_liquidatePositionAllowed(_position, _side, _indexPrice, borrowIndex)) {
            revert PoolErrors.UpdateCauseLiquidation();
        }
    }

    function _requireValidTokenPair(address _indexToken, address _collateralToken, Side _side, bool _isIncrease)
        internal
        view
    {
        if (!_validateToken(_indexToken, _collateralToken, _side, _isIncrease)) {
            revert PoolErrors.InvalidTokenPair(_indexToken, _collateralToken);
        }
    }

    function _validateAsset(address _token) internal view {
        if (!isAsset[_token]) {
            revert PoolErrors.UnknownToken(_token);
        }
    }

    function _requireListedToken(address _token) internal view {
        if (!isListed[_token]) {
            revert PoolErrors.AssetNotListed(_token);
        }
    }

    function _requireOrderManager() internal view {
        if (msg.sender != orderManager) {
            revert PoolErrors.OrderManagerOnly();
        }
    }

    function _validateFeeDistributor() internal view {
        if (msg.sender != feeDistributor) {
            revert PoolErrors.FeeDistributorOnly();
        }
    }

    function _validateMaxValue(uint256 _input, uint256 _max) internal pure {
        if (_input > _max) {
            revert PoolErrors.ValueTooHigh(_max);
        }
    }

    function _getAmountIn(address _token) internal returns (uint256 amount) {
        uint256 balance = IERC20(_token).getBalance(address(this));
        amount = balance - poolTokens[_token].poolBalance;
        poolTokens[_token].poolBalance = balance;
    }

    function _doTransferOut(address _token, address _to, uint256 _amount) internal {
        if (_amount > 0) {
            IERC20 token = IERC20(_token);
            token.transferTo(_to, _amount);
            poolTokens[_token].poolBalance = token.getBalance(address(this));
        }
    }

    function _accrueInterest(address _token) internal returns (uint256) {
        PoolTokenInfo memory tokenInfo = poolTokens[_token];
        AssetInfo memory asset = _getPoolAsset(_token);
        uint256 _now = block.timestamp;
        if (tokenInfo.lastAccrualTimestamp == 0) {
            // accrue interest for the first time
            tokenInfo.lastAccrualTimestamp = (_now / accrualInterval) * accrualInterval;
        } else {
            uint256 nInterval = (_now - tokenInfo.lastAccrualTimestamp) / accrualInterval;
            if (nInterval == 0) {
                return tokenInfo.borrowIndex;
            }

            tokenInfo.borrowIndex += (nInterval * interestRate * asset.reservedAmount) / asset.poolAmount;
            tokenInfo.lastAccrualTimestamp += nInterval * accrualInterval;
        }

        poolTokens[_token] = tokenInfo;
        emit InterestAccrued(_token, tokenInfo.borrowIndex);
        return tokenInfo.borrowIndex;
    }

    /// @notice calculate adjusted fee rate
    /// fee is increased or decreased based on action's effect to pool amount
    /// each token has their target weight set by gov
    /// if action make the weight of token far from its target, fee will be increase, vice versa
    function _calcAdjustedFee(
        uint256 _poolValue,
        address _token,
        uint256 _tokenPrice,
        uint256 _valueChange,
        bool _isSwapIn
    )
        internal
        view
        returns (uint256)
    {
        if (_poolValue == 0) {
            return 0;
        }
        uint256 targetValue = (targetWeights[_token] * _poolValue) / totalWeight;
        uint256 currentValue = _tokenPrice * poolTokens[_token].poolBalance;
        if (currentValue == 0) {
            return 0;
        }
        uint256 nextValue = _isSwapIn ? currentValue + _valueChange : currentValue - _valueChange;
        (uint256 baseSwapFee, uint256 taxBasisPoint) =
            isStableCoin[_token]
            ? (fee.stableCoinBaseSwapFee, fee.stableCoinTaxBasisPoint)
            : (fee.baseSwapFee, fee.taxBasisPoint);
        return _calcAdjustedFee(targetValue, currentValue, nextValue, baseSwapFee, taxBasisPoint);
    }

    function _calcAdjustedFee(
        uint256 _targetValue,
        uint256 _currentValue,
        uint256 _nextValue,
        uint256 _baseSwapFee,
        uint256 _taxBasisPoint
    )
        internal
        pure
        returns (uint256)
    {
        if (_currentValue == 0) {
            return 0;
        } // no fee on initial deposit
        uint256 initDiff = MathUtils.diff(_currentValue, _targetValue);
        uint256 nextDiff = MathUtils.diff(_nextValue, _targetValue);
        if (nextDiff < initDiff) {
            uint256 feeAdjust = _targetValue > 0 ? (_taxBasisPoint * initDiff) / _targetValue : _baseSwapFee;
            return _baseSwapFee > feeAdjust ? _baseSwapFee - feeAdjust : 0;
        } else {
            uint256 avgDiff = (initDiff + nextDiff) / 2;
            uint256 feeAdjust =
                (_targetValue == 0 || avgDiff > _targetValue) ? _taxBasisPoint : (_taxBasisPoint * avgDiff) / _targetValue;
            return _baseSwapFee + feeAdjust;
        }
    }

    /// @notice calculate new avg entry price when increase position
    /// @dev for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    ///      for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function _calcAveragePrice(
        Side _side,
        uint256 _lastSize,
        uint256 _increasedSize,
        uint256 _entryPrice,
        uint256 _nextPrice
    )
        internal
        pure
        returns (uint256)
    {
        if (_lastSize == 0) {
            return _nextPrice;
        }
        SignedInt memory pnl = PositionUtils.calcPnl(_side, _lastSize, _entryPrice, _nextPrice);
        SignedInt memory nextSize = SignedIntOps.wrap(_lastSize + _increasedSize);
        SignedInt memory divisor = _side == Side.LONG ? nextSize.add(pnl) : nextSize.sub(pnl);
        return nextSize.mul(_nextPrice).div(divisor).toUint();
    }

    function _getPoolValue() internal view returns (uint256 sum) {
        sum = 0;
        for (uint256 i = 0; i < allTranches.length; i++) {
            sum += _getTrancheValue(allTranches[i]);
        }
    }

    function _getTrancheValue(address _tranche) internal view returns (uint256 sum) {
        SignedInt memory aum = SignedIntOps.wrap(uint256(0));

        for (uint256 i = 0; i < allAssets.length; i++) {
            address token = allAssets[i];
            assert(isAsset[token]); // double check
            AssetInfo memory asset = trancheAssets[_tranche][token];
            uint256 price = _getPrice(token);
            if (isStableCoin[token]) {
                aum = aum.add(price * asset.poolAmount);
            } else {
                aum = aum.add(_calcManagedValue(token, asset, price));
            }
        }

        // aum MUST not be negative. If it is, please debug
        return aum.toUint();
    }

    function _calcManagedValue(address _token, AssetInfo memory _asset, uint256 _price)
        internal
        view
        returns (SignedInt memory aum)
    {
        uint256 averageShortPrice = poolTokens[_token].averageShortPrice;
        SignedInt memory shortPnl =
            _asset.totalShortSize == 0
            ? SignedIntOps.wrap(uint256(0))
            : SignedIntOps.wrap(averageShortPrice).sub(_price).mul(_asset.totalShortSize).div(averageShortPrice);

        aum = SignedIntOps.wrap(_asset.poolAmount).sub(_asset.reservedAmount).mul(_price).add(_asset.guaranteedValue);
        aum = aum.sub(shortPnl);
    }

    function _decreaseTranchePoolAmount(address _tranche, address _token, uint256 _amount) internal {
        AssetInfo memory asset = trancheAssets[_tranche][_token];
        asset.poolAmount -= _amount;
        if (asset.poolAmount < asset.reservedAmount) {
            revert PoolErrors.InsufficientPoolAmount(_token);
        }
        trancheAssets[_tranche][_token] = asset;
    }

    /// @notice return pseudo pool asset by sum all tranches asset
    function _getPoolAsset(address _token) internal view returns (AssetInfo memory asset) {
        for (uint256 i = 0; i < allTranches.length; i++) {
            address tranche = allTranches[i];
            asset.poolAmount += trancheAssets[tranche][_token].poolAmount;
            asset.reservedAmount += trancheAssets[tranche][_token].reservedAmount;
            asset.totalShortSize += trancheAssets[tranche][_token].totalShortSize;
            asset.guaranteedValue += trancheAssets[tranche][_token].guaranteedValue;
        }
    }

    /// @notice reserve asset when open position
    function _reservePoolAsset(
        bytes32 _key,
        IncreasePositionVars memory _vars,
        address _indexToken,
        address _collateralToken,
        Side _side
    )
        internal
    {
        AssetInfo memory collateral = _getPoolAsset(_collateralToken);
        AssetInfo memory indexAsset = _getPoolAsset(_indexToken);

        if (collateral.reservedAmount + _vars.reserveAdded > collateral.poolAmount) {
            revert PoolErrors.InsufficientPoolAmount(_collateralToken);
        }

        poolTokens[_collateralToken].feeReserve += _vars.daoFee;
        _reserveTrancheAsset(_key, _vars, _indexToken, _collateralToken, _side);

        if (_side == Side.SHORT) {
            // recalculate total short position
            uint256 lastSize = indexAsset.totalShortSize;
            uint256 entryPrice = poolTokens[_indexToken].averageShortPrice;
            poolTokens[_indexToken].averageShortPrice =
                _calcAveragePrice(Side.SHORT, lastSize, _vars.sizeChanged, entryPrice, _vars.indexPrice);
        }
    }

    /// @notice release asset and take or distribute realized PnL when close position
    function _releasePoolAsset(
        bytes32 _key,
        DecreasePositionVars memory _vars,
        address _indexToken,
        address _collateralToken,
        Side _side
    )
        internal
    {
        AssetInfo memory collateral = _getPoolAsset(_collateralToken);

        if (collateral.reservedAmount < _vars.reserveReduced) {
            revert PoolErrors.ReserveReduceTooMuch(_collateralToken);
        }

        poolTokens[_collateralToken].feeReserve += _vars.daoFee;
        _releaseTranchesAsset(_key, _vars, _indexToken, _collateralToken, _side);
    }

    function _reserveTrancheAsset(
        bytes32 _key,
        IncreasePositionVars memory _vars,
        address _indexToken,
        address _collateralToken,
        Side _side
    )
        internal
    {
        uint256[] memory shares;
        uint256 totalShare;
        if (_vars.reserveAdded > 0) {
            totalShare = _vars.reserveAdded;
            shares = _calcTrancheSharesAmount(_collateralToken, _vars.reserveAdded, false);
        } else {
            totalShare = _vars.collateralAmount;
            shares = _calcTrancheSharesAmount(_collateralToken, _vars.collateralAmount, true);
        }

        for (uint256 i = 0; i < shares.length; i++) {
            address tranche = allTranches[i];
            uint256 share = shares[i];

            AssetInfo storage collateral = trancheAssets[tranche][_collateralToken];
            AssetInfo storage indexAsset = trancheAssets[tranche][_indexToken];

            uint256 reserveAmount = MathUtils.frac(_vars.reserveAdded, share, totalShare);
            tranchePositionReserves[tranche][_key] += reserveAmount;
            collateral.reservedAmount += reserveAmount;

            if (_side == Side.LONG) {
                collateral.poolAmount = collateral.poolAmount
                    + MathUtils.frac(_vars.collateralAmount, share, totalShare)
                    - MathUtils.frac(_vars.daoFee, share, totalShare);
                // ajust guaranteed
                collateral.guaranteedValue = collateral.guaranteedValue
                    + MathUtils.frac(_vars.sizeChanged + _vars.feeValue, share, totalShare)
                    - MathUtils.frac(_vars.collateralValueAdded, share, totalShare);
            } else {
                // recalculate total short position
                indexAsset.totalShortSize += MathUtils.frac(_vars.sizeChanged, share, totalShare);
            }
        }
    }

    function _releaseTranchesAsset(
        bytes32 _key,
        DecreasePositionVars memory _vars,
        address _indexToken,
        address _collateralToken,
        Side _side
    )
        internal
    {
        uint256 totalShare = positions[_key].reserveAmount;

        for (uint256 i = 0; i < allTranches.length; i++) {
            address tranche = allTranches[i];
            uint256 share = tranchePositionReserves[tranche][_key];
            AssetInfo storage collateral = trancheAssets[tranche][_collateralToken];
            AssetInfo storage indexAsset = trancheAssets[tranche][_indexToken];

            {
                uint256 reserveReduced = MathUtils.frac(_vars.reserveReduced, share, totalShare);
                tranchePositionReserves[tranche][_key] -= reserveReduced;
                collateral.reservedAmount -= reserveReduced;
            }
            collateral.poolAmount =
                SignedIntOps.wrap(collateral.poolAmount).sub(_vars.poolAmountReduced.frac(share, totalShare)).toUint();

            if (_side == Side.LONG) {
                collateral.guaranteedValue =
                    collateral.guaranteedValue + MathUtils.frac(_vars.collateralReduced, share, totalShare);
                collateral.guaranteedValue =
                    collateral.guaranteedValue < MathUtils.frac(_vars.sizeChanged, share, totalShare)
                    ? 0
                    : collateral.guaranteedValue - MathUtils.frac(_vars.sizeChanged, share, totalShare);
            } else {
                // fix rounding error when increase total short size
                indexAsset.totalShortSize =
                    MathUtils.zeroCapSub(indexAsset.totalShortSize, MathUtils.frac(_vars.sizeChanged, share, totalShare));
            }
            emit PnLDistributed(_collateralToken, tranche, _vars.pnl.frac(share, totalShare).abs, _vars.pnl.isPos());
        }
    }

    /// @notice distributed amount of token to all tranches
    /// @param _isIncreasePoolAmount set to true when "increase pool amount" or "decrease reserve amount"
    function _calcTrancheSharesAmount(address _token, uint256 _amount, bool _isIncreasePoolAmount)
        internal
        view
        returns (uint256[] memory reserves)
    {
        uint256 nTranches = allTranches.length;
        reserves = new uint[](nTranches);
        uint256[] memory factors = new uint[](nTranches);
        uint256[] memory maxShare = new uint[](nTranches);

        for (uint256 i = 0; i < nTranches; i++) {
            address tranche = allTranches[i];
            AssetInfo memory asset = trancheAssets[tranche][_token];
            factors[i] = riskFactor[_token][tranche];
            maxShare[i] = _isIncreasePoolAmount ? type(uint256).max : asset.poolAmount - asset.reservedAmount;
        }

        uint256 totalFactor = totalRiskFactor[_token];

        for (uint256 k = 0; k < nTranches; k++) {
            uint256 remaining = _amount; // amount distributed in this round

            uint256 totalRiskFactor_ = totalFactor;
            for (uint256 i = 0; i < nTranches; i++) {
                uint256 riskFactor_ = factors[i];
                uint256 shareAmount = MathUtils.frac(remaining, riskFactor_, totalRiskFactor_);
                uint256 availableAmount = maxShare[i] - reserves[i];
                if (shareAmount >= availableAmount) {
                    // skip this tranche on next rounds since it's full
                    shareAmount = availableAmount;
                    totalFactor -= riskFactor_;
                    factors[i] = 0;
                }

                reserves[i] += shareAmount;
                _amount -= shareAmount;
                remaining -= shareAmount;
                totalRiskFactor_ -= riskFactor_;
                if (remaining == 0) {
                    return reserves;
                }
            }
        }

        if (_amount > 0) {
            revert PoolErrors.CannotDistributeToTranches(_token, _amount, _isIncreasePoolAmount);
        }
    }

    /// @notice rebalance fund between tranches after swap token
    function _rebalanceTranches(address _tokenIn, uint256 _amountIn, address _tokenOut, uint256 _amountOut) internal {
        uint256[] memory shares;
        shares = _calcTrancheSharesAmount(_tokenIn, _amountIn, true);
        for (uint256 i = 0; i < shares.length; i++) {
            address tranche = allTranches[i];
            trancheAssets[tranche][_tokenIn].poolAmount += shares[i];
        }

        shares = _calcTrancheSharesAmount(_tokenOut, _amountOut, false);
        for (uint256 i = 0; i < shares.length; i++) {
            address tranche = allTranches[i];
            // always safe
            trancheAssets[tranche][_tokenOut].poolAmount -= shares[i];
        }
    }

    function _liquidatePositionAllowed(Position memory _position, Side _side, uint256 _indexPrice, uint256 _borrowIndex)
        internal
        view
        returns (bool allowed)
    {
        if (_position.size == 0) {
            return false;
        }
        // calculate fee needed when close position
        uint256 feeValue = _calcPositionFee(_position, _position.size, _borrowIndex);
        feeValue = feeValue + fee.liquidationFee;
        SignedInt memory pnl = PositionUtils.calcPnl(_side, _position.size, _position.entryPrice, _indexPrice);
        SignedInt memory remainingCollateral = pnl.add(_position.collateralValue).sub(feeValue);
        return !remainingCollateral.isPos() || remainingCollateral.abs * maxLeverage < _position.size;
    }

    function _calcDecreasePayout(
        Position memory _position,
        address _indexToken,
        address _collateralToken,
        Side _side,
        uint256 _sizeChanged,
        uint256 _collateralChanged
    )
        internal
        view
        returns (DecreasePositionVars memory vars)
    {
        // clean user input
        vars.sizeChanged = _position.size < _sizeChanged ? _position.size : _sizeChanged;
        vars.collateralReduced =
            _position.collateralValue < _collateralChanged || _position.size == _sizeChanged
            ? _position.collateralValue
            : _collateralChanged;

        vars.indexPrice = _getPrice(_indexToken);
        vars.collateralPrice = _getPrice(_collateralToken);

        uint256 borrowIndex = poolTokens[_collateralToken].borrowIndex;

        // vars is santinized, only trust these value from now on
        vars.reserveReduced = (_position.reserveAmount * vars.sizeChanged) / _position.size;
        vars.pnl = PositionUtils.calcPnl(_side, vars.sizeChanged, _position.entryPrice, vars.indexPrice);
        vars.feeValue = _calcPositionFee(_position, vars.sizeChanged, borrowIndex);
        vars.daoFee = vars.feeValue * fee.daoFee / vars.collateralPrice / FEE_PRECISION;

        SignedInt memory remainingCollateral = SignedIntOps.wrap(_position.collateralValue).sub(vars.collateralReduced);
        SignedInt memory payoutValue = vars.pnl.add(vars.collateralReduced).sub(vars.feeValue);
        if (payoutValue.isNeg()) {
            // deduct uncovered lost from collateral
            remainingCollateral = remainingCollateral.add(payoutValue);
            payoutValue = SignedIntOps.wrap(uint256(0));
        }

        vars.remainingCollateral = remainingCollateral.isNeg() ? 0 : remainingCollateral.abs;
        vars.payout = payoutValue.isNeg() ? 0 : payoutValue.abs / vars.collateralPrice;
        SignedInt memory poolValueReduced = _side == Side.LONG ? payoutValue.add(vars.feeValue) : vars.pnl;
        vars.poolAmountReduced = poolValueReduced.div(vars.collateralPrice);
    }

    function _calcPositionFee(Position memory _position, uint256 _sizeChanged, uint256 _borrowIndex)
        internal
        view
        returns (uint256 feeValue)
    {
        uint256 borrowFee = ((_borrowIndex - _position.borrowIndex) * _position.size) / INTEREST_RATE_PRECISION;
        uint256 positionFee = (_sizeChanged * fee.positionFee) / FEE_PRECISION;
        feeValue = borrowFee + positionFee;
    }

    function _getPrice(address _token) internal view returns (uint256) {
        return oracle.getPrice(_token);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

library PoolErrors {
    error UpdateCauseLiquidation();
    error InvalidTokenPair(address index, address collateral);
    error InvalidLeverage(uint256 size, uint256 margin, uint256 maxLeverage);
    error InvalidPositionSize();
    error OrderManagerOnly();
    error UnknownToken(address token);
    error AssetNotListed(address token);
    error InsufficientPoolAmount(address token);
    error ReserveReduceTooMuch(address token);
    error InvalidTransferInAmount(uint256 expected, uint256 actual);
    error SlippageExceeded();
    error ValueTooHigh(uint256 maxValue);
    error InvalidInterval();
    error PositionNotLiquidated(bytes32 key);
    error RedeemDelayed();
    error ZeroAmount();
    error ZeroAddress();
    error RequireAllTokens();
    error DuplicateToken(address token);
    error TokenNotListed(address token);
    error FeeDistributorOnly();
    error InvalidMaxLeverage();
    error SameTokenSwap(address token);
    error InvalidTranche(address tranche);
    error TrancheAlreadyAdded(address tranche);
    error RemoveLiquidityTooMuch(address tranche, uint256 outAmount, uint256 trancheBalance);
    error CannotDistributeToTranches(address token, uint256 amount, bool CannotDistributeToTranches);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IOracle} from "../interfaces/IOracle.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {IPositionHook} from "../interfaces/IPositionHook.sol";

uint256 constant INTEREST_RATE_PRECISION = 1e10;
uint256 constant FEE_PRECISION = 1e10;
uint256 constant LP_INITIAL_PRICE = 1e12; // fix to 1$
uint256 constant MAX_BASE_SWAP_FEE = 1e8; // 1%
uint256 constant MAX_TAX_BASIS_POINT = 1e8; // 1%
uint256 constant MAX_POSITION_FEE = 1e8; // 1%

struct Fee {
    /// @notice charge when changing position size
    uint256 positionFee;
    /// @notice charge when liquidate position (in dollar)
    uint256 liquidationFee;
    /// @notice swap fee used when add/remove liquidity, swap token
    uint256 baseSwapFee;
    /// @notice tax used to adjust swapFee due to the effect of the action on token's weight
    /// It reduce swap fee when user add some amount of a under weight token to the pool
    uint256 taxBasisPoint;
    /// @notice swap fee used when add/remove liquidity, swap token
    uint256 stableCoinBaseSwapFee;
    /// @notice tax used to adjust swapFee due to the effect of the action on token's weight
    /// It reduce swap fee when user add some amount of a under weight token to the pool
    uint256 stableCoinTaxBasisPoint;
    /// @notice part of fee will be kept for DAO, the rest will be distributed to pool amount, thus
    /// increase the pool value and the price of LP token
    uint256 daoFee;
}

struct Position {
    /// @dev contract size is evaluated in dollar
    uint256 size;
    /// @dev collateral value in dollar
    uint256 collateralValue;
    /// @dev contract size in indexToken
    uint256 reserveAmount;
    /// @dev average entry price
    uint256 entryPrice;
    /// @dev last cumulative interest rate
    uint256 borrowIndex;
}

struct PoolTokenInfo {
    /// @notice amount reserved for fee
    uint256 feeReserve;
    /// @notice recorded balance of token in pool
    uint256 poolBalance;
    /// @notice last borrow index update timestamp
    uint256 lastAccrualTimestamp;
    /// @notice accumulated interest rate
    uint256 borrowIndex;
    /// @notice average entry price of all short position
    uint256 averageShortPrice;
}

struct AssetInfo {
    /// @notice amount of token deposited (via add liquidity or increase long position)
    uint256 poolAmount;
    /// @notice amount of token reserved for paying out when user decrease long position
    uint256 reservedAmount;
    /// @notice total borrowed (in USD) to leverage
    uint256 guaranteedValue;
    /// @notice total size of all short positions
    uint256 totalShortSize;
}

abstract contract PoolStorage {
    Fee public fee;

    address public feeDistributor;

    IOracle public oracle;

    address public orderManager;

    // ========= Assets management =========
    mapping(address => bool) public isAsset;
    /// @notice A list of all configured assets
    /// @dev use a pseudo address for ETH
    /// Note that token will not be removed from this array when it was delisted. We keep this
    /// list to calculate pool value properly
    address[] public allAssets;

    mapping(address => bool) public isListed;

    mapping(address => bool) public isStableCoin;

    mapping(address => PoolTokenInfo) public poolTokens;

    /// @notice target weight for each tokens
    mapping(address => uint256) public targetWeights;

    mapping(address => bool) public isTranche;
    /// @notice risk factor of each token in each tranche
    /// @dev token => tranche => risk factor
    mapping(address => mapping(address => uint256)) public riskFactor;
    /// @dev token => total risk score
    mapping(address => uint256) public totalRiskFactor;

    address[] public allTranches;

    mapping(address => mapping(address => AssetInfo)) public trancheAssets;
    /// @notice position reserve in each tranche
    mapping(address => mapping(bytes32 => uint256)) public tranchePositionReserves;

    /// @notice interest rate model
    uint256 public interestRate;

    uint256 public accrualInterval;

    uint256 public totalWeight;
    // ========= Positions management =========
    /// @notice max leverage for each token
    uint256 public maxLeverage;
    /// @notice positions tracks all open positions
    mapping(bytes32 => Position) public positions;
    /// @notice max position size allowed to open. Disable if set to 0
    uint256 public maxPositionSize;

    IPositionHook public positionHook;
}