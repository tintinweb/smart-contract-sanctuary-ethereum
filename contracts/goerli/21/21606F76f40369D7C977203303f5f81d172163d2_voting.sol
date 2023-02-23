// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract voting{
    struct Candidate{
        uint candidateID;
        string candidateName;
        string partyName;
        uint votesCount; 
    }

    struct Voter{
        uint voterID;
        string voterName;
        uint candidateID;
        string candidateName;
    }

    Candidate[] public candidates;

    Voter[] public voters;

    mapping(address => bool) public hasVoted;

    mapping(uint => uint) public candidateIndex;

    mapping(address => uint) public voterVotes;

    event Vote(address indexed voter, uint candidateID);

    function addCandidate(string memory name, string memory partyName, uint candidateID) public {
        candidates.push(Candidate({
            candidateID: candidateID,
            candidateName: name,
            partyName: partyName,
            votesCount: 0
        }));

        candidateIndex[candidateID] = candidates.length -1;
    }

    function vote(uint voterID, string memory voterName, uint candidateID, string memory candidateName) public {
        require(!hasVoted[msg.sender], "You have already voted.");

        voterVotes[msg.sender] = candidateID;

        uint index = candidateIndex[candidateID];

        candidates[index].votesCount++;

        hasVoted[msg.sender] = true;

        voters.push(Voter({
            voterID: voterID,
            voterName: voterName,
            candidateID: candidateID,
            candidateName: candidateName
        }));

        emit Vote(msg.sender, candidateID);
    }

    function getCandidate(uint candidateID) public view returns (uint, string memory, string memory, uint) {
        uint index = candidateIndex[candidateID];

        return (candidates[index].candidateID, candidates[index].candidateName, candidates[index].partyName, candidates[index].votesCount);
    }
}