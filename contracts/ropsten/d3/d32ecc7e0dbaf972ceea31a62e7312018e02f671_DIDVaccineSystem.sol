/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

//SPDX-License-Identifier : GPL-3.0
pragma solidity >= 0.7.0 <0.9.0;

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
    event DeleteIssuer(address indexed _issuer);

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

    function deleteIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DeleteIssuer(_addr);
        return true;
    }
}


contract DIDVaccineSystem is IssuerHelper{

    uint256 private idCount;
    mapping(uint8=>string) private manufacturerEnum;
    mapping(uint8=>string) private vaccineDoseEnum;

    struct Credential {
        uint256 id;
        address issuer;
        uint8 manufacturerType;
        uint8 vaccineDoseType;
        string value;
        uint256 createDate;
    }
    
    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        manufacturerEnum[0] = "Astrazeneca";
        manufacturerEnum[1] = "Janssen";
        manufacturerEnum[2] = "Pfizer";
        manufacturerEnum[3] = "Moderna";
        manufacturerEnum[4] = "Novavax";
        vaccineDoseEnum[0] = "1st";
        vaccineDoseEnum[1] = "2nd";
        vaccineDoseEnum[2] = "3rd";
        vaccineDoseEnum[3] = "4th";
        vaccineDoseEnum[4] = "5th";
        vaccineDoseEnum[5] = "6th";
        vaccineDoseEnum[6] = "7th";
        vaccineDoseEnum[7] = "8th";
        vaccineDoseEnum[8] = "9th";
        vaccineDoseEnum[9] = "10th";
        vaccineDoseEnum[10] = "11th";
        vaccineDoseEnum[11] = "12th";
        vaccineDoseEnum[12] = "13th";
        vaccineDoseEnum[13] = "14th";
        vaccineDoseEnum[14] = "15th";
        vaccineDoseEnum[15] = "16th";
    }

    function claimCredential(address _userAddress, uint8 _manufacturerType, uint8 _vaccineDoseType, string calldata _value) onlyIssuer public returns(bool){

        Credential storage credential = credentials[_userAddress];
        require(credential.id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.manufacturerType = _manufacturerType;
        credential.vaccineDoseType = _vaccineDoseType;
        credential.value = _value;
        credential.createDate = block.timestamp;

        idCount += 1;

        return true;
    }

    function getCredential(address _userAddress) public view returns(Credential memory) {
        return credentials[_userAddress];
    }

    function addManufaturerType(uint8 _type, string calldata _manufacturer) onlyIssuer public returns(bool) {
        require(bytes(manufacturerEnum[_type]).length == 0);
        manufacturerEnum[_type] = _manufacturer;
        return true;
    }

    function getManufaturerType(uint8 _type) public view returns(string memory) {
        return manufacturerEnum[_type];
    }

}