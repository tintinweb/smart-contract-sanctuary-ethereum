/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract Healtcare{
    struct Patient{
        string name;
        string place;
        uint age;
        string diseases;
        string allergies;
        bool insurance;
    }
    Patient[] public patientrecord;
    address public owner;
    constructor(){
        owner=msg.sender;
    }
    function setPatientRecord(string memory _name,string memory _place,uint _age,string memory _disease,string memory _allergy,bool _insurance) public{
        patientrecord.push(Patient(_name,_place,_age,_disease,_allergy,_insurance));
    }
    function getrecord() public view returns(Patient[] memory){
        return patientrecord;
    }
    function editRecord(uint index,string memory nam,string memory add,uint ag,string memory dis,string memory aller,bool insu)public{
        require(msg.sender==owner,"no access");
        patientrecord[index]=Patient(nam,add,ag,dis,aller,insu);
    }
    function setfee(uint i) public view  returns(uint){
        uint CheckupFees;
        
        if(patientrecord[i].insurance==true){
            CheckupFees=0;
        }
        else{
            CheckupFees=1000;
        }
        return CheckupFees;
    }
}