/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {
   
    struct todo {
        uint256 taskNumber;
        string Name;
        bool completed;
    }

   mapping(uint256 => todo) public tasks;

    uint256 public taskNumber;
    bool completed;

   function setter(string memory _taskName) public {
       tasks[taskNumber] = todo(taskNumber , _taskName, completed);
       taskNumber++;
   }

   function update(uint256 _taskNumber) public {
       tasks[_taskNumber].completed = !tasks[_taskNumber].completed;
   }

}