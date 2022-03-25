// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Voting {

    struct Candidate {
        string name;
        bool added;
        uint256 votes;
    }

    struct Voter {
        bool voted;
    }

    address private owner;

    mapping (address => Candidate) private candidates;
    mapping (address => Voter) private voters;

    address[] private candidatesAddress;

    constructor() {
        owner = msg.sender;
    }

    function getCandidate(address candidateAddress) public view returns (string memory name) {
        require(address(0) != candidateAddress,"You need to provide address of candidate");
         require(candidates[candidateAddress].added, "No Candidate found");
        return candidates[candidateAddress].name;
    }

    function addCandidate(address candidateAddress, string memory name) public returns (bool) {

        require(msg.sender == owner, "You're not allowed to add candidate. Only owner of the contract can add the candidate");
        require(candidateAddress != address(0), "This address can't be candidate");
        require(bytes(name).length != 0, "Empty name of candidate is not acceptable");
        require(!candidates[candidateAddress].added, "Candidate Already Added");

        candidates[candidateAddress].name = name;
        candidates[candidateAddress].added = true;
        candidates[candidateAddress].votes = 0;

        candidatesAddress.push(candidateAddress);

        return true;
    }

    function castVote(address yourCandidateAddress) public returns (bool) {

        require(!voters[msg.sender].voted, "You already casted your vote");
        require(yourCandidateAddress != address(0), "Your Candidate is not an actual candidate");
        require(candidates[yourCandidateAddress].added, "We don't have such candidate");
        require(!candidates[msg.sender].added, "You're not allow to vote because you're candidate");

        voters[msg.sender].voted = true;
        candidates[yourCandidateAddress].votes += 1;

        return true;        
    }


    function votesOf(address candidateAddress) public view returns (uint256){
        
        require(candidateAddress != address(0), "Your Candidate is not an actual candidate");
        require(candidates[candidateAddress].added, "We don't have such candidate");
        return candidates[candidateAddress].votes;
        
    }

    function winner() public view returns (string memory name) {
        address winnerCandidate = candidatesAddress[0];
        for(uint i=0; i< candidatesAddress.length; i++) {
            if(candidates[candidatesAddress[i]].votes > candidates[winnerCandidate].votes){
                winnerCandidate = candidatesAddress[i];
            }
        }
        return candidates[winnerCandidate].name;
    }

    function candidatesCount() public view returns (uint256) {
        return candidatesAddress.length;
    }
}