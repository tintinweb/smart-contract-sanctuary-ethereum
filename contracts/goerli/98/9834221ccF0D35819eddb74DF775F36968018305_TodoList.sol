/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

contract TodoList {
    string[] private todos;
    string[] private todoCompleted;
    constructor() {}
    function addTodo(string memory todo) external{
        todos.push(todo);
    }
    function moveTodoTOCompleted(uint256 index) external {
        string storage compeltedTodo = todos[index];
        todoCompleted.push(compeltedTodo);
        deleteTodo(index );
    }
        function getTodo(uint256 index) external view returns (string memory) {
        return todos[index];
    }

    function deleteTodo(uint256 index) public  {
        todos[index] = todos[todos.length - 1];
        todos.pop();

    }

    function getCompleted(uint256 index) external view returns (string memory) {
        return todoCompleted[index];
    }
    function clearCompleted() external {
        for (uint256 i = 0; i < todoCompleted.length; i++) {
            delete todoCompleted[i];
        }
        for (;todoCompleted.length>0;) {
            todoCompleted.pop();
        }
       
    }
    function getAllTodo() external view returns (string[] memory) {
        return todos;
    }

    function getAllCompleted() external view returns (string[] memory) {
        return todoCompleted;
    }


}