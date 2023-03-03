// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IPriceFeed.sol";

contract PriceFeed is IPriceFeed {

    AggregatorV3Interface internal priceFeed;

    /**
     * Construct price feed with hash of desired asset
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x982B232303af1EFfB49939b81AD6866B2E4eeD0B
            /* use 0x982B232303af1EFfB49939b81AD6866B2E4eeD0B for TSLA / USD */
            /* use 0x7b219F57a8e9C7303204Af681e9fA69d17ef626f for BNB / USD */
        );
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int, uint) {
        (, int price, , uint lastUpdatedTime, ) = priceFeed.latestRoundData(); 
        return (price, lastUpdatedTime); /* shouldn't be necessary? */
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IPriceFeed {
    function getLatestPrice() external view returns (
        int price,
        uint lastUpdatedTime
    );
}

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