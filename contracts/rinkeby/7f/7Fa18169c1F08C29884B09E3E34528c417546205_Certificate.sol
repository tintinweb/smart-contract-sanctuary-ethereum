/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Certificate {

    struct Certified {
        string credentialID;
        string name;
        string courseName;
        string issuingOrganization;
        string reasonForAward;
        uint issueDate;
        uint expirationDate;
    }
    

    uint numberOfCertificates = 0;       

    mapping(string => Certified) newCertified;
    mapping(string => Certified) selectedCertified;

    Certified[] public certified;

    address owner;

    constructor() {
        owner = msg.sender;
        numberOfCertificates=0;
    }

    function getNumberOfCertificates() public view returns(uint){
        return(numberOfCertificates);
    }

    function getOwner() public view returns(address){
        return(owner);
    }

    function addCertificate(
        string memory _credentialID,
        string memory  _name,
        string memory  _courseName,
        string memory  _issuingOrganization,
        string memory _reasonForAward,
        uint _issueDate,
        uint _expirationDate
        ) public {

        require( owner == msg.sender);
        certified.push(Certified({
        credentialID: _credentialID,
        name: _name,
        courseName: _courseName,
        issuingOrganization: _issuingOrganization,
        reasonForAward: _reasonForAward,
        issueDate: _issueDate,
        expirationDate: _expirationDate
        }));
        numberOfCertificates++;
    }

    function checkCertificate(string memory _credentialID) public view returns(
        string memory,  string memory, string memory, string memory,string memory,uint,uint
    ){
        for(uint m=0 ; m<numberOfCertificates ; m++){
            if(keccak256(bytes(certified[m].credentialID))==keccak256(bytes(_credentialID))) {
                if((block.timestamp<=certified[m].expirationDate)||(certified[m].expirationDate==40000000000)){
                    return(certified[m].credentialID,
                    certified[m].name,
                    certified[m].courseName,
                    certified[m].issuingOrganization,
                    certified[m].reasonForAward,
                    certified[m].issueDate,
                    certified[m].expirationDate
                    );
                }
            }
        }
        return('','','','','',0,0);
    }
}