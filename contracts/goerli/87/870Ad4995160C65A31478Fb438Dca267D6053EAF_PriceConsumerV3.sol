pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
  AggregatorV3Interface internal priceFeed;

  /**
   * Network: Goerli
   * Aggregator: ETH/USD
   * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
   */
  constructor(address _priceFeed) public {
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  /**
   * Returns the latest price
   */
  function getLatestPrice() public view returns (int256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return price;
  }
}

// SPDX-License-Identifier: MIT
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