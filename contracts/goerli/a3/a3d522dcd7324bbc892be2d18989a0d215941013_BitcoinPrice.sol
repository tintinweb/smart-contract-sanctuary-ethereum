// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../interfaces/IBitcoinPrice.sol";
import "chainlink/v0.8/interfaces/AggregatorV3Interface.sol";

contract BitcoinPrice is IBitcoinPrice {
  AggregatorV3Interface internal priceFeed;
  uint256 lastPrice;
  uint256 s_timestamp;

  constructor() {
    priceFeed = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
    lastPrice = 0;
  }

  function fetch() public {
    (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
      priceFeed.latestRoundData();
    lastPrice = uint256(price);
    s_timestamp = timeStamp;
  }

  function getPrice() public view returns (uint256) {
    return lastPrice;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IBitcoinPrice {
  function getPrice() external view returns (uint256 price);
}