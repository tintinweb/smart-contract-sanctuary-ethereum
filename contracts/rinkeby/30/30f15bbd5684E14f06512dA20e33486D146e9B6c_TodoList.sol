/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <0.9.0;

contract TodoList{
    uint public taskCount = 0;
    struct Task{
        uint id;
        string content;
        bool completed;
    }

    mapping (uint => Task) public tasks;

    constructor() public{
        createTask("check out the docs");
    }

    function createTask(string memory _content) public{
        taskCount ++;
        tasks[taskCount] = Task(taskCount, _content, false);
    }

    function completeTask(uint _id) public{
        tasks[_id].completed = true;
    }
}