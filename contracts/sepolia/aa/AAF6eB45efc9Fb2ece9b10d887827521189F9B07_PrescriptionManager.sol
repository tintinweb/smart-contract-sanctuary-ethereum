//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrescriptionManager {
    struct Prescription {
        uint256 id;
        address patient;
        address doctor;
        string disease;
        string medicine;
        string dosage;
        string duration;
        uint256 timestamp;
    }
    
    mapping(address => Prescription[]) private prescriptions;
    function addPrescription(
        address _patient,
        address _doctor,
        string memory _disease,
        string memory _medicine,
        string memory _dosage,
        string memory _duration
    ) public {
        uint256 id = prescriptions[_patient].length;
        uint256 timestamp = block.timestamp;
        
        Prescription memory newPrescription = Prescription(
            id,
            _patient,
            _doctor,
            _disease,
            _medicine,
            _dosage,
            _duration,
            timestamp
        );
        
        prescriptions[_patient].push(newPrescription);
    }
    
    function getPrescription(address _patient, uint256 _index) public view returns (
        uint256 id,
        address patient,
        address doctor,
        string memory disease,
        string memory medicine,
        string memory dosage,
        string memory duration,
        uint256 timestamp
    ) {
        Prescription memory prescription = prescriptions[_patient][_index];
        
        return (
            prescription.id,
            prescription.patient,
            prescription.doctor,
            prescription.disease,
            prescription.medicine,
            prescription.dosage,
            prescription.duration,
            prescription.timestamp
        );
    }
    
    function getPrescriptionCount(address _patient) public view returns (uint256) {
        return prescriptions[_patient].length;
    }
}