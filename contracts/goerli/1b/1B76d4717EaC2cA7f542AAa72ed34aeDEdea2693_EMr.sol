// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract EMr {
  
    struct Patient{
        string info;
        
    }

    mapping(string  => Patient) public PMap; 
    uint256 public numberOfPatients=0;
     
     function  addPatient (
        string memory _info,string memory _name
     )public{
        Patient memory currPat ;
        currPat.info=_info;
        PMap[_name]=currPat;
      numberOfPatients++;
        


     }
     function getPatient(string memory code) view public returns (
        Patient memory
     ){
        return PMap[code];

     }

    
     

}