/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract TheHiddenMission {

   function IntelligenceA(string memory userinput) public view returns(string memory){
      if (keccak256(bytes(userinput)) == keccak256(bytes("sisyphus")))
      {
         return "8Fgm5";
      }
      else if (keccak256(bytes(userinput)) == keccak256(bytes("sheep")))
      {
         return "9cofAc";
      }
      else if (keccak256(bytes(userinput)) == keccak256(bytes("electric")))
      {
         return "FKd8b";
      }       
   }

   function IntelligenceB(string memory userinput2) public view returns(string memory){
      if (keccak256(bytes(userinput2)) == keccak256(bytes("chip")))
      {
         return "5Kfidf";
      }
      else if (keccak256(bytes(userinput2)) == keccak256(bytes("secret")))
      {
         return "1MXCnt";
      }   
      else if (keccak256(bytes(userinput2)) == keccak256(bytes("pass")))
      {
         return "kfj2E";
      }   
   }

   function IntelligenceC(string memory userinput3) public view returns(string memory){
      if (keccak256(bytes(userinput3)) == keccak256(bytes("word")))
      {
         return "KfDcmd";
      }
      else if (keccak256(bytes(userinput3)) == keccak256(bytes("human")))
      {
         return "cdFk2";
      }   
      else if (keccak256(bytes(userinput3)) == keccak256(bytes("code")))
      {
         return "MOSeg";
      }   
   }

   function IntelligenceD(string memory userinput4) public view returns(string memory){
      if (keccak256(bytes(userinput4)) == keccak256(bytes("augmented")))
      {
         return "jFid87";
      }
      else if (keccak256(bytes(userinput4)) == keccak256(bytes("hidden")))
      {
         return "fj2kg";
      }   
      else if (keccak256(bytes(userinput4)) == keccak256(bytes("correct")))
      {
         return "23FjcK";
      }   
   }
}