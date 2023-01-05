// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= CurveAMOv5Helper ===========================
// ====================================================================

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna

import "./interfaces/curve/IMinCurvePool.sol";
import "./interfaces/ICurveAMOv5.sol";
import "./interfaces/IFrax.sol";
import "./interfaces/convex/IConvexBaseRewardPool.sol";
import "./interfaces/convex/IVirtualBalanceRewardPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurveAMOv5Helper {
    /* ============================================= STATE VARIABLES ==================================================== */

    // Constants (ERC20)
    IFrax private constant FRAX =
        IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    ERC20 private constant USDC =
        ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /* ================================================== VIEWS ========================================================= */

    /// @notice Show allocations of CurveAMO in FRAX and USDC
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolArrayLength Number of pools in Curve AMO
    /// @return allocations [Free FRAX in AMO, Free USDC in AMO, Total FRAX Minted into Pools, Total USDC deposited into Pools, Total withdrawable Frax directly from pools, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool LP, Total withdrawable USDC from pool and basepool LP, Total Frax, Total USDC]
    function showAllocations(address _curveAMOAddress, uint256 _poolArrayLength)
        public
        view
        returns (uint256[10] memory allocations)
    {
        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        // ------------Frax Balance------------
        // Free Frax Amount
        allocations[0] = FRAX.balanceOf(_curveAMOAddress); // [0] Free FRAX in AMO

        // Free Collateral
        allocations[1] = USDC.balanceOf(_curveAMOAddress); // [1] Free USDC in AMO

        // ------------Withdrawables------------
        for (uint256 i = 0; i < _poolArrayLength; i++) {
            address _poolAddress = curveAMO.poolArray(i);
            (, , bool _hasFrax, , bool _hasUsdc) = curveAMO.showPoolInfo(
                _poolAddress
            );
            (, uint256 _fraxIndex, uint256 _usdcIndex, ) = curveAMO
                .showPoolCoinIndexes(_poolAddress);
            try curveAMO.showPoolAccounting(_poolAddress) returns (
                uint256[] memory,
                uint256[] memory _depositedAmounts,
                uint256[] memory,
                uint256[3] memory
            ) {
                if (_hasFrax) {
                    allocations[2] += _depositedAmounts[_fraxIndex]; // [2] Total FRAX Minted into Pools
                }
                if (_hasUsdc) {
                    allocations[3] += _depositedAmounts[_usdcIndex]; // [3] Total USDC deposited into Pools
                }
            } catch {}
            try curveAMO.calcFraxUsdcOnlyFromFullLPExit(_poolAddress) returns (
                uint256[4] memory _withdrawables
            ) {
                allocations[4] += _withdrawables[0]; // [4] Total withdrawable Frax directly from pool
                allocations[5] += _withdrawables[1]; // [5] Total withdrawable USDC directly from pool
                allocations[6] += _withdrawables[2]; // [6] Total withdrawable Frax from pool and basepool LP
                allocations[7] += _withdrawables[3]; // [7] Total  withdrawable USDC from pool and basepool LP
            } catch {}
        }
        allocations[8] = allocations[0] + allocations[6]; // [8] Total Frax
        allocations[9] = allocations[1] + allocations[7]; // [9] Total USDC
    }

    /// @notice Calculate recieving amount of FRAX and USDC after withdrawal
    /// @notice Ignores other tokens that may be present in the LP (e.g. DAI, USDT, SUSD, CRV)
    /// @notice This can cause bonuses/penalties for withdrawing one coin depending on the balance of said coin.
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolLpTokenAddress Address of Curve Pool LP Token
    /// @param _lpAmount LP Amount for withdraw
    /// @return _withdrawables [Total withdrawable Frax directly from pool, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool lp, Total withdrawable USDC from pool and basepool lp]
    function calcFraxAndUsdcWithdrawable(
        address _curveAMOAddress,
        address _poolAddress,
        address _poolLpTokenAddress,
        uint256 _lpAmount
    ) public view returns (uint256[4] memory _withdrawables) {
        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        (
            bool _isMetapool,
            bool _isCrypto,
            bool _hasFrax,
            ,
            bool _hasUsdc
        ) = curveAMO.showPoolInfo(_poolAddress);
        (
            ,
            uint256 _fraxIndex,
            uint256 _usdcIndex,
            uint256 _baseTokenIndex
        ) = curveAMO.showPoolCoinIndexes(_poolAddress);

        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        if (_hasFrax) {
            ERC20 _lpToken = ERC20(_poolLpTokenAddress);
            uint256 _lpTotalSupply = _lpToken.totalSupply();
            if (_hasUsdc) {
                _withdrawables[0] =
                    (pool.balances(_fraxIndex) * _lpAmount) /
                    _lpTotalSupply;
                _withdrawables[1] =
                    (pool.balances(_usdcIndex) * _lpAmount) /
                    _lpTotalSupply;
                _withdrawables[2] = _withdrawables[0];
                _withdrawables[3] = _withdrawables[1];
            } else if (_isMetapool) {
                _withdrawables[0] =
                    (pool.balances(_fraxIndex) * _lpAmount) /
                    _lpTotalSupply;
                _withdrawables[1] = 0;
                uint256 _totalWithdrawable = (pool.balances(_baseTokenIndex) *
                    _lpAmount) / _lpTotalSupply;
                address _baseTokenAddress = pool.coins(_baseTokenIndex);

                // Recursive call
                uint256[4] memory _poolwithdrawables = curveAMO
                    .calcFraxAndUsdcWithdrawable(
                        curveAMO.lpTokenToPool(_baseTokenAddress),
                        _totalWithdrawable
                    );

                _withdrawables[2] = _withdrawables[0] + _poolwithdrawables[2];
                _withdrawables[3] = _poolwithdrawables[3];
            } else {
                _withdrawables[1] = 0;
                _withdrawables[3] = 0;
                if (_lpAmount > 0) {
                    if (_isCrypto) {
                        _withdrawables[0] = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _fraxIndex
                        );
                    } else {
                        int128 _index = int128(uint128(_fraxIndex));
                        _withdrawables[0] = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _index
                        );
                    }
                }
                _withdrawables[2] = _withdrawables[0];
            }
        } else {
            if (_hasUsdc) {
                _withdrawables[0] = 0;
                if (_lpAmount > 0) {
                    if (_isCrypto) {
                        _withdrawables[1] = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _usdcIndex
                        );
                    } else {
                        int128 _index = int128(uint128(_usdcIndex));
                        _withdrawables[1] = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _index
                        );
                    }
                }
                _withdrawables[2] = _withdrawables[0];
                _withdrawables[3] = _withdrawables[1];
            } else {
                _withdrawables[0] = 0;
                _withdrawables[1] = 0;
                uint256 _totalWithdrawable = 0;
                if (_lpAmount > 0) {
                    if (_isCrypto) {
                        _totalWithdrawable = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _baseTokenIndex
                        );
                    } else {
                        int128 _index = int128(uint128(_baseTokenIndex));
                        _totalWithdrawable = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _index
                        );
                    }
                }
                address _baseTokenAddress = pool.coins(_baseTokenIndex);
                uint256[4] memory _poolwithdrawables = curveAMO
                    .calcFraxAndUsdcWithdrawable(
                        curveAMO.lpTokenToPool(_baseTokenAddress),
                        _totalWithdrawable
                    );
                _withdrawables[2] = _poolwithdrawables[2];
                _withdrawables[3] = _poolwithdrawables[3];
            }
        }
    }

    /// @notice Show allocations of CurveAMO into Curve Pool
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolAddress Address of Curve Pool
    /// @return _assetBalances Pool coins current AMO balances
    function showPoolAssetBalances(
        address _curveAMOAddress,
        address _poolAddress
    ) public view returns (uint256[] memory _assetBalances) {
        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        (uint256 _coinCount, , , ) = curveAMO.showPoolCoinIndexes(_poolAddress);

        _assetBalances = new uint256[](_coinCount);
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        for (uint256 i = 0; i < _coinCount; i++) {
            ERC20 _token = ERC20(pool.coins(i));
            _assetBalances[i] = _token.balanceOf(_curveAMOAddress);
        }
    }

    // @notice Show allocations of CurveAMO into Curve Pool
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolAddress Address of Curve Pool
    /// @return _oneStepBurningLp Pool coins current AMO balances
    function showOneStepBurningLp(
        address _curveAMOAddress,
        address _poolAddress
    ) public view returns (uint256 _oneStepBurningLp) {
        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        (, , , uint256[3] memory _allocations) = curveAMO.showPoolAccounting(
            _poolAddress
        );
        _oneStepBurningLp = _allocations[0] + _allocations[2];
    }

    /// @notice Get the balances of the underlying tokens for the given amount of LP,
    /// @notice assuming you withdraw at the current ratio.
    /// @notice May not necessarily = balanceOf(<underlying token address>) due to accumulated fees
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolLpTokenAddress Address of Curve Pool LP Token
    /// @param _lpAmount LP Amount
    /// @return _withdrawables Amount of each token expected
    function getTknsForLPAtCurrRatio(
        address _curveAMOAddress,
        address _poolAddress,
        address _poolLpTokenAddress,
        uint256 _lpAmount
    ) public view returns (uint256[] memory _withdrawables) {
        // CurvePool memory _poolInfo = poolInfo[_poolAddress];
        ERC20 _lpToken = ERC20(_poolLpTokenAddress);
        uint256 _lpTotalSupply = _lpToken.totalSupply();

        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        (uint256 _coinCount, , , ) = curveAMO.showPoolCoinIndexes(_poolAddress);
        _withdrawables = new uint256[](_coinCount);

        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        for (uint256 i = 0; i < _coinCount; i++) {
            _withdrawables[i] = (pool.balances(i) * _lpAmount) / _lpTotalSupply;
        }
    }

    /// @notice Show all rewards of CurveAMO
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _rewardsContractAddress Address of Convex Base Reward Contract
    /// @return _crvReward Pool CRV rewards
    /// @return _extraRewardAmounts [CRV claimable, CVX claimable, cvxCRV claimable]
    /// @return _extraRewardTokens [Token Address]
    function showPoolRewards(
        address _curveAMOAddress,
        address _rewardsContractAddress
    )
        external
        view
        returns (
            uint256 _crvReward,
            uint256[] memory _extraRewardAmounts,
            address[] memory _extraRewardTokens
        )
    {
        IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(
            _rewardsContractAddress
        );
        _crvReward = _convexBaseRewardPool.earned(_curveAMOAddress); // CRV claimable

        uint256 _extraRewardsLength = _convexBaseRewardPool
            .extraRewardsLength();
        for (uint256 i = 0; i < _extraRewardsLength; i++) {
            IVirtualBalanceRewardPool _convexExtraRewardsPool = IVirtualBalanceRewardPool(
                    _convexBaseRewardPool.extraRewards(i)
                );
            _extraRewardAmounts[i] = _convexExtraRewardsPool.earned(
                _curveAMOAddress
            );
            _extraRewardTokens[i] = _convexExtraRewardsPool.rewardToken();
        }
    }
}

