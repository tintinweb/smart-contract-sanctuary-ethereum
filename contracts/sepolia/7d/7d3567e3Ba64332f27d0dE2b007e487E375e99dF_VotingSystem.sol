// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

contract VotingSystem {
    struct Voter {
        bool alreadyVoted;
        uint256 candidateIndex;
    }

    struct Candidate {
        string name;
        string description;
        string image;
        uint256 target;
        uint256 voteCount;
    }

    mapping(address => Voter) VoterAddress;
    Candidate[] private candidates;

    
    function addCanadidate(string memory _name,string memory _description,string memory _image,uint256 _target) public {
        candidates.push(Candidate(_name,_description,_image,_target,0));
    }

    
    function voteTo(string memory _name) public {
        require(VoterAddress[msg.sender].alreadyVoted == false, "You have already voted");
        VoterAddress[msg.sender].alreadyVoted = true;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (keccak256(bytes(candidates[i].name)) == keccak256(bytes(_name))) {
                VoterAddress[msg.sender].candidateIndex = i;
                candidates[i].voteCount++;
            }
        }
    }

    
    function winner() public view returns (Candidate memory) {
        uint256 max = 0;
        Candidate memory winnerCan;
        string memory winnerCandidate;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > max) {
                max = candidates[i].voteCount;
                winnerCandidate = candidates[i].name;
                winnerCan= candidates[i];
            }
        }
        return winnerCan;
    }

    
    
function getCandidatesDetails() public view returns (Candidate[] memory) {
    return candidates;
    }

    
    
}