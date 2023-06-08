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
        string ailment;
        uint256 roomId;
        bool isActive;
    }

    struct AdmitPatient {
        uint256 id;
        string Doctor;
        string roomNo;
        string roomCost;
        string mealsCostPerDay;
        string insuranceCareer;
        string admitDate;
        string admitReason;
        bool isAdmit;
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
        bool isActive;
    }
    string public contractName = "Hospital Management System";
    address public owner;
    uint256 private patientCounter;
    uint256 private doctorCounter;
    uint256 private roomCounter;
    uint256 private admitPatientCounter;

    mapping(string => Patient) private patients;
    mapping(string => Doctor) private doctors;
    mapping(string => Room) private rooms;
    mapping(string => AdmitPatient) private admitPatients;

    Patient[] public getAllPatientList;
    Doctor[] public getAllDoctorList;
    Room[] public getAllRoomList;
    AdmitPatient[] public getAllAdmitPatientList;

    mapping(string => mapping(address => bool)) private patientAccess;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        patientCounter = 0;
        doctorCounter = 0;
        roomCounter = 0;
        admitPatientCounter = 0;
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
        string memory _ailment
    ) public onlyOwner {
        require(!patients[_email].isActive, "Patient Already Exist");
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
            _ailment,
            0,
            true
        );
        getAllPatientList.push(patients[_email]);
        patientCounter++;
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
        require(!doctors[_email].isActive, "Doctor already exist.");

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
        getAllDoctorList.push(doctors[_email]);
        doctorCounter++;
    }

    function admitPatient(
        string memory _email,
        string memory _doctor,
        string memory _roomNo,
        string memory _roomCost,
        string memory _mealsCostPerDay,
        string memory _insuranceCareer,
        string memory _admitDate,
        string memory _admitReason
    ) public onlyOwner {
        require(patients[_email].isActive, "Patient did not Exist");
        require(doctors[_doctor].isActive, "Doctor did not Exist");
        require(!admitPatients[_email].isAdmit, "Patient already admited");
        require(rooms[_roomNo].isActive, "Room did not exist");
        require(rooms[_roomNo].noOfBeds > 0, "Sorry, Room already full");
        admitPatients[_email] = AdmitPatient(
            admitPatientCounter,
            _doctor,
            _roomNo,
            _roomCost,
            _mealsCostPerDay,
            _insuranceCareer,
            _admitDate,
            _admitReason,
            true
        );
        rooms[_roomNo].noOfBeds -= 1;
        getAllAdmitPatientList.push(admitPatients[_email]);
        admitPatientCounter++;
    }

    function DischargePatient(string memory _email) public onlyOwner {
        require(admitPatients[_email].isAdmit, "Please admit Patient first");
        admitPatients[_email].isAdmit = false;
        rooms[admitPatients[_email].roomNo].noOfBeds += 1;
        getAllAdmitPatientList[admitPatients[_email].id] = (
            admitPatients[_email]
        );
    }

    function addRoom(
        string memory _roomType,
        string memory roomNo,
        uint256 costPerDay,
        uint256 noOfBeds,
        uint mealCostPerDay
    ) public onlyOwner {
        require(!rooms[roomNo].isActive, "Room already exist");
        rooms[roomNo] = Room(
            roomCounter,
            _roomType,
            roomNo,
            costPerDay,
            noOfBeds,
            mealCostPerDay,
            false,
            true
        );
        getAllRoomList.push(rooms[roomNo]);
        roomCounter++;
    }

    function getPatientList() public view returns (Patient[] memory) {
        return getAllPatientList;
    }

    function getDoctorList() public view returns (Doctor[] memory) {
        return getAllDoctorList;
    }

    function getRoomList() public view returns (Room[] memory) {
        return getAllRoomList;
    }

    function getAdmitList() public view returns (AdmitPatient[] memory) {
        return getAllAdmitPatientList;
    }

    function updatePatient(
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
        patients[_email].sex = _gender;
        patients[_email].phone = _phone;
        patients[_email].birthDate = _birthDate;
        getAllPatientList[patients[_email].id] = (patients[_email]);
    }

    function updateDoctor(
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
        getAllDoctorList[doctors[_email].id] = (doctors[_email]);
    }

    function updateRoom(
        string memory _roomNo,
        uint256 _costPerDay,
        uint256 _numberOfBeds,
        uint _mealsCostPerDay
    ) public onlyOwner {
        require(rooms[_roomNo].isActive, "Room did not exist");
        rooms[_roomNo].costPerDay = _costPerDay;
        rooms[_roomNo].noOfBeds = _numberOfBeds;
        rooms[_roomNo].mealCostPerDay = _mealsCostPerDay;
        getAllRoomList[rooms[_roomNo].id] = rooms[_roomNo];
    }
}