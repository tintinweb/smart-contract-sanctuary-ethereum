// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IUniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
}

contract SushiSwapTokenSwap {
    
    address private constant SUSHISWAP_V2_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

   function swap(address _tokenOut) external payable {
       address[] memory path = new address[](2);
       path[0] = WETH;
       path[1] = _tokenOut;
       
       IUniswapV2Router(SUSHISWAP_V2_ROUTER).swapExactETHForTokens{value: msg.value}(
           0, path, msg.sender, block.timestamp + 120);
    }
}