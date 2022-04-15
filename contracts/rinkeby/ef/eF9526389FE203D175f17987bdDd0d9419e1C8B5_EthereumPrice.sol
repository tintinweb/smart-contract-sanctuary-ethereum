/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: contracts/EthereumPrice.sol


pragma solidity ^0.8.7;


contract EthereumPrice {

    // returns the latest price for ethereum or any other coin

    AggregatorV3Interface internal priceFeed;

    constructor() {
        // You can find the address for below at https://docs.chain.link/docs/ethereum-addresses/
        priceFeed = AggregatorV3Interface(0x7B17A813eEC55515Fb8F49F2ef51502bC54DD40F);
    }

    function getEthPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int ethPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return ethPrice;
    }
}