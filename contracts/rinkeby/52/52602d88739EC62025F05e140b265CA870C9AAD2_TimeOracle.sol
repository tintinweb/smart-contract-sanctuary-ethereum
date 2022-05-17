// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract TimeOracle {

    AggregatorV3Interface[] public timeFeed;

    constructor() {
        timeFeed.push(AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e));
    }

    /**
     * Returns the latest price
     */
    function getLatestTime() public view returns (uint) {
        (
            /*uint80 roundID*/,
            /*int price*/,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = timeFeed[0].latestRoundData();
        return timeStamp;
        
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