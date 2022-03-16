/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;
interface sushiRo {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Property{
    // using SafeERC20 for IERC20;
    address public SushiSwapRouterAddr = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    sushiRo public sushiRouter = sushiRo(SushiSwapRouterAddr);

    //价格：预估兑换出的token，用A兑换B，可以兑换出B的数量amountOut
    function sushiGetSwapTokenAmountOut(
        address[] memory path,
        uint amountIn
    ) public view virtual returns (uint) {
        uint amountOut = sushiRouter.getAmountsOut(
            amountIn,
            path
        )[path.length - 1];
        return amountOut;

        // return amountIn*95/100;
    }


    function test() public view returns(uint){
        address[] memory path = new address[](3);
        path[0] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        path[1] = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        path[2] = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        uint amount = sushiGetSwapTokenAmountOut(path,1000000);
        return amount;
    }



}