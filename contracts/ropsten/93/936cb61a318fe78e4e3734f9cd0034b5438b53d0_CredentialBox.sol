/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

contract CredentialBox {
    address private issuerAddress;
    uint256 private idCount;
    mapping(uint8 => string) private vaccineEnum;

    struct Credential{
        uint256 id;
        address issuer;
        uint8 vaccineType;
        string value;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        issuerAddress = msg.sender;
        idCount = 1;
        vaccineEnum[0] = "astra";
        vaccineEnum[1] = "janssen";
        vaccineEnum[2] = "pfizer";
        vaccineEnum[3] = "moderna";
    }

    function claimCredential(address _vaccineAddress, uint8 _vaccineType, string calldata _value) public returns(bool){
        require(issuerAddress == msg.sender, "Not Issuer");
				Credential storage credential = credentials[_vaccineAddress];
        require(credential.id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.vaccineType = _vaccineType;
        credential.value = _value;
        
        idCount += 1;

        return true;
    }

    function getCredential(address _vaccineAddress) public view returns (Credential memory){
        return credentials[_vaccineAddress];
    }

}