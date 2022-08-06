/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract TodoPractice {
    // 增加代辦事項 (TODO)
    // 陣列 ARRAY
    
    string[] public todos;
    // 增加已完成事項 (COMPLETED)
    string[] public todoCompleteds;

    // 新增 TODO
    function addTodo(string memory todoText) public {
        todos.push(todoText); //push 新增一個東西到array
    }

    // 刪除 TODO
    function deleteTodo() public {
        
    }

    // 檢查指定 TODO
    function getTodo(uint256 index) public view returns (string memory) {
        return todos[index];
    }

    // 檢查全部 TODO
    function getallTodo() public {

    }
    
    // TODO 改為 COMPLETED
    function todoCompleted() public {
    }

    // 查看所有 COMPLETED
    function getAllCompleted() public {
    }
}