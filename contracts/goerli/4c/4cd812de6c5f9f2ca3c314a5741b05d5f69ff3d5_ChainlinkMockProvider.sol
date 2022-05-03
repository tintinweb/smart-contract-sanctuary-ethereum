/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
// Chainlink Aggregator v3 interface
// https://github.com/smartcontractkit/chainlink/blob/6fea3ccd275466e082a22be690dbaf1609f19dce/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
interface IChainlinkAggregatorV3Interface {
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

contract ChainlinkMockProvider is IChainlinkAggregatorV3Interface {
    int256 public answer;

    function setAnswer(int256 answer_) external {
        answer = answer_;
    }

    function decimals()
        external
        pure
        override(IChainlinkAggregatorV3Interface)
        returns (uint8)
    {
        return 18;
    }

    function description()
        external
        pure
        override(IChainlinkAggregatorV3Interface)
        returns (string memory)
    {
        return "MOCK / USD ";
    }

    function version()
        external
        pure
        override(IChainlinkAggregatorV3Interface)
        returns (uint256)
    {
        return 0;
    }

    function getRoundData(
        uint80 /*_roundId*/
    )
        external
        view
        override(IChainlinkAggregatorV3Interface)
        returns (
            uint80 roundId_,
            int256 answer_,
            uint256 startedAt_,
            uint256 updatedAt_,
            uint80 answeredInRound_
        )
    {
        roundId_ = 92233720368547764552;
        answer_ = answer;
        startedAt_ = 1644474147;
        updatedAt_ = 1644474147;
        answeredInRound_ = 92233720368547764552;
    }

    function latestRoundData()
        external
        view
        override(IChainlinkAggregatorV3Interface)
        returns (
            uint80 roundId_,
            int256 answer_,
            uint256 startedAt_,
            uint256 updatedAt_,
            uint80 answeredInRound_
        )
    {
        roundId_ = 92233720368547764552;
        answer_ = answer;
        startedAt_ = 1644474147;
        updatedAt_ = 1644474147;
        answeredInRound_ = 92233720368547764552;
    }
}