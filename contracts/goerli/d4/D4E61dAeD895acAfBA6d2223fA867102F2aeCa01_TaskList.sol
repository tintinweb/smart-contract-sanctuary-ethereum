/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


contract TaskList {
  uint public taskCount = 0;
  uint public taskHistoryCount = 0;

  enum PriorityLevels { low, medium, high, urgent }
  PriorityLevels priorityLevels;

  struct Task {
    uint taskId;
    string content;
    bool completed;
    PriorityLevels priority;
    uint deadlineDateTime;
    uint createdOn;
    uint updatedOn;
    uint blockNumber;
    bytes32 blockHash;
  }

  struct TaskHistory {
    uint historyId;
    uint taskId;
    string content;
    bool completed;
    PriorityLevels priority;
    uint deadlineDateTime;
    uint createdOn;
    uint updatedOn;
    uint blockNumber;
    bytes32 blockHash;
  }
  
  mapping(uint => Task) public tasks;
  mapping(uint => TaskHistory) public tasks_History;
  
  event TaskCreated(
      uint taskId,
      string content,
      bool completed,
      uint deadlineDateTime
  );

  event TaskFileCreated(
      uint fileId,
      uint taskId
  );

  event TaskToggle(
      uint taskId,
      bool completed
  );

  event TaskPriorityChanged(
      uint taskId,
      PriorityLevels priority
  );

  event TaskDeadlineChanged(
      uint taskId,
      uint deadlineDate
  );


  function createTask(string memory _content) public {
    taskCount ++;
    tasks[taskCount] = Task(taskCount, _content, false, PriorityLevels.medium, 0, (block.timestamp), (block.timestamp), block.number, (blockhash(block.number)));
  
    logTaskHistory(tasks[taskCount]);

    emit TaskCreated(taskCount, _content, false, 0);
  }

  // function createTaskWithPriority(string memory _content, PriorityLevels _priority) public {
  //   taskCount ++;
  //   tasks[taskCount] = Task(taskCount, _content, false, _priority, 0, (block.timestamp), (block.timestamp), block.number, (blockhash(block.number)));
  
  //   logTaskHistory(tasks[taskCount]);

  //   emit TaskCreated(taskCount, _content, false);
  // }

  function createTaskDeadline(string memory _content, uint _deadlineDateTime) public {
    taskCount ++;
    
    tasks[taskCount] = Task(taskCount, _content, false, PriorityLevels.medium, _deadlineDateTime, (block.timestamp), (block.timestamp), block.number, (blockhash(block.number)));
  
    logTaskHistory(tasks[taskCount]);

    emit TaskCreated(taskCount, _content, false, _deadlineDateTime);
  }

  function logTaskHistory(Task memory tk) private {
      taskHistoryCount++;
      tasks_History[taskHistoryCount] = TaskHistory(taskHistoryCount, tk.taskId, tk.content, tk.completed, tk.priority, tk.deadlineDateTime, (block.timestamp), (block.timestamp), block.number, (blockhash(block.number)));
  }

  function changeTaskPriority(uint _taskId, PriorityLevels _priority) public{
        Task memory _task = tasks[_taskId];
        _task.priority = _priority;
        _task.updatedOn = uint32(block.timestamp);
        tasks[_taskId] = _task;

        logTaskHistory(_task);
        emit TaskPriorityChanged(_taskId, _task.priority);
    }
  
  function changeTaskDeadlineDate(uint _taskId, uint _deadlineDate) public{
        Task memory _task = tasks[_taskId];
        _task.deadlineDateTime = _deadlineDate;
        _task.updatedOn = uint32(block.timestamp);
        tasks[_taskId] = _task;

        logTaskHistory(_task);
        emit TaskDeadlineChanged(_taskId, _task.deadlineDateTime);
    }

 
  function toggleTask(uint _taskId) public{
        Task memory _task = tasks[_taskId];
        _task.completed = !_task.completed;
        _task.updatedOn = (block.timestamp);
        tasks[_taskId] = _task;

        logTaskHistory(_task);
        emit TaskToggle(_taskId, _task.completed);
    }

 

  function getTaskIsOverdue(uint _taskId) public view returns(bool) {
      Task memory tk = tasks[_taskId];
      bool isOverdue = false;
      if (tk.completed == false) {
        if (tk.deadlineDateTime < block.timestamp)  {
            isOverdue = true;
        }
      } else {
        isOverdue = false;
      }
      return isOverdue;
      
  }

  function getAllPriorityLevels() public view returns(PriorityLevels) {
    return priorityLevels;
  }

  function getAllTasks() public view returns (Task[] memory) {
    Task[] memory id = new Task[](taskCount);
    for (uint i = 0; i < taskCount; i++) {
          Task storage tk = tasks[i+1];
          id[i] = tk;
      }
      return id;
  }

  // function getAllTasksHistory() public view returns (TaskHistory[] memory) {
    
  //     TaskHistory[] memory id = new TaskHistory[](taskHistoryCount);
      
      
  //       for (uint i = 0; i < taskHistoryCount; i++) {
  //           TaskHistory storage th = tasks_History[i+1];
  //           id[i] = th;
  //       }
      
  //     return id;
  // }

  function getAllTasksHistoryForTask(uint _taskId) public view returns (TaskHistory[] memory) {
    uint countMatch = 0;
    for (uint i = 0; i < taskHistoryCount; i++) {
          TaskHistory storage th = tasks_History[i+1];
          if (th.taskId == _taskId) {
            countMatch++;
          }
      }

      TaskHistory[] memory id = new TaskHistory[](countMatch);
      if (taskHistoryCount > 0) {
        uint j = 0;
        for (uint i = 0; i < taskHistoryCount; i++) {
            TaskHistory storage th = tasks_History[i+1];
            if (th.taskId == _taskId) {
              if (j <= countMatch) {
                id[j] = th;
                j++;
              }
            }
        }
      }
      return id;
  }

}