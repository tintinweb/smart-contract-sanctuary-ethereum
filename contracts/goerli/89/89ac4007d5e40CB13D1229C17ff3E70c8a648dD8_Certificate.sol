/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract Certificate {
    address private owner;
    mapping(address => bool) public schools;

    struct CertificateData {
        address school;
        address student;
        bytes32 certificateHash;
        bool valid;
        uint time;
        string[] fileAddresses;
    }

    mapping(address => CertificateData) private certificates;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlySchool() {
        require(schools[msg.sender] == true, "Only school can perform this action");
        _;
    }

    modifier onlyStudent(address student) {
        require(msg.sender == student, "Only student can perform this action");
        _;
    }

    modifier schoolIssuedCertificate(address student) {
        require(certificates[student].school == msg.sender, "Only issuing school can perform this action");
        _;
    }

    function setSchool(address schoolAddress) public onlyOwner {
        schools[schoolAddress] = true;
    }

    function issueCertificate(
        address student,
        bytes32 certificateHash,
        string[] memory fileAddresses
    ) public onlySchool {
        certificates[student] = CertificateData({
            school: msg.sender,
            student: student,
            certificateHash: certificateHash,
            valid: true,
            time: block.timestamp,
            fileAddresses: fileAddresses
        });
    }

    function validCertificate(address student, bool validStatus) public onlySchool schoolIssuedCertificate(student) {
        certificates[student].valid = validStatus;
    }

    function updateCertificate(
        address student,
        bytes32 certificateHash,
        string[] memory fileAddresses
    ) public onlySchool schoolIssuedCertificate(student) {
        certificates[student].certificateHash = certificateHash;
        certificates[student].time = block.timestamp;
        certificates[student].fileAddresses = fileAddresses;
    }

    function downloadCertificate(address student) public view onlyStudent(student) returns (string[] memory) {
        return certificates[student].fileAddresses;
    }
}