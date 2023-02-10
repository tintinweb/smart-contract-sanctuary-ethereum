//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";
import "./IUniswap.sol";

contract WRUniswap {
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    //address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    
    constructor() {
        
    }

    function swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin) external returns (uint[] memory amountOut) {
        // _tokenIn = DAI;
        // _tokenOut = USDC;
        // _amountIn = 10_000_000_000_000_000_000;
        // _amountOutMin = 1;

        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn); //transferring tokens from sender to contract
        IERC20(_tokenIn).approve(address(UNISWAP_V2_ROUTER), _amountIn); //this contract needs to allow uniswap V2 router to spend token

        address[] memory path;
        path = new address[](3);
        path[0] = _tokenIn; //we are using DAI
        path[1] = WETH; 
        path[2] = _tokenOut; //we are using USDT
        uint[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, msg.sender, block.timestamp);
        return amounts;
    }
}