// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IPriceOracle.sol";

contract ChainlinkPriceOracle is IPriceOracle {
    uint256 constant priceInUSD = uint256(10 * 1e18) * 1e8;
    AggregatorV3Interface internal priceFeed;

    constructor(address _aggregator) {
        priceFeed = AggregatorV3Interface(_aggregator);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 ethPriceInUsd, , , ) = priceFeed.latestRoundData();

        return uint256(ethPriceInUsd);
    }

    function getPriceInEth() external view override returns (uint256) {
        return priceInUSD / getLatestPrice();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IPriceOracle {
    function getPriceInEth() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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