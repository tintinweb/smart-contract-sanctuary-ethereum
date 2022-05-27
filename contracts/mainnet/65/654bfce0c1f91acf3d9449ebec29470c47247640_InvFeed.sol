/**
 *Submitted for verification at Etherscan.io on 2022-05-27
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

contract InvFeed is IFeed {
    IUniswapV2OracleCeiling public constant oracle = IUniswapV2OracleCeiling(0x7E2A6e9395df9f01C00BC3Af095068B454FD896e);
    IAggregator public constant ETH = IAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function latestAnswer() public view override returns (uint256) {
        uint256 InvDollarPrice = oracle.price() * uint256(ETH.latestAnswer());

        return InvDollarPrice / 1e8;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}