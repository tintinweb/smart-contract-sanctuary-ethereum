// SPDX-License-Identifier: MIT 

// thanks to Smart Contract Programmer on YouTube for the demo
pragma solidity 0.8.13;

contract ChainlinkETHprice {
  AggregatorV3Interface internal priceFeed;

  constructor() {
    // ETH/USD price
    priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
  }

  function getLatestPrice() public view returns (int) {
    (
      uint80 roundID,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    // for ETH/USD price is scaled up by 10^8
    return price / 1e8;
  }
}

interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int answer,
      uint startedAt,
      uint updatedAt,
      uint80 answeredInRound
    );
}