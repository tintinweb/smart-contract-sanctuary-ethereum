/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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

contract ArbSwap {
    struct Params {
        bytes path;
        uint256 amountIn;
        uint256 amountOut;
    }
     address owner;
     address v3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
     constructor() {
        owner = msg.sender;
    }
    function ammSwap(address router,bool input,address[] calldata path,uint amountIn, uint amountOut) public {
        require(msg.sender == owner,"fake");
        IERC20(path[0]).approve(router,amountIn);
        input ? ISwapRouter(router).swapTokensForExactTokens(amountOut,amountIn,path,address(this),block.timestamp) : ISwapRouter(router).swapExactTokensForTokens(amountIn,amountOut,path,address(this),block.timestamp);
    }

    function uniV3Swap(bool input,address approveAddress ,Params calldata params) public {
        require(msg.sender == owner,"fake");
        IERC20(approveAddress).approve(v3Router,params.amountIn);
        if(input) {
           ISwapRouter.ExactOutputParams memory inputParams = ISwapRouter.ExactOutputParams({
                path: params.path,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: params.amountOut,
                amountInMaximum: params.amountIn
            });
           ISwapRouter(v3Router).exactOutput(inputParams); 

        } else {

            ISwapRouter.ExactInputParams memory outParams = ISwapRouter.ExactInputParams({
                path: params.path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOut
            });
           ISwapRouter(v3Router).exactInput(outParams);
        }
    }

    function withdraw (address coin,address manage) public {
        require(msg.sender == owner,"fake");
        IERC20 token = IERC20(coin);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(manage,amount);
    }

    receive () external payable {}


    

}