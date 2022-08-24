/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TodoContract {
  
  event AddTask(address recipient, uint taskId);
  event DeleteTask(uint taskId, bool isDeleted);

  struct Task {
    uint id;
    string taskText;
    bool isDeleted;
  }

  Task[] private tasks;

  mapping(uint => address) taskToOwner;

  function addTask(string memory _taskText, bool isDeleted) external {
    uint taskId = tasks.length;
    tasks.push(Task(taskId, _taskText, isDeleted));
    taskToOwner[taskId] = msg.sender;
    emit AddTask(msg.sender ,taskId);
  }

  function getMyTasks() external view returns (Task[] memory) {
    Task[] memory bufferTask = new Task[](tasks.length);
    uint counter = 0;
    //Loop to find the owner address
    for (uint i=0; i<tasks.length; i++) {
      if (taskToOwner[i] == msg.sender && tasks[i].isDeleted == false) {
        bufferTask[counter] = tasks[i];
        counter++;
      }
    }
    //But don't want to return all length of task array just msg.semder's tasks
    Task[] memory ownerTasks = new Task[](counter);
    for (uint i=0; i<counter; i++) {
      ownerTasks[i] = bufferTask[i];
    }

    return ownerTasks;
  }

  function delTask(uint _taskId, bool mybool) external {
    if (msg.sender == taskToOwner[_taskId]) {
      tasks[_taskId].isDeleted = mybool;
      emit DeleteTask(_taskId, mybool);
    }
  } 
  
}