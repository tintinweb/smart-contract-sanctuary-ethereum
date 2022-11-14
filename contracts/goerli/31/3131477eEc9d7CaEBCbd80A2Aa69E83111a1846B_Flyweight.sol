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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Flyweight {
    struct Order {
        uint id;
        address owner;
        OrderState orderState;
        string tokenIn;
        string tokenOut;
        string tokenInTriggerPrice;
        OrderTriggerDirection direction;
        uint tokenInAmount;
    }
    struct NewPriceItem {
        string symbol;
        string price;
    }

    event PriceUpdated (
        uint timestamp,
        string symbol,
        string oldPrice,
        string newPrice
    );

    event OrderTriggered (
        uint orderId
    );

    event OrderExecuted (
        uint orderId
    );

    enum OrderState { UNTRIGGERED, EXECUTED }
    enum OrderTriggerDirection { BELOW, EQUAL, ABOVE }

    uint public ordersCount;
    mapping(uint => Order) public orders;
    mapping(string => string) public prices;
    mapping(string => address) public tokenAddresses;

    constructor() {
        tokenAddresses["UNI"] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        tokenAddresses["WETH"] = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

        address uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IERC20 uni = IERC20(tokenAddresses["UNI"]);
        IERC20 weth = IERC20(tokenAddresses["WETH"]);
        uni.approve(uniswapRouterAddress, type(uint).max);
        weth.approve(uniswapRouterAddress, type(uint).max);
    }

    function addNewOrder(string calldata tokenIn, string calldata tokenOut, string calldata tokenInTriggerPrice, OrderTriggerDirection direction, uint tokenInAmount) external returns(uint) {
        uint id = ordersCount;
        orders[id] = Order({
            id: id,
            owner: msg.sender,
            orderState: OrderState.UNTRIGGERED,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            tokenInTriggerPrice: tokenInTriggerPrice,
            direction: direction,
            tokenInAmount: tokenInAmount
        });

        ordersCount++;
        return id;
    }

    function storePricesAndProcessTriggeredOrderIds(NewPriceItem[] calldata newPriceItems, uint[] calldata newTriggeredOrderIds) external {
        for (uint i = 0; i < newPriceItems.length; i++) {
            NewPriceItem memory item = newPriceItems[i];
            string memory oldPrice = prices[item.symbol];
            prices[item.symbol] = item.price;

            emit PriceUpdated({
                timestamp: block.timestamp,
                symbol: item.symbol,
                oldPrice: oldPrice,
                newPrice: item.price
            });
        }

        for (uint i = 0; i < newTriggeredOrderIds.length; i++) {
            uint orderId = newTriggeredOrderIds[i];
            emit OrderTriggered({
                orderId: orderId
            });
            
            executeOrderId(orderId);
            emit OrderExecuted({
                orderId: orderId
            });
        }
    }

    function executeOrderId(uint orderId) private {
        Order storage order = orders[orderId];
        uint balance = IERC20(address(tokenAddresses[order.tokenIn])).balanceOf(address(this));
        require(balance >= order.tokenInAmount);

        address[2] memory path = [tokenAddresses[order.tokenIn], tokenAddresses[order.tokenOut]];
        uint tokenOutMinQuote = 0;  // todo: when front-end is made, it should allow user-defined max slippage

        address uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        ISwapRouter swapRouter = ISwapRouter(uniswapRouterAddress);
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: path[0],
            tokenOut: path[1],
            fee: 3000,
            recipient: order.owner,
            deadline: block.timestamp,
            amountIn: order.tokenInAmount,
            amountOutMinimum: tokenOutMinQuote,
            sqrtPriceLimitX96: 0
        });

        swapRouter.exactInputSingle(swapParams);
        order.orderState = OrderState.EXECUTED;
    }
}