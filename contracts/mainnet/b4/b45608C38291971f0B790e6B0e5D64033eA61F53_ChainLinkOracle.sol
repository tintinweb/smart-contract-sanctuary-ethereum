// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SafeMath} from "../../lib/SafeMath.sol";

import {ISapphireOracle} from "../ISapphireOracle.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

contract ChainLinkOracle is ISapphireOracle {

    using SafeMath for uint256;

    AggregatorV3Interface public priceFeed;

    uint256 public scalar;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        scalar = 10 ** uint256(18 - priceFeed.decimals());
    }

    /**
     * @notice Fetches the timestamp and the current price of the asset, in 18 decimals
     */
    function fetchCurrentPrice()
        external
        override
        view
        returns (uint256, uint256)
    {
        (, int256 price, , uint256 timestamp, ) = priceFeed.latestRoundData();

        require(
            price > 0,
            "ChainLinkOracle: price was invalid"
        );

        return (
            uint256(price) * scalar,
            timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ISapphireOracle {

    /**
     * @notice Fetches the current price of the asset
     *
     * @return price The price in 18 decimals
     * @return timestamp The timestamp when price is updated and the decimals of the asset
     */
    function fetchCurrentPrice()
        external
        view
        returns (uint256 price, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
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