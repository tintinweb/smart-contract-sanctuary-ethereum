// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract TaskContract {
    event AddTask(address recipient, uint taskId);
    event DeleteTask(uint taskId, bool isDeleted);
    event UpdateTask(uint taskId, string taskTitle, string taskDescription, string taskStatus);

    enum Status {
        Todo,
        Pending,
        Completed
    }

    struct Task {
        uint id;
        string title;
        string description;
        string status;
        bool isDeleted;
    }
 
    uint256 constant NULL = 0;


    // stores tasks
    Task[] private tasks;

    mapping(uint256 => address) taskToOwner;

    function addTask(
        string memory title,
        string memory description,
        string memory status,
        bool isDeleted
    ) external {
        uint taskId = tasks.length;
        tasks.push(Task(taskId, title, description, status, isDeleted));
        taskToOwner[taskId] = msg.sender;
        emit AddTask(msg.sender, taskId);
    }

    function updateTask(
        uint taskId,
        string memory title,
        string memory description,
        string memory status
    ) external {
        Task storage task = tasks[taskId];
        task.title = title;
        task.description = description;
        task.status = status;
        emit UpdateTask(taskId, title, description, status);
    }

    function getMyTasks() external view returns (Task[] memory) {
        Task[] memory temporary = new Task[](tasks.length);
        uint counter = 0;
        for (uint i = 0; i < tasks.length; i++) {
            if (taskToOwner[i] == msg.sender && tasks[i].isDeleted == false) {
                temporary[counter] = tasks[i];
                counter++;
            }
        }
        Task[] memory result = new Task[](counter);
        for (uint i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function deleteTask(uint taskId, bool isDeleted) external {
        if (taskToOwner[taskId] == msg.sender) {
            tasks[taskId].isDeleted = isDeleted;
            emit DeleteTask(taskId, isDeleted);
        }
    }
}