// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Goerli
interface ISupraSValueFeed {
    function checkPrice(string memory marketPair) external view returns (int256 price, uint256 timestamp);
}

contract SupraSValueFeedExample {
    ISupraSValueFeed internal sValueFeed;

    constructor() {}

    function setSValueFeed(address feed) external {
        sValueFeed = ISupraSValueFeed(feed);
    }

    function getAvaxUsdtPrice() external view returns (int) {
        (
            int price,
            /* uint timestamp */
        ) = sValueFeed.checkPrice("avax_usdt");

        return price;
    }
}