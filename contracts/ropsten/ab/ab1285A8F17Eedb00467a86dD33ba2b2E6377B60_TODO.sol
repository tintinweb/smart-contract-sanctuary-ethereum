/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0
// Vsevolod Medvedev, 2022, for iLink

pragma solidity >=0.7.0 <0.9.0;

contract TODO {
    enum Status { Pending, Completed }

    struct Task {
        uint id;
        address owner;
        uint createdTime;
        uint estimatedTimeInSeconds;
        Status status;
        bool isDeleted;
        bool isCompletedInTime;
    }

    Task[] tasks;
    mapping (address => uint) public userToTasksCompletedInTimePercent;

    event TaskCreated(uint id, address owner, uint createdTime, uint estimatedTimeInSeconds);
    event TaskCompleted(uint id, bool inTime);
    event TaskDeleted(uint id);

    modifier ownerOnly(uint _id) {
        require(tasks[_id].owner == msg.sender, "Only owner can modify a task");
        _;
    }

    modifier notDeleted(uint _id) {
        require(!tasks[_id].isDeleted, "The task was deleted previously");
        _;
    }

    function createTask(uint _estimatedTimeInSeconds) public {
        uint id = tasks.length;
        uint createdTime = block.timestamp;
        Task memory task = Task(id, msg.sender, createdTime, _estimatedTimeInSeconds, Status.Pending, false, false);
        tasks.push(task);
        _updateUserToTasksCompletedInTimePercent(msg.sender);
        emit TaskCreated(task.id, task.owner, task.createdTime, task.estimatedTimeInSeconds);
    }

    function getTask(uint _id) public view notDeleted(_id) returns (Task memory) {
        return tasks[_id];
    }

    function listTasks() public view returns (Task[] memory) {
        uint size = 0;
        for (uint i = 0; i < tasks.length; i++) {
            if (!tasks[i].isDeleted) {
                size++;
            }
        }
        Task[] memory filtered = new Task[](size);
        uint j = 0;
        for (uint i = 0; i < tasks.length; i++) {
            if (!tasks[i].isDeleted) {
                filtered[j] = tasks[i];
                j++;
            }
        }
        return filtered;
    }

    function deleteTask(uint _id) public ownerOnly(_id) notDeleted(_id) {
        tasks[_id].isDeleted = true;
        _updateUserToTasksCompletedInTimePercent(msg.sender);
        emit TaskDeleted(_id);
    }

    function changeTaskStatus(uint _id, Status _status) public ownerOnly(_id) notDeleted(_id) {
        Task storage task = tasks[_id];
        if (_status == task.status) {
            return;
        }
        task.status = _status;
        if (_status == Status.Completed) {
            task.isCompletedInTime = block.timestamp <= task.createdTime + task.estimatedTimeInSeconds;
            _updateUserToTasksCompletedInTimePercent(msg.sender);
            emit TaskCompleted(_id, task.isCompletedInTime);
        }
    }

    function _updateUserToTasksCompletedInTimePercent(address _user) private {
        uint inTimeCount = 0;
        uint completedCount = 0;
        for (uint i = 0; i < tasks.length; i++) {
            Task memory task = tasks[i];
            if (!task.isDeleted && task.owner == _user) {
                if (task.status == Status.Completed) {
                    completedCount++;
                }
                if (task.isCompletedInTime) {
                    inTimeCount++;
                }
            }
        }
        uint percent;
        if (completedCount == 0) {
            percent = 0;
        } else {
            percent = inTimeCount * 100 / completedCount;
        }
        userToTasksCompletedInTimePercent[_user] = percent;
    }
}