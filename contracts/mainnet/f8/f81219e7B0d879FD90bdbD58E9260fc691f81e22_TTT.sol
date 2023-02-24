pragma solidity ^0.8.4;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract TTT {
    function g(address addr)
        public
        view
        returns (uint256 price, uint8 decimals)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(addr);
        (, uint256 price1, , , ) = priceFeed.latestRoundData();
        price = uint256(price1);
        decimals = priceFeed.decimals();
    }

    function c(address addr) public view returns (uint256 rate) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(addr);
        (, uint256 price1, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();

        return (uint256(10000 ether) / uint256(price1)) * 10**(12 - decimals);
    }

    function d(address addr) public view returns (uint256 rate) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(addr);
        (, uint256 price1, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();

        return (uint256(1000000 ether) / uint256(price1)) * 10**(10 - decimals);
    }
}