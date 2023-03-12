/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList {
    struct TodoItem {
        string name;
        uint256 createdTime;
        bool completed;
        bool isPending;
        uint256 pendingTime;
    }

    TodoItem[] public todos;
    TodoItem[] public todoCompleted;
    TodoItem[] public todoPending;

    uint256 public constant n = 60; // n 秒

    constructor() {}

    function addTodo(string memory todo) external {
        TodoItem memory newTodo = TodoItem({
            name: todo,
            createdTime: block.timestamp,
            completed: false,
            isPending: false,
            pendingTime: 0
        });

        todos.push(newTodo);
    }

    function setCompleted(uint256 index) external {
        TodoItem memory completedTodo = todos[index];
        completedTodo.completed = true;
        completedTodo.isPending = false;

        for (uint256 i = index; i < todos.length - 1; i++) {
            todos[i] = todos[i + 1];
        }
        todos.pop();

        todoCompleted.push(completedTodo);
    }

    function setPending(uint256 index) external {
        TodoItem memory pendingTodo = todos[index];
        pendingTodo.isPending = true;
        pendingTodo.pendingTime = block.timestamp;

        for (uint256 i = index; i < todos.length - 1; i++) {
            todos[i] = todos[i + 1];
        }
        todos.pop();

        todoPending.push(pendingTodo);
    }

    function getTodo(uint256 index) external view returns (TodoItem memory) {
        return todos[index];
    }

    function deleteTodo(uint256 index) external {
        for (uint256 i = index; i < todos.length - 1; i++) {
            todos[i] = todos[i + 1];
        }
        todos.pop();
    }

    function getCompleted(uint256 index)
        external
        view
        returns (TodoItem memory)
    {
        return todoCompleted[index];
    }

    function getPending(uint256 index) external view returns (TodoItem memory) {
        return todoPending[index];
    }

    function getAllTodo() external view returns (TodoItem[] memory) {
        return todos;
    }

    function getAllCompleted() external view returns (TodoItem[] memory) {
        return todoCompleted;
    }

    function getAllPending() external view returns (TodoItem[] memory) {
        return todoPending;
    }

    function clearCompleted() external {
        delete todoCompleted;
    }

    function canMoveToTodos(uint256 index) public view returns (bool) {
        if (!todoPending[index].isPending) {
            return false;
        }

        if (block.timestamp < todoPending[index].pendingTime + n) {
            return false;
        }

        return true;
    }

    function movePendingToTodos(uint256 index) external {
        require(canMoveToTodos(index), "Cannot move todo to todos");

        TodoItem memory pendingTodo = todoPending[index];
        pendingTodo.isPending = false;
        pendingTodo.pendingTime = 0;

        for (uint256 i = index; i < todoPending.length - 1; i++) {
            todoPending[i] = todoPending[i + 1];
        }
        todoPending.pop();

        todos.push(pendingTodo);
    }

    function getTodoCount() external view returns (uint256) {
        return todos.length;
    }

    function getCompletedCount() external view returns (uint256) {
        return todoCompleted.length;
    }

    function getPendingCount() external view returns (uint256) {
        return todoPending.length;
    }
}