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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FakeChainlinkOracle  is AggregatorV3Interface {
  int256 private answer;
  string private oracleDescription;

  constructor(int256 _answer, string memory _oracleDescription) {
    answer = _answer;
    oracleDescription = _oracleDescription;
  }

  function decimals() external pure returns (uint8) {
    return 8;
  }

  function description() external view returns (string memory) {
    return oracleDescription;
  }

  function version() external pure returns (uint256) {
    return 3;
  }

  function setAnswer(int256 _answer) public {
    answer = _answer;
  }

  function latestRoundData() external view returns(
    uint80 roundId,
    int256,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  ) {
    return (
      92233720368547777283,
      answer,
      1644641759,
      1644641759,
      92233720368547777283
    );
  }

  function getRoundData(uint80 _roundId) external view returns(
    uint80 roundId,
    int256,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  ) {
    return (
      92233720368547777283,
      answer,
      1644641759,
      1644641759,
      92233720368547777283
    );
  }
}