// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Todolist {

    // Event to emit when a Task is created.
    event newTask (
        string name,
        bool status
    );

    // structure to store a task
    struct Task {
        string name;
        bool status;
    }

    mapping (address => Task[]) private Tasks;

    /**
        addTask - This function adds the name of the sender to the
        Tasks
    */
    function addTask(string calldata _name) external {
        // Add the task to storage.
        Tasks[msg.sender].push(Task({
            name: _name,
            status: false
        }));

        // Emit a NewTask event with details about the task.
        emit newTask (
            _name,
            false
        );
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
        Tasks[msg.sender][_index].status = _status;
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