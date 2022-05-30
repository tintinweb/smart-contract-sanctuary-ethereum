//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ITokenInterface {
    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256 answer);
}

contract IUSDCPriceResolver {
    string public constant name = "iUSDC-price-v1.0";
    ITokenInterface public constant iToken =
        ITokenInterface(0xc8871267e07408b89aA5aEcc58AdCA5E574557F8);
    AggregatorV3Interface public constant chainLinkOracleEth =
        AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4); // USDC/ETH
    AggregatorV3Interface public constant chainLinkOracleUsd =
        AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6); // USDC/USD

    function getPriceInEth() public view returns (uint256) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInEth = chainLinkOracleEth.latestAnswer();
        uint8 decimals = chainLinkOracleEth.decimals();
        return (exchangeRate * uint256(tokenPriceInEth)) / (10**decimals);
    }

    function getPriceInUsd() public view returns (uint256 priceInUsd) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInUsd = chainLinkOracleUsd.latestAnswer();
        uint8 decimals = chainLinkOracleUsd.decimals();
        return (exchangeRate * uint256(tokenPriceInUsd)) / (10**decimals);
    }

    function getExchangeRate() public view returns (uint256 exchangeRate) {
        (exchangeRate, ) = iToken.getCurrentExchangePrice();
    }
}