pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

import "./Data.sol";
import "./AdminAuthorized.sol";

// Inherit abilities of admin authorization from above contract
contract EHR is AdminAuthorized {
    // Store a single object where
    // Each patient's address corresponds to the Data.PatientData
    // eg.   0xab32......2c   =>   Data.PatientData{.....}
    mapping(address => Data.PatientData) registeredUsers;

    // Store a single object where
    // Each authorized hospital's address corresponds to the Data.HospitalData
    // eg.   0xc43d......d8   =>   Data.HospitalData{.....}
    mapping(address => Data.HospitalData) authorizedHospitals;

    // Store a list/array of records for each patient separately
    // eg.   0xab32......2c   =>   [MedicalData{.....}, MedicalData{.....}, ... MedicalData{.....}]
   mapping(address => Data.MedicalData[]) userRecords;

    // Stores the basic information of admin when contract it is deployed
    Data.AdminData adminInfo;
    constructor(
        string memory adminName,
        string memory adminRegisteredNumber,
        string memory adminResidentialAddress
    ){
        adminInfo = Data.AdminData({
            name: adminName,
            registeredNumber: adminRegisteredNumber,
            residentialAddress: adminResidentialAddress
        });
    }

    // Function for Hospital registration, only permitted to admin
    function hospitalRegistration(
        address hospitalAddress,
        string memory name,
        string memory residentialAddress,
        string memory phone,
        string memory govtLicenseNumber,
        uint256 authorityIssueDate,
        uint256 authorityTerminalDate
    ) onlyAdmin public returns (bool){
        require(authorizedHospitals[hospitalAddress].authorityIssueDate == 0, "Authorized hospital data already available");
        Data.HospitalData memory newAuthorizedHospital = Data.HospitalData({
            name: name,
            Address: residentialAddress,
            phone: phone,
            govtLicenseNumber: govtLicenseNumber,
            authorityIssueDate: authorityIssueDate,
            authorityTerminalDate: authorityTerminalDate
        });
        authorizedHospitals[hospitalAddress] = newAuthorizedHospital;
        return true;
    }

    // Function to modify hospital data, only permitted to admin
    function modifyHospitalData(
        address hospitalAddress,
        string memory name,
        string memory residentialAddress,
        string memory phone,
        string memory govtLicenseNumber,
        uint256 authorityIssueDate,
        uint256 authorityTerminalDate
    ) onlyAdmin public returns (bool){
        require(authorizedHospitals[hospitalAddress].authorityIssueDate > 0, "Hospital is not registered/authorized");
        Data.HospitalData storage targetHospital = authorizedHospitals[hospitalAddress];
        targetHospital.name = name;
        targetHospital.Address = residentialAddress;
        targetHospital.phone = phone;
        targetHospital.govtLicenseNumber = govtLicenseNumber;
        targetHospital.authorityIssueDate = authorityIssueDate;
        targetHospital.authorityTerminalDate = authorityTerminalDate;
        return true;
    }
    
    // Function for User registration, only permitted to admin
    function userRegistration(
        address patientAddress,
        string memory fname,
        string memory lname,
        string memory phone,
        string memory residentialAddress,
        uint256 birthdate,
        Data.Gender gender
    ) onlyAdmin public returns (bool){
        require(registeredUsers[patientAddress].birthdate == 0, "User already registered");
        Data.PatientData memory newRegisteredUser = Data.PatientData({
            fname: fname,
            lname: lname,
            phone: phone,
            residentialAddress: residentialAddress,
            birthdate: birthdate,
            gender: gender
        });
        registeredUsers[patientAddress] = newRegisteredUser;
        return true;
    }

    // Function to modify user data, only permitted to admin
    function modifyUserData(
        address patientAddress,
        string memory fname,
        string memory lname,
        string memory phone,
        string memory residentialAddress,
        uint256 birthdate,
        Data.Gender gender
    ) onlyAdmin public returns (bool){
        require(registeredUsers[patientAddress].birthdate > 0, "User is not registered");
        Data.PatientData storage targetUser = registeredUsers[patientAddress];
        targetUser.fname = fname;
        targetUser.lname = lname;
        targetUser.phone = phone;
        targetUser.residentialAddress = residentialAddress;
        targetUser.birthdate = birthdate;
        targetUser.gender = gender;
        return true;
    }

    // Get information about specific registered user
    function getAdminInfo() public view returns (Data.AdminData memory){
        return adminInfo;
    }

    // Get information about specific authorized hospitals
    function getHospitalInfo(address hospitalAddress) public view returns (Data.HospitalData memory){
        return authorizedHospitals[hospitalAddress];
    }

    // Get information about specific registered user
    function getUserInfo(address patientAddress) public view returns (Data.PatientData memory){
        return registeredUsers[patientAddress];
    }

    // Get specified record for a particular person
    function getRecord(address person, uint256 idx) public view returns (Data.MedicalData memory){
        return userRecords[person][idx];
    }

    // Get all records for a particular person
    function getAllRecords(address person) public view returns (Data.MedicalData[] memory) {
        return userRecords[person];
    }

    // Function to add record for the hospitals
    function addRecord(
        address patient,
        string memory disease,
        string memory treatment,
        string memory medication,
        string memory DrName,
        string memory hospitalRecordID,
        uint256 diagnoseDate,
        uint256 dischargeDate,
        string[] memory cids,
        string[] memory titles
    ) public returns (uint256) {
        require(cids.length == titles.length, "CIDs and titles of files count must match"); 

        // After push, target index will pe previous length
        uint256 targetRecordIdx = userRecords[patient].length;
        userRecords[patient].push();

        Data.MedicalData storage newRecord = userRecords[patient][targetRecordIdx];
        newRecord.senderHospital = msg.sender;
        newRecord.approved = false;
        newRecord.declineMsg = '';
        newRecord.patient = patient;
        newRecord.disease = disease;
        newRecord.treatment = treatment;
        newRecord.medication = medication;
        newRecord.DrName = DrName;
        newRecord.hospitalRecordID = hospitalRecordID;
        newRecord.diagnoseDate = diagnoseDate;
        newRecord.dischargeDate = dischargeDate;
        for (uint256 i=0; i<cids.length; i++) {
            newRecord.reports.push(Data.Media(titles[i], cids[i]));
        }

        // Not necessarily required, as it can be derived from getAllRecords
        return userRecords[patient].length - 1;
    }

    // Function to approve record to the profile, done by the user
    // 'msg.sender' in this function ensures that the user can approve only own records
    function approveRecord(uint256 recordID) public returns (bool){
        // Check if the specified record exists
        uint256 recordsLength = userRecords[msg.sender].length;
        require(recordID >= 0, "Attempt to access record at negative index");
        require(recordID < recordsLength, "Attempt to access Invalid record");

        // Obtain specified medical record
        Data.MedicalData storage targetMedicalRecord = userRecords[msg.sender][recordID];

        // Verify that the specified medical record isn't already declined
        require(bytes(targetMedicalRecord.declineMsg).length == 0, "Record already declined !");
        
        // Verify that the specified medical record isn't already approved
        require(targetMedicalRecord.approved == false, "Record already approved!");
        
        // Approve record
        targetMedicalRecord.approved = true;
        return true;
    }

    // Function to decline record added to the profile, done by the user
    // 'msg.sender' in this function ensures that the user can approve only own records
    function declineRecord(uint256 recordID, string memory declineMsg) public returns (bool){
        // Check if the specified record exists
        uint256 recordsLength = userRecords[msg.sender].length;
        require(recordID >= 0, "Attempt to access record at negative index");
        require(recordID < recordsLength, "Attempt to access Invalid record");

        // Obtain specified medical record
        Data.MedicalData storage targetMedicalRecord = userRecords[msg.sender][recordID];

        // Verify that the specified medical record isn't already approved
        require(targetMedicalRecord.approved == false, "Record already approved!");
        
        // Verify that the specified medical record isn't already declined
        require(bytes(targetMedicalRecord.declineMsg).length == 0, "Record already declined !");

        // Decline record
        targetMedicalRecord.declineMsg = declineMsg;
        return true;
    }

    // Possible feature
    //    mapping(aadhar => [address, address]) aadharToAccountLogin;
}

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

