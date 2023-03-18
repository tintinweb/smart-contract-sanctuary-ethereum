// SPDX-License-Identifier: MIT    
pragma solidity ^0.8.17;

contract TodoList {
    string[] public todos;
    string[] public todoCompleted;
    string[] public todoPending;

    constructor() {}

    function addTodo(string memory todo) external {
        todos.push(todo);
    }

    function setCompleted(uint256 index) external {
        string memory compeltedTodo = todos[index];
        
        popHelper(todos, index);

        todoCompleted.push(compeltedTodo);
    }

    function getTodo(uint256 index) external view returns (string memory) {
        return todos[index];
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

    /**
        Homework easy
     */

    // 移動 todo 至 pending 中
    function moveTodoToPending(uint256 index) external {
        string memory todo = todos[index];
        
        popHelper(todos, index);

        todoPending.push(todo);
    }

    // 移動 pending 至 todo 中
    function movePendingToTodo(uint256 index) external {
        string memory pendingTodo = todoPending[index];
        
        popHelper(todoPending, index);

        todos.push(pendingTodo);
    }

    // helper
    function popHelper(string[] storage list, uint256 index) private {
        for (uint256 i = index; i < list.length - 1; i++){
            list[i] = list[i + 1];
        }
        delete list[list.length - 1];
        list.pop();
    }
}