interface ICurveAMOv5 {
    function addOrSetPool ( bytes memory _configData, address _poolAddress ) external;
    function burnFRAX ( uint256 _fraxAmount ) external;
    function calcAllTknsFromFullLPExit ( address _poolAddress ) external view returns ( uint256[] memory _withdrawables );
    function calcFraxAndUsdcWithdrawable ( address _poolAddress, uint256 _lpAmount ) external view returns ( uint256[4] memory );
    function calcFraxUsdcOnlyFromFullLPExit ( address _poolAddress ) external view returns ( uint256[4] memory _withdrawables );
    function claimRewards ( address _poolAddress, bool _claimConvexVault, bool _claimFxsVault ) external;
    function createFxsVault ( address _poolAddress, uint256 _pid ) external;
    function depositToFxsVault ( address _poolAddress, uint256 _poolLpIn, uint256 _secs ) external returns ( bytes32 _kek_id );
    function depositToPool ( address _poolAddress, uint256[] memory _amounts, uint256 _minLpOut ) external;
    function depositToVault ( address _poolAddress, uint256 _poolLpIn ) external;
    function discountRate (  ) external view returns ( uint256 );
    function dollarBalances (  ) external view returns ( uint256 fraxValE18, uint256 collatValE18 );
    function execute ( address _to, uint256 _value, bytes memory _data ) external returns ( bool, bytes memory );
    function fraxDiscountRate (  ) external view returns ( uint256 );
    function getTknsForLPAtCurrRatio ( address _poolAddress, uint256 _lpAmount ) external view returns ( uint256[] memory _withdrawables );
    function giveCollatBack ( uint256 _collateralAmount ) external;
    function kekIdTotalDeposit ( bytes32 ) external view returns ( uint256 );
    function lockLongerInFxsVault ( address _poolAddress, bytes32 _kek_id, uint256 new_ending_ts ) external;
    function lockMoreInFxsVault ( address _poolAddress, bytes32 _kek_id, uint256 _addl_liq ) external;
    function lpInVault ( address _poolAddress ) external view returns ( uint256 );
    function lpTokenToPool ( address ) external view returns ( address );
    function mintedBalance (  ) external view returns ( int256 );
    function operatorAddress (  ) external view returns ( address );
    function owner (  ) external view returns ( address );
    function poolArray ( uint256 ) external view returns ( address );
    function poolInitialized ( address ) external view returns ( bool );
    function poolSwap ( address _poolAddress, uint256 _inIndex, uint256 _outIndex, uint256 _inAmount, uint256 _minOutAmount ) external;
    function recoverERC20 ( address tokenAddress, uint256 tokenAmount ) external;
    function renounceOwnership (  ) external;
    function setAMOMinter ( address _amoMinterAddress ) external;
    function setDiscount (  ) external view returns ( bool );
    function setDiscountRate ( bool _state, uint256 _discountRate ) external;
    function setOperatorAddress ( address _newOperatorAddress ) external;
    function setPoolAllocation ( address _poolAddress, uint256[] memory _poolMaxAllocations ) external;
    function setPoolVault ( address _poolAddress, address _rewardsContractAddress ) external;
    function showAllocations (  ) external view returns ( uint256[10] memory  );
    function showCVXRewards (  ) external view returns ( uint256 _cvxReward );
    function showPoolAccounting ( address _poolAddress ) external view returns ( uint256[] memory _assetBalances, uint256[] memory _depositedAmounts, uint256[] memory _profitTakenAmounts, uint256[3] memory _allocations );
    function showPoolAssetBalances ( address _poolAddress ) external view returns ( uint256[] memory _assetBalances );
    function showPoolCoinIndexes ( address _poolAddress ) external view returns ( uint256 _coinCount, uint256 _fraxIndex, uint256 _usdcIndex, uint256 _baseTokenIndex );
    function showPoolInfo ( address _poolAddress ) external view returns ( bool _isMetapool, bool _isCrypto, bool _hasFrax, bool _hasVault, bool _hasUsdc );
    function showPoolMaxAllocations ( address _poolAddress ) external view returns ( uint256[] memory _tokenMaxAllocation );
    function showPoolRewards ( address _poolAddress ) external view returns ( uint256 _crvReward, uint256[] memory  _extraRewardAmounts, address[] memory _extraRewardTokens );
    function showPoolVaults ( address _poolAddress ) external view returns ( uint256 _lpDepositPid, address _rewardsContractAddress, address _fxsPersonalVaultAddress );
    function transferOwnership ( address newOwner ) external;
    function vaultKekIds ( address, uint256 ) external view returns ( bytes32 );
    function withdrawAllAtCurrRatio ( address _poolAddress, uint256[] memory _minAmounts ) external returns ( uint256[] memory _amountReceived );
    function withdrawAndUnwrapFromFxsVault ( address _poolAddress, bytes32 _kek_id ) external;
    function withdrawAndUnwrapFromVault ( address _poolAddress, uint256 amount, bool claim ) external;
    function withdrawAtCurrRatio ( address _poolAddress, uint256 _lpIn, uint256[] memory _minAmounts ) external returns ( uint256[] memory _amountReceived );
    function withdrawOneCoin ( address _poolAddress, uint256 _lpIn, uint256 _coinIndex, uint256 _minAmountOut ) external returns ( uint256 _amountReceived );
    function withdrawRewards ( uint256 crvAmount, uint256 cvxAmount, uint256 cvxCRVAmount, uint256 fxsAmount ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IFrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address pool_address ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateral_ratio_paused() external view returns (bool);
  function controller_address() external view returns (address);
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function frax_eth_oracle_address() external view returns (address);
  function frax_info() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function frax_pools(address ) external view returns (bool);
  function frax_pools_array(uint256 ) external view returns (address);
  function frax_price() external view returns (uint256);
  function frax_step() external view returns (uint256);
  function fxs_address() external view returns (address);
  function fxs_eth_oracle_address() external view returns (address);
  function fxs_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function global_collateral_ratio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function pool_burn_from(address b_address, uint256 b_amount ) external;
  function pool_mint(address m_address, uint256 m_amount ) external;
  function price_band() external view returns (uint256);
  function price_target() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refresh_cooldown() external view returns (uint256);
  function removePool(address pool_address ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controller_address ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address ) external;
  function setFXSAddress(address _fxs_address ) external;
  function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address ) external;
  function setFraxStep(uint256 _new_step ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setPriceBand(uint256 _price_band ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setRefreshCooldown(uint256 _new_cooldown ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IConvexBaseRewardPool {
  function addExtraReward(address _reward) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function currentRewards() external view returns (uint256);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward() external returns (bool);
  function getReward(address _account, bool _claimExtras) external returns (bool);
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function pid() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external returns (bool);
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external returns (bool);
  function stakeAll() external returns (bool);
  function stakeFor(address _for, uint256 _amount) external returns (bool);
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 amount, bool claim) external returns (bool);
  function withdrawAll(bool claim) external;
  function withdrawAllAndUnwrap(bool claim) external;
  function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IVirtualBalanceRewardPool {
    function balanceOf(address account) external view returns (uint256);
    function currentRewards() external view returns (uint256);
    function deposits() external view returns (address);
    function donate(uint256 _amount) external returns (bool);
    function duration() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function getReward(address _account) external;
    function historicalRewards() external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function lastUpdateTime() external view returns (uint256);
    function newRewardRatio() external view returns (uint256);
    function operator() external view returns (address);
    function periodFinish() external view returns (uint256);
    function queueNewRewards(uint256 _rewards) external;
    function queuedRewards() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardPerTokenStored() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardToken() external view returns (address);
    function rewards(address) external view returns (uint256);
    function stake(address _account, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function userRewardPerTokenPaid(address) external view returns (uint256);
    function withdraw(address _account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

interface IMinCurvePool{
    function get_virtual_price() external view returns ( uint256 );
    function coins ( uint256 arg0 ) external view returns ( address );
    function balances ( uint256 arg0 ) external view returns ( uint256 );
    function add_liquidity ( uint256[2] memory _amounts, uint256 _min_mint_amount ) external returns ( uint256 );
    function add_liquidity ( uint256[3] memory _amounts, uint256 _min_mint_amount ) external ;
    function remove_liquidity ( uint256 _burn_amount, uint256[2] memory _min_amounts ) external;
    function remove_liquidity ( uint256 _burn_amount, uint256[3] memory _min_amounts ) external;

    // USD Pools
    function get_dy ( int128 i, int128 j, uint256 dx ) external view returns ( uint256 );
    function calc_token_amount ( uint256[] memory _amounts, bool _is_deposit ) external view returns ( uint256 );
    function calc_withdraw_one_coin ( uint256 _token_amount, int128 i ) external view returns ( uint256 );
    function remove_liquidity_one_coin ( uint256 _burn_amount, int128 i, uint256 _min_received ) external;
    // function remove_liquidity_one_coin ( uint256 _burn_amount, int128 i, uint256 _min_received ) external returns ( uint256 );
    function exchange ( int128 i, int128 j, uint256 dx, uint256 min_dy ) external;

    // metapool
    function get_dy ( int128 i, int128 j, uint256 dx, uint256[] memory _balances ) external view returns ( uint256 );

    // Crypto Pool
    function get_dy ( uint256 i, uint256 j, uint256 dx ) external view returns ( uint256 );
    function price_oracle (  ) external view returns ( uint256 );
    function lp_price (  ) external view returns ( uint256 );
    function calc_token_amount ( uint256[] memory _amounts ) external view returns ( uint256 );
    function calc_withdraw_one_coin ( uint256 _token_amount, uint256 i ) external view returns ( uint256 );
    function remove_liquidity_one_coin ( uint256 token_amount, uint256 i, uint256 min_amount ) external returns ( uint256 );
    function exchange ( uint256 i, uint256 j, uint256 dx, uint256 min_dy ) external returns ( uint256 );
}