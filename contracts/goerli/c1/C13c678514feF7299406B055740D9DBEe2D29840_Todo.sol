// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Todo {
    string[] public todos;

    function setTodo(string memory _todo) public {
        todos.push(_todo);
    }

    function getTodo() public view returns (string[] memory) {
        return todos;
    }

    function getTodosLength() public view returns (uint256) {
        uint256 todosLength = todos.length;
        return todosLength;
    }

    function deleteTodo(uint _index) public {
        require(_index < todos.length, "This array desn't exist ");
        todos[_index] = todos[getTodosLength() - 1];
        todos.pop();
    }
}