contract AdminAuthorized{
    // Private variable to store admin's identity (address)
    address private adminAddress;
    
    // Stores the identity of admin when contract it is deployed
    constructor(){
        adminAddress = msg.sender;
    }

    // Publicly show the admin's identity (Not used in webapp, but for debugging)
    function admin() public view returns(address) {
        return adminAddress;
    }

    // onlyAdmin modifier validates only if function caller is admin 
    // This can be reused wherever admin authority needs to be verified
    modifier onlyAdmin(){
        require(msg.sender == adminAddress, "Admin authorization required for this action !!");
        _;
    }
    
    // function for the admin to verify their ownership. 
    // Returns true for admin otherwise false
    function isAdmin() public view returns(bool) {
        return msg.sender == adminAddress;
    }
}

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

library Data{
    // Possible values for gender
    // Corresponding values while integrating with web3 or calling fn via remix:
    //          MALE: 0,     FEMALE: 1,     NONBINARY: 2
    enum Gender { MALE, FEMALE, NONBINARY }

    // Object to store basic information about the admin
    // Added during contract deployment & can't be modified later
    struct AdminData {
        string name;
        string registeredNumber;
        string residentialAddress;
    }

    // Object to store basic information about the patient
    // This can be added/modified only by the admin 
    struct PatientData {
        string fname;
        string lname;
        string phone;
        string residentialAddress;
        uint256 birthdate;
        Gender gender; 
    }
     
    // Object to store basic information about the hospital
    // This can be added/modified only by the admin 
    struct HospitalData {
        string name;
        string Address;
        string phone;

        // License number alloted to hospital by the Govt.
        // For reference purpose
        string govtLicenseNumber;

        // Authority issued by blockchain admin starts from this date
        uint256 authorityIssueDate;

        // Authority issued by blockchain admin ends on this date
        // Hospital must get the audit/verification done & authority renewed by admin 
        uint256 authorityTerminalDate;
    }

    struct Media {
        string title;
        // string description;
        string cid;
    }

    // Object to store medical record information
    // This is supposed to be added by the hospital 
    struct MedicalData {
        // Identifies the hospital responsible for this record
        address senderHospital;

        // Value set to false on adding recorded and then toggled to true when approved by user
        bool approved;

        // Value set to empty string by default & changed to string if declined by the user
        string declineMsg;

        // Public address of the patient kept for convenience (Not used for authorization anywhere)
        address patient;

        // Actual medical data
        string disease;
        string treatment;
        string medication;
        string DrName;

        // Record ID of the hospital specific medical record management system
        // Maintainence of this makes it convenient to track down the medical event 
        string hospitalRecordID;
        
        uint256 diagnoseDate;
        uint256 dischargeDate;      // Set to 0 if patient was not admitted

        Media[] reports;
    }
}