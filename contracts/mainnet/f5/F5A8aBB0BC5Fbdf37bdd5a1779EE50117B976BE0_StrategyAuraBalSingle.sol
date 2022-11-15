/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin-4/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin-4/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin-4/contracts/utils/Context.sol

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

// File: @openzeppelin-4/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin-4/contracts/token/ERC20/extensions/draft-IERC20Permit.sol

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

// File: @openzeppelin-4/contracts/utils/Address.sol

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

// File: @openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: contracts/BIFI/interfaces/aura/IAuraBooster.sol


pragma solidity ^0.8.0;

interface IAuraBooster {
    function deposit(uint256 pid, uint256 amount, bool stake) external returns (bool);
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);
    function earmarkRewards(uint256 _pid) external;
    function poolInfo(uint256 pid) external view returns (
        address lptoken,
        address token,
        address gauge,
        address crvRewards,
        address stash,
        bool shutdown
    );
}

// File: contracts/BIFI/interfaces/aura/IAuraRewardPool.sol


pragma solidity >=0.6.0 <0.9.0;

interface IAuraRewardPool {
    function deposit(uint256 amount) external;
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function balanceOf(address account) external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardsToken() external view returns (address);
    function withdrawAndUnwrap(uint256 _amount, bool claim) external;
    function withdraw(uint256 _amount, bool claim) external;
}

// File: contracts/BIFI/interfaces/beethovenx/IBalancerVault.sol


pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IBalancerVault {
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external returns (int256[] memory assetDeltas);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function getPool(bytes32 poolId)
        external
        view
        returns (address, uint8);
    
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol

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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: contracts/BIFI/interfaces/common/IFeeConfig.sol


pragma solidity ^0.8.0;

interface IFeeConfig {
    struct FeeCategory {
        uint256 total;
        uint256 beefy;
        uint256 call;
        uint256 strategist;
        string label;
        bool active;
    }
    struct AllFees {
        FeeCategory performance;
        uint256 deposit;
        uint256 withdraw;
    }
    function getFees(address strategy) external view returns (FeeCategory memory);
    function stratFeeId(address strategy) external view returns (uint256);
    function setStratFeeId(uint256 feeId) external;
}

// File: contracts/BIFI/strategies/Common/StratFeeManagerInitializable.sol


pragma solidity ^0.8.0;



contract StratFeeManagerInitializable is OwnableUpgradeable, PausableUpgradeable {

    struct CommonAddresses {
        address vault;
        address unirouter;
        address keeper;
        address strategist;
        address beefyFeeRecipient;
        address beefyFeeConfig;
    }

    // common addresses for the strategy
    address public vault;
    address public unirouter;
    address public keeper;
    address public strategist;
    address public beefyFeeRecipient;
    IFeeConfig public beefyFeeConfig;

    uint256 constant DIVISOR = 1 ether;
    uint256 constant public WITHDRAWAL_FEE_CAP = 50;
    uint256 constant public WITHDRAWAL_MAX = 10000;
    uint256 internal withdrawalFee;

    event SetStratFeeId(uint256 feeId);
    event SetWithdrawalFee(uint256 withdrawalFee);
    event SetVault(address vault);
    event SetUnirouter(address unirouter);
    event SetKeeper(address keeper);
    event SetStrategist(address strategist);
    event SetBeefyFeeRecipient(address beefyFeeRecipient);
    event SetBeefyFeeConfig(address beefyFeeConfig);

    function __StratFeeManager_init(CommonAddresses calldata _commonAddresses) internal onlyInitializing {
        __Ownable_init();
        __Pausable_init();
        vault = _commonAddresses.vault;
        unirouter = _commonAddresses.unirouter;
        keeper = _commonAddresses.keeper;
        strategist = _commonAddresses.strategist;
        beefyFeeRecipient = _commonAddresses.beefyFeeRecipient;
        beefyFeeConfig = IFeeConfig(_commonAddresses.beefyFeeConfig);
        withdrawalFee = 10;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    // fetch fees from config contract
    function getFees() internal view returns (IFeeConfig.FeeCategory memory) {
        return beefyFeeConfig.getFees(address(this));
    }

    // fetch fees from config contract and dynamic deposit/withdraw fees
    function getAllFees() external view returns (IFeeConfig.AllFees memory) {
        return IFeeConfig.AllFees(getFees(), depositFee(), withdrawFee());
    }

    function getStratFeeId() external view returns (uint256) {
        return beefyFeeConfig.stratFeeId(address(this));
    }

    function setStratFeeId(uint256 _feeId) external onlyManager {
        beefyFeeConfig.setStratFeeId(_feeId);
        emit SetStratFeeId(_feeId);
    }

    // adjust withdrawal fee
    function setWithdrawalFee(uint256 _fee) public onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");
        withdrawalFee = _fee;
        emit SetWithdrawalFee(_fee);
    }

    // set new vault (only for strategy upgrades)
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
        emit SetVault(_vault);
    }

    // set new unirouter
    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
        emit SetUnirouter(_unirouter);
    }

    // set new keeper to manage strat
    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
        emit SetKeeper(_keeper);
    }

    // set new strategist address to receive strat fees
    function setStrategist(address _strategist) external {
        require(msg.sender == strategist, "!strategist");
        strategist = _strategist;
        emit SetStrategist(_strategist);
    }

    // set new beefy fee address to receive beefy fees
    function setBeefyFeeRecipient(address _beefyFeeRecipient) external onlyOwner {
        beefyFeeRecipient = _beefyFeeRecipient;
        emit SetBeefyFeeRecipient(_beefyFeeRecipient);
    }

    // set new fee config address to fetch fees
    function setBeefyFeeConfig(address _beefyFeeConfig) external onlyOwner {
        beefyFeeConfig = IFeeConfig(_beefyFeeConfig);
        emit SetBeefyFeeConfig(_beefyFeeConfig);
    }

    function depositFee() public virtual view returns (uint256) {
        return 0;
    }

    function withdrawFee() public virtual view returns (uint256) {
        return paused() ? 0 : withdrawalFee;
    }

    function beforeDeposit() external virtual {}
}

