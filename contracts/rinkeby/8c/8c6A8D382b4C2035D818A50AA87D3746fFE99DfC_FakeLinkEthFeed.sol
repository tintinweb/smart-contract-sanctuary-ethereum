/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract FakeLinkEthFeed {
    uint256 public round_answer;

    function setLatestRoundAnswer(uint256 answer) public {
        round_answer = answer;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            uint80(1),
            round_answer,
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }
}