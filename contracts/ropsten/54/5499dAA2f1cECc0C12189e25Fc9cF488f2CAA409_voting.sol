/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT License

pragma solidity 0.8.15;

contract voting{

    struct candidate{
        uint id;
        string name;
        uint VoteCount;
    }

    candidate [] candidatelist;

    uint CandidateCount;
    address Owner;

    mapping (uint => candidate) candidates;
    mapping (address => bool) participants;

    constructor(){
        Owner = msg.sender;
    }
    modifier onlyowner(address){
        require (msg.sender==Owner , "Acces Denied");
        _;
    }
    function AddCandidate(string memory _name) public onlyowner(msg.sender) returns(string memory){
        CandidateCount ++;
        candidate(CandidateCount,_name,0);
        candidates[CandidateCount] = candidate(CandidateCount,_name,0);
        candidatelist.push(candidate(CandidateCount,_name,0));
        return "Success";
    }
    function ShowCandidates() public view returns(candidate [] memory){
        return candidatelist;
    }

    function Vote(uint _id) public returns(string memory){
        require(_id <= CandidateCount && _id>0 , "Candidate`s Id Not Found");
        require( participants[msg.sender]==false) ;
        candidates[_id].VoteCount ++;
        participants[msg.sender]=true;
        return "Your Vote Submitted Successfully";
    }

    
    function ShowWinner()public view returns(string memory , uint){
        uint WinnerId;
        uint WinnerVote;

        for (uint i=0; i<=CandidateCount ; i++){
            if (candidates[i].VoteCount>WinnerVote){
               WinnerVote = candidates[i].VoteCount;
               WinnerId = candidates[i].id;
            }
        }
        return (candidates[WinnerId].name, candidates[WinnerId].VoteCount);
    }

}