// File: contracts/BIFI/strategies/Balancer/BeefyBalancerStructs.sol

pragma solidity ^0.8.0; 

library BeefyBalancerStructs {
    struct BatchSwapStruct {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
    }

    struct Reward {
        mapping(uint => BatchSwapStruct) swapInfo;
        address[] assets;
        bytes routeToNative; // backup route in case there is no Balancer liquidity for reward
        uint minAmount; // minimum amount to be swapped to native
    }

     struct Input {
        address input;
        bool isComposable;
    }
}

// File: contracts/BIFI/strategies/Balancer/BalancerActionsLib.sol

pragma solidity ^0.8.0; 
library BalancerActionsLib {
    function balancerJoin(address _vault, bytes32 _poolId, address _tokenIn, uint256 _amountIn) internal {
        (address[] memory lpTokens,,) = IBalancerVault(_vault).getPoolTokens(_poolId);
        uint256[] memory amounts = new uint256[](lpTokens.length);
        for (uint256 i = 0; i < amounts.length;) {
            amounts[i] = lpTokens[i] == _tokenIn ? _amountIn : 0;
            unchecked { ++i; }
        }
        bytes memory userData = abi.encode(1, amounts, 1);

        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(lpTokens, amounts, userData, false);
        IBalancerVault(_vault).joinPool(_poolId, address(this), address(this), request);
    }

     function buildSwapStructArray(BeefyBalancerStructs.BatchSwapStruct[] memory _route, uint256 _amountIn) internal pure returns (IBalancerVault.BatchSwapStep[] memory) {
        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](_route.length);
        for (uint i; i < _route.length;) {
            if (i == 0) {
                swaps[0] =
                    IBalancerVault.BatchSwapStep({
                        poolId: _route[0].poolId,
                        assetInIndex: _route[0].assetInIndex,
                        assetOutIndex: _route[0].assetOutIndex,
                        amount: _amountIn,
                        userData: ""
                    });
            } else {
                swaps[i] =
                    IBalancerVault.BatchSwapStep({
                        poolId: _route[i].poolId,
                        assetInIndex: _route[i].assetInIndex,
                        assetOutIndex: _route[i].assetOutIndex,
                        amount: 0,
                        userData: ""
                    });
            }
            unchecked {
                ++i;
            }
        }

        return swaps;
    }

    function balancerSwap(address _vault, IBalancerVault.SwapKind _swapKind, IBalancerVault.BatchSwapStep[] memory _swaps, address[] memory _route, IBalancerVault.FundManagement memory _funds, int256 _amountIn) internal returns (int256[] memory) {
        int256[] memory limits = new int256[](_route.length);
        for (uint i; i < _route.length;) {
            if (i == 0) {
                limits[0] = _amountIn;
            } else if (i == _route.length - 1) {
                limits[i] = -1;
            }
            unchecked { ++i; }
        }
        return IBalancerVault(_vault).batchSwap(_swapKind, _swaps, _route, _funds, limits, block.timestamp);
    }
}

