/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Candidate {
    string fullName;
    uint256 voteCount;
}

contract Vote {
    address managerAddress;

    Candidate[] candidates;

    constructor(address _managerAddress) {
        managerAddress = _managerAddress;
    }

    function addCandidate(string memory _fullName) public {
        require(msg.sender == managerAddress, "You are not manager.");
        candidates.push(Candidate(_fullName, 0));
    }

    function viewCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function vote(uint256 _candidateIndex) public {
        require(
            _candidateIndex <= candidates.length,
            "No candidate in this number."
        );

        candidates[_candidateIndex].voteCount += 1;
    }
}