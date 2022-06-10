/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract VaccineBox {

    address private issuerAddress;
    uint private idCount;
    mapping(uint8 => string) private vaccine;

    struct Certificate{
        uint256 id;
        address issuer;
        uint vaccineType;
        string value;
        uint createDate;
    }

    mapping(address => Certificate) private certificates;

    constructor() {
        issuerAddress = msg.sender;
        idCount = 1;
        vaccine[0] = "pfizer";
        vaccine[1] = "moderna";
        vaccine[2] = "janssen";
    }

    modifier onlyIssuer {
        require(issuerAddress == msg.sender);
        _;
    }

    function claimCertificate(address _vaccinatedAddress, uint8 _vaccineType, 
    string calldata _value) onlyIssuer public returns(bool){
        Certificate storage certificate = certificates[_vaccinatedAddress];
        require(certificate.id == 0);
        certificate.id = idCount;
        certificate.issuer = msg.sender;
        certificate.vaccineType = _vaccineType;
        certificate.value = _value;
        certificate.createDate = block.timestamp;

        idCount += 1;

        return true;
    }

    function getCertificate(address _vaccinatedAddress) 
    public view returns (Certificate memory){
        return certificates[_vaccinatedAddress];
    }

    function addVaccineType(uint8 _type, string calldata _value) onlyIssuer public returns (bool) {
        require(bytes(vaccine[_type]).length == 0);
        vaccine[_type] = _value;
        return true;
    }

    function getVaccineType(uint8 _type) public view returns (string memory) {
        return vaccine[_type];
    }



}