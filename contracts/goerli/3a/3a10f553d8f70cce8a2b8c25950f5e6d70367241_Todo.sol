/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// Write a smart contract for a To-Do app. Make use of structs.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Todo {
    struct Task {
        string name;
        bool completed;
    }

    Task[] public tasks;

    function createTask(string memory _name) public {
        Task memory newTask = Task(_name, false);
        tasks.push(newTask);
    }

    function toggleCompleted(uint256 _index) public {
        Task storage task = tasks[_index];
        task.completed = !task.completed;
    }
}