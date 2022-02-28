pragma solidity ^0.8.4;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Intermediate contract for obtaining index prices, can be used in future to get custom
//prices


//Can use a price converter function to derive different price denominations - eg use eth/usd and aud/usd to get eth/aud 
contract OraclePrice {
    mapping(string => address) public priceOracles;
    AggregatorV3Interface internal priceFeed;

    constructor () {
        priceOracles["USDC/ETH"] = 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf;
        priceOracles["DAI/USD"] = 0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF;
        priceFeed = AggregatorV3Interface(priceOracles["USDC/ETH"]);

    }
    
    function getPrice(string memory pair) public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
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