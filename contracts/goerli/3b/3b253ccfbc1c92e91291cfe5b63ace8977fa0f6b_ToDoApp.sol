/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.7;

contract ToDoApp {

    enum Priority { 
        SMALL, 
        MEDIUM, 
        LARGE 
    }

    enum Status { 
        TODO, 
        INPROGRESS, 
        COMPLETED 
    }

    struct ToDo {
        address owner;
        string text;
        Priority priority;
        Status status;
    }

    ToDo[] public todos;

    function createTodo(string calldata _text, Priority _priority, Status _status) external returns(uint) {
        todos.push(ToDo({owner: msg.sender, text: _text, priority: _priority, status: _status}));
        return (todos.length - 1);
    }

    function updateTodo(uint _id, string calldata _text) external  {
        require(msg.sender == todos[_id].owner, "Not the owner of todo");
        require(Status.COMPLETED != todos[_id].status, "Cannot change task completed");
        ToDo storage todo = todos[_id];
        todo.text = _text;
    }

    function updateStatus(uint _id, Status _status) external  {
        require(msg.sender == todos[_id].owner, "Not the owner of todo");
        ToDo storage todo = todos[_id];
        todo.status = _status;
    }

    function deleteToDo(uint _id) external {
        delete todos[_id];
    }
}