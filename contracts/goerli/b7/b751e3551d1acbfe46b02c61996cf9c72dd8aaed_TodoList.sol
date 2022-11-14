/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// File: Todo.sol

pragma solidity ^0.5.0;
 
contract TodoList {
  uint public taskCount = 0;
  constructor() public {
        createTask("initialise create task todo list");
      }
  struct Task {
    uint id;
    string content;
    bool completed;
  }
  mapping(uint => Task) public tasks;
  function createTask(string memory _content) public {
    taskCount ++;
    tasks[taskCount] = Task(taskCount, _content, false);
  }
}