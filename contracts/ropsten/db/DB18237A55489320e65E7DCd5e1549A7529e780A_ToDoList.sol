/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;


contract ToDoList{

  string[] todo;
  string task;

  function getTask() public view returns(string[] memory){
    return(todo);
  }

  function DoTask(string memory _task) public {
    todo.push(_task);
  }
}