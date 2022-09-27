// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/access/IOwnable.sol";
import "../utils/Context.sol";

/**
 * @title Ownable contract module.
 * @author Ing. Michael Goldfinger
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an address (an owner) that can be granted exclusive access to specific functions.
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with the function {transferOwnership(address newOwner)}".
 * @dev This module is used through inheritance. It will make available the modifier
 * {onlyOwner}, which can be applied to your functions to restrict their use to the owner.
 */
contract Ownable is IOwnable, Context
{
	address private _owner;

	/**
	* @notice Throws if called by any account other than the owner.
	*/
	modifier onlyOwner()
	{
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	/**
	* @notice Initializes the contract setting the deployer as the initial owner.
	* 
	* Emits an {OwnershipTransferred} event indicating the initially set ownership.
	*/
	constructor()
	{
		_transferOwnership(_msgSender());
	}

	/// @inheritdoc IOwnable
	function renounceOwnership() override public virtual onlyOwner 
	{
		_transferOwnership(address(0));
	}

	/// @inheritdoc IOwnable
	function transferOwnership(address newOwner) override public virtual onlyOwner
	{
		require(newOwner != address(0), "Ownable: new owner is address(0)");
		_transferOwnership(newOwner);
	}

	/// @inheritdoc IOwnable
	function owner() public view virtual override returns (address)
	{
		return _owner;
	}

	/**
	* @notice Transfers ownership of the contract to a new address.
	* Internal function without access restriction.
	* 
	* Emits an {OwnershipTransferred} event indicating the transfered ownership.
	*/
	function _transferOwnership(address newOwner) internal virtual
	{
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ownable interface.
/// @author Ing. Michael Goldfinger
/// @notice This interface contains all visible functions and events for the Ownable contract module.
interface IOwnable
{
	/// @notice Emitted when ownership is moved from one address to another.
	/// @param previousOwner (indexed) The owner of the contract until now.
	/// @param newOwner (indexed) The new owner of the contract.
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @notice Leaves the contract without an owner. It will not be possible to call {onlyOwner} functions anymore.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an owner,
	 * thereby removing any functionality that is only available to the owner.
	 *
	 * Emits an [`OwnershipTransferred`](#ownershiptransferred) event indicating the renounced ownership.
	 *
	 * Requirements:
	 * - Can only be called by the current owner.
	 * 
	 * @dev Sets the zero address as the new contract owner.
	 */
	function renounceOwnership() external;

	/**
	 * @notice Transfers ownership of the contract to a new address.
	 *
	 * Emits an [`OwnershipTransferred`](#ownershiptransferred) event indicating the transfered ownership.
	 *
	 * Requirements:
	 * - Can only be called by the current owner.
	 *
	 * @param newOwner The new owner of the contract.
	 */
	function transferOwnership(address newOwner) external;

	/// @notice Returns the current owner.
	/// @return The current owner.
	function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface.
 * @author Ing. Michael Goldfinger
 * @notice Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20
{
	/**
	 * @notice Emitted when the allowance of a {spender} for an {owner} is set to a new value.
	 *
	 * NOTE: {value} may be zero.
	 * @param owner (indexed) The owner of the tokens.
	 * @param spender (indexed) The spender for the tokens.
	 * @param value The amount of tokens that got an allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @notice Emitted when {value} tokens are moved from one address {from} to another {to}.
	 *
	 * NOTE: {value} may be zero.
	 * @param from (indexed) The origin of the transfer.
	 * @param to (indexed) The target of the transfer.
	 * @param value The amount of tokens that got transfered.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

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
	* @dev Moves `amount` tokens from the caller's account to `to`.
	*
	* Returns a boolean value indicating whether the operation succeeded.
	*
	* Emits a {Transfer} event.
	*/
	function transfer(address to, uint256 amount) external returns (bool);

	/**
	* @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism.
	* `amount` is then deducted from the caller's allowance.
	*
	* Returns a boolean value indicating whether the operation succeeded.
	*
	* Emits a {Transfer} event.
	*/
	function transferFrom(address from, address to, uint256 amount) external returns (bool);

	/**
	* @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}.
	* This is zero by default.
	*
	* This value changes when {approve}, {increaseAllowance}, {decreseAllowance} or {transferFrom} are called.
	*/
	function allowance(address owner, address spender) external view returns (uint256);

	/**
	* @dev Returns the amount of tokens owned by `account`.
	*/
	function balanceOf(address account) external view returns (uint256);

	/**
	* @dev Returns the amount of tokens in existence.
	*/
	function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC20Metadata interface.
/// @author Ing. Michael Goldfinger
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC20.sol";

/// @title ERC20Metadata interface.
/// @author Ing. Michael Goldfinger
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/token/ERC20/extensions/IERC20AltApprove.sol";
import "../../interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
	mapping(address => mapping(address => uint256)) private _allowances;
	string private _name;
	string private _symbol;

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
	function approve(address spender, uint256 amount) override public virtual returns (bool)
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
	function decreaseAllowance(address spender, uint256 subtractedValue) override public virtual returns (bool)
	{
		address owner = _msgSender();
		uint256 currentAllowance = allowance(owner, spender);
		require(currentAllowance >= subtractedValue, "ERC20: reduced allowance below 0");
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
	function increaseAllowance(address spender, uint256 addedValue) override public virtual returns (bool)
	{
		address owner = _msgSender();
		_approve(owner, spender, allowance(owner, spender) + addedValue);
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
	function transfer(address to, uint256 amount) override public virtual returns (bool)
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
	function transferFrom(address from, address to, uint256 amount) override public virtual returns (bool)
	{
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}

	/**
	* @notice See {IERC20-allowance}.
	*/
	function allowance(address owner, address spender) override public view virtual returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	* @notice See {IERC20-balanceOf}.
	*/
	function balanceOf(address account) override public view virtual returns (uint256)
	{
		return _balances[account];
	}

	/**
	* @notice Returns the name of the token.
	*/
	function name() override public view virtual returns (string memory)
	{
		return _name;
	}

	/**
	* @notice Returns the symbol of the token, usually a shorter version of the
	* name.
	*/
	function symbol() override public view virtual returns (string memory)
	{
		return _symbol;
	}

	/**
	* @notice See {IERC20-totalSupply}.
	*/
	function totalSupply() override public view virtual returns (uint256)
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
	function decimals() override public pure virtual returns (uint8)
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
		require(owner != address(0), "ERC20: approve from address(0)");
		require(spender != address(0), "ERC20: approve to address(0)");

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
		require(account != address(0), "ERC20: burn from address(0)");

		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn exceeds balance");
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
		require(account != address(0), "ERC20: mint to address(0)");

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
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			require(currentAllowance >= amount, "ERC20: insufficient allowance");
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
		require(from != address(0), "ERC20: transfer from address(0)");
		require(to != address(0), "ERC20: transfer to address(0)");

		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer exceeds balance");
		unchecked {
			_balances[from] = fromBalance - amount;
		}
		_balances[to] += amount;

		emit Transfer(from, to, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/token/ERC20/IERC20.sol";
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
library SafeERC20
{
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal
    {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal
    {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal
    {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: exploitable approve");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal
    {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal
    {
        unchecked
        {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: reduced allowance <0");
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0)
        {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 call failed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address
{
    /* solhint-disable max-line-length */
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
     /* solhint-enable max-line-length */
    function functionCall(address target, bytes memory data) internal returns (bytes memory)
    {
        return functionCallWithValue(target, data, 0, "Address: call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory)
    {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory)
    {
        return functionCallWithValue(target, data, value, "Address: call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory)
    {
        require(address(this).balance >= value, "Address: balance to low for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory)
    {
        if (success)
        {
            return returndata;
        } else
        {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly
                {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            else
            {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "@exoda/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IExofiswapERC20.sol";

contract ExofiswapERC20 is ERC20, IExofiswapERC20
{
	// keccak256("permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 private constant _PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	mapping(address => uint256) private _nonces;

	constructor(string memory tokenName) ERC20(tokenName, "ENERGY")
	{ } // solhint-disable-line no-empty-blocks

	// The standard ERC-20 race condition for approvals applies to permit as well.
	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) override public
	{
		// solhint-disable-next-line not-rely-on-time
		require(deadline >= block.timestamp, "Exofiswap: EXPIRED");
		bytes32 digest = keccak256(
			abi.encodePacked(
				"\x19\x01",
				DOMAIN_SEPARATOR(),
				keccak256(
					abi.encode(
						_PERMIT_TYPEHASH,
						owner,
						spender,
						value,
						_nonces[owner]++,
						deadline
					)
				)
			)
		);
		address recoveredAddress = ecrecover(digest, v, r, s);
		// Since the ecrecover precompile fails silently and just returns the zero address as signer when given malformed messages,
		// it is important to ensure owner != address(0) to avoid permit from creating an approval to spend “zombie funds”
		// belong to the zero address.
		require(recoveredAddress != address(0) && recoveredAddress == owner, "Exofiswap: INVALID_SIGNATURE");
		_approve(owner, spender, value);
	}

	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() override public view returns(bytes32)
	{
		// If the DOMAIN_SEPARATOR contains the chainId and is defined at contract deployment instead of reconstructed
		// for every signature, there is a risk of possible replay attacks between chains in the event of a future chain split
		return keccak256(
			abi.encode(
				keccak256(
					"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
				),
				keccak256(bytes(name())),
				keccak256(bytes("1")),
				block.chainid,
				address(this)
			)
		);
	}

	function nonces(address owner) override public view returns (uint256)
	{
		return _nonces[owner];
	}

	function PERMIT_TYPEHASH() override public pure returns (bytes32) //solhint-disable-line func-name-mixedcase
	{
		return _PERMIT_TYPEHASH;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "@exoda/contracts/access/Ownable.sol";
import "./interfaces/IExofiswapFactory.sol";
import "./interfaces/IExofiswapPair.sol";
import "./ExofiswapPair.sol";

contract ExofiswapFactory is IExofiswapFactory, Ownable
{
	address private _feeTo;
	IMigrator private _migrator;
	mapping(IERC20Metadata => mapping(IERC20Metadata => IExofiswapPair)) private _getPair;
	IExofiswapPair[] private _allPairs;

	constructor()
	{} // solhint-disable-line no-empty-blocks

	function createPair(IERC20Metadata tokenA, IERC20Metadata tokenB) override public returns (IExofiswapPair)
	{
		require(tokenA != tokenB, "EF: IDENTICAL_ADDRESSES");
		(IERC20Metadata token0, IERC20Metadata token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(address(token0) != address(0), "EF: ZERO_ADDRESS");
		require(address(_getPair[token0][token1]) == address(0), "EF: PAIR_EXISTS"); // single check is sufficient

		bytes32 salt = keccak256(abi.encodePacked(token0, token1));
		IExofiswapPair pair = new ExofiswapPair{salt: salt}(); // Use create2
		pair.initialize(token0, token1);

		_getPair[token0][token1] = pair;
		_getPair[token1][token0] = pair; // populate mapping in the reverse direction
		_allPairs.push(pair);
		emit PairCreated(token0, token1, pair, _allPairs.length);
		return pair;
	}

	function setFeeTo(address newFeeTo) override public onlyOwner
	{
		_feeTo = newFeeTo;
	}

	function setMigrator(IMigrator newMigrator) override public onlyOwner
	{
		_migrator = newMigrator;
	}

	function allPairs(uint256 index) override public view returns (IExofiswapPair)
	{
		return _allPairs[index];
	}

	function allPairsLength() override public view returns (uint256)
	{
		return _allPairs.length;
	}

	function feeTo() override public view returns (address)
	{
		return _feeTo;
	}

	function getPair(IERC20Metadata tokenA, IERC20Metadata tokenB) override public view returns (IExofiswapPair)
	{
		return _getPair[tokenA][tokenB];
	}

	function migrator() override public view returns (IMigrator)
	{
		return _migrator;
	}

	function pairCodeHash() override public pure returns (bytes32)
	{
		return keccak256(type(ExofiswapPair).creationCode);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IExofiswapCallee.sol";
import "./interfaces/IExofiswapFactory.sol";
import "./interfaces/IExofiswapPair.sol";
import "./interfaces/IMigrator.sol";
import "./ExofiswapERC20.sol";
import "./libraries/MathUInt32.sol";
import "./libraries/MathUInt256.sol";
import "./libraries/UQ144x112.sol";

contract ExofiswapPair is IExofiswapPair, ExofiswapERC20
{
	// using UQ144x112 for uint256;
	// using SafeERC20 for IERC20Metadata; // For some unknown reason using this needs a little more gas than using the library without it.
	struct SwapAmount // needed to reduce stack deep;
	{
		uint256 balance0;
		uint256 balance1;
		uint112 reserve0;
		uint112 reserve1;
	}

	uint256 private constant _MINIMUM_LIQUIDITY = 10**3;
	uint256 private _price0CumulativeLast;
	uint256 private _price1CumulativeLast;
	uint256 private _kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
	uint256 private _unlocked = 1;
	uint112 private _reserve0;           // uses single storage slot, accessible via getReserves
	uint112 private _reserve1;           // uses single storage slot, accessible via getReserves
	uint32  private _blockTimestampLast; // uses single storage slot, accessible via getReserves
	IExofiswapFactory private immutable _factory;
	IERC20Metadata private _token0;
	IERC20Metadata private _token1;

	modifier lock()
	{
		require(_unlocked == 1, "EP: LOCKED");
		_unlocked = 0;
		_;
		_unlocked = 1;
	}

	constructor() ExofiswapERC20("Plasma")
	{
		_factory = IExofiswapFactory(_msgSender());
	}

	// called once by the factory at time of deployment
	function initialize(IERC20Metadata token0Init, IERC20Metadata token1Init) override external
	{
		require(_msgSender() == address(_factory), "EP: FORBIDDEN");
		_token0 = token0Init;
		_token1 = token1Init;
	}

	// this low-level function should be called from a contract which performs important safety checks
	function burn(address to) override public lock returns (uint, uint)
	{
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1,) = getReserves(); // gas savings
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));
		uint256 liquidity = balanceOf(address(this));

		// Can not overflow
		bool feeOn = _mintFee(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1));
		uint256 totalSupplyValue = _totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
		uint256 amount0 = MathUInt256.unsafeDiv(liquidity * sa.balance0, totalSupplyValue); // using balances ensures pro-rata distribution
		uint256 amount1 = MathUInt256.unsafeDiv(liquidity * sa.balance1, totalSupplyValue); // using balances ensures pro-rata distribution
		require(amount0 > 0 && amount1 > 0, "EP: INSUFFICIENT_LIQUIDITY");
		_burn(address(this), liquidity);
		SafeERC20.safeTransfer(_token0, to, amount0);
		SafeERC20.safeTransfer(_token1, to, amount1);
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));

		_update(sa);

		if (feeOn)
		{
			unchecked // Can not overflow
			{
				// _reserve0 and _reserve1 are up-to-date
				// What _update(sa) does is set _reserve0 to sa.balance0 and _reserve1 to sa.balance1
				// So there is no neet to access and converte the _reserves directly,
				// instead use the known balances that are already in the correct type.
				_kLast = sa.balance0 * sa.balance1; 
			}
		}
		emit Burn(msg.sender, amount0, amount1, to);
		return (amount0, amount1);
	}

	// this low-level function should be called from a contract which performs important safety checks
	function mint(address to) override public lock returns (uint256)
	{
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1,) = getReserves(); // gas savings
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));
		uint256 amount0 = sa.balance0 - sa.reserve0;
		uint256 amount1 = sa.balance1 - sa.reserve1;

		bool feeOn = _mintFee(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1));
		uint256 totalSupplyValue = _totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
		uint256 liquidity;

		if (totalSupplyValue == 0)
		{
			IMigrator migrator = _factory.migrator();
			if (_msgSender() == address(migrator))
			{
				liquidity = migrator.desiredLiquidity();
				require(liquidity > 0 && liquidity != type(uint256).max, "EP: Liquidity Error");
			}
			else
			{
				require(address(migrator) == address(0), "EP: Migrator set");
				liquidity = MathUInt256.sqrt(amount0 * amount1) - _MINIMUM_LIQUIDITY;
				_mintMinimumLiquidity();
			}
		}
		else
		{
			//Div by uint can not overflow
			liquidity = 
				MathUInt256.min(
					MathUInt256.unsafeDiv(amount0 * totalSupplyValue, sa.reserve0),
					MathUInt256.unsafeDiv(amount1 * totalSupplyValue, sa.reserve1)
				);
		}
		require(liquidity > 0, "EP: INSUFFICIENT_LIQUIDITY");
		_mint(to, liquidity);

		_update(sa);
		if (feeOn)
		{
			// _reserve0 and _reserve1 are up-to-date
			// What _update(sa) does is set _reserve0 to sa.balance0 and _reserve1 to sa.balance1
			// So there is no neet to access and converte the _reserves directly,
			// instead use the known balances that are already in the correct type.
			_kLast = sa.balance0 * sa.balance1; 
		}
		emit Mint(_msgSender(), amount0, amount1);
		return liquidity;
	}

	// force balances to match reserves
	function skim(address to) override public lock
	{
		SafeERC20.safeTransfer(_token0, to, _token0.balanceOf(address(this)) - _reserve0);
		SafeERC20.safeTransfer(_token1, to, _token1.balanceOf(address(this)) - _reserve1);
	}

	// this low-level function should be called from a contract which performs important safety checks
	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) override public lock
	{
		require(amount0Out > 0 || amount1Out > 0, "EP: INSUFFICIENT_OUTPUT_AMOUNT");
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1, ) = getReserves(); // gas savings
		require(amount0Out < sa.reserve0, "EP: INSUFFICIENT_LIQUIDITY");
		require(amount1Out < sa.reserve1, "EP: INSUFFICIENT_LIQUIDITY");

		(sa.balance0, sa.balance1) = _transferTokens(to, amount0Out, amount1Out, data);

		(uint256 amount0In, uint256 amount1In) = _getInAmounts(amount0Out, amount1Out, sa);
		require(amount0In > 0 || amount1In > 0, "EP: INSUFFICIENT_INPUT_AMOUNT");
		{ 
			// This is a sanity check to make sure we don't lose from the swap.
			// scope for reserve{0,1} Adjusted, avoids stack too deep errors
			uint256 balance0Adjusted = (sa.balance0 * 1000) - (amount0In * 3); 
			uint256 balance1Adjusted = (sa.balance1 * 1000) - (amount1In * 3); 
			// 112 bit * 112 bit * 20 bit can not overflow a 256 bit value
			// Bigest possible number is 2,695994666715063979466701508702e+73
			// uint256 maxvalue is 1,1579208923731619542357098500869e+77
			// or 2**112 * 2**112 * 2**20 = 2**244 < 2**256
			require(balance0Adjusted * balance1Adjusted >= MathUInt256.unsafeMul(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1), 1_000_000), "EP: K");
		}
		_update(sa);
		emit Swap(_msgSender(), amount0In, amount1In, amount0Out, amount1Out, to);
	}

	
	// force reserves to match balances
	function sync() override public lock
	{
		_update(SwapAmount(_token0.balanceOf(address(this)), _token1.balanceOf(address(this)), _reserve0, _reserve1));
	}
	
	function factory() override public view returns (IExofiswapFactory)
	{
		return _factory;
	}

	function getReserves() override public view returns (uint112, uint112, uint32)
	{
		return (_reserve0, _reserve1, _blockTimestampLast);
	}

	function kLast() override public view returns (uint256)
	{
		return _kLast;
	}
	
	function name() override(ERC20, IERC20Metadata) public view virtual returns (string memory)
	{
		return string(abi.encodePacked(_token0.symbol(), "/", _token1.symbol(), " ", super.name()));
	}

	function price0CumulativeLast() override public view returns (uint256)
	{
		return _price0CumulativeLast;
	}

	function price1CumulativeLast() override public view returns (uint256)
	{
		return _price1CumulativeLast;
	}


	function token0() override public view returns (IERC20Metadata)
	{
		return _token0;
	}
	
	function token1() override public view returns (IERC20Metadata)
	{
		return _token1;
	}

	function MINIMUM_LIQUIDITY() override public pure returns (uint256) //solhint-disable-line func-name-mixedcase
	{
		return _MINIMUM_LIQUIDITY;
	}

	function _mintMinimumLiquidity() private
	{
		require(_totalSupply == 0, "EP: Total supply not 0");

		_totalSupply += _MINIMUM_LIQUIDITY;
		_balances[address(0)] += _MINIMUM_LIQUIDITY;
		emit Transfer(address(0), address(0), _MINIMUM_LIQUIDITY);
	}

	function _transferTokens(address to, uint256 amount0Out, uint256 amount1Out, bytes calldata data) private returns (uint256, uint256)
	{
		require(address(to) != address(_token0) && to != address(_token1), "EP: INVALID_TO");
		if (amount0Out > 0) SafeERC20.safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
		if (amount1Out > 0) SafeERC20.safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
		if (data.length > 0) IExofiswapCallee(to).exofiswapCall(_msgSender(), amount0Out, amount1Out, data);
		return (_token0.balanceOf(address(this)), _token1.balanceOf(address(this)));
	}

	// if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
	function _mintFee(uint256 k) private returns (bool)
	{
		address feeTo = _factory.feeTo();
		uint256 kLastHelp = _kLast; // gas savings
		if (feeTo != address(0))
		{
			if (kLastHelp != 0)
			{
				uint256 rootK = MathUInt256.sqrt(k);
				uint256 rootKLast = MathUInt256.sqrt(kLastHelp);
				if (rootK > rootKLast)
				{
					uint256 numerator = _totalSupply * MathUInt256.unsafeSub(rootK, rootKLast);
					// Since rootK is the sqrt of k. Multiplication by 5 can never overflow
					uint256 denominator = MathUInt256.unsafeMul(rootK, 5) + rootKLast;
					uint256 liquidity = MathUInt256.unsafeDiv(numerator, denominator);
					if (liquidity > 0)
					{
						_mint(feeTo, liquidity);
					}
				}
			}
			return true;
		}
		if(kLastHelp != 0)
		{
			_kLast = 0;
		}
		return false;
	}

	// update reserves and, on the first call per block, price accumulators
	function _update(SwapAmount memory sa) private
	{
		require(sa.balance0 <= type(uint112).max, "EP: OVERFLOW");
		require(sa.balance1 <= type(uint112).max, "EP: OVERFLOW");
		// solhint-disable-next-line not-rely-on-time
		uint32 blockTimestamp = uint32(block.timestamp);
		if (sa.reserve1 != 0)
		{
			if (sa.reserve0 != 0)
			{	
				uint32 timeElapsed = MathUInt32.unsafeSub32(blockTimestamp, _blockTimestampLast); // overflow is desired
				if (timeElapsed > 0)
				{	
					// * never overflows, and + overflow is desired
					unchecked
					{
						_price0CumulativeLast += (UQ144x112.uqdiv(UQ144x112.encode(sa.reserve1),sa.reserve0) * timeElapsed);
						_price1CumulativeLast += (UQ144x112.uqdiv(UQ144x112.encode(sa.reserve0), sa.reserve1) * timeElapsed);
					}
				}
			}
		}
		_reserve0 = uint112(sa.balance0);
		_reserve1 = uint112(sa.balance1);
		_blockTimestampLast = blockTimestamp;
		emit Sync(_reserve0, _reserve1);
	}

	function _getInAmounts(uint256 amount0Out, uint256 amount1Out, SwapAmount memory sa)
		private pure returns(uint256, uint256)
	{
		uint256 div0 = MathUInt256.unsafeSub(sa.reserve0, amount0Out);
		uint256 div1 = MathUInt256.unsafeSub(sa.reserve1, amount1Out);
		return (sa.balance0 > div0 ? MathUInt256.unsafeSub(sa.balance0, div0) : 0, sa.balance1 > div1 ? MathUInt256.unsafeSub(sa.balance1, div1) : 0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExofiswapCallee
{
    function exofiswapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20AltApprove.sol";
import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";

interface IExofiswapERC20 is IERC20AltApprove, IERC20Metadata
{
	// Functions as described in EIP 2612
	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
	function nonces(address owner) external view returns (uint256);
	function DOMAIN_SEPARATOR() external view returns (bytes32); // solhint-disable-line func-name-mixedcase
	function PERMIT_TYPEHASH() external pure returns (bytes32); //solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/access/IOwnable.sol";
import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "./IExofiswapFactory.sol";
import "./IExofiswapPair.sol";
import "./IMigrator.sol";

interface IExofiswapFactory is IOwnable
{
	event PairCreated(IERC20Metadata indexed token0, IERC20Metadata indexed token1, IExofiswapPair pair, uint256 pairCount);

	function createPair(IERC20Metadata tokenA, IERC20Metadata tokenB) external returns (IExofiswapPair pair);
	function setFeeTo(address) external;
	function setMigrator(IMigrator) external;
	
	function allPairs(uint256 index) external view returns (IExofiswapPair);
	function allPairsLength() external view returns (uint);
	function feeTo() external view returns (address);
	function getPair(IERC20Metadata tokenA, IERC20Metadata tokenB) external view returns (IExofiswapPair);
	function migrator() external view returns (IMigrator);

	function pairCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExofiswapCallee.sol";
import "./IExofiswapERC20.sol";
import "./IExofiswapFactory.sol";

interface IExofiswapPair is IExofiswapERC20
{
	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
	event Sync(uint112 reserve0, uint112 reserve1);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);
	function initialize(IERC20Metadata token0Init, IERC20Metadata token1Init) external;
	function mint(address to) external returns (uint256 liquidity);
	function skim(address to) external;
	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
	function sync() external;

	function factory() external view returns (IExofiswapFactory);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
	function kLast() external view returns (uint256);
	function price0CumulativeLast() external view returns (uint256);
	function price1CumulativeLast() external view returns (uint256);
	function token0() external view returns (IERC20Metadata);
	function token1() external view returns (IERC20Metadata);

	function MINIMUM_LIQUIDITY() external pure returns (uint256); //solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMigrator
{
	// Return the desired amount of liquidity token that the migrator wants.
	function desiredLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MathUInt256
{
	function min(uint256 a, uint256 b) internal pure returns(uint256)
	{
		return a > b ? b : a;
	}

	// solhint-disable-next-line code-complexity
	function sqrt(uint256 x) internal pure returns (uint256)
	{
		if (x == 0)
		{
			return 0;
		}

		// Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
		uint256 xAux = x;
		uint256 result = 1;
		if (xAux >= 0x100000000000000000000000000000000)
		{
			xAux >>= 128;
			result <<= 64;
		}
		if (xAux >= 0x10000000000000000)
		{
			xAux >>= 64;
			result <<= 32;
		}
		if (xAux >= 0x100000000)
		{
			xAux >>= 32;
			result <<= 16;
		}
		if (xAux >= 0x10000)
		{
			xAux >>= 16;
			result <<= 8;
		}
		if (xAux >= 0x100)
		{
			xAux >>= 8;
			result <<= 4;
		}
		if (xAux >= 0x10)
		{
			xAux >>= 4;
			result <<= 2;
		}
		if (xAux >= 0x4)
		{
			result <<= 1;
		}

		// The operations can never overflow because the result is max 2^127 when it enters this block.
		unchecked
		{
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1; // Seven iterations should be enough
			uint256 roundedDownResult = x / result;
			return result >= roundedDownResult ? roundedDownResult : result;
		}
	}

	function unsafeDec(uint256 a) internal pure returns (uint256)
	{
		unchecked 
		{
			return a - 1;
		}
	}

	function unsafeDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a / b;
		}
	}

	function unsafeInc(uint256 a) internal pure returns (uint256)
	{
		unchecked 
		{
			return a + 1;
		}
	}

	function unsafeMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a * b;
		}
	}

	function unsafeSub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a - b;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MathUInt32
{
	function unsafeSub32(uint32 a, uint32 b) internal pure returns (uint32)
	{
		unchecked
		{
			return a - b;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**144 - 1]
// resolution: 1 / 2**112

library UQ144x112
{
	uint256 private constant _Q112 = 2**112;

	// encode a uint112 as a UQ144x112
	function encode(uint112 y) internal pure returns (uint256)
	{
		unchecked
		{
			return uint256(y) * _Q112; // never overflows
		}
	}

	// divide a UQ144x112 by a uint112, returning a UQ144x112
    function uqdiv(uint256 x, uint112 y) internal pure returns (uint256)
	{
        return x / uint256(y);
    }
}