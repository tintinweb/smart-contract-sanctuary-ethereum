/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Candidate {
    string name;   // ชื่อผู้สมัคร
    string party;  // พรรค
    uint votecount;
}

struct Voter {
    bool isRegister;
    bool isVoted;
    uint voteIndex;
}

struct Winner {
    bool isWinner;
    string name;
    string party;
    uint totalVote;
}

contract Election {
    address public Manager; // เจ้าหน้าที่
    Candidate [] public candidates;
    Winner [1] public winner;
    mapping(address=>Voter) public voter;
    constructor(){
        Manager = msg.sender;
    }
    //เป็นคำสั่งคนที่ใช่งาน function ได้แค่ manager เท่านั้น
    modifier onlyManager{
        require(msg.sender == Manager,"You Can't add Candidate Function");
        _;
    }
    // เพิ่มผู้สมัคร by Manager
    function AddCandidate(string memory name, string memory party) onlyManager public{
        
        candidates.push(Candidate(name,party,0));

    }
    //ลงทะเบียน voter
    function register(address person) onlyManager public{
        voter[person].isRegister = true;
    }

    function vote(uint index) public{
        //check ว่าลงทะเบียนยัง
        require(voter[msg.sender].isRegister,"You Can't Vote");
        //check ลง vote หรือยัง
        require(!voter[msg.sender].isVoted,"You are Elected");
        require(!winner[0].isWinner,"Election already end");
        //เก็บเลข index ที่ vote
        voter[msg.sender].voteIndex = index;
        voter[msg.sender].isVoted = true;
        candidates[index].votecount +=1;
    }

    function maxVote() public view returns(uint){
        uint i;
        uint largest = 0;
        uint WinCandidate;
        for(i = 0; i < candidates.length; i++){
            if(candidates[i].votecount > largest) {
                largest = candidates[i].votecount; 
                WinCandidate = i;
            } 
        }
        return WinCandidate;
        
    }

    function WinnerCandidate() onlyManager public{
        uint WinnerIndex = maxVote();
        winner[0].isWinner = true;
        winner[0].name = candidates[WinnerIndex].name;
        winner[0].party = candidates[WinnerIndex].party;
        winner[0].totalVote = candidates[WinnerIndex].votecount;   
    }
    
}