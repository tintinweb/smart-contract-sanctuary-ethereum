/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IEthV2Interface {
    function exchangePrice()
            external
            view
            returns (uint256);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

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

contract IETHPriceResolver {
    string public constant name = "iETH-price-v2.0";

    IEthV2Interface public constant iV2Token = 
        IEthV2Interface(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);  // iETH V2
    AggregatorV3Interface public constant chainLinkOracle = 
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD price feed

    function getPriceInUsd() public view returns (uint256 priceInUsd) {
        uint256 exchangeRate =  iV2Token.exchangePrice();
        ( , int256 oraclePrice, , , ) = chainLinkOracle.latestRoundData();
        uint8 decimals = chainLinkOracle.decimals();

        return (exchangeRate * uint256(oraclePrice)) / (10 ** decimals);
    }

    function getPriceInEth() public view returns (uint256 priceInEth) {
        uint256 exchangeRate =  iV2Token.exchangePrice();
        return (exchangeRate);
    }

    function getExchangeRate() public view returns (uint256 exchangeRate) {
        exchangeRate =  iV2Token.exchangePrice();
    }
}