// File: contracts/BIFI/utils/BalancerUtils.sol


pragma solidity ^0.8.0;

library BalancerUtils {
    struct SingleSwapInfo {
        IBalancerVault.SingleSwap singleSwap;
        IBalancerVault.FundManagement funds;
    }

    struct BatchSwapInfo {
        IBalancerVault.SwapKind swapKind;
        IBalancerVault.BatchSwapStep[] swaps;
        address[] route;
        IBalancerVault.FundManagement funds;
        int[] limits;
    }

    /**
     * @dev Swap using a single pool with a custom pool and route.
     * @param _router Address of the router to make the swap.
     * @param _pool Hash of the pool which contains the two tokens to swap between.
     * @param _route Addresses of the tokens in the order of swapping.
     * @param _amountIn Amount of the input token to use in the swap.
     * @return amountCalculated The amount of the output token resulting from the swap.
     */
    function swap(
        IBalancerVault _router,
        bytes32 _pool,
        address[] memory _route,
        uint _amountIn
    ) internal returns (uint) {
        SingleSwapInfo memory swapInfo = getSwapInfo(_pool, _route);
        return swap(_router, swapInfo, _amountIn);
    }

    /**
     * @dev Swap using a single pool with set parameters.
     * @param _router Address of the router to make the swap.
     * @param _swapInfo Pre-determined struct data used to make the swap.
     * @param _amountIn Amount of the input token to use in the swap.
     * @return amountCalculated The amount of the output token resulting from the swap.
     */
    function swap(
        IBalancerVault _router,
        SingleSwapInfo memory _swapInfo,
        uint _amountIn
    ) internal returns (uint) {
        _swapInfo.singleSwap.amount = _amountIn;
        return IBalancerVault(_router).swap(_swapInfo.singleSwap, _swapInfo.funds, 1, block.timestamp);
    }

    /**
     * @dev Swap using multiple pools with custom pools and route.
     * @param _router Address of the router to make the swap.
     * @param _pools Hashes of the pools which contains the tokens to swap between.
     * @param _route Addresses of the tokens in the order of swapping.
     * @param _amountIn Amount of the input token to use in the swap.
     * @return deltaAmounts The signed amount of the token changes occuring in the swap.
     */
    function swap(
        IBalancerVault _router,
        bytes32[] memory _pools,
        address[] memory _route,
        uint _amountIn
    ) internal returns (int[] memory) {
        BatchSwapInfo memory swapInfo = getBatchSwapInfo(_pools, _route);
        swapInfo.swaps[0].amount = _amountIn;
        return IBalancerVault(_router).batchSwap(
            swapInfo.swapKind,
            swapInfo.swaps,
            swapInfo.route,
            swapInfo.funds,
            swapInfo.limits,
            block.timestamp
        );
    }

    /**
     * @dev Swap using multiple pools with set parameters.
     * @param _router Address of the router to make the swap.
     * @param _swapInfo Pre-determined struct data used to make the swap.
     * @param _amountIn Amount of the input token to use in the swap.
     * @return deltaAmounts The signed amount of the token changes occuring in the swap.
     */
    function swap(
        IBalancerVault _router,
        BatchSwapInfo memory _swapInfo,
        uint _amountIn
    ) internal returns (int[] memory) {
        _swapInfo.swaps[0].amount = _amountIn;
        return IBalancerVault(_router).batchSwap(
            _swapInfo.swapKind,
            _swapInfo.swaps,
            _swapInfo.route,
            _swapInfo.funds,
            _swapInfo.limits,
            block.timestamp
        );
    }

    /**
     * @dev Calculate the parameters for a specific swap using a one pool.
     * @param _pool Hash of the pool which contains the two tokens to swap between.
     * @param _route Addresses of the tokens in the order of swapping.
     * @return swapInfo Data used to make the swap for a single pool.
     */
    function getSwapInfo(
        bytes32 _pool,
        address[] memory _route
    ) internal view returns (SingleSwapInfo memory swapInfo) {
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(
            _pool,
            swapKind(),
            _route[0],
            _route[1],
            0,
            ""
        );
        swapInfo = SingleSwapInfo(singleSwap, funds());
    }

    /**
     * @dev Calculate the parameters for a specific swap using multiple pools.
     * @param _pools Hashes of the pools which contain the tokens to swap between.
     * @param _route Addresses of the tokens in the order of swapping.
     * @return swapInfo Data used to make a multi-hop swap.
     */
    function getBatchSwapInfo(
        bytes32[] memory _pools,
        address[] memory _route
    ) internal view returns (BatchSwapInfo memory swapInfo) {
        IBalancerVault.BatchSwapStep[] memory swaps;
        uint poolLength = _pools.length;
        for (uint i; i < poolLength;) {
            swaps[i] = IBalancerVault.BatchSwapStep(_pools[i], i, i+1, 0, "");
            unchecked { ++i; }
        }
        swapInfo = BatchSwapInfo(
            swapKind(),
            swaps,
            _route,
            funds(),
            limits(_route.length)
        );
    }

    /**
     * @dev Add liquidity to a balancer pool.
     * @param _router Address of the router.
     * @param _poolId Hash of the pool to add liquidity to.
     * @param _input Address of the token being deposited to the pool. 
     * @param _amountIn Amount of the input token to add to the pool.
     */
    function addLiquidity(
        address _router,
        bytes32 _poolId,
        address _input,
        uint _amountIn
    ) internal {
        (address[] memory lpTokens,,) = IBalancerVault(_router).getPoolTokens(_poolId);
        uint tokenLength = lpTokens.length;
        uint[] memory amounts = new uint[](tokenLength);
        for (uint i; i < tokenLength;) {
            amounts[i] = lpTokens[i] == _input ? _amountIn : 0;
            unchecked { ++i; }
        }
        bytes memory userData = abi.encode(1, amounts, 1);

        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(
            lpTokens,
            amounts,
            userData,
            false
        );
        IBalancerVault(_router).joinPool(_poolId, address(this), address(this), request);
    }

    /**
     * @dev Estimate the outputs of a swap with custom pools and routes.
     * @param _router Address of the router.
     * @param _pools Hashes of the pools to check the swap amount from.
     * @param _route Addresses of the tokens being swapped in order. 
     * @param _amountIn Amount of the input token to swap.
     * @return amounts Amounts of tokens being output from each swap step.
     */
    function getAmountsOut(
        IBalancerVault _router,
        bytes32[] calldata _pools,
        address[] calldata _route,
        uint _amountIn
    ) internal view returns (uint[] memory) {
        uint poolLength = _pools.length;
        uint[] memory amounts = new uint[](poolLength+1);
        amounts[0] = _amountIn;
        for (uint i; i < poolLength;) {
            amounts[i+1] = getAmountOut(_router, _pools[i], _route[i], _route[i+1], amounts[i]);
            unchecked { ++i; }
        }
        return amounts;
    }

    /**
     * @dev Estimate the outputs of a multi-hop swap with set parameters.
     * @param _router Address of the router.
     * @param _swapInfo Pre-determined struct data used to make a multi-pool swap.
     * @param _amountIn Amount of the input token to swap.
     * @return amounts Amounts of tokens being output from each swap step.
     */
    function getAmountsOut(
        IBalancerVault _router,
        BatchSwapInfo memory _swapInfo,
        uint _amountIn
    ) internal view returns (uint[] memory) {
        uint swapLength = _swapInfo.swaps.length;
        uint[] memory amounts = new uint[](swapLength+1);
        amounts[0] = _amountIn;
        for (uint i; i < swapLength;) {
            amounts[i+1] = getAmountOut(
                _router,
                _swapInfo.swaps[i].poolId,
                _swapInfo.route[i],
                _swapInfo.route[i+1],
                amounts[i]
            );
            unchecked { ++i; }
        }
        return amounts;
    }

    /**
     * @dev Estimate the output of a single swap with custom pool and route.
     * @param _router Address of the router.
     * @param _swapInfo Pre-determined struct data used to make a single swap.
     * @param _amountIn Amount of the input token to swap.
     * @return amount Amount being output from the swap.
     */
    function getAmountOut(
        IBalancerVault _router,
        SingleSwapInfo memory _swapInfo,
        uint _amountIn
    ) internal view returns (uint) {
        return getAmountOut(
            _router,
            _swapInfo.singleSwap.poolId,
            _swapInfo.singleSwap.assetIn,
            _swapInfo.singleSwap.assetOut,
            _amountIn
        );
    }

    /**
     * @dev Estimate the output of a single swap with custom pool and route.
     * @param _router Address of the router.
     * @param _pool Hash of the pool to check the swap amount from.
     * @param _tokenIn Address of the input token being swapped.
     * @param _tokenIn Address of the output token being received.
     * @param _amountIn Amount of the input token to swap.
     * @return amount Amount being output from the swap.
     */
    function getAmountOut(
        IBalancerVault _router,
        bytes32 _pool,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn
    ) internal view returns (uint) {
        uint reserveA;
        uint reserveB;
        (address[] memory tokens, uint[] memory balances,) = 
            IBalancerVault(_router).getPoolTokens(_pool);
        for (uint i; i < tokens.length;) {
            if (tokens[i] == _tokenIn) {
                reserveA = balances[i];
            } else if (tokens[i] == _tokenOut) {
                reserveB = balances[i];
            }
            unchecked { ++i; }
        }
        return _amountIn * reserveB / (reserveA + _amountIn);
    }

    /**
     * @dev Calculate and assign the parameters for a specific swap using multiple pools. Assigning
     * is done here to work around the limitation of copying a memory struct arrary into storage.
     * @param _storedInfo Pointer to assign the swap info to.
     * @param _pools Hashes of the pools which contain the tokens to swap between.
     * @param _route Addresses of the tokens in the order of swapping.
     */
    function assignBatchSwapInfo(
        BatchSwapInfo storage _storedInfo,
        bytes32[] memory _pools,
        address[] memory _route
    ) internal {
        uint poolLength = _pools.length;
        for (uint i; i < poolLength;) {
            _storedInfo.swaps.push(IBalancerVault.BatchSwapStep(_pools[i], i, i+1, 0, ""));
            unchecked { ++i; }
        }
        _storedInfo.swapKind = swapKind();
        _storedInfo.route = _route;
        _storedInfo.funds = funds();
        _storedInfo.limits = limits(_route.length);
    }

    /**
     * @dev Return the swap kind, not stored here due to library restrictions.
     * @return swapkind Enum is always GIVEN_IN.
     */
    function swapKind() private pure returns (IBalancerVault.SwapKind) {
        return IBalancerVault.SwapKind.GIVEN_IN;
    }

    /**
     * @dev Return a completed fund management struct, not stored here due to library restrictions.
     * @return funds Struct is always the same with receiver address the same as sender.
     */
    function funds() private view returns (IBalancerVault.FundManagement memory) {
        return IBalancerVault.FundManagement(
            address(this),
            false,
            payable(address(this)),
            false
        );
    }

    /**
     * @dev Create an array of minimum amounts to receive from swaps.
     * @return limit Uint array initialized with the value of 1.
     */
    function limits(uint _length) private pure returns (int[] memory) {
        int[] memory limit = new int[](_length);
        limit[0] = type(int).max;
        for (uint i = 1; i < _length;) {
            limit[i] = int(0);
            unchecked { ++i; }
        }
        return limit;
    }
}

