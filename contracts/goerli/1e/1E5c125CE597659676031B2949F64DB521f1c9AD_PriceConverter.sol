// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import vrfCoordinator
// - set constant minimum usd value : A
// - get ETH / USD pricefeed data : B
// - convert mimum usd value to minimum eth value : A * B

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConverter {
    // pricefeed with type AggregatorV3Interface
    // reference pricefeed using goerli testnet address in constructor

    /* state variables */
    AggregatorV3Interface private pricefeed;
    int256 private constant MINIMUM_FUND_AMOUNT_USD = 100;
    int256 private ethUsdRatio;

    constructor(address aggregatorAddress) {
        pricefeed = AggregatorV3Interface(aggregatorAddress);
        (, ethUsdRatio, , , ) = pricefeed.latestRoundData();
    }

    function getLatestPrice() public view returns (int256) {
        return ethUsdRatio;
    }

    function getMinimumUSD() public pure returns (int256) {
        return MINIMUM_FUND_AMOUNT_USD;
    }

    function getMinimumETH() public view returns (int256) {
        return (ethUsdRatio * MINIMUM_FUND_AMOUNT_USD) / 10**8;
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