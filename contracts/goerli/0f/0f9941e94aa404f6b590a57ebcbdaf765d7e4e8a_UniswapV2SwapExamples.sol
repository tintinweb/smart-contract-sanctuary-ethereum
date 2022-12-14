/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract UniswapV2SwapExamples {
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address private constant RESET = 0x30df7D7EE52c1b03cd009e656F00AB875AdCEeD2;
    address constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

    IUniswapV2Router private router = IUniswapV2Router(UNISWAP_V2_ROUTER);
    IERC20 private weth = IERC20(WETH);
    IERC20 private reset = IERC20(RESET);


    // Swap RESET -> WETH -> USDC
    function swapMultiHopExactAmountIn(uint amountIn, uint amountOutMin)
        external
        returns (uint amountOut)
    {
        reset.transferFrom(msg.sender, address(this), amountIn);
        reset.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](3);
        path[0] = RESET;
        path[1] = WETH;
        path[2] = USDC;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // // amounts[0] = RESET amount
        // // amounts[1] = WETH amount
        // // amounts[2] = USDC amount
        return amounts[2];
    }

    // Swap RESET to WETH
    function swapSingleHopExactAmountIn(uint amountIn, uint amountOutMin)
        external
        returns (uint amountOut)
    {
        reset.transferFrom(msg.sender, address(this), amountIn);
        reset.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = RESET;
        path[1] = WETH;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = RESET amount, amounts[1] = WETH amount
        return amounts[1];
    }
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}