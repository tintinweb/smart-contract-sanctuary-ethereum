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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface INeuronPool {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function available() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function controller() external view returns (address);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(address _enterToken, uint256 _amount) external payable returns (uint256);

    function depositAll(address _enterToken) external payable returns (uint256);

    function earn() external;

    function getSupportedTokens() external view returns (address[] memory tokens);

    function governance() external view returns (address);

    function harvest(address reserve, uint256 amount) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function masterchef() external view returns (address);

    function max() external view returns (uint256);

    function min() external view returns (uint256);

    function name() external view returns (string memory);

    function pricePerShare() external view returns (uint256);

    function setController(address _controller) external;

    function setGovernance(address _governance) external;

    function setMin(uint256 _min) external;

    function setTimelock(address _timelock) external;

    function symbol() external view returns (string memory);

    function timelock() external view returns (address);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function withdraw(address _withdrawableToken, uint256 _shares) external;

    function withdrawAll(address _withdrawableToken) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IConvexBooster {
    event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);

    function FEE_DENOMINATOR() external view returns (uint256);

    function MaxFees() external view returns (uint256);

    function addPool(
        address _lptoken,
        address _gauge,
        uint256 _stashVersion
    ) external returns (bool);

    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    function crv() external view returns (address);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function distributionAddressId() external view returns (uint256);

    function earmarkFees() external returns (bool);

    function earmarkIncentive() external view returns (uint256);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function feeDistro() external view returns (address);

    function feeManager() external view returns (address);

    function feeToken() external view returns (address);

    function gaugeMap(address) external view returns (bool);

    function isShutdown() external view returns (bool);

    function lockFees() external view returns (address);

    function lockIncentive() external view returns (uint256);

    function lockRewards() external view returns (address);

    function minter() external view returns (address);

    function owner() external view returns (address);

    function platformFee() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function poolLength() external view returns (uint256);

    function poolManager() external view returns (address);

    function registry() external view returns (address);

    function rewardArbitrator() external view returns (address);

    function rewardClaimed(
        uint256 _pid,
        address _address,
        uint256 _amount
    ) external returns (bool);

    function rewardFactory() external view returns (address);

    function setArbitrator(address _arb) external;

    function setFactories(
        address _rfactory,
        address _sfactory,
        address _tfactory
    ) external;

    function setFeeInfo() external;

    function setFeeManager(address _feeM) external;

    function setFees(
        uint256 _lockFees,
        uint256 _stakerFees,
        uint256 _callerFees,
        uint256 _platform
    ) external;

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function setOwner(address _owner) external;

    function setPoolManager(address _poolM) external;

    function setRewardContracts(address _rewards, address _stakerRewards) external;

    function setTreasury(address _treasury) external;

    function setVoteDelegate(address _voteDelegate) external;

    function shutdownPool(uint256 _pid) external returns (bool);

    function shutdownSystem() external;

    function staker() external view returns (address);

    function stakerIncentive() external view returns (uint256);

    function stakerRewards() external view returns (address);

    function stashFactory() external view returns (address);

    function tokenFactory() external view returns (address);

    function treasury() external view returns (address);

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool);

    function voteDelegate() external view returns (address);

    function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight) external returns (bool);

    function voteOwnership() external view returns (address);

    function voteParameter() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external returns (bool);
}

interface IBaseRewardPool {
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

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

interface IVirtualBalanceRewardPool {
    function getReward(address) external;

    function getReward() external;

    function balanceOf(address) external view returns (uint256);

    function earned(address) external view returns (uint256);
}

interface IConvexToken is IERC20 {
    function reductionPerCliff() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}

interface IConvexMasterChef {
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        bool _withUpdate
    ) external;

    function bonusEndBlock() external view returns (uint256);

    function claim(uint256 _pid, address _account) external;

    function cvx() external view returns (address);

    function deposit(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingCvx(uint256 _pid, address _user) external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCvxPerShare,
            address rewarder
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function rewardPerBlock() external view returns (uint256);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool _withUpdate,
        bool _updateRewarder
    ) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

interface IConvexClaimZap {
    function claimRewards(
        address[] memory rewardContracts,
        address[] memory extraRewardContracts,
        address[] memory tokenRewardContracts,
        address[] memory tokenRewardTokens,
        uint256 depositCrvMaxAmount,
        uint256 minAmountOut,
        uint256 depositCvxMaxAmount,
        uint256 spendCvxAmount,
        uint256 options
    ) external;

    function crv() external view returns (address);

