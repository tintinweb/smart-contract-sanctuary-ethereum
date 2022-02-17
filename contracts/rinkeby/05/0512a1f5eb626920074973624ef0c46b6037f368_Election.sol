/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;

contract Election {
    address public owner;
    string public electionName;

    Candidate[] public candidates;
    uint public totalVotes;

    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Voter {
        bool authorized;
        bool voted;
        uint vote;
    }

    mapping(address => Voter) public voters;

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    constructor(string memory _name) {
        owner = msg.sender;
        electionName = _name;
    }

    function addCandidate(string memory _name) ownerOnly public {
        candidates.push(Candidate(_name, 0));
    }

    function getNumCandidate() public view returns(uint) {
        return candidates.length;
    }

    function authorized(address _person) ownerOnly public {
        voters[_person].authorized = true;
    }

    function vote(uint _voting) public {
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorized);

        voters[msg.sender].vote = _voting;
        voters[msg.sender].voted = true;

        candidates[_voting].voteCount += 1;
        totalVotes += 1;
    }
}