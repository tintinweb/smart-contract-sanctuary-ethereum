/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity ^0.4.21;
/*
Election contract that allows the owner to issue voting rights
to anybody and also end the election and announce results
*/
contract Election {
    struct Candidate {
        string name;
        uint voteCount;
    }
    struct Voter {
        bool authorized;
        bool voted;
        uint vote;
    }
   
    address public owner;
    string public electionName;
    
    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    uint public totalVotes;
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; // Pre condition
    }
  
    function Election(string _name) public{
        owner = msg.sender;
        electionName = _name;
    }
   
    function addCandidate(string name) ownerOnly public {
        candidates.push(Candidate(name, 0));
    }
   
    function getNumCandidate() public view returns(uint) {
        return candidates.length;
    }
  
    function authorize(address _person) ownerOnly public {
        voters[_person].authorized = true;
    }
    
    function vote(uint _voteIndex) public {
        
        //make sure voter is authorized and has not already voted
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorized);
        
        //record vote
        voters[msg.sender].vote = _voteIndex;
        voters[msg.sender].voted = true;
        
        //increase candidate vote count by 1
        candidates[_voteIndex].voteCount += 1;
        totalVotes +=1 ;
    }
  
    // function end() ownerOnly public{
    //     selfdestruct(owner);
    // }

    // function endVote() public inState(State.Voting) owner{
    //  state = State.Ended ; 
    //  finalResult = countResult ;}
}