// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;

contract HealthCare {
    // Define a struct to represent a patient's medical record.
    struct Record {
        string cid;
        string fileName;
        address patientId;
        address doctorId;
        uint256 timeAdded;
    }

    // Define a struct to represent a patient.
    struct Patient {
        address id;
        string name;
        Record[] records;
    }

    // Define a struct to represent a doctor.
    struct Doctor {
        address id;
    }

    // Define mappings to keep track of patients and doctors in the system.
    mapping(address => Patient) public patients;
    mapping(address => Doctor) public doctors;

    // Define events that can be emitted to signify when a new patient, doctor or record is added.
    event PatientAdded(address patientId);
    event DoctorAdded(address doctorId);
    event RecordAdded(string cid, address patientId, address doctorId);

    // Define modifiers to check for sender existence, patient existence and doctor status.
    modifier senderExists() {
        require(
            doctors[msg.sender].id == msg.sender ||
                patients[msg.sender].id == msg.sender,
            "Sender does not exist"
        );
        _;
    }

    modifier patientExists(address patientId) {
        require(patients[patientId].id == patientId, "Patient does not exist");
        _;
    }

    modifier onlyDoctor() {
        require(doctors[msg.sender].id == msg.sender, "Sender is not a doctor");
        _;
    }

    // Define functions to add a new patient, doctor or record, get all patient records, get the role of the sender, and check if a patient exists.
    function addPatient(address _patientId) public onlyDoctor {
        // Check that the patient doesn't already exist.
        require(
            patients[_patientId].id != _patientId,
            "This patient already exists."
        );
        // Set the id of the patient to the provided address.
        patients[_patientId].id = _patientId;
        // Emit an event to signify that a new patient has been added.
        emit PatientAdded(_patientId);
    }

    function addDoctor() public {
        // Check that the doctor doesn't already exist.
        require(
            doctors[msg.sender].id != msg.sender,
            "This doctor already exists."
        );
        // Set the id of the doctor to the message sender's address.
        doctors[msg.sender].id = msg.sender;
        // Emit an event to signify that a new doctor has been added.
        emit DoctorAdded(msg.sender);
    }

    function addRecord(
        string memory _cid,
        string memory _fileName,
        address _patientId
    ) public onlyDoctor patientExists(_patientId) {
        // Create a new record object and fill it with the details about the provided record.
        Record memory record = Record(
            _cid,
            _fileName,
            _patientId,
            msg.sender,
            block.timestamp
        );
        // Add the newly created record object to the records array of the targeted patient.
        patients[_patientId].records.push(record);
        // Emit an event to signify that a new record has been added.
        emit RecordAdded(_cid, _patientId, msg.sender);
    }

    function getRecords(
        address _patientId
    )
        public
        view
        senderExists
        patientExists(_patientId)
        returns (Record[] memory)
    {
        // Return all medical records for the targeted patient.
        return patients[_patientId].records;
    }

    function getSenderRole() public view returns (string memory) {
        // Determine the role of the message sender and return it as a string.
        if (doctors[msg.sender].id == msg.sender) {
            return "doctor";
        } else if (patients[msg.sender].id == msg.sender) {
            return "patient";
        } else {
            return "unknown";
        }
    }

    function getPatientExists(
        address _patientId
    ) public view onlyDoctor returns (bool) {
        // Check whether a patient with the provided address exists in the system.
        return patients[_patientId].id == _patientId;
    }
}