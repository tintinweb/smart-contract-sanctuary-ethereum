// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    enum Status { toDo, inProgress, done }

    struct Task {
        string name;
        uint256 endTask;
        bool isDeleted;
        bool isOverdue;
        Status statusTask;
    }

    struct User {
        uint256 id;
        mapping (uint256 => Task) tasks;
    }
    
    mapping(address => User) users;
       
    function set(string memory _name, uint256 _daysTodo) public {
        User storage user = users[msg.sender];
        uint256 id = users[msg.sender].id;

        user.tasks[id].name = _name;
        user.tasks[id].endTask = block.timestamp + _daysTodo * 1 days;

        users[msg.sender].id++;
    }

    function setStatusNotDone(uint256 _id) public {
        users[msg.sender].tasks[_id].statusTask = Status.toDo;
    }

    function setStatusDuring(uint256 _id) public {
        users[msg.sender].tasks[_id].statusTask = Status.inProgress;
    }

    function setStatusDone(uint256 _id) public {
        users[msg.sender].tasks[_id].statusTask = Status.done;
    }

    function getTask(uint256 _id) public view returns (Task memory) {
        return users[msg.sender].tasks[_id];
    }

    function taskInTime() public view returns (uint256) {
        User storage user = users[msg.sender];
        uint256 counter;

        for (uint i; i < user.id; i++) {
            if(!isOverdue(user.tasks[i]) && user.tasks[i].statusTask == Status.done) {
                counter++;
            }
        }

        return counter * 10000 / user.id;
    }

    function deleteTask(uint256 _id) public {
        users[msg.sender].tasks[_id].isDeleted = true;
    }

    function getUser(address) public view returns (uint256) {
        return users[msg.sender].id;
    }

    function isOverdue(Task memory _task) public view returns (bool) {
        if(block.timestamp >= _task.endTask) {
            _task.isOverdue = true;
        }

        return _task.isOverdue;
    }
}