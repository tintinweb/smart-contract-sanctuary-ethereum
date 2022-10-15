/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title RentManager
contract TodoApp {
    struct Task {
        uint8 currentStatus; // 0 = not started; 1 = in progress; 2 = completed.
        string title;
        string description;
        uint256 deadlineTimestamp;
        uint256 createdOnTimestamp;
        uint256 completedOnTimestamp;
    }

    /// @dev Mapping of no. of user tasks
    mapping (address => uint256) public taskBalance;

    /// @dev Mapping from user address to task id to Task details.
    mapping (address => mapping (uint256 => Task)) public tasks;

    event CreateTask(
        address who,
        uint256 id,
        string title, 
        string description, 
        uint256 deadlineTimestamp, 
        uint256 createdOnTimestamp
    );

    event CompleteTask(
        address who,
        uint256 id
    );

    event TaskInProgress(
        address who,
        uint256 id
    );


    function createTask(string memory title, string memory description, uint256 deadline) external {
        // Fetch the current task balance.
        uint256 taskId = taskBalance[msg.sender];
        // Create the new task.
        Task memory task = Task({
            currentStatus: 0,
            title: title,
            description: description,
            deadlineTimestamp: deadline,
            createdOnTimestamp: block.timestamp,
            completedOnTimestamp: 0
        });
        // Increment the taskBalance.
        taskId++;
        emit CreateTask(msg.sender, taskId, title, description, deadline, task.createdOnTimestamp);
        // Update the task balance and the enter the task as per the id.
        taskBalance[msg.sender] = taskId;
        tasks[msg.sender][taskId] = task;
    }

    function markTaskComplete(uint256 taskId) external {
       Task storage task = tasks[msg.sender][taskId];
       require(task.createdOnTimestamp != 0, "TASK_DOESNT_EXIST");
       require(task.currentStatus == 1, "TASK_NOT_IN_PROGRESS");

        emit CompleteTask(msg.sender, taskId);

        task.currentStatus = 2;
        task.completedOnTimestamp = block.timestamp;
    }

    function markTaskInProgress(uint256 taskId) external {
       Task storage task = tasks[msg.sender][taskId];
       require(task.createdOnTimestamp != 0, "TASK_DOESNT_EXIST");
       require(task.currentStatus == 0, "ALREADY_STARTED");

        emit TaskInProgress(msg.sender, taskId);

        task.currentStatus = 1;
    }
}