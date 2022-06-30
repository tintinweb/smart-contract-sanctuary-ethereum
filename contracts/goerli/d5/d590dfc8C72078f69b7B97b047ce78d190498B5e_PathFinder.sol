// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IQuoter} from "../intergrations/uniswap/IQuoter.sol";
import {Constants} from "../libraries/Constants.sol";

contract PathFinder {
    IQuoter public quoter;
    uint24[] public fees = [500, 3000, 10000];
    address[] public passbyTokens;

    struct TradePath {
        bytes path;
        uint256 expectedAmount;
    }

    constructor(IQuoter _quoter, address[] memory _tokens) {
        quoter = _quoter;
        passbyTokens = _tokens;
    }

    function exactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path) {
        address[] memory tokens = passbyTokens;
        path = bestExactInputPath(tokenIn, tokenOut, amount, tokens);
    }

    function exactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path) {
        address[] memory tokens = passbyTokens;
        path = bestExactOutputPath(tokenIn, tokenOut, amount, tokens);
    }

    function bestExactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) public returns (TradePath memory path) {
        path = _bestV3Path(Constants.EXACT_INPUT, tokenIn, tokenOut, amount, tokens);
    }

    function bestExactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) public returns (TradePath memory path) {
        path = _bestV3Path(Constants.EXACT_OUTPUT, tokenIn, tokenOut, amount, tokens);
    }

    function _bestV3Path(
        uint256 tradeType,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) internal returns (TradePath memory) {
        if (amount == 0) return TradePath({path: "", expectedAmount: 0});

        uint256 bestAmount = tradeType == Constants.EXACT_INPUT
            ? 0
            : Constants.MAX_INT;
        bytes memory bestPath;
        for (uint256 i = 0; i < fees.length; i++) {
            bytes memory path = abi.encodePacked(tokenIn, fees[i], tokenOut);
            (uint256 expectedAmount, bool best) = _getAmount(
                tradeType,
                path,
                amount,
                bestAmount
            );
            if (best) {
                bestAmount = expectedAmount;
                bestPath = path;
            }
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenIn == tokens[i] || tokenOut == tokens[i]) continue;
            for (uint256 j = 0; i < fees.length; j++) {
                for (uint256 k = 0; i < fees.length; k++) {
                    bytes memory path = abi.encodePacked(
                        tokenIn,
                        fees[j],
                        tokens[i],
                        fees[k],
                        tokenOut
                    );
                    (uint256 expectedAmount, bool best) = _getAmount(
                        tradeType,
                        path,
                        amount,
                        bestAmount
                    );
                    if (best) {
                        bestAmount = expectedAmount;
                        bestPath = path;
                    }
                }
            }
        }
        return TradePath({path: bestPath, expectedAmount: bestAmount});
    }

    function _getAmount(
        uint256 tradeType,
        bytes memory path,
        uint256 amount,
        uint256 bestAmount
    ) internal returns (uint256, bool) {
        uint256 expectedAmount;

        if (tradeType == 1) {
            try quoter.quoteExactInput(path, amount) returns (
                uint256 amountOut
            ) {
                expectedAmount = amountOut;
            } catch {
                return (bestAmount, false);
            }
        } else {
            try quoter.quoteExactOutput(path, amount) returns (
                uint256 amountIn
            ) {
                expectedAmount = amountIn;
            } catch {
                return (bestAmount, false);
            }
        }

        if (
            (tradeType == 1 && expectedAmount > bestAmount) ||
            (tradeType == 2 && expectedAmount < bestAmount)
        ) {
            return (expectedAmount, true);
        }
        return (expectedAmount, false);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

library Constants {
    // TARGETS
    uint256 internal constant NO_SWAP = 0;
    uint256 internal constant UNISWAP_V2 = 1;
    uint256 internal constant UNISWAP_V3 = 2;

    // ACTIONS
    uint256 internal constant EXACT_INPUT = 1;
    uint256 internal constant EXACT_OUTPUT = 2;
    uint256 internal constant ADD_LIQUIDITY = 3;
    uint256 internal constant REMOVE_LIQUIDITY = 4;
    uint256 internal constant COLLECT_FEE = 5;

    // SIZES
    uint256 internal constant ADDR_SIZE = 20;
    uint256 internal constant FEE_SIZE = 3;

    uint256 internal constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
}