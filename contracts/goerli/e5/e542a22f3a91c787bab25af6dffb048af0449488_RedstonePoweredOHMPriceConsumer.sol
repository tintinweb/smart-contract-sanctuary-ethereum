/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

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

// File: gist.githubusercontent.com/hatskier/cff1fe57ad029dcbefc1c8d25a1ab81d/raw/52af83eb34bc86750277124d4ab20152fbdbc24a/RedstoneOHMPriceFeedConsumer.sol


pragma solidity ^0.8.7;


contract RedstonePoweredOHMPriceConsumer {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Price Feed: OHM/USD
     * Address: 0x6d95D190A8Db4C8740DE7b636a93BDC1eC53dCD1
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x6d95D190A8Db4C8740DE7b636a93BDC1eC53dCD1
        );
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}