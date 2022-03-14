//SPDX-License-Identifier

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract currenciesToUsd {
    address public owner;
    AggregatorV3Interface internal gbpUsdPriceFeed;
    AggregatorV3Interface internal jpyUsdPriceFeed;
    AggregatorV3Interface internal eurUsdPriceFeed;
    AggregatorV3Interface internal ethUsdPriceFeed;
    AggregatorV3Interface internal linkUsdPriceFeed;

    constructor(
        address _gbpPriceFeed,
        address _jpyPriceFeed,
        address _eurPriceFeed,
        address _ethPriceFeed,
        address _linkPriceFeed
    ) public {
        gbpUsdPriceFeed = AggregatorV3Interface(_gbpPriceFeed);
        jpyUsdPriceFeed = AggregatorV3Interface(_jpyPriceFeed);
        eurUsdPriceFeed = AggregatorV3Interface(_eurPriceFeed);
        ethUsdPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        linkUsdPriceFeed = AggregatorV3Interface(_linkPriceFeed);
        owner = msg.sender;
    }

    function getGbpPrice() public view returns (uint256) {
        (, int256 answer, , , ) = gbpUsdPriceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getJpyPrice() public view returns (uint256) {
        (, int256 answer, , , ) = jpyUsdPriceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getEurPrice() public view returns (uint256) {
        (, int256 answer, , , ) = eurUsdPriceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 answer, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getLinkPrice() public view returns (uint256) {
        (, int256 answer, , , ) = linkUsdPriceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }
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