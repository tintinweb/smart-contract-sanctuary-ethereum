/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TodoList {
    struct TodoItem {
        string todoName;
        uint256 updateTimestamp;
    }
    TodoItem[] public todos;
    TodoItem[] public todoCompleted;
    TodoItem[] public todoPending;
    uint256 public startTime;
    

    constructor() {
        startTime = block.timestamp;
    }

    // 永久儲存是storage，短暫使用就用memory，calldata傳入後只能參考不能改變的data type 
    //--------------Todo------------------------------------------------------------------------------------------
    function addTodo(string memory _todoName) external {
        pushTodoItem(_todoName);
    }

    function pushTodoItem(string memory _todoName) internal {
        todos.push(TodoItem(_todoName, block.timestamp));
    }

    function getTodoItem(uint256 index) internal view returns (string memory) {
        return todos[index].todoName;
    }

    function getTodo(uint256 _index) external view returns (string memory) {
        return getTodoItem(_index);
    }

    function deleteTodo(uint256 index) external {
        delete todos[index];
    }

    function getAllTodo() external view returns (string memory) {
        string memory todosName;
        todosName = "The Todo List: ";
        for (uint256 i = 0; i <= todos.length - 1; i++){
            todosName = string(abi.encodePacked(todosName, " ", todos[i].todoName));
        }
        return todosName;
    }

    //--------------Todo end------------------------------------------------------------------------------------------

    //--------------Complete------------------------------------------------------------------------------------------

    function setCompleted(uint256 index) external {
        TodoItem memory compeltedTodo = todos[index];
        
        for (uint256 i = index; i < todos.length - 1; i++){
            todos[i] = todos[i + 1];
        }
        delete todos[todos.length - 1];
        todos.pop();

        compeltedTodo.updateTimestamp = block.timestamp;
        todoCompleted.push(compeltedTodo);
    }

    function setUncompleted(uint256 index) external {
        TodoItem memory uncompeltedTodo = todoCompleted[index];
        require(block.timestamp<(uncompeltedTodo.updateTimestamp+86400), "The time is waiting too long to restore the Todo Item.");
        for (uint256 i = index; i < todoCompleted.length - 1; i++){
            todoCompleted[i] = todoCompleted[i + 1];
        }
        delete todoCompleted[todoCompleted.length - 1];
        todoCompleted.pop();

        todos.push(uncompeltedTodo);
    }

    function getCompletedTodoItem(uint256 index) internal view returns (string memory) {
        return todoCompleted[index].todoName;
    }

    function getCompleted(uint256 _index) external view returns (string memory) {
        return getCompletedTodoItem(_index);
    }

    function getAllCompleted() external view returns (string memory) {
        string memory completedTodosName;
        completedTodosName = "The Completed Todo List: ";
        for (uint256 i = 0; i <= todoCompleted.length - 1; i++){
            completedTodosName = string(abi.encodePacked(completedTodosName, " ", todoCompleted[i].todoName));
        }
        return completedTodosName;
    }

    function emptyCompleted() external returns (uint256) {
        delete todoCompleted;
        return todoCompleted.length;
    }

    //--------------Complete end------------------------------------------------------------------------------------------

    //--------------Pending------------------------------------------------------------------------------------------

    function setPending(uint256 index) external {
        TodoItem memory pendingTodo = todos[index];
        
        for (uint256 i = index; i < todos.length - 1; i++){
            todos[i] = todos[i + 1];
        }
        delete todos[todos.length - 1];
        todos.pop();

        pendingTodo.updateTimestamp = block.timestamp;
        todoPending.push(pendingTodo);
    }

    function setResume(uint256 index) external {
        TodoItem memory resumeTodo = todoPending[index];
        require(block.timestamp<(resumeTodo.updateTimestamp+10), "The time is waiting too long to restore the Todo Item.");

        for (uint256 i = index; i < todoPending.length - 1; i++){
            todoPending[i] = todoPending[i + 1];
        }
        delete todoPending[todoPending.length - 1];
        todoPending.pop();

        todos.push(resumeTodo);
    }

    function getPendingTodoItem(uint256 index) internal view returns (string memory) {
        return todoPending[index].todoName;
    }

    function getPending(uint256 _index) external view returns (string memory) {
        return getPendingTodoItem(_index);
    }

    function getAllPending() external view returns (string memory) {
        string memory pendingTodosName;
        pendingTodosName = "The Pending Todo List: ";
        for (uint256 i = 0; i <= todoPending.length - 1; i++){
            pendingTodosName = string(abi.encodePacked(pendingTodosName, " ", todoPending[i].todoName));
        }
        return pendingTodosName;
    }

    //--------------Pending end------------------------------------------------------------------------------------------

    function getTSDisplay() external view returns (uint256) {
        return startTime;
    }
    
}