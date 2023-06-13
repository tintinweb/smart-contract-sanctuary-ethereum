// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

///////////////////////////////////
///////////// ERRORS /////////////
//////////////////////////////////
error HealthChain__youAlreadyHaveAnAccount();
error HealthChain__MedicalRecordNotFound();
error HealthChain__notYourData();
error HealthChain__cantAccessData();
error HealthChain__requestNotFound();
error HealthChain__requestNotApprovedYet();

/**
 * @title HealthChain
 * @author Alberto Toscano
 * @notice HealthChain is a decentralized health records management system.
 * It allows doctors to create and update medical records for their patients,
 * while ensuring patient privacy and control over their data.
 * Patients can grant access to their medical records to specific doctors by approving requests.
 */
contract HealthChain {
    //////////////////////////////////
    //////////// ENUM DATA ///////////
    //////////////////////////////////

    enum RequestStatus {
        Pending,
        Approved,
        Rejected,
        Closed
    }

    //////////////////////////////////
    ///////// STRUCTURE DATA /////////
    //////////////////////////////////

    struct Doctor {
        address id;
        string name;
        string surname;
        string dateOfBirth;
        string email;
        string telephone;
        string zipCode;
        string city;
        string country;
    }

    struct Patient {
        address id;
        address doctorId;
        string name;
        string surname;
        string dateOfBirth;
        string email;
        string telephone;
        string telephone2;
        // string doctorTelephone;
        string zipCode;
        string city;
        string country;
    }

    struct MedicalRecord {
        uint256 id;
        uint256 timeAdded;
        address patientId;
        address doctorId;
        string fileName;
        string hospital;
        string details;
    }

    struct Request {
        uint256 requestId;
        address patientId;
        address doctorId;
        uint timestamp;
        RequestStatus status;
    }

    ///////////////////////////////////
    ////////// MAPPINGS DATA //////////
    ///////////////////////////////////

    mapping(address => Patient) private s_patients;
    mapping(address => Doctor) private s_doctors;
    mapping(address => MedicalRecord[]) private s_medicalRecords;
    mapping(address => Request[]) private s_requests;

    ///////////////////////////////////
    ///////////// EVENTS //////////////
    ///////////////////////////////////

    event doctorCreated(address id, string name, string surname);
    event patientCreated(address id, string name, string surname);
    event doctorUpdated(address id, string name, string surname);
    event patientUpdated(address id, string name, string surname);
    event requestCreated(
        uint256 requestId,
        address patientId,
        address doctorId
    );
    event requestApproved(uint256 requestId, address patientId);
    event requestRejected(uint256 requestId, address patientId);
    event medicalRecordCreated(
        uint256 medicalRecordId,
        address patientId,
        address doctorId
    );
    event medicalRecordUpdated(
        uint256 medicalRecordId,
        address patientId,
        address doctorId
    );

    ///////////////////////////////////
    //////////// MODIFIER /////////////
    ///////////////////////////////////

    modifier onlyDoctor() {
        require(s_doctors[msg.sender].id == msg.sender);
        _;
    }
    modifier doctorExists(address doctorId) {
        require(s_doctors[doctorId].id == doctorId);
        _;
    }
    modifier onlyPatient() {
        require(s_patients[msg.sender].id == msg.sender);
        _;
    }
    modifier patientExists(address patientId) {
        require(s_patients[patientId].id == patientId);
        _;
    }

    ///////////////////////////////////
    ///////// MAIN FUNCTIONS //////////
    ///////////////////////////////////

    function createDoctor(
        string memory name,
        string memory surname,
        string memory dateOfBirth,
        string memory email,
        string memory telephone,
        string memory zipCode,
        string memory city,
        string memory country
    ) public {
        if (
            s_doctors[msg.sender].id == msg.sender ||
            s_patients[msg.sender].id == msg.sender
        ) {
            revert HealthChain__youAlreadyHaveAnAccount();
        }
        s_doctors[msg.sender] = Doctor(
            msg.sender,
            name,
            surname,
            dateOfBirth,
            email,
            telephone,
            zipCode,
            city,
            country
        );
        emit doctorCreated(msg.sender, name, surname);
    }

    function createPatient(
        address doctorId,
        string memory name,
        string memory surname,
        string memory dateOfBirth,
        string memory email,
        string memory telephone,
        string memory telephone2,
        string memory zipCode,
        string memory city,
        string memory country
    ) public {
        if (
            s_patients[msg.sender].id == msg.sender ||
            s_doctors[msg.sender].id == msg.sender
        ) {
            revert HealthChain__youAlreadyHaveAnAccount();
        }
        s_patients[msg.sender] = Patient(
            msg.sender,
            doctorId,
            name,
            surname,
            dateOfBirth,
            email,
            telephone,
            telephone2,
            zipCode,
            city,
            country
        );

        emit patientCreated(msg.sender, name, surname);
    }

    function updateDoctor(
        address doctorId,
        string memory name,
        string memory surname,
        string memory dateOfBirth,
        string memory email,
        string memory telephone,
        string memory zipCode,
        string memory city,
        string memory country
    ) public onlyDoctor doctorExists(doctorId) {
        Doctor storage doctor = s_doctors[msg.sender];
        if (doctor.id != doctorId) {
            revert HealthChain__notYourData();
        }
        doctor.name = name;
        doctor.surname = surname;
        doctor.dateOfBirth = dateOfBirth;
        doctor.email = email;
        doctor.telephone = telephone;
        doctor.zipCode = zipCode;
        doctor.city = city;
        doctor.country = country;

        emit doctorUpdated(doctorId, name, surname);
    }

    function updatePatient(
        address patientId,
        address doctorId,
        string memory name,
        string memory surname,
        string memory dateOfBirth,
        string memory email,
        string memory telephone,
        string memory telephone2,
        string memory zipCode,
        string memory city,
        string memory country
    ) public patientExists(patientId) {
        Patient storage patient = s_patients[msg.sender];
        if (patient.id != patientId) {
            revert HealthChain__notYourData();
        }
        patient.doctorId = doctorId;
        patient.name = name;
        patient.surname = surname;
        patient.dateOfBirth = dateOfBirth;
        patient.email = email;
        patient.telephone = telephone;
        patient.telephone2 = telephone2;
        patient.zipCode = zipCode;
        patient.city = city;
        patient.country = country;

        emit patientUpdated(patientId, name, surname);
    }

    function createRequest(
        address patientAddress
    ) external onlyDoctor patientExists(patientAddress) {
        uint256 requestId = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        s_requests[patientAddress].push(
            Request(
                requestId,
                patientAddress,
                msg.sender,
                block.timestamp,
                RequestStatus.Pending
            )
        );
        emit requestCreated(requestId, patientAddress, msg.sender);
    }

    function respondToRequest(
        uint256 requestId,
        bool approved
    ) public onlyPatient {
        Request[] storage requests = s_requests[msg.sender];

        bool foundRequest = false;
        for (uint256 i = 0; i < requests.length; i++) {
            if (
                requests[i].requestId == requestId &&
                requests[i].patientId == msg.sender &&
                requests[i].status == RequestStatus.Pending
            ) {
                foundRequest = true;
                if (approved == true) {
                    requests[i].status = RequestStatus.Approved;
                    emit requestApproved(requestId, msg.sender);
                } else {
                    requests[i].status = RequestStatus.Rejected;
                    emit requestRejected(requestId, msg.sender);
                }
                break;
            }
        }
        if (!foundRequest) {
            revert HealthChain__requestNotFound();
        }
    }

    function createMedicalRecord(
        uint256 requestId,
        address patientId,
        string memory fileName,
        string memory hospital,
        string memory details
    ) public onlyDoctor patientExists(patientId) {
        // verifying if the request to access has been accepted by the patient
        Request[] storage requests = s_requests[patientId];
        bool found = false;
        for (uint256 i = 0; i < requests.length; i++) {
            if (
                requests[i].requestId == requestId &&
                requests[i].doctorId == msg.sender &&
                requests[i].status == RequestStatus.Approved
            ) {
                found = true;
                requests[i].status = RequestStatus.Closed;
                uint256 medicalRecordId = uint256(
                    keccak256(abi.encodePacked(block.timestamp, msg.sender))
                );
                s_medicalRecords[patientId].push(
                    MedicalRecord(
                        medicalRecordId,
                        block.timestamp,
                        patientId,
                        msg.sender,
                        fileName,
                        hospital,
                        details
                    )
                );
                emit medicalRecordCreated(
                    medicalRecordId,
                    patientId,
                    msg.sender
                );
                break;
            }
        }
        if (!found) {
            revert HealthChain__requestNotApprovedYet();
        }
    }

    function updateMedicalRecord(
        address patientId,
        uint256 medicalRecordId,
        uint256 requestId,
        string memory fileName,
        string memory hospital,
        string memory details
    ) public onlyDoctor {
        // verifying if the request to access has been accepted by the patient
        Request[] storage requests = s_requests[patientId];
        bool approved = false;
        for (uint256 i = 0; i < requests.length; i++) {
            if (
                requests[i].requestId == requestId &&
                requests[i].doctorId == msg.sender &&
                requests[i].status == RequestStatus.Approved
            ) {
                approved = true;
                requests[i].status = RequestStatus.Closed;
                break;
            }
        }
        if (!approved) {
            revert HealthChain__requestNotApprovedYet();
        }
        // check for the correct medical record by the medical record id
        MedicalRecord[] storage medicalRecords = s_medicalRecords[patientId];
        bool found = false;
        for (uint256 i = 0; i < medicalRecords.length; i++) {
            if (medicalRecords[i].id == medicalRecordId) {
                found = true;
                medicalRecords[i].fileName = fileName;
                medicalRecords[i].hospital = hospital;
                medicalRecords[i].details = details;
                medicalRecords[i].timeAdded = block.timestamp;

                emit medicalRecordUpdated(
                    medicalRecordId,
                    patientId,
                    msg.sender
                );
                break;
            }
        }
        if (!found) {
            revert HealthChain__MedicalRecordNotFound();
        }
    }

    ///////////////////////////////////
    ////////// VIEW FUNCTIONS /////////
    ///////////////////////////////////

    function getDoctorData(
        address doctorId
    ) public view doctorExists(doctorId) returns (Doctor memory) {
        Doctor memory doctor = s_doctors[doctorId];
        return doctor;
    }

    function getPatientData(
        address patientId
    ) public view patientExists(patientId) returns (Patient memory) {
        if (msg.sender == patientId) {
            Patient memory patient = s_patients[patientId];
            return patient;
        }
        revert HealthChain__cantAccessData();
    }

    function getPatientsDoctorNumber(
        address patientId
    ) public view patientExists(patientId) returns (address) {
        address doctorTelephone = s_patients[patientId].doctorId;
        return doctorTelephone;
    }

    function getMedicalRecords(
        address patientId
    ) public view returns (MedicalRecord[] memory) {
        if (msg.sender == patientId) {
            return s_medicalRecords[patientId];
        }
        revert HealthChain__cantAccessData();
    }

    function getMedicalRecordById(
        uint256 medicalRecordId,
        address patientId
    ) public view returns (MedicalRecord memory) {
        MedicalRecord[] memory medicalRecords = s_medicalRecords[patientId];
        if (msg.sender == patientId) {
            for (uint256 i = 0; i < medicalRecords.length; i++) {
                if (medicalRecords[i].id == medicalRecordId) {
                    return medicalRecords[i];
                }
            }
            revert HealthChain__MedicalRecordNotFound();
        }
        revert HealthChain__cantAccessData();
    }

    function getRequests(
        address patientId
    ) public view returns (Request[] memory) {
        if (msg.sender == patientId) {
            return s_requests[patientId];
        }
        revert HealthChain__notYourData();
    }
}