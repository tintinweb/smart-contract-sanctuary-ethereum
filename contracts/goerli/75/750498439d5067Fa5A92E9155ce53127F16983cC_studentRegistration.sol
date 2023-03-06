// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// students data.
// create a function that registers students.
// students details should include Name, Id, age, gender, Faculty.
// create a function to get students details.
// create function to delete student details
// only admin can add or remove student
// create a function that can change admin.

contract studentRegistration {
    struct studentDetails {
        address studentAddress;
        string name;
        uint256 Id;
        uint256 age;
        string gender;
        string faculty;
        bool status;
    }

    address public admin;
    uint256 public studentId;
    mapping(address => studentDetails) public studentData;
    address[] public studentAddr;
    int256 arrayIndex = -1;
    mapping(address => uint256) public index;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "You dont have permission");
        _;
    }

    function registerStudent(
        address _studentAddr,
        string memory _name,
        uint256 _age,
        string memory _gender,
        string memory _faculty
    ) public onlyAdmin {
        require(_studentAddr != address(0), "Invalid Student's address");
        require(
            studentData[_studentAddr].status == false,
            "Address already exists"
        );
        require(_studentAddr != admin, "You can't register yourself");
        studentId++;
        studentDetails memory data = studentDetails(
            _studentAddr,
            _name,
            studentId,
            _age,
            _gender,
            _faculty,
            true
        );

        studentData[_studentAddr] = data;
        studentAddr.push(_studentAddr);
        arrayIndex++;
        index[_studentAddr] = uint256(arrayIndex);
    }

    function getStudentDetails(address _address)
        public
        view
        returns (studentDetails memory data)
    {
        data = studentData[_address];
    }

    function deleteStudent(address _addr) public onlyAdmin {
        delete studentData[_addr];
    }

    function deleteAddr(address _addr) public onlyAdmin {
        uint256 addressIndex = index[_addr];
        delete studentAddr[addressIndex];
        require(addressIndex < studentAddr.length, "index is out of range");
        for (uint256 i = addressIndex; i < studentAddr.length - 1; i++) {
            studentAddr[i] = studentAddr[i + 1];
        }
        studentAddr.pop();
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }
}