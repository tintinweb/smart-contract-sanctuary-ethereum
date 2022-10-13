/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract myStudentId {
 
    // Create a contract that stores your StudentId
    // it should have a constructor that has the studentid as a parameter
    // if should have the following functions:
    //      viewMyId -> returns a view of your id, can be viewed by anone
    //      updateID -> permits only you, the owner, to update your id
    uint StudentId;
    address owner;
    constructor(){
      StudentId=1142241;
      owner=msg.sender;
    }
    function viewMyId() public view returns (uint){
        return StudentId;
    }
    function updateID(uint newStudentId) public {
       require(msg.sender==owner,"Owner must call this function");
       StudentId= newStudentId;
    }
}