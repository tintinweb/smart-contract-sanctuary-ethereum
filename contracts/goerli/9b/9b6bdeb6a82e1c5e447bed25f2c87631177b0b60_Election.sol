/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.2;

contract Election{
    //Mode a candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    //Store candidate

    //Fetch Candidate
    mapping(uint=> Candidate) public candidates; 
    //store Candidate Count
    uint public candidatesCount;

    function election() public {
      addCandidate("Candidate 1");
      addCandidate("Candidate 2");

    }
    
    function addCandidate (string memory _name) private{
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount,  _name,0);
    }
}