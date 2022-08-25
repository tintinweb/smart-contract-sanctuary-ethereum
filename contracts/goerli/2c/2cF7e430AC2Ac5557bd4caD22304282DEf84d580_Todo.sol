// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Todo {
    struct TodoItem {
        string title;
        string description;
        bool status;
    }

    TodoItem[] public todos;

    function createTodoItem(string memory _title, string memory _description)
        external
    {
        TodoItem memory newTodo;
        newTodo.title = _title;
        newTodo.description = _description;
        todos.push(newTodo);
    }

    function getTodoItems() external view returns (TodoItem[] memory) {
        return todos;
    }

    function updateTodoItem(
        uint256 _index,
        string memory _title,
        string memory _description
    ) external {
        todos[_index].title = _title;
        todos[_index].description = _description;
    }

    function updateTodoItemStatus(uint256 _index) external {
        todos[_index].status = !todos[_index].status;
    }

    function getTodoItemByIndex(uint256 _index)
        external
        view
        returns (TodoItem memory)
    {
        return todos[_index];
    }

    function deleteTodoItem(uint256 _index) external {
        delete todos[_index];
    }
}