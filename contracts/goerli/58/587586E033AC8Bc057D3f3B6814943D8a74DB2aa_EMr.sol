// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract EMr {
  
    struct Patient{
        string info;
        string public_info;
        
    }

    mapping(string  => Patient) public PMap; 
    mapping(string  => string[]) public FMap; 
    uint256 public numberOfPatients=0;
     
     function  addPatient (
        string memory _info,string memory _public_info, string memory puuid,string memory cuuid
     )public{
        Patient memory currPat ;
        currPat.info=_info;
        currPat.public_info=_public_info;
        PMap[cuuid]=currPat;
        
  
      FMap[puuid].push(cuuid);
        


     }

     
     
     function getPatient(string memory uid) view public returns (
        Patient memory
     ){
        return PMap[uid];

     }
      function getFamilyuid(string memory uid) view public returns (
        string[] memory
     ){
        return FMap[uid];

     }

     function delPatient(string memory uid )  public{
      Patient memory currPat ;
         PMap[uid]=currPat;

     }

    
     

}