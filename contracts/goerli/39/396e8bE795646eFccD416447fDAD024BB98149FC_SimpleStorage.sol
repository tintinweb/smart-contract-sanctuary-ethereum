// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favNum;
    Student[] public _student;

    mapping(string => uint256) public nameToAge;

    function store(uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        // return favNum+favNum;
        return favNum;
    }

    function addStudent(string memory _name, uint256 _ages) public {
        _student.push(Student(_student.length + 1, _name, _ages));
        nameToAge[_name] = _ages;
    }

    function getStudents() public view returns (Student[] memory) {
        return _student;
    }

    struct Student {
        uint256 id;
        string name;
        uint256 ages;
    }
}