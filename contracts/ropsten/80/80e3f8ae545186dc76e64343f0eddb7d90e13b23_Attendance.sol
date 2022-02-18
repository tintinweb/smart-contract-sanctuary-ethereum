/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.4.99;
pragma experimental ABIEncoderV2;

/// @title Attendance Smart Contract.
contract Attendance {
    
    // Our contract will create Student structs which hold basic info about students.
    struct Student {
        string id; // The ID chosen by the student.
        bool present; // Boolean (True/False) if the student is present.
        address creator; // The account address of the creator.
    }
    
    mapping(string => Student) studentMap; // We map strings to Student structs. This allows us to look up students by name.
    mapping(uint => string) studentIndex; // We map integers to the names, this allows us to look up students by index as well.
    uint256 mapsize; // We track how many students we have over time.

    function addStudent(string memory _id) public returns (bool) {
        Student memory new_student = Student(_id, false, msg.sender);
        studentMap[_id] = new_student;
        studentIndex[mapsize] = _id;
        mapsize++;
        return true;
    }
    
    // Only the address that added the student can mark them present.
    function markPresent(string memory _id) public returns (bool) {
        if (msg.sender == studentMap[_id].creator){
            studentMap[_id].present = true;
            return true;
        }
        return false;
    }

    function checkStatus(string memory _id) public view returns (Student memory){
        return studentMap[_id];
    }

    function showPresentStudents() public view returns (string[] memory){
        string[] memory present = new string[] (mapsize);
        uint counter;
        for(uint i = 0; i < mapsize; i++){
            string memory id = studentIndex[i];
            if (studentMap[id].present){
                present[counter] = id;
                counter++;
            }
        }
        return present;
    }
    
        
   
}