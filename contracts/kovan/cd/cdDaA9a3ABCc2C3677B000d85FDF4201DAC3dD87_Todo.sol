// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Todo {
    mapping(string => bool) public todoList;

    function addTodo(string memory _todoName) public {
        todoList[_todoName] = false;
    }
}