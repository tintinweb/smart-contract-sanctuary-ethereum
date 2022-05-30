/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
struct Candidate{
    string name;//ชื่อคนสมัคร
    uint voteCount;//จำนวนคนเลือก
}
struct Voter{
    bool isRegister;
    bool isVoted;
    uint voteIndex;
}
contract Election{
    address public manager;//เจ้าหน้าที่จัดการเลือกตั้ง
    Candidate [] public candidates;
    mapping(address=>Voter) public voter;
    constructor(){
        manager = msg.sender;
    }
    modifier onlyManager{
        require(msg.sender == manager,"You Can't Manager");
        _;
    }
    function addCandidate(string memory name) onlyManager public{
        candidates.push(Candidate(name,0));
    }
    function register(address person) onlyManager public{
            voter[person].isRegister = true;
    }

    //เลือกตั้ง
    function vote(uint index) public{
        require(voter[msg.sender].isRegister,"You Can't Register");
        require(!voter[msg.sender].isVoted,"You are Elected");
        voter[msg.sender].voteIndex = index;
        voter[msg.sender].isVoted=true;
        candidates[index].voteCount+=1;
    }
}