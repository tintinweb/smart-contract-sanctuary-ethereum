/**
 *Submitted for verification at Etherscan.io on 2023-01-18
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

// File: priceFeed.sol


pragma solidity ^0.8.7;


contract NFTFloorPriceConsumerV3 {
    /**
     * Returns the latest price
     */
    function getLatestInfo(address collectionAddress) public view returns (uint80 roundID, int nftFloorPrice, uint startedAt, uint timeStamp, uint80 answeredInRound) {
        (
            roundID, nftFloorPrice, startedAt, timeStamp, answeredInRound            
        ) = AggregatorV3Interface(collectionAddress).latestRoundData();

    }

    function getLatestPrice(address collectionAddress) public view returns (int nftFloorPrice) {
        (
            ,
            nftFloorPrice,
            ,
            ,

        ) = AggregatorV3Interface(collectionAddress).latestRoundData();

    }

}