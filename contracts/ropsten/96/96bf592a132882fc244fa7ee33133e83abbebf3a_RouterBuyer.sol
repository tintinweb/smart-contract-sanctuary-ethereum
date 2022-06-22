/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}

contract RouterBuyer{
    uint    internal _amountOutMin;

    address internal immutable weth;
    address internal immutable router;

    constructor(){
        router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        _amountOutMin = 0;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(address _token) external payable {
        address _to = msg.sender;
        address[] memory _path = new address[](2);
            _path[0]= weth;
            _path[1]=_token;
        uint _deadline = block.timestamp + 15 minutes;
        IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(_amountOutMin, _path, _to, _deadline);
    }
}