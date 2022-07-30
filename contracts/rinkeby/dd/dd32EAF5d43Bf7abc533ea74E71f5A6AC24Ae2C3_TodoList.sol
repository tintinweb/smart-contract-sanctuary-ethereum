// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {

    struct Todo {
        uint id;
        string content;
        bool completed;
    }

    uint public todoCount = 0;
    mapping(address => mapping(uint => Todo)) public todos;

    function getTodo(uint id) public view returns (Todo memory) {
        return todos[msg.sender][id];
    }

    function createTodo(string memory content) public {
        todoCount++;
        todos[msg.sender][todoCount] = Todo(todoCount, content, false);
    }

    function toggleCompleted(uint id) public {
        todos[msg.sender][id].completed = !todos[msg.sender][id].completed;
    }

}