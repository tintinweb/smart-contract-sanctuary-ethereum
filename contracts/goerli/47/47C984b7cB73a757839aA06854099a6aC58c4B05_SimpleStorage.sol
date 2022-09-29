/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


contract SimpleStorage {
   
struct adminInfo {
    string ssn;
    address account;
}


//...................................Admins..........................................//
   //create an array of admins  
    adminInfo[] internal admins;

 //Mapping to search for admins with address return the struct 
    
        mapping(address => adminInfo) public adminaddressTossn;


//admin store function
  
    function addAdmin(string memory _ssn, address _adminAddress) public {
        adminInfo memory newAdmin;
        newAdmin.ssn=_ssn;
        newAdmin.account=_adminAddress;
        admins.push(newAdmin);
        adminaddressTossn[_adminAddress] = newAdmin;
     }

     //admin verify/view function
     function getAdmin(address _adminAddress) public view returns (string memory){
        adminInfo memory s = adminaddressTossn[_adminAddress];
        return (s.ssn);
    }
    //...................................patients..........................................//

struct patientInfo {
    string ssn;
    address account;
}



   //create an array of admins  
    patientInfo[] internal patients;

 //Mapping to search for patient with address return the struct 
    
        mapping(address => patientInfo) public patientaddressTossn;


//admin store function
  
    function addPatient(string memory _ssn, address _patientAddress) public {
        patientInfo memory newPatient;
        newPatient.ssn=_ssn;
        newPatient.account=_patientAddress;
        patients.push(newPatient);
        patientaddressTossn[_patientAddress] = newPatient;
     }

     //admin verify/view function
     function getPatient(address _patientAddress) public view returns (string memory){
        patientInfo memory s = patientaddressTossn[_patientAddress];
        return (s.ssn);
    }


}