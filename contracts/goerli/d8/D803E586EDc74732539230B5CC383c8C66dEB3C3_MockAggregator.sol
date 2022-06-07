// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

contract MockAggregator {
    int256 private _answer;
    uint80 public roundId;
    uint80 public answeredInRound;
    uint256 public updatedAt;
    uint8 public decimals;

    // AggregatorV1 event
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

    constructor(uint8 _decimals) {
        decimals = _decimals;
        roundId = 1;
        answeredInRound = 1;
        updatedAt = 1;
    }

    function latestRoundData() external view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        ) {

        return (roundId, _answer, 0, updatedAt, answeredInRound);
    }

    function latestAnswer() external view returns (int256) {
        return _answer;
    }

    function setAnswer(int256 a) external {
        _answer = a;
        emit AnswerUpdated(a, 0, block.timestamp);
    }

    function setRoundData(uint80 _roundId, uint256 _updatedAt, uint80 _answeredInRound) external {
        roundId = _roundId;
        updatedAt = _updatedAt;
        answeredInRound = _answeredInRound;
    }
}