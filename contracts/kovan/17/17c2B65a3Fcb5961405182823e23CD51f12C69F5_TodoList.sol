// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Task {
        uint256 id;
        string content;
        bool completed;
    }

    Task[] public tasks;

    constructor() public {
        createTask("Initialize TodoList");
    }

    function createTask(string memory _content) public {
        uint256 taskId = tasks.length;
        tasks.push(Task(taskId, _content, false));
    }

    function getTasksCount() public view returns (uint256) {
        return tasks.length;
    }

    function completeTask(uint256 _id) public {
        tasks[_id].completed = true;
    }
}