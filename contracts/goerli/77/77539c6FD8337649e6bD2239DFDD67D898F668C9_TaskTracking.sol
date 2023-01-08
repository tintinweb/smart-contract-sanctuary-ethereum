// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract TaskTracking {
    address public taskListOwner;
    uint16 public totalTasks = 0;
    mapping(uint16 => Task) public taskList;

    struct Task {
        uint16 taskId;
        string taskName;
        bool taskCompleted;
        uint256 taskCompletedTime;
    }

    constructor() payable {
        taskListOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == taskListOwner,
            "Only the Task List Owner may update this Task"
        );
        _;
    }

    function createTask(string memory taskText) public onlyOwner {
        taskList[totalTasks] = Task(totalTasks, taskText, false, 0);
        totalTasks += 1;
    }

    function editTask(uint16 taskId, string memory taskText) public onlyOwner {
        // Update Task name to tastText
        taskList[taskId].taskName = taskText;

        // Clear completed time and set completed to false
        taskList[taskId].taskCompletedTime = 0;
        taskList[taskId].taskCompleted = false;
    }

    function toggleTask(uint16 taskId) public onlyOwner {
        // Toggle the Task Completion Flag
        taskList[taskId].taskCompleted = !taskList[taskId].taskCompleted;

        // Set or Clear the Completed Time
        if (taskList[taskId].taskCompleted) {
            taskList[taskId].taskCompletedTime = block.timestamp;
        } else {
            taskList[taskId].taskCompletedTime = 0;
        }
    }
}