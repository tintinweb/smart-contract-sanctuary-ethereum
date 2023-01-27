// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Todolist {
    // structure to store a task
    struct Task {
        string name;
        bool status;
        uint timestamp;
    }

    mapping (address => Task[]) private Tasks;

    /**
        addTask - This function adds the name of the sender to the
        Tasks
    */
    function addTask(string calldata _name) public {
        // Add the task to storage.
        Tasks[msg.sender].push(Task({
            name: _name,
            status: false,
            timestamp: block.timestamp
        }));
    }

    /**
        updateStatus - This function update status of a task
    */
    function updateStatus(uint256 _index) public {
        Tasks[msg.sender][_index].status = !Tasks[msg.sender][_index].status;
    }

    /**
        deleteTask - This function delete of a task
    */
    function deleteTask(uint256 _index) public {
        delete Tasks[msg.sender][_index];
    }

    /**
        getTasks - This function get the tasks
    */
    function getTasks() public view returns (Task[] memory) {
        Task[] memory listTask = new Task[](Tasks[msg.sender].length);
        
        uint i = 0;
        for (uint taskId = 0; taskId < Tasks[msg.sender].length; taskId++) {
            listTask[i] = Tasks[msg.sender][taskId];
            i++;
        }

        return listTask;
    }
}