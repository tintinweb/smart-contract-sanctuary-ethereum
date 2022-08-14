/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/*
    進階題
    當 TODO 搬移到 PENDING 後，要記錄時間，當時間超過 n 秒，就不可以再搬回 TODO
    TODO 有三種狀態：TODO、COMLETED、PENDING
*/

contract TodoList_Plus2 {
    enum Status{
        TODO,
        PENDING,
        COMPLETED
    }

    // Status.TODO => 0
    // Status.PENDING  => 1
    // Status.COMPLETED => 2

    struct Todo{
        string title;
        Status status;
        uint256 expired;
    }

    //在Pending中滯留時間
    uint256 public expiredPeriod = 5; // 5 seconds

    Todo[] public todos;

    //分離式判斷 - 確定只有在 TODO狀態才可執行，否則報錯
    modifier OnlyTodo(uint256 _index) {
        require(todos[_index].status == Status.TODO, "Only Todo");
        _;
    }

    //新增TODO

    function addTodo(string memory _title) external {
        todos.push(
            Todo({
                title:_title,
                status:Status.TODO,
                expired:0
            })
        );
    }

    function SetTodoComplete(uint256 _index) external OnlyTodo(_index){
        Todo storage todo = todos[_index];  // storage 儲存下來
        todo.status = Status.COMPLETED;
    }

    function moveTodoToPending(uint256 _index) external OnlyTodo(_index) {
        Todo storage todo = todos[_index];
        todo.status = Status.PENDING; // 將狀態改為 PENDING
        todo.expired = block.timestamp + expiredPeriod; //block.timestamp紀錄當下時間 + expiredPeriod停滯多長時間
    }

    function movePendingToTodo(uint256 _index) external {
        require(todos[_index].status == Status.PENDING, "only PENDING"); //檢查是否為pending狀態，若是則往下執行，若不是報錯
        require(todos[_index].expired >= block.timestamp, "pending expired"); //檢查時間是否超過設定時間(block.timestamp + expiredPeriod)，若未超過則往下執行，若不是報錯

        Todo storage todo = todos[_index];
        todo.status = Status.TODO;
        todo.expired = 0;
    }
    
    //讀取所有TODO
    function ShowAllTodo() external view returns(Todo[] memory) {
        return(todos);
    }


}