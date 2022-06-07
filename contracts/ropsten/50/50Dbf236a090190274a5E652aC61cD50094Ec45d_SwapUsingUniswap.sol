/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20{
    function decimals() external view returns (uint8);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface Iuniswap{
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

}

interface IUniswapV2Pair{
    function token1() external view returns(IERC20);
    function token0() external view returns(IERC20);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract SwapUsingUniswap{

    Iuniswap router;
    IUniswapV2Factory factory;
    address internal constant ETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address internal constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    uint amountOutMin = 0;
    uint deadline;

    constructor(){
        router = Iuniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    }

    function swapEthForTokens() external payable{
        address [] memory path = new address[](2);
        path[0] = ETH;
        path[1] = DAI;
        deadline = block.timestamp+300;
        router.swapExactETHForTokens{value:msg.value}(amountOutMin, path, msg.sender, deadline);
    }

    function swapTokensForEth(uint amountIn) external{
        IERC20(DAI).transferFrom(msg.sender,address(this), amountIn);
        IERC20(DAI).approve(address(router), amountIn);
        address [] memory path = new address[](2);
        path[0] = DAI;
        path[1] = ETH;
        deadline = block.timestamp+300;
        router.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, deadline);
    }

    // getPrice functions returns amount of tokens per 1 token
    function getDAIperETHPrice() external view returns (uint){
        address PAIR = factory.getPair(DAI,ETH);
        IUniswapV2Pair vpair = IUniswapV2Pair(PAIR);
        IERC20 token1 = IERC20(vpair.token1());
        (uint Res0, uint Res1,) = vpair.getReserves();
        uint res0 = Res0*(10**token1.decimals());
        return((res0)/Res1); // return amount of token0 needed to buy token1
    }
    function getETHperDAIPrice() external view returns (uint){
        address PAIR = factory.getPair(DAI,ETH);
        IUniswapV2Pair vpair = IUniswapV2Pair(PAIR);
        IERC20 token0 = IERC20(vpair.token0());
        (uint Res0, uint Res1,) = vpair.getReserves();
        uint res1 = Res1*(10**token0.decimals());
        return((res1)/Res0); // return amount of token1 needed to buy token0
    }
}