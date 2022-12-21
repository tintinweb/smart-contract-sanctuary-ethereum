// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockAggregator {
    int256 public s_answer;

    constructor() {
        setLatestAnswer(5360444);
    }

    function setLatestAnswer(int256 answer) public {
        s_answer = answer;
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, s_answer, 0, 0, 0);
    }
}