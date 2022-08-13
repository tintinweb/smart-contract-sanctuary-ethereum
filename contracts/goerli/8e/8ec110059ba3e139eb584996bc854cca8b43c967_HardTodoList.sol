/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract HardTodoList{
    enum Status{
        TODO,
        PENDING,
        COMPELETED
    }

    struct Todo{
        string title;
        Status status;
        uint256 expired;
    }

    uint256 public externalPeriod=5;
    Todo[] public todos;

    modifier onlyTodo(uint256 _index) {
        Todo storage todo=todos[_index];
        require(todo.status==Status.TODO,"status must be TODO");
        _;
   }

    function addTodo(string memory title) external{
        todos.push(Todo(title,Status.TODO,0));
    }

    function setTodoCompleted(uint256 _index) external onlyTodo(_index){
        Todo storage todo=todos[_index];
        // require(todo.status==Status.TODO,"status must be TODO");
        todo.status=Status.COMPELETED;
    }

    function moveTodoToPending(uint256 _index) external  onlyTodo(_index){
        Todo storage todo=todos[_index];
        // require(todo.status==Status.TODO,"status must be TODO");
        todo.status=Status.PENDING;
        todo.expired=block.timestamp+externalPeriod;
    }

    function movePendingToTodo(uint256 _index) external{
        Todo storage todo=todos[_index];
        require(todo.status==Status.PENDING,"status must be PENDING");
        require(block.timestamp<=todo.expired,"pending expired");
        todo.status=Status.TODO;
        todo.expired=0;
    }
}