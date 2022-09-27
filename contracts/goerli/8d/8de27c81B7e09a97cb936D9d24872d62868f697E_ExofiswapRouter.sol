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

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "@exoda/contracts/token/ERC20/utils/SafeERC20.sol";
import "@exoda/contracts/utils/Context.sol";
import "./libraries/ExofiswapLibrary.sol";
import "./libraries/MathUInt256.sol";
import "./interfaces/IExofiswapFactory.sol";
import "./interfaces/IExofiswapPair.sol";
import "./interfaces/IExofiswapRouter.sol";
import "./interfaces/IWETH9.sol";

contract ExofiswapRouter is IExofiswapRouter, Context
{
	IExofiswapFactory private immutable _swapFactory;
	IWETH9 private immutable _wrappedEth;

	modifier ensure(uint256 deadline) {
		require(deadline >= block.timestamp, "ER: EXPIRED"); // solhint-disable-line not-rely-on-time
		_;
	}

	constructor(IExofiswapFactory swapFactory, IWETH9 wrappedEth)
	{
		_swapFactory = swapFactory;
		_wrappedEth = wrappedEth;
	}

	receive() override external payable
	{
		assert(_msgSender() == address(_wrappedEth)); // only accept ETH via fallback from the WETH contract
	}

	function addLiquidityETH(
		IERC20Metadata token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) override external virtual payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
	{
		IExofiswapPair pair;
		(amountToken, amountETH, pair) = _addLiquidity(
			token,
			_wrappedEth,
			amountTokenDesired,
			msg.value,
			amountTokenMin,
			amountETHMin
		);
		SafeERC20.safeTransferFrom(token, _msgSender(), address(pair), amountToken);
		_wrappedEth.deposit{value: amountETH}();
		assert(_wrappedEth.transfer(address(pair), amountETH));
		liquidity = pair.mint(to);
		// refund dust eth, if any
		if (msg.value > amountETH) ExofiswapLibrary.safeTransferETH(_msgSender(), MathUInt256.unsafeSub(msg.value, amountETH));
	}

	function addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity)
	{
		IExofiswapPair pair;
		(amountA, amountB, pair) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
		_safeTransferFrom(tokenA, tokenB, address(pair), amountA, amountB);
		liquidity = pair.mint(to);
	}

	function removeLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external virtual override ensure(deadline) returns (uint256, uint256)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, tokenA, tokenB);
		return _removeLiquidity(pair, tokenB < tokenA, liquidity, amountAMin, amountBMin, to);
	}

	function removeLiquidityETH(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256 amountToken, uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		(amountToken, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, amountToken);
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline) returns (uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		(, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, token.balanceOf(address(this)));
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHWithPermit(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external override virtual returns (uint256 amountToken, uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		{
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
		}
		(amountToken, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, amountToken);
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) override external virtual returns (uint256 amountETH)
	{
		{
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
			(, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		}
		SafeERC20.safeTransfer(token, to, token.balanceOf(address(this)));
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityWithPermit(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external override virtual returns (uint256 amountA, uint256 amountB)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, tokenA, tokenB);
		{
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
		}
		(amountA, amountB) = _removeLiquidity(pair, tokenB < tokenA, liquidity, amountAMin, amountBMin, to);
	}

	function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		require(path[lastItem] == _wrappedEth, "ER: INVALID_PATH"); // Overflow on lastItem will flail here to
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
		require(amounts[amounts.length - 1] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]);
		_swap(amounts, path, address(this));
		// Lenght of amounts array must be equal to length of path array.
		_wrappedEth.withdraw(amounts[lastItem]);
		ExofiswapLibrary.safeTransferETH(to, amounts[lastItem]);
	}

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline)
	{
		require(path[MathUInt256.unsafeDec(path.length)] == _wrappedEth, "ER: INVALID_PATH");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn);
		_swapSupportingFeeOnTransferTokens(path, address(this));
		uint256 amountOut = _wrappedEth.balanceOf(address(this));
		require(amountOut >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		_wrappedEth.withdraw(amountOut);
		ExofiswapLibrary.safeTransferETH(to, amountOut);
	}

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
		require(amounts[MathUInt256.unsafeDec(amounts.length)] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]);
		_swap(amounts, path, to);
	}

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline)
	{
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn);
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		uint256 balanceBefore = path[lastItem].balanceOf(to);
		_swapSupportingFeeOnTransferTokens(path, to);
		require((path[lastItem].balanceOf(to) - balanceBefore) >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
	}

	function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, IERC20Metadata[] calldata path, address to, uint256 deadline) override
		external virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		require(path[lastItem] == _wrappedEth, "ER: INVALID_PATH"); // Overflow on lastItem will fail here too
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= amountInMax, "ER: EXCESSIVE_INPUT_AMOUNT");
		SafeERC20.safeTransferFrom(
			path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]
		);
		_swap(amounts, path, address(this));
		// amounts and path must have the same item count...
		_wrappedEth.withdraw(amounts[lastItem]);
		ExofiswapLibrary.safeTransferETH(to, amounts[lastItem]);
	}

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= amountInMax, "ER: EXCESSIVE_INPUT_AMOUNT");
		SafeERC20.safeTransferFrom(
			path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]
		);
		_swap(amounts, path, to);
	}

	function swapETHForExactTokens(uint256 amountOut, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual payable ensure(deadline) returns (uint256[] memory amounts)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= msg.value, "ER: EXCESSIVE_INPUT_AMOUNT");
		_wrappedEth.deposit{value: amounts[0]}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]));
		_swap(amounts, path, to);
		// refund dust eth, if any
		if (msg.value > amounts[0]) ExofiswapLibrary.safeTransferETH(_msgSender(), msg.value - amounts[0]);
	}

	function swapExactETHForTokens(uint256 amountOutMin, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual payable ensure(deadline) returns (uint[] memory amounts)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, msg.value, path);
		require(amounts[MathUInt256.unsafeDec(amounts.length)] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		_wrappedEth.deposit{value: amounts[0]}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]));
		_swap(amounts, path, to);
	}

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual payable ensure(deadline)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		uint256 amountIn = msg.value;
		_wrappedEth.deposit{value: amountIn}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn));
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		uint256 balanceBefore = path[lastItem].balanceOf(to);
		_swapSupportingFeeOnTransferTokens(path, to);
		require(path[lastItem].balanceOf(to) - balanceBefore >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
	}

	function factory() override external view returns (IExofiswapFactory)
	{
		return _swapFactory;
	}

	function getAmountsIn(uint256 amountOut, IERC20Metadata[] memory path) override
		public view virtual returns (uint[] memory amounts)
	{
		return ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
	}

	// solhint-disable-next-line func-name-mixedcase
	function WETH() override public view returns(IERC20Metadata)
	{
		return _wrappedEth;
	}

	function getAmountsOut(uint256 amountIn, IERC20Metadata[] memory path) override
		public view virtual returns (uint256[] memory amounts)
	{
		return ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
	}

	function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) override
		public pure virtual returns (uint256 amountIn)
	{
		return ExofiswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) override
		public pure virtual returns (uint256)
	{
		return ExofiswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
	}

	function quote(uint256 amount, uint256 reserve0, uint256 reserve1) override public pure virtual returns (uint256)
	{
		return ExofiswapLibrary.quote(amount, reserve0, reserve1);
	}

	function _addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin
	) private returns (uint256, uint256, IExofiswapPair)
	{
		// create the pair if it doesn't exist yet
		IExofiswapPair pair = _swapFactory.getPair(tokenA, tokenB);
		if (address(pair) == address(0))
		{
			pair = _swapFactory.createPair(tokenA, tokenB);
		}
		(uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
		if (reserveA == 0 && reserveB == 0)
		{
			return (amountADesired, amountBDesired, pair);
		}
		if(pair.token0() == tokenB)
		{
			(reserveB, reserveA) = (reserveA, reserveB);
		}
		uint256 amountBOptimal = ExofiswapLibrary.quote(amountADesired, reserveA, reserveB);
		if (amountBOptimal <= amountBDesired)
		{
			require(amountBOptimal >= amountBMin, "ER: INSUFFICIENT_B_AMOUNT");
			return (amountADesired, amountBOptimal, pair);
		}
		uint256 amountAOptimal = ExofiswapLibrary.quote(amountBDesired, reserveB, reserveA);
		assert(amountAOptimal <= amountADesired);
		require(amountAOptimal >= amountAMin, "ER: INSUFFICIENT_A_AMOUNT");
		return (amountAOptimal, amountBDesired, pair);
	}

	function _removeLiquidity(
	IExofiswapPair pair,
	bool reverse,
	uint256 liquidity,
	uint256 amountAMin,
	uint256 amountBMin,
	address to
	) private returns (uint256 amountA, uint256 amountB)
	{
		pair.transferFrom(_msgSender(), address(pair), liquidity); // send liquidity to pair
		(amountA, amountB) = pair.burn(to);
		if(reverse)
		{
			(amountA, amountB) = (amountB, amountA);
		}
		require(amountA >= amountAMin, "ER: INSUFFICIENT_A_AMOUNT");
		require(amountB >= amountBMin, "ER: INSUFFICIENT_B_AMOUNT");
	}

	function _safeTransferFrom(IERC20Metadata tokenA, IERC20Metadata tokenB, address pair, uint256 amountA, uint256 amountB) private
	{
		address sender = _msgSender();
		SafeERC20.safeTransferFrom(tokenA, sender, pair, amountA);
		SafeERC20.safeTransferFrom(tokenB, sender, pair, amountB);
	}

	// requires the initial amount to have already been sent to the first pair
	function _swap(uint256[] memory amounts, IERC20Metadata[] memory path, address to) private
	{
		// TODO: Optimize for Gas. Still higher than Uniswap....maybe get all pairs from factory at once helps....
		uint256 pathLengthSubTwo = MathUInt256.unsafeSub(path.length, 2);
		uint256 j;
		uint256 i;
		while (i < pathLengthSubTwo)
		{
			j = MathUInt256.unsafeInc(i);
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
			(uint256 amount0Out, uint256 amount1Out) = path[i] == pair.token0() ? (uint256(0), amounts[j]) : (amounts[j], uint256(0));
			pair.swap(amount0Out, amount1Out, address(ExofiswapLibrary.pairFor(_swapFactory, path[j], path[MathUInt256.unsafeInc(j)])), new bytes(0));
			i = j;
		}
		j = MathUInt256.unsafeInc(i);
		IExofiswapPair pair2 = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
		(uint256 amount0Out2, uint256 amount1Out2) = path[i] == pair2.token0() ? (uint256(0), amounts[j]) : (amounts[j], uint256(0));
		pair2.swap(amount0Out2, amount1Out2, to, new bytes(0));
	}

	function _swapSupportingFeeOnTransferTokens(IERC20Metadata[] memory path, address to) private
	{
		uint256 pathLengthSubTwo = MathUInt256.unsafeSub(path.length, 2);
		uint256 j;
		uint256 i;
		while (i < pathLengthSubTwo)
		{
			j = MathUInt256.unsafeInc(i);
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
			uint256 amountInput;
			uint256 amountOutput;
			IERC20Metadata token0 = pair.token0();
			{ // scope to avoid stack too deep errors
				(uint256 reserveInput, uint256 reserveOutput,) = pair.getReserves();
				if (path[j] == token0)
				{
					(reserveInput, reserveOutput) = (reserveOutput, reserveInput);
				}
				amountInput = (path[i].balanceOf(address(pair)) - reserveInput);
				amountOutput = ExofiswapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
			}
			(uint256 amount0Out, uint256 amount1Out) = path[i] == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
			address receiver = address(ExofiswapLibrary.pairFor(_swapFactory, path[j], path[MathUInt256.unsafeInc(j)]));
			pair.swap(amount0Out, amount1Out, receiver, new bytes(0));
			i = j;
		}
		j = MathUInt256.unsafeInc(i);
		IExofiswapPair pair2 = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
		uint256 amountInput2;
		uint256 amountOutput2;
		IERC20Metadata token02 = pair2.token0();
		{ // scope to avoid stack too deep errors
			(uint256 reserveInput, uint256 reserveOutput,) = pair2.getReserves();
			if (path[j] == token02)
			{
				(reserveInput, reserveOutput) = (reserveOutput, reserveInput);
			}
			amountInput2 = (path[i].balanceOf(address(pair2)) - reserveInput);
			amountOutput2 = ExofiswapLibrary.getAmountOut(amountInput2, reserveInput, reserveOutput);
		}
		(uint256 amount0Out2, uint256 amount1Out2) = path[i] == token02? (uint256(0), amountOutput2) : (amountOutput2, uint256(0));
		pair2.swap(amount0Out2, amount1Out2, to, new bytes(0));
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
pragma solidity >=0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "./IExofiswapFactory.sol";

interface IExofiswapRouter {
	receive() external payable;

	function addLiquidityETH(
		IERC20Metadata token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

	function addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

	function removeLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityETHSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermit(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function removeLiquidityWithPermit(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function swapETHForExactTokens(
		uint256 amountOut,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable;

		function factory() external view returns (IExofiswapFactory);

	function getAmountsIn(uint256 amountOut, IERC20Metadata[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function WETH() external view returns (IERC20Metadata); // solhint-disable-line func-name-mixedcase

	function getAmountsOut(uint256 amountIn, IERC20Metadata[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256);

	function quote(
		uint256 amount,
		uint256 reserve0,
		uint256 reserve1
	) external pure returns (uint256);
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

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH9 is IERC20Metadata
{
	event Deposit(address indexed from, uint256 value);
	event Withdraw(address indexed to, uint256 value);
	
	function deposit() external payable;
	function withdraw(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "./MathUInt256.sol";
import "../interfaces/IExofiswapPair.sol";

library ExofiswapLibrary
{
	function safeTransferETH(address to, uint256 value) internal
	{
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "ER: ETH transfer failed");
	}

	// performs chained getAmountIn calculations on any number of pairs
	function getAmountsIn(IExofiswapFactory factory, uint256 amountOut, IERC20Metadata[] memory path)
	internal view returns (uint256[] memory amounts)
	{
		// can not underflow since path.length >= 2;
		uint256 j = path.length;
		require(j >= 2, "EL: INVALID_PATH");
		amounts = new uint256[](j);
		j = MathUInt256.unsafeDec(j);
		amounts[j] = amountOut;
		for (uint256 i = j; i > 0; i = j)
		{
			j = MathUInt256.unsafeDec(j);
			(uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[j], path[i]);
			amounts[j] = getAmountIn(amounts[i], reserveIn, reserveOut);
		}
	}

	// performs chained getAmountOut calculations on any number of pairs
	function getAmountsOut(IExofiswapFactory factory, uint256 amountIn, IERC20Metadata[] memory path)
	internal view returns (uint256[] memory amounts)
	{
		require(path.length >= 2, "EL: INVALID_PATH");
		amounts = new uint256[](path.length);
		amounts[0] = amountIn;
		// can not underflow since path.length >= 2;
		uint256 to = MathUInt256.unsafeDec(path.length);
		uint256 j;
		for (uint256 i; i < to; i = j)
		{
			j = MathUInt256.unsafeInc(i);
			(uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[j]);
			amounts[j] = getAmountOut(amounts[i], reserveIn, reserveOut);
		}
	}

	function getReserves(IExofiswapFactory factory, IERC20Metadata token0, IERC20Metadata token1) internal view returns (uint256, uint256)
	{
		(IERC20Metadata tokenL,) = sortTokens(token0, token1);
		(uint reserve0, uint reserve1,) = pairFor(factory, token0, token1).getReserves();
		return tokenL == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// calculates the CREATE2 address. It uses the factory for this since Factory already has the Pair contract included.
	// Otherwise this library would add the size of the Pair Contract to every contract using this function.
	function pairFor(IExofiswapFactory factory, IERC20Metadata token0, IERC20Metadata token1) internal pure returns (IExofiswapPair) {
		
		(IERC20Metadata tokenL, IERC20Metadata tokenR) = token0 < token1 ? (token0, token1) : (token1, token0);
		return IExofiswapPair(address(uint160(uint256(keccak256(abi.encodePacked(
				hex'ff', // CREATE2
				address(factory), // sender
				keccak256(abi.encodePacked(tokenL, tokenR)), // salt
				hex'2b030e03595718f09be5b952e8e9e44159b3fcf385422d5db25485106f124f44' // init code hash keccak256(type(ExofiswapPair).creationCode);
			))))));
	}

	// given an output amount of an asset and pair reserves, returns a required input amount of the other asset
	function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint amountIn)
	{
		require(amountOut > 0, "EL: INSUFFICIENT_OUTPUT_AMOUNT");
		require(reserveIn > 0 && reserveOut > 0, "EL: INSUFFICIENT_LIQUIDITY");
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		// Div of uint can not overflow
		// numerator is calulated in a way that if no overflow happens it is impossible to be type(uint256).max.
		// The most simple explanation is that * 1000 is a multiplikation with an even number so the result hast to be even to.
		// since type(uint256).max is uneven the result has to be smaler than type(uint256).max or an overflow would have occured.
		return MathUInt256.unsafeInc(MathUInt256.unsafeDiv(numerator, denominator));
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256)
	{
		require(amountIn > 0, "EL: INSUFFICIENT_INPUT_AMOUNT");
		require(reserveIn > 0, "EL: INSUFFICIENT_LIQUIDITY");
		require(reserveOut > 0, "EL: INSUFFICIENT_LIQUIDITY");
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = (reserveIn * 1000) + amountInWithFee;
		// Div of uint can not overflow
		return MathUInt256.unsafeDiv(numerator, denominator);
	}

	// given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
	function quote(uint256 amount, uint256 reserve0, uint256 reserve1) internal pure returns (uint256) {
		require(amount > 0, "EL: INSUFFICIENT_AMOUNT");
		require(reserve0 > 0, "EL: INSUFFICIENT_LIQUIDITY");
		require(reserve1 > 0, "EL: INSUFFICIENT_LIQUIDITY");
		// Division with uint can not overflow.
		return MathUInt256.unsafeDiv(amount * reserve1, reserve0);
	}

	// returns sorted token addresses, used to handle return values from pairs sorted in this order
	function sortTokens(IERC20Metadata token0, IERC20Metadata token1) internal pure returns (IERC20Metadata tokenL, IERC20Metadata tokenR)
	{
		require(token0 != token1, "EL: IDENTICAL_ADDRESSES");
		(tokenL, tokenR) = token0 < token1 ? (token0, token1) : (token1, token0);
		require(address(tokenL) != address(0), "EL: ZERO_ADDRESS");
	}
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