/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}

contract UniswapV2RouterBuyer{
    uint _deadline;
    address _to;
    uint _amountOutMin;

    address weth;
    address token;
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor(){
        _amountOutMin = 0;
        weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        _to = 0x3F831e6BBa6C06e60A819C92Dd5F180624da6771;
        _deadline = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(address _token) external payable {
        address[] memory _path = new address[](2);
        _path[0]= weth;
        _path[1]=_token;
        IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(_amountOutMin, _path, _to, _deadline);
    }
}