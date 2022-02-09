/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract CredentialBox {
    address private issuerAddress;
    uint8 private vaccineTypeCnt;

    struct Credential {
        uint256 id;
        address issuer;
        uint8 vaccineType;
        string value;
    }

    // who => shot count => credential
    mapping(address => mapping(uint8 => Credential)) private credentials;

    // shot count => id count
    mapping(uint8 => uint256) private idCounts;

    // vaccineType => vaccine identifier
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

        // 1차 부터 (shotCnt-1)차 까지 접종한 상태이어야 함
        for(uint8 i=1; i<shotCnt; i++) require(credentials[inoculatorAddress][i].id != 0, "Who didn't inoculated previous shot.");
        require(credentials[inoculatorAddress][shotCnt].id == 0, "Who already inoculated.");   // shotCnt차 백신은 접종하지 않은 상태이어야 함

        Credential storage credential = credentials[inoculatorAddress][shotCnt];

        credential.id = ++idCounts[shotCnt];    // id는 1부터 시작
        credential.issuer = msg.sender;
        credential.vaccineType = _vaccineType;
        credential.value = _value;      // 암호화된 개인 정보

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

    function getVaccineEnum(uint8 vaccineType) public view returns (string memory) {
        return vaccineEnum[vaccineType];
    }

    // 현재 접종자 수
    function getInoculatorCnt(uint8 shotCnt) public view returns (uint256) {
        return idCounts[shotCnt];
    }

    // 현재 백신 종류 수
    function getVaccineTypeCnt() public view returns (uint8) {
        return vaccineTypeCnt;
    }
}