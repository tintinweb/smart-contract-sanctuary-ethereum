/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier:  MIT

pragma solidity >= 0.8.4;

contract TodoList {
    //增加代辦事項
    string[] public todos; //storage
    //增加已完成事項
    string[] public finishedtodo;


    //storage、memeory、calldata
    //storage永久存放
    //memory暫存
    //僅可參考，不可修改

    //新增
    function addTodo(string memory todo) public {
        todos.push(todo);
    }

    //刪除
    function delTodo(string memory todo) public {

    }

    //查看指定Todo
    function viewTodo(uint256 index) view public returns(string memory){   //view、pure
        return todos[index];
    }






    //查看所有Todo
    function viewAllTodo() public {

    }

    //查看所有completed
    function viewAllCompleted() public {

    }

    //todo改為completed
    function setTodoCompleted() public {

    }
}