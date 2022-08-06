/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.4;


contract TodoList {
    // 增加事項 (TODO)
    string[] public todos;
    
    // 增加已完成事項 (COMPLETED)
    string[] public todoCompleted;

    // 新增todo
    function addTodo(string memory todo) public {
        todos.push(todo);
    }

    // 刪除todo
    function removeTodo(uint256 index) public {
        delete todos[index];
    }
    
    // 查看指定todo
    function retrieveTodo(uint256 index) public view returns (string memory) {
        return todos[index];
    }

    // 查看所有todo
    function retrieveAllTodo() public view returns (string[] memory) {
        return todos;
    }

    // 改為completed
    function changoToCompleted(uint256 index) public {
        
    }
}