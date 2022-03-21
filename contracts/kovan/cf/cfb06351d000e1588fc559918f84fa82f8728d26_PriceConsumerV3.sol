pragma solidity ^0.8.7;

import "../AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;


    function getLatestPrice(address feed) public returns (int) {
        priceFeed = AggregatorV3Interface(feed);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}