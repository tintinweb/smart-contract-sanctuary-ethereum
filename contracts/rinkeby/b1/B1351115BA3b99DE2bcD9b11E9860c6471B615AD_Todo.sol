// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

enum Status {
  TODO,
  IN_PROGRESS,
  DONE,
  CANCELLED
}

struct Task {
  string title;
  string description;
  Status status;
}

contract Todo {
  uint256 numberOfTasks = 0;
  mapping(uint256 => Task) tasks;
  mapping(address => uint256[]) userToTasksMapping;

  function addTask (string memory title, string memory description) public {
    require(bytes(title).length != 0, '[Todo Error] Title should not be empty.');
    require(bytes(description).length != 0, '[Todo Error] Description should not be empty.');
    numberOfTasks++;

    tasks[numberOfTasks] = Task({
      title: title,
      description: description,
      status: Status.TODO
    });

    userToTasksMapping[msg.sender].push(numberOfTasks);
  }

  function getTaskDetailsById (uint256 id) public view returns (Task memory) {
    return tasks[id];
  }

  function getTaskByUser (address addr) public view returns (Task[] memory) {
    uint256[] memory listOfTasks = userToTasksMapping[addr];
    Task[] memory output = new Task[](listOfTasks.length);
    
    for (uint256 i=0; i<listOfTasks.length; i++) {
      output[i] = tasks[listOfTasks[i]];
    }

    return output;
  }

  function updateStatusToInProgress (uint256 id) public {
    require(tasks[id].status == Status.TODO, '[Todo Error] This task is not in todo status.');
    tasks[id].status = Status.IN_PROGRESS;
  }

  function updateStatusToDone (uint256 id) public {
    require(tasks[id].status == Status.TODO, '[Todo Error] This task is not in progress status.');
    tasks[id].status = Status.DONE;
  }

  function updateStatusToCancelled (uint256 id) public {
    require(tasks[id].status != Status.DONE, '[Todo Error] This task has already been completed.');
    tasks[id].status = Status.CANCELLED;
  }

  function updateTaskContent (uint256 id, string memory title, string memory description) public {
    if (bytes(title).length != 0) {
      tasks[id].title = title;
    }

    if (bytes(description).length != 0) {
      tasks[id].description = description;
    }
  }
  
  // Should not use this function. If want to void a task, use updateStatusToCancelled and create a new task.
  function deleteTask (uint256 id) public {
    delete tasks[id];
  }
}