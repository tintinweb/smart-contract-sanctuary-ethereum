// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    uint256 public taskCount = 0;

    struct Task {
        uint256 idx;
        string content;
        bool completed;
    }

    Task[] public tasks;

    constructor() {
        createTask("Check out https://github.com/memochou1993");
    }

    function getTasks()
        external
        view
        returns (Task[] memory)
    {
        return tasks;
    }

    function createTask(string memory _content) public {
        uint256 _idx = taskCount;
        tasks.push(Task(_idx, _content, false));
        taskCount++;
        emit TaskCreated(_idx, tasks[_idx]);
    }

    function updateTask(uint256 _idx, bool _completed) public {
        tasks[_idx].completed = _completed;
        emit TaskUpdated(_idx, tasks[_idx]);
    }

    event TaskCreated(uint256 idx, Task task);
    event TaskUpdated(uint256 idx, Task task);
}