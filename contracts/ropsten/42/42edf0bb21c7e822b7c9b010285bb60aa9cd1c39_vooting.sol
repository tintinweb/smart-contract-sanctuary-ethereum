/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

//SPDX-License-Identifier: MIT

 pragma solidity 0.8.0;

  contract vooting{

  address Owner;
  constructor(){Owner = msg.sender;}


  struct Candid{
      string Name;
       uint ID ;
        uint voutcount;
  } uint id= 0;

   mapping(uint => Candid) public Candidate;
    mapping(address => bool) Statuse;

     
      function Candidates(string memory name) public {
         require(msg.sender == Owner," You are not Owner");
          id++;
           Candidate[id]= Candid(name , id , 0);
        }


     function voter(uint count) public {
         require(msg.sender != Owner," You are Owner");
           require(Statuse[msg.sender] != true," You have a vout");
         Candidate[count].voutcount++;
           Statuse[msg.sender]= true;

        }


   function winner() public view returns(string memory) {
     require(msg.sender == Owner, "You are not Owner");
      uint winnerid= 0;
        uint winnervoute= 0;
            for(uint i=0; i<= id; i++){
         if(Candidate[i].voutcount >= winnervoute){
               winnerid= i;
                winnervoute= Candidate[i].voutcount;
         }
      }
     return Candidate[winnerid].Name;
   }
 }