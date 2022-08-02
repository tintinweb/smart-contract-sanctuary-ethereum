/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;



interface IUniswap {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
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
    IERC20 DAI;

    constructor(address _uniswap, address _dai) {
        uniswap = IUniswap(_uniswap);
        DAI = IERC20(_dai);
    }

    function swapDAIForEth() external{
        uint amountIn = 1;

        require(DAI.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');

        require(DAI.approve(address(uniswap), amountIn), 'approve failed.');

        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = uniswap.WETH();
        uniswap.swapExactTokensForETH(amountIn, 0, path, msg.sender, block.timestamp);
    }

}