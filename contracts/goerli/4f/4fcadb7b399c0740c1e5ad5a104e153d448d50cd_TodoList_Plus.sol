/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;


/*目標 原本在todos裡最多存放5個 再多的都到pending等待
todos 用手動確認進到completed 
clean complete 清除所有completed區域內的資訊 
*/

contract TodoList_Plus {

    string[] public todos;
    uint256 todosfullblank;

    string[] public pendings;

    string[] public todoCompleted;
    constructor() {
        todosfullblank = 3;
    }

    //新增TODO 同時確認是否還有空間 若無空間進到Pending
    function addTodo(string memory todo) public returns(uint256)  {
        if(todos.length < todosfullblank){
            todos.push(todo);
        }else{
            pendings.push(todo);
        }
        return (todos.length);
    }

    function setCompleted(uint256 index) public  {

        if(index < todos.length){
            string memory compeltedTodo = todos[index];
        
            for (uint256 i = index; i < todos.length - 1; i++){
                todos[i] = todos[i + 1];
            }
            delete todos[todos.length - 1];
            todos.pop();
            todoCompleted.push(compeltedTodo);

            if(pendings.length >0){
                string memory firstpendingtodo = pendings[0];
                todos.push(firstpendingtodo);
                delete pendings[0];

                for(uint256 i = 0 ; i < pendings.length - 1; i++){
                    pendings[i] = pendings[i+1];
                }
                pendings.pop();
            }
        }else if(index >= todos.length){
            require(false , "index is out of array");
        }
    }


    //刪除特定Complete的內容
    function deleteComplete(uint256 index) public {
        delete todoCompleted[index];
        for(uint256 i = 0 ; i < todoCompleted.length - 1; i++){
            todoCompleted[i] = todoCompleted[i+1];
        }
        todoCompleted.pop();
    }

    //刪除全部Complete的內容
    function deleteAllComplete() public {
        delete todoCompleted;
    }

    function getCompleted(uint256 index) external view returns (string memory) {
        return todoCompleted[index];
    }

    //獲得所有Todos的內容
    function getAllTodo() external view returns (string[] memory) {
        return todos;
    }
    
    //獲得所有Pendings的內容
    function getAllPending() external view returns (string[] memory) {
        return pendings;
    }

    //獲得所有Completed的內容
    function getAllCompleted() external view returns (string[] memory) {
        return todoCompleted;
    }

}