// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract info {
    uint256 rollno;
    string name;

    function RollNumber(uint256 _rollno) public {
        rollno = _rollno;
    }

    function Name(string memory _name) public {
        name = _name;
    }

    function CheckRollNo() public view returns (uint256) {
        return rollno;
    }
}