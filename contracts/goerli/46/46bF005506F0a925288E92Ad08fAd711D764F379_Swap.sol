// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract Swap {
    address public constant router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    IUniswap public swapRouter = IUniswap(router);

    /**
     * @dev Swap ETH for USDC
     */
    function swapUSDC() public payable {
    uint deadline = block.timestamp + 100;
    address[] memory path = new address[](2);
    path[0] = address(WETH);
    path[1] = address(USDC);

    // Send all balance
    uint256 amount = address(this).balance;

    // TODO: Check the result
    swapRouter.swapExactETHForTokens{value: amount}(0, path, address(this), deadline);
}
}