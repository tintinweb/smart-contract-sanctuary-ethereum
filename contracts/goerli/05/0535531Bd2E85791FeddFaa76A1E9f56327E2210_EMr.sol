// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract EMr {
  
    struct Patient{
        string name;
        
    }

    mapping(uint256  => Patient) public PMap; 
    uint256 public numberOfPatients=0;
     
     function addPatient(
        string memory _name
     ) public returns (uint256){
        Patient storage currPat = PMap[numberOfPatients];
        currPat.name=_name;
      numberOfPatients++;
        return numberOfPatients-1;


     }
     function getPatient(uint256 _id) view public returns (
        Patient memory
     ){
        return PMap[_id];

     }

     function getAllPatients() view public returns (
        Patient[] memory
     ){
       Patient[] memory allPatients = new Patient[](numberOfPatients);
       for(uint i=0;i<numberOfPatients;i++){
           Patient storage item = PMap[i];
           allPatients[i]=item;
       }
        return allPatients;

     }
     

}