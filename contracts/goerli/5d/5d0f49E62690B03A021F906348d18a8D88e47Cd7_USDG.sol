// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { YieldToken } from "./YieldToken.sol";

interface IUSDG {
    function addVault(address _vault) external;
    function removeVault(address _vault) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

contract USDG is YieldToken, IUSDG {

    mapping (address => bool) public vaults;

    modifier onlyVault() {
        require(vaults[msg.sender], "USDG: forbidden");
        _;
    }

    constructor(address _vault) YieldToken("USD Gambit", "USDG", 0) {
        vaults[_vault] = true;
    }

    function addVault(address _vault) external override onlyGov {
        vaults[_vault] = true;
    }

    function removeVault(address _vault) external override onlyGov {
        vaults[_vault] = false;
    }

    function mint(address _account, uint256 _amount) external override onlyVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyVault {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Context } from "../utils/Context.sol";

error AllowanceBelowZero(uint256 currentAllowance, uint256 subtractedValue);
error InsufficientAllowance(uint256 currentAllowance, uint256 amount);
error InvalidAddress(address usedAddress, string message);
error AmountExceedsBalance(address usedAddress, uint256 balance, uint256 amount);

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
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/// @title ERC20AltApprove interface.
/// @notice Interface for an alternative to {approve} that can be used as a mitigation for problems described in {IERC20-approve}.
/// @dev This is not part of the ERC20 specification.
interface IERC20AltApprove
{
	/**
	* @notice Atomically decreases the allowance granted to `spender` by the caller.
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
	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

	/**
	* @notice Atomically increases the allowance granted to `spender` by the caller.
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
	function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

/// @title ERC20Metadata interface.
/// @notice Interface for the optional metadata functions from the ERC20 standard.
interface IERC20Metadata is IERC20
{
	/// @notice Returns the name of the token.
	/// @return The token name.
	function name() external view returns (string memory);

	/// @notice Returns the symbol of the token.
	/// @return The symbol for the token.
	function symbol() external view returns (string memory);

	/// @notice Returns the decimals of the token.
	/// @return The decimals for the token.
	function decimals() external pure returns (uint8);
}

/**
* @notice Implementation of the {IERC20Metadata} interface.
* The IERC20Metadata interface extends the IERC20 interface.
*
* This implementation is agnostic to the way tokens are created. This means
* that a supply mechanism has to be added in a derived contract using {_mint}.
* For a generic mechanism see Open Zeppelins {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20AltApprove, IERC20Metadata
{
	uint256 internal _totalSupply;
	mapping(address => uint256) internal _balances;
	mapping(address => mapping(address => uint256)) internal _allowances;
	string internal _name;
	string internal _symbol;

	/**
	* @notice Sets the values for {name} and {symbol}.
	*
	* The default value of {decimals} is 18. To select a different value for
	* {decimals} you should overload it.
	*
	* All two of these values are immutable: they can only be set once during
	* construction.
	*/
	constructor(string memory tokenName, string memory tokenSymbol)
	{
		_name = tokenName;
		_symbol = tokenSymbol;
	}

	/**
	* @notice See {IERC20-approve}.
	*
	* NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
	* `transferFrom`. This is semantically equivalent to an infinite approval.
	*
	* Requirements:
	*
	* - `spender` cannot be the zero address.
	*/
	function approve(address spender, uint256 amount) override external virtual returns (bool)
	{
		address owner = _msgSender();
		_approve(owner, spender, amount);
		return true;
	}

	/**
	* @notice Atomically decreases the allowance granted to `spender` by the caller.
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
	function decreaseAllowance(address spender, uint256 subtractedValue) override external virtual returns (bool)
	{
		address owner = _msgSender();
		uint256 currentAllowance = _allowances[owner][spender];
		if(currentAllowance < subtractedValue) revert AllowanceBelowZero(currentAllowance, subtractedValue);
		unchecked {
			_approve(owner, spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	/**
	* @notice Atomically increases the allowance granted to `spender` by the caller.
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
	function increaseAllowance(address spender, uint256 addedValue) override external virtual returns (bool)
	{
		address owner = _msgSender();
		_approve(owner, spender, _allowances[owner][spender] + addedValue);
		return true;
	}

	/**
	* @notice See {IERC20-transfer}.
	*
	* Requirements:
	*
	* - `to` cannot be the zero address.
	* - the caller must have a balance of at least `amount`.
	*/
	function transfer(address to, uint256 amount) override external virtual returns (bool)
	{
		address owner = _msgSender();
		_transfer(owner, to, amount);
		return true;
	}

	/**
	* @notice See {IERC20-transferFrom}.
	*
	* Emits an {Approval} event indicating the updated allowance. This is not
	* required by the EIP. See the note at the beginning of {ERC20}.
	*
	* NOTE: Does not update the allowance if the current allowance is the maximum `uint256`.
	*
	* Requirements:
	*
	* - `from` and `to` cannot be the zero address.
	* - `from` must have a balance of at least `amount`.
	* - the caller must have allowance for ``from``'s tokens of at least
	* `amount`.
	*/
	function transferFrom(address from, address to, uint256 amount) override external virtual returns (bool)
	{
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}

	/**
	* @notice See {IERC20-allowance}.
	*/
	function allowance(address owner, address spender) override external view virtual returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	* @notice See {IERC20-balanceOf}.
	*/
	function balanceOf(address account) override external view virtual returns (uint256)
	{
		return _balances[account];
	}

	/**
	* @notice Returns the name of the token.
	*/
	function name() override external view virtual returns (string memory)
	{
		return _name;
	}

	/**
	* @notice Returns the symbol of the token, usually a shorter version of the
	* name.
	*/
	function symbol() override external view virtual returns (string memory)
	{
		return _symbol;
	}

	/**
	* @notice See {IERC20-totalSupply}.
	*/
	function totalSupply() override external view virtual returns (uint256)
	{
		return _totalSupply;
	}

	/**
	* @notice Returns the number of decimals used to get its user representation.
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
	function decimals() override external pure virtual returns (uint8)
	{
		return 18;
	}

	/**
	* @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
	function _approve(address owner, address spender, uint256 amount) internal virtual
	{
		if(owner == address(0)) revert InvalidAddress(owner, "Can not approve from zero address.");
		if(spender == address(0)) revert InvalidAddress(spender, "Can not approve to zero address.");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	* @notice Destroys `amount` tokens from `account`, reducing the
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
		if(account == address(0)) revert InvalidAddress(account, "Can not burn from zero address.");

		uint256 accountBalance = _balances[account];
		if(accountBalance < amount) revert AmountExceedsBalance(account, accountBalance, amount);
		unchecked {
			_balances[account] = accountBalance - amount;
		}
		_totalSupply -= amount;

		emit Transfer(account, address(0), amount);
	}

	/** @notice Creates `amount` tokens and assigns them to `account`, increasing
	* the total supply.
	*
	* Emits a {Transfer} event with `from` set to the zero address.
	*
	* Requirements:
	*
	* - `account` cannot be the zero address.
	*/
	function _mint(address account, uint256 amount) internal virtual
	{
		if(account == address(0)) revert InvalidAddress(account, "Can not mint to zero address.");

		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);
	}

	/**
	* @notice Updates `owner` s allowance for `spender` based on spent `amount`.
	*
	* Does not update the allowance amount in case of infinite allowance.
	* Revert if not enough allowance is available.
	*
	* Might emit an {Approval} event.
	*/
	function _spendAllowance(address owner, address spender, uint256 amount) internal virtual
	{
		uint256 currentAllowance = _allowances[owner][spender];
		if (currentAllowance != type(uint256).max)
		{
			if(currentAllowance < amount) revert InsufficientAllowance(currentAllowance, amount);
			unchecked {
				_approve(owner, spender, currentAllowance - amount);
			}
		}
	}

	/**
	* @notice Moves `amount` of tokens from `sender` to `recipient`.
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
	function _transfer(address from, address to, uint256 amount) internal virtual
	{
		if(from == address(0)) revert InvalidAddress(from, "Can not transfer from zero address.");
		if(to == address(0)) revert InvalidAddress(to, "Can not transfer to zero address.");

		uint256 fromBalance = _balances[from];
		if(fromBalance < amount) revert AmountExceedsBalance(from, fromBalance, amount);
		unchecked {
			_balances[from] = fromBalance - amount;
		}
		_balances[to] += amount;

		emit Transfer(from, to, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "./ERC20.sol";
import { Address } from "../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity ^0.8.20;

/**
* @notice Provides information about the current execution context, including the
* sender of the transaction and its data. While these are generally available
* via msg.sender and msg.data, they should not be accessed in such a direct
* manner, since when dealing with meta-transactions the account sending and
* paying for execution may not be the actual sender (as far as an application
* is concerned).
*
* This contract is only required for intermediate, library-like contracts.
*/
abstract contract Context
{
	/// @notice returns the sender of the transaction.
	/// @return The sender of the transaction.
	function _msgSender() internal view virtual returns (address)
	{
		return msg.sender;
	}

	/// @notice returns the data of the transaction.
	/// @return The data of the transaction.
	function _msgData() internal view virtual returns (bytes calldata)
	{
		return msg.data;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error ReentrantCall();

/**
 * @title Reentrancy guard
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can be applied to functions to make sure there are no
 * nested (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may not call one another. This can be worked around
 * by making those functions `private`, and then adding `external` `nonReentrant` entry points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways to protect against it, check out the blog post
 * [Reentrancy After Istanbul](https://blog.openzeppelin.com/reentrancy-after-istanbul/).
 */
abstract contract ReentrancyGuard {
	// Booleans are more expensive than uint256 or any type that takes up a full word because each write operation emits an extra SLOAD to first
	// read the slot's contents, replace the bits taken up by the boolean, and then write back. This is the compiler's defense against contract
	// upgrades and pointer aliasing, and it cannot be disabled.

	// The values being non-zero value makes deployment a bit more expensive, but in exchange the refund on every call to nonReentrant will be lower
	// in amount. Since refunds are capped to a percentage of the total transaction's gas, it is best to keep them low in cases like this one, to
	// increase the likelihood of the full refund coming into effect.
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;
	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}

	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly. Calling a `nonReentrant` function from another `nonReentrant`
	 * function is not supported. It is possible to prevent this from happening by making the `nonReentrant` function external, and make it call a
	 * `private` function that does the actual work.
	 */
	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		if(_status == _ENTERED) revert ReentrantCall();

		// Any calls to nonReentrant after this point will fail
		_status = _ENTERED;

		_;

		// By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}
}
// 26947/26935

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "../libraries/token/ERC20.sol";
import { SafeERC20 } from "../libraries/token/SafeERC20.sol";


interface IDistributor {
    function distribute() external returns (uint256);
    function getRewardToken(address _receiver) external view returns (address);
    function getDistributionAmount(address _receiver) external view returns (uint256);
    function tokensPerInterval(address _receiver) external view returns (uint256);
}

contract TimeDistributor is IDistributor {
    using SafeERC20 for IERC20;

    uint256 public constant DISTRIBUTION_INTERVAL = 1 hours;
    address public gov;
    address public admin;

    mapping (address => address) public rewardTokens;
    mapping (address => uint256) public override tokensPerInterval;
    mapping (address => uint256) public lastDistributionTime;

    event Distribute(address receiver, uint256 amount);
    event DistributionChange(address receiver, uint256 amount, address rewardToken);
    event TokensPerIntervalChange(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "TimeDistributor: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "TimeDistributor: forbidden");
        _;
    }

    constructor() {
        gov = msg.sender;
        admin = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setTokensPerInterval(address _receiver, uint256 _amount) external onlyAdmin {
        if (lastDistributionTime[_receiver] != 0) {
            uint256 intervals = getIntervals(_receiver);
            require(intervals == 0, "TimeDistributor: pending distribution");
        }

        tokensPerInterval[_receiver] = _amount;
        _updateLastDistributionTime(_receiver);
        emit TokensPerIntervalChange(_receiver, _amount);
    }

    function updateLastDistributionTime(address _receiver) external onlyAdmin {
        _updateLastDistributionTime(_receiver);
    }

    function setDistribution(
        address[] calldata _receivers,
        uint256[] calldata _amounts,
        address[] calldata _rewardTokens
    ) external onlyGov {
        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];

            if (lastDistributionTime[receiver] != 0) {
                uint256 intervals = getIntervals(receiver);
                require(intervals == 0, "TimeDistributor: pending distribution");
            }

            uint256 amount = _amounts[i];
            address rewardToken = _rewardTokens[i];
            tokensPerInterval[receiver] = amount;
            rewardTokens[receiver] = rewardToken;
            _updateLastDistributionTime(receiver);
            emit DistributionChange(receiver, amount, rewardToken);
        }
    }

    function distribute() external override returns (uint256) {
        address receiver = msg.sender;
        uint256 intervals = getIntervals(receiver);

        if (intervals == 0) { return 0; }

        uint256 amount = getDistributionAmount(receiver);
        _updateLastDistributionTime(receiver);

        if (amount == 0) { return 0; }

        IERC20(rewardTokens[receiver]).safeTransfer(receiver, amount);

        emit Distribute(receiver, amount);
        return amount;
    }

    function getRewardToken(address _receiver) external override view returns (address) {
        return rewardTokens[_receiver];
    }

    function getDistributionAmount(address _receiver) public override view returns (uint256) {
        uint256 _tokensPerInterval = tokensPerInterval[_receiver];
        if (_tokensPerInterval == 0) { return 0; }

        uint256 intervals = getIntervals(_receiver);
        uint256 amount = _tokensPerInterval * intervals;

        if (IERC20(rewardTokens[_receiver]).balanceOf(address(this)) < amount) { return 0; }

        return amount;
    }

    function getIntervals(address _receiver) public view returns (uint256) {
        uint256 timeDiff = block.timestamp - lastDistributionTime[_receiver];
        return timeDiff / DISTRIBUTION_INTERVAL;
    }

    function _updateLastDistributionTime(address _receiver) private {
        lastDistributionTime[_receiver] = (block.timestamp / DISTRIBUTION_INTERVAL) * DISTRIBUTION_INTERVAL;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "../libraries/token/ERC20.sol";
import { SafeERC20 } from "../libraries/token/SafeERC20.sol";
import { IYieldTracker } from "./YieldTracker.sol";

interface IYieldToken {
    function totalStaked() external view returns (uint256);
    function stakedBalance(address _account) external view returns (uint256);
    function removeAdmin(address _account) external;
}

contract YieldToken is IERC20, IYieldToken {
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;
    uint256 public nonStakingSupply;

    address public gov;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    address[] public yieldTrackers;
    mapping (address => bool) public nonStakingAccounts;
    mapping (address => bool) public admins;

    bool public inWhitelistMode;
    mapping (address => bool) public whitelistedHandlers;

    modifier onlyGov() {
        require(msg.sender == gov, "YieldToken: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "YieldToken: forbidden");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        gov = msg.sender;
        admins[msg.sender] = true;
        _mint(msg.sender, _initialSupply);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setInfo(string memory _name, string memory _symbol) external onlyGov {
        name = _name;
        symbol = _symbol;
    }

    function setYieldTrackers(address[] memory _yieldTrackers) external onlyGov {
        yieldTrackers = _yieldTrackers;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external override onlyGov {
        admins[_account] = false;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function setInWhitelistMode(bool _inWhitelistMode) external onlyGov {
        inWhitelistMode = _inWhitelistMode;
    }

    function setWhitelistedHandler(address _handler, bool _isWhitelisted) external onlyGov {
        whitelistedHandlers[_handler] = _isWhitelisted;
    }

    function addNonStakingAccount(address _account) external onlyAdmin {
        require(!nonStakingAccounts[_account], "YieldToken: _account already marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = true;
        nonStakingSupply = nonStakingSupply + balances[_account];
    }

    function removeNonStakingAccount(address _account) external onlyAdmin {
        require(nonStakingAccounts[_account], "YieldToken: _account not marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = false;
        nonStakingSupply = nonStakingSupply - balances[_account];
    }

    function recoverClaim(address _account, address _receiver) external onlyAdmin {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(_account, _receiver);
        }
    }

    function claim(address _receiver) external {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(msg.sender, _receiver);
        }
    }

    function totalStaked() external view override returns (uint256) {
        return totalSupply - nonStakingSupply;
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function stakedBalance(address _account) external view override returns (uint256) {
        if (nonStakingAccounts[_account]) {
            return 0;
        }
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender] - _amount;
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "YieldToken: mint to the zero address");

        _updateRewards(_account);

        totalSupply = totalSupply + (_amount);
        balances[_account] = balances[_account] + (_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply + (_amount);
        }

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "YieldToken: burn from the zero address");

        _updateRewards(_account);

        balances[_account] = balances[_account] - (_amount);
        totalSupply = totalSupply-(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply-(_amount);
        }

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "YieldToken: transfer from the zero address");
        require(_recipient != address(0), "YieldToken: transfer to the zero address");

        if (inWhitelistMode) {
            require(whitelistedHandlers[msg.sender], "YieldToken: msg.sender not whitelisted");
        }

        _updateRewards(_sender);
        _updateRewards(_recipient);

        balances[_sender] = balances[_sender]-(_amount);
        balances[_recipient] = balances[_recipient]+(_amount);

        if (nonStakingAccounts[_sender]) {
            nonStakingSupply = nonStakingSupply-(_amount);
        }
        if (nonStakingAccounts[_recipient]) {
            nonStakingSupply = nonStakingSupply+(_amount);
        }

        emit Transfer(_sender, _recipient,_amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "YieldToken: approve from the zero address");
        require(_spender != address(0), "YieldToken: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _updateRewards(address _account) private {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).updateRewards(_account);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "../libraries/token/ERC20.sol";
import { SafeERC20 } from "../libraries/token/SafeERC20.sol";
import { ReentrancyGuard } from "../libraries/utils/ReentrancyGuard.sol";
import { IDistributor } from "./Distributor.sol";
import { IYieldToken } from "./YieldToken.sol";

interface IYieldTracker {
    function claim(address _account, address _receiver) external returns (uint256);
    function updateRewards(address _account) external;
    function getTokensPerInterval() external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
}

// code adapated from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/TrueFarm.sol
contract YieldTracker is IYieldTracker, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 1e30;

    address public gov;
    address public yieldToken;
    address public distributor;

    uint256 public cumulativeRewardPerToken;
    mapping (address => uint256) public claimableReward;
    mapping (address => uint256) public previousCumulatedRewardPerToken;

    event Claim(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "YieldTracker: forbidden");
        _;
    }

    constructor(address _yieldToken) {
        gov = msg.sender;
        yieldToken = _yieldToken;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setDistributor(address _distributor) external onlyGov {
        distributor = _distributor;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function claim(address _account, address _receiver) external override returns (uint256) {
        require(msg.sender == yieldToken, "YieldTracker: forbidden");
        updateRewards(_account);

        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        address rewardToken = IDistributor(distributor).getRewardToken(address(this));
        IERC20(rewardToken).safeTransfer(_receiver, tokenAmount);
        emit Claim(_account, tokenAmount);

        return tokenAmount;
    }

    function getTokensPerInterval() external override view returns (uint256) {
        return IDistributor(distributor).tokensPerInterval(address(this));
    }

    function claimable(address _account) external override view returns (uint256) {
        uint256 stakedBalance = IYieldToken(yieldToken).stakedBalance(_account);
        if (stakedBalance == 0) {
            return claimableReward[_account];
        }
        uint256 pendingRewards = IDistributor(distributor).getDistributionAmount(address(this)) * PRECISION;
        uint256 totalStaked = IYieldToken(yieldToken).totalStaked();
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken + (pendingRewards / totalStaked);
        return claimableReward[_account] + (stakedBalance * (nextCumulativeRewardPerToken - previousCumulatedRewardPerToken[_account]) / PRECISION);
    }

    function updateRewards(address _account) public override nonReentrant {
        uint256 blockReward;

        if (distributor != address(0)) {
            blockReward = IDistributor(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        uint256 totalStaked = IYieldToken(yieldToken).totalStaked();
        // only update cumulativeRewardPerToken when there are stakers, i.e. when totalStaked > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (totalStaked > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken + ((blockReward * PRECISION) / totalStaked);
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 stakedBalance = IYieldToken(yieldToken).stakedBalance(_account);
            uint256 _previousCumulatedReward = previousCumulatedRewardPerToken[_account];
            uint256 _claimableReward = claimableReward[_account] + ((stakedBalance * (_cumulativeRewardPerToken - _previousCumulatedReward)) / PRECISION);

            claimableReward[_account] = _claimableReward;
            previousCumulatedRewardPerToken[_account] = _cumulativeRewardPerToken;
        }
    }
}