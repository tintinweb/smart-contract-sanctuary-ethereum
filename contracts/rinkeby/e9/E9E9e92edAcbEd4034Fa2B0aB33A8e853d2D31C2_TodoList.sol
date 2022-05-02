/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity >=0.4.22 <0.9.0;
contract TodoList {
  uint public taskCount = 0;

  struct Task {
    uint id;
    string content;
    bool completed;
  }
  constructor() public 
  {
      createTask("Buy Coffee!!");
  }

  mapping(uint => Task) public tasks;

  function createTask(string memory _content) public {
    taskCount ++;
    tasks[taskCount] = Task(taskCount, _content, false);
  }

}