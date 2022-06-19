/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

    abstract contract dex {
        function name() external pure virtual returns (string memory);
        function symbol() external pure virtual returns (string memory);
        function decimals() external pure virtual returns (uint8);
        function totalSupply() external view virtual returns (uint);   
        function factory() external view virtual returns (address);
        function getPair(address tokenA, address tokenB) external view virtual returns (address pair);
        function token0() external view virtual returns (address);
        function token1() external view virtual returns (address);
        function getReserves() external view virtual returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);       
    }

contract dexinfo {
    struct dexStruct {
        address factory;
        address pair;
        string dexName;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 blockTimestampLast;
        string token0Name;
        string token0Symbol;
        uint256 token0Decimal;
        uint256 token0Supply;
        string token1Name;
        string token1Symbol;
        uint256 token1Decimal;
        uint256 token1Supply;
    }

    function getInfo(address add, address token0, address token1, uint8 method) public view returns (dexStruct memory){
        dexStruct memory dexInfo;
        if(method == 0){ //router
            dexInfo.factory = dex(add).factory();
            dexInfo.pair = dex(dexInfo.factory).getPair(token0, token1);
        } else if(method == 1){ // factory
            dexInfo.factory = add;
            dexInfo.pair = dex(dexInfo.factory).getPair(token0, token1);
        } else if(method == 2){ // pair
            dexInfo.pair = add;
        }

        dexInfo.dexName = dex(dexInfo.pair).name();
        dexInfo.token0 = dex(dexInfo.pair).token0();
        dexInfo.token1 = dex(dexInfo.pair).token1();
        (dexInfo.reserve0, dexInfo.reserve1, dexInfo.blockTimestampLast) = dex(dexInfo.pair).getReserves();
        dexInfo.token0Name = dex(dexInfo.token0).name();
        dexInfo.token0Symbol = dex(dexInfo.token0).symbol();
        dexInfo.token0Decimal = dex(dexInfo.token0).decimals();
        dexInfo.token0Supply = dex(dexInfo.token0).totalSupply();
        dexInfo.token1Name = dex(dexInfo.token1).name();
        dexInfo.token1Symbol = dex(dexInfo.token1).symbol();
        dexInfo.token1Decimal = dex(dexInfo.token1).decimals();
        dexInfo.token1Supply = dex(dexInfo.token1).totalSupply();     

        return dexInfo;
    }
}