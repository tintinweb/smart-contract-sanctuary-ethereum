pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title External Access Controlled Aggregator Proxy
 * @notice A trusted proxy for updating where current answers are read from
 * @notice This contract provides a consistent address for the
 * Aggregator and AggregatorV3Interface but delegates where it reads from to the owner, who is
 * trusted to update it.
 * @notice Only access enabled addresses are allowed to access getters for
 * aggregated answers and round information.
 */
contract EACAggregatorProxy is AggregatorV3Interface {
    uint80 roundId_ = 291162087;
    int256 answer_; // $5 = 5e8
    uint256 startedAt_ = 1656366025;
    uint256 updatedAt_ = 1656366025;
    uint80 answeredInRound_ = 291162087;
    uint256 delay;

    constructor(int256 _answer, uint256 _delay) {
        answer_ = _answer;
        delay = _delay;
    }

    /**
     * @notice get data about the latest round. Consumers are encouraged to check
     * that they're receiving fresh data by inspecting the updatedAt and
     * answeredInRound return values.
     * Note that different underlying implementations of AggregatorV3Interface
     * have slightly different semantics for some of the return values. Consumers
     * should determine what implementations they expect to receive
     * data from and validate that they can properly handle return data from all
     * of them.
     * @return roundId is the round ID from the aggregator for which the data was
     * retrieved combined with a phase to ensure that round IDs get larger as
     * time moves forward.
     * @return answer is the answer for the given round
     * @return startedAt is the timestamp when the round was started.
     * (Only some AggregatorV3Interface implementations return meaningful values)
     * @return updatedAt is the timestamp when the round last was updated (i.e.
     * answer was last computed)
     * @return answeredInRound is the round ID of the round in which the answer
     * was computed.
     * (Only some AggregatorV3Interface implementations return meaningful values)
     * @dev Note that answer and updatedAt may change between queries.
     */
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
        return (roundId_, answer_, startedAt_, block.timestamp - delay, answeredInRound_);
    }

    function setDelay(uint256 _delay) public {
        delay = _delay;
    }

    /**
     * @notice represents the number of decimals the aggregator responses represent.
     */
    function decimals() external view returns (uint8) {
        return 18;
    }

    function description() external view returns (string memory) {
        return "Bond/USD";
    }

    function version() external view returns (uint256) {
        return 1;
    }

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
        )
    {
        return (roundId_, answer_, startedAt_, updatedAt_, answeredInRound_);
    }
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