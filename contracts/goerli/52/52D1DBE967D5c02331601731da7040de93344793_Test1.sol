// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test1 {
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

    IUniswapV2Router private router = IUniswapV2Router(UNISWAP_V2_ROUTER);
    IERC20 private weth = IERC20(WETH);
    IERC20 private uni = IERC20(UNI);

    // Swap WETH to UNI
    function swapSingleHopExactAmountIn(
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut) {
        weth.transferFrom(msg.sender, address(this), amountIn);
        weth.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = UNI;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = WETH amount, amounts[1] = UNI amount
        return amounts[1];
    }

    // Swap UNI -> WETH -> USDC
    function swapMultiHopExactAmountIn(
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut) {
        uni.transferFrom(msg.sender, address(this), amountIn);
        uni.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](3);
        path[0] = UNI;
        path[1] = WETH;
        path[2] = USDC;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = UNI amount
        // amounts[1] = WETH amount
        // amounts[2] = USDC amount
        return amounts[2];
    }

    // Swap WETH to UNI
    function swapSingleHopExactAmountOut(
        uint amountOutDesired,
        uint amountInMax
    ) external returns (uint amountOut) {
        weth.transferFrom(msg.sender, address(this), amountInMax);
        weth.approve(address(router), amountInMax);

        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = UNI;

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

    // Swap UNI -> WETH -> USDC
    function swapMultiHopExactAmountOut(
        uint amountOutDesired,
        uint amountInMax
    ) external returns (uint amountOut) {
        uni.transferFrom(msg.sender, address(this), amountInMax);
        uni.approve(address(router), amountInMax);

        address[] memory path;
        path = new address[](3);
        path[0] = UNI;
        path[1] = WETH;
        path[2] = USDC;

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOutDesired,
            amountInMax,
            path,
            msg.sender,
            block.timestamp
        );

        // Refund UNI to msg.sender
        if (amounts[0] < amountInMax) {
            uni.transfer(msg.sender, amountInMax - amounts[0]);
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