// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract TestAggregator {
    int256 private value = 2 * 10**7; // 0.2 USDT per ALBT

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, value, 0, 0, 0);
    }

    function setValue(int256 _value) external {
        value = _value;
    }
}