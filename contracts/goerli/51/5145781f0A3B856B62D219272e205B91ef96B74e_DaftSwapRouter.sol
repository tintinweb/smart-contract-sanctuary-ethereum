// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './DaftSwapPair.sol';
import './interfaces/IERC20Minimal.sol';

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

contract DaftSwapRouter is Ownable {

	/// Maps pair to pair address
	mapping(address => mapping(address => mapping(uint256 => address))) public pairAddresses;

    /// Transfer failed error
	error TransferFailed();

	/// @dev Get the pair contract's balance of token
	/// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
	/// check
	function tokenBalance(address token, address pair) private view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, pair)
		);
		require(success && data.length >= 32);
		return abi.decode(data, (uint256));
	}

	/// @dev Gets pair address for tokenX and tokenY
	/// @param tokenX the address of desired tokenX
	/// @param tokenY the address of desired tokenY
	function getPair(address tokenX, address tokenY, uint256 tickMode) external view returns (address pair) {
		return pairAddresses[tokenX][tokenY][tickMode];
	}

	/// @dev Creates a new pair for tokenX and tokenY
	/// @param tokenX the address of desired tokenX
	/// @param tokenY the address of desired tokenY
	function createPair(address tokenX, address tokenY, uint256 tickMode) public returns (address pair) {
		require(tokenX != address(0) && tokenY != address(0));
		pair = address(new DaftSwapPair{salt: keccak256(abi.encode(tokenX, tokenY, tickMode))}(address(this), tokenX, tokenY, tickMode));
		pairAddresses[tokenX][tokenY][tickMode] = pair;
	}

	function createLimitOrder(address pairAddress, uint256 tokenXAmount, int24 tick) external returns (uint256 orderId) {
		require(pairAddress != address(0));
		//transfer tokenX to pair contract, adjust tokenXAmount based on token transfer fees (if any)
        address tokenX = DaftSwapPair(pairAddress).tokenX();
		{
			uint256 preBalance = tokenBalance(tokenX, pairAddress);
			if (!IERC20Minimal(tokenX).transferFrom(msg.sender, pairAddress, tokenXAmount)) revert TransferFailed();
			tokenXAmount = tokenBalance(tokenX, pairAddress) - preBalance;
		}
		orderId = DaftSwapPair(pairAddress).createLimitOrder(tokenXAmount, tick, msg.sender);
	}

	function swapTokenYForExactTokenX(address pairAddress, uint256 tokenXAmount, uint256 maxTokenYAmount) external {
		require(pairAddress != address(0));
		//transfer tokenY to contract, adjust tokenXAmount based on token transfer fees (if any)
        address tokenY = DaftSwapPair(pairAddress).tokenY();
		{
			uint256 preBalance = tokenBalance(tokenY, pairAddress);
			if (!IERC20Minimal(tokenY).transferFrom(msg.sender, pairAddress, maxTokenYAmount)) revert TransferFailed();
			maxTokenYAmount = tokenBalance(tokenY, pairAddress) - preBalance;
		}
		DaftSwapPair(pairAddress).swapTokenYForExactTokenX(tokenXAmount, maxTokenYAmount, msg.sender);
	}

	function swapExactTokenYForTokenX(address pairAddress, uint256 tokenYAmount, uint256 minTokenXAmount) external {
		require(pairAddress != address(0));
		//transfer tokenY to contract, adjust tokenYAmount based on token transfer fees (if any)
        address tokenY = DaftSwapPair(pairAddress).tokenY();
		{
			uint256 preBalance = tokenBalance(tokenY, pairAddress);
			if (!IERC20Minimal(tokenY).transferFrom(msg.sender, pairAddress, tokenYAmount)) revert TransferFailed();
			tokenYAmount = tokenBalance(tokenY, pairAddress) - preBalance;
		}
		DaftSwapPair(pairAddress).swapExactTokenYForTokenX(tokenYAmount, minTokenXAmount, msg.sender);
	}

	function withdraw(address pairAddress, uint256 orderId) external {
		require(pairAddress != address(0));
		DaftSwapPair(pairAddress).withdraw(orderId, msg.sender);
	}

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './libraries/Tick.sol';
import './libraries/TickBitmap.sol';
import './libraries/TickMath.sol';
import './libraries/ABDKMath64x64.sol';
import './interfaces/IERC20Minimal.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IWETH.sol';
import './DaftSwapRouter.sol';


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

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
	/// @dev The original address of this contract
	address private immutable original;

	constructor() {
		// Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
		// In other words, this variable won't change when it's checked at runtime.
		original = address(this);
	}

	/// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
	///     and the use of immutable means the address bytes are copied in every place the modifier is used.
	function checkNotDelegateCall() private view {
		require(address(this) == original);
	}

	/// @notice Prevents delegatecall into the modified method
	modifier noDelegateCall() {
		checkNotDelegateCall();
		_;
	}
}

