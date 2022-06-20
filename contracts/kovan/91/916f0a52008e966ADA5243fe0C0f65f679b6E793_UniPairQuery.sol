// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Uniswap example from https://solidity-by-example.org/interface/
interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface UniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract UniPairQuery {
    address private factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private dai = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD; // Change from kovan's network
    address private weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Change from kovan's network

    function getTokenReserves() external view returns (uint256, uint256) {
        address pair = UniswapV2Factory(factory).getPair(dai, weth);
        (uint256 reserve0, uint256 reserve1, ) = UniswapV2Pair(pair)
            .getReserves();
        return (reserve0, reserve1);
    }
}