// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Initializable.sol";

contract SybilOracle is Initializable {
    // Contract owner
    address public owner;

    struct SybilScore {
        uint summary;
        uint black;
        uint bulk;
        uint star;
        uint chain;
        uint seq;
        uint timestamp;
    }

    mapping(address => SybilScore) public scores;

    event CallbackGetSybilScore(address target);

    function initialize() public initializer {
        owner = msg.sender;
    }

    function prepareSybilScore(address target) public {
        emit CallbackGetSybilScore(target);
    }

    function updateSybilScore(
        address target,
        uint summary,
        uint black,
        uint bulk,
        uint star,
        uint chain,
        uint seq
    ) public {
        require(msg.sender == owner, "only owner can update cap");
        scores[target] = SybilScore({
            summary: summary,
            black: black,
            bulk: bulk,
            star: star,
            chain: chain,
            seq: seq,
            timestamp: block.timestamp
        });
    }

    function getSybilScore(
        address target
    )
        public
        view
        returns (
            uint summary,
            uint black,
            uint bulk,
            uint star,
            uint chain,
            uint seq,
            uint timestamp
        )
    {
        SybilScore storage score = scores[target];
        return (
            score.summary,
            score.black,
            score.bulk,
            score.star,
            score.chain,
            score.seq,
            score.timestamp
        );
    }
}