// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MockUniswapV2Pool {
    uint112 public reserve0;
    uint112 public reserve1;
    uint32 public blockTimeStampLast;
    uint public price0CumLast;
    uint public price1CumLast;
    uint public totalSupply;
    uint public decimals = 18;

    address public token0;
    address public token1;
    address public factory;

    mapping (address => uint) public balanceOf;

    constructor(address _factory) {
        init(_factory);
    }

    function init(address _factory) public {
        reserve0 = 1265853603707383427790000;
        reserve1 = 253170720741476685558;
        blockTimeStampLast = uint32(block.timestamp);
        price0CumLast =       16605707706021539124070921915727672600000000;
        price1CumLast = 39194436442927457763557598254579840882221574000000;
        totalSupply = 1000000000000000000000000;
        factory = _factory;
    }

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimeStampLast);
    }

    function setBlockTimeStampLast(uint32 blockTimeStampLast_) public {
        blockTimeStampLast = blockTimeStampLast_;
    }

    function price0CumulativeLast() public view returns (uint) {
        return price0CumLast;
    }

    function price1CumulativeLast() public view returns (uint) {
        return price1CumLast;
    }

    function setData(address tokenA, address tokenB) public {
        (token0, token1) = (tokenA, tokenB);
    }

    function setData(address tokenA, address tokenB, uint112 reserveA, uint112 reserveB) public {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (reserve0, reserve1) = tokenA < tokenB ? (reserveA, reserveB) : (reserveB, reserveA);
    }

    function setData(address tokenA, address tokenB, uint112 reserveA, uint112 reserveB, uint price0_, uint price1_) public {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (reserve0, reserve1) = tokenA < tokenB ? (reserveA, reserveB) : (reserveB, reserveA);
        (price0CumLast, price1CumLast) = tokenA < tokenB ? (price0_, price1_) : (price1_, price0_);
    }

    function transferFrom(address from, address to, uint amount) public {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }

    function mint(address to, uint amount) public {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint amount) public {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}