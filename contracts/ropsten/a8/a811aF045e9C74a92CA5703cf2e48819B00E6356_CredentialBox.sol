/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

abstract contract OwnerHelper {
    address private owner;

  	event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner {
		require(msg.sender == owner);
		_;
  	}

  	constructor() {
		owner = msg.sender;
  	}

  	function transferOwnership(address _to) onlyOwner public {
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

    modifier onlyIssuer {
        require(isIssuer(msg.sender) == true);
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    function addIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == false);
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper {
    uint256 private idCount;
    mapping(uint8 => string) private vaccineEnum;
    mapping(uint8 => string) private statusEnum;
    mapping(uint8 => string) private noteEnum;

    struct Credential{
        uint256 id;
        address issuer;
        uint8 vaccineType;
        uint8 statusType;
        uint8 noteType;
        uint256 createDate;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        vaccineEnum[0] = "PFIZER";
        vaccineEnum[1] = "MODERNA";
        vaccineEnum[2] = "JANSSEN";
        vaccineEnum[3] = "ASTRAZENECA";
        statusEnum[0] = "None";
        statusEnum[1] = "first shot";
        statusEnum[2] = "second shot";
        statusEnum[3] = "third shot";
        noteEnum[0] = "None";
        noteEnum[1] = "vaccinated, 14 days not passed";
        noteEnum[2] = "vaccinated, 14 days passed";
        noteEnum[3] = "expired";
    }

    function claimCredential(address _personAddress, uint8 _vaccineType, uint8 _statusType, uint8 _noteType) onlyIssuer public returns(bool){
        Credential storage credential = credentials[_personAddress];
        require(credential.id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.vaccineType = _vaccineType;
        credential.statusType = _statusType;
        credential.noteType = _noteType;
        credential.createDate = block.timestamp;

        idCount += 1;

        return true;
    }

    function getCredential(address _personAddress) public view returns (Credential memory){
        return credentials[_personAddress];
    }

    function passOrNot(address _person, uint8 _vaccineType, uint8 _statusType) public view returns (bool){
        if (credentials[_person].id == 0){
            return false;
        }
        if (credentials[_person].vaccineType == _vaccineType && credentials[_person].statusType >= _statusType && credentials[_person].noteType == 2){
            return true;
        }
        else {
            return false;
        }
    }

    function addVaccineType(uint8 _type, string calldata _value) onlyIssuer public returns (bool) {
        require(bytes(vaccineEnum[_type]).length == 0);
        vaccineEnum[_type] = _value;
        return true;
    }

    function getVaccineType(uint8 _type) public view returns (string memory) {
        return vaccineEnum[_type];
    }

    function changeVaccine(address _person, uint8 _type) onlyIssuer public returns (bool) {
        require(credentials[_person].id != 0);
        require(bytes(vaccineEnum[_type]).length != 0);
        credentials[_person].vaccineType = _type;
        return true;
    }

    function addStatusType(uint8 _type, string calldata _value) onlyIssuer public returns (bool){
        require(bytes(statusEnum[_type]).length == 0);
        statusEnum[_type] = _value;
        return true;
    }

    function getStatusType(uint8 _type) public view returns (string memory) {
        return statusEnum[_type];
    }

    function changeStatus(address _person, uint8 _type) onlyIssuer public returns (bool) {
        require(credentials[_person].id != 0);
        require(bytes(statusEnum[_type]).length != 0);
        credentials[_person].statusType = _type;
        return true;
    }

    function addNoteType(uint8 _type, string calldata _value) onlyIssuer public returns (bool){
        require(bytes(noteEnum[_type]).length == 0);
        noteEnum[_type] = _value;
        return true;
    }

    function getNoteType(uint8 _type) public view returns (string memory) {
        return noteEnum[_type];
    }

    function changeNote(address _person, uint8 _type) onlyIssuer public returns (bool) {
        require(credentials[_person].id != 0);
        require(bytes(noteEnum[_type]).length != 0);
        credentials[_person].noteType = _type;
        return true;
    }

}