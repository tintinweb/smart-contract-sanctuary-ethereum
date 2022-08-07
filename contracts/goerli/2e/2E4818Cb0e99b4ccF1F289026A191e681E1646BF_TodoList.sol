/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

contract TodoList {
    //待辦事項
    string[] public todos; //storage
    //已完成待辦事項
    string[] public completedTodos;

    //暫停中的待辦事項
    string[] public pendingTodos;
     
    //storage: 永久儲存在 smart contract
    //memory: 生命週期只有在function 週期 
    //calldata: 只可使用，不可更改

    // 新增 todo
    function  addTodo (string memory todo) public {
        todos.push(todo);
    }

    // 移除 todo
    function  removeTodo (uint i) public {
        delete todos[i];
    }

    // 查看指定 todo
    //uint = uint256, you can use 8 -256 bits
    function   getTodo (uint i) public view returns (string memory)  {
        return todos[i];
    }

    //查看所有 todos
    function getAllTodos () public  view returns (string[] memory){
        return todos;
    }

    //TODO 改為 COMPLETED
    function markToDoCompledted (uint i) public{
        completedTodos.push(todos[i]);
        delete todos[i];    
    }

    //TODO 改為 PENDING
    function markToDoPending (uint i) public{
        pendingTodos.push(todos[i]);
        delete todos[i];    
    }

    //PENDING 重新 todo
    function markToDoPendingToDo (uint i) public{
        todos.push(todos[i]);
        delete pendingTodos[i];    
    }

    //查看所有 completed todos
    function getAllCompletedTodos () public view returns (string[] memory){
        return completedTodos;
    }
    //查看所有 pending todos
    function getAllPendingTodos () public view returns (string[] memory){
        return pendingTodos;
    }

}