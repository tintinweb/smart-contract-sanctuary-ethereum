// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error TodoList__TaskNameMinimumThree();
error TodoList__TaskIndexInvalid();

contract TodoList {
    
    /*----Type declarations-----*/
    enum TaskStatus {PENDING, DONE}
    
    struct Task {
        string taskName;
        TaskStatus taskStatus; 
    }

    /*-----Variables-----*/
    mapping (address => Task[]) taskList;

    /*-----Functions-----*/
    constructor() {
        // For this contract, constructor is not need ..!
    }

    function addTask(string memory taskName) public {
        if( bytes(taskName).length < 3) {
            revert TodoList__TaskNameMinimumThree();
        }
        taskList[msg.sender].push(Task(taskName,TaskStatus.PENDING));
    }


    // task name rewrite
    function editTaskName(uint256 taskIndex, string memory taskName) public {
        if(taskIndex < 0 || taskIndex >= getTaskListLength() ){
            revert TodoList__TaskIndexInvalid();
        }
        if( bytes(taskName).length < 3) {
            revert TodoList__TaskNameMinimumThree();
        }
        taskList[msg.sender][taskIndex].taskName = taskName;
    }

    // task Status update
    function editTaskStatus(uint256 taskIndex) public {
        if(taskIndex < 0 || taskIndex >= getTaskListLength() ){
            revert TodoList__TaskIndexInvalid();
        }
        if(taskList[msg.sender][taskIndex].taskStatus == TaskStatus.DONE){
            taskList[msg.sender][taskIndex].taskStatus = TaskStatus.PENDING;
        } else {
            taskList[msg.sender][taskIndex].taskStatus = TaskStatus.DONE;
        }
    }

    function taskDelete(uint256 taskIndex) public {
        if(taskIndex < 0 || taskIndex >= getTaskListLength() ){
            revert TodoList__TaskIndexInvalid();
        }
        uint256 lenght = getTaskListLength();
        for(uint256 i = taskIndex; i < lenght-1 ; i++) {
            taskList[msg.sender][i] = taskList[msg.sender][i+1];
        }
        taskList[msg.sender].pop();
    }

    /*-----get/pure Funcions-----*/
    function getAddressTaskList() public view returns(Task[] memory) {
        return taskList[msg.sender];
    }
    function getTaskWithIndex(uint256 taskIndex) public view returns(Task memory) {
        if(taskIndex < 0 || taskIndex >= getTaskListLength() ){
            revert TodoList__TaskIndexInvalid();
        }
        return taskList[msg.sender][taskIndex];
    }
    function getTaskListLength() public view returns(uint256) {
        return taskList[msg.sender].length;
    }
}