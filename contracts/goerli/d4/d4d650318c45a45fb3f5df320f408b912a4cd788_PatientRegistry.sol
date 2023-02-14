/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PatientRegistry {
    mapping (bytes32 => address) public patients;

    event ApprovalRequested(bytes32 hash, address patientAddress);
    event ApprovalGranted(bytes32 hash, address patientAddress);

    function registerPatient(bytes32 hash, address patientAddress) public {
        emit ApprovalRequested(hash, patientAddress);
    }

    function approveRegistration(bytes32 hash) public {
        require(msg.sender == patients[hash], "Invalid approval request");
        emit ApprovalGranted(hash, patients[hash]);
    }

    function getPatientAddress(bytes32 hash) public view returns (address) {
        return patients[hash];
    }
}