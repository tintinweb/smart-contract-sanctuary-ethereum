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

    struct User {
        uint256 id;
        mapping(uint256 => Task) tasks;
    }
    
    mapping(address => User) users;

    error functionInvalidAtThisStage();

    event UserTask(address indexed users_, string name_, uint256 data_);
    event DeleteTask(address indexed users_, string name_, uint256 indexed id_);

    modifier atStage(Status stage_, uint256 id_) {
        if (users[msg.sender].tasks[id_].statusTask != stage_) {
            revert functionInvalidAtThisStage();
        }
        
        _;
    }
       
    modifier stageNext(uint256 id_) {
        _;
        nextStage(id_);
    }

    function setTask(
        string memory name_, 
        uint256 daysTodo_
    ) 
        external 
        stageNext(users[msg.sender].id) 
        {
        User storage user = users[msg.sender];
        users[msg.sender].id++;
        uint256 id = users[msg.sender].id;

        user.tasks[id] = Task({name: name_, isDeleted: false, isOverdue: false, endTask: daysTodo_, statusTask:Status.NotCreatedYetTask});
       
        users[msg.sender].id++;

        emit UserTask(msg.sender, name_, daysTodo_);
    }

    function setStatusToDo(uint256 id_) external atStage(Status.AddTask, id_) {
        users[msg.sender].tasks[id_].statusTask = Status.ToDo;
    }

    function setStatusInProgress(uint256 id_) external atStage(Status.AddTask, id_)  {
        users[msg.sender].tasks[id_].statusTask = Status.RealizationTask;
    }

    function setStatusDone(uint256 id_) external atStage(Status.RealizationTask, id_) {
        users[msg.sender].tasks[id_].statusTask = Status.DoneTask;
    }

     function deleteTask(uint256 id_) external atStage(Status.DoneTask, id_) {
        users[msg.sender].tasks[id_].isDeleted = true;

        emit DeleteTask(msg.sender, users[msg.sender].tasks[id_].name, id_);
    }

    function nextStage(uint256 id_) internal {
         users[msg.sender].tasks[id_].statusTask = Status(uint(users[msg.sender].tasks[id_].statusTask) + 1);
    }

    function getTask(uint256 id_) external view returns (Task memory) {
        //require(users[msg.sender].id != 0, "invalid id");
        
        return users[msg.sender].tasks[id_];
    }

    function taskInTime() external view returns (uint256) {
        User storage user = users[msg.sender];
        uint256 counter;

        assert(user.id != 0);

        for (uint i; i < user.id; i++) {
            if (!isOverdue(user.tasks[i]) && user.tasks[i].statusTask == Status.DoneTask) {
                counter++;
            }
        }

        return counter * 10000 / user.id;
    }

    function getUser(address) external view  returns (uint256) {
        require(msg.sender != address(0));

        return users[msg.sender].id;
    }

    function isOverdue(Task memory task_) public view returns (bool) {
        if (block.timestamp >= task_.endTask) {
            task_.isOverdue = true;
        }

        return task_.isOverdue;
    }
}