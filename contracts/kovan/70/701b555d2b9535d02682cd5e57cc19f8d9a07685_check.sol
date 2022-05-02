/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/IQuoter.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;
interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external view returns (uint256 amountOut);
}


// File contracts/IUniswapV2Router.sol



pragma solidity >=0.6.2;

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}


// File contracts/check.sol

pragma solidity ^0.8.0;
contract check{
address constant uniV3Quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    function checkArbitrage(
        address _tokenBorrow, // example: usdc
        uint256 _amountTokenBorrow, // example: BNB => 10 * 1e18
        address _tokenPay, // example: eth
        address _sourceRouter
    ) public view returns(int256) {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = _tokenPay;
        path1[1] = path2[0] = _tokenBorrow;
        uint24 _fee = 500;
        uint256 amountRecieve = IUniswapV2Router(_sourceRouter).getAmountsIn(_amountTokenBorrow, path1)[0];
        //eth but usdc in uniswapv3
        uint256 amountOut = IQuoter(uniV3Quoter).quoteExactInputSingle(_tokenBorrow, _tokenPay, _fee, _amountTokenBorrow, 0);
        //usdc buy eth in sushi
        

        return int256(amountOut - amountRecieve); // our profit or loss; example output: BNB amount
        
    }
    function checkTest(
        address _tokenBorrow, // example: BUSD
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _tokenPay, // example: BNB
        address _sourceRouter,
        address _targetRouter
    ) public view returns(int256, uint256) {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = _tokenPay;
        path1[1] = path2[0] = _tokenBorrow;

        uint256 amountOut = IUniswapV2Router(_sourceRouter).getAmountsOut(_amountTokenPay, path1)[1];//[bnb,usdc] buy amountOut usdc with amounttokenpay bnb in swap1
        uint256 amountRepay = IUniswapV2Router(_targetRouter).getAmountsOut(amountOut, path2)[1];//[usdc,bnb]

        return (
            int256(amountRepay - _amountTokenPay), // our profit or loss; example output: BNB amount
            amountOut // the amount we get from our input "_amountTokenPay"; example: BUSD amount
        );
    }
    

}