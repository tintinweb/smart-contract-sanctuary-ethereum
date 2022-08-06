/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList {
    string[] public todos;
    string[] public todoCompleted;
    string[] public pending;
    mapping(string => uint256) public pendingEndTime;

    constructor() {}

    function addTodo(string memory todo) external {
        todos.push(todo);
    }

    function todo2Pending(uint256 index, uint256 time) external {
        pending.push(todos[index]);
        uint256 endTime = callTime() + time;
        pendingEndTime[todos[index]] = endTime;
        todos[index] = todos[todos.length - 1];
        todos.pop();
    }

    function pending2Todo(uint256 index) external {
        uint256 deadline = pendingEndTime[pending[index]];
        require(deadline >= block.timestamp, "over deadline, plz complete");
        todos.push(pending[index]);
        pending[index] = pending[pending.length - 1];
        pending.pop();
    }

    function setCompleted(uint256 index) external {
        // how to ?
        todoCompleted.push(todos[index]);
    }

    function pending2Complete(uint256 index) external {
        todoCompleted.push(pending[index]);
    }

    function getTodo(uint256 index) external view returns (string memory) {
        return todos[index];
    }

    function deleteTodo(uint256 index) external {
        delete todos[index];
    }

    function clearCompleted() external {
        todoCompleted = new string[](0);
    }

    function getCompleted() external view returns (string[] memory) {
        return todoCompleted;
    }

    function getAllTodo() external view returns (string[] memory) {
        return todos;
    }

    function getAllPending() external view returns (string[] memory) {
        return pending;
    }

    function getAllCompleted() external view returns (string[] memory) {
        return todoCompleted;
    }

    function callTime() private view returns (uint256) {
        return block.timestamp;
    }
}