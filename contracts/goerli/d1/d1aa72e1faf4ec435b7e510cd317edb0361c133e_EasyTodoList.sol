/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract EasyTodoList{
    string[] public todos;
    string[] public todoCompleted;
    string[] public todoPending;

    // 新增代辦事項
    function addTodo(string memory todo) external{
        todos.push(todo);
    }

    // 取得所有todo
    function getAllTodo() external view returns(string[] memory){
        return todos;
    }

    // 取得所有todoCompleted
    function getTodoCompleted() external view returns(string[] memory){
        return todoCompleted;
    }

    // 取得所有todoPending
    function getTodoPending() external view returns(string[] memory){
        return todoPending;
    }

    // 將待辦事項設為完成
    function setCompleted(uint256 index) external{
        require(index<todos.length,"error");
        todoCompleted.push(todos[index]);
        popHelper(todos,index);
    }
    
    // 將todo移動到Pending
    function moveTodoToPending(uint256 index) external{
        todoPending.push(todos[index]);
        popHelper(todos,index);
    }

    function popHelper(string[] storage list,uint256 index) private{
        for(uint256 i=index;i<list.length-1;i++)
        {
            list[i]=list[i+1];
        }
        list.pop();
    }




}