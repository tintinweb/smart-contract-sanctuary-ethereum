// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockPriceFeed {
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(73786976294838215160),
            int256(156739000000),
            uint256(1673795531),
            uint256(1673795531),
            uint80(73786976294838215160)
        );
    }
}