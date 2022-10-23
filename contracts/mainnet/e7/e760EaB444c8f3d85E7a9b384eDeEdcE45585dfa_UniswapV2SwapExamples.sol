// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract UniswapV2SwapExamples {
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router private router = IUniswapV2Router(UNISWAP_V2_ROUTER);    

    // Swap assetIn to assetOut
    function swapSingleHopExactAmountIn(address assetIn, uint amountIn, address assetOut, uint amountOutMin)
        external
        returns (uint amoutnOut)
    {

        IERC20 coin1 = IERC20(assetIn);
        IERC20 coin2 = IERC20(assetOut);

        coin1.transferFrom(msg.sender, address(this), amountIn);
        coin1.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = assetIn;
        path[1] = assetOut;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = assetIn amount, amounts[1] = assetOut amount
        return amounts[1];
    }


    // Swap assetIn to assetOut
    function swapSingleHopExactAmountOut(address assetIn, uint amountInMax, address assetOut, uint amountOutDesired)
        external
        returns (uint amountOut)
    {

        IERC20 coin1 = IERC20(assetIn);
        IERC20 coin2 = IERC20(assetOut);

        coin1.transferFrom(msg.sender, address(this), amountInMax);
        coin1.approve(address(router), amountInMax);

        address[] memory path;
        path = new address[](2);
        path[0] = assetIn;
        path[1] = assetOut;

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOutDesired,
            amountInMax,
            path,
            msg.sender,
            block.timestamp
        );

        // Refund assetIn to msg.sender
        if (amounts[0] < amountInMax) {
            coin1.transfer(msg.sender, amountInMax - amounts[0]);
        }

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

interface IassetIn is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}