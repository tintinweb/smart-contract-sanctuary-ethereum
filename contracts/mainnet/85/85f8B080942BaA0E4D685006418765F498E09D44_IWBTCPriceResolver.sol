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

contract IWBTCPriceResolver {
    string public constant name = "iWBTC-price-v1.0";
    ITokenInterface public constant iToken =
        ITokenInterface(0xEC363faa5c4dd0e51f3D9B5d0101263760E7cdeB);
    AggregatorV3Interface public constant chainLinkOracleWbtcinBtc =
        AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23); // WBTC/BTC
    AggregatorV3Interface public constant chainLinkOracleEth =
        AggregatorV3Interface(0xdeb288F737066589598e9214E782fa5A8eD689e8); // BTC/ETH
    AggregatorV3Interface public constant chainLinkOracleUsd =
        AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c); // BTC/USD

    function getPriceInEth() public view returns (uint256) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInEth = chainLinkOracleEth.latestAnswer();
        uint8 tokenOracleDecimals = chainLinkOracleEth.decimals();
        int256 wbtcPriceInBtc = chainLinkOracleWbtcinBtc.latestAnswer();
        uint8 wbtcOracleDecimals = chainLinkOracleWbtcinBtc.decimals();
        return
            (exchangeRate *
                uint256(tokenPriceInEth) *
                uint256(wbtcPriceInBtc)) /
            ((10**tokenOracleDecimals) * (10**wbtcOracleDecimals));
    }

    function getPriceInUsd() public view returns (uint256 priceInUsd) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInUsd = chainLinkOracleUsd.latestAnswer();
        uint8 tokenOracleDecimals = chainLinkOracleUsd.decimals();
        int256 wbtcPriceInBtc = chainLinkOracleWbtcinBtc.latestAnswer();
        uint8 wbtcOracleDecimals = chainLinkOracleWbtcinBtc.decimals();
        return
            (exchangeRate *
                uint256(tokenPriceInUsd) *
                uint256(wbtcPriceInBtc)) /
            ((10**tokenOracleDecimals) * (10**wbtcOracleDecimals));
    }

    function getExchangeRate() public view returns (uint256 exchangeRate) {
        (exchangeRate, ) = iToken.getCurrentExchangePrice();
    }
}