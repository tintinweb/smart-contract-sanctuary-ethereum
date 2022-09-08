/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ToDoList {
struct Todo {
    string message;
    string title;
    bool taskCompleted;

}

Todo[] public todos;

function createToDo(string calldata _message, string calldata _title) external {
    Todo memory newTodo;
    newTodo.message = _message;
    newTodo.title = _title;
    newTodo.taskCompleted = false;
    todos.push(newTodo);

}
function getTodo() external view returns (Todo[] memory) {
    return todos;
}

function updateToDo(uint _index, string calldata _newMessage, string calldata _newTitle) external {
    todos[_index].message = _newMessage;
    todos[_index].title = _newTitle;

}

function toggleCOmpleted(uint _index) external {
    todos[_index].taskCompleted = !todos[_index].taskCompleted;

}

function deleteTask (uint _index) external {
    delete todos[_index];
}

}