/// Pair contract for DaftSwap
contract DaftSwapPair is ReentrancyGuard, NoDelegateCall {

	using Tick for mapping(int24 => Tick.Info);
	using TickBitmap for mapping(int16 => uint256);

	/// Immutables
	address public immutable router;
	address public immutable tokenX;
	address public immutable tokenY;
	uint256 public immutable tickMode;

	/// Protocol fee (only applies to tokenX) - protocolFee / 10000 is the fee ratio
	uint256 public protocolFee;
	uint256 public feeTokenXAmountAccumulated;
	uint256 public swapFeeTokenXAmountAt;
	address public tokenXPairedAddress; //address tokenX is paired with (usually WETH)

	/// Current order ID
	uint256 public ORDER_ID;

	/// Order indexed state
	struct Order {
		address maker;
		int24 tick;
		uint128 tickMultiplier; //multiplier of tick at order creation
		uint256 tokenXAmount;
		uint256 creationTimestamp;
	}

	/// Slot0
	int24 public lowestTick;

	/// Maps tick index to info
	mapping(int24 => Tick.Info) public ticks;

	/// Tick bitmap
	mapping(int16 => uint256) public tickBitmap;

	/// Maps orderId to order
	mapping(uint256 => Order) orderIdMapping;

	/// Maps wallet to list of orderIds
	mapping(address => uint256[]) public orderIdsByMaker;

	/// Modifier to allow only router to make a call
	modifier onlyRouter() {
		require(msg.sender == router);
		_;
	}

	/// Modifier to allow only router owner to make a call
	modifier onlyRouterOwner() {
		require(msg.sender == DaftSwapRouter(router).owner());
		_;
	}

	/// Transfer failed error
	error TransferFailed();


	/// Constructooor
	constructor(address _router, address _tokenX, address _tokenY, uint256 _tickMode) {
		router = _router;
		tokenX = _tokenX;
		tokenY = _tokenY;
		tickMode = _tickMode;
	}


	/// @dev Get the contract's balance of token
	/// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
	/// check
	function tokenBalance(address token) private view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
		);
		require(success && data.length >= 32);
		return abi.decode(data, (uint256));
	}

	/// @dev Get all orderIds for maker
	function getOrderIdsByMaker(address maker) external view returns (uint256[] memory) {
		return orderIdsByMaker[maker];
	}

	/// @dev Get tick info for tick
	function getTickInfo(int24 tick) external view returns (Tick.Info memory) {
		return ticks[tick];
	}

	/// @dev Get tick bitmap for word corresponding to tick
	function getTickBitmap(int24 tick) external view returns (uint256) {
		return tickBitmap[int16(tick >> 8)];
	}

	/// @dev Get order info for orderId
	function getOrderInfo(uint256 orderId) external view returns (Order memory) {
		return orderIdMapping[orderId];
	}

	/// @dev Gets tokenYAmount required for exact tokenXAmount
	/// @param tokenXAmount the exact amount of tokenX desired
	function getExactTokenYForTokenX(uint256 tokenXAmount) external view returns (uint256 tokenYAmountRequired) {
		require(tokenXAmount > 0);
		int24 currTick = lowestTick;
		uint256 tickModeForPair = tickMode;
		bool initialized = true; //assume tick at slot0 is initialized

		// NOTE: while loop will run forever if there isn't enough liquidity to satisfy order, causing an error!
		while (tokenXAmount > 0) {
			//only executing if initialized saves an unnecessary SLOAD in tick.execute(). If not initialized we simply proceed to next initialized tick.
			if (initialized) {
				(uint256 requiredTokenYAmount, uint256 usedTokenXAmount) = ticks.simulateExecute(currTick, tickModeForPair, tokenXAmount);
				tokenXAmount -= usedTokenXAmount;
				tokenYAmountRequired += requiredTokenYAmount;
			}

			if (tokenXAmount > 0) {
				(currTick, initialized) = tickBitmap.nextInitializedTickWithinOneWord(currTick + 1);
			}
		}
	}

	/// @dev Gets expected tokenXAmount for exact tokenYAmount
	/// @param tokenYAmount the exact amount of tokenY desired
	function getExactTokenXForTokenY(uint256 tokenYAmount) external view returns (uint256 tokenXAmountOut) {
		require(tokenYAmount > 0);
		int24 currTick = lowestTick;
		uint256 tickModeForPair = tickMode;
		bool initialized = true; //assume tick at slot0 is initialized

		// NOTE: while loop will run forever if there isn't enough liquidity to satisfy order, causing an error!
		while (tokenYAmount > 0) {
			//only executing if initialized saves an unnecessary SLOAD in tick.execute(). If not initialized we simply proceed to next initialized tick.
			if (initialized) {
				(uint256 requiredTokenXAmount, uint256 usedTokenYAmount) = ticks.simulateExecuteWithTokenY(currTick, tickModeForPair, tokenYAmount);
				tokenYAmount -= usedTokenYAmount;
				tokenXAmountOut += requiredTokenXAmount;
			}

			if (tokenYAmount > 0) {
				(currTick, initialized) = tickBitmap.nextInitializedTickWithinOneWord(currTick + 1);
			}
		}
	}



	/// @dev Create limit order at tick
	function createLimitOrder(uint256 tokenXAmount, int24 tick, address maker) external nonReentrant noDelegateCall onlyRouter returns (uint256 orderId) {
		//create order
		orderId = ++ORDER_ID;
		orderIdsByMaker[maker].push(orderId);

		//update tickInfo for tick and flip tick if necessary
		(bool flipped, uint128 tickMultiplier) = ticks.update(tick, tokenXAmount, false);
		if (flipped) tickBitmap.initializeTick(tick);
		orderIdMapping[orderId] = Order({
			maker: maker,
			tick: tick,
			tokenXAmount: tokenXAmount,
			creationTimestamp: block.timestamp,
			tickMultiplier: tickMultiplier
		});

		//update lowestTick
		if (lowestTick > tick || ticks[lowestTick].tokenXAmount == 0) lowestTick = tick;
	}


	/// @dev Swaps tokenY for exact tokenX, ensuring tokenYAmount required doesn't exceed maxTokenYAmount
	/// @param tokenXAmount the exact amount of tokenX desired
	/// @param maxTokenYAmount the maximum tokenY amount to be spent
	function swapTokenYForExactTokenX(uint256 tokenXAmount, uint256 maxTokenYAmount, address maker) external nonReentrant noDelegateCall onlyRouter {
		require(tokenXAmount > 0 && maxTokenYAmount > 0);

		int24 currTick = lowestTick;
		uint256 tickModeForPair = tickMode;
		bool initialized = true; //assume tick at slot0 is initialized

		// NOTE: while loop will run forever if there isn't enough liquidity to satisfy order, causing an error!
		uint256 tokenYAmountAccumulated;
		uint256 tokenXAmountRemaining = tokenXAmount;
		while (tokenXAmountRemaining > 0 && tokenYAmountAccumulated < maxTokenYAmount) {
			//only executing if initialized saves an unnecessary SLOAD in tick.execute(). If not initialized we simply proceed to next initialized tick.
			bool flipped;
			if (initialized) {
				(bool currFlipped, uint256 requiredTokenYAmount, uint256 usedTokenXAmount) = ticks.execute(currTick, tickModeForPair, tokenXAmountRemaining);
				flipped = currFlipped;
				tokenXAmountRemaining -= usedTokenXAmount;
				tokenYAmountAccumulated += requiredTokenYAmount;
			}

			// if (flipped) tickBitmap.resetTick(currTick); //an unecessary SSTORE, since a tick thats initialized in bitmap but not in storage wont make any changes.

			if (tokenXAmountRemaining > 0 || flipped) {
				(currTick, initialized) = tickBitmap.nextInitializedTickWithinOneWord(currTick + 1);
			}
		}

		//check to make sure desired tokenXAmount is met and tokenYAmountAccumulated doesn't exceed maxTokenYAmount
		require(tokenYAmountAccumulated <= maxTokenYAmount);

		//take protocol fees, transfer tokenXAmount and refund tokenY if necessary
		uint256 currProtocolFeeTokenX = protocolFee;
		if (currProtocolFeeTokenX != 0) {
			uint256 tokenXFeeAmount = tokenXAmount * currProtocolFeeTokenX / 10000;
			tokenXAmount -= tokenXFeeAmount;
			feeTokenXAmountAccumulated += tokenXFeeAmount;
			//TODO: if feeTokenXAmountAccumulated >= swapFeeTokenXAmountAt, swap tokenX for protocol token and burn protocol token.
			if (feeTokenXAmountAccumulated >= swapFeeTokenXAmountAt) {
				swapFeeAndBurn();
			}
		}
		if (!IERC20Minimal(tokenX).transfer(maker, tokenXAmount)) revert TransferFailed();
		if (tokenYAmountAccumulated < maxTokenYAmount) {
			if (!IERC20Minimal(tokenY).transfer(maker, maxTokenYAmount - tokenYAmountAccumulated)) revert TransferFailed();
		}

		//update lowestTick
		lowestTick = currTick;
	}


	/// @dev Swaps exact tokenY for tokenX, ensuring tokenXAmount is atleast minTokenXAmount
	/// @param tokenYAmount the exact amount of tokenY desired
	/// @param minTokenXAmount the minimum tokenX amount to be received
	function swapExactTokenYForTokenX(uint256 tokenYAmount, uint256 minTokenXAmount, address maker) external nonReentrant noDelegateCall onlyRouter {
		require(tokenYAmount > 0);

		int24 currTick = lowestTick;
		uint256 tickModeForPair = tickMode;
		bool initialized = true; //assume tick at slot0 is initialized

		// NOTE: while loop will run forever if there isn't enough liquidity to satisfy order, causing an error!
		uint256 tokenXAmountAccumulated;
		uint256 tokenYAmountRemaining = tokenYAmount;
		while (tokenYAmountRemaining > 0) {
			//only executing if initialized saves an unnecessary SLOAD in tick.execute(). If not initialized we simply proceed to next initialized tick.
			bool flipped;
			if (initialized) {
				(bool currFlipped, uint256 requiredTokenXAmount, uint256 usedTokenYAmount) = ticks.executeWithTokenY(currTick, tickModeForPair, tokenYAmountRemaining);
				flipped = currFlipped;
				tokenYAmountRemaining -= usedTokenYAmount;
				tokenXAmountAccumulated += requiredTokenXAmount;
			}

			// if (flipped) tickBitmap.resetTick(currTick); //an unecessary SSTORE, since a tick thats initialized in bitmap but not in storage wont make any changes.

			if (tokenYAmountRemaining > 0 || flipped) {
				(currTick, initialized) = tickBitmap.nextInitializedTickWithinOneWord(currTick + 1);
			}
		}

		//check to make sure desired tokenXAmount is met and tokenXAmountAccumulated is at least minTokenXAmount
		require(tokenXAmountAccumulated >= minTokenXAmount);

		//take protocol fees, transfer tokenXAmountAccumulated
		uint256 currProtocolFeeTokenX = protocolFee;
		if (currProtocolFeeTokenX != 0) {
			uint256 tokenXFeeAmount = tokenXAmountAccumulated * currProtocolFeeTokenX / 10000;
			tokenXAmountAccumulated -= tokenXFeeAmount;
			feeTokenXAmountAccumulated += tokenXFeeAmount;
			//TODO: if feeTokenXAmountAccumulated >= swapFeeTokenXAmountAt, swap tokenX for protocol token and burn protocol token.
			if (feeTokenXAmountAccumulated >= swapFeeTokenXAmountAt) {
				swapFeeAndBurn();
			}
		}
		if (!IERC20Minimal(tokenX).transfer(maker, tokenXAmountAccumulated)) revert TransferFailed();

		//update lowestTick
		lowestTick = currTick;
	}

	/// @dev Withdraws (fully) order specified by orderId
	/// @param orderId the orderId to withdraw
	function withdraw(uint256 orderId, address maker) external nonReentrant noDelegateCall onlyRouter {
		//TODO: withdraw order
		Order memory order = orderIdMapping[orderId];
		require(maker == order.maker);

		int24 tick = order.tick;
		Tick.Info storage tickInfo = ticks[tick];

		uint256 tokenXAmountWithdrawable;
		uint256 tokenYAmountWithdrawable;
		if (!tickInfo.initialized || tickInfo.lastInitializationTimestamp > order.creationTimestamp) {
			//tick has been executed
			tokenYAmountWithdrawable = TickMath.getOutputTokenYAmount(tick, tickMode, order.tokenXAmount);
		} else if (tickInfo.multiplier != order.tickMultiplier) {
			//tick has been partially executed since order creation
			int128 netMultiplier = ABDKMath64x64.div(int128(tickInfo.multiplier), int128(order.tickMultiplier));
			tokenXAmountWithdrawable = ABDKMath64x64.mulu(netMultiplier, order.tokenXAmount);
			tokenYAmountWithdrawable = TickMath.getOutputTokenYAmount(tick, tickMode, order.tokenXAmount - tokenXAmountWithdrawable);
		} else {
			//tick has not been executed since order creation
			tokenXAmountWithdrawable = order.tokenXAmount;
		}

		//token transfers and update tick and tickBitmap if necessary
		if (tokenXAmountWithdrawable > 0) {
			if (!IERC20Minimal(tokenX).transfer(maker, tokenXAmountWithdrawable)) revert TransferFailed();
			(bool flipped,) = ticks.update(tick, tokenXAmountWithdrawable, true);
			if (flipped) {
				tickBitmap.resetTick(tick);
			}
		}
		if (tokenYAmountWithdrawable > 0) {
			if (!IERC20Minimal(tokenY).transfer(maker, tokenYAmountWithdrawable)) revert TransferFailed();
		}

		//delete order
		delete orderIdMapping[orderId];
	}

	///@dev Swaps fee tokenX and burn native token
	function swapFeeAndBurn() internal {
		//load fee amount
		uint256 feeAmount = feeTokenXAmountAccumulated;

		//execute swap
		if (tokenXPairedAddress != address(0x9c7de7DF49c102b133D17b40195947E0fb1784c8)) {
			address[] memory path = new address[](4);
			path[0] = tokenX;
			path[1] = tokenXPairedAddress;
			path[2] = address(0x9c7de7DF49c102b133D17b40195947E0fb1784c8); // native token is paired with DAI
			path[3] = address(0x6C54F2D5167d7b42d809c5A84D936C38c7c25d0F); // native token (TODO: change)

			// approves uniswap router to spend tokenX
			IERC20Minimal(tokenX).approve(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), feeAmount);

			IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				feeAmount,
				0, // accept any amount
				path,
				address(this),
				block.timestamp
			);
		} else {
			address[] memory path = new address[](3);
			path[0] = tokenX;
			path[1] = address(0x9c7de7DF49c102b133D17b40195947E0fb1784c8); // tokenX is paired with DAI
			path[2] = address(0x6C54F2D5167d7b42d809c5A84D936C38c7c25d0F); // native token (TODO: change)

			// approves uniswap router to spend tokenX
			IERC20Minimal(tokenX).approve(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), feeAmount);

			IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				feeAmount,
				0, // accept any amount
				path,
				address(this),
				block.timestamp
			);
		}

		//burn native token
		IERC20Minimal(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)).transfer(address(0xdead), tokenBalance(address(0x6C54F2D5167d7b42d809c5A84D936C38c7c25d0F)));
	}

	/// @dev Sets protocol fee (only callable by router owner)
	function setProtocolFees(
		uint256 newProtocolFee,
		uint256 newSwapFeeTokenXAmountAt,
		address newTokenXPairedAddress
	) external onlyRouterOwner {
		protocolFee = newProtocolFee;
		swapFeeTokenXAmountAt = newSwapFeeTokenXAmountAt;
		tokenXPairedAddress = newTokenXPairedAddress;
	}

}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

