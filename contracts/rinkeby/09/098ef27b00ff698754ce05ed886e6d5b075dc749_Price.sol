/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// File: PboxPrice.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ILpToken {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}

interface IRouter {
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

contract Price {

    address public immutable factory;
    address public immutable router;
    address public PBOX;
    address public WETH;

    constructor(address _factory, address _router ,address _PBOX, address _WETH) {
        factory = _factory;
        router = _router;
        PBOX = _PBOX;
        WETH = _WETH;
    }
    
    function pboxToEth(uint256 amountIn) public view returns (uint256 usd) {
        uint256 amountOut;
        address LpToken = IFactory(factory).getPair(WETH, PBOX);
        require(LpToken != address(0), "liquidity pair does not exist");
        if(ILpToken(LpToken).token0() == PBOX) {
            (uint256 _PBOX, uint256 _WETH, ) = ILpToken(LpToken).getReserves();
            amountOut = IRouter(router).quote(amountIn, _PBOX, _WETH);
        }
        else {
            (uint256 _WETH, uint256 _PBOX, ) = ILpToken(LpToken).getReserves();
            amountOut = IRouter(router).quote(amountIn, _PBOX, _WETH);
        }
        return amountOut;
    }
}