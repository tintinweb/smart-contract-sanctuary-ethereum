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
import "./TokenWhitelist.sol";

contract Flyweight {
    address constant public UNISWAP_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

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

    enum OrderState { UNTRIGGERED, EXECUTED, CANCELLED }
    enum OrderTriggerDirection { BELOW, EQUAL, ABOVE }

    uint public ordersCount;
    mapping(uint => Order) public orders;
    mapping(address => uint[]) public orderIdsByAddress;
    mapping(string => string) public prices;
    TokenWhitelist public immutable tokenWhitelist;

    constructor() {
        tokenWhitelist = new TokenWhitelist(block.chainid);
    }

    function getWhitelistedSymbols(string[] calldata symbols) external view returns(string[] memory) {
        string[] memory whitelist = new string[](symbols.length);
        uint whitelistCount = 0;
        for (uint i = 0; i < symbols.length; i++) {
            string calldata symbol = symbols[i];
            bool isWhitelisted = tokenWhitelist.addresses(symbol) != address(0);
            if (isWhitelisted) {
                whitelist[whitelistCount] = symbol;
                whitelistCount++;
            }
        }

        string[] memory trimmedWhitelist = new string[](whitelistCount);
        for (uint i = 0; i < whitelistCount; i++) {
            trimmedWhitelist[i] = whitelist[i];
        }

        return trimmedWhitelist;
    }

    function tryGetTokenAddress(string calldata symbol) external view returns(address) {
        return tokenWhitelist.addresses(symbol);
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

        orderIdsByAddress[msg.sender].push(id);
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
        assert(order.orderState == OrderState.UNTRIGGERED);

        address tokenInAddress = tokenWhitelist.addresses(order.tokenIn);
        address tokenOutAddress = tokenWhitelist.addresses(order.tokenOut);
        uint balance = IERC20(tokenInAddress).balanceOf(address(this));
        require(balance >= order.tokenInAmount);

        address[2] memory path = [tokenInAddress, tokenOutAddress];
        uint tokenOutMinQuote = 0;  // todo: when front-end is made, it should allow user-defined max slippage

        ISwapRouter swapRouter = ISwapRouter(UNISWAP_ROUTER_ADDRESS);
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

    function getOrdersByAddress(address addr) external view returns(Order[] memory) {
        uint[] storage orderIds = orderIdsByAddress[addr];
        Order[] memory ordersForAddress = new Order[](orderIds.length);
        for (uint i = 0; i < orderIds.length; i++) {
            uint orderId = orderIds[i];
            ordersForAddress[i] = orders[orderId];
        }

        return ordersForAddress;
    }

    function cancelOrder(uint orderId) external returns(uint, string memory, address, uint, uint) {
        Order storage order = orders[orderId];
        assert(msg.sender == order.owner);
        require(order.orderState != OrderState.CANCELLED);

        address tokenInAddress = tokenWhitelist.addresses(order.tokenIn);
        IERC20(tokenInAddress).transfer(order.owner, order.tokenInAmount);
        order.orderState = OrderState.CANCELLED;
        return (order.tokenInAmount, order.tokenIn, order.owner, block.number, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenWhitelist {
    address constant public UNISWAP_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    mapping(string => address) public addresses;

    constructor(uint chainId) {
        if (chainId == 1) {
            initTokenWhitelistMainnet();
        } else if (chainId == 5) {
            initTokenWhitelistGoerli();
        }
    }

    function initTokenWhitelistMainnet() private {
        addresses["1INCH"] = 0x111111111117dC0aa78b770fA6A738034120C302;
        addresses["AAVE"] = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
        addresses["AXS"] = 0xBB0E17EF65F82Ab018d8EDd776e8DD940327B28b;
        addresses["BAL"] = 0xba100000625a3754423978a60c9317c58a424e3D;
        addresses["BUSD"] = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
        addresses["COMP"] = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
        addresses["CRV"] = 0xD533a949740bb3306d119CC777fa900bA034cd52;
        addresses["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        addresses["DYDX"] = 0x92D6C1e31e14520e676a687F0a93788B716BEff5;
        addresses["ENS"] = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;
        addresses["FXS"] = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
        addresses["GUSD"] = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;
        addresses["IMX"] = 0xF57e7e7C23978C3cAEC3C3548E3D615c346e79fF;
        addresses["LDO"] = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
        addresses["LINK"] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        addresses["LRC"] = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
        addresses["MATIC"] = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
        addresses["MKR"] = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
        addresses["PAXG"] = 0x45804880De22913dAFE09f4980848ECE6EcbAf78;
        addresses["RPL"] = 0xD33526068D116cE69F19A9ee46F0bd304F21A51f;
        addresses["RUNE"] = 0x3155BA85D5F96b2d030a4966AF206230e46849cb;
        addresses["SHIB"] = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
        addresses["SNX"] = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
        addresses["STETH"] = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        addresses["SUSHI"] = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
        addresses["UNI"] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        addresses["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        addresses["USDT"] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        addresses["WBTC"] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        addresses["WETH"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        addresses["XAUT"] = 0x68749665FF8D2d112Fa859AA293F07A622782F38;

        IERC20(addresses["1INCH"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["AAVE"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["AXS"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["BAL"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["BUSD"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["COMP"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["CRV"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["DAI"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["DYDX"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["ENS"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["FXS"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["GUSD"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["IMX"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["LDO"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["LINK"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["LRC"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["MATIC"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["MKR"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["PAXG"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["RPL"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["RUNE"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["SHIB"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["SNX"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["STETH"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["SUSHI"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["UNI"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["USDC"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["USDT"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["WBTC"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["WETH"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["XAUT"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
    }

    function initTokenWhitelistGoerli() private {
        addresses["UNI"] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        addresses["WETH"] = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

        IERC20(addresses["UNI"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
        IERC20(addresses["WETH"]).approve(UNISWAP_ROUTER_ADDRESS, type(uint).max);
    }
}