pragma solidity ^0.8.16;

// import "forge-std/console2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract ChainlinkFeedMock is AggregatorV2V3Interface {
    int256 latestPrice;
    int256 price;
    uint256 updatedTimestamp;
    string description_;

    constructor(
        int256 _latestPrice,
        int256 _price,
        string memory _description
    ) {
        latestPrice = _latestPrice;
        price = _price;
        updatedTimestamp = block.timestamp - 1 days;
        description_ = _description;
    }

    /**
     * Functions only for mocks
     */
    function setLatestPrice(int256 _latestPrice) external {
        latestPrice = _latestPrice;
    }

    function setPrice(int256 _price) external {
        price = _price;
    }

    function setupdatedTimestamp(uint256 _updatedTimestamp) external {
        updatedTimestamp = _updatedTimestamp;
    }

    /**
     * Inherit functions
     */
    function latestAnswer() external view override returns (int256) {
        return latestPrice;
    }

    function latestTimestamp() external view override returns (uint256) {}

    function latestRound() external view override returns (uint256) {
        return block.timestamp;
    }

    function getAnswer(uint256 roundId) external view override returns (int256) {}

    function getTimestamp(uint256 roundId) external view override returns (uint256) {
        roundId = 0;
        return block.timestamp;
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external view override returns (string memory) {
        return description_;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        _roundId = 0;
        return (0, price, 0, updatedTimestamp, 0);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, latestPrice, 0, block.timestamp, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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