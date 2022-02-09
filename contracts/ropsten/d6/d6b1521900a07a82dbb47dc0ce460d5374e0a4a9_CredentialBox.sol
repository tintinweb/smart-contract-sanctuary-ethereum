/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

abstract contract OwnerHelper {
    address private owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public onlyOwner {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer() {
        require(isIssuer(msg.sender) == true);
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    function addIssuer(address _addr) public onlyOwner returns (bool) {
        require(issuers[_addr] == false);
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) public onlyOwner returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper {
    uint8 private idCount;
    uint8 private vaccineEnumLength;
    uint8 private conditionEnumLength;

    mapping(uint8 => string) private vaccineEnum;
    mapping(uint8 => string) private conditionEnum;

    struct Credential {
        uint256 id;
        address issuer;
        uint8 vaccineType;
        uint8 vaccinatedCondition;
        string value;
        uint256 createDate;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        vaccineEnum[0] = "Moderna";
        vaccineEnum[1] = "Pfizer";
        vaccineEnum[2] = "Janssen";
        vaccineEnum[3] = "Astrazeneca";
        conditionEnum[0] = "Normal";
        conditionEnum[1] = "Mild";
        conditionEnum[2] = "Severe";
        conditionEnum[3] = "Expiration";
    }

    function claimCredential(
        address _vaccinatedAddress,
        uint8 _vaccineType,
        string calldata _value
    ) public onlyIssuer returns (bool) {
        Credential storage credential = credentials[_vaccinatedAddress];
        require(credential.id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.vaccineType = _vaccineType;
        credential.vaccinatedCondition = 0;
        credential.value = _value;
        credential.createDate = block.timestamp;

        idCount += 1;

        return true;
    }

    function getCredential(address _vaccinatedAddress)
        public
        view
        returns (Credential memory)
    {
        return credentials[_vaccinatedAddress];
    }

    function addVaccineType(uint8 _type, string calldata _value)
        public
        onlyIssuer
        returns (bool)
    {
        require(bytes(vaccineEnum[_type]).length == 0);
        vaccineEnum[_type] = _value;
        return true;
    }

    function getVaccineType(uint8 _type) public view returns (string memory) {
        return vaccineEnum[_type];
    }

    function addVaccinatedCondition(uint8 _type, string calldata _value)
        public
        onlyIssuer
        returns (bool)
    {
        require(bytes(conditionEnum[_type]).length == 0);
        conditionEnum[_type] = _value;
        return true;
    }

    function getVaccinatedCondition(uint8 _type) public view returns (string memory) {
        return conditionEnum[_type];
    }

    function changeStatus(address _vaccinatedAddress, uint8 _type)
        public
        onlyIssuer
        returns (bool)
    {
        require(credentials[_vaccinatedAddress].id != 0);
        require(bytes(conditionEnum[_type]).length != 0);
        credentials[_vaccinatedAddress].vaccinatedCondition = _type;
        return true;
    }
}