// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract HealthReport {
    struct Patient {
        string ic;
        address addr;
        string name;
        string phone;
        string gender;
        string dob;
        // string image;
        string height;
        string weight;
        string houseaddr;
        string bloodgroup;
        string allergies;
        string medication;
        string emergencyName;
        string emergencyContact;
        uint date;
    }
    struct Doctor{
        string ic;
        string name;
        string phone;
        // string image;
        string gender;
        string dob;
        string qualification;
        string major;
        address addr;
        uint date;
    }
    struct Appointments{
        address doctoraddr;
        address patientaddr;
        string date;
        string time;
        string prescription;
        string description;
        string diagnosis;
        string status;
        uint creationDate;
    }

    address public owner;
    address[] public patientList;
    address[] public doctorList;
    address[] public appointmentList;

    mapping(address => Patient) patients;
    mapping(address => Doctor) doctors;
    mapping(address => Appointments) appointments;

    mapping(address=>mapping(address=>bool)) isApproved;
    mapping(address => bool) isPatient;
    mapping(address => bool) isDoctor;
    mapping(address => uint) AppointmentPerPatient;

    uint256 public patientCount = 0;
    uint256 public doctorCount = 0;
    uint256 public appointmentCount = 0;
    uint256 public permissionGrantedCount = 0;
    
    // function Record() public {
    //     owner = msg.sender;
    // }


    function createPatient(Patient memory pat ) public returns (uint256) {
        Patient storage p = patients[msg.sender];

        require(!isPatient[msg.sender], "Patient Already exists");

        p.ic = pat.ic;
        p.name = pat.name;
        p.phone = pat.phone;
        p.gender = pat.gender;
        p.dob = pat.dob;
        p.height = pat.height; 
        p.weight = pat.weight;
        p.houseaddr = pat.houseaddr;
        p.bloodgroup = pat.bloodgroup;
        p.allergies = pat.allergies;
        p.medication = pat.medication;
        p.emergencyName = pat.emergencyName;
        p.emergencyContact = pat.emergencyContact;
        p.addr = msg.sender;
        p.date = block.timestamp;

        patientList.push(msg.sender);
        isPatient[msg.sender] = true;
        isApproved[msg.sender][msg.sender] = true;
        patientCount++;

        return patientCount - 1;
    }

    function editPatient(Patient memory pat) public {
        require(isPatient[msg.sender]);
        Patient storage p = patients[msg.sender];
        //var p = patients[msg.sender];
        
        p.ic = pat.ic;
        p.name = pat.name;
        p.phone = pat.phone;
        p.gender = pat.gender;
        p.dob = pat.dob;
        p.height = pat.height; 
        p.weight = pat.weight;
        p.houseaddr = pat.houseaddr;
        p.bloodgroup = pat.bloodgroup;
        p.allergies = pat.allergies;
        p.medication = pat.medication;
        p.emergencyName = pat.emergencyName;
        p.emergencyContact = pat.emergencyContact;
        p.addr = msg.sender;    
    }

    function setDoctor(string memory _ic, string memory _name, string memory _phone, string memory _gender, string memory _dob, string memory _qualification, string memory  _major) public returns (uint256) {
        require(!isDoctor[msg.sender]);
        Doctor storage d = doctors[msg.sender];
        //var d = doctors[msg.sender];
        
        d.ic = _ic;
        d.name = _name;
        d.phone = _phone;
        d.gender = _gender;
        d.dob = _dob;
        d.qualification = _qualification;
        d.major = _major;
        d.addr = msg.sender;
        d.date = block.timestamp;
        
        doctorList.push(msg.sender);
        isDoctor[msg.sender] = true;
        doctorCount++;
        return doctorCount - 1;
    }

    function editDoctor(string memory _ic, string memory _name, string memory _phone, string memory _gender, string memory _dob, string memory _qualification, string memory  _major) public {
        require(isDoctor[msg.sender]);
        Doctor storage d = doctors[msg.sender];
        //var d = doctors[msg.sender];
        
        d.ic = _ic;
        d.name = _name;
        d.phone = _phone;
        d.gender = _gender;
        d.dob = _dob;
        d.qualification = _qualification;
        d.major = _major;
        d.addr = msg.sender;
    }

    function setAppointment(address _addr, string memory _date, string memory _time, string memory _diagnosis, string memory _prescription, string memory _description, string memory _status) public {
        require(isDoctor[msg.sender]);
        Appointments storage a = appointments[_addr];
        
        a.doctoraddr = msg.sender;
        a.patientaddr = _addr;
        a.date = _date;
        a.time = _time;
        a.diagnosis = _diagnosis;
        a.prescription = _prescription; 
        a.description = _description;
        a.status = _status;
        a.creationDate = block.timestamp;

        appointmentList.push(_addr);
        appointmentCount++;
        AppointmentPerPatient[_addr]++;
    }

    function updateAppointment(address _addr, string memory _date, string memory _time, string memory _diagnosis, string memory _prescription, string memory _description, string memory _status) public {
        require(isDoctor[msg.sender]);
        Appointments storage a = appointments[_addr];
        //var a = appointments[_addr];
        
        a.doctoraddr = msg.sender;
        a.patientaddr = _addr;
        a.date = _date;
        a.time = _time;
        a.diagnosis = _diagnosis;
        a.prescription = _prescription; 
        a.description = _description;
        a.status = _status;
    }

    function givePermission(address _address) public returns(bool success) {
        isApproved[msg.sender][_address] = true;
        permissionGrantedCount++;
        return true;
    }

    function RevokePermission(address _address) public returns(bool success) {
        isApproved[msg.sender][_address] = false;
        return true;
    }

    function getPatients() public view returns(address[] memory) {
        return patientList;
    }

    function getDoctors() public view returns(address[] memory) {
        return doctorList;
    }

    function getAppointments() public view returns(address[] memory) {
        return appointmentList;
    }

    function searchPatientDemographic(address _address) public view returns(string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
        require(isApproved[_address][msg.sender]);
        
        Patient storage p = patients[_address];
        
        return (p.ic, p.name, p.phone, p.gender, p.dob, p.height, p.weight);
    }

    function searchPatientMedical(address _address) public view returns(string memory, string memory, string memory, string memory, string memory, string memory) {
        require(isApproved[_address][msg.sender]);
        
        Patient storage p = patients[_address];
        
        return (p.houseaddr, p.bloodgroup, p.allergies, p.medication, p.emergencyName, p.emergencyContact);
    }

    function searchDoctor(address _address) public view returns(string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
        // require(isDoctor[_address]);
        Doctor storage d = doctors[_address];
        
        return (d.ic, d.name, d.phone, d.gender, d.dob, d.qualification, d.major);
    }

    function searchAppointment(address _address) public view returns(address, string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
        Appointments storage a = appointments[_address];
        Doctor storage d = doctors[a.doctoraddr];

        return (a.doctoraddr, d.name, a.date, a.time, a.diagnosis, a.prescription, a.description, a.status);
    }

    function searchRecordDate(address _address) public view returns(uint) {
        Patient storage p = patients[_address];
        
        return (p.date);
    }

    function searchDoctorDate(address _address) public view returns(uint) {
        Doctor storage d = doctors[_address];
        
        return (d.date);
    }

    function searchAppointmentDate(address _address) public view returns(uint) {
        Appointments storage a = appointments[_address];
        
        return (a.creationDate);
    }

    function getPatientCount() public view returns(uint256) {
        return patientCount;
    }

    function getDoctorCount() public view returns(uint256) {
        return doctorCount;
    }

    function getAppointmentCount() public view returns(uint256) {
        return appointmentCount;
    }

    function getPermissionGrantedCount() public view returns(uint256) {
        return permissionGrantedCount;
    }

    function getAppointmentPerPatient(address _address) public view returns(uint256) {
        return AppointmentPerPatient[_address];
    }


}