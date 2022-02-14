// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 staartedAt,
        uint256 updatedAt,
        uint80 answerInRound
    );

}

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    function getLatestPrice() public view returns(int) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }
}