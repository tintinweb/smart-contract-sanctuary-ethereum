/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

/*
    進階題
    當 TODO 搬移到 PENDING 後，要記錄時間，當時間超過 n 秒，就不可以再搬回 TODO
    TODO 有三種狀態：TODO、COMLETED、PENDING
*/
contract HardTodoList {
    // 列舉
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

    // 宣告滯留時間
    uint256 public expiredPeriod = 5; // 5 seconds
    // 宣告 todos 陣列
    Todo[] public todos;

    modifier OnlyTodo(uint256 _index) {
        require(todos[_index].status == Status.TODO, "Only Todo");
        _;
    }

    // 新增待辦事項
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
        todo.status = Status.PENDING; // 將狀態改為 PENDING
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