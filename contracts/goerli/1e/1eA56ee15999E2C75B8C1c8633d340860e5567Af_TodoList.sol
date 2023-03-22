// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList {
    string[] public todos;
    string[] public todoCompleted;
    string[] public todoPending;

    constructor() {}

    // 永久儲存是storage，短暫使用就用memory，calldata傳入後只能參考不能改變的data type 
    function addTodo(string memory todo) external {
        todos.push(todo);
    }
    function setPending(uint256 index) external {
        string memory pendingTodo = todos[index];
        
        for (uint256 i = index; i < todos.length - 1; i++){
            todos[i] = todos[i + 1];
        }
        delete todos[todos.length - 1];
        todos.pop();

        todoPending.push(pendingTodo);
    }

    function setCompleted(uint256 index) external {
        string memory compeltedTodo = todos[index];
        
        for (uint256 i = index; i < todos.length - 1; i++){
            todos[i] = todos[i + 1];
        }
        delete todos[todos.length - 1];
        todos.pop();
        todoCompleted.push(compeltedTodo);
    }

    function getTodo(uint256 index) external view returns (string memory) {
        return todos[index];
    }
    function getPending(uint256 index) external view returns (string memory) {
        return todoPending[index];
    }

    function deleteTodo(uint256 index) external {
        delete todos[index];
    }

    function getCompleted(uint256 index) external view returns (string memory) {
        return todoCompleted[index];
    }

    function getAllTodo() external view returns (string[] memory) {
        return todos;
    }

    function getAllCompleted() external view returns (string[] memory) {
        return todoCompleted;
    }
    function getAllPending() external view returns (string[] memory) {
        return todoPending;
    }
}