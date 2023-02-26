// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IPriceFeed.sol";

contract PriceFeed is IPriceFeed {
    AggregatorV3Interface internal priceFeed;

	
    // Constructor function to initialize the price feed contract address
    constructor(address contractAddress) {
    priceFeed = AggregatorV3Interface(
        contractAddress
    );
}

    // Returns the latest price and updated time
    function getLatestPrice() external view returns (int, uint) {
		(
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            uint lastUpdatedTime,
            /*uint80 answeredInRound*/
		) = priceFeed.latestRoundData();
        return (price, lastUpdatedTime);
	}

    // Returns historical price for a round id.
    function getHistoricalPrice(uint80 roundId) public view returns (int256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
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