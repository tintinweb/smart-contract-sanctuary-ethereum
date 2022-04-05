/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract VaccineCredential {
    address private issuerAddress;
    uint256 private idCount;
    mapping(uint8 => string) private vaccineEnum;
    uint8 vaccineTypeCount;

    struct Credential {
        uint256 id;
        uint256 verifiedTime;
        address issuer;
        string vaccineType;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        issuerAddress = msg.sender;
        idCount = 1;
        vaccineEnum[0] = "Pfizer";
        vaccineEnum[1] = "Moderna";
        vaccineEnum[2] = "AstraZeneca";
        vaccineEnum[3] = "Janssen";
        vaccineTypeCount = 4;
    }

    function claimCredential(address _address, uint8 _vaccineType) public returns(bool) {
        require(issuerAddress == msg.sender, "Not Issuer");
        Credential storage credential = credentials[_address];
        require(credential.id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.vaccineType = vaccineEnum[_vaccineType];
        credential.verifiedTime = block.timestamp;

        idCount += 1;
        return true;
    }

    function getCredential(address _address) public view returns(Credential memory) {
        return credentials[_address];
    }

    function addVaccineType(string memory _newVaccine) public returns(bool) {
        require(issuerAddress == msg.sender, "Now Issuer");
        vaccineEnum[vaccineTypeCount] = _newVaccine;
        vaccineTypeCount++;
        return true;
    }
}