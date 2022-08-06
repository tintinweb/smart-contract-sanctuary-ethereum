/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TodoList{
    //增加代辦事項(TO DO)
    //陣列Array
    string[] public todos;
    //增加已完成事項(Completed)
    //
    string[] public todoCompleted;

    
    
    //新增
                        //寫合約建議都用private才安全，練習可以用public沒關係
                        //storage,memory,calldata
    /*memory 表示短暫使用，不會儲存在智能合約上，執行在這個 function 範圍內
    storage：原本已存在合約內
    calldata：memory 的變形，傳入後只可以做使用參考，不可以改變的資料型別
    當宣告 public, external，只能選 memory, calldata
    當宣告 private, internal，可以選 storage, memory*/
    function addTodo(string memory todo) public {
        todos.push(todo);

    }

    //刪除 TODO
    function delTodo() public {

    }


    //查看指定 TODO
    function getTodo(uint256 index) public view returns(string memory){

        return todos[index];

    }

    //查看所有 TODO
    function getAllTodo() public{


    }



    //TODO改為COMPLETED
    function setCompletedTodo() public{


    }

    //查看所有 COMPLETED
    function getAllCompleted() public{


    }




}