// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

contract EHR {

    // Address of the admin (who deployed the contract), we only have one admin
    address admin;
    // Next patient id
    uint public id;

    // Doctor class, has two attributes
    // First attribute is a hashtable where the key is a patient id, and the value is a list of patient visit numbers to the clinic that were consulted by this doctor
    // Second attribute is a boolean to determine whether the doctor is registered or not
    struct Doctor {
        mapping(uint => uint[]) patientVisitNumbers;
        bool registered;
    }

    // Hashtable where the key is a doctor address, and the value is a doctor object
    mapping(address => Doctor) doctors;
    // Hashtable where the key is a nurse address, and the value is a boolean to determine whether the nurse is registered or not
    mapping(address => bool) nurses;
    // Hashtable where the key is a patient id, and the value is a list where the general information is stored at index 0 and the rest are visit informations
    mapping(uint => string[]) patients;

    // Smart contract constructor, the first person to deploy the contract will be the admin
    constructor() {                 
        admin = msg.sender;
        id = 1;      
    }
    
    // Transact function
    // Input: doctor address
    // This function registers a new doctor on the system, only an admin can do this
    function registerDoctor(address _address) public {
        require(msg.sender == admin, "Only an admin can register a new doctor!");
        require(!doctors[_address].registered, "This doctor is already registered!");
        doctors[_address].registered = true;
    }

    // Transact function
    // Input: nurse address
    // This function registers a new nurse on the system, only an admin can do this
    function registerNurse(address _address) public {
        require(msg.sender == admin, "Only an admin can add a new nurse!");
        require(!nurses[_address], "This nurse is already registered!");
        nurses[_address] = true;
    }

    // Transact function
    // Input: patient general information
    // This function registers a new patient on the system, only a nurse can do this
    function registerPatient(string memory _generalInfo) public {
        require(nurses[msg.sender], "Only a nurse can register a new patient!");
        patients[id++].push(_generalInfo);
    }

    // Transact function
    // Input: patient id - patient visit information
    // This function adds a new patient visit information to the system, only a doctor can do this
    // This visit information is also linked to the doctor who uploads it to the system
    function addVisit(uint _id, string memory _visitInfo) public {
        require(doctors[msg.sender].registered, "Only a doctor can add a new patient visit!");
        require(patients[_id].length != 0, "There is no patient registered with this id!");
        patients[_id].push(_visitInfo);
        doctors[msg.sender].patientVisitNumbers[_id].push(patients[_id].length-1);
    }

    // Call function
    // Input: login address
    // Return: integer where (0 => admin) - (1 => doctor) - (2 => nurse) - (3 => unknown) 
    function getRole(address _address) public view returns (uint){
        if (admin == _address) {
            return 0;
        }
        else if (doctors[_address].registered) {
            return 1;
        }
        else if (nurses[_address]) {
            return 2;
        }
        else {
            return 3;
        }
    }

    // Call function
    // Input: patient id
    // Return: patient general information
    function getGenInfo(uint _id) public view returns (string memory){
        require(patients[_id].length != 0, "There is no patient registered with this id!");
        return patients[_id][0];
    }

    // Call function
    // Input: doctor address - patient id
    // Return: List of patient visit numbers that were consulted by given doctor
    function getPatVisitNumbers(address _address, uint _id) public view returns (uint[] memory){
        require(patients[_id].length != 0, "There is no patient registered with this id!");
        require(doctors[_address].patientVisitNumbers[_id].length != 0, "You have never consulted this patient before!");
        return doctors[_address].patientVisitNumbers[_id];
    }

    // Call function
    // Input: patient id - patient visit number
    // Return: patient visit information
    function getVisitInfo(uint _id, uint visitNumber) public view returns (string memory){
        return patients[_id][visitNumber];
    }
}