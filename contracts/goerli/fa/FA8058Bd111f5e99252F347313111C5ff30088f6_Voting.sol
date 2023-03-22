/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Voting {
    address public owner;
    struct Candidate {                  //will store info of candidates
        address candidateAddress;
        uint voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public checkVoter;     //will return status of voter exist or not
    mapping(address => bool) public candidatesCheck;    //will return status of candidate exists or not
    uint public candidatesCount;    // will return number of candidates
    uint votesCount = 0;    // will return number of votes

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    //method to add/establish candidates which can be called by only owner
    function establishCandidate(address _candidateAddress) public onlyOwner {
        require(!candidatesCheck[_candidateAddress], "Candidate already exists.");
        candidatesCount ++;
        candidates.push(Candidate({candidateAddress: _candidateAddress, voteCount: 0}));
        candidatesCheck[_candidateAddress] = true ;
    }

    //public function through which vote can be casted by adding candidate address & voter's age
    function castVote(uint _voterAge, address _candidateAddress) public {
        require(_voterAge >= 18, "Voter must be at least 18 years old.");
        require(!checkVoter[msg.sender], "Voter has already voted.");
        require(candidatesCheck[_candidateAddress], "Candidate doesn't exist.");
        votesCount ++;
        
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].candidateAddress == _candidateAddress) {
                candidates[i].voteCount++;
                checkVoter[msg.sender] = true;
                break;
            }
        }
    }

    //public function through which winner can be announced
    function announceWinner() public view returns (address, uint) {
        require(votesCount > 0, "No votes casted yet");
        uint maxVotes = 0;
        address winningCandidate;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winningCandidate = candidates[i].candidateAddress;
            }
        }

        return (winningCandidate, maxVotes);
    }

    //public function through which list of all candidates can be viewed
    function getAllCandidates() public view returns (address[] memory) {
        address[] memory candidateAddresses = new address[](candidates.length);
        for (uint i = 0; i < candidates.length; i++) {
            candidateAddresses[i] = candidates[i].candidateAddress;
        }
        return candidateAddresses;
    }
}