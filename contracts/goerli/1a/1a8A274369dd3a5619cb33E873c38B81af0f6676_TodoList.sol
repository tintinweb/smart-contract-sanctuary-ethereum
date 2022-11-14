/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract TodoList{
 uint public taskCount;

 struct Task {
  uint id;   //unique for each task
  string content;// task to be performed 
  bool completed; // status of task
 }
 mapping(uint => Task) public tasks;

 constructor() {
  taskCount=0;
 }

 function AddTask(string memory _content) public{ // to add a new task
 
 tasks[taskCount] = Task(taskCount, _content, false);
 taskCount ++;

 }
 function MarkCompleteByTaskId(uint index)public{        // marks a specific task completed=true by index value
     require(tasks[index].completed==false,"Alreday marked finished");
     tasks[index].completed=true;

 }

   
 function RemoveTask(uint index) public{   //Remove specific task by index value
     require(taskCount!=0,"No task to remove");
     require(taskCount>=index,"No task to found");
     delete tasks[index];
     taskCount --;

 }
 function RemoveAllTask() public{           // removes all tasks
     require(taskCount!=0,"No task to remove");
     for (uint i = 0; i<taskCount; i++){
           delete tasks[i];
        }
     taskCount=0;

 }
}