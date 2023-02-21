/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function approve(address spender, uint value) external returns (bool);
}

contract BuyOnLiquidityAdd {
    address public tokenAddress;
    address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //mainnet uniswap router
    bool public isBuying = false;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function setTokenAddress(address _tokenAddress) external {
        require(msg.sender == address(this), "Caller is not the contract owner");
        tokenAddress = _tokenAddress;
    }

    function buyOnLiquidityAdd() external {
        require(msg.sender == address(this), "Caller is not the contract address");
        require(!isBuying, "Transaction already in progress");

        isBuying = true;

        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswapRouter).WETH();
        path[1] = tokenAddress;

        IUniswapV2Pair pair = IUniswapV2Pair(tokenAddress);

        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        pair.approve(address(uniswapRouter), type(uint).max);

        uint amountOutMin = 0;

        IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: address(this).balance}(amountOutMin, path, address(this), block.timestamp);

        isBuying = false;
    }

    receive() external payable {}
}