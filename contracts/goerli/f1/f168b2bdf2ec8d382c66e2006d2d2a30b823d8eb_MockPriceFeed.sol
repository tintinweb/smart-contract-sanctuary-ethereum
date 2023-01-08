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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV2V3Interface} from "interfaces/AggregatorV2V3Interface.sol";

contract MockPriceFeed is AggregatorV2V3Interface {
    int256 public s_answer;
    uint8 public s_decimals;
    uint256 public s_timestamp;
    uint80 public s_roundId;
    uint80 public s_answeredInRound;

    function setLatestAnswer(int256 answer) public {
        s_answer = answer;
    }

    function latestAnswer() public view override returns (int256) {
        return s_answer;
    }

    function setDecimals(uint8 decimals_) public {
        s_decimals = decimals_;
    }

    function decimals() external view override returns (uint8) {
        return s_decimals;
    }

    function setTimestamp(uint256 timestamp_) public {
        s_timestamp = timestamp_;
    }

    function latestTimestamp() external view override returns (uint256) {
        return s_timestamp;
    }

    function setRoundId(uint80 roundId_) public {
        s_roundId = roundId_;
    }

    function latestRound() external view override returns (uint256) {
        return uint256(s_roundId);
    }

    function setAnsweredInRound(uint80 answeredInRound_) public {
        s_answeredInRound = answeredInRound_;
    }

    function latestAnsweredInRound() external view returns (uint256) {
        return uint256(s_answeredInRound);
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
        return (s_roundId, s_answer, 0, s_timestamp, s_answeredInRound);
    }

    /// Not implemented but required by interface

    function getAnswer(uint256 roundId) external view override returns (int256) {}

    function getTimestamp(uint256 roundId) external view override returns (uint256) {}

    function description() external view override returns (string memory) {}

    function version() external view override returns (uint256) {}

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
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
    {}
}