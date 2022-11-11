// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./SwapHandlerCombinedBase.sol";

/// @notice Swap handler executing trades on 1Inch
contract SwapHandler1Inch is SwapHandlerCombinedBase {
    address immutable public oneInchAggregator;

    constructor(address oneInchAggregator_, address uniSwapRouterV2, address uniSwapRouterV3) SwapHandlerCombinedBase(uniSwapRouterV2, uniSwapRouterV3) {
        oneInchAggregator = oneInchAggregator_;
    }

    function swapPrimary(SwapParams memory params) override internal returns (uint amountOut) {
        setMaxAllowance(params.underlyingIn, params.amountIn, oneInchAggregator);

        (bool success, bytes memory result) = oneInchAggregator.call(params.payload);
        if (!success) revertBytes(result);

        // return amount out reported by 1Inch. It might not be exact for fee-on-transfer or rebasing tokens.
        amountOut = abi.decode(result, (uint));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./SwapHandlerBase.sol";
import "../vendor/ISwapRouterV3.sol";
import "../vendor/ISwapRouterV2.sol";

/// @notice Base contract for swap handlers which execute a secondary swap on Uniswap V2 or V3 for exact output
abstract contract SwapHandlerCombinedBase is SwapHandlerBase {
    address immutable public uniSwapRouterV2;
    address immutable public uniSwapRouterV3;

    constructor(address uniSwapRouterV2_, address uniSwapRouterV3_) {
        uniSwapRouterV2 = uniSwapRouterV2_;
        uniSwapRouterV3 = uniSwapRouterV3_;
    }

    function executeSwap(SwapParams memory params) external override {
        require(params.mode <= 1, "SwapHandlerCombinedBase: invalid mode");

        if (params.mode == 0) {
            swapPrimary(params);
        } else {
            // For exact output expect a payload for the primary swap provider and a path to swap the remainder on Uni2 or Uni3
            bytes memory path;
            (params.payload, path) = abi.decode(params.payload, (bytes, bytes));

            uint primaryAmountOut = swapPrimary(params);

            if (primaryAmountOut < params.amountOut) {
                // The path param is reused for UniV2 and UniV3 swaps. The protocol to use is determined by the path length.
                // The length of valid UniV2 paths is given as n * 20, for n > 1, and the shortes path is 40 bytes.
                // The length of valid UniV3 paths is given as 20 + n * 23 for n > 0, because of an additional 3 bytes for the pool fee.
                // The max path length must be lower than the first path length which is valid for both protocols (and is therefore ambiguous)
                // This value is at 20 UniV3 hops, which corresponds to 24 UniV2 hops.
                require(path.length >= 40 && path.length < 20 + (20 * 23), "SwapHandlerPayloadBase: secondary path format");

                uint remainder;
                unchecked { remainder = params.amountOut - primaryAmountOut; }

                swapExactOutDirect(params, remainder, path);
            }
        }

        transferBack(params.underlyingIn);
    }

    function swapPrimary(SwapParams memory params) internal virtual returns (uint amountOut);

    function swapExactOutDirect(SwapParams memory params, uint amountOut, bytes memory path) private {
        (bool isUniV2, address[] memory uniV2Path) = detectAndDecodeUniV2Path(path);

        if (isUniV2) {
            setMaxAllowance(params.underlyingIn, params.amountIn, uniSwapRouterV2);

            ISwapRouterV2(uniSwapRouterV2).swapTokensForExactTokens(amountOut, type(uint).max, uniV2Path, msg.sender, block.timestamp);
        } else {
            setMaxAllowance(params.underlyingIn, params.amountIn, uniSwapRouterV3);

            ISwapRouterV3(uniSwapRouterV3).exactOutput(
                ISwapRouterV3.ExactOutputParams({
                    path: path,
                    recipient: msg.sender,
                    amountOut: amountOut,
                    amountInMaximum: type(uint).max,
                    deadline: block.timestamp
                })
            );
        }
    }

    function detectAndDecodeUniV2Path(bytes memory path) private pure returns (bool, address[] memory) {
        bool isUniV2 = path.length % 20 == 0;
        address[] memory addressPath;

        if (isUniV2) {
            uint addressPathSize = path.length / 20;
            addressPath = new address[](addressPathSize);

            unchecked {
                for(uint i = 0; i < addressPathSize; ++i) {
                    addressPath[i] = toAddress(path, i * 20);
                }
            }
        }

        return (isUniV2, addressPath);
    }

    function toAddress(bytes memory data, uint start) private pure returns (address result) {
        // assuming data length is already validated
        assembly {
            // borrowed from BytesLib https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
            result := div(mload(add(add(data, 0x20), start)), 0x1000000000000000000000000)
        }
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
pragma solidity >=0.6.2;

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


interface ISwapRouterV2 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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