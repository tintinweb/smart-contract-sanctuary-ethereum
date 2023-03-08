/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoListSimple {
    string[] public todos;
    string[] public todoCompleted;
    string[] public pending;

    constructor() {}

    // 永久儲存是storage，短暫使用就用memory，calldata傳入後只能參考不能改變的data type 
    function addTodo(string memory todo) external {
        todos.push(todo);
    }

    function setCompleted(uint256 index) external {
        string memory compeltedTodo = pending[index];
        
        for (uint256 i = index; i < pending.length - 1; i++){
            pending[i] = pending[i + 1];
        }
        delete pending[pending.length - 1];
        pending.pop();

        todoCompleted.push(compeltedTodo);
    }

    function getTodo(uint256 index) external view returns (string memory) {
        return todos[index];
    }

    function deleteTodo(uint256 index) external {
        delete todos[index];
        for(uint256 i = index; i < todos.length - 1 ; i++){
            todos[i] = todos[i+1];
        }

        todos.pop();
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

    function setPending(uint256 index) external {
        string memory pendingTodo = todos[index];
        
        for (uint256 i = index; i < todos.length - 1; i++){
            todos[i] = todos[i + 1];
        }
        delete todos[todos.length - 1];
        todos.pop();

        pending.push(pendingTodo);
    }

    function getAllPending() external view returns (string[] memory) {
        return pending;
    }

    function getPending(uint256 index) external view returns (string memory) {
        return pending[index];
    }
}