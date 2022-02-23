/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract student {

    struct studentInfo {
        string name;
        uint256 age;
    }

    studentInfo [] public info; 
    mapping (string => uint256) public studentMapping;

    function addStudentMapping (string memory _name, uint256 _age) public {
        studentMapping[_name]=_age ;
        info.push(studentInfo(_name,_age));

    }

}