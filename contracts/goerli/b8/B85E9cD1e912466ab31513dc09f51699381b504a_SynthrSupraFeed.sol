// SPDX-License-Identifier: MIT
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
    function getRoundData(
        uint80 _roundId
    ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorV2V3Interface.sol";
interface ISupraSValueFeed {
    function checkPrice(string memory marketPair) external view returns (int256 price, uint256 timestamp);
}

contract SynthrSupraFeed is AggregatorV2V3Interface {
    ISupraSValueFeed internal sValueFeed;

    string public tokenPairName;
    uint80 public lastRoundId;

    struct RoundData {
        int256 answer;
        uint128 startedAt;
        uint128 updatedAt;
    }

    mapping(uint80 => RoundData) private recordedData;

    constructor(string memory _tokenPairName) {
        tokenPairName = _tokenPairName;
    }

    function updateRoundData() external {
        (
            int price,
            /* uint timestamp */
        ) = sValueFeed.checkPrice(tokenPairName);

        recordedData[lastRoundId].answer = price;
        recordedData[lastRoundId].updatedAt = uint128(block.timestamp);
        if (recordedData[lastRoundId].startedAt == 0) {
            recordedData[lastRoundId].startedAt = uint128(block.timestamp);
        }
    }

    function levelUpRound() external {
        (
            int price,
            /* uint timestamp */
        ) = sValueFeed.checkPrice(tokenPairName);

        lastRoundId++;

        recordedData[lastRoundId].answer = price;
        recordedData[lastRoundId].updatedAt = uint128(block.timestamp);
        recordedData[lastRoundId].startedAt = uint128(block.timestamp);
    }

    //
    // V2 Interface:
    //
    function latestAnswer() external view override returns (int256) {
        return recordedData[lastRoundId].answer;
    }

    function latestTimestamp() external view override returns (uint256) {
        return recordedData[lastRoundId].updatedAt;
    }

    function latestRound() external view override returns (uint256) {
        return uint256(lastRoundId);
    }

    function getAnswer(uint256 roundId) external view override returns (int256) {
        return recordedData[uint80(roundId)].answer;
    }

    function getTimestamp(uint256 roundId) external view override returns (uint256) {
        return recordedData[uint80(roundId)].updatedAt;
    }

    //
    // V3 Interface:
    //
    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return "SynthrPriceFeed Supra";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    ) external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        roundId = _roundId;
        answer = recordedData[_roundId].answer;
        startedAt = recordedData[_roundId].startedAt;
        updatedAt = recordedData[_roundId].updatedAt;
    }

    function latestRoundData() external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        roundId = lastRoundId;
        answer = recordedData[roundId].answer;
        startedAt = recordedData[roundId].startedAt;
        updatedAt = recordedData[roundId].updatedAt;
    }

    function setSValueFeed(address feed) external {
        sValueFeed = ISupraSValueFeed(feed);
    }
}