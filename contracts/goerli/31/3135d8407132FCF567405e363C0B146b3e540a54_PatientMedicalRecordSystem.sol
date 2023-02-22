// SPDX-License-Identifier: GPL-3.0-only	

pragma solidity ^0.8.7;

/// @title Smart Contract for medicare, a decentralized patient medical records
/// @author Onkar Giram @ Feb 2023

//imports
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DoctorType} from "./DoctorType.sol";
import {HospitalType} from "./HospitalType.sol";
import {PatientType} from "./PatientType.sol";

//errors
error PatientMedicalRecords__NotOwner();
error PatientMedicalRecords__NotDoctor();
error PatientMedicalRecords__NotApproved();
error PatientMedicalRecords__NotPatient();

contract PatientMedicalRecordSystem is ReentrancyGuard {
    //Type Declaration

    //Storage Variables
    mapping(address => PatientType.Patient) private s_patients;
    mapping(address => DoctorType.Doctor) private s_doctors;
    mapping(address => HospitalType.Hospital) private s_hospitals;
    mapping(address => string) private s_addressToPublicKey;

    address private immutable i_owner;

    //Events
    event AddedPatient(
        address indexed patientAddress,
        string name,
        string[] chronicHash,
        uint256 indexed dob,
        string bloodGroup,
        uint256 indexed dateOfRegistration,
        string publicKey,
        string[] vaccinationHash,
        string phoneNumber,
        string[] accidentHash,
        string[] acuteHash
    ); //added or modified

    event AddedPublicKey(address indexed patientAddress, string publicKey); //emitting when public key is added.

    event AddedDoctor(
        address indexed doctorAddress,
        string name,
        string doctorRegistrationId,
        uint256 indexed dateOfRegistration,
        string specialization,
        address indexed hospitalAddress
    ); //added or modified to the mapping
    event AddedHospital(
        address indexed hospitalAddress,
        string name,
        string hospitalRegistrationId,
        uint256 indexed dateOfRegistration,
        string email,
        string phoneNumber
    ); //added(mostly) or modified

    //modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert PatientMedicalRecords__NotOwner();
        }
        _;
    }

    modifier onlyDoctor(address senderAddress) {
        if (s_doctors[senderAddress].doctorAddress != senderAddress) {
            revert PatientMedicalRecords__NotDoctor();
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    //Functions
    //patients can themselves register to the system.
    function registerPatient(
        address _patientAddress,
        string memory _name,
        uint256 _dob,
        string memory _phoneNumber,
        string memory _bloodGroup,
        string memory _publicKey
    ) external nonReentrant {
        if (msg.sender != _patientAddress) {
            revert PatientMedicalRecords__NotPatient();
        }
        PatientType.Patient memory patient;
        patient.name = _name;
        patient.patientAddress = _patientAddress;
        patient.dob = _dob;
        patient.phoneNumber = _phoneNumber;
        patient.bloodGroup = _bloodGroup;
        patient.dateOfRegistration = block.timestamp;
        patient.publicKey = _publicKey; //public key is stored here.

        patient.vaccinationHash = new string[](0); //0
        patient.accidentHash = new string[](0); // 1
        patient.chronicHash = new string[](0); //2
        patient.acuteHash = new string[](0); //3

        s_patients[_patientAddress] = patient;
        s_addressToPublicKey[_patientAddress] = _publicKey;

        //emiting the events
        emit AddedPublicKey(_patientAddress, _publicKey);
        emit AddedPatient(
            _patientAddress,
            patient.name,
            patient.chronicHash,
            patient.dob,
            patient.bloodGroup,
            patient.dateOfRegistration,
            patient.publicKey,
            patient.vaccinationHash,
            patient.phoneNumber,
            patient.accidentHash,
            patient.acuteHash
        );
    }

    function addPatientDetails(
        address _patientAddress,
        uint16 _category,
        string memory _IpfsHash //This is the IPFS hash of the diagnostic report which contains an IPFS file hash (preferably PDF file)
    ) external onlyDoctor(msg.sender) nonReentrant {
        if (_category == 0) {
            s_patients[_patientAddress].vaccinationHash.push(_IpfsHash);
        } else if (_category == 1) {
            s_patients[_patientAddress].accidentHash.push(_IpfsHash);
        } else if (_category == 2) {
            s_patients[_patientAddress].chronicHash.push(_IpfsHash);
        } else if (_category == 3) {
            s_patients[_patientAddress].acuteHash.push(_IpfsHash);
        }
        PatientType.Patient memory patient = s_patients[_patientAddress];
        //emitting the event.
        emit AddedPatient(
            _patientAddress,
            patient.name,
            patient.chronicHash,
            patient.dob,
            patient.bloodGroup,
            patient.dateOfRegistration,
            patient.publicKey,
            patient.vaccinationHash,
            patient.phoneNumber,
            patient.accidentHash,
            patient.acuteHash
        );
    }

    //this will be done using script by the owner
    function addDoctorDetails(
        address _doctorAddress,
        string memory _name,
        string memory _doctorRegistrationId,
        uint256 _dateOfRegistration,
        string memory _specialization,
        address _hospitalAddress
    ) external onlyOwner nonReentrant {
        DoctorType.Doctor memory doctor;
        doctor.name = _name;
        doctor.doctorRegistrationId = _doctorRegistrationId;
        doctor.doctorAddress = _doctorAddress;
        doctor.dateOfRegistration = _dateOfRegistration;
        doctor.specialization = _specialization;
        doctor.hospitalAddress = _hospitalAddress;
        s_doctors[_doctorAddress] = doctor;
        //emitting the event.
        emit AddedDoctor(
            _doctorAddress,
            doctor.name,
            doctor.doctorRegistrationId,
            doctor.dateOfRegistration,
            doctor.specialization,
            doctor.hospitalAddress
        );
    }

    //this will be done using script by the owner
    function addHospitalDetails(
        address _hospitalAddress,
        string memory _name,
        string memory _hospitalRegistrationId,
        string memory _email,
        string memory _phoneNumber
    ) external onlyOwner nonReentrant {
        HospitalType.Hospital memory hospital = s_hospitals[_hospitalAddress];
        hospital.hospitalAddress = _hospitalAddress;
        hospital.name = _name;
        hospital.email = _email;
        hospital.phoneNumber = _phoneNumber;
        hospital.hospitalRegistrationId = _hospitalRegistrationId;
        hospital.dateOfRegistration = block.timestamp;
        s_hospitals[_hospitalAddress] = hospital;
        //emitting the event.
        emit AddedHospital(
            hospital.hospitalAddress,
            hospital.name,
            hospital.hospitalRegistrationId,
            hospital.dateOfRegistration,
            hospital.email,
            hospital.phoneNumber
        );
    }

    function getMyDetails() external view returns (PatientType.Patient memory) {
        return s_patients[msg.sender];
    }

    //authorized doctor viewing patient's records
    function getPatientDetails(address _patientAddress)
        external
        view
        returns (
            string memory,
            string memory,
            uint256
        )
    {
        return (
            s_patients[_patientAddress].name,
            s_patients[_patientAddress].publicKey,
            s_patients[_patientAddress].dateOfRegistration
        );
    }

    function getPublicKey(address _patientAddress) public view returns (string memory) {
        return s_addressToPublicKey[_patientAddress];
    }

    function getDoctorDetails(address _doctorAddress)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            address
        )
    {
        return (
            s_doctors[_doctorAddress].name,
            s_doctors[_doctorAddress].specialization,
            s_doctors[_doctorAddress].doctorRegistrationId,
            s_doctors[_doctorAddress].hospitalAddress
        );
    }

    function getHospitalDetails(address _hospitalAddress)
        external
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        return (
            s_hospitals[_hospitalAddress].name,
            s_hospitals[_hospitalAddress].hospitalRegistrationId,
            s_hospitals[_hospitalAddress].email
        );
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-only	

pragma solidity ^0.8.7;

library DoctorType {
    //Type Declaration
    struct Doctor {
        address doctorAddress; //account address of doctor
        string name;
        string doctorRegistrationId; //NMC Regsitration Id
        uint256 dateOfRegistration;
        string specialization;
        address hospitalAddress;
    }
}

// SPDX-License-Identifier: GPL-3.0-only	

pragma solidity ^0.8.7;

library HospitalType{
    //Type Declaration

    struct Hospital{
        string name;
        address hospitalAddress; //account address of hospital
        uint256 dateOfRegistration;
        string hospitalRegistrationId;
        string email;
        string phoneNumber;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.7;


library PatientType {
    //Type Declaration
    struct Patient {
        string name;        //   
        address patientAddress; //account address of patient     
        uint256 dob;      //
        string phoneNumber;
        string bloodGroup;     //
        string publicKey;      //for storing public key for encrypting the data
        uint256 dateOfRegistration; //the date of registration of patient to the system. Tells which records are not in the system.
        //Medical Records
        string[] vaccinationHash; //0
        string[] accidentHash; // 1
        string[] chronicHash; //2
        string[] acuteHash; //3
    }
}