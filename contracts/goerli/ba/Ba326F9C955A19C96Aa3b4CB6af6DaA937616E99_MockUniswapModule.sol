pragma solidity ^0.8.17;

import '@chainlink/interfaces/AggregatorV3Interface.sol';

import '@size/modules/ITwapOracle.sol';

contract MockUniswapModule is ITwapOracle {
    address public uniswapV3Pool; // the uniswap pool is actually the chainling oracle here
    uint32 public twapInterval;

    constructor(address _uniswapV3Pool, uint32 _twapInterval) {
        uniswapV3Pool = _uniswapV3Pool;
        twapInterval = _twapInterval;
    }

    function getSqrtTwapX96(
        uint32 twapInterval_
    ) external view override returns (uint160) {
        return 0;
    }

    function getPriceX96(
        uint160 sqrtPriceX96
    ) external pure override returns (uint256) {
        return 0;
    }

    function getPrice() external view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(uniswapV3Pool);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }
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

pragma solidity ^0.8.17;

interface ITwapOracle {
    function uniswapV3Pool() external view returns (address);

    function twapInterval() external view returns (uint32);

    function getSqrtTwapX96(
        uint32 twapInterval
    ) external view returns (uint160 sqrtPriceX96);

    function getPriceX96(
        uint160 sqrtPriceX96
    ) external pure returns (uint256 priceX96);

    function getPrice() external view returns (uint256 price);
}