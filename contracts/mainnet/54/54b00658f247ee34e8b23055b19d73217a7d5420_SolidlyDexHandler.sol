// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IDexHandler.sol";

interface IBaseV1Factory {
    function getPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (address);
}

interface IBaseV1Pair {
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);
}

contract SolidlyDexHandler is IDexHandler {
    constructor() {}

    function getPairAmountOut(
        address pair,
        address tokenIn,
        uint256 amountIn
    ) internal view returns (uint256 amountOut_) {
        if (pair != address(0)) {
            try IBaseV1Pair(pair).getAmountOut(amountIn, tokenIn) returns (uint256 amountOut) {
                amountOut_ = amountOut;
            } catch {}
        }
    }

    function getAmountOut(
        address _dex,
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view override returns (address pair, uint256 amountOut) {
        pair = IBaseV1Factory(_dex).getPair(_tokenIn, _tokenOut, false);
        amountOut = getPairAmountOut(pair, _tokenIn, _amountIn);

        address stablePair = IBaseV1Factory(_dex).getPair(_tokenIn, _tokenOut, true);
        uint256 stableAmountOut = getPairAmountOut(stablePair, _tokenIn, _amountIn);
        if (stableAmountOut > amountOut) {
            pair = stablePair;
            amountOut = stableAmountOut;
        }

        if (amountOut == 0) {
            pair = address(0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IDexHandler {
    function getAmountOut(
        address _dex,
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (address pair, uint256 amountOut);
}