interface IWETH {

	event  Approval(address indexed src, address indexed guy, uint wad);
	event  Transfer(address indexed src, address indexed dst, uint wad);
	event  Deposit(address indexed dst, uint wad);
	event  Withdrawal(address indexed src, uint wad);

	function deposit() external payable;
	function withdraw(uint wad) external;

	function totalSupply() external view returns (uint);

	function approve(address guy, uint wad) external returns (bool);

	function transfer(address dst, uint wad) external returns (bool);

	function transferFrom(address src, address dst, uint wad) external returns (bool);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

interface IUniswapV2Router02 {
	function factory() external pure returns (address);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) internal pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x4) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './ABDKMath64x64.sol';

/// @title Math library for computing prices from ticks and vice versa
/// @notice Computes price for ticks of size 1.0001, i.e. (1.0001^tick) as fixed point Q64.64 numbers. Supports
/// prices between 2**-64 and 2**63, with a resolution of 2**-64
library TickMath {
    /// @dev The minimum tick that may be passed to #getPriceRatioAtTick computed from log base 1.0001 of 2**-64
    int24 internal constant MIN_TICK = -443646;
    /// @dev The maximum tick that may be passed to #getPriceRatioAtTick computed from log base 1.0001 of 2**63
    int24 internal constant MAX_TICK = 436704;

    // /// TODO: FIGURE THIS SHIT OUT
    // /// @dev The minimum value that can be returned from #getPriceRatioAtTick. Equivalent to getPriceRatioAtTick(MIN_TICK)
    // uint128 internal constant MIN_PRICE_RATIO = 4295128739;
    // /// @dev The maximum value that can be returned from #getPriceRatioAtTick. Equivalent to getPriceRatioAtTick(MAX_TICK)
    // uint128 internal constant MAX_PRICE_RATIO = 1461446703485210103287273052203988822378723970342;


    /// @notice Calculates 1.0001^tick * 2^64
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return priceX64 A Fixed point Q64.64 number representing the ratio of the two assets (tokenY/tokenX)
    /// at the given tick
    function getPriceRatioAtTick(int24 tick, uint256 tickMode) internal pure returns (int128 priceX64) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), 'T');

        if (tickMode == 0) {
            // Q64.64 equivalent of 1.0001 => 1.0001 * 2**64 (with correct precision) = 18448588748116922571
            priceX64 = ABDKMath64x64.pow(18448588748116922571, absTick);
        } else if (tickMode == 1) {
            // Q64.64 equivalent of 1.001 => 1.001 * 2**64 (with correct precision) = 18465190817783261167
            priceX64 = ABDKMath64x64.pow(18465190817783261167, absTick);
        } else {
            // Q64.64 equivalent of 1.01 => 1.01 * 2**64 (with correct precision) = 18631211514446647132
            priceX64 = ABDKMath64x64.pow(18631211514446647132, absTick);
        }

        if (tick < 0) priceX64 = ABDKMath64x64.inv(priceX64);
    }


    /// @notice Calculates output amount of tokenY for given tick and tokenXAmount
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return tokenYAmount A Fixed point Q64.64 number representing the ratio of the two assets (tokenY/tokenX)
    /// at the given tick
    function getOutputTokenYAmount(int24 tick, uint256 tickMode, uint256 tokenXAmount) internal pure returns (uint256 tokenYAmount) {
        int128 priceX64 = getPriceRatioAtTick(tick, tickMode);
        tokenYAmount = ABDKMath64x64.mulu(priceX64, tokenXAmount);
    }


    /// @notice Calculates output amount of tokenX for given tick and tokenYAmount
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return tokenXAmount A Fixed point Q64.64 number representing the ratio of the two assets (tokenY/tokenX)
    /// at the given tick
    function getOutputTokenXAmount(int24 tick, uint256 tickMode, uint256 tokenYAmount) internal pure returns (uint256 tokenXAmount) {
        int128 priceY64 = getPriceRatioAtTick(-tick, tickMode);
        tokenXAmount = ABDKMath64x64.mulu(priceY64, tokenYAmount);
        if (getOutputTokenYAmount(tick, tickMode, tokenXAmount) < tokenYAmount) ++tokenXAmount; //round up if necessary
    }


    // /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    // /// @dev Throws in case priceX64 < MIN_PRICE_RATIO, as MIN_PRICE_RATIO is the lowest value getRatioAtTick may
    // /// ever return.
    // /// @param priceX64 The sqrt ratio for which to compute the tick as a Q64.64
    // /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    // function getTickAtPriceRatio(uint128 priceX64) internal pure returns (int24 tick) {
    //     require(priceX64 <= MAX_PRICE_RATIO && priceX64 >= MIN_PRICE_RATIO);
    //     int128 log_2 = ABDKMath64x64.log_2(int128(priceX64));

    //     //log_1.0001(2) = 6931.8183734137953551959678499998267835280741368840996616580870734
    //     //log_1.0001(2) * 2**64 = 127869479499801913173570 (with correct precision)
    //     int128 log_10001 = ABDKMath64x64.mul(log_2, 127869479499801913173570);

    //     //128-24 = 104
    //     tick = int24(log_10001 >> 104);
    // }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './BitMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(int8(tick % 256)); //TODO: double check this
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal {
        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }


    /// @notice Sets initialized state of tick to true
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to initialize
    function initializeTick(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal {
        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] |= mask;
    }


    /// @notice Flips the initialized state for a given tick to false
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    function resetTick(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal {
        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] &= ~mask;
    }


    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick;

        (int16 wordPos, uint8 bitPos) = position(compressed);
        // all the 1s at or to the right of the current bitPos
        uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
        uint256 masked = self[wordPos] & mask;

        // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
        initialized = masked != 0;
        // overflow/underflow is possible, but prevented externally by limiting tick
        //TODO: double check this
        next = initialized
            ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked))))
            : (compressed - int24(uint24(bitPos)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import './TickMath.sol';

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {

    /// Tick indexed state
    struct Info {
        uint256 tokenXAmount;
        uint256 lastInitializationTimestamp;
        uint128 multiplier; //Q64.64 multiplier
        bool initialized;
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param tokenXDelta The amount of tokenX to be added/removed from tick
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tokenXDelta,
        bool isRemove
    ) internal returns (bool flipped, uint128 tickMultiplier) {
        require(tokenXDelta != 0);
        Tick.Info storage info = self[tick];
        uint256 prevTokenXAmount = info.tokenXAmount;

        if (isRemove) {
            require(tokenXDelta <= prevTokenXAmount, 'E');
            info.tokenXAmount -= tokenXDelta;
        } else {
            info.tokenXAmount += tokenXDelta;
        }

        if (prevTokenXAmount == 0) {
            info.initialized = true;
            info.lastInitializationTimestamp = block.timestamp;
            flipped = true;
        } else if (isRemove && prevTokenXAmount == tokenXDelta) {
            delete self[tick];
            flipped = true;
        }

        tickMultiplier = info.multiplier;
    }

    /// @notice Executes a tick (with given tokenX) and returns if the tick is to be flipped and the required tokenYAmount for execution (partial or full)
    /// @dev can only be called on an initialized tick
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be executed
    /// @param tokenXDelta The amount of tokenX to be executed from tick (amount tokenX remaining in swap loop)
    function execute(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tickMode,
        uint256 tokenXDelta
    ) internal returns (bool flipped, uint256 requiredTokenYAmount, uint256 usedTokenXAmount) {
        Tick.Info storage info = self[tick];
        uint256 prevTokenXAmount = info.tokenXAmount;
        if (prevTokenXAmount == 0) return (true, 0, 0);

        usedTokenXAmount = tokenXDelta;
        if (usedTokenXAmount >= prevTokenXAmount) {
            usedTokenXAmount = prevTokenXAmount;
            delete self[tick];
            flipped = true;
        } else {
            uint128 currRatio = ABDKMath64x64.divuu(prevTokenXAmount - usedTokenXAmount, prevTokenXAmount);
            uint128 currTickMultiplier = info.multiplier;
            if (currTickMultiplier == 0){
                info.multiplier = currRatio;
            } else {
                info.multiplier = uint128(ABDKMath64x64.mul(int128(currTickMultiplier), int128(currRatio)));
            }
            info.tokenXAmount -= usedTokenXAmount;
        }
        requiredTokenYAmount = TickMath.getOutputTokenYAmount(tick, tickMode, usedTokenXAmount);
    }

    /// @notice Executes a tick (with given tokenY) and returns if the tick is to be flipped and the required tokenYAmount for execution (partial or full)
    /// @dev can only be called on an initialized tick
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be executed
    /// @param tokenYDelta The amount of tokenX to be executed from tick (amount tokenX remaining in swap loop)
    function executeWithTokenY(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tickMode,
        uint256 tokenYDelta
    ) internal returns (bool flipped, uint256 requiredTokenXAmount, uint256 usedTokenYAmount) {
        Tick.Info storage info = self[tick];
        uint256 prevTokenXAmount = info.tokenXAmount;
        if (prevTokenXAmount == 0) return (true, 0, 0);

        requiredTokenXAmount = TickMath.getOutputTokenXAmount(tick, tickMode, tokenYDelta);
        if (requiredTokenXAmount >= prevTokenXAmount) {
            requiredTokenXAmount = prevTokenXAmount;
            delete self[tick];
            flipped = true;
        } else {
            uint128 currRatio = ABDKMath64x64.divuu(prevTokenXAmount - requiredTokenXAmount, prevTokenXAmount);
            uint128 currTickMultiplier = info.multiplier;
            if (currTickMultiplier == 0){
                info.multiplier = currRatio;
            } else {
                info.multiplier = uint128(ABDKMath64x64.mul(int128(currTickMultiplier), int128(currRatio)));
            }
            info.tokenXAmount -= requiredTokenXAmount;
        }
        usedTokenYAmount = TickMath.getOutputTokenYAmount(tick, tickMode, requiredTokenXAmount);
    }



    /// @notice Simulates execution of a tick and returns if the tick is to be flipped and the required tokenYAmount for execution (partial or full)
    /// @dev can only be called on an initialized tick
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be executed
    /// @param tokenXDelta The amount of tokenX to be executed from tick (amount tokenX remaining in swap loop)
    function simulateExecute(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tickMode,
        uint256 tokenXDelta
    ) internal view returns (uint256 requiredTokenYAmount, uint256 usedTokenXAmount) {
        uint256 prevTokenXAmount = self[tick].tokenXAmount;
        if (prevTokenXAmount == 0) return (0, 0);

        usedTokenXAmount = (tokenXDelta > prevTokenXAmount) ? prevTokenXAmount : tokenXDelta;

        requiredTokenYAmount = TickMath.getOutputTokenYAmount(tick, tickMode, usedTokenXAmount);
    }

    /// @notice Simulates execution of a tick (with tokenY) and returns if the tick is to be flipped and the required tokenYAmount for execution (partial or full)
    /// @dev can only be called on an initialized tick
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be executed
    /// @param tokenYDelta The amount of tokenX to be executed from tick (amount tokenX remaining in swap loop)
    function simulateExecuteWithTokenY(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tickMode,
        uint256 tokenYDelta
    ) internal view returns (uint256 requiredTokenXAmount, uint256 usedTokenYAmount) {
        uint256 prevTokenXAmount = self[tick].tokenXAmount;
        if (prevTokenXAmount == 0) return (0, 0);

        requiredTokenXAmount = TickMath.getOutputTokenXAmount(tick, tickMode, tokenYDelta);
        if (requiredTokenXAmount > prevTokenXAmount) {
            requiredTokenXAmount = prevTokenXAmount;
        }
        usedTokenYAmount = TickMath.getOutputTokenYAmount(tick, tickMode, requiredTokenXAmount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}