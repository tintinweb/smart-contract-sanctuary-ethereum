/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract A {
    event MyEvent (
        string ticker
    );

    Price[] public prices;
    uint public pricesCount;

    struct Price {
        string ticker;
        uint unixTimestamp;
        string lastTradedPrice;
    }

    function createPriceRequest() external {
        emit MyEvent("ETH");
    }

    function storePriceResponse(string calldata _ticker, uint _unixTimestamp, string calldata _lastTradedPrice) external {
        prices.push(Price({
            ticker: _ticker,
            unixTimestamp: _unixTimestamp,
            lastTradedPrice: _lastTradedPrice
        }));

        pricesCount++;
    }
}