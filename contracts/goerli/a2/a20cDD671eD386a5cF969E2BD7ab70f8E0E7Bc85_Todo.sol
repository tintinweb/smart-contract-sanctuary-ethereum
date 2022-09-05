// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9; 

contract Todo{
    
struct Task{
  string task;
  bool isDone; //boolean to tell whether the task is completed or not
}
 
mapping (address => Task[]) public Users; // Create a mapping to store task array with an associated user address
      
// Defining function to add a task
function addTask(string calldata _task) external {
  Users[msg.sender].push(Task({ //The push method to add the task to the mapping.
    task: _task,
    isDone: false
}));
}
 
// Defining a function to get details of a task 
function getTask(uint _taskId) external view returns (Task memory){
  Task storage task = Users[msg.sender][_taskId];
  return task;
}
   
// Defining a function to update status of a task
function updateStatus(uint256 _taskId,bool _status) external{
  Users[msg.sender][_taskId].isDone = _status;
}
   
// Defining a function to delete a task
//deleteTask method will take the task index and then delete the element from the array.after
function deleteTask(uint256 _taskIndex) external {
  delete Users[msg.sender][_taskIndex];
}
   
// Defining a function to get task count.
//This will help to get the count of tasks can be retrieved as the task array length
function getTaskCount() external view returns (uint256){
  return Users[msg.sender].length;
} 
}