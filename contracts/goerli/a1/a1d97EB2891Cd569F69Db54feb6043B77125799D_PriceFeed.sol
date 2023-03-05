/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IPriceFeed {
    function getLatestPrice() external view returns (
        int price,
        uint lastUpdatedTime
    );
}

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



contract PriceFeed is IPriceFeed {
    AggregatorV3Interface internal priceFeed;
    string public assetName;

    constructor(string memory name, address addr) {
        assetName = name;
        priceFeed = AggregatorV3Interface(addr);
    }

    function getLatestPrice() external view returns (int, uint) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return (price, timeStamp);
    }
}