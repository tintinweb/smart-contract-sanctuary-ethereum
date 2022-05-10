// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    enum Status { 
        NotCreatedYetTask,
        AddTask,
        ToDo, 
        RealizationTask, 
        DoneTask 
    }

    struct Task {
        string name;
        uint256 endTask;
        bool isDeleted;
        bool isOverdue;
        Status statusTask;
    }

    mapping(address => uint256) public ids;
    mapping(address => mapping(uint256 =>Task)) public tasks;

    error functionInvalidAtThisStage();

    event UserTask(address indexed users_, string name_, uint256 data_);
    event DeleteTask(address indexed users_, string name_, uint256 indexed id_);

    modifier atStage(Status stage_, uint256 id_) {
        if (tasks[msg.sender][id_].statusTask != stage_) {
            revert functionInvalidAtThisStage();
        }
        
        _;
    }
       
    modifier stageNext(uint256 id_) {
        _;
        nextStage(id_);
    }

    function setTask(string memory name_, uint256 daysTodo_) external stageNext(ids[msg.sender]) {
        Task storage task = tasks[msg.sender][ids[msg.sender]];

        task.name = name_;
        task.endTask = block.timestamp + daysTodo_ * 1 days;

        ids[msg.sender]++;

        emit UserTask(msg.sender, name_, daysTodo_);
    }

    function setStatusToDo(uint256 id_) external atStage(Status.AddTask, id_) {
        tasks[msg.sender][id_].statusTask = Status.ToDo;
    }

    function setStatusInProgress(uint256 id_) external atStage(Status.AddTask, id_)  {
        tasks[msg.sender][id_].statusTask = Status.RealizationTask;
    }

    function setStatusDone(uint256 id_) external atStage(Status.RealizationTask, id_) {
        tasks[msg.sender][id_].statusTask = Status.DoneTask;
    }

    function deleteTask(uint256 id_) external atStage(Status.DoneTask, id_) {
        tasks[msg.sender][id_].isDeleted = true;

        emit DeleteTask(msg.sender, tasks[msg.sender][id_].name, id_);
    }

    function nextStage(uint256 id_) internal {
        tasks[msg.sender][id_].statusTask = Status(uint(tasks[msg.sender][id_].statusTask) + 1);
    }

    function getTask(uint256 id_) external view returns (Task memory) {
       // require(ids[msg.sender] != 0, "invalid id");
        
        return tasks[msg.sender][id_];
    }

    function taskInTime() external view returns (uint256) {
        uint256 counter;

        assert(ids[msg.sender] != 0);

        for (uint i; i < ids[msg.sender]; i++) {
            if (!isOverdue(tasks[msg.sender][i]) && tasks[msg.sender][i].statusTask == Status.DoneTask) {
                counter++;
            }
        }

        return counter * 10000 / ids[msg.sender];
    }

    function getUser(address) external view  returns (uint256) {
        require(msg.sender != address(0), "invalid address");

        return ids[msg.sender];
    }

    function isOverdue(Task memory task_) public view returns (bool) {
        if (block.timestamp >= task_.endTask) {
            task_.isOverdue = true;
        }

        return task_.isOverdue;
    }
}