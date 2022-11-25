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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Scroll L2 Testnet and Polygon zkEVM Testnet are not supported by ChainLink
// This is mock contract of ChainLink ETH / USD price feed for those unsupported chains
// https://etherscan.io/address/0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419#readContract
// Mocked round data is 92233720368547796225

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockChainLinkPriceOracle is AggregatorV3Interface {
  uint80 constant latestRound = 92233720368547796225;

  function decimals() external pure returns (uint8) {
    return 8;
  }

  function description() external pure returns (string memory) {
    return "ETH / USD";
  }

  function version() external pure returns (uint256) {
    return 4;
  }

  function getRoundData(
    uint80 _roundId
  ) public pure returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
    require(_roundId == latestRound, "MockChainLinkPriceOracle: round id not supported");

    return (92233720368547796225, 119253000000, 1669377323, 1669377323, 92233720368547796225);
  }

  function latestRoundData()
    public
    pure
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    return getRoundData(latestRound);
  }
}