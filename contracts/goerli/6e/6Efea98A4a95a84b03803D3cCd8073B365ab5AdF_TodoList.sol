/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract TodoList {
    enum Status {
        TODO,
        PENDING,
        COMPLETED
    }

    struct Todo {
        string title;
        Status status;
        uint256 expired;
    }

    uint256 public expiredPeriod = 5; // 5 seconds
    Todo[] public todos;

    constructor() {}

    modifier OnlyTodo(uint256 _index) {
        require(todos[_index].status == Status.TODO, "only TODO");
        _;
    }

    function addTodo(string memory _title) external {
        todos.push(
            Todo({
                title: _title,
                status: Status.TODO,
                expired: 0
            })
        );
    }

    function setTodoCompleted(uint256 _index) external OnlyTodo(_index) {
        Todo storage todo = todos[_index];
        todo.status = Status.COMPLETED;
    }

    function moveTodoToPending(uint256 _index) external OnlyTodo(_index) {
        Todo storage todo = todos[_index];
        todo.status = Status.PENDING;
        todo.expired = block.timestamp + expiredPeriod;
    }

    function movePendingToTodo(uint256 _index) external {
        require(todos[_index].status == Status.PENDING, "only PENDING");
        require(todos[_index].expired >= block.timestamp, "pending expired");

        Todo storage todo = todos[_index];
        todo.status = Status.TODO;
        todo.expired = 0;
    }
}