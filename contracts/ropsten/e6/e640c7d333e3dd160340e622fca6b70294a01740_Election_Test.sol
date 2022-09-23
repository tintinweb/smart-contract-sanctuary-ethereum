/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Candidate {
    string name;   // ชื่อผู้สมัคร
    string party;  // พรรค
    string Image;
    uint votecount;
}

struct Voter {
    bool isRegister;
    bool isVoted;
    string votewho;
}

struct Winner {
    bool isWinner;
    string name;
    string party;
    uint totalVote;
}



contract Election_Test {
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
    function AddCandidate(string memory name, string memory party , string memory Image) onlyManager public{
        
        candidates.push(Candidate(name,party,Image,0));

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
        voter[msg.sender].votewho = candidates[index].name;
        voter[msg.sender].isVoted = true;
        candidates[index].votecount +=1;
    }

    function maxVote() public view returns(uint){
        uint i;
        uint largest = 0;
        uint WinCandidate;
        uint secoundCandidate = 0;
        for(i = 0; i < candidates.length; i++){
            if(candidates[i].votecount > largest) {
                largest = candidates[i].votecount; 
                WinCandidate = i;
                secoundCandidate = 0;
            }
        }
        return WinCandidate;
        
    }

     function Checkequal() public view returns(bool){
        uint i;
        uint largest = 0;
        uint WinCandidate;
        bool Haveequalscore = false;
        for(i = 0; i < candidates.length; i++){
            if(candidates[i].votecount > largest) {
                largest = candidates[i].votecount; 
                WinCandidate = i;
                Haveequalscore = false;
            }else if(candidates[i].votecount == largest){
               Haveequalscore = true;
            }
        }
        return Haveequalscore;
        
    }

    function WinnerCandidate() onlyManager public{
        uint WinnerIndex = maxVote();
        bool Haveequalscore = Checkequal();
        require(Haveequalscore != true,"Don't Have Winner in Election");
        winner[0].isWinner = true;
        winner[0].name = candidates[WinnerIndex].name;
        winner[0].party = candidates[WinnerIndex].party;
        winner[0].totalVote = candidates[WinnerIndex].votecount;   
    }
    
}