/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// File: Election.sol



pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

contract  Election  {
    address public owner; // the owner of the smart contract 

    Candidate [] public candidates ; // a list of candidate

    uint private totalVotes; // total of Votes

    constructor(){
        owner = msg.sender;
    }
    //  the candidate structure
    struct Candidate {
        string name;
        string imageUrl;
        uint numVotes;
    }
// the candidate 
    struct Voter {
        string name; // is name
        string cartNumber;
        bool authorized;
        uint whom; // whom he vhas oted 
        bool  isVoted; // verify if he had voted
    }

    string public electionName; // the name of the election

    modifier ownerOnly(){
        require(msg.sender  == owner); // put a little condition , only the one who deployed the smart contract would have some right
    _; 
    }

    mapping(address => Voter) public voters; // this is the hashage table that connect address and voter identity


    function startElection(string memory _electionName) public {
      //  owner =  msg.sender ; // the owner is the person who has deployed the smart contract
        electionName = _electionName ;
    }

    function addCandidate(string memory _candidateName , string memory _image ) ownerOnly public  {
        candidates.push(Candidate(_candidateName ,_image , 0 )); //  adding a candidate
    } 
    
    function authorized(address _voterAdress) ownerOnly public {
        voters[_voterAdress].authorized = true;
    }

    function getNumCandidates() public view returns (uint){ // candidates length
        return candidates.length;
    }

    function vote(uint candidateIndex) public {
        require(!voters[msg.sender].isVoted); // verify if voters has not already voted
        require(voters[msg.sender].authorized); // check  if the voters is authorized to vote

        voters[msg.sender].whom  = candidateIndex;
        voters[msg.sender].isVoted  = true;
        candidates[candidateIndex].numVotes ++ ;
        totalVotes ++ ;
    }

    function seeAllCandiddate()public view returns(Candidate [] memory ){ // see all Candidates and their information
        return candidates;
    }

    function candididateInfo(uint index)public view returns(Candidate  memory ){ // see one Candidates and their information
        return candidates[index];
    }

    function getTotalVotes() public view returns(uint){
        return totalVotes; // see total of votes 
    }

}