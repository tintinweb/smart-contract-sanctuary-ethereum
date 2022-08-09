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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./utils/LiquidationReentrancyGuard.sol";

import "./interfaces/IBaseSilo.sol";
import "./interfaces/IGuardedLaunch.sol";
import "./interfaces/ISiloRepository.sol";
import "./interfaces/IPriceProvidersRepository.sol";
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/IShareToken.sol";

import "./lib/Ping.sol";
import "./lib/EasyMath.sol";
import "./lib/TokenHelper.sol";
import "./lib/Solvency.sol";

/// @title BaseSilo
/// @dev Base contract for Silo core logic.
/// @custom:security-contact [email protected]
abstract contract BaseSilo is IBaseSilo, ReentrancyGuard, LiquidationReentrancyGuard {
    using SafeERC20 for ERC20;
    using EasyMath for uint256;

    ISiloRepository immutable public override siloRepository;

    // asset address for which Silo was created
    address public immutable siloAsset;

    /// @dev version of silo
    /// @notice It tells us which `SiloRepository.siloFactory(version)` created this Silo
    uint128 public immutable VERSION; // solhint-disable-line var-name-mixedcase

    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable _ASSET_DECIMAL_POINTS;

    /// @dev stores all *synced* assets (bridge assets + removed bridge assets + siloAsset)
    address[] private _allSiloAssets;

    /// @dev asset => AssetStorage
    mapping(address => AssetStorage) private _assetStorage;

    /// @dev asset => AssetInterestData
    mapping(address => AssetInterestData) private _interestData;

    error AssetDoesNotExist();
    error BorrowNotPossible();
    error DepositNotPossible();
    error DepositsExceedLimit();
    error InvalidRepository();
    error InvalidSiloVersion();
    error MaximumLTVReached();
    error NotEnoughLiquidity();
    error NotEnoughDeposits();
    error NotSolvent();
    error OnlyRouter();
    error Paused();
    error UnexpectedEmptyReturn();
    error UserIsZero();

    modifier onlyExistingAsset(address _asset) {
        if (_interestData[_asset].status == AssetStatus.Undefined) {
            revert AssetDoesNotExist();
        }

        _;
    }

    modifier onlyRouter() {
        if (msg.sender != siloRepository.router()) revert OnlyRouter();

        _;
    }

    modifier validateMaxDepositsAfter(address _asset) {
        _;

        IPriceProvidersRepository priceProviderRepo = siloRepository.priceProvidersRepository();

        AssetStorage storage _assetState = _assetStorage[_asset];
        uint256 allDeposits = _assetState.totalDeposits + _assetState.collateralOnlyDeposits;

        if (
            priceProviderRepo.getPrice(_asset) * allDeposits / (10 ** IERC20Metadata(_asset).decimals()) >
            IGuardedLaunch(address(siloRepository)).getMaxSiloDepositsValue(address(this), _asset)
        ) {
            revert DepositsExceedLimit();
        }
    }

    constructor (ISiloRepository _repository, address _siloAsset, uint128 _version) {
        if (!Ping.pong(_repository.siloRepositoryPing)) revert InvalidRepository();
        if (_version == 0) revert InvalidSiloVersion();

        uint256 decimals = TokenHelper.assertAndGetDecimals(_siloAsset);

        VERSION = _version;
        siloRepository = _repository;
        siloAsset = _siloAsset;
        _ASSET_DECIMAL_POINTS = 10**decimals;
    }

    /// @dev this is exposed only for test purposes, but it is safe to leave it like that
    function initAssetsTokens() external nonReentrant {
        _initAssetsTokens();
    }

    /// @inheritdoc IBaseSilo
    function syncBridgeAssets() external override nonReentrant {
        // sync removed assets
        address[] memory removedBridgeAssets = siloRepository.getRemovedBridgeAssets();

        for (uint256 i = 0; i < removedBridgeAssets.length; i++) {
            // If removed bridge asset is the silo asset for this silo, do not remove it
            address removedBridgeAsset = removedBridgeAssets[i];
            if (removedBridgeAsset != siloAsset) {
                _interestData[removedBridgeAsset].status = AssetStatus.Removed;
                emit AssetStatusUpdate(removedBridgeAsset, AssetStatus.Removed);
            }
        }

        // must be called at the end, because we overriding `_assetStorage[removedBridgeAssets[i]].removed`
        _initAssetsTokens();
    }

    /// @inheritdoc IBaseSilo
    function assetStorage(address _asset) external view override returns (AssetStorage memory) {
        return _assetStorage[_asset];
    }

    /// @inheritdoc IBaseSilo
    function interestData(address _asset) external view override returns (AssetInterestData memory) {
        return _interestData[_asset];
    }

    /// @inheritdoc IBaseSilo
    function utilizationData(address _asset) external view override returns (UtilizationData memory data) {
        AssetStorage storage _assetState = _assetStorage[_asset];

        return UtilizationData(
            _assetState.totalDeposits,
            _assetState.totalBorrowAmount,
            _interestData[_asset].interestRateTimestamp
        );
    }

    /// @inheritdoc IBaseSilo
    function getAssets() public view override returns (address[] memory assets) {
        return _allSiloAssets;
    }

    /// @inheritdoc IBaseSilo
    function getAssetsWithState() public view override returns (
        address[] memory assets,
        AssetStorage[] memory assetsStorage
    ) {
        assets = _allSiloAssets;
        assetsStorage = new AssetStorage[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            assetsStorage[i] = _assetStorage[assets[i]];
        }
    }

    /// @inheritdoc IBaseSilo
    function isSolvent(address _user) public view override returns (bool) {
        if (_user == address(0)) revert UserIsZero();

        (address[] memory assets, AssetStorage[] memory assetsStates) = getAssetsWithState();

        (uint256 userLTV, uint256 liquidationThreshold) = Solvency.calculateLTVs(
            Solvency.SolvencyParams(
                siloRepository,
                ISilo(address(this)),
                assets,
                assetsStates,
                _user
            ),
            Solvency.TypeofLTV.LiquidationThreshold
        );

        return userLTV <= liquidationThreshold;
    }

    /// @inheritdoc IBaseSilo
    function depositPossible(address _asset, address _depositor) public view override returns (bool) {
        return _assetStorage[_asset].debtToken.balanceOf(_depositor) == 0
            && _interestData[_asset].status == AssetStatus.Active;
    }

    /// @inheritdoc IBaseSilo
    function borrowPossible(address _asset, address _borrower) public view override returns (bool) {
        AssetStorage storage _assetState = _assetStorage[_asset];

        return _assetState.collateralToken.balanceOf(_borrower) == 0
            && _assetState.collateralOnlyToken.balanceOf(_borrower) == 0
            && _interestData[_asset].status == AssetStatus.Active;
    }

    /// @inheritdoc IBaseSilo
    function liquidity(address _asset) public view returns (uint256) {
        return ERC20(_asset).balanceOf(address(this)) - _assetStorage[_asset].collateralOnlyDeposits;
    }

    /// @dev Initiate asset by deploying accounting EC20 tokens for collateral and debt
    /// @param _tokensFactory factory contract that deploys collateral and debt tokens
    /// @param _asset which asset to initialize
    /// @param _isBridgeAsset true if initialized asset is a bridge asset
    function _initAsset(ITokensFactory _tokensFactory, address _asset, bool _isBridgeAsset) internal {
        AssetSharesMetadata memory metadata = _generateSharesNames(_asset, _isBridgeAsset);

        AssetStorage storage _assetState = _assetStorage[_asset];

        _assetState.collateralToken = _tokensFactory.createShareCollateralToken(
            metadata.collateralName, metadata.collateralSymbol, _asset
        );

        _assetState.collateralOnlyToken = _tokensFactory.createShareCollateralToken(
            metadata.protectedName, metadata.protectedSymbol, _asset
        );

        _assetState.debtToken = _tokensFactory.createShareDebtToken(
            metadata.debtName, metadata.debtSymbol, _asset
        );

        // keep synced asset in storage array
        _allSiloAssets.push(_asset);
        _interestData[_asset].status = AssetStatus.Active;
        emit AssetStatusUpdate(_asset, AssetStatus.Active);
    }

    /// @dev Initializes all assets (bridge assets + unique asset) for Silo but only if asset has not been
    /// initialized already. It's safe to call it multiple times. It's safe for anyone to call it at any time.
    function _initAssetsTokens() internal {
        ITokensFactory tokensFactory = siloRepository.tokensFactory();

        // init silo asset if needed
        if (address(_assetStorage[siloAsset].collateralToken) == address(0)) {
            _initAsset(tokensFactory, siloAsset, false);
        }

        // sync active assets
        address[] memory bridgeAssets = siloRepository.getBridgeAssets();

        for (uint256 i = 0; i < bridgeAssets.length; i++) {
            address bridgeAsset = bridgeAssets[i];
            // In case a bridge asset is added that already has a Silo,
            // do not initiate that asset in its Silo
            if (address(_assetStorage[bridgeAsset].collateralToken) == address(0)) {
                _initAsset(tokensFactory, bridgeAsset, true);
            } else {
                _interestData[bridgeAsset].status = AssetStatus.Active;
                emit AssetStatusUpdate(bridgeAsset, AssetStatus.Active);
            }
        }
    }

    /// @dev Generate asset shares tokens names and symbols
    /// @param _asset asset for which shares tokens will be initializaed
    /// @param _isBridgeAsset true if initialized asset is a bridge asset
    function _generateSharesNames(address _asset, bool _isBridgeAsset)
        internal
        view
        returns (AssetSharesMetadata memory metadata)
    {
        // Naming convention in UNI example:
        // - for siloAsset: sUNI, dUNI, spUNI
        // - for bridgeAsset: sWETH-UNI, dWETH-UNI, spWETH-UNI
        string memory assetSymbol = TokenHelper.symbol(_asset);

        metadata = AssetSharesMetadata({
            collateralName: string.concat("Silo Finance Borrowable ", assetSymbol, " Deposit"),
            collateralSymbol: string.concat("s", assetSymbol),
            protectedName: string.concat("Silo Finance Protected ", assetSymbol, " Deposit"),
            protectedSymbol: string.concat("sp", assetSymbol),
            debtName: string.concat("Silo Finance ", assetSymbol, " Debt"),
            debtSymbol: string.concat("d", assetSymbol)
        });

        if (_isBridgeAsset) {
            string memory baseSymbol = TokenHelper.symbol(siloAsset);

            metadata.collateralName = string.concat(metadata.collateralName, " in ", baseSymbol, " Silo");
            metadata.collateralSymbol = string.concat(metadata.collateralSymbol, "-", baseSymbol);

            metadata.protectedName = string.concat(metadata.protectedName, " in ", baseSymbol, " Silo");
            metadata.protectedSymbol = string.concat(metadata.protectedSymbol, "-", baseSymbol);

            metadata.debtName = string.concat(metadata.debtName, " in ", baseSymbol, " Silo");
            metadata.debtSymbol = string.concat(metadata.debtSymbol, "-", baseSymbol);
        }
    }

    /// @dev Main deposit function that handles all deposit logic and validation
    /// @param _asset asset address that is being deposited
    /// @param _from wallet address form which to pull asset tokens
    /// @param _depositor wallet address that will be granted ownership of deposited tokens. Keep in mind
    /// that deposit can be made by Router contract but the owner of the deposit should be user.
    /// @param _amount deposit amount
    /// @param _collateralOnly true if deposit should be used for collateral only. Otherwise false.
    /// Collateral only deposit cannot be borrowed by anyone and does not earn any interest. However,
    /// it can be used as collateral and can be subject to liquidation.
    /// @return collateralAmount deposited amount
    /// @return collateralShare `_depositor` collateral shares based on deposited amount
    function _deposit(
        address _asset,
        address _from,
        address _depositor,
        uint256 _amount,
        bool _collateralOnly
    )
        internal
        nonReentrant
        validateMaxDepositsAfter(_asset)
        returns (uint256 collateralAmount, uint256 collateralShare)
    {
        // MUST BE CALLED AS FIRST METHOD!
        _accrueInterest(_asset);

        if (!depositPossible(_asset, _depositor)) revert DepositNotPossible();

        AssetStorage storage _state = _assetStorage[_asset];

        collateralAmount = _amount;

        uint256 totalDepositsCached = _collateralOnly ? _state.collateralOnlyDeposits : _state.totalDeposits;

        if (_collateralOnly) {
            collateralShare = _amount.toShare(totalDepositsCached, _state.collateralOnlyToken.totalSupply());
            _state.collateralOnlyDeposits = totalDepositsCached + _amount;
            _state.collateralOnlyToken.mint(_depositor, collateralShare);
        } else {
            collateralShare = _amount.toShare(totalDepositsCached, _state.collateralToken.totalSupply());
            _state.totalDeposits = totalDepositsCached + _amount;
            _state.collateralToken.mint(_depositor, collateralShare);
        }

        ERC20(_asset).safeTransferFrom(_from, address(this), _amount);

        emit Deposit(_asset, _depositor, _amount, _collateralOnly);
    }

    /// @dev Main withdraw function that handles all withdraw logic and validation
    /// @param _asset asset address that is being withdrawn
    /// @param _depositor wallet address that is an owner of the deposited tokens
    /// @param _receiver wallet address that will receive withdrawn tokens. It's possible that Router
    /// contract is the owner of deposited tokens but we want user to get these tokens directly.
    /// @param _amount amount to withdraw. If amount is equal to maximum value stored by uint256 type
    /// (type(uint256).max), it will be assumed that user wants to withdraw all tokens and final account
    /// will be dynamically calculated including interest.
    /// @param _collateralOnly true if collateral only tokens are to be withdrawn. Otherwise false.
    /// User can deposit the same asset as collateral only and as regular deposit. During withdraw,
    /// it must be specified which tokens are to be withdrawn.
    /// @return withdrawnAmount withdrawn amount that was transferred to user
    /// @return withdrawnShare burned share based on `withdrawnAmount`
    function _withdraw(address _asset, address _depositor, address _receiver, uint256 _amount, bool _collateralOnly)
        internal
        nonReentrant // because we transferring tokens
        onlyExistingAsset(_asset)
        returns (uint256 withdrawnAmount, uint256 withdrawnShare)
    {
        // MUST BE CALLED AS FIRST METHOD!
        _accrueInterest(_asset);

        (withdrawnAmount, withdrawnShare) = _withdrawAsset(
            _asset,
            _amount,
            _depositor,
            _receiver,
            _collateralOnly,
            0 // do not apply any fees on regular withdraw
        );

        if (withdrawnAmount == 0) revert UnexpectedEmptyReturn();

        if (!isSolvent(_depositor)) revert NotSolvent();

        emit Withdraw(_asset, _depositor, _receiver, withdrawnAmount, _collateralOnly);
    }

    /// @dev Main borrow function that handles all borrow logic and validation
    /// @param _asset asset address that is being borrowed
    /// @param _borrower wallet address that will own debt
    /// @param _receiver wallet address that will receive borrowed tokens. It's possible that Router
    /// contract is executing borrowing for user and should be the one receiving tokens, however,
    /// the owner of the debt should be user himself.
    /// @param _amount amount of asset to borrow
    /// @return debtAmount borrowed amount
    /// @return debtShare user debt share based on borrowed amount
    function _borrow(address _asset, address _borrower, address _receiver, uint256 _amount)
        internal
        nonReentrant
        returns (uint256 debtAmount, uint256 debtShare)
    {
        // MUST BE CALLED AS FIRST METHOD!
        _accrueInterest(_asset);

        if (!borrowPossible(_asset, _borrower)) revert BorrowNotPossible();

        if (liquidity(_asset) < _amount) revert NotEnoughLiquidity();

        AssetStorage storage _state = _assetStorage[_asset];

        uint256 totalBorrowAmount = _state.totalBorrowAmount;
        uint256 entryFee = siloRepository.entryFee();
        uint256 fee = entryFee == 0 ? 0 : _amount * entryFee / Solvency._PRECISION_DECIMALS;
        debtShare = (_amount + fee).toShareRoundUp(totalBorrowAmount, _state.debtToken.totalSupply());
        debtAmount = _amount;

        _state.totalBorrowAmount = totalBorrowAmount + _amount + fee;
        _interestData[_asset].protocolFees += fee;

        _state.debtToken.mint(_borrower, debtShare);

        emit Borrow(_asset, _borrower, _amount);
        ERC20(_asset).safeTransfer(_receiver, _amount);

        // IMPORTANT - keep `validateBorrowAfter` at the end
        _validateBorrowAfter(_borrower);
    }

    /// @dev Main repay function that handles all repay logic and validation
    /// @param _asset asset address that is being repaid
    /// @param _borrower wallet address for which debt is being repaid
    /// @param _repayer wallet address that will pay the debt. It's possible that Router
    /// contract is executing repay for user and should be the one paying the debt.
    /// @param _amount amount of asset to repay
    /// @return repaidAmount amount repaid
    /// @return repaidShare burned debt share
    function _repay(address _asset, address _borrower, address _repayer, uint256 _amount)
        internal
        onlyExistingAsset(_asset)
        nonReentrant
        returns (uint256 repaidAmount, uint256 repaidShare)
    {
        // MUST BE CALLED AS FIRST METHOD!
        _accrueInterest(_asset);

        AssetStorage storage _state = _assetStorage[_asset];
        (repaidAmount, repaidShare) = _calculateDebtAmountAndShare(_state, _borrower, _amount);

        if (repaidShare == 0) revert UnexpectedEmptyReturn();

        emit Repay(_asset, _borrower, repaidAmount);

        ERC20(_asset).safeTransferFrom(_repayer, address(this), repaidAmount);

        // change debt state before, because share token state is changes the same way (notification is after burn)
        _state.totalBorrowAmount -= repaidAmount;
        _state.debtToken.burn(_borrower, repaidShare);
    }

    /// @param _assets all current assets, this is an optimization, so we don't have to read it from storage few times
    /// @param _user user to liquidate
    /// @param _flashReceiver address which will get all collaterals and will be notified once collaterals will be send
    /// @param _flashReceiverData custom data to forward to receiver
    /// @return receivedCollaterals amounts of collaterals transferred to `_flashReceiver`
    /// @return shareAmountsToRepay expected amounts to repay
    function _userLiquidation(
        address[] memory _assets,
        address _user,
        IFlashLiquidationReceiver _flashReceiver,
        bytes memory _flashReceiverData
    )
        internal
        // we can not use `nonReentrant` because we are using it in `_repay`,
        // and `_repay` needs to be reentered as part of a liquidation
        liquidationNonReentrant
        returns (uint256[] memory receivedCollaterals, uint256[] memory shareAmountsToRepay)
    {
        // gracefully fail if _user is solvent
        if (isSolvent(_user)) {
            uint256[] memory empty = new uint256[](_assets.length);
            return (empty, empty);
        }

        (receivedCollaterals, shareAmountsToRepay) = _flashUserLiquidation(_assets, _user, address(_flashReceiver));

        // _flashReceiver needs to repayFor user
        _flashReceiver.siloLiquidationCallback(
            _user,
            _assets,
            receivedCollaterals,
            shareAmountsToRepay,
            _flashReceiverData
        );

        for (uint256 i = 0; i < _assets.length; i++) {
            if (receivedCollaterals[i] != 0 || shareAmountsToRepay[i] != 0) {
                emit Liquidate(_assets[i], _user, shareAmountsToRepay[i], receivedCollaterals[i]);
            }
        }

        if (!isSolvent(_user)) revert NotSolvent();
    }

    function _flashUserLiquidation(address[] memory _assets, address _borrower, address _liquidator)
        internal
        returns (uint256[] memory receivedCollaterals, uint256[] memory amountsToRepay)
    {
        uint256 assetsLength = _assets.length;
        receivedCollaterals = new uint256[](assetsLength);
        amountsToRepay = new uint256[](assetsLength);

        uint256 protocolLiquidationFee = siloRepository.protocolLiquidationFee();

        for (uint256 i = 0; i < assetsLength; i++) {
            _accrueInterest(_assets[i]);

            AssetStorage storage _state = _assetStorage[_assets[i]];

            // we do not allow for partial repayment on liquidation, that's why max
            (amountsToRepay[i],) = _calculateDebtAmountAndShare(_state, _borrower, type(uint256).max);

            (uint256 withdrawnOnlyAmount,) = _withdrawAsset(
                _assets[i],
                type(uint256).max,
                _borrower,
                _liquidator,
                true, // collateral only
                protocolLiquidationFee
            );

            (uint256 withdrawnAmount,) = _withdrawAsset(
                _assets[i],
                type(uint256).max,
                _borrower,
                _liquidator,
                false, // collateral only
                protocolLiquidationFee
            );

            receivedCollaterals[i] = withdrawnOnlyAmount + withdrawnAmount;
        }
    }

    /// @dev Utility function for withdrawing an asset
    /// @param _asset asset to withdraw
    /// @param _assetAmount amount of asset to withdraw
    /// @param _depositor wallet address that is an owner of the deposit
    /// @param _receiver wallet address that is receiving the token
    /// @param _collateralOnly true if withdraw collateral only.
    /// @param _protocolLiquidationFee if provided (!=0) liquidation fees will be applied and returned
    /// `withdrawnAmount` will be decreased
    /// @return withdrawnAmount amount of asset that has been sent to receiver
    /// @return burnedShare burned share based on `withdrawnAmount`
    function _withdrawAsset(
        address _asset,
        uint256 _assetAmount,
        address _depositor,
        address _receiver,
        bool _collateralOnly,
        uint256 _protocolLiquidationFee
    )
        internal
        returns (uint256 withdrawnAmount, uint256 burnedShare)
    {
        (uint256 assetTotalDeposits, IShareToken shareToken, uint256 availableLiquidity) =
            _getWithdrawAssetData(_asset, _collateralOnly);

        if (_assetAmount == type(uint256).max) {
            burnedShare = shareToken.balanceOf(_depositor);
            withdrawnAmount = burnedShare.toAmount(assetTotalDeposits, shareToken.totalSupply());
        } else {
            burnedShare = _assetAmount.toShareRoundUp(assetTotalDeposits, shareToken.totalSupply());
            withdrawnAmount = _assetAmount;
        }

        if (withdrawnAmount == 0) {
            // we can not revert here, because liquidation will fail when one of collaterals will be empty
            return (0, 0);
        }

        if (assetTotalDeposits < withdrawnAmount) revert NotEnoughDeposits();

        unchecked {
            // can be unchecked because of the `if` above
            assetTotalDeposits -=  withdrawnAmount;
        }

        uint256 amountToTransfer = _applyLiquidationFee(_asset, withdrawnAmount, _protocolLiquidationFee);

        if (availableLiquidity < amountToTransfer) revert NotEnoughLiquidity();

        AssetStorage storage _state = _assetStorage[_asset];

        if (_collateralOnly) {
            _state.collateralOnlyDeposits = assetTotalDeposits;
        } else {
            _state.totalDeposits = assetTotalDeposits;
        }

        shareToken.burn(_depositor, burnedShare);
        // in case token sent in fee-on-transfer type of token we do not care when withdrawing
        ERC20(_asset).safeTransfer(_receiver, amountToTransfer);
    }

    /// @notice Calculates liquidations fee and returns amount of asset transferred to liquidator
    /// @param _asset asset address
    /// @param _amount amount on which we will apply fee
    /// @param _protocolLiquidationFee liquidation fee in Solvency._PRECISION_DECIMALS
    /// @return change amount left after subtracting liquidation fee
    function _applyLiquidationFee(address _asset, uint256 _amount, uint256 _protocolLiquidationFee)
        internal
        returns (uint256 change)
    {
        if (_protocolLiquidationFee == 0) {
            return _amount;
        }

        uint256 liquidationFeeAmount;

        (
            liquidationFeeAmount,
            _interestData[_asset].protocolFees
        ) = Solvency.calculateLiquidationFee(_interestData[_asset].protocolFees, _amount, _protocolLiquidationFee);

        unchecked {
            // if fees will not be higher than 100% this will not underflow, this is responsibility of siloRepository
            // in case we do underflow, we can expect liquidator reject tx because of too little change
            change = _amount - liquidationFeeAmount;
        }
    }

    /// @dev harvest protocol fees from particular asset
    /// @param _asset asset we want to harvest fees from
    /// @param _receiver address of fees receiver
    /// @return harvestedFees harvested fee
    function _harvestProtocolFees(address _asset, address _receiver)
        internal
        nonReentrant
        returns (uint256 harvestedFees)
    {
        AssetInterestData storage data = _interestData[_asset];

        harvestedFees = data.protocolFees - data.harvestedProtocolFees;

        uint256 currentLiquidity = liquidity(_asset);

        if (harvestedFees > currentLiquidity) {
            harvestedFees = currentLiquidity;
        }

        if (harvestedFees == 0) {
            return 0;
        }

        unchecked {
            // This can't overflow because this addition is less than or equal to data.protocolFees
            data.harvestedProtocolFees += harvestedFees;
        }

        ERC20(_asset).safeTransfer(_receiver, harvestedFees);
    }

    /// @notice Accrue interest for asset
    /// @dev Silo Interest Rate Model implements dynamic interest rate that changes every second. Returned
    /// interest rate by the model is compounded rate so it can be used in math calculations as if it was
    /// static. Rate is calculated for the time range between last update and current timestamp.
    /// @param _asset address of the asset for which interest should be accrued
    /// @return accruedInterest total accrued interest
    function _accrueInterest(address _asset) internal returns (uint256 accruedInterest) {
        /// @dev `_accrueInterest` is called on every user action, including liquidation. It's enough to check
        /// if Silo is paused in this function.
        if (IGuardedLaunch(address(siloRepository)).isSiloPaused(address(this), _asset)) {
            revert Paused();
        }

        AssetStorage storage _state = _assetStorage[_asset];
        AssetInterestData storage _assetInterestData = _interestData[_asset];
        uint256 lastTimestamp = _assetInterestData.interestRateTimestamp;

        // This is the first time, so we can return early and save some gas
        if (lastTimestamp == 0) {
            _assetInterestData.interestRateTimestamp = uint64(block.timestamp);
            return 0;
        }

        // Interest has already been accrued this block
        if (lastTimestamp == block.timestamp) {
            return 0;
        }

        uint256 rcomp = _getModel(_asset).getCompoundInterestRateAndUpdate(_asset, block.timestamp);
        uint256 protocolShareFee = siloRepository.protocolShareFee();

        uint256 totalBorrowAmountCached = _state.totalBorrowAmount;
        uint256 protocolFeesCached = _assetInterestData.protocolFees;
        uint256 newProtocolFees;
        uint256 protocolShare;
        uint256 depositorsShare;

        accruedInterest = totalBorrowAmountCached * rcomp / Solvency._PRECISION_DECIMALS;

        unchecked {
            // If we overflow on multiplication it should not revert tx, we will get lower fees
            protocolShare = accruedInterest * protocolShareFee / Solvency._PRECISION_DECIMALS;
            newProtocolFees = protocolFeesCached + protocolShare;

            if (newProtocolFees < protocolFeesCached) {
                protocolShare = type(uint256).max - protocolFeesCached;
                newProtocolFees = type(uint256).max;
            }
    
            depositorsShare = accruedInterest - protocolShare;
        }

        // update contract state
        _state.totalBorrowAmount = totalBorrowAmountCached + accruedInterest;
        _state.totalDeposits = _state.totalDeposits + depositorsShare;
        _assetInterestData.protocolFees = newProtocolFees;
        _assetInterestData.interestRateTimestamp = uint64(block.timestamp);
    }

    /// @dev gets interest rates model object
    /// @param _asset asset for which to calculate interest rate
    /// @return IInterestRateModel interest rates model object
    function _getModel(address _asset) internal view returns (IInterestRateModel) {
        return IInterestRateModel(siloRepository.getInterestRateModel(address(this), _asset));
    }

    /// @dev calculates amount to repay based on user shares, we do not apply virtual balances here,
    /// if needed, they need to be apply beforehand
    /// @param _state asset storage struct
    /// @param _borrower borrower address
    /// @param _amount proposed amount of asset to repay. Based on that,`repayShare` is calculated.
    /// @return amount amount of asset to repay
    /// @return repayShare amount of debt token representing debt ownership
    function _calculateDebtAmountAndShare(AssetStorage storage _state, address _borrower, uint256 _amount)
        internal
        view
        returns (uint256 amount, uint256 repayShare)
    {
        uint256 borrowerDebtShare = _state.debtToken.balanceOf(_borrower);
        uint256 debtTokenTotalSupply = _state.debtToken.totalSupply();
        uint256 totalBorrowed = _state.totalBorrowAmount;
        uint256 maxAmount = borrowerDebtShare.toAmountRoundUp(totalBorrowed, debtTokenTotalSupply);

        if (_amount >= maxAmount) {
            amount = maxAmount;
            repayShare = borrowerDebtShare;
        } else {
            amount = _amount;
            repayShare = _amount.toShare(totalBorrowed, debtTokenTotalSupply);
        }
    }

    /// @dev verifies if user did not borrow more than allowed maximum
    function _validateBorrowAfter(address _user) private view {
        (address[] memory assets, AssetStorage[] memory assetsStates) = getAssetsWithState();

        (uint256 userLTV, uint256 maximumAllowedLTV) = Solvency.calculateLTVs(
            Solvency.SolvencyParams(
                siloRepository,
                ISilo(address(this)),
                assets,
                assetsStates,
                _user
            ),
            Solvency.TypeofLTV.MaximumLTV
        );

        if (userLTV > maximumAllowedLTV) revert MaximumLTVReached();
    }

    function _getWithdrawAssetData(address _asset, bool _collateralOnly)
        private
        view
        returns(uint256 assetTotalDeposits, IShareToken shareToken, uint256 availableLiquidity)
    {
        AssetStorage storage _state = _assetStorage[_asset];

        if (_collateralOnly) {
            assetTotalDeposits = _state.collateralOnlyDeposits;
            shareToken = _state.collateralOnlyToken;
            availableLiquidity = assetTotalDeposits;
        } else {
            assetTotalDeposits = _state.totalDeposits;
            shareToken = _state.collateralToken;
            availableLiquidity = liquidity(_asset);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ISilo.sol";

import "./lib/EasyMath.sol";
import "./BaseSilo.sol";

/// @title Silo
/// @notice Silo is the main component of the protocol. It implements lending logic, manages and isolates
/// risk, acts as a vault for assets, and performs liquidations. Each Silo is composed of the unique asset
/// for which it was created (ie. UNI) and bridge assets (ie. ETH and SiloDollar). There may be multiple
/// bridge assets at any given time.
/// @dev Main Silo contact that inherits from Base contract. It implements all user/UI facing methods.
/// @custom:security-contact [email protected]
contract Silo is ISilo, BaseSilo {
    using SafeERC20 for ERC20;
    using EasyMath for uint256;

    constructor (ISiloRepository _repository, address _siloAsset, uint128 _version)
        BaseSilo(_repository, _siloAsset, _version)
    {
        // initial setup is done in BaseSilo, nothing to do here
    }

    /// @inheritdoc ISilo
    function deposit(address _asset, uint256 _amount, bool _collateralOnly)
        external
        override
        returns (uint256 collateralAmount, uint256 collateralShare)
    {
        return _deposit(_asset, msg.sender, msg.sender, _amount, _collateralOnly);
    }

    /// @inheritdoc ISilo
    function depositFor(
        address _asset,
        address _depositor,
        uint256 _amount,
        bool _collateralOnly
    )
        external
        override
        returns (uint256 collateralAmount, uint256 collateralShare)
    {
        return _deposit(_asset, msg.sender, _depositor, _amount, _collateralOnly);
    }

    /// @inheritdoc ISilo
    function withdraw(address _asset, uint256 _amount, bool _collateralOnly)
        external
        override
        returns (uint256 withdrawnAmount, uint256 withdrawnShare)
    {
        return _withdraw(_asset, msg.sender, msg.sender, _amount, _collateralOnly);
    }

    /// @inheritdoc ISilo
    function withdrawFor(address _asset, address _depositor, address _receiver, uint256 _amount, bool _collateralOnly)
        external
        override
        onlyRouter
        returns (uint256 withdrawnAmount, uint256 withdrawnShare)
    {
        return _withdraw(_asset, _depositor, _receiver, _amount, _collateralOnly);
    }

    /// @inheritdoc ISilo
    function borrow(address _asset, uint256 _amount) external override returns (uint256 debtAmount, uint256 debtShare) {
        return _borrow(_asset, msg.sender, msg.sender, _amount);
    }

    /// @inheritdoc ISilo
    function borrowFor(address _asset, address _borrower, address _receiver, uint256 _amount)
        external
        override
        onlyRouter
        returns (uint256 debtAmount, uint256 debtShare)
    {
        return _borrow(_asset, _borrower, _receiver, _amount);
    }

    /// @inheritdoc ISilo
    function repay(address _asset, uint256 _amount)
        external
        override
        returns (uint256 repaidAmount, uint256 repaidShare)
    {
        return _repay(_asset, msg.sender, msg.sender, _amount);
    }

    /// @inheritdoc ISilo
    function repayFor(address _asset, address _borrower, uint256 _amount)
        external
        override
        returns (uint256 repaidAmount, uint256 repaidShare)
    {
        return _repay(_asset, _borrower, msg.sender, _amount);
    }

    /// @inheritdoc ISilo
    function flashLiquidate(address[] memory _users, bytes memory _flashReceiverData)
        external
        override
        returns (
            address[] memory assets,
            uint256[][] memory receivedCollaterals,
            uint256[][] memory shareAmountsToRepay
        )
    {
        assets = getAssets();
        uint256 usersLength = _users.length;
        receivedCollaterals = new uint256[][](usersLength);
        shareAmountsToRepay = new uint256[][](usersLength);

        for (uint256 i = 0; i < usersLength; i++) {
            (
                receivedCollaterals[i],
                shareAmountsToRepay[i]
            ) = _userLiquidation(assets, _users[i], IFlashLiquidationReceiver(msg.sender), _flashReceiverData);
        }
    }

    /// @inheritdoc ISilo
    function harvestProtocolFees() external override returns (uint256[] memory harvestedAmounts) {
        address[] memory assets = getAssets();
        harvestedAmounts = new uint256[](assets.length);

        address repositoryOwner = siloRepository.owner();

        for (uint256 i; i < assets.length;) {
            unchecked {
                // it will not overflow because fee is much lower than any other amounts
                harvestedAmounts[i] = _harvestProtocolFees(assets[i], repositoryOwner);
                // we run out of gas before we overflow i
                i++;
            }
        }
    }

    /// @inheritdoc ISilo
    function accrueInterest(address _asset) public override returns (uint256 interest) {
        return _accrueInterest(_asset);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./Silo.sol";
import "./interfaces/ISiloFactory.sol";

/// @title SiloFactory
/// @notice Silo Factory has one job, deploy Silo implementation
/// @dev Silo Factory is registered within SiloRepository contract and it's given a version. Each version
/// is different Silo Factory that deploys different Silo implementation. Many Factory contracts can be
/// registered with the Repository contract.
/// @custom:security-contact [email protected]
contract SiloFactory is ISiloFactory {
    address public siloRepository;

    event InitSiloRepository();

    error OnlyRepository();
    error RepositoryAlreadySet();

    /// @inheritdoc ISiloFactory
    function initRepository(address _repository) external {
        // We don't perform a ping to the repository because this is meant to be called in its constructor
        if (siloRepository != address(0)) revert RepositoryAlreadySet();

        siloRepository = _repository;
        emit InitSiloRepository();
    }

    /// @inheritdoc ISiloFactory
    function createSilo(address _siloAsset, uint128 _version, bytes memory) external override returns (address silo) {
        // Only allow silo repository
        if (msg.sender != siloRepository) revert OnlyRepository();

        silo = address(new Silo(ISiloRepository(msg.sender), _siloAsset, _version));
        emit NewSiloCreated(silo, _siloAsset, _version);
    }

    function siloFactoryPing() external pure override returns (bytes4) {
        return this.siloFactoryPing.selector;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IShareToken.sol";
import "./IFlashLiquidationReceiver.sol";
import "./ISiloRepository.sol";

interface IBaseSilo {
    enum AssetStatus { Undefined, Active, Removed }

    /// @dev Storage struct that holds all required data for a single token market
    struct AssetStorage {
        /// @dev Token that represents a share in totalDeposits of Silo
        IShareToken collateralToken;
        /// @dev Token that represents a share in collateralOnlyDeposits of Silo
        IShareToken collateralOnlyToken;
        /// @dev Token that represents a share in totalBorrowAmount of Silo
        IShareToken debtToken;
        /// @dev COLLATERAL: Amount of asset token that has been deposited to Silo with interest earned by depositors.
        /// It also includes token amount that has been borrowed.
        uint256 totalDeposits;
        /// @dev COLLATERAL ONLY: Amount of asset token that has been deposited to Silo that can be ONLY used
        /// as collateral. These deposits do NOT earn interest and CANNOT be borrowed.
        uint256 collateralOnlyDeposits;
        /// @dev DEBT: Amount of asset token that has been borrowed with accrued interest.
        uint256 totalBorrowAmount;
    }

    /// @dev Storage struct that holds data related to fees and interest
    struct AssetInterestData {
        /// @dev Total amount of already harvested protocol fees
        uint256 harvestedProtocolFees;
        /// @dev Total amount (ever growing) of asset token that has been earned by the protocol from
        /// generated interest.
        uint256 protocolFees;
        /// @dev Timestamp of the last time `interestRate` has been updated in storage.
        uint64 interestRateTimestamp;
        /// @dev True if asset was removed from the protocol. If so, deposit and borrow functions are disabled
        /// for that asset
        AssetStatus status;
    }

    /// @notice data that InterestModel needs for calculations
    struct UtilizationData {
        uint256 totalDeposits;
        uint256 totalBorrowAmount;
        /// @dev timestamp of last interest accrual
        uint64 interestRateTimestamp;
    }

    /// @dev Shares names and symbols that are generated while asset initialization
    struct AssetSharesMetadata {
        /// @dev Name for the collateral shares token
        string collateralName;
        /// @dev Symbol for the collateral shares token
        string collateralSymbol;
        /// @dev Name for the collateral only (protected collateral) shares token
        string protectedName;
        /// @dev Symbol for the collateral only (protected collateral) shares token
        string protectedSymbol;
        /// @dev Name for the debt shares token
        string debtName;
        /// @dev Symbol for the debt shares token
        string debtSymbol;
    }

    /// @notice Emitted when deposit is made
    /// @param asset asset address that was deposited
    /// @param depositor wallet address that deposited asset
    /// @param amount amount of asset that was deposited
    /// @param collateralOnly type of deposit, true if collateralOnly deposit was used
    event Deposit(address indexed asset, address indexed depositor, uint256 amount, bool collateralOnly);

    /// @notice Emitted when withdraw is made
    /// @param asset asset address that was withdrawn
    /// @param depositor wallet address that deposited asset
    /// @param receiver wallet address that received asset
    /// @param amount amount of asset that was withdrew
    /// @param collateralOnly type of withdraw, true if collateralOnly deposit was used
    event Withdraw(
        address indexed asset,
        address indexed depositor,
        address indexed receiver,
        uint256 amount,
        bool collateralOnly
    );

    /// @notice Emitted on asset borrow
    /// @param asset asset address that was borrowed
    /// @param user wallet address that borrowed asset
    /// @param amount amount of asset that was borrowed
    event Borrow(address indexed asset, address indexed user, uint256 amount);

    /// @notice Emitted on asset repay
    /// @param asset asset address that was repaid
    /// @param user wallet address that repaid asset
    /// @param amount amount of asset that was repaid
    event Repay(address indexed asset, address indexed user, uint256 amount);

    /// @notice Emitted on user liquidation
    /// @param asset asset address that was liquidated
    /// @param user wallet address that was liquidated
    /// @param shareAmountRepaid amount of collateral-share token that was repaid. This is collateral token representing
    /// ownership of underlying deposit.
    /// @param seizedCollateral amount of underlying token that was seized by liquidator
    event Liquidate(address indexed asset, address indexed user, uint256 shareAmountRepaid, uint256 seizedCollateral);

    /// @notice Emitted when the status for an asset is updated
    /// @param asset asset address that was updated
    /// @param status new asset status
    event AssetStatusUpdate(address indexed asset, AssetStatus indexed status);

    /// @return version of the silo contract
    function VERSION() external returns (uint128); // solhint-disable-line func-name-mixedcase

    /// @notice Synchronize current bridge assets with Silo
    /// @dev This function needs to be called on Silo deployment to setup all assets for Silo. It needs to be
    /// called every time a bridged asset is added or removed. When bridge asset is removed, depositing and borrowing
    /// should be disabled during asset sync.
    function syncBridgeAssets() external;

    /// @notice Get Silo Repository contract address
    /// @return Silo Repository contract address
    function siloRepository() external view returns (ISiloRepository);

    /// @notice Get asset storage data
    /// @param _asset asset address
    /// @return AssetStorage struct
    function assetStorage(address _asset) external view returns (AssetStorage memory);

    /// @notice Get asset interest data
    /// @param _asset asset address
    /// @return AssetInterestData struct
    function interestData(address _asset) external view returns (AssetInterestData memory);

    /// @dev helper method for InterestRateModel calculations
    function utilizationData(address _asset) external view returns (UtilizationData memory data);

    /// @notice Calculates solvency of an account
    /// @param _user wallet address for which solvency is calculated
    /// @return true if solvent, false otherwise
    function isSolvent(address _user) external view returns (bool);

    /// @notice Returns all initialized (synced) assets of Silo including current and removed bridge assets
    /// @return assets array of initialized assets of Silo
    function getAssets() external view returns (address[] memory assets);

    /// @notice Returns all initialized (synced) assets of Silo including current and removed bridge assets
    /// with corresponding state
    /// @return assets array of initialized assets of Silo
    /// @return assetsStorage array of assets state corresponding to `assets` array
    function getAssetsWithState() external view returns (address[] memory assets, AssetStorage[] memory assetsStorage);

    /// @notice Check if depositing an asset for given account is possible
    /// @dev Depositing an asset that has been already borrowed (and vice versa) is disallowed
    /// @param _asset asset we want to deposit
    /// @param _depositor depositor address
    /// @return true if asset can be deposited by depositor
    function depositPossible(address _asset, address _depositor) external view returns (bool);

    /// @notice Check if borrowing an asset for given account is possible
    /// @dev Borrowing an asset that has been already deposited (and vice versa) is disallowed
    /// @param _asset asset we want to deposit
    /// @param _borrower borrower address
    /// @return true if asset can be borrowed by borrower
    function borrowPossible(address _asset, address _borrower) external view returns (bool);

    /// @dev Amount of token that is available for borrowing
    /// @param _asset asset to get liquidity for
    /// @return Silo liquidity
    function liquidity(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev when performing Silo flash liquidation, FlashReceiver contract will receive all collaterals
interface IFlashLiquidationReceiver {
    /// @dev this method is called when doing Silo flash liquidation
    ///         one can NOT assume, that if _seizedCollateral[i] != 0, then _shareAmountsToRepaid[i] must be 0
    ///         one should assume, that any combination of amounts is possible
    ///         on callback, one must call `Silo.repayFor` because at the end of transaction,
    ///         Silo will check if borrower is solvent.
    /// @param _user user address, that is liquidated
    /// @param _assets array of collateral assets received during user liquidation
    ///         this array contains all assets (collateral borrowed) without any order
    /// @param _receivedCollaterals array of collateral amounts received during user liquidation
    ///         indexes of amounts are related to `_assets`,
    /// @param _shareAmountsToRepaid array of amounts to repay for each asset
    ///         indexes of amounts are related to `_assets`,
    /// @param _flashReceiverData data that are passed from sender that executes liquidation
    function siloLiquidationCallback(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid,
        bytes memory _flashReceiverData
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IGuardedLaunch {
    /// @dev Stores info about maximum allowed liquidity in a Silo. This limit applies to deposit only.
    struct MaxLiquidityLimit {
        /// @dev flag to turn on/off all limits for all Silos
        bool globalLimit;
        /// @dev default value represents maximum allowed liquidity in Silo
        uint256 defaultMaxLiquidity;
        /// @notice siloMaxLiquidity maps silo => asset => maximum allowed deposit liquidity.
        /// @dev Deposit liquidity limit is denominated in quote token. For example, if set to 1e18, it means that any
        /// given Silo is allowed for deposits up to 1 quote token of value. Value is calculated using prices from the
        /// Oracle.
        mapping(address => mapping(address => uint256)) siloMaxLiquidity;
    }

    /// @dev Stores info about paused Silos
    /// if `globalPause` == `true`, all Silo are paused
    /// if `globalPause` == `false` and `siloPause[silo][0x0]` == `true`, all assets in a `silo` are paused
    /// if `globalPause` == `false` and `siloPause[silo][asset]` == `true`, only `asset` in a `silo` is paused
    struct Paused {
        bool globalPause;
        /// @dev maps silo address to asset address to bool
        mapping(address => mapping(address => bool)) siloPause;
    }

    /// @notice Emitted when all Silos are paused or unpaused
    /// @param globalPause current value of `globalPause`
    event GlobalPause(bool globalPause);

    /// @notice Emitted when a single Silo or single asset in a Silo is paused or unpaused
    /// @param silo address of Silo which is paused
    /// @param asset address of an asset which is paused
    /// @param pauseValue true when paused, otherwise false
    event SiloPause(address silo, address asset, bool pauseValue);

    /// @notice Emitted when max liquidity toggle is switched
    /// @param newLimitedMaxLiquidityState new value for max liquidity toggle
    event LimitedMaxLiquidityToggled(bool newLimitedMaxLiquidityState);

    /// @notice Emitted when deposit liquidity limit is changed for Silo and asset
    /// @param silo Silo address for which to set limit
    /// @param asset Silo asset for which to set limit
    /// @param newMaxDeposits deposit limit amount in quote token
    event SiloMaxDepositsLimitsUpdate(address indexed silo, address indexed asset, uint256 newMaxDeposits);

    /// @notice Emitted when default max liquidity limit is changed
    /// @param newMaxDeposits new deposit limit in quote token
    event DefaultSiloMaxDepositsLimitUpdate(uint256 newMaxDeposits);

    /// @notice Sets limited liquidity to provided value
    function setLimitedMaxLiquidity(bool _globalLimit) external;

    /// @notice Sets default deposit limit for all Silos
    /// @param _maxDeposits deposit limit amount in quote token
    function setDefaultSiloMaxDepositsLimit(uint256 _maxDeposits) external;

    /// @notice Sets deposit limit for Silo
    /// @param _silo Silo address for which to set limit
    /// @param _asset Silo asset for which to set limit
    /// @param _maxDeposits deposit limit amount in quote token
    function setSiloMaxDepositsLimit(
        address _silo,
        address _asset,
        uint256 _maxDeposits
    ) external;

    /// @notice Pause all Silos
    /// @dev Callable only by owner.
    /// @param _globalPause true to pause all Silos, otherwise false
    function setGlobalPause(bool _globalPause) external;

    /// @notice Pause single asset in a single Silo
    /// @dev Callable only by owner.
    /// @param _silo address of Silo in which `_asset` is being paused
    /// @param _asset address of an asset that is being paused
    /// @param _pauseValue true to pause, false to unpause
    function setSiloPause(address _silo, address _asset, bool _pauseValue) external;

    /// @notice Check given asset in a Silo is paused
    /// @param _silo address of Silo
    /// @param _asset address of an asset
    /// @return true if given asset in a Silo is paused, otherwise false
    function isSiloPaused(address _silo, address _asset) external view returns (bool);

    /// @notice Gets deposit limit for Silo
    /// @param _silo Silo address for which to set limit
    /// @param _asset Silo asset for which to set limit
    /// @return deposit limit for Silo
    function getMaxSiloDepositsValue(address _silo, address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IInterestRateModel {
    /* solhint-disable */
    struct Config {
        // uopt ∈ (0, 1) – optimal utilization;
        int256 uopt;
        // ucrit ∈ (uopt, 1) – threshold of large utilization;
        int256 ucrit;
        // ulow ∈ (0, uopt) – threshold of low utilization
        int256 ulow;
        // ki > 0 – integrator gain
        int256 ki;
        // kcrit > 0 – proportional gain for large utilization
        int256 kcrit;
        // klow ≥ 0 – proportional gain for low utilization
        int256 klow;
        // klin ≥ 0 – coefficient of the lower linear bound
        int256 klin;
        // beta ≥ 0 - a scaling factor
        int256 beta;
        // ri ≥ 0 – initial value of the integrator
        int256 ri;
        // Tcrit ≥ 0 - the time during which the utilization exceeds the critical value
        int256 Tcrit;
    }
    /* solhint-enable */

    /// @dev Set dedicated config for given asset in a Silo. Config is per asset per Silo so different assets
    /// in different Silo can have different configs.
    /// It will try to call `_silo.accrueInterest(_asset)` before updating config, but it is not guaranteed,
    /// that this call will be successful, if it fail config will be set anyway.
    /// @param _silo Silo address for which config should be set
    /// @param _asset asset address for which config should be set
    function setConfig(address _silo, address _asset, Config calldata _config) external;

    /// @dev get compound interest rate and update model storage
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    function getCompoundInterestRateAndUpdate(
        address _asset,
        uint256 _blockTimestamp
    ) external returns (uint256 rcomp);

    /// @dev Get config for given asset in a Silo. If dedicated config is not set, default one will be returned.
    /// @param _silo Silo address for which config should be set
    /// @param _asset asset address for which config should be set
    /// @return Config struct for asset in Silo
    function getConfig(address _silo, address _asset) external view returns (Config memory);

    /// @dev get compound interest rate
    /// @param _silo address of Silo
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    function getCompoundInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (uint256 rcomp);

    /// @dev get current annual interest rate
    /// @param _silo address of Silo
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcur current annual interest rate (1e18 == 100%)
    function getCurrentInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (uint256 rcur);

    /// @notice get the flag to detect rcomp restriction (zero current interest) due to overflow
    /// overflow boolean flag to detect rcomp restriction
    function overflowDetected(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (bool overflow);

    /// @dev pure function that calculates current annual interest rate
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcur current annual interest rate (1e18 == 100%)
    function calculateCurrentInterestRate(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (uint256 rcur);

    /// @dev pure function that calculates interest rate based on raw input data
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    /// @return ri current integral part of the rate
    /// @return Tcrit time during which the utilization exceeds the critical value
    /// @return overflow boolean flag to detect rcomp restriction
    function calculateCompoundInterestRateWithOverflowDetection(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit, // solhint-disable-line var-name-mixedcase
        bool overflow
    );

    /// @dev pure function that calculates interest rate based on raw input data
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    /// @return ri current integral part of the rate
    /// @return Tcrit time during which the utilization exceeds the critical value
    function calculateCompoundInterestRate(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit // solhint-disable-line var-name-mixedcase
    );

    /// @dev returns decimal points used by model
    function DP() external pure returns (uint256); // solhint-disable-line func-name-mixedcase

    /// @dev just a helper method to see if address is a InterestRateModel
    /// @return always true
    function interestRateModelPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @title Common interface for Silo Incentive Contract
interface INotificationReceiver {
    /// @dev Informs the contract about token transfer
    /// @param _token address of the token that was transferred
    /// @param _from sender
    /// @param _to receiver
    /// @param _amount amount that was transferred
    function onAfterTransfer(address _token, address _from, address _to, uint256 _amount) external;

    /// @dev Sanity check function
    /// @return always true
    function notificationReceiverPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

/// @title Common interface for Silo Price Providers
interface IPriceProvider {
    /// @notice Returns "Time-Weighted Average Price" for an asset. Calculates TWAP price for quote/asset.
    /// It unifies all tokens decimal to 18, examples:
    /// - if asses == quote it returns 1e18
    /// - if asset is USDC and quote is ETH and ETH costs ~$3300 then it returns ~0.0003e18 WETH per 1 USDC
    /// @param _asset address of an asset for which to read price
    /// @return price of asses with 18 decimals, throws when pool is not ready yet to provide price
    function getPrice(address _asset) external view returns (uint256 price);

    /// @dev Informs if PriceProvider is setup for asset. It does not means PriceProvider can provide price right away.
    /// Some providers implementations need time to "build" buffer for TWAP price,
    /// so price may not be available yet but this method will return true.
    /// @param _asset asset in question
    /// @return TRUE if asset has been setup, otherwise false
    function assetSupported(address _asset) external view returns (bool);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Helper method that allows easily detects, if contract is PriceProvider
    /// @dev this can save us from simple human errors, in case we use invalid address
    /// but this should NOT be treated as security check
    /// @return always true
    function priceProviderPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "./IPriceProvider.sol";

interface IPriceProvidersRepository {
    /// @notice Emitted when price provider is added
    /// @param newPriceProvider new price provider address
    event NewPriceProvider(IPriceProvider indexed newPriceProvider);

    /// @notice Emitted when price provider is removed
    /// @param priceProvider removed price provider address
    event PriceProviderRemoved(IPriceProvider indexed priceProvider);

    /// @notice Emitted when asset is assigned to price provider
    /// @param asset assigned asset   address
    /// @param priceProvider price provider address
    event PriceProviderForAsset(address indexed asset, IPriceProvider indexed priceProvider);

    /// @notice Register new price provider
    /// @param _priceProvider address of price provider
    function addPriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Unregister price provider
    /// @param _priceProvider address of price provider to be removed
    function removePriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Sets price provider for asset
    /// @dev Request for asset price is forwarded to the price provider assigned to that asset
    /// @param _asset address of an asset for which price provider will be used
    /// @param _priceProvider address of price provider
    function setPriceProviderForAsset(address _asset, IPriceProvider _priceProvider) external;

    /// @notice Returns "Time-Weighted Average Price" for an asset
    /// @param _asset address of an asset for which to read price
    /// @return price TWAP price of a token with 18 decimals
    function getPrice(address _asset) external view returns (uint256 price);

    /// @notice Gets price provider assigned to an asset
    /// @param _asset address of an asset for which to get price provider
    /// @return priceProvider address of price provider
    function priceProviders(address _asset) external view returns (IPriceProvider priceProvider);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Gets manager role address
    /// @return manager role address
    function manager() external view returns (address);

    /// @notice Checks if providers are available for an asset
    /// @param _asset asset address to check
    /// @return returns TRUE if price feed is ready, otherwise false
    function providersReadyForAsset(address _asset) external view returns (bool);

    /// @notice Returns true if address is a registered price provider
    /// @param _provider address of price provider to be removed
    /// @return true if address is a registered price provider, otherwise false
    function isPriceProvider(IPriceProvider _provider) external view returns (bool);

    /// @notice Gets number of price providers registered
    /// @return number of price providers registered
    function providersCount() external view returns (uint256);

    /// @notice Gets an array of price providers
    /// @return array of price providers
    function providerList() external view returns (address[] memory);

    /// @notice Sanity check function
    /// @return returns always TRUE
    function priceProvidersRepositoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./INotificationReceiver.sol";

interface IShareToken is IERC20Metadata {
    /// @notice Emitted every time receiver is notified about token transfer
    /// @param notificationReceiver receiver address
    /// @param success false if TX reverted on `notificationReceiver` side, otherwise true
    event NotificationSent(
        INotificationReceiver indexed notificationReceiver,
        bool success
    );

    /// @notice Mint method for Silo to create debt position
    /// @param _account wallet for which to mint token
    /// @param _amount amount of token to be minted
    function mint(address _account, uint256 _amount) external;

    /// @notice Burn method for Silo to close debt position
    /// @param _account wallet for which to burn token
    /// @param _amount amount of token to be burned
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IBaseSilo.sol";

interface ISilo is IBaseSilo {
    /// @notice Deposit `_amount` of `_asset` tokens from `msg.sender` to the Silo
    /// @param _asset The address of the token to deposit
    /// @param _amount The amount of the token to deposit
    /// @param _collateralOnly True if depositing collateral only
    /// @return collateralAmount deposited amount
    /// @return collateralShare user collateral shares based on deposited amount
    function deposit(address _asset, uint256 _amount, bool _collateralOnly)
        external
        returns (uint256 collateralAmount, uint256 collateralShare);

    /// @notice Router function to deposit `_amount` of `_asset` tokens to the Silo for the `_depositor`
    /// @param _asset The address of the token to deposit
    /// @param _depositor The address of the recipient of collateral tokens
    /// @param _amount The amount of the token to deposit
    /// @param _collateralOnly True if depositing collateral only
    /// @return collateralAmount deposited amount
    /// @return collateralShare `_depositor` collateral shares based on deposited amount
    function depositFor(address _asset, address _depositor, uint256 _amount, bool _collateralOnly)
        external
        returns (uint256 collateralAmount, uint256 collateralShare);

    /// @notice Withdraw `_amount` of `_asset` tokens from the Silo to `msg.sender`
    /// @param _asset The address of the token to withdraw
    /// @param _amount The amount of the token to withdraw
    /// @param _collateralOnly True if withdrawing collateral only deposit
    /// @return withdrawnAmount withdrawn amount that was transferred to user
    /// @return withdrawnShare burned share based on `withdrawnAmount`
    function withdraw(address _asset, uint256 _amount, bool _collateralOnly)
        external
        returns (uint256 withdrawnAmount, uint256 withdrawnShare);

    /// @notice Router function to withdraw `_amount` of `_asset` tokens from the Silo for the `_depositor`
    /// @param _asset The address of the token to withdraw
    /// @param _depositor The address that originally deposited the collateral tokens being withdrawn,
    /// it should be the one initiating the withdrawal through the router
    /// @param _receiver The address that will receive the withdrawn tokens
    /// @param _amount The amount of the token to withdraw
    /// @param _collateralOnly True if withdrawing collateral only deposit
    /// @return withdrawnAmount withdrawn amount that was transferred to `_receiver`
    /// @return withdrawnShare burned share based on `withdrawnAmount`
    function withdrawFor(
        address _asset,
        address _depositor,
        address _receiver,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 withdrawnAmount, uint256 withdrawnShare);

    /// @notice Borrow `_amount` of `_asset` tokens from the Silo to `msg.sender`
    /// @param _asset The address of the token to borrow
    /// @param _amount The amount of the token to borrow
    /// @return debtAmount borrowed amount
    /// @return debtShare user debt share based on borrowed amount
    function borrow(address _asset, uint256 _amount) external returns (uint256 debtAmount, uint256 debtShare);

    /// @notice Router function to borrow `_amount` of `_asset` tokens from the Silo for the `_receiver`
    /// @param _asset The address of the token to borrow
    /// @param _borrower The address that will take the loan,
    /// it should be the one initiating the borrowing through the router
    /// @param _receiver The address of the asset receiver
    /// @param _amount The amount of the token to borrow
    /// @return debtAmount borrowed amount
    /// @return debtShare `_receiver` debt share based on borrowed amount
    function borrowFor(address _asset, address _borrower, address _receiver, uint256 _amount)
        external
        returns (uint256 debtAmount, uint256 debtShare);

    /// @notice Repay `_amount` of `_asset` tokens from `msg.sender` to the Silo
    /// @param _asset The address of the token to repay
    /// @param _amount amount of asset to repay, includes interests
    /// @return repaidAmount amount repaid
    /// @return burnedShare burned debt share
    function repay(address _asset, uint256 _amount) external returns (uint256 repaidAmount, uint256 burnedShare);

    /// @notice Allows to repay in behalf of borrower to execute liquidation
    /// @param _asset The address of the token to repay
    /// @param _borrower The address of the user to have debt tokens burned
    /// @param _amount amount of asset to repay, includes interests
    /// @return repaidAmount amount repaid
    /// @return burnedShare burned debt share
    function repayFor(address _asset, address _borrower, uint256 _amount)
        external
        returns (uint256 repaidAmount, uint256 burnedShare);

    /// @dev harvest protocol fees from an array of assets
    /// @return harvestedAmounts amount harvested during tx execution for each of silo asset
    function harvestProtocolFees() external returns (uint256[] memory harvestedAmounts);

    /// @notice Function to update interests for `_asset` token since the last saved state
    /// @param _asset The address of the token to be updated
    /// @return interest accrued interest
    function accrueInterest(address _asset) external returns (uint256 interest);

    /// @notice this methods does not requires to have tokens in order to liquidate user
    /// @dev during liquidation process, msg.sender will be notified once all collateral will be send to him
    /// msg.sender needs to be `IFlashLiquidationReceiver`
    /// @param _users array of users to liquidate
    /// @param _flashReceiverData this data will be forward to msg.sender on notification
    /// @return assets array of all processed assets (collateral + debt, including removed)
    /// @return receivedCollaterals receivedCollaterals[userId][assetId] => amount
    /// amounts of collaterals send to `_flashReceiver`
    /// @return shareAmountsToRepaid shareAmountsToRepaid[userId][assetId] => amount
    /// required amounts of debt to be repaid
    function flashLiquidate(address[] memory _users, bytes memory _flashReceiverData)
        external
        returns (
            address[] memory assets,
            uint256[][] memory receivedCollaterals,
            uint256[][] memory shareAmountsToRepaid
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface ISiloFactory {
    /// @notice Emitted when Silo is deployed
    /// @param silo address of deployed Silo
    /// @param asset address of asset for which Silo was deployed
    /// @param version version of silo implementation
    event NewSiloCreated(address indexed silo, address indexed asset, uint128 version);

    /// @notice Must be called by repository on constructor
    /// @param _siloRepository the SiloRepository to set
    function initRepository(address _siloRepository) external;

    /// @notice Deploys Silo
    /// @param _siloAsset unique asset for which Silo is deployed
    /// @param _version version of silo implementation
    /// @param _data (optional) data that may be needed during silo creation
    /// @return silo deployed Silo address
    function createSilo(address _siloAsset, uint128 _version, bytes memory _data) external returns (address silo);

    /// @dev just a helper method to see if address is a factory
    function siloFactoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./ISiloFactory.sol";
import "./ITokensFactory.sol";
import "./IPriceProvidersRepository.sol";
import "./INotificationReceiver.sol";
import "./IInterestRateModel.sol";

interface ISiloRepository {
    /// @dev protocol fees in precision points (Solvency._PRECISION_DECIMALS), we do allow for fee == 0
    struct Fees {
        /// @dev One time protocol fee for opening a borrow position in precision points (Solvency._PRECISION_DECIMALS)
        uint64 entryFee;
        /// @dev Protocol revenue share in interest paid in precision points (Solvency._PRECISION_DECIMALS)
        uint64 protocolShareFee;
        /// @dev Protocol share in liquidation profit in precision points (Solvency._PRECISION_DECIMALS).
        /// It's calculated from total collateral amount to be transferred to liquidator.
        uint64 protocolLiquidationFee;
    }

    struct SiloVersion {
        /// @dev Default version of Silo. If set to 0, it means it is not set. By default it is set to 1
        uint128 byDefault;

        /// @dev Latest added version of Silo. If set to 0, it means it is not set. By default it is set to 1
        uint128 latest;
    }

    /// @dev AssetConfig struct represents configurable parameters for each Silo
    struct AssetConfig {
        /// @dev Loan-to-Value ratio represents the maximum borrowing power of a specific collateral.
        ///      For example, if the collateral asset has an LTV of 75%, the user can borrow up to 0.75 worth
        ///      of quote token in the principal currency for every quote token worth of collateral.
        ///      value uses 18 decimals eg. 100% == 1e18
        ///      max valid value is 1e18 so it needs storage of 60 bits
        uint64 maxLoanToValue;

        /// @dev Liquidation Threshold represents the threshold at which a borrow position will be considered
        ///      undercollateralized and subject to liquidation for each collateral. For example,
        ///      if a collateral has a liquidation threshold of 80%, it means that the loan will be
        ///      liquidated when the borrowAmount value is worth 80% of the collateral value.
        ///      value uses 18 decimals eg. 100% == 1e18
        uint64 liquidationThreshold;

        /// @dev interest rate model address
        IInterestRateModel interestRateModel;
    }

    event NewDefaultMaximumLTV(uint64 defaultMaximumLTV);

    event NewDefaultLiquidationThreshold(uint64 defaultLiquidationThreshold);

    /// @notice Emitted on new Silo creation
    /// @param silo deployed Silo address
    /// @param asset unique asset for deployed Silo
    /// @param siloVersion version of deployed Silo
    event NewSilo(address indexed silo, address indexed asset, uint128 siloVersion);

    /// @notice Emitted when new Silo (or existing one) becomes a bridge pool (pool with only bridge tokens).
    /// @param pool address of the bridge pool, It can be zero address when bridge asset is removed and pool no longer
    /// is treated as bridge pool
    event BridgePool(address indexed pool);

    /// @notice Emitted on new bridge asset
    /// @param newBridgeAsset address of added bridge asset
    event BridgeAssetAdded(address indexed newBridgeAsset);

    /// @notice Emitted on removed bridge asset
    /// @param bridgeAssetRemoved address of removed bridge asset
    event BridgeAssetRemoved(address indexed bridgeAssetRemoved);

    /// @notice Emitted when default interest rate model is changed
    /// @param newModel address of new interest rate model
    event InterestRateModel(IInterestRateModel indexed newModel);

    /// @notice Emitted on price provider repository address update
    /// @param newProvider address of new oracle repository
    event PriceProvidersRepositoryUpdate(
        IPriceProvidersRepository indexed newProvider
    );

    /// @notice Emitted on token factory address update
    /// @param newTokensFactory address of new token factory
    event TokensFactoryUpdate(address indexed newTokensFactory);

    /// @notice Emitted on router address update
    /// @param newRouter address of new router
    event RouterUpdate(address indexed newRouter);

    /// @notice Emitted on INotificationReceiver address update
    /// @param newIncentiveContract address of new INotificationReceiver
    event NotificationReceiverUpdate(INotificationReceiver indexed newIncentiveContract);

    /// @notice Emitted when new Silo version is registered
    /// @param factory factory address that deploys registered Silo version
    /// @param siloLatestVersion Silo version of registered Silo
    /// @param siloDefaultVersion current default Silo version
    event RegisterSiloVersion(address indexed factory, uint128 siloLatestVersion, uint128 siloDefaultVersion);

    /// @notice Emitted when Silo version is unregistered
    /// @param factory factory address that deploys unregistered Silo version
    /// @param siloVersion version that was unregistered
    event UnregisterSiloVersion(address indexed factory, uint128 siloVersion);

    /// @notice Emitted when default Silo version is updated
    /// @param newDefaultVersion new default version
    event SiloDefaultVersion(uint128 newDefaultVersion);

    /// @notice Emitted when default fee is updated
    /// @param newEntryFee new entry fee
    /// @param newProtocolShareFee new protocol share fee
    /// @param newProtocolLiquidationFee new protocol liquidation fee
    event FeeUpdate(
        uint64 newEntryFee,
        uint64 newProtocolShareFee,
        uint64 newProtocolLiquidationFee
    );

    /// @notice Emitted when asset config is updated for a silo
    /// @param silo silo for which asset config is being set
    /// @param asset asset for which asset config is being set
    /// @param assetConfig new asset config
    event AssetConfigUpdate(address indexed silo, address indexed asset, AssetConfig assetConfig);

    /// @notice Emitted when silo (silo factory) version is set for asset
    /// @param asset asset for which asset config is being set
    /// @param version Silo version
    event VersionForAsset(address indexed asset, uint128 version);

    /// @param _siloAsset silo asset
    /// @return version of Silo that is assigned for provided asset, if not assigned it returns zero (default)
    function getVersionForAsset(address _siloAsset) external returns (uint128);

    /// @notice setter for `getVersionForAsset` mapping
    /// @param _siloAsset silo asset
    /// @param _version version of Silo that will be assigned for `_siloAsset`, zero (default) is acceptable
    function setVersionForAsset(address _siloAsset, uint128 _version) external;

    /// @notice use this method only when off-chain verification is OFF
    /// @dev Silo does NOT support rebase and deflationary tokens
    /// @param _siloAsset silo asset
    /// @param _siloData (optional) data that may be needed during silo creation
    /// @return createdSilo address of created silo
    function newSilo(address _siloAsset, bytes memory _siloData) external returns (address createdSilo);

    /// @notice use this method to deploy new version of Silo for an asset that already has Silo deployed.
    /// Only owner (DAO) can replace.
    /// @dev Silo does NOT support rebase and deflationary tokens
    /// @param _siloAsset silo asset
    /// @param _siloVersion version of silo implementation. Use 0 for default version which is fine
    /// for 99% of cases.
    /// @param _siloData (optional) data that may be needed during silo creation
    /// @return createdSilo address of created silo
    function replaceSilo(
        address _siloAsset,
        uint128 _siloVersion,
        bytes memory _siloData
    ) external returns (address createdSilo);

    /// @notice Set factory contract for debt and collateral tokens for each Silo asset
    /// @dev Callable only by owner
    /// @param _tokensFactory address of TokensFactory contract that deploys debt and collateral tokens
    function setTokensFactory(address _tokensFactory) external;

    /// @notice Set default fees
    /// @dev Callable only by owner
    /// @param _fees:
    /// - _entryFee one time protocol fee for opening a borrow position in precision points
    /// (Solvency._PRECISION_DECIMALS)
    /// - _protocolShareFee protocol revenue share in interest paid in precision points
    /// (Solvency._PRECISION_DECIMALS)
    /// - _protocolLiquidationFee protocol share in liquidation profit in precision points
    /// (Solvency._PRECISION_DECIMALS). It's calculated from total collateral amount to be transferred
    /// to liquidator.
    function setFees(Fees calldata _fees) external;

    /// @notice Set configuration for given asset in given Silo
    /// @dev Callable only by owner
    /// @param _silo Silo address for which config applies
    /// @param _asset asset address for which config applies
    /// @param _assetConfig:
    ///    - _maxLoanToValue maximum Loan-to-Value, for details see `Repository.AssetConfig.maxLoanToValue`
    ///    - _liquidationThreshold liquidation threshold, for details see `Repository.AssetConfig.maxLoanToValue`
    ///    - _interestRateModel interest rate model address, for details see `Repository.AssetConfig.interestRateModel`
    function setAssetConfig(
        address _silo,
        address _asset,
        AssetConfig calldata _assetConfig
    ) external;

    /// @notice Set default interest rate model
    /// @dev Callable only by owner
    /// @param _defaultInterestRateModel default interest rate model
    function setDefaultInterestRateModel(IInterestRateModel _defaultInterestRateModel) external;

    /// @notice Set default maximum LTV
    /// @dev Callable only by owner
    /// @param _defaultMaxLTV default maximum LTV in precision points (Solvency._PRECISION_DECIMALS)
    function setDefaultMaximumLTV(uint64 _defaultMaxLTV) external;

    /// @notice Set default liquidation threshold
    /// @dev Callable only by owner
    /// @param _defaultLiquidationThreshold default liquidation threshold in precision points
    /// (Solvency._PRECISION_DECIMALS)
    function setDefaultLiquidationThreshold(uint64 _defaultLiquidationThreshold) external;

    /// @notice Set price provider repository
    /// @dev Callable only by owner
    /// @param _repository price provider repository address
    function setPriceProvidersRepository(IPriceProvidersRepository _repository) external;

    /// @notice Set router contract
    /// @dev Callable only by owner
    /// @param _router router address
    function setRouter(address _router) external;

    /// @notice Set NotificationReceiver contract
    /// @dev Callable only by owner
    /// @param _silo silo address for which to set `_notificationReceiver`
    /// @param _notificationReceiver NotificationReceiver address
    function setNotificationReceiver(address _silo, INotificationReceiver _notificationReceiver) external;

    /// @notice Adds new bridge asset
    /// @dev New bridge asset must be unique. Duplicates in bridge assets are not allowed. It's possible to add
    /// bridge asset that has been removed in the past. Note that all Silos must be synced manually. Callable
    /// only by owner.
    /// @param _newBridgeAsset bridge asset address
    function addBridgeAsset(address _newBridgeAsset) external;

    /// @notice Removes bridge asset
    /// @dev Note that all Silos must be synced manually. Callable only by owner.
    /// @param _bridgeAssetToRemove bridge asset address to be removed
    function removeBridgeAsset(address _bridgeAssetToRemove) external;

    /// @notice Registers new Silo version
    /// @dev User can choose which Silo version he wants to deploy. It's possible to have multiple versions of Silo.
    /// Callable only by owner.
    /// @param _factory factory contract that deploys new version of Silo
    /// @param _isDefault true if this version should be used as default
    function registerSiloVersion(ISiloFactory _factory, bool _isDefault) external;

    /// @notice Unregisters Silo version
    /// @dev Callable only by owner.
    /// @param _siloVersion Silo version to be unregistered
    function unregisterSiloVersion(uint128 _siloVersion) external;

    /// @notice Sets default Silo version
    /// @dev Callable only by owner.
    /// @param _defaultVersion Silo version to be set as default
    function setDefaultSiloVersion(uint128 _defaultVersion) external;

    /// @notice Check if contract address is a Silo deployment
    /// @param _silo address of expected Silo
    /// @return true if address is Silo deployment, otherwise false
    function isSilo(address _silo) external view returns (bool);

    /// @notice Get Silo address of asset
    /// @param _asset address of asset
    /// @return address of corresponding Silo deployment
    function getSilo(address _asset) external view returns (address);

    /// @notice Get Silo Factory for given version
    /// @param _siloVersion version of Silo implementation
    /// @return ISiloFactory contract that deploys Silos of given version
    function siloFactory(uint256 _siloVersion) external view returns (ISiloFactory);

    /// @notice Get debt and collateral Token Factory
    /// @return ITokensFactory contract that deploys debt and collateral tokens
    function tokensFactory() external view returns (ITokensFactory);

    /// @notice Get Router contract
    /// @return address of router contract
    function router() external view returns (address);

    /// @notice Get current bridge assets
    /// @dev Keep in mind that not all Silos may be synced with current bridge assets so it's possible that some
    /// assets in that list are not part of given Silo.
    /// @return address array of bridge assets
    function getBridgeAssets() external view returns (address[] memory);

    /// @notice Get removed bridge assets
    /// @dev Keep in mind that not all Silos may be synced with bridge assets so it's possible that some
    /// assets in that list are still part of given Silo.
    /// @return address array of bridge assets
    function getRemovedBridgeAssets() external view returns (address[] memory);

    /// @notice Get maximum LTV for asset in given Silo
    /// @dev If dedicated config is not set, method returns default config
    /// @param _silo address of Silo
    /// @param _asset address of an asset
    /// @return maximum LTV in precision points (Solvency._PRECISION_DECIMALS)
    function getMaximumLTV(address _silo, address _asset) external view returns (uint256);

    /// @notice Get Interest Rate Model address for asset in given Silo
    /// @dev If dedicated config is not set, method returns default config
    /// @param _silo address of Silo
    /// @param _asset address of an asset
    /// @return address of interest rate model
    function getInterestRateModel(address _silo, address _asset) external view returns (IInterestRateModel);

    /// @notice Get liquidation threshold for asset in given Silo
    /// @dev If dedicated config is not set, method returns default config
    /// @param _silo address of Silo
    /// @param _asset address of an asset
    /// @return liquidation threshold in precision points (Solvency._PRECISION_DECIMALS)
    function getLiquidationThreshold(address _silo, address _asset) external view returns (uint256);

    /// @notice Get incentive contract address. Incentive contracts are responsible for distributing rewards
    /// to debt and/or collateral token holders of given Silo
    /// @param _silo address of Silo
    /// @return incentive contract address
    function getNotificationReceiver(address _silo) external view returns (INotificationReceiver);

    /// @notice Get owner role address of Repository
    /// @return owner role address
    function owner() external view returns (address);

    /// @notice get PriceProvidersRepository contract that manages price providers implementations
    /// @return IPriceProvidersRepository address
    function priceProvidersRepository() external view returns (IPriceProvidersRepository);

    /// @dev Get protocol fee for opening a borrow position
    /// @return fee in precision points (Solvency._PRECISION_DECIMALS == 100%)
    function entryFee() external view returns (uint256);

    /// @dev Get protocol share fee
    /// @return protocol share fee in precision points (Solvency._PRECISION_DECIMALS == 100%)
    function protocolShareFee() external view returns (uint256);

    /// @dev Get protocol liquidation fee
    /// @return protocol liquidation fee in precision points (Solvency._PRECISION_DECIMALS == 100%)
    function protocolLiquidationFee() external view returns (uint256);

    /// @dev Checks all conditions for new silo creation and throws when not possible to create
    /// @param _asset address of asset for which you want to create silo
    /// @param _assetIsABridge bool TRUE when `_asset` is bridge asset, FALSE when it is not
    function ensureCanCreateSiloFor(address _asset, bool _assetIsABridge) external view;

    function siloRepositoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IShareToken.sol";

interface ITokensFactory {
    /// @notice Emitted when collateral token is deployed
    /// @param token address of deployed collateral token
    event NewShareCollateralTokenCreated(address indexed token);

    /// @notice Emitted when collateral token is deployed
    /// @param token address of deployed debt token
    event NewShareDebtTokenCreated(address indexed token);

    ///@notice Must be called by repository on constructor
    /// @param _siloRepository the SiloRepository to set
    function initRepository(address _siloRepository) external;

    /// @notice Deploys collateral token
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @param _asset underlying asset for which token is deployed
    /// @return address of deployed collateral share token
    function createShareCollateralToken(
        string memory _name,
        string memory _symbol,
        address _asset
    ) external returns (IShareToken);

    /// @notice Deploys debt token
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @param _asset underlying asset for which token is deployed
    /// @return address of deployed debt share token
    function createShareDebtToken(
        string memory _name,
        string memory _symbol,
        address _asset
    )
        external
        returns (IShareToken);

    /// @dev just a helper method to see if address is a factory
    /// @return always true
    function tokensFactoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

library EasyMath {
    error ZeroAssets();
    error ZeroShares();

    function toShare(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return amount;
        }

        uint256 result = amount * totalShares / totalAmount;

        // Prevent rounding error
        if (result == 0 && amount != 0) {
            revert ZeroShares();
        }

        return result;
    }

    function toShareRoundUp(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return amount;
        }

        uint256 numerator = amount * totalShares;
        uint256 result = numerator / totalAmount;
        
        // Round up
        if (numerator % totalAmount != 0) {
            result += 1;
        }

        return result;
    }

    function toAmount(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        uint256 result = share * totalAmount / totalShares;

        // Prevent rounding error
        if (result == 0 && share != 0) {
            revert ZeroAssets();
        }

        return result;
    }

    function toAmountRoundUp(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        uint256 numerator = share * totalAmount;
        uint256 result = numerator / totalShares;
        
        // Round up
        if (numerator % totalShares != 0) {
            result += 1;
        }

        return result;
    }

    function toValue(uint256 _assetAmount, uint256 _assetPrice, uint256 _assetDecimals)
        internal
        pure
        returns (uint256)
    {
        return _assetAmount * _assetPrice / 10 ** _assetDecimals;
    }

    function sum(uint256[] memory _numbers) internal pure returns (uint256 s) {
        for(uint256 i; i < _numbers.length; i++) {
            s += _numbers[i];
        }
    }

    /// @notice Calculates fraction between borrowed and deposited amount of tokens denominated in percentage
    /// @dev It assumes `_dp` = 100%.
    /// @param _dp decimal points used by model
    /// @param _totalDeposits current total deposits for assets
    /// @param _totalBorrowAmount current total borrows for assets
    /// @return utilization value
    function calculateUtilization(uint256 _dp, uint256 _totalDeposits, uint256 _totalBorrowAmount)
        internal
        pure
        returns (uint256)
    {
        if (_totalDeposits == 0 || _totalBorrowAmount == 0) return 0;

        return _totalBorrowAmount * _dp / _totalDeposits;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;


library Ping {
    function pong(function() external pure returns(bytes4) pingFunction) internal pure returns (bool) {
        return pingFunction.address != address(0) && pingFunction.selector == pingFunction();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IPriceProvidersRepository.sol";
import "../interfaces/ISilo.sol";
import "../interfaces/IInterestRateModel.sol";
import "../interfaces/ISiloRepository.sol";
import "./EasyMath.sol";

library Solvency {
    using EasyMath for uint256;

    /// @notice
    /// MaximumLTV - Maximum Loan-to-Value ratio represents the maximum borrowing power of all user's collateral
    /// positions in a Silo
    /// LiquidationThreshold - Liquidation Threshold represents the threshold at which all user's borrow positions
    /// in a Silo will be considered under collateralized and subject to liquidation
    enum TypeofLTV { MaximumLTV, LiquidationThreshold }

    error DifferentArrayLength();
    error UnsupportedLTVType();

    struct SolvencyParams {
        /// @param siloRepository SiloRepository address
        ISiloRepository siloRepository;
        /// @param silo Silo address
        ISilo silo;
        /// @param assets array with assets
        address[] assets;
        /// @param assetStates array of states for each asset, where index match the `assets` index
        ISilo.AssetStorage[] assetStates;
        /// @param user wallet address for which to read debt
        address user;
    }

    /// @dev is value that used for integer calculations and decimal points for utilization ratios, LTV, protocol fees
    uint256 internal constant _PRECISION_DECIMALS = 1e18;
    uint256 internal constant _INFINITY = type(uint256).max;

    /// @notice Returns current user LTV and second LTV chosen in params
    /// @dev This function is optimized for protocol use. In some cases there is no need to keep the calculation
    /// going and predefined results can be returned.
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @param _secondLtvType type of LTV to be returned as second value
    /// @return currentUserLTV Loan-to-Value ratio represents current user's proportion of debt to collateral
    /// @return secondLTV second type of LTV which depends on _secondLtvType, zero is returned if the value of the loan
    /// or the collateral are zero
    function calculateLTVs(SolvencyParams memory _params, TypeofLTV _secondLtvType)
        internal
        view
        returns (uint256 currentUserLTV, uint256 secondLTV)
    {
        uint256[] memory totalBorrowAmounts = getBorrowAmounts(_params);

        // this return avoids eg. additional checks on withdraw, when user did not borrow any asset
        if (EasyMath.sum(totalBorrowAmounts) == 0) return (0, 0);

        IPriceProvidersRepository priceProvidersRepository = _params.siloRepository.priceProvidersRepository();

        uint256[] memory borrowValues = convertAmountsToValues(
            priceProvidersRepository,
            _params.assets,
            totalBorrowAmounts
        );

        // value of user's total debt
        uint256 borrowTotalValue = EasyMath.sum(borrowValues);

        if (borrowTotalValue == 0) return (0, 0);

        uint256[] memory collateralValues = getUserCollateralValues(priceProvidersRepository, _params);

        // value of user's collateral
        uint256 collateralTotalValue = EasyMath.sum(collateralValues);

        if (collateralTotalValue == 0) return (_INFINITY, 0);

        // value of theoretical debt user can have depending on TypeofLTV
        uint256 borrowAvailableTotalValue = _getTotalAvailableToBorrowValue(
            _params.siloRepository,
            address(_params.silo),
            _params.assets,
            _secondLtvType,
            collateralValues
        );

        currentUserLTV = borrowTotalValue * _PRECISION_DECIMALS / collateralTotalValue;

        // one of Solvency.TypeofLTV
        secondLTV = borrowAvailableTotalValue * _PRECISION_DECIMALS / collateralTotalValue;
    }

    /// @notice Calculates chosen LTV limit
    /// @dev This function should be used by external actors like SiloLens and UI/subgraph. `calculateLTVs` is
    /// optimized for protocol use and may not return second LVT calculation when they are not needed.
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @param _ltvType acceptable values are only TypeofLTV.MaximumLTV or TypeofLTV.LiquidationThreshold
    /// @return limit theoretical LTV limit of `_ltvType`
    function calculateLTVLimit(SolvencyParams memory _params, TypeofLTV _ltvType)
        internal
        view
        returns (uint256 limit)
    {
        IPriceProvidersRepository priceProvidersRepository = _params.siloRepository.priceProvidersRepository();

        uint256[] memory collateralValues = getUserCollateralValues(priceProvidersRepository, _params);

        // value of user's collateral
        uint256 collateralTotalValue = EasyMath.sum(collateralValues);

        if (collateralTotalValue == 0) return 0;

        // value of theoretical debt user can have depending on TypeofLTV
        uint256 borrowAvailableTotalValue = _getTotalAvailableToBorrowValue(
            _params.siloRepository,
            address(_params.silo),
            _params.assets,
            _ltvType,
            collateralValues
        );

        limit = borrowAvailableTotalValue * _PRECISION_DECIMALS / collateralTotalValue;
    }

    /// @notice Returns worth (in quote token) of each collateral deposit of a user
    /// @param _priceProvidersRepository address of IPriceProvidersRepository where prices are read
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @return collateralValues worth of each collateral deposit of a user as an array
    function getUserCollateralValues(IPriceProvidersRepository _priceProvidersRepository, SolvencyParams memory _params)
        internal
        view
        returns(uint256[] memory collateralValues)
    {
        uint256[] memory collateralAmounts = getCollateralAmounts(_params);
        collateralValues = convertAmountsToValues(_priceProvidersRepository, _params.assets, collateralAmounts);
    }

    /// @notice Convert assets amounts to values in quote token (amount * price)
    /// @param _priceProviderRepo address of IPriceProvidersRepository where prices are read
    /// @param _assets array with assets for which prices are read
    /// @param _amounts array of amounts
    /// @return values array of values for corresponding assets
    function convertAmountsToValues(
        IPriceProvidersRepository _priceProviderRepo,
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal view returns (uint256[] memory values) {
        if (_assets.length != _amounts.length) revert DifferentArrayLength();

        values = new uint256[](_assets.length);

        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] == 0) continue;

            uint256 assetPrice = _priceProviderRepo.getPrice(_assets[i]);
            uint8 assetDecimals = ERC20(_assets[i]).decimals();

            values[i] = _amounts[i].toValue(assetPrice, assetDecimals);
        }
    }

    /// @notice Get amount of collateral for each asset
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @return collateralAmounts array of amounts for each token in Silo. May contain zero values if user
    /// did not deposit given collateral token.
    function getCollateralAmounts(SolvencyParams memory _params)
        internal
        view
        returns (uint256[] memory collateralAmounts)
    {
        if (_params.assets.length != _params.assetStates.length) {
            revert DifferentArrayLength();
        }

        collateralAmounts = new uint256[](_params.assets.length);

        for (uint256 i = 0; i < _params.assets.length; i++) {
            uint256 userCollateralTokenBalance = _params.assetStates[i].collateralToken.balanceOf(_params.user);
            uint256 userCollateralOnlyTokenBalance = _params.assetStates[i].collateralOnlyToken.balanceOf(_params.user);

            if (userCollateralTokenBalance + userCollateralOnlyTokenBalance == 0) continue;

            uint256 rcomp = getRcomp(_params.silo, _params.siloRepository, _params.assets[i], block.timestamp);

            collateralAmounts[i] = getUserCollateralAmount(
                _params.assetStates[i],
                userCollateralTokenBalance,
                userCollateralOnlyTokenBalance,
                rcomp,
                _params.siloRepository
            );
        }
    }

    /// @notice Get amount of debt for each asset
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @return totalBorrowAmounts array of amounts for each token in Silo. May contain zero values if user
    /// did not borrow given token.
    function getBorrowAmounts(SolvencyParams memory _params)
        internal
        view
        returns (uint256[] memory totalBorrowAmounts)
    {
        if (_params.assets.length != _params.assetStates.length) {
            revert DifferentArrayLength();
        }

        totalBorrowAmounts = new uint256[](_params.assets.length);

        for (uint256 i = 0; i < _params.assets.length; i++) {
            uint256 rcomp = getRcomp(_params.silo, _params.siloRepository, _params.assets[i], block.timestamp);
            totalBorrowAmounts[i] = getUserBorrowAmount(_params.assetStates[i], _params.user, rcomp);
        }
    }

    /// @notice Get amount of deposited token, including collateralOnly deposits
    /// @param _assetStates state of deposited asset in Silo
    /// @param _userCollateralTokenBalance balance of user's share collateral token
    /// @param _userCollateralOnlyTokenBalance balance of user's share collateralOnly token
    /// @param _rcomp compounded interest rate to account for during calculations, could be 0
    /// @param _siloRepository SiloRepository address
    /// @return amount of underlying token deposited, including collateralOnly deposit
    function getUserCollateralAmount(
        ISilo.AssetStorage memory _assetStates,
        uint256 _userCollateralTokenBalance,
        uint256 _userCollateralOnlyTokenBalance,
        uint256 _rcomp,
        ISiloRepository _siloRepository
    ) internal view returns (uint256) {
        uint256 assetAmount = _userCollateralTokenBalance == 0 ? 0 : _userCollateralTokenBalance.toAmount(
            totalDepositsWithInterest(_assetStates.totalDeposits, _siloRepository.protocolShareFee(), _rcomp),
            _assetStates.collateralToken.totalSupply()
        );

        uint256 assetCollateralOnlyAmount = _userCollateralOnlyTokenBalance == 0
            ? 0
            : _userCollateralOnlyTokenBalance.toAmount(
                _assetStates.collateralOnlyDeposits,
                _assetStates.collateralOnlyToken.totalSupply()
            );

        return assetAmount + assetCollateralOnlyAmount;
    }

    /// @notice Get amount of borrowed token
    /// @param _assetStates state of borrowed asset in Silo
    /// @param _user user wallet address for which to read debt
    /// @param _rcomp compounded interest rate to account for during calculations, could be 0
    /// @return amount of borrowed token
    function getUserBorrowAmount(ISilo.AssetStorage memory _assetStates, address _user, uint256 _rcomp)
        internal
        view
        returns (uint256)
    {
        uint256 balance = _assetStates.debtToken.balanceOf(_user);
        if (balance == 0) return 0;

        uint256 totalBorrowAmountCached = totalBorrowAmountWithInterest(_assetStates.totalBorrowAmount, _rcomp);
        return balance.toAmountRoundUp(totalBorrowAmountCached, _assetStates.debtToken.totalSupply());
    }

    /// @notice Get compounded interest rate from the model
    /// @param _silo Silo address
    /// @param _siloRepository SiloRepository address
    /// @param _asset address of asset for which to read interest rate
    /// @param _timestamp used to determine amount of time from last rate update
    /// @return rcomp compounded interest rate for an asset
    function getRcomp(ISilo _silo, ISiloRepository _siloRepository, address _asset, uint256 _timestamp)
        internal
        view
        returns (uint256 rcomp)
    {
        IInterestRateModel model = _siloRepository.getInterestRateModel(address(_silo), _asset);
        rcomp = model.getCompoundInterestRate(address(_silo), _asset, _timestamp);
    }

    /// @notice Returns total deposits with interest dynamically calculated with the provided rComp
    /// @param _assetTotalDeposits total deposits for asset
    /// @param _protocolShareFee `siloRepository.protocolShareFee()`
    /// @param _rcomp compounded interest rate
    /// @return _totalDepositsWithInterests total deposits amount with interest
    function totalDepositsWithInterest(uint256 _assetTotalDeposits, uint256 _protocolShareFee, uint256 _rcomp)
        internal
        pure
        returns (uint256 _totalDepositsWithInterests)
    {
        uint256 depositorsShare = _PRECISION_DECIMALS - _protocolShareFee;

        return _assetTotalDeposits + _assetTotalDeposits * _rcomp / _PRECISION_DECIMALS * depositorsShare /
            _PRECISION_DECIMALS;
    }

    /// @notice Returns total borrow amount with interest dynamically calculated with the provided rComp
    /// @param _totalBorrowAmount total borrow amount
    /// @param _rcomp compounded interest rate
    /// @return totalBorrowAmountWithInterests total borrow amount with interest
    function totalBorrowAmountWithInterest(uint256 _totalBorrowAmount, uint256 _rcomp)
        internal
        pure
        returns (uint256 totalBorrowAmountWithInterests)
    {
        totalBorrowAmountWithInterests = _totalBorrowAmount + _totalBorrowAmount * _rcomp / _PRECISION_DECIMALS;
    }

    /// @notice Calculates protocol liquidation fee and new protocol total fees collected
    /// @param _protocolEarnedFees amount of total collected fees so far
    /// @param _amount amount on which we will apply fee
    /// @param _liquidationFee liquidation fee in Solvency._PRECISION_DECIMALS
    /// @return liquidationFeeAmount calculated interest
    /// @return newProtocolEarnedFees the new total amount of protocol fees
    function calculateLiquidationFee(uint256 _protocolEarnedFees, uint256 _amount, uint256 _liquidationFee)
        internal
        pure
        returns (uint256 liquidationFeeAmount, uint256 newProtocolEarnedFees)
    {
        unchecked {
            // If we overflow on multiplication it should not revert tx, we will get lower fees
            liquidationFeeAmount = _amount * _liquidationFee / Solvency._PRECISION_DECIMALS;

            if (_protocolEarnedFees > type(uint256).max - liquidationFeeAmount) {
                newProtocolEarnedFees = type(uint256).max;
                liquidationFeeAmount = type(uint256).max - _protocolEarnedFees;
            } else {
                newProtocolEarnedFees = _protocolEarnedFees + liquidationFeeAmount;
            }
        }
    }

    /// @notice Calculates theoretical value (in quote token) that user could borrow based given collateral value
    /// @param _siloRepository SiloRepository address
    /// @param _silo Silo address
    /// @param _asset address of collateral token
    /// @param _type type of LTV limit to use for calculations
    /// @param _collateralValue value of collateral deposit (in quote token)
    /// @return availableToBorrow value (in quote token) that user can borrow against collateral value
    function _getAvailableToBorrowValue(
        ISiloRepository _siloRepository,
        address _silo,
        address _asset,
        TypeofLTV _type,
        uint256 _collateralValue
    ) private view returns (uint256 availableToBorrow) {
        uint256 assetLTV;

        if (_type == TypeofLTV.MaximumLTV) {
            assetLTV = _siloRepository.getMaximumLTV(_silo, _asset);
        } else if (_type == TypeofLTV.LiquidationThreshold) {
            assetLTV = _siloRepository.getLiquidationThreshold(_silo, _asset);
        } else {
            revert UnsupportedLTVType();
        }

        // value that can be borrowed against the deposit
        // ie. for assetLTV = 50%, 1 ETH * 50% = 0.5 ETH of available to borrow
        availableToBorrow = _collateralValue * assetLTV / _PRECISION_DECIMALS;
    }

    /// @notice Calculates theoretical value (in quote token) that user can borrow based on deposited collateral
    /// @param _siloRepository SiloRepository address
    /// @param _silo Silo address
    /// @param _assets array with assets
    /// @param _ltvType type of LTV limit to use for calculations
    /// acceptable values are only TypeofLTV.MaximumLTV or TypeofLTV.LiquidationThreshold
    /// @param _collateralValues value (worth in quote token) of each deposit made by user
    /// @return totalAvailableToBorrowValue value (in quote token) that user can borrow against collaterals
    function _getTotalAvailableToBorrowValue(
        ISiloRepository _siloRepository,
        address _silo,
        address[] memory _assets,
        TypeofLTV _ltvType,
        uint256[] memory _collateralValues
    ) private view returns (uint256 totalAvailableToBorrowValue) {
        if (_assets.length != _collateralValues.length) revert DifferentArrayLength();

        for (uint256 i = 0; i < _assets.length; i++) {
            totalAvailableToBorrowValue += _getAvailableToBorrowValue(
                _siloRepository,
                _silo,
                _assets[i],
                _ltvType,
                _collateralValues[i]
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


library TokenHelper {
    uint256 private constant _BYTES32_SIZE = 32;

    error TokenIsNotAContract();

    function assertAndGetDecimals(address _token) internal view returns (uint256) {
        (bool hasMetadata, bytes memory data) = _tokenMetadataCall(_token, abi.encodeCall(IERC20Metadata.decimals,()));

        // decimals() is optional in the ERC20 standard, so if metadata is not accessible
        // we assume there are no decimals and use 0.
        if (!hasMetadata) {
            return 0;
        }

        return abi.decode(data, (uint8));
    }

    /// @dev Returns the symbol for the provided ERC20 token.
    /// An empty string is returned if the call to the token didn't succeed.
    /// @param _token address of the token to get the symbol for
    /// @return assetSymbol the token symbol
    function symbol(address _token) internal view returns (string memory assetSymbol) {
        (bool hasMetadata, bytes memory data) = _tokenMetadataCall(_token, abi.encodeCall(IERC20Metadata.symbol,()));

        if (!hasMetadata || data.length == 0) {
            return "?";
        } else if (data.length == _BYTES32_SIZE) {
            return string(removeZeros(data));
        } else {
            return abi.decode(data, (string));
        }
    }

    /// @dev Removes bytes with value equal to 0 from the provided byte array.
    /// @param _data byte array from which to remove zeroes
    /// @return result byte array with zeroes removed 
    function removeZeros(bytes memory _data) internal pure returns (bytes memory result) {
        uint256 n = _data.length;

        unchecked {
            for (uint256 i; i < n; i++) {
                if (_data[i] == 0) continue;

                result = abi.encodePacked(result, _data[i]);
            }
        }
    }

    /// @dev Performs a staticcall to the token to get its metadata (symbol, decimals, name)
    function _tokenMetadataCall(address _token, bytes memory _data) private view returns(bool, bytes memory) {
        // We need to do this before the call, otherwise the call will succeed even for EOAs
        if (!Address.isContract(_token)) revert TokenIsNotAContract();

        (bool success, bytes memory result) = _token.staticcall(_data);

        // If the call reverted we assume the token doesn't follow the metadata extension
        if (!success) {
            return (false, "");
        }

        return (true, result);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev This is cloned solution of @openzeppelin/contracts/security/ReentrancyGuard.sol
abstract contract LiquidationReentrancyGuard {
    error LiquidationReentrancyCall();

    uint256 private constant _LIQUIDATION_NOT_ENTERED = 1;
    uint256 private constant _LIQUIDATION_ENTERED = 2;

    uint256 private _liquidationStatus;

    modifier liquidationNonReentrant() {
        if (_liquidationStatus == _LIQUIDATION_ENTERED) {
            revert LiquidationReentrancyCall();
        }

        _liquidationStatus = _LIQUIDATION_ENTERED;

        _;

        _liquidationStatus = _LIQUIDATION_NOT_ENTERED;
    }

    constructor() {
        _liquidationStatus = _LIQUIDATION_NOT_ENTERED;
    }
}