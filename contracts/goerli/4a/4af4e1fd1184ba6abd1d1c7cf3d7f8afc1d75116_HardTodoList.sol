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
    // Status.TODO => 0
    // Status.PENDING  => 1
    // Status.COMPLETED => 2
    // Status.NOT_COMPLETED 報錯

    struct Todo {
        string item;
        Status status;
        uint256 expired;
    }
   
    uint256 public expiredTime = 30; // 放進pending事項的到期時間
    Todo[] public todos;

    // 新增事項
    function addTodo(string memory _item) external {
        todos.push(
            Todo({
                item: _item,
                status: Status.TODO,
                expired: 0
            })
        );
    }

    // 設定事項完成
    function setCompleted(uint256 _index) external {
        Todo storage todo = todos[_index];
        require(todo.status != Status.COMPLETED, "Item is already completed");

        todo.status = Status.COMPLETED;

    }
    
    // 設定事項pending
    function setPending(uint256 _index) external {
        Todo storage todo = todos[_index];
        require(todo.status == Status.TODO, "Item is not on todo");

        todo.expired = block.timestamp + expiredTime;
        todo.status = Status.PENDING;
    }

    // 將pending事項拉回todo
    function backToDo(uint256 _index) external {
        Todo storage todo = todos[_index];
        require(todo.status == Status.PENDING, "Item is not on pending");
        require(todo.expired > block.timestamp, "Item is already expired");
        
        todo.status = Status.TODO;
        todo.expired = 0;
    }

    // 清空completed功能
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