// File: contracts/BIFI/interfaces/common/IKyberElastic.sol

pragma solidity ^0.8.0;

interface IKyberElastic {
    struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 minAmountOut;
    uint160 limitSqrtP;
  }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function swapExactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
  }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function swapExactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 maxAmountIn;
        uint160 limitSqrtP;
  }


    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function swapExactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
         bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 maxAmountIn;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function swapExactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// File: contracts/BIFI/interfaces/common/IUniswapRouterV3.sol


pragma solidity ^0.8.0;

interface IUniswapRouterV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// File: contracts/BIFI/interfaces/common/IUniswapRouterV3WithDeadline.sol


pragma solidity >=0.6.0;


interface IUniswapRouterV3WithDeadline {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// File: contracts/BIFI/utils/UniV3Actions.sol

pragma solidity ^0.8.0; 
library UniV3Actions {
     // kyber V3 swap
    function kyberSwap(address _router, bytes memory _path, uint256 _amount) internal returns (uint256 amountOut) {
        IKyberElastic.ExactInputParams memory swapParams = IKyberElastic.ExactInputParams({
            path: _path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amount,
            minAmountOut: 0
        });
        return IKyberElastic(_router).swapExactInput(swapParams);
    }

    // Uniswap V3 swap
    function swapV3(address _router, bytes memory _path, uint256 _amount) internal returns (uint256 amountOut) {
        IUniswapRouterV3.ExactInputParams memory swapParams = IUniswapRouterV3.ExactInputParams({
            path: _path,
            recipient: address(this),
            amountIn: _amount,
            amountOutMinimum: 0
        });
        return IUniswapRouterV3(_router).exactInput(swapParams);
    }

    // Uniswap V3 swap with deadline
    function swapV3WithDeadline(address _router, bytes memory _path, uint256 _amount) internal returns (uint256 amountOut) {
        IUniswapRouterV3WithDeadline.ExactInputParams memory swapParams = IUniswapRouterV3WithDeadline.ExactInputParams({
            path: _path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amount,
            amountOutMinimum: 0
        });
        return IUniswapRouterV3WithDeadline(_router).exactInput(swapParams);
    }

    // Uniswap V3 swap with deadline
    function swapV3WithDeadline(address _router, bytes memory _path, uint256 _amount, address _to) internal returns (uint256 amountOut) {
        IUniswapRouterV3WithDeadline.ExactInputParams memory swapParams = IUniswapRouterV3WithDeadline.ExactInputParams({
            path: _path,
            recipient: _to,
            deadline: block.timestamp,
            amountIn: _amount,
            amountOutMinimum: 0
        });
        return IUniswapRouterV3WithDeadline(_router).exactInput(swapParams);
    }
}

// File: contracts/BIFI/strategies/Balancer/StrategyAuraBalSingle.sol


pragma solidity ^0.8.0;
interface IBalancerPool {
    function getPoolId() external view returns (bytes32);
}

interface IAuraLocker {
    function deposit(uint256 _amount, bool _lock) external;
}

contract StrategyAuraBalSingle is StratFeeManagerInitializable {
    using SafeERC20 for IERC20;

    // Tokens used
    address public want;
    address public bpt;
    address public output;
    address public native;
    bytes32 public auraBalBptPoolId;

    BeefyBalancerStructs.Input public input;

    // Third party contracts
    address public rewardPool;
    address public locker;
    bool public shouldLock;

    IBalancerVault.SwapKind public swapKind;
    IBalancerVault.FundManagement public funds;

    BeefyBalancerStructs.BatchSwapStruct[] public nativeToInputRoute;
    BeefyBalancerStructs.BatchSwapStruct[] public outputToNativeRoute;
    address[] public nativeToInputAssets;
    address[] public outputToNativeAssets;

    mapping(address => BeefyBalancerStructs.Reward) public rewards;
    address[] public rewardTokens;

    address public uniswapRouter;
    bool public harvestOnDeposit;
    uint256 public lastHarvest;
    uint256 public lastSweep;

    event StratHarvest(address indexed harvester, uint256 indexed wantHarvested, uint256 indexed tvl);
    event Deposit(uint256 indexed tvl);
    event Withdraw(uint256 indexed tvl);
    event ChargedFees(uint256 indexed callFees, uint256 indexed beefyFees, uint256 indexed strategistFees);

    function initialize(
        address _want,
        address _bpt,
        bool _inputIsComposable,
        BeefyBalancerStructs.BatchSwapStruct[] memory _nativeToInputRoute,
        BeefyBalancerStructs.BatchSwapStruct[] memory _outputToNativeRoute,
        address _rewardPool,
        address _locker,
        bytes32 _auraBalBptPoolId,
        address[] memory _nativeToInput,
        address[] memory _outputToNative,
        CommonAddresses calldata _commonAddresses
    ) public initializer  {
        __StratFeeManager_init(_commonAddresses);

        for (uint i; i < _nativeToInputRoute.length;) {
            nativeToInputRoute.push(_nativeToInputRoute[i]);
            unchecked {
                ++i;
            }
        }

        for (uint j; j < _outputToNativeRoute.length;) {
            outputToNativeRoute.push(_outputToNativeRoute[j]);
            unchecked {
                ++j;
            }
        }

        want = _want;
        bpt = _bpt; 
        auraBalBptPoolId = _auraBalBptPoolId;
        outputToNativeAssets = _outputToNative;
        nativeToInputAssets = _nativeToInput;
        output = outputToNativeAssets[0];
        native = nativeToInputAssets[0];
        input.input = nativeToInputAssets[nativeToInputAssets.length - 1];
        input.isComposable = _inputIsComposable;
        uniswapRouter = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        rewardPool = _rewardPool;
        locker = _locker;

        swapKind = IBalancerVault.SwapKind.GIVEN_IN;
        funds = IBalancerVault.FundManagement(address(this), false, payable(address(this)), false);

        _giveAllowances();
    }

    function deposit() public whenNotPaused {}
    
    // puts the funds to work
    function _deposit() internal whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IAuraRewardPool(rewardPool).stake(wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IAuraRewardPool(rewardPool).withdraw(_amount - wantBal, false);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        if (tx.origin != owner() && !paused()) {
            uint256 withdrawalFeeAmount = wantBal * withdrawalFee / WITHDRAWAL_MAX;
            wantBal = wantBal - withdrawalFeeAmount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "!vault");
            _harvest(tx.origin);
        }
    }

