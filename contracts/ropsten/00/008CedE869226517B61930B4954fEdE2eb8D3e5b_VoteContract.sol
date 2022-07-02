// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//create events
contract VoteContract{
event StartTimer(uint startTime);

  address owner;
  uint hasPicked;
  uint voteTotal;
  mapping (address => bool) private voted;
  uint c1;
  uint c2;
  uint c3;
  uint c4;

constructor(){
owner=msg.sender;
hasPicked=1;
voteTotal=0;
c1=0;
c2=0;
c3=0;
c4=0;
}

struct Candidates {
 uint256 p1;
 uint256 p2;
 uint256 p3;
 uint256 p4;
} 

Candidates private candidates;

//admin starts the time limit to vote 
function startTime(uint timer) public onlyOwner{
emit StartTimer(timer);
}


//choose candidate, tally is done automatically
function pickPerson(uint pick)public returns(string memory winner){
 require(voted[msg.sender] == false,"user already voted");
 Candidates memory candidates1 = Candidates(1,2,3,4);
 
 if(pick == candidates1.p1){
   voted[msg.sender]=true;
   c1++;
    voteTotal++;
  return "You picked candidate #1";
 }
  else if(pick == candidates1.p2){
     voted[msg.sender]=true;
     c2++;
    voteTotal++;
  return "You picked candidate #2";
 }
 else if(pick == candidates1.p3){
    voted[msg.sender]=true;
    c3++;
    voteTotal++;
  return "You picked candidate #3";
 }
  else if(pick == candidates1.p4){
     voted[msg.sender]=true;
     c4++;
    voteTotal++;
  return "You picked candidate #4";

 } else{
   revert("Please select one of the 4 candidates");
 }

}


//returns total votes tallied
function voteCount() public view returns(uint){
  return voteTotal; 
}

//returns all candidate results
function candidatesCount() public view returns(uint num1,uint num2,uint num3,uint num4){
  return (c1,c2,c3,c4);
}


 //only owner can transact modifier
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }
 



}