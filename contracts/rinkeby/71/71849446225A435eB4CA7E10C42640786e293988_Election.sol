/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// File: Election.sol

// File: Election.sol

contract Election {
    //Candidate Structure
    struct Candidate {
        uint256 id;
        string name;
        string party;
        uint256 vote_count;
    }
    //count voters
    mapping(address => bool) public voters;
    //Store candidates
    mapping(uint256 => Candidate) public Candidates;
    //count candidates
    uint256 public Candidate_count;

    constructor() {
        addCandidate("Suresh Narayan Dhanorkar", "Indian National Congress");
        addCandidate("Hansraj Gangaram Ahir", "Bharatiya Janata Party");
        addCandidate("Rajendra Shriram Mahadole", "Vanchit Bahujan Aaghadi");
        addCandidate("Sushil Wasnik", "Bahujan Samaj Party");
        addCandidate("Pramod Mangaruji Sorte", "Independent politician");
        addCandidate("NOTA", "None Of The Above");
    }

    function addCandidate(string memory _name, string memory _party) private {
        Candidate_count++;
        Candidates[Candidate_count] = Candidate(
            Candidate_count,
            _name,
            _party,
            0
        );
    }

    function Vote(uint256 _candidateId) public {
        //require that voter hasn't voted before
        require(!voters[msg.sender]);
        //require valid candidate
        require(_candidateId > 0 && _candidateId <= Candidate_count);
        //record vote from voter
        voters[msg.sender] = true;
        //update candidate vote count
        Candidates[_candidateId].vote_count++;
    }

    //for frontend
    function viewvotes() public view returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](6);
        for (uint256 i = 0; i <= 5; i++) {
            ret[i] = Candidates[i + 1].vote_count;
        }
        return ret;
    }
}