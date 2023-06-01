/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function decimals() external view returns (uint256);
}


interface UniRouter{
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


contract GetEOAvalue{
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function getWETHvalue() internal view returns(uint256){
        UniRouter uniswapRouter = UniRouter(router);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        
        return uniswapRouter.getAmountsOut(10 ** 18, path)[1];
    }

    function getUSDamount(address token, address addr) internal view returns(uint256){
        return IERC20(token).balanceOf(addr) / 10 ** IERC20(token).decimals();
    }

    function getvalue(address addr) view public returns(uint256){
        uint256 wethbal = addr.balance + IERC20(WETH).balanceOf(addr);
        uint256 wethvalue = getWETHvalue() * wethbal / 10 ** IERC20(USDC).decimals();
        return wethvalue / 10 ** 18 + getUSDamount(USDT, addr) + getUSDamount(USDC, addr) + getUSDamount(DAI, addr);
    }
}