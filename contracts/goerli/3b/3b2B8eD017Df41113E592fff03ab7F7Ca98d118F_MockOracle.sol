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

pragma solidity ^0.8.0;

// Import aggregatorv3
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockOracle is AggregatorV3Interface {
    int256 public price;
    uint8 public decimals;
    string public description;
    uint256 public version = 1;
    uint80 public roundId = 1;
    mapping(uint80 => int256) public answers;
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    constructor(int256 _price, uint8 _decimals, string memory _description) {
        price = _price;
        answers[roundId] = price;
        decimals = _decimals;
        description = _description;
    }

    function getRoundData(uint80 _roundId) public view override returns (uint80, int256, uint256, uint256, uint80) {
        return (_roundId, answers[_roundId], 0, 0, 0);
    }

    function latestRoundData() public view override returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, price, 0, 0, 0);
    }

    function setPrice(int256 _price) public {
        price = _price;
        answers[roundId] = price;
        emit AnswerUpdated(price, roundId, block.timestamp);
        roundId++;
    }
}