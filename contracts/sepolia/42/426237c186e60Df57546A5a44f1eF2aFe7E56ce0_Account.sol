// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Todo} from "./Todo.sol";
import {Owner} from "./Owner.sol";

contract Account is Owner {
    mapping(address => Todo) public todos;

    event TodoCreated(address todoAdress, string title, bool completed);

    function createTodo(string memory title) public onlyOwner {
        Todo todo = new Todo(title);
        todos[address(todo)] = todo;

        emit TodoCreated(address(todo), todo.title(), todo.completed());
    }

    function updateTodo(
        address todoAddress,
        string memory title
    ) public onlyOwner {
        Todo todo = Todo(todoAddress);
        todo.setTitle(title);
    }

    function toggleCompleted(address todoAddress) public onlyOwner {
        Todo todo = Todo(todoAddress);
        todo.toggleCompleted();
    }

    function getTodo(
        address todoAddress
    ) public view onlyOwner returns (string memory, bool) {
        return (todos[todoAddress].title(), todos[todoAddress].completed());
    }
}