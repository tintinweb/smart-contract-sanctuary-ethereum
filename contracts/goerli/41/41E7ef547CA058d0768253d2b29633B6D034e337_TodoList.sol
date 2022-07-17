// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    uint256 public taskCount = 0;

    struct Task {
        uint256 idx;
        string content;
        bool completed;
    }

    mapping(uint256 => Task) public tasks;

    constructor() {
        createTask("Check out https://github.com/memochou1993");
    }

    function createTask(string memory _content) public {
        uint256 _idx = taskCount;
        tasks[_idx] = Task(_idx, _content, false);
        taskCount++;
        emit TaskCreated(_idx, tasks[_idx]);
    }

    function updateTask(uint256 _idx, bool _completed) public {
        Task memory _task = tasks[_idx];
        _task.completed = _completed;
        tasks[_idx] = _task;
        emit TaskUpdated(_idx, _task);
    }

    event TaskCreated(uint256 idx, Task task);
    event TaskUpdated(uint256 idx, Task task);
}