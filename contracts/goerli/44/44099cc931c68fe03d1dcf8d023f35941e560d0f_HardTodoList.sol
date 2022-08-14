/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract HardTodoList {
    
// 列舉
   enum Status {
        TODO,
        PENDING,
        COMPLETED

    }
    // Status.TODO => 0
    // Status.PENDING  => 1
    // Status.COMPLETED => 2
    // Status.NOT_COMPLETED 報錯

    struct Todo {
        string title;
        Status status;
        uint256 expired;
    }

    //宣告滯留時間
    uint256 public expiredPeriod = 10; // 10 seconds
    //宣告 todos 陣列
    Todo[] public todos;

      modifier OnlyTodo(uint256 _index) {
        require(todos[_index].status == Status.TODO, "Only Todo");
        _;
    }

    //新增代辦事項
 
    function addTodo(string memory _title) external {
        todos.push(
            Todo({
                title: _title,
                status: Status.TODO,
                expired: 0
                })
            );
        }

    // 將 TODO 狀態變為 COMLETED
    // 將待辦事項變完成
    function setTodoCompleted(uint256 _index) external OnlyTodo(_index) {
        // 檢查：必須狀態是 Status.TODO
        // require(檢查語法, "報錯訊息");

        Todo storage todo = todos[_index];
        todo.status = Status.COMPLETED;
    }
    
    // todo => Pending
    // TODO 搬移到 PENDING 後，要記錄時間
    // 當下的時間 block.timesamp
    function moveTodoToPending(uint256 _index) external OnlyTodo(_index) {
        
        // 1): require 變成 modifier OnlyTodo 重複檢查的函數，拉出來
        // 2): todo.expired 紀錄的時間 block.timestamp, expiredPeriod
        Todo storage todo = todos[_index];
        todo.status = Status.PENDING; // 將狀態改為 PENDING
        todo.expired = block.timestamp + expiredPeriod;
      

    }

    // Pending => todo
    // 當時間超過 n 秒，就不可以再搬回 TODO
    // 驗證時間超過的話
    function movePendingToTodo(uint256 _index) external {
        require(todos[_index].status == Status.PENDING, "only PENDING");
        require(todos[_index].expired >= block.timestamp, "pending expired");

        Todo storage todo = todos[_index];
        todo.status = Status.TODO;
        todo.expired = 0;
    }


    }