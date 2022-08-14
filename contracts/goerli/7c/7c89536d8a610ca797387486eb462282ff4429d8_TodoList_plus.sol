/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList_plus {

    string[] public todos;
    string[] public todos_completed;  
    string[] public todos_pending;

    //新增待辦事項  用external或public都可以,但external 比較省gsa
    function add_todo(string memory todo) external{
        todos.push(todo);  //將todo丟進todos陣列內
    }
    //取得所有的待辦事項
    function get_all_todo() external view returns(string[] memory){
        return todos;
    }
    //取得所有已完成事項
    function get_all_todo_completed() external view returns(string[] memory) {
        return todos_completed;
    }
     //取得所有pending狀態的todo
    function get_all_todo_pending() external view returns(string[] memory){
        return todos_pending;
    }
    //將待辦事項設定完成
    function set_todo_completed(uint256 index) external {
        //檢查待辦事項是否存在
        require(index < todos.length ,"index not exit"); //如果index小於todos整體長度就成功.否則回傳index not exit的錯誤訊息
      
        //將完成的待辦事項移動到完成的todo陣列內
        string memory completedtodo = todos[index];
        todos_completed.push(completedtodo);

        //原本的待辦事項還在todos內 ,因此呼叫pop來刪除
        pop(todos,index);
    }
    //todo -> pending
    function move_todo_to_pending(uint256 index) external {
        //將todo移動到pending陣列內
        string memory todo = todos[index];
        todos_pending.push(todo);

        //原本的待辦事項還在todos內 ,因此呼叫pop來刪除
        pop(todos,index);
    }
    //pending -> todo
    function move_pending_to_todo(uint256 index) external {
        //將pending移動到todos陣列內
        string memory pending = todos_pending[index];
        todos.push(pending);

        //原本的待辦事項還在pending內 ,因此呼叫pop來刪除
        pop(todos_pending,index);
    }
    //新增pop function ,將舊資料刪除
    function pop(string[] storage list , uint256 index) private{
        for(uint256 i = index ; i < list.length -1 ;i++){
            list[i] = list[i+1];
        }
        list.pop();
    }
    //增加清空 Completed 功能
    function clearcompleted() external{
        delete todos_completed;
    }
}