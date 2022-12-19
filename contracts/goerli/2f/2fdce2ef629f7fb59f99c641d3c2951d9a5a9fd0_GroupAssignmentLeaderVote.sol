/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// This contract allows voters to vote for a team leader for a university group assignment

// Our contract will have two main parts:
// - A mapping that allows us to track the votes for each candidate
// - A function that allows voters to cast their votes

// First, we'll define our contract
contract GroupAssignmentLeaderVote {

    // We'll use a mapping to track the votes for each candidate
    mapping (string => uint) internal votes;

    // We'll use an array to store the names of the candidates
    string[] internal candidates;

    event RevealResult(string candidate, uint voteCount);

    constructor() public {
        addCandidate("WIF190501");
        addCandidate("WIF190038");
        addCandidate("WIF190003");
        addCandidate("WIF190034");
        addCandidate("WIF190009");
        addCandidate("WIF190041");
    }

    // This function allows voters to cast their votes
    function vote(string memory candidate) public {
        // Increment the vote count for the selected candidate
        votes[candidate] += 1;
    }

    // This function allows us to add new candidates to the election
    function addCandidate(string memory candidate) private {
        // Add the new candidate to the list of candidates
        candidates.push(candidate);
    }

    // Reveal the results! 
    function revealResult() public {
        emit RevealResult("WIF190501", votes["WIF190501"]);
        emit RevealResult("WIF190003", votes["WIF190003"]);
        emit RevealResult("WIF190034", votes["WIF190034"]);
        emit RevealResult("WIF190009", votes["WIF190009"]);
        emit RevealResult("WIF190041", votes["WIF190041"]);
        emit RevealResult("WIF190038", votes["WIF190038"]);
    }
}