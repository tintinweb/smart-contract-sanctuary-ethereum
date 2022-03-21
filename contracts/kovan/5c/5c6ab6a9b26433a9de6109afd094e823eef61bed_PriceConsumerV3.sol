// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;




    /**
     * Returns the latest price
     */
    function getLatestPrice(address CN) public payable returns (int) {
        priceFeed = AggregatorV3Interface(CN);
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