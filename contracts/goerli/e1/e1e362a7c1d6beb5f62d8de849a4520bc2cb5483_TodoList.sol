/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.4;

contract TodoList {
    // 增加代辦事項（TODO）
    string[] public todos; // storage
    // 增加已完成事項（COMPLETED）
    string[] public todoCompleted;

    // storage, memory, calldata

    // 新增 TODO
    // ["eat"]
    function addTodo(string memory todo) public {
        todos.push(todo);
    }
    // 刪除 TODO
    function delTodo() public {

    }
    // 查看指定 TODO
    // ["eat"]
    //    0  1                            // pure/view             // 第二週預錄課程
    function getTodo(uint256 index) public view returns (string memory) {
        // 怎麼取得 todos 索引的資訊 //
        // 20 秒後一起來講答案
        return todos[index];
    }
    // 查看所有 TODO
    function getAllTodo() public {

    }
    // TODO 改為 COMPLETED
    function setTodoCompleted() public {

    }
    // 查看所有 COMPLETED
    function getAllTodoCompleted() public {

    }
}