/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    // Mapping of candidate names to number of votes received
    mapping (bytes32 => uint8) public votesReceived;
    // Array of candidate names
    bytes32[] public candidates;

    // Constructor function to initialize candidates
    constructor() public {
        candidates.push("Candidate 1");
        candidates.push("Candidate 2");
        candidates.push("Candidate 3");
    }

    // Function to cast a vote
    function vote(uint8 candidate) public {
        require(candidate < candidates.length, "Invalid candidate index");
        votesReceived[candidates[candidate]] += 1;
    }
}