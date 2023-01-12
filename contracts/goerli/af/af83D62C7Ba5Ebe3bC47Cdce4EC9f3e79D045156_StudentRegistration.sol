//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error YouAreNotFromAuthority();
error NameNotProvided();
error EmailNotProvided();

contract StudentRegistration{
    
    struct Student{
        uint256 id;
        string name;
        string email;
        string imgHash;
    }

    event StudentAdded(uint256 indexed id, string name, string email, string imgHash);

    modifier onlyAuthority(){
        if(msg.sender != authority) {
            revert YouAreNotFromAuthority();
        }
        _;
    }

    mapping(uint256 => Student) private s_students;
    address private authority;

    constructor() {
        authority = msg.sender;
    }

    function addStudent(uint256 id, string memory name, string memory email, string memory imgHash) external onlyAuthority() {
        if(bytes(name).length == 0) {
            revert NameNotProvided();
        }
        if(bytes(email).length == 0) {
            revert EmailNotProvided();
        }
        s_students[id] = Student(id, name, email, imgHash);
        emit StudentAdded(id, name, email, imgHash);
    }

    function seeStudent(uint256 id) external view returns(Student memory) {
        return s_students[id];
    } 

    function seeAuthority() external view returns(address) {
        return authority;
    }
}