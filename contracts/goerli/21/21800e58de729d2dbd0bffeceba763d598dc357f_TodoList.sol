/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.4;


contract TodoList {

    uint8 public pendingExpiredTime = 5;
    // 增加事項 (TODO)
    string[] public todos;

    // 增加已完成事項 (COMPLETED)
    string[] public todoCompleted;
    
    PendingTodoStruct[] public todoPending; // 暫存的todo (PENDING)
    struct PendingTodoStruct{
        string todo;
        uint timeout;
    }
    

    // 新增todo
    function addTodo(string memory todo) public {
        todos.push(todo);
    }



    // 刪除todo
    function delTodo(uint256 index) public {
        _remove(todos, index); 
    }
    

    // 查看所有todo
    function getAllTodo() public view returns (string[] memory) {
        return todos;
    }

    // 查看指定todo
    function getTodo(uint256 index) public view returns (string memory) {
        require(index < todos.length, "Out of bounds");
        return todos[index];
    }

    // 查看完成的todo
    function getAllCompleted() public view returns (string[] memory) {
        return todoCompleted;
    }

    // 移除所有completed項目 : 清空 Completed 功能
    function clearCompleted() public {
        delete todoCompleted;
    }

    // 改為completed
    function toCompleted(uint256 index) public {
        todoCompleted.push(todos[index]);
        // delete todos[index];
        _remove(todos, index);
    }

    // 改為pending
    function toPending(uint256 index) public {
        todoPending.push(PendingTodoStruct(todos[index], getTime(pendingExpiredTime))); // 轉移至pending list
        _remove(todos, index);
    }

    // 將 pending todo 改回 Todo list
    function backToTodos(uint256 index) public {
        require(index < todoPending.length, "Out of bounds");
        if(todoPending[index].timeout > getTime(0)){ // 目前相同時間＝過期
            todos.push(todoPending[index].todo);
            // delete todoPending[index];
            _removePending(index);
        }else{
            // 之後應該 emit event.   (todo pending time out)
        }
    }

    // 取得時間 (傳入offset , 可以計算時間位移)
    function getTime(uint256 secOffset) public view returns (uint256) {
        return block.timestamp + secOffset;
    }

    // 移除順便將array空格補上
    function _remove(string[] storage tlist , uint256 index) private {
        require(tlist.length > index, "Out of bounds");
        // 將所有陣列項目左移
        for (uint256 i = index; i < tlist.length - 1; i++) {
            tlist[i] = tlist[i+1];
        }
        tlist.pop(); // 移除最後一筆紀錄
    }

    // 移除 pending todo (由於專屬 PendingTodoStruct，直接在func操作 storage)
    function _removePending(uint256 index) private {
        require(todoPending.length > index, "Out of bounds");
        // 將所有陣列項目左移
        for (uint256 i = index; i < todoPending.length - 1; i++) {
            todoPending[i] = todoPending[i+1];
        }
        todoPending.pop(); // 移除最後一筆紀錄
    }

    // 查看所有pending清單
    function getAllPending() public view returns (PendingTodoStruct[] memory) {
        return todoPending;
    }

    // 更新pending過期時間
    function updatePendingExpiredTime(uint8 _newExpiredTime) public {
        require(_newExpiredTime >= 0 && _newExpiredTime <= 255 , "Out of bounds");
        pendingExpiredTime = _newExpiredTime;
    }
}