/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CredentialBox {
    address private issuerAddress;
    uint8 private vaccineTypeCnt;

    struct Credential {
        uint256 id;
        address issuer;
        uint8 vaccineType;
        string value;
    }

    mapping(address => mapping(uint8 => Credential)) private credentials;

    mapping(uint8 => uint256) private idCounts;

    mapping(uint8 => string) private vaccineEnum;

    constructor() {
        issuerAddress = msg.sender;
        vaccineEnum[1] = "Pfizer";
        vaccineEnum[2] = "Moderna";
        vaccineEnum[3] = "Janssen";
        vaccineTypeCnt = 3;
    }

    function claimCredential(address inoculatorAddress, uint8 shotCnt, uint8 _vaccineType, string calldata _value) public returns (bool) {
        require(issuerAddress == msg.sender, "Not Issuer");

        for(uint8 i=1; i<shotCnt; i++) require(credentials[inoculatorAddress][i].id != 0, "Didn't inoculated previous shot.");
        require(credentials[inoculatorAddress][shotCnt].id == 0, "already inoculated.");   

        Credential storage credential = credentials[inoculatorAddress][shotCnt];

        credential.id = ++idCounts[shotCnt];    
        credential.issuer = msg.sender;
        credential.vaccineType = _vaccineType;
        credential.value = _value;      

        return true;
    }

    function addVaccine(string memory vaccineName) public returns (bool) {
        require(issuerAddress == msg.sender, "Not Issuer");
        require(bytes(vaccineEnum[vaccineTypeCnt+1]).length == 0, "Vaccine type is already exist.");

        vaccineEnum[++vaccineTypeCnt] = vaccineName;

        return true;
    }

    function getCrednetial(address inoculatorAddress, uint8 shotCnt) public view returns (Credential memory) {
        return credentials[inoculatorAddress][shotCnt];
    }

}