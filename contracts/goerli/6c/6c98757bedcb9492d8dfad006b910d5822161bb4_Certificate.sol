//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Define the contract
contract Certificate {
    // Define the struct to hold the certificate data
    struct CertificateData {
        string recipient; // name of the recipient
        string course; // name of the course or program
        uint date; // date the certificate was issued (in Unix timestamp format)
    }

    // Define the mapping to store the certificate data
    mapping (uint256 => CertificateData) public certificates;

    // Define the function to add a new certificate
    function addCertificate(uint256 id, string memory recipient, string memory course, uint date) public {
        // Set the certificate data
        CertificateData memory data = CertificateData(recipient, course, date);

        // Store the certificate data in the mapping
        certificates[id] = data;
    }

    
   // Define the function to update an existing certificate
    function updateCertificate(uint256 id, string memory recipient, string memory course, uint date) public {
        // Check if the certificate exists
       
      // require(certificates[id].recipient.length > 0, "Certificate does not exist");

        require(keccak256(abi.encodePacked(certificates[id].recipient)) != keccak256(abi.encodePacked("")), "Certificate does not exist");

        // Set the updated certificate data
        CertificateData memory data = CertificateData(recipient, course, date);

        // Update the certificate data in the mapping
        certificates[id] = data;
    }

    function getCertificate(uint256 id) public view returns (string memory, string memory, uint) {
        // Retrieve the certificate data from the mapping
        CertificateData memory data = certificates[id];

        // Return the certificate data
        return (data.recipient, data.course, data.date);
    }
   // emit getCertificate(id);
}