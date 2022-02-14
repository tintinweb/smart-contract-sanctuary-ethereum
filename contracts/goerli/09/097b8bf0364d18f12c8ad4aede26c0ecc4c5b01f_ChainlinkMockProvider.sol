/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/deploy/ChainlinkMockProvider.sol
// SPDX-License-Identifier: Apache-2.0 AND MIT
pragma solidity >=0.8.0 <0.9.0;

////// src/oracle_implementations/spot_price/Chainlink/ChainlinkAggregatorV3Interface.sol
/* pragma solidity ^0.8.0; */

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

////// src/deploy/ChainlinkMockProvider.sol
/* pragma solidity ^0.8.0; */
/* import {IChainlinkAggregatorV3Interface} from "src/oracle_implementations/spot_price/Chainlink/ChainlinkAggregatorV3Interface.sol"; */

contract ChainlinkMockProvider is IChainlinkAggregatorV3Interface {
    int256 public answer;

    function setAnswer(int256 answer_) external {
        answer = answer_;
    }

    function decimals()
        external
        view
        override(IChainlinkAggregatorV3Interface)
        returns (uint8)
    {
        return 18;
    }

    function description()
        external
        view
        override(IChainlinkAggregatorV3Interface)
        returns (string memory)
    {
        return "MOCK / USD ";
    }

    function version()
        external
        view
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