/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

abstract contract OwnerHelper {
    address public owner;  //public으로 open

    event OwnerTransferPropose(address indexed _from, address indexed _to); //index

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
        emit OwnerTransferPropose(owner, _to);
        owner = _to; 
    }
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;    
    
    event AddIssuer(address indexed _issuer); //index
    event DelIssuer(address _issuer); //indexed 제거

    modifier onlyIssuer {
        require(isIssuer(msg.sender) == true);
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns(bool){
        return issuers[_addr];
    }

    function addIssuer(address _addr) onlyOwner public returns(bool){
        require(issuers[_addr] == false); //issuer 데이터가 삭제되었을 때 실행가능
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) onlyOwner public returns(bool){
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper {
    uint256 public idCount;   //public으로 open

    mapping(uint8 => string) private alumniEnum;
    mapping(uint8 => string) private statusEnum; //status?

    event CreateNewCredential(address _who, Credential _newcredential, uint256 _idCount); //index

    struct Credential {
        uint256 id;
        address issuer;
        uint8 alumniType;
        uint8 statusType;
        string value;       //https://jwt.io/
        uint256 createDate;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        alumniEnum[0] = "SEB";
        alumniEnum[1] = "BEB";
        alumniEnum[2] = "AIB";
    }

    function claimCredential(address _alumniAddress, uint8 _alumniType, string calldata _value) onlyIssuer public returns(bool){ //calldata?
        Credential storage credential = credentials[_alumniAddress];
        require(credential.id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.alumniType = _alumniType;
        credential.statusType = 0;
        credential.value = _value;
        credential.createDate = block.timestamp; //Block TimeStamp
        idCount += 1;

        emit CreateNewCredential(_alumniAddress, credential, idCount); // add throw event

        return true;
    }

    function getCredential(address _alumniAddress) public view returns (Credential memory){
        return credentials[_alumniAddress];
    }

     function getStatusType(uint8 _type) public view returns (string memory) {
        return statusEnum[_type];
    }

    function addAlumniType(uint8 _type, string calldata _value) onlyIssuer public returns(bool){ //onlyowner
        require(bytes(alumniEnum[_type]).length == 0); //존재하지 않는지 확인, bytes길이가 0이어야함.
        alumniEnum[_type] = _value; //calldata?
        return true;
    }

    function changeStatus(address _alumni, uint8 _type) onlyIssuer public returns(bool){ //onlyowner
        require(credentials[_alumni].id != 0);
        require(bytes(statusEnum[_type]).length != 0); //이미 존재하는지 확인, bytes길이가 0이상
        credentials[_alumni].statusType = _type;
        return true;
    }
}