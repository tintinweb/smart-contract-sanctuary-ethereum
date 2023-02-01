/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract UniswapExample {
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address private constant USDT = 0xFb7378D0997B0092bE6bBf278Ca9b8058C24752f;
    address private constant USDC = 0xEEa85fdf0b05D1E0107A61b4b4DB1f345854B952;

    IUniswapV2Router private router = IUniswapV2Router(UNISWAP_V2_ROUTER);
    IERC20 private weth = IERC20(WETH);
    IERC20 private usdt = IERC20(USDT);
    IERC20 private usdc = IERC20(USDC);

    function approveWethContract(uint amountIn) external {
        usdc.approve(address(this), amountIn);
    }

    //EOA -> this current contract approval  (//move tokens)
    //currenct contract -> uniswap router contract (//move tokens) 

    function approveWethRouter(uint amountIn) external {
        usdc.approve(address(router), amountIn);
    }

    function checkAllowance() external view returns(uint amount1, uint amount2) { 
        amount1 = usdc.allowance(msg.sender, address(this));
        amount2 = usdc.allowance(msg.sender, address(router));
    }

    function transferWeth(uint amountIn) external {
        usdc.transferFrom(msg.sender, address(this), amountIn);
    }
    
    function swapSingleHopExactAmountIn(uint amountIn, uint amountOutMin) external returns (uint amountOut) {
        address[] memory path;
        path = new address[](2);
        path[0] = USDC;
        path[1] = USDT;

        uint timestamp = block.timestamp + 5 minutes;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            timestamp
        );

        // amounts[0] = WETH amount, amounts[1] = USDC amount
        return amounts[1];
    }

    // Swap USDT -> WETH -> USDC
    function swapMultiHopExactAmountIn(
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut) {
        usdt.transferFrom(msg.sender, address(this), amountIn);
        usdt.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](3);
        path[0] = USDT;
        path[1] = WETH;
        path[2] = USDC;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = USDT amount
        // amounts[1] = WETH amount
        // amounts[2] = USDC amount
        return amounts[2];
    }

    // Swap WETH to USDT
    function swapSingleHopExactAmountOut(
        uint amountOutDesired,
        uint amountInMax
    ) external returns (uint amountOut) {
        weth.transferFrom(msg.sender, address(this), amountInMax);
        weth.approve(address(router), amountInMax);

        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = USDT;

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOutDesired,
            amountInMax,
            path,
            msg.sender,
            block.timestamp
        );

        // Refund WETH to msg.sender
        if (amounts[0] < amountInMax) {
            weth.transfer(msg.sender, amountInMax - amounts[0]);
        }

        return amounts[1];
    }

    // Swap USDT -> WETH -> USDC
    function swapMultiHopExactAmountOut(
        uint amountOutDesired,
        uint amountInMax
    ) external returns (uint amountOut) {
        usdt.transferFrom(msg.sender, address(this), amountInMax);
        usdt.approve(address(router), amountInMax);

        address[] memory path;
        path = new address[](3);
        path[0] = USDT;
        path[1] = WETH;
        path[2] = USDC;

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOutDesired,
            amountInMax,
            path,
            msg.sender,
            block.timestamp
        );

        // Refund USDT to msg.sender
        if (amounts[0] < amountInMax) {
            usdt.transfer(msg.sender, amountInMax - amounts[0]);
        }

        return amounts[2];
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

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
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