// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Certificate {
    address public owner;
    struct certificateData {
        bytes32 certificate_hash;
        bool assigned;
    }

    constructor() {
        owner = msg.sender;
    }

    mapping(uint => certificateData) allCertificates;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier notAssigned(uint id) {
        require(allCertificates[id].assigned == false);
        _;
    }

    function addCertificate(
        uint id,
        string memory issuedTo,
        string memory issuer,
        string memory course,
        string memory issuedOn
    ) external onlyOwner notAssigned(id) {
        allCertificates[id].certificate_hash = keccak256(
            abi.encodePacked(issuedTo, issuer, course, issuedOn)
        );
        allCertificates[id].assigned = true;
    }

    function sendDataForVerification(uint id) external view returns (bytes32) {
        return allCertificates[id].certificate_hash;
    }
}