/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList {
    string[] public todos;
    string[] public todoCompleted;
    
    //延遲項目的屬性
    struct pendingitems{
        string itemname;
        uint pendingtime;
        // uint pendinghowlong;
    }
    
    //延遲項目
    mapping(uint=>pendingitems) public pendings;
    uint count = 0; //延遲項目編號
    uint public howlong; //延遲項目的延遲時間
    
    constructor() {
    }

    // 永久儲存是storage，短暫使用就用memory，calldata傳入後只能參考不能改變的data type 
    function addTodo(string memory todo) public {
        todos.push(todo);
    }

    //設定完成項目
    function setCompleted(uint256 index) external {

        string memory completedTodo = todos[index];
        
        for (uint256 i = index; i < todos.length - 1; i++){
            todos[i] = todos[i + 1];
        }
        delete todos[todos.length - 1];
        todos.pop();

        todoCompleted.push(completedTodo);
    }

    //設定延遲項目
    function setpending (uint256 whichone) external {

        string memory pendingitem = todos[whichone];
        
        for (uint256 i = whichone; i < todos.length - 1; i++){
            todos[i] = todos[i + 1];
        }
        delete todos[todos.length - 1];
        todos.pop();

        pendings[count] = pendingitems(pendingitem, block.timestamp);
        count++;
    }

    //轉移延遲項目，看是否超過指定時間，可否回到Todolist
    function Moveoutpendingitem (uint256 whichone) public {
        howlong = block.timestamp - pendings[whichone].pendingtime;

        require(howlong < 3600 , "This item has been pending for more than 1 hours and can't be moved.");
            // if(howlong < 20){
            //      todos.push(pendings[whichone].itemname);
            // }
            // else{
            //      return "This item has been pending for more than 3 hours and can't be executed. This item has been deleted.";
            // }
    }
    
    //刪除延遲項目
    function deletepending (uint256 whichone) external {
        delete pendings[whichone];
        for (uint256 i = whichone ; i < count - 1 ; i++){
            pendings[i] = pendings[i + 1];
        }
        delete pendings[count - 1];
    }

    //計算延遲時間
    function countpendinghowlong(uint256 whichone) public {
        howlong = block.timestamp - pendings[whichone].pendingtime;
    }

    //清除全部資料
    function Complete() public  {
        delete todos;
        delete todoCompleted;
        //delete pendings;
    }

    function getTodo(uint256 index) external view returns (string memory) {
        return todos[index];
    }

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
    
    // function getAllpendings() external view returns (string[] memory) {
    //     return pendings;
    // }
}