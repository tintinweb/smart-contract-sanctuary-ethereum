// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    address public WETH = 0xaFD5305dABA3CE11612DA37C48BFBf48D018DC26;

    constructor() {}

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function getAllPairs() external view returns (address[] memory) {
        return allPairs;
    }

    function addPair(address tokenA, address tokenB, address pair) public {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
    }

    function setPair(address pair_) public { //dummie function for compatibleness 
        getPair[pair_][address(0)] = address(0);
    }
}