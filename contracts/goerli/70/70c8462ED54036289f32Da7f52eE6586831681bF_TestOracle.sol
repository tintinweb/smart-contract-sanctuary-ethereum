// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TestOracle is AggregatorV3Interface {
    // OracleInterface public oracle;
    uint80 lastRoundId;

    mapping(uint80 => data) public roundData;

    struct data {
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    function setRoundData(uint80 _roundId, int256 answer, uint256 startAt, uint256 updatedAt) external {
        data memory d = data(answer, startAt, updatedAt, 0);
        roundData[_roundId] = d;
        lastRoundId = _roundId;
    }

    function version() external view override returns (uint256) {
        return 1;
    }

    function decimals() external view override returns (uint8) {
        return 18;
    }

    function description() external view override returns (string memory) {
        return "MockPricer";
    }

    function getRoundData(uint80 _roundId) external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        data memory d = roundData[_roundId];
        return (
        _roundId,
        d.answer,
        d.startedAt,
        d.updatedAt,
        d.answeredInRound
        );
    }

    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        data memory d = roundData[lastRoundId];
        return (
        lastRoundId,
        d.answer,
        d.startedAt,
        d.updatedAt,
        d.answeredInRound
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}