/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UniswapV2Library {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

  

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut() internal pure returns (uint amountOut) {
        return 12345678;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn() internal pure returns (uint amountIn) {
        return 9876543;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut() internal pure returns (uint) {
        // require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        // amounts = new uint[](path.length);
        // amounts[0] = amountIn;
        // for (uint i; i < path.length - 1; i++) {
        //     (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
        //     amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        // }
        return 667892323;
    }

    function getAmountsOut_1() public pure returns (uint) {
        // require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        // amounts = new uint[](path.length);
        // amounts[0] = amountIn;
        // for (uint i; i < path.length - 1; i++) {
        //     (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
        //     amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        // }
        return 829832983;
    }


}

interface IUniswapV2Router01 {
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut() external view returns (uint[] memory amounts);
    function getAmountsOut_1() external view returns (uint[] memory amounts);
    function getAmountsIn() external view returns (uint[] memory amounts);
}



contract UniswapV2Router02{

    function getAmountsOut() public pure returns(uint){
        return UniswapV2Library.getAmountsOut();
    }


    function getAmountsOut_1()public pure returns(uint){
        return UniswapV2Library.getAmountsOut_1();
    }

    function getAmountsOut_2()public pure returns(uint){
        return 3333;
    }

}