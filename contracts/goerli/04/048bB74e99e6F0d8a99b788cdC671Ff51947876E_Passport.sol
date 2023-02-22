// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Passport {

    struct passport {
        string hashId;
        string name;
        uint age;
        string sex;
    }
    mapping (string => passport) passportRepo;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    event passportInformation(string indexed _hashId, string _name, uint _age, string _sex);

    function setPassportDetails(string memory _hashId, string memory _name, uint _age, string memory _sex) public returns(bool) {
        
        emit passportInformation(_hashId, _name, _age, _sex);
        
        require(false, "Transcation reverted");
        
        passportRepo[_hashId].hashId = _hashId;
        passportRepo[_hashId].name= _name;
        passportRepo[_hashId].age = _age;
        passportRepo[_hashId].sex = _sex;

        return(true);
    }

}