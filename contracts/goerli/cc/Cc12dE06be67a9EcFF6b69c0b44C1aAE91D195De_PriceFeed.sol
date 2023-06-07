// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

contract PriceFeed {

    uint80  public _roundId;
    int256  public _answer;
    uint256 public _startedAt;
    uint256 public _updatedAt;
    uint80  public _answeredInRound;

    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {

        return (_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
    }

    function set(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) external {
        _roundId = roundId;
        _answer = answer;
        _startedAt = startedAt;
        _updatedAt = updatedAt;
        _answeredInRound = answeredInRound;
    }
}