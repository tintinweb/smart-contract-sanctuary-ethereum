// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract NFTFloorPriceConsumerV3 {
    AggregatorV3Interface internal nftFloorPriceFeed;

    /**
     * Network: Goerli
     * Aggregator: CryptoPunks
     * Address: 0x5c13b249846540F81c093Bc342b5d963a7518145


     https://docs.chain.link/data-feeds/nft-floor-price/addresses/
        0x9F6d70CDf08d893f0063742b51d3E9D1e18b7f74 for azuki

     */
    constructor() {
        nftFloorPriceFeed = AggregatorV3Interface(
            0x9F6d70CDf08d893f0063742b51d3E9D1e18b7f74
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int nftFloorPrice /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = nftFloorPriceFeed.latestRoundData();
        return nftFloorPrice;
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