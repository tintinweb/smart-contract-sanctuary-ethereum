/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TODO_List_Solidity{

    //增加代辦事項
    string[] public todos;
    //增加已完成事項
    string[] public todos_Completed;  

    //新增 TODO
    function add_todo (string memory todo) public{
        todos.push(todo);  //將todo丟進去todos陣列內
    }
    //刪除TODO
    function del_todo () public {

    }   
    //查看指定 TODO
    function get_todo(uint256 index) public view returns(string memory){
        return todos[index];
    }

    //查詢所有TODO
    function search_todo ( ) public view returns(string memory){
    }
    //TODO 設定成COMPLETED
    function set_todo_completed () public {

    }
    //查看所有 COMPLETED
    function get_all_todo_completed() public {

    }
}