// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./AggregatorV2V3Interface.sol";

contract SeacowsGroupFeed is AggregatorV2V3Interface {
   
  uint256 public constant version = 0;

  uint8 public decimals;
  int256 public latestAnswer;
  uint256 public latestTimestamp;
  uint256 public latestRound;

  address public registry;
  address public collection;
  uint256 public groupId;

  mapping(uint256 => int256) public getAnswer;
  mapping(uint256 => uint256) public getTimestamp;
  mapping(uint256 => uint256) private getStartedAt;

  constructor() public {
    registry = msg.sender;
  }

  function initialize(address _collection, uint256 _groupId) external {
    require(msg.sender == registry, 'GroupFeed: FORBIDDEN');
    collection = _collection;
    groupId = _groupId;
  }

  function updateAnswer(int256 _answer) public onlyRegistry() {
    latestAnswer = _answer;
    latestTimestamp = block.timestamp;
    latestRound++;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = block.timestamp;
    getStartedAt[latestRound] = block.timestamp;
  }

  function updateRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public  onlyRegistry() {
    latestRound = _roundId;
    latestAnswer = _answer;
    latestTimestamp = _timestamp;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = _timestamp;
    getStartedAt[latestRound] = _startedAt;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
  }

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      uint80(latestRound),
      getAnswer[latestRound],
      getStartedAt[latestRound],
      getTimestamp[latestRound],
      uint80(latestRound)
    );
  }

  function description() external view returns (string memory) {
    return "v0.0.1/GroupFeed.sol";
  }

  modifier onlyRegistry() {
    require(msg.sender == registry, "only registry may call");
    _;
  }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface AggregatorV2V3Interface {
  //
  // V2 Interface:
  //
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

  //
  // V3 Interface:
  //
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