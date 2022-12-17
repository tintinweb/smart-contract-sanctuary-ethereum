// SPDX-License-Identifier: NONE
pragma solidity ^0.8.5;

// Creare todo [x]
// Modificare todo [x]
contract Todo {
    struct Task {
        string taskName;
        address creator;
        bool status;
        uint id;
    }

    Task[] public tasksArray;
    mapping(uint => Task) public tasks;

    function createTask(string memory _taskName) public {
        Task memory newTask = Task({
            taskName: _taskName,
            creator: msg.sender,
            status: false,
            id: tasksArray.length
        });
        tasks[newTask.id] = newTask;
        tasksArray.push(newTask);
    }

    function updateStatus(uint taskId) public {
        Task storage task = tasks[taskId];
        task.status = true;
    }

    function deleteTask(uint taskId) public {
        Task memory task = tasks[taskId];
        require(task.status == true, "Try to complete it before deleting it");
        delete (tasks[taskId]);
        delete (tasksArray[taskId]);
    }
}