/**
 *Submitted for verification at Etherscan.io on 2022-06-09
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
    }

    mapping(address => Certificate) private certificates;

    constructor() {
        issuerAddress = msg.sender;
        idCount = 1;
        vaccine[0] = "pfizer";
        vaccine[1] = "moderna";
        vaccine[2] = "janssen";
    }

    function claimCertificate(address _vaccinatedAddress, uint8 _vaccineType, string calldata _value) public returns(bool){
        require(issuerAddress == msg.sender, "Not Issuer");
        Certificate storage certificate = certificates[_vaccinatedAddress];
        require(certificate.id == 0);
        certificate.id = idCount;
        certificate.issuer = msg.sender;
        certificate.vaccineType = _vaccineType;
        certificate.value = _value;

        idCount += 1;

        return true;
    }

    function getCertificate(address _vaccinatedAddress) public view returns (Certificate memory){
        return certificates[_vaccinatedAddress];
    }


}