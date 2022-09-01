/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL
pragma solidity >=0.7.0 < 0.9.0;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

    function latestRoundData() external view returns (
        uint80 roundId, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound);
}

contract TestChainlinkFeederMock is IChainlinkAggregator {
    int private currentPrice;
    uint8 private decimal;

    constructor(uint8 _decimal) {
        decimal = _decimal;
    }

    function setPrice(int newPrice) public {
        currentPrice = newPrice;
    }

    function latestRoundData() external view returns (uint80, int, uint, uint, uint80) {
        return (0, currentPrice * int(10 ** decimal), 0, 0, 0);
    }

    function decimals() public view returns (uint8) {
        return decimal;
    }
}