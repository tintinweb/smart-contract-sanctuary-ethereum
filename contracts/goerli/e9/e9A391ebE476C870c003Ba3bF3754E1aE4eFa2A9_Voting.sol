/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Voting {
    address public owner;
    struct Candidate {
        address candidateAddress;
        uint voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public voters;
    mapping(address => bool) public candidatesCheck;
    uint public candidatesCount;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function establishCandidate(address _candidateAddress) public onlyOwner {
        candidatesCount ++;
        candidates.push(Candidate({candidateAddress: _candidateAddress, voteCount: 0}));
        candidatesCheck[_candidateAddress] = true ;
    }

    function castVote(uint _voterAge, address _candidateAddress) public {
        require(_voterAge >= 18, "Voter must be at least 18 years old.");
        require(!voters[msg.sender], "Voter has already voted.");
        require(candidatesCheck[_candidateAddress], "Candidate doesn't exist.");
        
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].candidateAddress == _candidateAddress) {
                candidates[i].voteCount++;
                voters[msg.sender] = true;
                break;
            }
        }
    }

    function announceWinner() public view returns (address) {
        uint maxVotes = 0;
        address winningCandidate;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winningCandidate = candidates[i].candidateAddress;
            }
        }

        return winningCandidate;
    }

    function getAllCandidates() public view returns (address[] memory) {
        address[] memory candidateAddresses = new address[](candidates.length);
        for (uint i = 0; i < candidates.length; i++) {
            candidateAddresses[i] = candidates[i].candidateAddress;
        }
        return candidateAddresses;
    }
}