    function crvDeposit() external view returns (address);

    function cvx() external view returns (address);

    function cvxCrv() external view returns (address);

    function cvxCrvRewards() external view returns (address);

    function cvxRewards() external view returns (address);

    function exchange() external view returns (address);

    function getName() external pure returns (string memory);

    function locker() external view returns (address);

    function owner() external view returns (address);

    function setApprovals() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
}

interface ICurveFi {
    function add_liquidity(
        // stETH pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function balances(int128) external view returns (uint256);
}

interface ICurveFi_2 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(int128) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

interface ICurveFi_2_256 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

interface ICurveFi_3 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256,
        bool use_underlying
    ) external;
}

interface ICurveFi_3_int128 {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function balances(int128) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

interface ICurveFi_4 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(int128) external view returns (uint256);
}

interface ICurveZap_4 {
    function add_liquidity(uint256[4] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[4] calldata uamounts, uint256 max_burn_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount,
        bool donate_dust
    ) external;

    function withdraw_donated_dust() external;

    function coins(int128 arg0) external returns (address);

    function underlying_coins(int128 arg0) external returns (address);

    function curve() external returns (address);

    function token() external returns (address);
}

interface ICurveZap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;
}

// Interface to manage Crv strategies' interactions
interface ICurveGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function balanceOf(address arg0) external view returns (uint256);

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool claim_rewards) external;

    function claim_rewards() external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address addr) external view returns (uint256);

    function claimable_reward(address, address) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);
}

interface ICurveMintr {
    function mint(address) external;

    function minted(address arg0, address arg1) external view returns (uint256);
}

interface ICurveVotingEscrow {
    function locked(address arg0) external view returns (int128 amount, uint256 end);

    function locked__end(address _addr) external view returns (uint256);

    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;

    function smart_wallet_checker() external returns (address);
}

interface ICurveSmartContractChecker {
    function wallets(address) external returns (bool);

    function approveWallet(address _wallet) external;
}

interface ICurveFi_Polygon_3 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);
}

