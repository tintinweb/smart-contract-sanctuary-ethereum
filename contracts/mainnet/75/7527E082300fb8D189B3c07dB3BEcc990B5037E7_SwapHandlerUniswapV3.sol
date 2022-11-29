// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./SwapHandlerBase.sol";
import "../vendor/ISwapRouterV3.sol";

/// @notice Swap handler executing trades on UniswapV3 through SwapRouter
contract SwapHandlerUniswapV3 is SwapHandlerBase {
    address immutable public uniSwapRouterV3;

    constructor(address uniSwapRouterV3_) {
        uniSwapRouterV3 = uniSwapRouterV3_;
    }

    function executeSwap(SwapParams calldata params) override external {
        require(params.mode <= 1, "SwapHandlerUniswapV3: invalid mode");

        setMaxAllowance(params.underlyingIn, params.amountIn, uniSwapRouterV3);

        // The payload in SwapParams has double use. For single pool swaps, the price limit and a pool fee are abi-encoded as 2 uints, where bytes length is 64.
        // For multi-pool swaps, the payload represents a swap path. A valid path is a packed encoding of tokenIn, pool fee and tokenOut.
        // The valid path lengths are therefore: 20 + n*(3 + 20), where n >= 1, and no valid path can be 64 bytes long.
        if (params.payload.length == 64) {
            (uint sqrtPriceLimitX96, uint fee) = abi.decode(params.payload, (uint, uint));
            if (params.mode == 0)
                exactInputSingle(params, sqrtPriceLimitX96, fee);
            else
                exactOutputSingle(params, sqrtPriceLimitX96, fee);
        } else {
            if (params.mode == 0)
                exactInput(params, params.payload);
            else
                exactOutput(params, params.payload);
        }

        if (params.mode == 1) transferBack(params.underlyingIn);
    }

    function exactInputSingle(SwapParams memory params, uint sqrtPriceLimitX96, uint fee) private {
        ISwapRouterV3(uniSwapRouterV3).exactInputSingle(
            ISwapRouterV3.ExactInputSingleParams({
                tokenIn: params.underlyingIn,
                tokenOut: params.underlyingOut,
                fee: uint24(fee),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOut,
                sqrtPriceLimitX96: uint160(sqrtPriceLimitX96)
            })
        );
    }

    function exactInput(SwapParams memory params, bytes memory path) private {
        ISwapRouterV3(uniSwapRouterV3).exactInput(
            ISwapRouterV3.ExactInputParams({
                path: path,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOut
            })
        );
    }

    function exactOutputSingle(SwapParams memory params, uint sqrtPriceLimitX96, uint fee) private {
        ISwapRouterV3(uniSwapRouterV3).exactOutputSingle(
            ISwapRouterV3.ExactOutputSingleParams({
                tokenIn: params.underlyingIn,
                tokenOut: params.underlyingOut,
                fee: uint24(fee),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: params.amountOut,
                amountInMaximum: params.amountIn,
                sqrtPriceLimitX96: uint160(sqrtPriceLimitX96)
            })
        );
    }

    function exactOutput(SwapParams memory params, bytes memory path) private {
        ISwapRouterV3(uniSwapRouterV3).exactOutput(
            ISwapRouterV3.ExactOutputParams({
                path: path,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: params.amountOut,
                amountInMaximum: params.amountIn
            })
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./ISwapHandler.sol";
import "../Interfaces.sol";
import "../Utils.sol";

/// @notice Base contract for swap handlers
abstract contract SwapHandlerBase is ISwapHandler {
    function trySafeApprove(address token, address to, uint value) internal returns (bool, bytes memory) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))), data);
    }

    function safeApproveWithRetry(address token, address to, uint value) internal {
        (bool success, bytes memory data) = trySafeApprove(token, to, value);

        // some tokens, like USDT, require the allowance to be set to 0 first
        if (!success) {
            (success,) = trySafeApprove(token, to, 0);
            if (success) {
                (success,) = trySafeApprove(token, to, value);
            }
        }

        if (!success) revertBytes(data);
    }

    function transferBack(address token) internal {
        uint balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) Utils.safeTransfer(token, msg.sender, balance);
    }

    function setMaxAllowance(address token, uint minAllowance, address spender) internal {
        uint allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < minAllowance) safeApproveWithRetry(token, spender, type(uint).max);
    }

    function revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }

        revert("SwapHandlerBase: empty error");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouterV3 is IUniswapV3SwapCallback {
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function permit(address owner, address spender, uint value, uint deadline, bytes calldata signature) external;
}

interface IERC3156FlashBorrower {
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32);
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);
    function flashFee(address token, uint256 amount) external view returns (uint256);
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Interfaces.sol";

library Utils {
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }

    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface ISwapHandler {
    /// @notice Params for swaps using SwapHub contract and swap handlers
    /// @param underlyingIn sold token address
    /// @param underlyingOut bought token address
    /// @param mode type of the swap: 0 for exact input, 1 for exact output
    /// @param amountIn amount of token to sell. Exact value for exact input, maximum for exact output
    /// @param amountOut amount of token to buy. Exact value for exact output, minimum for exact input
    /// @param exactOutTolerance Maximum difference between requested amountOut and received tokens in exact output swap. Ignored for exact input
    /// @param payload multi-purpose byte param. The usage depends on the swap handler implementation
    struct SwapParams {
        address underlyingIn;
        address underlyingOut;
        uint mode;                  // 0=exactIn  1=exactOut
        uint amountIn;              // mode 0: exact,    mode 1: maximum
        uint amountOut;             // mode 0: minimum,  mode 1: exact
        uint exactOutTolerance;     // mode 0: ignored,  mode 1: downward tolerance on amountOut (fee-on-transfer etc.)
        bytes payload;
    }

    /// @notice Execute a trade on the swap handler
    /// @param params struct defining the requested trade
    function executeSwap(SwapParams calldata params) external;
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