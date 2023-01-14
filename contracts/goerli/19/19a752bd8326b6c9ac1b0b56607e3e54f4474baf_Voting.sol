/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    string[] public candidateList;
    mapping(string => uint) voteReceived;
    // A: 0, 1
    // B: 0, 1, 2

    // ["Pig", "Dog", "Crow", "Chicken"]

    constructor(string[] memory candidateName) {
        candidateList = candidateName;
    }

    function voteForCandidate(string memory candidate) public {
        voteReceived[candidate] += 1;
    }

    function totalVotesFor(string memory candidate)
    public view returns (uint256) {
        return voteReceived[candidate];
    }

    function candidateCount() public view returns (uint256) {
        return candidateList.length;
    }

    //function addForCandidate(string memory addCandidate) public {
    //    candidateList = addCandidate;        
    //}
}