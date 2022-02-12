/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Todo {

  struct Task {
    uint id;
    string title;
    bool isCompleted;
  }

  Task[] tasks;
  uint index = 0;
  mapping(uint => bool) tasksMap;

  event Response(bool isDone, string message);

  function addTask(string memory _title) external {
    Task memory task = Task(index, _title, false);
    tasksMap[index] = true;
    tasks.push(task);
    index ++;
  }

  function getAllTask() external view returns( Task[] memory) {
    return tasks; 
  }

  function toggleTask(uint _id) external returns(bool){
    if(tasksMap[_id] == true){
      tasks[_id].isCompleted = !tasks[_id].isCompleted;
      emit Response(true, "Task is updated");
      return true;
    }
    else {
      emit Response(false, "Task is not Present in the Database");
      return false;
    }
  }

  function deleteTask(uint _id) external returns(bool){
    if(tasksMap[_id] == true){
      delete tasks[_id];
      delete tasksMap[_id];
      emit Response(true, "Task is Deleted");
      return true;
    }
    else {
      emit Response(false, "Task is not Present in the Database");
      return false;
    }
  }
}