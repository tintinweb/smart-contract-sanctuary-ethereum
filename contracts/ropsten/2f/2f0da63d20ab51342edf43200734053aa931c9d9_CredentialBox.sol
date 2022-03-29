/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract CredentialBox {
    address private issuerAddress;
    uint256 private idCount;
    mapping(uint8 => string) private alumniEnum;

    // VC 구현 구조체
    // id : index 순서를 표기하는 idCount
    // issuer : VC를 발급하고, 보유자에게 전달하는 엔터티
    // alumniType : 졸업증명서 타입
    // value : VC에 포함되어야 하는 암호화된 정보. 신원/신원제공자/엔터티/서명등이 JSON 형태로 저장
    struct Credential{
        uint256 id;
        address issuer;
        uint8 alumniType;
        string value;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        issuerAddress = msg.sender;
        idCount = 1;
        alumniEnum[0] = "SEB";
        alumniEnum[1] = "BEB";
        alumniEnum[2] = "AIB";
    }

    function claimCredential(address _alumniAddress, uint8 _alumniType, string calldata _value) public returns(bool){
        require(issuerAddress == msg.sender, "Not Issuer");
				Credential storage credential = credentials[_alumniAddress];
        require(credential.id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.alumniType = _alumniType;
        credential.value = _value;
        
        idCount += 1;

        return true;
    }

    function getCredential(address _alumniAddress) public view returns (Credential memory){
        return credentials[_alumniAddress];
    }

}