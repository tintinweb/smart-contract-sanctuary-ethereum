// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockAggregatorProxy {
  struct Data {
    uint80 roundId;         // The round ID.
    int256 answer;          // The price.
    uint256 timestamp;      // Timestamp of when the round was updated.
    uint256 roundTimestamp; // Timestamp of when the round started.
    uint80 answeredInRound; // The round ID of the round in which the answer was computed.
  }

  address public owner;
  string constant description_ = "Mock Aggregator";
  uint256 constant version_ = 1;
  uint8 public decimals_;
  uint80 public currentRoundId_;
  mapping(uint256 => Data) public data_;

  constructor(uint8 _decimals) {
    decimals_ = _decimals;
    owner = msg.sender;
  }

  modifier onlyOwner() {
      require(msg.sender == owner, "MockAggregatorProxy: only owner can call");
      _;
  }

  function changeOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function mockSetData(Data calldata data) external onlyOwner {
    data_[data.roundId] = data;
    currentRoundId_ = data.roundId;
  }

  function mockSetValidAnswer(int256 answer) external onlyOwner {
    currentRoundId_++;
    data_[currentRoundId_] = 
      Data(
        currentRoundId_,
        answer,
        block.timestamp,
        block.timestamp,
        currentRoundId_
      );
  }

  function latestAnswer() external view returns (int256) {
    return data_[currentRoundId_].answer; 
  }

  function latestTimestamp() external view returns (uint256) {
    return data_[currentRoundId_].timestamp;
  }

  function latestRound() external view returns (uint256) {
    return currentRoundId_;
  }

  function getAnswer(uint256 roundId) external view returns (int256) {
    return data_[roundId].answer;
  }

  function getTimestamp(uint256 roundId) external view returns (uint256) {
    return data_[roundId].timestamp;
  }

  function decimals() external view returns (uint8) {
    return decimals_;
  }

  function description() external pure returns (string memory) {
    return description_;
  }

  function version() external pure returns (uint256) {
    return version_;
  }

  function getRoundData(uint80 _roundId) external view 
  returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
    Data memory result = data_[_roundId];
    return (
      result.roundId,
      result.answer,
      result.timestamp,
      result.roundTimestamp,
      result.answeredInRound
    );
  }

  function latestRoundData() external view 
  returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
    Data memory result = data_[currentRoundId_];
    return (
      result.roundId,
      result.answer,
      result.timestamp,
      result.roundTimestamp,
      result.answeredInRound
    );
  }
}