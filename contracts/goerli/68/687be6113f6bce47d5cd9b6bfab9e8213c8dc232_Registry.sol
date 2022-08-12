/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswap {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address [] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 rawAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Registry {

    //    constructor ( MinimalForwarder minimalForwarder)
    //    ERC2771Context(address(minimalForwarder)){}
    event ApproveLog(address uniswapTokenAddress, uint amountInToken);
    event PathLog(address path0, address path1);
    //
    //    function register(address owner, address toAddress, uint value) external payable {
    //        address IERC20tokenAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    //        IERC20 token = IERC20(IERC20tokenAddress);
    //        token.transferFrom(owner, toAddress, value);
    //    }

    function swap(address uniswapRouterAddress, address owner,
        address userIRC20Token, uint amountInToken,
        uint amountOutMin, address outAddress, uint deadline, uint8 permitV, bytes32 permitR, bytes32 permitS) external {
        IERC20(userIRC20Token).permit(owner, address(this), amountInToken, deadline, permitV, permitR, permitS);
        IERC20(userIRC20Token).transferFrom(owner, address(this), amountInToken);
        IUniswap uniswap = IUniswap(uniswapRouterAddress);
        address [] memory path = new address[](2);
        path[0] = userIRC20Token;
        path[1] = uniswap.WETH();
        emit PathLog(path[0], path[1]);
        IERC20(userIRC20Token).approve(address(uniswap), amountInToken);
        emit ApproveLog(address(uniswap), amountInToken);
        uniswap.swapExactTokensForETH(
            amountInToken,
            amountOutMin,
            path,
            outAddress,
            deadline
        );
    }

}