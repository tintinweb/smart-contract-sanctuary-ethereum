// SPDX-License-Identifier: MIT

// specify the solidity version here
pragma solidity ^0.8.0;

contract Todos {
    // We will declare an array of strings called todos
    string[] public todos;
    
    // We will take _todo as an input and push it inside the array in this function
    function setTodo(string memory _todo) public {
        todos.push(_todo);
    }

    // In this function we are just returning the array
    function getTodo() public view returns (string[] memory) {
        return todos;
    }
    
    // Here we are returning the length of the todos array
    function getTodosLength() public view returns (uint) {
        uint todosLength = todos.length;
        return todosLength;
    }
    
    // We are using the pop method to remove a todo from the array as you can see we are basically just removing one index
    function deleteToDo(uint _index) public {
        require(_index < todos.length, "This todo index does not exist.");
        todos[_index] = todos[getTodosLength() - 1];
        todos.pop();
    }
}