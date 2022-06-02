//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IETHInterface {
    function getCurrentExchangePrice()
            external
            view
            returns (uint256 exchangePrice_, uint256 newRevenue_);
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
    string public constant name = "iETH-price-v1.0";

    IETHInterface public constant iToken = IETHInterface(0xc383a3833A87009fD9597F8184979AF5eDFad019); // iETH
    AggregatorV3Interface public constant chainLinkOracle = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD

    function getPriceInUsd() public view returns (uint256 priceInUsd) {
        (uint256 exchangeRate, ) =  iToken.getCurrentExchangePrice();
        ( , int256 oraclePrice, , , ) = chainLinkOracle.latestRoundData();
        uint8 decimals = chainLinkOracle.decimals();

        return (exchangeRate * uint256(oraclePrice)) / (10 ** decimals);
    }

    function getPriceInEth() public view returns (uint256 priceInEth) {
        (uint256 exchangeRate, ) =  iToken.getCurrentExchangePrice();
        return (exchangeRate);
    }

    function getExchangeRate() public view returns (uint256 exchangeRate) {
        (exchangeRate, ) =  iToken.getCurrentExchangePrice();
    }
}