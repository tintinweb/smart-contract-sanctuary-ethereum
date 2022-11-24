/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

contract GoerliPriceConsumerV3 {
    AggregatorV3Interface internal EthUsdPriceFeed;
    AggregatorV3Interface internal BtcUsdPriceFeed;
    AggregatorV3Interface internal BtcEthPriceFeed;
    AggregatorV3Interface internal CzkUsdPriceFeed;
    AggregatorV3Interface internal DaiUsdPriceFeed;
    AggregatorV3Interface internal ForthUsdPriceFeed;
    AggregatorV3Interface internal JpyUsdPriceFeed;
    AggregatorV3Interface internal LinkEthPriceFeed;
    AggregatorV3Interface internal LinkUsdPriceFeed;
    AggregatorV3Interface internal SnxUsdPriceFeed;
    AggregatorV3Interface internal UsdcUsdPriceFeed;
    AggregatorV3Interface internal XauUsdPriceFeed;

    constructor() {
        EthUsdPriceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        BtcUsdPriceFeed = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
        BtcEthPriceFeed = AggregatorV3Interface(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        CzkUsdPriceFeed = AggregatorV3Interface(0xAE45DCb3eB59E27f05C170752B218C6174394Df8);
        DaiUsdPriceFeed = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d);
        ForthUsdPriceFeed = AggregatorV3Interface(0x7A65Cf6C2ACE993f09231EC1Ea7363fb29C13f2F);
        JpyUsdPriceFeed = AggregatorV3Interface(0x295b398c95cEB896aFA18F25d0c6431Fd17b1431);
        LinkEthPriceFeed = AggregatorV3Interface(0xb4c4a493AB6356497713A78FFA6c60FB53517c63);
        LinkUsdPriceFeed = AggregatorV3Interface(0x48731cF7e84dc94C5f84577882c14Be11a5B7456);
        SnxUsdPriceFeed = AggregatorV3Interface(0xdC5f59e61e51b90264b38F0202156F07956E2577);
        UsdcUsdPriceFeed = AggregatorV3Interface(0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7);
        XauUsdPriceFeed = AggregatorV3Interface(0x7b219F57a8e9C7303204Af681e9fA69d17ef626f);
    }
    //Returns the latest price
    function getLatestEthUsd() public view returns(uint, uint) {
        (/*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = EthUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBtcUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBtcEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestCzkUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestDaiUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestForthUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestJpyUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestLinkEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestLinkUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestSnxUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestUsdcUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestXauUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    }