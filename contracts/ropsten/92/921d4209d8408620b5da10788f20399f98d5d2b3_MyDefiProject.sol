/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IUniswap {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract MyDefiProject {
    IUniswap uniswap;

    event Log(uint256 val);

    constructor(address _uniswap) {
        uniswap = IUniswap(_uniswap);
    }

    function swapTokensForETH(
        address token,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external {
        emit Log(0);

        IERC20(token).approve(address(this), amountIn);

        emit Log(1);

        IERC20(token).transferFrom(msg.sender, address(this), amountIn);

        emit Log(2);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        IERC20(token).approve(address(uniswap), amountIn);

        emit Log(3);
        uniswap.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            deadline
        );
        emit Log(4);
    }
}