// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {

    struct Todo {
        uint id;
        string content;
        bool completed;
    }

    uint public todoCount = 0;
    mapping(uint => Todo) public todos;

    function getTodo(uint id) public view returns (Todo memory) {
        return todos[id];
    }

    function getId(uint id) public view returns(uint) {
        return id;
    }

    function createTodo(string memory content) public {
        todoCount++;
        todos[todoCount] = Todo(todoCount, content, false);
    }

    function toggleCompleted(uint id) public {
        todos[id].completed = !todos[id].completed;
    }

}