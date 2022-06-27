// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOracle.sol";
import "../interfaces/IChainlinkV3Aggregator.sol";

contract MockChainlinkUSDAdapter is IOracle {
    uint256 public override viewPriceInUSD;

    constructor(uint256 price) {
        viewPriceInUSD = price;
    }

    function setViewPriceInUSD(uint256 price) external {
        viewPriceInUSD = price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function viewPriceInUSD() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkV3Aggregator {
  function decimals() external view returns (uint8);

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