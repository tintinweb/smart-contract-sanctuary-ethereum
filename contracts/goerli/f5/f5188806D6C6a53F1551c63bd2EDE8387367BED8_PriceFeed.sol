/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// File: contracts/interface/IPriceFeed.sol


pragma solidity >=0.8.0 <0.9.0;

interface IPriceFeed {
    function getLatestPrice() external view returns (
        int price,
        uint lastUpdatedTime
    );
}
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

// File: contracts/PriceFeed.sol


pragma solidity >=0.8.0 <0.9.0;



contract PriceFeed is IPriceFeed {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Sepolia
     * Aggregator: TSLA/USD
     * Address: 0x982B232303af1EFfB49939b81AD6866B2E4eeD0B
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x982B232303af1EFfB49939b81AD6866B2E4eeD0B
        );
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int, uint) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /* uint startedAt */,
            uint timeStamp,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return (price, timeStamp);
    }
}