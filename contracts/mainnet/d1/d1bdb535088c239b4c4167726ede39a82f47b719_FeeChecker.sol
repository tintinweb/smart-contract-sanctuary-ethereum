/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.7;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
}

interface UniswapRouter {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    }

contract FeeChecker {
    address public immutable router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function feeCheck(address token) external payable virtual returns (uint buyFee, uint sellFee){
        IWETH(UniswapRouter(router).WETH()).deposit{value: msg.value}();
        address[] memory buyPath;
        address weth = UniswapRouter(router).WETH();
        buyPath = new address[](2);
        buyPath[0] = weth;
        buyPath[1] = token;
        uint ethBalance = IERC20(weth).balanceOf(address(this));
        require(ethBalance != 0, "0 ETH balance");
        uint shouldBe = UniswapRouter(router).getAmountsOut(ethBalance, buyPath)[1];
        uint balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(weth).approve(router, ~uint(0));
        UniswapRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(ethBalance, 0, buyPath, address(this), block.timestamp);
        uint tokenBalance = IERC20(token).balanceOf(address(this));
        require(tokenBalance != 0, "100% buy fee");
        buyFee = 100 - ((tokenBalance - balanceBefore) * 100 / shouldBe);
        address[] memory sellPath;
        sellPath = new address[](2);
        sellPath[0] = token;
        sellPath[1] = weth;
        shouldBe = UniswapRouter(router).getAmountsOut(tokenBalance, sellPath)[1];
        balanceBefore = IERC20(weth).balanceOf(address(this));
        IERC20(token).approve(router, ~uint(0));
        UniswapRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenBalance, 0, sellPath, address(this), block.timestamp);
        sellFee = 100 - ((IERC20(weth).balanceOf(address(this)) - balanceBefore) * 100 / shouldBe);
    }
}