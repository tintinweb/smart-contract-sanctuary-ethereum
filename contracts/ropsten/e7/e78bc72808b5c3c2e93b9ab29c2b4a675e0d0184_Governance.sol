/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Governance{

    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint=>Candidate) public candidates;

    mapping(address=>bool)public voters;

    uint public candidateCount;

    constructor() {
        addCandidate("Yes");
        addCandidate("NO");
    }

    function addCandidate(string memory _name)private{
        candidateCount ++;
        candidates[candidateCount] = Candidate(candidateCount,_name,0); 
    }

    function vote(uint _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId>0&&_candidateId<=candidateCount);
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
    }
}