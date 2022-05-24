// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

// EACAggregatorProxy is (AggregatorProxy is AggregatorV2V3Interface)
contract MockChainlinkOracle is AggregatorV2V3Interface {
  uint80[] internal roundIdArray;
  int256[] internal answerArray;
  uint256[] internal decimalsArray;
  uint256[] internal timestampArray;
  uint80[] internal versionArray;
  uint8 internal _decimals;

  constructor(uint8 decimals_) {
    _decimals = decimals_;
  }

  // Proxy
  function aggregator() public view returns (address) {
    return address(this);
  }

  // V2
  function latestAnswer() external view override returns (int256) {
    uint256 index = roundIdArray.length - 1;
    return answerArray[index];
  }

  function latestTimestamp() external view override returns (uint256) {
    uint256 index = roundIdArray.length - 1;
    return timestampArray[index];
  }

  function latestRound() external view override returns (uint256) {
    uint256 index = roundIdArray.length - 1;
    return roundIdArray[index];
  }

  function getAnswer(uint256 roundId) external view override returns (int256) {
    uint256 maxIndex = roundIdArray.length - 1;
    uint256 index = maxIndex + roundId - roundIdArray[maxIndex];
    return answerArray[index];
  }

  function getTimestamp(uint256 roundId) external view override returns (uint256) {
    uint256 maxIndex = roundIdArray.length - 1;
    uint256 index = maxIndex + roundId - roundIdArray[maxIndex];
    return timestampArray[index];
  }

  // V3
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function description() external pure override returns (string memory) {
    return "";
  }

  function version() external pure override returns (uint256) {
    return 0;
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
    uint256 maxIndex = roundIdArray.length - 1;
    uint256 index = maxIndex + _roundId - roundIdArray[maxIndex];
    return (roundIdArray[index], answerArray[index], decimalsArray[index], timestampArray[index], versionArray[index]);
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
    uint256 index = roundIdArray.length - 1;
    return (roundIdArray[index], answerArray[index], decimalsArray[index], timestampArray[index], versionArray[index]);
  }

  // mock
  function mockAddAnswer(
    uint80 _roundId,
    int256 _answer,
    uint256 _startedAt,
    uint256 _updatedAt,
    uint80 _answeredInRound
  ) external {
    roundIdArray.push(_roundId);
    answerArray.push(_answer);
    decimalsArray.push(_startedAt);
    timestampArray.push(_updatedAt);
    versionArray.push(_answeredInRound);

    emit AnswerUpdated(_answer, _roundId, _updatedAt);
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