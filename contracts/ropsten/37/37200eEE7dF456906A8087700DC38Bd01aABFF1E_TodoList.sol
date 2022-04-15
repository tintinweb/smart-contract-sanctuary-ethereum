/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TodoList {
    mapping(address => User) private users;

    struct Task {
        uint id;
        address owner;
        string text;
        bool isCompleted;
        bool isDeleted;
        bool isOverdue;
        uint timeCreated;
        uint deadline;
    }

    struct User {
        uint tasksCount;
        mapping(uint => Task) tasks;
    }

    modifier checkDeadline(uint _taskNumber) {
        if (block.timestamp >= users[msg.sender].tasks[_taskNumber].deadline)
            users[msg.sender].tasks[_taskNumber].isOverdue = true;
        _;
    }

    modifier checkTaskNum(uint _taskNumber) {
        require(_taskNumber < users[msg.sender].tasksCount, "_taskNumber is greater than max task index!");
        _;
    }

    function createTask(string memory _text, uint _timeOverdue) public {
        uint taskNum = users[msg.sender].tasksCount;
        users[msg.sender].tasksCount++;

        users[msg.sender].tasks[taskNum] = Task({
            id: taskNum,
            owner: msg.sender,
            text: _text,
            isCompleted: false,
            isDeleted: false,
            isOverdue: false,
            timeCreated: block.timestamp,
            deadline: _timeOverdue
        });
    }

    function getAllTasks() public view returns(Task[] memory) {
        require(users[msg.sender].tasksCount > 0, "No tasks!");
        Task[] memory _tasks = new Task[](users[msg.sender].tasksCount);
        for (uint i = 0; i < users[msg.sender].tasksCount; i++) {
            _tasks[i] = users[msg.sender].tasks[i];
        }
        return _tasks;
    }

    function getTask(uint _taskNumber) public checkDeadline(_taskNumber) checkTaskNum(_taskNumber) returns(Task memory) {
        Task memory _task = users[msg.sender].tasks[_taskNumber];
        require(!_task.isDeleted, "Task is deleted!");
        return(_task);
    }

    function deleteTask(uint _taskNumber) checkTaskNum(_taskNumber) public {
        users[msg.sender].tasks[_taskNumber].isDeleted = true;
    }

    function undeleteTask(uint _taskNumber) checkTaskNum(_taskNumber) public {
        users[msg.sender].tasks[_taskNumber].isDeleted = false;
    }

    function toggleComplete(uint _taskNumber) checkTaskNum(_taskNumber) public {
        users[msg.sender].tasks[_taskNumber].isCompleted = !users[msg.sender].tasks[_taskNumber].isCompleted;
    }

    function getCompletionRate() public returns(uint) {
        require(users[msg.sender].tasksCount > 0, "No tasks!");
        uint completed = 0;
        uint rate = 0;
        for (uint i = 0; i < users[msg.sender].tasksCount; i++) {
            Task memory _task = getTask(i);
            if (_task.isCompleted && !_task.isOverdue)
                completed++;
        }
        rate = (100 * completed) / users[msg.sender].tasksCount;
        return rate;
    }
}