// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SecureStorage {
    struct File {
        string name;
        string sem1;
        string sem2;
        string sem3;
        string sem4;
        string sem5;
        string sem6;
        string sem7;
        string sem8;
        string enrolNo;
        string cgpa;
        bool isRevoked;
    }
    address public owner;
    mapping(string => File) public files;
    constructor() {
        owner = msg.sender;
    }
    function addFile(
        string memory _name,
        string memory _enrolNo,
        string memory _sem1,
        string memory _sem2,
        string memory _sem3,
        string memory _sem4,
        string memory _sem5,
        string memory _sem6,
        string memory _sem7,
        string memory _sem8,
        string memory _cgpa,
        bool _isRevoked
    ) public {
        require(msg.sender == owner);
        File memory file = File({
            name: _name,
            enrolNo: _enrolNo,
            sem1: _sem1,
            sem2: _sem2,
            sem3: _sem3,
            sem4: _sem4,
            sem5: _sem5,
            sem6: _sem6,
            sem7: _sem7,
            sem8: _sem8,
            cgpa: _cgpa,
            isRevoked: _isRevoked
        });
        files[_enrolNo] = file;
    }
    function getFile(string memory _enrolNo) public view returns (File memory) {
        return files[_enrolNo];
    }
}