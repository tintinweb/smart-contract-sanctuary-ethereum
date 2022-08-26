/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract healthCare{
    struct Patient{
       // contract address 0x1fb1ee9c0d6714dd060172af99dc6bd5673a4c76
        string name;
        uint id;
        uint age;
        string data;
    }
    mapping(uint => Patient) public PatientData;
  Patient public patientData;

    function set(uint id,string memory name,uint age,string memory data) public{
       
    patientData=Patient(name,id,age,data);
    PatientData[id]=patientData;
    
    }

    function getData(uint id) public view returns(Patient memory){
        return PatientData[id];
    }


}