/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: chainlink.sol



pragma solidity ^0.8.0;


contract ChainlinkPriceFeed {
   
    AggregatorV3Interface public priceFeed;
    
    event PriceUpdated(uint256 price);
    event VolatilityUpdated(uint256 volatility);

    // Constructor
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // Get the latest price from the price feed
    function getLatestPrice() public returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(answer > 0, "Invalid price value");
        uint256 price = uint256(answer);

        emit PriceUpdated(price);
        
        return price;
    }

  
    function updateVolatility() external {
        

        uint256 volatility;
       
        
        emit VolatilityUpdated(volatility);
    }
    
  
}