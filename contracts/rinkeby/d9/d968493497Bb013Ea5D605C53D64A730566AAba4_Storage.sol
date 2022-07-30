// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Storage {
    uint256 id;
    mapping(address => uint) idOf;
    mapping(address => bool) checkStudent;
    event registered(string _name, string _gender, uint8 age);

    Student[] public list;

    struct Student {
        string name;
        string gender;
        uint8 age;
    }

    modifier studentExists(address _address) {
        require(checkStudent[_address] == false, "Student already exists");
        _;
    }

    function setStudent(
        string memory _name,
        string memory _gender,
        uint8 _age
    ) external studentExists(msg.sender) {
        list.push(Student(_name, _gender, _age));
        idOf[msg.sender] = id;
        checkStudent[msg.sender] = true;
        id++;
        emit registered(_name, _gender, _age);
    }

    function getID() external view returns (uint) {
        return idOf[msg.sender];
    }

    function getStudent() external view returns (Student memory) {
        return list[idOf[msg.sender]];
    }
}