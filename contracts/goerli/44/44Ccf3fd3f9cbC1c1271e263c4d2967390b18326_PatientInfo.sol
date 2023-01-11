// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

/**
Notes: This contract will hold the patient information and then be added to blockchain
- Can only be verified by a person who holds an "account" -- which are trusted healthcare individuals
- Python Scripts: There should be a script to deploy this contract for a new patient
  - Should be a script to grab a contract from the blockchain and edit it, which means there needs to be an interface for
   this contract
 */

import "PatientStruct.sol";

contract PatientInfo is PatientStruct {
    // patientIns object created from patientIns Struct in patientStruct.sol
    Patient private patientIns;

    // Declare mapping for those who are authorized to view this record
    // The reason for "mapping" instead of array to hold the addresses is because
    // we have to check if address exists in these list. Solidity doesn't have a
    // a function to check if something exists in an array, so it's more efficient to use a mapping
    mapping(address => bool) private authorizedUsersTier1;
    mapping(address => bool) private authorizedUsersTier2;
    mapping(address => bool) private authorizedUsersTier3;

    // Declare the patientIns as the person with unrestricted access
    address private patientInsAddress;

    // Modifier -- use this to restrict functions for patientIns use only
    modifier restrictpatientInsOnly() {
        require(msg.sender == patientInsAddress);
        _;
    }

    /**
        Modifiers for Tier System -- different tiers of healthcare individuals get access to certain patientIns info
            For ex. tier 1 could be just for receptionists where they only have access to name, address, phone number, etc.
                tier 2 could just be for nurses, for instance, where they have access to both tier 1 info and also height, weight, bp, etc.
                tier 3 could be for doctors, with more sensitive health info
     */
    modifier restrictTier1() {
        require(authorizedUsersTier1[msg.sender] == true);
        _;
    }

    modifier restrictTier2() {
        require(authorizedUsersTier2[msg.sender] == true);
        _;
    }

    modifier restrictTier3() {
        require(authorizedUsersTier3[msg.sender] == true);
        _;
    }

    // Constructor with essential info supplied
    constructor(
        string memory _name,
        string memory _address_,
        string memory _dob,
        uint256 _phoneNum,
        string memory _email
    ) public {
        patientIns.name = _name;
        patientIns.address_ = _address_;
        patientIns.dob = _dob;
        patientIns.phoneNum = _phoneNum;
        patientIns.email = _email;
    }

    // Setter Functions (An address/healthcare individual needed to run these functions)
    function setName(string memory _name) public {
        patientIns.name = _name;
    }

    function setAddress(string memory _address_) public {
        patientIns.address_ = _address_;
    }

    function setDob(string memory _dob) public {
        patientIns.dob = _dob;
    }

    function setGender(string memory _gender) public {
        patientIns.gender = _gender;
    }

    function setPhoneNum(uint256 _phoneNum) public {
        patientIns.phoneNum = _phoneNum;
    }

    function setEmail(string memory _email) public {
        patientIns.email = _email;
    }

    function setPcp(string memory _pcp) public {
        patientIns.pcp = _pcp;
    }

    function addRace(string memory _race) public {
        patientIns.race.push(_race);
    }

    function addEthnicity(string memory _ethnicity) public {
        patientIns.ethnicity.push(_ethnicity);
    }

    function addLanguage(string memory _language) public {
        patientIns.languages.push(_language);
    }

    function setTemperature(uint256 _temperature) public {
        patientIns.temperature = _temperature;
    }

    function setHeartRate(uint256 _heartRate) public {
        patientIns.heartRate = _heartRate;
    }

    function setHeight(uint256 _height) public {
        patientIns.height = _height;
    }

    function setWeight(uint256 _weight) public {
        patientIns.weight = _weight;
    }

    // **Check if this is correct way to calculate bmi, assuming weight in pounds and height in feet
    // Also, require that height and weight are set before using this function
    function calculateBmi() public {
        patientIns.bmi = patientIns.weight / patientIns.height**2;
    }

    function writeSynopsis(string memory _medicalSynopsis) public {
        patientIns.medicalSynopsis = _medicalSynopsis;
    }

    function writePastMedicalHistory(string memory _pastMedicalHistory) public {
        patientIns.pastMedicalHistory = _pastMedicalHistory;
    }

    function addMedication(string memory _medication) public {
        patientIns.medications.push(_medication);
    }

    function writeSocialHistory(string memory _socialHistory) public {
        patientIns.socialHistory = _socialHistory;
    }

    function writeAlcoholDetails(string memory _alcoholDetails) public {
        patientIns.alcoholDetails = _alcoholDetails;
    }

    function writeFamilyHistory(string memory _familyHistory) public {
        patientIns.familyHistory = _familyHistory;
    }

    // Getter (View) Functions -- only patientIns and whoever was granted access can view
    function getName() public view returns (string memory) {
        return patientIns.name;
    }

    function getAddress() public view returns (string memory) {
        return patientIns.address_;
    }

    function getDob() public view returns (string memory) {
        return patientIns.dob;
    }

    function getPhoneNum() public view returns (uint256) {
        return patientIns.phoneNum;
    }

    function getEmail() public view returns (string memory) {
        return patientIns.email;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract PatientStruct {
    struct Patient {
        // What should be included as a patient record
        string name;
        string address_;
        string dob;
        string gender;
        uint256 phoneNum;
        string email;
        string pcp;
        string[] race;
        string[] ethnicity;
        string[] languages;
        // Vital Signs
        uint256 temperature;
        uint256 heartRate;
        uint256 height;
        uint256 weight;
        uint256 bmi;
        // Medical Info
        string medicalSynopsis;
        string pastMedicalHistory;
        string[] medications;
        string socialHistory;
        string alcoholDetails;
        string familyHistory;
    }
}