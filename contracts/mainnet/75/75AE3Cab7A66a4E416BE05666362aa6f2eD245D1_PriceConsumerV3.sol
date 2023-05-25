/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
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

// File: contracts/PriceConsumerV3.sol


pragma solidity >=0.4.22 <0.9.0;


contract PriceConsumerV3 {

    AggregatorV3Interface internal ETHpriceFeed;

    /**
     * Network: Sepolia Testnet
     * Aggregator: ETH/USD
     * ETH: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     
     * Network: Ethereum Mainnet
     * Aggregator: ETH/USD
     * ETH: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        ETHpriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }
  
    /**
     * Returns the usdc latest price
     */
    function getETHLatestPrice() public view returns (uint256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ETHpriceFeed.latestRoundData();
        return uint256(price);
    }
}