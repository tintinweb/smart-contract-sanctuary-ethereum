/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Voting {
    string[] public candidateList;
    mapping ( string => uint) votesReceived;

    // ["A", "B", "C"]
    // 0,   1,   2
    constructor ( string[] memory candidateName) {
        candidateList = candidateName;
    }

    function voteForCandidate(string memory candidate) public {
        votesReceived[candidate] += 1;
    }

    function totalVotesFor(string memory candidate) public view returns (uint256) {
        return votesReceived[candidate];
    }

    function candidateCount() public view returns (uint256) {
        return candidateList.length;
    }

    function addCandidate(string memory candidate) public {
        candidateList.push(candidate);
    }

    function removeCandidate(uint256 index) public {
        candidateList[index] = candidateList[candidateList.length - 1];
        candidateList.pop();
    }

    function showAllCandidateList() public view returns (string[] memory) {
        return candidateList;
    }
}