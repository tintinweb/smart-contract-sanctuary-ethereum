/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;



interface IUniswap {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
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

contract MyApp {
    IUniswap uniswap;

    constructor(address _uniswap) {
        uniswap = IUniswap(_uniswap);
    }

    function swapETHForToken(uint amountOut, address token) external payable{
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = address(token);
        uniswap.swapETHForExactTokens(amountOut, path, msg.sender, block.timestamp);
        require(IERC20(token).transferFrom(address(this), msg.sender, amountOut), 'transferFrom failed.');
    }

}