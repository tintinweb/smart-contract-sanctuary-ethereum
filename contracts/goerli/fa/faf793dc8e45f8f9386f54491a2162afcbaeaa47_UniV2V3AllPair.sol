// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router, IQuoter} from "../src/UniV2-V3-quote.sol";

contract UniV2V3AllPair {
    address routerV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // address Goo = 0x600000000a36F3cD48407e35eB7C5c910dc1f7a8;
    // address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    uint24 fee = 10000;
    IQuoter iquoter = IQuoter(quoter);
    IUniswapV2Factory ifactory = IUniswapV2Factory(factory);
    IUniswapV2Router irouterV2 = IUniswapV2Router(routerV2);

    function getAllPairs(uint start, uint last)
        public
        view
        returns (address[3][] memory)
    {
        uint allPairsLength = ifactory.allPairsLength();
        if (last > allPairsLength) {
            last = allPairsLength;
        }
        require(start < last, "start shuold be less then last");
        uint qty = last - start;
        address[3][] memory pairs = new address[3][](qty);
        for (uint i = 0; i < qty; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(ifactory.allPairs(i + start));
            pairs[i][0] = address(pair);
            pairs[i][1] = pair.token0();
            pairs[i][2] = pair.token1();
        }
        return pairs;
    }

    function getReserves(address[] memory pairs)
        public
        view
        returns (uint256[3][] memory)
    {
        uint256[3][] memory reserves = new uint256[3][](pairs.length);
        for (uint i; i < pairs.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);

            (reserves[i][0], reserves[i][1], reserves[i][2]) = pair
                .getReserves();
        }
        return reserves;
    }
}

pragma solidity ^0.8.13;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IUniswapV2Router {
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);
}

interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

contract UniV2V3Price {
    address routerV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address Goo = 0x600000000a36F3cD48407e35eB7C5c910dc1f7a8;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    uint24 fee = 10000;
    IQuoter iquoter = IQuoter(quoter);
    IUniswapV2Factory ifactory = IUniswapV2Factory(factory);
    IUniswapV2Router irouterV2 = IUniswapV2Router(routerV2);

    function getPair() public returns (address) {
        address pairGooWeth = ifactory.getPair(Goo, WETH);
        return pairGooWeth;
    }

    function getReserves()
        public
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        address pairGooWeth = getPair();
        IUniswapV2Pair ipair = IUniswapV2Pair(pairGooWeth);
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = ipair
            .getReserves();
        return (reserve0, reserve1, blockTimestampLast);
    }

    function CoinToWETHV2(uint256 amountIn) public returns (uint256) {
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = getReserves();
        uint256 amountOut = irouterV2.getAmountOut(
            amountIn,
            reserve0,
            reserve1
        );
        return amountOut;
    }

    function WETHToCoinV2(uint256 amountIn) public returns (uint256) {
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = getReserves();
        uint256 amountOut = irouterV2.getAmountOut(
            amountIn,
            reserve1,
            reserve0
        );
        return amountOut;
    }

    function getAmountOutV3(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) public returns (uint256) {
        uint256 amountOut = iquoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            sqrtPriceLimitX96
        );
        return amountOut;
    }

    function V2V3priceCall(uint256 amountIn)
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountOutV2 = WETHToCoinV2(amountIn);
        uint256 amountOutWETH = getAmountOutV3(Goo, WETH, fee, amountIn, 0);
        uint256 profitV2ToV3 = amountOutWETH > amountIn
            ? amountOutWETH - amountIn
            : 0;
        uint256 amountOutCoin = getAmountOutV3(WETH, Goo, fee, amountIn, 0);
        uint256 amountOutV2WETH = CoinToWETHV2(amountOutCoin);
        uint256 profitV3ToV2 = amountOutV2WETH > amountIn
            ? amountOutV2WETH - amountIn
            : 0;
        uint256 profit1Negtive = amountIn - amountOutWETH;
        uint256 profit2Negtive = amountIn - amountOutV2WETH;
        return (profitV2ToV3, profitV3ToV2, profit1Negtive, profit2Negtive);
    }
}