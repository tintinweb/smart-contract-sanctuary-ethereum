/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma abicoder v2;
// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/swap-router-contracts/contracts/interfaces/IV2SwapRouter.sol


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);
}

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol

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

// File: @uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @uniswap/v3-periphery/contracts/libraries/TransferHelper.sol

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
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// File: contracts/revenue-router.sol

interface ISplitter {
    function run(address token, address dPayer) external;
}

interface IPayer {
    function receivePayment(address sender, uint256 amount) external;
    function releasePayment() external;
}

contract RevenueRouter is Ownable {
    address public PROFIT;
    address public BASE;
    uint24 public BASE_FEE;
    ISplitter public splitter;
    IPayer public profitPayer;
    IV3SwapRouter public v3Router;

    /**
     * @dev Route to swap revenue token to PROFIT on Uniswap V3 DEX
     */
    struct V3Route {
        // @dev revenue token which we need to swap to PROFIT
        address inputToken;

        // @dev output token can be BASE or paired with BASE token on v3Router pools
        address outputToken;

        // @dev input-output pair LP pool fee, used only when outputToken is not BASE
        uint24 poolFee;

        // @dev output-base pair LP pool fee, used only when outputToken is not BASE
        uint24 outputBasePoolFee;

        // @dev route can be decativated
        bool active;
    }

    /**
     * @dev Route to swap revenue token to other token on Uniswap V2 DEX
     */
    struct V2Route {
        // @dev revenue token which we need to swap to PROFIT
        address inputToken;

        // @dev output token can be BASE, paired with BASE token on v2Router or any V3Route input token
        address outputToken;

        // @dev Uniswap V2 router
        address v2Router;

        // @dev swap outputToken to BASE through this v2Router
        bool swapToBase;

        // @dev route can be decativated
        bool active;
    }

    V3Route[] public v3Routes;
    V2Route[] public v2Routes;

    event SwapToProfit(uint256 profitOut);
    event V3RouteAdded(address indexed inputToken, address indexed outputToken, uint24 poolFee, uint24 outputBasePoolFee_);
    event V3RouteUpdated(uint256 routeIndex, address inputToken, address outputToken, uint24 poolFee, uint24 outputBasePoolFee, bool active);
    event V3RouteDeleted(uint256 routeIndex);
    event V2RouteAdded(address indexed inputToken, address indexed outputToken, address indexed router);
    event V2RouteUpdated(uint256 routeIndex, address inputToken, address outputToken, address v2Router, bool active, bool swapToBase);
    event V2RouteDeleted(uint256 routeIndex);

    constructor (
        address PROFIT_,
        address BASE_,
        uint24 BASE_FEE_,
        IV3SwapRouter v3Router_,
        ISplitter splitter_,
        IPayer profitPayer_
    ) {
        PROFIT = PROFIT_;
        BASE = BASE_;
        BASE_FEE = BASE_FEE_;
        v3Router = v3Router_;
        splitter = splitter_;
        profitPayer = profitPayer_;
    }

    // important to receive ETH
    receive() external payable {}

    function totalV3Routes() external view returns (uint256) {
        return v3Routes.length;
    }

    function totalV2Routes() external view returns (uint256) {
        return v2Routes.length;
    }

    // Add a new token to list of tokens that can be swapped to PROFIT.
    function addV3Route(address inputToken_, address outputToken_, uint24 poolFee_, uint24 outputBasePoolFee_) external onlyOwner {
        v3Routes.push(
            V3Route({
        inputToken: inputToken_,
        outputToken: outputToken_,
        poolFee: poolFee_,
        outputBasePoolFee: outputBasePoolFee_,
        active: true
        })
        );

        emit V3RouteAdded(inputToken_, outputToken_, poolFee_, outputBasePoolFee_);
    }

    function addV2Route(address inputToken_, address outputToken_, address v2Router_, bool swapToBase_) external onlyOwner {
        v2Routes.push(
            V2Route({
        inputToken: inputToken_,
        outputToken: outputToken_,
        v2Router: v2Router_,
        swapToBase: swapToBase_,
        active: true
        })
        );

        emit V2RouteAdded(inputToken_, outputToken_, v2Router_);
    }

    // function to remove tokenIn (spends less gas)
    function deleteV3Route(uint256 index_) external onlyOwner {
        require(index_ < v3Routes.length, "index out of bound");
        v3Routes[index_] = v3Routes[v3Routes.length - 1];
        v3Routes.pop();

        emit V3RouteDeleted(index_);
    }

    function deleteV2Route(uint256 index_) external onlyOwner {
        require(index_ < v2Routes.length, "index out of bound");
        v2Routes[index_] = v2Routes[v2Routes.length - 1];
        v2Routes.pop();

        emit V2RouteDeleted(index_);
    }

    function updateV3Route(uint256 index_, address inputToken_, address outputToken_, uint24 poolFee_, uint24 outputBasePoolFee_, bool active_) external onlyOwner {
        v3Routes[index_].inputToken = inputToken_;
        v3Routes[index_].outputToken = outputToken_;
        v3Routes[index_].poolFee = poolFee_;
        v3Routes[index_].outputBasePoolFee = outputBasePoolFee_;
        v3Routes[index_].active = active_;
        emit V3RouteUpdated(index_, inputToken_, outputToken_, poolFee_, outputBasePoolFee_, active_);
    }

    function updateV2Route(uint256 index_,  address inputToken_, address outputToken_, address v2Router_, bool active_, bool swapToBase_) external onlyOwner {
        v2Routes[index_].inputToken = inputToken_;
        v2Routes[index_].outputToken = outputToken_;
        v2Routes[index_].v2Router = v2Router_;
        v2Routes[index_].swapToBase = swapToBase_;
        v2Routes[index_].active = active_;
        emit V2RouteUpdated(index_, inputToken_, outputToken_, v2Router_, active_, swapToBase_);
    }

    function run() external {
        swapTokens();
        splitter.run(address(PROFIT), address(profitPayer));
    }

    function swapTokens() public returns (uint256 amountOut) {
        uint256 amount;
        uint256 i;

        for (i = 0; i < v2Routes.length; i++) {
            V2Route storage v2route = v2Routes[i];

            if (v2route.active == false) {
                continue;
            }

            uint256 tokenBal = IERC20(v2route.inputToken).balanceOf(address(this));
            if (tokenBal > 0) {
                address[] memory path = new address[](2);
                path[0] = v2route.inputToken;
                path[1] = v2route.outputToken;
                if (IERC20(v2route.inputToken).allowance(address(this), v2route.v2Router) < tokenBal) {
                    TransferHelper.safeApprove(v2route.inputToken, v2route.v2Router, type(uint256).max);
                }

                amount = IUniswapV2Router01(v2route.v2Router).swapExactTokensForTokens(tokenBal, 0, path, address(this), block.timestamp)[1];

                if (v2route.outputToken != BASE && v2route.swapToBase == true) {
                    path[0] = v2route.outputToken;
                    path[1] = BASE;
                    if (IERC20(v2route.outputToken).allowance(address(this), v2route.v2Router) < amount) {
                        TransferHelper.safeApprove(v2route.outputToken, v2route.v2Router, type(uint256).max);
                    }

                    amount = IUniswapV2Router01(v2route.v2Router).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp)[1];
                }

                // Swap WETH to PROFIT on v3
                IV3SwapRouter.ExactInputSingleParams memory params2 = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: BASE,
                tokenOut: PROFIT,
                fee: BASE_FEE,
                recipient: address(splitter),
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend WETH
                if (IERC20(BASE).allowance(address(this), address(v3Router)) < amount) {
                    TransferHelper.safeApprove(BASE, address(v3Router), type(uint256).max);
                }
                amountOut += v3Router.exactInputSingle(params2);
            }
        }

        for (i = 0; i < v3Routes.length; i++) {
            V3Route storage v3route = v3Routes[i];

            if (v3route.active == false) {
                continue;
            }

            uint256 tokenBal = IERC20(v3route.inputToken).balanceOf(address(this));

            if (tokenBal > 0) {
                // If TOKEN is Paired with BASE token (WETH now)
                if (v3route.outputToken == BASE) {
                    // Swap TOKEN to WETH
                    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
                    tokenIn: v3route.inputToken,
                    tokenOut: BASE,
                    fee: BASE_FEE,
                    recipient: address(this),
                    amountIn: tokenBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                    });

                    // approve dexRouter to spend tokens
                    if (IERC20(v3route.inputToken).allowance(address(this), address(v3Router)) < tokenBal) {
                        TransferHelper.safeApprove(v3route.inputToken, address(v3Router), type(uint256).max);
                    }

                    amount = v3Router.exactInputSingle(params);
                } else {
                    // TOKEN is Paired with v3route.outputToken
                    // Swap TOKEN to v3route.outputToken
                    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
                    tokenIn: v3route.inputToken,
                    tokenOut: v3route.outputToken,
                    fee: v3route.poolFee,
                    recipient: address(this),
                    amountIn: tokenBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                    });

                    // approve dexRouter to spend TOKEN
                    if (IERC20(v3route.inputToken).allowance(address(this), address(v3Router)) < tokenBal) {
                        TransferHelper.safeApprove(v3route.inputToken, address(v3Router), type(uint256).max);
                    }

                    amount = v3Router.exactInputSingle(params);

                    // Swap v3route.outputToken to BASE
                    // uint256 usdtBal = IERC20(USDT).balanceOf(address(this));
                    IV3SwapRouter.ExactInputSingleParams memory params2 = IV3SwapRouter.ExactInputSingleParams({
                    tokenIn: v3route.outputToken,
                    tokenOut: BASE,
                    fee: v3route.outputBasePoolFee,
                    recipient: address(this),
                    amountIn: amount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                    });

                    // approve dexRouter to spend USDT
                    if (IERC20(v3route.outputToken).allowance(address(this), address(v3Router)) < amount) {
                        TransferHelper.safeApprove(v3route.outputToken, address(v3Router), type(uint256).max);
                    }

                    amount = v3Router.exactInputSingle(params2);
                }

                // Swap BASE to PROFIT
                // uint256 wethBal = IERC20(WETH).balanceOf(address(this));
                IV3SwapRouter.ExactInputSingleParams memory params3 = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: BASE,
                tokenOut: PROFIT,
                fee: BASE_FEE,
                recipient: address(splitter),
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend WETH
                if (IERC20(BASE).allowance(address(this), address(v3Router)) < amount) {
                    TransferHelper.safeApprove(BASE, address(v3Router), type(uint256).max);
                }
                amountOut += v3Router.exactInputSingle(params3);
            }
        }

        if (amountOut > 0) {
            emit SwapToProfit(amountOut);
        }
    }

    function withdraw(address _token, address _to, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

}