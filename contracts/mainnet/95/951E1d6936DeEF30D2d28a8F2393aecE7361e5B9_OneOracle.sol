/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;


interface IGMUOracle {
    function fetchPrice() external returns(uint);    
}

contract ARTHOracle {
    
    IGMUOracle immutable feed;

    constructor(IGMUOracle _feed) public {
        feed = _feed;
    }

    function decimals() external pure returns(uint8) {
        return 18;
    }

    function latestRoundData() external returns
    (
        uint80 /* roundId */,
        int256 answer,
        uint256 /* startedAt */,
        uint256 timestamp,
        uint80 /* answeredInRound */
    )
    {
        answer = int(feed.fetchPrice());
        timestamp = now;
    }
}

contract OneOracle {
    function decimals() external pure returns(uint8) {
        return 0;
    }

    function latestRoundData() external view returns
    (
        uint80 /* roundId */,
        int256 answer,
        uint256 /* startedAt */,
        uint256 timestamp,
        uint80 /* answeredInRound */
    )
    {
        answer = 1;
        timestamp = now;
    }
}