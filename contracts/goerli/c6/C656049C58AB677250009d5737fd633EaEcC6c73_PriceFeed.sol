/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// File: contracts/interfaces/IPriceFeed.sol


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
    /* TODO: implement your functions here */
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Sepolia
     * Aggregator: BTC/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    constructor(address asset_address) {
        priceFeed = AggregatorV3Interface(
            asset_address
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
            /*uint startedAt*/,
            uint lastUpdatedTime,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return (price, lastUpdatedTime);
    }
}