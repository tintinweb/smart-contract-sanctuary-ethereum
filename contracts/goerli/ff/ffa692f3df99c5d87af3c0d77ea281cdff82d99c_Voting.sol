/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // select complier: 0.8.7

contract Voting {
    string [] public candidateList;
    mapping(string => uint) votesReceived;
    // A: 0, 1
    // B: 0,1,2
    
    // ["Dog", "PM", "NET"]
    // 0, 1, 2
    constructor(string[] memory candidateName ) {
        candidateList = candidateName;
    } 

    // add new candidate
    function addNewCandidate(string memory candidate) public {
        candidateList.push(candidate);
    }

    // remove a candidate
    //function removecandidate(...)

    function voteForCandidate(string memory candidate) public {
        votesReceived[candidate] +=1;
    }
    function totalVotesFor(string memory candidate)
    public view returns (uint256) {
        return votesReceived [candidate];
    }
    function candidateCount() public view returns (uint256) {
        return candidateList.length;
    }
}