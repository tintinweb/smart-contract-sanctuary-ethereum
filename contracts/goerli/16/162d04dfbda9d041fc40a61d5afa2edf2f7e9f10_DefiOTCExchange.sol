/**
 *Submitted for verification at Etherscan.io on 2022-11-21
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


contract DefiOTCExchange is ReentrancyGuard {

    uint256 public ORDER_ID;

    struct Order {
        uint256 tokenXAmount;
        uint256 desiredTokenYAmount;
        address maker;
    }

    mapping(uint256 => Order) public orderIdMapping;
    mapping(address => uint256[]) public orderIdsByMaker;
    mapping(address => mapping(address => uint256[])) public orderBooks;

    /// No other orders exist for creation of minimum order
    error NoOtherOrdersExistForAutoMinimumOrder();
    /// No orders exist to fulfill
    error NoOrdersExist();
    /// Invalid order amounts
    error InvalidOrderAmounts();
    /// Insufficient market depth
    error InsufficientMarketDepth();
    /// Desired tokenYAmount exceeds current minimum order
    error DesiredTokenYAmountExceedsMinimum();
    /// Token transfer failed
    error TransferFailed();


    /// Create a minimum limit order, automatically chooses desiredTokenYAmount based on current minimum order
    function createLimitOrderAuto(address tokenX, address tokenY, uint256 tokenXAmount) external nonReentrant returns (uint256 _orderId) {
        if (tokenXAmount == 0) revert InvalidOrderAmounts();
        if (!IERC20(tokenX).transferFrom(msg.sender, address(this), tokenXAmount)) revert TransferFailed();

        _orderId = ++ORDER_ID;
        uint256[] storage orderIds = orderBooks[tokenX][tokenY];

        if (orderIds.length == 0) revert NoOtherOrdersExistForAutoMinimumOrder();
        else {
            Order memory minOrder = orderIdMapping[orderIds[orderIds.length-1]];
            orderIdMapping[_orderId] = Order({
                tokenXAmount: tokenXAmount,
                desiredTokenYAmount: tokenXAmount * (minOrder.desiredTokenYAmount/minOrder.tokenXAmount) - 1,
                maker: msg.sender
            });
            orderIdsByMaker[msg.sender].push(_orderId);
            orderIds.push(_orderId);
        }
    }

    /// Create a minimum limit order with specified desiredTokenYAmount
    function createLimitOrderWithDesiredTokenYAmount(address tokenX, address tokenY, uint256 tokenXAmount, uint256 desiredTokenYAmount) external nonReentrant returns (uint256 _orderId) {
        if (tokenXAmount == 0 || desiredTokenYAmount == 0) revert InvalidOrderAmounts();
        if (!IERC20(tokenX).transferFrom(msg.sender, address(this), tokenXAmount)) revert TransferFailed();

        _orderId = ++ORDER_ID;
        uint256[] storage orderIds = orderBooks[tokenX][tokenY];

        if (orderIds.length != 0) {
            Order memory minOrder = orderIdMapping[orderIds[orderIds.length-1]];
            if ((minOrder.tokenXAmount/minOrder.desiredTokenYAmount) > (tokenXAmount/desiredTokenYAmount)) revert DesiredTokenYAmountExceedsMinimum();
        }
        orderIdMapping[_orderId] = Order({
            tokenXAmount: tokenXAmount,
            desiredTokenYAmount: desiredTokenYAmount,
            maker: msg.sender
        });
        orderIdsByMaker[msg.sender].push(_orderId);
        orderIds.push(_orderId);
    }


    /// Fulfill minimum order
    function fulfillMinimumOrder(address tokenX, address tokenY, uint256 tokenYAmount) external nonReentrant {
        if (tokenYAmount == 0) revert InvalidOrderAmounts();
        if (!IERC20(tokenY).transferFrom(msg.sender, address(this), tokenYAmount)) revert TransferFailed();

        uint256[] storage orderIds = orderBooks[tokenX][tokenY];
        if (orderIds.length == 0) revert NoOrdersExist();

        Order storage order = orderIdMapping[orderIds[orderIds.length-1]];
        if (order.desiredTokenYAmount < tokenYAmount) revert InsufficientMarketDepth();

        uint256 tokenXAmount = tokenYAmount * (order.tokenXAmount/order.desiredTokenYAmount);
        if (!IERC20(tokenY).transfer(order.maker, tokenYAmount)) revert TransferFailed();
        if (!IERC20(tokenX).transfer(msg.sender, tokenXAmount)) revert TransferFailed();

        if (tokenXAmount - order.tokenXAmount == 0) {
            delete orderIdMapping[orderIds[orderIds.length-1]];
            orderIds.pop();
        } else {
            order.tokenXAmount -= tokenXAmount;
            order.desiredTokenYAmount -= tokenYAmount;
        }
    }

    /// Fulfill minimum orders
    function fulfillMinimumOrders(address tokenX, address tokenY, uint256 tokenYAmount, uint256 minTokenXAmountOut) external nonReentrant {
        if (tokenYAmount == 0 || minTokenXAmountOut == 0) revert InvalidOrderAmounts();
        if (!IERC20(tokenY).transferFrom(msg.sender, address(this), tokenYAmount)) revert TransferFailed();

        uint256[] storage orderIds = orderBooks[tokenX][tokenY];
        if (orderIds.length == 0) revert NoOrdersExist();

        uint256 totalTokenXAmount;
        uint256 remainingTokenYAmount = tokenYAmount;
        for (uint256 i = orderIds.length; i>0; i--) {
            Order storage order = orderIdMapping[orderIds[i-1]];
            if (order.desiredTokenYAmount >= remainingTokenYAmount) {
                uint256 tokenXAmount = remainingTokenYAmount * (order.tokenXAmount/order.desiredTokenYAmount);
                totalTokenXAmount += tokenXAmount;
                order.tokenXAmount -= tokenXAmount;
                order.desiredTokenYAmount -= remainingTokenYAmount;
                if (!IERC20(tokenY).transfer(order.maker, remainingTokenYAmount)) revert TransferFailed();
                break;
            } else {
                totalTokenXAmount += order.tokenXAmount;
                remainingTokenYAmount -= order.desiredTokenYAmount;
                if (!IERC20(tokenY).transfer(order.maker, order.desiredTokenYAmount)) revert TransferFailed();
                orderIds.pop();
            }
        }

        if (totalTokenXAmount < minTokenXAmountOut) revert InsufficientMarketDepth();
    }

    /// Get tokenX amount out for fullfilling minimum order
    function getMinimumOrderTokenXOut(address tokenX, address tokenY, uint256 tokenYAmount) external view returns (uint256 _tokenXAmountOut) {
        if (tokenYAmount == 0) revert InvalidOrderAmounts();

        uint256[] memory orderIds = orderBooks[tokenX][tokenY];
        if (orderIds.length == 0) revert NoOrdersExist();

        Order memory order = orderIdMapping[orderIds[orderIds.length-1]];
        if (order.desiredTokenYAmount < tokenYAmount) revert InsufficientMarketDepth();

        _tokenXAmountOut = tokenYAmount * (order.tokenXAmount/order.desiredTokenYAmount);
    }

    /// Get tokenX amount out for fullfilling minimum orders
    function getMinimumOrdersTokenXOut(address tokenX, address tokenY, uint256 tokenYAmount) external view returns (uint256) {
        if (tokenYAmount == 0) revert InvalidOrderAmounts();

        uint256[] memory orderIds = orderBooks[tokenX][tokenY];
        if (orderIds.length == 0) revert NoOrdersExist();

        uint256 _tokenXAmountOut;
        uint256 remainingTokenYAmount = tokenYAmount;
        for (uint256 i = orderIds.length; i>0; i--) {
            Order memory order = orderIdMapping[orderIds[i-1]];
            if (order.desiredTokenYAmount >= remainingTokenYAmount) {
                uint256 tokenXAmount = remainingTokenYAmount * (order.tokenXAmount/order.desiredTokenYAmount);
                _tokenXAmountOut += tokenXAmount;
                break;
            } else {
                _tokenXAmountOut += order.tokenXAmount;
                remainingTokenYAmount -= order.desiredTokenYAmount;
            }
        }

        return _tokenXAmountOut;
    }

    /// Get order ids for pair
    function getOpenOrderIdsForPair(address tokenX, address tokenY) external view returns (uint256[] memory _orderIds) {
        _orderIds = orderBooks[tokenX][tokenY];
    }

    /// Get order by order id
    function getOrderById(uint256 orderId) external view returns (Order memory _order) {
        _order = orderIdMapping[orderId];
    }

    /// Get orders by order address
    function getOrderIdsByAddress(address maker) external view returns (uint256[] memory _orderIds) {
        _orderIds = orderIdsByMaker[maker];
    }

}