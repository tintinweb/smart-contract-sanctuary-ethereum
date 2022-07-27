import "../../v0.6/src/interfaces/AggregatorV3Interface.sol";

contract MockGASAggregator is AggregatorV3Interface {
    int256 public answer;
    constructor (int256 _answer) {
        answer = _answer;
    }
    function decimals() external override view returns (uint8) {
        return 18;
    }
    function description() external override view returns (string memory) {
        return "MockGASAggregator";
    }
    function version() external override view returns (uint256) {
        return 1;
    }
    function getRoundData(uint80 _roundId) external override view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, answer, block.timestamp, block.timestamp, 1);
    }
    function latestRoundData() external override view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, answer, block.timestamp, block.timestamp, 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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