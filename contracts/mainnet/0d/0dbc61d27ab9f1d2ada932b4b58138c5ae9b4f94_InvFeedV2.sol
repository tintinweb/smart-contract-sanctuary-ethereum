/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}
interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface IUniswapV2OracleCeiling {
    function price() external view returns (uint256 price);
}

contract InvFeedV2 is IFeed {
    IUniswapV2OracleCeiling public constant oracle = IUniswapV2OracleCeiling(0x323959FfEB06eE77a6B84F8e193cf100E6191fB7);
    IAggregator public constant ETH = IAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function latestAnswer() public view override returns (uint256) {
        uint256 InvDollarPrice = oracle.price() * uint256(ETH.latestAnswer());

        return InvDollarPrice / 1e8;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}