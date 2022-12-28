/**
 *Submitted for verification at Etherscan.io on 2022-12-28
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

// File: docs.chain.link/samples/PriceFeeds/PriceConsumerV3.sol


pragma solidity ^0.8.7;


contract ETHPriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal priceFeed1;
    AggregatorV3Interface internal priceFeed2;
    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        priceFeed1= AggregatorV3Interface(0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7);//USDC
        priceFeed2 = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d);  ///DAI
    }

    /**
     * Returns the latest price
     */
    function getEth_Price() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price/1e8;
    }
    
    function getUSDC_Price() public view returns (int) {
        (
            , int price ,,,) = priceFeed1.latestRoundData();
        return price;
    }
     function getDAI_Price() public view returns (int) {
        (
            , int price ,,,) = priceFeed2.latestRoundData();
        return price;
    }
}