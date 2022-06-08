/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// Sources flattened with hardhat v2.9.7 https://hardhat.org

// File contracts/hyphen/structures/SwapRequest.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

enum SwapOperation {ExactOutput, ExactInput}

struct SwapRequest {
    address tokenAddress;
    uint256 percentage;
    uint256 amount;
    SwapOperation operation;
}

// File contracts/hyphen/interfaces/ISwapAdaptor.sol
pragma solidity 0.8.0;

interface ISwapAdaptor {
    function swap(
        address inputTokenAddress,
        uint256 amountInMaximum,
        address receiver,
        SwapRequest[] calldata swapRequests
    ) external returns (uint256 amountIn);

    function swapNative(
        uint256 amountInMaximum,
        address receiver,
        SwapRequest[] calldata swapRequests
    ) external returns (uint256 amountOut);
}


// File contracts/hyphen/interfaces/IUniswapV3SwapCallback.sol

pragma solidity 0.8.0;

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


// File contracts/hyphen/interfaces/ISwapRouter.sol

pragma solidity 0.8.0;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        // uint256 deadline;
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
        // uint256 deadline;
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


// File contracts/hyphen/interfaces/IERC20.sol

pragma solidity 0.8.0;
pragma abicoder v2;
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


pragma solidity 0.8.0;

/// @title Interface for WETH9
interface IWETH9 is IERC20 {

     function withdraw(uint256 _amount) external;
}

// File contracts/hyphen/lib/TransferHelper.sol

pragma solidity 0.8.0;

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


// File contracts/hyphen/swaps/UniswapAdaptor.sol

/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity 0.8.0;



contract UniswapAdaptor is ISwapAdaptor {

    uint24 public constant POOL_FEE = 3000;
    address private constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    address public immutable NATIVE_WRAP_ADDRESS;
    ISwapRouter public immutable swapRouter;

    constructor(ISwapRouter _swapRouter, address nativeWrapAddress) {
        NATIVE_WRAP_ADDRESS = nativeWrapAddress;
        swapRouter = _swapRouter; // "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
    }

    /// @notice swapForFixedInput swaps a fixed amount of DAI for a maximum possible amount of WETH9
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param inputTokenAddress Erc20 token address.
    /// @param amountInMaximum The exact amount of Erc20 that will be swapped for desired token.
    /// @param receiver address where all tokens will be sent.
    /// @return amountOut The amount of Swapped token received.
    function swap(
        address inputTokenAddress,
        uint256 amountInMaximum,
        address receiver,
        SwapRequest[] calldata swapRequests
    ) override external returns (uint256 amountOut) {

        require(inputTokenAddress != NATIVE, "wrong function");
        uint256 swapArrayLength = swapRequests.length;

        require(swapArrayLength <= 2, "too many swap requests");
        require(swapArrayLength == 1 || swapRequests[1].operation == SwapOperation.ExactInput, "Invalid swap operation");

        TransferHelper.safeTransferFrom(inputTokenAddress, msg.sender, address(this), amountInMaximum);
        TransferHelper.safeApprove(inputTokenAddress, address(swapRouter), amountInMaximum);
        
        uint256 amountIn;
        if(swapArrayLength == 1) {
            if (swapRequests[0].operation == SwapOperation.ExactOutput ){
                amountIn = _fixedOutputSwap (
                    inputTokenAddress,
                    amountInMaximum,
                    receiver,
                    swapRequests[0]
                );
                if(amountIn < amountInMaximum) {
                    TransferHelper.safeApprove(inputTokenAddress, address(swapRouter), 0);
                    TransferHelper.safeTransfer(inputTokenAddress, receiver, amountInMaximum - amountIn);
                }
            } else {
                _fixedInputSwap (
                    inputTokenAddress,
                    amountInMaximum,
                    receiver,
                    swapRequests[0]
                );
            }
        } else {
            amountIn = _fixedOutputSwap (
                inputTokenAddress,
                amountInMaximum,
                receiver,
                swapRequests[0]
            );
            if(amountIn < amountInMaximum){
                amountOut = _fixedInputSwap (
                    inputTokenAddress,
                    amountInMaximum - amountIn,
                    receiver,
                    swapRequests[1]
                );
            } 
        }
    }

    /// @notice swapNative swaps a fixed amount of WETH for a maximum possible amount of Swap tokens
    /// @dev The calling address must send Native token to this contract to spend at least `amountIn` worth of its WETH for this function to succeed.
    /// @param amountInMaximum The exact amount of WETH that will be swapped for Desired token.
    /// @param receiver Address to with tokens will be sent after swap.
    /// @return amountOut The amount of Desired token received.
    function swapNative(
        uint256 amountInMaximum,
        address receiver,
        SwapRequest[] calldata swapRequests
    ) override external returns (uint256 amountOut) {
        require(swapRequests.length == 1 , "only 1 swap request allowed");
        amountOut = _fixedInputSwap(NATIVE_WRAP_ADDRESS, amountInMaximum, receiver, swapRequests[0]);
    }

    // Call uniswap router for a fixed output swap
    function _fixedOutputSwap(
        address inputTokenAddress,
        uint256 amountInMaximum,
        address receiver,
        SwapRequest calldata swapRequests
    ) internal returns (uint256 amountIn) {
        ISwapRouter.ExactOutputSingleParams memory params;
        if(swapRequests.tokenAddress == NATIVE_WRAP_ADDRESS){
            params = ISwapRouter.ExactOutputSingleParams({
                tokenIn: inputTokenAddress,
                tokenOut: swapRequests.tokenAddress,
                fee: POOL_FEE,
                recipient: address(this),
                amountOut: swapRequests.amount,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

            amountIn = swapRouter.exactOutputSingle(params);
            unwrapWETH(receiver);

        } else {
            params = ISwapRouter.ExactOutputSingleParams({
                tokenIn: inputTokenAddress,
                tokenOut: swapRequests.tokenAddress,
                fee: POOL_FEE,
                recipient: receiver,
                amountOut: swapRequests.amount,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

            amountIn = swapRouter.exactOutputSingle(params);
        }
        
    }

    // Call uniswap router for a fixed Input amount
     function _fixedInputSwap(
        address inputTokenAddress,
        uint256 amount,
        address receiver,
        SwapRequest calldata swapRequests
    ) internal returns (uint256 amountOut) {
         ISwapRouter.ExactInputSingleParams memory params ;
         if(swapRequests.tokenAddress == NATIVE_WRAP_ADDRESS){
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: inputTokenAddress,
                tokenOut: swapRequests.tokenAddress,
                fee: POOL_FEE,
                recipient: address(this),
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            amountOut = swapRouter.exactInputSingle(params);
            unwrapWETH(receiver);

        } else {
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: inputTokenAddress,
                tokenOut: swapRequests.tokenAddress,
                fee: POOL_FEE,
                recipient: receiver,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            amountOut = swapRouter.exactInputSingle(params);
        }

    }

    function unwrapWETH(address recipient) internal {
        uint256 balanceWETH9 = IERC20(NATIVE_WRAP_ADDRESS).balanceOf(address(this));

        if (balanceWETH9 > 0) {
            TransferHelper.safeApprove(NATIVE_WRAP_ADDRESS, address(NATIVE_WRAP_ADDRESS), balanceWETH9);
            IWETH9(NATIVE_WRAP_ADDRESS).withdraw(balanceWETH9);
            TransferHelper.safeTransferETH(recipient, balanceWETH9);
            TransferHelper.safeApprove(NATIVE_WRAP_ADDRESS, address(NATIVE_WRAP_ADDRESS), 0);
        }
    }
}