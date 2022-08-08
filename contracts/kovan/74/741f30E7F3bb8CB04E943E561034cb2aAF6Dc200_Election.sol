//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

// import "hardhat/console.sol";

contract Election {

    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint256 voteCount;
    }

    struct Voter {
        address voter;
        uint256 votedOn;
    }


    // Store accounts that have voted
    uint256 public totalVotes;
    mapping(address => Voter) public voters;
    Voter[] private votersList;

    // Read/write candidates
    mapping(uint8 => Candidate) public candidates;

    // Store Candidates Count
    uint8 public candidatesCount;

    constructor () {
        addCandidate("Asif Ali Zardari");
        addCandidate("Imran Khan");
        addCandidate("Nawaz Shareef");
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint8 _candidateId) public {
        // require that they haven't voted before
        require(voters[msg.sender].voter == address(0), "Already voted");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "not a valid customer ID");

        // record that voter has voted
        Voter memory _voter = Voter(msg.sender, block.timestamp);
        voters[msg.sender] = _voter; 
        votersList.push(_voter);

        // update candidate vote Count
        candidates[_candidateId].voteCount++;
        totalVotes++;
    }

    function isVoter(address user) public view returns (bool){
        return voters[user].voter != address(0);
    }

    function getVotersList() public view returns (Voter[] memory){
        return votersList;
    }

    function getCandidatesList() public view returns (Candidate[] memory) {
        Candidate[] memory candicatesss = new Candidate[](3);

        for(uint8 i=0;  i < candidatesCount; i++){
            candicatesss[i] = candidates[i+1];
        }
        return candicatesss;
    }

}