/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BuyOnLiquidityAdd {
    address public owner;
    address public tokenToBuy;
    address public uniswapRouter;
    bool public isBuying;

    constructor(address _uniswapRouter) {
        owner = msg.sender;
        uniswapRouter = _uniswapRouter;
    }

    function setTokenToBuy(address _tokenToBuy) public onlyOwner {
        tokenToBuy = _tokenToBuy;
    }

    function setUniswapRouter(address _uniswapRouter) public onlyOwner {
        uniswapRouter = _uniswapRouter;
    }

    function buyOnLiquidityAdd() public payable {
        require(msg.sender == tx.origin, "Only external accounts can call this function");
        require(isBuying == false, "Token purchase is already in progress");
        require(tokenToBuy != address(0), "Token to buy not set");
        isBuying = true;

        address weth = IUniswapV2Factory(uniswapRouter).getWETH();
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = tokenToBuy;

        uint256 deadline = block.timestamp + 300;

        // Approve token transfer to router
        IERC20(weth).approve(uniswapRouter, type(uint).max);

        // Swap ETH for token
        IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            deadline
        );

        isBuying = false;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
}

interface IUniswapV2Factory {
    function getWETH() external pure returns (address);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}