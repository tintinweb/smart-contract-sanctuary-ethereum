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

contract IDAIPriceResolver {
    string public constant name = "iDAI-price-v1.0";
    ITokenInterface public constant iToken =
        ITokenInterface(0x40a9d39aa50871Df092538c5999b107f34409061);
    AggregatorV3Interface public constant chainLinkOracleEth =
        AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4); // DAI/ETH
    AggregatorV3Interface public constant chainLinkOracleUsd =
        AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9); // DAI/USD

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