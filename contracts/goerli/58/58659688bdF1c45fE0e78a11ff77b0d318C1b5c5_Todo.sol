// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Todo {
    struct TodoItem {
        string description;
        bool status;
    }

    TodoItem[] public todoItems;

    function createToDoItem(string memory _description) external {
        todoItems.push(TodoItem(_description, false));
    }

    function updateTodoItem(uint _position, string memory _description)
        external
    {
        todoItems[_position].description = _description;

        TodoItem storage todo = todoItems[_position];
        todo.description = _description;
    }

    function getTodoItem(uint _position)
        external
        view
        returns (string memory, bool)
    {
        TodoItem memory todo = todoItems[_position];
        return (todo.description, todo.status);
    }
}