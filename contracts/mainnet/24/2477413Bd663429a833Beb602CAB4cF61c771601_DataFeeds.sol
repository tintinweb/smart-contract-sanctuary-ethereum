// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DataFeeds {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: 
     * Aggregator: ETH/USD
     * Address: 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e
     **/
    constructor() {
        //Sepolia
        // priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        // Goerli
        // priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

        // mainnet
         priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    function getLatestPrice() public view returns (int) {
        (
          , // uint80 roundId
          int256 answer,
          , // uint256 startedAt
          , // uint256 updatedAt
            // uint80 answeredInRound
         ) = priceFeed.latestRoundData();
        return answer / 10 ** 8 ;
    }

    function getEthPriceInMxn() public view returns(uint256){
        int256 ethInMxn = getLatestPrice();
        return uint256(ethInMxn)*20;
    }
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