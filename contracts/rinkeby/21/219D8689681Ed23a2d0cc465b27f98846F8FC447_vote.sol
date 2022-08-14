// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract vote {
    struct candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    mapping(address => bool) public firstVote;
    mapping(uint256 => candidate) public candidates;
    uint256 public candidateCount;
    address private i_owner;

    error NotOwner();

    function newCandidate(string memory _name) public onlyOwner {
        candidateCount++;
        candidates[candidateCount] = candidate(candidateCount, _name, 0);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    //   newCandidate("BJP");
    //   newCandidate("Cong");
    //   newCandidate("Aap");
    //   newCandidate("oth");
    // }

    function Makevote(uint256 _candidateId) public {
        require(!firstVote[msg.sender], "You have already voted");
        require(
            _candidateId > 0 && _candidateId < candidateCount,
            "Pls Enter Correct Id"
        );
        firstVote[msg.sender] = true;
        candidates[_candidateId].voteCount++;
    }

    function VoterAddress() public view returns (address) {
        return msg.sender;
    }

    function winner() public view onlyOwner returns (string memory name) {
        if (msg.sender == i_owner) {
            uint winnerVoteCount = 0;
            for (uint p = 0; p < candidateCount; p++) {
                if (candidates[p].voteCount > winnerVoteCount) {
                    winnerVoteCount = candidates[p].voteCount;
                    name = candidates[p].name;
                }
            }
        }
        return name;
    }

    /// Calls winnerProposal() function in order to acquire the index
    /// of the winner which the proposalsOption array contains and then
    /// returns the name of the winning proposal
}