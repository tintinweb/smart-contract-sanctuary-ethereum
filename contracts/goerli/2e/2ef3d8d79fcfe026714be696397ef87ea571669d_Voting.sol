/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting {
    string[] public candidateList;
    mapping(string => uint) votesReceived;
    //address public Voter;
    
    constructor(string[] memory candidateName){
        candidateList = candidateName;
    }


    //mapping(candidateList => uint) public canIndexes;
 


    function voteForCandidate(string memory candidate) public{
        votesReceived[candidate] += 1;
    }

    function totalVotesFor(string memory candidate) public view returns (uint256){
        return votesReceived[candidate];
    }

    function candidateCount() public view returns (uint256){
        return candidateList.length;
    }

    function addCandidate(string memory newName) public {
        candidateList.push(newName);
    }

//การลบแบบเลื่อน index
    function removeItem(uint256 index) public{
        candidateList[index] = candidateList[candidateList.length-1];
        candidateList.pop();
        //delete candidateList(canIndexes[i]);
    }
    
}