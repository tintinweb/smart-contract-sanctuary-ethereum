// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Todo {
  struct TodoItem {
    string name;
    bool done;
  }

  TodoItem[] private todos;

  function addTodo(string memory _name) external {
    todos.push(TodoItem(_name, false));
  }

  function updateStatus(uint256 _id, bool _done) external {
    todos[_id].done = _done;
  }

  function removeTodo(uint256 _id) external {
    delete todos[_id];
  }

  function getTodos() external view returns (TodoItem[] memory) {
    return todos;
  }

  function getTodoById(uint256 _id) external view returns (TodoItem memory) {
    return todos[_id];
  }
}