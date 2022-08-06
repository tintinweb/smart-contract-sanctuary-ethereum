/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

contract TodoList {
    //增加代辦事項（TODO)
    //陣列 ARRAY
    string[] public todos;
    //格式["eat", "sleep"]
    //增加已完成事項（completed)
    //陣列ARRAY（請大家來增加）
     string[] public completed;
                //(）就是參數的意思
                // publc 會公開為練習用的但平常建議都用 private
                //storage(永久) memory(短暫呼叫就可以運作) calldata
     function add_todo(string memory todo) public {
        todos.push(todo);
        
    }
    // 刪除todo
    function delete_Todo() public {}

    // 查看指定 todo
    //["eat"]
    // 0 是指輸入 0 會顯示 eat.                      //第二週預錄課程
    function getTodo(uint256 index) view public returns(string memory){
        //怎麼取得 todos 索引的資訊//
        return todos[index]; 
    }

    // 查看所有 todo
    function get_All_Todo() public {}

    // todo改為 completed
    function change_Todo_Completed() public {}

    // 查看所有 completed 
    function get_All_Completed() public {}
}