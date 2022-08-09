/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract TodoList {

    // 初始化pendingTimeLimit
    uint256 public pendingTimeLimit;
    constructor(uint256 _pendingTimeLimit){
        pendingTimeLimit=_pendingTimeLimit;
    }

    // ====================================================================

    string[] public todos;
    // 新增 TODO
    function addTodo(string memory todo) external {
        todos.push(todo);
    }

    // 刪除 TODO
    function deleteTodo(uint256 index) external {
        removeListElement(todos,index);
    }

    // 查看指定 TODO
    function getTodo(uint256 index) external view returns (string memory) {
        return todos[index];
    }

    // 查看所有 TODO
    function getAllTodo() external view returns (string[] memory) {
        return todos;
    }

    // ====================================================================

    string[] public completedTodos;
    // 新增 Completed TODO
    function addCompletedTodo(uint256 index) external {
        require(index<todos.length-1,"index must < todos.length-1");
        completedTodos.push(todos[index]);
        removeListElement(todos,index);
    }

    // 刪除 Completed TODO
    function deleteCompletedTodo(uint256 index) external {
        todos.push(completedTodos[index]);
        removeListElement(completedTodos,index);
    }

    // 查看指定 Completed TODO
    function getCompletedTodo(uint256 index) external view returns (string memory) {
        return completedTodos[index];
    }

    // 查看所有 Completed TODO
    function getAllCompletedTodo() external view returns (string[] memory) {
        return completedTodos;
    }

    // 清空 Completed TODO
    function clearAllCompletedTodo() external{
        delete completedTodos;
    }

    // ====================================================================
    struct PendingTodo{
        string PendingTodoString;
        uint256 PendingTodoExpireTimestamp;
    }
    PendingTodo[] public PendingTodoInstance;
    
    // 新增 Pending TODO
    function addPendingTodo(uint256 index) public{
        require(index<todos.length-1,"index must < todos.length-1");
        PendingTodoInstance.push(PendingTodo(todos[index],block.timestamp+pendingTimeLimit));
        removeListElement(todos,index);
    }

    // 更新 Pending TODO,如果過期則放到todos中
    function updatePendingTodo() public{
        for(uint256 i=0;i<PendingTodoInstance.length;i++){
            if(PendingTodoInstance[i].PendingTodoExpireTimestamp<=block.timestamp)
            {
                todos.push(PendingTodoInstance[i].PendingTodoString);
                removePendingTodoStructElement(PendingTodoInstance,i);
            }
        }
    }

    // 查看所有 Pending TODO
    function getAllPendingTodo() external view returns (PendingTodo[] memory) {
        return PendingTodoInstance;
    }

    // ====================================================================
    function removeListElement(string[] storage list,uint256 index) private{
        require(index<list.length,"error");
        for(uint256 i=index;i<list.length-1;i++)
        {
            list[i]=list[i+1];
        }
        list.pop();
    }

    function removePendingTodoStructElement(PendingTodo[] storage list,uint256 index) private{
        require(index<list.length,"error");
        for(uint256 i=index;i<list.length-1;i++)
        {
            list[i]=list[i+1];
        }
        list.pop();
    }


}