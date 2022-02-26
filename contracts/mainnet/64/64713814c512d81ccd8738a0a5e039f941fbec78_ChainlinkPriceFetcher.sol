/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

pragma solidity 0.8.11;

interface AggregatorV3Interface {
  //
  // V3 Interface:
  //
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  // latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.

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

contract ChainlinkPriceFetcher {
  function getChainlinkPrice(AggregatorV3Interface chainlinkFeed) external view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound,
      uint256 blockTimestamp
    )
  {
    (roundId, answer, startedAt, updatedAt, answeredInRound) = chainlinkFeed.latestRoundData();
    blockTimestamp = block.timestamp;
  }
}