// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract HospitalManagement {
    struct Patient {
        uint256 id;
        string name;
        string email;
        string password;
        string patientaddress;
        string phone;
        string sex;
        string birthDate;
        uint256 age;
        string gender;
        string ailment;
        uint256 roomId;
        bool isActive;
    }
    struct Doctor {
        uint256 id;
        string name;
        string email;
        string password;
        uint256 fee;
        string phone;
        string department;
        string speciality;
        uint256 experience;
        bool isActive;
    }
    struct Room {
        uint256 id;
        string roomType;
        string roomNo;
        uint256 costPerDay;
        uint256 noOfBeds;
        uint mealCostPerDay;
        bool isOccupied;
    }
    string public contractName = "Hospital Management System";
    address public owner;
    uint256 private patientCounter;
    uint256 private doctorCounter;
    uint256 private roomCounter;

    mapping(string => Patient) private patients;
    mapping(string => Doctor) private doctors;
    mapping(uint256 => Room) private rooms;

    // Access control mapping for patient records
    mapping(string => mapping(address => bool)) private patientAccess;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can perform this action."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        patientCounter = 0;
        doctorCounter = 0;
        roomCounter = 0;
    }

    function getContractName() public pure returns (string memory) {
        return "Hospital Management System";
    }

    function registerPatient(
        string memory _name,
        string memory _email,
        string memory _password,
        string memory _patientaddress,
        string memory _phone,
        string memory _sex,
        string memory _birthdate,
        uint256 _age,
        string memory _gender,
        string memory _ailment
    ) public onlyOwner {
        patientCounter++;
        patients[_email] = Patient(
            patientCounter,
            _name,
            _email,
            _password,
            _patientaddress,
            _phone,
            _sex,
            _birthdate,
            _age,
            _gender,
            _ailment,
            0,
            true
        );
    }

    function registerDoctor(
        string memory _name,
        string memory _email,
        string memory _password,
        uint256 _fee,
        string memory _phone,
        string memory _department,
        string memory _speciality,
        uint256 _experience
    ) public {
        doctorCounter++;
        doctors[_email] = Doctor(
            doctorCounter,
            _name,
            _email,
            _password,
            _fee,
            _phone,
            _department,
            _speciality,
            _experience,
            true
        );
    }

    function addRoom(
        //bool isOccupied
        string memory _roomType,
        string memory roomNo,
        uint256 costPerDay,
        uint256 noOfBeds,
        uint mealCostPerDay
    ) public onlyOwner {
        roomCounter++;
        rooms[roomCounter] = Room(
            roomCounter,
            _roomType,
            roomNo,
            costPerDay,
            noOfBeds,
            mealCostPerDay,
            false
        );
    }

    function assignRoomToPatient(
        string memory _patientEmail,
        uint256 _roomId
    ) public onlyOwner {
        require(patients[_patientEmail].isActive, "Patient not found.");
        require(!rooms[_roomId].isOccupied, "Room is already occupied.");

        if (patients[_patientEmail].roomId != 0) {
            rooms[patients[_patientEmail].roomId].isOccupied = false;
        }

        patients[_patientEmail].roomId = _roomId;
        rooms[_roomId].isOccupied = true;
    }

    function getPatient(
        string memory _patientEmail
    ) public view returns (Patient memory) {
        require(patients[_patientEmail].isActive, "Patient not found.");

        require(
            patientAccess[_patientEmail][msg.sender] || msg.sender == owner,
            "You do not have permission to view this patient record."
        );
        return patients[_patientEmail];
    }

    function grantAccess(
        string memory _patientEmail,
        address _user
    ) public onlyOwner {
        require(patients[_patientEmail].isActive, "Patient not found.");
        patientAccess[_patientEmail][_user] = true;
    }

    function revokeAccess(
        string memory _patientEmail,
        address _user
    ) public onlyOwner {
        require(patients[_patientEmail].isActive, "Patient not found.");
        patientAccess[_patientEmail][_user] = false;
    }

    function getDoctor(
        string memory _email
    ) public view returns (Doctor memory) {
        require(doctors[_email].isActive, "Doctor not found.");
        return doctors[_email];
    }

    function getRoom(uint256 _id) public view returns (Room memory) {
        require(rooms[_id].id == _id, "Room not found.");
        return rooms[_id];
    }

    function updatePatient(
        // uint256 _id,
        string memory _name,
        string memory _email,
        string memory _patientaddress,
        string memory _gender,
        string memory _phone,
        string memory _birthDate
    ) public onlyOwner {
        require(patients[_email].isActive, "Patient not found.");
        patients[_email].name = _name;
        patients[_email].email = _email;
        patients[_email].patientaddress = _patientaddress;
        patients[_email].gender = _gender;
        patients[_email].phone = _phone;
        patients[_email].birthDate = _birthDate;
    }

    function updateDoctor(
        // uint _id,
        string memory _name,
        string memory _email,
        string memory _password,
        uint256 _fee,
        string memory _phone,
        string memory _department,
        string memory _speciality,
        uint256 _experience
    ) public {
        require(doctors[_email].isActive, "Doctor not found.");
        doctors[_email].name = _name;
        doctors[_email].email = _email;
        doctors[_email].password = _password;
        doctors[_email].fee = _fee;
        doctors[_email].phone = _phone;
        doctors[_email].department = _department;
        doctors[_email].speciality = _speciality;
        doctors[_email].experience = _experience;
    }

    function deletePatient(string memory _email) public onlyOwner {
        require(patients[_email].isActive, "Patient not found.");
        patients[_email].isActive = false;
        if (patients[_email].roomId != 0) {
            rooms[patients[_email].roomId].isOccupied = false;
        }
    }

    function deleteDoctor(string memory _email) public onlyOwner {
        require(doctors[_email].isActive, "Doctor not found.");
        doctors[_email].isActive = false;
    }
}