/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract TodoList {
    string[] public todos;
    string[] public todoCompleted;
    string[] public Pending;

    constructor() {}

    // 永久儲存是storage，短暫使用就用memory，calldata傳入後只能參考不能改變的data type 
    function addTodo(string memory todo) external {
        todos.push(todo);
    }

    // 此寫法可以把刪掉並把後面的元素往前面提
    function setCompleted(uint256 index) external {
        string memory compeltedTodo = todos[index];

        popmaker(todos,index);

        todoCompleted.push(compeltedTodo);
    }

    function getTodo(uint256 index) external view returns (string memory) {
        return todos[index];
    }

    // delete 會把元素刪掉，留下個空格
    function deleteTodo(uint256 index) external {
        delete todos[index];
    }

    function getCompleted(uint256 index) external view returns (string memory) {
        return todoCompleted[index];
    }

    function getAllTodo() external view returns (string[] memory) {
        return todos;
    }

    function getAllCompleted() external view returns (string[] memory) {
        return todoCompleted;
    }
    
    
    // Homework easy//
    function moveToPending(uint index) external{
        string memory pendingtodo = todos[index];
        popmaker(todos,index); //刪掉index
        Pending.push(pendingtodo); // 並加入pending
    }

    //刪掉要轉陣列的元素
    function popmaker(string[] storage list,uint index) private{
        for(uint i = index ; i < list.length - 1; i++)
        {
            list[i] = list[i + 1];
        }
        list.pop();
    }

    function getPending() external view returns(string[] memory){
        return Pending;
    }

   
}