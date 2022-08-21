/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// License-Identifier: MIT
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


// File contracts/TestFeedV1.sol

// License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestFeedV1 {

    AggregatorV3Interface internal priceFeedBtcUsd;
    AggregatorV3Interface internal priceFeedEthUsd;
    AggregatorV3Interface internal priceFeedLinkUsd;

    /**
     * Network: Goerli
     * Aggregator: BTC/ETH, BTC/USD, ETH/USD, LINK/ETH, LINK/USD
     */
    constructor() {
        priceFeedBtcUsd = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
        priceFeedEthUsd = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        priceFeedLinkUsd = AggregatorV3Interface(0x48731cF7e84dc94C5f84577882c14Be11a5B7456);
    }

    /**
     * Returns the latest price BTC/USD
     */
    function getLatestPriceBTC() public view returns (uint80, int, uint) {
        (
            uint80 roundID,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeedBtcUsd.latestRoundData();
        return (roundID, price, timeStamp);
    }

    /**
     * Returns the latest price ETH/USD
     */
    function getLatestPriceEth() public view returns (uint80, int, uint) {
        (
            uint80 roundID,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeedEthUsd.latestRoundData();
        return (roundID, price, timeStamp);
    }

    /**
     * Returns the latest price LINK/USD
     */
    function getLatestPriceLink() public view returns (uint80, int, uint) {
        (
            uint80 roundID,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeedLinkUsd.latestRoundData();
        return (roundID, price, timeStamp);
    }
}