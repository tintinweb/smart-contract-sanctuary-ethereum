/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


contract VotingForTopper {
    address owner;
    string public purpose;


    struct Voter {
        bool voted;
    }




    uint256 totalVotes;
    uint256 public Apple;
    uint256 public Banana;
    uint256 public cherry;


    mapping(address => Voter) info;


    constructor(string memory _name) public {
        purpose = _name;
        owner = msg.sender;
    }


    function voteForApple() public {    
        Apple++;
        totalVotes++;
    }


 
    function voteForBanana() public {    
        Banana++;
        totalVotes++;
    }


    function voteForcherry() public {  
        cherry++;
        totalVotes++;
    }


    function getTotalVotes() public view returns (uint256) {
        return totalVotes;
    }


    function getVotesForApple() public view returns (uint256) {
        return Apple;
    }


    function getVotesForBanana() public view returns (uint256) {
        return Banana;
    }


    function getVotesForcherry() public view returns (uint256) {
        return cherry;
    }


}