// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    struct Candidate {
        uint candidateId;
        string name;
        uint voteCount;
    }

    struct Voter {
        bool authorized;
        bool voted;
        uint vote;
    }
    
    struct Election{
        uint id;
        string name;
        
    }
    

    address public owner;
    string public electionName;

    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    Election[] public elections;
    uint public totalVotes;

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function addElection(string memory _name) public ownerOnly{
        elections.push(Election(elections.length,_name));
    }

    function addCandidate(uint _id,string calldata _name) public ownerOnly {
        candidates.push(Candidate(_id,_name,0));
    }

    function getNumCandidate() public view returns (uint) {
        return candidates.length;
    }

    function authorize(address _person) public ownerOnly {
        voters[_person].authorized = true;
    }

    function vote(uint _voteIndex) public {
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorized);

        voters[msg.sender].vote = _voteIndex;
        voters[msg.sender].voted = true;

        candidates[_voteIndex].voteCount += 1;
        totalVotes += 1;
    }

   
}