//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract record {
    struct Patients {
        string ic;
        string name;
        string phone;
        string gender;
        string dob;
        string height;
        string weight;
        string houseaddr;
        string bloodgroup;
        string allergies;
        string medication;
        // string emergencyName;
        // string emergencyContact;
        address addr;
        uint256 date;
    }
    address public owner;
    address[] public patientList;
    mapping(address => Patients) patients;
    uint256 public patientCount = 0;

    constructor() {
        owner = msg.sender;
    }

    //Retrieve patient details from user sign up page and store the details into the blockchain
    function setDetails(
        string memory _ic,
        string memory _name,
        string memory _phone,
        string memory _gender,
        string memory _dob,
        string memory _height,
        string memory _weight,
        string memory _houseaddr,
        string memory _bloodgroup,
        string memory _allergies,
        string memory _medication
        // string memory _emergencyName,
        // string memory _emergencyContact
    ) public {
        patients[msg.sender] = Patients({
            ic: _ic,
            name: _name,
            phone: _phone,
            gender: _gender,
            dob: _dob,
            height: _height,
            weight: _weight,
            houseaddr: _houseaddr,
            bloodgroup: _bloodgroup,
            allergies: _allergies,
            medication: _medication,
            // emergencyName: _emergencyName,
            // emergencyContact: _emergencyContact,
            addr: msg.sender,
            date: block.timestamp
        });

        patientList.push(msg.sender);
        patientCount++;
    }

    //Allows patient to edit their existing record
    function editDetails(
        string memory _ic,
        string memory _name,
        string memory _phone,
        string memory _gender,
        string memory _dob,
        string memory _height,
        string memory _weight,
        string memory _houseaddr,
        string memory _bloodgroup,
        string memory _allergies,
        string memory _medication
        // string memory _emergencyName,
        // string memory _emergencyContact
    ) public {
        patients[msg.sender] = Patients({
            ic: _ic,
            name: _name,
            phone: _phone,
            gender: _gender,
            dob: _dob,
            height: _height,
            weight: _weight,
            houseaddr: _houseaddr,
            bloodgroup: _bloodgroup,
            allergies: _allergies,
            medication: _medication,
            // emergencyName: _emergencyName,
            // emergencyContact: _emergencyContact,
            addr: msg.sender,
            date: block.timestamp
        });
    }

    //Retrieve list of all patient address
    function getPatients() public view returns (address[] memory) {
        return patientList;
    }
    function searchPatientDemographic(address _address) public view returns(string memory, string memory, string memory, string memory, string memory, string memory, string memory) {        
        Patients memory p = patients[_address];
        
        return (p.ic, p.name, p.phone, p.gender, p.dob, p.height, p.weight);
    }
    function searchPatientMedical(address _address) public view returns(string memory, string memory, string memory, string memory) {
        
        Patients memory p = patients[_address];
        
        return (p.houseaddr, p.bloodgroup, p.allergies, p.medication);
    }
    //Retrieve patient count
    function getPatientCount() public view returns (uint256) {
        return patientCount;
    }
}