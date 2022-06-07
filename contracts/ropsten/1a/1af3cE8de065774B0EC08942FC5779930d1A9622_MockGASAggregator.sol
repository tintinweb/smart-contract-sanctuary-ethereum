/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

contract MockGASAggregator is AggregatorV3Interface {
    int256 public answerp;
    constructor (int256 _answer) public {
        answerp = _answer;
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
        return (1, answerp, block.timestamp, block.timestamp, 1);
    }
    function latestRoundData() external override view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, answerp, block.timestamp, block.timestamp, 1);
    }
}