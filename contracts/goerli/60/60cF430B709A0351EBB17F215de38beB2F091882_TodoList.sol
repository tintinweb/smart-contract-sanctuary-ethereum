/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList {


    struct Item{
        string content;
        uint256 pendingStartTime;
    }


    Item[] public todos;
    Item[] public todoCompleted;
    Item[] public pending;

    uint256 public pendingThreshold; 

    constructor(uint256 _pendingLimit) {
        pendingThreshold = _pendingLimit;
    }

    modifier overRecoverTime(uint256 pendingStartTime){
        require(block.timestamp - pendingStartTime <= pendingThreshold, "over time !");
        _;
    }

    // 永久儲存是storage，短暫使用就用memory，calldata傳入後只能參考不能改變的data type 
    function addTodo(string memory todo) external {
        Item memory todoItem = Item({
            content: todo,
            pendingStartTime: 0 
            });
        todos.push(todoItem);
    }

    function setCompleted(uint256 index) external {

        Item memory compeltedTodo = pending[index];

        for (uint256 i = index; i < pending.length - 1; i++){
            pending[i] = pending[i + 1];
        }

        delete pending[pending.length - 1];

        pending.pop();

        todoCompleted.push(compeltedTodo);
    }

    function getTodo(uint256 index) external view returns (string memory) {
        return todos[index].content;
    }

    function deleteTodo(uint256 index) external {

        delete todos[index];

        //調整刪除arr元素，自動排序arr內容，並pop空間 (如此會增加deleteTodo所需支付的Gas Fee)
        for(uint256 i = index; i < todos.length - 1 ; i++){
            todos[i] = todos[i+1];
        }

        todos.pop();
    }

    function getCompleted(uint256 index) external view returns (string memory) {
        return todoCompleted[index].content;
    }

    function getAllTodo() external view returns (string[] memory) {
        string[] memory res = new string[](todos.length);
        for (uint256 i =0; i< todos.length; i++){
            res[i] = todos[i].content;
        }
        return res;
    }

    function getAllCompleted() external view returns (string[] memory) {
        string[] memory res = new string[](todoCompleted.length);
        for (uint256 i =0; i< todoCompleted.length; i++){
            res[i] = todoCompleted[i].content;
        }
        return res;
    }

    function setPending(uint256 _index) external {
        //取得要完成todo list 事項的內容
        Item memory pendingTodo = todos[_index];
        pendingTodo.pendingStartTime = block.timestamp;
        //重新整理arr內容，將完成事項後面的內容網前移動
        for (uint256 i = _index; i < todos.length - 1; i++){
            todos[i] = todos[i + 1];
        }
        //將最後一項還原成預設直
        delete todos[todos.length - 1];
        //將arr最後一個剛被還原的空間刪掉(arr長度-1)
        todos.pop();

        //將完成事項加入另一個list中
        pending.push(pendingTodo);
    } 

    function getPending (uint256 _index) external view returns (string memory){
        return pending[_index].content;
    }

    function getAllPending()external view returns(string[] memory) {
        string[] memory res = new string[](pending.length);
        for (uint256 i =0; i< pending.length; i++){
            res[i] = pending[i].content;
        }
        return res;
    }

    function recoverFromPendingToTodo(uint256 _index) external overRecoverTime(pending[_index].pendingStartTime) {
        Item memory pendingRecoverItem = pending[_index];
        todos.push(pendingRecoverItem);

        for(uint256 i= _index; i < pending.length-1; i++){
            pending[i] = pending[i+1];
        }
        delete pending[pending.length-1];
        pending.pop();
    }
}