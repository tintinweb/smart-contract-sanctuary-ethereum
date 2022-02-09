/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )external payable returns (uint[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

 contract alfaBuyer {

     IUniswapV2Router02 private uniswapV2Router;

     constructor() {
         uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
     }

    function getWETH() public view returns(address) {
        return uniswapV2Router.WETH();
    }
    

 }