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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal ethUsd;
    AggregatorV3Interface internal btcUsd;
    AggregatorV3Interface internal daiUsd;
    AggregatorV3Interface internal linkUsd;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     * Aggregator: BTC/USD
     * Address: 0xA39434A63A52E749F02807ae27335515BA4b07F7
     * Aggregator: DAI/USD
     * Address: 0x0d79df66BE487753B02D015Fb622DED7f0E9798d
     * Aggregator: LINK/USD
     * Address: 0x48731cF7e84dc94C5f84577882c14Be11a5B7456
     */
    constructor() {
        ethUsd = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        btcUsd = AggregatorV3Interface(
            0xA39434A63A52E749F02807ae27335515BA4b07F7
        );
        daiUsd = AggregatorV3Interface(
            0x0d79df66BE487753B02D015Fb622DED7f0E9798d
        );
        linkUsd = AggregatorV3Interface(
            0x48731cF7e84dc94C5f84577882c14Be11a5B7456
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = ethUsd.latestRoundData();
        return price;
    }
}