/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0 < 0.9.0;
contract Election{
    struct Candidate{
        string name;
        uint votes;
    }
    struct Voter{
        string name;
        bool authorized; //whether the voter is authorized to vote or not
        uint whom; //uint because we will pass a list
        bool voted; 
    }
    address public owner ;
    string public electionName ;
    mapping (address => Voter) public voters;
    Candidate [] public candidates ;
    address[] public senders;
    uint public totalVotes;
    modifier ownerOnly(){
        require(msg.sender == owner);
        _; // only go ahead if the msg.sender is the owner else dont go ahead
    }
    function startElection(string memory _electionName) public {
        owner = msg.sender; // the person who will trigger this smart contract will become the owner of this election   
        electionName = _electionName;
    }
    function addCandidate(string memory _candidateName) ownerOnly public {
        candidates.push(Candidate(_candidateName,0));
    }
    function authorizeVoter(address _voterAddress) ownerOnly public {
        voters[_voterAddress].authorized=true; //voters at this voteraddress make authorized equals true
    }
    function getNumCandidates() public view returns(uint){
        return candidates.length;
    }
    function Vote(uint candidateIndex) public {
         // msg.sender returns the person who is currently accessing the smart contract
        require(!voters[msg.sender].voted); //checking if the voter has already voted or not
        require(voters[msg.sender].authorized);  //checking if the voter is authorized to vote or not
        senders.push(msg.sender);
        voters[msg.sender].whom = candidateIndex; //means the arg passed as candidateindex will be the one the msg.sender guy is voting for
        voters[msg.sender].voted=true;
        candidates[candidateIndex].votes++; //incrementing the number of votes in the candidate list of the particular index which was passed in the arg
        totalVotes++;
    }
    //function removeCandidate()
    function removeCandidate(uint candidateIndex) ownerOnly public{
        for(uint i=candidateIndex; i<candidates.length-1;i++){
            candidates[i]=candidates[i+1];
        }
        candidates.pop();
    }
    //function seeAllAuthVoters()
    //function to see all votes for a particular candidate
    function totalVotesOfCandidate(uint candidateIndex) public view returns(uint){
        return(candidates[candidateIndex].votes);
    }
}