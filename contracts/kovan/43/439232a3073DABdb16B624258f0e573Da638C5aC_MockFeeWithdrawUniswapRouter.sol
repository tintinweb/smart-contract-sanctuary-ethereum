// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract MockFeeWithdrawUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {}
}