interface ICurveFi_Polygon_2 {
    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function dynamic_fee(int128 i, int128 j) external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] calldata _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] calldata);

    function remove_liquidity(
        uint256 _amount,
        uint256[2] calldata _min_amounts,
        bool _use_underlying
    ) external returns (uint256[2] calldata);

    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(
        uint256[2] calldata _amounts,
        uint256 _max_burn_amount,
        bool _use_underlying
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function commit_new_fee(
        uint256 new_fee,
        uint256 new_admin_fee,
        uint256 new_offpeg_fee_multiplier
    ) external;

    function apply_new_fee() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function donate_admin_fees() external;

    function kill_me() external;

    function unkill_me() external;

    function set_aave_referral(uint256 referral_code) external;

    function set_reward_receiver(address _reward_receiver) external;

    function set_admin_fee_receiver(address _admin_fee_receiver) external;

    function coins(uint256 arg0) external view returns (address);

    function underlying_coins(uint256 arg0) external view returns (address);

    function admin_balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function offpeg_fee_multiplier() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function owner() external view returns (address);

    function lp_token() external view returns (address);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function future_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function future_offpeg_fee_multiplier() external view returns (uint256);

    function future_owner() external view returns (address);

    function reward_receiver() external view returns (address);

    function admin_fee_receiver() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface INeuronPoolsController {
    function nPools(address) external view returns (address);

    function rewards() external view returns (address);

    function treasury() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function withdraw(address, uint256) external;

    function earn(address, uint256) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStrategy {
    event Deposit(uint256 amount);
    event Withdraw(uint256 claimedAmount, uint256 totalAmount);
    event Harvest();
    event RewardToken(address indexed token, uint256 amount);

    function want() external view returns (address);

    function deposit() external;

    function withdrawForSwap(uint256) external returns (uint256);

    function withdraw(address) external returns (uint256 balance);

    function withdraw(uint256) external;

    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function harvest() external;

    function setController(address _controller) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IUniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { INeuronPool } from "../../common/interfaces/INeuronPool.sol";
import { IUniswapRouterV2 } from "../interfaces/IUniswapRouterV2.sol";
import { INeuronPoolsController } from "../interfaces/INeuronPoolsController.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";

// Strategy Contract Basics

abstract contract StrategyBase is IStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable want;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // User accounts
    address public governance;
    address public controller;

    // Dex
    address public constant univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    constructor(
        // Input token accepted by the contract
        address _want,
        address _governance,
        address _controller
    ) {
        require(_want != address(0));
        require(_governance != address(0));
        require(_controller != address(0));

        want = _want;
        governance = _governance;
        controller = _controller;
    }

    receive() external payable {}

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external pure virtual returns (string memory);

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // NeuronPoolsController only function for creating additional rewards from dust
    function withdraw(address _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != _asset, "want");
        balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a pool withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        address _nPool = INeuronPoolsController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_nPool, _amount);

        emit Withdraw(_amount, _amount);
    }

    // Withdraw funds, used to swap between strategies
    function withdrawForSwap(uint256 _amount) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        address _nPool = INeuronPoolsController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool");
        IERC20(want).safeTransfer(_nPool, balance);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _nPool = INeuronPoolsController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_nPool, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;

    // **** Internal functions ****
    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapUniswapExactETHForTokens(address _to, uint256 _amount) internal {
        require(_to != address(0));

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = _to;

        IUniswapRouterV2(univ2Router2).swapExactETHForTokens{ value: _amount }(
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapUniswapExactTokensForETH(address _from, uint256 _amount) internal {
        require(_from != address(0));

        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = weth;

        IUniswapRouterV2(univ2Router2).swapExactTokensForETH(_amount, 0, path, address(this), block.timestamp.add(60));
    }

    function _swapSushiswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { StrategyBase } from "../StrategyBase.sol";
import { IConvexBooster, IBaseRewardPool } from "../../interfaces/IConvexFarm.sol";

abstract contract StrategyConvexFarmBase is StrategyBase {
    using SafeERC20 for IERC20;

    // Strategy config, + "want" this lp token
    address public curvePool;
    uint256 public convexPoolId;

    // Base convex config
    address public constant convexBooster = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    constructor(
        address _want,
        address _curvePool,
        uint256 _convexPoolId,
        address _governance,
        address _controller
    ) StrategyBase(_want, _governance, _controller) {
        curvePool = _curvePool;
        convexPoolId = _convexPoolId;
    }

    function getCrvRewardContract() internal view returns (address crvRewards_) {
        (, , , crvRewards_, , ) = IConvexBooster(convexBooster).poolInfo(convexPoolId);
    }

    function balanceOfPool() public view override returns (uint256) {
        return IBaseRewardPool(getCrvRewardContract()).balanceOf(address(this));
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(convexBooster, 0);
            IERC20(want).safeApprove(convexBooster, _want);

            IConvexBooster(convexBooster).deposit(convexPoolId, _want, true);
            emit Deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IBaseRewardPool(getCrvRewardContract()).withdrawAndUnwrap(_amount, true);
        return _amount;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { StrategyConvexFarmBase } from "../StrategyConvexFarmBase.sol";
import { ICurveFi_3_int128 } from "../../../interfaces/ICurve.sol";
import { IBaseRewardPool } from "../../../interfaces/IConvexFarm.sol";

contract StrategyConvexCurveSBTC is StrategyConvexFarmBase {
    using SafeERC20 for IERC20;

    address internal constant RENBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant SBTC = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;

    constructor(address _governance, address _controller)
        StrategyConvexFarmBase(
            0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3, // want = 3crv lp-token
            0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714, // curvePool = 3crv pool
            7, // convexPoolId
            _governance,
            _controller
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCurveSBTC";
    }

    function harvest() public override {
        IBaseRewardPool(getCrvRewardContract()).getReward(address(this), true);

        // Check rewards
        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        emit RewardToken(cvx, _cvx);

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        emit RewardToken(crv, _crv);

        // Swap cvx to crv
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, crv, _cvx);
        }

        // Swap crv to stable coins
        (address to, uint256 toIndex) = getMostPremium();

        _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(univ2Router2, 0);
            IERC20(crv).safeApprove(univ2Router2, _crv);
            _swapUniswap(crv, to, _crv);
        }

        // reinvestment
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curvePool, 0);
            IERC20(to).safeApprove(curvePool, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_3_int128(curvePool).add_liquidity(liquidity, 0);
        }
        emit Harvest();
        deposit();
    }

    function getMostPremium() internal view returns (address, uint256) {
        ICurveFi_3_int128 curve = ICurveFi_3_int128(curvePool);
        uint256[3] memory balances = [curve.balances(0) * 1e10, curve.balances(1) * 1e10, curve.balances(2)];

        // USDC
        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (RENBTC, 0);
        }

        // USDT
        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (WBTC, 1);
        }

        return (SBTC, 2);
    }
}