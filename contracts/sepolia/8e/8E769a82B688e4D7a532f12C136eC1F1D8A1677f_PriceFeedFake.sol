// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../src/interfaces/IPriceFeed.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceFeedFake is IPriceFeed {
  

    /**
     * @notice Returns the latest price
     */
    function getLatestPrice() public override view returns (int256) {
        return 14220224000000000000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IPriceFeed {
    // Cost of quote token to base token
    function getLatestPrice() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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