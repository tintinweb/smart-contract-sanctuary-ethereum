// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Todolist {
    
    // Defining a structure to store a task
    struct Task {
        string nameTask;
        bool isDone;
    }

    mapping (address => Task[]) private Tasks;

    /**
        addTask - This function adds the nameTask of the sender to the
        Tasks
    */
    function addTask(string calldata _nameTask) external {
        // 
        Tasks[msg.sender].push(Task({
            nameTask: _nameTask,
            isDone: false
        }));
    }

    /**
        getTasks - This function get the tasks
    */
    function getTasks() external view returns (Task[] memory) {
        return Tasks[msg.sender];
    }

    /**
        updateStatus - This function update status of a task
    */
    function updateStatus(uint256 _index, bool _status) external {
        Tasks[msg.sender][_index].isDone = _status;
    }

    /**
        deleteTask - This function delete of a task
    */
    function deleteTask(uint256 _index) external {
        delete Tasks[msg.sender][_index];
    }

    /**
        getTaskCount - This function get task count
    */
    function getTaskCount() external view returns (uint256) {
        uint256 counts = Tasks[msg.sender].length;
        return counts;
    }

}