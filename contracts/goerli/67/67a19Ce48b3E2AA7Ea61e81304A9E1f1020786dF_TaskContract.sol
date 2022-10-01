// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TaskContract {
    event AddTask(address recipient, uint16 taskId);
    event DeleteTask(uint16 taskId, bool isDeleted);
    event UpdateTask(
        address recipient,
        string taskTitle,
        string taskDescription
    );

    struct Task {
        uint16 taskId;
        string taskTitle;
        string taskDescription;
        bool isDeleted;
    }

    Task[] private tasks;

    mapping(uint16 => address) taskToOwner;

    // FUNCTIONS

    // Get all the tasks
    function getTasks() external view returns (Task[] memory) {
        Task[] memory tempTasks = new Task[](tasks.length);
        uint16 counter = 0;
        for (uint16 i = 0; i < tasks.length; i++) {
            if (taskToOwner[i] == msg.sender && !tasks[i].isDeleted) {
                tempTasks[counter] = tasks[i];
                counter++;
            }
        }

        Task[] memory actualTasks = new Task[](counter);
        for (uint16 i = 0; i < counter; i++) {
            actualTasks[i] = tempTasks[i];
        }
        return actualTasks;
    }

    // Add a new task
    function addTask(
        string memory _taskTitle,
        string memory _taskDescription,
        bool _isDeleted
    ) external {
        uint16 _taskId = uint16(tasks.length);
        tasks.push(
            Task({
                taskId: _taskId,
                taskTitle: _taskTitle,
                taskDescription: _taskDescription,
                isDeleted: _isDeleted
            })
        );
        taskToOwner[_taskId] = msg.sender;
        emit AddTask(msg.sender, _taskId);
    }

    // Get a single task
    function getTask(uint16 _taskId) external view returns (Task memory) {
        return tasks[_taskId];
    }

    // Update a task
    function updateTask(
        uint16 _taskId,
        string memory _taskTitle,
        string memory _taskDescription
    ) external {
        tasks[_taskId].taskTitle = _taskTitle;
        tasks[_taskId].taskDescription = _taskDescription;
    }

    // Delete a task
    function deleteTask(uint16 _taskId, bool _isDeleted) external {
        if (taskToOwner[_taskId] == msg.sender) {
            tasks[_taskId].isDeleted = _isDeleted;
            emit DeleteTask(_taskId, _isDeleted);
        }
    }
}