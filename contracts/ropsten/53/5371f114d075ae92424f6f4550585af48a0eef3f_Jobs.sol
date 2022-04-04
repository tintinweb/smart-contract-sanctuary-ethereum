/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.5.2;

contract Jobs {

 
  struct Hr{
      uint HrId;
      string name;
      uint phone;
  } 

    struct Candidate{
      uint CandidateId;
      string name;
      uint phone;
  } 
  
  uint nextHrId;
  uint nextCandidateId;

  mapping(uint=>Hr) public hrs;
  mapping(uint=>Candidate) public candidates;

  function addHr(string memory _name,uint _phone) public  {
       hrs[nextHrId]= Hr(nextHrId,_name,_phone);
       nextHrId++ ;
  }

    function addCandidate(string memory _name,uint _phone) public  {
       candidates[nextCandidateId]= Candidate(nextCandidateId,_name,_phone);
       nextCandidateId++ ;
  }


}