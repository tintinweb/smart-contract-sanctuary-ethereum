// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @title Chainlink RoundId Fetcher
/// @dev Used to get historical pricing data from Chainlink data feeds
contract RoundIdFetcher {

    constructor() {}

    /// @notice Gets the phase that contains the target time
    /// @param _feed Address of the chainlink data feed
    /// @param _targetTime Target time to fetch the round id for
    /// @return The first roundId of the phase that contains the target time
    /// @return The timestamp of the phase that contains the target time
    /// @return The first roundId of the current phase
    function getPhaseForTimestamp(AggregatorV2V3Interface _feed, uint256 _targetTime) public view returns (uint80, uint256, uint80) {
        uint16 currentPhase = uint16(_feed.latestRound() >> 64);
        uint80 firstRoundOfCurrentPhase = (uint80(currentPhase) << 64) + 1;
        
        for (uint16 phase = currentPhase; phase >= 1; phase--) {
            uint80 firstRoundOfPhase = (uint80(phase) << 64) + 1;
            uint256 firstTimeOfPhase = _feed.getTimestamp(firstRoundOfPhase);

            if (_targetTime > firstTimeOfPhase) {
                return (firstRoundOfPhase, firstTimeOfPhase, firstRoundOfCurrentPhase);
            }
        }
        return (0,0, firstRoundOfCurrentPhase);
    }

    /// @notice Performs a binary search on the data feed to find the first round id after the target time
    /// @param _feed Address of the chainlink data feed
    /// @param _targetTime Target time to fetch the round id for
    /// @param _lhRound Lower bound roundId (typically the first roundId of the targeted phase)
    /// @param _lhTime Lower bound timestamp (typically the first timestamp of the targeted phase)
    /// @param _rhRound Upper bound roundId (typically the last roundId of the targeted phase)
    /// @return targetRound The first roundId after the target timestamp
    function _binarySearchForTimestamp(AggregatorV2V3Interface _feed, uint256 _targetTime, uint80 _lhRound, uint256 _lhTime, uint80 _rhRound) public view returns (uint80 targetRound) {

        if (_lhTime > _targetTime) return 0; // targetTime not in range

        uint80 guessRound = _rhRound;
        while (_rhRound - _lhRound > 1) {
            guessRound = uint80(int80(_lhRound) + int80(_rhRound - _lhRound)/2);
            uint256 guessTime = _feed.getTimestamp(uint256(guessRound));
            if (guessTime == 0 || guessTime > _targetTime) {
                _rhRound = guessRound;
            } else if (guessTime < _targetTime) {
                (_lhRound, _lhTime) = (guessRound, guessTime);
            }
        }
        return guessRound;
    }

    /// @notice Gets the round id for a given timestamp
    /// @param _feed Address of the chainlink data feed
    /// @param _timeStamp Target time to fetch the round id for
    /// @return roundId The roundId for the given timestamp
    function getRoundId(AggregatorV2V3Interface _feed, uint256 _timeStamp) public view returns (uint80 roundId) {

        (uint80 lhRound, uint256 lhTime, uint80 firstRoundOfCurrentPhase) = getPhaseForTimestamp(_feed, _timeStamp);

        uint80 rhRound;
        if (lhRound == 0) {
            // Date is too far in the past, no data available
            return 0;
        } else if (lhRound == firstRoundOfCurrentPhase) {
            (rhRound,,,,) = _feed.latestRoundData();
        } else {
            // No good way to get last round of phase from Chainlink feed, so our binary search function will have to use trial & error.
            // Use 2**16 == 65536 as a upper bound on the number of rounds to search in a single Chainlink phase.
            
            rhRound = lhRound + 2**16; 
        } 

        uint80 foundRoundId = _binarySearchForTimestamp(_feed, _timeStamp, lhRound, lhTime, rhRound);
        roundId = getRoundIdForTimestamp(_feed, _timeStamp, foundRoundId, lhRound);
        
        return roundId;
    }

    function getRoundIdForTimestamp(AggregatorV2V3Interface _feed, uint256 _timeStamp, uint80 _roundId, uint80 _firstRoundOfPhase) internal view returns (uint80) {
        uint256 roundTimeStamp = _feed.getTimestamp(_roundId);

        if (roundTimeStamp > _timeStamp && _roundId > _firstRoundOfPhase) {
            _roundId = getRoundIdForTimestamp(_feed, _timeStamp, _roundId - 1, _firstRoundOfPhase);
        } else if (roundTimeStamp > _timeStamp && _roundId == _firstRoundOfPhase) {
            _roundId = 0;
        }
            return _roundId;
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