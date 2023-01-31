/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

//voting contract
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
contract voting{
    mapping (address => bool) private votted;
    mapping (string => uint) public vote_count;
    string[] public candidate_list;

    address private Election_Commission = msg.sender;


    modifier For_Election_Commission(){
        require(msg.sender==Election_Commission,"You are not Allowed");
        _;
    }

    function setCandidateList(string[] memory list_Of_Candidates) public For_Election_Commission {
        candidate_list=list_Of_Candidates;
    }

    // constructor(string[] memory list_Of_Candidates){
    //     candidate_list=list_Of_Candidates;
    // }

    //funtion to check valid candidate
    function validCandidate(string memory candidate) view private returns(bool) {
    for (uint i=0;i<candidate_list.length;i++){
        if(keccak256(abi.encodePacked(candidate_list[i]))==keccak256(abi.encodePacked(candidate))){
            return true;
        }
    }
    return false;
    }


    // function to vote
    function vote(string memory voteFor) public{
        require(validCandidate(voteFor),"Invalid Candidate");
        require(votted[msg.sender]!=true,"You have already votted");
        vote_count[voteFor]+=1;
        votted[msg.sender]=true;

    }

}