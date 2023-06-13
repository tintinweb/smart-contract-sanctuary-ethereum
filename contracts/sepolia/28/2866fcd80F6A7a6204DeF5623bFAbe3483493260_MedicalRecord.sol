/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract MedicalRecord {
    address owner;
    address docAdd;
    address patientAdd;
    uint256 CountforPatient;
    uint256 CountForDoctor;

    struct Doctor {
        address docAdd;
        uint256 id;
        string name;
        string qualification;
        string workPlace;
    }

    struct Patient {
        address patientAdd;
        uint256 id;
        string name;
        uint256 age;
        string disease;
        string diagnoseDate;
        uint256 medId;
        bool isReg;
    }

    struct Ids {
        uint256 id;
        address patientAdd;
    }

    struct Medicine {
        uint256 id;
        string name;
        string expirydate;
        string dose;
        uint256 price;
    }

    mapping(uint256 => Doctor) doctors;
    mapping(address => Ids) patients;
    mapping(uint256 => Patient) patientIds;
    mapping(uint256 => Medicine) medicines;

    event DoctorRegistered(uint256 indexed _docId);
    event PatientRegistered(address patientAddr, uint256 indexed _patientId);
    event newDisease(address patientAddr);
    event PrescribedMedicine(address docAdd, address patient, uint256 _medId);
    event RecordUpdated(address patient);

    event addMedicine(uint256 indexed _medId, uint256 _price);

    constructor() {
        owner = msg.sender;
    }

    function registerDoctor(
        string memory _name,
        string memory _qualification,
        string memory _workPlace
    ) public {
        CountForDoctor++;
        docAdd = msg.sender;
        doctors[CountForDoctor] = Doctor(
            docAdd,
            CountForDoctor,
            _name,
            _qualification,
            _workPlace
        );

        emit DoctorRegistered(CountForDoctor);
        // event DoctorRegistered(CountForDoctor);
    }

    function registerPatient(string memory _name, uint256 _age) public {
        require(
            patientIds[patients[patientAdd].id].isReg == false,
            " Patient Already Registered"
        );
        CountforPatient++;
        patientAdd = msg.sender;
        patients[patientAdd].patientAdd = patientAdd;
        patients[patientAdd].id = CountforPatient;
        //patients[patientAdd].id = CountforPatient;
        // patients[patientAdd].name = _name;
        // patients[patientAdd].age = _age;
        patientIds[CountforPatient].patientAdd = patientAdd;
        patientIds[CountforPatient].id = CountforPatient;
        patientIds[CountforPatient].patientAdd = patientAdd;
        patientIds[CountforPatient].name = _name;
        patientIds[CountforPatient].age = _age;
        patientIds[patients[patientAdd].id].isReg = true;
        emit PatientRegistered(patientAdd, CountforPatient);
    }

    //RegisterPatientdisease
    function addNewDisease(string memory _disease, string memory _diagnoseDate)
        public
    {
        patientAdd = msg.sender;
        //patients[patientAdd].disease = _disease;
        patientIds[patients[patientAdd].id].diagnoseDate = _diagnoseDate;
        patientIds[patients[patientAdd].id].disease = _disease;
        emit newDisease(patientAdd);
    }

    //addMedicine
    function addmedicine(
        uint256 _medId,
        string memory _nameofMed,
        string memory _ExpiryDate,
        string memory _dose,
        uint56 _price
    ) public {
        medicines[_medId].id = _medId;
        medicines[_medId].name = _nameofMed;
        medicines[_medId].expirydate = _ExpiryDate;
        medicines[_medId].dose = _dose;
        medicines[_medId].price = _price;
        emit addMedicine(_medId, _price);
    }

    //Prescribe Medicne
    function PrescribeMedTopateint(uint256 _medId, address _patient)
        public
        onlyDoc
    {
        require(patients[_patient].id != 0, "Not a Patient");
        patientIds[patients[_patient].id].medId = _medId;
        emit PrescribedMedicine(
            msg.sender,
            patientIds[patients[_patient].id].patientAdd,
            _medId
        );
    }

    //UpdatePetient Details By Patient
    function UpdateRecord(uint256 _age) public {
        require(patients[msg.sender].id != 0, "Not a Patient");
        patientIds[patients[msg.sender].id].age = _age;
        emit RecordUpdated(msg.sender);
    }

    // View Patient Data
    function ViewPatient()
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory
        )
    {
        Patient memory patient = patientIds[patients[msg.sender].id];
        // Pateint memory patient_id = patientIds[patient.id];
        return (patient.id, patient.age, patient.name, patient.disease);
    }

    function viewPatientByDoctor(uint256 _patientId)
        public
        view
        onlyDoc
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            address
        )
    {
        // require( patients[patientAdd].id == _patientId);

        Patient memory patient = patientIds[_patientId];
        return (
            patient.id,
            patient.age,
            patient.name,
            patient.disease,
            patient.patientAdd
        );
    }

    //View doc Details

    function viewDoctorById(uint256 _id)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            string memory
        )
    {
        Doctor memory doctor = doctors[_id];
        return (doctor.id, doctor.name, doctor.qualification, doctor.workPlace);
    }

    // View Medicine
    function viewMedicine(uint256 _medId)
        public
        view
        onlyDoc
        returns (
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        Medicine memory medicine = medicines[_medId];
        return (
            medicine.id,
            medicine.expirydate,
            medicine.dose,
            medicine.price
        );
    }

    // View PrescribedMedicine
    function viewPrescribedMedicine(address _patientAddr)
        public
        view
        onlyDoc
        returns (uint256)
    {
        return patientIds[patients[_patientAddr].id].medId;
    }

    //Modifiers
    modifier onlyDoc() {
        require(
            doctors[CountForDoctor].id != 0,
            "Only Doctor can call the function"
        );
        _;
    }
}