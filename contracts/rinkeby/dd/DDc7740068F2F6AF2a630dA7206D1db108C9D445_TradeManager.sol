// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/IDexTrader.sol";
import "./interfaces/ITradeManager.sol";
import "./libraries/TransferHelper.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TradeManager is ITradeManager, OwnableUpgradeable {
	mapping(address => mapping(address => TradeParams)) public params;

	uint256 public correctionRatioMultiplier; // 2 decimals, e.g. 100 = 1x
	uint256 public offsetTolerance; // 2 decimals, e.g. 100 = 1%

	modifier checkNonZero(uint256 _amount) {
		if (_amount == 0) revert ZeroAmountPassed();
		_;
	}

	modifier checkNonZero2(uint256 _amount0, uint256 _amount1) {
		if (_amount0 == 0 || _amount1 == 0) revert ZeroAmountPassed();
		_;
	}

	modifier checkNonZeroAddress(address _addr) {
		if (_addr == address(0)) revert ZeroAddressPassed();
		_;
	}

	modifier checkNonZeroAddress2(address _addr0, address _addr1) {
		if (_addr0 == address(0) || _addr1 == address(0))
			revert ZeroAddressPassed();
		_;
	}

	modifier tradePathExists(address _tokenIn, address _tokenOut) {
		if (params[_tokenIn][_tokenOut].path.length == 0)
			revert TradePathNotFound(_tokenIn, _tokenOut);
		_;
	}

	function setUp(
		uint256 _correctionRatioMultiplier,
		uint256 _offsetTolerance
	) external initializer {
		__Ownable_init();

		setCorrectionRatioMultiplier(_correctionRatioMultiplier);
		setOffsetTolerance(_offsetTolerance);
	}

	function setCorrectionRatioMultiplier(uint256 _correctionRatioMultiplier)
		public
		onlyOwner
	{
		require(
			_correctionRatioMultiplier > 100,
			"TradeManager: bad correction ratio multiplier"
		);
		correctionRatioMultiplier = _correctionRatioMultiplier;
	}

	function setOffsetTolerance(uint256 _offsetTolerance) public onlyOwner {
		offsetTolerance = _offsetTolerance;
	}

	function setCorrectionRatio(
		address _tokenIn,
		address _tokenOut,
		uint256 _correctionRatio
	)
		public
		tradePathExists(_tokenIn, _tokenOut)
		checkNonZero(_correctionRatio)
		onlyOwner
	{
		params[_tokenIn][_tokenOut].correctionRatio = _correctionRatio;
	}

	function setTradeParams(
		address _tokenIn,
		address _tokenOut,
		Swap[] memory _path,
		uint256 _defaultCorrectionRatio
	)
		public
		onlyOwner
		checkNonZeroAddress2(_tokenIn, _tokenOut)
		checkNonZero(_defaultCorrectionRatio)
	{
		uint256 pathLength = _path.length;

		if (pathLength == 0) revert ZeroPathLength();

		if (
			_path[0].tokenIn != _tokenIn ||
			_path[_path.length - 1].tokenOut != _tokenOut
		) revert PathMismatch();

		delete params[_tokenIn][_tokenOut].path;

		Swap[] storage path = params[_tokenIn][_tokenOut].path;

		for (uint256 i = 0; i < pathLength; i++) {
			path.push(_path[i]);
		}

		params[_tokenIn][_tokenOut].correctionRatio = _defaultCorrectionRatio;
	}

	function getTradeParams(address tokenIn, address tokenOut)
		external
		view
		returns (TradeParams memory)
	{
		return params[tokenIn][tokenOut];
	}

	function expectInputForExactOutput(
		address _tokenIn,
		address _tokenOut,
		uint256 _amountOut
	)
		public
		view
		tradePathExists(_tokenIn, _tokenOut)
		returns (uint256 expectedInAmount)
	{
		Swap[] memory path = params[_tokenIn][_tokenOut].path;

		uint256 swapAmount = _amountOut;
		uint256 i = path.length;
		do {
			i--;
			Swap memory swap = path[i];
			IDexTrader trader = IDexTrader(swap.trader);
			uint256 swapIn = trader.expectInputForExactOutput(
				swap.tokenIn,
				swap.tokenOut,
				swapAmount
			);
			swapAmount = swapIn;
		} while (i > 0);

		expectedInAmount =
			(swapAmount * params[_tokenIn][_tokenOut].correctionRatio) /
			1 ether;

		return expectedInAmount;
	}

	function tradeExactInput(
		address _tokenIn,
		address _tokenOut,
		uint256 _amountIn,
		uint256 _amountOutMin
	)
		public
		checkNonZero(_amountIn)
		checkNonZeroAddress2(_tokenIn, _tokenOut)
		tradePathExists(_tokenIn, _tokenOut)
		returns (uint256 amountOut)
	{
		amountOut = _trade(_tokenIn, _tokenOut, _amountIn, msg.sender);

		if (amountOut < _amountOutMin) revert InsufficientTradeOutput();
	}

	function tradeExactOutput(
		address _tokenIn,
		address _tokenOut,
		uint256 _amountOut,
		uint256 _amountInMax
	)
		public
		checkNonZero2(_amountOut, _amountInMax)
		checkNonZeroAddress2(_tokenIn, _tokenOut)
		tradePathExists(_tokenIn, _tokenOut)
		returns (uint256 amountIn)
	{
		amountIn = expectInputForExactOutput(_tokenIn, _tokenOut, _amountOut);

		if (amountIn > _amountInMax) revert InsufficientTradeInput();

		uint256 amountOutReal = _trade(
			_tokenIn,
			_tokenOut,
			amountIn,
			msg.sender
		);

		if (amountOutReal < _amountOut) {
			_increaseCorrectionRatio(_tokenIn, _tokenOut);

			revert InsufficientTradeOutput();
		}

		uint256 offset = amountOutReal - _amountOut;
		if (offset > (_amountOut * offsetTolerance) / 10000) {
			_decreaseCorrectionRatio(_tokenIn, _tokenOut);
		}

		return amountIn;
	}

	function _trade(
		address _tokenIn,
		address _tokenOut,
		uint256 _amountIn,
		address _sender
	) internal returns (uint256 amountOut) {
		TransferHelper.safeTransferFrom(
			_tokenIn,
			_sender,
			address(this),
			_amountIn
		);

		Swap[] memory path = params[_tokenIn][_tokenOut].path;

		uint256 swapAmountIn = _amountIn;
		for (uint256 i; i < path.length; i++) {
			Swap memory swap = path[i];
			IDexTrader trader = IDexTrader(swap.trader);

			TransferHelper.safeApprove(
				swap.tokenIn,
				address(trader),
				swapAmountIn
			);

			uint256 swapAmountOut = trader.swapExactInputSinglePath(
				swap.tokenIn,
				swap.tokenOut,
				swapAmountIn,
				0
			);

			swapAmountIn = swapAmountOut;
		}

		amountOut = swapAmountIn;

		TransferHelper.safeTransfer(_tokenOut, _sender, amountOut);

		return amountOut;
	}

	function increaseCorrectionRatio(address _tokenIn, address _tokenOut)
		public
		onlyOwner
	{
		_increaseCorrectionRatio(_tokenIn, _tokenOut);
	}

	function _increaseCorrectionRatio(address _tokenIn, address _tokenOut)
		internal
	{
		params[_tokenIn][_tokenOut].correctionRatio =
			(params[_tokenIn][_tokenOut].correctionRatio *
				correctionRatioMultiplier) /
			100;
	}

	function decreaseCorrectionRatio(address _tokenIn, address _tokenOut)
		public
		onlyOwner
	{
		_decreaseCorrectionRatio(_tokenIn, _tokenOut);
	}

	function _decreaseCorrectionRatio(address _tokenIn, address _tokenOut)
		internal
	{
		uint256 newRatio = (params[_tokenIn][_tokenOut].correctionRatio /
			correctionRatioMultiplier) * 100;
		if (newRatio < 100) {
			return;
		}
		params[_tokenIn][_tokenOut].correctionRatio = newRatio;
	}
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IDexTrader {
	/// @notice swapExactInputSinglePath swaps a fixed amount of input token for a maximum possible amount of output token
	/// @dev The calling address must approve this contract to spend at least `amountIn` worth of its input token for this function to succeed.
	/// @param amountIn The exact amount of input token that will be swapped for output token.
	/// @param amountOutMin The amount of output token we are willing to receive by spending the specified amount of input token.
	/// @return amountOut The amount of output token received.
	function swapExactInputSinglePath(
		address tokenIn,
		address tokenOut,
		uint256 amountIn,
		uint256 amountOutMin
	) external returns (uint256 amountOut);

	/// @notice swapExactOutputSinglePath swaps a minimum possible amount of input token for a fixed amount of output token.
	/// @dev The calling address must approve this contract to spend its input token for this function to succeed. As the amount of input input token is variable,
	/// the calling address will need to approve for a slightly higher amount, anticipating some variance.
	/// @param amountOut The exact amount of output token to receive from the swap.
	/// @param amountInMax The amount of input token we are willing to spend to receive the specified amount of output token.
	/// @return amountIn The amount of input token actually spent in the swap.
	function swapExactOutputSinglePath(
		address tokenIn,
		address tokenOut,
		uint256 amountOut,
		uint256 amountInMax
	) external returns (uint256 amountIn);

	/// @notice expectInputForExactOutput calculates an expected amount of input token to be spent in order to receive exact output token amount.
	/// @dev It returns a rough expected amount and it can be often not so exact.
	/// @param amountOut The amount of output token we are willing to receive by swap.
	/// @return expectedAmountIn The amount of input token that should be spent in the swap.
	function expectInputForExactOutput(
		address tokenIn,
		address tokenOut,
		uint256 amountOut
	) external view returns (uint256 expectedAmountIn);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../models/TradeManagerModels.sol";

interface ITradeManager {
	error InsufficientTradeInput();

	error InsufficientTradeOutput();

	error TradePathNotFound(address from, address to);

	error ZeroAmountPassed();

	error ZeroAddressPassed();

	error ZeroPathLength();

	error PathMismatch();

	error InvalidCorrectionRatio();

	function correctionRatioMultiplier() external view returns (uint256);

	function offsetTolerance() external view returns (uint256);

	function getTradeParams(address tokenIn, address tokenOut)
		external
		view
		returns (TradeParams memory);

	function expectInputForExactOutput(
		address _tokenIn,
		address _tokenOut,
		uint256 _amountOut
	) external returns (uint256 expectedInAmount);

	function tradeExactInput(
		address _tokenIn,
		address _tokenOut,
		uint256 _amountIn,
		uint256 _amountOutMin
	) external returns (uint256 amountOut);

	function tradeExactOutput(
		address _tokenIn,
		address _tokenOut,
		uint256 _amountOut,
		uint256 _amountInMax
	) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
	/// @notice Transfers tokens from the targeted address to the given destination
	/// @notice Errors with 'STF' if transfer fails
	/// @param token The contract address of the token to be transferred
	/// @param from The originating address from which the tokens will be transferred
	/// @param to The destination address of the transfer
	/// @param value The amount to be transferred
	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"STF"
		);
	}

	/// @notice Transfers tokens from msg.sender to a recipient
	/// @dev Errors with ST if transfer fails
	/// @param token The contract address of the token which will be transferred
	/// @param to The recipient of the transfer
	/// @param value The value of the transfer
	function safeTransfer(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20.transfer.selector, to, value)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"ST"
		);
	}

	/// @notice Approves the stipulated contract to spend the given allowance in the given token
	/// @dev Errors with 'SA' if transfer fails
	/// @param token The contract address of the token to be approved
	/// @param to The target of the approval
	/// @param value The amount of the given token the target will be allowed to spend
	function safeApprove(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20.approve.selector, to, value)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"SA"
		);
	}

	/// @notice Transfers ETH to the recipient address
	/// @dev Fails with `STE`
	/// @param to The destination of the transfer
	/// @param value The value to be transferred
	function safeTransferETH(address to, uint256 value) internal {
		(bool success, ) = to.call{ value: value }(new bytes(0));
		require(success, "STE");
	}
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

struct Swap {
	address trader;
	address tokenIn;
	address tokenOut;
}

struct TradeParams {
	Swap[] path;
	uint256 correctionRatio; // correction ratio decimals 18
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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