    function harvest() external virtual {
        _harvest(tx.origin);
    }

    function harvest(address callFeeRecipient) external virtual {
        _harvest(callFeeRecipient);
    }

    function managerHarvest() external onlyManager {
        _harvest(tx.origin);
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal whenNotPaused {
        _deposit();
        IAuraRewardPool(rewardPool).getReward();
        swapRewardsToNative();
        uint256 nativeBal = IERC20(native).balanceOf(address(this));

        if (nativeBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            _deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    function swapRewardsToNative() internal {
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        if (outputBal > 0) {
            IBalancerVault.BatchSwapStep[] memory _swaps = BalancerActionsLib.buildSwapStructArray(outputToNativeRoute, outputBal);
            BalancerActionsLib.balancerSwap(unirouter, swapKind, _swaps, outputToNativeAssets, funds, int256(outputBal));
        }
        // extras
        for (uint i; i < rewardTokens.length;) {
            uint bal = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (bal >= rewards[rewardTokens[i]].minAmount) {
                if (rewards[rewardTokens[i]].assets[0] != address(0)) {
                    BeefyBalancerStructs.BatchSwapStruct[] memory swapInfo = new BeefyBalancerStructs.BatchSwapStruct[](rewards[rewardTokens[i]].assets.length - 1);
                    for (uint j; j < rewards[rewardTokens[i]].assets.length - 1;) {
                        swapInfo[j] = rewards[rewardTokens[i]].swapInfo[j];
                    unchecked {
                        ++j;
                    }
                    }
                    IBalancerVault.BatchSwapStep[] memory _swaps = BalancerActionsLib.buildSwapStructArray(swapInfo, bal);
                    BalancerActionsLib.balancerSwap(unirouter, swapKind, _swaps, rewards[rewardTokens[i]].assets, funds, int256(bal));
                } else {
                    UniV3Actions.swapV3WithDeadline(uniswapRouter, rewards[rewardTokens[i]].routeToNative, bal);
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        IFeeConfig.FeeCategory memory fees = getFees();
        uint256 nativeBal = IERC20(native).balanceOf(address(this)) * fees.total / DIVISOR;

        uint256 callFeeAmount = nativeBal * fees.call / DIVISOR;
        IERC20(native).safeTransfer(callFeeRecipient, callFeeAmount);

        uint256 beefyFeeAmount = nativeBal * fees.beefy / DIVISOR;
        IERC20(native).safeTransfer(beefyFeeRecipient, beefyFeeAmount);

        uint256 strategistFeeAmount = nativeBal * fees.strategist / DIVISOR;
        IERC20(native).safeTransfer(strategist, strategistFeeAmount);

        emit ChargedFees(callFeeAmount, beefyFeeAmount, strategistFeeAmount);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 nativeBal = IERC20(native).balanceOf(address(this));        
        if (native != input.input) {
            IBalancerVault.BatchSwapStep[] memory _swaps = BalancerActionsLib.buildSwapStructArray(nativeToInputRoute, nativeBal);
            BalancerActionsLib.balancerSwap(unirouter, swapKind, _swaps, nativeToInputAssets, funds, int256(nativeBal));
        }

        uint256 inputBal = IERC20(input.input).balanceOf(address(this));
        BalancerActionsLib.balancerJoin(unirouter, IBalancerPool(want).getPoolId(), input.input, inputBal);

        IBalancerVault router = IBalancerVault(unirouter);
        uint256 bptBal = IERC20(bpt).balanceOf(address(this));
        uint swapAmount = BalancerUtils.getAmountOut(router, auraBalBptPoolId, bpt, want, bptBal);

        if (swapAmount > bptBal) {
            address[] memory route = new address[](2);
            route[0] = bpt;
            route[1] = want;
            BalancerUtils.swap(router, auraBalBptPoolId, route, bptBal);
        } else {
            IAuraLocker(locker).deposit(bptBal, shouldLock);
        }
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return IAuraRewardPool(rewardPool).balanceOf(address(this));
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return IAuraRewardPool(rewardPool).earned(address(this));
    }

    // native reward amount for calling harvest
    function callReward() public pure returns (uint256) {
        return 0; // multiple swap providers with no easy way to estimate native output.
    }

    function addRewardToken(address _token, BeefyBalancerStructs.BatchSwapStruct[] memory _swapInfo, address[] memory _assets, bytes calldata _routeToNative, uint _minAmount) external onlyOwner {
        require(_token != want, "!want");
        require(_token != native, "!native");
        if (_assets[0] != address(0)) {
            IERC20(_token).safeApprove(unirouter, 0);
            IERC20(_token).safeApprove(unirouter, type(uint).max);
        } else {
            IERC20(_token).safeApprove(uniswapRouter, 0);
            IERC20(_token).safeApprove(uniswapRouter, type(uint).max);
        }

        rewards[_token].assets = _assets;
        rewards[_token].routeToNative = _routeToNative;
        rewards[_token].minAmount = _minAmount;

        for (uint i; i < _swapInfo.length; ) {
            rewards[_token].swapInfo[i].poolId = _swapInfo[i].poolId;
            rewards[_token].swapInfo[i].assetInIndex = _swapInfo[i].assetInIndex;
            rewards[_token].swapInfo[i].assetOutIndex = _swapInfo[i].assetOutIndex;
            unchecked {
                ++i;
            }
        }
        rewardTokens.push(_token);
    }

    function resetRewardTokens() external onlyManager {
        for (uint i; i < rewardTokens.length;) {
            delete rewards[rewardTokens[i]];
        unchecked { ++i; }
        }
        delete rewardTokens;
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;

        if (harvestOnDeposit) {
            setWithdrawalFee(0);
        } else {
            setWithdrawalFee(10);
        }
    }
    
    // should we pay the gas cost to lock for the system instead of pay a fee?
    function setShouldLock(bool _lock) external onlyManager {
        shouldLock = _lock;
    }

    function sweep() external {
        _deposit();
        lastSweep = block.timestamp;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        IAuraRewardPool(rewardPool).withdraw(balanceOfPool(), false);

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        IAuraRewardPool(rewardPool).withdraw(balanceOfPool(), false);
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(rewardPool, type(uint).max);
        IERC20(output).safeApprove(unirouter, type(uint).max);
        IERC20(bpt).safeApprove(locker, type(uint).max);
        IERC20(bpt).safeApprove(unirouter, type(uint).max);
        IERC20(native).safeApprove(unirouter, type(uint).max);
        if (rewardTokens.length != 0) {
            for (uint i; i < rewardTokens.length; ++i) {
                if (rewards[rewardTokens[i]].assets[0] != address(0)) {
                    IERC20(rewardTokens[i]).safeApprove(unirouter, 0);
                    IERC20(rewardTokens[i]).safeApprove(unirouter, type(uint).max);
                } else {
                    IERC20(rewardTokens[i]).safeApprove(uniswapRouter, 0);
                    IERC20(rewardTokens[i]).safeApprove(uniswapRouter, type(uint).max);
                }
            }
        }
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(rewardPool, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(native).safeApprove(unirouter, 0);
        IERC20(bpt).safeApprove(locker, 0);
        IERC20(bpt).safeApprove(unirouter, 0);
        if (rewardTokens.length != 0) {
            for (uint i; i < rewardTokens.length; ++i) {
                if (rewards[rewardTokens[i]].assets[0] != address(0)) {
                    IERC20(rewardTokens[i]).safeApprove(unirouter, 0);
                } else {
                    IERC20(rewardTokens[i]).safeApprove(uniswapRouter, 0);
                }
            }
        }
    }
}