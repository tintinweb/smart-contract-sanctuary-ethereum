// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CoingeckoOracle {
    uint256 public ethUsdPrice;
    uint256 public lastUpdated;

    event PriceUpdated(uint256 indexed timeStamp, uint256 price);

    receive() external payable {}

    function updatePrice(uint256 _price) external {
        ethUsdPrice = _price;
        lastUpdated = block.timestamp;

        emit PriceUpdated(block.timestamp, _price);
    }
}