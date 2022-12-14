/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
// A truly decentralized, automated market making contract that allows for Over-the-Counter (OTC) swaps between 2 ERC-20 tokens.
pragma solidity ^0.8.10;


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


contract DefiOTCSwapSimple is ReentrancyGuard {

	uint256 public ORDER_ID;

	struct Order {
		address tokenX;
		address tokenY;
		uint256 tokenXAmount;
		uint256 desiredTokenYAmount;
		address maker;
	}

	mapping(uint256 => Order) public orderIdMapping;
	mapping(address => uint256[]) public orderIdsByMaker;
	mapping(address => mapping(address => uint256[])) public orderBooks;

	/// No other orders exist for creation of minimum order
	error NoOtherOrdersExistForAutoMinimumOrder();
	/// No order exists for id
	error OrderDoesNotExist();
	/// Unauthorized withdrawal
	error UnauthorizedWithdrawal();
	/// Invalid order
	error InvalidOrder();
	/// Invalid order id
	error InvalidOrderId();
	/// Insufficient market depth
	error InsufficientMarketDepth();
	/// Desired tokenYAmount exceeds current minimum order
	error DesiredTokenYAmountExceedsMinimum();
	/// Token transfer failed
	error TransferFailed();
	/// Too little tokenY received
	error TooLittleTokenYReceived();




	/// Create a minimum limit order with specified desiredTokenYAmount
	/// TODO: Decide whether or not to update desiredTokenYAmount if tokenX has transfer taxes
	function createLimitOrderWithDesiredTokenYAmount(address tokenX, address tokenY, uint256 tokenXAmount, uint256 desiredTokenYAmount) external nonReentrant returns (uint256 _orderId) {
		if (tokenXAmount == 0 || desiredTokenYAmount == 0 || tokenX == address(0) || tokenY == address(0)) revert InvalidOrder();

		{
			uint256 preBalance = IERC20(tokenX).balanceOf(address(this));
			if (!IERC20(tokenX).transferFrom(msg.sender, address(this), tokenXAmount)) revert TransferFailed();
			tokenXAmount = IERC20(tokenX).balanceOf(address(this)) - preBalance;
		}

		_orderId = ++ORDER_ID;
		orderIdsByMaker[msg.sender].push(_orderId);

		orderIdMapping[_orderId] = Order({
			tokenX: tokenX,
			tokenY: tokenY,
			tokenXAmount: tokenXAmount,
			desiredTokenYAmount: desiredTokenYAmount,
			maker: msg.sender
		});
		
		orderBooks[tokenX][tokenY].push(_orderId);
	}


	/// Create a minimum limit order with specified desiredTokenYAmount. Only works if tokenX is WETH.
	/// TODO: Decide whether or not to update desiredTokenYAmount if tokenX has transfer taxes
	function createETHLimitOrderWithDesiredTokenYAmount(address tokenX, address tokenY, uint256 tokenXAmount, uint256 desiredTokenYAmount) external payable nonReentrant returns (uint256 _orderId) {
		IWETH weth = IWETH(address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6));
		if (tokenXAmount == 0 || desiredTokenYAmount == 0 || tokenX != address(weth) || tokenY == address(0)) revert InvalidOrder();
		if (msg.value != tokenXAmount) revert InvalidOrder();
		weth.deposit{value:msg.value}();
		
		_orderId = ++ORDER_ID;
		orderIdsByMaker[msg.sender].push(_orderId);

		orderIdMapping[_orderId] = Order({
			tokenX: tokenX,
			tokenY: tokenY,
			tokenXAmount: tokenXAmount,
			desiredTokenYAmount: desiredTokenYAmount,
			maker: msg.sender
		});
		
		orderBooks[tokenX][tokenY].push(_orderId);
	}

	/// Fullfill orders by given orderIds based on exact tokenYAmount.
	function fulfillOrdersWithExactTokenYAmount(address tokenX, address tokenY, uint256 tokenYAmount, uint256 minTokenXAmountOut, uint256[] calldata orderIds) external nonReentrant {
		if (tokenYAmount == 0) revert InvalidOrder();		
		{
			uint256 preBalance = IERC20(tokenY).balanceOf(address(this));
			if (!IERC20(tokenY).transferFrom(msg.sender, address(this), tokenYAmount)) revert TransferFailed();
			tokenYAmount = IERC20(tokenY).balanceOf(address(this)) - preBalance;
		}

		uint256 totalTokenXAmount = fulfillOrdersWithExactTokenYAmountHelper(tokenX, tokenY, tokenYAmount, orderIds);
		
		if (totalTokenXAmount < minTokenXAmountOut) revert InsufficientMarketDepth();
		if (!IERC20(tokenX).transfer(msg.sender, totalTokenXAmount)) revert TransferFailed();
	}

	/// Internal helper to avoid stack too deep error
	function fulfillOrdersWithExactTokenYAmountHelper(address tokenX, address tokenY, uint256 remainingTokenYAmount, uint256[] calldata orderIds) internal returns (uint256 totalTokenXAmount) {	
		uint256 currOrderDesiredTokenYAmount;
		for (uint256 i; i < orderIds.length; i++) {
			Order storage currOrder = orderIdMapping[orderIds[i]];
			if (currOrder.tokenX != tokenX || currOrder.tokenY != tokenY) revert InvalidOrder();
			currOrderDesiredTokenYAmount = currOrder.desiredTokenYAmount;
			if (currOrderDesiredTokenYAmount == 0) revert OrderDoesNotExist();

			if (currOrderDesiredTokenYAmount >= remainingTokenYAmount) {
				uint256 tokenXAmount = remainingTokenYAmount * currOrder.tokenXAmount / currOrderDesiredTokenYAmount;
				totalTokenXAmount += tokenXAmount;
				if (currOrderDesiredTokenYAmount == remainingTokenYAmount) {
					if (!IERC20(tokenY).transfer(currOrder.maker, remainingTokenYAmount)) revert TransferFailed();
					delete orderIdMapping[orderIds[i]];
				} else {
					currOrder.tokenXAmount -= tokenXAmount;
					currOrder.desiredTokenYAmount -= remainingTokenYAmount;
					if (!IERC20(tokenY).transfer(currOrder.maker, remainingTokenYAmount)) revert TransferFailed();
				}
				break;
			} else {
				totalTokenXAmount += currOrder.tokenXAmount;
				remainingTokenYAmount -= currOrderDesiredTokenYAmount;
				if (!IERC20(tokenY).transfer(currOrder.maker, currOrderDesiredTokenYAmount)) revert TransferFailed();
				delete orderIdMapping[orderIds[i]];
			}
		}
	}

	/// Fullfill orders by given orderIds based on exact tokenXAmountOut.
	function fulfillOrdersWithExactTokenXAmountOut(address tokenX, address tokenY, uint256 exactTokenXAmountOut, uint256 maxTokenYAmount, uint256[] calldata orderIds) external nonReentrant {
		if (maxTokenYAmount == 0) revert InvalidOrder();		
		{
			uint256 preBalance = IERC20(tokenY).balanceOf(address(this));
			if (!IERC20(tokenY).transferFrom(msg.sender, address(this), maxTokenYAmount)) revert TransferFailed();
			maxTokenYAmount = IERC20(tokenY).balanceOf(address(this)) - preBalance;
		}

		uint256 totalTokenYAmount = fulfillOrdersWithExactTokenXAmountOutHelper(tokenX, tokenY, exactTokenXAmountOut, orderIds);

		if (totalTokenYAmount > maxTokenYAmount) revert TooLittleTokenYReceived();
		if (totalTokenYAmount != maxTokenYAmount) {
			if (!IERC20(tokenY).transfer(msg.sender, maxTokenYAmount-totalTokenYAmount)) revert TransferFailed();
		}

		if (!IERC20(tokenX).transfer(msg.sender, exactTokenXAmountOut)) revert TransferFailed();
	}

	/// Internal helper to avoid stack too deep error
	function fulfillOrdersWithExactTokenXAmountOutHelper(address tokenX, address tokenY, uint256 remainingTokenXAmount, uint256[] calldata orderIds) internal returns (uint256 totalTokenYAmount) {	
		uint256 currOrderTokenXAmount;
		uint256 currOrderTokenYAmount;
		for (uint256 i; i < orderIds.length; i++) {
			Order storage currOrder = orderIdMapping[orderIds[i]];
			if (currOrder.tokenX != tokenX || currOrder.tokenY != tokenY) revert InvalidOrder();
			currOrderTokenXAmount = currOrder.tokenXAmount;
			if (currOrderTokenXAmount == 0) revert OrderDoesNotExist();

			if (currOrderTokenXAmount >= remainingTokenXAmount) {
				uint256 tokenYAmount = remainingTokenXAmount * currOrder.desiredTokenYAmount / currOrderTokenXAmount;
				totalTokenYAmount += tokenYAmount;
				if (currOrderTokenXAmount == remainingTokenXAmount) {
					if (!IERC20(tokenY).transfer(currOrder.maker, tokenYAmount)) revert TransferFailed();
					delete orderIdMapping[orderIds[i]];
				} else {
					currOrder.tokenXAmount -= remainingTokenXAmount;
					currOrder.desiredTokenYAmount -= tokenYAmount;
					if (!IERC20(tokenY).transfer(currOrder.maker, tokenYAmount)) revert TransferFailed();
				}
				break;
			} else {
				currOrderTokenYAmount = currOrder.desiredTokenYAmount;
				totalTokenYAmount += currOrderTokenYAmount;
				remainingTokenXAmount -= currOrderTokenXAmount;
				if (!IERC20(tokenY).transfer(currOrder.maker, currOrderTokenYAmount)) revert TransferFailed();
				delete orderIdMapping[orderIds[i]];
			}
		}
	}



	/// Withdraw orders by ids
	function withdrawOrders(uint256[] calldata orderIds) external nonReentrant {
		address currOrderMaker;
		for (uint256 i; i < orderIds.length; i++) {
			Order storage currOrder = orderIdMapping[orderIds[i]];
			currOrderMaker = currOrder.maker;
			if (currOrderMaker != msg.sender) revert UnauthorizedWithdrawal();

			if (!IERC20(currOrder.tokenX).transfer(currOrderMaker, currOrder.tokenXAmount)) revert TransferFailed();
			delete orderIdMapping[orderIds[i]];
		}
	}

	/// Withdraw all open orders for caller
	function withdrawAllOpenOrders() external nonReentrant {
		uint256[] memory orderIds = orderIdsByMaker[msg.sender];
		address currOrderMaker;
		for (uint256 i; i < orderIds.length; i++) {
			Order storage currOrder = orderIdMapping[orderIds[i]];
			currOrderMaker = currOrder.maker;
			if (currOrderMaker != msg.sender) continue; //already withdrawn or fulfilled

			if (!IERC20(currOrder.tokenX).transfer(currOrderMaker, currOrder.tokenXAmount)) revert TransferFailed();
			delete orderIdMapping[orderIds[i]];
		}
		delete orderIdsByMaker[msg.sender];
	}




	///BEGINNING OF READ-ONLY FUNCTIONS


	/// Get tokenX amount out based on tokenYAmount for fullfilling given orders
	function getTokenXOut(address tokenX, address tokenY, uint256 tokenYAmount, uint256[] calldata orderIds) external view returns (uint256) {
		uint256 totalTokenXAmount;
		uint256 remainingTokenYAmount = tokenYAmount;
		for (uint256 i; i < orderIds.length; i++) {
			Order memory currOrder = orderIdMapping[orderIds[i]];
			if (currOrder.tokenX != tokenX || currOrder.tokenY != tokenY) revert InvalidOrder();
			if (currOrder.desiredTokenYAmount >= remainingTokenYAmount) {
				uint256 tokenXAmount = remainingTokenYAmount * currOrder.tokenXAmount / currOrder.desiredTokenYAmount;
				totalTokenXAmount += tokenXAmount;
				break;
			} else {
				totalTokenXAmount += currOrder.tokenXAmount;
				remainingTokenYAmount -= currOrder.desiredTokenYAmount;
			}
		}

		return totalTokenXAmount;
	}

	/// Get required tokenY amount based on tokenXAmountOut for fullfilling given orders
	function getRequiredTokenYAmount(address tokenX, address tokenY, uint256 tokenXAmountOut, uint256[] calldata orderIds) external view returns (uint256) {
		uint256 totalTokenYAmount;
		uint256 remainingTokenXAmount = tokenXAmountOut;
		for (uint256 i; i < orderIds.length; i++) {
			Order memory currOrder = orderIdMapping[orderIds[i]];
			if (currOrder.tokenX != tokenX || currOrder.tokenY != tokenY) revert InvalidOrder();
			if (currOrder.tokenXAmount >= remainingTokenXAmount) {
				uint256 tokenYAmount = remainingTokenXAmount * currOrder.desiredTokenYAmount / currOrder.tokenXAmount;
				totalTokenYAmount += tokenYAmount;
				break;
			} else {
				totalTokenYAmount += currOrder.desiredTokenYAmount;
				remainingTokenXAmount -= currOrder.tokenXAmount;
			}
		}

		return totalTokenYAmount;
	}

	/// Get all orders created for pair
	function getOrdersForPair(address tokenX, address tokenY) external view returns (uint256[] memory) {
		return orderBooks[tokenX][tokenY];
	}

	/// Get order by order id
	function getOrderById(uint256 orderId) external view returns (Order memory _order) {
		_order = orderIdMapping[orderId];
	}

	/// Get orders by maker address
	function getOrderIdsByMaker(address maker) external view returns (uint256[] memory _orderIds) {
		_orderIds = orderIdsByMaker[maker];
	}

}