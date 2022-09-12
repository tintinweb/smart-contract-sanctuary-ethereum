/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

contract UniswapV2Pool {
    address public immutable factory;

    event PairAddress(address indexed addrOfPair);

    constructor(address _factory) public {
        factory = _factory;
    }

    function liquidPairList() public returns (address[] memory pairList) {
        address token0 = 0xB404c51BBC10dcBE948077F18a4B8E553D160084;
        address token1 = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

        address addrOfPair = IUniswapV2Factory(factory).getPair(token0, token1);

        emit PairAddress(addrOfPair);
    }
}