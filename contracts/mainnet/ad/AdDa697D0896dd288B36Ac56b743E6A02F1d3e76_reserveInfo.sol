/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
//import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";
//import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol";


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


contract reserveInfo {    
    address  private addr_factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;  
    IUniswapV2Factory private factory;
    constructor(){
            factory = IUniswapV2Factory(addr_factory);
    } 


    function getReservesInfo(address tokenA,address tokenB) public view returns(uint[2] memory){ 
        address[1] memory addr_pair;
        addr_pair[0] = factory.getPair(tokenA,tokenB);
        (uint x,uint y,) = IUniswapV2Pair(addr_pair[0]).getReserves(); 
        uint[2] memory reserveInfo1;
        (reserveInfo1[0],reserveInfo1[1]) = tokenA < tokenB ? (x,y):(y,x);
        return(reserveInfo1);
    }

    function getReservesInfo2(address tokenA,address tokenB,address tokenC) public view returns(uint[4] memory){ 
        address[2] memory addr_pair;
        addr_pair[0] = factory.getPair(tokenA,tokenB);
        addr_pair[1] = factory.getPair(tokenB,tokenC);
        (uint x1,uint y1,) = IUniswapV2Pair(addr_pair[0]).getReserves(); 
        (uint x2,uint y2,) = IUniswapV2Pair(addr_pair[1]).getReserves(); 
        uint[4] memory reserveInfo2;
        (reserveInfo2[0],reserveInfo2[1]) = tokenA < tokenB ? (x1,y1):(y1,x1);
        (reserveInfo2[2],reserveInfo2[3]) = tokenB < tokenC ? (x2,y2):(y2,x2);
        return(reserveInfo2);
    }



}