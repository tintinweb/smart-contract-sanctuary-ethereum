/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    string[] public candidateList;
    mapping(string => uint) votesReceived;

    // ["Dog", "PM", "NET"]
    constructor(string[] memory candidateName) {
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

    function allCandidate() public view returns (string[] memory) {
        return candidateList;
    }

    function addNewCandidate(string memory candidateName) public {
        candidateList.push(candidateName);
    }

    function removeCandidate(uint256 candidateIndex) public {
        // delete candidateList[candidateIndex];
        candidateList[candidateIndex] = candidateList[candidateList.length - 1];
        candidateList.pop();
    }
}