/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Factory{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract UniswapGetReserves{
    address private factory;
    address private weth;
    address private usdc;

    constructor(){
        factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        usdc = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    }

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1){
        address pair = IUniswapV2Factory(factory).getPair(weth, usdc);
        (reserve0, reserve1, ) = IUniswapV2Pair(pair).getReserves();
    }
}