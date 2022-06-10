/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract CredentialBox {
    // 상태 변수들
    address private issuerAddress;  
    uint256 private idCount;

   event inoculationImformation(address inoculatorAddress , uint id, uint8 vaccineType);

    mapping(uint8 => string) private vaccineType;

    struct Credential{
        uint256 id;     //index(몇 차 인지?)
        address issuer;  //접종 기관
        uint8 vaccineType;   //백신 종류
        string value;  //크리덴셜 추가적인 정보
        uint256 createDate;  //크리덴셜 생성 날짜
    }

    mapping(address => Credential) private credentials;

    constructor() {
        issuerAddress = msg.sender;     
        idCount = 1;
        vaccineType[0] = "Pfizer";
        vaccineType[1] = "Moderna";
        vaccineType[2] = "Astrazeneca";
        vaccineType[3] = "Janssen";
        vaccineType[4] = "Novavax";
    }

    // 접종확인증 발급자(issuer)는 접종자(_inoculatorAddress)에게 크리덴셜(Credential)을 발행(claim)
    function claimCredential(address _inoculatorAddress, uint8 _vaccineType, string calldata _value) public returns(bool){
        require(issuerAddress == msg.sender, "Not Issuer");  //접종기관에서 발급 할 때만 TX 성공, 아니면 TX 실패, "Not Issuer" 뜸.
                Credential storage credential = credentials[_inoculatorAddress];
        // require(credential.id == 0);
        
        credential.issuer = msg.sender;
        credential.vaccineType = _vaccineType;
        credential.id = idCount; 
        credential.value = _value;
        credential.createDate = block.timestamp;
        
        emit inoculationImformation( _inoculatorAddress, idCount, _vaccineType);

        
        idCount += 1;  //발급 시 id(발급 차수) +1

        return true;
    }

    // 접종자 주소(_inoculatorAddress)를 입력하여 발행(claim)받은 크리덴셜(Credential)을 확인
    function getCredential(address _inoculatorAddress) public view returns (Credential memory){
        return credentials[_inoculatorAddress];
    }

}