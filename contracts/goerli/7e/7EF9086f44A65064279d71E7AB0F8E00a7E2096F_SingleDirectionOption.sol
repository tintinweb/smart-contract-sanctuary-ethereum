// SPDX-License-Identifier: MIT

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
pragma solidity =0.8.17;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Utils.sol";
import "./StructureData.sol";
//import "hardhat/console.sol"; 

library OptionLifecycle {
    using SafeERC20 for IERC20;
    using Utils for uint128;
    using Utils for uint256;  
    using StructureData for StructureData.UserState; 

    //physical withdraw
    function withdraw(
        address _target,
        uint256 _amount,
        address _contractAddress
    ) external {
        require(_amount > 0, "!amt");
        if (
            _contractAddress ==
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            payable(_target).transfer(_amount);
        } else {
            IERC20(_contractAddress).safeTransfer(_target, _amount);
        }
    }
 
    function initiateWithrawStorage(
        StructureData.VaultState storage _vault,
        address _user,
        uint256 _amountToRedeem
    ) external {
        rollToNextRoundIfNeeded(_vault);
        require(_vault.currentRound > 1, "Nothing to redeem");

        StructureData.UserState storage state = _vault.userStates[_user]; 
        _vault.userStates[_user] = recalcState(
            _vault,
            state,
            _vault.currentRound
        );

        state = _vault.userStates[_user];

        uint256 maxInstantRedeemable =
            uint256(state.expiredAmount) - state.expiredQueuedRedeemAmount;
        uint256 maxRedeemable =
            maxInstantRedeemable + state.onGoingAmount -
                state.onGoingQueuedRedeemAmount;
        require(_amountToRedeem <= maxRedeemable, "Not enough to redeem");

        //check if the sold amount is expired or not
        //1. withdraw initiated before the sold option expired (buyer not providing the expiry level yet)
        //user could terminate all the sold options, and selling options
        //user would be able to redeem all the sold options after expiry and all the selling option after next expiry
        uint256 price =
            _vault.currentRound > 2
                ? _vault.depositPriceAfterExpiryPerRound[
                    _vault.currentRound - 2
                ]
                : 0;
         
        if (price == 0) {
            //first redeem from the sold options
            if (_amountToRedeem <= maxInstantRedeemable) {
                uint256 expiredQueuedRedeemAmount =
                    _amountToRedeem + state.expiredQueuedRedeemAmount;
                Utils.assertUint128(expiredQueuedRedeemAmount);
                state.expiredQueuedRedeemAmount = uint128(
                    expiredQueuedRedeemAmount
                );
                uint256 totalExpiredQueuedRedeemAmount =
                    _amountToRedeem + _vault.expired.queuedRedeemAmount;
                Utils.assertUint128(totalExpiredQueuedRedeemAmount);
                _vault.expired.queuedRedeemAmount = uint128(
                    totalExpiredQueuedRedeemAmount
                );
            } else {
                uint256 amountToRemdeemNextRound =
                    _amountToRedeem - maxInstantRedeemable;
                state.expiredQueuedRedeemAmount = state.expiredAmount;
                uint256 onGoingQueuedRedeemAmount =
                    amountToRemdeemNextRound +
                        state.onGoingQueuedRedeemAmount;
                Utils.assertUint128(onGoingQueuedRedeemAmount);
                state.onGoingQueuedRedeemAmount = uint128(
                    onGoingQueuedRedeemAmount
                );
                _vault.expired.queuedRedeemAmount = uint128(
                    uint256(_vault.expired.queuedRedeemAmount) + 
                        maxInstantRedeemable
                );
                _vault.onGoing.queuedRedeemAmount = uint128(
                    uint256(_vault.onGoing.queuedRedeemAmount) + 
                        amountToRemdeemNextRound
                );
            }
        }
        //2. withdraw initiated after the sold option expired (expiry level specified)
        //user could terminate all the selling options
        //user would be able to redeem all the selling options after next expiry
        else {
            uint256 onGoingQueuedRedeemAmount =
                _amountToRedeem + state.onGoingQueuedRedeemAmount;
            Utils.assertUint128(onGoingQueuedRedeemAmount);
            state.onGoingQueuedRedeemAmount = uint128(
                onGoingQueuedRedeemAmount
            );
            uint256 totalOnGoingQueuedRedeemAmount =
                _amountToRedeem + _vault.onGoing.queuedRedeemAmount;
            Utils.assertUint128(totalOnGoingQueuedRedeemAmount);
            _vault.onGoing.queuedRedeemAmount = uint128(
                totalOnGoingQueuedRedeemAmount
            );
        }
    }

    function cancelWithrawStorage(
        StructureData.VaultState storage _vault,
        address _user,
        uint256 _amountToRedeemToCancel
    ) external {
        rollToNextRoundIfNeeded(_vault);
        require(_vault.currentRound > 1, "Nothing to cancel redeem");

        StructureData.UserState storage state = _vault.userStates[_user];
        _vault.userStates[_user] = recalcState(
            _vault,
            state,
            _vault.currentRound
        );
        state = _vault.userStates[_user];

        uint256 expiredQueuedRedeemAmount = state.expiredQueuedRedeemAmount;
        uint256 onGoingQueuedRedeemAmount = state.onGoingQueuedRedeemAmount;
        require(
            _amountToRedeemToCancel <=
                expiredQueuedRedeemAmount + onGoingQueuedRedeemAmount,
            "Not enough to cancel redeem"
        );
        if (_amountToRedeemToCancel <= expiredQueuedRedeemAmount) {
            state.expiredQueuedRedeemAmount = uint128(
                expiredQueuedRedeemAmount - _amountToRedeemToCancel
            );
            _vault.expired.queuedRedeemAmount = uint128(
                uint256(_vault.expired.queuedRedeemAmount) - 
                    _amountToRedeemToCancel
            );
            return;
        }
        state.expiredQueuedRedeemAmount = 0;
        _vault.expired.queuedRedeemAmount = uint128(
            uint256(_vault.expired.queuedRedeemAmount) -
                expiredQueuedRedeemAmount
        );
        uint256 onGoingQueuedRedeeemAmountToCancel =
            _amountToRedeemToCancel - expiredQueuedRedeemAmount;
        state.onGoingQueuedRedeemAmount = uint128(
            onGoingQueuedRedeemAmount - onGoingQueuedRedeeemAmountToCancel
        );
        _vault.onGoing.queuedRedeemAmount = uint128(
            uint256(_vault.onGoing.queuedRedeemAmount) - 
                onGoingQueuedRedeeemAmountToCancel
        );
    }

    function withdrawStorage(
        StructureData.VaultState storage _vaultState,
        address _user,
        uint256 _amount
    ) external {
        rollToNextRoundIfNeeded(_vaultState);

        StructureData.UserState storage state = _vaultState.userStates[_user];
        _vaultState.userStates[_user] = recalcState(
            _vaultState,
            state,
            _vaultState.currentRound
        );
        state = _vaultState.userStates[_user];

        uint256 redeemed = state.redeemed;
        if (state.redeemed >= _amount) {
            state.redeemed = uint128(redeemed - _amount);
            _vaultState.totalRedeemed = uint128(
                uint256(_vaultState.totalRedeemed) - _amount
            );
            return;
        }

        //then withdraw the pending
        uint256 pendingAmountToWithdraw = _amount - redeemed;
        require(
            state.pending >= pendingAmountToWithdraw,
            "Not enough to withdraw"
        );
        _vaultState.totalRedeemed = uint128(
            uint256(_vaultState.totalRedeemed) - redeemed
        );
        _vaultState.totalPending = uint128(
            uint256(_vaultState.totalPending) - pendingAmountToWithdraw
        );
        state.redeemed = 0;
        state.pending = uint128(
            uint256(state.pending) - pendingAmountToWithdraw
        );
    }

    function depositFor(
        StructureData.VaultState storage _vaultState,
        address _user,
        uint256 _amount
    ) external {
        rollToNextRoundIfNeeded(_vaultState);

        StructureData.UserState storage state = _vaultState.userStates[_user]; 
        _vaultState.userStates[_user] = recalcState(
            _vaultState,
            state,
            _vaultState.currentRound
        );
        state = _vaultState.userStates[_user]; 

        uint256 newTVL =
            _amount
                 + _vaultState.totalPending
                 + _vaultState.onGoing.amount
                 + _vaultState.expired.amount
                 - _vaultState.expired.queuedRedeemAmount;
        uint256 newUserPending = _amount + state.pending;
        require(newTVL <= _vaultState.maxCapacity, "Exceeds capacity");
        Utils.assertUint128(newUserPending);
        state.pending = uint128(newUserPending);
        uint256 newTotalPending = _amount + _vaultState.totalPending;
        Utils.assertUint128(newTotalPending);
        _vaultState.totalPending = uint128(newTotalPending);
    }

    //calculate the real round number based on epoch period(vault round would only be physically updated when there is relevant chain operation) 
    function getRealRound(StructureData.VaultState storage _vaultState)
        public
        view
        returns (uint32, uint16)
    {
        if (
            _vaultState.cutOffAt > block.timestamp ||
            _vaultState.currentRound == 0
        ) {
            return (_vaultState.cutOffAt, _vaultState.currentRound);
        }
        uint256 cutOffAt = _vaultState.cutOffAt;
        uint256 currentRound = _vaultState.currentRound;
        while (cutOffAt <= block.timestamp) {
            currentRound++;
            uint32 nextStartOverride = _vaultState.nextPeriodStartOverrides[uint16(currentRound)]; 
            if (nextStartOverride != 0) {
                cutOffAt = nextStartOverride;
            }
            else {
                cutOffAt = uint256(_vaultState.periodLength) + cutOffAt;
            } 
            require(cutOffAt <= type(uint32).max, "Overflow cutOffAt");
        }
        return (uint32(cutOffAt), uint16(currentRound));
    }

    //physically update the vault data 
    function rollToNextRoundIfNeeded(
        StructureData.VaultState storage _vaultState
    ) public {
        if (
            _vaultState.cutOffAt > block.timestamp ||
            _vaultState.currentRound == 0
        ) {
            return;
        }
        (uint32 cutOffAt, uint16 currentRound) = getRealRound(_vaultState);
        uint256 lastUpdateRound = _vaultState.currentRound;
        uint256 pending = _vaultState.totalPending;
        _vaultState.totalPending = 0;
        while (lastUpdateRound < currentRound) {
            StructureData.OptionState memory onGoing = _vaultState.onGoing;

            _vaultState.onGoing = StructureData.OptionState({
                amount: uint128(pending),
                queuedRedeemAmount: 0,
                strike: 0,
                premiumRate: 0,
                buyerAddress: address(0)
            });
            pending = 0;
            //premium not sent, simply bring it to next round as if the buyer lost the premium
            if (lastUpdateRound > 1 && _vaultState.expired.amount > 0) {
                uint104 premiumRate =
                    _vaultState.expired.buyerAddress == address(0)
                        ? 0
                        : _vaultState.expired.premiumRate;
                uint256 expiredAmount =
                    uint256(_vaultState.expired.amount).withPremium(
                        premiumRate
                    );
                uint256 expiredRedeemAmount =
                    uint256(_vaultState.expired.queuedRedeemAmount).withPremium(
                        premiumRate
                    );
                uint256 onGoingAmount =
                    uint256(_vaultState.onGoing.amount) + expiredAmount - 
                        expiredRedeemAmount;
                Utils.assertUint128(onGoingAmount);
                _vaultState.onGoing.amount = uint128(onGoingAmount);
                uint256 totalRedeemed =
                    uint256(_vaultState.totalRedeemed) + expiredRedeemAmount;
                Utils.assertUint128(totalRedeemed);
                _vaultState.totalRedeemed = uint128(totalRedeemed);
                _vaultState.depositPriceAfterExpiryPerRound[
                    uint16(lastUpdateRound - 2)
                ] = premiumRate  >  0 ? (Utils.RATIOMULTIPLIER + premiumRate) : 0;
                _vaultState.expiryLevelSkipped[uint16(lastUpdateRound - 2)] = true;
            }
            _vaultState.expired = onGoing; 
            lastUpdateRound = lastUpdateRound + 1;
        }

        _vaultState.cutOffAt = cutOffAt;
        _vaultState.currentRound = currentRound;
    }

     //calculate the real vault state 
    function recalcVault(StructureData.VaultState storage _vaultState)
        public
        view
        returns (StructureData.VaultSnapShot memory)
    {
        StructureData.VaultSnapShot memory snapShot =
            StructureData.VaultSnapShot({
                totalPending: _vaultState.totalPending,
                totalRedeemed: _vaultState.totalRedeemed,
                cutOffAt: _vaultState.cutOffAt,
                currentRound: _vaultState.currentRound,
                maxCapacity: _vaultState.maxCapacity,
                onGoing: _vaultState.onGoing,
                expired: _vaultState.expired
            });
        if (
            _vaultState.cutOffAt > block.timestamp ||
            _vaultState.currentRound == 0
        ) {
            return snapShot;
        }

        (uint32 cutOffAt, uint16 currentRound) = getRealRound(_vaultState);
        uint256 lastUpdateRound = _vaultState.currentRound;
        while (lastUpdateRound < currentRound) {
            StructureData.OptionState memory onGoing = snapShot.onGoing;
            snapShot.onGoing = StructureData.OptionState({
                amount: snapShot.totalPending,
                queuedRedeemAmount: 0,
                strike: 0,
                premiumRate: 0,
                buyerAddress: address(0)
            });

            //premium not sent, simply bring it to next round
            if (lastUpdateRound > 1 && snapShot.expired.amount > 0) {
                uint104 premiumRate =
                    snapShot.expired.buyerAddress == address(0)
                        ? 0
                        : snapShot.expired.premiumRate;
                uint256 expiredAmount =
                    uint256(snapShot.expired.amount).withPremium(premiumRate);
                uint256 expiredRedeemAmount =
                    uint256(snapShot.expired.queuedRedeemAmount).withPremium(
                        premiumRate
                    );
                uint256 onGoingAmount =
                    uint256(snapShot.onGoing.amount) + expiredAmount - 
                        expiredRedeemAmount;
                Utils.assertUint128(onGoingAmount);
                snapShot.onGoing.amount = uint128(onGoingAmount);
                uint256 totalRedeemed =
                    uint256(snapShot.totalRedeemed) + expiredRedeemAmount;
                Utils.assertUint128(totalRedeemed);
                snapShot.totalRedeemed = uint128(totalRedeemed);
            }
            snapShot.expired = onGoing;
            snapShot.totalPending = 0;
            lastUpdateRound = lastUpdateRound + 1;
        }

        snapShot.totalPending = 0;
        snapShot.cutOffAt = cutOffAt;
        snapShot.currentRound = currentRound;
        return snapShot;
    }

    //both premiumRate and depositPriceAfterExpiryPerRound are using 8 decimals as ratio
    function getDepositPriceAfterExpiryPerRound(
        StructureData.VaultState storage _vaultState,
        uint16 _round,
        uint16 _latestRound
    ) internal view returns (uint256, bool) {
        uint256 price = _vaultState.depositPriceAfterExpiryPerRound[_round]; 
        //expiry level specified
        if (price > 0) return (price, !_vaultState.expiryLevelSkipped[_round]);
        //expiry level overdued, use premiumRate
        if (
            _latestRound > _round + 2 &&
            _vaultState.currentRound == _round + 1 &&
            _vaultState.onGoing.premiumRate > 0 &&
            _vaultState.onGoing.buyerAddress != address(0)
        ) {
            return (
                Utils.RATIOMULTIPLIER + _vaultState.onGoing.premiumRate,
                false
            );
        }
        if (
            _latestRound > _round + 2 &&
            _vaultState.currentRound == _round + 2 &&
            _vaultState.expired.premiumRate > 0 &&
            _vaultState.expired.buyerAddress != address(0)
        ) {
            return (
                Utils.RATIOMULTIPLIER + _vaultState.expired.premiumRate,
                false
            );
        }

        //aggregate preivous non-sold round with current sold-round
        if (
            _latestRound > _round + 1 &&
            _vaultState.currentRound == _round + 2 &&
            _vaultState.onGoing.buyerAddress != address(0) &&
            _vaultState.expired.buyerAddress == address(0)
        ) {
            return (Utils.RATIOMULTIPLIER, true);
        }
        return (0, false);
    }

    //calculate the real user state
    function recalcState(
        StructureData.VaultState storage _vaultState,
        StructureData.UserState storage _userState,
        uint16 _currentRound
    ) public view returns (StructureData.UserState memory) {
        uint256 onGoingAmount = _userState.onGoingAmount;
        uint256 expiredAmount = _userState.expiredAmount;
        uint256 expiredQueuedRedeemAmount =
            _userState.expiredQueuedRedeemAmount;
        uint256 onGoingQueuedRedeemAmount =
            _userState.onGoingQueuedRedeemAmount;
        uint256 lastUpdateRound = _userState.lastUpdateRound;
        uint256 pendingAmount = _userState.pending;
        uint256 redeemed = _userState.redeemed;
        bool expiredAmountCaculated = lastUpdateRound == _currentRound && _userState.expiredAmountCaculated;
        //catch up the userState with the latest
        //Basically it's by increasing/decreasing the onGoing amount based on each round's status.
        //expired amount is a temporary state for expiry level settlement
        //One time step a: accumulate pending to on-going once, and then clear it out
        //One time step b: accumulate expiredQueuedRedeemAmount to redeemed, reduce it from expired, and then clear it out
        //One time step c: copy onGoingQueuedRedeemAmount to expiredQueuedRedeemAmount, and then clear it out
        //Set on-going -> adjust expired -> accummulate expired to new on-going -> move old on-going to expired 
        if (lastUpdateRound > 2 && !_userState.expiredAmountCaculated) {
            (uint256 price, bool expiryLevelSpecified) =
                getDepositPriceAfterExpiryPerRound(
                    _vaultState,
                    uint16(lastUpdateRound - 2),
                    _currentRound
                );
            if (price > 0) {  
                if (expiredAmount > 0) {
                    expiredAmount = expiredAmount * price /
                        Utils.RATIOMULTIPLIER;
                    expiredQueuedRedeemAmount = expiredQueuedRedeemAmount
                         * price / Utils.RATIOMULTIPLIER;
                    if (expiryLevelSpecified) {
                        onGoingAmount = onGoingAmount + expiredAmount - 
                            expiredQueuedRedeemAmount;
                        expiredAmount = 0;                    
                        redeemed = redeemed + expiredQueuedRedeemAmount;
                        expiredQueuedRedeemAmount = 0;
                    } 
                } else { 
                    onGoingAmount = onGoingAmount * price /  
                        Utils.RATIOMULTIPLIER; 
                }
                if (lastUpdateRound == _currentRound) {
                    expiredAmountCaculated = true;
                }
            }
        }

        while (lastUpdateRound < _currentRound) {
            uint256 oldOnGoing = onGoingAmount;

            //set on-going
            //One time step a
            onGoingAmount = pendingAmount;
            pendingAmount = 0;

            onGoingAmount = onGoingAmount + expiredAmount - 
                expiredQueuedRedeemAmount;
            expiredAmount = oldOnGoing;

            //One time step b
            redeemed = redeemed + expiredQueuedRedeemAmount;

            //One time step c
            expiredQueuedRedeemAmount = onGoingQueuedRedeemAmount;
            onGoingQueuedRedeemAmount = 0;

            lastUpdateRound = lastUpdateRound + 1;

            if (lastUpdateRound <= 2) continue;
            (uint256 price, bool expiryLevelSpecified) =
                getDepositPriceAfterExpiryPerRound(
                    _vaultState,
                    uint16(lastUpdateRound - 2),
                    _currentRound
                );

            if (price > 0) { 
                if (expiredAmount > 0) {
                    expiredAmount = expiredAmount * price / 
                        Utils.RATIOMULTIPLIER;
                    expiredQueuedRedeemAmount = expiredQueuedRedeemAmount
                        * price / Utils.RATIOMULTIPLIER;
                    if (expiryLevelSpecified) {
                        onGoingAmount = onGoingAmount + expiredAmount -
                            expiredQueuedRedeemAmount;
                        expiredAmount = 0;                    
                        redeemed = redeemed + expiredQueuedRedeemAmount;
                        expiredQueuedRedeemAmount = 0;
                    } 

                } else {
                    if (
                        _userState.pending > 0 &&
                        _userState.lastUpdateRound == lastUpdateRound - 1
                    ) {
                        onGoingAmount = onGoingAmount - _userState.pending;
                    }
                    onGoingAmount = onGoingAmount * price /
                       Utils.RATIOMULTIPLIER;
                    if (
                        _userState.pending > 0 &&
                        _userState.lastUpdateRound == lastUpdateRound - 1
                    ) {
                        onGoingAmount = onGoingAmount + _userState.pending;
                    }
                } 
                if (lastUpdateRound == _currentRound) {
                    expiredAmountCaculated = true;
                }
            }
        }

        Utils.assertUint128(pendingAmount);
        Utils.assertUint128(redeemed);
        Utils.assertUint128(expiredAmount);
        Utils.assertUint128(expiredQueuedRedeemAmount);
        Utils.assertUint128(onGoingAmount);
        Utils.assertUint128(onGoingQueuedRedeemAmount);
        StructureData.UserState memory updatedUserState =
            StructureData.UserState({
                lastUpdateRound: _currentRound,
                pending: uint128(pendingAmount),
                redeemed: uint128(redeemed),
                expiredAmount: uint128(expiredAmount),
                expiredQueuedRedeemAmount: uint128(expiredQueuedRedeemAmount),
                onGoingAmount: uint128(onGoingAmount),
                onGoingQueuedRedeemAmount: uint128(onGoingQueuedRedeemAmount),
                expiredAmountCaculated: expiredAmountCaculated
            });

        return updatedUserState;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library StructureData { 
    
 
    //information that won't change
    struct VaultDefinition { 
        uint8 assetAmountDecimals; 
        address asset;
        address underlying; 
        bool callOrPut; //call for collateral -> stablecoin; put for stablecoin->collateral;  
    } 

    struct OptionState {
        uint128 amount; //total deposits
        uint128 queuedRedeemAmount;  //deposts stop autoroll into next round
        uint128 strike;
        uint104 premiumRate;
        address buyerAddress; 
    }
 
    struct VaultState { 
        uint128 totalPending; //deposits for queued round
        uint128 totalRedeemed; //redeemded but not withdrawn yet
        uint16 currentRound; //queued round number, start from 1 for first round
        uint32 cutOffAt;  //cut off time for next round
        uint32 periodLength; //default periodLength
        uint128 maxCapacity;  //max deposits to accept  

        StructureData.OptionState onGoing; //data for current round
        StructureData.OptionState expired;  //data for previous round when new epoch is started and expiry level not specified yet
        mapping(uint16 => uint32) nextPeriodStartOverrides; //default to to next friday 8:00am utc, if missing
        mapping(uint16 => uint256) depositPriceAfterExpiryPerRound; //how much per deposit worth by ratio for each expired round
        //is expiry level overdued? since if the expiry level is not specified within a whole epoch, the option becomes of no value by default
        mapping(uint16 => bool) expiryLevelSkipped; 
        //user deposit/withdraw states
        mapping(address=>StructureData.UserState) userStates;
        //whitelisted traders
        
    }
 
    
    //similar to VaultState
    struct UserState {
        uint128 pending;
        uint128 redeemed;
        uint128 expiredAmount;
        uint128 expiredQueuedRedeemAmount;
        uint128 onGoingAmount;
        uint128 onGoingQueuedRedeemAmount;
        uint16 lastUpdateRound; //last round number when user deposit/withdraw/redeem
        bool expiredAmountCaculated; //is the expiry level specified when last updated
    }
 
    //current vault state
    struct VaultSnapShot {
        uint128 totalPending; 
        uint128 totalRedeemed;
        uint32 cutOffAt;  
        uint16 currentRound;
        uint128 maxCapacity;   
        StructureData.OptionState onGoing;
        StructureData.OptionState expired;
    
    } 

     
    struct CollectableValue {
       address asset;
       uint256 amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
 
library Utils { 
     
    uint256 public constant ROUND_PRICE_DECIMALS = 10;
    uint256 public constant RATIOMULTIPLIER = 10 ** ROUND_PRICE_DECIMALS; 
    function getAmountToTerminate(uint256 _maturedAmount, uint256 _assetToTerminate, uint256 _assetAmount) 
    internal pure returns(uint256) {
       if (_assetToTerminate == 0 || _assetAmount == 0 || _maturedAmount == 0) return 0;
       return _assetToTerminate >= _assetAmount ?  _maturedAmount  : _maturedAmount * _assetToTerminate / _assetAmount;
   }

   function withPremium(uint256 _baseAmount, uint256 _premimumRate) internal pure returns(uint256) {
       return  _baseAmount * (RATIOMULTIPLIER + _premimumRate) / RATIOMULTIPLIER;
   }
   
   function premium(uint256 _baseAmount, uint256 _premimumRate) internal pure returns(uint256) {
       return   _baseAmount * _premimumRate / RATIOMULTIPLIER;
   }
   
   function subOrZero(uint256 _base, uint256 _substractor) internal pure returns (uint256) {
       return _base >= _substractor ? _base - _substractor : 0;
   }
  
    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
 
import {StructureData} from "./libraries/StructureData.sol";
import {Utils} from "./libraries/Utils.sol";
import {OptionLifecycle} from "./libraries/OptionLifecycle.sol";  
//import "hardhat/console.sol";

contract OptionGovernor {  
    
    address public adminAddress;
    address public managerAddress; 
    bool public paused;
    
    mapping(address=>bool) private whitelist;
    mapping(uint8 => address) private traders;
    uint8 private traderCount;
    bool private locked;
    

    constructor(address _admin, address _manager) {
        adminAddress = _admin; 
        managerAddress = _manager;
    }
  
    function transferAdmin(address _newAdminAddress) external adminOnly { 
      require(_newAdminAddress != address(0), "invalid address");
      adminAddress = _newAdminAddress;
    }
    
    function transferManager(address _newManagerAddress) external adminOnly { 
      require(_newManagerAddress != address(0), "invalid address");
      managerAddress = _newManagerAddress;
    }
  
    function pause() external adminOnly {
        require(!paused, "paused"); 
        paused = true;
    }

    function resume() external adminOnly {
        require(paused, "!paused"); 
        paused = false;
    }

    modifier notPaused() {
        require(!paused, "paused"); 
        _;
    } 
  
    function addToWhitelist(address[] memory _whitelistAddresses)
        external 
        managerOnly
    {
        uint8 traderCount_ = traderCount;
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            address trader = _whitelistAddresses[i];
            if (!whitelist[trader]) {
                whitelist[trader] = true;
                bool existingTrader = false;
                for (uint8 j = 0; j < traderCount_; j++) {
                    if (traders[j] == trader) {
                        existingTrader = true;
                        break;
                    }
                }
                if (!existingTrader) {
                    traders[traderCount_++] = trader;
                }
            }
        }
        traderCount = traderCount_;
    }

    function removeFromWhitelist(address[] memory _delistAddresses)
        external managerOnly
    {
        for (uint256 i = 0; i < _delistAddresses.length; i++) {
            whitelist[_delistAddresses[i]] = false;
        }
    }

    function whitelistTraders()
        external
        view 
        returns (address[] memory)
    {
        if (traderCount == 0) {
            return new address[](0);
        }
        uint256 count = 0;
        for (uint8 i = 0; i < traderCount; i++) {
            if (whitelist[traders[i]]) {
                count++;
            }
        }
        address[] memory whitelistData = new address[](count);
        count = 0;
        for (uint8 i = 0; i < traderCount; i++) {
            if (whitelist[traders[i]]) {
                whitelistData[count++] = traders[i];
            }
        }
        return whitelistData;
    }


    modifier whitelisted() {
        require(whitelist[msg.sender], "!whitelisted");
        _;
    }

    modifier managerOnly() {
        require(managerAddress == msg.sender, "!manager");
        _;
    }

    modifier adminOnly() {
        
        require(adminAddress == msg.sender, "!admin");
        _;
    }

    modifier lock() {
        require(!locked, "locked");
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
//import "hardhat/console.sol";

import {StructureData} from "./libraries/StructureData.sol";
import {Utils} from "./libraries/Utils.sol";
import {OptionLifecycle} from "./libraries/OptionLifecycle.sol";
import "./OptionGovernor.sol";
import "./OptionVaultEvents.sol";

abstract contract OptionVault is OptionGovernor, OptionVaultEvents {
    using SafeERC20 for IERC20; 
    using Utils for uint256; 
    uint32 public vaultId;
    StructureData.VaultDefinition public definition;
    StructureData.VaultState public state;
    mapping(address => uint256) public optionHolderValues;

    constructor(
        address _admin,
        address _manager,
        uint32 _vaultId,
        StructureData.VaultDefinition memory _definition
    ) OptionGovernor(_admin, _manager) {
        definition = _definition;
        vaultId = _vaultId;
    }

    //only needed for the initial kick off
    function kickOffOption(
        uint128 _maxCapacity,
        uint32 _nextPeriodStart,
        uint32 _periodLength
    ) external managerOnly notPaused {
        require(state.currentRound == 0, "already kicked off");
        require(_maxCapacity > 0, "zero maxCapacity");
        require(_nextPeriodStart > block.timestamp, "Invalid nextPeriodStart");
        state.maxCapacity = _maxCapacity;
        state.cutOffAt = _nextPeriodStart;
        state.periodLength = _periodLength;
        state.nextPeriodStartOverrides[1] = _nextPeriodStart;
        state.currentRound = 1;
    }

    function setCapacity(uint128 _maxCapacity) external managerOnly notPaused {
        uint256 currentTVL =
            uint256(state.totalPending)
                + state.onGoing.amount
                + state.expired.amount
                - state.expired.queuedRedeemAmount;
        require(currentTVL <= _maxCapacity, "Max Cap less than tvl");
        state.maxCapacity = _maxCapacity;
    }

    function setNextPeriodStart(uint32 _nextPeriodStart)
        external
        managerOnly
        notPaused
    {
        require(_nextPeriodStart > block.timestamp, "Invalid nextPeriodStart");
        OptionLifecycle.rollToNextRoundIfNeeded(state);
        state.cutOffAt = _nextPeriodStart;
        state.nextPeriodStartOverrides[state.currentRound] = _nextPeriodStart;
    }

    //parameters for option to sell
    function sellOption(
        uint128 _strike, // strike price
        uint104 _premiumRate //take, 0.01% is represented as 1, precision is 4
    ) external managerOnly notPaused {
        require(_premiumRate > 0, "!premium");
        require(_strike > 0, "!strike");
        OptionLifecycle.rollToNextRoundIfNeeded(state);
        require(state.currentRound > 1, "No selling round");
        require(
            state.expired.buyerAddress == address(0) ||
                state.expired.amount == 0,
            "Expiry level not specified yet"
        );
        StructureData.OptionState storage onGoing = state.onGoing;
        require(onGoing.buyerAddress == address(0), "Already sold");
        onGoing.strike = _strike;
        onGoing.premiumRate = _premiumRate; 
    }

    //after buying by sending back the premium, the premium and strike can no longer be changed
    function buyOption() external payable whitelisted notPaused lock {
        OptionLifecycle.rollToNextRoundIfNeeded(state);
        StructureData.OptionState storage onGoing = state.onGoing;
        require(onGoing.buyerAddress == address(0), "Already sold"); 
        require(
            onGoing.strike > 0 && onGoing.premiumRate > 0,
            "strike or premium missing"
        );
        uint256 total =
            uint256(onGoing.amount) + state.expired.amount - 
                state.expired.queuedRedeemAmount;
        require(total > 0, "Nothing to sell");

        Utils.assertUint128(total);
        uint256 premium = total.premium(onGoing.premiumRate);

        emit OptionBought(
            state.currentRound - 1,
            msg.sender,
            total,
            onGoing.strike,
            onGoing.premiumRate
        );

        if (
            definition.asset ==
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            require(premium >= msg.value, "Not enough eth");
            //transfer back extra
            if (premium > msg.value) {
                payable(msg.sender).transfer(premium - msg.value);
            }
        } else {
            IERC20(definition.asset).safeTransferFrom(
                msg.sender,
                address(this),
                premium
            );
        }
        onGoing.amount = uint128(total);
        if (state.expired.amount > 0) {
            state.depositPriceAfterExpiryPerRound[
                uint16(state.currentRound - 2)
            ] = Utils.RATIOMULTIPLIER;
            if (state.expired.queuedRedeemAmount > 0) {
                uint256 totalRedeemed =
                    uint256(state.expired.queuedRedeemAmount) + 
                        state.totalRedeemed;
                Utils.assertUint128(totalRedeemed);
                state.totalRedeemed = uint128(totalRedeemed);
            }
            state.expired.amount = 0;
            state.expired.queuedRedeemAmount = 0;
        }
        onGoing.buyerAddress = msg.sender;
    }

    function expireOption(uint128 _expiryLevel) external managerOnly notPaused {
        require(_expiryLevel > 0, "!expiryLevel");
        OptionLifecycle.rollToNextRoundIfNeeded(state);
        require(state.currentRound > 2, "No expired round");
        StructureData.OptionState storage expired = state.expired;
        if (expired.amount == 0 || expired.buyerAddress == address(0)) {
            return;
        }

        require(expired.strike > 0, "!strike");
        uint256 diff =
            definition.callOrPut
                ? (
                    _expiryLevel > expired.strike
                        ? _expiryLevel - expired.strike
                        : 0
                )
                : (
                    expired.strike > _expiryLevel
                        ? expired.strike - _expiryLevel
                        : 0
                );

        //extra value available for trader
        uint256 optionHolderValue =
            diff * expired.amount / (
                definition.callOrPut ? _expiryLevel : expired.strike
            ); 
        uint256 remaining =
            uint256(expired.amount).withPremium(expired.premiumRate) -
                optionHolderValue;
        optionHolderValue = optionHolderValue + 
            optionHolderValues[expired.buyerAddress];
        Utils.assertUint128(optionHolderValue);
        optionHolderValues[expired.buyerAddress] = uint128(optionHolderValue);

        emit OptionExpired(
            state.currentRound - 2,
            _expiryLevel,
            uint128(optionHolderValue)
        );


        uint256 depositPriceAfterExpiry =
            remaining * Utils.RATIOMULTIPLIER / expired.amount;
        state.depositPriceAfterExpiryPerRound[
            state.currentRound - 2
        ] = depositPriceAfterExpiry;

        uint256 redeemed =
            remaining * expired.queuedRedeemAmount / expired.amount;
        uint256 totalRedeemed = redeemed + state.totalRedeemed;
        Utils.assertUint128(totalRedeemed);
        state.totalRedeemed = uint128(totalRedeemed);
        uint256 totalOnGoing =
            remaining - redeemed + state.onGoing.amount;
        Utils.assertUint128(totalOnGoing); 
        state.onGoing.amount = uint128(totalOnGoing);
        expired.amount = 0;
        expired.queuedRedeemAmount = 0;
    }

    function collectOptionHolderValue() external lock notPaused {
        uint256 assetAmount = optionHolderValues[msg.sender];
        if (assetAmount > 0) {
            optionHolderValues[msg.sender] = 0;
            OptionLifecycle.withdraw(msg.sender, assetAmount, definition.asset);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;  

abstract contract OptionVaultEvents {
   
    event OptionBought(uint16 indexed _currentRound, address indexed _buyerAddress, uint256 _amount, uint128 _strike, uint104 _premiumRate); 
    event OptionExpired(uint16 indexed _currentRound, uint128 _expiryLevel, uint256 _optionHolderValue);

    event Deposit(address indexed _account, uint256 _amount, uint16 _round);
    event InitiateWithdraw(address indexed _account, uint256 _redeemAmount, uint16 _round);
    event CancelWithdraw(address indexed _account, uint256 _redeemAmount, uint16 _round);
    event Withdraw(address indexed _account, uint256 _amount, uint16 _round); 
 
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {StructureData} from "./libraries/StructureData.sol";
import {Utils} from "./libraries/Utils.sol";
import {OptionLifecycle} from "./libraries/OptionLifecycle.sol";
import "./OptionVault.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol"; 
//import "hardhat/console.sol";
import "./OptionVaultEvents.sol";

contract SingleDirectionOption is OptionVault {
    using SafeERC20 for IERC20; 
    using Utils for uint256;
    address creator;

    constructor(
        address _creator,
        address _admin,
        address _manager,
        uint32 _vaultId,
        StructureData.VaultDefinition memory _definition
    ) OptionVault(_admin, _manager, _vaultId, _definition) {
        creator = _creator;
    }

    function destroy(address payable _to) external {
        require(msg.sender == creator, "!creator");
        selfdestruct(_to);
    }

    function initiateWithraw(uint256 _redeemAmount) external notPaused {
        OptionLifecycle.initiateWithrawStorage(
            state,
            msg.sender,
            _redeemAmount
        );

        emit InitiateWithdraw(msg.sender, _redeemAmount, state.currentRound);
    }

    function cancelWithdraw(uint256 _redeemAmount) external notPaused {
        OptionLifecycle.cancelWithrawStorage(state, msg.sender, _redeemAmount);

        emit CancelWithdraw(msg.sender, _redeemAmount, state.currentRound);
    }

    //withdraw pending and expired amount
    function withdraw(uint256 _amount) external lock notPaused {
        OptionLifecycle.withdrawStorage(state, msg.sender, _amount);
        OptionLifecycle.withdraw(msg.sender, _amount, definition.asset);

        emit Withdraw(msg.sender, _amount, state.currentRound);
    }

    //deposit eth
    function depositETH() external payable lock notPaused {
        require(msg.value > 0, "!value");
        require(
            definition.asset ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            "!ETH"
        );
        require(state.cutOffAt > 0, "!started");
        //todo: check for cap
        OptionLifecycle.depositFor(state, msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value, state.currentRound);
    }

    //deposit other erc20 coin, take wbtc
    function deposit(uint256 _amount) external lock notPaused {
        require(_amount > 0, "!amount");
        require(
            definition.asset !=
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            "ETH"
        );
        require(state.cutOffAt > 0, "!started");

        IERC20(definition.asset).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        OptionLifecycle.depositFor(state, msg.sender, _amount);
        emit Deposit(msg.sender, _amount, state.currentRound);
    }

    function getUserState()
        external
        view
        returns (StructureData.UserState memory)
    {
        (, uint16 currentRound) = OptionLifecycle.getRealRound(state);
        StructureData.UserState storage userState = state.userStates[
            msg.sender
        ];
        return OptionLifecycle.recalcState(state, userState, currentRound);
    }

    function getVaultState()
        external
        view
        returns (StructureData.VaultSnapShot memory)
    {
        return OptionLifecycle.recalcVault(state);
    }
}