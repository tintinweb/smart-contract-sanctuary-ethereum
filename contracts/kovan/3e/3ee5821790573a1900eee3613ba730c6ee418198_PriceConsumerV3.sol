/**
 *Submitted for verification at Etherscan.io on 2022-06-22
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

// File: docs.chain.link/samples/PriceFeeds/PriceConsumerV3.sol


pragma solidity ^0.8.0;


contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed; 
    mapping(string => AggregatorV3Interface) public priceFeeds;

    // All the price feeds will return a dollar amount (<token_symbol>/USD)
    constructor(){
        priceFeeds["DAI"]   =  AggregatorV3Interface(0x777A68032a88E5A84678A77Af2CD65A7b3c0775a);
        priceFeeds["BAT"]   =  AggregatorV3Interface(0x8e67A0CFfbbF6A346ce87DFe06daE2dc782b3219);
        priceFeeds["COMP"]  =  AggregatorV3Interface(0xECF93D14d25E02bA2C13698eeDca9aA98348EFb6);
        priceFeeds["ZRX"]   =  AggregatorV3Interface(0x24D6B177CF20166cd8F55CaaFe1c745B44F6c203);
        priceFeeds["USDC"]  =  AggregatorV3Interface(0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60);
        priceFeeds["USDT"]  =  AggregatorV3Interface(0x2ca5A90D34cA333661083F89D831f757A9A50148);
        priceFeeds["UNI"]   =  AggregatorV3Interface(0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39);
    }

    /****
        @notice this function returns the price of a token in USD through chainlink data feeds
        @param _symbol the symbol of the token to get the price for (for example: ETH)
        @return (int) the price of the token in USD
    *****/
    function getLatestPriceOfToken(string memory _symbol) public view returns (int) {
          (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        )  = priceFeeds[_symbol].latestRoundData();
        return price / 10 ** 8;
    }
}