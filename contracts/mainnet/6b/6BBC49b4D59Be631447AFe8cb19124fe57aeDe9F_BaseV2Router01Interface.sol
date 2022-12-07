// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

contract BaseV2Router01Interface {
    struct route {
        address from;
        address to;
        bool stable;
    }

    function UNSAFE_swapExactTokensForTokens(
        uint256[] memory amounts,
        route[] memory routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory) {}

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {}

    function addLiquidityFTM(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountFTMMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountFTM,
            uint256 liquidity
        )
    {}

    function factory() external view returns (address) {}

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount, bool stable) {}

    function getAmountsOut(uint256 amountIn, route[] memory routes)
        external
        view
        returns (uint256[] memory amounts)
    {}

    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (uint256 reserveA, uint256 reserveB) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(address _factory, address _wftm) external {}

    function isPair(address pair) external view returns (bool) {}

    function pairFor(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (address pair) {}

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {}

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB) {}

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {}

    function removeLiquidityFTM(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountFTMMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountFTM) {}

    function removeLiquidityFTMWithPermit(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountFTMMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountFTM) {}

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB) {}

    function sortTokens(address tokenA, address tokenB)
        external
        pure
        returns (address token0, address token1)
    {}

    function swapExactFTMForTokens(
        uint256 amountOutMin,
        route[] memory routes,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {}

    function swapExactTokensForFTM(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] memory routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {}

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] memory routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {}

    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {}

    function wftm() external view returns (address) {}
}