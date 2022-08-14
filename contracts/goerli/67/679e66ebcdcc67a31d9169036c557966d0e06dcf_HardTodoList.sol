/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract HardTodoList {
    
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

    
    uint256 public expiredPeriod = 20;
    
    Todo[] public todos;

    modifier OnlyTodo(uint256 _index) {
        require(todos[_index].status == Status.TODO, "Only Todo");
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

    function removeAllCompleted() external {
        for (uint256 i=0; i < todos.length; i++) {
            if (todos[i].status == Status.COMPLETED) {
                for (uint256 j=i; j < todos.length-1; j++) {
                    todos[j] = todos[j+1];
                }
                todos.pop();
            }
        }
    }
    
}