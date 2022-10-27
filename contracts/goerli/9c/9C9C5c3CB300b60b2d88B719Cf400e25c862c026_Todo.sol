/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

error Todo__NotAuthorized();

contract Todo {
    /* Type Declarations */

    /* State Variables */
    struct Task {
        uint256 id;
        string text;
        bool isDone;
        uint256 modifiedCount;
    }

    Task[] private tasks;
    mapping(uint256 => address) taskOwnerByTaskId;

    /* Events */
    event AddTask(address indexed wallet, uint256 indexed taskId);
    event CompleteTask(uint256 indexed taskId, bool indexed isDone);
    event ModifyTask(uint256 indexed taskId, bool indexed isChanged);

    /* Functions */
    function addTask(string calldata _text, bool _isDone) external {
        uint256 taskId = tasks.length;
        tasks.push(Task(taskId, _text, _isDone, 0));
        taskOwnerByTaskId[taskId] = msg.sender;

        emit AddTask(msg.sender, taskId);
    }

    function doneTask(uint256 _taskId, bool _isDone) external {
        if (taskOwnerByTaskId[_taskId] != msg.sender) {
            revert Todo__NotAuthorized();
        }
        tasks[_taskId].isDone = _isDone;

        emit CompleteTask(_taskId, _isDone);
    }

    /* Getters */
    function getTask() external view returns (Task[] memory) {
        Task[] memory pendingTasksOfOwner = new Task[](tasks.length);
        uint256 index = 0;

        for (uint256 i = 0; i < tasks.length; i++) {
            if (
                taskOwnerByTaskId[i] == msg.sender && tasks[i].isDone == false
            ) {
                pendingTasksOfOwner[index] = tasks[i];
                index++;
            }
        }

        Task[] memory data = new Task[](index);
        for (uint256 i = 0; i < index; i++) {
            data[i] = pendingTasksOfOwner[i];
        }

        return pendingTasksOfOwner;
    }

    /* Modifiers */
}