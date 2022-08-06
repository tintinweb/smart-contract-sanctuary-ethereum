/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract ToDoList {
    //新增代辦事項(TODO)
    string[] public todos;
    
    //增加已完成事項(COMPLETED)
    string[] public todocompleted;

    //constructor() {}
    
    //新增todo
    function addtodo(string memory todo) public {
        todos.push(todo);
    } 

    //刪除todo
    function deltodo() public {

    }

    //查看指定todo
    function gettodo(uint256 index) public view returns (string memory){
        return todos [index];
        }

    //查看所有todo
    function alltodo() public {

    }

    //todo改為完成
    function completedtodo() public {

    }

    //查看所有完成todo
    function allCompletedtodo() public {

    }


}