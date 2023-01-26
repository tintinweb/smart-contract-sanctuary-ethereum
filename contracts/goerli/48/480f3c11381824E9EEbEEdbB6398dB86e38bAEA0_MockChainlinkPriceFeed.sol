// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IAggregatorV3 {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";

contract MockChainlinkPriceFeed is IAggregatorV3 {
  string simulatedDescription;
  uint8 simulatedDecimals;
  int256 fakePrice;

  constructor(string memory description_, uint8 decimals_, int256 fakePrice_) {
    simulatedDescription = description_;
    simulatedDecimals = decimals_;
    fakePrice = fakePrice_;
  }

  function setPriceFeedData(
    string memory description_,
    uint8 decimals_,
    int256 fakePrice_
  )
    external
  {
    simulatedDescription = description_;
    simulatedDecimals = decimals_;
    fakePrice = fakePrice_;
  }

  function decimals() external view override returns (uint8) {
    return simulatedDecimals;
  }

  function description() external view override returns (string memory) {
    return simulatedDescription;
  }

  function version() external pure override returns (uint256) {
    return 4;
  }

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = _roundId;
    answer = fakePrice;
    startedAt = 1577880000;
    updatedAt = 1577880000;
    answeredInRound = _roundId;
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = 92233720368547793488;
    answer = fakePrice;
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = roundId;
  }
}