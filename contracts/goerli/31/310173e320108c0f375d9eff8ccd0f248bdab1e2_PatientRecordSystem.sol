// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

error UnauthorizedDoctor();
error AlreadyRegisteredAsPatient();
error AlreadyRegisteredAsDoctor();
error AlreadyRegisteredAsPharmacy();
error UnauthorizedRole();
error NotRegisteredAsPatient();
error NotRegisteredAsDoctor();
error NotRegisteredAsPharmacy();
error OwnerCannotJoinasParticipant();

contract PatientRecordSystem is Ownable {
    enum AccessControls {
        Unauthorized,
        Patient,
        Doctor,
        Pharmacy
    }
    struct PatientRecord {
        bytes32 name;
        uint age;
        bytes32 gender;
        bytes32 bloodGroup;
        address addr;
        uint timestamp;
        address updatedBy;
        address pharmacy;
        string description;
    }
    struct DoctorRecord {
        bytes32 name;
        uint age;
        bytes32 gender;
        bytes32 Qualification;
        bytes32 HospitalName;
        bytes32 location;
        address addr;
    }
    struct PharmacyRecord {
        bytes32 name;
        bytes32 street;
        bytes32 location;
        address addr;
    }
    mapping(address => AccessControls) allowAccess;
    mapping(address => PatientRecord) patientRecordDetails;
    PatientRecord[] patientRecords;
    mapping(address => DoctorRecord) doctorRecordDetails;
    DoctorRecord[] doctorRecords;
    mapping(address => PharmacyRecord) pharmacyRecordDetails;
    PharmacyRecord[] pharmacyRecords;
    // address[] public  pharmacyAddress;

    mapping(address => mapping(address => bool)) public hasAccessToDoctor;
    mapping(address => mapping(address => bool)) public hasAccessToPharmacy;

    event PatientRecordsAdded(address Patient);
    event DoctorRecordsAdded(address Doctor);
    event PharmacyRecordsAdded(address Pharmacy);
    event AccessGrantedToDoctor(address Patient, address Doctor);
    event AccessGrantedToPharmacy(address Patient, address Pharmacy);
    event AccessRevokedFromDoctor(address Patient, address Doctor);
    event AccessRevokedFromPharmacy(address Patient, address Pharmacy);
    event PatientRecordModified(address Patient, address ModifiedBy);
    event RevokeUser(address user, AccessControls);

    modifier isValid(address _addr) {
        if (allowAccess[_addr] == AccessControls.Patient)
            revert AlreadyRegisteredAsPatient();
        if (allowAccess[_addr] == AccessControls.Doctor)
            revert AlreadyRegisteredAsDoctor();
        if (allowAccess[_addr] == AccessControls.Pharmacy)
            revert AlreadyRegisteredAsPharmacy();
        if (owner() == _addr) revert OwnerCannotJoinasParticipant();
        _;
    }

    modifier isOutOfRangeAccessControls(uint8 role) {
        if (role > uint8(AccessControls.Pharmacy)) revert UnauthorizedRole();
        _;
    }
    modifier isPatient(address _addr) {
        if (allowAccess[_addr] != AccessControls.Patient)
            revert NotRegisteredAsPatient();
        _;
    }
    modifier OwnerOrPatient(address _addr) {
        require(
            _addr == owner() || allowAccess[_addr] == AccessControls.Patient,
            "Unauthorized users"
        );
        _;
    }
    modifier OwnerOrPatientOrDoctor(address _addr) {
        require(
            _addr == owner() ||
                allowAccess[_addr] == AccessControls.Patient ||
                allowAccess[msg.sender] == AccessControls.Doctor,
            "Unauthorized users"
        );
        _;
    }
    modifier isDoctor(address _addr) {
        if (allowAccess[_addr] != AccessControls.Doctor)
            revert NotRegisteredAsDoctor();
        _;
    }
    modifier isPharmacy(address _addr) {
        if (allowAccess[_addr] != AccessControls.Pharmacy)
            revert NotRegisteredAsPharmacy();
        _;
    }

    function authorizeUser(
        address _addr,
        uint8 role
    ) public onlyOwner isValid(_addr) isOutOfRangeAccessControls(role) {
        allowAccess[_addr] = AccessControls(role);
    }

    function revokeUser(address _addr) public onlyOwner {
        require(
            allowAccess[_addr] != AccessControls.Unauthorized,
            "Not Registered"
        );
        if (allowAccess[_addr] == AccessControls.Patient) {
            // PatientRecord memory patient;
            // for (uint i = 0; i < patientRecords.length; i++) {
            //     if (patientRecords[i].addr == _addr) {
            //         patient = patientRecords[i];
            //         patientRecords[i] = patientRecords[
            //             patientRecords.length - 1
            //         ];
            //         patientRecords[patientRecords.length - 1] = patient;
            //     }
            // }
            // patientRecords.pop();
            delete patientRecordDetails[_addr];
        }
        if (allowAccess[_addr] == AccessControls.Doctor) {
            // DoctorRecord memory doctor;
            // for (uint i = 0; i < doctorRecords.length; i++) {
            //     if (doctorRecords[i].addr == _addr) {
            //         doctor = doctorRecords[i];
            //         doctorRecords[i] = doctorRecords[doctorRecords.length - 1];
            //         doctorRecords[doctorRecords.length - 1] = doctor;
            //     }
            // }
            // doctorRecords.pop();
            delete doctorRecordDetails[_addr];
        }
        if (allowAccess[_addr] == AccessControls.Pharmacy) {
            // PharmacyRecord memory pharmacy;
            // for (uint i = 0; i < pharmacyRecords.length; i++) {
            //     if (pharmacyRecords[i].addr == _addr) {
            //         pharmacy = pharmacyRecords[i];
            //         pharmacyRecords[i] = pharmacyRecords[
            //             pharmacyRecords.length - 1
            //         ];
            //         pharmacyRecords[pharmacyRecords.length - 1] = pharmacy;
            //     }
            // }
            // pharmacyRecords.pop();
            // address  pharmacy;
            // for (uint i = 0; i < pharmacyAddress.length; i++) {
            //     if (pharmacyAddress[i] == _addr) {
            //         pharmacy = pharmacyAddress[i];
            //         pharmacyAddress[i] = pharmacyAddress[
            //             pharmacyAddress.length - 1
            //         ];
            //         pharmacyAddress[pharmacyAddress.length - 1] = pharmacy;
            //     }
            // }
            // pharmacyAddress.pop();

            delete pharmacyRecordDetails[_addr];
        }
        emit RevokeUser(_addr, allowAccess[_addr]);
        allowAccess[_addr] = AccessControls.Unauthorized;
    }

    function isRegistered() public view returns (string memory status) {
        if (allowAccess[msg.sender] == AccessControls.Unauthorized)
            return "Not Registered";
        if (allowAccess[msg.sender] == AccessControls.Patient)
            return "Registered as Patient";
        if (allowAccess[msg.sender] == AccessControls.Doctor)
            return "Registered as Doctor";
        if (allowAccess[msg.sender] == AccessControls.Pharmacy)
            return "Registered as Pharmacy";
    }

    function updatePatientArray(
        bytes32 name,
        uint age,
        bytes32 gender,
        bytes32 bloodGroup
    ) internal returns (bool) {
        bool control = true;
        for (uint i = 0; i < patientRecords.length; i++) {
            if (patientRecords[i].addr == msg.sender) {
                PatientRecord memory patient = PatientRecord(
                    name,
                    age,
                    gender,
                    bloodGroup,
                    msg.sender,
                    block.timestamp,
                    msg.sender,
                    patientRecords[i].pharmacy,
                    patientRecords[i].description
                );
                patientRecords[i] = patient;
                patientRecordDetails[msg.sender] = patient;
                control = false;
            }
        }
        return control;
    }

    function updatePatientDoctor(
        PatientRecord memory patient,
        address _patient
    ) internal {
        for (uint i = 0; i < patientRecords.length; i++) {
            if (patientRecords[i].addr == _patient) {
                patientRecords[i] = patient;
            }
        }
    }

    function addPatientRecord(
        bytes32 name,
        uint age,
        bytes32 gender,
        bytes32 bloodGroup
    ) public isPatient(msg.sender) {
        if (updatePatientArray(name, age, gender, bloodGroup)) {
            PatientRecord memory patient = PatientRecord(
                name,
                age,
                gender,
                bloodGroup,
                msg.sender,
                block.timestamp,
                msg.sender,
                address(0),
                ""
            );
            patientRecords.push(patient);
            patientRecordDetails[msg.sender] = patient;
        }
        emit PatientRecordsAdded(msg.sender);
    }

    function getPatientRecord()
        public
        view
        isPatient(msg.sender)
        returns (PatientRecord memory)
    {
        return patientRecordDetails[msg.sender];
    }

    function addDoctorRecord(
        bytes32 name,
        uint age,
        bytes32 gender,
        bytes32 Qualification,
        bytes32 HospitalName,
        bytes32 location
    ) public isDoctor(msg.sender) {
        DoctorRecord memory doctor = DoctorRecord(
            name,
            age,
            gender,
            Qualification,
            HospitalName,
            location,
            msg.sender
        );
        bool control = true;
        for (uint i = 0; i < doctorRecords.length; i++) {
            if (doctorRecords[i].addr == msg.sender) {
                doctorRecords[i] = doctor;
                control = false;
            }
        }
        if (control) doctorRecords.push(doctor);
        doctorRecordDetails[msg.sender] = doctor;
        emit DoctorRecordsAdded(msg.sender);
    }

    function getDoctorRecord()
        public
        view
        isDoctor(msg.sender)
        returns (DoctorRecord memory)
    {
        return doctorRecordDetails[msg.sender];
    }

    function addPharmacyRecord(
        bytes32 name,
        bytes32 street,
        bytes32 location
    ) public isPharmacy(msg.sender) {
        PharmacyRecord memory Pharmacy = PharmacyRecord(
            name,
            street,
            location,
            msg.sender
        );
        bool control = true;
        for (uint i = 0; i < pharmacyRecords.length; i++) {
            if (pharmacyRecords[i].addr == msg.sender) {
                pharmacyRecords[i] = Pharmacy;
                control = false;
            }
        }
        if (control) {
            pharmacyRecords.push(Pharmacy);
            // pharmacyAddress.push(msg.sender);
        }
        pharmacyRecordDetails[msg.sender] = Pharmacy;
        emit PharmacyRecordsAdded(msg.sender);
    }

    function getPharmacyRecord()
        public
        view
        isPharmacy(msg.sender)
        returns (PharmacyRecord memory)
    {
        return pharmacyRecordDetails[msg.sender];
    }

    function getAllPatientRecords()
        public
        view
        onlyOwner
        returns (PatientRecord[] memory)
    {
        return patientRecords;
    }

    function getAllDoctorRecords()
        public
        view
        OwnerOrPatient(msg.sender)
        returns (DoctorRecord[] memory)
    {
        return doctorRecords;
    }

    function getAllPharmacyRecords()
        public
        view
        OwnerOrPatientOrDoctor(msg.sender)
        returns (PharmacyRecord[] memory)
    {
        return pharmacyRecords;
    }

    function allowAccessToDoctor(address _doctor) public isPatient(msg.sender) {
        require(
            allowAccess[_doctor] == AccessControls.Doctor,
            "Not Registered as Doctor"
        );
        hasAccessToDoctor[_doctor][msg.sender] = true;
        emit AccessGrantedToDoctor(msg.sender, _doctor);
    }

    function revokeAccessToDoctor(
        address _doctor
    ) public isPatient(msg.sender) {
        require(
            allowAccess[_doctor] == AccessControls.Doctor,
            "Not Registered as Doctor"
        );
        hasAccessToDoctor[_doctor][msg.sender] = false;
        emit AccessRevokedFromDoctor(msg.sender, _doctor);
    }

    function allowAccessToPharmacy(
        address _Pharmacy
    ) public isPatient(msg.sender) {
        // address _Pharmacy = patientRecordDetails[msg.sender].pharmacy;
        require(
            allowAccess[_Pharmacy] == AccessControls.Pharmacy,
            "Not Registered as Pharmacy"
        );
        hasAccessToPharmacy[_Pharmacy][msg.sender] = true;
        emit AccessGrantedToPharmacy(msg.sender, _Pharmacy);
    }

    function revokeAccessToPharmacy(
        address _Pharmacy
    ) public isPatient(msg.sender) {
        // address _Pharmacy = patientRecordDetails[msg.sender].pharmacy;
        require(
            allowAccess[_Pharmacy] == AccessControls.Pharmacy,
            "Not Registered as Pharmacy"
        );
        hasAccessToPharmacy[_Pharmacy][msg.sender] = false;
        emit AccessRevokedFromPharmacy(msg.sender, _Pharmacy);
    }

    function getPatientsOfDoctors()
        public
        view
        isDoctor(msg.sender)
        returns (PatientRecord[] memory records)
    {
        uint256 resultCount;
        for (uint i = 0; i < patientRecords.length; i++) {
            if (hasAccessToDoctor[msg.sender][patientRecords[i].addr]) {
                resultCount++;
            }
        }
        records = new PatientRecord[](resultCount);
        uint256 j;
        for (uint i = 0; i < patientRecords.length; i++) {
            if (hasAccessToDoctor[msg.sender][patientRecords[i].addr]) {
                records[j] = patientRecords[i];
                j++;
            }
        }
    }

    function getPatientsOfPharmacy()
        public
        view
        isPharmacy(msg.sender)
        returns (PatientRecord[] memory records)
    {
        uint256 resultCount;
        for (uint i = 0; i < patientRecords.length; i++) {
            if (hasAccessToPharmacy[msg.sender][patientRecords[i].addr]) {
                resultCount++;
            }
        }
        records = new PatientRecord[](resultCount);
        uint256 j;
        for (uint i = 0; i < patientRecords.length; i++) {
            if (hasAccessToPharmacy[msg.sender][patientRecords[i].addr]) {
                records[j] = patientRecords[i];
                j++;
            }
        }
    }

    function modifyPatientRecord(
        address _addr,
        address _pharmacy,
        string memory _desc
    ) public isDoctor(msg.sender) isPharmacy(_pharmacy) isPatient(_addr) {
        if (!hasAccessToDoctor[msg.sender][_addr]) revert UnauthorizedDoctor();
        PatientRecord memory patient = PatientRecord(
            patientRecordDetails[_addr].name,
            patientRecordDetails[_addr].age,
            patientRecordDetails[_addr].gender,
            patientRecordDetails[_addr].bloodGroup,
            patientRecordDetails[_addr].addr,
            block.timestamp,
            msg.sender,
            _pharmacy,
            _desc
        );
        updatePatientDoctor(patient, _addr);
        patientRecordDetails[_addr] = patient;
        emit PatientRecordModified(_addr, msg.sender);
    }
}