//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

//import "hardhat/console.sol";

contract Voteapp{

    address public owner;
    string[] public voteArray;
    constructor(){
        owner = msg.sender;
    }

    struct candidate{
        bool exists;
        uint256 votes;
        mapping(address => bool) Voters;
    }
    event voteUpdate (    
        uint256 votes,
        address voter,
        string voted );
    
    mapping(string => candidate) private Candidates;

    function addCandidate(string memory _candidate) public{
        require(msg.sender == owner, "You don't have the proper authentification");

        candidate storage newCandidate = Candidates[_candidate];
        newCandidate.exists = true;
        voteArray.push(_candidate);

            }

    function vote(string memory _candidate) public{
        require(Candidates[_candidate].exists, "This candidate doesnt exist");
        require(!Candidates[_candidate].Voters[msg.sender], "You have already voted");

        candidate storage c = Candidates[_candidate];
        c.Voters[msg.sender]= true;
        c.votes++;
        emit voteUpdate(c.votes,msg.sender,_candidate);
    }

    function getVotes(string memory _candidate) public view returns( uint256 votes){
        require(Candidates[_candidate].exists, "This candidate doesnt exist");
        candidate storage c = Candidates[_candidate];
        return(c.votes);
    }

}