// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IPriceFeed.sol";
import "../interfaces/AggregatorV3Interface.sol";

// Price feed smart contract
contract PriceFeed is IPriceFeed {
    AggregatorV3Interface internal priceFeed;

    /**
     * Creates an aggregator for the specified address on the Goerli testnet.
     */
    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() external view override returns (int256, uint256) {
        (
            /* uint80 roundID */,
            int256 price,
            /* uint256 startedAt */,
            uint256 timestamp,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return (price, timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IPriceFeed {
    function getLatestPrice()
        external
        view
        returns (int256 price, uint256 lastUpdatedTime);
}