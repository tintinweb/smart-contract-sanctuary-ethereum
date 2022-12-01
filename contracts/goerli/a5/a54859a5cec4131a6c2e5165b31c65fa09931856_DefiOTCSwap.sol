/**
 *Submitted for verification at Etherscan.io on 2022-12-01
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


contract DefiOTCSwap is ReentrancyGuard {

	uint96 public ORDER_ID;

	struct Order {
		address tokenX;
		uint96 next;
		address tokenY;
		uint96 prev;
		uint256 tokenXAmount;
		uint256 desiredTokenYAmount;
		address maker;
	}

	mapping(uint256 => Order) public orderIdMapping;
	mapping(address => uint256[]) public orderIdsByMaker;
	mapping(address => mapping(address => uint96)) public orderBooks;

	/// No other orders exist for creation of minimum order
	error NoOtherOrdersExistForAutoMinimumOrder();
	/// No orders exist to fulfill
	error NoOrdersExist();
	/// No order exists for id
	error OrderDoesNotExist();
	/// Unauthorized withdrawal
	error UnauthorizedWithdrawal();
	/// Invalid order
	error InvalidOrder();
	/// Insufficient market depth
	error InsufficientMarketDepth();
	/// Desired tokenYAmount exceeds current minimum order
	error DesiredTokenYAmountExceedsMinimum();
	/// Token transfer failed
	error TransferFailed();
	/// Too little tokenY received
	error TooLittleTokenYReceived();




	/// Create a minimum limit order, automatically chooses desiredTokenYAmount based on current minimum order
	function createLimitOrderAuto(address tokenX, address tokenY, uint256 tokenXAmount) external nonReentrant returns (uint96 _orderId) {
		if (tokenXAmount == 0 || tokenX == address(0) || tokenY == address(0)) revert InvalidOrder();

		IERC20 tokenXLoaded = IERC20(tokenX);
		uint256 preBalance = tokenXLoaded.balanceOf(address(this));
		if (!tokenXLoaded.transferFrom(msg.sender, address(this), tokenXAmount)) revert TransferFailed();
		tokenXAmount = tokenXLoaded.balanceOf(address(this)) - preBalance;

		_orderId = ++ORDER_ID;
		orderIdsByMaker[msg.sender].push(_orderId);
		uint96 currMinOrderId = orderBooks[tokenX][tokenY];
		if (currMinOrderId == 0) revert NoOtherOrdersExistForAutoMinimumOrder();

		Order storage minOrder = orderIdMapping[currMinOrderId];
		orderIdMapping[_orderId] = Order({
			tokenX: tokenX,
			tokenY: tokenY,
			tokenXAmount: tokenXAmount,
			desiredTokenYAmount: tokenXAmount * minOrder.desiredTokenYAmount / minOrder.tokenXAmount - 1,
			maker: msg.sender,
			next: currMinOrderId,
			prev: 0
		});

		minOrder.prev = _orderId;
		orderBooks[tokenX][tokenY] = _orderId;
	}

	/// Create a minimum limit order with specified desiredTokenYAmount
	/// TODO: Decide whether or not to update desiredTokenYAmount if tokenX has transfer taxes
	function createLimitOrderWithDesiredTokenYAmount(address tokenX, address tokenY, uint256 tokenXAmount, uint256 desiredTokenYAmount) external nonReentrant returns (uint96 _orderId) {
		if (tokenXAmount == 0 || desiredTokenYAmount == 0 || tokenX == address(0) || tokenY == address(0)) revert InvalidOrder();
		
		IERC20 tokenXLoaded = IERC20(tokenX);
		uint256 preBalance = tokenXLoaded.balanceOf(address(this));
		if (!tokenXLoaded.transferFrom(msg.sender, address(this), tokenXAmount)) revert TransferFailed();
		tokenXAmount = tokenXLoaded.balanceOf(address(this)) - preBalance;

		_orderId = ++ORDER_ID;
		orderIdsByMaker[msg.sender].push(_orderId);

		uint96 currOrderId = orderBooks[tokenX][tokenY];
		uint96 prevOrderId;
		while (currOrderId != 0) {
			Order storage currOrder = orderIdMapping[currOrderId];
			if ((currOrder.tokenXAmount * desiredTokenYAmount / currOrder.desiredTokenYAmount) < tokenXAmount) {
				orderIdMapping[_orderId] = Order({
					tokenX: tokenX,
					tokenY: tokenY,
					tokenXAmount: tokenXAmount,
					desiredTokenYAmount: desiredTokenYAmount,
					maker: msg.sender,
					next: currOrderId,
					prev: prevOrderId
				});
				if (prevOrderId == 0) {
					orderBooks[tokenX][tokenY] = _orderId;
				} else {
					orderIdMapping[prevOrderId].next = _orderId;
				}
				currOrder.prev = _orderId;
				break;
			}
			prevOrderId = currOrderId;
			currOrderId = currOrder.next;
		}

		if (currOrderId == 0) {
			orderIdMapping[_orderId] = Order({
				tokenX: tokenX,
				tokenY: tokenY,
				tokenXAmount: tokenXAmount,
				desiredTokenYAmount: desiredTokenYAmount,
				maker: msg.sender,
				next: 0,
				prev: prevOrderId
			});
			if (prevOrderId != 0) orderIdMapping[prevOrderId].next = _orderId;
		}
	}

	/// Create a minimum limit order, automatically chooses desiredTokenYAmount based on current minimum order. Only works if tokenX is WETH.
	function createETHLimitOrderAuto(address tokenX, address tokenY, uint256 tokenXAmount) external payable nonReentrant returns (uint96 _orderId) {
		address weth = address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
		if (tokenXAmount == 0 || tokenX != address(weth) || tokenY == address(0)) revert InvalidOrder();
		if (msg.value != tokenXAmount) revert InvalidOrder();
		IWETH(weth).deposit{value:msg.value}();

		_orderId = ++ORDER_ID;
		orderIdsByMaker[msg.sender].push(_orderId);
		uint96 currMinOrderId = orderBooks[tokenX][tokenY];
		if (currMinOrderId == 0) revert NoOtherOrdersExistForAutoMinimumOrder();

		Order storage minOrder = orderIdMapping[currMinOrderId];
		orderIdMapping[_orderId] = Order({
			tokenX: tokenX,
			tokenY: tokenY,
			tokenXAmount: tokenXAmount,
			desiredTokenYAmount: tokenXAmount * minOrder.desiredTokenYAmount / minOrder.tokenXAmount - 1,
			maker: msg.sender,
			next: currMinOrderId,
			prev: 0
		});

		minOrder.prev = _orderId;
		orderBooks[tokenX][tokenY] = _orderId;
	}

	/// Create a minimum limit order with specified desiredTokenYAmount. Only works if tokenx is WETH.
	/// TODO: Decide whether or not to update desiredTokenYAmount if tokenX has transfer taxes
	function createETHLimitOrderWithDesiredTokenYAmount(address tokenX, address tokenY, uint256 tokenXAmount, uint256 desiredTokenYAmount) external payable nonReentrant returns (uint96 _orderId) {
		IWETH weth = IWETH(address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6));
		if (tokenXAmount == 0 || desiredTokenYAmount == 0 || tokenX != address(weth) || tokenY == address(0)) revert InvalidOrder();
		if (msg.value != tokenXAmount) revert InvalidOrder();
		weth.deposit{value:msg.value}();
		
		_orderId = ++ORDER_ID;
		orderIdsByMaker[msg.sender].push(_orderId);

		uint96 currOrderId = orderBooks[tokenX][tokenY];
		uint96 prevOrderId;
		while (currOrderId != 0) {
			Order storage currOrder = orderIdMapping[currOrderId];
			if ((currOrder.tokenXAmount * desiredTokenYAmount / currOrder.desiredTokenYAmount) < tokenXAmount) {
				orderIdMapping[_orderId] = Order({
					tokenX: tokenX,
					tokenY: tokenY,
					tokenXAmount: tokenXAmount,
					desiredTokenYAmount: desiredTokenYAmount,
					maker: msg.sender,
					next: currOrderId,
					prev: prevOrderId
				});
				if (prevOrderId == 0) {
					orderBooks[tokenX][tokenY] = _orderId;
				} else {
					orderIdMapping[prevOrderId].next = _orderId;
				}
				currOrder.prev = _orderId;
				break;
			}
			prevOrderId = currOrderId;
			currOrderId = currOrder.next;
		}

		if (currOrderId == 0) {
			orderIdMapping[_orderId] = Order({
				tokenX: tokenX,
				tokenY: tokenY,
				tokenXAmount: tokenXAmount,
				desiredTokenYAmount: desiredTokenYAmount,
				maker: msg.sender,
				next: 0,
				prev: prevOrderId
			});
			if (prevOrderId != 0) orderIdMapping[prevOrderId].next = _orderId;
		}
	}

	/// Swap exact tokenY for tokenX, makes sure tokenXOut is at least minTokenXAmountOut.
	function swapExactTokenYforTokenX(address tokenX, address tokenY, uint256 tokenYAmount, uint256 minTokenXAmountOut) external nonReentrant {
		if (tokenYAmount == 0 || minTokenXAmountOut == 0) revert InvalidOrder();
		IERC20 tokenYLoaded = IERC20(tokenY);
		uint256 preBalance = tokenYLoaded.balanceOf(address(this));
		if (!tokenYLoaded.transferFrom(msg.sender, address(this), tokenYAmount)) revert TransferFailed();
		tokenYAmount = tokenYLoaded.balanceOf(address(this)) - preBalance;

		uint96 currOrderId = orderBooks[tokenX][tokenY];
		if (currOrderId == 0) revert NoOrdersExist();

		uint256 totalTokenXAmount;
		uint256 remainingTokenYAmount = tokenYAmount;
		uint96 currOrderNext;
		bool isLastOrderDeleted;
		while (currOrderId != 0) {
			Order storage currOrder = orderIdMapping[currOrderId];
			uint256 currOrderDesiredTokenYAmount = currOrder.desiredTokenYAmount;
			currOrderNext = currOrder.next;
			if (currOrderDesiredTokenYAmount >= remainingTokenYAmount) {
				uint256 tokenXAmount = remainingTokenYAmount * currOrder.tokenXAmount / currOrderDesiredTokenYAmount;
				totalTokenXAmount += tokenXAmount;
				if (currOrderDesiredTokenYAmount == remainingTokenYAmount) {
					orderIdMapping[currOrderNext].prev = 0;
					delete orderIdMapping[currOrderId];
					isLastOrderDeleted = true;
				} else {
					currOrder.tokenXAmount -= tokenXAmount;
					currOrder.desiredTokenYAmount -= remainingTokenYAmount;
				}
				if (!tokenYLoaded.transfer(currOrder.maker, remainingTokenYAmount)) revert TransferFailed();
				break;
			} else {
				totalTokenXAmount += currOrder.tokenXAmount;
				remainingTokenYAmount -= currOrderDesiredTokenYAmount;
				if (!tokenYLoaded.transfer(currOrder.maker, currOrderDesiredTokenYAmount)) revert TransferFailed();
				orderIdMapping[currOrderNext].prev = 0;
				delete orderIdMapping[currOrderId];
			}
			currOrderId = currOrderNext;
		}

		IERC20 tokenXLoaded = IERC20(tokenX);
		uint256 preTokenXBalance = tokenXLoaded.balanceOf(msg.sender);
		if (!tokenXLoaded.transfer(msg.sender, totalTokenXAmount)) revert TransferFailed();
		if (currOrderId == 0 || (tokenXLoaded.balanceOf(msg.sender) - preTokenXBalance) < minTokenXAmountOut) revert InsufficientMarketDepth();

		if (isLastOrderDeleted) orderBooks[tokenX][tokenY] = currOrderNext;
		else orderBooks[tokenX][tokenY] = currOrderId;
	}

	/// Swap tokenY for exact tokenX specified by exactTokenXAmountOut, makes sure required tokenY doesn't exceed maxTokenYAmount, and issues refund when maxTokenYAmount is higher than necessary.
	function swapTokenYforExactTokenX(address tokenX, address tokenY, uint256 maxTokenYAmount, uint256 exactTokenXAmountOut) external nonReentrant {
		if (maxTokenYAmount == 0 || exactTokenXAmountOut == 0) revert InvalidOrder();
		IERC20 tokenYLoaded = IERC20(tokenY);
		uint256 preBalance = tokenYLoaded.balanceOf(address(this));
		if (!tokenYLoaded.transferFrom(msg.sender, address(this), maxTokenYAmount)) revert TransferFailed();
		maxTokenYAmount = tokenYLoaded.balanceOf(address(this)) - preBalance;

		uint96 currOrderId = orderBooks[tokenX][tokenY];
		if (currOrderId == 0) revert NoOrdersExist();

		uint256 totalTokenYAmount;
		uint256 remainingTokenXAmount = exactTokenXAmountOut;
		uint96 currOrderNext;
		bool isLastOrderDeleted;
		while (currOrderId != 0) {
			Order storage currOrder = orderIdMapping[currOrderId];
			uint256 currOrderTokenXAmount = currOrder.tokenXAmount;
			currOrderNext = currOrder.next;

			if (currOrderTokenXAmount >= remainingTokenXAmount) {
				uint256 tokenYAmount = remainingTokenXAmount * currOrder.desiredTokenYAmount / currOrderTokenXAmount;
				totalTokenYAmount += tokenYAmount;
				if (currOrderTokenXAmount == remainingTokenXAmount) {
					orderIdMapping[currOrderNext].prev = 0;
					delete orderIdMapping[currOrderId];
					isLastOrderDeleted = true;
				} else {
					currOrder.tokenXAmount -= remainingTokenXAmount;
					currOrder.desiredTokenYAmount -= tokenYAmount;
				}
				if (!tokenYLoaded.transfer(currOrder.maker, tokenYAmount)) revert TransferFailed();
				break;
			} else {
				uint256 currOrderTokenYAmount = currOrder.desiredTokenYAmount;
				totalTokenYAmount += currOrderTokenYAmount;
				remainingTokenXAmount -= currOrderTokenXAmount;
				if (!tokenYLoaded.transfer(currOrder.maker, currOrderTokenYAmount)) revert TransferFailed();
				orderIdMapping[currOrderNext].prev = 0;
				delete orderIdMapping[currOrderId];
			}
			currOrderId = currOrderNext;
		}

		if (currOrderId == 0) revert InsufficientMarketDepth();
		if (totalTokenYAmount > maxTokenYAmount) revert TooLittleTokenYReceived();
		if (totalTokenYAmount != maxTokenYAmount) {
			if (!tokenYLoaded.transfer(msg.sender, maxTokenYAmount-totalTokenYAmount)) revert TransferFailed();
		}

		IERC20 tokenXLoaded = IERC20(tokenX);
		if (!tokenXLoaded.transfer(msg.sender, exactTokenXAmountOut)) revert TransferFailed();

		if (isLastOrderDeleted) orderBooks[tokenX][tokenY] = currOrderNext;
		else orderBooks[tokenX][tokenY] = currOrderId;
	}

	/// Swap exact ETH for tokenX, makes sure tokenXOut is at least minTokenXAmountOut. Works only if tokenY is WETH.
	function swapExactETHforTokenX(address tokenX, address tokenY, uint256 tokenYAmount, uint256 minTokenXAmountOut) external payable nonReentrant {
		if (tokenYAmount == 0 || minTokenXAmountOut == 0) revert InvalidOrder();
		IWETH weth = IWETH(address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6));
		if (msg.value != tokenYAmount || tokenY != address(weth)) revert InvalidOrder();
		weth.deposit{value:msg.value}();

		IERC20 tokenYLoaded = IERC20(tokenY);

		uint96 currOrderId = orderBooks[tokenX][tokenY];
		if (currOrderId == 0) revert NoOrdersExist();

		uint256 totalTokenXAmount;
		uint256 remainingTokenYAmount = tokenYAmount;
		uint96 currOrderNext;
		bool isLastOrderDeleted;
		while (currOrderId != 0) {
			Order storage currOrder = orderIdMapping[currOrderId];
			uint256 currOrderDesiredTokenYAmount = currOrder.desiredTokenYAmount;
			currOrderNext = currOrder.next;
			if (currOrderDesiredTokenYAmount >= remainingTokenYAmount) {
				uint256 tokenXAmount = remainingTokenYAmount * currOrder.tokenXAmount / currOrderDesiredTokenYAmount;
				totalTokenXAmount += tokenXAmount;
				if (currOrderDesiredTokenYAmount == remainingTokenYAmount) {
					orderIdMapping[currOrderNext].prev = 0;
					delete orderIdMapping[currOrderId];
					isLastOrderDeleted = true;
				} else {
					currOrder.tokenXAmount -= tokenXAmount;
					currOrder.desiredTokenYAmount -= remainingTokenYAmount;
				}
				if (!tokenYLoaded.transfer(currOrder.maker, remainingTokenYAmount)) revert TransferFailed();
				break;
			} else {
				totalTokenXAmount += currOrder.tokenXAmount;
				remainingTokenYAmount -= currOrderDesiredTokenYAmount;
				if (!tokenYLoaded.transfer(currOrder.maker, currOrderDesiredTokenYAmount)) revert TransferFailed();
				orderIdMapping[currOrderNext].prev = 0;
				delete orderIdMapping[currOrderId];
			}
			currOrderId = currOrderNext;
		}

		IERC20 tokenXLoaded = IERC20(tokenX);
		uint256 preTokenXBalance = tokenXLoaded.balanceOf(msg.sender);
		if (!tokenXLoaded.transfer(msg.sender, totalTokenXAmount)) revert TransferFailed();
		if (currOrderId == 0 || (tokenXLoaded.balanceOf(msg.sender) - preTokenXBalance) < minTokenXAmountOut) revert InsufficientMarketDepth();

		if (isLastOrderDeleted) orderBooks[tokenX][tokenY] = currOrderNext;
		else orderBooks[tokenX][tokenY] = currOrderId;
	}

	/// Swap tokenY for exact tokenX specified by exactTokenXAmountOut, makes sure required tokenY doesn't exceed maxTokenYAmount, and issues refund when maxTokenYAmount is higher than necessary.
	/// Only works when tokenY is WETH.
	function swapETHforExactTokenX(address tokenX, address tokenY, uint256 maxTokenYAmount, uint256 exactTokenXAmountOut) external payable nonReentrant {
		if (maxTokenYAmount == 0 || exactTokenXAmountOut == 0) revert InvalidOrder();
		IWETH weth = IWETH(address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6));
		if (msg.value != maxTokenYAmount || tokenY != address(weth)) revert InvalidOrder();
		weth.deposit{value:msg.value}();

		IERC20 tokenYLoaded = IERC20(tokenY);

		uint96 currOrderId = orderBooks[tokenX][tokenY];
		if (currOrderId == 0) revert NoOrdersExist();

		uint256 totalTokenYAmount;
		uint256 remainingTokenXAmount = exactTokenXAmountOut;
		uint96 currOrderNext;
		bool isLastOrderDeleted;
		while (currOrderId != 0) {
			Order storage currOrder = orderIdMapping[currOrderId];
			uint256 currOrderTokenXAmount = currOrder.tokenXAmount;
			currOrderNext = currOrder.next;

			if (currOrderTokenXAmount >= remainingTokenXAmount) {
				uint256 tokenYAmount = remainingTokenXAmount * currOrder.desiredTokenYAmount / currOrderTokenXAmount;
				totalTokenYAmount += tokenYAmount;
				if (currOrderTokenXAmount == remainingTokenXAmount) {
					orderIdMapping[currOrderNext].prev = 0;
					delete orderIdMapping[currOrderId];
					isLastOrderDeleted = true;
				} else {
					currOrder.tokenXAmount -= remainingTokenXAmount;
					currOrder.desiredTokenYAmount -= tokenYAmount;
				}
				if (!tokenYLoaded.transfer(currOrder.maker, tokenYAmount)) revert TransferFailed();
				break;
			} else {
				uint256 currOrderTokenYAmount = currOrder.desiredTokenYAmount;
				totalTokenYAmount += currOrderTokenYAmount;
				remainingTokenXAmount -= currOrderTokenXAmount;
				if (!tokenYLoaded.transfer(currOrder.maker, currOrderTokenYAmount)) revert TransferFailed();
				orderIdMapping[currOrderNext].prev = 0;
				delete orderIdMapping[currOrderId];
			}
			currOrderId = currOrderNext;
		}

		if (currOrderId == 0) revert InsufficientMarketDepth();
		if (totalTokenYAmount > maxTokenYAmount) revert TooLittleTokenYReceived();
		if (totalTokenYAmount != maxTokenYAmount) {
			if (!tokenYLoaded.transfer(msg.sender, maxTokenYAmount-totalTokenYAmount)) revert TransferFailed();
		}

		IERC20 tokenXLoaded = IERC20(tokenX);
		if (!tokenXLoaded.transfer(msg.sender, exactTokenXAmountOut)) revert TransferFailed();

		if (isLastOrderDeleted) orderBooks[tokenX][tokenY] = currOrderNext;
		else orderBooks[tokenX][tokenY] = currOrderId;
	}


	/// Fullfill order by id supporting fee on tokenY transfers.
	function fulfillOrderById(uint96 orderId, uint256 tokenYAmount) external nonReentrant {
		Order storage order = orderIdMapping[orderId];
		uint256 orderDesiredTokenYAmount = order.desiredTokenYAmount;
		uint256 orderTokenXAmount = order.tokenXAmount;
		address tokenY = order.tokenY;
		address tokenX = order.tokenX;

		if (tokenYAmount == 0) revert InvalidOrder();
		if (order.maker == address(0) || tokenX == address(0) || tokenY == address(0) || orderTokenXAmount == 0 || orderDesiredTokenYAmount == 0) revert OrderDoesNotExist();

		IERC20 tokenYLoaded = IERC20(tokenY);
		uint256 preBalance = tokenYLoaded.balanceOf(address(this));
		if (!tokenYLoaded.transferFrom(msg.sender, address(this), tokenYAmount)) revert TransferFailed();
		tokenYAmount = tokenYLoaded.balanceOf(address(this)) - preBalance;
		if (orderDesiredTokenYAmount < tokenYAmount) revert InsufficientMarketDepth();

		uint256 tokenXAmount = tokenYAmount * order.tokenXAmount / order.desiredTokenYAmount;
		if (!tokenYLoaded.transfer(order.maker, tokenYAmount)) revert TransferFailed();
		if (!IERC20(tokenX).transfer(msg.sender, tokenXAmount)) revert TransferFailed();

		if (tokenXAmount == order.tokenXAmount) {
			if (order.prev != 0) orderIdMapping[order.prev].next = order.next;
			else orderBooks[order.tokenX][order.tokenY] = order.next;
			orderIdMapping[order.next].prev = order.prev;
			delete orderIdMapping[orderId];
		} else {
			order.desiredTokenYAmount -= tokenYAmount;
			order.tokenXAmount -= tokenXAmount;
		}
	}

	/// Withdraw order by id
	function withdrawOrderById(uint96 orderId) external nonReentrant {
		Order memory order = orderIdMapping[orderId];
		if (order.maker != msg.sender) revert UnauthorizedWithdrawal();

		if (order.prev != 0) orderIdMapping[order.prev].next = order.next;
		else orderBooks[order.tokenX][order.tokenY] = order.next;
		orderIdMapping[order.next].prev = order.prev;

		delete orderIdMapping[orderId];
		if (!IERC20(order.tokenX).transfer(order.maker, order.tokenXAmount)) revert TransferFailed();
	}

	/// Withdraw all open orders for caller
	function withdrawAllOpenOrders() external nonReentrant {
		uint256[] memory orderIds = orderIdsByMaker[msg.sender];
		for (uint256 i; i<orderIds.length; i++) {
			Order memory order = orderIdMapping[orderIds[i]];
			if (order.maker == address(0) || order.tokenX == address(0) || order.tokenY == address(0) || order.tokenXAmount == 0 || order.desiredTokenYAmount == 0) continue;

			if (order.prev != 0) orderIdMapping[order.prev].next = order.next;
			else orderBooks[order.tokenX][order.tokenY] = order.next;
			orderIdMapping[order.next].prev = order.prev;

			delete orderIdMapping[orderIds[i]];
			if (!IERC20(order.tokenX).transfer(order.maker, order.tokenXAmount)) revert TransferFailed();
		}
		delete orderIdsByMaker[msg.sender];
	}




	///BEGINNING OF READ-ONLY FUNCTIONS


	/// Get tokenX amount out based on tokenYAmount for fullfilling minimum orders
	function getTokenXOutForTokenYAmount(address tokenX, address tokenY, uint256 tokenYAmount) external view returns (uint256) {
		if (tokenYAmount == 0) revert InvalidOrder();

		uint96 currOrderId = orderBooks[tokenX][tokenY];
		if (currOrderId == 0) revert NoOrdersExist();

		uint256 totalTokenXAmount;
		uint256 remainingTokenYAmount = tokenYAmount;
		while (currOrderId != 0) {
			Order memory currOrder = orderIdMapping[currOrderId];
			if (currOrder.desiredTokenYAmount >= remainingTokenYAmount) {
				uint256 tokenXAmount = remainingTokenYAmount * currOrder.tokenXAmount / currOrder.desiredTokenYAmount;
				totalTokenXAmount += tokenXAmount;
				break;
			} else {
				totalTokenXAmount += currOrder.tokenXAmount;
				remainingTokenYAmount -= currOrder.desiredTokenYAmount;
			}
			currOrderId = currOrder.next;
		}
		if (currOrderId == 0) revert InsufficientMarketDepth();

		return totalTokenXAmount;
	}

	/// Get required tokenY amount out based on tokenXAmount for fullfilling minimum orders
	function getRequiredTokenYAmountForTokenXOut(address tokenX, address tokenY, uint256 tokenXOut) external view returns (uint256) {
		if (tokenXOut == 0) revert InvalidOrder();

		uint96 currOrderId = orderBooks[tokenX][tokenY];
		if (currOrderId == 0) revert NoOrdersExist();

		uint256 totalTokenYAmount;
		uint256 remainingTokenXAmount = tokenXOut;
		while (currOrderId != 0) {
			Order memory currOrder = orderIdMapping[currOrderId];
			if (currOrder.tokenXAmount >= remainingTokenXAmount) {
				uint256 tokenYAmount = remainingTokenXAmount * currOrder.desiredTokenYAmount / currOrder.tokenXAmount;
				totalTokenYAmount += tokenYAmount;
				break;
			} else {
				totalTokenYAmount += currOrder.desiredTokenYAmount;
				remainingTokenXAmount -= currOrder.tokenXAmount;
			}
			currOrderId = currOrder.next;
		}
		if (currOrderId == 0) revert InsufficientMarketDepth();

		return totalTokenYAmount;
	}

	/// Get minimum order id for pair
	function getMinimumOrderIdForPair(address tokenX, address tokenY) external view returns (uint96) {
		return orderBooks[tokenX][tokenY];
	}

	/// Get minimum order for pair
	function getMinimumOrderForPair(address tokenX, address tokenY) external view returns (Order memory) {
		return orderIdMapping[orderBooks[tokenX][tokenY]];
	}

	/// Get order by order id
	function getOrderById(uint96 orderId) external view returns (Order memory _order) {
		_order = orderIdMapping[orderId];
	}

	/// Get next order id for given order id
	function getNextOrderId(uint96 orderId) external view returns (uint256 _nextOrderId) {
		_nextOrderId = orderIdMapping[orderId].next;
	}

	/// Get orders by maker address
	function getOrderIdsByMaker(address maker) external view returns (uint256[] memory _orderIds) {
		_orderIds = orderIdsByMaker[maker];
	}

}