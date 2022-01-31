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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TestnetChainlinkFeed is AggregatorV3Interface {
    uint8 private immutable _decimals;

    uint80 private _roundId;
    int256 private _latestPrice;
    uint256 private _latestStartedTimestamp;
    uint256 private _latestUpdatedTimestamp;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function description() external pure returns (string memory) {
        return "Testnet Chainlink Feed";
    }

    function version() external pure returns (uint256) {
        return 0;
    }

    function getRoundData(uint80) external pure returns (uint80, int256, uint256, uint256, uint80) {
        revert("TestnetChainlinkFeed: historical lookup unsupported");
    }

    function setLatestRound(int256 price) external {
        _roundId++;
        _latestPrice = price;
        _latestStartedTimestamp = _latestUpdatedTimestamp;
        _latestUpdatedTimestamp = block.timestamp;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (_roundId, _latestPrice, _latestStartedTimestamp, _latestUpdatedTimestamp, _roundId);
    }
}