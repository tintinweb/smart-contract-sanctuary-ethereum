/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

abstract contract OwnerHelper {
    address private owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner, "msg.sender is not owner"); // msg.sender가 owner일 때만 함수 실행
        _; // 함수 실행
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnerShip(address _to) onlyOwner public {
        require(_to != owner, "new address is owner");
        require(_to != address(0), "invalid address"); // _to가 0이 아니라면, 즉 제대로 된 주소라면 실행
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer {
        require(isIssuer(msg.sender) == true, "msg.sender is not issuer"); // msg.sender가 issuer일때만 함수 실행
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    // _addr이 issuer 역할을 하는지 검사
    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    // _addr를 issuer로 등록. issuers에 추가.
    function addIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == false, "already issuer"); // 이미 등록되어있지 않을 때만 실행
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    // issuer였던 _addr을 취소.
    function delIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == true, "_addr is not issuer"); // _addr이 issuer로 등록되어 있는지 검사.
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper {
    uint256 private idCount;
    mapping(uint8 => string) private vaccineEnum; // 백신 타입
    mapping(uint8 => string) private statusEnum; // 접종 차수 저장

    struct Credential {
        uint256 id;
        address issuer; 
        uint8 vaccineType; // 백신 타입 저장.
        uint8 statusType; // 접종 차수 저장. 
        string value;
        uint256 createDate; // 백신증명서 발급일.
    }

    // address마다 Credential 배열이 매핑된다. 
    // Credential 배열은 각 차수의 백신증명서를 저장하고 있다. (0번째는 1차, 1번째는 2차, 2번째는 3차)
    mapping(address => Credential[]) private credentials;

    constructor() {
        // 값 초기화
        idCount = 1;
        vaccineEnum[0] = "Astrazeneca";
        vaccineEnum[1] = "Janssen";
        vaccineEnum[2] = "Pfizer";
        vaccineEnum[3] = "Moderna";
        statusEnum[0] = "first";
        statusEnum[1] = "second";
        statusEnum[2] = "third";
    }

    // 크레덴셜 발급
    function claimCredential(address _addr, uint8 _vaccineType, uint8 _statusType, string calldata _value) onlyIssuer public returns(bool) {
        // _addr 검사
        require(_addr != address(0), "invalid address");
        // _vaccineType과 _statusType이 미리 정의되어 있는 것인지 검사
        require(bytes(vaccineEnum[_vaccineType]).length != 0, "_vaccineType is undefined");
        require(bytes(statusEnum[_statusType]).length != 0, "_statusType is undefined");

        // 해당 _addr이 _statusType번째 백신증명서를 발급할 순서인지 검사
        require(credentials[_addr].length == _statusType, "wrong _statusType");


        // address의 _statusType번째 Credential
        credentials[_addr].push(Credential({
            id: idCount,
            issuer: msg.sender,
            vaccineType: _vaccineType,
            statusType: _statusType,
            value: _value,
            createDate: block.timestamp // 크레덴셜을 클레임한 시간 저장
        })); 

        idCount += 1;

        return true;
    }

    // 해당 _address에 매핑되는 Credential배열을 반환한다.
    function getCredential(address _address) public view returns (Credential[] memory) {
        return credentials[_address];
    }

    // 백신 타입 추가
    function addvaccineType(uint8 _type, string calldata _value) onlyIssuer public returns (bool) {
        require(bytes(vaccineEnum[_type]).length == 0); // 해당 _type에 해당하는 AluminEnum이 이미 있는지 길이로 검사
        vaccineEnum[_type] = _value;
        return true;
    }

    function getvaccineType(uint8 _type) public view returns (string memory) {
        return vaccineEnum[_type];
    }

    function addStatusType(uint8 _type, string calldata _value) onlyIssuer public returns (bool) {
        require(bytes(statusEnum[_type]).length == 0, "already exists");
        statusEnum[_type] = _value;
        return true;
    }

    function getStatusType(uint8 _type) public view returns (string memory) {
        return statusEnum[_type];
    }

    // _addr의 _statusType 차수의 크레덴셜의 백신 타입을 변경하는 함수
    function changeVaccineType(address _addr, uint8 _vaccine, uint8 _status) onlyIssuer public returns (bool) {
        // _addr에게 발급한 _status 차수의 credential이 있는지 검사
        require(_status < credentials[_addr].length , "credential is undefined"); 
        require(bytes(vaccineEnum[_vaccine]).length != 0, "_vaccineType is undefined"); // 해당 _type의 vaccineEnum이 존재하는지 검사
        // _address에게 발급한 credential의 vaccine 변경
        credentials[_addr][_status].vaccineType = _vaccine;
        return true;
    }
}